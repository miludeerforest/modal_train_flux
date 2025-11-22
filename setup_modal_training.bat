@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ===== 可自定义的默认路径 =====
set "DEFAULT_PYTHON_EXE=C:\Users\sxm2\scoop\apps\miniforge\25.9.1-0\python.exe"
set "DEFAULT_REPO_DIR=C:\ai-toolkit"
set "DEFAULT_REPO_URL=https://github.com/miludeerforest/modal_train_flux.git"
set "DEFAULT_CONFIG_FILE=config/modal_train_lora_flux.yaml"

REM ===== 让用户手动输入或接受默认值 =====
echo 请输入 Python 可执行文件路径，直接回车使用默认值:
echo 默认: %DEFAULT_PYTHON_EXE%
set "PYTHON_EXE=%DEFAULT_PYTHON_EXE%"
set /p INPUT_PYTHON_EXE="> "
if defined INPUT_PYTHON_EXE set "PYTHON_EXE=%INPUT_PYTHON_EXE%"

echo.
echo 请输入仓库克隆路径，直接回车使用默认值:
echo 默认: %DEFAULT_REPO_DIR%
set "REPO_DIR=%DEFAULT_REPO_DIR%"
set /p INPUT_REPO_DIR="> "
if defined INPUT_REPO_DIR set "REPO_DIR=%INPUT_REPO_DIR%"

REM 规范化路径末尾的反斜杠，避免重复\
if "%REPO_DIR:~-1%"=="\" set "REPO_DIR=%REPO_DIR:~0,-1%"

echo.
echo 请输入仓库克隆地址，直接回车使用默认值:
echo 默认: %DEFAULT_REPO_URL%
set "REPO_URL=%DEFAULT_REPO_URL%"
set /p INPUT_REPO_URL="> "
if defined INPUT_REPO_URL set "REPO_URL=%INPUT_REPO_URL%"

echo.
echo 请输入配置文件相对路径，直接回车使用默认值:
echo 默认: %DEFAULT_CONFIG_FILE%
set "CONFIG_FILE=%DEFAULT_CONFIG_FILE%"
set /p INPUT_CONFIG_FILE="> "
if defined INPUT_CONFIG_FILE set "CONFIG_FILE=%INPUT_CONFIG_FILE%"

echo.
echo 是否需要执行克隆步骤？[Y/N，直接回车默认Y]
set "CLONE_CHOICE=Y"
set /p INPUT_CLONE="> "
if defined INPUT_CLONE set "CLONE_CHOICE=%INPUT_CLONE%"

echo.
echo 使用的参数:
echo PYTHON_EXE : %PYTHON_EXE%
echo REPO_DIR   : %REPO_DIR%
echo REPO_URL   : %REPO_URL%
echo CONFIG_FILE: %CONFIG_FILE%
echo CLONE?     : %CLONE_CHOICE%
echo.

if not exist "%PYTHON_EXE%" (
    echo [ERROR] 找不到指定的 Python 可执行文件: %PYTHON_EXE%
    echo 请安装 Python 或重新输入有效路径。
    pause
    exit /b 1
)

REM Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] This script is not running with administrator privileges.
    echo Some features may not work correctly.
    echo.
    echo Please run this script as administrator:
    echo 1. Right-click on this script
    echo 2. Select "Run as administrator"
    echo.
    echo Do you want to continue anyway? [Y/N]
    set /p CONTINUE_NOADMIN="> "
    if /i not "%CONTINUE_NOADMIN%"=="Y" (
        echo Setup cancelled. Please restart with administrator privileges.
        pause
        exit /b 1
    )
    echo.
)

echo === FLUX LoRA Training Setup Script ===

echo.
echo This script will help you set up the environment for training LoRA models with FLUX:
echo  - Install required software (Python 3.10, Git) if not already installed
echo  - Clone the ai-toolkit repository to C:\ai-toolkit (to avoid Windows path length issues)
echo  - Set up virtual environment and dependencies
echo  - Configure Modal and Hugging Face tokens
echo.
echo NOTE: The repository will be cloned to %REPO_DIR%
echo This location is chosen to prevent Windows path length limitations.
echo.
echo IMPORTANT: Make sure you have:
echo - Installed Python 3.10 or higher
echo - Installed Git
echo - Registered accounts on Modal and Hugging Face
echo - Accepted FLUX.1-dev license on Hugging Face (if using it)
echo.
echo Do you want to continue? [Y/N]
set /p CONTINUE="> "
if /i not "%CONTINUE%"=="Y" (
    echo Setup cancelled by user.
    pause
    exit /b 0
)
echo.

