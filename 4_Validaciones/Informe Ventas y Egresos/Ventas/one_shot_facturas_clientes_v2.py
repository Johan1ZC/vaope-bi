# -*- coding: utf-8 -*-
"""
one_shot_facturas_clientes_all.py
- Pagina el endpoint de "facturas de clientes" hasta traer TODAS las filas.
- Guarda RAW en JSONL y JSON.
- Normaliza en dos tablas: facturas.csv (cabecera) e items.csv (detalle).
- CSV con separador ';' (ideal Excel español).

Requisitos:
  pip install requests pandas
"""

import json
from datetime import datetime
from pathlib import Path
import requests
import pandas as pd

# =========== CONFIGURA AQUÍ ===========
URL = "https://odoo-stage.colaborativa.pe/api/customer_invoices"    # <-- PON TU URL
TOKEN = "pR4GfvD1keR1oafsk06vUdavoagX5ODelYOfIp6HPa6wX_k="          # <-- PON TU TOKEN

# Filtros base y paginación
DATE_FROM = "2024-01-01"
DATE_TO   = "2025-12-31"
LIMIT     = 1000                   # tamaño de página (ajústalo si el API lo permite)
START_OFFSET = 0

# Si tu API necesita POST con body JSON, define BODY_JSON y cambia METHOD a 'POST'
METHOD = "GET"
BODY_JSON = None

# Comparación con proveedor (OPCIONAL):
PROVEEDOR_TOTAL = None             # ej. 12345  -> imprime comparativo
PROVEEDOR_CSV   = None             # ej. r"C:\...\proveedor.csv" -> hace len() de filas
# ======================================


def call_api(url: str, method: str, token: str, params: dict, body_json):
    # Si tu API usa Authorization Bearer:
    # headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    headers = {"token": token, "Content-Type": "application/json"}
    resp = requests.request(method, url, headers=headers, params=params, json=body_json, timeout=120)
    resp.raise_for_status()
    return resp.json()


def extract_list(payload):
    """
    Devuelve la lista de facturas desde varias formas posibles de respuesta.
    Estructuras soportadas:
      - {"result":{"success":true,"data":[...]}}
      - {"data":[...]}
      - [...]
      - {...}  (un solo registro)
    """
    if isinstance(payload, dict):
        data = payload.get("result", {}).get("data")
        if isinstance(data, list):
            return data
        data = payload.get("data")
        if isinstance(data, list):
            return data
        # último recurso: un solo objeto
        return [payload]
    elif isinstance(payload, list):
        return payload
    else:
        return []


def fetch_all_pages():
    """
    Pagina con limit/offset hasta agotar resultados.
    Si tu API devolviera 'next_offset', 'has_more' o 'next', puedes adaptar aquí.
    """
    all_rows = []
    offset = START_OFFSET

    base_params = {
        "date_from": DATE_FROM,
        "date_to":   DATE_TO,
        "limit":     LIMIT,
        "offset":    offset,
    }

    while True:
        params = dict(base_params)
        params["offset"] = offset

        payload = call_api(URL, METHOD, TOKEN, params, BODY_JSON)
        chunk = extract_list(payload)
        if not chunk:
            break

        all_rows.extend(chunk)

        # Criterio de corte: llegó última página si devolvió menos que LIMIT
        if len(chunk) < LIMIT:
            break

        offset += LIMIT

    return all_rows


def normalize_facturas_items(facturas_list):
    # Cabecera (aplana 1 nivel)
    df_fact = pd.json_normalize(facturas_list, max_level=1)

    # Items (si existen)
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
    # Fechas
    date_hints = ("fecha", "emision", "vencimiento", "date")
    for c in res.columns:
        lc = c.lower()
        if any(h in lc for h in date_hints):
            try:
                res[c] = pd.to_datetime(res[c], errors="coerce")
            except Exception:
                pass
    # Números
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
    # 0) Carpeta de salida
    outdir = Path(r"C:/Users/SOPORTE/Desktop/vaope-bi/4_Validaciones/Informe Ventas y Egresos/Api contabilidad/salida_facturas")
    outdir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")

    # 1) Traer TODAS las páginas
    facturas_list = fetch_all_pages()

    # 2) Guardar RAW (JSON y JSONL)
    raw_json_path  = outdir / f"facturas_clientes_raw_{ts}.json"
    raw_jsonl_path = outdir / f"facturas_clientes_raw_{ts}.jsonl"

    with open(raw_json_path, "w", encoding="utf-8") as f:
        json.dump(facturas_list, f, ensure_ascii=False, indent=2)

    with open(raw_jsonl_path, "w", encoding="utf-8") as f:
        for row in facturas_list:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    # 3) Normalizar
    df_fact, df_items = normalize_facturas_items(facturas_list)
    df_fact = coerce_types(df_fact)
    df_items = coerce_types(df_items)

    # 4) Exportar CSV (separador ';' para Excel)
    fact_csv = outdir / "facturas.csv"
    items_csv = outdir / "items.csv"
    df_fact.to_csv(fact_csv, index=False, encoding="utf-8", sep=";")
    df_items.to_csv(items_csv, index=False, encoding="utf-8", sep=";")

    # 5) Conteos y comparativo
    total_odoo = len(df_fact)
    total_items = len(df_items)
    print(f"Total facturas Odoo: {total_odoo}")
    print(f"Total ítems detalle: {total_items}")
    print("RAW JSON:", raw_json_path)
    print("RAW JSONL:", raw_jsonl_path)
    print("Facturas CSV:", fact_csv)
    print("Items CSV:", items_csv)

    proveedor_total = None
    if PROVEEDOR_TOTAL is not None:
        proveedor_total = PROVEEDOR_TOTAL
    elif PROVEEDOR_CSV:
        try:
            df_prov = pd.read_csv(PROVEEDOR_CSV)
            proveedor_total = len(df_prov)
        except Exception as e:
            print(f"[WARN] No se pudo leer PROVEEDOR_CSV: {e}")

    if proveedor_total is not None:
        delta = total_odoo - proveedor_total
        print(f"Total proveedor: {proveedor_total}")
        print(f"Diferencia (Odoo - Proveedor): {delta}")

    print("Listo.")


if __name__ == "__main__":
    main()
