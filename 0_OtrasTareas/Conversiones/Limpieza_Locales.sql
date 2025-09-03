

SELECT * FROM ua_analisis.locations

use ua_analisis;

drop temporary table if exists lugares_temp;
create temporary table lugares_temp as
select place_name,count(1) q
#into @temporal
from ua_analisis.locations
group by place_name
order by 2 desc
-- select * from lugares_temp


select  
 distinct a.place_name, a.street_address, a.address_locality
-- *
from ua_analisis.locations a
inner join lugares_temp b on a.place_name = b.place_name and q >= 2
order by a.place_name desc

locales repetidos y cantidad de eventos duplicados

-- select * from ua_analisis.locations order by 3 desc