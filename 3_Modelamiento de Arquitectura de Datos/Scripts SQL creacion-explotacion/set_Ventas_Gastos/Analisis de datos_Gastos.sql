
SELECT sum(SinImpuesto) simimpuesto,sum(impuesto) impuesto, sum(total) total
 FROM colaborativa_etl.FactEgresosDetalle
 where year(fechaid) = 2025;
 

  SELECT fechaid,count(1) Q
-- select *
 FROM colaborativa_etl.FactEgresosDetalle
  where year(fechaid) = 2025
group by fechaid order by 1 desc;



select facturaID,sinImpuesto,impuesto,total  
-- select *
FROM colaborativa_etl.FactEgresosDetalle
where year(fechaid) = 2025 
AND facturaid = 'E001-00000059'


select facturaID,sinImpuesto,impuesto,total  
-- select *
FROM colaborativa_etl.FactEgresosDetalle
where year(fechaid) = 2025 
AND facturaid = 'SB01-0571094872'


 select *
FROM colaborativa_etl.FactEgresosDetalle
where year(fechaid) = 2025 
AND facturaid = 'E001-00000537'



select a.*,b.NomProducto
 FROM colaborativa_etl.FactEgresosDetalle a
 inner join colaborativa_etl.DimProducto b on a.ProductoID = b.ProductoID
  where year(fechaid) = 2025 -- AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  
  
select b.NomProducto,sum(sinImpuesto)  sinImpuesto, count(1) Q
 FROM colaborativa_etl.FactEgresosDetalle a
 inner join colaborativa_etl.DimProducto b on a.ProductoID = b.ProductoID
  where year(fechaid) = 2025 -- AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  group by b.NomProducto
  order by 3,2 desc;
  
  
  select b.categoriaProducto,sum(sinImpuesto)  sinImpuesto, count(1) Q, sum(cantidadProd) cantidadProd
 FROM colaborativa_etl.FactEgresosDetalle a
 inner join colaborativa_etl.DimProducto b on a.ProductoID = b.ProductoID
  where year(fechaid) = 2025 -- AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  group by b.categoriaProducto
  order by 2 desc;
  
  
    select b.nombre,sum(sinImpuesto)  sinImpuesto, count(1) Q, sum(cantidadProd) cantidadProd
 FROM colaborativa_etl.FactEgresosDetalle a
 inner join colaborativa_etl.DimDistribucionAnalitica b on a.DistribucionID = b.DistribucionID
  where year(fechaid) = 2025 -- AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  group by b.nombre
  order by 2 desc;
  
  select b.nombre,c.nomproducto,sum(sinImpuesto)  sinImpuesto, count(1) Q, sum(cantidadProd) cantidadProd
 FROM colaborativa_etl.FactEgresosDetalle a
 inner join colaborativa_etl.DimDistribucionAnalitica b on a.DistribucionID = b.DistribucionID
inner join colaborativa_etl.DimProducto c on a.ProductoID = c.ProductoID
  where year(fechaid) = 2025 -- AND facturaid in ('(03) Boleta BOB1-00000030','(03) Boleta BOB1-00000029')
  group by b.nombre,c.nomproducto
  order by 1 desc;
  
  
    -- extraer registros sin cuenta analitica
  SELECT * FROM colaborativa_etl.FactEgresosDetalle
  where distribucionID = 0;
  
    SELECT sum(sinimpuesto) sinimpuesto FROM colaborativa_etl.FactEgresosDetalle
  where distribucionID = 0;

