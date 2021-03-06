-- diskspd
	-- https://gallery.technet.microsoft.com/DiskSpd-a-robust-storage-6cd2f223
	
-- DiskSpeed.ps1
	-- GUI для diskspd
		1. В системе должны быть разрешены сценарии
			- Запустить PS как администратор
			- Set-ExecutionPolicy Unrestricted
			- Если хотим выключить Set-ExecutionPolicy Restricted
		2. В папке с этим скриптом должен быть запускной файл diskspd.exe

-- Запуск через PS. Необходимо быть на том же томе, где распологается программа, чтобы не открывалось новое окно

-- random 
.\diskspd -c2G -b64K -F8 -r -o32 -W60 -d60 -Sh testfile.dat -- read
.\diskspd -c2G -w100 -b64K -F8 -r -o32 -W60 -d60 -Sh testfile.dat -- write

-- sequence
.\diskspd -c2G -b64K -F8 -T1b -s8b -o32 -W60 -d60 -Sh testfile.dat -- read
.\diskspd -c2G -w100 -b64K -F8 -T1b -s8b -o32 -W60 -d60 -Sh testfile.dat -- write


-- 
C:\DISTR\'SQL Server'\ds\x86fre\diskspd -c2G -b64K -F8 -r -o32 -W60 -d60 -Sh L:\LOGS\testfile.dat 

N1:
L - 150/117
D - 488/480
T - 304/303

N2: 
L - 130/180/130
D - 536/555
T - 303/297

-- 
C:\DISTR\'SQL Server'\ds\x86fre\diskspd -c2G -w -b64K -F8 -r -o32 -W60 -d60 -Sh L:\LOGS\testfile.dat 

N1:

L - 160/119/160
D - 490/


N2:
L - 192/140/190
D - 562
T - 288/301

-- Эмуляция нагрузки на сервер
	Нагрузка на сервер (RML Utilities), ostress