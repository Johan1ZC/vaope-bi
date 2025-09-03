/* ============================================================
   PASO 2 — Vistas fuente para SSIS (MySQL 8+)
   Esquema: erp_fake
   ============================================================ */
USE bd_odoofake;

-- Limpieza para re-creación
DROP VIEW IF EXISTS v_src_dim_fecha;
DROP VIEW IF EXISTS v_src_dim_ubicacion;
DROP VIEW IF EXISTS v_src_dim_local_evento;
DROP VIEW IF EXISTS v_src_dim_organizadores;
DROP VIEW IF EXISTS v_src_dim_producto;
DROP VIEW IF EXISTS v_src_dim_proveedor;
DROP VIEW IF EXISTS v_src_dim_vendedor;
DROP VIEW IF EXISTS v_src_dim_tiposgasto;
DROP VIEW IF EXISTS v_src_dim_cuenta_analitica;
DROP VIEW IF EXISTS v_src_dim_eventos;
DROP VIEW IF EXISTS v_src_bridge_evento_organizador;
DROP VIEW IF EXISTS v_src_fact_ventas_detalle;
DROP VIEW IF EXISTS v_src_fact_egresos_detalle;

-- =========================================
-- DimFecha (deriva de fechas presentes en la fuente)
-- =========================================
CREATE OR REPLACE VIEW v_src_dim_fecha AS
SELECT DISTINCT
  CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED) AS FechaID,
  d                                           AS Fecha,
  YEAR(d)                                     AS Anio,
  MONTH(d)                                    AS Mes,
  QUARTER(d)                                  AS Trimestre,
  ELT(DAYOFWEEK(d),'Dom','Lun','Mar','Mié','Jue','Vie','Sáb') AS DiaSemana
FROM (
  -- Reunimos fechas desde ventas, egresos y ventanas de eventos
  SELECT DATE(FechaHoraDetalle) AS d FROM venta_det
  UNION
  SELECT DATE(FechaHoraDetalle) AS d FROM egreso_det
  UNION
  SELECT DATE(FechaInicio)      AS d FROM evento
  UNION
  SELECT DATE(FechaFin)         AS d FROM evento
) fechas;

-- =========================================
-- DimUbicacion
-- =========================================
CREATE OR REPLACE VIEW v_src_dim_ubicacion AS
SELECT
  UbicacionCodigo AS UbicacionID,
  Pais, Departamento, Provincia, Distrito
FROM ubicacion;

-- =========================================
-- DimLocalEvento (requiere que DimUbicacion exista en DW)
-- =========================================
CREATE OR REPLACE VIEW v_src_dim_local_evento AS
SELECT
  le.LocalEventoCodigo AS LocalEventoID,
  le.UbicacionCodigo   AS UbicacionID   -- si en el DW mantienes mismos IDs, carga directa
FROM local_evento le;

-- =========================================
-- DimOrganizadores
-- =========================================
CREATE OR REPLACE VIEW v_src_dim_organizadores AS
SELECT
  OrganizadorCodigo AS OrganizadorID,
  Nombre,
  TipoOrg
FROM organizador;

-- =========================================
-- DimProducto
-- =========================================
CREATE OR REPLACE VIEW v_src_dim_producto AS
SELECT
  ProductoCodigo    AS ProductoID,
  NomProducto,
  CategoriaProducto
FROM producto;

-- =========================================
-- DimProveedor
-- =========================================
CREATE OR REPLACE VIEW v_src_dim_proveedor AS
SELECT
  ProveedorCodigo AS ProveedorID,
  NomProveedor    AS NomProveedor,
  ''              AS Descripcion   -- placeholder si en ERP no hay descripción
FROM proveedor;

-- =========================================
-- DimVendedor
-- =========================================
CREATE OR REPLACE VIEW v_src_dim_vendedor AS
SELECT
  VendedorCodigo AS VendedorID,
  Vendedor
FROM vendedor;

