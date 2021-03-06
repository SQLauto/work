-- Было всё хорошо, стало плохо
	- Изменение кода
	- Обслуживание

-- Health Check
	sp_Blitz

-- Кто кого блочит

	SELECT DB_NAME(pr1.dbid) AS 'DB'
		  ,pr1.spid AS 'ID жертвы'
		  ,RTRIM(pr1.loginame) AS 'Login жертвы'      
		  ,pr1.waittime/1000 as 'Время ожидания жертвы, sec'
		  ,pr2.spid AS 'ID виновника'
		  ,RTRIM(pr2.loginame) AS 'Login виновника'
		  ,pr1.hostname as 'HostName жертвы'
		  ,pr2.hostname as 'HostName вновника'
		  ,pr1.program_name AS 'программа жертвы'
		  ,pr2.program_name AS 'программа виновника'
		  ,txt.[text] AS 'Запрос виновника'
		  ,pr1_txt.[text] AS 'Запрос жертвы'
		  ,pr1.login_time
		  ,pr1.last_batch
		  ,GETDATE() as 'Время проблемы'
		   INTO #blocking_info
	FROM   MASTER.dbo.sysprocesses pr1(NOLOCK)
		   JOIN MASTER.dbo.sysprocesses pr2(NOLOCK)
				ON  (pr2.spid = pr1.blocked) 
		   OUTER APPLY sys.[dm_exec_sql_text](pr2.[sql_handle]) AS txt
		   OUTER APPLY sys.[dm_exec_sql_text](pr1.[sql_handle]) AS pr1_txt
	WHERE  pr1.blocked <> 0

	SELECT * FROM #blocking_info

	SELECT spid,loginame,lastwaittype,DB_NAME(er.[dbid]) as [DB_NAME],[status],cmd,hostname,[program_name],cpu,physical_io,login_time,last_batch,[text],GETDATE() as 'Время проблемы' FROM sys.sysprocesses er
	left join sys.dm_exec_query_stats qs on er.sql_handle=qs.sql_handle
	outer apply sys.dm_exec_sql_text((er.sql_handle)) st
	WHERE spid IN (SELECT DISTINCT [ID виновника] FROM #blocking_info)

	DROP TABLE #blocking_info

-- Выполняемые команды
	
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
		last_wait_type,
		[wt].wait_info,
		er.[status],
		wait_resource,command,
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
		cast(pln.query_plan as xml) as [Individual Query Plan]	
		,[qmg].query_cost	
		,er.open_transaction_count,
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
		qs.total_rows [Rows return],
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

		-- Оба LEFT JOIN можно удалить если не нужны подробности wait_type и query_cost
		LEFT JOIN [sys].[dm_exec_query_memory_grants] [qmg] ON [er].[session_id] = [qmg].[session_id] AND [er].[request_id] = [qmg].[request_id]
		
		LEFT JOIN ( SELECT DISTINCT [wait].[session_id] ,
			            ( SELECT    [waitwait].[wait_type] + N' ('
			                        + CAST(SUM([waitwait].[wait_duration_ms]) AS NVARCHAR(128))
			                        + N' ms) '
			                FROM      [sys].[dm_os_waiting_tasks] AS [waitwait]
			                WHERE     [waitwait].[session_id] = [wait].[session_id]
			                GROUP BY  [waitwait].[wait_type]
			                ORDER BY  SUM([waitwait].[wait_duration_ms]) DESC
			            FOR
			                XML PATH('') ) AS [wait_info]
					 FROM    [sys].[dm_os_waiting_tasks] AS [wait] ) AS [wt] ON [es].[session_id] = [wt].[session_id]

		outer apply sys.dm_exec_sql_text((er.sql_handle)) st
		outer apply sys.dm_exec_query_plan((er.plan_handle)) qp
		outer APPLY sys.dm_exec_text_query_plan(er.plan_handle,
		er.statement_start_offset
		, er.statement_end_offset ) pln
		WHERE es.session_id>49 --AND es.session_id IN(160,298)
		--and last_wait_type <> 'ASYNC_NETWORK_IO'
		and last_wait_type NOT IN ('SP_SERVER_DIAGNOSTICS_SLEEP','BROKER_TASK_STOP','MISCELLANEOUS','HADR_WORK_QUEUE')
		and es.session_id<>@@spid order by start_time desc	

			
	-- Lock summary
		SELECT dbid=database_id, objectname=object_name(s.object_id),
		indexname=i.name, i.index_id, row_lock_count, row_lock_wait_count,
		[block %]= CAST (100.0 * row_lock_wait_count / (1 + row_lock_count) AS NUMERIC(15,2)),
		row_lock_wait_in_ms,
		[avg row lock waits in ms]= CAST (1.0 * row_lock_wait_in_ms / (1 + row_lock_wait_count) AS NUMERIC(15,2))
		FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) AS s
		INNER JOIN sys.indexes AS i
		ON i.object_id = s.object_id
		WHERE objectproperty(s.object_id,'IsUserTable') = 1
		AND i.index_id = s.index_id
		ORDER BY row_lock_wait_count DESC

	-- All lock in DB
		SELECT request_session_id, DB_NAME(resource_database_id) AS [Database], 
		resource_type, resource_subtype, request_type, request_mode, 
		resource_description, request_mode, request_owner_type
		FROM sys.dm_tran_locks
		WHERE request_session_id > 50
		AND resource_database_id = DB_ID()
		AND request_session_id <> @@SPID
		ORDER BY request_session_id;	
		
		
	-- ***** Узнать какой ресурс ожидает запрос *****
		--OBJECT: 7:1467152272:0 

			SELECT object_name(1467152272)

		-- Key: 7:72057594068008960 (dbbb80a5050f)
			- A keylock affects all rows that match the given predicate 
			SELECT 
				 o.name AS TableName, 
				i.name AS IndexName,
				SCHEMA_NAME(o.schema_id) AS SchemaName
				FROM sys.partitions p JOIN sys.objects o ON p.OBJECT_ID = o.OBJECT_ID 
				JOIN sys.indexes i ON p.OBJECT_ID = i.OBJECT_ID  AND p.index_id = i.index_id 
				WHERE p.hobt_id = 72057594068008960
				
				-- Если хотим узнать hash строки, то надо выполнить до её изменения 
				SELECT * FROM dbo.Srv_Svc (NOLOCK) WHERE %%lockres%% = '(1467152272)';

		-- Page 
			DBCC traceon (3604)
			GO
			DBCC page (68, 1, 492478) --Database_id,file_id,page_id 
			
-- Вместо DBCC OPENTRAN()/Открытые транзакции
	SELECT DB_NAME(dt.database_id),
	CASE dt.database_transaction_state
		WHEN 1  THEN 'Not initialized'
		WHEN 3  THEN  'initialized, but not producing log records'
		WHEN 4  THEN  'Producing log records'
		WHEN 5  THEN  'Prepared'
		WHEN 10  THEN  'Committed'
		WHEN 11  THEN  'Rolled back'
		WHEN 12  THEN  'Commit in process' END
		,at.name
	,st.session_id
	,es.[host_name]
	,es.[program_name]
	,ec.connect_time
	,es.login_time
	,es.last_request_start_time
	,es.last_request_end_time
	,es.cpu_time
	,es.logical_reads
	,es.reads
	,es.writes
	,est.[text]
	FROM sys.dm_tran_database_transactions dt 
	FULL JOIN sys.dm_tran_session_transactions st ON dt.transaction_id = st.transaction_id
	FULL JOIN sys.dm_tran_active_transactions at ON dt.transaction_id = at.transaction_id
	FULL JOIN sys.dm_exec_connections ec ON ec.session_id = st.session_id
	FULL JOIN sys.dm_exec_sessions es ON es.session_id = st.session_id
	outer apply sys.dm_exec_sql_text((ec.most_recent_sql_handle)) est
	WHERE st.session_id IS NOT NULL
	
	-- Открытые транзакции для таблиц в памяти
		SELECT xtp_transaction_id ,
		transaction_id ,
		session_id ,
		begin_tsn ,
		end_tsn ,
		state_desc
		FROM sys.dm_db_xtp_transactions
		WHERE transaction_id > 0;

	
-- Загрузка провессора/загрузка CPU
	;with
	not_idle as (select COUNT(*) AS not_idle FROM   sys.dm_os_schedulers WHERE scheduler_id<255 AND is_online=1 AND is_idle=0),
	idle as (select COUNT(*) AS idle FROM   sys.dm_os_schedulers WHERE scheduler_id<255 AND is_online=1 /*AND is_idle=1*/)
	SELECT 100.*not_idle/(idle/*+not_idle*/) FROM idle,not_idle

	-- какой процессор что делает
		SELECT DB_NAME(ISNULL(s.dbid,1)) AS [Имя базы данных],
			   c.session_id AS [ID сессии],
			   t.scheduler_id AS [Номер процессора],
			   s.text AS [Текст SQL-запроса]
		  FROM sys.dm_exec_connections AS c
		  CROSS APPLY master.sys.dm_exec_sql_text(c.most_recent_sql_handle) AS s
		  JOIN sys.dm_os_tasks t ON t.session_id = c.session_id AND
									t.task_state = 'RUNNING' AND
									ISNULL(s.dbid,1) > 4
		  ORDER BY c.session_id DESC
		 
		
	-- История использования процессора/использование cpu/cpu load
		DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info WITH (NOLOCK)); 

		SELECT TOP(256) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
					   SystemIdle AS [System Idle Process], 
					   100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
						DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
		 FROM (SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
					 record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
					 AS [SystemIdle], 
					 record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') 
					AS [SQLProcessUtilization], [timestamp] 
		  FROM (SELECT [timestamp], CONVERT(xml, record) AS [record] 
					FROM sys.dm_os_ring_buffers WITH (NOLOCK)
					WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
					AND record LIKE N'%<SystemHealth>%') AS x) AS y 
			 ORDER BY record_id DESC OPTION (RECOMPILE);
			
-- Background process
	 select 
            tblSysProcess.cmd
        , tblSysProcess.physical_io IOUsage
        , tblSysProcess.cpu as CPUusage
        , tblSysProcess.waittype as waitType
        , tblSysProcess.waittime as waitTime
        , tblSysProcess.lastwaittype as lastWaitType
        , tblSysProcess.waitResource as waitResource
        , case
                when (dbid > 0) then db_name(dbid) 
                else ''
            end as dbName
        , memusage as memUsage
        , status
       from  master.dbo.sysprocesses tblSysProcess
       where 
              (
                  --background process    
                  (tblSysProcess.spid < 50)
              )

