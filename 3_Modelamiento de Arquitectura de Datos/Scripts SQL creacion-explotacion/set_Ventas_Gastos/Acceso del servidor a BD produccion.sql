use etl_prd;

select max(fechaCarga) from factventasdetalle;

select max(fechaCarga)  from factegresosdetalle;

select max(fechaid)  from factventasweb;

select * from llavedistribucionproducto

select * from jobs

SELECT user, host
FROM mysql.user
WHERE user = 'etl_prd';



CREATE USER 'etl_prd'@'38.25.18.20' IDENTIFIED BY 'Vaope2026*';

GRANT SELECT, SHOW VIEW ON etl_prd.* TO 'etl_prd'@'38.25.18.20';
FLUSH PRIVILEGES;

GRANT EXECUTE ON etl_prd.* TO 'etl_prd'@'38.25.18.20';
FLUSH PRIVILEGES;

GRANT SELECT, SHOW VIEW ON vaope_qa5.* TO 'etl_prd'@'38.25.18.20';
FLUSH PRIVILEGES;

GRANT EXECUTE ON vaope_qa5.* TO 'etl_prd'@'38.25.18.20';
FLUSH PRIVILEGES;

SHOW GRANTS FOR 'etl_prd'@'38.25.18.20';

