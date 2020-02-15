USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_delete_old_differential_backups]    Script Date: 03/23/2011 22:09:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alberto Dallagiacoma
-- Create date: 08/07/2010	
-- Description:	Keeps only the last differential backup performed
-- =============================================
ALTER PROCEDURE [dbo].[sp_delete_old_differential_backups]
(
	@DBName sysname,				-- Es.: 'Northwind'
	@DBBackupFolder varchar(500)	-- Es.: 'E:\Backup\Northwind\' (occhio al backslash finale, che è fondamentale!!!
)
AS
BEGIN
	-- Variabili
	DECLARE @cmd nvarchar(1024) 
	DECLARE @fileList TABLE (backupFile nvarchar(255), backupFileId int identity(1, 1)) 
	DECLARE @backupFileId int
	DECLARE @backupFileIdMax int
	DECLARE @backupFileName varchar(500)
	DECLARE @delPreviousDiffBackupsShellCmd varchar(1024)

	-- Elenco dei files su disco
	SET @cmd = 'DIR /b ' + @DBBackupFolder + '*.DIF'

	INSERT INTO @fileList(backupFile) 
	EXEC master.sys.xp_cmdshell @cmd 

	SELECT @backupFileId = 0, @backupFileIdMax = COALESCE(MAX(backupfileid), 0) FROM @filelist

	-- Esclude l'ultima riga (NULL) e l'ultimo backup differenziale eseguito.
	-- Elimina gli altri files
	WHILE @backupFileId < @backupFileIdMax - 2
		BEGIN
			SELECT @backupFileId = MIN(backupfileid) FROM @filelist WHERE backupfileid > @backupFileId
			SELECT @backupFileName = backupfile FROM @filelist WHERE backupfileid = @backupFileId
			SET @delPreviousDiffBackupsShellCmd = 'del /q ' + @DBBackupFolder + @backupFileName
			-- PRINT @delPreviousDiffBackupsShellCmd
			EXEC master..xp_cmdshell @delPreviousDiffBackupsShellCmd
		END
END
