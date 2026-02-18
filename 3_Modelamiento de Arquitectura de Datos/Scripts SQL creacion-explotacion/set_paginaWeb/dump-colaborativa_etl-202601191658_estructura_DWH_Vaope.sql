-- MySQL dump 10.13  Distrib 8.0.19, for Win64 (x86_64)
--
-- Host: 161.132.37.28    Database: colaborativa_etl
-- ------------------------------------------------------
-- Server version	5.5.5-10.11.15-MariaDB-ubu2204

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `DimCuenta`
--

DROP TABLE IF EXISTS `DimCuenta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimCuenta` (
  `CuentaID` int(11) NOT NULL,
  `NombreCuenta` varchar(100) DEFAULT NULL,
  `Detalle` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`CuentaID`),
  UNIQUE KEY `uq_dimcta_nombre` (`NombreCuenta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimCuenta`
--

LOCK TABLES `DimCuenta` WRITE;
/*!40000 ALTER TABLE `DimCuenta` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimCuenta` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimDistribucionAnalitica`
--

DROP TABLE IF EXISTS `DimDistribucionAnalitica`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimDistribucionAnalitica` (
  `DistribucionID` int(11) NOT NULL,
  `Nombre` varchar(100) DEFAULT NULL,
  `Subcategoria` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`DistribucionID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimDistribucionAnalitica`
--

LOCK TABLES `DimDistribucionAnalitica` WRITE;
/*!40000 ALTER TABLE `DimDistribucionAnalitica` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimDistribucionAnalitica` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimEmpleado`
--

DROP TABLE IF EXISTS `DimEmpleado`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimEmpleado` (
  `EmpleadoID` int(11) NOT NULL AUTO_INCREMENT,
  `DNI` varchar(25) DEFAULT NULL,
  `Nombre` varchar(250) DEFAULT NULL,
  `Apellidos` varchar(250) DEFAULT NULL,
  `Genero` varchar(150) DEFAULT NULL,
  `FecNacimiento` date DEFAULT NULL,
  `FecIngreso` date DEFAULT NULL,
  `FecCese` date DEFAULT NULL,
  `TipoContrato` varchar(150) DEFAULT NULL,
  `Puesto` varchar(150) DEFAULT NULL,
  `EstructuraID` int(11) DEFAULT NULL,
  `FechaCarga` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`EmpleadoID`),
  UNIQUE KEY `uq_empleado_empid_dni` (`DNI`),
  KEY `ix_empl_estructura` (`EstructuraID`),
  CONSTRAINT `fk_dimestr_dimempleado` FOREIGN KEY (`EstructuraID`) REFERENCES `DimEstructura` (`EstructuraID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimEmpleado`
--

LOCK TABLES `DimEmpleado` WRITE;
/*!40000 ALTER TABLE `DimEmpleado` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimEmpleado` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimEstadoFactura`
--

DROP TABLE IF EXISTS `DimEstadoFactura`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimEstadoFactura` (
  `EstadoFacturaID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `EstadoFacturaSlc` varchar(30) NOT NULL,
  `EstadoFactura` varchar(50) NOT NULL,
  PRIMARY KEY (`EstadoFacturaID`),
  UNIQUE KEY `uq_estadofactslc` (`EstadoFacturaSlc`),
  UNIQUE KEY `uq_estadofact` (`EstadoFactura`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimEstadoFactura`
--

LOCK TABLES `DimEstadoFactura` WRITE;
/*!40000 ALTER TABLE `DimEstadoFactura` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimEstadoFactura` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimEstadosRRHH`
--

DROP TABLE IF EXISTS `DimEstadosRRHH`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimEstadosRRHH` (
  `EstadoID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `TipoEstado` varchar(150) NOT NULL,
  `Motivo` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`EstadoID`),
  UNIQUE KEY `uq_estado_tipo_motivo` (`TipoEstado`,`Motivo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimEstadosRRHH`
--

LOCK TABLES `DimEstadosRRHH` WRITE;
/*!40000 ALTER TABLE `DimEstadosRRHH` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimEstadosRRHH` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimEstructura`
--

DROP TABLE IF EXISTS `DimEstructura`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimEstructura` (
  `EstructuraID` int(11) NOT NULL AUTO_INCREMENT,
  `Area` varchar(150) NOT NULL,
  `SubArea` varchar(150) DEFAULT NULL,
  `Equipo` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`EstructuraID`),
  UNIQUE KEY `uq_estructura` (`Area`,`SubArea`,`Equipo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimEstructura`
--

LOCK TABLES `DimEstructura` WRITE;
/*!40000 ALTER TABLE `DimEstructura` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimEstructura` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimEventos`
--

DROP TABLE IF EXISTS `DimEventos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimEventos` (
  `EventoID` int(11) NOT NULL,
  `NombreEvento` varchar(250) DEFAULT NULL,
  `FechaInicio` datetime NOT NULL,
  `FechaFin` datetime DEFAULT NULL,
  `NroClics` int(11) NOT NULL DEFAULT 0,
  `LocalEventoID` int(11) DEFAULT NULL,
  `Stock` int(11) DEFAULT NULL,
  `Categoria` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`EventoID`),
  KEY `dimeventos_localeventoid_index` (`LocalEventoID`),
  CONSTRAINT `fk_event_local` FOREIGN KEY (`LocalEventoID`) REFERENCES `DimLocalEvento` (`LocalEventoID`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimEventos`
--

LOCK TABLES `DimEventos` WRITE;
/*!40000 ALTER TABLE `DimEventos` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimEventos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimFecha`
--

DROP TABLE IF EXISTS `DimFecha`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimFecha` (
  `FechaID` int(11) NOT NULL,
  `Fecha` date NOT NULL,
  `Anio` int(11) DEFAULT NULL,
  `Mes` int(11) DEFAULT NULL,
  `Trimestre` int(11) DEFAULT NULL,
  `NombreDia` varchar(10) DEFAULT NULL,
  `NombreMes` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`FechaID`),
  UNIQUE KEY `uq_dimfecha_fecha` (`Fecha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimFecha`
--

LOCK TABLES `DimFecha` WRITE;
/*!40000 ALTER TABLE `DimFecha` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimFecha` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimLocalEvento`
--

DROP TABLE IF EXISTS `DimLocalEvento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimLocalEvento` (
  `LocalEventoID` int(11) NOT NULL,
  `UbicacionID` int(11) DEFAULT NULL,
  `NomLocal` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`LocalEventoID`),
  KEY `dimlocalevento_ubicacionid_index` (`UbicacionID`),
  CONSTRAINT `fk_ubica_local` FOREIGN KEY (`UbicacionID`) REFERENCES `DimUbicacion` (`UbicacionID`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimLocalEvento`
--

LOCK TABLES `DimLocalEvento` WRITE;
/*!40000 ALTER TABLE `DimLocalEvento` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimLocalEvento` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimOrganizadores`
--

DROP TABLE IF EXISTS `DimOrganizadores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimOrganizadores` (
  `OrganizadorID` int(11) NOT NULL,
  `Nombre` varchar(100) DEFAULT NULL,
  `TipoOrg` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`OrganizadorID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimOrganizadores`
--

LOCK TABLES `DimOrganizadores` WRITE;
/*!40000 ALTER TABLE `DimOrganizadores` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimOrganizadores` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimProducto`
--

DROP TABLE IF EXISTS `DimProducto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimProducto` (
  `ProductoID` int(11) NOT NULL,
  `NomProducto` varchar(100) DEFAULT NULL,
  `CategoriaProducto` varchar(100) DEFAULT NULL,
  `TipoOrigen` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`ProductoID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimProducto`
--

LOCK TABLES `DimProducto` WRITE;
/*!40000 ALTER TABLE `DimProducto` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimProducto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimProveedor`
--

DROP TABLE IF EXISTS `DimProveedor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimProveedor` (
  `ProveedorID` int(11) NOT NULL,
  `NomProveedor` varchar(100) NOT NULL,
  `Descripcion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`ProveedorID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimProveedor`
--

LOCK TABLES `DimProveedor` WRITE;
/*!40000 ALTER TABLE `DimProveedor` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimProveedor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimTicketera`
--

DROP TABLE IF EXISTS `DimTicketera`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimTicketera` (
  `TicketeraID` int(11) NOT NULL,
  `NomTicketera` varchar(100) DEFAULT NULL,
  `TipoTicketera` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`TicketeraID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimTicketera`
--

LOCK TABLES `DimTicketera` WRITE;
/*!40000 ALTER TABLE `DimTicketera` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimTicketera` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimTiposGasto`
--

DROP TABLE IF EXISTS `DimTiposGasto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimTiposGasto` (
  `TipoGastoID` int(11) NOT NULL,
  `NombreGasto` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`TipoGastoID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimTiposGasto`
--

LOCK TABLES `DimTiposGasto` WRITE;
/*!40000 ALTER TABLE `DimTiposGasto` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimTiposGasto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimUbicacion`
--

DROP TABLE IF EXISTS `DimUbicacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimUbicacion` (
  `UbicacionID` int(11) NOT NULL,
  `Pais` varchar(50) NOT NULL,
  `Departamento` varchar(100) NOT NULL,
  `Provincia` varchar(100) NOT NULL,
  `Distrito` varchar(100) NOT NULL,
  `Ubigeo6` char(6) NOT NULL,
  PRIMARY KEY (`UbicacionID`),
  UNIQUE KEY `UX_Ubigeo6` (`Ubigeo6`),
  UNIQUE KEY `XAK1DimUbicacion` (`Pais`,`Departamento`,`Provincia`,`Distrito`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimUbicacion`
--

LOCK TABLES `DimUbicacion` WRITE;
/*!40000 ALTER TABLE `DimUbicacion` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimUbicacion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DimVendedor`
--

DROP TABLE IF EXISTS `DimVendedor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DimVendedor` (
  `VendedorID` int(11) NOT NULL,
  `Vendedor` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`VendedorID`),
  UNIQUE KEY `uq_vendedor_nombre` (`Vendedor`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DimVendedor`
--

LOCK TABLES `DimVendedor` WRITE;
/*!40000 ALTER TABLE `DimVendedor` DISABLE KEYS */;
/*!40000 ALTER TABLE `DimVendedor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Dimhora`
--

DROP TABLE IF EXISTS `Dimhora`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Dimhora` (
  `HoraID` int(11) NOT NULL,
  `Hora` time DEFAULT NULL,
  `Hora24` tinyint(4) DEFAULT NULL,
  `Hora12` tinyint(4) DEFAULT NULL,
  `AMPM` char(2) DEFAULT NULL,
  `Tramo` varchar(15) DEFAULT NULL,
  `BloqueHora` varchar(15) DEFAULT NULL,
  `EshorarioLaboral` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`HoraID`),
  CONSTRAINT `ck_hora24_valid` CHECK (`Hora24` between 0 and 23),
  CONSTRAINT `ck_hora12_valid` CHECK (`Hora12` between 1 and 12),
  CONSTRAINT `ck_ampm_valid` CHECK (`AMPM` in ('AM','PM')),
  CONSTRAINT `ck_eslaboral_valid` CHECK (`EshorarioLaboral` in (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Dimhora`
--

LOCK TABLES `Dimhora` WRITE;
/*!40000 ALTER TABLE `Dimhora` DISABLE KEYS */;
/*!40000 ALTER TABLE `Dimhora` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Dimusuario`
--

DROP TABLE IF EXISTS `Dimusuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Dimusuario` (
  `usuarioID` int(11) NOT NULL,
  `genero` varchar(15) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `esActivo` tinyint(1) DEFAULT 0,
  `origen` varchar(150) NOT NULL,
  PRIMARY KEY (`usuarioID`),
  KEY `idx_dimusuario_esActivo` (`esActivo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Dimusuario`
--

LOCK TABLES `Dimusuario` WRITE;
/*!40000 ALTER TABLE `Dimusuario` DISABLE KEYS */;
/*!40000 ALTER TABLE `Dimusuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FactAsistencia`
--

DROP TABLE IF EXISTS `FactAsistencia`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FactAsistencia` (
  `AsistenciaID` bigint(20) NOT NULL AUTO_INCREMENT,
  `FechaID` int(11) NOT NULL,
  `EmpleadoID` int(11) NOT NULL,
  `EstructuraID` int(11) DEFAULT NULL,
  `Asistio` tinyint(1) NOT NULL DEFAULT 0,
  `MinTardanza` int(11) NOT NULL DEFAULT 0,
  `MinExtras` int(11) NOT NULL DEFAULT 0,
  `HorasTrabajadas` decimal(12,2) DEFAULT NULL,
  `MinAusencia` int(11) NOT NULL DEFAULT 0,
  `HoraIngReal` time DEFAULT NULL,
  `HoraSalReal` time DEFAULT NULL,
  `TipoAsistencia` varchar(150) DEFAULT NULL,
  `NombreTurno` varchar(150) NOT NULL,
  `HoraEntradaPlan` time NOT NULL,
  `HoraSalidaPlan` time NOT NULL,
  `Fuente` varchar(100) NOT NULL,
  `FechaCarga` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`AsistenciaID`),
  UNIQUE KEY `uq_asistencia_dia_emp` (`FechaID`,`EmpleadoID`),
  KEY `ix_asist_emp` (`EmpleadoID`),
  KEY `ix_asist_fecha` (`FechaID`),
  KEY `ix_asist_estr` (`EstructuraID`),
  CONSTRAINT `fk_dimempl_factasist` FOREIGN KEY (`EmpleadoID`) REFERENCES `DimEmpleado` (`EmpleadoID`) ON DELETE CASCADE,
  CONSTRAINT `fk_dimestr_factasist` FOREIGN KEY (`EstructuraID`) REFERENCES `DimEstructura` (`EstructuraID`) ON DELETE CASCADE,
  CONSTRAINT `fk_dimfecha_factasist` FOREIGN KEY (`FechaID`) REFERENCES `DimFecha` (`FechaID`) ON DELETE CASCADE,
  CONSTRAINT `ck_asist_no_negativos` CHECK (`MinTardanza` >= 0 and `MinExtras` >= 0 and `MinAusencia` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FactAsistencia`
--

LOCK TABLES `FactAsistencia` WRITE;
/*!40000 ALTER TABLE `FactAsistencia` DISABLE KEYS */;
/*!40000 ALTER TABLE `FactAsistencia` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FactEgresosDetalle`
--

DROP TABLE IF EXISTS `FactEgresosDetalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FactEgresosDetalle` (
  `EgresoID` bigint(20) NOT NULL AUTO_INCREMENT,
  `FechaFacturaID` int(11) NOT NULL,
  `FechaID` int(11) NOT NULL,
  `EventoID` int(11) DEFAULT NULL,
  `ProductoID` int(11) NOT NULL,
  `CantidadProd` int(11) NOT NULL,
  `SinImpuesto` decimal(12,2) NOT NULL,
  `TipoGastoID` int(11) DEFAULT NULL,
  `Total` decimal(12,2) NOT NULL,
  `PercentDist` decimal(12,2) NOT NULL,
  `FacturaDetalleID` varchar(50) NOT NULL,
  `Impuesto` decimal(12,2) NOT NULL,
  `EstadoFacturaID` bigint(20) unsigned NOT NULL,
  `DistribucionID` int(11) DEFAULT NULL,
  `FacturaID` varchar(100) NOT NULL,
  `CuentaID` int(11) DEFAULT NULL,
  `valor_unitario` decimal(12,2) NOT NULL,
  `precio_unitario` decimal(12,2) NOT NULL,
  `descuento` decimal(12,2) NOT NULL,
  `porcentaje_igv` decimal(12,2) NOT NULL,
  `moneda` varchar(25) DEFAULT NULL,
  `tipo_cambio` varchar(25) DEFAULT NULL,
  `nombreEmpresa` varchar(150) DEFAULT NULL,
  `Fuente` varchar(50) DEFAULT NULL,
  `FechaCarga` datetime NOT NULL DEFAULT current_timestamp(),
  `ProveedorID` int(11) DEFAULT NULL,
  PRIMARY KEY (`EgresoID`),
  KEY `ix_fe_fechafact` (`FechaFacturaID`),
  KEY `ix_fe_fecha` (`FechaID`),
  KEY `ix_fe_tipogasto` (`TipoGastoID`),
  KEY `ix_fe_proveedor` (`ProveedorID`),
  KEY `ix_fe_evento` (`EventoID`),
  KEY `ix_fe_estado` (`EstadoFacturaID`),
  KEY `ix_fe_producto` (`ProductoID`),
  KEY `ix_fe_distanalit` (`DistribucionID`),
  KEY `ix_fe_cuenta` (`CuentaID`),
  CONSTRAINT `fk_factegre_event` FOREIGN KEY (`EventoID`) REFERENCES `DimEventos` (`EventoID`) ON DELETE SET NULL,
  CONSTRAINT `fk_factegre_fecha` FOREIGN KEY (`FechaID`) REFERENCES `DimFecha` (`FechaID`),
  CONSTRAINT `fk_factegre_produc` FOREIGN KEY (`ProductoID`) REFERENCES `DimProducto` (`ProductoID`),
  CONSTRAINT `fk_factegre_tipgasto` FOREIGN KEY (`TipoGastoID`) REFERENCES `DimTiposGasto` (`TipoGastoID`) ON DELETE SET NULL,
  CONSTRAINT `fk_factegredetall_estadofact` FOREIGN KEY (`EstadoFacturaID`) REFERENCES `DimEstadoFactura` (`EstadoFacturaID`),
  CONSTRAINT `fk_factegredetall_proveed` FOREIGN KEY (`ProveedorID`) REFERENCES `DimProveedor` (`ProveedorID`) ON DELETE SET NULL,
  CONSTRAINT `fk_factegreso_DistAna` FOREIGN KEY (`DistribucionID`) REFERENCES `DimDistribucionAnalitica` (`DistribucionID`) ON DELETE SET NULL,
  CONSTRAINT `fk_factegreso_cuenta` FOREIGN KEY (`CuentaID`) REFERENCES `DimCuenta` (`CuentaID`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FactEgresosDetalle`
--

LOCK TABLES `FactEgresosDetalle` WRITE;
/*!40000 ALTER TABLE `FactEgresosDetalle` DISABLE KEYS */;
/*!40000 ALTER TABLE `FactEgresosDetalle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FactEventosRRHH`
--

DROP TABLE IF EXISTS `FactEventosRRHH`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FactEventosRRHH` (
  `EventoRrhhID` bigint(20) NOT NULL AUTO_INCREMENT,
  `FechaID` int(11) NOT NULL,
  `EmpleadoID` int(11) NOT NULL,
  `EstadoID` int(10) unsigned NOT NULL,
  `EstructuraDesdeID` int(11) DEFAULT NULL,
  `EstructuraHastaID` int(11) DEFAULT NULL,
  `Fuente` varchar(100) NOT NULL,
  `FechaCarga` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`EventoRrhhID`),
  KEY `ix_evt_fecha_emp` (`FechaID`,`EmpleadoID`),
  KEY `ix_evt_estado` (`EstadoID`),
  KEY `fk_dimempl_facteventrrhh` (`EmpleadoID`),
  KEY `fk_dimestrdes_facteventrrhh` (`EstructuraDesdeID`),
  KEY `fk_dimestrhast_facteventrrhh` (`EstructuraHastaID`),
  CONSTRAINT `fk_dimempl_facteventrrhh` FOREIGN KEY (`EmpleadoID`) REFERENCES `DimEmpleado` (`EmpleadoID`) ON DELETE CASCADE,
  CONSTRAINT `fk_dimesta_facteventrrhh` FOREIGN KEY (`EstadoID`) REFERENCES `DimEstadosRRHH` (`EstadoID`) ON DELETE CASCADE,
  CONSTRAINT `fk_dimestrdes_facteventrrhh` FOREIGN KEY (`EstructuraDesdeID`) REFERENCES `DimEstructura` (`EstructuraID`) ON DELETE CASCADE,
  CONSTRAINT `fk_dimestrhast_facteventrrhh` FOREIGN KEY (`EstructuraHastaID`) REFERENCES `DimEstructura` (`EstructuraID`) ON DELETE CASCADE,
  CONSTRAINT `fk_dimfecha_facteventrrhh` FOREIGN KEY (`FechaID`) REFERENCES `DimFecha` (`FechaID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FactEventosRRHH`
--

LOCK TABLES `FactEventosRRHH` WRITE;
/*!40000 ALTER TABLE `FactEventosRRHH` DISABLE KEYS */;
/*!40000 ALTER TABLE `FactEventosRRHH` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FactIncidencias`
--

DROP TABLE IF EXISTS `FactIncidencias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FactIncidencias` (
  `factincidenciaID` int(11) NOT NULL AUTO_INCREMENT,
  `IncidenciaID` int(11) NOT NULL,
  `FecIniIncID` int(11) DEFAULT NULL,
  `FecFinIncID` int(11) DEFAULT NULL,
  `EstructuraID` int(11) DEFAULT NULL,
  `TipoIncID` int(11) DEFAULT NULL,
  `NomTipoInc` varchar(150) DEFAULT NULL,
  `NomEstado` varchar(150) DEFAULT NULL,
  `Fuente` varchar(150) DEFAULT NULL,
  `FechaCarga` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`factincidenciaID`),
  UNIQUE KEY `uq_fact_incidencias_incidenciaid` (`IncidenciaID`),
  KEY `idx_factinc_fecini` (`FecIniIncID`),
  KEY `idx_factinc_fecfin` (`FecFinIncID`),
  KEY `idx_factinc_estruct` (`EstructuraID`),
  KEY `idx_factinc_tipoinc` (`TipoIncID`),
  KEY `idx_factinc_estruct_fechas` (`EstructuraID`,`FecIniIncID`,`FecFinIncID`),
  CONSTRAINT `fk_factinc_dimestructura` FOREIGN KEY (`EstructuraID`) REFERENCES `DimEstructura` (`EstructuraID`) ON DELETE CASCADE,
  CONSTRAINT `fk_factinc_dimfecha_fin` FOREIGN KEY (`FecFinIncID`) REFERENCES `DimFecha` (`FechaID`) ON DELETE CASCADE,
  CONSTRAINT `fk_factinc_dimfecha_ini` FOREIGN KEY (`FecIniIncID`) REFERENCES `DimFecha` (`FechaID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FactIncidencias`
--

LOCK TABLES `FactIncidencias` WRITE;
/*!40000 ALTER TABLE `FactIncidencias` DISABLE KEYS */;
/*!40000 ALTER TABLE `FactIncidencias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FactRedesSociales`
--

DROP TABLE IF EXISTS `FactRedesSociales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FactRedesSociales` (
  `FactID` int(11) NOT NULL AUTO_INCREMENT,
  `FechaID` int(11) NOT NULL,
  `empresa` varchar(150) NOT NULL,
  `plataformaRS` enum('tiktok','instagram','facebook','youtube') NOT NULL,
  `nuevos_Seguidores` int(11) NOT NULL DEFAULT 0,
  `nuevos_meGusta` int(11) NOT NULL DEFAULT 0,
  `nuevas_publicaciones` int(11) NOT NULL DEFAULT 0,
  `nuevas_visitasPerfil` int(11) NOT NULL DEFAULT 0,
  `nuevos_clics` int(11) NOT NULL DEFAULT 0,
  `nuevas_vistas` int(11) NOT NULL DEFAULT 0,
  `nuevos_comentarios` int(11) NOT NULL DEFAULT 0,
  `nuevos_compartidos` int(11) NOT NULL DEFAULT 0,
  `nuevos_guardados` int(11) NOT NULL DEFAULT 0,
  `nuevos_mensajesDM` int(11) NOT NULL DEFAULT 0,
  `inversionAds` decimal(12,2) NOT NULL DEFAULT 0.00,
  `Fuente` varchar(100) DEFAULT NULL,
  `FechaCarga` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`FactID`),
  UNIQUE KEY `uq_periodo_empresa_plat` (`FechaID`,`empresa`,`plataformaRS`),
  KEY `ix_fact_empresa_fecha` (`empresa`,`FechaID`),
  KEY `ix_fact_plataforma_fecha` (`plataformaRS`,`FechaID`),
  CONSTRAINT `fk_fact_fecha` FOREIGN KEY (`FechaID`) REFERENCES `DimFecha` (`FechaID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FactRedesSociales`
--

LOCK TABLES `FactRedesSociales` WRITE;
/*!40000 ALTER TABLE `FactRedesSociales` DISABLE KEYS */;
/*!40000 ALTER TABLE `FactRedesSociales` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FactVentasDetalle`
--

DROP TABLE IF EXISTS `FactVentasDetalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FactVentasDetalle` (
  `VentaID` bigint(20) NOT NULL AUTO_INCREMENT,
  `FechaFacturaID` int(11) NOT NULL,
  `FechaID` int(11) NOT NULL,
  `EventoID` int(11) DEFAULT NULL,
  `ProductoID` int(11) NOT NULL,
  `CantidadProd` int(11) NOT NULL,
  `SinImpuesto` decimal(12,2) NOT NULL,
  `Total` decimal(12,2) NOT NULL,
  `PercentDist` decimal(12,2) NOT NULL DEFAULT 100.00,
  `VendedorID` int(11) DEFAULT NULL,
  `FacturaDetalleID` varchar(100) NOT NULL,
  `Impuesto` decimal(12,2) NOT NULL,
  `EstadoFacturaID` bigint(20) unsigned NOT NULL,
  `DistribucionID` int(11) DEFAULT NULL,
  `FacturaID` varchar(100) NOT NULL,
  `CuentaID` int(11) DEFAULT NULL,
  `valor_unitario` decimal(12,2) NOT NULL,
  `precio_unitario` decimal(12,2) NOT NULL,
  `descuento` decimal(12,2) NOT NULL,
  `porcentaje_igv` decimal(12,2) NOT NULL,
  `moneda` varchar(25) DEFAULT NULL,
  `tipo_cambio` varchar(25) DEFAULT NULL,
  `nombreEmpresa` varchar(150) DEFAULT NULL,
  `Fuente` varchar(50) DEFAULT NULL,
  `FechaCarga` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`VentaID`),
  KEY `ix_fv_fechafact` (`FechaFacturaID`),
  KEY `ix_fv_fecha` (`FechaID`),
  KEY `ix_fv_producto` (`ProductoID`),
  KEY `ix_fv_vendedor` (`VendedorID`),
  KEY `ix_fv_evento` (`EventoID`),
  KEY `ix_fv_estado` (`EstadoFacturaID`),
  KEY `ix_fv_distanalit` (`DistribucionID`),
  KEY `ix_fv_cuenta` (`CuentaID`),
  CONSTRAINT `fk_factvent_estado` FOREIGN KEY (`EstadoFacturaID`) REFERENCES `DimEstadoFactura` (`EstadoFacturaID`),
  CONSTRAINT `fk_factvent_event` FOREIGN KEY (`EventoID`) REFERENCES `DimEventos` (`EventoID`) ON DELETE SET NULL,
  CONSTRAINT `fk_factvent_fechafactura` FOREIGN KEY (`FechaID`) REFERENCES `DimFecha` (`FechaID`),
  CONSTRAINT `fk_factvent_produc` FOREIGN KEY (`ProductoID`) REFERENCES `DimProducto` (`ProductoID`),
  CONSTRAINT `fk_factvent_vendor` FOREIGN KEY (`VendedorID`) REFERENCES `DimVendedor` (`VendedorID`) ON DELETE SET NULL,
  CONSTRAINT `fk_factventa_DistAna` FOREIGN KEY (`DistribucionID`) REFERENCES `DimDistribucionAnalitica` (`DistribucionID`) ON DELETE SET NULL,
  CONSTRAINT `fk_factventa_cuenta` FOREIGN KEY (`CuentaID`) REFERENCES `DimCuenta` (`CuentaID`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FactVentasDetalle`
--

LOCK TABLES `FactVentasDetalle` WRITE;
/*!40000 ALTER TABLE `FactVentasDetalle` DISABLE KEYS */;
/*!40000 ALTER TABLE `FactVentasDetalle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `FactVentasWeb`
--

DROP TABLE IF EXISTS `FactVentasWeb`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FactVentasWeb` (
  `factVentaID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `fechaID` int(11) NOT NULL,
  `horaID` int(11) DEFAULT NULL,
  `web_VentaID` int(11) NOT NULL,
  `eventoID` int(11) DEFAULT NULL,
  `nom_evento` varchar(150) DEFAULT NULL,
  `status_general` varchar(150) DEFAULT NULL,
  `usuarioID` int(11) DEFAULT NULL,
  `utm_source` varchar(250) DEFAULT NULL,
  `utm_campaign` varchar(250) DEFAULT NULL,
  `utm_medium` varchar(250) DEFAULT NULL,
  `cantidadProd` int(11) DEFAULT NULL,
  `sub_total` decimal(12,2) DEFAULT NULL,
  `discount` decimal(12,2) DEFAULT NULL,
  `delivery` decimal(12,2) DEFAULT NULL,
  `total_price` decimal(12,2) DEFAULT NULL,
  `payment_commission` decimal(12,2) DEFAULT NULL,
  `vaope_commission` decimal(12,2) DEFAULT NULL,
  `sale_commission` decimal(12,2) DEFAULT NULL,
  `total_deposit` decimal(12,2) DEFAULT NULL,
  `total_deposit_new` decimal(12,2) DEFAULT NULL,
  `esCortesia` tinyint(1) DEFAULT NULL,
  `persons` int(11) DEFAULT NULL,
  `payment_method_id` int(11) DEFAULT NULL,
  `mp_NomMetodo` varchar(150) DEFAULT NULL,
  `mp_EntidadFinanciera` varchar(150) DEFAULT NULL,
  `mp_Procesador_Wallet` varchar(150) DEFAULT NULL,
  `mp_Red_Tarjeta` varchar(150) DEFAULT NULL,
  `mp_Producto` varchar(150) DEFAULT NULL,
  `pagos_count` int(11) DEFAULT NULL,
  `metodos_distintos` int(11) DEFAULT NULL,
  `mp_MetodoGrupo` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`factVentaID`),
  UNIQUE KEY `uq_factventasweb` (`web_VentaID`),
  KEY `idx_factventasweb_fecha` (`fechaID`),
  KEY `idx_factventasweb_web_venta` (`web_VentaID`),
  KEY `idx_factventasweb_evento` (`eventoID`),
  KEY `idx_factventasweb_hora` (`horaID`),
  KEY `idx_factventasweb_usuario` (`usuarioID`),
  KEY `idx_factventasweb_utms` (`utm_source`,`utm_medium`,`utm_campaign`),
  KEY `idx_factventasweb_fecha_evento` (`fechaID`,`eventoID`),
  KEY `idx_metodogrupo` (`mp_MetodoGrupo`),
  CONSTRAINT `fk_dimusuario_factventasweb` FOREIGN KEY (`usuarioID`) REFERENCES `Dimusuario` (`usuarioID`) ON DELETE CASCADE,
  CONSTRAINT `fk_factventasweb_dimeventos` FOREIGN KEY (`eventoID`) REFERENCES `DimEventos` (`EventoID`) ON DELETE CASCADE,
  CONSTRAINT `fk_factventasweb_dimfecha` FOREIGN KEY (`fechaID`) REFERENCES `DimFecha` (`FechaID`) ON DELETE CASCADE,
  CONSTRAINT `fk_factventasweb_dimhora` FOREIGN KEY (`horaID`) REFERENCES `Dimhora` (`HoraID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `FactVentasWeb`
--

LOCK TABLES `FactVentasWeb` WRITE;
/*!40000 ALTER TABLE `FactVentasWeb` DISABLE KEYS */;
/*!40000 ALTER TABLE `FactVentasWeb` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache`
--

LOCK TABLES `cache` WRITE;
/*!40000 ALTER TABLE `cache` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache_locks`
--

DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_locks`
--

LOCK TABLES `cache_locks` WRITE;
/*!40000 ALTER TABLE `cache_locks` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_locks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `eventosOrganizador_Detalle`
--

DROP TABLE IF EXISTS `eventosOrganizador_Detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `eventosOrganizador_Detalle` (
  `OrganizadorID` int(11) NOT NULL,
  `EventoID` int(11) NOT NULL,
  PRIMARY KEY (`EventoID`,`OrganizadorID`),
  KEY `ix_evorg_org` (`OrganizadorID`),
  CONSTRAINT `fk_eventos_organizador` FOREIGN KEY (`EventoID`) REFERENCES `DimEventos` (`EventoID`) ON DELETE CASCADE,
  CONSTRAINT `fk_organiza_event` FOREIGN KEY (`OrganizadorID`) REFERENCES `DimOrganizadores` (`OrganizadorID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `eventosOrganizador_Detalle`
--

LOCK TABLES `eventosOrganizador_Detalle` WRITE;
/*!40000 ALTER TABLE `eventosOrganizador_Detalle` DISABLE KEYS */;
/*!40000 ALTER TABLE `eventosOrganizador_Detalle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `eventosTicketera_detalle`
--

DROP TABLE IF EXISTS `eventosTicketera_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `eventosTicketera_detalle` (
  `TicketeraID` int(11) NOT NULL,
  `EventoID` int(11) NOT NULL,
  PRIMARY KEY (`TicketeraID`,`EventoID`),
  KEY `ix_evtick_ticke` (`TicketeraID`),
  KEY `fk_eventos_ticket` (`EventoID`),
  CONSTRAINT `fk_eventos_ticket` FOREIGN KEY (`EventoID`) REFERENCES `DimEventos` (`EventoID`) ON DELETE CASCADE,
  CONSTRAINT `fk_ticket_event` FOREIGN KEY (`TicketeraID`) REFERENCES `DimTicketera` (`TicketeraID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `eventosTicketera_detalle`
--

LOCK TABLES `eventosTicketera_detalle` WRITE;
/*!40000 ALTER TABLE `eventosTicketera_detalle` DISABLE KEYS */;
/*!40000 ALTER TABLE `eventosTicketera_detalle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `failed_jobs`
--

DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `failed_jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `failed_jobs`
--

LOCK TABLES `failed_jobs` WRITE;
/*!40000 ALTER TABLE `failed_jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `failed_jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_batches`
--

DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_batches`
--

LOCK TABLES `job_batches` WRITE;
/*!40000 ALTER TABLE `job_batches` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_batches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) unsigned NOT NULL,
  `reserved_at` int(10) unsigned DEFAULT NULL,
  `available_at` int(10) unsigned NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `migrations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `migrations`
--

LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
INSERT INTO `migrations` VALUES (1,'0001_01_01_000000_create_users_table',1),(2,'0001_01_01_000001_create_cache_table',1),(3,'0001_01_01_000002_create_jobs_table',1),(4,'2025_08_25_154634_create_personal_access_tokens_table',1),(5,'2025_08_25_180332_create_dim_distribucion_analitica_table',1),(6,'2025_08_25_180522_create_dim_estado_factura_table',1),(7,'2025_08_25_180635_create_dim_ubicacion_table',1),(8,'2025_08_25_181042_create_dim_local_evento_table',1),(9,'2025_08_25_181239_add_dim_local_evento_fk',1),(10,'2025_08_25_181403_create_dim_eventos_table',1),(11,'2025_08_25_181438_add_dim_eventos_fk',1),(12,'2025_08_25_201641_create_dim_fecha_table',1),(13,'2025_08_25_201716_create_dim_organizadores_table',1),(14,'2025_08_25_201754_create_dim_producto_table',1),(15,'2025_08_25_201817_create_dim_proveedor_table',1),(16,'2025_08_25_201845_create_dim_tipos_gasto_table',1),(17,'2025_08_25_201846_create_dim_cuenta_table',1),(18,'2025_08_25_201916_create_dim_vendedor_table',1),(19,'2025_08_25_202027_create_eventos_organizador_detalle_table',1),(20,'2025_08_25_202201_add_eventos_organizador_detalle_fk',1),(21,'2025_08_25_202308_create_fact_egresos_detalle_table',1),(22,'2025_08_25_202435_add_fact_egresos_detalle_fk',1),(23,'2025_08_25_202516_create_fact_ventas_detalle_table',1),(24,'2025_08_25_202603_add_fact_ventas_detalle_fk',1),(25,'2025_10_09_220322_create_ticket_holders_table',1),(26,'2025_10_09_220453_create_ticket_event_details_table',1),(27,'2025_10_09_221606_add_fk_ticket_event_details_table',1),(28,'2025_10_09_224122_create_dim_estructura_table',1),(29,'2025_10_09_224841_create_dim_empleados_table',1),(30,'2025_10_09_225543_alter_fk_dim_empleado_table',1),(31,'2025_10_09_225707_create_fact_asistencias_table',1),(32,'2025_10_09_230716_alter_fk_fact_asistencia_table',1),(33,'2025_10_09_232708_create_state_hr_dims_table',1),(34,'2025_10_09_232924_create_fact_hr_event_table',1),(35,'2025_10_09_234304_alter_fk_fact_hr_state_table',1),(36,'2025_10_09_234555_create_hour_dims_table',1),(37,'2025_10_10_041755_create_user_dims_table',1),(38,'2025_10_10_061545_create_web_sales_facts_table',1),(39,'2025_10_10_125640_alter_fk_web_sales_fact_table',1),(40,'2025_10_10_130043_create_fact_incidents_table',1),(41,'2025_10_10_130630_alter_fk_fact_incident_table',1),(42,'2025_10_10_132447_create_social_network_facts_table',1),(43,'2025_10_10_133257_alter_fk__social_network_fact_table',1),(44,'2025_11_06_162319_alter_tables_dim_eventos',1);
/*!40000 ALTER TABLE `migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_reset_tokens`
--

DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_reset_tokens`
--

LOCK TABLES `password_reset_tokens` WRITE;
/*!40000 ALTER TABLE `password_reset_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `password_reset_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `personal_access_tokens`
--

DROP TABLE IF EXISTS `personal_access_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) unsigned NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personal_access_tokens`
--

LOCK TABLES `personal_access_tokens` WRITE;
/*!40000 ALTER TABLE `personal_access_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `personal_access_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'colaborativa_etl'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 16:58:09
