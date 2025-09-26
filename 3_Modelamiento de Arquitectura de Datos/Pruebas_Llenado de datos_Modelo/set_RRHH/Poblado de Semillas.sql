SELECT * FROM dw_modelizacion.factventasdetalle;


-- Charset/engine (opcional si tu instancia ya lo hereda)
3ALTER DATABASE dw_modelizacion CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- Dimensiones con clave 0
INSERT IGNORE INTO DimFecha (FechaID, Fecha, Anio, Mes, Trimestre, DiaSemana)
VALUES (0, '1900-01-01', 1900, 1, 1, 'NA');
-- select * from DimFecha

INSERT IGNORE INTO DimUbicacion (UbicacionID, Pais, Departamento, Provincia, Distrito)
VALUES (0, 'N/A', 'N/A', 'N/A', 'N/A');
-- select * from DimUbicacion

INSERT IGNORE INTO DimLocalEvento (LocalEventoID, UbicacionID) VALUES (0, 0);
-- select * from DimLocalEvento

INSERT IGNORE INTO DimEventos (EventoID, NombreEvento, FechaInicio, FechaFin, LocalEventoID)
VALUES (0, 'N/A', '1900-01-01', NULL, 0);
-- select * from DimEventos

INSERT IGNORE INTO DimProducto (ProductoID, NomProducto, CategoriaProducto)
VALUES (0, 'N/A', 'N/A');
-- select * from DimProducto

INSERT IGNORE INTO DimProveedor (ProveedorID, NomProveedor, Descripcion)
VALUES (0, 'N/A', 'N/A');
-- select * from DimProveedor

INSERT IGNORE INTO DimVendedor (VendedorID, Vendedor) VALUES (0, 'N/A');
-- select * from DimVendedor

INSERT IGNORE INTO DimTiposGasto (TipoGastoID, NombreGasto) VALUES (0, 'N/A');
-- select * from DimTiposGasto

INSERT IGNORE INTO DimEstadoFactura (EstadoFacturaID, EstadoFactura) VALUES (0, 'N/A');
-- select * from DimEstadoFactura

INSERT IGNORE INTO DimOrganizadores (OrganizadorID, Nombre, TipoOrg) VALUES (0, 'N/A', 'N/A');
-- select * from DimOrganizadores

INSERT IGNORE INTO DimCuentaAnalitica (CuentaAnaliticaID, anio, Presupuesto, Nombre)
VALUES (0, 1900, 0.00, 'N/A');
-- select * from DimCuentaAnalitica
