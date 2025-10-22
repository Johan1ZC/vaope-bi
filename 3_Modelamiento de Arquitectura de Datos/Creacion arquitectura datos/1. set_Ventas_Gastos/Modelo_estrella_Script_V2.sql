/* =======================================================================
   Huella: JZ-VAOPE-DW-SET_VENTA_EGRESOS-002
   Proyecto: VAOPE – Data Warehouse (Ventas/Egresos/Eventos)
   Artefacto: Modelo Estrella – V2 (DDL)
   Autor: Johan Zuñiga Cordova  |
   Email: johan@vaope.com | johan.zcor.upc@gmail.com
   Licencia: MIT
   Versión: v2.1
   Fecha: 2025-10-14
   Entorno: MySQL 8.0  |  Schema: dwh_dev
   Dependencias: Privilegios CREATE/ALTER/INDEX.
   Descripción:
     - Crea dimensiones y hechos clave (DimCuenta, DimDistribucionAnalitica,
       DimEstadoFactura, DimEventos, DimFecha, DimOrganizadores, DimProducto,
       DimProveedor, DimTiposGasto, DimUbicacion, DimVendedor, DimLocalEvento,
       DimTicketera, factevntasdetalle, factegresosdetalle) y tablas puente (eventosOrganizador_Detalle, eventosTicketera_detalle).
     - Define PK/UK/Índices y FKs para integridad y performance.
   Métricas rápidas del DDL:
     - Entidades: 14+
     - Primary keys: 28
     - Foreign keys: 16
   ADR relacionado:
     - ADR-003: Relaciones de fecha activa (FechaInicio) e inactiva (FechaFin) para eventos.
     - ADR-005: Índices compuestos en DimUbicacion y unicidad de Ubigeo6.
   Convención de nombres:
     - Dim* (dimensiones), Fact* (hechos), *_Detalle (puentes), fk_* (FK), uq_* (UK), ix_* (index).
   Propósito:
     - Estandarizar el modelo estrella para ventas y gastos vinculados a eventos, proveedores,
       cuentas y distribución analítica con claves de negocio y surrogate keys.
   ======================================================================= */

USE dwh_dev;

-- Agregado Nuevo
CREATE TABLE DimCuenta    
(
	CuentaID     INT NOT NULL,
	NombreCuenta VARCHAR(100) NULL,
    Detalle      VARCHAR(100) NULL
);

ALTER TABLE DimCuenta ADD PRIMARY KEY (CuentaID);
ALTER TABLE DimCuenta ADD UNIQUE KEY uq_dimcta_nombre (NombreCuenta);
-- 

/*
CREATE TABLE DimCuentaAnalitica
(
	CuentaAnaliticaID    INT NOT NULL,
	Nombre               VARCHAR(100) NULL
);

ALTER TABLE DimCuentaAnalitica ADD PRIMARY KEY (CuentaAnaliticaID);
ALTER TABLE DimCuentaAnalitica ADD UNIQUE KEY uq_dimctanalitica_nombre (Nombre);
*/


CREATE TABLE DimDistribucionAnalitica
(
	DistribucionID    INT NOT NULL,
	Nombre               VARCHAR(100) NULL,
    Subcategoria         VARCHAR(100) NULL
);

ALTER TABLE DimDistribucionAnalitica ADD PRIMARY KEY (DistribucionID);
-- ALTER TABLE DimDistribucionAnalitica ADD UNIQUE KEY uq_dist_nombre (Nombre);

/*
CREATE TABLE distribucion_Cuentaan_Detalle
(
	CuentaAnaliticaID        INT NOT NULL,
	DistribucionID             INT NOT NULL
);

ALTER TABLE distribucion_Cuentaan_Detalle ADD CONSTRAINT pk_dist_cuen PRIMARY KEY (CuentaAnaliticaID, DistribucionID);

CREATE INDEX ix_dist_cuent ON distribucion_Cuentaan_Detalle (CuentaAnaliticaID);
*/


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
	FechaFin             DATETIME NULL,
	LocalEventoID        INT NULL,
    NroClics		     INT NULL 
);


