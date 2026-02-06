# HU3.1 — Crawler de listados paginados (multi-fuente)

## Objetivo
Encolar URLs de detalle de eventos y metadatos (`meta_json`) desde múltiples fuentes (Teleticket, Joinnus, Ticketmaster, Vaope) en una cola común `url_queue`, de manera idempotente y con deduplicación.

## Arquitectura
- **Core común** (opcional): normalización de URLs, hash MD5, upsert a `url_queue`.
- **Un adaptador por fuente**: script + manifest YAML, con headers/params/endpoint propios.
- **BD**: `source` (catálogo de fuentes) y `url_queue` (cola de URLs con `meta_json`).

## Prerrequisitos
- Python 3.10+
- MySQL 8.x
- Crear `.env` en la raíz con `DB_URL`, `TZ_NAME`, etc.
- Instalar dependencias:
  ```bash
  python -m venv .venv
  # Windows PowerShell
  .\.venv\Scripts\Activate
  python -m pip install -r requirements.txt

