USE tempdb
GO

-- Prepara il posto per l'albero (di solito, l'8 di dicembre)
 CREATE TABLE #AlberoDiNatale
( 
	oggetto VARCHAR(32) 
	, forma GEOMETRY 
); 

-- Monta l'albero e la stella
 INSERT INTO #AlberoDiNatale
 VALUES  
	('Pino'  , 'POLYGON((4 0, 0 0, 3 2, 1 2, 3 4, 1 4, 3 6, 2 6, 4 8, 6 6, 5 6, 7 4, 5 4, 7 2, 5 2, 8 0, 4 0))'), 
	('Base'  , 'POLYGON((2.5 0, 3 -1, 5 -1, 5.5 0, 2.5 0))'), 
	('Stella', 'POLYGON((4 7.5, 3.5 7.25, 3.6 7.9, 3.1 8.2, 3.8 8.2, 4 8.9, 4.2 8.2, 4.9 8.2, 4.4 7.9, 4.5 7.25, 4 7.5))') 
	 
-- Metti gli addobbi
DECLARE @pallina INT = 0, @x INT, @y INT 
WHILE (@pallina < 30)  
    BEGIN
		INSERT INTO #AlberoDiNatale
		VALUES ('Pallina' + CAST(@pallina AS VARCHAR(8)), GEOMETRY::Point(RAND() * 5 + 1.5, RAND() * 6, 0).STBuffer(0.3)) 
        SET @pallina = @pallina + 1
    END

-- Guarda l'albero
SELECT * FROM #AlberoDiNatale

-- Smonta l'albero (l'8 di gennaio)
DROP TABLE #AlberoDiNatale