@echo off
REM Build script for Trampoline AUTOSAR OS on Raspberry Pi 4 (Windows)

echo ================================================
echo   Trampoline OS Build Script for Raspberry Pi 4
echo ================================================
echo.

REM Configuration
set TRAMPOLINE_ROOT=..\trampoline
set APP_DIR=%~dp0..\app
set BUILD_DIR=%~dp0
set OUTPUT_DIR=%BUILD_DIR%output

REM Check Trampoline
if not exist "%TRAMPOLINE_ROOT%" (
    echo Error: Trampoline source not found at %TRAMPOLINE_ROOT%
    echo Please clone Trampoline:
    echo   git clone https://github.com/TrampolineRTOS/trampoline.git ..\trampoline
    exit /b 1
)

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Check cross-compiler
where arm-none-eabi-gcc >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: arm-none-eabi-gcc not found
    echo Please install ARM GCC toolchain from:
    echo   https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
    exit /b 1
)

echo [1/5] Checking environment...
echo   Trampoline root: %TRAMPOLINE_ROOT%
echo   Application dir: %APP_DIR%
arm-none-eabi-gcc --version | findstr /R "^arm-none-eabi-gcc"
echo.

echo [2/5] Generating AUTOSAR configuration from OIL...
echo   (OIL compilation requires goil tool from Trampoline)
echo   Skipping automatic OIL compilation in this example
echo.

echo [3/5] Compiling application...
cd /d "%BUILD_DIR%"

REM Compile flags for Raspberry Pi 4 (Cortex-A72)
set CFLAGS=-mcpu=cortex-a72 -mfloat-abi=hard -mfpu=neon-fp-armv8 -O2 -Wall -Wextra
set CFLAGS=%CFLAGS% -nostdlib -nostartfiles -ffreestanding
set CFLAGS=%CFLAGS% -I%APP_DIR% -I%TRAMPOLINE_ROOT%\os -I%TRAMPOLINE_ROOT%\autosar -I%TRAMPOLINE_ROOT%\machines\cortex-a-r -DRPI4

REM Compile
echo   Compiling: boot.S
arm-none-eabi-gcc %CFLAGS% -c %APP_DIR%\boot.S -o %OUTPUT_DIR%\boot.o

echo   Compiling: main.c
arm-none-eabi-gcc %CFLAGS% -c %APP_DIR%\main.c -o %OUTPUT_DIR%\main.o

echo   Compiling: uart_comm.c
arm-none-eabi-gcc %CFLAGS% -c %APP_DIR%\uart_comm.c -o %OUTPUT_DIR%\uart_comm.o

echo   Compiling: framebuffer.c
arm-none-eabi-gcc %CFLAGS% -c %APP_DIR%\framebuffer.c -o %OUTPUT_DIR%\framebuffer.o

echo   Compiling: tpl_os_stubs.c
arm-none-eabi-gcc %CFLAGS% -c %APP_DIR%\tpl_os_stubs.c -o %OUTPUT_DIR%\tpl_os_stubs.o

echo.

echo [4/5] Linking...
set LDFLAGS=-T %BUILD_DIR%\link.ld -nostdlib

arm-none-eabi-ld %LDFLAGS% %OUTPUT_DIR%\boot.o %OUTPUT_DIR%\main.o %OUTPUT_DIR%\uart_comm.o %OUTPUT_DIR%\framebuffer.o %OUTPUT_DIR%\tpl_os_stubs.o -o %OUTPUT_DIR%\kernel.elf

echo   Created: %OUTPUT_DIR%\kernel.elf
echo.

echo [5/5] Creating binary image...
arm-none-eabi-objcopy %OUTPUT_DIR%\kernel.elf -O binary %OUTPUT_DIR%\kernel.img
echo   Created: %OUTPUT_DIR%\kernel.img
echo.

echo ================================================
echo   Build completed successfully!
echo ================================================
echo.
echo Next steps:
echo   1. Copy kernel.img to Raspberry Pi SD card
echo   2. Add bootcode.bin, start.elf from Raspberry Pi firmware
echo   3. Create config.txt with appropriate settings
echo   4. Connect UART and power on the Pi
echo.

pause
