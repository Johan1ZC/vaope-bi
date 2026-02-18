
-- ALIMENTAR TABLA DIMENSION HORAS

-- SELECT * FROM dimhora

USE etl_prd;
-- USE dwh_dev_4;
-- USE vaope;

/*
-- INSERTAR DATOS DE LA FECHA
-- Asegurar idioma español
DROP TEMPORARY TABLE IF EXISTS nums;
CREATE TEMPORARY TABLE nums (n INT);

INSERT INTO nums (n)
SELECT a.n + b.n * 10 + c.n * 100 + d.n * 1000
FROM
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
CROSS JOIN
 (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
  UNION ALL SELECT 5) d;



INSERT INTO dimfecha (
    FechaID,
    Fecha,
    Anio,
    Mes,
    Trimestre,
    NombreDia,
    NombreMes
)
SELECT
    CAST(DATE_FORMAT(f.fecha, '%Y%m%d') AS UNSIGNED) AS FechaID,
    f.fecha AS Fecha,
    YEAR(f.fecha) AS Anio,
    MONTH(f.fecha) AS Mes,
    QUARTER(f.fecha) AS Trimestre,

    CASE DAYOFWEEK(f.fecha)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miércoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sábado'
    END AS NombreDia,

    CASE MONTH(f.fecha)
        WHEN 1 THEN 'Enero'
        WHEN 2 THEN 'Febrero'
        WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Mayo'
        WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
    END AS NombreMes
FROM (
    SELECT DATE_ADD('2021-01-01', INTERVAL n DAY) AS fecha
    FROM nums
    WHERE DATE_ADD('2021-01-01', INTERVAL n DAY) <= '2030-12-31'
) f
ORDER BY f.fecha;


SELECT *
FROM dimfecha
WHERE Fecha BETWEEN '2016-01-01' AND '2016-01-05';


INSERT INTO etl_prd.dimfecha (fechaID, Fecha, Anio, Mes, Trimestre, NombreDia, NombreMes)
SELECT  s.fechaID, s.Fecha, s.Anio, s.Mes, s.Trimestre, s.NombreDia, s.NombreMes
FROM vaope.dimfecha s
LEFT JOIN etl_prd.dimfecha t
  ON t.fechaID = s.fechaID
WHERE t.fechaID IS NULL;



*/



-- Limpia primero si corresponde
-- TRUNCATE TABLE Dimhora;

INSERT INTO Dimhora
  (HoraID, Hora, Hora24, Hora12, AMPM, Tramo, BloqueHora, EshorarioLaboral)
SELECT
  hr                                        AS HoraID,
  MAKETIME(hr, 0, 0)                        AS Hora,
  hr                                        AS Hora24,
  CASE WHEN MOD(hr,12)=0 THEN 12 ELSE MOD(hr,12) END AS Hora12,
  CASE WHEN hr < 12 THEN 'AM' ELSE 'PM' END AS AMPM,
  CASE
    WHEN hr BETWEEN 0  AND 5  THEN 'Madrugada'
    WHEN hr BETWEEN 6  AND 11 THEN 'Mañana'
    WHEN hr BETWEEN 12 AND 17 THEN 'Tarde'
    ELSE 'Noche'
  END                                       AS Tramo,
  CONCAT(LPAD(hr,2,'0'), ':00-', LPAD(hr,2,'0'), ':59') AS BloqueHora,
  CASE WHEN hr BETWEEN 9 AND 18 THEN 1 ELSE 0 END       AS EshorarioLaboral
FROM (
  -- Generador 0..23 sin CTE
  SELECT o.u + t.t*10 AS hr
  FROM (SELECT 0 u UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) o
  CROSS JOIN (SELECT 0 t UNION ALL SELECT 1 UNION ALL SELECT 2) t
) gen
WHERE hr < 24
ORDER BY hr;


-- SELECT * FROM dimusuario
INSERT INTO dimusuario
	(usuarioID,genero,created_at,updated_at,esActivo,origen)
SELECT * FROM vaope.dimUsuarioweb;
-- select * from dimusuario
-- 18551
-- 680096
-- 688999
-- 713800

-- Usuario desconocido
-- INSERT IGNORE INTO dwh_dev.Dimusuario (usuarioID, esActivo) VALUES (0, 0);

