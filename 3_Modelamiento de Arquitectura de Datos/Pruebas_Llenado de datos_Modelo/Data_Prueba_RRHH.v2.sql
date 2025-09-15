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

-- ================================================================
-- 2) EMPLEADOS (300 filas, con EstructuraID asignado)
-- ================================================================

INSERT INTO DimEmpleado
  (DNI, Nombre, Apellidos, Genero, FecNacimiento, FecIngreso, FecCese,
   TipoContrato, Puesto, EstructuraID)
   WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n+1 FROM seq WHERE n < 300
)
SELECT
  CONCAT('DNI', LPAD(n,8,'0'))                                 AS DNI,
  CONCAT('Empleado ', LPAD(n,3,'0'))                           AS Nombre,
  CONCAT('Apellido ', LPAD(n,3,'0'))                           AS Apellidos,
  CASE WHEN n % 2 = 0 THEN 'M' ELSE 'F' END                    AS Genero,
  DATE_ADD('1985-01-01', INTERVAL MOD(n*79, 12000) DAY)        AS FecNacimiento,  -- 1985..2018 aprox
  DATE_ADD('2023-01-01', INTERVAL MOD(n*37, 650) DAY)          AS FecIngreso,     -- 2023..2024
  CASE WHEN n % 7 = 0
       THEN DATE_ADD(DATE_ADD('2023-01-01', INTERVAL MOD(n*37, 650) DAY),
                     INTERVAL (120 + MOD(n*11, 420)) DAY)
       ELSE NULL END                                           AS FecCese,        -- ~14-15% con cese
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
  END                                                          AS Puesto,
  ((n-1) % (SELECT COUNT(*) FROM DimEstructura)) + 1           AS EstructuraID
FROM seq
ON DUPLICATE KEY UPDATE
  Nombre = VALUES(Nombre),
  Apellidos = VALUES(Apellidos),
  Genero = VALUES(Genero),
  FecNacimiento = VALUES(FecNacimiento),
  FecIngreso = VALUES(FecIngreso),
  FecCese = VALUES(FecCese),
  TipoContrato = VALUES(TipoContrato),
  Puesto = VALUES(Puesto),
  EstructuraID = VALUES(EstructuraID);


-- ================================================================
-- 3) EVENTOS RRHH (ALTAS, CAMBIOS, BAJAS)
-- ================================================================
-- Cache de IDs de estado
SET @id_alta   := (SELECT EstadoID FROM DimEstadosRRHH WHERE TipoEstado='Alta' LIMIT 1);
SET @id_baja   := (SELECT EstadoID FROM DimEstadosRRHH WHERE TipoEstado='Baja' AND Motivo='Renuncia' LIMIT 1);
SET @id_cambio := (SELECT EstadoID FROM DimEstadosRRHH WHERE TipoEstado='CambioEstructura' LIMIT 1);

-- 3.1 Alta para todos (en su fecha de ingreso)
INSERT INTO FactEventosRRHH (FechaID, EmpleadoID, EstadoID, EstructuraDesdeID, EstructuraHastaID, Fuente)
SELECT
  df.FechaID,
  e.EmpleadoID,
  @id_alta AS EstadoID,
  NULL     AS EstructuraDesdeID,
  e.EstructuraID AS EstructuraHastaID,
  'SEED'
FROM DimEmpleado e
JOIN DimFecha df ON df.Fecha = e.FecIngreso
LEFT JOIN FactEventosRRHH x
  ON x.EmpleadoID = e.EmpleadoID AND x.EstadoID = @id_alta AND x.FechaID = df.FechaID
WHERE x.EventoRrhhID IS NULL;

-- 3.2 Cambio de estructura (~20% a los 90 días de ingreso)
INSERT INTO FactEventosRRHH (FechaID, EmpleadoID, EstadoID, EstructuraDesdeID, EstructuraHastaID, Fuente)
SELECT
  dfc.FechaID,
  e.EmpleadoID,
  @id_cambio,
  e.EstructuraID AS EstructuraDesdeID,
  (
    ((e.EmpleadoID-1) % (SELECT COUNT(*) FROM DimEstructura)) + 2
  ) % (SELECT COUNT(*) FROM DimEstructura) + 1 AS EstructuraHastaID,
  'SEED'
FROM DimEmpleado e
JOIN DimFecha dfc
  ON dfc.Fecha = DATE_ADD(e.FecIngreso, INTERVAL 90 DAY)
WHERE e.EmpleadoID % 5 = 0;  -- ~20%

-- 3.3 Bajas (para quienes tienen FecCese)
INSERT INTO FactEventosRRHH (FechaID, EmpleadoID, EstadoID, EstructuraDesdeID, EstructuraHastaID, Fuente)
SELECT
  dfb.FechaID,
  e.EmpleadoID,
  @id_baja,
  e.EstructuraID,
  NULL,
  'SEED'
FROM DimEmpleado e
JOIN DimFecha dfb ON dfb.Fecha = e.FecCese
WHERE e.FecCese IS NOT NULL;


