/* =======================================================================
   Huella: JZ-VAOPE-RPT-set_paginaWeb.Usuarios-003
   Artefacto: (Metodos de conversion)
   Autora: Johan Zuñiga Cordova  |  v3.0  |  2025-10-14
   Propósito: Usuarios registrados en la pagina y sus caracteristicas (para export/BI)
   ======================================================================= */

drop table if exists  vaope.dimUsuarioweb;
create table vaope.dimUsuarioweb
SELECT
id as usuarioID,
gender as genero,
created_at,
updated_at,
active,
-- id_facebook,
-- id_Google,
-- id_Tiktok,
case when ((id_facebook is null or id_facebook = "") and (id_google is null or id_google = "") and (id_tiktok is null or id_tiktok = "")) then "Registro_Standar" 
when (id_facebook is not null and id_facebook <> "" and (id_google is null or id_google = "") and (id_tiktok is null or id_tiktok = "")) then "Facebook"
when (id_google is not null and id_google <> "" and (id_facebook is null or id_facebook = "") and (id_tiktok is null or id_tiktok = "")) then "Google"
when (id_tiktok is not null and id_tiktok <> "" and (id_google is null or id_google = "") and (id_facebook is null or id_facebook = "")) then "Tiktok" 
when (id_facebook is not null and id_google is not null) then "Facebook+google"
when (id_facebook is not null and id_tiktok is not null) then "Facebook+tiktok"
when (id_google is not null and id_tiktok is not null) then "google+tiktok"
when (id_google is not null and id_tiktok is not null and id_facebook is not null) then "google+tiktok+facebook"
else "Otros" end Origen
-- select *
FROM vaope2.clients
where id in (select distinct usuarioID from vaope.factventasweb);  -- DESACTIVAR EN PRODUCCION, AQUI SE SELEECCIONA SOLO LA MUESTRA OK DEL BACKUP DEL BACKEND
-- 18551
-- select * from vaope.dimUsuarioweb where active = 0
ALTER TABLE vaope.dimUsuarioweb ADD INDEX idx_dimusuarioweb_user (usuarioID);

/*
-- select distinct origen,id_facebook,
id_Google,
id_Tiktok from vaope.dimUsuarioweb order by 1

456777
456778
30278

SELECT * FROM vaope2.clients
where document_number = 47195322


Facebook
Google
Tiktok

select * from vaope.factventasweb*/