# -*- coding: utf-8 -*-
"""
HU3.4 — Joinnus → DW (dw_dev_hablavao)
- Lee url_queue 'nuevo' de Joinnus (meta_json opcional)
- Descarga detalle, parsea JSON-LD / fallbacks
- UPSERT a: source, department, venue, event, category, event_category, ticket_link, media, ingest_audit, (artist opcional)
"""

import os, re, json, hashlib, requests, pytz, dateparser
from bs4 import BeautifulSoup
from datetime import datetime, timezone
from dateutil import parser as dtp
from urllib.parse import urlsplit, urlunsplit
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from unidecode import unidecode

# ------------------ ENV ------------------
load_dotenv()
DB_URL      = os.getenv("DB_URL", "mysql+pymysql://user:pass@localhost:3306/dw_dev_hablavao?charset=utf8mb4")
UA          = os.getenv("UA", "HABLAVAO/1.0 (+contacto@hablavao.pe)")
BATCH_LIMIT = int(os.getenv("PARSER_BATCH", "40"))
TZ_NAME     = os.getenv("TZ_NAME", "America/Lima")

SOURCE_NAME = "Joinnus"
BASE_URL    = "https://www.joinnus.com"
SOURCE_ID_EXPECTED = 2
JOINNUS_GUESS_CATS = [
    "concerts","art-culture","entertainment","sports",
    "education","family","nightlife","travel","theater",
    "festival","business","charity"
]

engine = create_engine(DB_URL, pool_pre_ping=True, pool_recycle=180)
TZ = pytz.timezone(TZ_NAME)

# ------------------ Utils ------------------
SPACE_RE = re.compile(r"\s+")
PUNCT_RE = re.compile(r"[^\w\s]", re.UNICODE)
ART_SPLIT_RE = re.compile(r"[;/,|]+")
DATE_TXT_RE = re.compile(r"(\d{1,2}\s+de\s+\w+\s+\d{4}|\d{1,2}/\d{1,2}/\d{4})", re.I)

def normalize_url(u: str) -> str:
    p = urlsplit(u)
    path = (p.path or "/").rstrip("/")
    if not path:
        path = "/"
    return urlunsplit((p.scheme.lower(), p.netloc.lower(), path, "", ""))

def md5(s: str) -> str:
    return hashlib.md5(s.encode("utf-8")).hexdigest()

def to_iso_local(s: str | None):
    if not s:
        return None
    try:
        d = dtp.parse(s)
        if not d.tzinfo:
            d = TZ.localize(d)
        return d
    except Exception:
        pass

    d = dateparser.parse(s, languages=["es"])
    if d and not d.tzinfo:
        d = TZ.localize(d)
    return d

def to_utc(local_dt):
    return local_dt.astimezone(pytz.utc) if local_dt else None

def event_status(now_utc, start_utc, end_utc) -> str:
    if not start_utc and not end_utc:
        return "sin_fecha"
    if start_utc and now_utc < start_utc:
        return "proximo"
    if end_utc and now_utc > end_utc:
        return "pasado"
    return "en_curso"

def make_venue_key(name: str | None) -> str:
    if not name:
        return ""
    s = unidecode(name).strip().upper()
    s = PUNCT_RE.sub(" ", s)
    s = SPACE_RE.sub(" ", s)
    return s

def joinnus_build_canonical(slug: str, event_id: str, category: str | None = None) -> str:
    cat = (category or "").strip("/ ")
    if not cat:
        # Placeholder para luego probar categorías reales
        return f"{BASE_URL}/events/_guess_/{slug}-{event_id}"
    return f"{BASE_URL}/events/{cat}/{slug}-{event_id}"

def joinnus_fix_url(original_url: str, meta_hint: dict | None) -> str:
    """
    - Si ya es /events/... => la deja normalizada.
    - Si NO es /events/... y meta_json trae id + category => arma /events/{cat}/{slug}-{id}
    - Caso contrario, devuelve la URL normalizada y parse_detail hará el retry por categorías
      si la URL quedó como /events/_guess_/...
    """
    url = normalize_url(original_url)

    # Ya viene con /events/... (incluye /events/{cat}/slug-id), no tocar más
    if "/events/" in url:
        return url

    mh = meta_hint or {}
    evt_id = str(mh.get("id") or mh.get("eventId") or mh.get("eventoId") or "").strip()
    category = (mh.get("category") or mh.get("categorySlug") or "").strip()

    path = urlsplit(url).path.strip("/")
    slug = path.rsplit("/", 1)[-1] if path else ""

    if evt_id and slug:
        return joinnus_build_canonical(slug, evt_id, category)

    return url

