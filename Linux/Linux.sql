-- Вопросы
	- mount	
	sudo -- ??
	nohub -- ??

-- nohup
	- Пишет nohub.out в папку, откуда запущено
	- nohup ./scriptFLC2T.sh 20160130004352 &
	
-- sudo
	sudo su -
	
	-- если сломал sudo (vi /etc/sudoers)
		pkexec visudo
		
	-- vi /etc/sudoers
		dzaytsev ALL=(ALL:ALL) NOPASSWD: ALL
		
-- Узнать тип файла
	file /ggegerg/geheah.txt
	
-- Расширения файлов
	.so = dll (shared object)
	
-- Файлы открытые процессом
	lsof -p 52783 | grep ip -- какие файлы открыты процессом

-- netstat
	Информация о сети
	-- Параметры
		Можно везде добавить -p, тогда будет показываться SPID
		netstat -na -- Команда покажет IP-адрес вместо хоста, номер порта вместо имени порта, UID вместо имени пользователя.
		netstat -a -- Перечислить все порты
		netstat -at -- Перечислить все TCP порты
		netstat -au -- Перечислить все UDP порты
		netstat -l -- Перечислить все прослушиваемые порты
		netstat -lt -- Перечислить все прослушиваемые TCP порты
		netstat -lu -- Перечислить все прослушиваемые UDP порты
		netstat -lx -- Перечислить прослушиваемые UNIX сокеты
		netstat -s -- Показать статистику всех портов
		netstat -st -- Показать статистику всех TCP портов
		netstat -su -- Показать статистику всех UDP портов
		netstat -c -- Вывод информации непрерывно
		netstat -an | grep ':80' -- Каким процессом пользуется определённый порт
		netstat -i -- Список всех сетевых интерфейсов
		netstat -ie -- Список всех сетевых интерфейсов (расширенная информация)
		netstat -lnptux -- Полезная, резюмирующая, команда
	
-- top
	Показывает загрузку системы, по-умолчанию по CPU
	Почти то же самое что и vmstat
	
	-- Параметры
		k и вводим SPID
		top -u db2inst1 -- процессы конкретного поьзователя
		top -p 123 -- информацию по SPID
		top после запуска 1, будет показана нагрузка по CPU
		top после d > ввести время обновления
		top -n 2 -- Через 3 обновления выйти из top
		top потом shift+A получим данные в более структурированном виде
		
-- iotop
	iotop -o -- показать только активные процессы
	iotop -o -a -- показать суммарную информацию за время просмотра
	
-- vmstat
	Возвращает данные о загрузке системы
	vmstat 1 -- каждую 1 секунду обновлять данные
	vmstat 2 5 -- Каждые 2 секунды, всего 5 повторов
	vmstat -s -- меняет формат вывода информации
		-- Proc
		r — количество процессов в очереди на выполнение процессором (если значение > 0 — налицо нагрузка на процессор);
		b — количество процессов, ожидающих операций I/O (если значение > 0 — налицо нагрузка на диски и/или файловую систему).
		-- Memory
		swpd — количество блоков, перемещённых в swap;
		free — свободная память (без учёта памяти, занятой буферам и кэшом, тоже, что выводит free в колонке Mem:free, см. тут>>>);
		buff — буферы памяти (см. там же);
		cache — кеш (см. там же);		
		-- SWAP
		si (swap in) — количество блоков в секунду, которое система считывает из раздела или файла swap в память; -- В идеале, значение обоих должно быть около нуля или, по крайней мере, не более 10 блоков/секунду.
		so (swap out) — и наоборот, количество блоков в секунду, которое система перемещает из памяти в swap. -- В идеале, значение обоих должно быть около нуля или, по крайней мере, не более 10 блоков/секунду.
		-- IO
		bi (blocks in) — количество блоков в секунду, считанных с диска;
		bo (blocks out) — количество блоков в секунду, записанных на диск;
		-- CPU
		us (user time) — % времени CPU, занятый на выполнение «пользовательских» (не принадлежащих ядру) задач;
		sy (system time) — % времени CPU, занятый на выполнение задач ядра (сеть, I/O задачи, прерывания и т.п.);
		id (idle) — % времени в бездействии (ожидании задач);
		wa — % времени CPU, занятый на ожидание операций I/O;

