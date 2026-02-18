SELECT * FROM dwh_dev.factventasweb
where payment_method_id = 8 and year(fechaid) = 2026

SELECT status_general,count(1) FROM dwh_dev.factventasweb
where payment_method_id = 8
group by status_general;


SELECT 
day(fechaid) dia
,count(1) Q
,sum(total_deposit_new) total_deposit_new
,sum(total_price) total_price
-- select *
FROM dwh_dev_4.factventasweb
where year(fechaid) >= 2026 and fechaid = 20260122 -- and month(fechaid) = 1 and day(fechaid) = 2
group by day(fechaid);

select *
FROM dwh_dev_4.factventasweb
where web_ventaId = 750244;

select id,created_at
from vaope_qa5.sales a
where id = 750244;

SELECT
  @@global.time_zone  AS global_tz,
  @@session.time_zone AS session_tz,
  NOW()               AS now_sesion,
  UTC_TIMESTAMP()     AS utc;
  
  SHOW COLUMNS FROM vaope_qa5.sales LIKE 'created_at';
  
  SET SESSION time_zone = '-05:00';
SELECT id, created_at FROM vaope_qa5.sales WHERE id = 750244;

SET SESSION time_zone = '+00:00';
SELECT id, created_at FROM vaope_qa5.sales WHERE id = 750244;







UTC +5



SELECT 
-- day(fechaid) dia
year(fechaid) Anio
,count(1) Q
,sum(total_price) total_price
,sum(payment_commission) payment_commission
,sum(vaope_commission) vaope_commission
,sum(sale_commission) sale_commission
,sum(total_deposit_new) total_deposit_new
,sum((total_price-(ifnull(payment_commission,0)+ifnull(vaope_commission,0)+ifnull(sale_commission,0)))) as total_deposit_new_fix
,sum(payment_commission+vaope_commission+sale_commission+total_deposit_new) total_price_val
-- select *
FROM dwh_dev_4.factventasweb
where status_general in ('Pago confirmado','En Evento') and esCortesia <> 1 and payment_method_id <> 8 -- and fechaid = 20260101 -- < 20260201
-- group by day(fechaid);
group by year(fechaid)
order by 1 asc;

select * from dwh_dev_3.factventasweb
where year(fechaid) >= 2026 and month(fechaid) = 1 and day(fechaid) = 1;


select * from vaope_qa4.sales
where year(created_at) >= 2026 and month(created_at) = 1 and day(created_at) = 1;

select * from dwh_dev_4.factegresosdetalle;

select count(1) q from vaope_qa5.categories;
select count(1) q from vaope_qa5.clients;
select count(1) q from vaope_qa5.departments;
select count(1) q from vaope_qa5.districts;
select count(1) q from vaope_qa5.event_metrics;
select count(1) q from vaope_qa5.locations;
select count(1) q from vaope_qa5.payment_methods;
select count(1) q from vaope_qa5.product_liquidation_detail;
select count(1) q from vaope_qa5.products;
select count(1) q from vaope_qa5.provinces;
select count(1) q from vaope_qa5.sale_payments;
select count(1) q from vaope_qa5.sales;
select count(1) q from vaope_qa5.shops;


select * from vaope.factventasweb
SELECT mp_NomMetodo,count(1) Q FROM vaope.factventasweb group by mp_NomMetodo order by 1 desc
SELECT mp_MetodoGrupo,count(1) Q FROM vaope.factventasweb group by mp_MetodoGrupo order by 1 desc


select 
  a.mp_EntidadFinanciera
  ,a.mp_Producto        
  ,sum(a.pagos_count) pagos_count      
  ,sum(a.metodos_distintos) metodos_distintos
  ,count(1) Q
  FROM vaope.factventasweb a
  group by  a.mp_EntidadFinanciera
  ,a.mp_Producto
  order by 1 desc
  
    select 
  a.mp_EntidadFinanciera
  ,mp_Procesador_Wallet
  ,mp_Red_Tarjeta
  ,a.mp_Producto        
  ,sum(a.pagos_count) pagos_count      
  ,sum(a.metodos_distintos) metodos_distintos
  ,count(1) Q
  FROM vaope.factventasweb a
  group by 
   a.mp_EntidadFinanciera
  ,mp_Procesador_Wallet
  ,mp_Red_Tarjeta
  ,a.mp_Producto 
  order by 1 desc
  
SELECT COUNT(*) FROM vaope.factventasweb order by 1 desc;  
SELECT year(fechaID) year,COUNT(*) FROM vaope.factventasweb group by year(fechaID) order by 1 desc;
SELECT COUNT(*) FROM dwh_dev_4.factventasweb order by 1 desc;  
SELECT year(fechaID) year,COUNT(*) FROM dwh_dev_4.factventasweb group by year(fechaID) order by 1 desc;


use dwh_dev_4;

select * from dimfecha;
select * from dimhora;
select * from dimusuario;
select * from factventasweb;


SELECT * FROM dimeventos;
select * from eventosorganizador_detalle;
select * from dimorganizadores;

select * from dimlocalevento;
select * from dimubicacion; 

