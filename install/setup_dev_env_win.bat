:: CodeProject SenseAI Server 
::
:: Windows Development Environment install script
::
:: We assume we're in the source code /install directory.
::

@echo off
cls
setlocal enabledelayedexpansion

:: verbosity can be: quiet | info | loud
set verbosity=quiet

:: If files are already present, then don't overwrite if this is false
set forceOverwrite=false

:: Show output in wild, crazy colours
set techniColor=true

:: Basic App Features

set enableFaceDetection=True
set enableObjectDetection=True
set enableSceneDetection=True

set PROFILE=windows_native
set CUDA_MODE=False
set PORT=5000


:: Basic locations

:: The location of the solution root directory relative to this script
set rootPath=..

:: SenseAI specific :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: The name of the dir holding the frontend API server
set senseAPIDir=API

:: The name of the startup settings file
set settingsFile=CodeProject.SenseAI.config

:: DeepStack specific :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: The name of the dir holding the DeepStack analysis services
set deepstackDir=DeepStack

:: The name of the dir containing the Python code itself
set intelligenceDir=intelligencelayer

:: The name of the dir containing the AI models themselves
set modelsDir=assets

:: The name of the dir containing persisted DeepStack data
set datastoreDir=datastore

:: The name of the dir containing temporary DeepStack data
set tempstoreDir=tempstore

:: The name of the Environment variable setup file
set envVariablesFile=set_environment.bat

:: Shared :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: The location of large packages that need to be downloaded
:: a. From contrary GCP
rem set storageUrl=https://storage.googleapis.com/codeproject-senseai/
:: b. From AWS
set storageUrl=https://codeproject-ai.s3.ca-central-1.amazonaws.com/sense/installer/
:: c. Use a local directory rather than from online. Handy for debugging.
set storageUrl=C:\Dev\CodeProject\CodeProject.AI\install\cached_downloads\

:: The name of the source directory
set srcDir=src

:: The name of the dir, within the current directory, where install assets will be downloaded
set downloadDir=downloads

:: The name of the dir containing the Python interpreter
set pythonDir=python37

:: The name of the dir holding the backend analysis services
set analysisLayerDir=AnalysisLayer

:: Absolute paths :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: The absolute path to the root directory of CodeProject.SenseAI
set currentDir=%cd%
cd %rootPath%
set absoluteRootDir=%cd%
cd %currentDir%

:: The location of the backend analysis layer relative to the root of the solution directory
set analysisLayerPath=%absoluteRootDir%\%srcDir%\%analysisLayerDir%

if /i "%1" == "false" set techniColor=false
if /i "%techniColor%" == "true" call :setESC

:: Set Flags

set pipFlags=-q -q
set rmdirFlags=/q
set roboCopyFlags=/NFL /NDL /NJH /NJS /nc /ns  >nul 2>nul

if "%verbosity%"=="info" set pipFlags=-q
if "%verbosity%"=="info" set rmdirFlags=/q
if "%verbosity%"=="info" set roboCopyFlags=/NFL /NDL /NJH

if "%verbosity%"=="loud" set pipFlags=
if "%verbosity%"=="loud" set rmdirFlags=
if "%verbosity%"=="loud" set roboCopyFlags=

call :WriteLine Yellow "Setting up CodeProject.SenseAI Development Environment" 
call :WriteLine White ""
call :WriteLine White "========================================================================"
call :WriteLine White ""
call :WriteLine White "                 CodeProject SenseAI Installer"
call :WriteLine White ""
call :WriteLine White "========================================================================"
call :WriteLine White ""

:: ===============================================================================================
:: 1. Ensure directories are created and download required assets

:: Create some directories
call :Write White "Creating Directories..."

:: For downloading assets
if not exist %downloadDir%\ mkdir %downloadDir%

:: For DeepStack
set deepStackPath=%analysisLayerPath%\%deepstackDir%
if not exist %deepStackPath%\%tempstoreDir%\ mkdir %deepStackPath%\%tempstoreDir%
if not exist %deepStackPath%\%datastoreDir%\ mkdir %deepStackPath%\%datastoreDir%

