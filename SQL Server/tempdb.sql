USE tempdb
GO
EXEC sp_helpfile
GO

USE master
GO
ALTER DATABASE tempdb 
    MODIFY FILE (NAME = tempdev, FILENAME = 'C:\temp\tempdb.mdf')
GO
ALTER DATABASE tempdb 
    MODIFY FILE (NAME = templog, FILENAME = 'C:\temp\tempdb.ldf')
GO