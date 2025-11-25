SELECT * FROM colaborativa_etl.Dimusuario
order by 1 desc;

SELECT DISTINCT s.usuarioID
-- select count(1)
FROM colaborativa_etl.FactVentasWeb s;


SELECT * FROM colaborativa_etl.Dimusuario
order by 1 desc;


SELECT DISTINCT s.usuarioID,d.usuarioID, 1
FROM colaborativa_etl.FactVentasWeb s
LEFT JOIN colaborativa_etl.Dimusuario d ON d.usuarioID = s.usuarioID
WHERE s.usuarioID IS NOT NULL
  AND d.usuarioID IS NULL;
  
  
  SELECT DISTINCT s.usuarioID,d.usuarioID, 1
FROM colaborativa_etl.FactVentasWeb s
RIGHT JOIN colaborativa_etl.Dimusuario d ON d.usuarioID = s.usuarioID
WHERE d.usuarioID IS NULL
  AND d.usuarioID IS NOT NULL;
  
  
  use colaborativa_etl;
  
  -- 1) IDs duplicados en Dimusuario
SELECT usuarioID, COUNT(*) c
FROM Dimusuario
GROUP BY usuarioID
HAVING c > 1;

-- 2) Valores inválidos de esActivo (solo 0/1) o NULLs inesperados
SELECT *
FROM Dimusuario
WHERE esActivo NOT IN (0,1) OR esActivo IS NULL;

-- 3) created_at nulo o en el futuro
SELECT *
FROM Dimusuario
WHERE created_at IS NULL
   OR created_at > NOW();

-- 4) updated_at antes que created_at (inconsistencia)
SELECT *
FROM Dimusuario
WHERE updated_at IS NOT NULL
  AND created_at IS NOT NULL
  AND updated_at < created_at;

-- 5) Ventas con usuario inexistente (huérfanas respecto a la FK)
SELECT f.usuarioID, COUNT(*) n_ventas
FROM FactVentasWeb f
LEFT JOIN Dimusuario d ON d.usuarioID = f.usuarioID
WHERE f.usuarioID IS NOT NULL
  AND d.usuarioID IS NULL
GROUP BY f.usuarioID;

-- 6) Revisa estados 0/1 por fecha (opcional, para auditoría)
SELECT esActivo, DATE(created_at) dia, COUNT(*) n
FROM Dimusuario
GROUP BY esActivo, DATE(created_at)
ORDER BY dia DESC, esActivo DESC;