-- less
	Аналог more, но отличается возможность читать вверх-вниз
	
-- sar
	Snapshot нагрузки системы
	Изначально может быть отключен
	Получает данные за сутки
	/var/log/sa
	sar -f /var/log/sa/sa03 -- показать данные за предыдушие периоды
	-- Параметры
		%usr: - процент процессорного времени, потраченного на пользовательские процессы, такие как приложения, сценарии оболочки или взаимодействие с пользователем.
		%sys: - процент процессорного времени, потраченного на выполнение задач ядра. В примере это значение получилось большим, потому что я беру данные из генератора случайных чисел ядра.
		%wio: - процент процессорного времени, затраченного на ожидание ввода-вывода в/из блочных устройств, например, жесткого диска.
		%idle: - процент времени, которое процессор простаивал.
		
-- Поиск
	-- В файле
		-- grep
			| grep что ищем в выводе -- Обязательно строку поиска в двойные кавычки
			| grep "..." -A 5 -- 5 строк после найденного значение
			| grep "..." -B 5 -- 5 строк до найденного значение
			
			-- -l 
				- Ignore case distinctions in both the PATTERN and the input files.
		
		-- egrep			
			| egrep "log|backup" -- даёт возможность искать несколько значений сразу
		
	-- На файловой системы/find
		- find может выполнить любую команду к результату вывода
		find / -name file1 -- искать файлы или директорию начиная с /
		find / -user user1 -- искать файлы и директории относящиеся к user1
		find /home/user1 -name \*.bin -- искать файлы с расширением .bin в директории /home/user1
		find /usr/bin -type f -atime +100 -- искать бинарные файлы, которые не запускались 100 дней
		find /usr/bin -type f -mtime -10 -- найти файлы созданные или изменённые за 10 дней
		find / -name \*.deb -exec chmod 755 '{}' \; --найти файлы с расширением .deb и изменить права доступа
		locate \*.ps найти файлы с расширением .ps
		whereis halt показать путь к указанной программе, в данном случае halt
		which halt показать полный путь к указанной программе, в данном случае halt
		
-- История, hostory
	- Показывает историю операций не только в текущей сессии, а вообще
	history 10 -- 10 последних команд
	history -c -- очистить историю
	history | grep ...
	
	-- Повторное выполнение/repeat
		!! - выполнить последнюю команду
		!-1 - выполнить предпоследнюю команду
		!10 -- выполнить 10 событие
		ctrl + p -- показать предыдущю команду
		
	-- Редактировать команды
		ctrl + r далее можем искать нужный символ
		
-- Посмотреть активные фоновые задачи
	job
	
	-- Перейти на последний фоновый job
		fg

-- Читалка/работа с файлами
	more filename (посмотреть содержимое файла)	
	less аналог more
	tail -100 -- Вернуть последние 100 строк из файла
		tail -n 10 errorlog  -f -- вывести 10 последних строк и регулярно обновлять
	
-- Текстовый редактор vi
	vi /home/text.txt
		i -- Режим вставки
		:q! -- Завершить редактирования файла с отменой всех изменений. Эта команда очень часто используется при возникновении трудностей.
		:w -- Записать файл (независимо от того, был ли он изменен или нет). 
		ZZ  -- Записать файл, если он был изменен, а затем выйти из редактора.
		:e! -- Редактировать текущую копию файла на диске. 
		:g/^$/d -- Удаление всех пустых строк. ^ - начало строки, $ - конец строки, /d - удалить к найденному, :g - поиск
		:%g/^--/d -- удалить всю строку где есть такие символы
		:%s/^--/d -- удалить только совпадение

