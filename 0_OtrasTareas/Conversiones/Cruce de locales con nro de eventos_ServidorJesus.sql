SHOW VARIABLES LIKE 'local_infile';


SELECT * FROM vaope.bi_event;

select * FROM vaope.location_reply a
where a.id in (428,666)

USE vaope;

-- create table vaope.location_norm AS
SELECT a.id,a.district_id,a.place_name,a.street_address,a.address_locality,a.created_at,a.updated_at,a.deleted_at, count(distinct b.id ) '>=1_Evento', 
case when count(distinct b.id ) >= 1 then 'Tiene evento asociado' else 'No tiene evento' end '¿Tiene Evento?'
-- select *
FROM vaope.location_reply a
left join vaope.products b on a.id = b.location_id
-- where a.id in (428,666)
-- where a.id in (602,53)
group by a.id,a.district_id,a.place_name,a.street_address,a.address_locality,a.created_at,a.updated_at,a.deleted_at
order by 9 desc;
-- SELECT * FROM location_norm

select * from vaope.products