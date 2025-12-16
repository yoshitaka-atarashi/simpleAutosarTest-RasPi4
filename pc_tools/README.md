# PC Tools

Raspberry Pi 4ベアメタルプロジェクト用のPCツール集

## ツール一覧

### 1. serial_monitor.py

UART経由でRaspberry Piと通信するシリアルモニタープログラム。

#### 機能
- シリアルポート自動検出
- リアルタイム送受信
- カラー出力対応
- 双方向通信

#### 使用方法

```bash
# ポート一覧表示
python serial_monitor.py --list

# シリアルモニター起動（Windows）
python serial_monitor.py --port COM3 --baud 115200

# シリアルモニター起動（Linux）
python serial_monitor.py --port /dev/ttyUSB0 --baud 115200
```

#### オプション
- `--port`: シリアルポート名（必須）
- `--baud`: ボーレート（デフォルト: 115200）
- `--list`: 利用可能なポート一覧を表示

---

### 2. sd_writer.py

SDカードへの自動書き込みツール。Raspberry Pi 4の起動に必要なファイルを一括でSDカードに書き込みます。

#### 機能
- kernel.imgの自動コピー
- ブートファイル（bootcode.bin, start4.elf, fixup4.dat）のコピー
- config.txtの自動生成
- ドライブ検出（Windows）
- ドライラン（テストモード）

#### 前提条件

1. プロジェクトのビルドが完了していること
   ```bash
   cd build
   # Windows
   .\build.bat
   # Linux
   bash build.sh
   ```

2. ファームウェアディレクトリに必要なブートファイルが存在すること
   - `firmware/boot/bootcode.bin`
   - `firmware/boot/start4.elf`
   - `firmware/boot/fixup4.dat`

#### 使用方法

```bash
# ドライブ一覧を表示（Windows）
python sd_writer.py --list

# SDカードに書き込み（HDMI出力モード）
python sd_writer.py --drive E: --hdmi

# SDカードに書き込み（UART通信モード）
python sd_writer.py --drive E: --uart

# HDMI + UART両方有効
python sd_writer.py --drive E: --hdmi --uart

# ドライラン（実際には書き込まない）
python sd_writer.py --drive E: --hdmi --dry-run
```

#### オプション

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--list`, `-l` | 利用可能なドライブを一覧表示（Windows） | - |
| `--drive`, `-d` | ターゲットドライブ（例: `E:` または `/media/sdcard`） | 必須 |
| `--hdmi` | HDMI出力を有効化 | 有効 |
| `--no-hdmi` | HDMI出力を無効化 | - |
| `--uart` | UART通信を有効化 | 無効 |
| `--dry-run` | ドライラン（実際には書き込まない） | - |
| `--project-root` | プロジェクトルートディレクトリ | 自動検出 |

#### 書き込まれるファイル

1. **bootcode.bin** - 第1ステージブートローダー
2. **start4.elf** - 第2ステージブートローダー（Raspberry Pi 4用）
3. **fixup4.dat** - GPU設定（Raspberry Pi 4用）
4. **config.txt** - 起動設定（自動生成）
5. **kernel.img** - ビルドされたバイナリ

#### config.txtの内容

生成される`config.txt`には以下が含まれます：

```ini
# Raspberry Pi 4 Configuration for Bare Metal
arm_64bit=0
kernel=kernel.img
kernel_address=0x8000

# HDMI設定（--hdmiオプション使用時）
hdmi_safe=1
hdmi_force_hotplug=1
gpu_mem=64

# UART設定（--uartオプション使用時）
enable_uart=1
dtoverlay=disable-bt
```

#### ワークフロー例

```bash
# 1. ドライブを確認
python sd_writer.py --list

# 出力例:
# [リムーバブル] E:
# [リムーバブル] F:

# 2. ドライランでテスト
python sd_writer.py --drive E: --hdmi --dry-run

# 3. 実際に書き込み
python sd_writer.py --drive E: --hdmi

# 4. SDカードを安全に取り外し、Raspberry Piに挿入

# 5. 動作確認（UART使用時）
python serial_monitor.py --port COM3 --baud 115200
```

---

## セットアップ

必要なPythonパッケージをインストール：

```bash
cd pc_tools
pip install -r requirements.txt
```

### 依存パッケージ

- `pyserial>=3.5` - シリアル通信
- `colorama>=0.4.6` - カラー出力（オプション）

---

## トラブルシューティング

### serial_monitor.py

**問題:** ポートが開けない

**解決策:**
- ポート名が正しいか確認（`--list`で確認）
- 他のアプリケーションがポートを使用していないか確認
- Windows: デバイスマネージャーでドライバを確認
- Linux: ユーザーに`dialout`グループの権限があるか確認
  ```bash
  sudo usermod -a -G dialout $USER
  # ログアウト/ログインが必要
  ```

### sd_writer.py

**問題:** `kernel.img が見つかりません`

**解決策:**
- プロジェクトをビルドしてください
  ```bash
  cd build
  .\build.bat  # Windows
  bash build.sh  # Linux
  ```

**問題:** `必須ブートファイルが見つかりません`

**解決策:**
- ファームウェアリポジトリをクローンしてください
  ```bash
  # プロジェクトルートで実行
  git clone --depth=1 https://github.com/raspberrypi/firmware.git
  # または既存のfirmware/bootディレクトリに必要なファイルを配置
  ```

**問題:** 書き込み後、Raspberry Piが起動しない

**チェック項目:**
- SDカードが正しくフォーマットされているか（FAT32）
- config.txtの設定が正しいか
- 電源供給が十分か（5V 2.5A以上推奨）
- ACT LEDが点滅するか（SDカードアクセス確認）

---

## ライセンス

このプロジェクトのライセンスに従います。

## 参考

- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
- [Trampoline RTOS](https://github.com/TrampolineRTOS/trampoline)
- [pySerial Documentation](https://pyserial.readthedocs.io/)