-- (Haz lo mismo si lo necesitas para otras dims:)
-- INSERT IGNORE INTO dwh_dev.Dimhora (HoraID, Hora24, Hora12, AMPM, Tramo, BloqueHora, EshorarioLaboral)
-- VALUES (-1, NULL, NULL, NULL, 'Desconocido', 'NA', 0);
-- INSERT IGNORE INTO dwh_dev.DimEventos (EventoID, ...) VALUES (0, ...);
-- INSERT IGNORE INTO dwh_dev.DimFecha (FechaID, ...)  VALUES (0, ...);


-- Usuarios que vienen de la fuente y NO existen en Dimusuario
INSERT INTO Dimusuario (usuarioID, esActivo)
SELECT DISTINCT s.usuarioID, 1
FROM vaope.factventasweb s
LEFT JOIN dimusuario d ON d.usuarioID = s.usuarioID
WHERE s.usuarioID IS NOT NULL
  AND d.usuarioID IS NULL;
  
  -- nro de orfanos
  SELECT DISTINCT s.usuarioID
FROM vaope.factventasweb s
LEFT JOIN dimusuario d ON d.usuarioID = s.usuarioID
WHERE s.usuarioID IS NOT NULL
  AND d.usuarioID IS NULL;
  
SET SESSION time_zone = '-05:00';  
  -- Insertar productos (Eventos)
drop table if exists  vaope.dimEventos_;
create table vaope.dimEventos_
select 
p.id as eventoID,
location_id as localEventoID, 
upper(title_small) as nombreEvento,
TIMESTAMP(fecha_evento, hora_evento) as fechaInicio,
NULL as fechaFin,
c.name as categoria,
p.stock,
p.shop_id as organizadorID	
-- select *
from vaope_qa5.products p
left join vaope_qa5.categories c on p.category_id = c.id;
-- select * from vaope.dimEventos_
-- 3976



INSERT INTO dimeventos
	(eventoID,NombreEvento,fechaInicio,FechaFin,localeventoID,Stock,categoria)
SELECT eventoID,NombreEvento,IFNULL(fechaInicio, '2000-01-01'),FechaFin,localeventoID,Stock,categoria FROM vaope.dimEventos_;
-- select * from dwh_dev_4.dimeventos
-- select * from dimeventos

/*
SET FOREIGN_KEY_CHECKS = 0;
truncate table dwh_dev.dimeventos
SET FOREIGN_KEY_CHECKS = 1;
*/


-- Eventos que vienen de la fuente y NO existen en DimEventos
INSERT INTO dimeventos (eventoID, NombreEvento,fechaInicio)
SELECT DISTINCT s.eventoid, nom_evento, '2000-01-01'
FROM vaope.factventasweb s
LEFT JOIN dimeventos d ON d.eventoid = s.eventoid
WHERE s.eventoid IS NOT NULL
  AND d.eventoid IS NULL;
  
  -- nro de orfanos
  SELECT DISTINCT s.eventoid
FROM vaope.factventasweb s
LEFT JOIN dimeventos d ON d.eventoid = s.eventoid
WHERE s.eventoid IS NOT NULL
  AND d.eventoid IS NULL;


-- SELECT * FROM factventasweb
INSERT INTO factventasweb
	(fechaID,horaID,web_ventaID,eventoid,nom_evento,status_general,cantidadprod,sub_total,discount,delivery,total_price,
    payment_commission,vaope_commission,sale_commission,total_deposit,total_deposit_new,escortesia,utm_source,utm_campaign,utm_medium,usuarioID,persons,
    payment_method_id,mp_nommetodo,mp_entidadfinanciera,mp_procesador_wallet,mp_red_tarjeta,mp_producto,pagos_count,metodos_distintos,mp_MetodoGrupo)
select * from vaope.factventasweb
where year(fechaid) in (2026)
-- select * from factventasweb order by 4 desc
-- select web_ventaID,count(*) q from factventasweb group by web_ventaID order by 2 desc
-- 23746            Prod:
-- 9833 - 2021      9833  
-- 76138 - 2022     76138
-- 102952 - 2023    102952
-- 204266 - 2024    204266
-- 338236 - 2025    338236 
-- 43655 - 2026     43655


