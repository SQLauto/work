-- ������
	http://www.sql.ru/articles/mssql/2005/073102partitionedtablesandindexes.shtml
	http://www.cyberguru.ru/database/sqlserver/sqlserver2005-partitioned-tables-indexes-page12.html
	https://msdn.microsoft.com/ru-ru/library/ms188730.aspx
	https://technet.microsoft.com/ru-ru/library/ms191174(v=sql.105).aspx
	https://www.brentozar.com/sql/table-partitioning-resources/
	

-- ��������
	- partitioning is mostly for improved maintenance, fast loads, fast deletes and the ability to spread a table across multiple filegroups; it is not primarily for query performance.
	- � SQL Server ��� ������� � ������� � ���� ������ ��������� �����������������, ���� ���� ��� ������� ����� ���� �� ����� ������. ����������, ������ ������������ ����� ������� ��������������� ������� � ���������� ����������� ������ � ��������. ��� ��������, ��� ���������� � ���������� ����������� ������ � ��������, ���������� ��������� ������, ��������� �������� ����������� ������ � ��������, ��������� �� ����� ������
	- ��������������� ���������� �� ������ �������� ������, � �� ������	
	- ��� ��������� ���������������, �� ��������� ���� ������ ��������  (������������ PK, ����� ������ ���), �� ������ �� 2012
	- ���������� ������� �������� ���� �� ����� ��������. ��� ��������� ����� �������� � ���������� ���� ���������� ���������� ������, SQL Server ��� �� ������ ��� �� ���������� � ������ ����� ������ �������� ����	
	
-- ��������������� �������
	- ��� �������� � ��������� ��������
		sys.system_internals_allocation_units

-- ���� ���������������
	- https://www.simple-talk.com/content/article.aspx?article=1587
	-- ���������������� ������� ()
		- �������� ������ � Enterprise
		- ����� ��������� ������ ����� ��������� ��������, ������������� ������������ ����������
		- ��� ������� �� ���������
		- ����� ���������� �� ��� �������
		- ��� ��������� online ������������ ��������
		- ��������� ����������
		- ����������� 1000/15000 ������
		- ������� ��������������� ������������ (�����������) � ���������� � ������������ �������. ����������� ����� ������
		- ��������� ������ ���������� ��������

	-- ���������������� �������������
		- �������� � ����� ������ �������
		- ����������� 255 ������/������
		- ������ ��������� ������� �� ������ ������������� ���� CONSTRAINT
		- ������ ������ ���������� �� �������������, ����������� ����� �����, � ����� ������� ��������� ��� ������
		- ��� ������, ����� ������� ������������� ����������� ��� ������ ������ ����� ���� ������
		- �� ����� ���������� �������/������ � ������ �������� ������, �������� ��������� �������
		 (�� ��� ����� ���� ����� ���������� ������� ������ ��������� ������) (������ Enterprise Edition)
		- ����� ����� ������ ����� ��������� � �����
		- ���������� �� ������ ������
		- ����� � ������� ����� ���������� �� ������ ������
		- Online ������������ ������� (Enterprise)
		- �������� � ���������� ����������. ��� ���������� ����� �������, ����� ������ ����� ����������
		- �������� ������� �������� ���������� ���� ���� ������������ 1 ������������� �� ��������� ������
		
	-- ��������������
		- ���� �������� �� � ��������� ��, � � ��������� �������. � ���� ���� ��������� ����������������
		
	-- ���������
		- ��������� ����� ������ ������ ���������� �� �������, � �������� ���������� (������� 80/20) ��� ���� �� 50/50
		- Create Federation - ������������ SQL Azure
		
	-- ��������� �������� (�������)
		1. ������������ ������� ������� �� ������ �����
		2. ������ VIEW, ������ �� ��� � �������� ������ ����
	
-- ������� ��������������
	- ������� �������� (��� ����� � ������� ��������) ��������� ������, ������������ ���������� ���������.
	- ������� ��� ���������� ������� ����������� �� ���, ��� ���������, ���� ������� �� ������������ ��������� �������������� ������� ������������ ������������.
	
