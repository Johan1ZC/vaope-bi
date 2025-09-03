USE odoo_ERP_Fake; 

CREATE OR REPLACE VIEW v_src_fact_ventas_detalle AS
SELECT
  CAST(DATE_FORMAT(v.FechaHora, '%Y%m%d') AS UNSIGNED) AS FechaFacturaID,
  EXTRACT(HOUR FROM v.FechaHora)                       AS TiempoFacturaID,
  v.FacturaID,
  vd.FacturaDetalleID,
  vd.Cantidad                                           AS CantidadProd,
  (vd.Cantidad * vd.PrecioUnit)                         AS SinImpuesto,
  vd.Impuesto,
  (vd.Cantidad * vd.PrecioUnit + vd.Impuesto)           AS Total,
  p.NomProducto,                -- -> DimProducto
  ven.Vendedor,                 -- -> DimVendedor
  est.EstadoFactura,            -- -> DimEstadoFactura
  ev.NombreEvento,              -- -> DimEventos
  org.Nombre AS Organizador,    -- -> DimOrganizadores
  u.Pais, u.Departamento, u.Provincia, u.Distrito       -- -> DimUbicacion
FROM Venta v
JOIN Venta_Det     vd  ON vd.FacturaID = v.FacturaID
JOIN Producto      p   ON p.ProductoCodigo   = vd.ProductoCodigo
JOIN Vendedor      ven ON ven.VendedorCodigo = v.VendedorCodigo
JOIN EstadoFactura est ON est.EstadoCodigo   = v.EstadoCodigo
LEFT JOIN Evento       ev  ON ev.EventoCodigo       = v.EventoCodigo
LEFT JOIN Organizador  org ON org.OrganizadorCodigo = v.OrganizadorCodigo
LEFT JOIN Ubicacion    u   ON u.UbicacionCodigo     = v.UbicacionCodigo;

