
#Tabla de eventos / Estrella: DimEventos
select * from vaope.products;
#Fecha_evento y hora_evento
#Ciudad+
#EventoID = id
#NombreEvento = title_small

#Tabla de ventas
select * from vaope.sales; 
#id = idventa
#Cantidad = suma de id
#Precio_unitario = suma de "total_price"
#TotalVenta = Cantidad x precio_unitario

#Tabla de detalle de ventas
select * from vaope.sale_products;

#Tabla de Organizadores/ name y business_name: Nombre de la empresa organizadora
select * from vaope.shops; 



select * from vaope.departments ##Tabla de departamentos


#Tabla de cliente que se registran en la WEB
select * from vaope.clients
#where id_facebook is not null
#where id_tiktok is not null
where id_google is not null

##UsuarioID = id -OK
##CanalOrigen = Donde se registran los clientes de diversos canales ? Redes sociales, web, face, etc // id_facebook, id_tiktok, id_google - OK
##Plataforma = Nombre de la plataforma de donde proviene el cliente. // registred_from - OK
#Genero = gender - OK
#Fecha_nacimiento = dathebird - OK
#estado_civil = marital_status - OK
#Zona = adress, department_id,province,"district_id" - OK
#name = nombre del usuario
#paternal_name = Apellidos del usuario 
#active = 1 es activo y 0 inactivo
#activated_method = metodo de activacion
#activated_at = fecha desde que se activo




