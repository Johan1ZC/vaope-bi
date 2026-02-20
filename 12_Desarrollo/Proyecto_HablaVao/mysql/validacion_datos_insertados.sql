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

/*Ejecutar con powershell desde VSCODE
 Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
 .\.venv\Scripts\Activate.ps1
*/

/*
# TELETICKET
$env:MANIFEST="sources/teleticket/teleticket_manifest.yaml"
python sources/teleticket/hu31_crawler_teleticket.py

# JOINNUS
$env:MANIFEST="sources/joinnus/joinnus_manifest.yaml"
python sources/joinnus/hu33_crawler_joinnus.py

# TICKETMASTER
$env:MANIFEST="sources/ticketmaster/ticketmaster_manifest.yaml"
python sources/ticketmaster/hu31_crawler_ticketmaster.py
*/

/*python hu31_crawler_teleticket.py*/


/* Limpiar
Remove-Item Env:HEADLESS
Remove-Item Env:DEBUG
*/


ALTER TABLE url_queue
  ADD COLUMN meta_json JSON NULL AFTER url;

  
select * FROM url_queue
where source_id = 1
order by discovered_at desc;
-- 3	29	12:07:11	select * FROM url_queue	169 row(s) returned	0.000 sec / 0.000 sec
-- 3	18	11:05:48	select * FROM url_queue order by discovered_at desc	245 row(s) returned	0.016 sec / 0.000 sec
-- 17:35:25	select * FROM url_queue order by discovered_at desc	247 row(s) returned	0.000 sec / 0.000 sec
-- 15:25:44	select * FROM url_queue order by discovered_at desc LIMIT 0, 1000	245 row(s) returned	0.015 sec / 0.000 sec
-- 10:04:50	select * FROM url_queue order by discovered_at desc	284 row(s) returned	0.000 sec / 0.000 sec
-- 12:45:39	select * FROM url_queue where source_id = 1 order by discovered_at desc	333 row(s) returned	0.000 sec / 0.000 sec
-- 11:54:57	select * FROM url_queue where source_id = 1 order by discovered_at desc	500 row(s) returned	0.031 sec / 0.000 sec
-- 01:42:57	select * FROM url_queue where source_id = 1 order by discovered_at desc	582 row(s) returned	0.015 sec / 0.000 sec




select * FROM url_queue
where source_id = 2
order by discovered_at desc;
-- 14:31:28	select * FROM url_queue where source_id = 2 order by discovered_at desc	262 row(s) returned	0.000 sec / 0.000 sec
-- 14:51:09	select * FROM url_queue where source_id = 2 order by discovered_at desc	319 row(s) returned	0.000 sec / 0.000 sec
-- 12:52:15	select * FROM url_queue where source_id = 2 order by discovered_at desc	351 row(s) returned	0.000 sec / 0.000 sec
-- 16:32:38	select * FROM url_queue where source_id = 2 order by discovered_at desc	413 row(s) returned	0.015 sec / 0.000 sec
-- 12:36:29	select * FROM url_queue where source_id = 2 order by discovered_at desc	557 row(s) returned	0.016 sec / 0.000 sec




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





-- ANALISIS DE INFORMACION:

SELECT DATABASE(hablavao);

-- Comparar ambos schemas
SELECT COUNT(*) AS n_dw  FROM dw_dev_hablavao.url_queue  WHERE source_id=1;
SELECT COUNT(*) AS n_cr  FROM hablavao.url_queue         WHERE source_id=1;


SELECT source_id FROM source WHERE name='Teleticket';

SELECT source_id, COUNT(*) 
FROM url_queue 
GROUP BY source_id;


SELECT status, COUNT(*) 
FROM url_queue 
WHERE source_id = 2
GROUP BY status;


SELECT COUNT(*) AS eventos_teleticket
FROM event
WHERE source_id = 1;

SELECT COUNT(*) AS eventos_Joinnus
-- select *
FROM event
WHERE source_id = 2;

select * FROM url_queue
where source_id = 2 and meta_json like '%trujillo%'


WITH q AS (
  SELECT
    url_id,
    url,
    status,
    COALESCE(
      JSON_UNQUOTE(JSON_EXTRACT(meta_json, '$.eventoId')),
      SUBSTRING_INDEX(url,'/',-1)
    ) AS seid
  FROM url_queue
  WHERE source_id = 1
)
SELECT q.url_id, q.url, q.status, q.seid
FROM q
LEFT JOIN event e
  ON e.source_id = 1
 AND e.source_event_id = q.seid
WHERE q.status = 'procesado'
  AND e.event_id IS NULL;
  
  
  UPDATE url_queue q
