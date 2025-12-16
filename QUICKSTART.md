# クイックスタートガイド

## 5分でできる動作確認

### 前提条件
- Raspberry Pi 4（BCM2711, Cortex-A72）
- HDMIディスプレイまたはUSB-シリアル変換ケーブル
- microSDカード（8GB以上）
- Python 3.8以上インストール済みのPC（シリアル通信使用時）

### ステップ1: ツールのインストール（5分）

**Windows:**
```powershell
# ARM GCC Toolchainをインストール
# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
# ダウンロード後、インストーラーを実行

# Python依存パッケージ
cd pc_tools
pip install -r requirements.txt
```

### ステップ2: Trampolineの取得（3分）

```bash
cd d:\genAI
git clone https://github.com/TrampolineRTOS/trampoline.git
```

### ステップ3: ビルド（2分）

```powershell
cd AutosarTest3\build
.\build.bat
```

### ステップ4: SDカード準備（5分）

1. SDカードをFAT32でフォーマット
2. [Raspberry Pi firmware](https://github.com/raspberrypi/firmware/tree/master/boot)から以下をダウンロードしてSDカードのルートにコピー:
   - bootcode.bin
   - start4.elf（RPi4用）
   - fixup4.dat（RPi4用）
3. 以下の内容で `config.txt` を作成:
   ```ini
   # Raspberry Pi 4 Configuration
   arm_64bit=0
   kernel=kernel.img
   kernel_address=0x8000
   
   # HDMI設定
   hdmi_safe=1
   hdmi_force_hotplug=1
   
   # GPU memory
   gpu_mem=64
   
   # UART設定（シリアル使用時）
   enable_uart=1
   dtoverlay=disable-bt
   kernel=kernel.img
   gpu_mem=16
   ```
4. `build\output\kernel.img` をSDカードのルートにコピー

### ステップ5: 接続と起動（3分）

1. **UART接続:**
   - RPi GPIO14 → USB-Serial RX
   - RPi GPIO15 → USB-Serial TX
   - RPi GND → USB-Serial GND

2. **起動:**
   - SDカードをRaspberry Piに挿入
   - USB-シリアルをPCに接続
   - Raspberry Piに電源投入

3. **モニター起動:**
   ```powershell
   cd pc_tools
   python serial_monitor.py --port COM3 --baud 115200
   ```
   ※ ポート名は環境に応じて変更

### 期待される出力

```
================================================
 Trampoline AUTOSAR OS on Raspberry Pi
 Serial Communication Test
================================================

[TaskSerial] Count: 1 | Uptime: 1 sec
[TaskSerial] Count: 2 | Uptime: 2 sec
```

成功です！これでAUTOSAR OS（Trampoline）がRaspberry Piで動作し、PCと通信できています。

---

## よくある問題と解決

| 問題 | 解決策 |
|------|--------|
| ビルドエラー | arm-none-eabi-gccがPATHに追加されているか確認 |
| 何も表示されない | シリアルポート名、TX/RX配線を確認 |
| 文字化け | ボーレート115200bpsを確認 |
| Raspberry Pi起動しない | bootcode.bin, start.elf, config.txtを確認 |

詳細は [docs/setup_guide.md](docs/setup_guide.md) を参照してください。