call :WriteLine Green "Done"

call :Write White "Downloading utilities and models: "
call :WriteLine Gray "Starting"

:: Clean up directories to force a re-download if necessary
if /i "%forceOverwrite%" == "true" (
    if exist %downloadDir%\%modelsDir% rmdir /s %rmdirFlags% %downloadDir%\%modelsDir%
    if exist %downloadDir%\%pythonDir% rmdir /s %rmdirFlags% %downloadDir%\%pythonDir%
)

:: Download whatever packages are missing 
if not exist %downloadDir%\%modelsDir% (
    call :Download %storageUrl% %downloadDir%\ models.zip %modelsDir% ^
                   "Downloading models..."
)
if not exist %downloadDir%\python37 (
    call :Download %storageUrl% %downloadDir%\ python37.zip %pythonDir% ^
                   "Downloading Python interpreter..."
)

:: Move downloads into place
call :Write White "Moving downloads into place..."
if exist %downloadDir%\%modelsDir% robocopy /e %downloadDir%\%modelsDir% %deepStackPath%\%modelsDir% !roboCopyFlags! > NUL
call :WriteLine Green "Done"

:: Copy over the startup script
call :Write White "Copying over startup script..."
copy /Y "Start_SenseAI_Win.bat" "!absoluteRootDir!\!srcDir!" >nul 2>nul
call :WriteLine Green "Done."

call :Write White "Downloading utilities and models: "
call :WriteLine Green "Completed"

:: ===============================================================================================
:: 2. Create & Activate Virtual Environment: DeepStack specific / Python 3.7

call :Write White "Creating Virtual Environment..."
if exist %deepStackPath%\venv (
    call :WriteLine Green "Already present"
) else (
    %downloadDir%\%pythonDir%\python.exe -m venv %deepStackPath%\venv
    call :WriteLine Green "Done"
)

call :Write White "Enabling our Virtual Environment..."

set currentDir=%cd%
cd !deepStackPath!

set VIRTUAL_ENV=%cd%\venv\Scripts

cd !currentDir!

if not defined PROMPT set PROMPT=$P$G
set PROMPT=(venv) !PROMPT!

set PYTHONHOME=
set PATH=!VIRTUAL_ENV!;%PATH%

if errorlevel 1 goto errorNoPythonVenv
call :WriteLine Green "Done"

:: Ensure Python Exists
call :Write White "Checking for Python 3.7..."
python --version | find "3.7" > NUL
if errorlevel 1 goto errorNoPython
call :WriteLine Green "present"

if "%verbosity%"=="loud" where Python


:: ===============================================================================================
:: 3. Install PIP packages

:: ASSUMPTION: If venv\Lib\site-packages\torch exists then no need to do this

call :Write White "Checking for required packages..."

if not exist %deepStackPath%\venv\Lib\site-packages\torch (

    call :WriteLine Yellow "Installing"

    call :Write White "Installing Python package manager..."
    python -m pip install --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org --upgrade pip !pipFlags!
    call :WriteLine Green "Done"

    REM call :Write White "Installing Packages into Virtual Environment..."
    REM pip install -r %deepStackPath%\%intelligenceDir%\requirements.txt !pipFlags!
    REM call :WriteLine Green "Success"

    REM We'll do this the long way so we can see some progress
    set currentOption=
    for /f "tokens=*" %%x in (%deepStackPath%\%intelligenceDir%\requirements.txt) do (

        set line=%%x

        if "!line!" == "" (
            set currentOption=
        ) else if "!line:~0,2!" == "##" (
            set currentOption=
        ) else if "!line:~0,12!" == "--find-links" (
            set currentOption=!line!
        ) else (
            call :Write White "    PIP: Installing !line!..."
            REM echo python.exe -m pip install !line! !currentOption! !pipFlags!
            python.exe -m pip install !line! !currentOption! !pipFlags!
            call :WriteLine Green "Done"

            set currentOption=
        )
    )
) else (
    call :WriteLine Green "present."
)

