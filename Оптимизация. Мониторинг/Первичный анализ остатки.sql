-- Выполняемые команды		
	-- 2005
		use master
		go
		select
		er.session_id,
		er.blocking_session_id,
		login_name,
		[host_name],
		DB_NAME(er.database_id) as	DBName,
		host_process_id,
		client_interface_name,
		es.[program_name],
		wait_time/1000 as [wait_time,s],
		last_wait_type,er.[status],wait_resource,command,
		  [Individual Query] = SUBSTRING (st.text,er.statement_start_offset/2, 
				 (CASE
					WHEN er.statement_end_offset = -1 THEN
		LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2 
					ELSE er.statement_end_offset
				  END -
		er.statement_start_offset)/2)
		,st.objectid
		,login_time,last_execution_time,last_request_start_time,last_request_end_time,
		cast (st.text as
		varchar(8000)) as ProcText,	
		er.open_transaction_count,
		execution_count as Q_execution_count,
		last_logical_reads as Q_last_logical_reads,last_logical_reads as
		Q_last_logical_reads,st.objectid,
		qp.query_plan
		,er.percent_complete as [% выполнено]
		,dateadd (ms, er.estimated_completion_time, getdate()) AS [Время завершения],
		creation_time as [Time plan compilation],
		qs.total_elapsed_time/1000000 as [Общее время выполнения, с],
		qs.total_worker_time/1000000 as [Общее время CPU, с],
		er.cpu_time/1000 as [CPU,s],
		er.logical_reads,
		er.row_count,
		er.reads,
		er.writes,
		qs.total_logical_reads [Total logical reads],
		qs.total_physical_reads [Total physical reads],
		qs.total_logical_writes [Total logical writes],		
		qs.execution_count,
		er.transaction_isolation_level,
		er.granted_query_memory as [Grant memory page count],
		es.memory_usage as [Memory page count usage],
		CASE es.transaction_isolation_level 
		WHEN 0 THEN 'Unspecified' 
		WHEN 1 THEN 'ReadUncommitted' 
		WHEN 2 THEN 'ReadCommitted' 
		WHEN 3 THEN 'Repeatable' 
		WHEN 4 THEN 'Serializable' 
		WHEN 5 THEN 'Snapshot' END AS TRANSACTION_ISOLATION_LEVEL 
		from sys.dm_exec_requests er 
		inner join sys.dm_exec_sessions es
		on er.session_id=es.session_id 
		left join sys.dm_exec_query_stats qs
		on
		er.sql_handle=qs.sql_handle
		and er.plan_handle=qs.plan_handle
		--and qs.last_execution_time=es.last_request_start_time
		--and er.query_hash=qs.query_hash
		--and er.query_plan_hash=qs.query_plan_hash
		and er.statement_start_offset=qs.statement_start_offset
		and er.statement_end_offset=qs.statement_end_offset
		outer apply sys.dm_exec_sql_text((er.sql_handle)) st
		outer apply sys.dm_exec_query_plan((er.plan_handle)) qp

		WHERE es.session_id>49 --AND es.session_id IN(160,298)
		--and last_wait_type <> 'ASYNC_NETWORK_IO'
		and last_wait_type NOT IN ('SP_SERVER_DIAGNOSTICS_SLEEP','BROKER_TASK_STOP','MISCELLANEOUS','HADR_WORK_QUEUE')
		and es.session_id<>@@spid order by start_time desc	

	
