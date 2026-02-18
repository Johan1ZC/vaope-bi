/* =======================================================================
   Huella: JZ-VAOPE-RPT-set_paginaWeb.Ventas-003
   Artefacto: (Metodos de conversion)
   Autora: Johan Zuñiga Cordova  |  v3.0  |  2025-10-14
   Propósito: Ventas realizadas en la pagina web de Vaope,
   detalles de productos, ingresos y metodos de pago (para export/BI)
   ======================================================================= */

use vaope_qa5;
SET SESSION time_zone = '-05:00';

-- construccion de tabla FACVENTASWEB

DROP TABLE IF EXISTS vaope.factventasweb;
CREATE TABLE vaope.factventasweb
select 
DATE_FORMAT(a.created_at,'%Y%m%d') as fechaID,
HOUR(a.created_at) as horaID,
a.id as web_VentaID,
a.product_id as eventoID,
c.title_small as nom_evento,
case when a.status = 0 then "Pendiente de pago" when a.status = 1 then "Pago Confirmado" when a.status = 2 then "En Evento"
when a.status = 3 then "" when a.status = 4 then "Finalizado" when a.status = 5 then "Anulado" 
when a.status = 6 then "Pendiente Devolución" when a.status = 7 then "Devuelto" when a.status = 9 then "Observado"  else "otros" end status_general,
sum(a.quantity_products) cantidadProd, -- Verificar que pasa con un producto que tiene 10 entradas tipo BOX
a.sub_total,
a.discount,
a.delivery, 
a.total_price, -- Precio total de la venta depositado por el cliente en la pasarella de pagos.
ifnull(e.payment_commission,0) payment_commission,  -- Comision VISA
ifnull(e.vaope_commission,0) vaope_commission, -- Comision Vaope
ifnull(e.sale_commission,0) sale_commission, -- Cobros adicionales ejemplo s/2
ifnull(e.total_deposit,0) total_deposit, -- Deposito organizador
-- abs(((ifnull(e.payment_commission,0)+ifnull(e.vaope_commission,0)+ifnull(e.sale_commission,0))-a.total_price)) as total_deposit_new,
(ifnull(a.total_price,0)-(ifnull(e.payment_commission,0)+ifnull(e.vaope_commission,0)+ifnull(e.sale_commission,0))) as total_deposit_new,
case when a.payment_method_id = 12 then 1 else 0 end esCortesia,
a.utm_source,
a.utm_campaign,
a.utm_medium,
a.client_id as usuarioID,
sum(a.persons) persons,
a.payment_method_id
from vaope_qa5.sales a
-- inner join vaope.lead_paginaweb_muestra d on a.id = d.id  -- DESACTIVAR EN PRODUCCION
left join vaope_qa5.products c on a.product_id = c.id
left join (select a.* from vaope_qa5.product_liquidation_detail a
inner join (select sale_id,max(id) max_id,count(1) Q from vaope_qa5.product_liquidation_detail group by sale_id) b on a.sale_id = b.sale_id and a.id = b.max_id) e on a.id = e.sale_id and a.payment_method_id = e.payment_method_id
group by 
DATE_FORMAT(a.created_at,'%Y%m%d'),
HOUR(a.created_at),
a.id,
a.product_id,
title_small, -- pendiente
case when a.status = 0 then "Pendiente de pago" when a.status = 1 then "Pago Confirmado" when a.status = 2 then "En Evento"
when a.status = 3 then "" when a.status = 4 then "Finalizado" when a.status = 5 then "Anulado" 
when a.status = 6 then "Pendiente Devolución" when a.status = 7 then "Devuelto" when a.status = 9 then "Observado"  else "otros" end,
case when a.payment_method_id = 12 then 1 else 0 end, -- pendiente obtene desde paymenth method
a.sub_total,
a.discount,
a.delivery, 
a.total_price,
e.payment_commission,
e.vaope_commission,
e.sale_commission,
e.total_deposit,
a.utm_source,
a.utm_campaign,
a.utm_medium,
a.client_id,
a.payment_method_id;
-- 712633
-- 748833
-- 775080

