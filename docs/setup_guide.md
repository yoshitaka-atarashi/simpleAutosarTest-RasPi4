# Trampoline OS セットアップガイド

## 詳細セットアップ手順

### 1. 開発環境の準備

#### 1.1 Trampolineソースの取得

```bash
# プロジェクトの親ディレクトリに移動
cd d:\genAI

# Trampolineをクローン
git clone https://github.com/TrampolineRTOS/trampoline.git
cd trampoline

# 安定版ブランチをチェックアウト（推奨）
git checkout master
```

#### 1.2 ARM GCC Toolchainのインストール

**Windows:**

1. [ARM Developer サイト](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)から最新版をダウンロード
2. `arm-gnu-toolchain-<version>-mingw-w64-i686-arm-none-eabi.exe` を実行
3. インストール時に「Add path to environment variable」にチェック
4. PowerShellで確認:
   ```powershell
   arm-none-eabi-gcc --version
   ```

**Linux/WSL:**

```bash
sudo apt-get update
sudo apt-get install gcc-arm-none-eabi binutils-arm-none-eabi gdb-arm-none-eabi
```

#### 1.3 Python環境の準備

```bash
cd AutosarTest3/pc_tools
pip install -r requirements.txt
```

### 2. Raspberry Piの準備

#### 2.1 ハードウェア接続

**オプション1: HDMI出力（推奨）**
- HDMIケーブルでディスプレイに接続
- シリアルケーブル不要
- `app/main.c`の`USE_HDMI`を`1`に設定（デフォルト）

**オプション2: UART接続（GPIO14/15使用）**

| Raspberry Pi 4 | USB-シリアル変換 |
|----------------|------------------|
| GPIO14 (TXD)   | RX               |
| GPIO15 (RXD)   | TX               |
| GND            | GND              |

**注意:** 
- Raspberry Pi 4は3.3Vロジックです
- 5V対応のシリアル変換を使う場合はレベル変換が必要
- TX/RXは交差接続してください
- `app/main.c`の`USE_HDMI`を`0`に設定

#### 2.2 SDカードの準備

1. **フォーマット:**
   - FAT32でフォーマット（8GB以上推奨）

2. **ブートファイルの配置:**
   ```
   sdcard/
   ├── bootcode.bin      # 第1ステージブートローダー
   ├── start4.elf        # 第2ステージブートローダー（RPi4用）
   ├── fixup4.dat        # GPU設定（RPi4用）
   ├── config.txt        # 起動設定
   └── kernel.img        # ビルドしたバイナリ
   ```

3. **ブートローダーの入手:**
   ```bash
   # Raspberry Pi firmwareリポジトリからダウンロード
   git clone --depth=1 https://github.com/raspberrypi/firmware.git
   
   # Raspberry Pi 4用ファイルをコピー
   cp firmware/boot/bootcode.bin /path/to/sdcard/
   cp firmware/boot/start4.elf /path/to/sdcard/
   cp firmware/boot/fixup4.dat /path/to/sdcard/
   ```

#### 2.3 config.txtの作成

SDカードのルートに `config.txt` を作成:

```ini
# Raspberry Pi 4 Configuration for Bare Metal

# ARMモード（32-bit）
arm_64bit=0
kernel=kernel.img
kernel_address=0x8000

# HDMI設定
hdmi_safe=1
hdmi_force_hotplug=1

# GPU メモリ（フレームバッファ用）
gpu_mem=64

# UART設定（シリアル使用時のみ）
enable_uart=1
dtoverlay=disable-bt

# オーバークロック（任意）
#arm_freq=1800
#over_voltage=2
```

### 3. ビルドとデプロイ

#### 3.1 アプリケーションのビルド

**Windows:**
```powershell
cd d:\genAI\AutosarTest3\build
.\build.bat
```

**Linux/WSL:**
```bash
cd /d/genAI/AutosarTest3/build
bash build.sh
```

ビルドが成功すると `build/output/kernel.img` が生成されます。

#### 3.2 SDカードへのデプロイ

