/* =======================================================================
   Huella: JZ-VAOPE-DW-SET_PAGINAWEB-EVENTOS-LOCALES-ZONAS-ORGANIZADORES
   Proyecto: VAOPE – Data Warehouse (PAGINAWEB)
   Artefacto: explotacion_datos_eventos_locacion_organizadores.sql (DDL)
   Autor: Johan Zuñiga Cordova  |
   Email: johan@vaope.com | johan.zcor.upc@gmail.com
   Licencia: MIT
   Versión: v1.1
   Fecha: 2025-10-28
   Entorno: MySQL 8.0  |  Schema: vaope2
   Dependencias: products, categories, locations, districts, provinces, departments, shops
   creadas peviamente.
   Descripción:
     - Extraer datos desde products, categories, locations, districts, provinces, departments, shops
   Métricas rápidas del DDL:
     - Entidades: 4
   ADR relacionado:
   Convención de nombres:
     - Dim* (dimensiones)
   Propósito:
     - Extraer informacion de negocio desde las tablas products, categories, locations, districts, provinces, departments, shops
     para completar informacion requerida del modelo estrella sobre EVENTOS-LOCALES-ZONAS-ORGANIZADORES
   ======================================================================= */

use vaope2;

-- drop table dimEventos
create temporary table dimEventos
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
from products p
left join categories c on p.category_id = c.id;
-- select * from dimEventos

-- drop table dimlocalevento
create temporary table dimlocalevento
select 
id as localEventoID, 
UPPER(place_name) as Nomlocal,
district_id as ubicacionID
from locations;
-- select * from dimlocalevento

create temporary table dimUbicacion
select 
d.id as ubicacionID,
"Peru" as pais,
dp.description as departamento,
p.description as provincia,
d.description as distrito,
d.id as ubigeo
from districts d
inner join provinces p on d.province_id = p.id
inner join departments dp on p.department_id = dp.id;
-- select * from dimUbicacion

create temporary table dimOrganizadores
select
id as organizadorID,
upper(name) as nombre,
case 
	when type_doc = 'RUC' then "Empresa" 
	when type_doc = 'DNI' then "Persona" 
    else "otros" end tipoOrg
from shops;
-- select * from dimOrganizadores

/*
select * from districts -- distritos
select * from provinces -- provincias
select * from departments -- departamentos
select * from categories -- categorias de evento
select * from products -- detalle de eventos
select * from locations -- locales del evento
select * from shops -- Organizadores de eventos
select * from shop_categories -- categoria de organizadores por tipos de evento.
-- shop_id = organizador
*/