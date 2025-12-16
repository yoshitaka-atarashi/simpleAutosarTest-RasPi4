# HDMI Display Output Setup

## Overview
シリアルケーブルなしで、HDMI ディスプレイに直接出力する設定です。

## 現在の設定
- **出力モード**: HDMI (フレームバッファ)
- `app/main.c` の `USE_HDMI` が `1` に設定されています

## UART出力に切り替える場合
[app/main.c](app/main.c#L12) の以下の行を変更：
```c
#define USE_HDMI  0  /* Set to 1 for HDMI, 0 for UART */
```

## Raspberry Pi 4 への展開手順

### 1. SDカードの準備
1. FAT32でフォーマットされたmicroSDカードを用意
2. 以下のファイルをダウンロード：
   - [Raspberry Pi firmware](https://github.com/raspberrypi/firmware/tree/master/boot)から：
     - `bootcode.bin`
     - `start4.elf` (RPi4用)
     - `fixup4.dat` (RPi4用)

### 2. ファイルのコピー
SDカードのルートに以下をコピー：
```
/
├── bootcode.bin
├── start4.elf
├── fixup4.dat
├── config.txt (下記参照)
└── kernel.img (ビルドで生成)
```

### 3. config.txt の作成
SDカードのルートに `config.txt` を作成：
```ini
# Raspberry Pi 4 Configuration
arm_64bit=0
kernel=kernel.img
kernel_address=0x8000

# UART設定 (デバッグ用)
enable_uart=1
uart_2ndstage=1

# HDMI設定
hdmi_safe=1
hdmi_force_hotplug=1

# GPU memory (framebuffer用)
gpu_mem=64
```

### 4. 起動
1. SDカードをRaspberry Pi 4に挿入
2. HDMIケーブルでモニターに接続
3. 電源を投入

### 5. 期待される画面表示
```
================================================
 Trampoline AUTOSAR OS on Raspberry Pi 4
 HDMI Display Test
================================================

[TaskSerial] Count: 1 | Uptime: 1 sec
[TaskSerial] Count: 2 | Uptime: 2 sec
[TaskSerial] Count: 3 | Uptime: 3 sec
...
```

## トラブルシューティング

### 画面に何も表示されない
1. **HDMI接続確認**: モニターとケーブルが正しく接続されているか
2. **config.txt確認**: `hdmi_force_hotplug=1` が設定されているか
3. **SDカードの内容確認**: 必要なファイルがすべてあるか

### "Rainbow screen" で止まる
- `kernel.img` の読み込みに失敗しています
- config.txt の `kernel_address=0x8000` を確認

### LEDのみ点滅する
- プログラムは動作していますが、framebufferの初期化に失敗
- UARTモードに切り替えて、シリアルコンソールでデバッグ推奨

## デバッグ方法

### LED点滅パターンで状態確認
ACT LED（緑色）の点滅パターン：
- **連続点滅**: 正常動作中
- **高速点滅**: エラー発生

### UARTでのデバッグ
1. `app/main.c` で `USE_HDMI` を `0` に変更
2. リビルド
3. UART0 (GPIO14/15) にシリアルコンソールを接続
4. 115200bps でシリアルモニターを開く

## 画面解像度の変更
[app/framebuffer.c](app/framebuffer.c#L24) で変更可能：
```c
#define SCREEN_WIDTH     1024  // 横幅
#define SCREEN_HEIGHT    768   // 縦幅
```

対応解像度例：
- 1024x768 (推奨)
- 1280x720 (720p)
- 1920x1080 (1080p) - GPU負荷大

## 機能制限

### 現在実装されている機能
- ✅ 基本的なテキスト表示
- ✅ 8x16 フォント
- ✅ 改行とスクロール
- ✅ 16進数・10進数表示

### 未実装の機能
- ❌ カーソル制御
- ❌ カラー変更（白固定）
- ❌ 全ASCII文字（基本文字のみ）
- ❌ 日本語表示

## その他の出力方法

### 1. LEDブリンクパターン
最もシンプル。デバッグコードをLED点滅回数に変換

### 2. SDカードへのログ出力
FAT32ドライバを実装すればログファイル書き込み可能（要実装）

### 3. ネットワーク経由
WiFi/Ethernetドライバ + TCP/IPスタックが必要（複雑）