def joinnus_try_categories(session: requests.Session, url_guess: str, timeout=(10, 60)) -> str | None:
    """
    url_guess: https://www.joinnus.com/events/_guess_/slug-12345
    Prueba /events/{cat}/slug-12345 en la lista de categorías.
    """
    if "/events/_guess_/" not in url_guess:
        return None

    tail = url_guess.split("/events/_guess_/", 1)[1]  # slug-12345
    if not tail:
        return None

    for cat in JOINNUS_GUESS_CATS:
        test = f"{BASE_URL}/events/{cat}/{tail}"
        try:
            r = session.get(test, headers={"User-Agent": UA}, timeout=timeout, allow_redirects=True)
            if 200 <= r.status_code < 300:
                return normalize_url(r.url or test)
        except Exception:
            pass
    return None

def norm_artist_name(s: str | None) -> str | None:
    if not s:
        return None
    s = unidecode(s).strip()
    s = re.sub(r"\s+", " ", s)
    return s if s else None

# ------------------ Schema helpers ------------------
def ensure_venue_key_schema():
    with engine.begin() as c:
        col = c.execute(text("""
            SELECT 1 FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME   = 'venue'
               AND COLUMN_NAME  = 'venue_key' LIMIT 1
        """)).scalar()
        if not col:
            c.execute(text("ALTER TABLE venue ADD COLUMN venue_key VARCHAR(255) NULL AFTER name"))

        idx = c.execute(text("""
            SELECT 1 FROM information_schema.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME   = 'venue'
               AND INDEX_NAME   = 'uk_venue_key' LIMIT 1
        """)).scalar()
        if not idx:
            c.execute(text("CREATE UNIQUE INDEX uk_venue_key ON venue(venue_key)"))

# ------------------ Repos / UPSERTS ------------------
def get_source_id() -> int:
    with engine.begin() as c:
        sid = c.execute(
            text("SELECT source_id FROM source WHERE name=:n"),
            {"n": SOURCE_NAME}
        ).scalar()
        if sid:
            return int(sid)

        c.execute(text("""
            INSERT INTO source(source_id, name, base_url)
            VALUES(:id, :n, :u)
            ON DUPLICATE KEY UPDATE
              name=VALUES(name), base_url=VALUES(base_url)
        """), {"id": SOURCE_ID_EXPECTED, "n": SOURCE_NAME, "u": BASE_URL})

        sid = c.execute(
            text("SELECT source_id FROM source WHERE name=:n"),
            {"n": SOURCE_NAME}
        ).scalar()
        return int(sid)

DEPT_HINTS = {
    "lima":"Lima","callao":"Lima","miraflores":"Lima","barranco":"Lima","san isidro":"Lima",
    "arequipa":"Arequipa","cusco":"Cusco","piura":"Piura","trujillo":"La Libertad","chiclayo":"Lambayeque",
}

def guess_department_id(text_block: str | None):
    if not text_block:
        return None
    low = text_block.lower()
    name = None
    for k, v in DEPT_HINTS.items():
        if k in low:
            name = v
            break
    if not name:
        return None

    with engine.begin() as c:
        c.execute(
            text("INSERT IGNORE INTO department(name, region) VALUES(:n,:r)"),
            {"n": name, "r": name}
        )
        return c.execute(
            text("SELECT department_id FROM department WHERE name=:n"),
            {"n": name}
        ).scalar()

def upsert_venue(name, address, district, province, department_id, lat=None, lon=None):
    if not name:
        return None
    vkey = make_venue_key(name)
    with engine.begin() as c:
        c.execute(text("""
            INSERT INTO venue(name, venue_key, address, district, province, department_id, latitude, longitude)
            VALUES(:n,:k,:a,:d,:p,:dep,:lat,:lon)
            ON DUPLICATE KEY UPDATE
              address=COALESCE(venue.address,VALUES(address)),
              district=COALESCE(venue.district,VALUES(district)),
              province=COALESCE(venue.province,VALUES(province)),
              department_id=COALESCE(venue.department_id,VALUES(department_id)),
              latitude=COALESCE(venue.latitude,VALUES(latitude)),
              longitude=COALESCE(venue.longitude,VALUES(longitude))
        """), {
            "n": name, "k": vkey, "a": address, "d": district, "p": province,
            "dep": department_id, "lat": lat, "lon": lon
        })
        return int(
            c.execute(text("SELECT venue_id FROM venue WHERE venue_key=:k"), {"k": vkey}).scalar()
        )

