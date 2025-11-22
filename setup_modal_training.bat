@echo off
setlocal enabledelayedexpansion
set "PYTHON_EXE=C:\Users\sxm2\scoop\apps\miniforge\python.exe"

if not exist "%PYTHON_EXE%" (
    echo [ERROR] Miniforge python.exe not found at %PYTHON_EXE%
    echo Please install Miniforge or update the PYTHON_EXE path inside setup_modal_training.bat.
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
echo NOTE: The repository will be cloned to C:\ai-toolkit
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
if exist "C:\ai-toolkit\" (
    echo Found existing ai-toolkit folder in C:\, skipping clone...
    cd /d C:\ai-toolkit
) else (
    echo Cloning to C:\ai-toolkit to avoid path length issues...
    cd /d C:\
    git clone https://github.com/miludeerforest/modal_train_flux.git ai-toolkit
    if %errorlevel% neq 0 (
        echo [ERROR] Could not clone repository.
        pause
        exit /b 1
    )
    cd ai-toolkit
)

echo [3/6] Updating submodules...
git submodule update --init --recursive

echo [4/7] Creating virtual environment...
"C:\Users\sxm2\scoop\apps\miniforge\python.exe" -m venv venv
call venv\Scripts\activate

echo [5/7] 安装/升级 Modal CLI...
"C:\Users\sxm2\scoop\apps\miniforge\python.exe" -m pip install --upgrade modal

echo [6/7] 安装项目依赖...
"C:\Users\sxm2\scoop\apps\miniforge\python.exe" -m pip install python-dotenv huggingface_hub oyaml

echo [7/7] 初始化 Modal CLI（参考 https://modal.com/docs/guide/apps ）...
echo ============================================================
echo 将执行 "modal setup"。请按提示在浏览器中登录 Modal，写入默认令牌。
echo 如需额外令牌，可在完成后运行:
echo   modal token new --name flux-training
echo ============================================================
modal setup || (
    echo [ERROR] modal setup 失败，请排查后重试。
    pause
    exit /b 1
)
echo Modal CLI 初始化完成！
echo.
echo === Next Steps ===
echo Required files to prepare:
echo 1. Configuration file:
echo    - Customize settings according to your needs in config/modal_train_lora_flux.yaml
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
if not exist "config/modal_train_lora_flux.yaml" (
    echo [ERROR] Configuration file not found!
    echo Please create config/modal_train_lora_flux.yaml
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

modal run download_model.py || (
    echo [ERROR] Failed to download FLUX model
    pause
    exit /b 1
)
echo.


timeout /t 1 /nobreak >nul

echo [2/2] Starting training process...

timeout /t 1 /nobreak >nul

modal run --detach run_modal.py::main --config-file-list-str=/root/ai-toolkit/config/modal_train_lora_flux.yaml || (
    echo [ERROR] Failed to start training process
    pause
    exit /b 1
)
echo.
echo Training process has started!
echo 打开 https://modal.com/apps ，在 “Apps” 中找到 flux-lora-training 查看日志与运行状态。
echo.
pause
