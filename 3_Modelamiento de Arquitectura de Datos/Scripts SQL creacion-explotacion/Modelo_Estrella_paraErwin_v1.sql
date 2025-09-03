

CREATE TABLE unidadanalisis.BridgeEventoOrganizador
(
	EventoID             INT NOT NULL,
	OrganizadorID        INT NOT NULL
);



ALTER TABLE unidadanalisis.BridgeEventoOrganizador
ADD PRIMARY KEY (EventoID,OrganizadorID);



CREATE TABLE unidadanalisis.DimCanal
(
	CanalID              INT NOT NULL,
	NombreCanal          VARCHAR(50) NULL
);



ALTER TABLE unidadanalisis.DimCanal
ADD PRIMARY KEY (CanalID);



CREATE TABLE unidadanalisis.DimEquiposRRHH
(
	EquipoID             INT NOT NULL,
	NombreEquipo         VARCHAR(50) NULL,
	Area                 VARCHAR(50) NULL
);



ALTER TABLE unidadanalisis.DimEquiposRRHH
ADD PRIMARY KEY (EquipoID);



CREATE TABLE unidadanalisis.DimEventos
(
	EventoID             INT NOT NULL,
	UbicacionID          INT NULL,
	NombreEvento         VARCHAR(100) NULL
);



ALTER TABLE unidadanalisis.DimEventos
ADD PRIMARY KEY (EventoID);



CREATE TABLE unidadanalisis.DimFecha
(
	FechaID              INT NOT NULL,
	Fecha                DATE NOT NULL,
	Anio                 INT NULL,
	Mes                  INT NULL,
	Trimestre            INT NULL,
	DiaSemana            VARCHAR(10) NULL
);



ALTER TABLE unidadanalisis.DimFecha
ADD PRIMARY KEY (FechaID);



CREATE TABLE unidadanalisis.DimOrganizadores
(
	OrganizadorID        INT NOT NULL,
	Nombre               VARCHAR(100) NULL,
	TipoOrg              VARCHAR(50) NULL
);



ALTER TABLE unidadanalisis.DimOrganizadores
ADD PRIMARY KEY (OrganizadorID);



CREATE TABLE unidadanalisis.DimTiposEntrada
(
	TipoEntradaID        INT NOT NULL,
	Descripcion          VARCHAR(50) NULL,
	EsCortesia           SMALLINT NULL
);



ALTER TABLE unidadanalisis.DimTiposEntrada
ADD PRIMARY KEY (TipoEntradaID);



CREATE TABLE unidadanalisis.DimTiposGasto
(
	TipoGastoID          INT NOT NULL,
	NombreGasto          VARCHAR(50) NULL
);



ALTER TABLE unidadanalisis.DimTiposGasto
ADD PRIMARY KEY (TipoGastoID);



CREATE TABLE unidadanalisis.DimTiposIncidencia
(
	TipoIncidenciaID     INT NOT NULL,
	Descripcion          VARCHAR(100) NULL
);



ALTER TABLE unidadanalisis.DimTiposIncidencia
ADD PRIMARY KEY (TipoIncidenciaID);



CREATE TABLE unidadanalisis.DimUbicacion
(
	UbicacionID          INT NOT NULL,
	Pais                 VARCHAR(50) NOT NULL,
	Departamento         VARCHAR(100) NOT NULL,
	Provincia            VARCHAR(100) NOT NULL,
	Distrito             VARCHAR(100) NOT NULL
);



ALTER TABLE unidadanalisis.DimUbicacion
ADD PRIMARY KEY (UbicacionID);



CREATE UNIQUE INDEX XAK1DimUbicacion ON unidadanalisis.DimUbicacion
(
	Pais,
	Departamento,
	Provincia,
	Distrito
);



CREATE TABLE unidadanalisis.DimUsuarios
(
	UsuarioID            INT NOT NULL,
	CanalOrigen          VARCHAR(50) NULL,
	Plataforma           VARCHAR(50) NULL,
	UbicacionID          INT NULL
);



ALTER TABLE unidadanalisis.DimUsuarios
ADD PRIMARY KEY (UsuarioID);



CREATE TABLE unidadanalisis.FactEgresos
(
	EgresoID             BIGINT NOT NULL,
	FechaID              INT NOT NULL,
	EventoID             INT NOT NULL,
	TipoGastoID          INT NOT NULL,
	Monto                DECIMAL(12,2) NULL,
	Descripcion          VARCHAR(200) NULL
);



ALTER TABLE unidadanalisis.FactEgresos
ADD PRIMARY KEY (EgresoID);



CREATE TABLE unidadanalisis.FactEventos
(
	RegistroID           BIGINT NOT NULL,
	FechaID              INT NOT NULL,
	EventoID             INT NOT NULL,
	OrganizadorID        INT NOT NULL,
	TotalEventos         INT NULL
);



ALTER TABLE unidadanalisis.FactEventos
ADD PRIMARY KEY (RegistroID);



CREATE TABLE unidadanalisis.FactIncidencias
(
	IncidenciaID         BIGINT NOT NULL,
	FechaID              INT NOT NULL,
	EventoID             INT NOT NULL,
	TipoIncidenciaID     INT NOT NULL,
	TotalIncidencias     INT NULL,
	Activas              INT NULL,
	Resueltas            INT NULL,
	TiempoPromedioRec    DECIMAL(10,2) NULL
);



ALTER TABLE unidadanalisis.FactIncidencias
ADD PRIMARY KEY (IncidenciaID);