-- Посмотреть ожидание всех подключённых процессов
	USE master
	SELECT * FROM SYSPROCESSES
	ORDER BY lastwaittype
	
-- Информация о сумме всех ожиданий сессии/ session waits
	- Начиная с SQL Server 2016
		SELECT * FROM sys.dm_exec_session_wait_stats WHERE session_id = 74
		ORDER BY wait_time_ms DESC
	
-- Сколько сессий на каждой БД
	SELECT DB_NAME(p.dbid) db, COUNT(*) quantity 
	FROM master.dbo.sysprocesses p 
	WHERE p.spid > 50 
	group by DB_NAME(p.dbid) 
	ORDER BY 1
	 

	SELECT db_name(l.resource_database_id) db, COUNT(*) quantity 
	FROM sys.dm_tran_locks l 
	GROUP BY db_name(l.resource_database_id) 
	ORDER BY 1
		
		
-- Какие команды на каком процессоре работают?
	
    SELECT DB_NAME(ISNULL(s.dbid,1)) AS [Имя базы данных]
			  , c.session_id              AS [ID сессии]
			  , t.scheduler_id            AS [Номер процессора]
			  , s.text                    AS [Текст SQL-запроса]
		   FROM sys.dm_exec_connections   AS c
	CROSS APPLY master.sys.dm_exec_sql_text(c.most_recent_sql_handle) AS s
		   JOIN sys.dm_os_tasks t
			 ON t.session_id = c.session_id
			AND t.task_state = 'RUNNING'
			AND ISNULL(s.dbid,1) > 4
	   ORDER BY c.session_id DESC
	 
	
-- Основные ожидания в CPU или ресурсах?
	USE master
	GO
	--DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);
	--GO
	WITH ByWaitTypes([Тип ожидания], [ожидания сигнала %], [ожидания ресурса %], [ожидания ms]) AS
	(
	SELECT TOP 20 wait_type
	   , cast(100.0 * sum(signal_wait_time_ms)/sum(wait_time_ms) AS NUMERIC (20,2))
	   , cast(100.0 * sum(wait_time_ms - signal_wait_time_ms)/sum(wait_time_ms) AS NUMERIC(20,2))
	   , sum(wait_time_ms)
	FROM sys.dm_os_wait_stats
	WHERE wait_time_ms <> 0
	GROUP BY wait_type
	ORDER BY sum(wait_time_ms) DESC
	)
	SELECT TOP 1 'Тип ожидания' = N'BCE!'
	   , 'ожидания сигнала %' = (SELECT cast(100.0 * sum(signal_wait_time_ms)/
		sum (wait_time_ms) AS NUMERIC (20,2)) FROM sys.dm_os_wait_stats)
	   , 'ожидания ресурса %' =(SELECT cast(100.0 * sum(wait_time_ms - signal_wait_time_ms)/
		sum(wait_time_ms) AS NUMERIC(20,2)) FROM sys.dm_os_wait_stats)
	   , 'ожидания ms' =(SELECT sum(wait_time_ms) FROM sys.dm_os_wait_stats)
	FROM sys.dm_os_wait_stats
	UNION
	SELECT [Тип ожидания], [ожидания сигнала %], [ожидания ресурса %], [ожидания ms]
	FROM ByWaitTypes
	ORDER BY [ожидания ms] DESC

-- VLF
	- Если функция DBCC LOGINFO возвращает больше 50-200, то исправить ситуацию (лучше делать в момент наименьшей активности)
		1. Сделайте backup лога
		2. DBCC SHRINKFILE(transactionloglogicalfilename, TRUNCATEONLY)
		3. Увеличте файл журнала до нужного размера ALTER DATABASE databasename MODIFY FILE ( NAME = transactionloglogicalfilename, SIZE = newtotalsize)

-- Последние backup
	select
	  database_name,
	  MAX(backup_finish_date) as Last_backup_start_date,
	  max(backup_finish_date) as Last_backup_finish_date,
			case when [type]= 'D' then '1_Full Backup'
				 when [type] = 'I' then '2_Diff Backup'
				 when [type] = 'L' then '3_Log Backup'
				 end as [Backup TYPE],
	  count (1) as 'Count of backups',
	  (SELECT bm1.physical_device_name FROM msdb..backupmediafamily as bm1 WHERE bm1.media_set_id = MAX(bs.media_set_id)) as [path],
	  (SELECT CAST(bs2.backup_size/1024/1024 as int) FROM msdb..backupset as bs2 WHERE bs2.backup_set_id = MAX(bs.backup_set_id)) as [size]
	from msdb..backupset bs
	group by database_name,[type]
	order by database_name,[Backup TYPE] --desc --, Last_backup_finish_date
	go 

