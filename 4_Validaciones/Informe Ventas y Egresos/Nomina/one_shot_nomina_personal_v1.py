# -*- coding: utf-8 -*-
"""
Autor: Johan Zuñiga Cordova
one_shot_nomina_all.py
- Extrae boletas de pago (Payroll Slips) desde la API dev.api.colaborativa.pe
- Auth: X-API-Key (también soporta Bearer/Basic opcionalmente)
- Paginación robusta: offset -> fallback a page/page_size si el backend lo exige
- Filtros opcionales: date_from, date_to, employee_id
- Exporta: RAW json/jsonl y CSV normalizado (slips.csv) formateado para Excel
"""

import json
from datetime import datetime
from pathlib import Path
import requests
import pandas as pd
import numpy as np

# =========== CONFIGURA AQUÍ ===========
BASE_URL   = "https://dev.api.colaborativa.pe"
ENDPOINT   = "/api/payroll/slips"            # base; usaremos /filter si hay fechas/empleado
API_KEY    = "tu_token_secreto"              # Header: X-API-Key
# Si prefieres probar Bearer/Basic, activa y completa (solo 1 a la vez):
USE_BEARER = False
BEARER     = "otro_token"
USE_BASIC  = False
BASIC_USER = "apiclient"
BASIC_PASS = "apipass"

# Filtros (dejar en "" para no aplicar)
DATE_FROM   = ""   # ej "2025-01-01"
DATE_TO     = ""   # ej "2025-12-31"
EMPLOYEE_ID = ""   # ej "123"

# Paginación
LIMIT      = 200
OFFSET     = 0
MAX_PAGES  = 1000

# GET + body JSON (Thunder/tu API lo acepta). Si prefieres query params, pon False.
GET_WITH_BODY = True

# Carpeta de salida (Windows)
OUTDIR = r"C:/Users/SOPORTE/Desktop/vaope-bi/4_Validaciones/Informe Ventas y Egresos/Nomina/salida_nomina_personal"
CSV_SEPARATOR = ";"  # ideal para Excel ES

# ======================================


# ------------------------ HTTP helpers ------------------------
def _auth_headers():
    headers = {"Accept": "application/json"}
    # Prioridad: X-API-Key, luego Bearer, luego Basic
    if API_KEY:
        headers["X-API-Key"] = API_KEY
    elif USE_BEARER and BEARER:
        headers["Authorization"] = f"Bearer {BEARER}"
    # Basic se maneja por requests auth=, no aquí en headers
    return headers

def _prepare(method, url, headers, params=None, body_json=None, auth=None):
    req = requests.Request(method, url, headers=headers, params=params, json=body_json, auth=auth)
    prepped = req.prepare()
    print(f"[HTTP] {method} {prepped.url}")
    if body_json:
        print("[HTTP] BODY:", json.dumps(body_json, ensure_ascii=False)[:600])
    return prepped

def call_api(method, url, params=None, body_json=None):
    headers = _auth_headers()
    auth = (BASIC_USER, BASIC_PASS) if (USE_BASIC and BASIC_USER and BASIC_PASS and not API_KEY and not USE_BEARER) else None
    prepped = _prepare(method, url, headers, params=params, body_json=body_json, auth=auth)
    with requests.Session() as s:
        resp = s.send(prepped, timeout=120)
    # Levanta error si 4xx/5xx
    try:
        resp.raise_for_status()
    except requests.HTTPError as e:
        print("==> RESPONSE TEXT:", resp.text[:1000])
        raise e
    # Devuelve JSON
    return resp.json()


# ------------------------ Payload parsing ------------------------
def extract_list(payload):
    """
    Soporta formatos:
      - {"result":{"success":true,"data":[...]}}
      - {"data":[...]}
      - {"items":[...]}
      - [...]
      - {...} (1 registro) -> lista de 1
    """
    if isinstance(payload, dict):
        data = payload.get("result", {}).get("data")
        if isinstance(data, list):
            return data
        data = payload.get("data")
        if isinstance(data, list):
            return data
        data = payload.get("items")
        if isinstance(data, list):
            return data
        return [payload]
    elif isinstance(payload, list):
        return payload
    else:
        return []


