@echo off
setlocal enabledelayedexpansion

:: FaceFusion Auto-Setup Script with CUDA 12.8 Support
:: Created on %date% %time%

echo ===================================================
echo            FaceFusion Auto-Setup Script
echo ===================================================
echo.

:: Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please right-click on this file and select "Run as administrator".
    echo.
    pause
    exit /b 1
)

:: Set working directory to script location
cd /d "%~dp0"

:: Check for Python installation
echo Checking for Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python not found. Installing Python 3.10...
    
    :: Download Python installer
    echo Downloading Python 3.10.11...
    curl -L -o python_installer.exe https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe
    
    if %errorlevel% neq 0 (
        echo Failed to download Python. Please check your internet connection.
        pause
        exit /b 1
    )
    
    :: Install Python (with PATH option enabled)
    echo Installing Python 3.10.11...
    start /wait python_installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    
    :: Clean up installer
    del python_installer.exe
    
    :: Verify installation
    python --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to install Python. Please install Python 3.10 manually.
        pause
        exit /b 1
    else
        echo Python installed successfully.
    )
) else (
    echo Python detected. Checking version...
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set pyversion=%%i
    echo Found Python %pyversion%
)

:: Check/Install Git if needed
echo.
echo Checking for Git installation...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Git not found. Installing Git...
    
    :: Download Git installer
    echo Downloading Git installer...
    curl -L -o git_installer.exe https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe
    
    if %errorlevel% neq 0 (
        echo Failed to download Git. Please check your internet connection.
        pause
        exit /b 1
    )
    
    :: Install Git silently
    echo Installing Git...
    start /wait git_installer.exe /VERYSILENT /NORESTART
    
    :: Clean up installer
    del git_installer.exe
    
    :: Add Git to PATH for current session
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    
    :: Verify installation
    git --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo Failed to install Git. Please install Git manually.
        pause
        exit /b 1
    else
        echo Git installed successfully.
    )
) else (
    echo Git detected.
)

:: Create or navigate to project directory
echo.
echo Setting up project directory...
if not exist FaceFusion (
    mkdir FaceFusion
)
cd FaceFusion

:: Check if repository already exists
if exist .git (
    echo FaceFusion repository already exists. Updating...
    git pull
) else (
    echo Cloning FaceFusion repository...
    git clone https://github.com/facefusion/facefusion.git .
    if %errorlevel% neq 0 (
        echo Failed to clone repository. Please check your internet connection.
        pause
        exit /b 1
    )
)

:: Set up virtual environment
echo.
echo Setting up Python virtual environment...
if not exist venv (
    python -m venv venv
) else (
    echo Virtual environment already exists.
)

:: Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

:: Check NVIDIA GPU and CUDA
echo.
echo Checking for NVIDIA GPU and CUDA support...
nvidia-smi >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: NVIDIA GPU not detected or driver not installed.
    echo FaceFusion will run in CPU mode only ^(slower^).
    set CUDA_AVAILABLE=0
) else (
    for /f "tokens=*" %%a in ('nvidia-smi --query-gpu=name --format=csv,noheader') do (
        echo Detected GPU: %%a
    )
    
    :: Check for CUDA installation
    echo Checking CUDA installation...
    
    :: Look for CUDA in Program Files
    if exist "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8" (
        echo CUDA 12.8 detected.
        set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8"
        set CUDA_VERSION=12.8
        set CUDA_AVAILABLE=1
    ) else if exist "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.0" (
        echo CUDA 12.0 detected.
        set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.0"
        set CUDA_VERSION=12.0
        set CUDA_AVAILABLE=1
    ) else if exist "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA" (
        echo Generic CUDA installation detected. Checking version...
        set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA"
        
        :: Try to find the actual version
        for /d %%d in ("C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v*") do (
            set "CUDA_PATH=%%d"
            for /f "tokens=2 delims=v" %%v in ("%%~nxd") do (
                set CUDA_VERSION=%%v
            )
        )
        
        if defined CUDA_VERSION (
            echo CUDA %CUDA_VERSION% detected.
            set CUDA_AVAILABLE=1
        ) else (
            echo CUDA installation found but version could not be determined.
            set CUDA_AVAILABLE=1
        )
    ) else (
        echo CUDA not detected. Would you like to install CUDA 12.8 Toolkit?
        echo Note: This will download a large installer (^>2GB^).
        choice /c YN /m "Download and install CUDA 12.8 Toolkit?"
        
        if !errorlevel! equ 1 (
            echo Downloading CUDA 12.8 Toolkit installer...
            curl -L -o cuda_installer.exe https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_551.61_windows.exe
            
            if !errorlevel! neq 0 (
                echo Failed to download CUDA installer. Please install CUDA 12.8 manually.
                echo You can download it from: https://developer.nvidia.com/cuda-downloads
                set CUDA_AVAILABLE=0
            ) else (
                echo Running CUDA 12.8 installer...
                echo NOTE: Follow the installation prompts in the new window that appears.
                echo IMPORTANT: Select "Express Installation" for best results.
                start /wait cuda_installer.exe
                
                :: Clean up installer
                del cuda_installer.exe
                
                :: Check if CUDA was installed
                if exist "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8" (
                    echo CUDA 12.8 installed successfully.
                    set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8"
                    set CUDA_VERSION=12.8
                    set CUDA_AVAILABLE=1
                ) else (
                    echo Failed to confirm CUDA 12.8 installation. Continuing anyway...
                    set CUDA_AVAILABLE=0
                )
            )
        ) else (
            echo CUDA installation skipped. FaceFusion will run in CPU mode only ^(slower^).
            set CUDA_AVAILABLE=0
        )
    )
)

