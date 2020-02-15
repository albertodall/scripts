USE [master]
GO

/****** Object:  StoredProcedure [dbo].[sp_retain_backups]    Script Date: 03/23/2011 22:08:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_retain_backups]
(
	@DBName 	  sysname,		-- Es.: 'Northwind'
	@BackupFolder varchar(255),	-- Es.: 'E:\SqlBackups\' (occhio al backslash finale, che è fondamentale)
	@RetainDays   int = 0
)
AS
BEGIN
	DECLARE @dbBackupPath varchar(255)
	DECLARE @lastBackupToKeep varchar(8)
	DECLARE @listBackupsShellCmd varchar(1000)
	DECLARE @deleteOlderBackupShellCmd varchar(128)
	
	SET @dbBackupPath = @BackupFolder + @DBName
	SET @listBackupsShellCmd = N'dir /B ' + @dbBackupPath + '\*.' -- Lista solo le cartelle
	SET @lastBackupToKeep = CONVERT(varchar(8), GETDATE() - @RetainDays, 112)
	
	-- Creazione della tabella dei backup esistenti.
	-- In questa tabella verranno tenuti solo i backup da cancellare, eliminando i record relativi  
	-- ai backup con data entro l'intervallo di retain.
	IF OBJECT_ID('tempdb..#ExistingBackups') IS NOT NULL DROP TABLE #ExistingBackups
	CREATE TABLE #ExistingBackups
	(
		backupfolder  	varchar(128),
		backupfolderid  int identity (1, 1)
	)
	INSERT INTO #ExistingBackups EXEC master..xp_cmdshell @listBackupsShellCmd
	DELETE FROM #ExistingBackups WHERE backupfolder >= @lastBackupToKeep
	
	-- Elimina dal disco i backup più vecchi di @RetainDays giorni
	DECLARE	@backupFolderId    	int
	DECLARE @backupFolderIdMax	int
	DECLARE	@backupFolderName	varchar(255)
			
	SELECT @backupFolderId = 0, @backupFolderIdMax = COALESCE(MAX(backupfolderid), 0) FROM #ExistingBackups
	WHILE @backupFolderId < @backupFolderIdMax
		BEGIN
			SELECT @backupFolderId = MIN(backupfolderid) FROM #ExistingBackups WHERE backupfolderid > @backupFolderId
			SELECT @backupFolderName = backupfolder FROM #ExistingBackups WHERE backupfolderid = @backupFolderId
			SET @deleteOlderBackupShellCmd = 'rd /s /q ' + @dbBackupPath + '\' + @backupFolderName
			--PRINT @deleteOlderBackupShellCmd
			EXEC master..xp_cmdshell @deleteOlderBackupShellCmd
		END
	DROP TABLE #ExistingBackups
END

GO