# ------------------------ Builders ------------------------
def target_url_and_filters():
    # Si hay filtros de fecha o employee, usamos /filter
    has_filters = bool(DATE_FROM or DATE_TO or EMPLOYEE_ID)
    endpoint = ENDPOINT + ("/filter" if has_filters else "")
    return f"{BASE_URL}{endpoint}", has_filters

def build_query(offset: int, page: int, mode: str):
    q = {}
    if DATE_FROM:   q["date_from"] = DATE_FROM
    if DATE_TO:     q["date_to"]   = DATE_TO
    if EMPLOYEE_ID: q["employee_id"] = EMPLOYEE_ID

    if mode == "offset":
        q["limit"]  = LIMIT
        q["offset"] = offset
    else:
        # fallback
        q["page_size"] = LIMIT
        q["page"]      = page
    return q

def build_body(offset: int, page: int, mode: str):
    b = {}
    if DATE_FROM:   b["date_from"] = DATE_FROM
    if DATE_TO:     b["date_to"]   = DATE_TO
    if EMPLOYEE_ID: b["employee_id"] = EMPLOYEE_ID

    if mode == "offset":
        b["limit"]  = LIMIT
        b["offset"] = offset
    else:
        b["page_size"] = LIMIT
        b["page"]      = page
    return b


# ------------------------ Dedupe key ------------------------
def make_key(row: dict) -> str:
    """
    Clave compuesta robusta para boletas.
    Preferimos boletaID si existe; si no, combinamos empleado+fecha+boletaID/correlativo.
    """
    bid  = str(row.get("boletaID") or row.get("boletaId") or row.get("boleta") or "").strip()
    emp  = str(row.get("nomEmpleado") or row.get("empleado") or row.get("employee") or "").strip()
    fpg  = str(row.get("fechaPago") or row.get("fecha", "")).strip()
    corr = str(row.get("correlativo") or row.get("serie") or "").strip()
    base = bid or f"{emp}::{fpg}"
    if corr:
        base = f"{base}::{corr}"
    return base


