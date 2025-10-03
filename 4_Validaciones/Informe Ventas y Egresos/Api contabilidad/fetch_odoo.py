import requests
import pymysql
import json

TOKEN = "pR4GfvD1keR1oafsk06vUdavoagX5ODelYOfIp6HPa6wX_k="
URL   = "https://odoo-stage.colaborativa.pe/api/customer_invoices"

headers = {"token": TOKEN}
resp = requests.get(URL, headers=headers, timeout=60)
resp.raise_for_status()

data = resp.json()
# Sólo para ver que funciona:
print("Tipo:", type(data).__name__)
if isinstance(data, list):
    print("Cantidad de facturas:", len(data))
else:
    print("Claves:", list(data.keys())[:10])

