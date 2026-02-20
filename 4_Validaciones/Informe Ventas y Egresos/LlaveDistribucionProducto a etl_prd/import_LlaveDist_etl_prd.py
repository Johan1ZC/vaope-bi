# ==============

import pandas as pd
from sqlalchemy import create_engine

# ============== CONFIG ==============
excel_path = r"LlaveDistribucionProducto.xlsx"
sheet_name = 0  # o "LlaveDistribucionVentas"
table_name = "llavedistribucionproducto"

host = "44.221.49.59"
port = 3306
user = "forge"
password = "kQYXTKIszdADDmPBvrst"
db = "etl_prd"
# ====================================

# 1) Leer Excel SIN header para detectar la fila correcta de cabeceras
raw = pd.read_excel(excel_path, sheet_name=sheet_name, header=None, dtype=str)

# Busca la primera fila con suficientes celdas llenas (probable cabecera)
header_row = None
for i in range(min(30, len(raw))):  # revisa hasta 30 filas
    non_empty = raw.iloc[i].notna().sum()
    if non_empty >= 3:  # ajusta a 2 si tu header tiene pocas columnas
        header_row = i
        break

if header_row is None:
    raise ValueError("No se pudo detectar la fila de cabecera. Revisa el Excel (posibles filas vacías al inicio).")

# 2) Leer Excel usando esa fila como cabecera
df = pd.read_excel(excel_path, sheet_name=sheet_name, header=header_row, dtype=str)

# 3) Quitar columnas totalmente vacías (incluida la de la izquierda)
df = df.dropna(axis=1, how="all")

# 4) Quitar filas totalmente vacías
df = df.dropna(how="all")

# 5) Limpiar nombres de columnas
df.columns = (
    df.columns.astype(str)
    .str.strip()
    .str.lower()
    .str.replace(" ", "_")
    .str.replace("-", "_")
)

# 6) Quitar columnas tipo "unnamed" si aún quedara alguna
df = df.loc[:, ~df.columns.str.contains(r"^unnamed", case=False, na=False)]

# 7) (Opcional) limpiar espacios en valores string
df = df.apply(lambda col: col.str.strip() if col.dtype == "object" else col)

# 8) Conexión MySQL
engine = create_engine(
    f"mysql+pymysql://{user}:{password}@{host}:{port}/{db}?charset=utf8mb4"
)

# 9) Test rápido (opcional pero recomendado)
with engine.connect() as conn:
    print("Conectado OK:", conn.exec_driver_sql("SELECT DATABASE(), USER()").fetchone())

# 10) Cargar a tabla
df.to_sql(name=table_name, con=engine, if_exists="replace", index=False, chunksize=5000)

print("Carga OK ->", f"{db}.{table_name}", "| filas:", len(df), "| columnas:", len(df.columns))
print("Columnas cargadas:", df.columns.tolist())