-- ������������
	1. ������������� ������ ����� ������ �������� ������������������ ���������� ���������� � ���������� ��������, ���������� �������� ����� ������ � ����������, �������������� �������� ����������
	2. ��������������� ������� ��� ������� ����� �������� ������������������ ��������, ���� ��� ��������� ���������� � �������������� � ������ ����� ����� ����������� �������� � ������������ ������������. 
	2. ����������� ��������� �������� OLTP/���������/������ �� FG
	3. �� ���������� ����������� ������ ������. 
	4. ��� ������ � ���������� ������������� ������ ������
	5. ����� ������������ OLTP FG, ���� ������ ����� � ���������� ��������������� �������� �����
	6. �������������� ���������� ����������. ��� 20% ���������, �������� ������ �������� ����� � �� ����� ��������������� ���������� ����������
	
-- ����������
	1. ��������� ����������, �����������, �������������
	2. � ������ ��� ������� ���� �������� ��� ����� ��������������� � ���� �������������� ��� ������� ����� ���������� ���������������
	3. � ������ ��������� ������ �� �������, ������� ����� ����������
	4. ��������� Enterprise ������ �������
	5. ������ ���������� ������� ���� MIX/MAX
		- �������� ����� ���� CROSS APPLY ��� UNION ALL ������ ��������
		
	
-- �����������:
	1. ������ ����� ����� �������������� ���������������� �������, � ��� ����� ������� ������ ��� ���. � ����� ������ ������ SQL Server ������������� ��������� ������ �� ������ �� ������ ��� �� ����� � ������� ���������������, ��� ������������ ��� �������. � ���������� ������ �������������� � �������� ����� �� �������, ��� � �������, ��� ������ ��� ����������� ������������ �������.
	2. �������� �������������� (���������� �� ������� �������) ����������������� ������� ����� ��������� ����������� � ��������� �������:
		- ������� ������� �� ��������������.
		- ���� ������� �������� ���������� � �� �������� ������� ��������������� �������.
		- ��������� ������� ������� ������� � ����������� ����������� � ���������, ������������� ������ ������� ����������.
	3. ��� ��������������� ����������� ������� (����������������� ��� �������������������) ������� ��������������� ���������� �������� �� ��������, ����������� � ����� ����������� �������.
	4. ��� ��������������� ����������������� ������� ������� ��������������� ������ ����������� � ����� �������������. ��� ��������������� ������������� ����������������� �������, ���� ������� ��������������� �� ������ ���� � ����� �������������, SQL Server �� ��������� ��������� ������� ��������������� � ������ ������ ����������������� �������.
	5. ����������� ����������� ������ ����� �������� �� ������������������ SQL Server ��� ���������� ����������������� ������� � ���� �� ���� ����������� ��� ����������. ����� ���������, ��������, ����� ������ �� �������� �� ����� ������� �������� ��� �� ����� ���������������� ��������, ���� ����� ���������� � �������. ��� ������ ����� ������, ��� ������ ��������� ����������� ������. ��� ��� �����������, ��� � ��� ������������� �������� ����� ������������� ������� ����� ����������� ������, ���� SQL Server ��������� ������� ������������ ��� ���������� ������ �������� �� ����������������� ����������
	6. � ������� ������ ���� ������ ������, � ������� ����� ������������ ����� ������
	7. �������� ��������, ��� ����� �������, �� ����������� �� �������������� ��������, ������ ���� ������� ��� ��������� �� ������������ ������. ������ ����� ������������ �� ����� ������� ��������. 
	8. SQL Server 2016 ������������ �� ��������� �� 15 000 ������. � �������, �������������� SQL Server 2012, ���������� ������ �������������� 1000 �� ���������. � �������� x86 �������� ������� ��� ������� � ������ ������ ����� 1000 ��������, �� �� ��������������.
	9. ����� �������� ������������ ������������������ � ������� ������������ ��������, �������������, ����� ����� ������ � ������������ ���� ���������. �� �� ��������� 64 (��� ������������ ����� ������������ �����������, ������� SQL Server ����� ������������).
	10. ��� ������� ���������� ������������ ������ ������������� ������������ ��� �� ����� 16 ��
	11. ���������� ���������, ������� �� ������� �� ������� ������. �������� �� < 200, � <= 199
	12. ������� ���������� �������� AND $PARTITION.PF(RowID) = 2;
	
-- �������� ���������������:
	1. ������� ������ ������� ���������������
		- � ������ ����� ���� �� ����� 1000 ������.
	2. ����� ���������������
	3. ��� ��������������� ����� ��������� CONSTRAINT, ����� �������� ������������
	
