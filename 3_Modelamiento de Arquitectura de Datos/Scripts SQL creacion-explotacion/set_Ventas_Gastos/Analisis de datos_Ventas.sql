SELECT * FROM colaborativa_etl.FactVentasDetalle;

SELECT sum(SinImpuesto) simimpuesto,sum(impuesto) impuesto, sum(total) total

 FROM colaborativa_etl.FactVentasDetalle;
 
SELECT sum(SinImpuesto) simimpuesto,sum(impuesto) impuesto, sum(total) total
 FROM colaborativa_etl.FactVentasDetalle
  where year(fechaid) = 2025;
 
 SELECT fechaid,count(1) Q
-- select *
 FROM colaborativa_etl.FactVentasDetalle
  where year(fechaid) = 2025
group by fechaid order by 1 desc;


select a.*,b.NomProducto
 FROM colaborativa_etl.FactVentasDetalle a
 inner join colaborativa_etl.DimProducto b on a.ProductoID = b.ProductoID
  where year(fechaid) = 2025 AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  
  
      select b.nomproducto,sum(sinImpuesto)  sinImpuesto, count(1) Q, sum(cantidadProd) cantidadProd
 FROM colaborativa_etl.FactVentasDetalle a
 inner join colaborativa_etl.DimProducto b on a.ProductoID = b.ProductoID
  where year(fechaid) = 2025 -- AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  group by b.nomproducto
  order by 2 desc;
  -- select * from colaborativa_etl.DimProducto
  
    select b.categoriaProducto,sum(sinImpuesto)  sinImpuesto, count(1) Q, sum(cantidadProd) cantidadProd
 FROM colaborativa_etl.FactVentasDetalle a
 inner join colaborativa_etl.DimProducto b on a.ProductoID = b.ProductoID
  where year(fechaid) = 2025 -- AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  group by b.categoriaProducto
  order by 2 desc;
  
  
   select b.nombre,sum(sinImpuesto)  sinImpuesto, count(1) Q, sum(cantidadProd) cantidadProd
 FROM colaborativa_etl.FactVentasDetalle a
 inner join colaborativa_etl.DimDistribucionAnalitica b on a.DistribucionID = b.DistribucionID
  where year(fechaid) = 2025 -- AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  group by b.nombre
  order by 2 desc;
  
  
  
  
  
  select b.nombre,c.nomproducto,sum(sinImpuesto)  sinImpuesto, count(1) Q, sum(cantidadProd) cantidadProd
 FROM colaborativa_etl_vaope.FactVentasDetalle a
 left join colaborativa_etl_vaope.DimDistribucionAnalitica b on a.DistribucionID = b.DistribucionID
left join colaborativa_etl_vaope.DimProducto c on a.ProductoID = c.ProductoID
  where year(fechaid) <= 20251110 -- AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  group by b.nombre,c.nomproducto
  order by 1 desc;  
  
    select b.tipoOrigen,sum(sinImpuesto)  sinImpuesto, count(1) Q, sum(cantidadProd) cantidadProd
 FROM colaborativa_etl.FactVentasDetalle a
 inner join colaborativa_etl.DimProducto b on a.ProductoID = b.ProductoID
  where year(fechaid) = 2025 -- AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  group by b.tipoOrigen
  order by 2 desc;
  
  -- extraer registros sin cuenta analitica
  SELECT * FROM colaborativa_etl.FactVentasDetalle
  where distribucionID is null;
  
     SELECT sum(sinimpuesto) sinimpuesto FROM colaborativa_etl.FactVentasDetalle
 where distribucionID is null;
 
   -- extraer registros sin Eventos desde producción
  SELECT * FROM colaborativa_etl_vaope.FactVentasDetalle
  where Eventoid is null;
  
     SELECT sum(sinimpuesto) sinimpuesto FROM colaborativa_etl_vaope.FactVentasDetalle
 where Eventoid is null;