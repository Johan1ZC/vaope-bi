# -*- coding: utf-8 -*-
"""
HU3.2 — Teleticket → DW (dw_dev_hablavao)
- Lee url_queue 'nuevo' de Teleticket (meta_json opcional)
- Descarga detalle, parsea JSON-LD/fallback
- Mapea y UPSERT a: source, department, venue, event, category, event_category, ticket_link, media, ingest_audit
"""

import os, re, json, hashlib, requests, pytz, dateparser
from bs4 import BeautifulSoup
from datetime import datetime, timezone
now_utc = datetime.now(timezone.utc)  # timezone-aware
from dateutil import parser as dtp
from urllib.parse import urlsplit, urlunsplit
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from unidecode import unidecode


# ------------------ ENV ------------------
load_dotenv()
DB_URL      = os.getenv("DB_URL", "mysql+pymysql://user:pass@localhost:3306/dw_dev_hablavao?charset=utf8mb4")
UA          = os.getenv("UA", "HABLAVAO/1.0 (+contacto@tu-dominio.pe)")
BATCH_LIMIT = int(os.getenv("PARSER_BATCH", "40"))
TZ_NAME     = os.getenv("TZ_NAME", "America/Lima")

engine = create_engine(DB_URL, pool_pre_ping=True, pool_recycle=180)
TZ = pytz.timezone(TZ_NAME)

# ------------------ Utils ------------------
def normalize_url(u: str) -> str:
    p = urlsplit(u)
    return urlunsplit((p.scheme.lower(), p.netloc.lower(), (p.path or "/").rstrip("/"), "", ""))

def md5(s: str) -> str:
    return hashlib.md5(s.encode("utf-8")).hexdigest()

def to_iso_local(s: str|None) -> datetime|None:
    if not s: return None
    # ISO directo
    try:
        d = dtp.parse(s)
        if not d.tzinfo:  # vuelve explícita la TZ local
            d = TZ.localize(d)
        return d
    except Exception:
        pass
    # español
    d = dateparser.parse(s, languages=["es"])
    if d:
        if not d.tzinfo:
            d = TZ.localize(d)
        return d
    return None

def to_utc(local_dt: datetime|None) -> datetime|None:
    return local_dt.astimezone(pytz.utc) if local_dt else None

def event_status(now_utc: datetime, start_utc: datetime|None, end_utc: datetime|None) -> str:
    if not start_utc and not end_utc:
        return "sin_fecha"
    if start_utc and now_utc < start_utc:
        return "proximo"
    if end_utc and now_utc > end_utc:
        return "pasado"
    return "en_curso"

# nuevo
SPACE_RE = re.compile(r"\s+")
PUNCT_RE = re.compile(r"[^\w\s]", re.UNICODE)

def make_venue_key(name: str | None) -> str:
    if not name:
        return ""
    s = unidecode(name)          # quita tildes: Á->A
    s = s.strip().upper()
    s = PUNCT_RE.sub(" ", s)     # signos -> espacio
    s = SPACE_RE.sub(" ", s)     # colapsa espacios múltiples
    return s

# ------------------ Schema helpers ---NUEVO---------------
def ensure_venue_key_schema():
    """
    Asegura que 'venue' tenga la columna venue_key y un índice UNIQUE.
    Es idempotente: si ya existen, no hace nada.
    """
    with engine.begin() as c:
        # ¿Existe la columna?
        col = c.execute(text("""
            SELECT 1
              FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME   = 'venue'
               AND COLUMN_NAME  = 'venue_key'
            LIMIT 1
        """)).scalar()

        if not col:
            c.execute(text("""
                ALTER TABLE venue
                  ADD COLUMN venue_key VARCHAR(255) NULL AFTER name
            """))

        # ¿Existe el índice UNIQUE?
        idx = c.execute(text("""
            SELECT 1
              FROM information_schema.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME   = 'venue'
               AND INDEX_NAME   = 'uk_venue_key'
            LIMIT 1
        """)).scalar()

        if not idx:
            # Si hay duplicados de name, el UNIQUE por venue_key evitará más duplicados
            c.execute(text("""
                CREATE UNIQUE INDEX uk_venue_key ON venue(venue_key)
            """))

ART_SPLIT_RE = re.compile(r"[;/,|]+")
def norm_artist_name(s: str|None) -> str|None:
    if not s: return None
    s = unidecode(s).strip()
    s = re.sub(r"\s+", " ", s)
    return s if s else None

def upsert_artist(name: str, alt_names: str|None=None) -> int:
    name = name[:200]
    if alt_names: alt_names = alt_names[:255]
    with engine.begin() as c:
        c.execute(text("""
            INSERT INTO artist(name, alt_names)
            VALUES(:n, :a)
            ON DUPLICATE KEY UPDATE
              alt_names = COALESCE(artist.alt_names, VALUES(alt_names))
        """), {"n": name, "a": alt_names})
        return int(c.execute(text("SELECT artist_id FROM artist WHERE name=:n"), {"n": name}).scalar())

