@echo off
COLOR 07
cls
echo - Installing Ruby gems for Diaspora Bundle

set path=%path%;"%~dp0root\bin";"%~dp0root\lib";"%~dp0root\mingw\bin";"%~dp0root\mingw\lib "

mkdir "%~dp0log"

:: ---------------------------------------------------------------
ECHO Applying simple rbreadline 1.8.7 patch

CALL move "%~dp0tmp\patch_rbreadline.rb" "%~dp0root\lib\ruby\site_ruby\1.8\rbreadline.rb"
IF %ERRORLEVEL% NEQ 0 (

ECHO  - Fail
) ELSE (

ECHO  - Success
)


:: ---------------------------------------------------------------
ECHO Installing gems

CALL gem install bundler rails 1>>"%~dp0log\output.log" 2>>"%~dp0log\error.log"
IF %ERRORLEVEL% NEQ 0 (

ECHO  - Fail
) ELSE (

ECHO  - Success
)


:: ---------------------------------------------------------------
ECHO Forcing eventmachine gem to be git version (step 1)

CALL gem install specific_install 1>>"%~dp0log\output.log" 2>>"%~dp0log\error.log"
IF %ERRORLEVEL% NEQ 0 (

ECHO  - Fail
) ELSE (

ECHO  - Success
)

:: ---------------------------------------------------------------
ECHO Forcing eventmachine gem to be git version (step 2)

CALL gem specific_install -l http://github.com/eventmachine/eventmachine.git 1>>"%~dp0log\output.log" 2>>"%~dp0log\error.log"
IF %ERRORLEVEL% NEQ 0 (

ECHO  - Fail
) ELSE (

ECHO  - Success
)


RM "%~dp0root\opt\diaspora\Gemfile.lock" 1>>"%~dp0log\output.log" 2>>"%~dp0log\error.log"

:: ---------------------------------------------------------------
ECHO Bundle install (installing dependencies)

CALL bundle install 1>>"%~dp0log\output.log" 2>>"%~dp0log\error.log"
IF %ERRORLEVEL% NEQ 0 (
ECHO  - Fail
) ELSE (
ECHO  - Success
)


CD "%~dp0" 1>>"%~dp0log\output.log" 2>>"%~dp0log\error.log"
