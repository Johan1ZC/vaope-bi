SELECT * FROM vaope_qa2.product_liquidation_operations;
select * from vaope_qa2.var_masters
where root = 9

-- Pauta y contenido.
13	4	04	PAUTA PUBLICITARIA  (Falta contenido)
68	4		Publicidad

-- validadores
14	5	03	SERV VALIDADORES
58	17	11	SUPERVISOR VALIDADORES
56	15	09	PUNTO DE VENTA

select * from vaope_qa4.var_masters
where code_secondary IS NOT NULL;

SELECT 
* 
-- max(event_id)
FROM vaope_qa4.product_liquidation_operations a
 -- inner join vaope_qa4.var_masters b on a.type_operation = b.cod and b.deleted_at is null and root = 9 -- and is_json = 1
where a.deleted_at is null and event_id = 3479
order by a.id desc;

SELECT 
* 
-- max(event_id)
FROM vaope_qa4.product_liquidation_operations a
left join vaope_qa4.var_masters b on a.type_operation = b.cod and b.deleted_at is null and b.root = 9 and b.code_secondary IS NOT NULL-- and is_json = 1
where a.deleted_at is null and event_id = 3479
order by a.id desc;

SELECT 
* 
-- max(event_id)
FROM vaope_qa4.product_liquidation_operations a
inner join vaope_qa4.var_masters b on a.type_operation = b.cod and b.deleted_at is null and root = 9 -- and is_json = 1
where a.deleted_at is null and event_id = 3479
order by a.id desc;
-- 

-- TRAER REGISTROS 2026 DE PRODUCTOS
SELECT 
a.id,product_liquidation_id,event_id,type_operation,amount,user_id,description,requires_approval,charged_to,payment_method,a.created_at,a.updated_at,
approved,approved_by,approved_at,b.code_secondary,b.name
-- * 
-- max(event_id)
FROM vaope_qa4.product_liquidation_operations a
left join vaope_qa4.var_masters b on a.type_operation = b.cod and b.deleted_at is null and b.root = 9 and b.code_secondary IS NOT NULL-- and is_json = 1
where a.deleted_at is null and year(a.created_at) >= 2026 
order by a.id desc;


SELECT 
* 
-- max(event_id)
FROM vaope_qa4.product_liquidation_operations a
where a.deleted_at is null and year(a.created_at) >= 2026 
order by a.id desc;



-- left join vaope_qa2.products c on a.event_id = c.id
where a.id in (3155,3156,3157,3158) AND a.deleted_at is null
order by a.created_at desc


SELECT 
* 
-- max(event_id)
FROM vaope_qa4.product_liquidation_operations a
inner join vaope_qa4.var_masters b on a.type_operation = b.cod and b.deleted_at is null and root = 9 -- and is_json = 1
where a.deleted_at is null -- and event_id = '3492'
order by event_id desc