/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates the 'UDFinanceWarehouse' database
    after checking if it already exists. If the database
    exists, it is dropped and recreated. Additionally, the
    script sets up three schemas within the database:
    'bronze', 'silver', and 'gold', corresponding to the
    T1, T2, and T3 layers of the Medallion Architecture.

WARNING:
    Running this script will drop the entire
    'UDFinanceWarehouse' database if it exists.
    All data in the database will be permanently deleted.
    Proceed with caution and ensure you have proper backups
    before running this script.
=============================================================
*/

USE master;
GO

-- Drop and recreate the 'UDFinanceWarehouse' Database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'UDFinanceWarehouse')
BEGIN
	ALTER DATABASE UDFinanceWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE UDFinanceWarehouse;
END
GO


-- 1. Create the 'UDFinanceWarehouse' Database
CREATE DATABASE UDFinanceWarehouse

USE UDFinanceWarehouse;

-- 2. Create schemas for the three layers: bronze (T1), silver (T2), and gold (T3)

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