def upsert_category(name: str | None):
    if not name:
        return None
    with engine.begin() as c:
        c.execute(text("INSERT IGNORE INTO category(name) VALUES(:n)"), {"n": name})
        return c.execute(text("SELECT category_id FROM category WHERE name=:n"), {"n": name}).scalar()

def link_event_category(event_id: int, category_id: int):
    with engine.begin() as c:
        c.execute(
            text("INSERT IGNORE INTO event_category(event_id, category_id) VALUES(:e,:c)"),
            {"e": event_id, "c": category_id}
        )

def upsert_event(source_id, src_event_id, title, desc_html,
                 starts_local, ends_local, tz_name,
                 starts_utc, ends_utc, status,
                 venue_id, department_id, ticket_url, canonical_url, hash_dedupe):
    with engine.begin() as c:
        c.execute(text("""
            INSERT INTO event(
              source_id, source_event_id, title, description_html,
              starts_at_local, ends_at_local, tz_name, starts_at_utc, ends_at_utc, status,
              venue_id, department_id, ticket_url, canonical_url, hash_dedupe
            ) VALUES (
              :sid,:seid,:t,:d,:sl,:el,:tz,:su,:eu,:st,:vid,:dep,:tu,:cu,:h
            )
            ON DUPLICATE KEY UPDATE
              title = VALUES(title),
              description_html = COALESCE(VALUES(description_html), event.description_html),
              starts_at_local = COALESCE(VALUES(starts_at_local), event.starts_at_local),
              ends_at_local   = COALESCE(VALUES(ends_at_local),   event.ends_at_local),
              starts_at_utc   = COALESCE(VALUES(starts_at_utc),   event.starts_at_utc),
              ends_at_utc     = COALESCE(VALUES(ends_at_utc),     event.ends_at_utc),
              status          = VALUES(status),
              venue_id        = COALESCE(VALUES(venue_id),        event.venue_id),
              department_id   = COALESCE(VALUES(department_id),   event.department_id),
              ticket_url      = VALUES(ticket_url),
              canonical_url   = VALUES(canonical_url),
              hash_dedupe     = VALUES(hash_dedupe)
        """), {
            "sid": source_id, "seid": src_event_id, "t": title, "d": desc_html,
            "sl": starts_local, "el": ends_local, "tz": tz_name,
            "su": starts_utc, "eu": ends_utc, "st": status,
            "vid": venue_id, "dep": department_id, "tu": ticket_url, "cu": canonical_url, "h": hash_dedupe
        })

        return int(c.execute(text("""
            SELECT event_id
              FROM event
             WHERE source_id=:sid AND source_event_id=:seid
        """), {"sid": source_id, "seid": src_event_id}).scalar())

def insert_ticket_link(event_id: int, url: str):
    with engine.begin() as c:
        c.execute(text("""
            INSERT IGNORE INTO ticket_link(event_id,url,provider)
            VALUES(:e,:u,'Joinnus')
        """), {"e": event_id, "u": url})

def insert_media_cover(event_id: int, url: str | None):
    if not url:
        return
    with engine.begin() as c:
        c.execute(text("""
            INSERT IGNORE INTO media(event_id,kind,url,is_cover)
            VALUES(:e,'image',:u,1)
        """), {"e": event_id, "u": url})

def audit(save: dict):
    with engine.begin() as c:
        c.execute(text("""
            INSERT INTO ingest_audit(
              source_id, url, page_type, http_status, fetched_at,
              selector_ok, raw_path, content_hash, error_msg
            ) VALUES (
              :sid,:u,'detail',:st,:ft,:ok,:raw,:hash,:err
            )
        """), save)

# ------------------ Parser Joinnus ------------------
def parse_jsonld(soup: BeautifulSoup) -> dict:
    for s in soup.find_all("script", {"type": "application/ld+json"}):
        try:
            obj = json.loads(s.string or "{}")
        except Exception:
            continue

        cand = []
        if isinstance(obj, dict):
            cand = [obj]
        elif isinstance(obj, list):
            cand = [x for x in obj if isinstance(x, dict)]

        for it in cand:
            ty = (it.get("@type") or "").lower()
            if "event" in ty:
                return it
    return {}

def meta(soup: BeautifulSoup, name_or_prop: str):
    tag = soup.find("meta", attrs={"name": name_or_prop}) or soup.find("meta", attrs={"property": name_or_prop})
    return tag.get("content").strip() if tag and tag.get("content") else None

