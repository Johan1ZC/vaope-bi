-- ==== TABLAS DIM ====
CREATE TABLE DimFecha (
  FechaID     INT NOT NULL,
  Fecha       DATE NOT NULL,
  Anio        INT,
  Mes         INT,
  Trimestre   INT,
  DiaSemana   VARCHAR(10),
  PRIMARY KEY (FechaID)
);

CREATE TABLE DimUbicacion (
  UbicacionID  INT NOT NULL,
  Pais         VARCHAR(50)  NOT NULL,
  Departamento VARCHAR(100) NOT NULL,
  Provincia    VARCHAR(100) NOT NULL,
  Distrito     VARCHAR(100) NOT NULL,
  PRIMARY KEY (UbicacionID),
  UNIQUE (Pais, Departamento, Provincia, Distrito)
);

CREATE TABLE DimUsuarios (
  UsuarioID    INT NOT NULL,
  CanalOrigen  VARCHAR(50),
  Plataforma   VARCHAR(50),
  UbicacionID  INT,
  PRIMARY KEY (UsuarioID)
);

CREATE TABLE DimTiposEntrada (
  TipoEntradaID INT NOT NULL,
  Descripcion   VARCHAR(50),
  EsCortesia    SMALLINT,      -- (0/1)
  PRIMARY KEY (TipoEntradaID)
);

CREATE TABLE DimTiposGasto (
  TipoGastoID  INT NOT NULL,
  NombreGasto  VARCHAR(50),
  PRIMARY KEY (TipoGastoID)
);

CREATE TABLE DimEquiposRRHH (
  EquipoID     INT NOT NULL,
  NombreEquipo VARCHAR(50),
  Area         VARCHAR(50),
  PRIMARY KEY (EquipoID)
);

CREATE TABLE DimTiposIncidencia (
  TipoIncidenciaID INT NOT NULL,
  Descripcion      VARCHAR(100),
  PRIMARY KEY (TipoIncidenciaID)
);

CREATE TABLE DimCanal (
  CanalID     INT NOT NULL,
  NombreCanal VARCHAR(50),
  PRIMARY KEY (CanalID)
);

CREATE TABLE DimEventos (
  EventoID     INT NOT NULL,
  UbicacionID  INT,
  NombreEvento VARCHAR(100),
  PRIMARY KEY (EventoID)
);

CREATE TABLE DimOrganizadores (
  OrganizadorID INT NOT NULL,
  Nombre        VARCHAR(100),
  TipoOrg       VARCHAR(50),
  PRIMARY KEY (OrganizadorID)
);

CREATE TABLE BridgeEventoOrganizador (
  EventoID      INT NOT NULL,
  OrganizadorID INT NOT NULL,
  PRIMARY KEY (EventoID, OrganizadorID)
);

-- ==== TABLAS FACT ====
CREATE TABLE FactVentas (
  VentaID        BIGINT NOT NULL,
  FechaID        INT NOT NULL,
  EventoID       INT NOT NULL,
  UsuarioID      INT NOT NULL,
  TipoEntradaID  INT NOT NULL,
  Cantidad       INT,
  PrecioUnitario DECIMAL(10,2),
  TotalVenta     DECIMAL(12,2),
  PRIMARY KEY (VentaID)
);

CREATE TABLE FactEgresos (
  EgresoID     BIGINT NOT NULL,
  FechaID      INT NOT NULL,
  EventoID     INT NOT NULL,
  TipoGastoID  INT NOT NULL,
  Monto        DECIMAL(12,2),
  Descripcion  VARCHAR(200),
  PRIMARY KEY (EgresoID)
);

CREATE TABLE FactRRHH (
  RRHHID            BIGINT NOT NULL,
  FechaID           INT NOT NULL,
  EquipoID          INT NOT NULL,
  CantTrabajadores  INT,
  RotacionPct       DECIMAL(5,2),
  PRIMARY KEY (RRHHID)
);

CREATE TABLE FactPosicionamiento (
  PosicionID      BIGINT NOT NULL,
  FechaID         INT NOT NULL,
  UbicacionID     INT NOT NULL,
  CanalID         INT NOT NULL,
  NuevosUsuarios  INT,
  SeguidoresRedes INT,
  MarketSharePct  DECIMAL(5,2),
  PRIMARY KEY (PosicionID)
);

