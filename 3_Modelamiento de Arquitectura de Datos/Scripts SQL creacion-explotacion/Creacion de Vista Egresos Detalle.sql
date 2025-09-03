CREATE OR REPLACE VIEW v_src_fact_egresos_detalle AS
SELECT
  CAST(DATE_FORMAT(e.FechaHora, '%Y%m%d') AS UNSIGNED) AS FechaFacturaID,
  EXTRACT(HOUR FROM e.FechaHora)                       AS TiempoFacturaID,
  e.FacturaID,
  ed.FacturaDetalleID,
  ed.Cantidad                                          AS CantidadProd,
  ed.MontoSinImpuesto                                  AS SinImpuesto,
  ed.Impuesto,
  (ed.MontoSinImpuesto + ed.Impuesto)                  AS Total,
  tg.NombreGasto,               -- -> DimTiposGasto
  pr.NomProveedor,              -- -> DimProveedor
  est.EstadoFactura,            -- -> DimEstadoFactura
  ev.NombreEvento,              -- -> DimEventos
  org.Nombre AS Organizador,    -- -> DimOrganizadores
  u.Pais, u.Departamento, u.Provincia, u.Distrito      -- -> DimUbicacion
FROM Egreso e
JOIN Egreso_Det   ed  ON ed.FacturaID = e.FacturaID
JOIN TipoGasto    tg  ON tg.TipoGastoCodigo = ed.TipoGastoCodigo
JOIN Proveedor    pr  ON pr.ProveedorCodigo = e.ProveedorCodigo
JOIN EstadoFactura est ON est.EstadoCodigo  = e.EstadoCodigo
LEFT JOIN Evento       ev  ON ev.EventoCodigo       = e.EventoCodigo
LEFT JOIN Organizador  org ON org.OrganizadorCodigo = e.OrganizadorCodigo
LEFT JOIN Ubicacion    u   ON u.UbicacionCodigo     = e.UbicacionCodigo;

# Nota: en MySQL no uses el prefijo dbo. y reemplaza FORMAT/DATEPART por DATE_FORMAT y EXTRACT(HOUR FROM …).