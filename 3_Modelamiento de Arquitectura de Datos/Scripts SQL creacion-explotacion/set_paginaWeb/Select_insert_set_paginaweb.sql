use vaope2;

-- construccion de tabla
select 
DATE_FORMAT(b.created_at,'%Y%m%d') as fechaID,
HOUR(b.created_at) as horaID,
a.id as web_VentaID,
b.id as web_EntradaID,
b.product_id as eventoID,
title_small as Evento, -- pendiente
case when a.status = 0 then "Pendiente de pago" when a.status = 1 then "Pago Confirmado" when a.status = 2 then "En Evento"
when a.status = 3 then "" when a.status = 4 then "Finalizado" when a.status = 5 then "Anulado" 
when a.status = 6 then "Pendiente Devolución" when a.status = 7 then "Devuelto" when a.status = 9 then "Observado"  else "otros" end status_general,
case when b.status = 0 then "Nuevo" when b.status = 1 then "Pendiente de consumo" when b.status = 2 then "Pendiente de consumo"
when b.status = 5 then "Expirado" else "otros" end statusproducto,
detail as zona,
sum(b.quantity) cantidadProd, -- Verificar que pasa con un producto que tiene 10 entradas tipo BOX
b.unit_price as precio_unitario,
b.total_dicount as descuento,
b.total_price as total, -- pendiente
case when a.payment_method_id = 12 then 1 else 0 end esCortesia, -- pendiente obtene desde paymenth method
a.utm_source,
a.utm_campaign,
a.utm_medium,
a.client_id as usuarioID,
a.payment_method_id
from sales a
inner join vaope.lead_paginaweb_muestra d on a.id = d.id
left join sale_products b on a.id = b.sale_id and b.status = 1 
left join products c on b.product_id = c.id
-- where a.status = 1 -- and a.quantity_products < 1000 
group by 
DATE_FORMAT(b.created_at,'%Y%m%d'),
HOUR(b.created_at),
a.id,
b.id,
b.product_id,
title_small,
case when a.status = 0 then "Pendiente de pago" when a.status = 1 then "Pago Confirmado" when a.status = 2 then "En Evento"
when a.status = 3 then "" when a.status = 4 then "Finalizado" when a.status = 5 then "Anulado" 
when a.status = 6 then "Pendiente Devolución" when a.status = 7 then "Devuelto" when a.status = 9 then "Observado"  else "otros" end,
case when b.status = 0 then "Nuevo" when b.status = 1 then "Pendiente de consumo" when b.status = 2 then "Pendiente de consumo"
when b.status = 5 then "Expirado" else "otros" end,
detail,
b.unit_price,
b.total_dicount,
b.total_price,
case when a.payment_method_id = 12 then 1 else 0 end,
a.utm_source,
a.utm_campaign,
a.utm_medium,
a.client_id,
a.payment_method_id
order by 1,2 desc
-- 218420