CREATE TABLE FactIncidencias (
  IncidenciaID       BIGINT NOT NULL,
  FechaID            INT NOT NULL,
  EventoID           INT NOT NULL,
  TipoIncidenciaID   INT NOT NULL,
  TotalIncidencias   INT,
  Activas            INT,
  Resueltas          INT,
  TiempoPromedioRec  DECIMAL(10,2),
  PRIMARY KEY (IncidenciaID)
);

CREATE TABLE FactEventos (
  RegistroID    BIGINT NOT NULL,
  FechaID       INT NOT NULL,
  EventoID      INT NOT NULL,
  OrganizadorID INT NOT NULL,
  TotalEventos  INT,
  PRIMARY KEY (RegistroID)
);

-- ==== RELACIONES ====
ALTER TABLE DimUsuarios
  ADD FOREIGN KEY (UbicacionID) REFERENCES DimUbicacion (UbicacionID);

ALTER TABLE DimEventos
  ADD FOREIGN KEY (UbicacionID) REFERENCES DimUbicacion (UbicacionID);

ALTER TABLE BridgeEventoOrganizador
  ADD FOREIGN KEY (EventoID) REFERENCES DimEventos (EventoID);

ALTER TABLE BridgeEventoOrganizador
  ADD FOREIGN KEY (OrganizadorID) REFERENCES DimOrganizadores (OrganizadorID);

ALTER TABLE FactVentas
  ADD FOREIGN KEY (FechaID)       REFERENCES DimFecha (FechaID);
ALTER TABLE FactVentas
  ADD FOREIGN KEY (EventoID)      REFERENCES DimEventos (EventoID);
ALTER TABLE FactVentas
  ADD FOREIGN KEY (UsuarioID)     REFERENCES DimUsuarios (UsuarioID);
ALTER TABLE FactVentas
  ADD FOREIGN KEY (TipoEntradaID) REFERENCES DimTiposEntrada (TipoEntradaID);

ALTER TABLE FactEgresos
  ADD FOREIGN KEY (FechaID)     REFERENCES DimFecha (FechaID);
ALTER TABLE FactEgresos
  ADD FOREIGN KEY (EventoID)    REFERENCES DimEventos (EventoID);
ALTER TABLE FactEgresos
  ADD FOREIGN KEY (TipoGastoID) REFERENCES DimTiposGasto (TipoGastoID);

ALTER TABLE FactRRHH
  ADD FOREIGN KEY (FechaID)  REFERENCES DimFecha (FechaID);
ALTER TABLE FactRRHH
  ADD FOREIGN KEY (EquipoID) REFERENCES DimEquiposRRHH (EquipoID);

ALTER TABLE FactPosicionamiento
  ADD FOREIGN KEY (FechaID)     REFERENCES DimFecha (FechaID);
ALTER TABLE FactPosicionamiento
  ADD FOREIGN KEY (UbicacionID) REFERENCES DimUbicacion (UbicacionID);
ALTER TABLE FactPosicionamiento
  ADD FOREIGN KEY (CanalID)     REFERENCES DimCanal (CanalID);

ALTER TABLE FactIncidencias
  ADD FOREIGN KEY (FechaID)          REFERENCES DimFecha (FechaID);
ALTER TABLE FactIncidencias
  ADD FOREIGN KEY (EventoID)         REFERENCES DimEventos (EventoID);
ALTER TABLE FactIncidencias
  ADD FOREIGN KEY (TipoIncidenciaID) REFERENCES DimTiposIncidencia (TipoIncidenciaID);

ALTER TABLE FactEventos
  ADD FOREIGN KEY (FechaID)       REFERENCES DimFecha (FechaID);
ALTER TABLE FactEventos
  ADD FOREIGN KEY (EventoID)      REFERENCES DimEventos (EventoID);
ALTER TABLE FactEventos
  ADD FOREIGN KEY (OrganizadorID) REFERENCES DimOrganizadores (OrganizadorID);
