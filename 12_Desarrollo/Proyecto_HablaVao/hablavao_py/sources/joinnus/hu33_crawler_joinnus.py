# -*- coding: utf-8 -*-
"""
HU3.1 — Crawler JOINNUS (API preferente + HTML fallback con Selenium)
- Encola detail_url + meta_json en url_queue
- Idempotente (hash_url=MD5(URL_normalizada))
- Lee configuración desde joinnus_manifest.yaml
- Modo de ejecución por .env: JOINNUS_MODE = auto|api|html (default: auto)
"""

import os, json, time, hashlib, yaml, requests, re
from urllib.parse import urlsplit, urlunsplit, urljoin
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# (para HTML fallback)
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, ElementClickInterceptedException

# ------------------ ENV & CFG ------------------
load_dotenv()
DB_URL      = os.getenv("DB_URL", "mysql+pymysql://user:pass@localhost:3306/hablavao?charset=utf8mb4")
MANIFEST    = os.getenv("MANIFEST", "sources/joinnus/joinnus_manifest.yaml")
JOINNUS_MODE= os.getenv("JOINNUS_MODE", "auto").lower()   # auto|api|html
HEADLESS    = os.getenv("HEADLESS", "1") != "0"

with open(MANIFEST, "r", encoding="utf-8") as f:
    cfg = yaml.safe_load(f) or {}

SRC_NAME = cfg.get("source", {}).get("name", "Joinnus")
BASE_URL = cfg.get("source", {}).get("base_url", "https://www.joinnus.com/")

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
    raw = item.get("permalink") or item.get("permaLink") or item.get("url") or item.get("link")
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

    # Authorization por ENV
    bearer = os.getenv("JOINNUS_BEARER")
    if bearer:
        s.headers["authorization"] = f"Bearer {bearer}"

    total_new = 0

    base_params = dict(API_PARAMS)
    base_json  = dict(API_JSON or {})

    page_param_name = PAGE_PARAM or "page"
    current_page = int(base_json.get(page_param_name, base_params.get(page_param_name, 1)) or 1)

    while True:
        params = dict(base_params)
        payload_json = dict(base_json)
        payload_json[page_param_name] = current_page

        r = s.request(API_METHOD, API_URL, params=params, json=payload_json, data=API_DATA, timeout=(10,60))
        r.raise_for_status()
        payload = r.json()

        d = payload.get("data", {}) or {}
        hits = d.get("hits", []) or []

        found = 0
        for h in hits:
            src = (h or {}).get("_source", {}) or {}
            permalink = src.get("activityUrl")
            if not permalink:
                continue

            detail_url = normalize_url(urljoin(BASE_URL, str(permalink).lstrip("/")))
            images = src.get("images", {}) or {}
            img = images.get("original") or images.get("medium") or images.get("small")

            meta = {
                "title": src.get("title"),
                "date":  src.get("dateStart") or src.get("date"),
                "location": src.get("location") or src.get("locationSlug"),
                "eventoId": src.get("activityId"),
                "image": img,
                "tags":  src.get("activityCategory"),
                "price": src.get("price"),
                "currency": src.get("currency"),
            }
            upsert_url_queue_with_meta(source_id, detail_url, meta)
            found += 1

        print(f"[JOINNUS/API][page={current_page}] nuevas en cola: {found}")
        total_new += found
        sleep_rate(RATE, JMIN, JMAX)

        next_page = d.get("nextPage")
        if not next_page:
            break
        current_page = int(next_page)

    return total_new

# ------------------ HTML fallback (Selenium) ------------------
SEARCH_URL = "https://www.joinnus.com/search"

def make_driver():
    opts = Options()
    if HEADLESS:
        opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--disable-gpu")
    opts.add_argument(f"--user-agent={UA}")
    opts.add_argument("--window-size=1366,1000")
    return webdriver.Chrome(options=opts)

def accept_cookies(driver):
    """
    Intenta aceptar cookies en distintas variantes (botones: Permitir/Aceptar/Allow),
    incluso si vienen dentro de un iframe de consentimiento.
    """
    def _click_candidates(context):
        for xp in [
            # texto en español más común
            "//button[contains(translate(.,'PERMITIR','permitir'),'permitir')]",
            "//button[contains(translate(.,'ACEPTAR','aceptar'),'aceptar')]",
            "//button[contains(.,'Permitir')]",
            "//button[contains(.,'Aceptar')]",
            "//button[contains(.,'Allow')]",
            "//button[contains(.,'OK')]",
            # algunos banners usan role=button en <div>
            "//*[@role='button' and contains(.,'Permitir')]",
            "//*[@role='button' and contains(.,'Aceptar')]",
        ]:
            els = context.find_elements(By.XPATH, xp)
            if els:
                try:
                    driver.execute_script("arguments[0].scrollIntoView({block:'center'});", els[0])
                    els[0].click()
                    time.sleep(0.6)
                    return True
                except Exception:
                    pass
        return False

    # 1) intentamos en el documento principal
    if _click_candidates(driver):
        return

    # 2) algunos banners vienen en iframes (OneTrust / TrustArc / etc.)
    try:
        iframes = driver.find_elements(By.TAG_NAME, "iframe")
        for fr in iframes:
            try:
                src = (fr.get_attribute("src") or "").lower()
                title = (fr.get_attribute("title") or "").lower()
                # heurística: iframes de cookies
                if any(k in src for k in ["cookie", "consent"]) or "cookie" in title or "consent" in title:
                    driver.switch_to.frame(fr)
                    if _click_candidates(driver):
                        driver.switch_to.default_content()
                        return
                    driver.switch_to.default_content()
            except Exception:
                driver.switch_to.default_content()
    except Exception:
        pass

