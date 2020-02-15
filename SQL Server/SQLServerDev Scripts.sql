USE AdventureWorks
GO

/***** Informazioni su una pagina dati *****/
DBCC TRACEON(3604)
GO
DBCC PAGE('AdventureWorks', 1, 11750, 3) WITH TABLERESULTS
GO
DBCC TRACEOFF(3604)
GO


/***** INDICI *****/

SELECT 
    OBJECT_NAME(op.[object_id]) AS [object_name], 
    i.[name] AS index_name, 
    op.leaf_insert_count, 
    op.leaf_update_count, 
    op.leaf_delete_count
FROM  
    sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL) op 
    INNER JOIN sys.indexes i 
        ON op.[object_id] = i.[object_id] AND op.index_id = i.index_id 
WHERE  
    OBJECTPROPERTY(op.[object_id],'IsUserTable') = 1

SELECT
    OBJECT_NAME(S.[object_id]) AS [object_name], 
    I.[name] AS [index_name], 
    s.user_seeks, 
    s.user_scans, 
    s.user_lookups, 
    s.user_updates 
FROM
    sys.dm_db_index_usage_stats s     
    INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id]  AND s.index_id = i.index_id
WHERE    
    OBJECTPROPERTY(S.[object_id], 'IsUserTable') = 1 

SELECT 
    OBJECT_NAME(ips.OBJECT_ID)
    , i.NAME
    , ips.index_id
    , index_type_desc
    , avg_fragmentation_in_percent
    , avg_page_space_used_in_percent
    , page_count
FROM 
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') ips
    INNER JOIN sys.indexes i ON (ips.object_id = i.object_id) AND (ips.index_id = i.index_id)
ORDER BY 
    avg_fragmentation_in_percent DESC

/***** Piani di esecuzione *****/
USE AdventureWorks
GO
SELECT *
FROM 
    Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
WHERE 
    soh.OrderDate = '2013-11-30'
GO

USE AdventureWorks
GO
DBCC FREEPROCCACHE
GO
-- Elenco di piani nella plan cache
SELECT 
    [cp].[refcounts]
    ,[cp].[usecounts]
    ,[cp].[objtype]
    ,[st].[dbid]
    ,[st].[objectid]
    ,[st].[text]
    ,[qp].[query_plan]
FROM 
    sys.dm_exec_cached_plans cp
    CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
    CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp

-- Ad-Hoc statements 
USE AdventureWorks
GO
SELECT * FROM [Production].[Product] WHERE [Name]='Adjustable Race'
GO
SELECT * FROM [Production].[Product] WHERE [Name]='Crown Race'
GO
SELECT * FROM [Production].[Product] WHERE [Name]='Handlebar Tube'
GO

-- Statements con parametri
USE AdventureWorks
GO
EXEC sp_executesql N'SELECT * FROM [Production].[Product] WHERE [Name] = @p1', N'@p1 varchar(4000)', 'Adjustable Race'
GO
EXEC sp_executesql N'SELECT * FROM [Production].[Product] WHERE [Name] = @p1', N'@p1 varchar(4000)', 'Crown Race'
GO
EXEC sp_executesql N'SELECT * FROM [Production].[Product] WHERE [Name] = @p1', N'@p1 varchar(4000)', 'Handlebar Tube'
GO

/***** Esempi di Execution plan su tabelle singole *****/

-- Table Scan
USE AdventureWorks
GO
SELECT * FROM [dbo].[DatabaseLog]
GO
SELECT COUNT(DatabaseLogID) FROM [dbo].[DatabaseLog]
GO


-- Clustered Index Scan
-- [PK_Product_ProductID]
USE AdventureWorks
GO
SELECT * FROM Production.Product
GO

-- Clustered Index Seek
-- [PK_Product_ProductID]
USE AdventureWorks
GO
SELECT * FROM Production.Product 
WHERE ProductID = 711
GO

