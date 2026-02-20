use dw_dev_hablavao;

-- TELETICKET
select * from event
where source_id = 1 -- and event_id in (204,205,230,244)
order by event_id desc;

select * from event_artist;

select * from event_category
order by 1 asc;

select * from event_category
where event_id = 325
order by 1 asc;

select * from category;

SELECT * FROM url_queue;

-- Verificar event_id y categoria asiganda teleticket.
select a.event_id,a.title,c.name from event a
inner join event_category b on a.event_id = b.event_id
inner join category c on b.category_id = c.category_id
where source_id = 1
order by 1 asc;

-- Verificar event_id y categoria asiganda teleticket (Por eventos)
select a.event_id,a.title,c.name from event a
inner join event_category b on a.event_id = b.event_id
inner join category c on b.category_id = c.category_id
where source_id = 1 and a.event_id in (204,205,230,244,833,827,820,320,325)
order by 1 asc;

SELECT COUNT(*) AS tours_mal
FROM event a
JOIN event_category b ON a.event_id = b.event_id
JOIN category c ON b.category_id = c.category_id
WHERE a.source_id = 1
  AND UPPER(a.title) LIKE '%TOUR%'
  AND c.name = 'Conciertos';
  
  describe category;
  
  describe event_category;

SELECT category_id FROM category WHERE name = 'Conciertos';

SELECT b.category_id, c.name, COUNT(*) AS cnt
FROM event a
JOIN event_category b ON a.event_id = b.event_id
JOIN category c ON c.category_id = b.category_id
WHERE a.source_id = 1
  AND UPPER(a.title) LIKE '%TOUR%'
GROUP BY b.category_id, c.name
ORDER BY cnt DESC;

SELECT 
  COUNT(*) AS total,
  SUM(ec.event_id IS NULL) AS sin_categoria
FROM event e
LEFT JOIN event_category ec ON e.event_id = ec.event_id
WHERE e.source_id = 1;

SELECT e.event_id, e.source_event_id, e.title, e.canonical_url
FROM event e
LEFT JOIN event_category ec ON e.event_id = ec.event_id
WHERE e.source_id = 1 AND ec.event_id IS NULL
ORDER BY e.event_id DESC
LIMIT 50;

SET SQL_SAFE_UPDATES = 0;
 
UPDATE url_queue uq
JOIN event e 
  ON e.canonical_url = uq.url
LEFT JOIN event_category ec
  ON ec.event_id = e.event_id
SET uq.status = 'nuevo', uq.last_error = NULL
WHERE e.source_id = 1
  AND uq.source_id = 1
  AND ec.event_id IS NULL;
  
SET SQL_SAFE_UPDATES = 1;

-- 1) Crear una tabla temporal con la categoría que te quedarás por evento
CREATE TEMPORARY TABLE tmp_event_cat_keep AS
SELECT event_id, MIN(category_id) AS keep_category_id
FROM event_category
GROUP BY event_id;
-- select * from tmp_event_cat_keep

-- 2) Borrar las categorías “extra”
DELETE ec
FROM event_category ec
JOIN tmp_event_cat_keep k
  ON ec.event_id = k.event_id
WHERE ec.category_id <> k.keep_category_id;

SELECT event_id
FROM event_category
GROUP BY event_id
HAVING COUNT(*) > 1;


-- elimina puente de categorías SOLO para eventos teleticket
DELETE ec
FROM event_category ec
JOIN event e ON e.event_id = ec.event_id
WHERE e.source_id = 1;

-- vuelve a poner URLs a nuevo
UPDATE url_queue
SET status='nuevo', last_error=NULL
WHERE source_id=1;

-- Ver cuántos eventos siguen sin categoría:
SELECT 
  COUNT(*) AS total,
  SUM(ec.event_id IS NULL) AS sin_categoria
FROM event e
LEFT JOIN event_category ec ON e.event_id = ec.event_id
WHERE e.source_id = 1;

-- Ver si alguno tiene más de 1 categoría:
SELECT ec.event_id, COUNT(*) AS n
FROM event_category ec
JOIN event e ON e.event_id = ec.event_id
WHERE e.source_id = 1
GROUP BY ec.event_id
HAVING COUNT(*) > 1;

-- Verificar eventos sin categoria e.*
SELECT 
  -- COUNT(*) total_sin_cat,
  -- SUM(e.ticket_url IS NULL) sin_ticket_url,
  -- SUM(e.canonical_url IS NULL) sin_canonical_url
  e.*
FROM event e
LEFT JOIN event_category ec ON ec.event_id = e.event_id
WHERE e.source_id = 1
  AND ec.event_id IS NULL;
  
  -- Insertar en temporal eventos sin categoria e.*
  create temporary table sin_categoria
SELECT 
  -- COUNT(*) total_sin_cat,
  -- SUM(e.ticket_url IS NULL) sin_ticket_url,
  -- SUM(e.canonical_url IS NULL) sin_canonical_url
  e.*
FROM event e
LEFT JOIN event_category ec ON ec.event_id = e.event_id
WHERE e.source_id = 1
  AND ec.event_id IS NULL;
  
  
  
  -- vuelve a poner URLs a nuevo (LOS QUE NO TIENEN CATEGORIA ASIGNADA)
UPDATE url_queue uq
JOIN event e 
  ON uq.source_id = e.source_id
 AND uq.url = e.ticket_url
LEFT JOIN event_category ec 
  ON ec.event_id = e.event_id
SET uq.status = 'nuevo',
    uq.last_error = NULL
WHERE e.source_id = 1
  AND ec.event_id IS NULL;
  
  
  -- TELETICKET
select b.* from event a 
inner join url_queue b on a.source_id = b.source_id and b.url = a.ticket_url
where a.source_id = 1 and event_id in (select event_id from sin_categoria)
order by a.event_id desc;




-- JOINNUS
-- ---------------------------------------------------------------------------------
select * from event
where source_id = 2;

select * from event_artist;

select * from event_category;

select * from category;

SELECT * FROM url_queue;

select * from event a
inner join event_category b on a.event_id = b.event_id
inner join category c on b.category_id = c.category_id
where source_id = 2;

SELECT 
  COUNT(*) AS total,
  SUM(ec.event_id IS NULL) AS sin_categoria
FROM event e
LEFT JOIN event_category ec ON e.event_id = ec.event_id
WHERE e.source_id = 2;

SELECT e.event_id, e.source_event_id, e.title, e.canonical_url
FROM event e
LEFT JOIN event_category ec ON e.event_id = ec.event_id
WHERE e.source_id = 2 AND ec.event_id IS NULL
ORDER BY e.event_id DESC
LIMIT 50;