def link_event_artist(event_id: int, artist_id: int, role: str|None=None):
    role = (role or "")[:60]
    with engine.begin() as c:
        # si ya existe, no duplica
        c.execute(text("""
            INSERT IGNORE INTO event_artist(event_id, artist_id, role)
            VALUES(:e,:a,:r)
        """), {"e": event_id, "a": artist_id, "r": role})

            

# ------------------ Repos / UPSERTS ------------------
def get_source_id() -> int:
    with engine.begin() as c:
        c.execute(text("""
            INSERT INTO source(name, base_url) VALUES('Teleticket','https://teleticket.com.pe/')
            ON DUPLICATE KEY UPDATE base_url=VALUES(base_url)
        """))
        return int(c.execute(text("SELECT source_id FROM source WHERE name='Teleticket'")).scalar())

# Mapa muy simple de departamento por texto; ajústalo con tu catálogo real/ubigeo
DEPT_HINTS = {
    "lima": "Lima", "cusco":"Cusco", "arequipa":"Arequipa", "piura":"Piura",
    "trujillo":"La Libertad", "callao":"Lima", "miraflores":"Lima", "barranco":"Lima",
}
def guess_department_id(text_block: str|None) -> int|None:
    if not text_block: return None
    low = text_block.lower()
    name = None
    for k,v in DEPT_HINTS.items():
        if k in low: name = v; break
    if not name: return None
    with engine.begin() as c:
        c.execute(text("INSERT IGNORE INTO department(name, region) VALUES(:n, :r)"),
                  {"n": name, "r": name})
        return c.execute(text("SELECT department_id FROM department WHERE name=:n"), {"n": name}).scalar()

def upsert_venue(name: str|None, address: str|None, district: str|None, province: str|None,
                 department_id: int|None, lat=None, lon=None) -> int|None:
    if not name:
        return None

    vkey = make_venue_key(name)

    with engine.begin() as c:
        # Inserta (o reutiliza) por venue_key; completa campos solo si están NULL
        c.execute(text("""
            INSERT INTO venue(name, venue_key, address, district, province, department_id, latitude, longitude)
            VALUES(:n, :k, :a, :d, :p, :dep, :lat, :lon)
            ON DUPLICATE KEY UPDATE
                address       = COALESCE(venue.address,       VALUES(address)),
                district      = COALESCE(venue.district,      VALUES(district)),
                province      = COALESCE(venue.province,      VALUES(province)),
                department_id = COALESCE(venue.department_id, VALUES(department_id)),
                latitude      = COALESCE(venue.latitude,      VALUES(latitude)),
                longitude     = COALESCE(venue.longitude,     VALUES(longitude))
        """), {"n": name, "k": vkey, "a": address, "d": district, "p": province,
               "dep": department_id, "lat": lat, "lon": lon})

        # Devuelve el id por venue_key (no por name)
        return int(c.execute(text("SELECT venue_id FROM venue WHERE venue_key=:k"),
                             {"k": vkey}).scalar())


def upsert_category(name: str|None) -> int|None:
    if not name: return None
    with engine.begin() as c:
        c.execute(text("INSERT IGNORE INTO category(name) VALUES(:n)"), {"n": name})
        return c.execute(text("SELECT category_id FROM category WHERE name=:n"), {"n": name}).scalar()

def link_event_category(event_id: int, category_id: int):
    with engine.begin() as c:
        c.execute(text("""
        INSERT IGNORE INTO event_category(event_id, category_id) VALUES(:e,:c)
        """), {"e": event_id, "c": category_id})

