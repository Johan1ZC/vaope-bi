# -*- coding: utf-8 -*-
"""
one_shot_facturas_clientes.py
- Llama al endpoint de "facturas de clientes" con TOKEN en header y URL fija (una sola consulta).
- Guarda RAW JSON.
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
TOKEN = "pR4GfvD1keR1oafsk06vUdavoagX5ODelYOfIp6HPa6wX_k="                           # <-- PON TU TOKEN
# Si tu API usa 'Authorization: Bearer ...', cambia el header más abajo

# Parámetros opcionales (ajusta si tu API los soporta)
PARAMS = {
    "date_from": "2024-01-01",
    "date_to":   "2025-12-31",
    "limit": 1000,
    "offset": 0,
}

# Si tu API necesita POST con body JSON, define BODY y cambia method a 'POST'
METHOD = "GET"
BODY_JSON = None
# ======================================


def call_api(url: str, method: str, token: str, params: dict, body_json):
    # Si tu API usa Authorization Bearer:
    # headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    headers = {"token": token, "Content-Type": "application/json"}
    resp = requests.request(method, url, headers=headers, params=params, json=body_json, timeout=60)
    resp.raise_for_status()
    return resp.json()


def normalize_facturas_items(payload):
    """
    Estructura típica observada:
    { "result": { "success": true, "data": [ { ... , "items": [ {...}, ... ] }, ... ] } }
    Soporta también lista en raíz o dict con 'data'.
    """
    # Caso 1: result.data como lista
    data = None
    if isinstance(payload, dict):
        data = payload.get("result", {}).get("data")
        if not isinstance(data, list):
            data = payload.get("data")

    if isinstance(data, list):
        facturas = data
    elif isinstance(payload, list):
        facturas = payload
    else:
        # último recurso: un solo registro
        facturas = [payload]

    # Cabecera (aplana 1 nivel)
    df_fact = pd.json_normalize(facturas, max_level=1)

    # Items (si existen)
    items_frames = []
    for f in facturas:
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
    # 1) Llamar API (una sola consulta)
    payload = call_api(URL, METHOD, TOKEN, PARAMS, BODY_JSON)

    # 2) Guardar RAW
    outdir = Path("C:/Users/SOPORTE/Desktop/vaope-bi/4_Validaciones/Informe Ventas y Egresos/Api contabilidad/salida_facturas")
    outdir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    raw_path = outdir / f"facturas_clientes_raw_{ts}.json"
    with open(raw_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    # 3) Normalizar
    df_fact, df_items = normalize_facturas_items(payload)
    df_fact = coerce_types(df_fact)
    df_items = coerce_types(df_items)

    # 4) Exportar CSV (separador ';' para Excel)
    fact_csv = outdir / "facturas.csv"
    items_csv = outdir / "items.csv"
    df_fact.to_csv(fact_csv, index=False, encoding="utf-8", sep=";")
    df_items.to_csv(items_csv, index=False, encoding="utf-8", sep=";")

    print("RAW guardado en:", raw_path)
    print("Facturas CSV:", fact_csv)
    print("Items CSV:", items_csv)
    print("Listo.")

if __name__ == "__main__":
    main()
