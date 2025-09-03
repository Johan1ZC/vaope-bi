/* ============================================================
   PASO 1 — ERP_FAKE: Esquema, Tablas y Datos de Ejemplo
   ============================================================ */

-- 1) Esquema base
CREATE DATABASE IF NOT EXISTS bd_odoofake
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE bd_odoofake;

-- 2) Limpieza (permite re-ejecutar)
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS venta_det;
DROP TABLE IF EXISTS venta;
DROP TABLE IF EXISTS egreso_det;
DROP TABLE IF EXISTS egreso;

DROP TABLE IF EXISTS eventos_organizador_det;
DROP TABLE IF EXISTS evento;
DROP TABLE IF EXISTS organizador;
DROP TABLE IF EXISTS local_evento;
DROP TABLE IF EXISTS ubicacion;

DROP TABLE IF EXISTS vendedor;
DROP TABLE IF EXISTS producto;
DROP TABLE IF EXISTS proveedor;
DROP TABLE IF EXISTS tipo_gasto;
DROP TABLE IF EXISTS cuenta_analitica;
DROP TABLE IF EXISTS estado_factura;

SET FOREIGN_KEY_CHECKS = 1;

-- 3) Catálogos / maestros
CREATE TABLE estado_factura (
  EstadoCodigo    TINYINT      NOT NULL,
  EstadoFactura   VARCHAR(50)  NOT NULL,
  PRIMARY KEY (EstadoCodigo),
  UNIQUE KEY uq_estadofact (EstadoFactura)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE vendedor (
  VendedorCodigo  INT          NOT NULL,
  Vendedor        VARCHAR(100) NOT NULL,
  PRIMARY KEY (VendedorCodigo),
  UNIQUE KEY uq_vendedor (Vendedor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE producto (
  ProductoCodigo     INT           NOT NULL,
  NomProducto        VARCHAR(100)  NOT NULL,
  CategoriaProducto  VARCHAR(100)  NOT NULL,
  PRIMARY KEY (ProductoCodigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE proveedor (
  ProveedorCodigo  INT           NOT NULL,
  NomProveedor     VARCHAR(100)  NOT NULL,
  PRIMARY KEY (ProveedorCodigo),
  UNIQUE KEY uq_proveedor (NomProveedor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tipo_gasto (
  TipoGastoCodigo  INT          NOT NULL,
  NombreGasto      VARCHAR(50)  NOT NULL,
  PRIMARY KEY (TipoGastoCodigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE cuenta_analitica (
  CuentaAnaliticaCodigo INT           NOT NULL,
  Nombre                VARCHAR(100)  NOT NULL,
  anio                  INT           NOT NULL,
  Presupuesto           DECIMAL(14,2) NOT NULL,
  PRIMARY KEY (CuentaAnaliticaCodigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ubicacion (
  UbicacionCodigo  INT           NOT NULL,
  Pais             VARCHAR(50)   NOT NULL,
  Departamento     VARCHAR(100)  NOT NULL,
  Provincia        VARCHAR(100)  NOT NULL,
  Distrito         VARCHAR(100)  NOT NULL,
  PRIMARY KEY (UbicacionCodigo),
  UNIQUE KEY uq_ubi (Pais,Departamento,Provincia,Distrito)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE local_evento (
  LocalEventoCodigo INT NOT NULL,
  UbicacionCodigo   INT NOT NULL,
  PRIMARY KEY (LocalEventoCodigo),
  KEY ix_le_ubi (UbicacionCodigo),
  CONSTRAINT fk_le_ubi FOREIGN KEY (UbicacionCodigo) REFERENCES ubicacion (UbicacionCodigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE organizador (
  OrganizadorCodigo  INT           NOT NULL,
  Nombre             VARCHAR(100)  NOT NULL,
  TipoOrg            VARCHAR(50)   NOT NULL,
  PRIMARY KEY (OrganizadorCodigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE evento (
  EventoCodigo       INT           NOT NULL,
  NombreEvento       VARCHAR(250)  NOT NULL,
  FechaInicio        DATETIME      NOT NULL,
  FechaFin           DATETIME      NOT NULL,
  LocalEventoCodigo  INT           NOT NULL,
  PRIMARY KEY (EventoCodigo),
  KEY ix_ev_local (LocalEventoCodigo),
  CONSTRAINT fk_ev_local FOREIGN KEY (LocalEventoCodigo) REFERENCES local_evento (LocalEventoCodigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE eventos_organizador_det (
  EventoCodigo        INT NOT NULL,
  OrganizadorCodigo   INT NOT NULL,
  PRIMARY KEY (EventoCodigo, OrganizadorCodigo),
  KEY ix_eod_org (OrganizadorCodigo),
  CONSTRAINT fk_eod_ev  FOREIGN KEY (EventoCodigo)      REFERENCES evento (EventoCodigo),
  CONSTRAINT fk_eod_org FOREIGN KEY (OrganizadorCodigo) REFERENCES organizador (OrganizadorCodigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4) Transaccionales (cabecera y DETALLE a nivel de línea)
CREATE TABLE venta (
  FacturaID   INT       NOT NULL,
  FechaHora   DATETIME  NOT NULL,
  PRIMARY KEY (FacturaID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE venta_det (
  FacturaID          INT          NOT NULL,
  FacturaDetalleID   VARCHAR(20)  NOT NULL,  -- granularidad a nivel de línea
  ProductoCodigo     INT          NOT NULL,
  Cantidad           INT          NOT NULL,
  PrecioUnit         DECIMAL(12,2) NOT NULL,
  Impuesto           DECIMAL(12,2) NOT NULL,
  EstadoCodigo       TINYINT      NOT NULL,  -- estado por DETALLE
  VendedorCodigo     INT          NOT NULL,
  EventoCodigo       INT          NOT NULL,
  FechaHoraDetalle   DATETIME     NOT NULL,  -- fecha/hora por DETALLE
  PRIMARY KEY (FacturaID, FacturaDetalleID),
  KEY ix_vd_prod (ProductoCodigo),
  KEY ix_vd_est  (EstadoCodigo),
  KEY ix_vd_ven  (VendedorCodigo),
  KEY ix_vd_ev   (EventoCodigo),
  KEY ix_vd_fh   (FechaHoraDetalle),
  CONSTRAINT fk_vd_fact    FOREIGN KEY (FacturaID)      REFERENCES venta (FacturaID),
  CONSTRAINT fk_vd_prod    FOREIGN KEY (ProductoCodigo) REFERENCES producto (ProductoCodigo),
  CONSTRAINT fk_vd_estado  FOREIGN KEY (EstadoCodigo)   REFERENCES estado_factura (EstadoCodigo),
  CONSTRAINT fk_vd_vend    FOREIGN KEY (VendedorCodigo) REFERENCES vendedor (VendedorCodigo),
  CONSTRAINT fk_vd_evento  FOREIGN KEY (EventoCodigo)   REFERENCES evento (EventoCodigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE egreso (
  FacturaID   INT       NOT NULL,
  FechaHora   DATETIME  NOT NULL,
  PRIMARY KEY (FacturaID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE egreso_det (
  FacturaID             INT           NOT NULL,
  FacturaDetalleID      VARCHAR(20)   NOT NULL,   -- granularidad a nivel de línea
  ProductoCodigo        INT           NOT NULL,
  Cantidad              INT           NOT NULL,
  PrecioUnit            DECIMAL(12,2) NOT NULL,
  Impuesto              DECIMAL(12,2) NOT NULL,
  EstadoCodigo          TINYINT       NOT NULL,   -- estado por DETALLE
  TipoGastoCodigo       INT           NOT NULL,
  ProveedorCodigo       INT           NOT NULL,
  CuentaAnaliticaCodigo INT           NOT NULL,
  EventoCodigo          INT           NOT NULL,
  FechaHoraDetalle      DATETIME      NOT NULL,   -- fecha/hora por DETALLE
  PRIMARY KEY (FacturaID, FacturaDetalleID),
  KEY ix_ed_prod   (ProductoCodigo),
  KEY ix_ed_est    (EstadoCodigo),
  KEY ix_ed_tg     (TipoGastoCodigo),
  KEY ix_ed_prov   (ProveedorCodigo),
  KEY ix_ed_cta    (CuentaAnaliticaCodigo),
  KEY ix_ed_ev     (EventoCodigo),
  KEY ix_ed_fh     (FechaHoraDetalle),
  CONSTRAINT fk_ed_fact   FOREIGN KEY (FacturaID)             REFERENCES egreso (FacturaID),
  CONSTRAINT fk_ed_prod   FOREIGN KEY (ProductoCodigo)        REFERENCES producto (ProductoCodigo),
  CONSTRAINT fk_ed_estado FOREIGN KEY (EstadoCodigo)          REFERENCES estado_factura (EstadoCodigo),
  CONSTRAINT fk_ed_tg     FOREIGN KEY (TipoGastoCodigo)       REFERENCES tipo_gasto (TipoGastoCodigo),
  CONSTRAINT fk_ed_prov   FOREIGN KEY (ProveedorCodigo)       REFERENCES proveedor (ProveedorCodigo),
  CONSTRAINT fk_ed_cta    FOREIGN KEY (CuentaAnaliticaCodigo) REFERENCES cuenta_analitica (CuentaAnaliticaCodigo),
  CONSTRAINT fk_ed_evento FOREIGN KEY (EventoCodigo)          REFERENCES evento (EventoCodigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5) Poblar catálogos / maestros
-- 5.1 Estados de factura
INSERT INTO estado_factura (EstadoCodigo, EstadoFactura) VALUES
  (1,'Borrador'),(2,'Pagada'),(3,'Anulada')
ON DUPLICATE KEY UPDATE EstadoFactura = VALUES(EstadoFactura);

-- 5.2 Vendedores 1..20
INSERT INTO vendedor (VendedorCodigo, Vendedor)
SELECT n, CONCAT('Vendedor ', LPAD(n,3,'0'))
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 20 )
  SELECT n FROM seq
) s
ON DUPLICATE KEY UPDATE Vendedor = VALUES(Vendedor);

-- 5.3 Productos 1..50
INSERT INTO producto (ProductoCodigo, NomProducto, CategoriaProducto)
SELECT
  n,
  CONCAT('Producto ', LPAD(n,3,'0')),
  CASE (n % 4)
    WHEN 0 THEN 'Entradas'
    WHEN 1 THEN 'Merch'
    WHEN 2 THEN 'Bebida'
    ELSE 'Comida'
  END
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 50 )
  SELECT n FROM seq
) s
ON DUPLICATE KEY UPDATE
  NomProducto = VALUES(NomProducto),
  CategoriaProducto = VALUES(CategoriaProducto);

-- 5.4 Proveedores 1..25
INSERT INTO proveedor (ProveedorCodigo, NomProveedor)
SELECT n, CONCAT('Proveedor ', LPAD(n,3,'0'))
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 25 )
  SELECT n FROM seq
) s
ON DUPLICATE KEY UPDATE NomProveedor = VALUES(NomProveedor);

-- 5.5 Tipos de gasto 1..10
INSERT INTO tipo_gasto (TipoGastoCodigo, NombreGasto)
SELECT n, CONCAT('TipoGasto ', LPAD(n,2,'0'))
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10 )
  SELECT n FROM seq
) s
ON DUPLICATE KEY UPDATE NombreGasto = VALUES(NombreGasto);

-- 5.6 Cuentas analíticas 1..12 (mitad 2024, mitad 2025)
INSERT INTO cuenta_analitica (CuentaAnaliticaCodigo, Nombre, anio, Presupuesto)
SELECT
  n,
  CONCAT('Cuenta Analítica ', LPAD(n,2,'0')),
  CASE WHEN n <= 6 THEN 2024 ELSE 2025 END,
  50000 + (n*3500)
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 12 )
  SELECT n FROM seq
) s
ON DUPLICATE KEY UPDATE
  Nombre = VALUES(Nombre),
  anio = VALUES(anio),
  Presupuesto = VALUES(Presupuesto);

-- 5.7 Ubicaciones (12 ejemplos)
INSERT INTO ubicacion (UbicacionCodigo, Pais, Departamento, Provincia, Distrito) VALUES
  (1,'Perú','Lima','Lima','Miraflores'),
  (2,'Perú','Lima','Lima','San Isidro'),
  (3,'Perú','Lima','Lima','Surco'),
  (4,'Perú','Lima','Lima','Barranco'),
  (5,'Perú','Cusco','Cusco','Cusco'),
  (6,'Perú','Arequipa','Arequipa','Arequipa'),
  (7,'Perú','La Libertad','Trujillo','Trujillo'),
  (8,'Perú','Piura','Piura','Piura'),
  (9,'Perú','Lambayeque','Chiclayo','Chiclayo'),
  (10,'Perú','Junín','Huancayo','Huancayo'),
  (11,'Perú','Lima','Huaral','Chancay'),
  (12,'Perú','Lima','Cañete','San Vicente')
ON DUPLICATE KEY UPDATE
  Pais=VALUES(Pais),Departamento=VALUES(Departamento),
  Provincia=VALUES(Provincia),Distrito=VALUES(Distrito);

-- 5.8 Locales (1..10) referenciando ubicaciones 1..12
INSERT INTO local_evento (LocalEventoCodigo, UbicacionCodigo)
SELECT n, 1 + (n % 12)
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 10 )
  SELECT n FROM seq
) s
ON DUPLICATE KEY UPDATE UbicacionCodigo = VALUES(UbicacionCodigo);

-- 5.9 Organizadores (1..15)
INSERT INTO organizador (OrganizadorCodigo, Nombre, TipoOrg)
SELECT
  n,
  CONCAT('Organizador ', LPAD(n,2,'0')),
  CASE WHEN n % 2 = 0 THEN 'Agencia' ELSE 'Productora' END
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 15 )
  SELECT n FROM seq
) s
ON DUPLICATE KEY UPDATE
  Nombre = VALUES(Nombre),
  TipoOrg = VALUES(TipoOrg);

-- 5.10 Eventos (1..30)
INSERT INTO evento (EventoCodigo, NombreEvento, FechaInicio, FechaFin, LocalEventoCodigo)
SELECT
  n,
  CONCAT('Evento ', LPAD(n,3,'0')),
  TIMESTAMP('2024-01-01') + INTERVAL (n*7) DAY,
  TIMESTAMP('2024-01-01') + INTERVAL (n*7+2) DAY,
  1 + (n % 10)
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30 )
  SELECT n FROM seq
) s
ON DUPLICATE KEY UPDATE
  NombreEvento = VALUES(NombreEvento),
  FechaInicio = VALUES(FechaInicio),
  FechaFin = VALUES(FechaFin),
  LocalEventoCodigo = VALUES(LocalEventoCodigo);

-- 5.11 Relación Evento–Organizador (1–3 organizadores por evento)
INSERT INTO eventos_organizador_det (EventoCodigo, OrganizadorCodigo)
SELECT e.n,
       1 + ((e.n + o.k) % 15)
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 30 )
  SELECT n FROM seq
) e
JOIN (SELECT 0 k UNION ALL SELECT 1 UNION ALL SELECT 2) o
ON ((e.n + o.k) % 3) <> 0
ON DUPLICATE KEY UPDATE OrganizadorCodigo = VALUES(OrganizadorCodigo);

-- 6) Cabeceras y DETALLES transaccionales

-- 6.1 Ventas — cabecera (200 facturas)
INSERT INTO venta (FacturaID, FechaHora)
SELECT
  n,
  TIMESTAMP('2024-01-01') + INTERVAL (n%365) DAY + INTERVAL (8 + (n%12)) HOUR
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 200 )
  SELECT n FROM seq
) s
ON DUPLICATE KEY UPDATE FechaHora = VALUES(FechaHora);

-- 6.2 Ventas — DETALLE (1–5 líneas por factura)
INSERT INTO venta_det
  (FacturaID, FacturaDetalleID, ProductoCodigo, Cantidad, PrecioUnit, Impuesto,
   EstadoCodigo, VendedorCodigo, EventoCodigo, FechaHoraDetalle)
SELECT
  v.n                                         AS FacturaID,
  CONCAT(LPAD(v.n,6,'0'),'-',LPAD(l.k,2,'0')) AS FacturaDetalleID,
  1 + ((v.n + l.k) % 50)                       AS ProductoCodigo,
  1 + ((v.n + l.k) % 5)                        AS Cantidad,
  ROUND(10 + ((v.n + l.k) % 50) * 1.5, 2)      AS PrecioUnit,
  ROUND(((1 + ((v.n + l.k) % 5)) * ROUND(10 + ((v.n + l.k) % 50) * 1.5, 2)) * 0.18, 2) AS Impuesto,
  ((v.n + l.k) % 3) + 1                         AS EstadoCodigo,
  1 + ((v.n + l.k) % 20)                        AS VendedorCodigo,
  1 + ((v.n + l.k) % 30)                        AS EventoCodigo,
  (TIMESTAMP('2024-01-01') + INTERVAL (v.n%365) DAY + INTERVAL (8 + (v.n%12)) HOUR) + INTERVAL (l.k-1) MINUTE
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 200 )
  SELECT n FROM seq
) v
JOIN (SELECT 1 k UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) l
  ON l.k <= 1 + (v.n % 5)
ON DUPLICATE KEY UPDATE
  ProductoCodigo   = VALUES(ProductoCodigo),
  Cantidad         = VALUES(Cantidad),
  PrecioUnit       = VALUES(PrecioUnit),
  Impuesto         = VALUES(Impuesto),
  EstadoCodigo     = VALUES(EstadoCodigo),
  VendedorCodigo   = VALUES(VendedorCodigo),
  EventoCodigo     = VALUES(EventoCodigo),
  FechaHoraDetalle = VALUES(FechaHoraDetalle);

-- 6.3 Egresos — cabecera (180 facturas)
INSERT INTO egreso (FacturaID, FechaHora)
SELECT
  n,
  TIMESTAMP('2024-02-01') + INTERVAL (n%365) DAY + INTERVAL (9 + (n%10)) HOUR
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 180 )
  SELECT n FROM seq
) s
ON DUPLICATE KEY UPDATE FechaHora = VALUES(FechaHora);

-- 6.4 Egresos — DETALLE (1–4 líneas por factura)
INSERT INTO egreso_det
  (FacturaID, FacturaDetalleID, ProductoCodigo, Cantidad, PrecioUnit, Impuesto,
   EstadoCodigo, TipoGastoCodigo, ProveedorCodigo, CuentaAnaliticaCodigo, EventoCodigo, FechaHoraDetalle)
SELECT
  e.n                                         AS FacturaID,
  CONCAT(LPAD(e.n,6,'0'),'-',LPAD(l.k,2,'0')) AS FacturaDetalleID,
  1 + ((e.n + l.k) % 50)                       AS ProductoCodigo,
  1 + ((e.n + l.k) % 6)                        AS Cantidad,
  ROUND(8 + ((e.n + l.k) % 60) * 1.2, 2)       AS PrecioUnit,
  ROUND(((1 + ((e.n + l.k) % 6)) * ROUND(8 + ((e.n + l.k) % 60) * 1.2, 2)) * 0.18, 2) AS Impuesto,
  ((e.n + l.k) % 3) + 1                        AS EstadoCodigo,
  1 + ((e.n + l.k) % 10)                       AS TipoGastoCodigo,
  1 + ((e.n + l.k) % 25)                       AS ProveedorCodigo,
  1 + ((e.n + l.k) % 12)                       AS CuentaAnaliticaCodigo,
  1 + ((e.n + l.k) % 30)                       AS EventoCodigo,
  (TIMESTAMP('2024-02-01') + INTERVAL (e.n%365) DAY + INTERVAL (9 + (e.n%10)) HOUR) + INTERVAL (l.k*2) MINUTE
FROM (
  WITH RECURSIVE seq(n) AS ( SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n < 180 )
  SELECT n FROM seq
) e
JOIN (SELECT 1 k UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) l
  ON l.k <= 1 + (e.n % 4)
ON DUPLICATE KEY UPDATE
  ProductoCodigo        = VALUES(ProductoCodigo),
  Cantidad              = VALUES(Cantidad),
  PrecioUnit            = VALUES(PrecioUnit),
  Impuesto              = VALUES(Impuesto),
  EstadoCodigo          = VALUES(EstadoCodigo),
  TipoGastoCodigo       = VALUES(TipoGastoCodigo),
  ProveedorCodigo       = VALUES(ProveedorCodigo),
  CuentaAnaliticaCodigo = VALUES(CuentaAnaliticaCodigo),
  EventoCodigo          = VALUES(EventoCodigo),
  FechaHoraDetalle      = VALUES(FechaHoraDetalle);

-- 7) Chequeos rápidos
SELECT 'vendedores' tabla, COUNT(*) filas FROM vendedor
UNION ALL SELECT 'producto', COUNT(*) FROM producto
UNION ALL SELECT 'proveedor', COUNT(*) FROM proveedor
UNION ALL SELECT 'tipo_gasto', COUNT(*) FROM tipo_gasto
UNION ALL SELECT 'cuenta_analitica', COUNT(*) FROM cuenta_analitica
UNION ALL SELECT 'ubicacion', COUNT(*) FROM ubicacion
UNION ALL SELECT 'local_evento', COUNT(*) FROM local_evento
UNION ALL SELECT 'organizador', COUNT(*) FROM organizador
UNION ALL SELECT 'evento', COUNT(*) FROM evento
UNION ALL SELECT 'eventos_organizador_det', COUNT(*) FROM eventos_organizador_det
UNION ALL SELECT 'venta', COUNT(*) FROM venta
UNION ALL SELECT 'venta_det', COUNT(*) FROM venta_det
UNION ALL SELECT 'egreso', COUNT(*) FROM egreso
UNION ALL SELECT 'egreso_det', COUNT(*) FROM egreso_det
UNION ALL SELECT 'estado_factura', COUNT(*) FROM estado_factura;