DATE_TXT_RE = re.compile(r"\b(\d{1,2}\s+de\s+\w+\s+\d{4})\b", re.I)

def parse_detail(session: requests.Session, url: str, meta_hint: dict | None) -> dict:
    """
    - Intenta GET
    - Si 404 y url contiene /events/_guess_/ => prueba categorías
    - Devuelve effective_url para persistir canónica en url_queue
    """
    effective_url = url

    try:
        resp = session.get(url, headers={"User-Agent": UA}, timeout=(10, 60), allow_redirects=True)
        resp.raise_for_status()
    except requests.HTTPError as e:
        if getattr(e.response, "status_code", None) == 404 and "/events/_guess_/" in url:
            candidate = joinnus_try_categories(session, url)
            if not candidate:
                raise
            resp = session.get(candidate, headers={"User-Agent": UA}, timeout=(10, 60), allow_redirects=True)
            resp.raise_for_status()
            effective_url = candidate
        else:
            raise

    soup = BeautifulSoup(resp.text, "html.parser")
    ld = parse_jsonld(soup)

    # Base
    title = ld.get("name") or meta(soup, "og:title") or (soup.find("h1").get_text(strip=True) if soup.find("h1") else None)
    desc  = ld.get("description") or meta(soup, "og:description")

    image = None
    if isinstance(ld.get("image"), list) and ld["image"]:
        image = ld["image"][0]
    elif isinstance(ld.get("image"), str):
        image = ld["image"]
    else:
        image = meta(soup, "og:image")

    # Fechas
    start_local = to_iso_local(ld.get("startDate"))
    end_local   = to_iso_local(ld.get("endDate"))

    if not start_local:
        ttag = soup.find("time")
        if ttag and ttag.get("datetime"):
            start_local = to_iso_local(ttag.get("datetime"))
        if not start_local:
            m = DATE_TXT_RE.search(soup.get_text(" ", strip=True))
            if m:
                start_local = to_iso_local(m.group(1))

    # Lugar
    venue_name = address = district = city = country = None
    loc = ld.get("location")
    if isinstance(loc, dict):
        venue_name = loc.get("name")
        addr = loc.get("address")
        if isinstance(addr, dict):
            address  = addr.get("streetAddress")
            district = addr.get("addressLocality")
            city     = addr.get("addressRegion") or addr.get("addressLocality")
            country  = addr.get("addressCountry")

    # Precio (opcional)
    price_text = None
    if isinstance(ld.get("offers"), dict):
        price_text = f"{ld['offers'].get('priceCurrency','')} {ld['offers'].get('price')}"
    elif isinstance(ld.get("offers"), list) and ld["offers"]:
        o0 = ld["offers"][0]
        price_text = f"{o0.get('priceCurrency','')} {o0.get('price')}"

    # meta_hint refuerzo
    if meta_hint:
        title = title or meta_hint.get("title")
        image = image or meta_hint.get("image")
        venue_name = venue_name or meta_hint.get("location")
        if not start_local and meta_hint.get("date"):
            start_local = to_iso_local(meta_hint["date"])

    return {
        "title": title,
        "description_html": desc,
        "image_url": image,
        "venue_name": venue_name,
        "address": address,
        "district": district,
        "city": city,
        "country": country,
        "start_local": start_local,
        "end_local": end_local,
        "price_text": price_text,
        "raw_html": resp.text,
        "http_status": resp.status_code,
        "effective_url": effective_url,
    }

# ------------------ Batch driver ------------------
def pick_batch(source_id: int):
    with engine.begin() as c:
        rows = c.execute(text("""
            SELECT url_id, url, meta_json
              FROM url_queue
             WHERE source_id=:sid AND status='nuevo'
             ORDER BY url_id ASC
             LIMIT :lim
        """), {"sid": source_id, "lim": BATCH_LIMIT}).mappings().all()
        return [dict(r) for r in rows]