-- select web_ventaID,count(*) q from vaope.factventasweb group by web_ventaID order by 2 desc
-- select * from vaope.factventasweb where web_ventaid = 518258
SET SESSION time_zone = '-05:00';

-- AGREGAR CAMPOS DE METODOS DE PAGO EN BLANCO
alter table vaope.factventasweb add column mp_NomMetodo varchar(150);
alter table vaope.factventasweb add column mp_EntidadFinanciera varchar(150);
alter table vaope.factventasweb add column mp_Procesador_Wallet varchar(150);
alter table vaope.factventasweb add column mp_Red_Tarjeta varchar(150); 
alter table vaope.factventasweb add column mp_Producto varchar(150);
alter table vaope.factventasweb add column pagos_count INT;
alter table vaope.factventasweb add column metodos_distintos INT;
alter table vaope.factventasweb add column mp_MetodoGrupo varchar(150);

SET SESSION time_zone = '-05:00';

-- ACTUALIZACION METODOS DE PAGO
SET SQL_SAFE_UPDATES = 0;
UPDATE vaope.factventasweb a
LEFT JOIN vaope_qa5.payment_methods b
  ON a.payment_method_id = b.id
SET
  a.mp_NomMetodo = NULLIF(b.name,'')
  WHERE b.id IS NOT NULL; 
  SET SQL_SAFE_UPDATES = 1;  -- vuelve a activarlo


SET SESSION time_zone = '-05:00';
-- TRANFORMACION DE CAMPOS DE METODOS DE PAGO PARA CLIENTES DE FACTVENTASWEB 
USE vaope_qa5;

DROP TABLE IF EXISTS vaope.tmp_payments_parse;

