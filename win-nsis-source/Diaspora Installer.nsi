; Diaspora installer by Hexagon <robinnilsson@gmail.com>

; TODO!
;   * Fetch portableGit binaries
;   * Add batch script for updating diaspora
;   * Check why mongoDB does not start
;   * Add descriptions to all sections
;   * Better in-installer-readme (installer-data/readme.txt)
;   * Modify downloader to use to 'cool' interface
;   * Change back to 1.9.2 as soon as the evetmachine gem is updated

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  !include "Locate.nsh"

;--------------------------------
;General

  ;Name and file
  Name "Diaspora Bundle"
  OutFile "disapora_git.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\Diaspora Root"
  
  ;Request application privileges for Windows Vista
  RequestExecutionLevel user

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "data\README.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "Diaspora" SecDiaspora
  SectionIn RO

  SetOutPath "$INSTDIR"
  CreateDirectory "$INSTDIR\tmp"
  CreateDirectory "$INSTDIR\root"
  CreateDirectory "$INSTDIR\root\opt"
  CreateDirectory "$INSTDIR\root\opt\diaspora"

  SetOutPath "$INSTDIR\"
  File "data\install-gems.bat"
  File "data\run-diaspora.bat"

  SetOutPath "$INSTDIR\tmp\"
  File "data\patch_rbreadline.rb"




  inetc::get /BANNER 	"Downloading Diaspora master zipball from github" \
			"https://github.com/diaspora/diaspora/zipball/master" \
			"$INSTDIR\tmp\diaspora-master.zip"
  Pop $0
  StrCmp $0 "OK" dlok
    MessageBox MB_OK|MB_ICONEXCLAMATION "Diaspora zipball download failed, aborting" /SD IDOK
    Abort

  dlok:

  SetOutPath "$INSTDIR\tmp\"
  nsUnzip::Extract "$INSTDIR\tmp\diaspora-master.zip" /END
  Delete "$INSTDIR\tmp\diaspora-master.zip"

  ${locate::Open} "$INSTDIR\tmp\" "/F=0 /M=diaspora*" $0
  StrCmp $0 0 0 continue
     MessageBox MB_OK "Could not find extracted diaspora files, aborting." /SD IDOK
     Abort

  continue:
  ${locate::Find} $0 $1 $2 $3 $4 $5 $6
  
  CopyFiles "$1\*.*" "$INSTDIR\root\opt\diaspora"

  ${locate::Close} $var

  ;Store installation folder
  WriteRegStr HKCU "Software\Diaspora" "" $INSTDIR
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

Section "Ruby (1.8.7-p302)" SecRuby
  ;SectionIn RO

  inetc::get /BANNER 	"Downloading Ruby" \
			"http://rubyforge.org/frs/download.php/72087/ruby-1.8.7-p302-i386-mingw32.7z" \
			"$INSTDIR\tmp\ruby-1.8.7-p302-i386-mingw32.7z"
  Pop $0
  StrCmp $0 "OK" dlok
  MessageBox MB_OK|MB_ICONEXCLAMATION "Ruby download failed" /SD IDOK
  Abort

  dlok:

  SetOutPath "$INSTDIR\tmp\"

  Nsis7z::ExtractWithDetails "$INSTDIR\tmp\ruby-1.8.7-p302-i386-mingw32.7z" "Extracting %s..."

  Delete "$INSTDIR\tmp\ruby-1.8.7-p302-i386-mingw32.7z" 

  CopyFiles "$INSTDIR\tmp\ruby-1.8.7-p302-i386-mingw32\*.*" "$INSTDIR\root\"

  Delete "$INSTDIR\tmp\ruby-1.8.7-p302-i386-mingw32\*"
  Delete "$INSTDIR\tmp\ruby-1.8.7-p302-i386-mingw32"


SectionEnd

