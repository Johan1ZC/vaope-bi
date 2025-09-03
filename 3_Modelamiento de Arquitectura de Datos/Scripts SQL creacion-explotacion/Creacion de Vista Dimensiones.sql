-- =============== DIMENSIONES (MySQL) =================

-- Eventos
CREATE OR REPLACE VIEW v_src_dim_eventos AS
SELECT DISTINCT
  ev.EventoCodigo AS EventoBK,
  ev.NombreEvento AS NombreEvento,
  ev.FechaInicio,
  ev.FechaFin
FROM Evento ev;

-- Organizadores (ojo: la columna es TipoOrg)
CREATE OR REPLACE VIEW v_src_dim_organizadores AS
SELECT DISTINCT
  o.OrganizadorCodigo AS OrganizadorBK,
  o.Nombre,
  o.TipoOrg
FROM Organizador o;

-- Producto
CREATE OR REPLACE VIEW v_src_dim_producto AS
SELECT DISTINCT
  p.ProductoCodigo AS ProductoBK,
  p.NomProducto,
  p.Descripcion,
  COALESCE(p.EsCortesia, 0) AS EsCortesia
FROM Producto p;

-- Proveedor
CREATE OR REPLACE VIEW v_src_dim_proveedor AS
SELECT DISTINCT
  pr.ProveedorCodigo AS ProveedorBK,
  pr.NomProveedor,
  pr.Descripcion
FROM Proveedor pr;

-- Vendedor
CREATE OR REPLACE VIEW v_src_dim_vendedor AS
SELECT DISTINCT
  v.VendedorCodigo AS VendedorBK,
  v.Vendedor
FROM Vendedor v;

-- Tipos de gasto
CREATE OR REPLACE VIEW v_src_dim_tipogasto AS
SELECT DISTINCT
  tg.TipoGastoCodigo AS TipoGastoBK,
  tg.NombreGasto
FROM TipoGasto tg;

-- Ubicación
CREATE OR REPLACE VIEW v_src_dim_ubicacion AS
SELECT DISTINCT
  u.UbicacionCodigo AS UbicacionBK,
  u.Pais, u.Departamento, u.Provincia, u.Distrito
FROM Ubicacion u;

-- Estado de factura
CREATE OR REPLACE VIEW v_src_dim_estadofactura AS
SELECT DISTINCT
  e.EstadoCodigo AS EstadoFacturaBK,
  e.EstadoFactura
FROM EstadoFactura e;
