#add = agregado
#mod = modificado

CREATE TABLE DimEstadoFactura
(
	EstadoFacturaID      INT NOT NULL,
	EstadoFactura        VARCHAR(50) NOT NULL
);


ALTER TABLE DimEstadoFactura ADD PRIMARY KEY (EstadoFacturaID);

CREATE UNIQUE INDEX uq_estadofact        ON DimEstadoFactura (EstadoFactura); #add


CREATE TABLE DimEventos
(
	EventoID             INT NOT NULL,
	NombreEvento         VARCHAR(250) NULL,
	FechaInicio          DATETIME NOT NULL,
	FechaFin             DATETIME NULL
);

ALTER TABLE DimEventos ADD PRIMARY KEY (EventoID);


CREATE TABLE DimFecha
(
	FechaID              INT NOT NULL,
	Fecha                DATE NOT NULL,
	Anio                 INT NULL,
	Mes                  INT NULL,
	Trimestre            INT NULL,
	DiaSemana            VARCHAR(10) NULL
);


ALTER TABLE DimFecha ADD PRIMARY KEY (FechaID);

CREATE UNIQUE INDEX uq_dimfecha_fecha    ON DimFecha (Fecha); #add 


CREATE TABLE DimOrganizadores
(
	OrganizadorID        INT NOT NULL,
	Nombre               VARCHAR(100) NULL,
	TipoOrg              VARCHAR(50) NULL
);


ALTER TABLE DimOrganizadores ADD PRIMARY KEY (OrganizadorID);


CREATE TABLE DimProducto
(
	ProductoID           INT NOT NULL,
	Descripcion          VARCHAR(100) NULL,
	EsCortesia           SMALLINT NULL,
	NomProducto          VARCHAR(100) NULL
);


ALTER TABLE DimProducto ADD PRIMARY KEY (ProductoID);



CREATE TABLE DimProveedor
(
	ProveedorID          INT NOT NULL,
	NomProveedor         VARCHAR(100) NOT NULL,
	Descripcion          VARCHAR(100) NULL
);


ALTER TABLE DimProveedor ADD PRIMARY KEY (ProveedorID);

CREATE UNIQUE INDEX uq_proveedor_nombre  ON DimProveedor (NomProveedor); #add



CREATE TABLE dimTiempo
(
	TiempoID             SMALLINT NOT NULL,
	Hora                 TIME NOT NULL,
	Hora24               TINYINT NOT NULL,
	Hora12               TINYINT NOT NULL,
	AMPM                 CHAR(2) NOT NULL,
	Tramo                VARCHAR(15) NOT NULL,
	BloqueHora           VARCHAR(15) NOT NULL
);


ALTER TABLE dimTiempo ADD PRIMARY KEY (TiempoID);

CREATE UNIQUE INDEX uq_dimtiempo_hora    ON dimTiempo (Hora); #add 


CREATE TABLE DimTiposGasto
(
	TipoGastoID          INT NOT NULL,
	NombreGasto          VARCHAR(50) NULL
);



ALTER TABLE DimTiposGasto ADD PRIMARY KEY (TipoGastoID);



CREATE TABLE DimUbicacion
(
	UbicacionID          INT NOT NULL,
	Pais                 VARCHAR(50) NOT NULL,
	Departamento         VARCHAR(100) NOT NULL,
	Provincia            VARCHAR(100) NOT NULL,
	Distrito             VARCHAR(100) NOT NULL
);



ALTER TABLE DimUbicacion ADD PRIMARY KEY (UbicacionID);


CREATE UNIQUE INDEX XAK1DimUbicacion ON DimUbicacion
(
	Pais,
	Departamento,
	Provincia,
	Distrito
);



CREATE TABLE DimVendedor
(
	VendedorID           INT NOT NULL,
	Vendedor             VARCHAR(100) NULL
);


ALTER TABLE DimVendedor ADD PRIMARY KEY (VendedorID);

CREATE UNIQUE INDEX uq_vendedor_nombre   ON DimVendedor (Vendedor); #add

CREATE TABLE FactEgresosDetalle
(
	EgresoID             BIGINT NOT NULL,
	FechaFacturaID       INT NOT NULL,
	EventoID             INT NOT NULL,
	TipoGastoID          INT NOT NULL,
	SinImpuesto          DECIMAL(12,2) NOT NULL DEFAULT 0, #mod
	TiempoFacturaID      SMALLINT NOT NULL,
	Impuesto             DECIMAL(12,2) NOT NULL DEFAULT 0, #mod
	Total                DECIMAL(12,2) NOT NULL DEFAULT 0, #mod
	OrganizadorID        INT NULL,
	UbicacionID          INT NULL,
	FacturaDetalleID     VARCHAR(50) NOT NULL,
	EstadoFacturaID      INT NULL,
	FacturaID            VARCHAR(100) NULL,
	CantidadProd         INT NOT NULL DEFAULT 0, #mod
	ProveedorID          INT NOT NULL
);