-- Nonclustered Index Seek
-- [AK_Product_Name]
USE AdventureWorks
GO
SELECT 
    [Name]
FROM 
    [Production].[Product]
WHERE 
    [Name] like 'Flat%'
GO

-- Key Lookup
-- [AK_Product_Name]
USE AdventureWorks
GO
SELECT 
    [ProductID], [Name], [ProductNumber]
FROM
    [Production].[Product]
WHERE
    [Name] LIKE 'Flat%'
GO

-- RID Lookup
USE AdventureWorks
GO
SELECT * FROM [dbo].[DatabaseLog]
WHERE DatabaseLogID = 1
GO

/***** Piani di esecuzione su più tabelle *****/

-- Hash Match e Nested Loop 
-- Ritorna un elenco degli impiegati (nome e cognome) e la loro città di residenza
USE AdventureWorks
GO
SELECT 
    e.[JobTitle],
    a.[City],
    p.[LastName] + ', ' + p.[FirstName] AS EmployeeName -- Genera un'operazione di "Compute Scalar"
FROM 
    [HumanResources].[Employee] e
    INNER JOIN [Person].[BusinessEntityAddress] ea ON e.[BusinessEntityID] = ea.[BusinessEntityID] AND ea.AddressTypeID = 2 --> Home Address
    INNER JOIN [Person].[Address] a ON [ea].[AddressID] = [a].[AddressID] AND ea.AddressTypeID = 2 --> Home Address
    INNER JOIN [Person].[Person] p ON e.[BusinessEntityID] = p.[BusinessEntityID]
WHERE e.[JobTitle] = 'Production Technician - WC20'
GO

-- Merge Join
-- Ritorna gli ID dei clienti che hanno ordini
USE AdventureWorks
GO
SELECT 
    c.CustomerID
FROM 
    Sales.SalesOrderDetail od 
    INNER JOIN Sales.SalesOrderHeader oh ON od.SalesOrderID = oh.SalesOrderID
    INNER JOIN Sales.Customer c ON oh.CustomerID = c.CustomerID
GO

-- Sort
USE AdventureWorks
GO
SELECT *
FROM [Production].[ProductInventory]
ORDER BY [Shelf]

SELECT *
FROM [Production].[ProductInventory]
ORDER BY [ProductID]

-- Hash Match (Aggregate)
USE AdventureWorks
GO
SELECT 
    [City]
    , COUNT([City]) AS CityCount
FROM 
    [Person].[Address]
GROUP BY [City]

-- Filter
USE AdventureWorks
GO
SELECT 
    [City]
    , COUNT([City]) AS CityCount
FROM 
    [Person].[Address]
GROUP BY [City]
HAVING COUNT([City]) > 1

-- Query con una chiamata a funzione nella condizione WHERE
USE AdventureWorks
GO
SELECT 
    [SalesOrderID], [SalesOrderDetailID], [ModifiedDate] 
FROM 
    [Sales].[SalesOrderDetail] 
WHERE 
    DATEDIFF(YEAR, ModifiedDate, GETDATE()) < 0
GO

CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ModifiedDate] 
ON [Sales].[SalesOrderDetail] ([ModifiedDate])
GO

SELECT 
    [SalesOrderID], [SalesOrderDetailID], [ModifiedDate] 
FROM 
    [Sales].[SalesOrderDetail] 
WHERE 
    ModifiedDate > GETDATE()
GO

DROP INDEX [IX_SalesOrderDetail_ModifiedDate] ON [Sales].[SalesOrderDetail]
GO

-- Caso con LIKE nella condizione WHERE
SELECT * FROM Production.Product
WHERE [Name] LIKE '%set%'

SELECT * FROM Production.Product
WHERE [Name] LIKE 'Chain%'

/***** Included columns *****/
SELECT 
    [sod].[ProductID],
    [sod].[OrderQty],
    [sod].[UnitPrice]
FROM 
    [Sales].[SalesOrderDetail] sod
WHERE 
    [sod].[ProductID] = 897

