SET NOCOUNT ON;
WITH vStats(object_id, table_column_id, index_name )
AS 
( 
    SELECT 
        o.object_id AS object_id
        ,  ic.column_id AS table_column_id
        , i.name
    FROM 
        sys.indexes             AS i
        JOIN sys.objects        AS o    ON i.object_id = o.object_id
        JOIN sys.stats          AS st   ON i.object_id = st.object_id AND i.name = st.name
        JOIN sys.index_columns  AS ic   ON i.index_id = ic.index_id AND i.object_id = ic.object_id
    WHERE 
        o.is_ms_shipped = 0 
        AND i.has_filter = 0 
        AND ic.index_column_id = 1 
)
SELECT 
    QUOTENAME( SCHEMA_NAME( o.schema_id )) + '.' + QUOTENAME( o.name ) AS [Table], 
    s.name AS [Statistic To Remove], 
    vStats.index_name AS [Index on Table]
FROM 
    sys.stats AS s
    JOIN sys.stats_columns  AS sc   ON s.stats_id = sc.stats_id AND s.object_id = sc.object_id
    JOIN sys.objects        AS o    ON sc.object_id = o.object_id
    JOIN sys.columns        AS c    ON sc.object_id = c.object_id AND sc.column_id = c.column_id
    JOIN vStats                     ON o.object_id = vStats.object_id AND vStats.table_column_id = c.column_id
WHERE 
    s.auto_created = 1 
    AND s.has_filter = 0;
