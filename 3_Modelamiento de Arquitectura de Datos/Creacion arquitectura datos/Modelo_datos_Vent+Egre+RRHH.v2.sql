/* ================================================================
   RRHH – Modelo DW (MySQL 8.0, InnoDB, utf8mb4)
   ================================================================= */

/* ================================================================
   RRHH – Modelo DW (MySQL 8.0, InnoDB, utf8mb4)
   ================================================================= */

USE dwh_dev;

/* --------------------------- DIMENSIONES --------------------------- */

CREATE TABLE IF NOT EXISTS DimEstructura (
  EstructuraID INT           NOT NULL AUTO_INCREMENT,
  Area         VARCHAR(150)  NOT NULL,
  SubArea      VARCHAR(150)  NULL,
  Equipo       VARCHAR(150)  NULL,
  PRIMARY KEY (EstructuraID),
  UNIQUE KEY uq_estructura (Area, SubArea, Equipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS DimEmpleado (
  EmpleadoID     INT            NOT NULL AUTO_INCREMENT,
  DNI            VARCHAR(25)    NULL,
  Nombre         VARCHAR(250)   NULL,
  Apellidos      VARCHAR(250)   NULL,
  Genero         VARCHAR(150)   NULL,
  FecNacimiento  DATE           NULL,
  FecIngreso     DATE           NULL,
  FecCese        DATE           NULL,
  TipoContrato   VARCHAR(150)   NULL,
  Puesto         VARCHAR(150)   NULL,
  EstructuraID   INT            NULL,   -- FK hacia DimEstructura (nuevo campo)
  FechaCarga     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (EmpleadoID),
  UNIQUE KEY uq_empleado_empid_dni (DNI),
  KEY ix_empl_estructura (EstructuraID),
  CONSTRAINT fk_dimestr_dimempleado FOREIGN KEY (EstructuraID) REFERENCES DimEstructura(EstructuraID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS DimEstadosRRHH (
  EstadoID     INT           NOT NULL AUTO_INCREMENT,
  TipoEstado   VARCHAR(150)  NOT NULL,
  Motivo       VARCHAR(150)  NULL,
  PRIMARY KEY (EstadoID),
  UNIQUE KEY uq_estado_tipo_motivo (TipoEstado, Motivo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS DimTurno (
  TurnoID         INT           NOT NULL AUTO_INCREMENT,
  NombreTurno     VARCHAR(150)  NOT NULL,
  HoraEntradaPlan TIME          NOT NULL,
  HoraSalidaPlan  TIME          NOT NULL,
  ToleranciaMin   INT           NOT NULL DEFAULT 0,
  PRIMARY KEY (TurnoID),
  UNIQUE KEY uq_turno_nombre (NombreTurno)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* ----------------------------- FACTS ------------------------------ */

CREATE TABLE IF NOT EXISTS FactAsistencia (
  AsistenciaID     BIGINT         NOT NULL AUTO_INCREMENT,
  FechaID          INT            NOT NULL,     -- FK DimFecha
  EmpleadoID       INT            NOT NULL,     -- FK DimEmpleado
  TurnoID          INT            NULL,         -- FK DimTurno
  EstructuraID     INT            NULL,         -- FK DimEstructura
  Asistio          TINYINT(1)     NOT NULL DEFAULT 0,
  MinTardanza      INT            NOT NULL DEFAULT 0,
  MinExtras        INT            NOT NULL DEFAULT 0,
  HorasTrabajadas  DECIMAL(12,2)  NULL,
  MinAusencia      INT            NOT NULL DEFAULT 0,
  HoraIngReal      TIME           NULL,
  HoraSalReal      TIME           NULL,
  TipoAsistencia   VARCHAR(150)   NULL,
  Fuente           VARCHAR(100)   NULL,
  FechaCarga       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (AsistenciaID),
  UNIQUE KEY uq_asistencia_dia_emp (FechaID, EmpleadoID),
  KEY ix_asist_emp (EmpleadoID),
  KEY ix_asist_fecha (FechaID),
  KEY ix_asist_turno (TurnoID),
  KEY ix_asist_estr (EstructuraID),
  CONSTRAINT fk_dimfecha_factasist   FOREIGN KEY (FechaID)      REFERENCES DimFecha(FechaID),
  CONSTRAINT fk_dimempl_factasist    FOREIGN KEY (EmpleadoID)   REFERENCES DimEmpleado(EmpleadoID),
  CONSTRAINT fk_dimturn_factasist    FOREIGN KEY (TurnoID)      REFERENCES DimTurno(TurnoID),
  CONSTRAINT fk_dimestr_factasist    FOREIGN KEY (EstructuraID) REFERENCES DimEstructura(EstructuraID),
  CONSTRAINT ck_asist_no_negativos CHECK (MinTardanza>=0 AND MinExtras>=0 AND MinAusencia>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS FactEventosRRHH (
  EventoRrhhID      BIGINT        NOT NULL AUTO_INCREMENT,
  FechaID           INT           NOT NULL,     -- FK DimFecha (fecha del evento)
  EmpleadoID        INT           NOT NULL,     -- FK DimEmpleado
  EstadoID          INT           NOT NULL,     -- FK DimEstadosRRHH
  EstructuraDesdeID INT           NULL,         -- FK DimEstructura
  EstructuraHastaID INT           NULL,         -- FK DimEstructura
  Fuente            VARCHAR(100)  NULL,
  FechaCarga        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (EventoRrhhID),
  KEY ix_evt_fecha_emp (FechaID, EmpleadoID),
  KEY ix_evt_estado (EstadoID),
  CONSTRAINT fk_dimfecha_facteventrrhh    FOREIGN KEY (FechaID)           REFERENCES DimFecha(FechaID),
  CONSTRAINT fk_dimempl_facteventrrhh     FOREIGN KEY (EmpleadoID)        REFERENCES DimEmpleado(EmpleadoID),
  CONSTRAINT fk_dimesta_facteventrrhh     FOREIGN KEY (EstadoID)          REFERENCES DimEstadosRRHH(EstadoID),
  CONSTRAINT fk_dimestrdes_facteventrrhh  FOREIGN KEY (EstructuraDesdeID) REFERENCES DimEstructura(EstructuraID),
  CONSTRAINT fk_dimestrhast_facteventrrhh FOREIGN KEY (EstructuraHastaID) REFERENCES DimEstructura(EstructuraID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


/*
CREATE TABLE IF NOT EXISTS FactSnapShot (
  SnapShotID     BIGINT        NOT NULL AUTO_INCREMENT,
  FechaID        INT           NOT NULL,     -- FK DimFecha (día de la foto)
  EmpleadoID     INT           NOT NULL,     -- FK DimEmpleado
  EstructuraID   INT           NOT NULL,     -- FK DimEstructura
  EsActivo       TINYINT(1)    NOT NULL,     -- 1 activo ese día
  Antiguedad     INT           NULL,
  Fuente         VARCHAR(100)  NULL,
  FechaCarga     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (SnapShotID),
  UNIQUE KEY uq_snapshot_dia_emp (FechaID, EmpleadoID),  -- una fila por día y empleado
  KEY ix_snap_fecha_estr (FechaID, EstructuraID),
  CONSTRAINT fk_dimfecha_factsnaps  FOREIGN KEY (FechaID)      REFERENCES DimFecha(FechaID),
  CONSTRAINT fk_dimempl_factsnaps   FOREIGN KEY (EmpleadoID)   REFERENCES DimEmpleado(EmpleadoID),
  CONSTRAINT fk_dimestr_factsnaps   FOREIGN KEY (EstructuraID) REFERENCES DimEstructura(EstructuraID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
*/