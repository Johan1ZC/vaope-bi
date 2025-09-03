SHOW VARIABLES LIKE 'local_infile';

-- temporal (hasta reinicio)
SET GLOBAL local_infile = 1;

-- mejor: persistente (MySQL 8+)
SET PERSIST local_infile = 1;
