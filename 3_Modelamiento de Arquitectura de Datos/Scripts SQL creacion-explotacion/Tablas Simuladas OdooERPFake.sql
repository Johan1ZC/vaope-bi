CREATE DATABASE odoo_erp_Fake;

USE odoo_erp_Fake;

-- Catálogos
CREATE TABLE   Producto(
  ProductoCodigo  nvarchar(20)  PRIMARY KEY,
  NomProducto     nvarchar(100) NOT NULL,
  Descripcion     nvarchar(100) NULL,
  EsCortesia      bit NOT NULL DEFAULT 0
);

CREATE TABLE   Proveedor(
  ProveedorCodigo nvarchar(20)  PRIMARY KEY,
  NomProveedor    nvarchar(100) NOT NULL,
  Descripcion     nvarchar(100) NULL
);

CREATE TABLE   Vendedor(
  VendedorCodigo  nvarchar(20)  PRIMARY KEY,
  Vendedor        nvarchar(100) NOT NULL
);

CREATE TABLE   TipoGasto(
  TipoGastoCodigo nvarchar(20)  PRIMARY KEY,
  NombreGasto     nvarchar(50)  NOT NULL
);

CREATE TABLE   Evento(
  EventoCodigo    nvarchar(20)  PRIMARY KEY,
  NombreEvento    nvarchar(250) NOT NULL,
  FechaInicio     datetime     NOT NULL,
  FechaFin        datetime     NULL
);

CREATE TABLE   Organizador(
  OrganizadorCodigo nvarchar(20) PRIMARY KEY,
  Nombre            nvarchar(100) NOT NULL,
  TipoOrg           nvarchar(50)  NULL
);

CREATE TABLE   Ubicacion(
  UbicacionCodigo  nvarchar(20)  PRIMARY KEY,
  Pais             nvarchar(50)  NOT NULL,
  Departamento     nvarchar(100) NOT NULL,
  Provincia        nvarchar(100) NOT NULL,
  Distrito         nvarchar(100) NOT NULL
);

CREATE TABLE   EstadoFactura(
  EstadoCodigo     nvarchar(10)  PRIMARY KEY,
  EstadoFactura    nvarchar(50)  NOT NULL
);

-- Cabeceras
CREATE TABLE   Venta(
  FacturaID          nvarchar(100) PRIMARY KEY,
  FechaHora          datetime     NOT NULL,
  VendedorCodigo     nvarchar(20)  NOT NULL,
  EstadoCodigo       nvarchar(10)  NOT NULL,
  EventoCodigo       nvarchar(20)  NULL,
  OrganizadorCodigo  nvarchar(20)  NULL,
  UbicacionCodigo    nvarchar(20)  NULL
);

CREATE TABLE   Egreso(
  FacturaID          nvarchar(100) PRIMARY KEY,
  FechaHora          datetime     NOT NULL,
  ProveedorCodigo    nvarchar(20)  NOT NULL,
  EstadoCodigo       nvarchar(10)  NOT NULL,
  EventoCodigo       nvarchar(20)  NULL,
  OrganizadorCodigo  nvarchar(20)  NULL,
  UbicacionCodigo    nvarchar(20)  NULL
);

-- Detalles
CREATE TABLE   Venta_Det(
  FacturaID          nvarchar(100) NOT NULL,
  FacturaDetalleID   nvarchar(100) NOT NULL,
  ProductoCodigo     nvarchar(20)  NOT NULL,
  Cantidad           int           NOT NULL,
  PrecioUnit         decimal(12,2) NOT NULL,
  Impuesto           decimal(12,2) NOT NULL,
  CONSTRAINT PK_VentaDet PRIMARY KEY(FacturaID, FacturaDetalleID)
);

CREATE TABLE   Egreso_Det(
  FacturaID          nvarchar(100) NOT NULL,
  FacturaDetalleID   nvarchar(100) NOT NULL,
  TipoGastoCodigo    nvarchar(20)  NOT NULL,
  Cantidad           int           NOT NULL,
  MontoSinImpuesto   decimal(12,2) NOT NULL,
  Impuesto           decimal(12,2) NOT NULL,
  CONSTRAINT PK_EgresoDet PRIMARY KEY(FacturaID, FacturaDetalleID)
);

-- Datos de ejemplo
INSERT   Producto VALUES
 ('PRD-ENT','Entrada General','Acceso general',0),
 ('PRD-VIP','Entrada VIP','Acceso VIP',0),
 ('PRD-CTE','Cortesía','Sin cobro',1);

INSERT   Proveedor VALUES
 ('PROV-01','Proveedor Lima','Servicios varios'),
 ('PROV-02','Proveedor Cusco','Servicios varios');

INSERT   Vendedor VALUES
 ('VEN-01','Carla Rosales'),
 ('VEN-02','Luis Pérez');

INSERT   TipoGasto VALUES
 ('GAS-SEG','Seguridad'),
 ('GAS-SND','Sonido');

INSERT   Evento VALUES
 ('EV-001','Festival Sol','2024-08-15 10:00','2024-08-15 22:00'),
 ('EV-002','Concierto Luna','2024-09-20 18:00','2024-09-20 23:30');

INSERT   Organizador VALUES
 ('ORG-01','ACME Eventos','Productora'),
 ('ORG-02','LivePro','Productora');

INSERT   Ubicacion VALUES
 ('UBI-01','Perú','Lima','Lima','Miraflores'),
 ('UBI-02','Perú','Cusco','Cusco','Cusco');

INSERT   EstadoFactura VALUES
 ('PAG','Pagada'),('PEN','Pendiente'),('DEV','Devolución');

-- Ventas
INSERT   Venta VALUES
 ('BD-1504','2024-08-15 11:23','VEN-01','PAG','EV-001','ORG-01','UBI-01'),
 ('BD-1505','2024-08-15 12:10','VEN-02','PEN','EV-001','ORG-01','UBI-01');

INSERT   Venta_Det VALUES
 ('BD-1504','sub-bd-01','PRD-ENT',2, 50.00, 18.00),
 ('BD-1504','sub-bd-02','PRD-VIP',1,120.00, 21.60),
 ('BD-1505','sub-bd-01','PRD-ENT',1, 50.00,  9.00);

-- Egresos
INSERT   Egreso VALUES
 ('EG-2001','2024-08-14 09:05','PROV-01','PAG','EV-001','ORG-01','UBI-01'),
 ('EG-2002','2024-09-19 14:20','PROV-02','PEN','EV-002','ORG-02','UBI-02');

INSERT   Egreso_Det VALUES
 ('EG-2001','eg-sub-01','GAS-SEG',3, 300.00, 54.00),
 ('EG-2002','eg-sub-01','GAS-SND',1, 800.00,144.00);
