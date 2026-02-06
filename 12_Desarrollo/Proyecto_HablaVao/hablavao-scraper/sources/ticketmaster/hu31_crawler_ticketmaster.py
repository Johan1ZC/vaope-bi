# -*- coding: utf-8 -*-
"""
HU3.1 — Crawler TICKETMASTER.pe (API preferente)
- Encola detail_url + meta_json en url_queue
- Idempotente por (source_id, hash_url)
- Config: ticketmaster_manifest.yaml
"""

import os, json, time, hashlib, yaml, requests
from urllib.parse import urlsplit, urlunsplit, urljoin
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# ------------------ ENV & CFG ------------------
load_dotenv()
DB_URL   = os.getenv("DB_URL", "mysql+pymysql://user:pass@localhost:3306/hablavao?charset=utf8mb4")
MANIFEST = os.getenv("MANIFEST", "sources/ticketmaster/ticketmaster_manifest.yaml")

with open(MANIFEST, "r", encoding="utf-8") as f:
    cfg = yaml.safe_load(f) or {}

SRC_NAME = cfg.get("source", {}).get("name", "Ticketmaster")
BASE_URL = cfg.get("source", {}).get("base_url", "https://www.ticketmaster.pe/")

UA       = cfg.get("compliance", {}).get("user_agent", "HABLAVAO/1.0 (+contacto@tu-dominio.pe)")
RATE     = float(cfg.get("compliance", {}).get("rate_limit_seconds", 1.0))
JMIN     = float(cfg.get("compliance", {}).get("jitter_seconds_min", 0.2))
JMAX     = float(cfg.get("compliance", {}).get("jitter_seconds_max", 0.8))

API_CFG     = cfg.get("api", {}).get("eventos_busqueda", {})
API_URL     = API_CFG.get("url")
API_METHOD  = API_CFG.get("method", "GET").upper()
API_HEADERS = API_CFG.get("headers", {}) or {}
API_PARAMS  = API_CFG.get("params", {}) or {}
API_JSON    = API_CFG.get("json", None)
API_DATA    = API_CFG.get("data", None)
PAGE_PARAM  = API_CFG.get("page_param", None)
START_PAGE  = int(API_CFG.get("start_page", 1))
MAX_PAGES   = int(API_CFG.get("max_pages", 1))

engine = create_engine(DB_URL, pool_pre_ping=True, pool_recycle=180)

# ------------------ Utils ------------------
def sleep_rate(rate, jmin, jmax):
    import random
    time.sleep(rate + random.uniform(jmin, jmax))

def normalize_url(u: str) -> str:
    p = urlsplit(u)
    return urlunsplit((p.scheme.lower(), p.netloc.lower(), p.path.rstrip('/'), '', ''))

def md5_hex(s: str) -> str:
    return hashlib.md5(s.encode("utf-8")).hexdigest()

# ------------------ DB helpers ------------------
def ensure_url_queue_table():
    with engine.begin() as conn:
        conn.execute(text("""
        CREATE TABLE IF NOT EXISTS url_queue (
          url_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
          source_id INT NOT NULL,
          url TEXT NOT NULL,
          page_type VARCHAR(30) NOT NULL DEFAULT 'detail',
          hash_url CHAR(32) NOT NULL,
          status ENUM('nuevo','procesado','error') NOT NULL DEFAULT 'nuevo',
          meta_json JSON NULL,
          discovered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (url_id),
          UNIQUE KEY uq_source_hash (source_id, hash_url),
          KEY ix_status (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"""))

def get_or_create_source_id(name: str, base_url: str) -> int:
    with engine.begin() as conn:
        conn.execute(text("""
        CREATE TABLE IF NOT EXISTS source (
          source_id INT NOT NULL AUTO_INCREMENT,
          name VARCHAR(200) NOT NULL,
          base_url VARCHAR(500) NOT NULL,
          PRIMARY KEY(source_id),
          UNIQUE KEY uq_name (name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"""))
        conn.execute(text("""
        INSERT INTO source (name, base_url)
        VALUES (:n, :u) ON DUPLICATE KEY UPDATE base_url=VALUES(base_url)"""),
        {"n": name, "u": base_url})
        return int(conn.execute(text("SELECT source_id FROM source WHERE name=:n"), {"n": name}).scalar())

def upsert_url_queue_with_meta(source_id: int, detail_url: str, meta: dict | None):
    url_norm = normalize_url(detail_url)
    h = md5_hex(url_norm)
    mj = json.dumps(meta, ensure_ascii=False) if meta else None
    with engine.begin() as conn:
        conn.execute(text("""
        INSERT INTO url_queue (source_id, url, page_type, hash_url, status, meta_json)
        VALUES (:sid, :u, 'detail', :h, 'nuevo', :mj)
        ON DUPLICATE KEY UPDATE
          url       = VALUES(url),
          meta_json = COALESCE(VALUES(meta_json), url_queue.meta_json)
        """), {"sid": source_id, "u": url_norm, "h": h, "mj": mj})

# ------------------ API crawl ------------------
def build_detail_url_from_item(item: dict) -> str | None:
    raw = item.get("permalink") or item.get("url") or item.get("link")
    if not raw:
        return None
    return normalize_url(urljoin(BASE_URL, raw.lstrip("/")))

def crawl_via_api(source_id: int) -> int:
    if not API_URL:
        print("[API] URL no configurada.")
        return 0

    s = requests.Session()
    s.headers.update({"User-Agent": UA, "Accept": "application/json, */*;q=0.1", "Referer": BASE_URL})
    s.headers.update(API_HEADERS)

    pages = [None] if not PAGE_PARAM else list(range(START_PAGE, START_PAGE + MAX_PAGES))
    total_new = 0

    for p in pages:
        params = dict(API_PARAMS)
        if PAGE_PARAM and p is not None:
            params[PAGE_PARAM] = p

        r = s.request(API_METHOD, API_URL, params=params, json=API_JSON, data=API_DATA, timeout=30)
        r.raise_for_status()
        data = r.json()
        items = data.get("items", data) if isinstance(data, dict) else data

        found = 0
        for it in items:
            u = build_detail_url_from_item(it)
            if not u:
                continue
            meta = {
                "title": it.get("title") or it.get("name"),
                "date": it.get("date"),
                "location": it.get("venue") or it.get("city"),
                "eventoId": it.get("id") or it.get("eventId"),
                "image": it.get("image") or it.get("poster"),
                "tags": it.get("tags") or it.get("category")
            }
            upsert_url_queue_with_meta(source_id, u, meta)
            found += 1

        print(f"[TICKETMASTER][page={p}] nuevas en cola: {found}")
        total_new += found
        sleep_rate(RATE, JMIN, JMAX)

    return total_new

# ------------------ Runner ------------------
def run():
    ensure_url_queue_table()
    sid = get_or_create_source_id(SRC_NAME, BASE_URL)
    total = crawl_via_api(sid)
    print(f"Terminado TICKETMASTER. Total URLs nuevas encoladas: {total}")

if __name__ == "__main__":
    run()
