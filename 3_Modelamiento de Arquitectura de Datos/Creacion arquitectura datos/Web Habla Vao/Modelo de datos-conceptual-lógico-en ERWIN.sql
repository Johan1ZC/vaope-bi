use dw_dev_hablavao;

-- Catálogo de fuentes
CREATE TABLE source (
  source_id       BIGINT PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(120) NOT NULL,                 -- p.ej., "conciertos.com.pe"
  base_url        VARCHAR(255) NOT NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Catálogo de Departamento
CREATE TABLE department (
  department_id       INT PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(80) NOT NULL,                  -- "Lima", "Cusco", ...
  region          VARCHAR(80) NOT NULL,
  code            VARCHAR(10) NULL,                      -- ubigeo dpto
  UNIQUE KEY uk_region_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  CONSTRAINT fk_venue_region FOREIGN KEY (region_id) REFERENCES region(region_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  region_id           INT NULL,                          -- redundancia útil para filtros rápidos
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
  CONSTRAINT fk_event_region FOREIGN KEY (region_id) REFERENCES region(region_id),
  UNIQUE KEY uk_src_event (source_id, source_event_id),
  KEY ix_event_dates (starts_at_utc, ends_at_utc),
  KEY ix_event_region (region_id),
  KEY ix_event_status (status),
  KEY ix_event_hash (hash_dedupe)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