-- ������� ������ �� ������� � �������
	1. ���������� �����
	2. � ������� ���������� ������ ���� ������ ������
	
	- ����� ���������� ������� � �������� ������ � ��� ������������ ���������������� �������.
	- ����� ������������ ������ �� ����� ���������������� ������� � ������.
	- ����� �������� ������ ��� �������� ������ �������.
	
-- Index/�������
	- ����� �������������� �������� �������, ��� �������
	- ���� ������� ����������� ������, ����� ����������� ����� ����������� ������ ����� ����� ������ 1 ������
	- ���� ������� ������������� ������, ����� ����������� ����� ����������� ������ ������ ������� ���� �������
	- ���� ������� �� ����������������� � �������������, �� ����������� ������ ���������� �� ���������� �������
	
-- �����������
	- CREATE PARTITION FUNCTION as RANGE right/right for values:
		- ���������, � ����� ������� ��������� �������� ����������� �������� boundary_value [ ,...n ] (� ����� ��� ������) ��� ������, ����� �������� ���������� ���� ������������� ����������� ��������� Database Engine �� ����������� ����� �������.
		- ��-�����f��� LEFT	

-- *** ������ ***
	- ������� ������ �������� ������ � �����
	CREATE PARTITION FUNCTION pfOrders2011(datetime2(0))
	as RANGE right for values
	(
		'2011-02-01','2011-03-01'...,'2011-12-01'
	)

	CREATE PARTITION scheme psOrders2011
	as PARTITION pfOrders2011
	all to ([Data2011])  -- �������� ������
	
	-- ����� �������� ������� � �����, ������ ������� � ��������� � ���
		CREATE TABLE par (part int, num int, gp int) ON psOrders2011 (part)
	
	-- CREATE Creates a partition function called myRangePF1 that will partition a table into four partitions
	CREATE PARTITION FUNCTION myRangePF1 (int)
		AS RANGE LEFT FOR VALUES (1, 100, 1000,5000) ;
	GO
	-- Creates a partition scheme called myRangePS1 that applies myRangePF1 to the four filegroups created above
	CREATE PARTITION SCHEME myRangePS1
		AS PARTITION myRangePF1
		TO (test1fg, test2fg, test3fg, test4fg,[PRIMARY]) ;
	GO

	-- ���������� ����� ������ ���������� ���������. ���������� ������ � ������� ���������� ������ � NEXT USED �����

	ALTER PARTITION SCHEME myRangePS1
		NEXT USED test5fg;
		
	ALTER PARTITION FUNCTION myRangePF1 ()
	SPLIT RANGE (50000);
	
-- ����� ������� ������ ����� CONSTRAINT � ������ �������, � �������� � VIEW

	CREATE TABLE Orders2011
	(
		OrderId int not null,
		OrderDate datetime2(0) not null
		...
		constraint CHK_Orders2011_Final
		check(OrderDate >= '2011-01-01' AND OrderDate < '2012-01-01')
	)
	ON [Data2011]	
		
	- ����� ����������� ������ �� ����������� � ��������, ������� ���������� �������� �� �������� �������� ������
	
-- �������� �� ������� ��������������� � �������
	SELECT *   
	FROM sys.tables AS t   
	JOIN sys.indexes AS i   
		ON t.[object_id] = i.[object_id]   
		--AND i.[type] IN (0,1)   
	JOIN sys.partition_schemes ps   
		ON i.data_space_id = ps.data_space_id   
	WHERE t.name = 'TableName';   
	
-- ����������� ��������� �������� ��� ���������������� �������
	SELECT t.name AS TableName, i.name AS IndexName, p.partition_number, p.partition_id, i.data_space_id, f.function_id, f.type_desc, r.boundary_id, r.value AS BoundaryValue   
	FROM sys.tables AS t  
	JOIN sys.indexes AS i  
		ON t.object_id = i.object_id  
	JOIN sys.partitions AS p  
		ON i.object_id = p.object_id AND i.index_id = p.index_id   
	JOIN  sys.partition_schemes AS s   
		ON i.data_space_id = s.data_space_id  
	JOIN sys.partition_functions AS f   
		ON s.function_id = f.function_id  
	LEFT JOIN sys.partition_range_values AS r   
		ON f.function_id = r.function_id and r.boundary_id = p.partition_number  
	WHERE t.name = 'TableName' AND i.type <= 1  
	ORDER BY p.partition_number;
	