Section "Ruby Devkit (4.5.0)" SecRubyDevkit
  ;SectionIn RO

  inetc::get /BANNER 	"Downloading Ruby Devkit" \
			"https://github.com/downloads/oneclick/rubyinstaller/DevKit-4.5.0-20100819-1536-sfx.exe" \
			"$INSTDIR\tmp\DevKit-4.5.0-20100819-1536-sfx.exe"
  Pop $0
  StrCmp $0 "OK" dlok
    MessageBox MB_OK|MB_ICONEXCLAMATION "Ruby Devkit download failed" /SD IDOK
    Abort

  dlok:

  SetOutPath "$INSTDIR\root\"
  
  Nsis7z::ExtractWithDetails "$INSTDIR\tmp\DevKit-4.5.0-20100819-1536-sfx.exe" "Extracting %s..."

  Delete "$INSTDIR\tmp\DevKit-4.5.0-20100819-1536-sfx.exe" 

SectionEnd

Section "MongoDB (1.6.3)" SecMongo
  ;SectionIn RO

  SetOutPath "$INSTDIR"
  CreateDirectory "$INSTDIR\root\opt\mongodb-data"
  File "data\run-mongodb.bat"

  inetc::get /BANNER 	"Downloading MongoDB" \
			"http://fastdl.mongodb.org/win32/mongodb-win32-i386-1.6.3.zip" \
			"$INSTDIR\tmp\mongodb-win32-i386-1.6.3.zip"
  Pop $0
  StrCmp $0 "OK" dlok
    MessageBox MB_OK|MB_ICONEXCLAMATION "MongoDB download failed, aborting." /SD IDOK
    Abort

  dlok:

  SetOutPath "$INSTDIR\tmp\"
  
  nsUnzip::Extract "$INSTDIR\tmp\mongodb-win32-i386-1.6.3.zip" /END

  Delete "$INSTDIR\tmp\mongodb-win32-i386-1.6.3.zip" 

  CopyFiles "$INSTDIR\tmp\mongodb-win32-i386-1.6.3\*.*" "$INSTDIR\root\"

  Delete "$INSTDIR\tmp\mongodb-win32-i386-1.6.3\*"
  Delete "$INSTDIR\tmp\mongodb-win32-i386-1.6.3"

SectionEnd

Section "ImageMagick (6.6.5)" SecImageMagick
  ;SectionIn RO

  inetc::get /BANNER 	"Downloading ImageMagick" \
			"http://www.imagemagick.org/download/binaries/ImageMagick-6.6.5-Q16-windows.zip" \
			"$INSTDIR\tmp\ImageMagick-6.6.5-Q16-windows.zip"
  Pop $0
  StrCmp $0 "OK" dlok
    MessageBox MB_OK|MB_ICONEXCLAMATION "ImageMagick download failed, aborting." /SD IDOK
    Abort

  dlok:

  SetOutPath "$INSTDIR\tmp\"
  
  nsUnzip::Extract "$INSTDIR\tmp\ImageMagick-6.6.5-Q16-windows.zip" /END

  Delete "$INSTDIR\tmp\ImageMagick-6.6.5-Q16-windows.zip" 

  CreateDirectory "$INSTDIR\root\bin\"
  CopyFiles "$INSTDIR\tmp\ImageMagick-6.6.5-8\*.*" "$INSTDIR\root\bin\"

  Delete "$INSTDIR\tmp\ImageMagick-6.6.5-Q16\*"
  Delete "$INSTDIR\tmp\ImageMagick-6.6.5-Q16"
  
SectionEnd

Section "Ruby Gems" SecRubyGems

  ExecWait "$INSTDIR\install-gems.bat"

SectionEnd
;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_SecRuby ${LANG_ENGLISH} "Fetches latest diaspora"
  LangString DESC_SecMongo ${LANG_ENGLISH} "Fetches mongodb-win32-i386-1.6.3"

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDiaspora} $(DESC_SecDiaspora)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecRuby} $(DESC_SecRuby)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecRubyDevkit} $(DESC_SecRubyDevkit)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecRubyMongo} $(DESC_SecMongo)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

Section "Uninstall"

  ;ADD YOUR OWN FILES HERE...

  Delete "$INSTDIR\Uninstall.exe"

  RMDir "$INSTDIR"

  DeleteRegKey /ifempty HKCU "Software\Modern UI Test"

SectionEnd