use dw_dev_hablavao;

select * from dw_dev_hablavao.event_category

SELECT status, COUNT(*) FROM url_queue GROUP BY status;

SELECT url_id, url,meta_json,discovered_at
-- select * 
FROM url_queue
 where url like '%gian-marco%'
ORDER BY url_id DESC

SELECT COUNT(*) total, COUNT(DISTINCT hash_url) distintos FROM url_queue;

/*
$env:HEADLESS = "0"
$env:DEBUG    = "1"
python hu31_crawler_teleticket.py
*/


/* Limpiar
Remove-Item Env:HEADLESS
Remove-Item Env:DEBUG
*/


ALTER TABLE url_queue
  ADD COLUMN meta_json JSON NULL AFTER url;
  
select * FROM url_queue order by discovered_at desc;
-- 3	29	12:07:11	select * FROM url_queue	169 row(s) returned	0.000 sec / 0.000 sec
-- 3	18	11:05:48	select * FROM url_queue order by discovered_at desc	245 row(s) returned	0.016 sec / 0.000 sec
-- 17:35:25	select * FROM url_queue order by discovered_at desc	247 row(s) returned	0.000 sec / 0.000 sec

select * FROM url_queue 
where url = 'https://teleticket.com.pe/evento/museo-de-efectos-visuales-arequipa-museo-de-efectos-visuales-arequipa'
order by discovered_at desc;

-- truncate table url_queue

/*
https://teleticket.com.pe/Landing/GetEventosBusqueda
Request Method GET
x-requested-with XMLHttpRequest
referer https://teleticket.com.pe/
content-type application/json; charset=utf-8
accept * /*
*/


-- ¿Cuántas filas totales vs. distintas por hash?
SELECT COUNT(*) total, COUNT(DISTINCT source_id, hash_url) distintas FROM url_queue;

-- Posibles duplicados si NO normalizaras (solo para entender el problema)
SELECT url
FROM url_queue
GROUP BY url
HAVING COUNT(*) > 1
LIMIT 20;


-- ¿Cuántas tienen / no tienen meta?
SELECT
  COUNT(*)                                       AS total,
  SUM(meta_json IS NULL)                         AS sin_meta,
  SUM(meta_json IS NOT NULL)                     AS con_meta
FROM url_queue;

-- Muestra ejemplos sin meta (para revisar el patrón de URL)
SELECT url
FROM url_queue
WHERE meta_json IS NULL
ORDER BY url_id DESC
LIMIT 20;


SELECT status, COUNT(*) FROM url_queue GROUP BY status;

SELECT url,
       JSON_EXTRACT(meta_json, '$.title') AS title
FROM url_queue
ORDER BY url_id DESC
LIMIT 10;

