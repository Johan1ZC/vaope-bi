
/*TELETICKET:

/*Ejecutar con powershell desde VSCODE

1.  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
 
2. .\.venv\Scripts\Activate.ps1

3. $env:MANIFEST="sources/teleticket/teleticket_manifest.yaml"

4. python sources/teleticket/hu31_crawler_teleticket.py

5. LOADER:

# variables (si no están en .env)
$env:DB_URL = "mysql+pymysql://user:pass@localhost:3306/dw_dev_hablavao?charset=utf8mb4"
$env:PARSER_BATCH = "100"
$env:UA = "HABLAVAO/1.0 (johanz1@pruebas.pe)"
$env:TZ_NAME = "America/Lima"

# correr
python sources/teleticket/hu32_loader_teleticket_dw.py

*/


/*JOINNUS:

/*Ejecutar con powershell desde VSCODE

1.  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
 
2. .\.venv\Scripts\Activate.ps1

3. $env:MANIFEST="sources/joinnus/joinnus_manifest.yaml"

4. python sources/joinnus/hu33_crawler_joinnus.py

5. LOADER:

# variables (si no están en .env)
$env:DB_URL = "mysql+pymysql://user:pass@localhost:3306/dw_dev_hablavao?charset=utf8mb4"
$env:PARSER_BATCH = "100"
$env:UA = "HABLAVAO/1.0 (johanz1@pruebas.pe)"
$env:TZ_NAME = "America/Lima"

# correr
python sources/joinnus/hu34_loader_joinnus_dw.py

*/











/*






# TICKETMASTER
$env:MANIFEST="sources/ticketmaster/ticketmaster_manifest.yaml"
python sources/ticketmaster/hu31_crawler_ticketmaster.py
*/

/*python hu31_crawler_teleticket.py*/


/* Limpiar
Remove-Item Env:HEADLESS
Remove-Item Env:DEBUG
*/
