
-- ALIMENTAR TABLA DIMENSION HORAS

-- SELECT * FROM dimhora

USE dwh_dev;

-- Limpia primero si corresponde
-- TRUNCATE TABLE Dimhora;

INSERT INTO Dimhora
  (HoraID, Hora, Hora24, Hora12, AMPM, Tramo, BloqueHora, EshorarioLaboral)
SELECT
  hr                                        AS HoraID,
  MAKETIME(hr, 0, 0)                        AS Hora,
  hr                                        AS Hora24,
  CASE WHEN MOD(hr,12)=0 THEN 12 ELSE MOD(hr,12) END AS Hora12,
  CASE WHEN hr < 12 THEN 'AM' ELSE 'PM' END AS AMPM,
  CASE
    WHEN hr BETWEEN 0  AND 5  THEN 'Madrugada'
    WHEN hr BETWEEN 6  AND 11 THEN 'Mañana'
    WHEN hr BETWEEN 12 AND 17 THEN 'Tarde'
    ELSE 'Noche'
  END                                       AS Tramo,
  CONCAT(LPAD(hr,2,'0'), ':00-', LPAD(hr,2,'0'), ':59') AS BloqueHora,
  CASE WHEN hr BETWEEN 9 AND 18 THEN 1 ELSE 0 END       AS EshorarioLaboral
FROM (
  -- Generador 0..23 sin CTE
  SELECT o.u + t.t*10 AS hr
  FROM (SELECT 0 u UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) o
  CROSS JOIN (SELECT 0 t UNION ALL SELECT 1 UNION ALL SELECT 2) t
) gen
WHERE hr < 24
ORDER BY hr;


-- SELECT * FROM dimusuario
INSERT INTO dimusuario
	(usuarioID,genero,created_at,updated_at,esActivo,origen)
SELECT * FROM vaope.dimUsuarioweb;
-- 18551

-- Usuario desconocido
-- INSERT IGNORE INTO dwh_dev.Dimusuario (usuarioID, esActivo) VALUES (0, 0);

-- (Haz lo mismo si lo necesitas para otras dims:)
-- INSERT IGNORE INTO dwh_dev.Dimhora (HoraID, Hora24, Hora12, AMPM, Tramo, BloqueHora, EshorarioLaboral)
-- VALUES (-1, NULL, NULL, NULL, 'Desconocido', 'NA', 0);
-- INSERT IGNORE INTO dwh_dev.DimEventos (EventoID, ...) VALUES (0, ...);
-- INSERT IGNORE INTO dwh_dev.DimFecha (FechaID, ...)  VALUES (0, ...);


-- Usuarios que vienen de la fuente y NO existen en Dimusuario
INSERT INTO dwh_dev.Dimusuario (usuarioID, esActivo)
SELECT DISTINCT s.usuarioID, 1
FROM vaope.factventasweb s
LEFT JOIN dwh_dev.Dimusuario d ON d.usuarioID = s.usuarioID
WHERE s.usuarioID IS NOT NULL
  AND d.usuarioID IS NULL;
  
  -- nro de orfanos
  SELECT DISTINCT s.usuarioID
FROM vaope.factventasweb s
LEFT JOIN dwh_dev.Dimusuario d ON d.usuarioID = s.usuarioID
WHERE s.usuarioID IS NOT NULL
  AND d.usuarioID IS NULL;


-- SELECT * FROM factventasweb
INSERT INTO factventasweb
	(fechaID,horaID,web_ventaID,eventoid,nom_evento,status_general,cantidadprod,sub_total,discount,delivery,total_price,
    payment_commission,vaope_commission,sale_commission,total_deposit,total_deposit_new,escortesia,utm_source,utm_campaign,utm_medium,usuarioID,persons,
    payment_method_id,mp_nommetodo,mp_entidadfinanciera,mp_procesador_wallet,mp_red_tarjeta,mp_producto,pagos_count,metodos_distintos,mp_MetodoGrupo)
select * from vaope.factventasweb
-- 23746