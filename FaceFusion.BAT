@echo off
chcp 65001 > nul
cls

set "ROOT_DIR=D:\FaceFusion"
set "VENV_DIR=%ROOT_DIR%\venv"
set "PYTHON_PATH=%VENV_DIR%\Scripts\python.exe"
set "LAUNCHER_LOG=%ROOT_DIR%\launcher.log"

::=====================================
::    1. Python & Git Installation
::=====================================
echo [⏳] Перевірка Python та Git...
where python > nul 2>&1 || (echo [❌] Python не знайдено. Встанови Python вручну і додай до PATH. && pause && exit /b)
where git > nul 2>&1 || (echo [❌] Git не знайдено. Встанови Git вручну і додай до PATH. && pause && exit /b)
echo [✔] Python та Git знайдено

::=====================================
::    2. Віртуальне середовище
::=====================================
echo [⚙] Створення віртуального середовища...
if not exist "%VENV_DIR%" (
    python -m venv "%VENV_DIR%"
)

call "%VENV_DIR%\Scripts\activate.bat"
echo [✔] Віртуальне середовище активовано

::=====================================
::    3. Клонування репозиторію
::=====================================
if not exist "%ROOT_DIR%\.git" (
    echo [⬇️] Клонування FaceFusion...
    git clone https://github.com/facefusion/facefusion.git "%ROOT_DIR%"
)
cd /d "%ROOT_DIR%"

::=====================================
::    4. Встановлення залежностей
::=====================================
echo [📦] Встановлення залежностей...
"%PYTHON_PATH%" -m pip install --upgrade pip
"%PYTHON_PATH%" -m pip install -r requirements.txt

::=====================================
::    5. CUDA PATH Setup & ONNX Fix
::=====================================
echo.
echo =====================================
echo     [🔧] CUDA PATH Setup & Check
echo =====================================

set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8"
setx PATH "%PATH%;%CUDA_PATH%\bin;%CUDA_PATH%\libnvvp"
echo [✔] CUDA шляхи додано до PATH

set "CUDART_DLL=%CUDA_PATH%\bin\cudart64_120.dll"
set "ONNX_CAPI_PATH=%VENV_DIR%\Lib\site-packages\onnxruntime\capi"

if not exist "%CUDART_DLL%" (
    echo [❌] cudart64_120.dll не знайдено в %CUDA_PATH%\bin
    echo     Перевірте встановлення CUDA Toolkit 12.8
    pause
) else (
    echo [✔] cudart64_120.dll знайдено
    echo [📦] Копіюємо cudart64_120.dll до ONNXRuntime...
    copy "%CUDART_DLL%" "%ONNX_CAPI_PATH%" > nul
    echo [✔] Готово
)

if not exist "%ONNX_CAPI_PATH%\onnxruntime_providers_cuda.dll" (
    echo [❌] onnxruntime_providers_cuda.dll відсутній!
    echo     Виконай: pip install onnxruntime-gpu==1.17.1
    "%PYTHON_PATH%" -m pip uninstall onnxruntime onnxruntime-gpu -y
    "%PYTHON_PATH%" -m pip install onnxruntime-gpu==1.17.1
) else (
    echo [✔] onnxruntime_providers_cuda.dll знайдено
)

echo [✅] Перевірка CUDA + ONNX завершена

::=====================================
::    6. Створення ярлика (опційно)
::=====================================
REM Тут можна вставити створення ярлика, якщо потрібно

::=====================================
::    7. Лаунчер режимів запуску
::=====================================
:launcher
cls
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
set /p mode="Select mode (1-3): "

if "%mode%"=="1" goto normal
if "%mode%"=="2" goto cuda
if "%mode%"=="3" goto full
echo [!] Невірний вибір.
pause
goto launcher

:normal
echo Запуск FaceFusion у звичайному режимі...
"%PYTHON_PATH%" run.py >> "%LAUNCHER_LOG%" 2>&1
exit /b

:cuda
echo Запуск FaceFusion з CUDA...
"%PYTHON_PATH%" run.py --execution-provider cuda >> "%LAUNCHER_LOG%" 2>&1
exit /b

:full
echo Запуск FaceFusion у повному режимі...
"%PYTHON_PATH%" run.py --execution-provider cuda --all-providers >> "%LAUNCHER_LOG%" 2>&1
exit /b
