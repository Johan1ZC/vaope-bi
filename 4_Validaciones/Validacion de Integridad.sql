USE dwh_dev;

-- 1. Duplicados en dimensiones -------------------------
-- Proveedores duplicados
SELECT NomProveedor, COUNT(*) AS cnt
FROM DimProveedor
GROUP BY NomProveedor
HAVING cnt > 1;

-- Estados de factura duplicados
SELECT EstadoFactura, COUNT(*) AS cnt
FROM DimEstadoFactura
GROUP BY EstadoFactura
HAVING cnt > 1;

-- Cuentas duplicadas
SELECT NombreCuenta, COUNT(*) AS cnt
FROM DimCuenta
GROUP BY NombreCuenta
HAVING cnt > 1;


-- 2. Facturas duplicadas en hechos ---------------------
-- Ventas
SELECT FacturaID, FacturaDetalleID, COUNT(*) AS cnt
FROM FactVentasDetalle
GROUP BY FacturaID, FacturaDetalleID
HAVING cnt > 1;

-- Egresos
SELECT FacturaID, FacturaDetalleID, COUNT(*) AS cnt
FROM FactEgresosDetalle
GROUP BY FacturaID, FacturaDetalleID
HAVING cnt > 1;


-- 3. Registros huérfanos (ventas sin dimensión asociada) ---------------
-- Productos inexistentes en ventas
SELECT v.VentaID, v.ProductoID
FROM FactVentasDetalle v
LEFT JOIN DimProducto p ON v.ProductoID = p.ProductoID
WHERE p.ProductoID IS NULL;

-- Eventos inexistentes en ventas
SELECT v.VentaID, v.EventoID
FROM FactVentasDetalle v
LEFT JOIN DimEventos e ON v.EventoID = e.EventoID
WHERE v.EventoID IS NOT NULL AND e.EventoID IS NULL;

-- Proveedores inexistentes en egresos
SELECT e.EgresoID, e.ProveedorID
FROM FactEgresosDetalle e
LEFT JOIN DimProveedor p ON e.ProveedorID = p.ProveedorID
WHERE e.ProveedorID IS NOT NULL AND p.ProveedorID IS NULL;


-- 4. Validación de distribuciones ----------------------
-- Chequea que PercentDist no sea negativo ni supere 100
SELECT 'Ventas' AS tabla, VentaID, PercentDist
FROM FactVentasDetalle
WHERE PercentDist < 0 OR PercentDist > 100
UNION ALL
SELECT 'Egresos', EgresoID, PercentDist
FROM FactEgresosDetalle
WHERE PercentDist < 0 OR PercentDist > 100;


-- 5. Validación de fechas ------------------------------
-- Fact con fecha inexistente en DimFecha
SELECT 'Ventas' AS tabla, VentaID, v.FechaID
FROM FactVentasDetalle v
LEFT JOIN DimFecha f ON v.FechaID = f.FechaID
WHERE f.FechaID IS NULL
UNION ALL
SELECT 'Egresos', EgresoID, e.FechaID
FROM FactEgresosDetalle e
LEFT JOIN DimFecha f ON e.FechaID = f.FechaID
WHERE f.FechaID IS NULL;
