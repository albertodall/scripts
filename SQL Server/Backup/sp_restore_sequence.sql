USE [master]
GO

/****** Object:  StoredProcedure [dbo].[sp_restore_sequence]    Script Date: 03/23/2011 22:10:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_restore_sequence]
(
	@DBName sysname,				-- Es.: 'Northwind'
	@DBBackupFolder varchar(500)	-- Es.: 'E:\SqlBackups\' (occhio al backslash finale, che è fondamentale...)
)
AS
BEGIN
	SET NOCOUNT ON 

	-- Variabili
	DECLARE @cmd nvarchar(1024) 
	DECLARE @fileList TABLE (backupFile nvarchar(255)) 
	DECLARE @lastFullBackup nvarchar(500) 
	DECLARE @lastDiffBackup nvarchar(500) 
	DECLARE @backupFile nvarchar(500) 

	-- Elenco dei files su disco
	SET @cmd = 'DIR /b ' + @DBBackupFolder

	INSERT INTO @fileList(backupFile) 
	EXEC master.sys.xp_cmdshell @cmd 

	-- Ricerca dell'ultimo full backup
	SELECT @lastFullBackup = MAX(backupFile)  
	FROM @fileList  
	WHERE (backupFile LIKE '%.BAK') AND (backupFile LIKE @dbName + '%')

	SET @cmd = 'RESTORE DATABASE ' + @dbName + ' FROM DISK = ''' + @DBBackupFolder + @lastFullBackup + ''' WITH NORECOVERY, REPLACE' 
	PRINT @cmd 

	-- Ricerca dell'ultimo backup differenziale
	SELECT @lastDiffBackup = MAX(backupFile)  
	FROM @fileList  
	WHERE (backupFile LIKE '%.DIF') AND (backupFile LIKE @dbName + '%') AND (backupFile > @lastFullBackup)

	IF @lastDiffBackup IS NOT NULL 
		BEGIN 
		   SET @cmd = 'RESTORE DATABASE ' + @dbName + ' FROM DISK = '''  
			   + @DBBackupFolder + @lastDiffBackup + ''' WITH NORECOVERY' 
		   PRINT @cmd 
		   SET @lastFullBackup = @lastDiffBackup 
		END 

	-- Controllo backup del T-Log
	DECLARE backupFiles CURSOR FOR  
	   SELECT backupFile  
	   FROM @fileList 
	   WHERE (backupFile LIKE '%.TRN') AND (backupFile LIKE @dbName + '%') AND (backupFile > @lastFullBackup )

	OPEN backupFiles  
	FETCH NEXT FROM backupFiles INTO @backupFile  

	WHILE @@FETCH_STATUS = 0  
		BEGIN  
		   SET @cmd = 'RESTORE LOG ' + @dbName + ' FROM DISK = '''  
			   + @DBBackupFolder + @backupFile + ''' WITH NORECOVERY' 
		   PRINT @cmd 
		   FETCH NEXT FROM backupFiles INTO @backupFile  
		END 

	CLOSE backupFiles  
	DEALLOCATE backupFiles  

	-- Impostazione dello stato di RECOVERY (ultima azione della procedura
	-- di Disaster Recovery per mettere il DB online)
	SET @cmd = 'RESTORE DATABASE ' + @dbName + ' WITH RECOVERY' 
	PRINT @cmd 
END

GO


