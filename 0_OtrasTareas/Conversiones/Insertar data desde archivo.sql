CREATE DATABASE IF NOT EXISTS UA_ANALISIS
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
  
USE UA_ANALISIS;

CREATE TABLE locations (
  id BIGINT UNSIGNED PRIMARY KEY,
  district VARCHAR(10),
  place_name VARCHAR(255),
  street_address VARCHAR(255),
  address_locality VARCHAR(255)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Borra lo que se cargó mal (si procede)
TRUNCATE TABLE locations;

SET NAMES utf8mb4;

LOAD DATA LOCAL INFILE
  'C:/Users/SOPORTE/Desktop/vaope-bi/0_OtrasTareas/Conversiones/Locales V2/locations (1).csv'
INTO TABLE locations
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'           -- <==== aquí el cambio clave
OPTIONALLY ENCLOSED BY '"'         -- Excel pone comillas solo cuando hace falta
ESCAPED BY '"'                     -- para comillas dobles dentro del texto
LINES TERMINATED BY '\r\n'         -- en Windows; prueba '\n' si hiciera falta
IGNORE 1 LINES
(@id, @district, @place_name, @street_address, @address_locality)
SET
  id               = NULLIF(@id,''),
  district         = NULLIF(@district,''),
  place_name       = NULLIF(@place_name,''),
  street_address   = NULLIF(@street_address,''),
  address_locality = NULLIF(@address_locality,'');
  
  -- SELECT * FROM locations order by 3 asc
  
  
  
  CREATE TABLE products (
  id BIGINT UNSIGNED PRIMARY KEY,
  location_id VARCHAR(50)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Borra lo que se cargó mal (si procede)
TRUNCATE TABLE products;

SET NAMES utf8mb4;

LOAD DATA LOCAL INFILE
  'C:/Users/SOPORTE/Desktop/vaope-bi/0_OtrasTareas/Conversiones/Locales V2/products.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'           -- <==== aquí el cambio clave
OPTIONALLY ENCLOSED BY '"'         -- Excel pone comillas solo cuando hace falta
ESCAPED BY '"'                     -- para comillas dobles dentro del texto
LINES TERMINATED BY '\r\n'         -- en Windows; prueba '\n' si hiciera falta
IGNORE 1 LINES
(@id, @location_id)
SET
  id               = NULLIF(@id,''),
  location_id         = NULLIF(@location_id,'')
  
  -- SELECT * FROM products order by 2 asc
  
  
  
  -- create table vaope.location_norm AS
SELECT a.id,a.district,a.place_name,a.street_address,a.address_locality, count(distinct b.id ) '>=1_Evento', 
case when count(distinct b.id ) >= 1 then 'Tiene evento asociado' else 'No tiene evento' end '¿Tiene Evento?'
-- select *
FROM locations a
left join products b on a.id = b.location_id
-- where a.id in (428,666)
-- where a.id in (602,53)
group by a.id,a.district,a.place_name,a.street_address,a.address_locality
order by 1 asc;
-- SELECT * FROM vaope.location_norm

