SELECT * FROM odoo_erp_fake.v_src_fact_ventas_detalle;



#INSERT INTO stg_* … SELECT … FROM v_src_* (una sola transacción).

#El resto del paquete lee stg_* así evitas que te cambie la fuente mientras corre.

#Crea una tabla física y refrescála con un job:
-- Tabla materializada
CREATE TABLE mv_src_fact_ventas_detalle AS
SELECT * FROM v_src_fact_ventas_detalle WHERE 1=0;

-- Refresco completo
TRUNCATE TABLE mv_src_fact_ventas_detalle;
INSERT INTO mv_src_fact_ventas_detalle
SELECT * FROM v_src_fact_ventas_detalle;

#Con incremental, usa una columna updated_at en origen y haz INSERT/REPLACE “desde la última carga”. (Opcional) Programar en MySQL:

#JOB
SET GLOBAL event_scheduler = ON;

CREATE EVENT ev_refresh_mv_ventas
ON SCHEDULE EVERY 1 HOUR
DO
  REPLACE INTO mv_src_fact_ventas_detalle
  SELECT * FROM v_src_fact_ventas_detalle;