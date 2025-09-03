use vaope_etl;

-- Duplicados en la granularidad (FacturaID, FacturaDetalleID)
SELECT FacturaID, FacturaDetalleID, COUNT(*) c
FROM FactVentasDetalle
GROUP BY 1,2 HAVING c > 1;

SELECT FacturaID, FacturaDetalleID, COUNT(*) c
FROM FactEgresosDetalle
GROUP BY 1,2 HAVING c > 1;

-- FKs faltantes (anti-join) antes de cargar a la fact
SELECT COUNT(*) faltan_producto
FROM Stg_VentasDetalle s
LEFT JOIN DimProducto d ON d.ProductoID = s.ProductoID
WHERE d.ProductoID IS NULL;

-- Coherencia del bridge evento–organizador
SELECT eo.EventoID
FROM eventosOrganizador_Detalle eo
LEFT JOIN DimEventos e ON e.EventoID = eo.EventoID
LEFT JOIN DimOrganizadores o ON o.OrganizadorID = eo.OrganizadorID
WHERE e.EventoID IS NULL OR o.OrganizadorID IS NULL;


-- Validaciones de total sin impuesto ventas
SELECT 
-- * ,
sum(SinImpuesto) TotalSinimpuesto
-- *
FROM vaope_etl.FactVentasDetalle;


-- Validaciones de total sin impuesto egreso
SELECT 
-- * ,
sum(SinImpuesto) TotalSinimpuesto
-- *
FROM vaope_etl.FactEgresosDetalle;


