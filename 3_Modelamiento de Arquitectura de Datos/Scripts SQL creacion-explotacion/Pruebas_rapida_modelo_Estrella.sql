-- Totales del día por producto
SELECT f.FechaFacturaID, p.NomProducto, SUM(f.CantidadProd) Cant, SUM(f.Total) Total
FROM unidadanalisis.FactVentasDetalle f
JOIN unidadanalisis.DimProducto p ON p.ProductoID = f.ProductoID
GROUP BY f.FechaFacturaID, p.NomProducto;

-- Conciliación: total = sin impuesto + impuesto
SELECT SUM(Total) t, SUM(SinImpuesto)+SUM(Impuesto) chk FROM unidadanalisis.FactEgresosDetalle;