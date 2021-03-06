
-- ***** SQL Server *****
	-- Недостатки
		1. Пользователи не автономные, в Oracle иначе
		2. Tempdb одно на все БД.
		3. Нет материализованных представлений
		4. Блокировки
		5. Нет сбора статистики автоматом (не агрегированной/абсолютной)
		6. При Restore в AON, нужно будет переподнять все реплики
		
	-- Достоинства
		1. ”же 5 лет занимает лидирующие позиции среди Ѕƒ по наименьшему количеству у¤звимостей
		2. ”величение реплик с 4 до 8 дл¤ Always On
		3. Легко настроить и сконфигурировать и администрировать
		
	-- И плюс и минус
		1. Большое расширение ANSI SQL-92. Такое как INNER JOIN, LEFT OUTER, RIGHT OUTER JOIN (больше функционал, но сложнее делать кросплатформенные решения)

-- ***** Oracle *****
	-- Недостатки
		1. Нет типа данных bit
		2. Дороговизна
		3. Версионность накладывает доп. нагрузку по обеспечению возврата данных на момент старта транзакции
		4. In-memory создано только для аналитики. Это просто колонки в памяти
		5. Не очевидные команды
		6. 40% на странице оставлено для обновления строк (но это настройки по-умолчанию, можно поменять)
		7. PL\SQL и SQL запускаются в разных engine и при переключении контекстов могут быть проблемы
	
	-- Достоинства
		1. Параллелизм на уровне таблицы
		2. Материализованные представления
		3. При standby можно восстановить Primary и если есть возможность откатиться flashback на Secondary. Очень актуально для больших БД
		4. Возможность кэширования результатов запросов
		
	-- И плюс и минус
		1. Лог перезаписываться даже в Full
		2. If table has multiple indexes, careful consideration needs to be given by which index to order table
		

-- ***** PostgreSQL *****
	-- Недостатки
		1. Хуже работает с памятью и как следствие больше IO

	
-- ***** Узнать *****
	1. Как борятся с грязным чтением в Oracle
	2. Как обрабатываются исключения в Oracle и обрабатываются ли вообще
	3. Сжатие?
	4. Кэширование данных на клиентской стороне?
	
-- ***** Сравнение блокировочного и версионного механизма *****
	-- Блокировки
		1. Такой тип БД работает на более слабом железе
		2. Последовательность действий
	
	-- Версионность
		- Плюсы:
			1. Нет ожиданий при массовой работе
		- Минусы
			1. Требует больше памяти
			2. Требует больше IO
			
