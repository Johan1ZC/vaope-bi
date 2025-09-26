USE dwh_dev;

-- =========================
-- 1) CATALOGOS BÁSICOS
-- =========================

-- Estados RRHH (Alta, Baja, Cambio, etc.)
INSERT INTO DimEstadosRRHH (TipoEstado, Motivo)
VALUES ('Alta','Ingreso'),
       ('Baja','Renuncia'),
       ('Baja','Despido'),
       ('CambioEstructura','Traslado'),
       ('CambioPuesto','Promoción'),
       ('Licencia','Permiso')
ON DUPLICATE KEY UPDATE Motivo = VALUES(Motivo);

-- Estructura (24 equipos: 6 áreas x 2 subáreas x 2 equipos)
INSERT INTO DimEstructura (Area, SubArea, Equipo)
VALUES
('Ventas','Minorista','Equipo A'),('Ventas','Minorista','Equipo B'),
('Ventas','Corporativa','Equipo A'),('Ventas','Corporativa','Equipo B'),
('Operaciones','Campo','Equipo A'),('Operaciones','Campo','Equipo B'),
('Operaciones','Backoffice','Equipo A'),('Operaciones','Backoffice','Equipo B'),
('Marketing','Digital','Equipo A'),('Marketing','Digital','Equipo B'),
('Marketing','BTL','Equipo A'),('Marketing','BTL','Equipo B'),
('TI','Desarrollo','Equipo A'),('TI','Desarrollo','Equipo B'),
('TI','Soporte','Equipo A'),('TI','Soporte','Equipo B'),
('Finanzas','Contabilidad','Equipo A'),('Finanzas','Contabilidad','Equipo B'),
('Finanzas','Tesorería','Equipo A'),('Finanzas','Tesorería','Equipo B'),
('RRHH','Selección','Equipo A'),('RRHH','Selección','Equipo B'),
('RRHH','Administración','Equipo A'),('RRHH','Administración','Equipo B')
ON DUPLICATE KEY UPDATE Equipo = VALUES(Equipo);

-- Turnos
INSERT INTO DimTurno (NombreTurno, HoraEntradaPlan, HoraSalidaPlan, ToleranciaMin)
VALUES ('Administrativo','08:30:00','17:30:00',10),
       ('Mañana','09:00:00','18:00:00',10),
       ('Tarde','13:00:00','22:00:00',10),
       ('Noche','22:00:00','07:00:00',10)
ON DUPLICATE KEY UPDATE HoraSalidaPlan = VALUES(HoraSalidaPlan);

-- =========================
-- 2) EMPLEADOS (120 filas)
-- =========================
INSERT INTO DimEmpleado
  (DNI, Nombre, Apellidos, Genero, FecNacimiento, FecIngreso, FecCese, TipoContrato, Puesto)
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n+1 FROM seq WHERE n < 120
)
SELECT
  CONCAT('DNI', LPAD(n,8,'0'))                                 AS DNI,
  CONCAT('Empleado ', LPAD(n,3,'0'))                           AS Nombre,
  CONCAT('Apellido ', LPAD(n,3,'0'))                           AS Apellidos,
  CASE WHEN n % 2 = 0 THEN 'M' ELSE 'F' END                    AS Genero,
  DATE_ADD('1980-01-01', INTERVAL MOD(n*97, 9000) DAY)         AS FecNacimiento,  -- 1980..2004
  DATE_ADD('2023-01-01', INTERVAL MOD(n*37, 650) DAY)          AS FecIngreso,     -- 2023..2024
  CASE WHEN n % 7 = 0
       THEN DATE_ADD(DATE_ADD('2023-01-01', INTERVAL MOD(n*37, 650) DAY),
                     INTERVAL (100 + MOD(n*11, 400)) DAY)
       ELSE NULL END                                           AS FecCese,        -- ~15% con cese
  CASE
    WHEN n % 10 < 6 THEN 'Indefinido'
    WHEN n % 10 < 9 THEN 'Temporal'
    ELSE 'Prácticas'
  END                                                          AS TipoContrato,
  CASE
    WHEN n % 5 = 0 THEN 'Analista'
    WHEN n % 5 = 1 THEN 'Ejecutivo'
    WHEN n % 5 = 2 THEN 'Asistente'
    WHEN n % 5 = 3 THEN 'Jefe'
    ELSE 'Coordinador'
  END                                                          AS Puesto