```bash
# kernel.imgをSDカードにコピー
copy build\output\kernel.img E:\kernel.img
```

### 4. 動作確認

#### 4.1 Raspberry Piの起動

1. SDカードをRaspberry Piに挿入
2. USB-シリアル変換ケーブルを接続
3. PCでシリアルポート番号を確認（デバイスマネージャー）
4. Raspberry Piに電源を投入

#### 4.2 PC側モニタープログラムの起動

**利用可能なポートの確認:**
```bash
cd pc_tools
python serial_monitor.py --list
```

**モニター起動:**
```powershell
# Windows
python serial_monitor.py --port COM3 --baud 115200

# Linux
python serial_monitor.py --port /dev/ttyUSB0 --baud 115200
```

#### 4.3 期待される出力

正常に動作すると、以下のようなメッセージが表示されます:

```
================================================
 Trampoline AUTOSAR OS on Raspberry Pi
 Serial Communication Test
================================================

[TaskSerial] Count: 1 | Uptime: 1 sec
[TaskSerial] Count: 2 | Uptime: 2 sec
[TaskSerial] Count: 3 | Uptime: 3 sec
...
```

#### 4.4 インタラクティブテスト

モニタープログラムで任意のメッセージを送信:

```
> HELLO
[RX] [TaskProcess] Received: HELLO

> TEST123
[RX] [TaskProcess] Received: TEST123
```

### 5. トラブルシューティング

#### 5.1 ビルドエラー

**問題:** `arm-none-eabi-gcc: command not found`

**解決策:**
- ツールチェインがインストールされているか確認
- PATHに追加されているか確認
  ```powershell
  $env:PATH += ";C:\Program Files\ARM\bin"
  ```

#### 5.2 起動しない

**問題:** Raspberry Piが起動しない

**チェック項目:**
- SDカードに全ブートファイルが揃っているか
- `config.txt`の設定が正しいか
- 電源供給が十分か（5V 2.5A以上推奨）
- ACT LEDが点滅するか（SDカードアクセス確認）

#### 5.3 シリアル通信できない

**問題:** PCでデータを受信できない

**チェック項目:**
- ポート名が正しいか（COM3, /dev/ttyUSB0など）
- ボーレートが一致しているか（115200bps）
- TX/RXが正しく接続されているか（交差接続）
- GNDが接続されているか
- ドライバがインストールされているか（デバイスマネージャー確認）

**デバッグコマンド:**
```bash
# Linuxでポート権限確認
ls -l /dev/ttyUSB0
sudo chmod 666 /dev/ttyUSB0

# 簡易テスト（minicomなど）
minicom -D /dev/ttyUSB0 -b 115200
```

#### 5.4 メモリ不足

**問題:** 実行時にハングする

**解決策:**
- リンカスクリプト `link.ld` のスタック/ヒープサイズを調整
- OILファイルのタスクスタックサイズを確認

### 6. カスタマイズ

#### 6.1 タスクの追加

1. `app/app.oil` に新しいタスク定義を追加
2. `app/main.c` にタスク実装を追加
3. リビルド

#### 6.2 通信プロトコルの拡張

`uart_comm.c` を拡張してカスタムプロトコルを実装:
- バイナリプロトコル
- チェックサム検証
- パケット化

#### 6.3 センサー連携

GPIO制御を追加してセンサーデータを送信:
```c
// app/sensor.c
void read_sensor_data(void) {
    // I2C/SPI通信でセンサー読み取り
    // UARTで送信
}
```

### 7. 参考資料

- [Trampoline Documentation](https://github.com/TrampolineRTOS/trampoline/wiki)
- [AUTOSAR 仕様](https://www.autosar.org/standards/classic-platform/)
- [Raspberry Pi GPIO](https://pinout.xyz/)
- [BCM2835 Datasheet](https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2835/README.md)

### 8. 次のステップ

- CANバス通信の実装
- リアルタイム性能の測定
- マルチコアサポート
- DMA転送の実装
- フラッシュメモリへの書き込み
