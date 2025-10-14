/* =======================================================================
   Huella: JZ-VAOPE-DW-SET_POSICIONAMIETO_TENDENCIAS-001
   Proyecto: VAOPE – Data Warehouse (Posicionamiento y Tendencias)
   Artefacto: Modelo Estrella – V1 (DDL)
   Autor: Johan Zuñiga Cordova  |
   Email: johan@vaope.com | johan.zcor.upc@gmail.com
   Licencia: MIT
   Versión: v1.1
   Fecha: 2025-10-14
   Entorno: MySQL 8.0  |  Schema: dwh_dev
   Dependencias: Dimfecha creada previamente - Privilegios CREATE/ALTER/INDEX.
   Descripción:
     - Crea dimensiones y hechos clave (FactRedesSociales)
     - Define PK/UK/Índices y FKs para integridad y performance.
   Métricas rápidas del DDL:
     - Entidades: 1
     - Primary keys: 1
     - Foreign keys: 1
   ADR relacionado:
     - ADR-003: Índices compuestos en FactRedesSociales
   Convención de nombres:
     - Dim* (dimensiones), Fact* (hechos), *_Detalle (puentes), fk_* (FK), uq_* (UK), ix_* (index).
   Propósito:
     - Estandarizar el modelo estrella para Posicionamiento y Tendencias de redes sociales vinculados
	   a Fecha con claves de negocio y surrogate keys.
   ======================================================================= */

USE dwh_dev;

-- ================== FACT unificada (mensual o diaria) ==================
CREATE TABLE IF NOT EXISTS FactRedesSociales (
  FactID               INT AUTO_INCREMENT PRIMARY KEY,
  FechaID              INT NOT NULL,   -- FK a DimFecha.FechaID
  empresa              VARCHAR(150) NOT NULL,    -- Analitica/14&6/colaborativa
  plataformaRS         ENUM('tiktok','instagram','facebook','youtube') NOT NULL,

  -- métricas del periodo (NUEVAS en el mes/día)
  nuevos_Seguidores    INT     NOT NULL DEFAULT 0,
  nuevos_meGusta       INT     NOT NULL DEFAULT 0,
  nuevas_publicaciones INT     NOT NULL DEFAULT 0,
  nuevas_visitasPerfil INT     NOT NULL DEFAULT 0,
  nuevos_clics         INT     NOT NULL DEFAULT 0,
  nuevas_vistas        INT  NOT NULL DEFAULT 0,

  -- desgloses
  nuevos_comentarios   INT     NOT NULL DEFAULT 0,
  nuevos_compartidos   INT     NOT NULL DEFAULT 0,
  nuevos_guardados     INT     NOT NULL DEFAULT 0,
  nuevos_mensajesDM    INT     NOT NULL DEFAULT 0,
  -- Inversiones
  inversionAds         DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  
  Fuente               VARCHAR(100) NULL,
  FechaCarga           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  

  -- clave lógica para UPSERT (evita duplicados en el mismo periodo)
  UNIQUE KEY uq_periodo_empresa_plat (FechaID, empresa, plataformaRS),

  CONSTRAINT fk_fact_fecha
    FOREIGN KEY (FechaID) REFERENCES DimFecha(FechaID)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Índices útiles para filtros
CREATE INDEX ix_fact_empresa_fecha   ON FactRedesSociales (empresa, FechaID);
CREATE INDEX ix_fact_plataforma_fecha ON FactRedesSociales (plataformaRS, FechaID);