\
"""
Proyecto: VAOPE | Módulo: <Crawler/Vaope>
Autor: Johan Zuñiga Cordova | Huella: JZ-VAOPE-CRAWLER | v1.0 | Fecha: 2025-11-25
Propósito: hu31_crawler_teleticket_v2.py
- Extrae ulrs y datos de eventos desde teleticket API - HTML
- Paginación robusta: offset → fallback a page/page_size si es necesario.
- Dedupe por clave compuesta: source, url
- Importa: Datos de eventos url, atributos desde la API y HTML en tablas mysql.
Licencia: MIT — sin garantías (“AS IS”)
"""
# coding: utf-8
"""
HU3.1 — Crawler de listados paginados (Teleticket)
Selenium → descubre URLs de detalle y las almacena en url_queue (MySQL)

Config:
- .env con DB_URL y TZ_NAME (opcional)
- teleticket_manifest.yaml con seeds, reglas y paginación

Nota: Los selectores/regex de detalle y paginación pueden requerir ajuste
según el HTML real de Teleticket.
"""
import requests
import os, re, time, json, random, hashlib
from urllib.parse import urljoin, urlparse
from datetime import datetime
from dataclasses import dataclass
from typing import List, Optional

import pytz
import dateparser
import pymysql
from sqlalchemy import create_engine, text
from sqlalchemy.exc import IntegrityError

from dotenv import load_dotenv
from tenacity import retry, wait_exponential, stop_after_attempt

import yaml
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# ------------------ Utils ------------------
def md5_hex(s: str) -> str:
    return hashlib.md5(s.encode("utf-8")).hexdigest()

def sleep_rate(min_s: float, jmin: float, jmax: float):
    time.sleep(min_s + random.uniform(jmin, jmax))

# ------------------ Carga de configuración ------------------
load_dotenv()
DB_URL   = os.getenv("DB_URL", "mysql+pymysql://user:pass@localhost:3306/hablavao?charset=utf8mb4")
TZ_NAME  = os.getenv("TZ_NAME", "America/Lima")
MANIFEST = os.getenv("MANIFEST", "teleticket_manifest.yaml")

with open(MANIFEST, "r", encoding="utf-8") as f:
    cfg = yaml.safe_load(f)

BASE_URL = cfg["source"]["base_url"]
UA       = cfg["compliance"]["user_agent"]
RATE     = float(cfg["compliance"]["rate_limit_seconds"])
JMIN     = float(cfg["compliance"]["jitter_seconds_min"])
JMAX     = float(cfg["compliance"]["jitter_seconds_max"])

ALLOWED_PREFIX = cfg["discovery"]["allowed_path_prefix"]
DETAIL_REGEX   = re.compile(cfg["discovery"]["detail_regex"])

NEXT_SELECTOR       = cfg["pagination"].get("next_selector")
LOAD_MORE_SELECTOR  = cfg["pagination"].get("load_more_selector")
MAX_PAGES           = int(cfg["pagination"]["max_pages"])

SEEDS = cfg["seeds"]

WAIT_SELECTORS = cfg.get("wait_selectors", [])
COOKIE_SELECTORS = cfg.get("cookie_selectors", [])

# new
API_CFG = cfg.get("api", {}).get("eventos_busqueda", {})
API_URL = API_CFG.get("url")
API_METHOD = API_CFG.get("method", "GET").upper()
API_PARAMS = API_CFG.get("params", {}) or {}
API_PAGE_PARAM = API_CFG.get("page_param", None)
API_START_PAGE = int(API_CFG.get("start_page", 1))
API_MAX_PAGES  = int(API_CFG.get("max_pages", 1))
#NEW
API_HEADERS   = API_CFG.get("headers", {}) or {}
API_JSON      = API_CFG.get("json", None)   # no se usa en GET
API_DATA      = API_CFG.get("data", None)

def handle_cookie_consent(driver):
    # intenta varios selectores comunes
    for sel in COOKIE_SELECTORS:
        try:
            btn = WebDriverWait(driver, 3).until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, sel))
            )
            btn.click()
            time.sleep(0.6)
            return
        except Exception:
            pass
    # fallback por texto
    try:
        btn = driver.find_element(By.XPATH, "//button[contains(., 'Aceptar') or contains(., 'Accept')]")
        btn.click()
        time.sleep(0.6)
    except Exception:
        pass

def wait_for_results(driver, timeout=20):
    if not WAIT_SELECTORS:
        return
    for sel in WAIT_SELECTORS:
        try:
            WebDriverWait(driver, timeout).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, sel))
            )
            return
        except Exception:
            continue

# ------------------ DB helpers ------------------
engine = create_engine(DB_URL, pool_pre_ping=True, isolation_level="AUTOCOMMIT")