def run():
    ensure_venue_key_schema()
    source_id = get_source_id()
    batch = pick_batch(source_id)
    if not batch:
        print("[HU3.4][Joinnus] No hay URLs pendientes.")
        return

    sess = requests.Session()
    ok = err = 0

    for row in batch:
        url_id = row["url_id"]
        detail_url = normalize_url(row["url"])

        meta_hint = None
        if row.get("meta_json"):
            try:
                meta_hint = json.loads(row["meta_json"])
            except Exception:
                meta_hint = None

        try:
            # Corrige URL con meta_json (si trae id/categoría); si no, queda igual
            detail_url = joinnus_fix_url(detail_url, meta_hint)

            parsed = parse_detail(sess, detail_url, meta_hint)

            # Persistir canónica si cambió por retry
            eff = parsed.get("effective_url")
            if eff:
                eff = normalize_url(eff)

            if eff and eff != detail_url:
                with engine.begin() as c:
                    c.execute(
                        text("UPDATE url_queue SET url=:u WHERE url_id=:i"),
                        {"u": eff, "i": url_id}
                    )
                detail_url = eff

            title = (parsed["title"] or "").strip()
            start_local = parsed["start_local"]
            end_local   = parsed["end_local"]

            start_utc = to_utc(start_local) if start_local else None
            end_utc   = to_utc(end_local) if end_local else None
            now_utc   = datetime.now(timezone.utc)
            status    = event_status(now_utc, start_utc, end_utc)

            # ID fuente
            raw_seid = (meta_hint or {}).get("eventoId") or (meta_hint or {}).get("id") or detail_url.rsplit("/", 1)[-1]
            source_event_id = (raw_seid or "")[:255]

            # venue / department
            dept_id = guess_department_id(" ".join(filter(None, [
                parsed["district"], parsed["city"], parsed["venue_name"], parsed["address"]
            ])))
            venue_id = upsert_venue(
                parsed["venue_name"], parsed["address"],
                parsed["district"], parsed["city"], dept_id
            )

            # hash dedupe
            hash_dedupe = md5(
                f"{title}|{(start_local.isoformat() if start_local else '')}|{parsed['venue_name'] or ''}"
            )

            # upsert event
            event_id = upsert_event(
                source_id=source_id,
                src_event_id=source_event_id,
                title=title,
                desc_html=parsed["description_html"],
                starts_local=(start_local.astimezone(TZ).replace(tzinfo=None) if start_local else None),
                ends_local=(end_local.astimezone(TZ).replace(tzinfo=None) if end_local else None),
                tz_name=TZ_NAME,
                starts_utc=(start_utc.replace(tzinfo=None) if start_utc else None),
                ends_utc=(end_utc.replace(tzinfo=None) if end_utc else None),
                status=status,
                venue_id=venue_id,
                department_id=dept_id,
                ticket_url=detail_url,
                canonical_url=detail_url,
                hash_dedupe=hash_dedupe
            )

            # Categoría heurística por ruta (opcional)
            low = detail_url.lower()
            cat_hint = None
            if "/conciert" in low or "/music" in low:
                cat_hint = "Conciertos"
            elif "/teatro" in low or "/theater" in low:
                cat_hint = "Teatro"
            elif "/deporte" in low or "/sports" in low:
                cat_hint = "Deportes"
            elif "/familia" in low or "/family" in low or "/entreten" in low:
                cat_hint = "Entretenimiento"
            elif "/turismo" in low or "/travel" in low:
                cat_hint = "Turismo"

            if cat_hint:
                cat_id = upsert_category(cat_hint)
                if cat_id:
                    link_event_category(event_id, cat_id)

            insert_ticket_link(event_id, detail_url)
            insert_media_cover(event_id, parsed["image_url"])

            # Auditoría OK
            audit({
                "sid": source_id,
                "u": detail_url,
                "st": parsed["http_status"],
                "ft": datetime.now(),
                "ok": 1,
                "raw": None,
                "hash": md5((parsed["raw_html"] or "")[:100000]),
                "err": None
            })

            with engine.begin() as c:
                c.execute(
                    text("UPDATE url_queue SET status='procesado', last_error=NULL WHERE url_id=:i"),
                    {"i": url_id}
                )

            ok += 1
            print(f"[OK][Joinnus] url_id={url_id} → event_id={event_id} | {title[:80]}")

        except Exception as ex:
            err += 1

            audit({
                "sid": source_id,
                "u": detail_url,
                "st": None,
                "ft": datetime.now(),
                "ok": 0,
                "raw": None,
                "hash": None,
                "err": str(ex)[:480]
            })

            with engine.begin() as c:
                c.execute(
                    text("UPDATE url_queue SET status='error', last_error=:e WHERE url_id=:i"),
                    {"e": str(ex)[:2000], "i": url_id}
                )

            print(f"[ERR][Joinnus] url_id={url_id} → {ex}")

    print(f"[HU3.4][Joinnus] Terminado. OK={ok} | Error={err}")

if __name__ == "__main__":
    run()
