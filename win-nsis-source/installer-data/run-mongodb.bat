@ECHO OFF

CLS

ECHO Starting MongoDB ...

CALL "%~dp0root\bin\mongod.exe" --dbpath "%~dp0root\opt\mongodb-data\"

pause