-- Creazione nuovo indice di copertura
IF EXISTS ( SELECT * FROM sys.indexes WHERE OBJECT_ID = OBJECT_ID(N'[Sales].[SalesOrderDetail]') AND name = N'IX_SalesOrderDetail_ProductID' )
    BEGIN
        EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'Sales', @level1type=N'TABLE',@level1name=N'SalesOrderDetail', @level2type=N'INDEX',@level2name=N'IX_SalesOrderDetail_ProductID'
        DROP INDEX [IX_SalesOrderDetail_ProductID] ON [Sales].[SalesOrderDetail]
    END
GO
CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID] 
ON [Sales].[SalesOrderDetail] ([ProductID] ASC)
INCLUDE ( [OrderQty], [UnitPrice] ) 
ON [PRIMARY]
GO

-- Ricrea l'indice originale
DROP INDEX [IX_SalesOrderDetail_ProductID] ON [Sales].[SalesOrderDetail]
GO
CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID] ON [Sales].[SalesOrderDetail]
(
	[ProductID] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Nonclustered index.' , @level0type=N'SCHEMA',@level0name=N'Sales', @level1type=N'TABLE',@level1name=N'SalesOrderDetail', @level2type=N'INDEX',@level2name=N'IX_SalesOrderDetail_ProductID'
GO

/***** Selettività degli indici *****/
USE AdventureWorks
GO
DBCC SHOW_STATISTICS('Sales.SalesOrderDetail', 'IX_SalesOrderDetail_ProductID') WITH DENSITY_VECTOR
GO

USE AdventureWorks
GO
SELECT 
    od.[SalesOrderDetailID],
    od.[SalesOrderID],
    od.[OrderQty],
    od.[LineTotal]
FROM 
    [Sales].[SalesOrderDetail] od
WHERE 
    od.[OrderQty] = 10

CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_OrderQty] 
ON [Sales].[SalesOrderDetail] ([OrderQty] ASC) ON [PRIMARY]
GO

DBCC SHOW_STATISTICS('Sales.SalesOrderDetail', 'IX_SalesOrderDetail_ProductID') WITH DENSITY_VECTOR
GO
DBCC SHOW_STATISTICS('Sales.SalesOrderDetail', 'IX_SalesOrderDetail_OrderQty') WITH DENSITY_VECTOR
Go

DROP INDEX [Sales].[SalesOrderDetail].[IX_SalesOrderDetail_OrderQty]
GO

--- Selettività, indici e statistiche
USE AdventureWorks
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NewOrders]') AND type in (N'U'))
DROP TABLE [dbo].[NewOrders]
GO
SELECT *
INTO dbo.NewOrders
FROM Sales.SalesOrderDetail
GO
CREATE INDEX IX_NewOrders_ProductID on [dbo].[NewOrders] (ProductID)
GO

-- Catturo Estimated Plan
SET SHOWPLAN_XML ON
GO
SELECT [OrderQty], [CarrierTrackingNumber]
FROM dbo.NewOrders
WHERE [ProductID] = 897
GO
SET SHOWPLAN_XML OFF
GO

BEGIN TRAN
    UPDATE dbo.NewOrders
    SET [ProductID] = 897
    WHERE [ProductID] BETWEEN 800 AND 900
    GO

    -- Actual Plan
    SELECT [OrderQty], [CarrierTrackingNumber]
    FROM dbo.NewOrders
    WHERE [ProductID] = 897
    GO
ROLLBACK TRAN
GO
DROP TABLE dbo.NewOrders
GO
/***** Tabelle temporanee, Table Variables e CTE *****/
USE AdventureWorks
GO

-- CTE
WITH cteTotalSales (SalesPersonID, NetSales) AS 
(
    SELECT SalesPersonID, ROUND(SUM(SubTotal), 2)
    FROM Sales.SalesOrderHeader 
    WHERE SalesPersonID IS NOT NULL
    GROUP BY SalesPersonID
)
SELECT 
    sp.FirstName + ' ' + sp.LastName AS FullName,
    sp.City + ', ' + StateProvinceName AS Location,
    ts.NetSales