LEFT JOIN event e
  ON e.source_id = 1
 AND e.source_event_id = COALESCE(
      JSON_UNQUOTE(JSON_EXTRACT(q.meta_json, '$.eventoId')),
      SUBSTRING_INDEX(q.url,'/',-1)
    )
SET q.status = 'nuevo',
    q.last_error = NULL
WHERE q.source_id = 1
  AND q.status = 'procesado'
  AND e.event_id IS NULL;
  
  
  SELECT source_id, name, base_url FROM source WHERE name = 'Joinnus';



-- 1) Elegir el ID canónico por nombre
CREATE TEMPORARY TABLE source_keep AS
SELECT MIN(source_id) AS keep_id, name
FROM source
GROUP BY name;

-- 2) Reapuntar referencias (url_queue, event, ingest_audit)
UPDATE url_queue u
JOIN source s     ON u.source_id = s.source_id
JOIN source_keep k ON s.name      = k.name
SET u.source_id = k.keep_id;

SET SQL_SAFE_UPDATES = 0;

UPDATE event e
JOIN source s     ON e.source_id = s.source_id
JOIN source_keep k ON s.name      = k.name
SET e.source_id = k.keep_id;

UPDATE ingest_audit ia
JOIN source s     ON ia.source_id = s.source_id
JOIN source_keep k ON s.name       = k.name
SET ia.source_id = k.keep_id;

-- 3) Borrar duplicados de source dejando solo el canónico
DELETE s
FROM source s
LEFT JOIN source_keep k ON s.source_id = k.keep_id
WHERE k.keep_id IS NULL;

-- 4) Crear índice único para que el ON DUPLICATE KEY funcione
ALTER TABLE source ADD UNIQUE KEY uk_source_name (name);

SET SQL_SAFE_UPDATES = 1;

SELECT source_id, name, base_url FROM source WHERE name='Joinnus';


SELECT status, COUNT(*) FROM url_queue
WHERE source_id = (SELECT source_id FROM source WHERE name='Joinnus')
GROUP BY status;
-- select * from url_queue

UPDATE url_queue
SET source_id = 2
WHERE source_id = 15;


START TRANSACTION;

-- Mueve referencias al ID canónico (2)
UPDATE url_queue     SET source_id = 2 WHERE source_id = 15;
UPDATE event         SET source_id = 2 WHERE source_id = 15;
UPDATE ingest_audit  SET source_id = 2 WHERE source_id = 15;

-- Asegura que el registro 2 sea Joinnus
UPDATE source
SET name = 'Joinnus', base_url = 'https://www.joinnus.com/'
WHERE source_id = 2;

-- Borra el duplicado 15
DELETE FROM source WHERE source_id = 15;

COMMIT;


SELECT source_id,name,base_url FROM source WHERE name='Joinnus';
SELECT status,COUNT(*) FROM url_queue WHERE source_id=2 GROUP BY status;



USE dw_dev_hablavao;
START TRANSACTION;

-- 1.1 Fija el registro canónico (id=2) para Joinnus (crea o actualiza)
INSERT INTO source (source_id, name, base_url)
VALUES (2, 'Joinnus', 'https://www.joinnus.com/')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  base_url = VALUES(base_url);

-- 1.2 Reapunta cualquier referencia que esté usando otro id (p.ej. 15, 16) hacia 2
UPDATE url_queue    SET source_id = 2 WHERE source_id IN (15,16);
UPDATE event        SET source_id = 2 WHERE source_id IN (15,16);
UPDATE ingest_audit SET source_id = 2 WHERE source_id IN (15,16);

-- 1.3 Borra duplicados de Joinnus distintos de 2 (si existe alguno)
DELETE FROM source
WHERE name = 'Joinnus' AND source_id <> 2;

COMMIT;



SELECT DATABASE();
SELECT COUNT(*) FROM url_queue WHERE source_id=2 AND status='nuevo';

select * from url_queue
where url_id = 475

select * from url_queue
where url_id = 5121 

-- Cantidad de registros por source:
SELECT source_id, status, COUNT(*) c
FROM url_queue
GROUP BY source_id, status
ORDER BY source_id, status;

-- CANTIDAD DE REGISTROS NUEVOS:
SELECT COUNT(*) AS nuevos
FROM url_queue
WHERE source_id = 1 AND status = 'nuevo';

SELECT COUNT(*) AS nuevos
FROM url_queue
WHERE source_id = 2 AND status = 'nuevo';

-- REINTENTAR EL LOADER:

UPDATE url_queue
SET status = 'nuevo',
    last_error = NULL
WHERE source_id = 2
  AND status = 'error';


