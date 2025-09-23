SELECT * FROM vaope2.sale_payments;

SELECT 
count(1) Q
-- * 
FROM vaope2.sale_payments;


SELECT * FROM vaope2.payment_methods;


select 
-- a.*,b.id,b.name 
b.name,count(1) Q
from vaope2.sale_payments a
inner join vaope2.payment_methods b on a.payment_method_id = b.id
group by b.name


select 
-- a.*,b.id,b.name 
b.name,a.validation_comments,count(1) Q
from vaope2.sale_payments a
left join vaope2.payment_methods b on a.payment_method_id = b.id
group by b.name,a.validation_comments


select 
-- a.*,b.id,b.name 
b.name,a.validation_comments,
UPPER(
    REGEXP_SUBSTR(
      TRIM(validation_comments),
      '^(visa|master[[:space:]]*card|INTER[[:space:]]*BANK|american[[:space:]]+express|amex|diners[[:space:]]*club|discover|jcb|union[[:space:]]*pay|maestro)',
      1, 1, 'i'
    )
  )     AS brand,
count(1) Q
from vaope2.sale_payments a
left join vaope2.payment_methods b on a.payment_method_id = b.id
group by b.name,a.validation_comments

select * from vaope2.sale_payments a



USE vaope2;

DROP TABLE IF EXISTS vaope.tmp_payments_parse;

