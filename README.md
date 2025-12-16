# Trampoline OS on Raspberry Pi 4 - AUTOSAR実装プロジェクト

このプロジェクトは、AUTOSAR準拠のリアルタイムOS「Trampoline」をRaspberry Pi 4で動作させ、HDMIディスプレイまたはシリアル通信で出力する実装例です。

## 概要

Trampolineは、フランスのNantes大学とIRCCyN研究所で開発されたAUTOSAR OS準拠のオープンソースRTOSです。本プロジェクトでは以下を実現します：

- Raspberry Pi 4（BCM2711, Cortex-A72）での動作
- HDMI出力またはUARTシリアル通信によるPC連携
- AUTOSAR OILによるシステム設定
- 周期タスクと通信タスクの実装

## 必要な環境

### ハードウェア
- Raspberry Pi 4（必須）
- HDMIディスプレイ（出力確認用）または USB-シリアル変換ケーブル（UART通信用）
- microSDカード（8GB以上）

### ソフトウェア（開発PC）
- Python 3.8以上
- ARM クロスコンパイラ（arm-none-eabi-gcc）
- Trampolineソース（自動ダウンロード）
- pyserial（Python通信ライブラリ）

## プロジェクト構成

```
AutosarTest3/
├── README.md                     # このファイル
├── app/
│   ├── app.oil                   # AUTOSAR OIL設定ファイル
│   ├── main.c                    # メインアプリケーション
│   └── uart_comm.c               # UART通信ドライバ
├── build/
│   ├── build.sh                  # ビルドスクリプト
│   └── Makefile                  # Makeファイル
├── pc_tools/
│   ├── serial_monitor.py         # PC側通信プログラム
│   └── requirements.txt          # Python依存パッケージ
└── docs/
    └── setup_guide.md            # 詳細セットアップガイド
```

## セットアップ手順

### 1. Trampolineソースの取得

```bash
# トランポリンOSのクローン
git clone https://github.com/TrampolineRTOS/trampoline.git ../trampoline
cd ../trampoline
git checkout master
```

### 2. ARM クロスコンパイラのインストール

**Windows:**
```powershell
# ARM GCC Toolchainをダウンロード
# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
# arm-gnu-toolchain-<version>-mingw-w64-i686-arm-none-eabi.exe をインストール
```

**Linux/WSL:**
```bash
sudo apt-get update
sudo apt-get install gcc-arm-none-eabi binutils-arm-none-eabi
```

### 3. プロジェクトのビルド

```bash
cd AutosarTest3
bash build/build.sh
```

### 4. Raspberry Piへの展開

```bash
# SDカードをフォーマットし、ブートローダーと共にバイナリをコピー
# 詳細はdocs/setup_guide.mdを参照
```

### 5. PC側通信プログラムの準備

```bash
cd pc_tools
pip install -r requirements.txt
python serial_monitor.py --port COM3 --baud 115200
```

## 動作確認

1. Raspberry PiにUSB-シリアル変換を接続（GPIO14/15またはUSB）
2. PCで通信プログラムを起動
3. Raspberry Piに電源投入
4. PCのターミナルに周期的なメッセージが表示されることを確認

## OIL設定の説明

`app/app.oil`でAUTOSARシステムを設定：
- OS設定（スケジューリングポリシー、タイマー）
- タスク定義（周期、優先度）
- リソース/イベント設定
- 割り込みハンドラ設定

## 参考資料

- [Trampoline GitHub](https://github.com/TrampolineRTOS/trampoline)
- [AUTOSAR仕様書](https://www.autosar.org/)
- [Raspberry Pi GPIO](https://www.raspberrypi.org/documentation/)

## トラブルシューティング

### ビルドエラー
- クロスコンパイラのパスが通っているか確認
- Trampolineソースのパスが正しいか確認

### 通信できない
- シリアルポート名を確認（Windows: COM*, Linux: /dev/ttyUSB*）
- ボーレートが一致しているか確認（115200bps）
- GPIO接続を確認（TX/RX、GND）

## ライセンス

このプロジェクトはMITライセンスです。Trampolineは独自のライセンスに従います。