FROM 
    Sales.vSalesPerson AS sp
    INNER JOIN cteTotalSales AS ts ON sp.BusinessEntityID = ts.SalesPersonID
ORDER BY 
    ts.NetSales DESC

WITH 
    cteTotalSales (SalesPersonID, NetSales) AS
    (
        SELECT SalesPersonID, ROUND(SUM(SubTotal), 2)
        FROM Sales.SalesOrderHeader
        WHERE 
            SalesPersonID IS NOT NULL
            --AND OrderDate BETWEEN '2003-01-01 00:00:00.000' 
            --AND '2003-12-31 23:59:59.000'
        GROUP BY 
            SalesPersonID
      ),
      cteTargetDiff (SalesPersonID, SalesQuota, QuotaDiff) AS
      (
        SELECT ts.SalesPersonID,
          CASE 
            WHEN sp.SalesQuota IS NULL THEN 0
            ELSE sp.SalesQuota
          END, 
          CASE 
            WHEN sp.SalesQuota IS NULL THEN ts.NetSales
            ELSE ts.NetSales - sp.SalesQuota
          END
        FROM cteTotalSales AS ts
          INNER JOIN Sales.SalesPerson AS sp ON ts.SalesPersonID = sp.BusinessEntityID
      )
SELECT 
    sp.FirstName + ' ' + sp.LastName AS FullName,
    sp.City,
    ts.NetSales,
    td.SalesQuota,
    td.QuotaDiff
FROM 
    Sales.vSalesPerson AS sp
    INNER JOIN cteTotalSales AS ts ON sp.BusinessEntityID = ts.SalesPersonID
    INNER JOIN cteTargetDiff AS td ON sp.BusinessEntityID = td.SalesPersonID
ORDER BY 
    ts.NetSales DESC

-- Tabella Temporanea Locale
CREATE TABLE #ProdottiOrdinati
(
    ID int IDENTITY(1,1),
    ProductID int,
    Qty int
)

INSERT INTO #ProdottiOrdinati(ProductID, Qty)
SELECT ProductID, SUM(OrderQty) AS Qty 
FROM [Sales].[SalesOrderDetail]
GROUP BY ProductID

SELECT * FROM #ProdottiOrdinati
GO
SELECT * FROM #ProdottiOrdinati
GO
SELECT * FROM #ProdottiOrdinati
GO

-- Tabella temporanea Globale
USE AdventureWorks
GO
CREATE TABLE ##ProdottiOrdinati
(
    ID int IDENTITY(1,1),
    ProductID int,
    Qty int
)

INSERT INTO ##ProdottiOrdinati(ProductID, Qty)
SELECT ProductID, SUM(OrderQty) AS Qty 
FROM [Sales].[SalesOrderDetail]
GROUP BY ProductID

SELECT * FROM ##ProdottiOrdinati
GO

-- Table Variable
DECLARE @ProdottiOrdinati TABLE
(
    ID int IDENTITY(1,1),
    ProductID int,
    Qty int
)

-- Inserimento dati nella table variable
INSERT INTO @ProdottiOrdinati(ProductID, Qty)
SELECT ProductID, SUM(OrderQty) AS Qty 
FROM [Sales].[SalesOrderDetail]
GROUP BY ProductID

-- Select data
SELECT * FROM @ProdottiOrdinati
 
-- Batch successivo
GO
SELECT * FROM @ProdottiOrdinati -- Errore

/*****  Hints *****/

--- Query Hints ---

-- Problema: C'è un sottosistema dischi lento, bisogna ridurre il numero di I/O
USE AdventureWorks
GO

SET STATISTICS IO ON
GO
SELECT
    s.[Name] AS StoreName
    , ct.[Name] AS ContactTypeName
    , p.[LastName] + ', ' + p.[FirstName] AS FullName
