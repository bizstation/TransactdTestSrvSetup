@echo off
@REM ===============================================================
@REM    Copyright (C) 2016 BizStation Corp All rights reserved.
@REM 
@REM    This program is free software; you can redistribute it and/or
@REM    modify it under the terms of the GNU General Public License
@REM    as published by the Free Software Foundation; either version 2
@REM    of the License, or (at your option) any later version.
@REM 
@REM    This program is distributed in the hope that it will be useful,
@REM    but WITHOUT ANY WARRANTY; without even the implied warranty of
@REM    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
@REM    GNU General Public License for more details.
@REM 
@REM    You should have received a copy of the GNU General Public License
@REM    along with this program; if not, write to the Free Software 
@REM    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  
@REM    02111-1307, USA.
@REM ===============================================================

rem %1 baseDir

set baseDir=%~dp0

rem remove last \
set baseDir=%baseDir:~0,-1%

set srcdir=%~dp0
set baseDrive=%~d0
if not "%1"=="" (
  set baseDir=%1
  set baseDrive=%~d1
)

%baseDrive%
cd %baseDir%

set statusMsg="Creating config file for mysqld"
call :createIni %baseDir%\my.ini 1 %baseDir%\data %baseDir%
if not ERRORLEVEL 0 goto handleError
call :createIni %baseDir%\my2.ini 2 %baseDir%\data2 %baseDir%
if not ERRORLEVEL 0 goto handleError


set statusMsg="Creating shortcuts for start server"
cscript //nologo "%srcdir%"\mklink.js "%CD%\mysqld-3306.lnk" "%baseDir%\bin\mysqld.exe" "--defaults-file="""%baseDir%\my.ini""" --console"
if not ERRORLEVEL 0 goto handleError
cscript //nologo "%srcdir%"\mklink.js "%CD%\mysql_client-3306.lnk" "%baseDir%\bin\mysql.exe" "-uroot -p"
if not ERRORLEVEL 0 goto handleError


echo %baseDir% | find "5.7" >NUL
if not ERRORLEVEL 1 (
set statusMsg="Create database for mysql 5.7"
call %baseDir%\bin\mysqld.exe --initialize-insecure
if not ERRORLEVEL 0 goto handleError
)

echo Starting mysqld...  Please wait 10 seconds.
start /i /min %baseDir%\bin\mysqld.exe --defaults-file=my.ini --console
timeout 10>NUL

set statusMsg="Installing Transactd plugin"
call "%srcdir%"\install_transactd.cmd root "" transactd 2
if not ERRORLEVEL 0 goto handleError

echo Stopping mysqld...  Please wait 10 seconds.
call %baseDir%\bin\mysqladmin -u root --password="" shutdown>NUL
timeout 10>NUL

if not exist %baseDir%\data2 (
set statusMsg="Copying data for port 3307"
mkdir %baseDir%\data2
xcopy %baseDir%\data\*.* %baseDir%\data2 /s /y>NUL
if not ERRORLEVEL 0 goto handleError
)
del %baseDir%\data2\auto.cnf /Q /F>NUL

set statusMsg="Creating shortcuts for start server"
cscript //nologo "%srcdir%"\mklink.js "%CD%\mysqld-3307.lnk" "%baseDir%\bin\mysqld.exe" "--defaults-file="""%baseDir%\my2.ini""" --console"
if not ERRORLEVEL 0 goto handleError
cscript //nologo "%srcdir%"\mklink.js "%CD%\mysql_client-3307.lnk" "%baseDir%\bin\mysql.exe" "-uroot -p -P3307"
if not ERRORLEVEL 0 goto handleError
echo;
echo   =====  SETUP HAS BEEN COMPLETED! =====
echo;

set /P ss="Please push any key to close."

exit /b 0

:handleError
echo;
echo   =====  SETUP HAS BEEN CANCELED AT %statusMsg%  =====
echo;
set /P ss="Please push any key to close."

exit /b 1


rem ---------------  createIni  ---------------------------
:createIni
rem %1 ini file path
rem %2 server id
rem %3 datadir
rem %4 basedir


set port=3306
set tdport=8610

if "%2"=="2" (set port=3307)
if "%2"=="3" (set port=3308)
if "%2"=="4" (set port=3309)

if "%2"=="2" (set tdport=8611)
if "%2"=="3" (set tdport=8612)
if "%2"=="4" (set tdport=8613)

echo [mysqld]> %1
echo basedir=%4>>%1
echo character-set-server=utf8>>%1
echo port=%port%>> %1
echo server-id=^%2>> %1
echo datadir=%3>> %1
echo log-bin=mysql-bin>> %1
echo binlog_format=row>> %1
echo log-slave-updates>> %1
echo loose-gtid_mode=ON>> %1
echo loose-enforce-gtid-consistency>> %1
echo innodb_file_per_table>> %1
echo loose-transactd_port=%tdport%>> %1
goto :EOF
rem --------------------------------------------------------
