
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
-- FACT: Ventas Web
--  - Unicidad lógica por (web_VentaID, web_EntradaID)
--  - FK a DimFecha.FechaID, DimEventos.EventoID, Dimhora.HoraID
-- ==================================================================
CREATE TABLE IF NOT EXISTS FactVentasWeb (
  factVentaID           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  fechaID               INT NOT NULL,
  horaID                INT NULL,
  web_VentaID           INT NOT NULL,
  web_EntradaID         INT NOT NULL,
  eventoID              INT NULL,
  zona                  VARCHAR(150) NULL,
  cantidadProd          INT NULL CHECK (cantidadProd IS NULL OR cantidadProd >= 0),
  precio_unitario       DECIMAL(12,2) NULL CHECK (precio_unitario IS NULL OR precio_unitario >= 0),
  descuento             DECIMAL(12,2) NULL CHECK (descuento    IS NULL OR descuento    >= 0),
  sinImpuesto           DECIMAL(12,2) NULL CHECK (sinImpuesto  IS NULL OR sinImpuesto  >= 0),
  porcentaje_igv        DECIMAL(12,2) NULL CHECK (porcentaje_igv IS NULL OR porcentaje_igv >= 0),
  impuesto              DECIMAL(12,2) NULL CHECK (impuesto     IS NULL OR impuesto     >= 0),
  total                 DECIMAL(12,2) NULL CHECK (total        IS NULL OR total        >= 0),
  moneda                VARCHAR(20) NULL,
  tipo_cambio           VARCHAR(25) NULL,
  esCortesia            TINYINT(1) NULL DEFAULT 0 CHECK (esCortesia IN (0,1)),
  utm_source            VARCHAR(100) NULL,
  utm_campaign          VARCHAR(100) NULL,
  utm_medium            VARCHAR(100) NULL,
  usuarioID             INT NULL,
  mp_NomMetodo          CHAR(18) NULL,
  mp_EntidadFinanciera  VARCHAR(150) NULL,
  mp_Procesador_Wallet  VARCHAR(150) NULL,
  mp_Red_Tarjeta        VARCHAR(150) NULL,
  mp_Producto           VARCHAR(150) NULL,  

  -- Claves
  PRIMARY KEY (factVentaID),

  -- Unicidad por venta + detalle
  CONSTRAINT uq_factventasweb_webventa_detalle
    UNIQUE (web_VentaID, web_EntradaID),

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

  -- Índices para rendimiento
  INDEX idx_factventasweb_fecha (fechaID),
  INDEX idx_factventasweb_evento (eventoID),
  INDEX idx_factventasweb_hora (horaID),
  INDEX idx_factventasweb_usuario (usuarioID),
  INDEX idx_factventasweb_utms (utm_source, utm_medium, utm_campaign),
  INDEX idx_factventasweb_fecha_evento (fechaID, eventoID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- SELECT * FROM FactVentasWeb


