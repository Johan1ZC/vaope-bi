CREATE USER 'pbi_reader'@'%' IDENTIFIED BY 'Vaope2025*';
GRANT SELECT ON vaope_etl.* TO 'pbi_reader'@'%';
FLUSH PRIVILEGES;