FROM seq;


-- =========================
-- 3) EVENTOS RRHH
-- =========================

-- IDs de estados útiles (cacheados en variables)
SET @id_alta  := (SELECT EstadoID FROM DimEstadosRRHH WHERE TipoEstado='Alta' LIMIT 1);
SET @id_baja1 := (SELECT EstadoID FROM DimEstadosRRHH WHERE TipoEstado='Baja' AND Motivo='Renuncia' LIMIT 1);
SET @id_cambio:= (SELECT EstadoID FROM DimEstadosRRHH WHERE TipoEstado='CambioEstructura' LIMIT 1);

-- Alta para todos los empleados (estructura inicial según EmpleadoID)
INSERT INTO FactEventosRRHH (FechaID, EmpleadoID, EstadoID, EstructuraDesdeID, EstructuraHastaID, Fuente)
SELECT
  f.FechaID,
  e.EmpleadoID,
  @id_alta AS EstadoID,
  NULL     AS EstructuraDesdeID,
  ((e.EmpleadoID-1) % (SELECT COUNT(*) FROM DimEstructura)) + 1 AS EstructuraHastaID,
  'SEED'
FROM DimEmpleado e
JOIN DimFecha f ON f.Fecha = e.FecIngreso
LEFT JOIN FactEventosRRHH x
  ON x.EmpleadoID = e.EmpleadoID AND x.EstadoID=@id_alta AND x.FechaID=f.FechaID
WHERE x.EventoRrhhID IS NULL;

-- Cambios de estructura (~20% de empleados) a los 90 días
INSERT INTO FactEventosRRHH (FechaID, EmpleadoID, EstadoID, EstructuraDesdeID, EstructuraHastaID, Fuente)
SELECT
  fc.FechaID,
  e.EmpleadoID,
  @id_cambio,
  ((e.EmpleadoID-1) % (SELECT COUNT(*) FROM DimEstructura)) + 1 AS EstrDesde,
  (((e.EmpleadoID-1) % (SELECT COUNT(*) FROM DimEstructura)) + 1) % (SELECT COUNT(*) FROM DimEstructura) + 1 AS EstrHasta,
  'SEED'
FROM DimEmpleado e
JOIN DimFecha fc
  ON fc.Fecha = DATE_ADD(e.FecIngreso, INTERVAL 90 DAY)
WHERE e.EmpleadoID % 5 = 0;  -- ~20%

-- Bajas para quienes tienen FecCese
INSERT INTO FactEventosRRHH (FechaID, EmpleadoID, EstadoID, EstructuraDesdeID, EstructuraHastaID, Fuente)
SELECT
  fb.FechaID,
  e.EmpleadoID,
  @id_baja1,
  ((e.EmpleadoID-1) % (SELECT COUNT(*) FROM DimEstructura)) + 1,
  NULL,
  'SEED'
FROM DimEmpleado e
JOIN DimFecha fb ON fb.Fecha = e.FecCese
WHERE e.FecCese IS NOT NULL;

-- =========================
-- 4) ASISTENCIAS (últimos 5 días hábiles x 120 empleados)
-- =========================
INSERT IGNORE INTO FactAsistencia
(FechaID, EmpleadoID, TurnoID, EstructuraID, Asistio, MinTardanza, MinExtras,
 HorasTrabajadas, MinAusencia, HoraIngReal, HoraSalReal, TipoAsistencia, Fuente)