-- Задержки файловой системы для файлов БД (за всё время)/использование диска
	SELECT DB_NAME(dm_io_virtual_file_stats.database_id) AS [Database Name], dm_io_virtual_file_stats.file_id,f.name,f.physical_name, io_stall_read_ms, num_of_reads,
	CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],io_stall_write_ms, 
	num_of_writes,CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],
	io_stall_read_ms + io_stall_write_ms AS [io_stalls], num_of_reads + num_of_writes AS [total_io],
	CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) 
	AS [avg_io_stall_ms]
	--INTO virtual_file_stats
	FROM sys.dm_io_virtual_file_stats(null,null) INNER JOIN sys.master_files as f ON dm_io_virtual_file_stats.database_id = f.database_id AND dm_io_virtual_file_stats.file_id = f.file_id
	ORDER BY io_stalls DESC,avg_io_stall_ms DESC;
	
	-- Текущие ожидания работы с файлами (текущие)
		SELECT
			COUNT (*) AS [PendingIOs],
			DB_NAME ([vfs].[database_id]) AS [DBName],
			[mf].[name] AS [FileName],
			[mf].[type_desc] AS [FileType],
			SUM ([pior].[io_pending_ms_ticks]) AS [TotalStall]
		FROM sys.dm_io_pending_io_requests AS [pior]
		JOIN sys.dm_io_virtual_file_stats (NULL, NULL) AS [vfs]
			ON [vfs].[file_handle] = [pior].[io_handle]
		JOIN sys.master_files AS [mf]
			ON [mf].[database_id] = [vfs].[database_id]
			AND [mf].[file_id] = [vfs].[file_id]
		WHERE
		   [pior].[io_pending] = 1
		GROUP BY [vfs].[database_id], [mf].[name], [mf].[type_desc]
		ORDER BY [vfs].[database_id], [mf].[name];
		
	-- Замер задержек IO за определённый период
		 
		IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
			WHERE [name] = N'##SQLskillsStats1')
			DROP TABLE [##SQLskillsStats1];
		 
		IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
			WHERE [name] = N'##SQLskillsStats2')
			DROP TABLE [##SQLskillsStats2];
		GO
		 
		SELECT [database_id], [file_id], [num_of_reads], [io_stall_read_ms],
			   [num_of_writes], [io_stall_write_ms], [io_stall],
			   [num_of_bytes_read], [num_of_bytes_written], [file_handle]
		INTO ##SQLskillsStats1
		FROM sys.dm_io_virtual_file_stats (NULL, NULL);
		GO
		 
		WAITFOR DELAY '00:03:00';
		GO
		 
		SELECT [database_id], [file_id], [num_of_reads], [io_stall_read_ms],
			   [num_of_writes], [io_stall_write_ms], [io_stall],
			   [num_of_bytes_read], [num_of_bytes_written], [file_handle]
		INTO ##SQLskillsStats2
		FROM sys.dm_io_virtual_file_stats (NULL, NULL);
		GO
		 
		WITH [DiffLatencies] AS
		(SELECT
		-- Files that weren't in the first snapshot
				[ts2].[database_id],
				[ts2].[file_id],
				[ts2].[num_of_reads],
				[ts2].[io_stall_read_ms],
				[ts2].[num_of_writes],
				[ts2].[io_stall_write_ms],
				[ts2].[io_stall],
				[ts2].[num_of_bytes_read],
				[ts2].[num_of_bytes_written]
			FROM [##SQLskillsStats2] AS [ts2]
			LEFT OUTER JOIN [##SQLskillsStats1] AS [ts1]
				ON [ts2].[file_handle] = [ts1].[file_handle]
			WHERE [ts1].[file_handle] IS NULL
		UNION
		SELECT
		-- Diff of latencies in both snapshots
				[ts2].[database_id],
				[ts2].[file_id],
				[ts2].[num_of_reads] - [ts1].[num_of_reads] AS [num_of_reads],
				[ts2].[io_stall_read_ms] - [ts1].[io_stall_read_ms] AS [io_stall_read_ms],
				[ts2].[num_of_writes] - [ts1].[num_of_writes] AS [num_of_writes],
				[ts2].[io_stall_write_ms] - [ts1].[io_stall_write_ms] AS [io_stall_write_ms],
				[ts2].[io_stall] - [ts1].[io_stall] AS [io_stall],
				[ts2].[num_of_bytes_read] - [ts1].[num_of_bytes_read] AS [num_of_bytes_read],
				[ts2].[num_of_bytes_written] - [ts1].[num_of_bytes_written] AS [num_of_bytes_written]
			FROM [##SQLskillsStats2] AS [ts2]
			LEFT OUTER JOIN [##SQLskillsStats1] AS [ts1]
				ON [ts2].[file_handle] = [ts1].[file_handle]
			WHERE [ts1].[file_handle] IS NOT NULL)
		SELECT
			DB_NAME ([vfs].[database_id]) AS [DB],
			LEFT ([mf].[physical_name], 2) AS [Drive],
			[mf].[type_desc],
			[num_of_reads] AS [Reads],
			[num_of_writes] AS [Writes],
			[ReadLatency(ms)] =
				CASE WHEN [num_of_reads] = 0
					THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END,
			[WriteLatency(ms)] =
				CASE WHEN [num_of_writes] = 0
					THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END,
			/*[Latency] =
				CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
					THEN 0 ELSE ([io_stall] / ([num_of_reads] + [num_of_writes])) END,*/
			[AvgBPerRead] =
				CASE WHEN [num_of_reads] = 0
					THEN 0 ELSE ([num_of_bytes_read] / [num_of_reads]) END,
			[AvgBPerWrite] =
				CASE WHEN [num_of_writes] = 0
					THEN 0 ELSE ([num_of_bytes_written] / [num_of_writes]) END,
			/*[AvgBPerTransfer] =
				CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
					THEN 0 ELSE
						(([num_of_bytes_read] + [num_of_bytes_written]) /
						([num_of_reads] + [num_of_writes])) END,*/
			[mf].[physical_name]
		FROM [DiffLatencies] AS [vfs]
		JOIN sys.master_files AS [mf]
			ON [vfs].[database_id] = [mf].[database_id]
			AND [vfs].[file_id] = [mf].[file_id]
		-- ORDER BY [ReadLatency(ms)] DESC
		ORDER BY [WriteLatency(ms)] DESC;
		GO
		 
		-- Cleanup
		IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
			WHERE [name] = N'##SQLskillsStats1')
			DROP TABLE [##SQLskillsStats1];
		 
		IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
			WHERE [name] = N'##SQLskillsStats2')
			DROP TABLE [##SQLskillsStats2];
		GO
		 
-- Использование процессора в разрезе БД
	WITH DB_CPU_Stats
	AS
	(SELECT DatabaseID, DB_Name(DatabaseID) AS [Database Name], SUM(total_worker_time) AS [CPU_Time_Ms]
	 FROM sys.dm_exec_query_stats AS qs
	 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
				  FROM sys.dm_exec_plan_attributes(qs.plan_handle)
				  WHERE attribute = N'dbid') AS F_DB
	 GROUP BY DatabaseID)
	SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [CPU Rank],
		   [Database Name], [CPU_Time_Ms] AS [CPU Time (ms)], 
		   CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPU Percent]
	FROM DB_CPU_Stats
	WHERE DatabaseID <> 32767 -- ResourceDB
	ORDER BY [CPU Rank] OPTION (RECOMPILE);

-- Задержки файлов логов
	- рекомендовано чтобы время отклика долговременного носителя журнала было в диапазоне от 1ms до 5ms.		
		SELECT      (wait_time_ms - signal_wait_time_ms) / waiting_tasks_count AS [Время отклика долговременного носителя журнала (ms)] 
					  ,    max_wait_time_ms AS [Максимальное время ожидания (ms)]
		FROM        sys.dm_os_wait_stats
		WHERE       wait_type = 'WRITELOG' AND waiting_tasks_count > 0;
	
-- Тестирование достаточности памяти/экспресс тестирование памяти
	WITH    RingBuffer
          AS (SELECT    CAST(dorb.record AS XML) AS xRecord,
                        dorb.TIMESTAMP
              FROM      sys.dm_os_ring_buffers AS dorb
              WHERE     dorb.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
             )
    SELECT  xr.value('(ResourceMonitor/Notification)[1]', 'varchar(75)') AS RmNotification,
            xr.value('(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint') AS IndicatorsProcess,
            xr.value('(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint') AS IndicatorsSystem,
            DATEADD(ss,
                    (-1 * ((dosi.cpu_ticks / CONVERT (FLOAT, (dosi.cpu_ticks / dosi.ms_ticks)))
                           - rb.TIMESTAMP) / 1000), GETDATE()) AS RmDateTime,
            xr.value('(MemoryNode/TargetMemory)[1]', 'bigint') AS TargetMemory,
            xr.value('(MemoryNode/ReserveMemory)[1]', 'bigint') AS ReserveMemory,
            xr.value('(MemoryNode/CommittedMemory)[1]', 'bigint')/1024 AS CommitedMemory,
            xr.value('(MemoryNode/SharedMemory)[1]', 'bigint') AS SharedMemory,
            xr.value('(MemoryNode/PagesMemory)[1]', 'bigint') AS PagesMemory,
            xr.value('(MemoryRecord/MemoryUtilization)[1]', 'bigint') AS MemoryUtilization,
            xr.value('(MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') AS TotalPhysicalMemory,
            xr.value('(MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS AvailablePhysicalMemory,
            xr.value('(MemoryRecord/TotalPageFile)[1]', 'bigint') AS TotalPageFile,
            xr.value('(MemoryRecord/AvailablePageFile)[1]', 'bigint') AS AvailablePageFile,
            xr.value('(MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') AS TotalVirtualAddressSpace,
            xr.value('(MemoryRecord/AvailableVirtualAddressSpace)[1]',
                     'bigint') AS AvailableVirtualAddressSpace,
            xr.value('(MemoryRecord/AvailableExtendedVirtualAddressSpace)[1]',
                     'bigint') AS AvailableExtendedVirtualAddressSpace
    FROM    RingBuffer AS rb
            CROSS APPLY rb.xRecord.nodes('Record') record (xr)
            CROSS JOIN sys.dm_os_sys_info AS dosi
    ORDER BY RmDateTime DESC;
	
-- Использование памяти по БД/Распределение памяти по Базам
	WITH AggregateBufferPoolUsage
	AS
	(SELECT DB_NAME(database_id) AS [Database Name],
	CAST(COUNT(*) * 8/1024.0 AS DECIMAL (10,2))  AS [CachedSize]
	FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
	WHERE database_id > 4 -- system databases
	AND database_id <> 32767 -- ResourceDB
	GROUP BY DB_NAME(database_id))
	SELECT ROW_NUMBER() OVER(ORDER BY CachedSize DESC) AS [Buffer Pool Rank], [Database Name], CachedSize AS [Cached Size (MB)],
		   CAST(CachedSize / SUM(CachedSize) OVER() * 100.0 AS DECIMAL(5,2)) AS [Buffer Pool Percent]
	FROM AggregateBufferPoolUsage
	ORDER BY [Buffer Pool Rank] OPTION (RECOMPILE);
	
	-- Какие запросы требуют много памяти, но не использует её
		SELECT * FROM sys.dm_exec_query_memory_grants er
			outer apply sys.dm_exec_sql_text((er.sql_handle)) st
			outer apply sys.dm_exec_query_plan((er.plan_handle)) qp		

	
-- Использование памяти планами
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	select COUNT(*),CASE WHEN usecounts =1 then 1 WHEN usecounts between 1 and 10 then 10 WHEN usecounts > 10 THEN 100 END  as USAGE from sys.dm_exec_cached_plans
	GROUP BY CASE WHEN usecounts =1 then 1 WHEN usecounts between 1 and 10 then 10 WHEN usecounts > 10 THEN 100 END
	
-- Проверить dm_os_schedulers
	- These are the processes that manage the worker processes
		SELECT  COUNT(*)
		FROM    sys.dm_os_schedulers AS dos
		WHERE   dos.is_idle = 0;
		
	-- Проверить активных worker
		SELECT  COUNT(*)
		FROM    sys.dm_os_workers AS dow
		WHERE   state = 'RUNNING';		
			
-- Нагрузка на все БД/использование БД (с момента рестарта сервера)
	SELECT DB_NAME(saf.dbid) AS [База данных],
	   saf.name AS [Логическое имя],
	   vfs.BytesRead/1048576 AS [Прочитано (Мб)],
	   vfs.BytesWritten/1048576 AS [Записано (Мб)],
	   saf.filename AS [Путь к файлу]
	FROM master..sysaltfiles AS saf
	JOIN ::fn_virtualfilestats(NULL,NULL) AS vfs ON vfs.dbid = saf.dbid AND
												  vfs.fileid = saf.fileid AND
												  saf.dbid NOT IN (1,3,4)
	ORDER BY vfs.BytesRead/1048576 + BytesWritten/1048576 DESC
	
-- Нагрузка на БД по таблицам/использование таблиц БД
	SELECT  t.name AS [TableName]
		  , fi.page_count AS [Pages]
		  , fi.record_count AS [Rows]
		  , CAST(fi.avg_record_size_in_bytes AS int) AS [AverageRecordBytes]
		  , CAST(fi.avg_fragmentation_in_percent AS int) AS [AverageFragmentationPercent]
		  , SUM(iop.leaf_insert_count) AS [Inserts]
		  , SUM(iop.leaf_delete_count) AS [Deletes]
		  , SUM(iop.leaf_update_count) AS [Updates]
		  , SUM(iop.row_lock_count) AS [RowLocks]
		  , SUM(iop.page_lock_count) AS [PageLocks]
	FROM    sys.dm_db_index_operational_stats(DB_ID(),NULL,NULL,NULL) AS iop
	JOIN    sys.indexes AS i
	ON      ((iop.index_id = i.index_id) AND (iop.object_id = i.object_id))
	JOIN    sys.tables AS t
	ON      i.object_id = t.object_id
	AND     i.type_desc IN ('CLUSTERED', 'HEAP')
	JOIN    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') AS fi
	ON      fi.object_id=CAST(t.object_id AS int)
	AND     fi.index_id=CAST(i.index_id AS int)
	AND     fi.index_id < 2
	GROUP BY t.name, fi.page_count, fi.record_count
		  , fi.avg_record_size_in_bytes, fi.avg_fragmentation_in_percent
	ORDER BY SUM(iop.leaf_insert_count)+SUM(iop.leaf_delete_count)+SUM(iop.leaf_update_count) DESC

-- Активность 
	
-- ***** Ожидания сервера *****
	
-- Ожидания сессий (sessions waits)
	SELECT * FROM sys.dm_exec_session_wait_stats

-- Общая информация о waits -- waits
	-- DBCC SQLPERF("sys.dm_os_wait_stats",CLEAR);  
	WITH [Waits] AS
    (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
       100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
	FROM sys.dm_os_wait_stats
		WHERE [wait_type] NOT IN (
			N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
			N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
			N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
			N'CHKPT', N'CLR_AUTO_EVENT',
			N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
	 
			-- Maybe uncomment these four if you have mirroring issues
			N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
			N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
	 
			N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
			N'EXECSYNC', N'FSAGENT',
			N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
	 
			-- Maybe uncomment these six if you have AG issues
			N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
			N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
			N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
	 
			N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
			N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT',
			N'ONDEMAND_TASK_QUEUE',
			N'PREEMPTIVE_XE_GETTARGETSTATE',
			N'PWAIT_ALL_COMPONENTS_INITIALIZED',
			N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
			N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
			N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
			N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK',
			N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
			N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
			N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
			N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
			N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
			N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
			N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
			N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
			N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
			N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
			N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
			N'WAIT_XTP_RECOVERY',
			N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
			N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
			N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
		AND [waiting_tasks_count] > 0
		)
	SELECT
		MAX ([W1].[wait_type]) AS [WaitType],
		CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
		CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
		CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
		MAX ([W1].[WaitCount]) AS [WaitCount],
		CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
		CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
		CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
		CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S],
		CAST ('https://www.sqlskills.com/help/waits/' + MAX ([W1].[wait_type]) as XML) AS [Help/Info URL]
	FROM [Waits] AS [W1]
	INNER JOIN [Waits] AS [W2]
		ON [W2].[RowNum] <= [W1].[RowNum]
	GROUP BY [W1].[RowNum]
	HAVING SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95; -- percentage threshold
	GO
	
-- LATCH
	WITH Latches AS
		(SELECT
			latch_class,
			wait_time_ms / 1000.0 AS WaitS,
			waiting_requests_count AS WaitCount,
			100.0 * wait_time_ms / SUM (wait_time_ms) OVER() AS Percentage,
			ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum
		FROM sys.dm_os_latch_stats
		WHERE latch_class NOT IN (
			'BUFFER')
		AND wait_time_ms > 0
		)
	SELECT
		W1.latch_class AS LatchClass, 
		CAST (W1.WaitS AS DECIMAL(14, 2)) AS Wait_S,
		W1.WaitCount AS WaitCount,
		CAST (W1.Percentage AS DECIMAL(14, 2)) AS Percentage,
		CAST ((W1.WaitS / W1.WaitCount) AS DECIMAL (14, 4)) AS AvgWait_S
	FROM Latches AS W1
	INNER JOIN Latches AS W2
		ON W2.RowNum <= W1.RowNum
	WHERE W1.WaitCount > 0
	GROUP BY W1.RowNum, W1.latch_class, W1.WaitS, W1.WaitCount, W1.Percentage
	HAVING SUM (W2.Percentage) - W1.Percentage < 95; -- percentage threshold
	GO
	
	-- Текущие latch
		SELECT session_id, wait_type, resource_description ,wait_duration_ms
				FROM sys.dm_os_waiting_tasks
		--WHERE wait_type LIKE 'PAGELATCH%'
		WHERE session_id > 50
		order by wait_duration_ms desc

		
		-- или
		
		SELECT wt.session_id, wt.wait_type
		, er.last_wait_type AS last_wait_type
		, wt.wait_duration_ms
		, wt.blocking_session_id, wt.blocking_exec_context_id, resource_description
		FROM sys.dm_os_waiting_tasks wt
		JOIN sys.dm_exec_sessions es ON wt.session_id = es.session_id
		JOIN sys.dm_exec_requests er ON wt.session_id = er.session_id
		WHERE es.is_user_process = 1
		AND wt.wait_type <> 'SLEEP_TASK'
		ORDER BY wt.wait_duration_ms desc

-- Приращение файлов 
	SELECT DB_NAME(database_id) as [БД], name as [Логическое имя],type_desc as [Тип файла], physical_name as [Физическое имя],  CASE is_percent_growth WHEN 1 THEN CAST(growth as nvarchar(50)) + '%' 
	ELSE CAST(growth/128 as nvarchar(50)) + ' mb' END as [Приращение] FROM sys.master_files

-- Последняя активность БД (видим активность по использованию индексов на таблицах)
	-- Обнуляется при перезагрузке
	SELECT
      T.NAME
      ,USER_SEEKS
      ,USER_SCANS
      ,USER_LOOKUPS
      ,USER_UPDATES
      ,LAST_USER_SEEK
      ,LAST_USER_SCAN
      ,LAST_USER_LOOKUP
      ,LAST_USER_UPDATE
	  ,modify_date
	FROM
		  SYS.DM_DB_INDEX_USAGE_STATS I JOIN
		  SYS.TABLES T ON (T.OBJECT_ID = I.OBJECT_ID)
	WHERE
		  --DATABASE_ID = DB_ID('VisitorControl')
		  DATABASE_ID = DB_ID() -- Если так не работает, то воспользоваться строчкой выше
	ORDER BY LAST_USER_UPDATE DESC
	
	-- По количеству транзакций
		SELECT *
		FROM sys.dm_os_performance_counters
		WHERE counter_name like 'Transactions/sec%'
		and instance_name like 'AdventureWorks2012%';
		GO

-- restore log/restore history
	DECLARE @dbname sysname, @days int
	SET @dbname = NULL --substitute for whatever database name you want
	SET @days = -30 --previous number of days, script will default to 30
	SELECT
	 rsh.destination_database_name AS [Database],
	 rsh.user_name AS [Restored By],
	 CASE WHEN rsh.restore_type = 'D' THEN 'Database'
	  WHEN rsh.restore_type = 'F' THEN 'File'
	  WHEN rsh.restore_type = 'G' THEN 'Filegroup'
	  WHEN rsh.restore_type = 'I' THEN 'Differential'
	  WHEN rsh.restore_type = 'L' THEN 'Log'
	  WHEN rsh.restore_type = 'V' THEN 'Verifyonly'
	  WHEN rsh.restore_type = 'R' THEN 'Revert'
	  ELSE rsh.restore_type 
	 END AS [Restore Type],
	 rsh.restore_date AS [Restore Started],
	 bmf.physical_device_name AS [Restored From], 
	 rf.destination_phys_name AS [Restored To]
	FROM msdb.dbo.restorehistory rsh
	 INNER JOIN msdb.dbo.backupset bs ON rsh.backup_set_id = bs.backup_set_id
	 INNER JOIN msdb.dbo.restorefile rf ON rsh.restore_history_id = rf.restore_history_id
	 INNER JOIN msdb.dbo.backupmediafamily bmf ON bmf.media_set_id = bs.media_set_id
	WHERE rsh.restore_date >= DATEADD(dd, ISNULL(@days, -30), GETDATE()) --want to search for previous days
	AND destination_database_name = ISNULL(@dbname, destination_database_name) --if no dbname, then return all
	ORDER BY rsh.restore_history_id DESC
	GO
	
-- Когда был сделан backup от restore текущей БД
	WITH    restore_date_cte
          AS ( SELECT   d.name AS DatabaseName
                      , rh.restore_date AS BackUpRestoredDatetime
                      , ISNULL(rh.user_name, 'No Restore') AS RestoredBy
                      , bs.name AS BackUpName
                      , bs.user_name AS BackupCreatedBy
                      , bs.backup_finish_date AS backupCompletedDatetime
                      , bs.database_name AS BackupSourceDB
                      , bs.server_name AS BackupSourceSQLInstance
                      , ROW_NUMBER() OVER --get the most recent
                        ( PARTITION BY d.name ORDER BY rh.restore_date DESC ) AS RestoreOrder
               FROM     sys.databases AS d
                        LEFT JOIN msdb.dbo.restorehistory AS rh
                            ON d.name = rh.destination_database_name
                        LEFT JOIN msdb.dbo.BackupSet AS bs
                            ON rh.backup_set_id = bs.backup_set_id
             )
    SELECT  rdc.DatabaseName
          , rdc.BackUpRestoredDatetime
          , rdc.RestoredBy
          , rdc.BackUpName
          , rdc.BackupCreatedBy
          , rdc.backupCompletedDatetime
          , rdc.BackupSourceDB
          , rdc.BackupSourceSQLInstance
          , rdc.RestoreOrder
    FROM    restore_date_cte AS rdc
    WHERE   RestoreOrder = 1
    ORDER BY rdc.DatabaseName
	
/* Чем занят сервер/Текущая активность сервера/нагрузка за указанный промежуток времени*/
-- Только процессы, которые начались и продолжаются к концу отчёта
	SELECT s.[spid]
		  ,s.[loginame]
		  ,s.[open_tran]
		  ,s.[blocked]
		  ,s.[waittime]
		  ,s.[cpu]
		  ,s.[physical_io]
		  ,s.[memusage]
		   INTO #sysprocesses2
	FROM   sys.[sysprocesses] s
	WHERE spid > 49

	WAITFOR DELAY '00:01:05' 

	SELECT txt.[text]
		  ,s.[spid]
		  ,s.[loginame]
		  ,s.[hostname]
		  ,DB_NAME(s.[dbid]) [db_name]
		  ,MAX(s.lastwaittype) [last_waittime]
		  ,SUM(s.[waittime] -ts.[waittime]) [waittime]
		  ,SUM(s.[cpu] -ts.[cpu]) [cpu]
		  ,SUM(s.[physical_io] -ts.[physical_io]) [physical_io]
		  ,s.[program_name]
	FROM   sys.[sysprocesses] s
		   JOIN #sysprocesses2 ts
				ON  s.[spid] = ts.[spid]
				AND s.[loginame] = ts.[loginame]
		   OUTER APPLY sys.[dm_exec_sql_text](s.[sql_handle]) AS txt
	WHERE  s.[cpu] -ts.[cpu] 
		   + s.[physical_io] -ts.[physical_io] 
		   > 10
		   OR  (s.[waittime] -ts.[waittime]) > 30
	GROUP BY
		   txt.[text]
		  ,s.[spid]
		  ,s.[loginame]
		  ,s.[hostname]
		  ,DB_NAME(s.[dbid])
		  ,s.[program_name]
	ORDER BY
		   [physical_io] DESC
		   
	DROP TABLE #sysprocesses2
	
-- ***** Поиск мелких запросов/нагрузка за указанный промежуток времени******

		SELECT [sql_handle], SUM(execution_count) as execution_count, SUM(total_worker_time) as total_worker_time, SUM(total_logical_reads) as total_logical_reads, SUM(total_logical_writes) as total_logical_writes
				   INTO #sysprocesses
		FROM sys.dm_exec_query_stats
		WHERE last_execution_time > DATEADD(mi,-20,GETDATE())
		GROUP BY [sql_handle]

			WAITFOR DELAY '00:01:10'

		SELECT [sql_handle], SUM(execution_count) as execution_count, SUM(total_worker_time) as total_worker_time, SUM(total_logical_reads) as total_logical_reads, SUM(total_logical_writes) as total_logical_writes
		INTO #sysprocesses1
		FROM sys.dm_exec_query_stats
		WHERE last_execution_time > DATEADD(mi,-20,GETDATE())
		GROUP BY [sql_handle]


			SELECT TOP 1000 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
			((CASE qs.statement_end_offset
			WHEN -1 THEN DATALENGTH(qt.TEXT)
			ELSE qs.statement_end_offset
			END - qs.statement_start_offset)/2)+1),
			qt.TEXT,
			ss1.execution_count - ss.execution_count as difference_execution_count,
			ss1.total_worker_time - ss.total_worker_time as difference_total_worker_time,
			ss1.total_logical_reads - ss.total_logical_reads as difference_total_logical_reads,
			ss1.total_logical_writes - ss.total_logical_writes as difference_total_logical_writes,	
			qs.execution_count,
			qs.total_worker_time,
			qs.total_logical_reads,
			qs.total_logical_writes,
			qs.total_elapsed_time/1000 total_elapsed_time_ms,
			qs.last_elapsed_time/1000 last_elapsed_time_ms,
			qs.max_elapsed_time/1000 max_elapsed_time_ms,
			qs.min_elapsed_time/1000 min_elapsed_time_ms,
			qs.max_worker_time,
			qs.min_worker_time,	
			qs.last_worker_time,
			qs.last_logical_reads,
			qs.last_logical_writes,
			qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
			qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
			qs.last_execution_time,
			CAST(qp.query_plan as XML)
			,DB_NAME(qt.dbid)	
			,qt.[objectid] -- по данному id можно вычислить что за объект SELECT name FROM sys.objects WHERE [object_id] = 238623893

		FROM sys.dm_exec_query_stats qs
		INNER JOIN #sysprocesses1 ss1 ON ss1.sql_handle = qs.sql_handle
		INNER JOIN #sysprocesses ss ON ss.sql_handle = qs.sql_handle AND ss1.execution_count > ss.execution_count
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
		CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
		ORDER BY ((ss1.total_logical_reads - ss.total_logical_reads) + (ss1.total_logical_writes - ss.total_logical_writes)) / (ss1.execution_count - ss.execution_count) DESC
		--ORDER BY difference_total_worker_time DESC -- CPU time
				   
		DROP TABLE #sysprocesses	
		DROP TABLE #sysprocesses1

-- Наблюдение за процессорамиc/cpu monitoring/schedule/yield
	USE <yourdb>
	 CREATE TABLE yields 
	 (runtime datetime, scheduler_id bigint,yield_count bigint,runnable int, session_id int,start_time datetime,command varchar(200),database_id int) 

	 GO   

	 SET NOCOUNT ON 
	 WHILE(1=1)
	 BEGIN 
	 INSERT INTO yields
	 SELECT getdate() 'runtime', a.scheduler_id, a.yield_count, runnable_tasks_count, session_id,start_time, command,database_id 
	 FROM sys.dm_os_schedulers a
	inner join sys.dm_os_workers b on a.active_worker_address=b.worker_address 
	left join sys.dm_exec_requests c on c.task_address=b.task_address 
	--Most system has less than 1024 cores, use this to ignore those HIDDEN schedulers 
	WHERE a.scheduler_id<1024 
	 --Monitor it every 5 seconds. you can change it to meet your needs
	 WAITFOR DELAY '00:00:05'
	 END 

	-- To get interesting non-yielding scheduler information out of table yields, I use below script. It is not the perfect one but it can give you the idea how to get  meaningful information from the captured data. 

	DECLARE scheduler_cur CURSOR  
	FOR SELECT scheduler_id from yields group by scheduler_id order by scheduler_id
	OPEN scheduler_cur
	DECLARE @id bigint
	FETCH NEXT  FROM scheduler_cur INTO @id
	WHILE (@@FETCH_STATUS=0)
	BEGIN 
	 DECLARE delta_cur CURSOR 
	 FOR SELECT runtime, yield_count,scheduler_id,runnable,session_id,start_time, command,database_id 
	 FROM yields WHERE scheduler_id=1  ORDER BY runtime ASC 
	 OPEN delta_cur
	 DECLARE @runtime_previous datetime,@yieldcount_previous bigint
	 DECLARE @runtime datetime,@yieldcount bigint,@scheduler_id bigint,@runnable int,@session_id int,@start_time datetime,@command varchar(200),@database_id int

	 FETCH NEXT FROM delta_cur INTO  @runtime ,@yieldcount ,@scheduler_id,@runnable ,@session_id ,@start_time,@command,@database_id 
	 SET @runtime_previous=@runtime;SET @yieldcount_previous=@yieldcount
	 FETCH NEXT FROM delta_cur INTO  @runtime ,@yieldcount ,@scheduler_id ,@runnable,@session_id ,@start_time,@command ,@database_id  

	 WHILE(@@FETCH_STATUS=0)
	 BEGIN 
	--We find one non-yielding scheduler during the runtime delta
	IF(@yieldcount=@yieldcount_previous)
	BEGIN 
	PRINT 'Non-yielding Scheduler Time delta found!'
	  SELECT @runtime_previous 'runtime_previous', @runtime 'runtime', datediff(second, @runtime_previous,@runtime) 'non_yielding_scheduler_time_second', @yieldcount_previous 'yieldcount_previous',
	  @yieldcount 'yieldcount' ,@scheduler_id 'scheduler_id',@runnable 'runnable_tasks' ,@session_id 'session_id' ,@start_time 'start_time', 

	  @command 'command' ,@database_id  'database_id'
	END 

	-- print @id
	SET @runtime_previous=@runtime;SET @yieldcount_previous=@yieldcount
	FETCH NEXT FROM delta_cur INTO  @runtime ,@yieldcount ,@scheduler_id,@runnable ,@session_id ,@start_time,@command ,@database_id    

	 END

	 CLOSE delta_cur
	 DEALLOCATE delta_cur
	 FETCH NEXT  FROM scheduler_cur INTO @id 

	END 
	CLOSE scheduler_cur
	DEALLOCATE scheduler_cur 
		
		
-- Использование файлов БД за указанный промежуток времени
	SELECT DB_NAME(saf.dbid) AS [db],
	   saf.name AS [name],
	   vfs.BytesRead/1048576 AS [read],
	   vfs.BytesWritten/1048576 AS [write]
	   INTO #dbusage
	FROM master..sysaltfiles AS saf
	JOIN ::fn_virtualfilestats(NULL,NULL) AS vfs ON vfs.dbid = saf.dbid AND
												  vfs.fileid = saf.fileid AND
												  saf.dbid NOT IN (1,3,4)
	WHERE  DB_NAME(saf.dbid) <> 'tempdb'
	ORDER BY vfs.BytesRead/1048576 + BytesWritten/1048576 DESC

	WAITFOR DELAY '00:03:00'

	SELECT DB_NAME(saf.dbid) AS [db],
	   saf.name AS [name],
	   vfs.BytesRead/1048576 AS [read],
	   vfs.BytesWritten/1048576 AS [write]
	   INTO #dbusage2
	FROM master..sysaltfiles AS saf
	JOIN ::fn_virtualfilestats(NULL,NULL) AS vfs ON vfs.dbid = saf.dbid AND
												  vfs.fileid = saf.fileid AND
												  saf.dbid NOT IN (1,3,4)
	WHERE  DB_NAME(saf.dbid) <> 'tempdb'
	ORDER BY vfs.BytesRead/1048576 + BytesWritten/1048576 DESC


	SELECT t.db,t.name,(t2.[read] - t.[read]) as tread,(t2.[write] - t.[write]) as [twrite]	
	 FROM #dbusage t INNER JOIN #dbusage2 t2 on t.db= t2.db AND t.name=t2.name
		
	DROP TABLE #dbusage
	DROP TABLE #dbusage2	

-- Использований файлов БД за указанный промежуток времени (более подробно)
	IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
		WHERE [name] = N'##SQLskillsStats1')
		DROP TABLE [##SQLskillsStats1];
	 
	IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
		WHERE [name] = N'##SQLskillsStats2')
		DROP TABLE [##SQLskillsStats2];
	GO
	 
	SELECT [database_id], [file_id], [num_of_reads], [io_stall_read_ms],
		   [num_of_writes], [io_stall_write_ms], [io_stall],
		   [num_of_bytes_read], [num_of_bytes_written], [file_handle]
	INTO ##SQLskillsStats1
	FROM sys.dm_io_virtual_file_stats (NULL, NULL);
	GO
	 
	WAITFOR DELAY '00:01:00';
	GO
	 
	SELECT [database_id], [file_id], [num_of_reads], [io_stall_read_ms],
		   [num_of_writes], [io_stall_write_ms], [io_stall],
		   [num_of_bytes_read], [num_of_bytes_written], [file_handle]
	INTO ##SQLskillsStats2
	FROM sys.dm_io_virtual_file_stats (NULL, NULL);
	GO
	 
	WITH [DiffLatencies] AS
	(SELECT
	-- Files that weren't in the first snapshot
			[ts2].[database_id],
			[ts2].[file_id],
			[ts2].[num_of_reads],
			[ts2].[io_stall_read_ms],
			[ts2].[num_of_writes],
			[ts2].[io_stall_write_ms],
			[ts2].[io_stall],
			[ts2].[num_of_bytes_read],
			[ts2].[num_of_bytes_written]
		FROM [##SQLskillsStats2] AS [ts2]
		LEFT OUTER JOIN [##SQLskillsStats1] AS [ts1]
			ON [ts2].[file_handle] = [ts1].[file_handle]
		WHERE [ts1].[file_handle] IS NULL
	UNION
	SELECT
	-- Diff of latencies in both snapshots
			[ts2].[database_id],
			[ts2].[file_id],
			[ts2].[num_of_reads] - [ts1].[num_of_reads] AS [num_of_reads],
			[ts2].[io_stall_read_ms] - [ts1].[io_stall_read_ms] AS [io_stall_read_ms],
			[ts2].[num_of_writes] - [ts1].[num_of_writes] AS [num_of_writes],
			[ts2].[io_stall_write_ms] - [ts1].[io_stall_write_ms] AS [io_stall_write_ms],
			[ts2].[io_stall] - [ts1].[io_stall] AS [io_stall],
			[ts2].[num_of_bytes_read] - [ts1].[num_of_bytes_read] AS [num_of_bytes_read],
			[ts2].[num_of_bytes_written] - [ts1].[num_of_bytes_written] AS [num_of_bytes_written]
		FROM [##SQLskillsStats2] AS [ts2]
		LEFT OUTER JOIN [##SQLskillsStats1] AS [ts1]
			ON [ts2].[file_handle] = [ts1].[file_handle]
		WHERE [ts1].[file_handle] IS NOT NULL)
	SELECT
		DB_NAME ([vfs].[database_id]) AS [DB],
		LEFT ([mf].[physical_name], 2) AS [Drive],
		[mf].[type_desc],
		[num_of_reads] AS [Reads],
		[num_of_writes] AS [Writes],
		[ReadLatency(ms)] =
			CASE WHEN [num_of_reads] = 0
				THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END,
		[WriteLatency(ms)] =
			CASE WHEN [num_of_writes] = 0
				THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END,
		/*[Latency] =
			CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
				THEN 0 ELSE ([io_stall] / ([num_of_reads] + [num_of_writes])) END,*/
		[AvgBPerRead] =
			CASE WHEN [num_of_reads] = 0
				THEN 0 ELSE ([num_of_bytes_read] / [num_of_reads]) END,
		[AvgBPerWrite] =
			CASE WHEN [num_of_writes] = 0
				THEN 0 ELSE ([num_of_bytes_written] / [num_of_writes]) END,
		/*[AvgBPerTransfer] =
			CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
				THEN 0 ELSE
					(([num_of_bytes_read] + [num_of_bytes_written]) /
					([num_of_reads] + [num_of_writes])) END,*/
		[mf].[physical_name]
	FROM [DiffLatencies] AS [vfs]
	JOIN sys.master_files AS [mf]
		ON [vfs].[database_id] = [mf].[database_id]
		AND [vfs].[file_id] = [mf].[file_id]
	-- ORDER BY [ReadLatency(ms)] DESC
	ORDER BY [WriteLatency(ms)] DESC;
	GO
	 
	-- Cleanup
	IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
		WHERE [name] = N'##SQLskillsStats1')
		DROP TABLE [##SQLskillsStats1];
	 
	IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
		WHERE [name] = N'##SQLskillsStats2')
		DROP TABLE [##SQLskillsStats2];
	GO	
	
		
-- Использование tempdb сессиями/место в tempdb под сессии	
	SELECT session_id, 
	  SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
	  SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count 
	FROM sys.dm_db_task_space_usage 
	GROUP BY session_id
	ORDER BY SUM(internal_objects_alloc_page_count) + SUM(internal_objects_dealloc_page_count) DESC
	
	-- 2 вариант
		SELECT TOP 10 session_id, database_id, user_objects_alloc_page_count + internal_objects_alloc_page_count / 129 AS tempdb_usage_MB
		FROM sys.dm_db_session_space_usage
		ORDER BY user_objects_alloc_page_count + internal_objects_alloc_page_count DESC;
	
-- Какие spinlock сейчас происходят (замер за минуту)?
	IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
   WHERE [name] = N'##TempSpinlockStats1')
   DROP TABLE [##TempSpinlockStats1];
 
	IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
	   WHERE [name] = N'##TempSpinlockStats2')
	   DROP TABLE [##TempSpinlockStats2];
	GO
	 
	-- Baseline
	SELECT * INTO [##TempSpinlockStats1]
	FROM sys.dm_os_spinlock_stats
	WHERE [collisions] > 0
	ORDER BY [name];
	GO
	 
	-- Now do something
	WAITFOR DELAY '00:01:00'
	 
	-- Capture updated stats
	SELECT * INTO [##TempSpinlockStats2]
	FROM sys.dm_os_spinlock_stats
	WHERE [collisions] > 0
	ORDER BY [name];
	GO
	 
	-- Diff them
	SELECT
		'***' AS [New],
		[ts2].[name] AS [Spinlock],
		[ts2].[collisions] AS [DiffCollisions],
		[ts2].[spins] AS [DiffSpins],
		[ts2].[spins_per_collision] AS [SpinsPerCollision],
		[ts2].[sleep_time] AS [DiffSleepTime],
		[ts2].[backoffs] AS [DiffBackoffs]
	FROM [##TempSpinlockStats2] [ts2]
	LEFT OUTER JOIN [##TempSpinlockStats1] [ts1]
		ON [ts2].[name] = [ts1].[name]
	WHERE [ts1].[name] IS NULL
	UNION
	SELECT
		'' AS [New],
		[ts2].[name] AS [Spinlock],
		[ts2].[collisions] - [ts1].[collisions] AS [DiffCollisions],
		[ts2].[spins] - [ts1].[spins] AS [DiffSpins],
		CASE ([ts2].[spins] - [ts1].[spins]) WHEN 0 THEN 0
			ELSE ([ts2].[spins] - [ts1].[spins]) /
				([ts2].[collisions] - [ts1].[collisions]) END
				AS [SpinsPerCollision],
		[ts2].[sleep_time] - [ts1].[sleep_time] AS [DiffSleepTime],
		[ts2].[backoffs] - [ts1].[backoffs] AS [DiffBackoffs]
	FROM [##TempSpinlockStats2] [ts2]
	LEFT OUTER JOIN [##TempSpinlockStats1] [ts1]
		ON [ts2].[name] = [ts1].[name]
	WHERE [ts1].[name] IS NOT NULL
		AND [ts2].[collisions] - [ts1].[collisions] > 0
	ORDER BY [New] DESC, [Spinlock] ASC;
	GO

	IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
	   WHERE [name] = N'##TempSpinlockStats1')
	   DROP TABLE [##TempSpinlockStats1];
	 
	IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
	   WHERE [name] = N'##TempSpinlockStats2')
	   DROP TABLE [##TempSpinlockStats2];
	GO
	
-- Включён ли instant file initialization?
	DBCC TRACESTATUS(-1);
	
-- Фрагментация индексов 
	SELECT 
		dm.database_id, 
		'['+tbl.name+']', 
		dm.index_id, 
		idx.name, 
		dm.avg_fragmentation_in_percent,   
		idx.fill_factor
	FROM sys.dm_db_index_physical_stats(DB_ID(), null, null, null, 'LIMITED') dm
		INNER JOIN sys.tables tbl ON dm.object_id = tbl.object_id
		INNER JOIN sys.indexes idx ON dm.object_id = idx.object_id AND dm.index_id = idx.index_id
	WHERE page_count > 1000
		AND avg_fragmentation_in_percent > 15
		AND dm.index_id > 0 
		AND idx.is_disabled = 0
		AND tbl.name not like '%$%'
		
-- Устаревание статистики (С SQL Server 2008 R2)
	SELECT
    sch.name  AS 'Schema',
    so.name as 'Table',
    ss.name AS 'Statistic'
	FROM sys.stats ss
	JOIN sys.objects so ON ss.object_id = so.object_id
	JOIN sys.schemas sch ON so.schema_id = sch.schema_id
	OUTER APPLY sys.dm_db_stats_properties(so.object_id, ss.stats_id) AS sp
	WHERE so.TYPE = 'U'
	AND sp.modification_counter >  CASE WHEN (sp.rows < 25000)
			THEN (sqrt((sp.rows) * 1000))
		WHEN ((sp.rows) > 25000 AND (sp.rows) <= 10000000)
			THEN ((sp.rows) * 0.10 + 500)
		WHEN ((sp.rows) > 10000000 AND (sp.rows) <= 100000000)
			THEN ((sp.rows) * 0.03 + 500)
		WHEN ((sp.rows) > 100000000)
			THEN ((sp.rows) * 0.01 + 500) END
	AND sp.last_updated < getdate() - 1 -- как давно последний раз обновлялась статистика
	ORDER BY sp.last_updated
	DESC
	
	-- До SQL Server 2008 R2
	
	select DISTINCT SCHEMA_NAME(uid) as gerg, -- Обязательно указать DISTINCT, чтобы убрать дубликаты
		object_name (i.id)as objectname,		
		i.name as indexname
		from sysindexes i INNER JOIN dbo.sysobjects o ON i.id = o.id
		LEFT JOIN sysindexes si ON si.id = i.id AND si.rows > 0 -- добавлено для анализа статистики столбцов
		where i.rowmodctr > 
		CASE WHEN (si.rows < 25000)
			THEN (sqrt((i.rows) * 1000))
		WHEN ((si.rows) > 25000 AND (si.rows) <= 10000000)
			THEN ((si.rows) * 0.10 + 500)
		WHEN ((si.rows) > 10000000 AND (si.rows) <= 100000000)
			THEN ((si.rows) * 0.03 + 500)
		WHEN ((si.rows) > 100000000)
			THEN ((si.rows) * 0.01 + 500)
		END
		AND i.name not like 'sys%'
		AND object_name(i.id) not like 'sys%'
		AND STATS_DATE(i.id, i.indid) < GetDATE()-1

-- Ожидания ресурсов
	SELECT * FROM sys.dm_os_waiting_tasks
	
-- Блокировки
	WITH Latches AS
		(SELECT
			latch_class,
			wait_time_ms / 1000.0 AS WaitS,
			waiting_requests_count AS WaitCount,
			100.0 * wait_time_ms / SUM (wait_time_ms) OVER() AS Percentage,
			ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum
		FROM sys.dm_os_latch_stats
		WHERE latch_class NOT IN (
			'BUFFER')
		AND wait_time_ms > 0
		)
	SELECT
		W1.latch_class AS LatchClass, 
		CAST (W1.WaitS AS DECIMAL(14, 2)) AS Wait_S,
		W1.WaitCount AS WaitCount,
		CAST (W1.Percentage AS DECIMAL(14, 2)) AS Percentage,
		CAST ((W1.WaitS / W1.WaitCount) AS DECIMAL (14, 4)) AS AvgWait_S
	FROM Latches AS W1
	INNER JOIN Latches AS W2
		ON W2.RowNum <= W1.RowNum
	WHERE W1.WaitCount > 0
	GROUP BY W1.RowNum, W1.latch_class, W1.WaitS, W1.WaitCount, W1.Percentage
	HAVING SUM (W2.Percentage) - W1.Percentage < 95; -- percentage threshold
	GO	
	
-- Какие таблицы используются больше всего
		SELECT  t.name AS [TableName]
			  , fi.page_count AS [Pages]
			  , fi.record_count AS [Rows]
			  , CAST(fi.avg_record_size_in_bytes AS int) AS [AverageRecordBytes]
			  , CAST(fi.avg_fragmentation_in_percent AS int) AS [AverageFragmentationPercent]
			  , SUM(iop.leaf_insert_count) AS [Inserts]
			  , SUM(iop.leaf_delete_count) AS [Deletes]
			  , SUM(iop.leaf_update_count) AS [Updates]
			  , SUM(iop.row_lock_count) AS [RowLocks]
			  , SUM(iop.page_lock_count) AS [PageLocks]
		FROM    sys.dm_db_index_operational_stats(DB_ID(),NULL,NULL,NULL) AS iop
		JOIN    sys.indexes AS i
		ON      ((iop.index_id = i.index_id) AND (iop.object_id = i.object_id))
		JOIN    sys.tables AS t
		ON      i.object_id = t.object_id
		AND     i.type_desc IN ('CLUSTERED', 'HEAP')
		JOIN    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') AS fi
		ON      fi.object_id=CAST(t.object_id AS int)
		AND     fi.index_id=CAST(i.index_id AS int)
		AND     fi.index_id < 2
		GROUP BY t.name, fi.page_count, fi.record_count
			  , fi.avg_record_size_in_bytes, fi.avg_fragmentation_in_percent
		ORDER BY [TableName]

-- Какие процедуры больше всего используются
	SELECT TOP 100 PERCENT    OBJECT_NAME(s.objectid,s.dbid) AS SP_Name
			, MAX(st.last_execution_time) AS last_execution_time
			, SUM(CAST((st.total_elapsed_time * 1.0 /100000)/st.execution_count AS money)) 
			  AS avg_elapsed_time_sec
         FROM master.sys.dm_exec_cached_plans AS c
  CROSS APPLY master.sys.dm_exec_query_plan (c.plan_handle) AS q
   INNER JOIN master.sys.dm_exec_query_stats AS st
           ON c.plan_handle = st.plan_handle
  CROSS APPLY master.sys.dm_exec_sql_text(sql_handle) AS s
        WHERE c.cacheobjtype = 'Compiled Plan'
          AND c.objtype = 'Proc'
          AND q.dbid = DB_ID()
     GROUP BY DB_NAME(q.dbid),OBJECT_NAME(s.objectid,s.dbid)  
     ORDER BY avg_elapsed_time_sec DESC

		
-- Performance Monitor
	- Диск
	- Процессор
	- Память
		SQLServer:Memory Manager - Target Server Memory (KB)
		SQLServer:Memory Manager - Total Server Memory (KB)
		SQLServer: Buffer Manager\Page life expectancy
	- Ожидания/блокировки
		SQLServer: Locks - Number of Deadlocks/sec	
		SQLServer: Locks - Average Wait Time
		SQL Server:General Statistics - Process blocked
	- Остальное
		SqlServer: SQL Statistics - Batch Requests/sec 
		SqlServer: SQL Statistics - SQL Compilations/sec 
		SqlServer: SQL Statistics - SQL Recompilations/sec
		
-- *****ИНДЕКСЫ*****

-- Использование индексов
		SELECT OBJECT_NAME(s.[object_id]) AS [Table Name], i.name AS [Index Name], i.index_id,
		user_updates AS [Total Writes], user_seeks + user_scans + user_lookups AS [Total Reads],
		user_updates - (user_seeks + user_scans + user_lookups) AS [Difference]
		FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
		INNER JOIN sys.indexes AS i WITH (NOLOCK)
		ON s.[object_id] = i.[object_id]
		AND i.index_id = s.index_id
		WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
		AND s.database_id = DB_ID()
		AND user_updates > (user_seeks + user_scans + user_lookups)
		AND i.index_id > 1
		ORDER BY [Difference] DESC, [Total Writes] DESC, [Total Reads] ASC;		
		
-- Упущенные индексы
		SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS [index_advantage], 
		migs.avg_user_impact as [% выигрыша],
		migs.last_user_seek,
		migs.avg_total_user_cost as [Стоимость запроса],
		migs.user_seeks as [Предполагаемое количество вызовов],
		migs.unique_compiles as [Число компиляций и повторных компиляций],
		mid.[statement] AS [Database.Schema.Table],
		mid.equality_columns, mid.inequality_columns, mid.included_columns, 
		(
		SELECT SUM(au.total_pages) * 8 / 1024  FROM  sys.tables as st WITH (NOLOCK) 
		INNER JOIN sys.partitions as sp WITH (NOLOCK) ON st.object_id = sp.object_id
		INNER JOIN sys.allocation_units as au WITH (NOLOCK) ON au.container_id = sp.partition_id
		INNER JOIN sys.data_spaces as spp WITH (NOLOCK) ON spp.data_space_id = au.data_space_id	
		WHERE  st.object_id = OBJECT_ID(mid.statement)
		group by st.name
		)	as [Размер,мб], -- Чтобы было значение необходимо вызывать в контексте нужной БД
		 [Transact SQL код для создания индекса] = ''+
      mid.statement + ' (' + ISNULL(mid.equality_columns,'') +
      (CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ', '
ELSE '' END) +
      (CASE WHEN mid.inequality_columns IS NOT NULL THEN + mid.inequality_columns ELSE '' END) + ')' +
      (CASE WHEN mid.included_columns IS NOT NULL THEN ' INCLUDE (' + mid.included_columns + ')'
ELSE '' END) +      ';'
		FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
		INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
		ON migs.group_handle = mig.index_group_handle
		INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
		ON mig.index_handle = mid.index_handle
		--WHERE mid.database_id = DB_ID()
		ORDER BY index_advantage DESC;
		
-- контроль "несжатости"
	SELECT tbl.name,
		   i.name,
		   p.partition_number AS [PartitionNumber],
		   p.data_compression_desc AS [DataCompression],
		   p.rows  AS [RowCount]
	  FROM sys.tables AS tbl
	  LEFT JOIN sys.indexes AS i ON (i.index_id > 0 and i.is_hypothetical = 0) AND (i.object_id=tbl.object_id)
	  INNER JOIN sys.partitions AS p ON p.object_id = CAST(tbl.object_id AS int) AND
										p.index_id = CAST(i.index_id AS int)
	  where p.data_compression_desc <> 'PAGE' and
			p.rows >= 1000000
	  order by p.rows desc, 3
  
 -- Количество операций в секунду/нагрузка в минуту
	DECLARE @counter int = 0
	WHILE @counter < 5
	BEGIN
	DECLARE @batch_counter_start bigint = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Batch Requests/sec')

	WAITFOR DELAY '00:01:00'

	DECLARE @batch_counter_end bigint = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Batch Requests/sec')

	SELECT @batch_counter_end - @batch_counter_start as [Батчей за минуту]

	SET @counter = @counter + 1

	END 
	
-- Сколько весит каждая таблица/Размер таблиц/Размер всех таблиц/Место занимаемое каждой таблицей
	WITH table_space_usage ( schema_name, table_name, used, reserved, ind_rows, tbl_rows ) 
	AS (
	SELECT 
		s.Name 
		, o.Name 
		, p.used_page_count * 8 / 1024
		, p.reserved_page_count * 8 / 1024
		, p.row_count 
		, case when i.index_id in ( 0, 1 ) then p.row_count else 0 end 
	FROM sys.dm_db_partition_stats p 
		INNER JOIN sys.objects as o ON o.object_id = p.object_id 
		INNER JOIN sys.schemas as s ON s.schema_id = o.schema_id 
		LEFT OUTER JOIN sys.indexes as i on i.object_id = p.object_id and i.index_id = p.index_id 
	WHERE o.type_desc = 'USER_TABLE' and o.is_ms_shipped = 0
		) 

	SELECT t.schema_name 
			, t.table_name 
			, sum(t.used) as used_in_mb 
			, sum(t.reserved) as reserved_in_mb
			,sum(t.tbl_rows) as rows 
	FROM table_space_usage as t 
	GROUP BY t.schema_name , t.table_name 
	ORDER BY used_in_mb desc	
	
-- Не используемые таблицы с последнего рестарта сервера
	WITH table_space_usage ( [schema_name], table_name, used, reserved, ind_rows, tbl_rows ) 
	AS (
	SELECT 
		s.Name 
		, o.Name 
		, p.used_page_count * 8 / 1024
		, p.reserved_page_count * 8 / 1024
		, p.row_count 
		, case when i.index_id in ( 0, 1 ) then p.row_count else 0 end 
	FROM sys.dm_db_partition_stats p 
		INNER JOIN sys.objects as o ON o.object_id = p.object_id 
		INNER JOIN sys.schemas as s ON s.schema_id = o.schema_id 
		LEFT OUTER JOIN sys.indexes as i on i.object_id = p.object_id and i.index_id = p.index_id 
	WHERE o.type_desc = 'USER_TABLE' and o.is_ms_shipped = 0
		) 
	SELECT t.[schema_name ]
			, t.table_name 
			, sum(t.used) as used_in_mb 
			, sum(t.reserved) as reserved_in_mb
			,sum(t.tbl_rows) as rows 
	FROM table_space_usage as t 
	WHERE table_name IN (
	SELECT T.NAME
	FROM SYS.DM_DB_INDEX_USAGE_STATS I JOIN	SYS.TABLES T ON (T.OBJECT_ID = I.OBJECT_ID)
	WHERE last_user_seek IS NULL AND LAST_USER_SCAN IS NULL AND LAST_USER_LOOKUP IS NULL
	)
	GROUP BY t.schema_name , t.table_name 

	
-- Размер всех БД/место под все БД
	CREATE TABLE #sizingDB (dbname nvarchar(255), type_desc nvarchar(50), size_mb bigint)

	INSERT INTO #sizingDB
	exec sp_msforeachdb @command1 = 'use [?]; 
	SELECT DB_NAME(),type_desc, SUM(size)*8/1024 as size FROM sys.database_files 
	GROUP BY type_desc'

	SELECT * FROM  #sizingDB
	WHERE dbname NOT IN ('master','msdb','model')
	ORDER BY dbname, type_desc DESC

	DROP TABLE #sizingDB
	
-- Свободное место в файлах БД
	select 
		f.type_desc as [Type]
		,f.name as [FileName]
		,fg.name as [FileGroup]
		,f.physical_name as [Path]
		,f.size / 128.0 as [CurrentSizeMB]
		,f.size / 128.0 - convert(int,fileproperty(f.name,'SpaceUsed')) / 
			128.0 as [FreeSpaceMb]
	from 
		sys.database_files f with (nolock) left outer join 
			sys.filegroups fg with (nolock) on
				f.data_space_id = fg.data_space_id
	option (recompile)
	
-- распределение объектов по filegroup/файловые группы
	SELECT DS.name AS DataSpaceName 
		  ,AU.type_desc AS AllocationDesc 
		  ,AU.total_pages / 128 AS TotalSizeMB 
		  ,AU.used_pages / 128 AS UsedSizeMB 
		  ,AU.data_pages / 128 AS DataSizeMB 
		  ,SCH.name AS SchemaName 
		  ,OBJ.type_desc AS ObjectType       
		  ,OBJ.name AS ObjectName 
		  ,IDX.type_desc AS IndexType 
		  ,IDX.name AS IndexName 
	FROM sys.data_spaces AS DS 
		 INNER JOIN sys.allocation_units AS AU 
			 ON DS.data_space_id = AU.data_space_id 
		 INNER JOIN sys.partitions AS PA 
			 ON (AU.type IN (1, 3)  
				 AND AU.container_id = PA.hobt_id) 
				OR 
				(AU.type = 2 
				 AND AU.container_id = PA.partition_id) 
		 INNER JOIN sys.objects AS OBJ 
			 ON PA.object_id = OBJ.object_id 
		 INNER JOIN sys.schemas AS SCH 
			 ON OBJ.schema_id = SCH.schema_id 
		 LEFT JOIN sys.indexes AS IDX 
			 ON PA.object_id = IDX.object_id 
				AND PA.index_id = IDX.index_id 
	ORDER BY DS.name 
			,SCH.name 
			,OBJ.name 
			,IDX.name

-- Занимаемое место файлами текущей БД	
SELECT RTRIM(name) AS [Segment Name], groupid AS [Group Id], filename AS [File Name],
   CAST(size/128 AS bigint) AS [Allocated Size in MB],
   CAST(FILEPROPERTY(name, 'SpaceUsed')/128 AS bigint) AS [Space Used in MB],
   CAST([maxsize]/128 AS bigint) AS [Max in MB],
   CAST([maxsize]/128-(FILEPROPERTY(name, 'SpaceUsed')/128) AS bigint) AS [Available Space in MB]
FROM sysfiles
ORDER BY groupid DESC

-- Список пользователей, которые имеют доступ к БД
	-- Пользователи
	
	-- Список sysadm
	
-- Распределение памяти
	select top(5) domc.[type], sum(pages_kb) 
	from sys.[dm_os_memory_clerks] as domc 
	group by domc.[type] 
	order by sum(pages_kb) desc
	
	-- Свободная память
		SELECT * FROM sys.dm_os_performance_counters WHERE counter_name = 'Free Memory (KB)'	
		
	-- Использование памяти в данный момент
		SELECT  
		(physical_memory_in_use_kb/1024) AS Memory_usedby_Sqlserver_MB,  
		(locked_page_allocations_kb/1024) AS Locked_pages_used_Sqlserver_MB,  
		(total_virtual_address_space_kb/1024) AS Total_VAS_in_MB,  
		process_physical_memory_low,  
		process_virtual_memory_low  
		FROM sys.dm_os_process_memory;  
		
-- Сеть
	-- Открытые соединения
	-- Открытые порты
	-- Открытые папки
		netstat -na|findstr "mssqlbackup"
		
-- Какая-то общая информация
	SELECT @@connections as [connections], @@cpu_busy as [cpu_busy], @@idle as [idle], @@io_busy as [io_busy], @@pack_received as [pack_received], @@timeticks as [timeticks], @@total_errors as [total_errors], @@total_read as [total_read], @@total_write as [total_write]
	
-- Распределение процессоров по NUMA/CPU per Numa
	select parent_node_id, Count(*)
	from sys.dm_os_schedulers
	where [status] = 'VISIBLE ONLINE'
		and parent_node_id < 64
	GROUP BY parent_node_id 
	
-- Запросы которым было выделено много памяти (видно только активные запросы в данный момент)
	SELECT qp.query_plan,* FROM sys.dm_exec_query_memory_grants er
		outer apply sys.dm_exec_sql_text((er.sql_handle)) st
		outer apply sys.dm_exec_query_plan((er.plan_handle)) qp
	
-- В памяти ли объекты/найти объект в памяти/найти таблицу в памяти
	SELECT * FROM sys.dm_os_buffer_descriptors
	
-- Ошибки сессий, пользователей
	WITH connectivity_ring_buffer as
	(SELECT
	record.value('(Record/@id)[1]', 'int') as id,
	record.value('(Record/@type)[1]', 'varchar(50)') as type,
	record.value('(Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(50)') as RecordType,
	record.value('(Record/ConnectivityTraceRecord/RecordSource)[1]', 'varchar(50)') as RecordSource,
	record.value('(Record/ConnectivityTraceRecord/Spid)[1]', 'int') as Spid,
	record.value('(Record/ConnectivityTraceRecord/SniConnectionId)[1]', 'uniqueidentifier') as SniConnectionId,
	record.value('(Record/ConnectivityTraceRecord/SniProvider)[1]', 'int') as SniProvider,
	record.value('(Record/ConnectivityTraceRecord/OSError)[1]', 'int') as OSError,
	record.value('(Record/ConnectivityTraceRecord/SniConsumerError)[1]', 'int') as SniConsumerError,
	record.value('(Record/ConnectivityTraceRecord/State)[1]', 'int') as State,
	record.value('(Record/ConnectivityTraceRecord/RemoteHost)[1]', 'varchar(50)') as RemoteHost,
	record.value('(Record/ConnectivityTraceRecord/RemotePort)[1]', 'varchar(50)') as RemotePort,
	record.value('(Record/ConnectivityTraceRecord/LocalHost)[1]', 'varchar(50)') as LocalHost,
	record.value('(Record/ConnectivityTraceRecord/LocalPort)[1]', 'varchar(50)') as LocalPort,
	record.value('(Record/ConnectivityTraceRecord/RecordTime)[1]', 'datetime') as RecordTime,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/TotalLoginTimeInMilliseconds)[1]', 'bigint') as TotalLoginTimeInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/LoginTaskEnqueuedInMilliseconds)[1]', 'bigint') as LoginTaskEnqueuedInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/NetworkWritesInMilliseconds)[1]', 'bigint') as NetworkWritesInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/NetworkReadsInMilliseconds)[1]', 'bigint') as NetworkReadsInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/SslProcessingInMilliseconds)[1]', 'bigint') as SslProcessingInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/SspiProcessingInMilliseconds)[1]', 'bigint') as SspiProcessingInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/LoginTimers/LoginTriggerAndResourceGovernorProcessingInMilliseconds)[1]', 'bigint') as LoginTriggerAndResourceGovernorProcessingInMilliseconds,
	record.value('(Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferError)[1]', 'int') as TdsInputBufferError,
	record.value('(Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsOutputBufferError)[1]', 'int') as TdsOutputBufferError,
	record.value('(Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferBytes)[1]', 'int') as TdsInputBufferBytes,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/PhysicalConnectionIsKilled)[1]', 'int') as PhysicalConnectionIsKilled,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/DisconnectDueToReadError)[1]', 'int') as DisconnectDueToReadError,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/NetworkErrorFoundInInputStream)[1]', 'int') as NetworkErrorFoundInInputStream,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/ErrorFoundBeforeLogin)[1]', 'int') as ErrorFoundBeforeLogin,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/SessionIsKilled)[1]', 'int') as SessionIsKilled,
	record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalDisconnect)[1]', 'int') as NormalDisconnect
	--record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalLogout)[1]', 'int') as NormalLogout
	FROM
	( SELECT CAST(record as xml) as record
	FROM sys.dm_os_ring_buffers
	WHERE ring_buffer_type = 'RING_BUFFER_CONNECTIVITY') as tab
	)
	SELECT c.*, text
	FROM connectivity_ring_buffer c
	LEFT JOIN sys.messages m ON c.SniConsumerError = m.message_id AND m.language_id = 1033
	--where recordtype IN ('ConnectionClose', 'Error')
	ORDER BY c.id desc
	
	