REM Check git availability up front
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed or not in PATH. Please install Git first: https://git-scm.com/downloads
    pause
    exit /b 1
)

echo [1/6] Setting up Git configuration...
REM Enable long paths in Git
git config --system core.longpaths true
if %errorlevel% neq 0 (
    echo [WARNING] Could not enable Git long path support. Try running as Administrator.
)

echo [2/6] Checking/Cloning ai-toolkit repository...
if "%REPO_DIR%"=="" (
    echo [ERROR] REPO_DIR 为空，请重新运行脚本并输入有效路径。
    pause
    exit /b 1
)

if /i "%CLONE_CHOICE%"=="N" (
    echo 跳过克隆步骤，直接进入后续流程...
    if exist "%REPO_DIR%\" (
        cd /d "%REPO_DIR%"
    ) else (
        echo [WARNING] 目录 %REPO_DIR% 不存在，后续步骤可能失败，请确认。
    )
) else (
    if exist "%REPO_DIR%\" (
        echo Found existing ai-toolkit folder in %REPO_DIR%, skipping clone...
        cd /d "%REPO_DIR%"
    ) else (
        REM 计算父目录与目标目录名，使用延迟展开避免语法错误
        set "PARENT_DIR="
        set "REPO_NAME="
        for %%I in ("%REPO_DIR%") do (
            set "PARENT_DIR=%%~dpI"
            set "REPO_NAME=%%~nxI"
        )
        if not defined PARENT_DIR set "PARENT_DIR=C:\"
        REM 去掉末尾反斜杠，防止 cd // 报错
        if "!PARENT_DIR:~-1!"=="\" set "PARENT_DIR=!PARENT_DIR:~0,-1!"
        if "!PARENT_DIR!"=="" set "PARENT_DIR=C:\"
        if not exist "!PARENT_DIR!" (
            echo [ERROR] 父目录不存在: !PARENT_DIR!
            pause
            exit /b 1
        )
        pushd "!PARENT_DIR!"
        git clone "%REPO_URL%" "!REPO_NAME!"
        set "CLONE_ERR=!errorlevel!"
        popd
        if not "!CLONE_ERR!"=="0" (
            echo [ERROR] Could not clone repository from %REPO_URL%.
            pause
            exit /b 1
        )
        cd /d "%REPO_DIR%"
    )
)

echo [3/6] Updating submodules...
git submodule update --init --recursive

echo [4/7] Creating virtual environment...
"%PYTHON_EXE%" -m venv venv
call venv\Scripts\activate

echo [5/7] 安装/升级 Modal CLI...
"%PYTHON_EXE%" -m pip install --upgrade modal

echo [6/7] 安装项目依赖...
"%PYTHON_EXE%" -m pip install python-dotenv huggingface_hub oyaml

echo [7/7] 初始化 Modal CLI（参考 https://modal.com/docs/guide/apps ）...
echo ============================================================
echo 选择 Modal 配置方式:
echo   M) 浏览器登录 (modal setup)  [默认]
echo   T) 手动输入 token (modal token set)
echo ============================================================
set "MODAL_SETUP_MODE=M"
set /p INPUT_MODAL_MODE="选择方式 [M/T，回车默认M]: "
if defined INPUT_MODAL_MODE set "MODAL_SETUP_MODE=%INPUT_MODAL_MODE%"

echo.
if /i "%MODAL_SETUP_MODE%"=="T" goto DO_MODAL_TOKEN_SET
if /i "%MODAL_SETUP_MODE%"=="M" goto DO_MODAL_SETUP

echo [ERROR] 输入无效，仅支持 M 或 T。
pause
exit /b 1

