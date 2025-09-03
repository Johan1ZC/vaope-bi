SELECT * FROM lugares.locations
where place_name = 'Aqulandia Ica';

#Crear tablas temporales vacia desde otro esquema
CREATE TEMPORARY TABLE tmp_locations LIKE locations;  -- clona columnas e índices

#Crear tabla temporal apartir de un select
CREATE TEMPORARY TABLE tmp_dupes AS
SELECT
  id,
  ROW_NUMBER() OVER (
    PARTITION BY place_name, street_address, address_locality
    ORDER BY id
  ) AS rn
FROM locations;
#select * from tmp_dupes



create temporary table lugares_temp as
select place_name,count(1) q
#into @temporal
from lugares.locations
group by place_name
order by 2 desc

select * from lugares_temp

select * from lugares.locations a
inner join lugares_temp b on a.place_name = b.place_name and q >= 2
order by a.place_name desc

#Limpiar datos

#Construir “firma” normalizada y elegir canónico

# (Opcional) diccionario simple de sinónimos; amplía según necesites
SET NAMES utf8mb4;
SET SESSION group_concat_max_len = 1024000;

-- 0) Diccionario (colación ai_ci = ignora tildes y mayúsculas)
DROP TEMPORARY TABLE IF EXISTS dict;
CREATE TEMPORARY TABLE dict (
  de VARCHAR(50) PRIMARY KEY,
  a  VARCHAR(50) NOT NULL
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO dict (de,a) VALUES
  ('jiron','jr'), ('jr.','jr'),
  ('avenida','av'), ('av.','av'),
  ('urbanizacion','urb'), ('urb.','urb');
  -- select * from dict

-- Limpieza por pasos
DROP TEMPORARY TABLE IF EXISTS tmp_base, tmp_clean, tmp_tok, tmp_mapped, tmp_filtered, tmp_signature, tmp_pick, t_map;

CREATE TEMPORARY TABLE tmp_base
DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AS
SELECT
  id,
  place_name, street_address, address_locality,
  LOWER(TRIM(CONCAT_WS(' ', place_name, street_address, address_locality))) AS txt
FROM locations;
-- select * from tmp_base

CREATE TEMPORARY TABLE tmp_clean
DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AS
SELECT
  id, place_name, street_address, address_locality,
  REGEXP_REPLACE(REGEXP_REPLACE(txt, '[-,./]', ' '), '\\s+', ' ') AS txt
FROM tmp_base;
-- select * from tmp_clean

-- Tokenizar
-- Por si necesitas más de 100 tokens por fila, sube este límite
SET SESSION cte_max_recursion_depth = 10000;

CREATE TEMPORARY TABLE tmp_tok
DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AS
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n+1 FROM seq WHERE n < 100
)
SELECT
  c.id,
  REGEXP_SUBSTR(c.txt, '[^ ]+', 1, seq.n) AS tok
FROM tmp_clean c
JOIN seq
  ON REGEXP_SUBSTR(c.txt, '[^ ]+', 1, seq.n) IS NOT NULL;
  -- select * from tmp_tok

-- Mapear sinónimos (nota: envolvemos dict en un subselect para evitar re-open)
CREATE TEMPORARY TABLE tmp_mapped
DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AS
SELECT t.id, COALESCE(d.a, t.tok) AS tok
FROM tmp_tok t
LEFT JOIN (SELECT de, a FROM dict) d ON t.tok = d.de;
-- select * from tmp_mapped

-- Quitar stopwords
CREATE TEMPORARY TABLE tmp_filtered
DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AS
SELECT id, tok
FROM tmp_mapped
WHERE tok NOT IN ('de','la','el','los','las','y','en','del','al','');
-- select * from tmp_filtered

-- Firma = tokens únicos ordenados
CREATE TEMPORARY TABLE tmp_signature
DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AS
SELECT id,
       GROUP_CONCAT(DISTINCT tok ORDER BY tok SEPARATOR ' ') AS firma
FROM tmp_filtered
GROUP BY id;
-- select * from tmp_signature

-- Elegir canónico: ID menor por firma (cambia ORDER BY si prefieres "texto más largo")
CREATE TEMPORARY TABLE tmp_pick
DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AS
SELECT
  s.firma,
  l.id,
  ROW_NUMBER() OVER (PARTITION BY s.firma ORDER BY l.id) AS r
FROM tmp_signature s
JOIN locations l ON l.id = s.id;
-- select * from tmp_pick

-- Mapeo final id -> canónico + textos canónicos
CREATE TEMPORARY TABLE t_map
DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AS
SELECT s.id,
       p.id AS canonical_id,
       lc.place_name       AS place_name_c,
       lc.street_address   AS street_address_c,
       lc.address_locality AS address_locality_c
FROM tmp_signature s
JOIN (SELECT firma, id FROM tmp_pick WHERE r = 1) p USING (firma)
JOIN locations lc ON lc.id = p.id;
-- select * from t_map where id in (672,673,674,675,723)
-- select * from t_map where id in (439,440,441)


-- (Opcional) inspecciona
SELECT canonical_id, COUNT(*) AS filas
FROM t_map
GROUP BY canonical_id
HAVING COUNT(*) > 1
ORDER BY filas DESC
LIMIT 20;







