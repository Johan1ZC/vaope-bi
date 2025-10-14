# -*- coding: utf-8 -*-

import json
from datetime import datetime
from pathlib import Path
import requests
import pandas as pd

# ==============================================================
URL = "https://odoo-stage.colaborativa.pe/api/vendor_bills"
TOKEN = "pR4GfvD1keR1oafsk06vUdavoagX5ODelYOfIp6HPa6wX_k="

DATE_FROM  = "2025-01-01"
DATE_TO    = "2025-12-31"
LIMIT      = 200          
OFFSET     = 0
COMPANY_ID = 1
STATE_LIST = ["posted"]    

METHOD = "GET"             
# ======================================

def prepare_request(url, method, headers, params=None, body_json=None):
    req = requests.Request(method, url, headers=headers, params=params, json=body_json)
    prepped = req.prepare()
    # logs útiles para verificar lo que se envía
    print("[HTTP] URL:", prepped.url)
    if body_json is not None:
        print("[HTTP] BODY:", json.dumps(body_json, ensure_ascii=False)[:800])
    return prepped

def call_api(url: str, method: str, token: str, params: dict, body_json):
    headers = {"token": token, "Content-Type": "application/json"}
    prepped = prepare_request(url, method, headers, params=params, body_json=body_json)
    with requests.Session() as s:
        resp = s.send(prepped, timeout=120)
    resp.raise_for_status()
    return resp.json()

def extract_list(payload):
    if isinstance(payload, dict):
        data = payload.get("result", {}).get("data")
        if isinstance(data, list):
            return data
        data = payload.get("data")
        if isinstance(data, list):
            return data
        return [payload]
    elif isinstance(payload, list):
        return payload
    else:
        return []

# Dedupe por un identificador estable de la factura
ID_FIELD  = "numero"
MAX_PAGES = 30

def build_body(offset: int = 0):
    """Body JSON exactamente como en Postman."""
    return {
        "date_from": DATE_FROM,
        "date_to": DATE_TO,
        "company_id": COMPANY_ID,
        "state": STATE_LIST,     # lista
        "limit": LIMIT,
        "offset": offset
    }

def build_body_page(page: int = 1):
    """Variante por page/page_size si el backend ignora offset (fallback)."""
    return {
        "date_from": DATE_FROM,
        "date_to": DATE_TO,
        "company_id": COMPANY_ID,
        "state": STATE_LIST,
        "limit": LIMIT,
        "page_size": LIMIT,
        "page": page
    }