-- SELECT fechaID,COUNT(*) FROM vaope.factventasweb group by fechaID order by 1 desc;
SELECT COUNT(*) FROM vaope.factventasweb order by 1 desc;  
SELECT year(fechaID) year,COUNT(*) FROM vaope.factventasweb group by year(fechaID) order by 1 desc;
SELECT COUNT(*) FROM etl_prd.factventasweb order by 1 desc;  
SELECT year(fechaID) year,COUNT(*) FROM etl_prd.factventasweb group by year(fechaID) order by 1 desc;

select distinct length(nom_evento) from vaope.factventasweb order by 1 desc

-- AUMENTAR TAMAÑO DEL CAMPO NOM_EVENTO QUE LLEGA HASTA 160 CARACTERES
ALTER TABLE etl_prd.factventasweb
MODIFY COLUMN nom_evento VARCHAR(250);

-- VALIDACION DE REGISTROS ORIGEN Y FINAL

SELECT year(fechaID) year,COUNT(*) FROM vaope.factventasweb group by year(fechaID) order by 1 desc;

SELECT year(fechaID) year,COUNT(*) FROM dwh_dev.factventasweb group by year(fechaID) order by 1 desc;


select year(created_at) year
,sum(esActivo = 1) EsActivo
,sum(esActivo = 0) NoActivo 
,((sum(esActivo = 0) / sum(esActivo = 1)) *100 )  as prct
,((sum(esActivo = 0) / sum(esActivo = 1)) *100 ) -100 as prct
from dwh_dev.dimusuario
group by year(created_at)
order by 1,2 desc


-- INSERTAR DATOS LOCAL EVENTO:
drop table if exists vaope.dimlocalevento;
create table vaope.dimlocalevento
select 
id as localEventoID, 
UPPER(place_name) as Nomlocal,
district_id as ubicacionID
from vaope_qa5.locations;
-- select * from vaope.dimlocalevento
-- 1177
-- 1218

/*
SET FOREIGN_KEY_CHECKS = 0;
truncate table dwh_dev.dimlocalevento
SET FOREIGN_KEY_CHECKS = 1;
*/

INSERT INTO dimlocalevento
	(LocalEventoID,Nomlocal,ubicacionID)
select * from vaope.dimlocalevento
-- select * from dimlocalevento
-- 1177
-- 1218


-- INSERTAR DATOS UBICACION:
drop table if exists vaope.dimUbicacion;
create table vaope.dimUbicacion
select 
d.id as ubicacionID,
"Peru" as pais,
dp.description as departamento,
p.description as provincia,
d.description as distrito,
d.id as ubigeo
from vaope_qa5.districts d
inner join vaope_qa5.provinces p on d.province_id = p.id
inner join vaope_qa5.departments dp on p.department_id = dp.id;
-- select * from vaope.dimUbicacion
-- 1876
-- 1876

/*
SET FOREIGN_KEY_CHECKS = 0;
truncate table dwh_dev.dimubicacion
SET FOREIGN_KEY_CHECKS = 1;
*/

INSERT INTO dimubicacion
	(ubicacionID,pais,departamento,provincia,distrito,ubigeo6)
select * from vaope.dimUbicacion
-- select * from dimubicacion
-- 1876

-- INSERTAR DATOS DE ORGANIZADORES:
drop table if exists vaope.dimOrganizadores;
create table vaope.dimOrganizadores
select
id as organizadorID,
upper(name) as nombre,
case 
	when type_doc = 'RUC' then "Empresa" 
	when type_doc = 'DNI' then "Persona" 
    else "otros" end tipoOrg
from vaope_qa5.shops;
-- select * from vaope.dimOrganizadores
-- 830
-- 845

INSERT INTO dimorganizadores
	(organizadorID,nombre,tipoOrg)
select * from vaope.dimOrganizadores;
-- select * from dimorganizadores
-- select distinct organizadorID,COUNT(1) Q from dimorganizadores GROUP BY organizadorID ORDER BY 2 ASC;
-- 830
-- 845


-- INSERTAR DATOS DE ORGANIZADOR DETALLE:
INSERT INTO eventosorganizador_detalle
	(organizadorID,EventoID)
select distinct organizadorID,EventoID from vaope.dimEventos_
-- SELECT * FROM eventosorganizador_detalle ORDER BY 2 ASC
-- 3831
-- 3976