:: ===============================================================================================
:: 5. Let's do this!


:: a) SET all Env. variables and store in a json file that will be loaded by the .NET API app

:: For DeepStack
set APPDIR=%deepStackPath%\%intelligenceDir%
set MODELS_DIR=%deepStackPath%\%modelsDir%
set DATA_DIR=%deepStackPath%\%datastoreDir%
set TEMP_PATH=%deepStackPath%\%tempstoreDir%
set VISION_FACE=%enableFaceDetection%
set VISION_DETECTION=%enableObjectDetection%
set VISION_SCENE=%enableSceneDetection%

:: For CodeProject.SenseAI

set modulesEnabled=,
if /i "%enableFaceDetection%"   == "true" set modulesEnabled=!modulesEnabled!VISION_FACE,
if /i "%enableObjectDetection%" == "true" set modulesEnabled=!modulesEnabled!VISION_DETECTION,
if /i "%enableSceneDetection%"  == "true" set modulesEnabled=!modulesEnabled!VISION_SCENE,
set modulesEnabled=!modulesEnabled:~1,-1!

call :Write White "Saving Environment variables..."

set CPSENSEAI_ROOTDIR=!absoluteRootDir!
set CPSENSEAI_APPDIR=!srcDir!
set CPSENSEAI_APIDIR=!senseAPIDir!
set CPSENSEAI_MODULES=!modulesEnabled!
set CPSENSEAI_ANALYSISDIR=!analysisLayerDir!
set CPSENSEAI_COMFIG=Debug
set CPSENSEAI_PRODUCTION=False
set CPSENSEAI_BUILDSERVER=True

call save_environment !absoluteRootDir!\!srcDir!\!envVariablesFile! !absoluteRootDir!\!srcDir!\!settingsFile!
call :WriteLine White "Done."

:: and we're done.
call :WriteLine Yellow "Development Environment setup complete" 
call :WriteLine White ""
call :WriteLine White ""

goto:eof



:: sub-routines

:setESC
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
      set ESC=%%b
      exit /B 0
    )
    exit /B 0