-- ����������� ������� ��������������� ���������������� �������
	SELECT   
		t.[object_id] AS ObjectID   
		, t.name AS TableName   
		, ic.column_id AS PartitioningColumnID   
		, c.name AS PartitioningColumnName   
	FROM sys.tables AS t   
	JOIN sys.indexes AS i   
		ON t.[object_id] = i.[object_id]   
		AND i.[type] <= 1 -- clustered index or a heap   
	JOIN sys.partition_schemes AS ps   
		ON ps.data_space_id = i.data_space_id   
	JOIN sys.index_columns AS ic   
		ON ic.[object_id] = i.[object_id]   
		AND ic.index_id = i.index_id   
		AND ic.partition_ordinal >= 1 -- because 0 = non-partitioning column   
	JOIN sys.columns AS c   
		ON t.[object_id] = c.[object_id]   
		AND ic.column_id = c.column_id   
	WHERE t.name = 'par';
	
-- ����� �������� ��� ������ 
	SELECT $PARTITION.[partition_function](patition_column) AS Partition,* FROM ...
	
	
-- ***** ������� ���������� *****

-- ������� ���������������:
	1. ��� ������ � ����� �����
	2. ���������� �����, �������, ���������� (�� ���� � ��� � �������� � ����������� ������ ������)
	3. �������� � ���������� ��������
	4. ��������� �����������
	5. �������������� ����� �����
	6. �������� �� ����������� 

-- ����������
	1. ��������������� ������ ���� ���������� ��������
	2. ��������������� �������� ������ ������ ������������� � ���� ����� �������������
	3. ���������� ��������� ����������
	4. ���������� ������ ������ (���� ��������������� �� �� ����������� �������, �� � ������� �������������
	   ����������� ����, �� �������� ���������� ����������)
	5. ��������� ��������
	6. ������������� �������� � Linked Servers
	7. �������� � ���������� ������ � Foreign Key

-- ������������
	1. ���� ����� ������� ������������������
	2. ������������� ��������

-- ��� �� ����� ������������ ������
	1. ������������ ���������������

-- ��������� ��������������� (������� ��������� �� ������ ������������� � ������, � �������� ������������� ���� ���������)
	- ���������� ������������ �������� ������ � �����������
	- ����������, ��������������, AlwaysOn ����� �������� ������ � ��� ������, ���� ��������� ��� � ������
	  ��������� �� ���� ��������

-- ��������������� � �������� ������
	1. ��� ������� ������� �� ���������
		- ��������� ��������������
		- ����������� � �������� �������
	2. ��������� �������
	3. ���������� ����� ��������������� � ���������� ���������
		- �������� ������ �� ����. ��������� ����� ���� �������� ��� Read Only

-- ���������� ������� ����� � ������� �������
	select partition_id, partition_number, rows
	  from sys.partitions
	  where object_id = object_id ( N'dbo.Table_1', N'U' );
	go

-- ��������� ������	10 � 100
	alter partition scheme ps_range_left
	next used [PRIMARY]; -- ���� ����� �������� ������
	alter partition function pf_range_left() 
	split range (50); -- ��������� ����� ��������, ������� �������� 10-50 � 50-100

-- ���������
	alter partition function pf_range_left()
	merge range (50);
	go	
	
-- I. ��� Windows Asure
-- ������ ���������
	CREATE federation Fed(FID int range)
	GO
	ALTER federation Fed split at (fid = 100)
	GO

-- ������� ��������� ���������
	SELECT * FROM sys.federations

-- ������������� � ���������
	- ��������� ��� ���������� ���� ��
	use federation Fed(fid=0) with reset, filtering = off

-- ����� �������� � ��������, ���� ������� ������� �� �� ������
	CREATE TABLE FedTable
	(
		ID int not null primary key,
		Val nchar(255)
	)
	federation on (fid=id) -- ������ ���� ������� �������� � �� ������, �� ������ �������� ������ � id < 100

-- ��������� � Windows Asure
	- ���������� ���������� ������ �� ������ ������ ��������� � ������ ������ �������
	- ����� ����������� ������� �� � 150 GB
	- ��������� ����� ������ � ������ ���������
	
--***** ����������/COMPRESS *****
	- �� �������� � ntext, nvarchar(max)
