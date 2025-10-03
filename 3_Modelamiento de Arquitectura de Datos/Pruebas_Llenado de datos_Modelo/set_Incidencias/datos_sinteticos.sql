-- =========================================================
-- DATOS SINTÉTICOS PARA FactIncidencias (Perú, año 2025)
-- Ajusta las fechas si tu DimFecha usa otro ID distinto a YYYYMMDD
-- =========================================================

INSERT INTO dwh_dev.FactIncidencias
  (IncidenciaID, FecIniIncID, FecFinIncID, EstructuraID, TipoIncID, NomTipoInc,            NomEstado,   Fuente)
VALUES
  -- Ene 2025
  (20250001, 20250103, 20250103,   3, 3, 'Caída pasarela de pagos (VISA Perú)', 'Resuelta',   'NOC / Finanzas'),
  (20250002, 20250107, 20250108,   8, 2, 'Degradación API backend (timeouts)',  'Resuelta',  'Observability / Grafana'),
  (20250003, 20250112,      NULL, 15, 6, 'Patrón de fraude en compras',         'En curso',  'Fraude / AML'),
   (20250037, 20250110, 20250111,   3, 3, 'Caída pasarela de pagos (VISA Perú)', 'Resuelta',   'NOC / Finanzas'),
  (20250038, 20250109, 20250110,   8, 2, 'Degradación API backend (timeouts)',  'Resuelta',  'Observability / Grafana'),
  (20250039, 20250114,      NULL, 15, 6, 'Patrón de fraude en compras',         'En curso',  'Fraude / AML'),

  -- Feb 2025
  (20250004, 20250202, 20250202,   5, 3, 'Caída pasarela de pagos (VISA Perú)',        'Resuelta',   'Proveedor Telecom'),
  (20250005, 20250211, 20250213,  21, 2, 'Degradación API backend (timeouts)',        'Resuelta',  'DWH / ETL'),
  (20250006, 20250218, 20250219,  10, 5, 'Bots RPA detenidos por credenciales', 'Resuelta',  'RPA / Orchestrator'),

  -- Mar 2025
  (20250007, 20250301, 20250302,   1, 3, 'Caída pasarela de pagos (VISA Perú)',              'Resuelta',   'APM / Backend'),
  (20250008, 20250305, 20250307,  12, 2, 'Degradación API backend (timeouts)',        'Resuelta',  'Finanzas / PSP'),
  (20250009, 20250320,      NULL,  6, 3, 'Caída pasarela de pagos (VISA Perú)', 'abierta',   'NOC / CDN'),

  -- Abr 2025
  (20250010, 20250403, 20250403,  24, 3, 'Caída pasarela de pagos (VISA Perú)',       'Resuelta',   'DWH / Calidad Datos'),
  (20250011, 20250410, 20250412,  14, 2, 'Degradación API backend (timeouts)',         'Resuelta',  'DBA / Backend'),
  (20250012, 20250417, 20250418,   2, 3, 'Caída pasarela de pagos (VISA Perú)', 'abierta',   'Seguridad / SOC'),

  -- May 2025
  (20250013, 20250504, 20250504,   7, 3, 'Caída pasarela de pagos (VISA Perú)',         'Resuelta',   'Proveedor Eléctrico'),
  (20250014, 20250509,      NULL, 18, 2, 'Degradación API backend (timeouts)',       'En curso',  'RPA / Finanzas'),
  (20250015, 20250523, 20250524,  11, 3, 'Caída pasarela de pagos (VISA Perú)', 'abierta',  'PSP / Pagos'),
  (20250040, 20250503, 20250503,   3, 3, 'Caída pasarela de pagos (VISA Perú)', 'Resuelta',   'NOC / Finanzas'),
  (20250041, 20250507, 20250508,   8, 2, 'Degradación API backend (timeouts)',  'Resuelta',  'Observability / Grafana'),
  (20250042, 20250512,      NULL, 15, 6, 'Patrón de fraude en compras',         'En curso',  'Fraude / AML'),

  -- Jun 2025
  (20250016, 20250602, 20250603,   9, 3, 'Caída pasarela de pagos (VISA Perú)',          'Resuelta',  'Observability / APM'),
  (20250017, 20250607, 20250608,  20, 2, 'Degradación API backend (timeouts)',        'Resuelta',   'DWH / ETL'),
  (20250018, 20250615, 20250616,   4, 3, 'Caída pasarela de pagos (VISA Perú)', 'abierta',  'NOC / ISP'),

  -- Jul 2025
  (20250019, 20250701, 20250701,  16, 3, 'Caída pasarela de pagos (VISA Perú)',      'Resuelta',  'Finanzas / PSP'),
  (20250020, 20250706, 20250707,  22, 2, 'Degradación API backend (timeouts)',         'Resuelta',  'Backend / Cache'),
  (20250021, 20250719,      NULL,  5, 3, 'Caída pasarela de pagos (VISA Perú)', 'abierta',  'Fraude / SOC'),

  -- Ago 2025
  (20250022, 20250803, 20250803,  13, 1, 'Microcortes ISP (Cusco)',             'Cerrada',   'NOC / ISP'),
  (20250023, 20250811, 20250812,  19, 2, 'Degradación API backend (timeouts)',         'Resuelta',  'BI / PowerBI'),
  (20250024, 20250821, 20250822,   1, 3, 'Caída pasarela de pagos (VISA Perú)', 'abierta',  'RPA / Ventas'),

  -- Sep 2025
  (20250025, 20250902, 20250902,  23, 2, 'Bug en endpoint /orders',             'Resuelta',   'APIs / Backend'),
  (20250026, 20250909,      NULL,  8, 2, 'Degradación API backend (timeouts)',    'Abierta',   'NOC / ISP'),
  (20250027, 20250914, 20250915,   6, 2, 'Degradación API backend (timeouts)',        'En curso',  'Finanzas / PSP'),
  (20250044, 20250903, 20250904,   3, 3, 'Caída pasarela de pagos (VISA Perú)', 'Resuelta',   'NOC / Finanzas'),
  (20250045, 20250907, 20250908,   8, 2, 'Degradación API backend (timeouts)',  'Resuelta',  'Observability / Grafana'),
  (20250046, 20250912,      NULL, 15, 6, 'Patrón de fraude en compras',         'En curso',  'Fraude / AML'),

  -- Oct 2025
  (20250028, 20251005, 20251005,  10, 4, 'DimEstructura sin claves nuevas',     'Resuelta',   'DWH / Modelado'),
  (20250029, 20251012, 20251013,  17, 2, 'Degradación API backend (timeouts)',       'Resuelta',  'Scheduler / Backend'),
  (20250030, 20251025, 20251026,   3, 1, 'Nodo CDN Lima con errores',           'Resuelta',   'CDN / NOC'),

  -- Nov 2025
  (20250031, 20251103, 20251103,  12, 6, 'Cuenta admin comprometida (2FA)',     'Resuelta',   'Seguridad / IAM'),
  (20250032, 20251109, 20251110,  21, 2, 'Degradación API backend (timeouts)',     'Resuelta',  'RPA / Finanzas'),
  (20250033, 20251120,      NULL,  9, 2, 'Degradación API backend (timeouts)',        'En curso',  'BI / Data Quality'),
  (20250048, 20251107, 20251109,   8, 2, 'Degradación API backend (timeouts)',  'Resuelta',  'Observability / Grafana'),
  (20250049, 20251112,      NULL, 15, 6, 'Patrón de fraude en compras',         'En curso',  'Fraude / AML'),

  -- Dic 2025
  (20250034, 20251201, 20251201,  14, 3, 'Fallo con tokenización PCI',          'Resuelta',  'Finanzas / PSP'),
  (20250035, 20251211, 20251212,  24, 2, 'Degradación API backend (timeouts)',      'Resuelta',  'APM / Backend'),
  (20250036, 20251220,      NULL,  2,  2, 'Degradación API backend (timeouts)',        'En curso', 'NOC / ISP');
  
  -- select * from dwh_dev.FactIncidencias
