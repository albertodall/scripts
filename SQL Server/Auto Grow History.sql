DECLARE @fn VARCHAR(1000)
SELECT @fn = t.[path] FROM sys.traces t WHERE t.is_default=1

SELECT te.name, t.DatabaseName, t.FileName, t.StartTime, t.ApplicationName  
FROM 
	fn_trace_gettable(@fn, default) AS t  
	INNER JOIN  sys.trace_events AS te ON t.EventClass = te.trace_event_id  
WHERE te.name LIKE '%Auto Grow'  
ORDER BY StartTime ASC


