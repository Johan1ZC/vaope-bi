
-- ALIMENTAR TABLA DIMENSION HORAS

-- SELECT * FROM dimhora

USE dwh_dev;

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
    SELECT DATE_ADD('2016-01-01', INTERVAL n DAY) AS fecha
    FROM nums
    WHERE DATE_ADD('2016-01-01', INTERVAL n DAY) <= '2030-12-31'
) f
ORDER BY f.fecha;


SELECT *
FROM dimfecha
WHERE Fecha BETWEEN '2016-01-01' AND '2016-01-05';



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
-- 18551

-- Usuario desconocido
-- INSERT IGNORE INTO dwh_dev.Dimusuario (usuarioID, esActivo) VALUES (0, 0);

-- (Haz lo mismo si lo necesitas para otras dims:)
-- INSERT IGNORE INTO dwh_dev.Dimhora (HoraID, Hora24, Hora12, AMPM, Tramo, BloqueHora, EshorarioLaboral)
-- VALUES (-1, NULL, NULL, NULL, 'Desconocido', 'NA', 0);
-- INSERT IGNORE INTO dwh_dev.DimEventos (EventoID, ...) VALUES (0, ...);
-- INSERT IGNORE INTO dwh_dev.DimFecha (FechaID, ...)  VALUES (0, ...);


-- Usuarios que vienen de la fuente y NO existen en Dimusuario
INSERT INTO dwh_dev.Dimusuario (usuarioID, esActivo)
SELECT DISTINCT s.usuarioID, 1
FROM vaope.factventasweb s
LEFT JOIN dwh_dev.Dimusuario d ON d.usuarioID = s.usuarioID
WHERE s.usuarioID IS NOT NULL
  AND d.usuarioID IS NULL;
  
  -- nro de orfanos
  SELECT DISTINCT s.usuarioID
FROM vaope.factventasweb s
LEFT JOIN dwh_dev.Dimusuario d ON d.usuarioID = s.usuarioID
WHERE s.usuarioID IS NOT NULL
  AND d.usuarioID IS NULL;
  
  -- Insertar productos (Eventos)
  -- drop temporary table dimEventos_
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
from vaope_qa2.products p
left join vaope_qa2.categories c on p.category_id = c.id;
-- select * from vaope.dimEventos_

INSERT INTO dwh_dev.dimeventos
	(eventoID,NombreEvento,fechaInicio,FechaFin,localeventoID,Stock,catogoria)
SELECT eventoID,NombreEvento,IFNULL(fechaInicio, '2000-01-01'),FechaFin,localeventoID,Stock,categoria FROM vaope.dimEventos_;
-- select * from dwh_dev.dimeventos

/*
SET FOREIGN_KEY_CHECKS = 0;
truncate table dwh_dev.dimeventos
SET FOREIGN_KEY_CHECKS = 1;
*/


-- Eventos que vienen de la fuente y NO existen en DimEventos
INSERT INTO dwh_dev.dimeventos (eventoID, NombreEvento,fechaInicio)
SELECT DISTINCT s.eventoid, nom_evento, '2000-01-01'
FROM vaope.factventasweb s
LEFT JOIN dwh_dev.dimeventos d ON d.eventoid = s.eventoid
WHERE s.eventoid IS NOT NULL
  AND d.eventoid IS NULL;
  
  -- nro de orfanos
  SELECT DISTINCT s.eventoid
FROM vaope.factventasweb s
LEFT JOIN dwh_dev.dimeventos d ON d.eventoid = s.eventoid
WHERE s.eventoid IS NOT NULL
  AND d.eventoid IS NULL;


-- SELECT * FROM factventasweb
INSERT INTO factventasweb
	(fechaID,horaID,web_ventaID,eventoid,nom_evento,status_general,cantidadprod,sub_total,discount,delivery,total_price,
    payment_commission,vaope_commission,sale_commission,total_deposit,total_deposit_new,escortesia,utm_source,utm_campaign,utm_medium,usuarioID,persons,
    payment_method_id,mp_nommetodo,mp_entidadfinanciera,mp_procesador_wallet,mp_red_tarjeta,mp_producto,pagos_count,metodos_distintos,mp_MetodoGrupo)