-- ================================================================
-- 4) ASISTENCIAS (10 días hábiles recientes × 300 empleados)
--    Incluye NombreTurno y horarios planeados en la propia Fact
-- ================================================================
INSERT IGNORE INTO FactAsistencia
(FechaID, EmpleadoID, EstructuraID, Asistio, MinTardanza, MinExtras,
 HorasTrabajadas, MinAusencia, HoraIngReal, HoraSalReal, TipoAsistencia,
 NombreTurno, HoraEntradaPlan, HoraSalidaPlan, Fuente)
WITH ultimos_dias AS (
  SELECT FechaID, Fecha
  FROM DimFecha
  WHERE Fecha <= CURDATE()
    AND DAYOFWEEK(Fecha) BETWEEN 2 AND 6  -- Lunes..Viernes
  ORDER BY Fecha DESC
  LIMIT 10
),
base AS (
  SELECT
    d.FechaID,
    d.Fecha,
    e.EmpleadoID,
    e.EstructuraID,
    ((e.EmpleadoID - 1) % 4) + 1 AS TurnoIdx,
    CASE WHEN MOD(CRC32(CONCAT(e.EmpleadoID,'-',d.FechaID)),10)=0 THEN 0 ELSE 1 END AS Asistio,
    CASE WHEN MOD(CRC32(CONCAT(e.EmpleadoID,'-',d.FechaID)),10)=0
         THEN 0 ELSE MOD(CRC32(CONCAT('T',e.EmpleadoID,'-',d.FechaID)),21) END AS MinTardanza,
    CASE WHEN MOD(CRC32(CONCAT(e.EmpleadoID,'-',d.FechaID,'X')),5)=0
         THEN MOD(CRC32(CONCAT('E',e.EmpleadoID,'-',d.FechaID)),61) ELSE 0 END AS MinExtras,
    CASE WHEN MOD(CRC32(CONCAT(e.EmpleadoID,'-',d.FechaID)),10)=0 THEN 480 ELSE 0 END AS MinAusencia
  FROM ultimos_dias d
  CROSS JOIN (
    SELECT EmpleadoID, EstructuraID
    FROM DimEmpleado
    ORDER BY EmpleadoID
    LIMIT 300
  ) e
),
turnos AS (
  SELECT
    b.*,
    CASE b.TurnoIdx
      WHEN 1 THEN 'Administrativo'
      WHEN 2 THEN 'Mañana'
      WHEN 3 THEN 'Tarde'
      ELSE 'Noche'
    END AS NombreTurno,
    CASE b.TurnoIdx
      WHEN 1 THEN '08:30:00'
      WHEN 2 THEN '09:00:00'
      WHEN 3 THEN '13:00:00'
      ELSE '22:00:00'
    END AS HoraEntradaPlan,
    CASE b.TurnoIdx
      WHEN 1 THEN '17:30:00'
      WHEN 2 THEN '18:00:00'
      WHEN 3 THEN '22:00:00'
      ELSE '07:00:00'
    END AS HoraSalidaPlan
  FROM base b
),
calc AS (
  SELECT
    t.*,
    CASE WHEN t.Asistio=1
         THEN ADDTIME(t.HoraEntradaPlan, SEC_TO_TIME(t.MinTardanza*60))
         ELSE NULL END AS HoraIngReal,
    CASE WHEN t.Asistio=1
         THEN SUBTIME(ADDTIME(t.HoraSalidaPlan, SEC_TO_TIME(t.MinExtras*60)),
                      SEC_TO_TIME(t.MinAusencia*60))
         ELSE NULL END AS HoraSalReal
  FROM turnos t
)
SELECT
  c.FechaID,
  c.EmpleadoID,
  c.EstructuraID,
  c.Asistio,
  c.MinTardanza,
  c.MinExtras,
  CASE
    WHEN c.Asistio=1 AND c.HoraIngReal IS NOT NULL AND c.HoraSalReal IS NOT NULL
    THEN ROUND( GREATEST(0,
              TIME_TO_SEC(SUBTIME(c.HoraSalReal, c.HoraIngReal)) / 3600 ), 2)
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
  c.NombreTurno,
  c.HoraEntradaPlan,
  c.HoraSalidaPlan,
  'SEED' AS Fuente
FROM calc c;

-- ================================================================
-- 5) CHEQUEOS RÁPIDOS
-- ================================================================
SELECT 'DimEstructura' AS tabla, COUNT(*) AS filas FROM DimEstructura
UNION ALL SELECT 'DimEmpleado', COUNT(*) FROM DimEmpleado
UNION ALL SELECT 'DimEstadosRRHH', COUNT(*) FROM DimEstadosRRHH
UNION ALL SELECT 'FactEventosRRHH', COUNT(*) FROM FactEventosRRHH
UNION ALL SELECT 'FactAsistencia', COUNT(*) FROM FactAsistencia;

-- Un par de sanity checks:
-- ¿Asistencias únicas por FechaID–EmpleadoID?
SELECT 'duplicados_asistencia' AS test, COUNT(*) AS duplicados
FROM (
  SELECT FechaID, EmpleadoID, COUNT(*) c
  FROM FactAsistencia
  GROUP BY FechaID, EmpleadoID
  HAVING c > 1
) t;

-- ¿Hay empleados con Alta registrada?
SELECT COUNT(*) AS altas
FROM FactEventosRRHH fe
JOIN DimEstadosRRHH de ON de.EstadoID = fe.EstadoID AND de.TipoEstado='Alta';





