/* =======================================================================
   Huella: JZ-VAOPE-RPT-set_CrossSelling.Ventas-001
   Artefacto: (Metodos de conversion)
   Autora: Johan Zuñiga Cordova  |  v1.0  |  2026-02-11
   Propósito: Arquitectura de datos de hechos sobre productos vendidos en un evento especifico,
   detalles de productos, categoria, ammount (para export/BI)
   ======================================================================= */
   
   use dwh_dev_4;

CREATE TABLE IF NOT EXISTS dwh_dev_4.fact_product_liquidation_operations (
  -- Surrogate Key DWH
  FactProductLiqOpID BIGINT AUTO_INCREMENT PRIMARY KEY,

  -- Business Key
  ProductLiquidationOperationID BIGINT NOT NULL,

  -- Relaciones
  ProductLiquidationID BIGINT NULL,
  EventID INT NULL,
  UserID BIGINT NULL,

  -- Atributos de la operación
  TypeOperation VARCHAR(50) NULL,
  CodeSecondary VARCHAR(50) NULL,
  OperationName VARCHAR(255) NULL,

  Description TEXT NULL,
  ChargedTo VARCHAR(50) NULL,
  PaymentMethod VARCHAR(50) NULL,

  -- Métrica
  Amount DECIMAL(18,2) NULL,

  -- Estados
  RequiresApproval TINYINT(1) NULL,
  Approved TINYINT(1) NULL,
  ApprovedBy BIGINT NULL,
  ApprovedAt DATETIME NULL,

  -- Fechas
  CreatedAt DATETIME NULL,
  UpdatedAt DATETIME NULL,

  -- Índices
  UNIQUE KEY uq_origin_id (ProductLiquidationOperationID),
  KEY ix_event_id (EventID),
  KEY ix_created_at (CreatedAt),
  KEY ix_type_operation (TypeOperation),
  KEY ix_product_liq_id (ProductLiquidationID)
  
  

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE dwh_dev_4.Fact_product_liquidation_operations
ADD FOREIGN KEY fk_factprod_event (EventID) REFERENCES DimEventos (EventoID);


-- SHOW CREATE TABLE dwh_dev_4.Fact_product_liquidation_operations;

-- ALTER TABLE dwh_dev_4.Fact_product_liquidation_operations
-- MODIFY COLUMN EventID INT;

-- select * from dwh_dev_4.Fact_product_liquidation_operations




