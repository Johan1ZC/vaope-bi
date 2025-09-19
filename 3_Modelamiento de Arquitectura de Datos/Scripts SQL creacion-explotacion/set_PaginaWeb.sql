use vaope2;

select * from sales -- datos de vetas
where id = 493091;

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
where id = 493091;
-- Revisar product_id, seler_id, created_at, status, client_id, shop_id, payment_method_id

select * from sale_products -- datos de las entradas
where sale_id = 493091
-- Revisar productid, tipo_entrada_id


-- validacion 1 a 1
select * from sales a
inner join sale_products b on a.id = b.sale_id 
where a.status = 1 and b.status = 1 and quantity_products < 1000 
order by 1,2 desc
-- and a.id <> 493091

select * from cart_transactions


-- construccion de tabla
select 
a.id as web_ventaID,
b.id as web_entradaID,
b.created_at as fecha,
product_id as eventoID,
slug as Evento, -- pendiente
a.client_id as usuarioID,
a.utm_source,
a.utm_campaign,
a.utm_medium,
count(1) cantidadProd,
sum(quantity) cantidadProd_, -- Verificar que pasa con un producto que tiene 10 entradas tipo BOX
b.unit_price as precio_unitario,
b.total_dicount as descuento,
b.total_price as sinImpuesto, -- pendiente
prcIGV = "", -- pendiente
impuesto = "", -- pendiente
total = "",  -- pendiente
esCortesia = "", -- pendiente obtene desde paymenth method
moneda = "",
tipo_cambio = "",
detail as zona,
a.paymenth_method_id,
-- Adicionales:
b.persons
from sales a
left join sale_products b on a.id = b.sale_id 
left join products c on a.product_id = c.id
where a.status = 1 and b.status = 1 and quantity_products < 1000 
order by 1,2 desc
-- and a.id <> 493091


select * from sales

select * from sale_products a

select a.*,b.id from sale_products a
inner join products b on a.product_id = b.id

select * from products

select * from sale_orders

select * from sale_order_details

select * from sale_payments -- datos de todos los pagos