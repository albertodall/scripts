-- Get current Report Server subscriptions
SELECT
	s.[Description]
	, s.laststatus
	, c.[Path]
	, c.Name 
	, LastRunTime 
	, ScheduleID
FROM    
	ReportServer.dbo.subscriptions s
	INNER JOIN ReportServer.dbo.Users u ON s.ownerid = u.userid
	INNER JOIN ReportServer.dbo.[Catalog] c ON s.report_oid = c.itemid
	INNER JOIN ReportServer.dbo.ReportSchedule rs ON rs.SubscriptionID = s.SubscriptionID

-- Manually execute a Report subscription
-- Copy the command shown in the output, and execute it in a new query window
SELECT 
	'exec sp_start_job @job_name = ''' + cast(j.name as varchar(40)) + '''' 
FROM
	msdb.dbo.sysjobs j  
	INNER JOIN msdb.dbo.sysjobsteps js on js.job_id = j.job_id 
	INNER JOIN [ReportServer].[dbo].[Subscriptions] s on js.command like '%' + cast(s.subscriptionid as varchar(40)) + '%' 