-- Последний запрос/ last query
	DBCC INPUTBUFFER(117)

	DECLARE @sqltext VARBINARY(128)
	SELECT @sqltext = sql_handle
	FROM sys.sysprocesses
	WHERE spid = 117
	SELECT TEXT
	FROM sys.dm_exec_sql_text(@sqltext)
	GO

	DECLARE @sqltext VARBINARY(128)
	SELECT @sqltext = sql_handle
	FROM sys.sysprocesses
	WHERE spid = 117
	SELECT TEXT
	FROM ::fn_get_sql(@sqltext)
	GO
	
-- Ghost
	SELECT * FROM sys.dm_exec_requests WHERE command LIKE '%ghost%'

	
-- Объекты в файловых группах/Что в моей файловой группе

	SELECT DS.name AS DataSpaceName 
		  ,AU.type_desc AS AllocationDesc 
		  ,AU.total_pages / 128 AS TotalSizeMB 
		  ,AU.used_pages / 128 AS UsedSizeMB 
		  ,AU.data_pages / 128 AS DataSizeMB 
		  ,SCH.name AS SchemaName 
		  ,OBJ.type_desc AS ObjectType       
		  ,OBJ.name AS ObjectName 
		  ,IDX.type_desc AS IndexType 
		  ,IDX.name AS IndexName 
	FROM sys.data_spaces AS DS 
		 INNER JOIN sys.allocation_units AS AU 
			 ON DS.data_space_id = AU.data_space_id 
		 INNER JOIN sys.partitions AS PA 
			 ON (AU.type IN (1, 3)  
				 AND AU.container_id = PA.hobt_id) 
				OR 
				(AU.type = 2 
				 AND AU.container_id = PA.partition_id) 
		 INNER JOIN sys.objects AS OBJ 
			 ON PA.object_id = OBJ.object_id 
		 INNER JOIN sys.schemas AS SCH 
			 ON OBJ.schema_id = SCH.schema_id 
		 LEFT JOIN sys.indexes AS IDX 
			 ON PA.object_id = IDX.object_id 
				AND PA.index_id = IDX.index_id 
	ORDER BY DS.name 
			,SCH.name 
			,OBJ.name 
			,IDX.name
			
