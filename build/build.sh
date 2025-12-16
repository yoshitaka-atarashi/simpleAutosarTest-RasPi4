#!/bin/bash
#
# Build script for Trampoline AUTOSAR OS on Raspberry Pi
# This script compiles the application and generates the ELF file
#

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Trampoline OS Build Script for Raspberry Pi${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# 設定
TRAMPOLINE_ROOT="../trampoline"
APP_DIR="$(dirname "$0")/../app"
BUILD_DIR="$(dirname "$0")"
OUTPUT_DIR="$BUILD_DIR/output"

# Trampolineのパスチェック
if [ ! -d "$TRAMPOLINE_ROOT" ]; then
    echo -e "${RED}Error: Trampoline source not found at $TRAMPOLINE_ROOT${NC}"
    echo -e "${YELLOW}Please clone Trampoline:${NC}"
    echo "  git clone https://github.com/TrampolineRTOS/trampoline.git ../trampoline"
    exit 1
fi

# 出力ディレクトリ作成
mkdir -p "$OUTPUT_DIR"

# クロスコンパイラチェック
if ! command -v arm-none-eabi-gcc &> /dev/null; then
    echo -e "${RED}Error: arm-none-eabi-gcc not found${NC}"
    echo -e "${YELLOW}Please install ARM GCC toolchain:${NC}"
    echo "  Windows: Download from https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads"
    echo "  Linux: sudo apt-get install gcc-arm-none-eabi"
    exit 1
fi

echo -e "${GREEN}[1/5] Checking environment...${NC}"
echo "  Trampoline root: $TRAMPOLINE_ROOT"
echo "  Application dir: $APP_DIR"
echo "  Compiler: $(arm-none-eabi-gcc --version | head -n1)"
echo ""

echo -e "${GREEN}[2/5] Generating AUTOSAR configuration from OIL...${NC}"
cd "$APP_DIR"
# Note: Trampolineにはgoilコンパイラが必要
# python $TRAMPOLINE_ROOT/goil/makefile-unix/goil ... などでOILをコンパイル
echo "  (OIL compilation requires goil tool from Trampoline)"
echo "  Skipping automatic OIL compilation in this example"
echo ""

echo -e "${GREEN}[3/5] Compiling application...${NC}"
cd "$BUILD_DIR"

# コンパイルフラグ
CFLAGS="-mcpu=cortex-a53 -mfloat-abi=hard -mfpu=neon-fp-armv8 -O2 -Wall -Wextra"
CFLAGS="$CFLAGS -nostdlib -nostartfiles -ffreestanding"
CFLAGS="$CFLAGS -I$APP_DIR -I$TRAMPOLINE_ROOT/os -I$TRAMPOLINE_ROOT/machines/arm/rpi"
CFLAGS="$CFLAGS -DRPI4"

# ソースファイル
APP_SOURCES="$APP_DIR/main.c $APP_DIR/uart_comm.c"

# コンパイル
echo "  Compiling: main.c"
arm-none-eabi-gcc $CFLAGS -c $APP_DIR/main.c -o $OUTPUT_DIR/main.o

echo "  Compiling: uart_comm.c"
arm-none-eabi-gcc $CFLAGS -c $APP_DIR/uart_comm.c -o $OUTPUT_DIR/uart_comm.o

echo ""

echo -e "${GREEN}[4/5] Linking...${NC}"
# リンカスクリプト（簡易版を使用）
LDFLAGS="-T $BUILD_DIR/link.ld -nostdlib"

arm-none-eabi-ld $LDFLAGS $OUTPUT_DIR/*.o -o $OUTPUT_DIR/kernel.elf

echo "  Created: $OUTPUT_DIR/kernel.elf"
echo ""

echo -e "${GREEN}[5/5] Creating binary image...${NC}"
arm-none-eabi-objcopy $OUTPUT_DIR/kernel.elf -O binary $OUTPUT_DIR/kernel.img
echo "  Created: $OUTPUT_DIR/kernel.img"
echo ""

# ファイルサイズ表示
echo -e "${GREEN}Build Summary:${NC}"
ls -lh $OUTPUT_DIR/kernel.elf $OUTPUT_DIR/kernel.img
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Build completed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Copy kernel.img to Raspberry Pi SD card"
echo "  2. Add bootcode.bin, start.elf from Raspberry Pi firmware"
echo "  3. Create config.txt with appropriate settings"
echo "  4. Connect UART and power on the Pi"
echo ""