:: Update PATH for CUDA if available
if "%CUDA_AVAILABLE%"=="1" (
    echo Setting up CUDA environment...
    set "PATH=%CUDA_PATH%\bin;%PATH%"
    echo CUDA_PATH set to: %CUDA_PATH%
)

:: Install dependencies
echo.
echo Installing FaceFusion dependencies...
python -m pip install --upgrade pip

:: Install PyTorch with appropriate CUDA support
if "%CUDA_AVAILABLE%"=="1" (
    echo Installing PyTorch with CUDA support...
    
    :: Pick appropriate PyTorch CUDA version based on detected CUDA
    if "%CUDA_VERSION%"=="12.8" (
        python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    ) else if "%CUDA_VERSION%"=="12.0" (
        python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    ) else (
        python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    )
) else (
    echo Installing PyTorch CPU version...
    python -m pip install torch torchvision torchaudio
)

:: Install FaceFusion requirements
echo Installing FaceFusion requirements...
python -m pip install -r requirements.txt

:: Install additional relevant packages
echo Installing additional packages for improved performance...
python -m pip install onnxruntime-gpu insightface ultralytics gfpgan realesrgan

:: Create FaceFusion launcher
echo.
echo Creating FaceFusion launcher...

:: Create launcher script
echo @echo off > launch_facefusion.bat
echo setlocal enabledelayedexpansion >> launch_facefusion.bat
echo. >> launch_facefusion.bat
echo REM Activate virtual environment >> launch_facefusion.bat
echo call venv\Scripts\activate.bat >> launch_facefusion.bat
echo. >> launch_facefusion.bat
echo REM Set CUDA environment if available >> launch_facefusion.bat
if "%CUDA_AVAILABLE%"=="1" (
    echo set "CUDA_PATH=%CUDA_PATH%" >> launch_facefusion.bat
    echo set "PATH=%%CUDA_PATH%%\bin;%%PATH%%" >> launch_facefusion.bat
    echo set PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128 >> launch_facefusion.bat
)
echo. >> launch_facefusion.bat
echo echo ===================================== >> launch_facefusion.bat
echo echo      FaceFusion Launcher >> launch_facefusion.bat
echo echo ===================================== >> launch_facefusion.bat
echo echo. >> launch_facefusion.bat
echo echo Select launch mode: >> launch_facefusion.bat
echo echo. >> launch_facefusion.bat
echo echo 1. Normal mode ^(with GUI^) >> launch_facefusion.bat

if "%CUDA_AVAILABLE%"=="1" (
    echo echo 2. GPU mode ^(CUDA^) >> launch_facefusion.bat
    echo echo 3. Full mode ^(GPU + all providers^) >> launch_facefusion.bat
)

echo echo. >> launch_facefusion.bat
echo set /p mode=Select mode ^(1-%CUDA_AVAILABLE:0=1%%CUDA_AVAILABLE:1=3%^): >> launch_facefusion.bat
echo. >> launch_facefusion.bat
echo if "%%mode%%"=="1" ^( >> launch_facefusion.bat
echo     echo Launching FaceFusion in normal mode... >> launch_facefusion.bat
echo     python facefusion.py run --ui-layouts default --open-browser >> launch_facefusion.bat
echo ^) >> launch_facefusion.bat

