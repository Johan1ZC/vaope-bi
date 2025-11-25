# HU3.1 — Crawler de listados paginados (Teleticket)

Este módulo descubre **URLs de detalle** desde páginas de **listado** en Teleticket y las guarda en `url_queue`.
> Solo descubrimiento/paginación. El parseo de fichas (HU3.2) va en otro script.

## Archivos
- `requirements.txt` — librerías.
- `url_queue.sql` — DDL de la cola de URLs.
- `teleticket_manifest.yaml` — seeds, rutas permitidas, regex de detalle, paginación y límites.
- `hu31_crawler_teleticket.py` — script Selenium para descubrimiento.
- `.env` — variables (crea este archivo):
  ```
  DB_URL=mysql+pymysql://user:pass@localhost:3306/hablavao?charset=utf8mb4
  TZ_NAME=America/Lima
  MANIFEST=teleticket_manifest.yaml
  ```

## Uso
1) Crear BD/tablas base (al menos `source`). El script las crea si faltan.
2) Ejecutar el DDL de `url_queue.sql` (opcional; el script también la crea).
3) Revisar y **ajustar** `teleticket_manifest.yaml` (seeds, selectores de paginación, regex).
4) Instalar dependencias:
   ```bash
   pip install -r requirements.txt
   ```
5) Ejecutar:
   ```bash
   python hu31_crawler_teleticket.py
   ```

## Notas
- Ajusta `detail_regex`, `allowed_path_prefix`, `next_selector` y/o `load_more_selector` según el HTML real.
- Respeta **robots.txt** y **Términos de Uso**. Limita el ritmo (`rate_limit_seconds`) y usa `user_agent` identificable.
- `url_queue` mantiene **estado** para que HU3.2 consuma (`nuevo` → `en_proceso` → `procesado`/`error`).