def fetch_all_pages():
    def first_key(rows):
        if not rows: return None
        return rows[0].get(ID_FIELD)

    all_rows, seen_keys = [], set()
    mode, page, offset = "offset", 1, OFFSET

    while True:
        if mode == "offset":
            params, body = None, build_body(offset=offset)
        else:
            params, body = None, build_body_page(page=page)

        payload = call_api(URL, METHOD, TOKEN, params, body)
        chunk = extract_list(payload)
        n = len(chunk)
        print(f"[{mode}] page/off={page if mode=='page' else offset} -> recibidos {n}")

        if n == 0:
            break

        fk = first_key(chunk)
        if fk is not None and fk in seen_keys and mode == "offset":
            print("[WARN] La API ignora 'offset'. Cambiando a paginación por 'page'…")
            mode, page = "page", 1
            continue

        nuevos = []
        for r in chunk:
            kid = r.get(ID_FIELD)
            if kid is None or kid not in seen_keys:
                if kid is not None:
                    seen_keys.add(kid)
                nuevos.append(r)

        if not nuevos:
            print("[INFO] Página sin avance (todo repetido). Deteniendo.")
            break

        all_rows.extend(nuevos)
        if mode == "offset":
            offset += n
        else:
            page += 1

        if (page if mode == "page" else (offset // max(n, 1))) > MAX_PAGES:
            print(f"[STOP] MAX_PAGES={MAX_PAGES}.")
            break

    return all_rows

def normalize_facturas_items(facturas_list):
    df_fact = pd.json_normalize(facturas_list, max_level=1)
    items_frames = []
    for f in facturas_list:
        its = f.get("items", [])
        if isinstance(its, list) and its:
            meta = {
                "factura.serie_correlativo": f.get("serie_correlativo"),
                "factura.numero": f.get("numero"),
                "factura.fecha_emision": f.get("fecha_emision") or f.get("fecha_de_emision"),
                "factura.cliente": f.get("cliente"),
                "factura.id_cliente": f.get("id_cliente"),
                "factura.total": f.get("total"),
                "factura.moneda": f.get("moneda"),
                "factura.estado": f.get("status") or f.get("estado") or f.get("id_estado") or f.get("nomb_estado"),
            }
            tmp = pd.json_normalize(its)
            for k, v in meta.items():
                tmp[k] = v
            items_frames.append(tmp)
    df_items = pd.concat(items_frames, ignore_index=True) if items_frames else pd.DataFrame()
    return df_fact, df_items

def coerce_types(df: pd.DataFrame) -> pd.DataFrame:
    res = df.copy()
    date_hints = ("fecha", "emision", "vencimiento", "date")
    for c in res.columns:
        if any(h in c.lower() for h in date_hints):
            try:
                res[c] = pd.to_datetime(res[c], errors="coerce", dayfirst=True)
            except Exception:
                pass
    num_hints = ("total", "subtotal", "igv", "iva", "impuesto", "descuento",
                 "delivery", "valor", "precio", "monto", "cantidad", "unitario")
    for c in res.columns:
        if any(h in c.lower() for h in num_hints):
            try:
                res[c] = pd.to_numeric(res[c], errors="coerce")
            except Exception:
                pass
    return res

def main():
    outdir = Path(r"C:/Users/SOPORTE/Desktop/vaope-bi/4_Validaciones/Informe Ventas y Egresos/Api contabilidad/salida_facturas_proveedores")
    outdir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")

    facturas_list = fetch_all_pages()

    raw_json_path  = outdir / f"facturas_clientes_raw_{ts}.json"
    raw_jsonl_path = outdir / f"facturas_clientes_raw_{ts}.jsonl"
    with open(raw_json_path, "w", encoding="utf-8") as f:
        json.dump(facturas_list, f, ensure_ascii=False, indent=2)
    with open(raw_jsonl_path, "w", encoding="utf-8") as f:
        for row in facturas_list:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    df_fact, df_items = normalize_facturas_items(facturas_list)
    df_fact = coerce_types(df_fact)
    df_items = coerce_types(df_items)

    fact_csv = outdir / "facturas.csv"
    items_csv = outdir / "items.csv"
    df_fact.to_csv(fact_csv, index=False, encoding="utf-8", sep=";")
    df_items.to_csv(items_csv, index=False, encoding="utf-8", sep=";")

    # Facturas + columnas de item (1 fila por ítem)
    if not df_items.empty:
        items_for_merge = df_items.copy()
        item_cols = [c for c in items_for_merge.columns if not c.startswith("factura.")]
        items_for_merge = items_for_merge.rename(columns={c: f"item.{c}" for c in item_cols})
        df_fact_items_full = df_fact.merge(
            items_for_merge,
            how="left",
            left_on=["numero", "serie_correlativo"],
            right_on=["factura.numero", "factura.serie_correlativo"]
        )
        df_fact_items_full.drop(columns=["factura.numero", "factura.serie_correlativo"], inplace=True, errors="ignore")
        fact_cols = list(df_fact.columns)
        item_cols_out = [c for c in df_fact_items_full.columns if c.startswith("item.")]
        other_cols = [c for c in df_fact_items_full.columns if c not in fact_cols + item_cols_out]
        df_fact_items_full = df_fact_items_full[fact_cols + other_cols + item_cols_out]
    else:
        df_fact_items_full = df_fact.copy()

    fact_items_full_csv = outdir / "facturas_con_items.csv"
    df_fact_items_full.to_csv(fact_items_full_csv, index=False, encoding="utf-8", sep=";")

    print(f"Total facturas Odoo: {len(df_fact)}")
    print(f"Total ítems detalle: {len(df_items)}")
    print("RAW JSON:", raw_json_path)
    print("RAW JSONL:", raw_jsonl_path)
    print("Facturas CSV:", fact_csv)
    print("Items CSV:", items_csv)
    print("Facturas+Items (expandido) CSV:", fact_items_full_csv)
    print("Listo.")

if __name__ == "__main__":
    main()