def get_or_create_source_id(name: str, base_url: str) -> int:
    with engine.begin() as conn:
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS source (
              source_id BIGINT PRIMARY KEY AUTO_INCREMENT,
              name      VARCHAR(120) NOT NULL,
              base_url  VARCHAR(255) NOT NULL,
              created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
              UNIQUE KEY uk_source_name (name)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        """))
        res = conn.execute(text("SELECT source_id FROM source WHERE name=:n"), {"n": name}).fetchone()
        if res:
            return int(res[0])
        conn.execute(text("INSERT INTO source(name, base_url) VALUES(:n,:b)"), {"n": name, "b": base_url})
        res = conn.execute(text("SELECT LAST_INSERT_ID()")).fetchone()
        return int(res[0])

def ensure_url_queue_table():
    with engine.begin() as conn:
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS url_queue (
              url_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
              source_id     BIGINT NOT NULL,
              url           VARCHAR(500) NOT NULL,
              page_type     ENUM('detail','list','other') DEFAULT 'detail',
              discovered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
              status        ENUM('nuevo','en_proceso','procesado','error') DEFAULT 'nuevo',
              last_error    VARCHAR(500) NULL,
              hash_url      CHAR(32) NOT NULL,
              UNIQUE KEY uk_source_hash (source_id, hash_url),
              KEY ix_status (status),
              KEY ix_discovered (discovered_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        """))

def enqueue_detail_url(source_id: int, url: str):
    h = md5_hex(url)
    with engine.begin() as conn:
        try:
            conn.execute(text("""
                INSERT INTO url_queue (source_id, url, page_type, hash_url, status)
                VALUES (:sid, :u, 'detail', :h, 'nuevo')
                """), {"sid": source_id, "u": url, "h": h}
            )
            return True
        except IntegrityError:
            # duplicado por uk_source_hash
            return False
        
# new
def build_detail_url(permalink: str) -> str:
    # El JSON trae "permalink": "/sport-player-2025"
    # Construimos la URL absoluta de detalle
    return urljoin(BASE_URL, permalink.lstrip("/"))

# new
def enqueue_with_meta(session_sql, source_id: int, detail_url: str, meta: dict):
    """Encola URL y, si existe la columna meta_json, la actualiza."""
    h = md5_hex(detail_url)
    with engine.begin() as conn:
        # intenta insertar como nuevo
        ins = conn.execute(text("""
            INSERT INTO url_queue (source_id, url, page_type, hash_url, status)
            VALUES (:sid, :u, 'detail', :h, 'nuevo')
            ON DUPLICATE KEY UPDATE url = VALUES(url)
        """), {"sid": source_id, "u": detail_url, "h": h})
        # si la tabla tiene meta_json, actualizamos
        try:
            conn.execute(text("""
                UPDATE url_queue
                   SET meta_json = :mj
                 WHERE source_id = :sid AND hash_url = :h
            """), {"mj": json.dumps(meta, ensure_ascii=False), "sid": source_id, "h": h})
        except Exception:
            # si no existe la columna meta_json, ignorar
            pass
    return True

# ------------------ Selenium driver ------------------
def make_driver():
    opts = Options()
    opts.add_argument(f"user-agent={UA}")
    if os.getenv("HEADLESS", "1") == "1":
        opts.add_argument("--headless=new")
    opts.add_argument("--disable-gpu")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--window-size=1366,900")
    # evitar algunas detecciones simples
    opts.add_argument("--disable-blink-features=AutomationControlled")
    return webdriver.Chrome(options=opts)


@retry(wait=wait_exponential(multiplier=1, min=2, max=30), stop=stop_after_attempt(3))
def safe_get(driver, url, timeout=45):
    driver.get(url)
    WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located((By.TAG_NAME, "body"))
    )
    handle_cookie_consent(driver)
    wait_for_results(driver)

#new
def make_requests_session_from_driver(driver):
    s = requests.Session()
    # User-Agent coherente con Selenium
    s.headers.update({"User-Agent": UA, "Accept": "application/json, */*;q=0.1"})
    # pasa cookies del navegador a requests (a veces la API las requiere)
    for c in driver.get_cookies():
        s.cookies.set(c['name'], c['value'], domain=c.get('domain'), path=c.get('path', '/'))
    return s


# ------------------ Reglas de descubrimiento ------------------
def is_allowed_path(url: str) -> bool:
    path = urlparse(url).path or "/"
    if is_detail_url(url):
        return True
    return any(path.startswith(pfx) for pfx in ALLOWED_PREFIX)


def is_detail_url(url: str) -> bool:
    return bool(DETAIL_REGEX.search(url))

DEBUG = os.getenv("DEBUG", "0") == "1"

def discover_links_on_page(driver):
    # busca primero patrones típicos de detalle
    css = ("a[href*='/evento/'], a[href*='/event/'], a[href*='/comprar/'], "
           ".event-card a[href], .card a[href]")
    anchors = driver.find_elements(By.CSS_SELECTOR, css)
    if not anchors:
        # fallback: todos los <a>
        anchors = driver.find_elements(By.CSS_SELECTOR, "a")

    raw = []
    for a in anchors:
        href = a.get_attribute("href")
        if href:
            if not href.startswith("http"):
                href = urljoin(BASE_URL, href)
            raw.append(href)

    if DEBUG:
        print(f"  [debug] hrefs totales (sin filtrar): {len(raw)}")
        for s in raw[:10]:
            print("    •", s)

    filtered = []
    for u in raw:
        if is_allowed_path(u) and is_detail_url(u):
            filtered.append(u)

    # dedup preservando orden
    seen, result = set(), []
    for u in filtered:
        if u not in seen:
            seen.add(u); result.append(u)

    if DEBUG:
        print(f"  [debug] candidatos detalle filtrados: {len(result)}")
    return result