def upsert_event(source_id: int, src_event_id: str, title: str, desc_html: str|None,
                 starts_local, ends_local, tz_name: str,
                 starts_utc, ends_utc, status: str,
                 venue_id: int|None, department_id: int|None,
                 ticket_url: str, canonical_url: str,
                 hash_dedupe: str) -> int:
    with engine.begin() as c:
        c.execute(text("""
        INSERT INTO event(
            source_id, source_event_id, title, description_html,
            starts_at_local, ends_at_local, tz_name, starts_at_utc, ends_at_utc, status,
            venue_id, department_id, ticket_url, canonical_url, hash_dedupe
        ) VALUES (
            :sid, :seid, :t, :d, :sl, :el, :tz, :su, :eu, :st, :vid, :dep, :tu, :cu, :h
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
            "sid":source_id, "seid":src_event_id, "t":title, "d":desc_html,
            "sl":starts_local, "el":ends_local, "tz":tz_name,
            "su":starts_utc, "eu":ends_utc, "st":status,
            "vid":venue_id, "dep":department_id, "tu":ticket_url, "cu":canonical_url, "h":hash_dedupe
        })
        return int(c.execute(text("""
            SELECT event_id FROM event WHERE source_id=:sid AND source_event_id=:seid
        """), {"sid":source_id, "seid":src_event_id}).scalar())

def insert_ticket_link(event_id: int, url: str):
    with engine.begin() as c:
        c.execute(text("""
        INSERT IGNORE INTO ticket_link(event_id,url,provider) VALUES(:e,:u,'Teleticket')
        """), {"e":event_id, "u":url})

def insert_media_cover(event_id: int, url: str|None):
    if not url: return
    with engine.begin() as c:
        c.execute(text("""
        INSERT IGNORE INTO media(event_id,kind,url,is_cover) VALUES(:e,'image',:u,1)
        """), {"e":event_id, "u":url})

def audit(save: dict):
    with engine.begin() as c:
        c.execute(text("""
        INSERT INTO ingest_audit(
            source_id, url, page_type, http_status, fetched_at,
            selector_ok, raw_path, content_hash, error_msg
        ) VALUES (
            :sid, :u, 'detail', :st, :ft, :ok, :raw, :hash, :err
        )
        """), save)

# ------------------ Parser Teleticket ------------------
def parse_jsonld(soup: BeautifulSoup) -> dict:
    """Toma schema.org/Event si existe."""
    for s in soup.find_all("script", {"type":"application/ld+json"}):
        try:
            obj = json.loads(s.string or "{}")
        except Exception:
            continue
        cand = []
        if isinstance(obj, dict): cand = [obj]
        if isinstance(obj, list): cand = [x for x in obj if isinstance(x, dict)]
        for it in cand:
            ty = (it.get("@type") or "").lower()
            if "event" in ty:
                return it
    return {}

def parse_detail(url: str, meta_hint: dict|None) -> dict:
    html = requests.get(url, headers={"User-Agent": UA}, timeout=(10,60))
    html.raise_for_status()
    soup = BeautifulSoup(html.text, "html.parser")
    ld = parse_jsonld(soup)

    # ---- Campos base
    title = ld.get("name") or (soup.find("h1").get_text(strip=True) if soup.find("h1") else None)
    desc  = ld.get("description")
    image = ld.get("image")[0] if isinstance(ld.get("image"), list) else (ld.get("image") if isinstance(ld.get("image"), str) else None)

    start_local = to_iso_local(ld.get("startDate"))
    end_local   = to_iso_local(ld.get("endDate"))

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

    price_text = None
    if isinstance(ld.get("offers"), dict):
        price_text = f"{ld['offers'].get('priceCurrency','')} {ld['offers'].get('price')}"
    elif isinstance(ld.get("offers"), list) and ld["offers"]:
        o0 = ld["offers"][0]
        price_text = f"{o0.get('priceCurrency','')} {o0.get('price')}"

    # ---- Refuerzo con meta_hint
    if meta_hint:
        title = title or meta_hint.get("title")
        image = image or meta_hint.get("image")
        venue_name = venue_name or meta_hint.get("location")
        if not start_local and meta_hint.get("date"):
            start_local = to_iso_local(meta_hint["date"])

    # ---- Artistas
    artists: list[dict] = []

    def push(name: str, role: str|None=None, alt: str|None=None):
        n = norm_artist_name(name)
        if not n:
            return
        key = (n.lower(), (role or "").lower())
        if key not in {(a["name"].lower(), (a.get("role") or "").lower()) for a in artists}:
            artists.append({"name": n, "role": role, "alt": alt})

    cand = []
    if isinstance(ld.get("performer"), list): cand += ld["performer"]
    elif isinstance(ld.get("performer"), dict): cand += [ld["performer"]]
    if isinstance(ld.get("byArtist"), list): cand += ld["byArtist"]
    elif isinstance(ld.get("byArtist"), dict): cand += [ld["byArtist"]]
    for it in cand:
        if isinstance(it, dict):
            push(it.get("name") or it.get("alternateName"))
        elif isinstance(it, str):
            for piece in ART_SPLIT_RE.split(it):
                push(piece)

    byline = ld.get("byLine") or ""
    for piece in ART_SPLIT_RE.split(byline):
        if piece: push(piece)

    kws = ld.get("keywords")
    if isinstance(kws, list):
        for k in kws: push(k)
    elif isinstance(kws, str):
        for piece in ART_SPLIT_RE.split(kws): push(piece)

    # Heurística HTML
    for lbl in ["Artistas", "Artista", "Banda", "Elenco", "Invitado", "Line up", "Line-up"]:
        for node in soup.find_all(string=re.compile(lbl, re.I)):
            parent = node.parent
            if not parent: 
                continue
            texts = []
            for sib in parent.find_all(["span","p","li","a"]):
                t = sib.get_text(" ", strip=True)
                if t and len(t) <= 120: texts.append(t)
            for piece in ART_SPLIT_RE.split(", ".join(texts)):
                push(piece)

    if not artists and title:
        m = re.match(r"(.+?)\s+en\s+.*", title, flags=re.I)
        if m: push(m.group(1))

    if meta_hint:
        for k in ["artist", "artists", "tags"]:
            v = meta_hint.get(k)
            if isinstance(v, list):
                for x in v: push(x)
            elif isinstance(v, str):
                for piece in ART_SPLIT_RE.split(v): push(piece)

    # ---- ÚNICO return al final
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
        "artists": artists,
        "raw_html": html.text,
        "http_status": html.status_code
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
        """), {"sid":source_id, "lim":BATCH_LIMIT}).mappings().all()
        return [dict(r) for r in rows]