-- ***** ПРОВЕРИТЬ 2 запроса в момент блокировок *****
	-- ****** 1 *****
	select 
	--[now] = cast(getdate() as datetime), 
	er.start_time 
	, es.[host_name] 
	, es.[login_name] 
	, [db_name] = db_name(er.[database_id]) 
	, es.session_id 
	, er.[status] 
	, er.command 
	, es.[program_name] 
	--, [sql_command] = case when er.sql_handle is null then null else (select [text] from sys.dm_exec_sql_text(er.sql_handle)) end 
	--,[query_plan] = case when er.plan_handle is null then null else (select [query_plan] from sys.dm_exec_query_plan ([er].[plan_handle])) end 
	,er.statement_start_offset 
	, er.percent_complete 
	, cast(cast(er.estimated_completion_time as decimal(15,2))/1000/60 as decimal(10,2)) as estimated_completion_time_MINS 
	, er.[wait_resource] 
	, er.blocking_session_id 
	, es.[nt_user_name] 
	, er.[user_id] 
	, er.connection_id 
	, er.wait_type
	,er.transaction_isolation_level 
	from 
	sys.dm_exec_requests er 
	inner join 
	sys.dm_exec_sessions es 
	on es.[session_id] = er.[session_id] 
	--OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp] 
	where 
	--Вывод информации только по конкретной базе 
	er.database_id = db_id('kkp_prod') 
	order by er.start_time 
	--order by es.session_id 
	
	
	-- ****** 2 *****		
	SELECT 
	[owt].[session_id], 
	[owt].[wait_duration_ms], 
	[owt].[wait_type], 
	[owt].[blocking_session_id], 
	db_name([er].[database_id]) as DataBase_Name, 
	[es].[program_name], 
	[er].command, 
	[owt].[resource_description], 
	CASE [owt].[wait_type] 
	WHEN N'CXPACKET' THEN 
	RIGHT ([owt].[resource_description], 
	CHARINDEX (N'=', REVERSE ([owt].[resource_description])) - 1) 
	ELSE NULL 
	END AS [Node ID], 
	[est].text, 
	[eqp].[query_plan], 
	[er].[cpu_time], 
	[owt].[exec_context_id], 
	[ot].[scheduler_id] 
	FROM sys.dm_os_waiting_tasks [owt] 
	INNER JOIN sys.dm_os_tasks [ot] ON 
	[owt].[waiting_task_address] = [ot].[task_address] 
	INNER JOIN sys.dm_exec_sessions [es] ON 
	[owt].[session_id] = [es].[session_id] 
	INNER JOIN sys.dm_exec_requests [er] ON 
	[es].[session_id] = [er].[session_id] 
	OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est] 
	OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp] 
	WHERE 
	[es].[is_user_process] = 1 
	ORDER BY 
	[owt].[session_id], 
	[owt].[exec_context_id]; 
	GO 
	
-- Использование памяти по таблицам
	SELECT
	objects.name AS object_name,
	objects.type_desc AS object_type_description,
	COUNT(*) AS buffer_cache_pages,
	COUNT(*) * 8 / 1024  AS buffer_cache_used_MB
	FROM sys.dm_os_buffer_descriptors
	INNER JOIN sys.allocation_units
	ON allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
	INNER JOIN sys.partitions
	ON ((allocation_units.container_id = partitions.hobt_id AND type IN (1,3))
	OR (allocation_units.container_id = partitions.partition_id AND type IN (2)))
	INNER JOIN sys.objects
	ON partitions.object_id = objects.object_id
	WHERE allocation_units.type IN (1,2,3)
	AND objects.is_ms_shipped = 0
	AND dm_os_buffer_descriptors.database_id = DB_ID()
	GROUP BY objects.name,
			 objects.type_desc
	ORDER BY COUNT(*) DESC;

-- Использование памяти по индексам
	SELECT
		indexes.name AS index_name,
		objects.name AS object_name,
		objects.type_desc AS object_type_description,
		COUNT(*) AS buffer_cache_pages,
		COUNT(*) * 8 / 1024  AS buffer_cache_used_MB
	FROM sys.dm_os_buffer_descriptors
	INNER JOIN sys.allocation_units
	ON allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
	INNER JOIN sys.partitions
	ON ((allocation_units.container_id = partitions.hobt_id AND type IN (1,3))
	OR (allocation_units.container_id = partitions.partition_id AND type IN (2)))
	INNER JOIN sys.objects
	ON partitions.object_id = objects.object_id
	INNER JOIN sys.indexes
	ON objects.object_id = indexes.object_id
	AND partitions.index_id = indexes.index_id
	WHERE allocation_units.type IN (1,2,3)
	AND objects.is_ms_shipped = 0
	AND dm_os_buffer_descriptors.database_id = DB_ID()
	GROUP BY indexes.name,
			 objects.name,
			 objects.type_desc
	ORDER BY COUNT(*) DESC;
	