:setColor
    REM echo %ESC%[4m - Underline
    REM echo %ESC%[7m - Inverse

    if /i "%2" == "foreground" (
        REM Foreground Colours
        if /i "%1" == "Black"       set currentColor=!ESC![30m
        if /i "%1" == "DarkRed"     set currentColor=!ESC![31m
        if /i "%1" == "DarkGreen"   set currentColor=!ESC![32m
        if /i "%1" == "DarkYellow"  set currentColor=!ESC![33m
        if /i "%1" == "DarkBlue"    set currentColor=!ESC![34m
        if /i "%1" == "DarkMagenta" set currentColor=!ESC![35m
        if /i "%1" == "DarkCyan"    set currentColor=!ESC![36m
        if /i "%1" == "Gray"        set currentColor=!ESC![37m
        if /i "%1" == "DarkGray"    set currentColor=!ESC![90m
        if /i "%1" == "Red"         set currentColor=!ESC![91m
        if /i "%1" == "Green"       set currentColor=!ESC![92m
        if /i "%1" == "Yellow"      set currentColor=!ESC![93m
        if /i "%1" == "Blue"        set currentColor=!ESC![94m
        if /i "%1" == "Magenta"     set currentColor=!ESC![95m
        if /i "%1" == "Cyan"        set currentColor=!ESC![96m
        if /i "%1" == "White"       set currentColor=!ESC![97m
    ) else (
        REM Background Colours
        if /i "%1" == "Black"       set currentColor=!ESC![40m
        if /i "%1" == "DarkRed"     set currentColor=!ESC![41m
        if /i "%1" == "DarkGreen"   set currentColor=!ESC![42m
        if /i "%1" == "DarkYellow"  set currentColor=!ESC![43m
        if /i "%1" == "DarkBlue"    set currentColor=!ESC![44m
        if /i "%1" == "DarkMagenta" set currentColor=!ESC![45m
        if /i "%1" == "DarkCyan"    set currentColor=!ESC![46m
        if /i "%1" == "Gray"        set currentColor=!ESC![47m
        if /i "%1" == "DarkGray"    set currentColor=!ESC![100m
        if /i "%1" == "Red"         set currentColor=!ESC![101m
        if /i "%1" == "Green"       set currentColor=!ESC![102m
        if /i "%1" == "Yellow"      set currentColor=!ESC![103m
        if /i "%1" == "Blue"        set currentColor=!ESC![104m
        if /i "%1" == "Magenta"     set currentColor=!ESC![105m
        if /i "%1" == "Cyan"        set currentColor=!ESC![106m
        if /i "%1" == "White"       set currentColor=!ESC![107m
    )
    exit /B 0

:WriteLine
    SetLocal EnableDelayedExpansion
    set resetColor=!ESC![0m

    if "%~2" == "" (
        Echo:
        exit /b 0
    )

    if /i "%techniColor%" == "true" (
        REM powershell write-host -foregroundcolor %1 %~2
        call :setColor %1 foreground
        echo !currentColor!%~2!resetColor!
    ) else (
        Echo %~2
    )
    exit /b 0

:Write
    SetLocal EnableDelayedExpansion
    set resetColor=!ESC![0m

    if /i "%techniColor%" == "true" (
        REM powershell write-host -foregroundcolor %1 -NoNewline %~2
        call :setColor %1 foreground
        <NUL set /p =!currentColor!%~2!resetColor!
    ) else (
        <NUL set /p =%~2
    )
    exit /b 0


:Download
    SetLocal EnableDelayedExpansion

    REM "https://codeproject-ai.s3.ca-central-1.amazonaws.com/sense/installer/"
    set storageUrl=%1 

    REM "downloads/" - relative to the current directory
    set downloadToDir=%2

    REM eg packages_for_gpu.zip
    set fileToGet=%3

    REM  eg packages
    set dirToSave=%4

    REm output message
    set message=%5

    if "!message!" == "" set message="Downloading !fileToGet!..."

    REM Doesn't provide progress as %
    REM powershell Invoke-WebRequest -Uri !storageUrl: =!!fileToGet! -OutFile !downloadDir!!dirToSave!.zip

    call :Write White !message!
    powershell Start-BitsTransfer -Source !storageUrl: =!!fileToGet! ^
                                  -Destination !downloadToDir!!dirToSave!.zip
    if errorlevel 1 (
        call :WriteLine Red "An error occurred that could not be resolved."
        exit /b
    )

    if not exist !downloadToDir!!dirToSave!.zip (
        call :WriteLine Red "An error occurred that could not be resolved."
        exit /b
    )

    call :Write White "Expanding..."

    REM Try tar first. If that doesn't work, fall back to pwershell (slow)
    set tarExists=true
    pushd !downloadToDir!
    mkdir !dirToSave!
    copy !dirToSave!.zip !dirToSave! > nul 2>nul
    pushd !dirToSave!
    tar -xf !dirToSave!.zip > nul 2>nul
    if "%errorlevel%" == "9009" set tarExists=false
    rm !dirToSave!.zip > nul 2>nul
    popd
    popd

    if "!tarExists!" == "false" (
        powershell Expand-Archive -Path !downloadToDir!!dirToSave!.zip ^
                                  -DestinationPath !downloadToDir! -Force
    )

    del /s /f /q !downloadToDir!!dirToSave!.zip > nul

    call :WriteLine Green "Done."

    exit /b

:: Jump points

:errorNoPython
call :WriteLine White ""
call :WriteLine White ""
call :WriteLine White "---------------------------------------------------------------------------"
call :WriteLine Red "Error: Python not installed"
call :WriteLine Red "Go to https://www.python.org/downloads/release/python-3712/ for Python 3.7"
goto:eof

:errorNoPythonVenv
call :WriteLine White ""
call :WriteLine White ""
call :WriteLine White "---------------------------------------------------------------------------"
call :WriteLine Red "Error: Python Virtual Environment activation failed"
call :WriteLine Red "Go to https://www.python.org/downloads/ for the latest version"
goto:eof