-- Содержимое папки
	ls
	ls -l -- use a long listing format (подробности о каждом вложении)
	-r -- сортировка в обратном порядке
	-t -- сортировать по показываемому временному штампу.
	
	-- Текущий рабочий каталог, с указанием пути
		pwd

	
-- Переход в другую папку
	cd
	
	-- Перейти на папку вышу
		cd ..
	
-- Копирование/copy
	cp (копирование)
		- cp /home/janet/clients/filename.sql /home/nick/customers
		
-- Статистика по процессу/от кого запущено	
	ps - показать свои процесс (посмотреть как показать все процессы)
	ps -axu (все процессы)/запущенные программы
	ps -p 1 -- выводит процесс с указанным SPID
	echo $$ (вывести свой процесс)
	ps --ppid spid_потомка (главного процесс) -- Будут показаны все зависимые от данного потомка потоки
	ps -ef | grep sysc (db2sysc - процесс db2) -- посмотреть процессы с фильтром
	
-- kill
	- Изначально посылается команда terminate, что не всегда позволяет завершить процесс. -9 принудительно убивает процесс
	kill -9 SPID -- принудительно убить процесс
	
	killall name_process -- убить всё для программ с укаанным именем
	killall -s 9 name_process -- принудительно убить
	
	sudo kill 123 -- если не хватает прав
	
-- iostat
	iostat -xk -t 10 -- Обновлять данные каждые 10 секунд
	-- парметры
		%u/%util -- общая загрузка

	
-- вывести на экран информацию из файла
	cat 

-- Очистить экран
	Ctrl+L
	
-- Узнать подробности команды, полное описание команды
	man ls

-- Краткая справка
	ls -help

-- Время	
	date -- Узнать время
	date -s "20150515" -- установка времени	

-- Папки
	-- Создать папку	
		mkdir $HOME/diag	
		
	-- Права доступа
		-- Показать права доступа на папку
			ls -dl /home/folder
			
		-- Изменить владельца папки/файла
			chown -R vasja:users /home/vasja
			
		-- Изменить группу папки/файла
			chgrp db2iadm3 /mnt/data/FLC2E
			
		-- Узнать группу пользователя
			id -a db2inst1
			
		-- chmod		
			- У папки-файла может быть только 1 владелец, 1 группа и все остальные
			- владельца файла (u);
			- других пользователей, входящих в группу владельца (g);
			- всех прочих пользователей (o);
			
			-- Цифровой вариант выдачи прав
				- Read (4)
				- WRITE (2)
				- EXECUTE (1)
			
			- формат
				1. -rwxrwxrwx(-r-xr-xr-x) (то есть если не хотим давать какой-ти тип прав, то ставим -) -- По 3 символа на каждый тип владельцев (u + g + o)
				
			-- Дать права
				chmod ugo+rwx /u02/seconddb -- дать все возможные права на папку
				chmod g+rw file1				
				chmod +rw file1 (дать права ReadWrite всем)
			
			-- Убрать права
				chmod go-r file1 (Убираем права на чтение у группы и всех остальных)
				chmod -R o-rwx ~/linuxrussia.com/ (рекурсивно убрать все права у пользователей внутри папки)
				
	-- изменения владельца или группы
		sudo chown имя_нового_владельца:имя_новой_группы имя_файла_или_директории
		sudo chown :имя_новой_группы имя_файла_или_директории (только группа)
		sudo chown имя_нового_владельца имя_файла_или_директории (только владелец)
		sudo chown -R имя_нового_владельца:имя_новой_группы имя_файла_или_директории (так же можно использовать рекурсию)
	
	
-- Удаление файлов/папок/удалить
	rm -r /home/username/

-- ************************	
-- ***** Пользователи *****
-- ************************

-- Имя текущего пользователя
	whoami
	
-- Группы текущего пользователя
	groups

-- Откуда запускается команда
	whitch db2
	
-- Информация о файле
	file /../.../.../filename
	