WITH base AS (
  SELECT
    d.FechaID,
    e.EmpleadoID,
    ((e.EmpleadoID-1) % (SELECT COUNT(*) FROM DimTurno)) + 1  AS TurnoID,
    ((e.EmpleadoID-1) % (SELECT COUNT(*) FROM DimEstructura)) + 1 AS EstructuraID,
    CASE WHEN MOD(CRC32(CONCAT(e.EmpleadoID,'-',d.FechaID)),10)=0 THEN 0 ELSE 1 END AS Asistio,
    CASE WHEN MOD(CRC32(CONCAT(e.EmpleadoID,'-',d.FechaID)),10)=0
         THEN 0 ELSE MOD(CRC32(CONCAT('T',e.EmpleadoID,'-',d.FechaID)),21) END AS MinTardanza,
    CASE WHEN MOD(CRC32(CONCAT(e.EmpleadoID,'-',d.FechaID,'X')),5)=0
         THEN MOD(CRC32(CONCAT('E',e.EmpleadoID,'-',d.FechaID)),61) ELSE 0 END AS MinExtras,
    CASE WHEN MOD(CRC32(CONCAT(e.EmpleadoID,'-',d.FechaID)),10)=0 THEN 480 ELSE 0 END AS MinAusencia
  FROM (
    SELECT FechaID, Fecha
    FROM DimFecha
    WHERE Fecha <= CURDATE()
      AND DAYOFWEEK(Fecha) BETWEEN 2 AND 6
    ORDER BY Fecha DESC
    LIMIT 5
  ) d
  CROSS JOIN (
    SELECT EmpleadoID
    FROM DimEmpleado
    ORDER BY EmpleadoID
    LIMIT 120
  ) e
),
calc AS (
  SELECT
    b.*,
    CASE WHEN b.Asistio=1
         THEN ADDTIME(t.HoraEntradaPlan, SEC_TO_TIME(b.MinTardanza*60))
         ELSE NULL END AS HoraIngReal,
    CASE WHEN b.Asistio=1
         THEN SUBTIME(ADDTIME(t.HoraSalidaPlan, SEC_TO_TIME(b.MinExtras*60)),
                      SEC_TO_TIME(b.MinAusencia*60))
         ELSE NULL END AS HoraSalReal
  FROM base b
  JOIN DimTurno t ON t.TurnoID = b.TurnoID
)
SELECT
  c.FechaID,
  c.EmpleadoID,
  c.TurnoID,
  c.EstructuraID,
  c.Asistio,
  c.MinTardanza,
  c.MinExtras,
  CASE
    WHEN c.Asistio=1 AND c.HoraIngReal IS NOT NULL AND c.HoraSalReal IS NOT NULL
    THEN ROUND(TIMESTAMPDIFF(MINUTE, c.HoraIngReal, c.HoraSalReal)/60, 2)
    ELSE 0
  END AS HorasTrabajadas,
  c.MinAusencia,
  c.HoraIngReal,
  c.HoraSalReal,
  CASE
    WHEN c.Asistio=0 THEN 'FALTA'
    WHEN c.MinTardanza>0 AND c.MinExtras=0 THEN 'TARDANZA'
    WHEN c.MinExtras>0  AND c.MinTardanza=0 THEN 'EXTRA'
    WHEN c.MinTardanza>0 AND c.MinExtras>0 THEN 'TAR+EXT'
    ELSE 'NORMAL'
  END AS TipoAsistencia,
  'SEED' AS Fuente
FROM calc c;




-- =========================
-- 6) COMPROBACIONES RÁPIDAS
-- =========================
-- Al menos 300 filas totales? (sólo FactAsistencia ya supera)
SELECT 'DimEmpleado' AS tabla, COUNT(*) AS filas FROM DimEmpleado
UNION ALL
SELECT 'FactAsistencia', COUNT(*) FROM FactAsistencia
UNION ALL
SELECT 'FactEventosRRHH', COUNT(*) FROM FactEventosRRHH