-- ACTUALIZAR DATOS DE IMPRESIONES POR EVENTO:
drop table if exists vaope.nroclics;
create table vaope.nroclics
SELECT product_id,sum(impression) nroClics FROM vaope_qa5.event_metrics
group by product_id;
-- select * from vaope.nroclics
-- 3297
-- 3417

-- SET SQL_SAFE_UPDATES = 0;
UPDATE 
-- select * from
dimeventos a
LEFT JOIN vaope.nroclics b
  ON a.EventoID = b.product_id
SET
  a.nroclics = ifnull(b.nroclics,0)
  where EventoID >= 0;
--  SET SQL_SAFE_UPDATES = 1;  -- vuelve a activarlo
-- select * from dimeventos
-- select * from vaope.nroclics
-- 3150
-- 3270


select * from dimfecha;
select * from dimhora;
select * from dimusuario;
select * from factventasweb;
SELECT * FROM dimeventos;
select * from eventosorganizador_detalle;
select * from dimorganizadores;
select * from dimlocalevento;
select * from dimubicacion;


-- TABLA DE CONTROL CONSOLIDADO:
SELECT *
FROM (
  -- DIMFECHA
  SELECT
    'dimfecha' AS tabla,
    COUNT(*)   AS cantidad_registros,
    NULL       AS max_fecha_actualizacion,
    MAX(Fecha) AS max_fecha_negocio,
    MAX(FECHAID) AS max_ID
  FROM dimfecha

  UNION ALL

  -- DIMHORA
  SELECT
    'dimhora' AS tabla,
    COUNT(*)  AS cantidad_registros,
    NULL      AS max_fecha_actualizacion,
    MAX(horaID) AS max_fecha_negocio,
    MAX(horaID) AS max_ID
  FROM dimhora

  UNION ALL

  -- DIMUSUARIO (ejemplo: si tuviera updated_at)
  SELECT
    'dimusuario' AS tabla,
    COUNT(*)     AS cantidad_registros,
    MAX(updated_at) AS max_fecha_actualizacion,
    MAX(created_at)         AS max_fecha_negocio,
    MAX(usuarioID) AS max_ID
  FROM dimusuario

  UNION ALL

  -- FACTVENTASWEB (ejemplo típico)
  SELECT
    'factventasweb' AS tabla,
    COUNT(*)        AS cantidad_registros,
    MAX(STR_TO_DATE(fechaID, '%Y%m%d')) AS max_fecha_actualizacion,
    MAX(STR_TO_DATE(fechaID, '%Y%m%d')) AS max_fecha_negocio,
    MAX(web_ventaid) AS max_ID
  FROM factventasweb

  UNION ALL

  -- DIMEVENTOS (ejemplo)
  SELECT
    'dimeventos' AS tabla,
    COUNT(*)     AS cantidad_registros,
    MAX(fechainicio) AS max_fecha_actualizacion,
    MAX(fechainicio) AS max_fecha_negocio,
    MAX(eventoid) AS max_ID
  FROM dimeventos

  UNION ALL

  -- EVENTOSORGANIZADOR_DETALLE (ejemplo)
  SELECT
    'eventosorganizador_detalle' AS tabla,
    COUNT(*) AS cantidad_registros,
    NULL AS max_fecha_actualizacion,
    NULL AS max_fecha_negocio,
    MAX(organizadorid) AS max_ID
  FROM eventosorganizador_detalle

  UNION ALL

  -- DIMORGANIZADORES (ejemplo)
  SELECT
    'dimorganizadores' AS tabla,
    COUNT(*) AS cantidad_registros,
    NULL AS max_fecha_actualizacion,
    NULL AS max_fecha_negocio,
    MAX(organizadorid) AS max_ID
  FROM dimorganizadores

  UNION ALL

  -- DIMLOCALEVENTO (ejemplo)
  SELECT
    'dimlocalevento' AS tabla,
    COUNT(*) AS cantidad_registros,
    NULL AS max_fecha_actualizacion,
    NULL AS max_fecha_negocio,
    MAX(localeventoid) AS max_ID
  FROM dimlocalevento

  UNION ALL

  -- DIMUBICACION (ejemplo)
  SELECT
    'dimubicacion' AS tabla,
    COUNT(*) AS cantidad_registros,
    NULL AS max_fecha_actualizacion,
    NULL AS max_fecha_negocio,
    MAX(ubicacionid) AS max_ID
  FROM dimubicacion
) t
ORDER BY 2 desc;