def wake_results(driver):
    """
    En algunas sesiones la lista aparece después de un pequeño scroll o clic en 'Buscar'.
    """
    # intenta clic en el botón "Buscar" si existe
    try:
        btn = driver.find_element(By.XPATH, "//button[contains(.,'Buscar')]")
        driver.execute_script("arguments[0].scrollIntoView({block:'center'});", btn)
        btn.click()
        time.sleep(0.8)
    except Exception:
        pass

    # pequeño scroll para activar lazy-load
    try:
        driver.execute_script("window.scrollBy(0, 600);")
        time.sleep(0.8)
        driver.execute_script("window.scrollBy(0, -400);")
        time.sleep(0.5)
    except Exception:
        pass


def click_load_more(driver) -> bool:
    for xp in [
        "//button[contains(.,'Cargar más')]",
        "//button[contains(.,'Ver más')]",
        "//button[contains(.,'Más resultados')]",
    ]:
        try:
            btn = WebDriverWait(driver, 2).until(EC.element_to_be_clickable((By.XPATH, xp)))
            btn.click(); time.sleep(1.0)
            return True
        except TimeoutException:
            continue
        except ElementClickInterceptedException:
            try:
                driver.execute_script("arguments[0].click();", btn); time.sleep(1.0); return True
            except Exception:
                continue
        except Exception:
            continue
    return False

def scroll_step(driver, px=1400):
    driver.execute_script(f"window.scrollBy(0,{px});"); time.sleep(0.6)

def parse_cards(driver) -> list[dict]:
    """
    Extrae tarjetas visibles. Usa heurísticas robustas y evita anchors de navegación.
    """
    items, seen = [], set()

    anchors = driver.find_elements(
        By.CSS_SELECTOR,
        "a[href^='https://www.joinnus.com/'], a[href^='/']"
    )

    for a in anchors:
        try:
            href = a.get_attribute("href") or ""
            if not href:
                continue

            # ignorar enlaces a login / registro / categorías
            low = href.lower()
            if any(x in low for x in ["/login", "/signin", "/register", "/category", "/search?"]):
                continue

            if "joinnus.com" not in href:
                href = urljoin(BASE_URL, href)

            parent = a
            for _ in range(3):
                parent = parent.find_element(By.XPATH, "./..")

            title = None; date_text = None; loc_text = None; image = None

            # título
            try:
                hdrs = parent.find_elements(By.XPATH, ".//h1|.//h2|.//h3|.//h4")
                if hdrs:
                    title = (hdrs[0].text or "").strip() or None
            except Exception:
                pass

            # fecha/lugar (heurística por regex)
            try:
                spans = parent.find_elements(By.XPATH, ".//span|.//p|.//div")
                for el in spans:
                    tx = (el.text or "").strip()
                    if not tx:
                        continue
                    if not date_text and re.search(r"\d{4}|\d{1,2}\s+de\s+\w+", tx, flags=re.I):
                        date_text = tx
                    if not loc_text and re.search(r"(lima|piura|cusco|miraflores|arequipa|trujillo|callao)", tx, flags=re.I):
                        loc_text = tx
            except Exception:
                pass

            # imagen
            try:
                imgs = parent.find_elements(By.TAG_NAME, "img")
                if imgs:
                    image = imgs[0].get_attribute("src")
            except Exception:
                pass

            key = (href, title or "")
            if key in seen or not title:
                continue
            seen.add(key)

            items.append({
                "detail_url": href,
                "title": title,
                "date": date_text,
                "location": loc_text,
                "image": image,
            })
        except Exception:
            continue
    return items


def crawl_via_html(source_id: int) -> int:
    driver = make_driver()
    total_new = 0
    try:
        driver.get(SEARCH_URL)
        WebDriverWait(driver, 20).until(EC.presence_of_element_located((By.TAG_NAME, "body")))
        # 1) aceptar cookies con los nuevos selectores
        accept_cookies(driver)
        # 2) “despertar” resultados
        wake_results(driver)

        # 3) primer scroll para que carguen cards
        for _ in range(4):
            scroll_step(driver)

        for _ in range(25):
            items = parse_cards(driver)
            found = 0
            for it in items:
                meta = {
                    "title": it["title"],
                    "date": it["date"],
                    "location": it["location"],
                    "image": it["image"],
                    "via": "html"
                }
                upsert_url_queue_with_meta(source_id, it["detail_url"], meta)
                found += 1
            total_new += found
            print(f"[JOINNUS/HTML] encoladas visibles: {found} (acum: {total_new})")

            if click_load_more(driver):
                continue

            prev = len(items)
            scroll_step(driver, 1600)
            items2 = parse_cards(driver)
            if len(items2) <= prev:
                break
    finally:
        driver.quit()
    return total_new

# ------------------ Runner ------------------
def run():
    ensure_url_queue_table()
    sid = get_or_create_source_id(SRC_NAME, BASE_URL)

    mode = JOINNUS_MODE
    total = 0

    if mode not in ("auto", "api", "html"):
        print(f"[JOINNUS][WARN] JOINNUS_MODE inválido: {mode!r}. Usando 'auto'.")
        mode = "auto"
    print(f"[JOINNUS] mode={mode} manifest={MANIFEST}")

    if mode in ("api", "auto"):
        try:
            print("[JOINNUS] Intentando modo API…")
            total = crawl_via_api(sid)
            print(f"[JOINNUS] API OK. Total: {total}")
            return
        except requests.exceptions.RequestException as e:
            print(f"[JOINNUS][API][WARN] {e}")
            if mode == "api":
                raise

    if mode in ("html", "auto"):
        print("[JOINNUS] Intentando modo HTML (fallback)…")
        total = crawl_via_html(sid)
        print(f"[JOINNUS] HTML OK. Total: {total}")
        return

if __name__ == "__main__":
    run()
