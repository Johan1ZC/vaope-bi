/* =======================================================================
   Huella: JZ-VAOPE-DW-SET_ATC-001
   Proyecto: VAOPE – Data Warehouse (ATC)
   Artefacto: Modelo Estrella – V1 (DDL)
   Autor: Johan Zuñiga Cordova  |
   Email: johan@vaope.com | johan.zcor.upc@gmail.com
   Licencia: MIT
   Versión: v1.1
   Fecha: 2025-11-14
   Entorno: MySQL 8.0  |  Schema: dwh_dev
   Dependencias: DimFecha creadas peviamente - Privilegios CREATE/ALTER/INDEX.
   Descripción:
     - Crea dimensiones y hechos clave (FactATC)
     - Define PK/UK/Índices y FKs para integridad y performance.
   Métricas rápidas del DDL:
     - Entidades: 1
     - Primary keys: 1
     - Foreign keys: 1
   ADR relacionado:
   Convención de nombres:
     - Dim* (dimensiones), Fact* (hechos), *_Detalle (puentes), fk_* (FK), uq_* (UK), ix_* (index).
   Propósito:
     - Estandarizar el modelo estrella para ATC vinculados a Fechas con claves de negocio y surrogate keys.
   ======================================================================= */

use dwh_dev;

CREATE TABLE FactATC
(
	fec_created_at       DATETIME NULL,
	id                   VARCHAR(150) NOT NULL,
	status               VARCHAR(250) NULL,
	fec_last_atention    DATETIME NULL,
	motive               VARCHAR(250) NULL,
	userID               VARCHAR(150) NULL,
	userName             VARCHAR(250) NULL,
	nps                  VARCHAR(150) NULL,
	source               VARCHAR(150) NULL,
	submotive            VARCHAR(250) NULL,
	FechaID              INT NULL,
	tmo_sec              DECIMAL(12,2) NULL,
	tmo_min              DECIMAL(12,2) NULL,
	tmo_day              DECIMAL(12,2) NULL,
	finish               INT NULL,
	pend                 INT NULL,
	promoter             INT NULL,
	neutral              INT NULL,
	detractors           INT NULL
);

ALTER TABLE FactATC
ADD PRIMARY KEY (id);

ALTER TABLE FactATC
ADD FOREIGN KEY R_97 (FechaID) REFERENCES DimFecha (FechaID);