/* =======================================================================
   Huella: JZ-VAOPE-DW-SET_INCIDENCIAS-001
   Proyecto: VAOPE – Data Warehouse (Incidencias)
   Artefacto: Modelo Estrella – V1 (DDL)
   Autor: Johan Zuñiga Cordova  |
   Email: johan@vaope.com | johan.zcor.upc@gmail.com
   Licencia: MIT
   Versión: v1.1
   Fecha: 2025-10-14
   Entorno: MySQL 8.0  |  Schema: dwh_dev
   Dependencias: Dimfecha, DimEstructura creadas previamente - Privilegios CREATE/ALTER/INDEX.
   Descripción:
     - Crea dimensiones y hechos clave (FactIncidencias)
     - Define PK/UK/Índices y FKs para integridad y performance.
   Métricas rápidas del DDL:
     - Entidades: 1
     - Primary keys: 1
     - Foreign keys: 3
   ADR relacionado:
     - ADR-003: Índices compuestos en FactIncidencias
   Convención de nombres:
     - Dim* (dimensiones), Fact* (hechos), *_Detalle (puentes), fk_* (FK), uq_* (UK), ix_* (index).
   Propósito:
     - Estandarizar el modelo estrella para Incidencias vinculados a Estructura,
       Fecha con claves de negocio y surrogate keys.
   ======================================================================= */

CREATE TABLE FactIncidencias
(   factincidenciaID     INT NOT NULL AUTO_INCREMENT,
	IncidenciaID         INT NOT NULL,
	FecIniIncID          INT NULL,
	FecFinIncID          INT NULL,
    EstructuraID         INT NULL,
	TipoIncID            INT NULL,
	NomTipoInc           VARCHAR(150) NULL,
	NomEstado            VARCHAR(150) NULL,
    Fuente               VARCHAR(150) NULL,
	FechaCarga           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
      -- Clave primaria
  CONSTRAINT pk_fact_incidencias PRIMARY KEY (factincidenciaID),
  
    -- Unicidad de código legible
  CONSTRAINT uq_fact_incidencias_incidenciaid UNIQUE KEY (IncidenciaID),
  
   -- Índices para performance
  KEY idx_factinc_fecini (FecIniIncID),
  KEY idx_factinc_fecfin (FecFinIncID),
  KEY idx_factinc_estruct (EstructuraID),
  KEY idx_factinc_tipoinc (TipoIncID),
  KEY idx_factinc_estruct_fechas (EstructuraID, FecIniIncID, FecFinIncID),
  
  -- Relaciones (en el mismo CREATE)
  CONSTRAINT fk_factinc_dimfecha_ini
    FOREIGN KEY (FecIniIncID)
    REFERENCES DimFecha (FechaID),

  CONSTRAINT fk_factinc_dimfecha_fin
    FOREIGN KEY (FecFinIncID)
    REFERENCES DimFecha (FechaID),

  CONSTRAINT fk_factinc_dimestructura
    FOREIGN KEY (EstructuraID)
    REFERENCES DimEstructura (EstructuraID)
);

-- select * from FactIncidencias