FROM    
    [Sales].[Store] s
    INNER JOIN [Sales].[Customer] c on s.BusinessEntityID = c.StoreID
    INNER JOIN [Person].[Person] p ON c.PersonID = p.BusinessEntityID
    INNER JOIN [Person].[BusinessEntityContact] bec ON c.PersonID = bec.PersonID
    INNER JOIN [Person].[ContactType] ct ON bec.ContactTypeID = ct.ContactTypeID   
-- OPTION (LOOP JOIN)
-- OPTION (MERGE JOIN)
-- OPTION (HASH JOIN)

-- MAXDOP

-- Numero di "Logical Processors"
SELECT 
    (cpu_count / hyperthread_ratio) AS PhysicalCPUs
    , cpu_count AS logicalCPUs   
FROM 
    sys.dm_os_sys_info

USE AdventureWorks
GO

EXEC sp_configure 'cost threshold for parallelism', 1
GO
RECONFIGURE WITH OVERRIDE
GO

SELECT  
    wo.[DueDate],
    MIN(wo.[OrderQty]) MinOrderQty,
    MIN(wo.[StockedQty]) MinStockedQty,
    MIN(wo.[ScrappedQty]) MinScrappedQty,
    MAX(wo.[OrderQty]) MaxOrderQty,
    MAX(wo.[StockedQty]) MaxStockedQty,
    MAX(wo.[ScrappedQty]) MaxScrappedQty
FROM    
    [Production].[WorkOrder] wo
GROUP BY 
    wo.[DueDate]
ORDER BY 
    wo.[DueDate]
-- OPTION (MAXDOP 1)

EXEC sp_configure 'cost threshold for parallelism', 5
GO
RECONFIGURE WITH OVERRIDE
GO

-- OPTIMIZE FOR
SELECT * FROM [Person].[Address] WHERE [City] = 'Newark'
SELECT * FROM [Person].[Address] WHERE [City] = 'London' -- Meno selettivo

DECLARE @City NVARCHAR(30)
SET @City = 'Newark'
SELECT * FROM [Person].[Address] WHERE [City]= @City
SET @City = 'London'
SELECT * FROM [Person].[Address] WHERE [City]= @City
OPTION  (OPTIMIZE FOR (@City = 'Newark'))

-- RECOMPILE

-- Esiste un Indice "IX_SalesOrderHeader_SalesPersonID" sulla tabella Sales.SalesOrderHeader
DECLARE @PersonId INT
SET @PersonId = 277
-- SELECT COUNT(*) FROM [Sales].[SalesOrderHeader] soh WHERE soh.SalesPersonID = @PersonId
SELECT  
    [soh].[SalesOrderNumber],
    [soh].[OrderDate],
    [soh].[SubTotal],
    [soh].[TotalDue]
FROM    
    [Sales].[SalesOrderHeader] soh
WHERE   
    [soh].[SalesPersonID] = @PersonId
-- OPTION (RECOMPILE)

SET @PersonId = 288 -- Più selettivo
-- SELECT COUNT(*) FROM [Sales].[SalesOrderHeader] soh WHERE soh.SalesPersonID = @PersonId
SELECT  
    [soh].[SalesOrderNumber],
    [soh].[OrderDate],
    [soh].[SubTotal],
    [soh].[TotalDue]
FROM    
    [Sales].[SalesOrderHeader] soh
WHERE   
    [soh].[SalesPersonID] = @PersonId
-- OPTION (RECOMPILE)

--- Join Hints ---

USE AdventureWorks
GO
SELECT  
    pm.[Name],
    pm.[CatalogDescription],
    p.[Name] AS ProductName,
    i.[Diagram]
