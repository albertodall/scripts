USE ISBets
GO

SET XACT_ABORT ON

DECLARE @Message varchar(1000)
DECLARE @TotalRows bigint = 0
DECLARE @CopiedRows bigint = 0
DECLARE @LastCopiedID bigint = 0
DECLARE @BlockSize bigint = 5000000

SELECT @TotalRows = SUM(row_count) 
FROM sys.dm_db_partition_stats 
WHERE [object_id] = OBJECT_ID('dbo.DettaglioScommesse') AND ([index_id] = 0 OR [index_id] = 1)

SELECT @CopiedRows = SUM(row_count) 
FROM sys.dm_db_partition_stats 
WHERE [object_id] = OBJECT_ID('dbo.DettaglioScommesse_new') AND ([index_id] = 0 OR [index_id] = 1)

RAISERROR('%I64d rows in the source table', 0, 1, @TotalRows) WITH NOWAIT
RAISERROR('%I64d rows in the target table', 0, 1, @CopiedRows) WITH NOWAIT

SET @Message = CAST(@TotalRows - @CopiedRows as varchar) + ' rows missing in the target table.'
RAISERROR(@Message, 0, 1) WITH NOWAIT

IF (@TotalRows - @CopiedRows) < @BlockSize
BEGIN
	SET @BlockSize = @TotalRows - @CopiedRows
END

SELECT @LastCopiedID = ISNULL(MAX(d.IDDettaglioScommessa), 0) FROM dbo.DettaglioScommesse_new d
SET @Message = 'Copying ' + CAST(@BlockSize as varchar) + ' rows...'
RAISERROR(@Message, 0, 1) WITH NOWAIT

SET IDENTITY_INSERT dbo.DettaglioScommesse_new ON 

BEGIN TRAN
	INSERT INTO dbo.DettaglioScommesse_new (IDDettaglioScommessa, IDScommessa, IDQuota, IDSottoEvento, Fissa, Esito, DataModificaEsito) 
	SELECT TOP (@BlockSize) d.IDDettaglioScommessa, d.IDScommessa, d.IDQuota, d.IDSottoEvento, d.Fissa, d.Esito, d.DataModificaEsito
	FROM 
		dbo.DettaglioScommesse d
	WHERE 
		d.IDDettaglioScommessa > @LastCopiedID
    ORDER BY 
		tbl.IDTransazione
COMMIT TRAN

SET IDENTITY_INSERT dbo.DettaglioScommesse_new OFF

SELECT @CopiedRows = SUM(row_count) 
FROM sys.dm_db_partition_stats 
WHERE [object_id] = OBJECT_ID('dbo.DettaglioScommesse_new') AND (index_id = 0 or index_id = 1)

SET @Message = 'Still ' + CAST(@TotalRows - @CopiedRows as varchar) + ' rows remaining.'
RAISERROR(@Message, 0, 1) WITH NOWAIT
