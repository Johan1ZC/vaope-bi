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