FROM    
    [Production].[ProductModel] pm
    LEFT /* LOOP | MERGE */ JOIN [Production].[Product] p ON pm.[ProductModelID] = p.[ProductModelID]
    LEFT JOIN [Production].[ProductModelIllustration] pmi ON pm.[ProductModelID] = pmi.[ProductModelID]
    LEFT JOIN [Production].[Illustration] i ON pmi.[IllustrationID] = i.[IllustrationID]
WHERE   
    pm.[Name] LIKE '%Mountain%'
ORDER BY 
    pm.[Name]
GO

--- Table Hints ---
USE AdventureWorks
GO
SELECT  
    [de].[Name],
    [e].JobTitle,
    [p].[LastName] + ', ' + [p].[FirstName]
FROM    
    [HumanResources].[Department] de -- WITH (INDEX(PK_Department_DepartmentID))
    INNER JOIN [HumanResources].[EmployeeDepartmentHistory] edh ON de.[DepartmentID] = edh.[DepartmentID]
    INNER JOIN [HumanResources].[Employee] e ON edh.BusinessEntityID = e.BusinessEntityID
    INNER JOIN [Person].[Person] p ON e.[BusinessEntityID] = p.[BusinessEntityID]
WHERE   
    [de].[Name] LIKE 'P%'

/***** Locking *****/

SELECT resource_type, request_mode, resource_description
FROM sys.dm_tran_locks
WHERE resource_type <> 'DATABASE'

/***** T-SQL Enhancements *****/

-- OFFSET / FETCH NEXT

USE AdventureWorks
GO

-- Paginazione con CTE
DECLARE @PageNumber int = 10
DECLARE @PageSize int = 30
;WITH EmployeeCTE AS (
    SELECT 
        ROW_NUMBER() OVER(ORDER BY LastName, FirstName) AS RowNumber,
        p.BusinessEntityID, p.Title, p.FirstName, p.LastName
    FROM 
        Person.Person p
    WHERE 
        PersonType = 'EM'
)
SELECT 
    cte.BusinessEntityID, cte.Title, cte.FirstName, cte.LastName, e.EmailAddress
FROM 
    EmployeeCTE cte
    INNER JOIN Person.EmailAddress e ON cte.BusinessEntityID = e.BusinessEntityID
WHERE 
    cte.RowNumber BETWEEN (@PageNumber - 1) * @PageSize + 1 AND @PageNumber * @PageSize
GO

-- Paginazione con FETCH/OFFSET
DECLARE @PageNumber int = 10
DECLARE @PageSize int = 30
SELECT 
    p.BusinessEntityID, p.Title, p.FirstName, p.LastName, e.EmailAddress
FROM 
    Person.Person p
    INNER JOIN Person.EmailAddress e ON p.BusinessEntityID = e.BusinessEntityID
WHERE 
     PersonType = 'EM'
ORDER BY LastName, FirstName
OFFSET (@PageNumber - 1) * @PageSize ROWS 
FETCH NEXT @PageSize ROWS ONLY
GO

-- WINDOWING FUNCTIONS
USE AdventureWorks  
GO
SELECT 
    BusinessEntityID,
    CONCAT_WS(' ', FirstName, LastName) AS SellerName,
    TerritoryGroup,
    SalesLastYear
FROM
    Sales.vSalesPerson;
GO

-- OVER(), RANK()
SELECT 
    BusinessEntityID,
    CONCAT_WS(' ', FirstName, LastName) AS SellerName,
    TerritoryGroup,
    SalesLastYear
    --, SUM(SalesLastYear) OVER (PARTITION BY TerritoryGroup) AS SalesLastYearTerritory,
    -- , RANK() OVER(ORDER BY SalesLastYear DESC) AS [Rank]
FROM
    Sales.vSalesPerson;
GO

-- LAG
SELECT 
    BusinessEntityID,
    CONCAT_WS(' ', FirstName, LastName) AS SellerName
    , SalesLastYear
    -- Argomento: di quante righe andare indietro
    , LAG(SalesLastYear, 1) OVER(ORDER BY SalesLastYear) AS PrevSalesLastYear
FROM
    Sales.vSalesPerson;