ALTER TABLE DimEventos ADD PRIMARY KEY (EventoID);


CREATE TABLE DimFecha
(
	FechaID              INT NOT NULL,  -- 20250401
	Fecha                DATE NOT NULL,
	Anio                 INT NULL,
	Mes                  INT NULL,
	Trimestre            INT NULL,
	NombreDia            VARCHAR(10) NULL,
    NombreMes            VARCHAR(10) NULL
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
	NomProducto          VARCHAR(100) NULL,
	CategoriaProducto    VARCHAR(100) NULL,
    TipoOrigen           VARCHAR(50) NULL     -- Define si es producto de Venta o de Egreso
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
	Distrito             VARCHAR(100) NOT NULL,
    Ubigeo6              CHAR(6)
);

ALTER TABLE DimUbicacion ADD PRIMARY KEY (UbicacionID);

ALTER TABLE dwh_dev.DimUbicacion ADD UNIQUE KEY UX_Ubigeo6 (Ubigeo6);

CREATE UNIQUE INDEX XAK1DimUbicacion ON dwh_dev.DimUbicacion
(
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

CREATE TABLE eventosOrganizador_Detalle
(
	OrganizadorID        INT NOT NULL,
	EventoID             INT NOT NULL
);

ALTER TABLE eventosOrganizador_Detalle ADD CONSTRAINT pk_ev_org PRIMARY KEY (EventoID, OrganizadorID);

CREATE INDEX ix_evorg_org ON eventosOrganizador_Detalle (OrganizadorID);

CREATE TABLE FactEgresosDetalle
(
	EgresoID             BIGINT NOT NULL primary key AUTO_INCREMENT,
	FechaFacturaID       INT NOT NULL,
    FechaID              INT NOT NULL,  -- PRIORIZAE FECHA INICIO EVENTO , 2DO FECHA FACTURA
	EventoID             INT NULL,
	TipoGastoID          INT NULL,
	SinImpuesto          DECIMAL(12,2) NOT NULL,
	Impuesto             DECIMAL(12,2) NOT NULL,
	Total                DECIMAL(12,2) NOT NULL,
    PercentDist 		 DECIMAL(12,2) NOT NULL,
	FacturaDetalleID     VARCHAR(50) NOT NULL,
	EstadoFacturaID      INT NOT NULL,
	FacturaID            VARCHAR(100) NOT NULL,
	CantidadProd         INT NOT NULL,
	ProveedorID          INT NULL,
	DistribucionID       INT NULL,
    CuentaID             INT NULL,
	ProductoID           INT NOT NULL,
    valor_unitario       DECIMAL(12,2) NOT NULL,
	precio_unitario      DECIMAL(12,2) NOT NULL,
	descuento            DECIMAL(12,2) NOT NULL,
	porcentaje_igv       DECIMAL(12,2) NOT NULL,
	moneda               VARCHAR(25) NULL,
	tipo_cambio          VARCHAR(25) NULL,
    nombreEmpresa        VARCHAR(150) NULL,
    Fuente               VARCHAR(100)   NULL,
	FechaCarga           DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

#ALTER TABLE FactEgresosDetalle ADD PRIMARY KEY (EgresoID);

CREATE UNIQUE INDEX uq_factegresos_linea ON FactEgresosDetalle (FacturaID, FacturaDetalleID); #add
  
#CREATE INDEX ix_fe_fecha     ON FactEgresosDetalle (FechaFacturaID, TiempoFacturaID); #add
CREATE INDEX ix_fe_fechafact       ON FactEgresosDetalle (FechaFacturaID);
CREATE INDEX ix_fe_fecha       ON FactEgresosDetalle (FechaID); #Agregado
CREATE INDEX ix_fe_tipogasto ON FactEgresosDetalle (TipoGastoID); #add
CREATE INDEX ix_fe_proveedor ON FactEgresosDetalle (ProveedorID); #add
CREATE INDEX ix_fe_evento    ON FactEgresosDetalle (EventoID); #add
CREATE INDEX ix_fe_estado    ON FactEgresosDetalle (EstadoFacturaID); #add
CREATE INDEX ix_fe_producto    ON FactEgresosDetalle (ProductoID);
CREATE INDEX ix_fe_distanalit  ON FactEgresosDetalle (DistribucionID);
CREATE INDEX ix_fe_cuenta      ON FactEgresosDetalle (CuentaID);
#CREATE INDEX ix_fe_ubi       ON FactEgresosDetalle (UbicacionID); #add

ALTER TABLE FactEgresosDetalle ADD COLUMN Fuente VARCHAR(50) NULL, ADD COLUMN FechaCarga DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP; #add


CREATE TABLE FactVentasDetalle
(
	VentaID              BIGINT NOT NULL primary key AUTO_INCREMENT,
	FechaFacturaID       INT NOT NULL,
    FechaID              INT NOT NULL,  -- PRIORIZAE FECHA INICIO EVENTO , 2DO FECHA FACTURA
	EventoID             INT NULL,
	ProductoID           INT NOT NULL,
	CantidadProd         INT NOT NULL,
	SinImpuesto          DECIMAL(12,2) NOT NULL,
	Total                DECIMAL(12,2) NOT NULL,
    PercentDist 		 DECIMAL(12,2) NOT NULL,
	VendedorID           INT NULL,
	FacturaDetalleID     VARCHAR(100) NOT NULL,
	Impuesto             DECIMAL(12,2) NOT NULL,
	EstadoFacturaID      INT NOT NULL,
    DistribucionID       INT NULL,
	FacturaID            VARCHAR(100) NOT NULL,
    CuentaID             INT NULL,
    valor_unitario       DECIMAL(12,2) NOT NULL,
	precio_unitario      DECIMAL(12,2) NOT NULL,
	descuento            DECIMAL(12,2) NOT NULL,
	porcentaje_igv       DECIMAL(12,2) NOT NULL,
	moneda               VARCHAR(25) NULL,
	tipo_cambio          VARCHAR(25) NULL,  
    nombreEmpresa        VARCHAR(150) NULL,
    Fuente               VARCHAR(100)   NULL,
    FechaCarga           DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

#ALTER TABLE FactVentasDetalle ADD PRIMARY KEY (VentaID);
CREATE UNIQUE INDEX uq_factventas_linea ON FactVentasDetalle (FacturaID, FacturaDetalleID); #add
  
#CREATE INDEX ix_fv_fecha     ON FactVentasDetalle (FechaFacturaID, TiempoFacturaID); #add
CREATE INDEX ix_fv_fechafact     ON FactVentasDetalle (FechaFacturaID);
CREATE INDEX ix_fv_fecha       ON FactVentasDetalle (FechaID); #Agregado
CREATE INDEX ix_fv_producto  ON FactVentasDetalle (ProductoID); #add
CREATE INDEX ix_fv_vendedor  ON FactVentasDetalle (VendedorID); #add
CREATE INDEX ix_fv_evento    ON FactVentasDetalle (EventoID); #add
CREATE INDEX ix_fv_estado    ON FactVentasDetalle (EstadoFacturaID); #add
CREATE INDEX ix_fv_distanalit  ON FactVentasDetalle (DistribucionID);
CREATE INDEX ix_fv_cuenta      ON FactVentasDetalle (CuentaID);
#CREATE INDEX ix_fv_ubi       ON FactVentasDetalle (UbicacionID); #add

ALTER TABLE FactVentasDetalle  ADD COLUMN Fuente VARCHAR(50) NULL, ADD COLUMN FechaCarga DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP; #add

CREATE TABLE DimLocalEvento
(
	LocalEventoID        INT NOT NULL,
	UbicacionID          INT NULL,
    NomLocal VARCHAR(100) NULL
);

ALTER TABLE DimLocalEvento ADD PRIMARY KEY (LocalEventoID);

-- Nuevo:

CREATE TABLE DimTicketera
(
	TicketeraID        INT NOT NULL,
	NomTicketera               VARCHAR(100) NULL,
	TipoTicketera             VARCHAR(50) NULL
);

ALTER TABLE DimTicketera ADD PRIMARY KEY (TicketeraID);

CREATE TABLE eventosTicketera_detalle
(
	TicketeraID        INT NOT NULL,
	EventoID             INT NOT NULL
);

ALTER TABLE eventosTicketera_detalle ADD CONSTRAINT pk_ev_ticket PRIMARY KEY (EventoID, TicketeraID);

CREATE INDEX ix_evtick_ticke ON eventosTicketera_detalle (TicketeraID);


-- Relaciones:

ALTER TABLE DimEventos ADD FOREIGN KEY fk_event_local (LocalEventoID) REFERENCES DimLocalEvento (LocalEventoID);

ALTER TABLE eventosOrganizador_Detalle ADD FOREIGN KEY fk_organiza_event (OrganizadorID) REFERENCES DimOrganizadores (OrganizadorID);

ALTER TABLE eventosOrganizador_Detalle ADD FOREIGN KEY fk_eventos_organizador (EventoID) REFERENCES DimEventos (EventoID);

ALTER TABLE eventosTicketera_detalle ADD FOREIGN KEY fk_ticket_event (TicketeraID) REFERENCES DimTicketera (TicketeraID);  -- NUEVO

ALTER TABLE eventosTicketera_detalle ADD FOREIGN KEY fk_eventos_ticket (EventoID) REFERENCES DimEventos (EventoID);  -- NUEVO

/*ALTER TABLE distribucion_Cuentaan_Detalle ADD FOREIGN KEY fk_analitia_dist (CuentaAnaliticaID) REFERENCES DimCuentaAnalitica (CuentaAnaliticaID);

ALTER TABLE distribucion_Cuentaan_Detalle ADD FOREIGN KEY fk_dist_analitica (DistribucionID) REFERENCES DimDistribucionAnalitica (DistribucionID);*/

ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegre_fecha (FechaID) REFERENCES DimFecha (FechaID);  #Agregado

ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegre_event (EventoID) REFERENCES DimEventos (EventoID);

ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegre_tipgasto (TipoGastoID) REFERENCES DimTiposGasto (TipoGastoID);

ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegredetall_estadofact (EstadoFacturaID) REFERENCES DimEstadoFactura (EstadoFacturaID);

ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegredetall_proveed (ProveedorID) REFERENCES DimProveedor (ProveedorID);

ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegreso_DistAna (DistribucionID) REFERENCES DimDistribucionAnalitica (DistribucionID);

ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegreso_cuenta (CuentaID) REFERENCES DimCuenta (CuentaID);

ALTER TABLE FactEgresosDetalle
ADD FOREIGN KEY fk_factegre_produc (ProductoID) REFERENCES DimProducto (ProductoID);

ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_fechafactura (FechaID) REFERENCES DimFecha (FechaID); #Agregado

ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_event (EventoID) REFERENCES DimEventos (EventoID);

ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_produc (ProductoID) REFERENCES DimProducto (ProductoID);

ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_vendor (VendedorID) REFERENCES DimVendedor (VendedorID);

ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factvent_estado (EstadoFacturaID) REFERENCES DimEstadoFactura (EstadoFacturaID);

ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factventa_DistAna (DistribucionID) REFERENCES DimDistribucionAnalitica (DistribucionID);

ALTER TABLE FactVentasDetalle
ADD FOREIGN KEY fk_factventa_cuenta (CuentaID) REFERENCES DimCuenta (CuentaID);

ALTER TABLE DimLocalEvento
ADD FOREIGN KEY fk_ubica_local (UbicacionID) REFERENCES DimUbicacion (UbicacionID);



