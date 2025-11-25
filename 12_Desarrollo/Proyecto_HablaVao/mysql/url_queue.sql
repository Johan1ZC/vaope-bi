-- HU3.1: tabla de staging para URLs descubiertas desde listados (Teleticket)
-- Motor: MySQL 8.0, InnoDB, utf8mb4

CREATE TABLE IF NOT EXISTS url_queue (
  url_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  source_id     BIGINT NOT NULL,               -- FK lógico a tabla source (catálogo)
  url           VARCHAR(500) NOT NULL,         -- URL de detalle descubierta
  page_type     ENUM('detail','list','other') DEFAULT 'detail',
  discovered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status        ENUM('nuevo','en_proceso','procesado','error') DEFAULT 'nuevo',
  last_error    VARCHAR(500) NULL,
  hash_url      CHAR(32) NOT NULL,             -- MD5 de la URL para dedup
  UNIQUE KEY uk_source_hash (source_id, hash_url),
  KEY ix_status (status),
  KEY ix_discovered (discovered_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
