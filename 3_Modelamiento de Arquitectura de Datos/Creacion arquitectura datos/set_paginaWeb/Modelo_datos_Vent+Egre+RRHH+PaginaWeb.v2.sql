
-- ==================================================================
-- Esquema base (opcional)
-- ==================================================================
-- CREATE DATABASE IF NOT EXISTS vaope_web
--   DEFAULT CHARACTER SET utf8mb4
--   DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE dwh_dev;

-- ==================================================================
-- DIM: Hora
-- ==================================================================
CREATE TABLE IF NOT EXISTS Dimhora (
  HoraID              INT NOT NULL,
  Hora                TIME NULL,
  Hora24              TINYINT NULL CHECK (Hora24 BETWEEN 0 AND 23),
  Hora12              TINYINT NULL CHECK (Hora12 BETWEEN 1 AND 12),
  AMPM                CHAR(2) NULL CHECK (AMPM IN ('AM','PM')),
  Tramo               VARCHAR(15) NULL,
  BloqueHora          VARCHAR(15) NULL,
  EshorarioLaboral    TINYINT(1) NULL CHECK (EshorarioLaboral IN (0,1)),
  PRIMARY KEY (HoraID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- SELECT * FROM Dimhora

-- ==================================================================
-- DIM: Usuario
-- ==================================================================
CREATE TABLE IF NOT EXISTS Dimusuario (
  usuarioID           INT NOT NULL,
  genero              VARCHAR(15),
  created_at          DATETIME NULL,
  updated_at          DATETIME NULL,
  esActivo            TINYINT(1) NULL DEFAULT 0 CHECK (esActivo IN (0,1)),
  origen              VARCHAR(150),
  PRIMARY KEY (usuarioID),
  INDEX idx_dimusuario_esActivo (esActivo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- SELECT * FROM Dimhora

-- ==================================================================
-- FACT: Ventas Web
--  - FK a DimFecha.FechaID, DimEventos.EventoID, Dimhora.HoraID
-- ==================================================================
CREATE TABLE IF NOT EXISTS FactVentasWeb (
  factVentaID           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  fechaID               INT NOT NULL,
  horaID                INT NULL,
  web_VentaID           INT NOT NULL,
  eventoID              INT NULL,
  nom_evento 		    VARCHAR(150) NULL,
  status_general        VARCHAR(150) NULL,
  usuarioID             INT NULL,
  utm_source            VARCHAR(250) NULL,
  utm_campaign          VARCHAR(250) NULL,
  utm_medium            VARCHAR(250) NULL,
  cantidadProd          INT NULL, -- CHECK (cantidadProd IS NULL OR cantidadProd >= 0),
  sub_total             DECIMAL(12,2) NULL, -- CHECK (sub_total IS NULL OR sub_total >= 0),
  discount              DECIMAL(12,2) NULL, -- CHECK (discount  IS NULL),
  delivery              DECIMAL(12,2) NULL, -- CHECK (delivery        IS NULL OR delivery        >= 0),
  total_price           DECIMAL(12,2) NULL, -- CHECK (total_price        IS NULL OR total_price        >= 0),
  esCortesia            TINYINT(1) NULL, -- DEFAULT 0 CHECK (esCortesia IN (0,1)),
  persons               INT NULL,
  payment_method_id     INT NULL,
  mp_NomMetodo          VARCHAR(150) NULL,
  mp_EntidadFinanciera  VARCHAR(150) NULL,
  mp_Procesador_Wallet  VARCHAR(150) NULL,
  mp_Red_Tarjeta        VARCHAR(150) NULL,
  mp_Producto           VARCHAR(150) NULL,  
  pagos_count           INT NULL,
  metodos_distintos     INT NULL,

  -- Claves
  PRIMARY KEY (factVentaID),

  -- Unicidad por venta
  CONSTRAINT uq_factventasweb
    UNIQUE (web_VentaID),

  -- Relaciones (FK)
  CONSTRAINT fk_factventasweb_dimfecha
    FOREIGN KEY (fechaID)
    REFERENCES DimFecha (FechaID),
    -- ON UPDATE RESTRICT ON DELETE RESTRICT,

  CONSTRAINT fk_factventasweb_dimeventos
    FOREIGN KEY (eventoID)
    REFERENCES DimEventos (EventoID),
    -- ON UPDATE RESTRICT ON DELETE RESTRICT,

  CONSTRAINT fk_factventasweb_dimhora
    FOREIGN KEY (horaID)
    REFERENCES Dimhora (HoraID),
    -- ON UPDATE RESTRICT ON DELETE RESTRICT,
    
  CONSTRAINT fk_dimusuario_factventasweb
    FOREIGN KEY (usuarioID)
    REFERENCES Dimusuario (usuarioID),
    -- ON UPDATE RESTRICT ON DELETE RESTRICT,

  -- Índices para rendimiento
  INDEX idx_factventasweb_fecha (fechaID),
  INDEX idx_factventasweb_web_venta (web_VentaID),
  INDEX idx_factventasweb_evento (eventoID),
  INDEX idx_factventasweb_hora (horaID),
  INDEX idx_factventasweb_usuario (usuarioID),
  INDEX idx_factventasweb_utms (utm_source, utm_medium, utm_campaign),
  INDEX idx_factventasweb_fecha_evento (fechaID, eventoID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- SELECT * FROM FactVentasWeb


