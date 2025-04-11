@echo off 
setlocal enabledelayedexpansion 
 
REM Activate virtual environment 
call venv\Scripts\activate.bat 
 
REM Set CUDA environment if available 
set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.3" 
set "PATH=%CUDA_PATH%\bin;%PATH%" 
set PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128 
 
echo ===================================== 
echo      FaceFusion Launcher 
echo ===================================== 
echo. 
echo Select launch mode: 
echo. 
echo 1. Normal mode (with GUI) 
echo 2. GPU mode (CUDA) 
echo 3. Full mode (GPU + all providers) 
echo. 
set /p mode=Select mode (1-13): 
 
if "%mode%"=="1" ( 
    echo Launching FaceFusion in normal mode... 
    python facefusion.py run --ui-layouts default --open-browser 
) 
else if "%mode%"=="2" ( 
    echo Launching FaceFusion with CUDA... 
    python facefusion.py run --ui-layouts default --open-browser --execution-providers cuda --video-memory-strategy moderate  
) 
else if "%mode%"=="3" ( 
    echo Launching FaceFusion with all providers... 
    python facefusion.py run --ui-layouts default --open-browser --execution-providers cuda cpu --video-memory-strategy moderate 
) 
else ( 
    echo Invalid selection. Launching in normal mode... 
    python facefusion.py run --ui-layouts default --open-browser 
) 
 
pause 
