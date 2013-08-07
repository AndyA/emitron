CREATE DATABASE /*!32312 IF NOT EXISTS*/ `elvis`;
USE `elvis`;
-- MySQL dump 10.14  Distrib 10.0.3-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: elvis
-- ------------------------------------------------------
-- Server version	10.0.3-MariaDB-1~wheezy-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `elvis_collection`
--

DROP TABLE IF EXISTS `elvis_collection`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_collection` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Collection id',
  `name` varchar(60) NOT NULL COMMENT 'Collection name',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_collection`
--

LOCK TABLES `elvis_collection` WRITE;
/*!40000 ALTER TABLE `elvis_collection` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_collection` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elvis_copyright_class`
--

DROP TABLE IF EXISTS `elvis_copyright_class`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_copyright_class` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Copyright class id',
  `name` char(1) NOT NULL COMMENT 'Copyright class',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_copyright_class`
--

LOCK TABLES `elvis_copyright_class` WRITE;
/*!40000 ALTER TABLE `elvis_copyright_class` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_copyright_class` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elvis_copyright_holder`
--

DROP TABLE IF EXISTS `elvis_copyright_holder`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_copyright_holder` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Copyright holder id',
  `name` varchar(200) NOT NULL COMMENT 'Copyright holder name',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_copyright_holder`
--

LOCK TABLES `elvis_copyright_holder` WRITE;
/*!40000 ALTER TABLE `elvis_copyright_holder` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_copyright_holder` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elvis_format`
--

DROP TABLE IF EXISTS `elvis_format`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_format` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Format id',
  `name` varchar(50) NOT NULL COMMENT 'Format name',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_format`
--

LOCK TABLES `elvis_format` WRITE;
/*!40000 ALTER TABLE `elvis_format` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_format` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elvis_image`
--

DROP TABLE IF EXISTS `elvis_image`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_image` (
  `acno` int(10) unsigned NOT NULL COMMENT 'Asset id',
  `kind_id` int(10) unsigned DEFAULT NULL,
  `collection_id` int(10) unsigned DEFAULT NULL,
  `copyright_class_id` int(10) unsigned DEFAULT NULL,
  `copyright_holder_id` int(10) unsigned DEFAULT NULL,
  `format_id` int(10) unsigned DEFAULT NULL,
  `location_id` int(10) unsigned DEFAULT NULL,
  `news_restriction_id` int(10) unsigned DEFAULT NULL,
  `personality_id` int(10) unsigned DEFAULT NULL,
  `origin_date` date DEFAULT NULL,
  `photographer_id` int(10) unsigned DEFAULT NULL,
  `subject_id` int(10) unsigned DEFAULT NULL,
  `width` int(5) unsigned DEFAULT NULL,
  `height` int(5) unsigned DEFAULT NULL,
  `annotation` text,
  `headline` text,
  PRIMARY KEY (`acno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_image`
--

LOCK TABLES `elvis_image` WRITE;
/*!40000 ALTER TABLE `elvis_image` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_image` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elvis_kind`
--

DROP TABLE IF EXISTS `elvis_kind`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_kind` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Image kind id',
  `name` varchar(60) NOT NULL COMMENT 'Image kind name',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_kind`
--

LOCK TABLES `elvis_kind` WRITE;
/*!40000 ALTER TABLE `elvis_kind` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_kind` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elvis_location`
--

DROP TABLE IF EXISTS `elvis_location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_location` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Location id',
  `name` varchar(100) NOT NULL COMMENT 'Location name',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_location`
--

LOCK TABLES `elvis_location` WRITE;
/*!40000 ALTER TABLE `elvis_location` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_location` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elvis_news_restriction`
--

DROP TABLE IF EXISTS `elvis_news_restriction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_news_restriction` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'News restriction id',
  `name` varchar(1000) NOT NULL COMMENT 'News restriction name',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_news_restriction`
--

LOCK TABLES `elvis_news_restriction` WRITE;
/*!40000 ALTER TABLE `elvis_news_restriction` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_news_restriction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elvis_personality`
--

DROP TABLE IF EXISTS `elvis_personality`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_personality` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Personality id',
  `name` varchar(2000) NOT NULL COMMENT 'Personality name',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_personality`
--

LOCK TABLES `elvis_personality` WRITE;
/*!40000 ALTER TABLE `elvis_personality` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_personality` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elvis_photographer`
--

DROP TABLE IF EXISTS `elvis_photographer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_photographer` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Photographer id',
  `name` varchar(200) NOT NULL COMMENT 'Photographer name',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_photographer`
--

LOCK TABLES `elvis_photographer` WRITE;
/*!40000 ALTER TABLE `elvis_photographer` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_photographer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `elvis_subject`
--

DROP TABLE IF EXISTS `elvis_subject`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `elvis_subject` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Subject term id',
  `name` varchar(200) NOT NULL COMMENT 'Subject term',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `elvis_subject`
--

LOCK TABLES `elvis_subject` WRITE;
/*!40000 ALTER TABLE `elvis_subject` DISABLE KEYS */;
/*!40000 ALTER TABLE `elvis_subject` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'elvis'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-07-19 15:13:43