if "%CUDA_AVAILABLE%"=="1" (
    echo else if "%%mode%%"=="2" ^( >> launch_facefusion.bat
    echo     echo Launching FaceFusion with CUDA... >> launch_facefusion.bat
    echo     python facefusion.py run --ui-layouts default --open-browser --execution-providers cuda --video-memory-strategy moderate >> launch_facefusion.bat 
    echo ^) >> launch_facefusion.bat
    echo else if "%%mode%%"=="3" ^( >> launch_facefusion.bat
    echo     echo Launching FaceFusion with all providers... >> launch_facefusion.bat
    echo     python facefusion.py run --ui-layouts default --open-browser --execution-providers cuda cpu --video-memory-strategy moderate >> launch_facefusion.bat
    echo ^) >> launch_facefusion.bat
)

echo else ^( >> launch_facefusion.bat
echo     echo Invalid selection. Launching in normal mode... >> launch_facefusion.bat
echo     python facefusion.py run --ui-layouts default --open-browser >> launch_facefusion.bat
echo ^) >> launch_facefusion.bat
echo. >> launch_facefusion.bat
echo pause >> launch_facefusion.bat

:: Download core models to speed up first run
echo.
echo Downloading core models...
call venv\Scripts\activate.bat
python -c "import insightface; insightface.utils.prepare_dir()" >nul 2>&1

:: Create shortcut to launcher on Desktop
echo Creating desktop shortcut...
echo Set oWS = WScript.CreateObject^("WScript.Shell"^) > createShortcut.vbs
echo sLinkFile = oWS.SpecialFolders^("Desktop"^) ^& "\FaceFusion.lnk" >> createShortcut.vbs
echo Set oLink = oWS.CreateShortcut^(sLinkFile^) >> createShortcut.vbs
echo oLink.TargetPath = oWS.CurrentDirectory ^& "\launch_facefusion.bat" >> createShortcut.vbs
echo oLink.WorkingDirectory = oWS.CurrentDirectory >> createShortcut.vbs
echo oLink.Description = "Launch FaceFusion" >> createShortcut.vbs
echo oLink.IconLocation = "shell32.dll,41" >> createShortcut.vbs
echo oLink.Save >> createShortcut.vbs
cscript //nologo createShortcut.vbs
del createShortcut.vbs

:: Create test script for CUDA verification
echo.
echo Creating CUDA test script...
echo import torch > cuda_test.py
echo print(f"PyTorch version: {torch.__version__}") >> cuda_test.py
echo print(f"CUDA available: {torch.cuda.is_available()}") >> cuda_test.py
echo if torch.cuda.is_available(): >> cuda_test.py
echo     print(f"CUDA version: {torch.version.cuda}") >> cuda_test.py
echo     print(f"CUDA device count: {torch.cuda.device_count()}") >> cuda_test.py
echo     print(f"Current CUDA device: {torch.cuda.current_device()}") >> cuda_test.py
echo     print(f"CUDA device name: {torch.cuda.get_device_name(0)}") >> cuda_test.py
echo     # Run a simple tensor operation on GPU >> cuda_test.py
echo     x = torch.tensor([1.0, 2.0, 3.0], device='cuda') >> cuda_test.py
echo     y = x * 2 >> cuda_test.py
echo     print(f"GPU Tensor test result: {y}") >> cuda_test.py
echo     print("CUDA test SUCCESSFUL!") >> cuda_test.py
echo else: >> cuda_test.py
echo     print("CUDA test FAILED! CUDA is not available.") >> cuda_test.py

:: Run CUDA test if available
if "%CUDA_AVAILABLE%"=="1" (
    echo.
    echo Testing CUDA functionality...
    python cuda_test.py
)

:: Installation completed
echo.
echo ===================================================
echo  FaceFusion installation completed successfully!
echo ===================================================
echo.
echo You can now launch FaceFusion using:
echo  1. The desktop shortcut
echo  2. The launch_facefusion.bat file in this directory
echo.
if "%CUDA_AVAILABLE%"=="1" (
    echo CUDA %CUDA_VERSION% support is enabled.
) else (
    echo WARNING: Running in CPU-only mode (slower performance).
    echo To enable GPU acceleration, install NVIDIA GPU drivers
    echo and CUDA 12.8 Toolkit, then run this setup again.
)
echo.
echo Enjoy using FaceFusion!
echo.
pause
