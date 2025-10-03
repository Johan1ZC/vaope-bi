import requests, pymysql, json
cn = pymysql.connect(host="localhost", user="root", password="1234", database="dwh_vaope")
cur = cn.cursor()

headers = {"token": "pR4GfvD1keR1oafsk06vUdavoagX5ODelYOfIp6HPa6wX_k="}
r = requests.get("https://odoo-stage.colaborativa.pe/api/customer_invoices", headers=headers, timeout=60)
r.raise_for_status()
data = r.json()  # puede ser lista o dict según endpoint

def insert_invoice(doc):
    sql = """
    INSERT INTO stg_odoo_invoice
      (source_endpoint, raw_json, codigo_unico, serie, numero, tipo_comprobante,
       cliente_ruc_dni, cliente_nombre, fecha_emision, moneda, total_gravada, total_igv, total)
    VALUES
      (%s, CAST(%s AS JSON),
       JSON_UNQUOTE(JSON_EXTRACT(%s,'$.codigo_unico')),
       JSON_UNQUOTE(JSON_EXTRACT(%s,'$.serie')),
       JSON_EXTRACT(%s,'$.numero'),
       JSON_UNQUOTE(JSON_EXTRACT(%s,'$.tipo_de_comprobante')),
       JSON_UNQUOTE(JSON_EXTRACT(%s,'$.cliente_numero_de_documento')),
       JSON_UNQUOTE(JSON_EXTRACT(%s,'$.cliente_denominacion')),
       STR_TO_DATE(JSON_UNQUOTE(JSON_EXTRACT(%s,'$.fecha_de_emision')), '%%d-%%m-%%Y'),
       JSON_UNQUOTE(JSON_EXTRACT(%s,'$.moneda')),
       JSON_EXTRACT(%s,'$.total_gravada'),
       JSON_EXTRACT(%s,'$.total_igv'),
       JSON_EXTRACT(%s,'$.total'))
    """
    js = json.dumps(doc, ensure_ascii=False)
    cur.execute(sql, ("customer_invoices", js, js, js, js, js, js, js, js, js, js, js, js))

# si es lista:
if isinstance(data, list):
    for doc in data: insert_invoice(doc)
else:
    insert_invoice(data)

cn.commit()
cur.close(); cn.close()
