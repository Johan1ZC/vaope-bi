# -*- coding: utf-8 -*-
"""
Vaope – Ingesta y validación en MySQL 8
Requisitos:
  pip install requests pymysql

Soporta 2 orígenes:
  - API: customer_invoices (GET), vendor_bills (POST paginado)
  - Archivo plano JSON (tu export): CUSTOMER_FILE

Guarda TODO:
  - JSON íntegro en staging
  - KV de todos los campos (cabecera + item)
  - Ítems normalizados
  - Tablas CORE para validar

Validaciones:
  - Totales que no cuadran (doc vs suma de ítems)
  - IGV 18% (líneas afectas tipo_igv='1' aprox.) 
"""

import os, json, time, traceback
import requests
import pymysql

# ------------------ CONFIG ------------------

DB_NAME = "dwh_vaope"

MYSQL = {
    "host": "127.0.0.1",
    "user": "root",
    "password": "1234",  # <-- CAMBIA
    "port": 3306,
    "charset": "utf8mb4",
    "cursorclass": pymysql.cursors.DictCursor,
    "autocommit": False,
}

# API (si quieres usarla)
TOKEN_CUSTOMER = "pR4GfvD1keR1oafsk06vUdavoagX5ODelYOfIp6HPa6wX_k="
TOKEN_VENDOR   = "pR4GfvD1keR1oafsk06vUdavoagX5ODelYOfIp6HPa6wX_k="
URL_CUSTOMER   = "https://odoo-stage.colaborativa.pe/api/customer_invoices"
URL_VENDOR     = "https://odoo-stage.colaborativa.pe/api/vendor_bills"

DATE_FROM = "2020-01-01"
DATE_TO   = "2030-12-31"
COMPANY_ID = 1
STATE_LIST = ["posted"]
PAGE_SIZE  = 200

# Archivo local (tu adjunto). Si está seteado, se usa para customer_invoices.
CUSTOMER_FILE = r""  # <-- pon la ruta o deja "" para usar API

SAVE_FIRST_PAYLOAD_TO = "payload_sample_customer.json"
SAVE_FIRST_VENDOR_PAYLOAD_TO = "payload_sample_vendor.json"


# ------------------ DB helpers ------------------

def connect_mysql_server():
    return pymysql.connect(**MYSQL)

def connect_mysql_db():
    cfg = MYSQL.copy()
    cfg["database"] = DB_NAME
    return pymysql.connect(**cfg)