CREATE TABLE vaope.tmp_payments_parse AS
WITH b AS (
  SELECT sp.id,sp.payment_method_id,sp.validation_comments,
         /* posición de la marca si aparece en texto */
         REGEXP_INSTR(
           sp.validation_comments COLLATE utf8mb4_0900_ai_ci,
           '(visa|master[[:space:]]*card|american[[:space:]]*express|\\bamex\\b|diners[[:space:]]*club|dinersclub|\\bdiners\\b|discover|jcb|union[[:space:]]*pay|maestro)',
           1,1,0,'i'
         ) AS pos_brand
  FROM vaope2.sale_payments sp
),
s AS (
  SELECT
  id,
payment_method_id,
    validation_comments,

    /* ENTIDAD: incluye abreviatura CAJAAQP */
    UPPER(REGEXP_SUBSTR(
      validation_comments COLLATE utf8mb4_0900_ai_ci,
      '(BANCO DE CREDITO DEL PERU|\\bBCP\\b|BBVA|SCOTIABANK|INTER[[:space:]]*BANK|BANBIF|MIBANCO|BANCO DE LA NACION|BANCO PICHINCHA|BANCO FALABELLA|BANCO RIPLEY|BANCO[[:space:]]*CENCOSUD|\\bCENCOSUD\\b|BANCO GNB|\\bGNB\\b|CITIBANK|AGROBANCO|BANCO DE COMERCIO|BANCO SANTANDER|BANCO FINANCIERO|BANCO AZTECA|CMR|OH!|FINANCIERA OH!|EFECTIVA|FINANCIERA EFECTIVA|CONFIANZA|FINANCIERA CONFIANZA|COMPARTAMOS|COMPARTAMOS FINANCIERA|CREDINKA|FINANCIERA CREDINKA|PROEMPRESA|FINANCIERA PROEMPRESA|QAPAQ|FINANCIERA QAPAQ|MITSUI|FINANCIERA MITSUI|ACCESO|ACCESO CREDITICIO|CAJA AREQUIPA|\\bCAJAAQP\\b|CAJA HUANCAYO|CAJA PIURA|CAJA TRUJILLO|CAJA SULLANA|CAJA ICA|CAJA TACNA|CAJA CUSCO|CAJA MAYNAS|CAJA PUNO|CAJA APURIMAC|CAJA DEL SANTA)'
    )) AS entidad_raw,

    /* PROCESADOR / WALLET: agrega AGORA */
    UPPER(REGEXP_SUBSTR(
      validation_comments COLLATE utf8mb4_0900_ai_ci,
      '(AGORA|NIUBIZ|IZIPAY|CULQI|PAGO[[:space:]]*EFECTIVO|SAFETYPAY|PAYU|MERCADO[[:space:]]*PAGO|KUSHKI|PAYME|OPENPAY|PAYPAL|STRIPE|YAPE|PLIN|LUKITA|BIM|TUNKI|VISA[[:space:]]*NET|V[- ]?POS)'
    )) AS procesador_raw,

    /* MARCA en texto (si viene) */
    UPPER(REGEXP_SUBSTR(
      validation_comments COLLATE utf8mb4_0900_ai_ci,
      '(visa|master[[:space:]]*card|american[[:space:]]*express|\\bamex\\b|diners[[:space:]]*club|dinersclub|\\bdiners\\b|discover|jcb|union[[:space:]]*pay|maestro)'
    )) AS red_txt,

    /* PRODUCTO solo desde la marca hacia adelante */
    CASE WHEN b.pos_brand > 0 THEN UPPER(
      REGEXP_SUBSTR(
        SUBSTRING(validation_comments, b.pos_brand) COLLATE utf8mb4_0900_ai_ci,
        '(cr[eé]dito|d[eé]bito)'
      )
    ) END AS producto,

    /* BIN6: si hay marca, toma desde ahí; si no, primer grupo de 6 dígitos */
    CASE
      WHEN b.pos_brand > 0 THEN REGEXP_SUBSTR(SUBSTRING(validation_comments, b.pos_brand), '[0-9]{6}')
      ELSE REGEXP_SUBSTR(validation_comments, '[0-9]{6}')
    END AS bin6,

    /* últimos 4 */
    REGEXP_SUBSTR(validation_comments, '([0-9]{4})$') AS ult4
  FROM b
)
SELECT
id,
payment_method_id,

  validation_comments,

  /* normalización ENTIDAD */
  CASE
    WHEN entidad_raw REGEXP '\\bCAJAAQP\\b' THEN 'CAJA AREQUIPA'
    ELSE entidad_raw
  END AS entidad_financiera,

  /* normalización PROCESADOR/WALLET */
  CASE
    WHEN procesador_raw REGEXP '\\bAGORA\\b' THEN 'AGORA'
    ELSE procesador_raw
  END AS procesador_wallet,

  /* MARCA: si no hay texto, inferir por BIN */
  CASE
    WHEN red_txt IS NOT NULL AND red_txt <> '' THEN red_txt
    WHEN bin6 REGEXP '^4' THEN 'VISA'
    WHEN bin6 REGEXP '^(5|22|23|24|25|26|27)' THEN 'MASTERCARD'  -- incluye rangos 2-series de MC
    WHEN bin6 REGEXP '^(34|37)' THEN 'AMEX'
    WHEN bin6 REGEXP '^(36|38|30[0-5])' THEN 'DINERS'
    WHEN bin6 REGEXP '^35' THEN 'JCB'
    WHEN bin6 REGEXP '^62' THEN 'UNIONPAY'
    WHEN bin6 REGEXP '^(6011|64|65)' THEN 'DISCOVER'
    ELSE NULL
  END AS red_tarjeta,

  producto,
  bin6,
  ult4
FROM s;


use vaope;
select a.id,a.payment_method_id,b.name,a.validation_comments,a.entidad_financiera, procesador_wallet,red_tarjeta,producto
from vaope.tmp_payments_parse  a
left join vaope2.payment_methods b on a.payment_method_id = b.id

-- Red_tarjeta = Yape y procesador_wallet = Yape -- NIUBIZ - ON LINE = yape

use vaope;
-- Agrupacion limpia
use vaope;
select b.id,b.name,a.entidad_financiera, procesador_wallet,red_tarjeta,producto,count(1) Q
from vaope.tmp_payments_parse  a
left join vaope2.payment_methods b on a.payment_method_id = b.id
group by b.id,b.name,a.entidad_financiera, procesador_wallet,red_tarjeta,producto
order by 6 desc

use vaope;
select * from vaope.tmp_payments_parse 
where entidad_financiera is null and procesador_wallet is null and red_tarjeta is null and producto is null

select entidad_financiera, procesador_wallet,red_tarjeta,producto,count(1) Q from vaope.tmp_payments_parse
group by entidad_financiera, procesador_wallet,red_tarjeta,producto




-- 	AGREGAR LA DIFERENCIACION DE YAPE QUE VIENE DE NUBIZ ONLINE - YAPE


