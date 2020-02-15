USE [master]
GO

/****** Object:  StoredProcedure [dbo].[sp_backup_database]    Script Date: 03/23/2011 22:08:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_backup_database]
(
	@DBName 	    varchar(128),	-- Es.: 'Northwind'
	@DBBackupFolder varchar(255),	-- Es.: 'E:\SqlBackups\' (occhio al backslash finale, che è obbligatorio...)
	@BackupType		varchar(4)		-- Es.: 'Full', 'Diff', 'Log'
)
AS
BEGIN
	DECLARE @createDailyFolderShellCmd varchar(1000)
	DECLARE @dailyFolderName varchar(8)
	DECLARE @backupTime varchar(5)
	DECLARE @destinationPath varchar(500)
	DECLARE @backupFileName varchar(500)

	-- Creazione della cartella che conterrà i backup giornalieri (se non esiste)
	SET @dailyFolderName = CONVERT(varchar(8), GETDATE(), 112)
	SET @destinationPath = @DBBackupFolder + @DBName + '\' + @dailyFolderName
	SET @createDailyFolderShellCmd = 'IF NOT EXIST ' + @destinationPath + ' md ' + @destinationPath
	EXEC master..xp_cmdshell @createDailyFolderShellCmd
	
	-- Il nome del file di backup risulterà nel formato Northwind_20090818_1230.BAK|DIF|TRN
	SET @backupTime = REPLACE(CONVERT(varchar(5), GETDATE(), 108), ':', '')
	SET @backupFileName = @destinationPath + '\' + @DBName + '_' + @dailyFolderName + '_' + @backupTime
	IF @BackupType = 'Full'
		BEGIN
			SET @backupFileName = @backupFileName + '.BAK'
			BACKUP DATABASE @DBName TO DISK = @backupFileName WITH INIT
		END
	ELSE IF @BackupType = 'Diff'
		BEGIN
			SET @backupFileName = @backupFileName + '.DIF'
			BACKUP DATABASE @DBName TO DISK = @backupFileName WITH DIFFERENTIAL, INIT
		END
	ELSE IF @BackupType = 'Log' 
		BEGIN
			SET @backupFileName = @backupFileName + '.TRN'
			BACKUP LOG @DBName TO DISK = @backupFileName WITH INIT
		END
END

GO