def ensure_database():
    conn = connect_mysql_server()
    try:
        with conn.cursor() as c:
            c.execute(f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}` "
                      f"CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;")
        conn.commit()
    finally:
        conn.close()

DDL = """
USE {db};

CREATE TABLE IF NOT EXISTS stg_odoo_invoice (
  stg_id           BIGINT NOT NULL AUTO_INCREMENT,
  source_endpoint  VARCHAR(80) NOT NULL,
  received_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  token_used       VARCHAR(200) NULL,
  raw_json         JSON NOT NULL,

  -- claves y campos útiles de búsqueda
  codigo_unico     VARCHAR(180) NULL,
  serie            VARCHAR(60) NULL,
  numero           VARCHAR(60) NULL,
  tipo_comprobante VARCHAR(60) NULL,

  proveedor_doc    VARCHAR(40) NULL,
  proveedor_nombre VARCHAR(400) NULL,

  fecha_emision    DATE NULL,
  moneda           VARCHAR(20) NULL,

  total_gravada    DECIMAL(18,2) NULL,
  total_igv        DECIMAL(18,2) NULL,
  total            DECIMAL(18,2) NULL,

  PRIMARY KEY (stg_id),
  KEY idx_src_rec (source_endpoint, received_at),
  KEY idx_cod_unq (codigo_unico),
  KEY idx_ser_num (serie, numero)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stg_odoo_invoice_kv (
  stg_kv_id BIGINT NOT NULL AUTO_INCREMENT,
  stg_id    BIGINT NOT NULL,
  k         VARCHAR(255) NOT NULL,
  v_text    LONGTEXT NULL,
  v_num     DECIMAL(30,10) NULL,
  v_bool    TINYINT(1) NULL,
  v_json    JSON NULL,
  PRIMARY KEY (stg_kv_id),
  KEY idx_stgk (stg_id, k),
  CONSTRAINT fk_stgkv_hdr FOREIGN KEY (stg_id) REFERENCES stg_odoo_invoice(stg_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stg_odoo_invoice_item (
  stg_item_id     BIGINT NOT NULL AUTO_INCREMENT,
  stg_id          BIGINT NOT NULL,
  linea_nro       INT NULL,
  unidad_medida   VARCHAR(60) NULL,
  codigo          VARCHAR(120) NULL,
  descripcion     VARCHAR(2000) NULL,
  cantidad        DECIMAL(18,6) NULL,
  valor_unitario  DECIMAL(18,6) NULL,
  precio_unitario DECIMAL(18,6) NULL,
  descuento       DECIMAL(18,6) NULL,
  subtotal        DECIMAL(18,6) NULL,
  tipo_igv        VARCHAR(40) NULL,
  igv             DECIMAL(18,6) NULL,
  total_linea     DECIMAL(18,6) NULL,
  estado_id       VARCHAR(40) NULL,
  estado_nombre   VARCHAR(120) NULL,
  raw_item_json   JSON NULL,
  PRIMARY KEY (stg_item_id),
  KEY idx_stg (stg_id),
  CONSTRAINT fk_stg_item_hdr FOREIGN KEY (stg_id) REFERENCES stg_odoo_invoice(stg_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stg_odoo_invoice_item_kv (
  stg_item_kv_id BIGINT NOT NULL AUTO_INCREMENT,
  stg_item_id    BIGINT NOT NULL,
  k              VARCHAR(255) NOT NULL,
  v_text         LONGTEXT NULL,
  v_num          DECIMAL(30,10) NULL,
  v_bool         TINYINT(1) NULL,
  v_json         JSON NULL,
  PRIMARY KEY (stg_item_kv_id),
  KEY idx_itemk (stg_item_id, k),
  CONSTRAINT fk_itemkv_item FOREIGN KEY (stg_item_id) REFERENCES stg_odoo_invoice_item(stg_item_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- CORE
CREATE TABLE IF NOT EXISTS inv_header (
  doc_key          VARCHAR(200) NOT NULL,
  source_endpoint  VARCHAR(80) NOT NULL,
  serie            VARCHAR(60) NULL,
  numero           VARCHAR(60) NULL,
  tipo_comprobante VARCHAR(60) NULL,
  proveedor_doc    VARCHAR(40) NULL,
  proveedor_nombre VARCHAR(400) NULL,
  fecha_emision    DATE NULL,
  moneda           VARCHAR(20) NULL,
  total_gravada    DECIMAL(18,2) NOT NULL DEFAULT 0,
  total_igv        DECIMAL(18,2) NOT NULL DEFAULT 0,
  total            DECIMAL(18,2) NOT NULL DEFAULT 0,
  last_received_at DATETIME NOT NULL,
  PRIMARY KEY (doc_key)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inv_item (
  doc_key         VARCHAR(200) NOT NULL,
  linea_nro       INT NOT NULL,
  unidad_medida   VARCHAR(60) NULL,
  codigo          VARCHAR(120) NULL,
  descripcion     VARCHAR(2000) NULL,
  cantidad        DECIMAL(18,6) NOT NULL DEFAULT 0,
  valor_unitario  DECIMAL(18,6) NOT NULL DEFAULT 0,
  precio_unitario DECIMAL(18,6) NOT NULL DEFAULT 0,
  descuento       DECIMAL(18,6) NOT NULL DEFAULT 0,
  subtotal        DECIMAL(18,6) NOT NULL DEFAULT 0,
  tipo_igv        VARCHAR(40) NULL,
  igv             DECIMAL(18,6) NOT NULL DEFAULT 0,
  total_linea     DECIMAL(18,6) NOT NULL DEFAULT 0,
  estado_id       VARCHAR(40) NULL,
  estado_nombre   VARCHAR(120) NULL,
  PRIMARY KEY (doc_key, linea_nro),
  CONSTRAINT fk_invitem_hdr FOREIGN KEY (doc_key) REFERENCES inv_header(doc_key) ON DELETE CASCADE
) ENGINE=InnoDB;
"""

def run_ddl(conn):
    with conn.cursor() as c:
        for stmt in [s.strip() for s in DDL.format(db=DB_NAME).split(";") if s.strip()]:
            c.execute(stmt + ";")
    conn.commit()


# ------------------ Fetchers ------------------

def extract_list(payload):
    """
    Devuelve SIEMPRE una lista de facturas:
    - list plano
    - dict con result.data / result.records / result.items
    - dict con data / results / records / items
    - NDJSON o texto JSON
    """
    def from_any_dict(d):
        if not isinstance(d, dict):
            return None
        # nivel 1
        for k in ("results", "data", "records", "items"):
            if isinstance(d.get(k), list):
                return d[k]
        # nivel 2: result.{data|results|records|items}
        res = d.get("result") or d.get("Result") or d.get("payload")
        if isinstance(res, dict):
            for k in ("results", "data", "records", "items"):
                if isinstance(res.get(k), list):
                    return res[k]
        # si parece una factura única
        return [d]

    # list plano
    if isinstance(payload, list):
        return payload
    # dict (con/ sin 'result')
    if isinstance(payload, dict):
        out = from_any_dict(payload)
        if out is not None:
            return out
    # texto
    if isinstance(payload, str):
        payload = payload.strip()
        try:
            j = json.loads(payload)
            return extract_list(j)
        except:
            # NDJSON
            rows = []
            for line in payload.splitlines():
                line = line.strip()
                if not line:
                    continue
                try:
                    rows.append(json.loads(line))
                except:
                    pass
            if rows:
                return rows
    return []


def fetch_customer_invoices_api():
    headers = {"token": TOKEN_CUSTOMER}
    r = requests.get(URL_CUSTOMER, headers=headers, timeout=60)
    r.raise_for_status()
    try: data = r.json()
    except ValueError: data = r.text
    lst = extract_list(data)
    if lst and SAVE_FIRST_PAYLOAD_TO and not os.path.exists(SAVE_FIRST_PAYLOAD_TO):
        with open(SAVE_FIRST_PAYLOAD_TO, "w", encoding="utf-8") as f:
            json.dump(lst[:3], f, ensure_ascii=False, indent=2)
    print(f"[customer_invoices API] {len(lst)}")
    return lst

def fetch_customer_invoices_file(path):
    with open(path, "r", encoding="utf-8") as f:
        txt = f.read()
    lst = extract_list(txt)
    print(f"[customer_invoices FILE] {len(lst)}")
    return lst

def fetch_vendor_bills_api(date_from, date_to, company_id=1, state_list=None, limit=200):
    headers = {"token": TOKEN_VENDOR}
    params = {
        "date_from": date_from,
        "date_to": date_to,
        "company_id": company_id,
        "limit": limit,
        "offset": 0
    }
    if state_list:
        # si el server acepta múltiples valores, usa coma-separado; si no, repite el parámetro
        params["state"] = ",".join(state_list)

    results = []
    while True:
        r = requests.get(URL_VENDOR, headers=headers, params=params, timeout=60)
        r.raise_for_status()
        try:
            data = r.json()
        except ValueError:
            data = r.text
        page = extract_list(data)
        if page and SAVE_FIRST_VENDOR_PAYLOAD_TO and not os.path.exists(SAVE_FIRST_VENDOR_PAYLOAD_TO):
            with open(SAVE_FIRST_VENDOR_PAYLOAD_TO, "w", encoding="utf-8") as f:
                json.dump(page[:3], f, ensure_ascii=False, indent=2)
        print(f"[vendor_bills offset={params['offset']}] page={len(page)}")
        results.extend(page)
        if len(page) < limit:
            break
        params["offset"] += limit
        time.sleep(0.2)
    print(f"[vendor_bills API total] {len(results)}")
    return results



# ------------------ Parse helpers ------------------

def as_float(x):
    if x is None: return None
    try:
        if isinstance(x,str):
            x=x.replace(",",".").strip()
        return float(x)
    except: return None

def as_int_str(x):
    if x is None: return None
    try:
        return str(int(x))
    except:
        return str(x)

def parse_fecha_ddmmyyyy(fe):
    if not fe: return None
    if isinstance(fe,str) and "-" in fe:
        p=fe.split("-")
        if len(p)==3 and len(p[0])<=2:
            d,m,y = p
            return f"{y}-{m.zfill(2)}-{d.zfill(2)}"
    return None

def parse_serie_from_correlativo(s):
    # ejemplos: "(01) Factura FB01" -> "FB01"; "(01) Factura " -> ""
    if not s: return None
    try:
        parts = s.strip().split()
        return parts[-1] if len(parts)>=3 else s.strip()
    except:
        return s


# ------------------ Inserts STAGING ------------------

def insert_kv_header(conn, stg_id, factura):
    with conn.cursor() as c:
        for k,v in factura.items():
            if k=="items": continue
            if isinstance(v,(dict,list)):
                c.execute("""INSERT INTO stg_odoo_invoice_kv (stg_id,k,v_json)
                             VALUES (%s,%s,CAST(%s AS JSON))""",
                          (stg_id,k,json.dumps(v,ensure_ascii=False)))
            elif isinstance(v,(int,float)):
                c.execute("""INSERT INTO stg_odoo_invoice_kv (stg_id,k,v_num)
                             VALUES (%s,%s,%s)""",(stg_id,k,v))
            elif isinstance(v,bool):
                c.execute("""INSERT INTO stg_odoo_invoice_kv (stg_id,k,v_bool)
                             VALUES (%s,%s,%s)""",(stg_id,k,int(v)))
            else:
                c.execute("""INSERT INTO stg_odoo_invoice_kv (stg_id,k,v_text)
                             VALUES (%s,%s,%s)""",(stg_id,k,str(v) if v is not None else None))

def insert_kv_item(conn, stg_item_id, item):
    with conn.cursor() as c:
        for k,v in item.items():
            if isinstance(v,(dict,list)):
                c.execute("""INSERT INTO stg_odoo_invoice_item_kv (stg_item_id,k,v_json)
                             VALUES (%s,%s,CAST(%s AS JSON))""",
                          (stg_item_id,k,json.dumps(v,ensure_ascii=False)))
            elif isinstance(v,(int,float)):
                c.execute("""INSERT INTO stg_odoo_invoice_item_kv (stg_item_id,k,v_num)
                             VALUES (%s,%s,%s)""",(stg_item_id,k,v))
            elif isinstance(v,bool):
                c.execute("""INSERT INTO stg_odoo_invoice_item_kv (stg_item_id,k,v_bool)
                             VALUES (%s,%s,%s)""",(stg_item_id,k,int(v)))
            else:
                c.execute("""INSERT INTO stg_odoo_invoice_item_kv (stg_item_id,k,v_text)
                             VALUES (%s,%s,%s)""",(stg_item_id,k,str(v) if v is not None else None))

def calc_totales_desde_items(items):
    grav=igv=ttl=0.0
    for it in items:
        grav += as_float(it.get("subtotal")) or 0.0
        igv  += as_float(it.get("igv")) or 0.0
        ttl  += as_float(it.get("total")) or 0.0
    return round(grav,2), round(igv,2), round(ttl,2)

def insert_header_and_items(conn, source, token, factura):
    # Mapeo a tus llaves reales
    serie   = parse_serie_from_correlativo(factura.get("serie_correlativo"))
    numero  = (factura.get("numero") if factura.get("numero") is not None else "")
    tipo    = "(01) Factura" if (factura.get("serie_correlativo") or "").startswith("(") else factura.get("tipo_de_comprobante")

    prov_doc   = factura.get("doc_proveedor")
    prov_nombre= factura.get("nom_proveedor")

    fecha_emision = parse_fecha_ddmmyyyy(factura.get("fecha_de_emision"))
    moneda = "1"  # en tu archivo siempre viene 1 dentro del item; si llega en cabecera, úsala.
    items  = factura.get("items") or []

    # Totales (si la cabecera no trae, los calculamos)
    total_gravada = factura.get("total_gravada")
    total_igv     = factura.get("total_igv")
    total         = factura.get("total")
    if total is None:
        g,i,t = calc_totales_desde_items(items)
        total_gravada = g
        total_igv     = i
        total         = t

    # Insert cabecera
    with conn.cursor() as c:
        c.execute("""
            INSERT INTO stg_odoo_invoice
            (source_endpoint, token_used, raw_json, codigo_unico, serie, numero, tipo_comprobante,
            proveedor_doc, proveedor_nombre, fecha_emision, moneda, total_gravada, total_igv, total)
            VALUES (%s, %s, CAST(%s AS JSON), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            source, token, json.dumps(factura, ensure_ascii=False),
            None, serie, numero, tipo,
            prov_doc, prov_nombre, fecha_emision, moneda,
            total_gravada, total_igv, total
        ))
        stg_id = c.lastrowid

    # KV cabecera (todos los campos)
    insert_kv_header(conn, stg_id, factura)

    # Ítems
    if isinstance(items, dict): items=list(items.values())
    with conn.cursor() as c:
        for idx, it in enumerate(items, start=1):
            unidad = it.get("unidad_de_medida") or it.get("unidad_medida")
            codigo = it.get("codigo_producto") or it.get("codigo") or it.get("id_producto")
            desc   = it.get("nom_producto") or it.get("descripcion")

            cantidad = as_float(it.get("cantidad")) or 0.0
            valor_u  = as_float(it.get("valor_unitario")) or 0.0
            precio_u = as_float(it.get("precio_unitario")) or 0.0
            desc_lin = as_float(it.get("descuento")) or 0.0
            sub_tot  = as_float(it.get("subtotal")) or (valor_u * cantidad)
            igv_line = as_float(it.get("igv")) or 0.0
            total_ln = as_float(it.get("total")) or (sub_tot + igv_line)

            # tipo_igv: si viene porcentaje '18.00' lo dejamos como '1' (afecto) para validar
            porc_igv = as_float(it.get("porcentaje_de_igv"))
            tipo_igv = "1" if (porc_igv and porc_igv > 0) else "0"

            estado_id   = str(it.get("id_estado")) if it.get("id_estado") is not None else None
            estado_nom  = it.get("nombre_estado")

            c.execute("""
                INSERT INTO stg_odoo_invoice_item
                (stg_id, linea_nro, unidad_medida, codigo, descripcion, cantidad,
                 valor_unitario, precio_unitario, descuento, subtotal, tipo_igv, igv, total_linea,
                 estado_id, estado_nombre, raw_item_json)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,CAST(%s AS JSON))
            """, (
                stg_id, idx, unidad, codigo, desc, cantidad,
                valor_u, precio_u, desc_lin, sub_tot, tipo_igv, igv_line, total_ln,
                estado_id, estado_nom, json.dumps(it, ensure_ascii=False)
            ))
            stg_item_id = c.lastrowid
            insert_kv_item(conn, stg_item_id, it)


# ------------------ CORE + Validaciones ------------------

UPSERT_HEADER = f"""
INSERT INTO inv_header (
  doc_key, source_endpoint, serie, numero, tipo_comprobante,
  proveedor_doc, proveedor_nombre, fecha_emision, moneda,
  total_gravada, total_igv, total, last_received_at
)
SELECT
  COALESCE(CONCAT_WS('-', s.serie, s.numero), UUID()) AS doc_key,
  s.source_endpoint, s.serie, s.numero, s.tipo_comprobante,
  s.proveedor_doc, s.proveedor_nombre, s.fecha_emision, s.moneda,
  COALESCE(s.total_gravada,0), COALESCE(s.total_igv,0), COALESCE(s.total,0), s.received_at
FROM stg_odoo_invoice s
JOIN (
  SELECT CONCAT_WS('-', serie, numero) AS doc_key, MAX(received_at) AS max_recv
  FROM stg_odoo_invoice
  GROUP BY CONCAT_WS('-', serie, numero)
) m ON m.doc_key = CONCAT_WS('-', s.serie, s.numero)
   AND m.max_recv = s.received_at
ON DUPLICATE KEY UPDATE
  source_endpoint = VALUES(source_endpoint),
  serie            = VALUES(serie),
  numero           = VALUES(numero),
  tipo_comprobante = VALUES(tipo_comprobante),
  proveedor_doc    = VALUES(proveedor_doc),
  proveedor_nombre = VALUES(proveedor_nombre),
  fecha_emision    = VALUES(fecha_emision),
  moneda           = VALUES(moneda),
  total_gravada    = VALUES(total_gravada),
  total_igv        = VALUES(total_igv),
  total            = VALUES(total),
  last_received_at = VALUES(last_received_at);
"""

DELETE_ITEMS = """
DELETE i FROM inv_item i
JOIN inv_header h ON h.doc_key = i.doc_key;
"""

INSERT_ITEMS = """
INSERT INTO inv_item (
  doc_key, linea_nro, unidad_medida, codigo, descripcion, cantidad,
  valor_unitario, precio_unitario, descuento, subtotal, tipo_igv, igv, total_linea,
  estado_id, estado_nombre
)
SELECT
  CONCAT_WS('-', s.serie, s.numero) AS doc_key,
  it.linea_nro, it.unidad_medida, it.codigo, it.descripcion,
  COALESCE(it.cantidad,0), COALESCE(it.valor_unitario,0), COALESCE(it.precio_unitario,0),
  COALESCE(it.descuento,0), COALESCE(it.subtotal,0), it.tipo_igv,
  COALESCE(it.igv,0), COALESCE(it.total_linea,0),
  it.estado_id, it.estado_nombre
FROM stg_odoo_invoice s
JOIN stg_odoo_invoice_item it ON it.stg_id = s.stg_id
JOIN (
  SELECT t.stg_id
  FROM stg_odoo_invoice t
  JOIN (
    SELECT CONCAT_WS('-', serie, numero) AS doc_key, MAX(received_at) AS max_recv
    FROM stg_odoo_invoice
    GROUP BY CONCAT_WS('-', serie, numero)
  ) m ON m.doc_key = CONCAT_WS('-', t.serie, t.numero)
     AND m.max_recv = t.received_at
) ult ON ult.stg_id = s.stg_id;
"""

VAL_TOTALES = """
SELECT 
  h.doc_key,
  ROUND(SUM(i.total_linea),2) AS total_items,
  ROUND(h.total,2)            AS total_doc,
  ROUND(SUM(i.total_linea),2) - ROUND(h.total,2) AS diff
FROM inv_header h
LEFT JOIN inv_item i ON i.doc_key = h.doc_key
GROUP BY h.doc_key
HAVING ABS(diff) > 0.01
ORDER BY ABS(diff) DESC
LIMIT 50;
"""

VAL_IGV_18 = """
SELECT
  doc_key, linea_nro, subtotal, igv,
  ROUND(subtotal * 0.18, 2) AS igv_18_calc,
  igv - ROUND(subtotal * 0.18, 2) AS diff
FROM inv_item
WHERE COALESCE(tipo_igv,'1')='1'
  AND ABS(igv - ROUND(subtotal * 0.18, 2)) > 0.01
ORDER BY ABS(igv - ROUND(subtotal * 0.18, 2)) DESC
LIMIT 50;
"""

def upsert_core(conn):
    with conn.cursor() as c:
        c.execute(UPSERT_HEADER)
        c.execute(DELETE_ITEMS)
        c.execute(INSERT_ITEMS)
    conn.commit()

def imprimir_validaciones(conn):
    with conn.cursor() as c:
        print("\n[Validación] Totales que no cuadran (muestra):")
        c.execute(VAL_TOTALES)
        for r in c.fetchall(): print(r)

        print("\n[Validación] IGV 18% con diferencia (muestra):")
        c.execute(VAL_IGV_18)
        for r in c.fetchall(): print(r)


# ------------------ MAIN ------------------

def main():
    ensure_database()
    conn = connect_mysql_db()
    try:
        run_ddl(conn)
        print("DDL OK")

        # CUSTOMER (archivo o API)
        try:
            if CUSTOMER_FILE and os.path.exists(CUSTOMER_FILE):
                cust = fetch_customer_invoices_file(CUSTOMER_FILE)
            else:
                cust = fetch_customer_invoices_api()
            print(f"Customer invoices: {len(cust)}")
            for f in cust:
                insert_header_and_items(conn, "customer_invoices", TOKEN_CUSTOMER, f)
            conn.commit()
        except Exception as e:
            print("[WARN] customer_invoices:", e)
            traceback.print_exc()

        # VENDOR (API opcional; si no lo usas, comenta este bloque)
        try:
            vend = fetch_vendor_bills_api(DATE_FROM, DATE_TO, COMPANY_ID, STATE_LIST, PAGE_SIZE)
            print(f"Vendor bills: {len(vend)}")
            for f in vend:
                insert_header_and_items(conn, "vendor_bills", TOKEN_VENDOR, f)
            conn.commit()
        except Exception as e:
            print("[WARN] vendor_bills:", e)
            traceback.print_exc()

        # CORE + VALIDACIONES
        upsert_core(conn)
        imprimir_validaciones(conn)

        print("\nProceso COMPLETO ✅")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
