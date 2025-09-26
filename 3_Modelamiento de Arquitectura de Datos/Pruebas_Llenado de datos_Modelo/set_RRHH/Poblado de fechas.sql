USE dw_modelizacion;

-- 1) Genera el calendario en una temporal
CREATE TEMPORARY TABLE tmp_cal (d DATE) ENGINE=MEMORY AS
WITH RECURSIVE cal(d) AS (
  SELECT DATE('2020-01-01')
  UNION ALL
  SELECT DATE_ADD(d, INTERVAL 1 DAY) FROM cal WHERE d < '2030-12-31'
)
SELECT d FROM cal;
-- select * from tmp_cal

-- Si quieres abreviar nombres de día en español:
SET lc_time_names = 'es_ES';

-- 2) Inserta sólo las fechas que no existan aún en DimFecha
-- truncate table dw_modelizacion.DimFecha
INSERT INTO dw_modelizacion.DimFecha
  (FechaID, Fecha, Anio, Mes, Trimestre, DiaSemana)
SELECT
  CAST(DATE_FORMAT(c.d, '%Y%m%d') AS UNSIGNED) AS FechaID,
  c.d,
  YEAR(c.d),
  MONTH(c.d),
  QUARTER(c.d),
  DATE_FORMAT(c.d, '%a')                      -- p.ej. 'Mon' o 'lun' según lc_time_names
FROM tmp_cal c
LEFT JOIN dw_modelizacion.DimFecha f
  ON f.Fecha = c.d
WHERE f.Fecha IS NULL;
-- select * from dw_modelizacion.DimFecha

DROP TEMPORARY TABLE tmp_cal;

-- Actualizar nombre de dias en Español
SET lc_time_names = 'es_ES';

UPDATE dw_modelizacion.DimFecha
SET DiaSemana = DATE_FORMAT(Fecha, '%a')   -- abreviado
WHERE FechaID BETWEEN 20200101 AND 20301231;   


/* Agregar nombre de mes
ALTER TABLE dw_modelizacion.DimFecha ADD COLUMN NombreMes VARCHAR(15) NULL;
SET lc_time_names = 'es_ES';
UPDATE dw_modelizacion.DimFecha SET NombreMes = DATE_FORMAT(Fecha, '%M');
*/


-- VALIDACION

-- Validar fecha inicio y fecha fin con nro de dias o filas:
SELECT MIN(Fecha) min_f, MAX(Fecha) max_f, COUNT(*) filas
FROM dw_modelizacion.DimFecha;


-- Validacion de fechas faltantes
SELECT COUNT(*) FROM (
  SELECT DATE('2020-01-01') + INTERVAL seq DAY AS d
  FROM (
    SELECT 0 seq UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
  ) u1
  CROSS JOIN (
    SELECT 0*10 t UNION ALL SELECT 1*10 UNION ALL SELECT 2*10 UNION ALL SELECT 3*10 UNION ALL SELECT 4*10
    UNION ALL SELECT 5*10 UNION ALL SELECT 6*10 UNION ALL SELECT 7*10 UNION ALL SELECT 8*10 UNION ALL SELECT 9*10
  ) u2
  -- (extiende el generador si necesitas más rango)
) gen
LEFT JOIN dw_modelizacion.DimFecha f ON f.Fecha = gen.d
WHERE gen.d BETWEEN '2020-01-01' AND '2020-01-31'  -- ajusta rango para test
  AND f.Fecha IS NULL;
  
-- Duplicados (no debería haber por el índice único)
SELECT Fecha, COUNT(*) c FROM dw_modelizacion.DimFecha GROUP BY Fecha HAVING c>1;

-- Spot check
SELECT * FROM dw_modelizacion.DimFecha ORDER BY Fecha LIMIT 7;

  
-- Eliminar columna de tabla:  
 -- alter table dw_modelizacion.DimFecha drop column   nombreMes


