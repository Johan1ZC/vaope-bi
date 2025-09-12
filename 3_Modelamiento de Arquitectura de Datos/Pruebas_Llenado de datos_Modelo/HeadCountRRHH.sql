use dwh_dev;

SELECT f.FechaID,
       COUNT(*) AS HeadcountDia
FROM DimFecha f
JOIN DimEmpleado e
  ON e.FecIngreso <= f.Fecha
 AND (e.FecCese  IS NULL)
GROUP BY f.FechaID order by 1 desc;


select fecIngreso,count(*) Q from DimEmpleado
where FecCese  IS NULL
group by fecIngreso order by 1 desc




SELECT DATE_FORMAT(df.Fecha,'%Y-%m') AS Mes,
       SUM(CASE WHEN er.TipoEstado IN ('Alta','Reingreso') THEN 1 ELSE 0 END) AS Altas,
       SUM(CASE WHEN er.TipoEstado IN ('Baja','Cese')     THEN 1 ELSE 0 END) AS Bajas
FROM FactEventosRRHH fe
JOIN DimFecha df     ON df.FechaID = fe.FechaID
JOIN DimEstadosRRHH er ON er.EstadoID = fe.EstadoID
GROUP BY DATE_FORMAT(df.Fecha,'%Y-%m');


SELECT FechaID,
       SUM(CASE WHEN Asistio=0 THEN 1 ELSE 0 END) AS Ausentes,
       COUNT(*) AS Registros
FROM FactAsistencia
GROUP BY FechaID;