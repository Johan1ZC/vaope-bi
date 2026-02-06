import pymysql

conn = pymysql.connect(
    host='161.132.37.28',
    user='colaborativa_etl',
    password='Z5Jb_,]M9qLwT4M7',
    database='colaborativa_etl',
    port=3306
)

print("Conexión exitosa")
conn.close()