:DO_MODAL_SETUP
"%PYTHON_EXE%" -m modal setup || (
    echo [ERROR] modal setup 失败，请排查后重试。
    pause
    exit /b 1
)
goto AFTER_MODAL_SETUP

:DO_MODAL_TOKEN_SET
setlocal enabledelayedexpansion
echo 可直接粘贴完整命令 (例如: modal token set --token-id ak-... --token-secret as-...)
set "MODAL_TOKEN_CMD="
set /p MODAL_TOKEN_CMD="> "
set "PARSED_ID="
set "PARSED_SECRET="
if defined MODAL_TOKEN_CMD (
    for /f "tokens=5,7" %%A in ("!MODAL_TOKEN_CMD!") do (
        set "PARSED_ID=%%A"
        set "PARSED_SECRET=%%B"
    )
    if not defined PARSED_ID goto DO_MODAL_TOKEN_MANUAL
    if not defined PARSED_SECRET goto DO_MODAL_TOKEN_MANUAL
    "%PYTHON_EXE%" -m modal token set --token-id "!PARSED_ID!" --token-secret "!PARSED_SECRET!" || (
        echo [ERROR] modal token set 执行失败，请检查输入。
        endlocal
        pause
        exit /b 1
    )
    endlocal
    goto AFTER_MODAL_SETUP
)

:DO_MODAL_TOKEN_MANUAL
set "MODAL_TOKEN_ID="
set "MODAL_TOKEN_SECRET="
echo 请输入 token id (格式 ak-...):
set /p MODAL_TOKEN_ID="> "
echo 请输入 token secret (格式 as-...):
set /p MODAL_TOKEN_SECRET="> "
"%PYTHON_EXE%" -m modal token set --token-id "!MODAL_TOKEN_ID!" --token-secret "!MODAL_TOKEN_SECRET!" || (
    echo [ERROR] modal token set 失败，请检查输入。
    endlocal
    pause
    exit /b 1
)
endlocal
goto AFTER_MODAL_SETUP

:AFTER_MODAL_SETUP
echo Modal CLI 初始化完成！
echo 如需额外令牌，可运行: python -m modal token new --name flux-training
echo ============================================================
echo.
echo === Next Steps ===
echo Required files to prepare:
echo 1. Configuration file:
echo    - Customize settings according to your needs in %CONFIG_FILE%
echo 2. Environment file (.env):
echo    - Add your Hugging Face token
echo 3. Training data files
echo.
echo Press Enter when you have prepared all required files to begin training...
pause

:CHECK_FILES
REM Check .env file
if not exist ".env" (
    echo [ERROR] .env file not found!
    echo Please create .env file and add your Hugging Face token in format:
    echo HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    echo.
    echo Press Enter after you have created the .env file...
    pause
    goto CHECK_FILES
)

REM Check HF_TOKEN format in .env
findstr /r /c:"^HF_TOKEN=hf_" ".env" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Invalid HF_TOKEN format in .env file!
    echo Token should be in format: HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    echo.
    echo Press Enter after you have fixed the token format...
    pause
    goto CHECK_FILES
)

REM Check config file
if not exist "%CONFIG_FILE%" (
    echo [ERROR] Configuration file not found!
    echo Please create %CONFIG_FILE%
    echo You can copy from templates in config/examples/modal/
    echo.
    echo Press Enter after you have created the config file...
    pause
    goto CHECK_FILES
)

echo All required files are present.
echo.
echo [1/2] Checking/Downloading FLUX model if needed (this may take a while)...

timeout /t 1 /nobreak >nul

"%PYTHON_EXE%" -m modal run download_model.py || (
    echo [ERROR] Failed to download FLUX model
    pause
    exit /b 1
)
echo.


timeout /t 1 /nobreak >nul

echo [2/2] Starting training process...

timeout /t 1 /nobreak >nul

"%PYTHON_EXE%" -m modal run --detach run_modal.py::main --config-file-list-str=/root/ai-toolkit/%CONFIG_FILE% || (
    echo [ERROR] Failed to start training process
    pause
    exit /b 1
)
echo.
echo Training process has started!
echo 打开 https://modal.com/apps ，在 “Apps” 中找到 flux-lora-training 查看日志与运行状态。
echo.
pause