# ------------------------ Paging ------------------------
def fetch_all_slips():
    url, _ = target_url_and_filters()

    def first_key(rows):
        if not rows:
            return None
        return make_key(rows[0])

    all_rows, seen = [], set()
    mode, page, offset = "offset", 1, OFFSET
    prev_first = None

    while True:
        params = body = None
        if GET_WITH_BODY:
            body = build_body(offset, page, mode)
        else:
            params = build_query(offset, page, mode)

        payload = call_api("GET", url, params=params, body_json=body)
        chunk = extract_list(payload)
        n = len(chunk)
        print(f"[{mode}] off/page = {offset if mode=='offset' else page} -> {n} filas")

        # 1) Sin filas => terminamos
        if n == 0:
            break

        # 2) Detectar que el servidor ignora offset: misma primera fila
        fk = first_key(chunk)
        if fk and prev_first and fk == prev_first and mode == "offset":
            print("[WARN] Parece que 'offset' no avanza. Cambio a paginación por 'page'.")
            mode, page = "page", 1
            prev_first = None
            continue

        # 3) Agregar solo nuevas (dedupe real)
        nuevos = []
        for r in chunk:
            k = make_key(r)
            if k not in seen:
                seen.add(k)
                nuevos.append(r)

        # 4) Si no hubo nuevas filas, no hay avance real => terminamos
        if not nuevos:
            print("[INFO] Sin avance (0 filas nuevas). Fin del paginado.")
            break

        all_rows.extend(nuevos)

        # 5) Avanzar cursor
        if mode == "offset":
            offset += n
        else:
            page += 1

        # 6) Corta si la página es menor al límite (última página usualmente)
        if n < LIMIT:
            print("[INFO] Última página detectada (n < LIMIT).")
            break

        # 7) Protección extra: si en 'page' la primera fila se repite, corta
        if mode == "page" and fk and fk == prev_first:
            print("[INFO] Misma primera fila en 'page', probablemente sin avance. Fin.")
            break

        prev_first = fk

        # 8) Salvaguarda por páginas máximas
        if (page if mode == "page" else (offset // max(n, 1))) > MAX_PAGES:
            print(f"[STOP] MAX_PAGES={MAX_PAGES}")
            break

    return all_rows


# ------------------------ Normalización ------------------------
def normalize_slips(rows):
    df = pd.json_normalize(rows, max_level=1)
    if df.empty:
        return df

    # ---- FECHAS: solo columnas que empiezan con 'fecha' (incluye 'fechaPago')
    date_like = []
    for c in df.columns:
        lc = c.lower()
        if lc.startswith("fecha"):
            date_like.append(c)
            try:
                df[c] = pd.to_datetime(df[c], errors="coerce")
            except Exception:
                pass

    # ---- NUMÉRICOS: EXCLUIR las columnas de fecha (evita romper 'fechaPago')
    num_hints = ("sueldo", "bono", "pago", "monto", "seguro", "descuento", "bruto", "neto", "total")
    for c in df.columns:
        if c in date_like:
            continue
        if any(h in c.lower() for h in num_hints):
            try:
                df[c] = pd.to_numeric(df[c], errors="coerce")
            except Exception:
                pass

    # Orden recomendado si existen
    preferred = [c for c in [
        "boletaID", "nomEmpleado", "areaID", "nomArea", "centroCosto",
        "tipoContrato", "sede", "fechaPago", "sueldoBasico", "sueldoBruto",
        "totalDSCctos", "sueldoNeto", "totalSeguros", "estadoBoleta",
        "producto", "productID", "nomEmpresa", "pagoHE"
    ] if c in df.columns]
    other = [c for c in df.columns if c not in preferred]
    df = df[preferred + other] if preferred else df
    return df


def format_for_excel(df: pd.DataFrame) -> pd.DataFrame:
    """
    - Convierte fechas a texto 'YYYY-MM-DD' (evita epoch ns en Excel).
    - Convierte numéricos a texto con 2 decimales y blancos como "" (evita -9.22337E+18).
    - No trata 'pagoHE' como fecha (solo como numérico).
    """
    if df.empty:
        return df.copy()

    out = df.copy()

    # --- FECHAS: solo columnas que empiezan con 'fecha' (ej. 'fechaPago')
    date_like = [c for c in out.columns if c.lower().startswith("fecha")]
    for c in date_like:
        try:
            ser_dt = pd.to_datetime(out[c], errors="coerce")
            out[c] = ser_dt.dt.strftime("%Y-%m-%d")
        except Exception:
            pass

    # --- NÚMEROS: 2 decimales como texto (incluye pagoHE)
    numeric_cols_known = [
        "sueldoBasico", "sueldoBruto", "sueldoNeto", "totalSeguros",
        "totalDSCctos", "bonos", "pagoHE", "beneficiosLey"
    ]
    for c in out.columns:
        if c in date_like:
            continue
        if c in numeric_cols_known or any(k in c.lower() for k in ["monto","sueldo","bono","seguro","neto","bruto","pago","total"]):
            try:
                ser = pd.to_numeric(out[c], errors="coerce")
                out[c] = ser.round(2).map(lambda x: ("" if pd.isna(x) else f"{x:.2f}"))
                # Si prefieres coma decimal:
                # out[c] = out[c].str.replace(".", ",", regex=False)
            except Exception:
                pass

    return out

# ------------------------ Main ------------------------
def main():
    outdir = Path(OUTDIR)
    outdir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")

    # 1) Extraer todo (paginado)
    rows = fetch_all_slips()
    print(f"[OK] Total filas recibidas: {len(rows)}")

    # 2) Guardar RAW
    raw_json   = outdir / f"slips_raw_{ts}.json"
    raw_jsonl  = outdir / f"slips_raw_{ts}.jsonl"
    with open(raw_json, "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=2)
    with open(raw_jsonl, "w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    # 3) Normalizar y CSV
    df = normalize_slips(rows)
    df_xls = format_for_excel(df)  # <<< Formateo para Excel
    csv_path = outdir / "slips.csv"
    df_xls.to_csv(csv_path, index=False, encoding="utf-8", sep=CSV_SEPARATOR)

    # 4) Logs
    print("RAW JSON :", raw_json)
    print("RAW JSONL:", raw_jsonl)
    print("CSV      :", csv_path)
    print("[FIN] Lista la exportación.")


if __name__ == "__main__":
    # Requisitos:
    #   pip install requests pandas numpy
    main()
