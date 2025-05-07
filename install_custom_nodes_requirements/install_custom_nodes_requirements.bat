@echo off
setlocal EnableDelayedExpansion

:: Get the directory where the batch script is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo Script is located at: %SCRIPT_DIR%

:: --- Initialize variables for installation type detection ---
set "PYTHON_EXE="
set "COMFYUI_APP_DIR="
set "VENV_ACTIVATE_SCRIPT="
set "INSTALL_TYPE=Unknown"

:: --- Define potential paths based on script location ---
:: Case 1: Script is in parent of ComfyUI folder (e.g., C:\Tools with ComfyUI in C:\Tools\ComfyUI)
set "STANDARD_COMFYUI_SUBDIR=%SCRIPT_DIR%\ComfyUI"
set "VENV_IN_STANDARD_SUBDIR=%STANDARD_COMFYUI_SUBDIR%\venv\Scripts\activate.bat"

:: Case 2: Script is inside the ComfyUI folder (e.g., C:\ComfyUI with venv in C:\ComfyUI\venv)
set "VENV_IN_SCRIPT_DIR=%SCRIPT_DIR%\venv\Scripts\activate.bat"

:: Case 3: Portable ComfyUI (e.g., C:\ComfyUI_portable with python_embeded and ComfyUI subfolder)
set "PORTABLE_PYTHON_EXE=%SCRIPT_DIR%\python_embeded\python.exe"
set "PORTABLE_COMFYUI_APP_SUBDIR=%SCRIPT_DIR%\ComfyUI"

echo.
echo --- Detecting ComfyUI Installation Type ---

echo Checking for Standard ComfyUI (venv in 'ComfyUI' subdirectory relative to script)...
if exist "%VENV_IN_STANDARD_SUBDIR%" (
    echo Found: Standard ComfyUI with venv in '%STANDARD_COMFYUI_SUBDIR%\venv'.
    set "INSTALL_TYPE=StandardVenv"
    set "COMFYUI_APP_DIR=%STANDARD_COMFYUI_SUBDIR%"
    set "VENV_ACTIVATE_SCRIPT=%VENV_IN_STANDARD_SUBDIR%"
    set "PYTHON_EXE=python"
) else (
    echo Not found.
    echo Checking for Standard ComfyUI (venv in script's directory, assuming script is inside ComfyUI main folder)...
    if exist "%VENV_IN_SCRIPT_DIR%" (
        echo Found: Standard ComfyUI with venv in '%SCRIPT_DIR%\venv'.
        set "INSTALL_TYPE=StandardVenv"
        set "COMFYUI_APP_DIR=%SCRIPT_DIR%"
        set "VENV_ACTIVATE_SCRIPT=%VENV_IN_SCRIPT_DIR%"
        set "PYTHON_EXE=python"
    ) else (
        echo Not found.
        echo Checking for Portable ComfyUI structure (python_embeded and 'ComfyUI' app subfolder at script's directory level)...
        if exist "%PORTABLE_PYTHON_EXE%" (
            if exist "%PORTABLE_COMFYUI_APP_SUBDIR%" (
                echo Found: Portable ComfyUI with python_embeded and '%PORTABLE_COMFYUI_APP_SUBDIR%'.
                set "INSTALL_TYPE=Portable"
                set "PYTHON_EXE=%PORTABLE_PYTHON_EXE%"
                set "COMFYUI_APP_DIR=%PORTABLE_COMFYUI_APP_SUBDIR%"
                :: VENV_ACTIVATE_SCRIPT remains undefined for portable
            ) else (
                echo Found 'python_embeded' but the required 'ComfyUI' application subdirectory ('%PORTABLE_COMFYUI_APP_SUBDIR%') is missing.
            )
        ) else (
            echo Not found. Portable 'python_embeded' directory not found at '%SCRIPT_DIR%'.
        )
    )
)

:: --- Final Check for Installation Type ---
if "%INSTALL_TYPE%"=="Unknown" (
    echo.
    echo Error: Could not determine ComfyUI installation type.
    echo Please ensure this script is placed correctly and your ComfyUI installation is intact:
    echo   1. For standard install (script outside ComfyUI): In the parent directory of 'ComfyUI' (e.g. C:\Tools\ if ComfyUI is C:\Tools\ComfyUI and venv is C:\Tools\ComfyUI\venv).
    echo   2. For standard install (script inside ComfyUI): In the main 'ComfyUI' directory (e.g. C:\ComfyUI\ if venv is C:\ComfyUI\venv).
    echo   3. For portable install: In the root of the portable ComfyUI directory (e.g., C:\AI\ComfyUI_windows_portable\), which should contain 'python_embeded' and a 'ComfyUI' subdirectory.
    pause
    exit /b 1
)

echo.
echo --- Configuration Determined ---
echo Installation Type: %INSTALL_TYPE%
echo Python Executable: %PYTHON_EXE%
echo ComfyUI App Dir: %COMFYUI_APP_DIR%
if defined VENV_ACTIVATE_SCRIPT (
    echo Venv Activation Script: %VENV_ACTIVATE_SCRIPT%
)
echo ---

:: --- Validations ---
:: Check if ComfyUI App directory exists (this should be guaranteed if INSTALL_TYPE was set, but double-check)
if not exist "%COMFYUI_APP_DIR%" (
    echo Error: ComfyUI application directory determined as '%COMFYUI_APP_DIR%' but it was not found.
    pause
    exit /b 1
)

:: Check if Python executable is valid (for portable, check file; for venv, 'python' is assumed to be on PATH after activation)
if "%INSTALL_TYPE%"=="Portable" (
    if not exist "%PYTHON_EXE%" (
        echo Error: Portable Python executable not found at %PYTHON_EXE%
        pause
        exit /b 1
    )
)

:: Check if install_custom_nodes_requirements.py exists
set "REQUIREMENTS_SCRIPT_PATH=%COMFYUI_APP_DIR%\install_custom_nodes_requirements.py"
if not exist "%REQUIREMENTS_SCRIPT_PATH%" (
    echo Error: 'install_custom_nodes_requirements.py' not found at '%REQUIREMENTS_SCRIPT_PATH%'
    pause
    exit /b 1
)

:: --- Execution ---
:: Activate virtual environment if determined to be a standard venv setup
if defined VENV_ACTIVATE_SCRIPT (
    echo.
    echo Activating virtual environment...
    call "%VENV_ACTIVATE_SCRIPT%"
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to activate virtual environment at '%VENV_ACTIVATE_SCRIPT%'
        pause
        exit /b %ERRORLEVEL%
    )
    echo Virtual environment activated.
)

echo.
echo Changing directory to ComfyUI App Dir: '%COMFYUI_APP_DIR%'
cd /d "%COMFYUI_APP_DIR%"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to change directory to '%COMFYUI_APP_DIR%'
    pause
    exit /b %ERRORLEVEL%
)
echo Current directory: %CD%

echo.
echo Running 'install_custom_nodes_requirements.py'...
echo Command: "%PYTHON_EXE%" "%REQUIREMENTS_SCRIPT_PATH%"
"%PYTHON_EXE%" "%REQUIREMENTS_SCRIPT_PATH%"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to execute 'install_custom_nodes_requirements.py' using "%PYTHON_EXE%".
    echo Exit code: %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Installation complete.
pause
endlocal
exit /b 0