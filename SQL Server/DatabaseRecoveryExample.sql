------------------------------------------------
-- Creating environment
------------------------------------------------
-- Create Database
CREATE DATABASE TestRecoveryDatabase
GO

-- Make sure database is in full recovery
ALTER DATABASE TestRecoveryDatabase
SET RECOVERY FULL
GO

USE TestRecoveryDatabase
GO
-- Create Table
CREATE TABLE TestTable (ID INT)
GO

-- Taking full backup
BACKUP DATABASE [TestRecoveryDatabase] TO DISK = N'C:\Db\TestRecoveryDatabase.bak'
GO

-- Insert some values
INSERT INTO TestTable (ID)
VALUES (1)
GO

-- Selecting the data from TestTable
SELECT *
FROM TestTable
GO

-- Taking log backup
BACKUP LOG [TestRecoveryDatabase] TO
DISK = N'C:\Db\TestRecoveryDatabase1.trn'
GO
INSERT INTO TestTable (ID)
VALUES (3)
GO
INSERT INTO TestTable (ID)
VALUES (4)
GO
BACKUP LOG [TestRecoveryDatabase] TO
DISK = N'C:\Db\TestRecoveryDatabase2.trn'
GO
-- Selecting the data from TestTable

INSERT INTO TestTable (ID)
VALUES (5)
GO
INSERT INTO TestTable (ID)
VALUES (6)
GO
INSERT INTO TestTable (ID)
VALUES (7)
GO
INSERT INTO TestTable (ID)
VALUES (8)
GO

-- Selecting the data from TestTable
SELECT *
FROM TestTable
GO

-- Marking Time Stamp
SELECT GETDATE() BeforeTruncateTime;

-- Selecting the data from TestTable
SELECT *
FROM TestTable
GO
-- Quick Delay before Truncate
WAITFOR DELAY '00:00:01'
GO
TRUNCATE TABLE TestTable
GO
-- Quick Delay after Truncate
WAITFOR DELAY '00:00:01'
GO

-- Marking Time Stamp
SELECT GETDATE() AfterTruncateTime;

-- Selecting the data from TestTable
SELECT *
FROM TestTable
GO

INSERT INTO TestTable (ID)
VALUES (9)
GO

-- Taking log backup
BACKUP LOG [TestRecoveryDatabase] TO
DISK = N'C:\Db\TestRecoveryDatabase.trn'
GO
-- Marking Time Stamp
SELECT GETDATE() CurrentTime;
-- Selecting the data from TestTable
SELECT *
FROM TestTable
GO

-----------------------------------------------
-- Restoring Database
------------------------------------------------
USE [master] GO

-- Taking tail log
BACKUP LOG [TestRecoveryDatabase] TO
DISK = N'C:\Db\TestRecoveryDatabase5.trn'
WITH NORECOVERY
GO

-- Restore full backup
RESTORE DATABASE [TestRecoveryDatabase] FROM DISK = N'C:\Db\TestRecoveryDatabase.bak'
GO

-- Restore transaction backup
RESTORE LOG [TestRecoveryDatabase] FROM DISK = N'C:\Db\TestRecoveryDatabase1.trn'
GO

-- Selecting the data from TestTable
SELECT *
FROM TestRecoveryDatabase.dbo.TestTable
GO

-- Restore transaction backup
RESTORE LOG [TestRecoveryDatabase] FROM DISK = N'C:\Db\TestRecoveryDatabase2.trn'
GO
-- Selecting the data from TestTable
SELECT *
FROM TestRecoveryDatabase.dbo.TestTable
GO
-- Restore transaction backup
RESTORE LOG [TestRecoveryDatabase] FROM DISK = N'C:\Db\TestRecoveryDatabase3.trn'
WITH STOPAT = '2011-12-21 11:12:18.797', -- Insert Your Time
GO

-- Rolling database forward
RESTORE LOG [TestRecoveryDatabase] WITH RECOVERY
GO

-- Selecting the data from TestTable
SELECT *
FROM TestRecoveryDatabase.dbo.TestTable
GO

