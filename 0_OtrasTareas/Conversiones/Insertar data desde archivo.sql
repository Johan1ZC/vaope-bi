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
  'C:/Users/SOPORTE/Desktop/BBDD_Relacional_Vaope/Modelamiento de Arquitectura de Datos/Conversiones/locales_duplicados_mal_ingresados.csv'
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
  
  -- SELECT * FROM locations
