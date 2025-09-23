use vaope2;

select * from sales -- datos de vetas
where id = 499585;

select distinct status,count(1) q from sales group by  status -- datos de vetas
-- status
-- 5	61401
-- 2	172151
-- 1	275052
-- 7	7651
-- 6	43
--  8	204
-- 9	5
-- 0	46

select * from sale_products -- datos de las entradas
where sale_id = 493091

select distinct status,count(1) q from sale_products group by  status -- datos de las entradas
-- status
-- 1	225993
-- 0	3263

select * from sales -- datos de vetas
where status = 1 and quantity_products < 1000  -- id = 493091;
-- Revisar product_id, seler_id, created_at, status, client_id, shop_id, payment_method_id

select * from sale_products -- datos de las entradas
where sale_id = 499585
-- Revisar productid, tipo_entrada_id


-- validacion 1 a 1
select * from sales a
inner join sale_products b on a.id = b.sale_id 
where a.status = 1 and b.status = 1 and quantity_products < 1000 
order by 1,2 desc
-- and a.id <> 493091

select * from cart_transactions

use vaope2;

select count(*)
from sales a
left join sale_products b on a.id = b.sale_id and b.status = 1 
left join products c on b.product_id = c.id
where a.quantity_products < 1000 

-- drop table sale_qp
create temporary table sale_qp
select 
-- *
id,
quantity_products
from sales
-- where status = 1
-- select * from sale_qp
-- 516553

-- drop table sale_products_qp
create temporary table sale_products_qp
select 
-- *
sale_id,
sum(quantity)  quantity,
count(1) conteo,
sum(quantity)  - count(1) Diferencia
-- select *
from sale_products
-- where status = 1
group by  sale_id
order by 4 desc
-- select * from sale_products_qp order by 4 desc
-- 26017

-- drop table vaope.lead_paginaweb_muestra
create table vaope.lead_paginaweb_muestra
select
a.id,
a.quantity_products,
b.quantity
from sale_qp a
inner join sale_products_qp b on a.id = b.sale_id and a.quantity_products = b.quantity
-- select * from vaope.lead_paginaweb_muestra
-- 23746


use vaope2;

-- construccion de tabla
select 
a.id as web_ventaID,
b.id as web_entradaID,
b.created_at as fecha,
b.product_id as eventoID,
title_small as Evento, -- pendiente
a.client_id as usuarioID,
a.utm_source,
a.utm_campaign,
a.utm_medium,
-- count(1) cantidadProd,
sum(b.quantity) cantidadProd_, -- Verificar que pasa con un producto que tiene 10 entradas tipo BOX
b.unit_price as precio_unitario,
b.total_dicount as descuento,
b.total_price as Total, -- pendiente
case when a.payment_method_id = 12 then 1 else 0 end esCortesia, -- pendiente obtene desde paymenth method
detail as zona,
a.payment_method_id,
-- Adicionales:
b.persons
from sales a
inner join vaope.lead_paginaweb_muestra d on a.id = d.id
left join sale_products b on a.id = b.sale_id and b.status = 1 
left join products c on b.product_id = c.id
-- where a.status = 1 -- and a.quantity_products < 1000 
group by a.id,
b.id,
b.created_at,
b.product_id,
slug, -- pendiente
a.client_id,
a.utm_source,
a.utm_campaign,
a.utm_medium,
b.unit_price,
b.total_dicount,
b.total_price, -- pendiente
case when a.payment_method_id = 12 then 1 else 0 end, -- pendiente obtene desde paymenth method
detail,
a.payment_method_id,
-- Adicionales:
b.persons
order by 1,2 desc
-- and a.id <> 493091
-- 218420


select * from vaope2.products

select * from vaope2.sales

select * from vaope2.sale_products a

select a.*,b.id from sale_products a
inner join products b on a.product_id = b.id

select * from products

select * from sale_orders

select * from sale_order_details

select * from sale_payments -- datos de todos los pagos