GO

-- LEAD
SELECT 
    BusinessEntityID,
    CONCAT_WS(' ', FirstName, LastName) AS SellerName
    , SalesLastYear
    -- Argomento: di quante righe andare avanti
    , LEAD(SalesLastYear, 1) OVER(ORDER BY SalesLastYear) AS NextSalesLastYear
FROM
    Sales.vSalesPerson
GO

-- FIRST_VALUE e LAST_VALUE
SELECT 
    BusinessEntityID,
    CONCAT_WS(' ', FirstName, LastName) AS SellerName
    , TerritoryGroup
    , SalesLastYear
    , FIRST_VALUE(SalesLastYear) OVER(PARTITION BY TerritoryGroup ORDER BY TerritoryGroup) first_order_date
    , LAST_VALUE(SalesLastYear) OVER(PARTITION BY TerritoryGroup ORDER BY TerritoryGroup) last_order_date
FROM 
    Sales.vSalesPerson

-- TOP ... WITH TIES
USE AdventureWorks;
GO

SELECT 
    p.ProductNumber, COUNT(od.SalesOrderDetailID) AS NumeroOrdini
FROM 
    Sales.SalesOrderDetail od
    INNER JOIN Production.Product p ON od.ProductID = p.ProductID
GROUP BY 
    p.ProductNumber
ORDER BY 
    COUNT(od.SalesOrderDetailID)
GO

SELECT TOP(5) -- WITH TIES
    p.ProductNumber, COUNT(od.SalesOrderDetailID) AS NumeroOrdini
FROM 
    Sales.SalesOrderDetail od
    INNER JOIN Production.Product p ON od.ProductID = p.ProductID
GROUP BY 
    p.ProductNumber
ORDER BY 
    COUNT(od.SalesOrderDetailID) 
GO

-- STRING_SPLIT
DECLARE @frase NVARCHAR(400) = 'non sopporto la vostra mancanza di fede'  
SELECT [value]  
FROM STRING_SPLIT(@frase, ' ')  

DECLARE @IDProdotti nvarchar(500) = '1,2,3,4,316'
SELECT 
    p.* 
FROM 
    Production.Product p
    INNER JOIN STRING_SPLIT(@IDProdotti, ',') idp ON p.ProductID = idp.value

-- DATEFROMPARTS
SELECT DATEFROMPARTS (1974, 11, 10) AS Result;  

-- IIF e CHOOSE
DECLARE @a int = 45, @b int = 40;  
SELECT IIF(@a > @b, 'TRUE', 'FALSE') AS Result;  

SELECT CHOOSE (3, 'Alby', 'Boniz', 'Mario', 'Lilla') AS Result; 

USE AdventureWorks;  
GO  
SELECT 
    JobTitle AS Professione, 
    HireDate AS DataAssunzione, 
    CHOOSE(
        MONTH(HireDate),'Inverno','Inverno', 'Primavera','Primavera','Primavera','Estate','Estate','Estate','Autunno','Autunno','Autunno','Inverno'
    ) AS StagioneAssunzione  
FROM 
    HumanResources.Employee  
WHERE 
    HireDate >= DATEFROMPARTS(2005, 1, 1)
ORDER BY 
    YEAR(HireDate)

-- CONCAT e CONCAT_WS
SELECT CONCAT('Sono ', 'nato ', 'il ', 10, '/', '11', '/', 1974) AS DataDiNascita; 

SELECT 
    CONCAT_WS(',', ProductID, [Name], ProductNumber ) AS InfoProdotto  
FROM 
    Production.Product

-- EOMONTH
DECLARE @oggi DATETIME = GETDATE();  
SELECT 
    EOMONTH(@oggi) AS 'Ultimo giorno di questo mese'
    , EOMONTH(@oggi, 1) AS 'Ultimo giorno del mese prossimo' 
    , EOMONTH(@oggi, -1) AS 'Ultimo giorno del mese scorso'
GO  