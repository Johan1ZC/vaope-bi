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
DATE_FROM = "2025-01-01"
DATE_TO   = "2025-12-31"
LIMIT     = 5               # tamaño de página (ajústalo si el API lo permite)
OFFSET    = 0
COMPANY_ID = 1 #AGREGAR
STATE     = "posted"

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


# Config extra arriba (ajústalo):
ID_FIELD   = "numero"          # o "id" o "serie_correlativo"
MAX_PAGES  = 30            # tope de seguridad
#LIMIT      = 30             # si el backend capa a 200, usa 200

def fetch_all_pages():
    """
    1) Intenta paginar con offset/limit.
    2) Si detecta página repetida (API ignora offset), cambia a page/page_size.
    3) Loguea progreso y corta con MAX_PAGES o sin avance.
    """
    def first_key(rows):
        if not rows: return None
        return rows[0].get(ID_FIELD)

    all_rows = []
    seen_keys = set()     # para detectar repetidos
    mode = "offset"       # offset -> page (fallback)
    page = 1
    offset = OFFSET

    while True:
        if mode == "offset":
            params = {
                "date_from": DATE_FROM,
                "date_to":   DATE_TO,
                "limit":     LIMIT,
                "offset":    offset,
                "company_id": COMPANY_ID,
                "state": STATE,
            }
        else:  # mode == "page"
            params = {
                "date_from": DATE_FROM,
                "date_to":   DATE_TO,
                "limit":     LIMIT,       # algunos APIs usan page_size; probamos ambos
                "page_size": LIMIT,
                "page":      page,
                "company_id": COMPANY_ID,
                "state": STATE,
            }

        payload = call_api(URL, METHOD, TOKEN, params, BODY_JSON)
        chunk = extract_list(payload)
        n = len(chunk)
        print(f"[{mode}] page/off={page if mode=='page' else offset} -> recibidos {n}")

        if n == 0:
            break

        # Detectar repetición (API ignora el cursor): si el primer ID de la página ya estaba, no hay avance
        fk = first_key(chunk)
        if fk is not None and fk in seen_keys and mode == "offset":
            print("[WARN] La API parece ignorar 'offset'. Cambiando a paginación por 'page'...")
            mode = "page"
            # reinicio de ciclo para la primera page
            page = 1
            continue

        # Agregar solo nuevos (evita duplicados si el backend repite filas)
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

        # avanzar cursor
        if mode == "offset":
            offset += n   # avanzar por lo realmente recibido
        else:
            page += 1

        if (page if mode == "page" else (offset // max(n,1))) > MAX_PAGES:
            print(f"[STOP] Se alcanzó MAX_PAGES={MAX_PAGES}.")
            break

        # Si el backend respeta el cursor, la última página será < LIMIT.
        # PERO como vimos que algunos capean a 200 y no respetan offset, NO cortamos por n < LIMIT.

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

        # 4.1) Facturas + desglose completo de columnas de items (una fila por ítem)
    # Claves de cruce: facturas.numero <-> items.factura.numero y
    #                  facturas.serie_correlativo <-> items.factura.serie_correlativo

    if not df_items.empty:
        items_for_merge = df_items.copy()

        # Prefija las columnas propias del ítem para distinguirlas de las de factura
        # (dejamos las claves factura.* para el merge y luego las quitamos)
        item_cols = [c for c in items_for_merge.columns if not c.startswith("factura.")]
        items_for_merge = items_for_merge.rename(columns={c: f"item.{c}" for c in item_cols})

        # Merge LEFT: conserva todas las facturas y expande a 1 fila por ítem
        df_fact_items_full = df_fact.merge(
            items_for_merge,
            how="left",
            left_on=["numero", "serie_correlativo"],
            right_on=["factura.numero", "factura.serie_correlativo"]
        )

        # Limpia las claves duplicadas del lado derecha (ya están en las columnas de factura)
        df_fact_items_full.drop(columns=["factura.numero", "factura.serie_correlativo"], inplace=True, errors="ignore")

        # (Opcional) Ordena: primero columnas de factura, luego las de item.*
        fact_cols = [c for c in df_fact.columns]
        item_cols_out = [c for c in df_fact_items_full.columns if c.startswith("item.")]
        other_cols = [c for c in df_fact_items_full.columns if c not in fact_cols + item_cols_out]
        df_fact_items_full = df_fact_items_full[fact_cols + other_cols + item_cols_out]
    else:
        # Si no hay items, crea archivo con solo columnas de factura
        df_fact_items_full = df_fact.copy()

    # Exporta el combinado
    fact_items_full_csv = outdir / "facturas_con_items.csv"
    df_fact_items_full.to_csv(fact_items_full_csv, index=False, encoding="utf-8", sep=";")



    # 5) Conteos y comparativo
    total_odoo = len(df_fact)
    total_items = len(df_items)
    print(f"Total facturas Odoo: {total_odoo}")
    print(f"Total ítems detalle: {total_items}")
    print("RAW JSON:", raw_json_path)
    print("RAW JSONL:", raw_jsonl_path)
    print("Facturas CSV:", fact_csv)
    print("Items CSV:", items_csv)
    print("Facturas+Items (expandido) CSV:", fact_items_full_csv)

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
        #print("Facturas+Items (expandido) CSV:", fact_items_full_csv)


    print("Listo.")

if __name__ == "__main__":
    main()
