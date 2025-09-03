-- Usuario solo para ETL SSIS
CREATE USER 'etl_ssis'@'localhost' IDENTIFIED BY 'Vaope2025**';
-- Permisos de lectura a la BD origen (ajusta el nombre)
GRANT SELECT ON bd_odoofake.* TO 'etl_ssis'@'localhost';
-- Permisos de carga a tu modelo estrella
GRANT SELECT, INSERT, UPDATE, DELETE ON unidadanalisis.* TO 'etl_ssis'@'localhost';
FLUSH PRIVILEGES;

GRANT SELECT, INSERT, UPDATE, DELETE ON dw_modelizacion.* TO 'etl_ssis'@'localhost';
FLUSH PRIVILEGES;



servidor: 192.168.0.67
usuario: webclient
password: password