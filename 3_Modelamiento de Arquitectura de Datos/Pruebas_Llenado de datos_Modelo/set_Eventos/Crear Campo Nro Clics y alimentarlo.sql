SELECT * FROM dwh_dev.dimeventos;


-- CREAR NUEVO CAMPO NROCLICS
use dwh_dev;
alter table dwh_dev.dimeventos add column NroClics INT

-- ACTUALIZAR CAMPO NROCLICS FICTICIO
update dwh_dev.dimeventos a
Set NroClics = EventoID * 98
where EventoID > 0