ALTER TABLE FactEgresosDetalle ADD PRIMARY KEY (EgresoID);

CREATE UNIQUE INDEX uq_factegresos_linea ON FactEgresosDetalle (FacturaID, FacturaDetalleID); #add
  
CREATE INDEX ix_fe_fecha     ON FactEgresosDetalle (FechaFacturaID, TiempoFacturaID); #add
CREATE INDEX ix_fe_tipogasto ON FactEgresosDetalle (TipoGastoID); #add
CREATE INDEX ix_fe_proveedor ON FactEgresosDetalle (ProveedorID); #add
CREATE INDEX ix_fe_evento    ON FactEgresosDetalle (EventoID); #add
CREATE INDEX ix_fe_estado    ON FactEgresosDetalle (EstadoFacturaID); #add
CREATE INDEX ix_fe_ubi       ON FactEgresosDetalle (UbicacionID); #add

ALTER TABLE FactEgresosDetalle ADD COLUMN Fuente VARCHAR(50) NULL, ADD COLUMN FechaCarga DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP; #add


CREATE TABLE FactVentasDetalle
(
	VentaID              BIGINT NOT NULL,
	FechaFacturaID       INT NOT NULL,
	EventoID             INT NOT NULL,
	ProductoID           INT NOT NULL,
	CantidadProd         INT NOT NULL DEFAULT 0, #mod
	SinImpuesto          DECIMAL(12,2) NOT NULL DEFAULT 0, #mod
	Total                DECIMAL(12,2) NOT NULL DEFAULT 0, #mod
	TiempoFacturaID      SMALLINT NOT NULL,
	VendedorID           INT NOT NULL,
	FacturaDetalleID     VARCHAR(100) NOT NULL,
	Impuesto             DECIMAL(12,2) NOT NULL DEFAULT 0, #mod
	EstadoFacturaID      INT NULL,
	OrganizadorID        INT NULL,
	UbicacionID          INT NULL,
	FacturaID            VARCHAR(100) NULL
);


ALTER TABLE FactVentasDetalle ADD PRIMARY KEY (VentaID);

CREATE UNIQUE INDEX uq_factventas_linea ON FactVentasDetalle (FacturaID, FacturaDetalleID); #add
  
CREATE INDEX ix_fv_fecha     ON FactVentasDetalle (FechaFacturaID, TiempoFacturaID); #add
CREATE INDEX ix_fv_producto  ON FactVentasDetalle (ProductoID); #add
CREATE INDEX ix_fv_vendedor  ON FactVentasDetalle (VendedorID); #add
CREATE INDEX ix_fv_evento    ON FactVentasDetalle (EventoID); #add
CREATE INDEX ix_fv_estado    ON FactVentasDetalle (EstadoFacturaID); #add
CREATE INDEX ix_fv_ubi       ON FactVentasDetalle (UbicacionID); #add

ALTER TABLE FactVentasDetalle  ADD COLUMN Fuente VARCHAR(50) NULL, ADD COLUMN FechaCarga DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP; #add
  

#Relaciones fact vs dim:

ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegre_fecha (FechaFacturaID) REFERENCES DimFecha (FechaID);


ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegre_event (EventoID) REFERENCES DimEventos (EventoID);


ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegre_tipgasto (TipoGastoID) REFERENCES DimTiposGasto (TipoGastoID);


ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegre_hora (TiempoFacturaID) REFERENCES dimTiempo (TiempoID);


ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegredetalle_organ (OrganizadorID) REFERENCES DimOrganizadores (OrganizadorID);


ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegredetal_ubi (UbicacionID) REFERENCES DimUbicacion (UbicacionID);


ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegredetall_estadofact (EstadoFacturaID) REFERENCES DimEstadoFactura (EstadoFacturaID);


ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegredetall_proveed (ProveedorID) REFERENCES DimProveedor (ProveedorID);


ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_fechafactura (FechaFacturaID) REFERENCES DimFecha (FechaID);


ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_event (EventoID) REFERENCES DimEventos (EventoID);


ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_tipentrada (ProductoID) REFERENCES DimProducto (ProductoID);


ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_hora (TiempoFacturaID) REFERENCES dimTiempo (TiempoID);


ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_vendor (VendedorID) REFERENCES DimVendedor (VendedorID);


ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_estado (EstadoFacturaID) REFERENCES DimEstadoFactura (EstadoFacturaID);


ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factventdetall_organ (OrganizadorID) REFERENCES DimOrganizadores (OrganizadorID);


ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factventdetalle_ubi (UbicacionID) REFERENCES DimUbicacion (UbicacionID);