CREATE TABLE unidadanalisis.FactPosicionamiento
(
	PosicionID           BIGINT NOT NULL,
	FechaID              INT NOT NULL,
	UbicacionID          INT NOT NULL,
	CanalID              INT NOT NULL,
	NuevosUsuarios       INT NULL,
	SeguidoresRedes      INT NULL,
	MarketSharePct       DECIMAL(5,2) NULL
);



ALTER TABLE unidadanalisis.FactPosicionamiento
ADD PRIMARY KEY (PosicionID);



CREATE TABLE unidadanalisis.FactRRHH
(
	RRHHID               BIGINT NOT NULL,
	FechaID              INT NOT NULL,
	EquipoID             INT NOT NULL,
	CantTrabajadores     INT NULL,
	RotacionPct          DECIMAL(5,2) NULL
);



ALTER TABLE unidadanalisis.FactRRHH
ADD PRIMARY KEY (RRHHID);



CREATE TABLE unidadanalisis.FactVentas
(
	VentaID              BIGINT NOT NULL,
	FechaID              INT NOT NULL,
	EventoID             INT NOT NULL,
	UsuarioID            INT NOT NULL,
	TipoEntradaID        INT NOT NULL,
	Cantidad             INT NULL,
	PrecioUnitario       DECIMAL(10,2) NULL,
	TotalVenta           DECIMAL(12,2) NULL
);



ALTER TABLE unidadanalisis.FactVentas
ADD PRIMARY KEY (VentaID);



ALTER TABLE unidadanalisis.BridgeEventoOrganizador
ADD FOREIGN KEY R_3 (EventoID) REFERENCES unidadanalisis.DimEventos (EventoID);



ALTER TABLE unidadanalisis.BridgeEventoOrganizador
ADD FOREIGN KEY R_4 (OrganizadorID) REFERENCES unidadanalisis.DimOrganizadores (OrganizadorID);



ALTER TABLE unidadanalisis.DimEventos
ADD FOREIGN KEY R_2 (UbicacionID) REFERENCES unidadanalisis.DimUbicacion (UbicacionID);



ALTER TABLE unidadanalisis.DimUsuarios
ADD FOREIGN KEY R_1 (UbicacionID) REFERENCES unidadanalisis.DimUbicacion (UbicacionID);



ALTER TABLE unidadanalisis.FactEgresos
ADD FOREIGN KEY R_9 (FechaID) REFERENCES unidadanalisis.DimFecha (FechaID);



ALTER TABLE unidadanalisis.FactEgresos
ADD FOREIGN KEY R_10 (EventoID) REFERENCES unidadanalisis.DimEventos (EventoID);



ALTER TABLE unidadanalisis.FactEgresos
ADD FOREIGN KEY R_11 (TipoGastoID) REFERENCES unidadanalisis.DimTiposGasto (TipoGastoID);



ALTER TABLE unidadanalisis.FactEventos
ADD FOREIGN KEY R_20 (FechaID) REFERENCES unidadanalisis.DimFecha (FechaID);



ALTER TABLE unidadanalisis.FactEventos
ADD FOREIGN KEY R_21 (EventoID) REFERENCES unidadanalisis.DimEventos (EventoID);



ALTER TABLE unidadanalisis.FactEventos
ADD FOREIGN KEY R_22 (OrganizadorID) REFERENCES unidadanalisis.DimOrganizadores (OrganizadorID);



ALTER TABLE unidadanalisis.FactIncidencias
ADD FOREIGN KEY R_17 (FechaID) REFERENCES unidadanalisis.DimFecha (FechaID);



ALTER TABLE unidadanalisis.FactIncidencias
ADD FOREIGN KEY R_18 (EventoID) REFERENCES unidadanalisis.DimEventos (EventoID);



ALTER TABLE unidadanalisis.FactIncidencias
ADD FOREIGN KEY R_19 (TipoIncidenciaID) REFERENCES unidadanalisis.DimTiposIncidencia (TipoIncidenciaID);



ALTER TABLE unidadanalisis.FactPosicionamiento
ADD FOREIGN KEY R_14 (FechaID) REFERENCES unidadanalisis.DimFecha (FechaID);



ALTER TABLE unidadanalisis.FactPosicionamiento
ADD FOREIGN KEY R_15 (UbicacionID) REFERENCES unidadanalisis.DimUbicacion (UbicacionID);



ALTER TABLE unidadanalisis.FactPosicionamiento
ADD FOREIGN KEY R_16 (CanalID) REFERENCES unidadanalisis.DimCanal (CanalID);



ALTER TABLE unidadanalisis.FactRRHH
ADD FOREIGN KEY R_12 (FechaID) REFERENCES unidadanalisis.DimFecha (FechaID);



ALTER TABLE unidadanalisis.FactRRHH
ADD FOREIGN KEY R_13 (EquipoID) REFERENCES unidadanalisis.DimEquiposRRHH (EquipoID);



ALTER TABLE unidadanalisis.FactVentas
ADD FOREIGN KEY R_5 (FechaID) REFERENCES unidadanalisis.DimFecha (FechaID);



ALTER TABLE unidadanalisis.FactVentas
ADD FOREIGN KEY R_6 (EventoID) REFERENCES unidadanalisis.DimEventos (EventoID);



ALTER TABLE unidadanalisis.FactVentas
ADD FOREIGN KEY R_7 (UsuarioID) REFERENCES unidadanalisis.DimUsuarios (UsuarioID);



ALTER TABLE unidadanalisis.FactVentas
ADD FOREIGN KEY R_8 (TipoEntradaID) REFERENCES unidadanalisis.DimTiposEntrada (TipoEntradaID);