-- Каждые несколько секунд обновлять результат команды
	watch 'cat /proc/loadabg' -- по-умолчанию запускается каждые 2 секунды
	watch -n 10 'ls -la' -- запускать каждые 10 секунд
	watch 'ls -l filename' -- наблюдать за скачиванием файла
	watch db2 list utilities show detail -- Показывать каждые несколько секунду информацию об утилитах
		
-- Переключение пользователя
	su - root (зайт за рута)
	
	- Создать пользователя
		useradd name
	
	- Иногда домашняя дирректория не создаётся автоматически, тогда нужно будет выполнить
		useradd -m name
		
	- Задать пароль пользователю
		passwd user_name
		
	- Вся информация о паролях хранится
		/etc/passwd
		
	- Удалить пользоваетля
		userdel username 
		
		-- Если пользователь активен
			pgrep -u test
			ps -fp $(pgrep -u test)
			killall -KILL -u test
			userdel -r test
		
	- Список всех пользователей
		cat /etc/passwd
		cat /etc/passwd | awk '/bash/{print}' (вывести не системных пользователей)
	
	-- Список активных пользователей
		who
	
	-- Отключить пользователя/logout
		pkill -KILL -u db2inst2
	
-- .bash_history

-- ********************************
-- ***** Информация о сервере *****
-- ********************************

-- Данные о сервере
	env
	
-- Версия операционной системы
	cat /proc/version
	
-- Информацию о CPU
	cat /proc/cpuinfo
		-- Количество процессоров
			cat /proc/cpuinfo | grep processor | wc -l
		-- Количество ядер
			cat /proc/cpuinfo | grep 'core id'
	
-- Информация о RAM
	 cat /proc/meminfo
	 
-- Общая информация/Можно посмотреть виртуальная машина или нет
	lscpu
	 
-- ip adrecc/ipconfig
	ifconfig
	
	cd /etc/ 
	vi hosts
	
	-- Режим вставки/редактирования
		нужно нажать i
		
	-- Выходы
		:q! (без сохранения)
		:wq (с сохранением)
	
-- Информация о системе (версия и тд)
	uname -a
	
-- Логи
	/var/log
	/var/log/messages - основной
	cd /tmp/

-- Переменные окружения
	- Создать
		a = qqq
		
	- Вызвать
		echo $alias

	- Удалить
		unset a
	
	-- Показать переменные окружения
		set
		env
	
-- Показать алиасы
	- Сокращённый вызов команд
	- Есть глобальные и локальные
	alias
		.bash_profile -- заставляет пользователю использьвать/не использовать алиасы
		
	- Добавить alias
		alias qq='call 2015'
		
	- Удалить alias
		unalias qq
	
-- Посмотреть размер дисков/место на дисках/диски
	df -h
	df -hl /test/filename
	
	-- Рамер файлов в папке
		du -sh ./*                                            */(дописал чтобы не портилось форматирование)
		du -h /test/filename
		
-- Устанвока модулей
	- yum is the primary tool for getting, installing, deleting, querying, and managing Red Hat Enterprise Linux RPM software packages from official Red Hat software repositories, as well as other third-party repositories. yum is used in Red Hat Enterprise Linux versions 5 and later. Versions of Red Hat Enterprise Linux 4 and earlier used up2date.

	yum install telnet
	
-- Архивация
	-- Упаковать
		tar -cvf test.tar test
		или
		tar -zcvf tast.tar.gz test
		или
		gzip test  – упакует, добавит gz и УДАЛИТ! файл
	-- Посмотреть:
		tar -tvf test.tar
		tar -ztvf test.tar.gz
	-- Распаковать:
		tar -xvf test.tar
		tar -zxvf test.tar.gz
		gunzip test.gz  – распакует и УДАЛИТ! test.gz

-- pscp
	- Работает только на Windows, нужно скачать и запускать из командной строки
	pscp.exe dkx6kpqadm@fsrumosdt0001:/home/local/FS01/dkx6kpqadm/scriptFLC2C.sh . -- Скопировать из Linux на Windows
	.\pscp C:\GIT\mssql-tools.rpm dzaytsev@10.24.3.189:/home/dzaytsev/ -- С Windows на Linux
	
