/*
==============================================================================
Create Database and Schemas
==============================================================================
Script Purpose:
	This script creates a new database named 'DataWarehouseProject', after checking if it already exists.
	If the database exists, it is dropped and recreated. Additionally, the scripts set up three schemas
	within the database: 'bronze', 'silver', and 'gold'.

WARNING:
	Running this script will drop the entire 'DataWarehouseProject' database if it exists.
	All data in the database will be permanently deleted. Proceed with caution
	and ensure you have proper backups before running this script.

*/


USE master,

-- Drop and recreate the 'DataWarehouseProject' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseProject')
BEGIN

	ALTER DATABASE DataWarehouseProject SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouseProject;
END;
GO


-- Create the 'DataWarehouseProject' database
CREATE DATABASE DataWarehouseProject;
GO

USE DataWarehouseProject
GO


-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