-- Настройки подключения
	Проверить:
	DECLARE @options INT
	SELECT @options = @@OPTIONS

	PRINT @options
	IF ( (1 & @options) = 1 ) PRINT 'DISABLE_DEF_CNST_CHK' 
	IF ( (2 & @options) = 2 ) PRINT 'IMPLICIT_TRANSACTIONS' 
	IF ( (4 & @options) = 4 ) PRINT 'CURSOR_CLOSE_ON_COMMIT' 
	IF ( (8 & @options) = 8 ) PRINT 'ANSI_WARNINGS' 
	IF ( (16 & @options) = 16 ) PRINT 'ANSI_PADDING' 
	IF ( (32 & @options) = 32 ) PRINT 'ANSI_NULLS' 
	IF ( (64 & @options) = 64 ) PRINT 'ARITHABORT' 
	IF ( (128 & @options) = 128 ) PRINT 'ARITHIGNORE'
	IF ( (256 & @options) = 256 ) PRINT 'QUOTED_IDENTIFIER' 
	IF ( (512 & @options) = 512 ) PRINT 'NOCOUNT' 
	IF ( (1024 & @options) = 1024 ) PRINT 'ANSI_NULL_DFLT_ON' 
	IF ( (2048 & @options) = 2048 ) PRINT 'ANSI_NULL_DFLT_OFF' 
	IF ( (4096 & @options) = 4096 ) PRINT 'CONCAT_NULL_YIELDS_NULL' 
	IF ( (8192 & @options) = 8192 ) PRINT 'NUMERIC_ROUNDABORT' 
	IF ( (16384 & @options) = 16384 ) PRINT 'XACT_ABORT'