-- =========================================
-- DimTiposGasto
-- =========================================
CREATE OR REPLACE VIEW v_src_dim_tiposgasto AS
SELECT
  TipoGastoCodigo AS TipoGastoID,
  NombreGasto     AS NombreGasto
FROM tipo_gasto;

-- =========================================
-- DimCuentaAnalitica
-- =========================================
CREATE OR REPLACE VIEW v_src_dim_cuenta_analitica AS
SELECT
  CuentaAnaliticaCodigo AS CuentaAnaliticaID,
  anio,
  Presupuesto,
  Nombre
FROM cuenta_analitica;

-- =========================================
-- DimEventos
-- =========================================
CREATE OR REPLACE VIEW v_src_dim_eventos AS
SELECT
  e.EventoCodigo      AS EventoID,
  e.NombreEvento,
  e.FechaInicio,
  e.FechaFin,
  e.LocalEventoCodigo AS LocalEventoID
FROM evento e;

-- =========================================
-- Bridge Evento–Organizador (M:N)
-- =========================================
CREATE OR REPLACE VIEW v_src_bridge_evento_organizador AS
SELECT
  EventoCodigo      AS EventoID,
  OrganizadorCodigo AS OrganizadorID
FROM eventos_organizador_det;

-- =========================================
-- FactVentasDetalle — DETALLE (linea)
-- =========================================
CREATE OR REPLACE VIEW v_src_fact_ventas_detalle AS
SELECT
  -- Claves a dimensiones (formateadas para DW)
  CAST(DATE_FORMAT(vd.FechaHoraDetalle, '%Y%m%d') AS UNSIGNED) AS FechaFacturaID,
  vd.EventoCodigo      AS EventoID,
  vd.ProductoCodigo    AS ProductoID,
  vd.VendedorCodigo    AS VendedorID,
  vd.EstadoCodigo      AS EstadoFacturaID,

  -- Grano y trazabilidad
  vd.FacturaID,
  vd.FacturaDetalleID,

  -- Métricas
  vd.Cantidad                                    AS CantidadProd,
  CAST(vd.Cantidad * vd.PrecioUnit AS DECIMAL(12,2))              AS SinImpuesto,
  vd.Impuesto,
  CAST(vd.Cantidad * vd.PrecioUnit + vd.Impuesto AS DECIMAL(12,2)) AS Total,

  -- Metadatos
  'ERP_FAKE'        AS Fuente,
  CURRENT_TIMESTAMP AS FechaCarga
FROM venta_det vd;

-- =========================================
-- FactEgresosDetalle — DETALLE (linea)
-- =========================================
CREATE OR REPLACE VIEW v_src_fact_egresos_detalle AS
SELECT
  -- Claves a dimensiones (formateadas para DW)
  CAST(DATE_FORMAT(ed.FechaHoraDetalle, '%Y%m%d') AS UNSIGNED) AS FechaFacturaID,
  ed.EventoCodigo           AS EventoID,
  ed.TipoGastoCodigo        AS TipoGastoID,
  ed.ProveedorCodigo        AS ProveedorID,
  ed.CuentaAnaliticaCodigo  AS CuentaAnaliticaID,
  ed.ProductoCodigo         AS ProductoID,
  ed.EstadoCodigo           AS EstadoFacturaID,

  -- Grano y trazabilidad
  ed.FacturaID,
  ed.FacturaDetalleID,

  -- Métricas
  ed.Cantidad                                                   AS CantidadProd,
  CAST(ed.Cantidad * ed.PrecioUnit AS DECIMAL(12,2))              AS SinImpuesto,
  ed.Impuesto,
  CAST(ed.Cantidad * ed.PrecioUnit + ed.Impuesto AS DECIMAL(12,2)) AS Total,

  -- Metadatos
  'ERP_FAKE'        AS Fuente,
  CURRENT_TIMESTAMP AS FechaCarga
FROM egreso_det ed;
