@ECHO OFF

SET port=3000

ECHO Starting Diaspora ...

SET path=%path%;"%~dp0root\bin"";%~dp0root\mingw\bin"
cd "%~dp0root\opt\diaspora\"
CALL bundle exec thin -p %port% start 

pause