-- scp
	- Используется на Linux and Windows (using WinSCP)
	- Синтасис такой же как и pscp.exe
	
-- bash
	-- Дескрипторы
		exec 6<&0 -- Перенаправить stdin в дескриптор 6
		exec 0<&6 6<&- -- Вернуть всё обратно закрыв дескриптор 6
		- В системе по-умолчанию всегда открыты три "файла" -- stdin (клавиатура), stdout (экран) и stderr (вывод сообщений об ошибках на экран).
		- С каждым открытым файлом связан дескриптор файла. [1] Дескрипторы файлов stdin, stdout и stderr -- 0, 1 и 2, соответственно. При открытии дополнительных файлов, дескрипторы с 3 по 9 остаются незанятыми
		
	echo $LAGN -- Показать язык сервера-пользователя (переменная окружения)
	cd ~username -- Покажет где твой home
	expr match "где" "что" -- поиск вхождения
	expr "где" "что" -- Получение результата, который будет найден через регулярное выражение

	-- export
		Позволяет передать переменную в дочерний процесс, изначально в дочернем процессе не видны переменные родителя
		$ a=linuxcareer.com
		$ echo $a
		$ export a
		$ bash
		$ echo $a
		
		export -- Покажет все переменные, которые экспортируются
		export myvar=10 -- Можно задать переменную и сразу объявить её экспортируемой
		export -f function_name -- export функции
		export -n myvar -- Удаление переменной из экспорта

-- shell		
	# which db2
	/usr/bin/which: no db2 in (/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin)

	Ну и вообще, db2 ставится под rootом, потом создается экземпляр, в том числе и непривилегированный пользователь для него (экземпляра).
	Создаются shell скрипты, срабатывающие при логине или смене пользователя:

	$ cat ~/.bashrc
	# .bashrc

	# Source global definitions
	if [ -f /etc/bashrc ]; then
			. /etc/bashrc
	fi

	# User specific aliases and functions

	# The following three lines have been added by UDB DB2.
	if [ -f /home/db2inst1/sqllib/db2profile ]; then
		. /home/db2inst1/sqllib/db2profile
	fi

	В db2profile экспортируется переменная PATH:

	 path_list="bin adm misc db2tss/bin"
		 class_list="java/db2java.zip java/db2jcc.jar java/sqlj.zip function \
		   java/db2jcc_license_cisuz.jar java/db2jcc_license_cu.jar \
		   java/runtime.zip tools/clpplus.jar tools/antlr-3.2.jar tools/jline-0.9.93.jar"

		 for tmp_entry in ${path_list?}; do
			AddRemoveString PATH ${CUR_INSTHOME?}/${tmp_entry?} r
		 done
	....

	В результате получается так:

	$ echo $PATH
	/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/db2inst1/sqllib/bin:/home/db2inst1/sqllib/adm:/home/db2inst1/sqllib/misc:/home/db2inst1/bin
	
-- What is curl
	curl is a tool to transfer data from or to a server, using one of the supported protocols (DICT, FILE, FTP, FTPS, GOPHER, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP, SCP, SFTP, SMB, SMBS, SMTP, SMTPS, TELNET and TFTP). The command is designed to work without user interaction.
	
-- Посмотреть установленные пакеты
	rpm -qa
	rpm -ql mssql-server -- дополнительная информация по пакету
	rpm -qf /usr/bin/htpasswd -- найти к какому пакету принадлежит папка
	rpm -evv mssql-server -- удалить пакет mssl-server
	rpm -qi package_name-- дополнительная информация об установленном пакете
	rpm -qip sqlbuddy-1.3.3-1.noarch.rpm -- дополнительная информация о ещё не установленном пакете
	
-- Перезагрузка / restart
	shutdown -r
	
-- Понять какой номер ошибки или завершения выдаёт команда
	echo $?