select * from vaope.factventasweb
where year(fechaid) in (2026)
-- 23746
-- 9833 - 2021
-- 76138 - 2022
-- 102952 - 2023
-- 204266 - 2024
-- 338236 - 2025
-- 7946 - 2026


SELECT fechaID,COUNT(*) FROM vaope.factventasweb group by fechaID order by 1 desc;
SELECT year(fechaID) year,COUNT(*) FROM vaope.factventasweb group by year(fechaID) order by 1 desc;

select distinct length(nom_evento) from vaope.factventasweb order by 1 desc

-- AUMENTAR TAMAÑO DEL CAMPO NOM_EVENTO QUE LLEGA HASTA 160 CARACTERES
ALTER TABLE factventasweb
MODIFY nom_evento VARCHAR(250);

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
-- drop table vaope.dimlocalevento
create table vaope.dimlocalevento
select 
id as localEventoID, 
UPPER(place_name) as Nomlocal,
district_id as ubicacionID
from vaope_qa2.locations;
-- select * from vaope.dimlocalevento

/*
SET FOREIGN_KEY_CHECKS = 0;
truncate table dwh_dev.dimlocalevento
SET FOREIGN_KEY_CHECKS = 1;
*/

INSERT INTO dwh_dev.dimlocalevento
	(LocalEventoID,Nomlocal,ubicacionID)
select * from vaope.dimlocalevento
-- select * from dwh_dev.dimlocalevento


-- INSERTAR DATOS UBICACION:
-- drop table vaope.dimUbicacion
create table vaope.dimUbicacion
select 
d.id as ubicacionID,
"Peru" as pais,
dp.description as departamento,
p.description as provincia,
d.description as distrito,
d.id as ubigeo
from vaope_qa2.districts d
inner join vaope_qa2.provinces p on d.province_id = p.id
inner join vaope_qa2.departments dp on p.department_id = dp.id;
-- select * from vaope.dimUbicacion

/*
SET FOREIGN_KEY_CHECKS = 0;
truncate table dwh_dev.dimubicacion
SET FOREIGN_KEY_CHECKS = 1;
*/

INSERT INTO dwh_dev.dimubicacion
	(ubicacionID,pais,departamento,provincia,distrito,ubigeo)
select * from vaope.dimUbicacion
-- select * from dwh_dev.dimubicacion

-- INSERTAR DATOS DE ORGANIZADORES:
create table vaope.dimOrganizadores
select
id as organizadorID,
upper(name) as nombre,
case 
	when type_doc = 'RUC' then "Empresa" 
	when type_doc = 'DNI' then "Persona" 
    else "otros" end tipoOrg
from vaope_qa2.shops;
-- select * from vaope.dimOrganizadores

INSERT INTO dwh_dev.dimorganizadores
	(organizadorID,nombre,tipoOrg)
select * from vaope.dimOrganizadores;
-- select * from dwh_dev.dimorganizadores


-- INSERTAR DATOS DE ORGANIZADOR DETALLE:
INSERT INTO dwh_dev.eventosorganizador_detalle
	(organizadorID,EventoID)
select distinct organizadorID,EventoID from vaope.dimEventos_
-- SELECT * FROM dwh_dev.eventosorganizador_detalle ORDER BY 2 ASC


-- ACTUALIZAR DATOS DE IMPRESIONES POR EVENTO:
create table vaope.nroclics
SELECT product_id,sum(impression) nroClics FROM vaope_qa2.event_metrics
group by product_id;
-- select * from vaope.nroclics

-- SET SQL_SAFE_UPDATES = 0;
UPDATE 
-- select * from
dwh_dev.dimeventos A 
LEFT JOIN vaope.nroclics b
  ON a.EventoID = b.product_id
SET
  a.nroclics = b.nroclics
  where EventoID >= 1;
--  SET SQL_SAFE_UPDATES = 1;  -- vuelve a activarlo
-- select * from dwh_dev.dimeventos


select * from dwh_dev.dimfecha;
select * from dwh_dev.dimhora;
select * from dwh_dev.dimusuario;
select * from dwh_dev.factventasweb;


SELECT * FROM dwh_dev.dimeventos;
select * from dwh_dev.eventosorganizador_detalle;
select * from dwh_dev.dimorganizadores;

select * from dwh_dev.dimlocalevento;
select * from dwh_dev.dimubicacion;
