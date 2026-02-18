use dw_dev_hablavao;

-- Catálogo de fuentes
CREATE TABLE source (
  source_id       BIGINT PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(120) NOT NULL,                
  base_url        VARCHAR(255) NOT NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- select * from source

ALTER TABLE source ADD UNIQUE KEY uq_name (name);

-- DELETE FROM source WHERE name='Teleticket' AND source_id<>1;


-- Catálogo de Departamento
CREATE TABLE department (
  department_id       INT PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(80) NOT NULL,                  -- "Lima", "Cusco", ...
  region          VARCHAR(80) NOT NULL,
  code            VARCHAR(10) NULL,                      -- ubigeo dpto
  UNIQUE KEY uk_region_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- select * from department

-- Lugares
CREATE TABLE venue (
  venue_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(200) NOT NULL,                 -- "Estadio Nacional", "Cocos", "etc"
  address         VARCHAR(255) NULL,                     -- dirección visible en ficha
  district        VARCHAR(120) NULL,                     -- distrito
  province        VARCHAR(120) NULL,                     -- provincia
  department_id   INT NULL,                              -- FK a department
  latitude        DECIMAL(10,6) NULL,
  longitude       DECIMAL(10,6) NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_venue_department FOREIGN KEY (department_id) REFERENCES department(department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- select * from venue

-- Eventos
CREATE TABLE event (
  event_id            BIGINT PRIMARY KEY AUTO_INCREMENT,
  source_id           BIGINT NOT NULL,
  source_event_id     VARCHAR(64) NOT NULL,              -- "#15605" o slug/ID fuente
  title               VARCHAR(255) NOT NULL,
  description_html    MEDIUMTEXT NULL,
  -- tiempos
  starts_at_local     DATETIME NULL,                     -- según la ficha (zona local)
  ends_at_local       DATETIME NULL,
  tz_name             VARCHAR(64) DEFAULT 'America/Lima',
  starts_at_utc       DATETIME NULL,
  ends_at_utc         DATETIME NULL,
  -- estado calculable: proximo/en_curso/pasado/sin_fecha/cancelado
  status              ENUM('proximo','en_curso','pasado','sin_fecha','cancelado') DEFAULT 'proximo',
  venue_id            BIGINT NULL,
  department_id           INT NULL,                          -- redundancia útil para filtros rápidos
  -- metadatos de la fuente
  published_at_src    DATETIME NULL,                     -- "Fecha de publicación"
  updated_at_src      DATETIME NULL,                     -- "Fecha de última actualización"
  ticket_url          VARCHAR(500) NULL,
  canonical_url       VARCHAR(500) NULL,                 -- URL detalle en la fuente
  disclaimer          VARCHAR(500) NULL,                 -- nota de precisión
  hash_dedupe         CHAR(32) NOT NULL,                 -- md5(title+fecha+lugar)
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_event_source FOREIGN KEY (source_id) REFERENCES source(source_id),
  CONSTRAINT fk_event_venue  FOREIGN KEY (venue_id)  REFERENCES venue(venue_id),
  CONSTRAINT fk_event_region FOREIGN KEY (department_id) REFERENCES department(department_id),
  UNIQUE KEY uk_src_event (source_id, source_event_id),
  KEY ix_event_dates (starts_at_utc, ends_at_utc),
  KEY ix_event_region (department_id),
  KEY ix_event_status (status),
  KEY ix_event_hash (hash_dedupe)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE event MODIFY source_event_id VARCHAR(255) NOT NULL;

-- select * from event

-- Artistas
CREATE TABLE artist (
  artist_id       BIGINT PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(200) NOT NULL,
  alt_names       VARCHAR(255) NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_artist_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE event_artist (
  event_id        BIGINT NOT NULL,
  artist_id       BIGINT NOT NULL,
  role            VARCHAR(60) NULL,                      -- headliner, invitado, etc.
  PRIMARY KEY (event_id, artist_id),
  CONSTRAINT fk_ea_event  FOREIGN KEY (event_id)  REFERENCES event(event_id)  ON DELETE CASCADE,
  CONSTRAINT fk_ea_artist FOREIGN KEY (artist_id) REFERENCES artist(artist_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Categorías (concierto, teatro, deportes, festival, etc.)
CREATE TABLE category (
  category_id     INT PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(80) NOT NULL,
  parent_id       INT NULL,
  CONSTRAINT fk_cat_parent FOREIGN KEY (parent_id) REFERENCES category(category_id),
  UNIQUE KEY uk_category_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE event_category (
  event_id        BIGINT NOT NULL,
  category_id     INT NOT NULL,
  PRIMARY KEY (event_id, category_id),
  CONSTRAINT fk_ec_event    FOREIGN KEY (event_id)    REFERENCES event(event_id)    ON DELETE CASCADE,
  CONSTRAINT fk_ec_category FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Enlaces de ticketera (por si hay múltiples)
CREATE TABLE ticket_link (
  ticket_id       BIGINT PRIMARY KEY AUTO_INCREMENT,
  event_id        BIGINT NOT NULL,
  url             VARCHAR(500) NOT NULL,
  provider        VARCHAR(120) NULL,                    -- "Teleticket", "Joinnus", etc.
  notes           VARCHAR(255) NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_tl_event FOREIGN KEY (event_id) REFERENCES event(event_id) ON DELETE CASCADE,
  KEY ix_ticket_event (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- (Opcional) Medios
CREATE TABLE media (
  media_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  event_id        BIGINT NOT NULL,
  kind            ENUM('image','video') DEFAULT 'image',
  url             VARCHAR(500) NOT NULL,
  is_cover        TINYINT(1) DEFAULT 0,
  CONSTRAINT fk_media_event FOREIGN KEY (event_id) REFERENCES event(event_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Auditoría de ingesta / trazabilidad
CREATE TABLE ingest_audit (
  ingest_id       BIGINT PRIMARY KEY AUTO_INCREMENT,
  source_id       BIGINT NOT NULL,
  url             VARCHAR(500) NOT NULL,
  page_type       ENUM('list','detail','other') DEFAULT 'detail',
  http_status     INT NULL,
  fetched_at      DATETIME NOT NULL,
  selector_ok     TINYINT(1) DEFAULT 1,
  raw_path        VARCHAR(500) NULL,                    -- dónde guardaste el HTML/JSON
  content_hash    CHAR(32) NULL,
  error_msg       VARCHAR(500) NULL,
  CONSTRAINT fk_ing_source FOREIGN KEY (source_id) REFERENCES source(source_id),
  KEY ix_ing_source_time (source_id, fetched_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


/*
# activar venv
.\.venv\Scripts\Activate.ps1

# variables (si no están en .env)
$env:DB_URL = "mysql+pymysql://user:pass@localhost:3306/dw_dev_hablavao?charset=utf8mb4"
$env:PARSER_BATCH = "60"
$env:UA = "HABLAVAO/1.0 (+contacto@tu-dominio.pe)"
$env:TZ_NAME = "America/Lima"

# correr
python sources/teleticket/hu32_loader_teleticket_dw.py
*/


/*
SELECT fetched_at, url, http_status, selector_ok, error_msg
FROM ingest_audit
WHERE source_id = 1
ORDER BY fetched_at DESC
LIMIT 50;
*/


select * from source;
select * from department;
select * from venue; -- select distinct name,count(1) Q from venue group by  name     
select * from event; -- select source_id,count(1) Q from event group by  source_id
select * from artist; -- select distinct name,count(1) Q from artist group by  name   Repetidos: ARMONIA 10 - ARMONIA10  Repetidos por otra letra: CAMILO CESTO - CAMILO SESTO
select * from event_artist;
select * from category;
select * from event_category;
select * from ticket_link
where event_id = 742;
select * from media;
select * from ingest_audit;


/*

USE dw_dev_hablavao;

SET FOREIGN_KEY_CHECKS = 0;

-- hijos de EVENT
TRUNCATE TABLE event_category;
TRUNCATE TABLE event_artist;
TRUNCATE TABLE ticket_link;
TRUNCATE TABLE media;
TRUNCATE TABLE ingest_audit;

-- tablas con FK a SOURCE / VENUE / DEPARTMENT / CATEGORY / ARTIST
TRUNCATE TABLE event;

-- padres intermedios
TRUNCATE TABLE venue;
TRUNCATE TABLE department;
TRUNCATE TABLE category;
TRUNCATE TABLE artist;

-- raíz
TRUNCATE TABLE source;

SET FOREIGN_KEY_CHECKS = 1;

*/


-- A) Permitir slugs/IDs largos
ALTER TABLE event
  MODIFY source_event_id VARCHAR(255) NOT NULL;

-- (si tienes un índice único ya creado no hace falta tocarlo en MySQL 8; 255 con utf8mb4 cabe dentro de 3072 bytes)

-- B) Permitir errores extensos (stack traces)
ALTER TABLE url_queue
  MODIFY last_error TEXT NULL;
  
  
/*  
  # correr
python sources/joinnus/hu34_loader_joinnus_dw.py
*/


select a.event_id,a.source_id,c.artist_id
from dw_dev_hablavao.event a
left join dw_dev_hablavao.event_artist b on a.event_id = b.event_id
left join dw_dev_hablavao.artist c on c.artist_id = b.artist_id
-- select * from dw_dev_hablavao.event_artist
-- select * from dw_dev_hablavao.event