CREATE temporary table vaope.tmp_payments_parse AS
WITH b AS (
  SELECT sp.id,sp.sale_id,sp.payment_method_id,sp.validation_comments,
         /* posición de la marca si aparece en texto */
         REGEXP_INSTR(
           sp.validation_comments COLLATE utf8mb4_0900_ai_ci,
           '(visa|master[[:space:]]*card|american[[:space:]]*express|\\bamex\\b|diners[[:space:]]*club|dinersclub|\\bdiners\\b|discover|jcb|union[[:space:]]*pay|maestro)',
           1,1,0,'i'
         ) AS pos_brand
  FROM vaope_qa5.sale_payments sp
  -- select * from vaope2.sale_payments sp
  where sale_id in (select web_ventaid from vaope.factventasweb)
),
s AS (
  SELECT
  id,
  sale_id,
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
sale_id,
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
-- SELECT * FROM vaope.tmp_payments_parse

ALTER TABLE vaope.tmp_payments_parse ADD INDEX idx_sp_saleid (sale_id);

/* CLIENTES CON MAS DE 1 METODO DE PAGO
-- select sale_id,count(*) from vaope.tmp_payments_parse group by sale_id order by 2 desc
select * from vaope.tmp_payments_parse
where sale_id = '507668';
select * from vaope.tmp_payments_parse
where sale_id = '519079';
select * from vaope.tmp_payments_parse
where sale_id = '518975';
*/

SET SESSION time_zone = '-05:00';
-- Por si los textos pueden ser largos
SET SESSION group_concat_max_len = 1000000;

DROP TABLE IF EXISTS vaope.tmp_payments_unificado;

CREATE temporary table vaope.tmp_payments_unificado AS
SELECT
  p.sale_id,

  -- Concatenados, deduplicados y en minúsculas (ajusta UPPER/LOWER a tu gusto)
  GROUP_CONCAT(DISTINCT LOWER(p.entidad_financiera)
               ORDER BY p.id SEPARATOR ' | ')         AS entidad_financiera,
  GROUP_CONCAT(DISTINCT LOWER(p.procesador_wallet)
               ORDER BY p.id SEPARATOR ' | ')         AS procesador_wallet,
  GROUP_CONCAT(DISTINCT LOWER(p.red_tarjeta)
               ORDER BY p.id SEPARATOR ' | ')         AS red_tarjeta,
  GROUP_CONCAT(DISTINCT LOWER(p.producto)
               ORDER BY p.id SEPARATOR ' | ')         AS producto,

  -- Extras útiles
  COUNT(*)                                           AS pagos_count,
  COUNT(DISTINCT p.payment_method_id)               AS metodos_distintos
  -- ,SUM(p.monto)                                   AS monto_total  -- si tienes el importe por pago
FROM vaope.tmp_payments_parse p
GROUP BY p.sale_id;
-- SELECT * FROM vaope.tmp_payments_unificado WHERE sale_id = 519079;

ALTER TABLE vaope.tmp_payments_unificado ADD INDEX idx_spu_saleid (sale_id);

SET SQL_SAFE_UPDATES = 0;
UPDATE vaope.factventasweb a
LEFT JOIN vaope.tmp_payments_unificado b
  ON a.web_VentaID = b.sale_id
SET
  a.mp_EntidadFinanciera = NULLIF(b.entidad_financiera,''),
  a.mp_Procesador_Wallet = NULLIF(b.procesador_wallet,''),
  a.mp_Red_Tarjeta       = NULLIF(b.red_tarjeta,''),
  a.mp_Producto          = NULLIF(b.producto,''),
  a.pagos_count          = b.pagos_count,
  a.metodos_distintos    = b.metodos_distintos
  WHERE b.sale_id IS NOT NULL; 
  SET SQL_SAFE_UPDATES = 1;  -- vuelve a activarlo

-- select count(1) Q from vaope.factventasweb -- 23746
-- select  * from vaope.factventasweb


/* Actualizar metodo Grupo
*/

SET SQL_SAFE_UPDATES = 0;

UPDATE vaope.factventasweb f
SET f.mp_MetodoGrupo =
CASE
  /* ==================== Casos específicos ==================== */

  -- Gmoney en cualquier campo
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_EntidadFinanciera, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_Producto)) LIKE '%GMONEY%'
    THEN 'Gmoney'

  -- Niubiz - online - yape / plin
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'NIUBIZ'
       AND UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'ON[ -]?LINE|ONLINE'
       AND UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) LIKE '%YAPE%'
    THEN 'niubiz - online - yape'

  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'NIUBIZ'
       AND UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'ON[ -]?LINE|ONLINE'
       AND UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) LIKE '%PLIN%'
    THEN 'niubiz - online - plin'

  -- Niubiz - online - Redes (Visa/Mastercard/Amex/Diners)
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'NIUBIZ'
       AND UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'ON[ -]?LINE|ONLINE'
       AND UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'VISA|MASTERCARD|\\bMC\\b|AMEX|DINERS'
    THEN CONCAT('niubiz - online - ',
                CASE
                  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'MASTERCARD|\\bMC\\b' THEN 'Mastercard'
                  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'AMEX|AMERICAN EXPRESS' THEN 'Amex'
                  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'DINERS' THEN 'Diners'
                  ELSE 'Visa'
                END)

  -- Niubiz - online - otros
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'NIUBIZ'
       AND UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'ON[ -]?LINE|ONLINE'
    THEN 'niubiz - online - otros'

  -- NiubizQR (Yape / Plin)
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Producto)) REGEXP 'NIUBIZ'
       AND UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Producto)) LIKE '%YAPE%'
    THEN 'NiubizQR - Yape'

  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Producto)) REGEXP 'NIUBIZ'
       AND UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Producto)) LIKE '%PLIN%'
    THEN 'NiubizQR - Plin'

  -- Niubiz (Tarjeta) - por red o por producto wallet
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_Producto)) LIKE '%NIUBIZ%'
       AND UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Red_Tarjeta)) REGEXP 'VISA|MASTERCARD|\\bMC\\b|AMEX|DINERS'
    THEN CONCAT('Niubiz (Tarjeta) - ',
                CASE
                  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Red_Tarjeta)) REGEXP 'MASTERCARD|\\bMC\\b' THEN 'MASTERCARD'
                  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Red_Tarjeta)) REGEXP 'AMEX|AMERICAN EXPRESS' THEN 'AMEX'
                  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Red_Tarjeta)) REGEXP 'DINERS' THEN 'DINERS'
                  ELSE 'VISA'
                END)

  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Producto)) LIKE '%NIUBIZ%'
       AND UPPER(f.mp_Producto) REGEXP 'YAPE|PLIN|BIM|LUKITA|TUNKI'
    THEN CONCAT('Niubiz (Tarjeta) - ',
                CASE
                  WHEN UPPER(f.mp_Producto) LIKE '%YAPE%'   THEN 'Yape'
                  WHEN UPPER(f.mp_Producto) LIKE '%PLIN%'   THEN 'Plin'
                  WHEN UPPER(f.mp_Producto) LIKE '%BIM%'    THEN 'Bim'
                  WHEN UPPER(f.mp_Producto) LIKE '%LUKITA%' THEN 'Lukita'
                  WHEN UPPER(f.mp_Producto) LIKE '%TUNKI%'  THEN 'Tunki'
                END)

  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Red_Tarjeta, f.mp_Producto)) LIKE '%NIUBIZ%'
    THEN 'Niubiz (Tarjeta)'

  /* ==================== Otros procesadores / métodos ==================== */

  -- Izipay
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Producto)) LIKE '%IZIPAY%'
    THEN 'Izipay'

  -- Transferencia
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'TRANSFER|TRANSFERENCIA'
    THEN 'Transferencia'

  -- Wallets directas
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Producto, f.mp_Procesador_Wallet)) LIKE '%YAPE%'
    THEN 'Yape'
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Producto, f.mp_Procesador_Wallet)) LIKE '%PLIN%'
    THEN 'Plin'

  -- POS / Efectivo
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Procesador_Wallet, f.mp_Producto)) REGEXP '\\bPOS\\b|POINT OF SALE'
    THEN 'POS'
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_EntidadFinanciera, f.mp_Producto)) REGEXP 'EFECTIVO|AGENTE|CAJA|CASH'
    THEN 'Efectivo/Agente'

  -- Tarjeta (Red) sin Niubiz
  WHEN UPPER(CONCAT_WS(' ', f.mp_Red_Tarjeta, f.mp_NomMetodo)) REGEXP 'VISA|MASTERCARD|\\bMC\\b|AMEX|DINERS'
    THEN CONCAT('Tarjeta (Red) - ',
                CASE
                  WHEN UPPER(CONCAT_WS(' ', f.mp_Red_Tarjeta, f.mp_NomMetodo)) REGEXP 'MASTERCARD|\\bMC\\b' THEN 'MASTERCARD'
                  WHEN UPPER(CONCAT_WS(' ', f.mp_Red_Tarjeta, f.mp_NomMetodo)) REGEXP 'AMEX|AMERICAN EXPRESS' THEN 'AMEX'
                  WHEN UPPER(CONCAT_WS(' ', f.mp_Red_Tarjeta, f.mp_NomMetodo)) REGEXP 'DINERS' THEN 'DINERS'
                  ELSE 'VISA'
                END)

  -- Cortesía (si llegara etiquetado)
  WHEN UPPER(CONCAT_WS(' ', f.mp_NomMetodo, f.mp_Producto)) LIKE '%CORTESIA%'
    THEN 'Cortesia'

  -- Fallback
  ELSE 'Otros'
END;

SET SQL_SAFE_UPDATES = 1;




/*
use vaope;
select b.id,b.name,a.entidad_financiera, procesador_wallet,red_tarjeta,producto,count(1) Q
from vaope.tmp_payments_parse  a
left join vaope2.payment_methods b on a.payment_method_id = b.id
group by b.id,b.name,a.entidad_financiera, procesador_wallet,red_tarjeta,producto
order by 6 desc

use vaope;
select b.name,a.entidad_financiera, procesador_wallet,red_tarjeta,producto,count(1) Q
from vaope.tmp_payments_parse  a
left join vaope2.payment_methods b on a.payment_method_id = b.id
group by b.name,a.entidad_financiera, procesador_wallet,red_tarjeta,producto
order by 6 desc

select * from cart_transactions

-- select * from vaope.factventasweb where web_ventaid = 191465
-- 14:30:30	select * from vaope.factventasweb	748833 row(s) returned	0.000 sec / 4.296 sec


*/