USE dwh_dev;

/* Inserta datos sintéticos (ene-2024 .. dic-2025) para empresa = 'colaborativa'
   usando el ÚLTIMO día de cada mes como Fecha (debe existir en DimFecha). */

INSERT INTO dwh_dev.FactRedesSociales
(FechaID, empresa, plataformaRS,
 nuevos_Seguidores, nuevos_meGusta, nuevas_publicaciones,
 nuevas_visitasPerfil, nuevos_clics, nuevas_vistas,
 nuevos_comentarios, nuevos_compartidos, nuevos_guardados, nuevos_mensajesDM,
 inversionAds)
SELECT
  df.FechaID,
  'colaborativa' AS empresa,
  f.plataforma   AS plataformaRS,

  /* NuevosSeguidores */
  (CASE f.plataforma
      WHEN 'instagram' THEN 900
      WHEN 'tiktok'    THEN 750
      WHEN 'facebook'  THEN 450
      WHEN 'youtube'   THEN 300
   END + 15*f.idx + 5*MOD(f.idx,3)) AS nuevos_Seguidores,

  /* Interacciones = me gusta + comentarios + compartidos + guardados */
  

  /* nuevos_meGusta */
  (CASE f.plataforma
      WHEN 'instagram' THEN 600
      WHEN 'tiktok'    THEN 520
      WHEN 'facebook'  THEN 420
      WHEN 'youtube'   THEN 300
   END + 35*f.idx + 7*MOD(f.idx,4)) AS nuevos_meGusta,

  /* nuevas_publicaciones */
  (CASE f.plataforma
      WHEN 'instagram' THEN 26
      WHEN 'tiktok'    THEN 18
      WHEN 'facebook'  THEN 14
      WHEN 'youtube'   THEN 12
   END + MOD(f.idx,4)) AS nuevas_publicaciones,

  /* nuevas_visitasPerfil */
  (CASE f.plataforma
      WHEN 'instagram' THEN 1500
      WHEN 'tiktok'    THEN 1300
      WHEN 'facebook'  THEN 900
      WHEN 'youtube'   THEN 700
   END + 40*f.idx + 10*MOD(f.idx,6)) AS nuevas_visitasPerfil,

  /* nuevos_clics */
  (CASE f.plataforma
      WHEN 'instagram' THEN 300
      WHEN 'tiktok'    THEN 260
      WHEN 'facebook'  THEN 180
      WHEN 'youtube'   THEN 240
   END + 12*f.idx + 3*MOD(f.idx,5)) AS nuevos_clics,

  /* nuevas_vistas */
  (CASE f.plataforma
      WHEN 'instagram' THEN 52000
      WHEN 'tiktok'    THEN 80000
      WHEN 'facebook'  THEN 38000
      WHEN 'youtube'   THEN 95000
   END + 3200*f.idx + 500*MOD(f.idx,5)) AS nuevas_vistas,

  /* Desgloses */
  (50 + 3*f.idx + MOD(f.idx,5)) AS nuevos_comentarios,
  (35 + 2*f.idx + MOD(f.idx,4)) AS nuevos_compartidos,
  (28 + 2*f.idx + MOD(f.idx,3)) AS nuevos_guardados,
  (18 + 1*f.idx + MOD(f.idx,4)) AS nuevos_mensajesDM,

  0.00 AS inversionAds
FROM (
  /* Genera 24 meses (último día) y les da un índice 1..24 */
  SELECT
    m.fecha_mes,
    TIMESTAMPDIFF(MONTH, DATE('2024-01-01'), DATE_FORMAT(m.fecha_mes,'%Y-%m-01')) + 1 AS idx,
    p.plataforma
  FROM (
    /* Usa DimFecha para obtener el ÚLTIMO día de cada mes 2024-01..2025-12 */
    SELECT DISTINCT LAST_DAY(Fecha) AS fecha_mes
    FROM DimFecha
    WHERE Fecha BETWEEN '2024-01-01' AND '2025-12-31'
  ) m
  CROSS JOIN (
    SELECT 'instagram' AS plataforma
    UNION ALL SELECT 'tiktok'
    UNION ALL SELECT 'facebook'
    UNION ALL SELECT 'youtube'
  ) p
) f
JOIN DimFecha df
  ON df.Fecha = f.fecha_mes
ON DUPLICATE KEY UPDATE
  nuevos_Seguidores    = VALUES(nuevos_Seguidores),
  nuevos_meGusta       = VALUES(nuevos_meGusta),
  nuevas_publicaciones = VALUES(nuevas_publicaciones),
  nuevas_visitasPerfil = VALUES(nuevas_visitasPerfil),
  nuevos_clics         = VALUES(nuevos_clics),
  nuevas_vistas        = VALUES(nuevas_vistas),
  nuevos_comentarios   = VALUES(nuevos_comentarios),
  nuevos_compartidos   = VALUES(nuevos_compartidos),
  nuevos_guardados     = VALUES(nuevos_guardados),
  nuevos_mensajesDM    = VALUES(nuevos_mensajesDM),
  inversionAds         = VALUES(inversionAds);
  
  -- select * from dwh_dev.FactRedesSociales
  
  
  -- PARCHE PARA AGREGAR COSTOS
  UPDATE dwh_dev.FactRedesSociales fr
JOIN dwh_dev.DimFecha df ON df.FechaID = fr.FechaID
JOIN (
  SELECT 'instagram' AS plataforma UNION ALL
  SELECT 'tiktok' UNION ALL SELECT 'facebook' UNION ALL SELECT 'youtube'
) p ON p.plataforma = fr.plataformaRS
JOIN (
  SELECT DISTINCT LAST_DAY(Fecha) AS fecha_mes,
         DATE_FORMAT(Fecha,'%Y-%m-01') AS primer_dia_mes
  FROM dwh_dev.DimFecha
) m ON m.fecha_mes = df.Fecha
SET fr.inversionAds = ROUND(
  CASE fr.plataformaRS
    WHEN 'instagram' THEN 1800
    WHEN 'tiktok'    THEN 2200
    WHEN 'facebook'  THEN 1200
    WHEN 'youtube'   THEN 1600
  END
  + 130 * (TIMESTAMPDIFF(MONTH, DATE('2024-01-01'), m.primer_dia_mes) + 1)
  + CASE MOD(TIMESTAMPDIFF(MONTH, DATE('2024-01-01'), m.primer_dia_mes) + 1,4)
      WHEN 0 THEN 400
      WHEN 1 THEN 200
      ELSE 0
    END
,2)
WHERE fr.empresa = 'colaborativa' AND IFNULL(fr.inversionAds,0)=0;