def scroll_to_load(driver, max_scrolls=3, pause=1.0):
    last_h = driver.execute_script("return document.body.scrollHeight")
    for _ in range(max_scrolls):
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(pause)
        new_h = driver.execute_script("return document.body.scrollHeight")
        if new_h == last_h:
            return False
        last_h = new_h
    return True

def paginate(driver) -> bool:
    # A) Cargar más
    if LOAD_MORE_SELECTOR:
        try:
            btn = WebDriverWait(driver, 3).until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, LOAD_MORE_SELECTOR))
            )
            btn.click(); time.sleep(1.0)
            wait_for_results(driver, timeout=10)
            return True
        except Exception:
            pass
    # B) Enlace siguiente
    if NEXT_SELECTOR:
        try:
            nxt = driver.find_element(By.CSS_SELECTOR, NEXT_SELECTOR)
            nxt.click(); time.sleep(1.0)
            wait_for_results(driver, timeout=10)
            return True
        except Exception:
            pass
    # C) Scroll si no hay paginación visible
    try:
        did = scroll_to_load(driver, max_scrolls=3, pause=1.0)
        if did:
            wait_for_results(driver, timeout=10)
        return did
    except Exception:
        return False


# new    
def crawl_via_api(driver, source_id: int) -> int:
    """Usa el endpoint JSON para encolar URLs de detalle."""
    if not API_URL:
        print("[info] API_URL no configurado; omitiendo crawl vía API.")
        return 0

    sess = make_requests_session_from_driver(driver)
    total_new = 0

    # Si hay paginación por parámetro (?page=)
    pages = [None]
    if API_PAGE_PARAM:
        pages = list(range(API_START_PAGE, API_START_PAGE + API_MAX_PAGES))

    for p in pages:
        params = dict(API_PARAMS)
        if API_PAGE_PARAM and p is not None:
            params[API_PAGE_PARAM] = p

        resp = sess.request(
            API_METHOD,
            API_URL,
            params=params,                   
            headers=API_HEADERS,             
            json=API_JSON if API_JSON is not None else None,   
            data=API_DATA if API_DATA is not None else None, 
            timeout=30
        )
        resp.raise_for_status()

        data = resp.json()
        # Esperamos una lista de objetos como:
        # {"permalink": "/...", "title": "...", "date": "...", "location": "...", "eventoId": "..."}
        if isinstance(data, dict) and "items" in data:
            items = data["items"]
        else:
            items = data

        found = 0
        for item in items:
            permalink = item.get("permalink") or item.get("permaLink") or item.get("url")
            if not permalink:
                continue
            detail_url = build_detail_url(permalink)
            # meta opcional
            meta = {
                "title": item.get("title"),
                "date": item.get("date"),
                "location": item.get("location"),
                "eventoId": item.get("eventoId"),
                "image": item.get("image"),
                "tags": item.get("tags"),
            }
            # encola (dedup por (source_id, hash_url))
            if enqueue_detail_url(source_id, detail_url):
                found += 1
                # intenta guardar meta si la columna existe
                enqueue_with_meta(None, source_id, detail_url, meta)

        print(f"[API] página={p} → nuevas en cola: {found}")
        total_new += found
        sleep_rate(RATE, JMIN, JMAX)

    return total_new


# ------------------ Runner ------------------
def run():
    ensure_url_queue_table()
    source_id = get_or_create_source_id(cfg["source"]["name"], BASE_URL)

    driver = make_driver()
    total_new = 0
    try:
        # 1) Primero: vía API (rápido y estable)
        try:
            api_new = crawl_via_api(driver, source_id)  # Usa el endpoint GetEventosBusqueda
            print(f"[API] Total URLs nuevas encoladas: {api_new}")
            total_new += api_new
        except Exception as ex:
            print(f"[API][WARN] Falló el crawl vía API: {ex}")

        # 2) (Opcional) Fallback HTML por seeds 
        for seed in SEEDS:
            try:
                safe_get(driver, seed)
            except Exception as ex:
                print(f"[HTML][WARN] No se pudo abrir seed {seed}: {ex}")
                continue

            pages = 0
            while pages < MAX_PAGES:
                pages += 1
                sleep_rate(RATE, JMIN, JMAX)
                found = discover_links_on_page(driver)
                print(f"[HTML][{seed}] Página {pages}: encontradas {len(found)} URLs candidatas.")

                new_count = 0
                for u in found:
                    if enqueue_detail_url(source_id, u):
                        new_count += 1
                total_new += new_count
                print(f"  + nuevas en cola (HTML): {new_count} (acum: {total_new})")

                if not paginate(driver):
                    break

    finally:
        driver.quit()
    print(f"Terminado. Total URLs nuevas encoladas: {total_new}")

if __name__ == "__main__":
    run()
