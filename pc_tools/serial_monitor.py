#!/usr/bin/env python3
"""
Serial Monitor for Trampoline AUTOSAR OS on Raspberry Pi
PC側通信プログラム - Raspberry PiとUART通信を行う

使用方法:
    python serial_monitor.py --port COM3 --baud 115200
    python serial_monitor.py --port /dev/ttyUSB0 --baud 115200
"""

import serial
import argparse
import sys
import time
import threading
from datetime import datetime

try:
    from colorama import init, Fore, Style
    init()
    COLORS_AVAILABLE = True
except ImportError:
    COLORS_AVAILABLE = False
    print("Warning: colorama not installed. Run: pip install colorama")


class SerialMonitor:
    """Raspberry Pi UART通信モニタークラス"""
    
    def __init__(self, port, baudrate=115200, timeout=1):
        """
        初期化
        
        Args:
            port (str): シリアルポート名 (e.g., 'COM3', '/dev/ttyUSB0')
            baudrate (int): ボーレート (デフォルト: 115200)
            timeout (float): タイムアウト秒数
        """
        self.port = port
        self.baudrate = baudrate
        self.timeout = timeout
        self.serial = None
        self.running = False
        self.rx_count = 0
        self.tx_count = 0
        
    def connect(self):
        """シリアルポートに接続"""
        try:
            self.serial = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=self.timeout
            )
            
            self._print_info(f"Connected to {self.port} at {self.baudrate} bps")
            return True
            
        except serial.SerialException as e:
            self._print_error(f"Failed to open {self.port}: {e}")
            return False
    
    def disconnect(self):
        """シリアルポートを切断"""
        if self.serial and self.serial.is_open:
            self.serial.close()
            self._print_info("Disconnected")
    
    def start_monitoring(self):
        """受信監視を開始"""
        if not self.serial or not self.serial.is_open:
            self._print_error("Serial port not open")
            return
        
        self.running = True
        
        # 受信スレッド開始
        rx_thread = threading.Thread(target=self._receive_loop, daemon=True)
        rx_thread.start()
        
        # ユーザー入力処理
        self._print_info("Monitoring started. Type messages to send (Ctrl+C to exit)")
        self._print_separator()
        
        try:
            while self.running:
                user_input = input()
                if user_input:
                    self.send_message(user_input)
                    
        except KeyboardInterrupt:
            self._print_info("\nStopping monitor...")
            self.running = False
            time.sleep(0.5)
    
    def _receive_loop(self):
        """受信ループ（別スレッドで実行）"""
        buffer = ""
        
        while self.running:
            try:
                if self.serial.in_waiting > 0:
                    # データ受信
                    data = self.serial.read(self.serial.in_waiting)
                    text = data.decode('utf-8', errors='ignore')
                    
                    # 受信データをバッファに追加
                    buffer += text
                    
                    # 改行区切りで表示
                    while '\n' in buffer:
                        line, buffer = buffer.split('\n', 1)
                        line = line.rstrip('\r')
                        if line:
                            self._print_received(line)
                            self.rx_count += 1
                else:
                    time.sleep(0.01)
                    
            except Exception as e:
                self._print_error(f"Receive error: {e}")
                break
    
    def send_message(self, message):
        """メッセージを送信"""
        try:
            # 改行を追加して送信
            self.serial.write((message + '\r\n').encode('utf-8'))
            self._print_sent(message)
            self.tx_count += 1
            
        except Exception as e:
            self._print_error(f"Send error: {e}")
    
    def send_test_sequence(self):
        """テストシーケンスを送信"""
        self._print_info("Sending test sequence...")
        
        test_messages = [
            "HELLO",
            "TEST123",
            "STATUS",
            "PING",
        ]
        
        for msg in test_messages:
            self.send_message(msg)
            time.sleep(1)
    
    def _print_info(self, message):
        """情報メッセージを表示"""
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        if COLORS_AVAILABLE:
            print(f"{Fore.CYAN}[{timestamp}] [INFO] {message}{Style.RESET_ALL}")
        else:
            print(f"[{timestamp}] [INFO] {message}")
    
    def _print_error(self, message):
        """エラーメッセージを表示"""
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        if COLORS_AVAILABLE:
            print(f"{Fore.RED}[{timestamp}] [ERROR] {message}{Style.RESET_ALL}")
        else:
            print(f"[{timestamp}] [ERROR] {message}")
    
    def _print_received(self, message):
        """受信メッセージを表示"""
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        if COLORS_AVAILABLE:
            print(f"{Fore.GREEN}[{timestamp}] [RX] {message}{Style.RESET_ALL}")
        else:
            print(f"[{timestamp}] [RX] {message}")
    
    def _print_sent(self, message):
        """送信メッセージを表示"""
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        if COLORS_AVAILABLE:
            print(f"{Fore.YELLOW}[{timestamp}] [TX] {message}{Style.RESET_ALL}")
        else:
            print(f"[{timestamp}] [TX] {message}")
    
    def _print_separator(self):
        """区切り線を表示"""
        print("-" * 80)


def list_serial_ports():
    """利用可能なシリアルポート一覧を表示"""
    import serial.tools.list_ports
    
    ports = serial.tools.list_ports.comports()
    
    if not ports:
        print("No serial ports found")
        return
    
    print("\nAvailable serial ports:")
    print("-" * 60)
    for port in ports:
        print(f"  {port.device}")
        print(f"    Description: {port.description}")
        print(f"    Hardware ID: {port.hwid}")
        print()


def main():
    """メイン関数"""
    parser = argparse.ArgumentParser(
        description='Serial Monitor for Trampoline AUTOSAR OS on Raspberry Pi'
    )
    
    parser.add_argument(
        '--port', '-p',
        type=str,
        help='Serial port (e.g., COM3, /dev/ttyUSB0)'
    )
    
    parser.add_argument(
        '--baud', '-b',
        type=int,
        default=115200,
        help='Baud rate (default: 115200)'
    )
    
    parser.add_argument(
        '--list', '-l',
        action='store_true',
        help='List available serial ports'
    )
    
    parser.add_argument(
        '--test', '-t',
        action='store_true',
        help='Send test sequence after connection'
    )
    
    args = parser.parse_args()
    
    # ポート一覧表示
    if args.list:
        list_serial_ports()
        return
    
    # ポート指定確認
    if not args.port:
        print("Error: Serial port not specified")
        print("Use --list to see available ports")
        print("Usage: python serial_monitor.py --port COM3 --baud 115200")
        sys.exit(1)
    
    # モニター起動
    monitor = SerialMonitor(args.port, args.baud)
    
    if not monitor.connect():
        sys.exit(1)
    
    try:
        # テストシーケンス送信
        if args.test:
            time.sleep(1)
            monitor.send_test_sequence()
        
        # 監視開始
        monitor.start_monitoring()
        
    finally:
        monitor.disconnect()
        print(f"\nStatistics: RX={monitor.rx_count}, TX={monitor.tx_count}")


if __name__ == '__main__':
    main()
