SELECT 
	r.session_id,
	r.command,
	s.[text],
	r.start_time,
	r.percent_complete, 
    CAST(((DATEDIFF(s, r.start_time, GETDATE())) / 3600) as varchar) + ' hour(s), '
		+ CAST((DATEDIFF(s, r.start_time, GETDATE()) % 3600) / 60 as varchar) + ' min, '
		+ CAST((DATEDIFF(s, r.start_time, GETDATE()) % 60) as varchar) + ' sec' as running_time,
    CAST((r.estimated_completion_time / 3600000) as varchar) + ' hour(s), '
        + CAST((r.estimated_completion_time % 3600000) / 60000 as varchar) + ' min, '
        + CAST((r.estimated_completion_time % 60000) / 1000 as varchar) + ' sec' as est_time_to_go,
	DATEADD(SECOND, r.estimated_completion_time / 1000, GETDATE()) as est_completion_time 
FROM 
	sys.dm_exec_requests r
	CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) s
WHERE 
	r.command in (
		'RESTORE DATABASE', 
		'BACKUP DATABASE', 
		'RESTORE LOG', 
		'BACKUP LOG'
	)