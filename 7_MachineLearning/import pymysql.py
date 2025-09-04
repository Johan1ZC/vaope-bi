import pymysql

conn = pymysql.connect(
    host='192.168.0.190
    user='user_remoto',
    password='Vaope2025',
    database='dw_dev',
    port=3306
)

print("Conexión exitosa")
conn.close()