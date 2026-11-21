-- Active: 1795184393029@@127.0.0.1@5432@datawarehouse
/*
=============================================================
Create Database and Schemas (PostgreSQL)
=============================================================
Script Purpose:
    This script creates a new database named 'datawarehouse' after checking if it already exists.
    If the database exists, active connections are terminated and it is dropped and recreated.
    Additionally, the script sets up three schemas within the database: 'bronze', 'silver', and 'gold'.

WARNING:
    Running this script will drop the entire 'datawarehouse' database if it exists.
    All data in the database will be permanently deleted. Proceed with caution
    and ensure you have proper backups before running this script.

Usage Note:
    1. Connect to a maintenance database (e.g., 'postgres') to execute the DROP DATABASE
       and CREATE DATABASE statements (each must be run outside a transaction block).
    2. Switch your connection to 'datawarehouse' (or uncomment `\c datawarehouse` in psql)
       before running the CREATE SCHEMA statements.
*/

-- =============================================================
-- Step 1: Drop and Recreate the Database
-- (Execute while connected to 'postgres' or another maintenance DB)
-- =============================================================

-- Terminate active connections and drop the 'datawarehouse' database if it exists (PostgreSQL 13+)
DROP DATABASE IF EXISTS datawarehouse WITH (FORCE);

-- Create the 'datawarehouse' database
CREATE DATABASE datawarehouse;

-- If running via psql CLI, uncomment the line below to switch connection to 'datawarehouse':
-- \c datawarehouse

-- =============================================================
-- Step 2: Create Schemas
-- (Execute while connected to 'datawarehouse')
-- =============================================================

CREATE SCHEMA IF NOT EXISTS bronze;

CREATE SCHEMA IF NOT EXISTS silver;

CREATE SCHEMA IF NOT EXISTS gold;
