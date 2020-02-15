USE [master]
GO

-- Add filestream filegroup
ALTER DATABASE [InstaLike] 
ADD FILEGROUP [Foto] CONTAINS FILESTREAM 
GO

-- Add Datafile to filegroup
ALTER DATABASE [InstaLike] 
ADD FILE ( NAME = N'InstaLike_Foto', FILENAME = N'D:\SqlDb\InstaLike\Foto' ) TO FILEGROUP [Foto]
GO

-- Remove
USE [InstaLike]
GO
ALTER DATABASE [InstaLike]  REMOVE FILE [InstaLike_Foto]
GO