def run():
    ensure_venue_key_schema() 
    source_id = get_source_id()
    batch = pick_batch(source_id)
    if not batch:
        print("[HU3.2][Teleticket] No hay URLs pendientes.")
        return

    ok=err=0
    for row in batch:
        url_id = row["url_id"]
        detail_url = normalize_url(row["url"])
        meta_hint = None
        try:
            if row.get("meta_json"):
                try: meta_hint = json.loads(row["meta_json"])
                except Exception: meta_hint = None

            parsed = parse_detail(detail_url, meta_hint)

            # Campos finales
            title = (parsed["title"] or "").strip()
            start_local = parsed["start_local"]
            end_local   = parsed["end_local"]
            start_utc   = to_utc(start_local) if start_local else None
            end_utc     = to_utc(end_local) if end_local else None
            now_utc     = datetime.utcnow().replace(tzinfo=pytz.utc)
            status      = event_status(now_utc, start_utc, end_utc)

            # IDs de fuente
            # - usa eventoId API si vino en meta_json; sino slug final de la URL como source_event_id
            raw_seid = (meta_hint or {}).get("eventoId") or detail_url.rsplit("/", 1)[-1]
            source_event_id = (raw_seid or "")[:255]  # cap a 255 para alinear con el DDL

            # venue / department
            dept_id = guess_department_id(" ".join(filter(None,[parsed["district"], parsed["city"], parsed["venue_name"], parsed["address"]])))
            venue_id = upsert_venue(parsed["venue_name"], parsed["address"], parsed["district"], parsed["city"], dept_id)

            # hash dedupe
            hash_dedupe = md5(f"{title}|{(start_local.isoformat() if start_local else '')}|{parsed['venue_name'] or ''}")

            # UPSERT event
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

                        # --- ARTISTAS ---
            for art in (parsed.get("artists") or []):
                name = art.get("name")
                role = art.get("role")
                alt  = art.get("alt")
                if not name:
                    continue
                try:
                    artist_id = upsert_artist(name, alt)
                    link_event_artist(event_id, artist_id, role)
                except Exception as e:
                    print(f"[WARN][artist] {name}: {e}")


            # categoría simple por URL (ajústalo con tus criterios)
            cat_hint = None
            low = detail_url.lower()
            if "/conciert" in low: cat_hint = "Conciertos"
            elif "/teatro" in low: cat_hint = "Teatro"
            elif "/deporte" in low: cat_hint = "Deportes"
            elif "/entreten" in low: cat_hint = "Entretenimiento"
            elif "/turismo" in low: cat_hint = "Turismo"
            if cat_hint:
                cat_id = upsert_category(cat_hint)
                if cat_id: link_event_category(event_id, cat_id)

            insert_ticket_link(event_id, detail_url)
            insert_media_cover(event_id, parsed["image_url"])

            # auditoría
            audit({
                "sid":source_id,
                "u":detail_url,
                "st":parsed["http_status"],
                "ft":datetime.now(),
                "ok":1,
                "raw":None,
                "hash":md5((parsed["raw_html"] or "")[:100000]),
                "err":None
            })

            # marcar url_queue
            with engine.begin() as c:
                c.execute(text("UPDATE url_queue SET status='procesado', last_error=NULL WHERE url_id=:i"), {"i":url_id})

            ok += 1
            print(f"[OK] url_id={url_id} → event_id={event_id} | {title[:80]}")
        except Exception as ex:
            err += 1
            # auditoría + marca error
            audit({
                "sid":source_id, "u":detail_url, "st":None, "ft":datetime.now(),
                "ok":0, "raw":None, "hash":None, "err":str(ex)[:480]
            })
            with engine.begin() as c:
                c.execute(text("UPDATE url_queue SET status='error', last_error=:e WHERE url_id=:i"),
                            {"e": str(ex)[:2000], "i": url_id}   # cap “defensivo”
)
            print(f"[ERR] url_id={url_id} → {ex}")

    print(f"[HU3.2][Teleticket] Terminado. OK={ok} | Error={err}")

if __name__ == "__main__":
    run()
