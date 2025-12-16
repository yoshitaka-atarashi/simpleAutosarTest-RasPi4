/**
 * UART Communication Driver for Raspberry Pi
 * Supports UART0 (GPIO14/15) on BCM2835/BCM2836/BCM2837
 */

#include "uart_comm.h"
#include <stdint.h>

/* Raspberry Pi Peripheral Base Addresses */
#if defined(RPI4)
    #define PERIPHERAL_BASE  0xFE000000  /* RPi 4 (BCM2711) */
#elif defined(RPI3)
    #define PERIPHERAL_BASE  0x3F000000  /* RPi 3 (BCM2837) */
#else
    #define PERIPHERAL_BASE  0x20000000  /* RPi 1/2 (BCM2835/BCM2836) */
#endif

/* GPIO Registers */
#define GPIO_BASE        (PERIPHERAL_BASE + 0x200000)
#define GPFSEL1          ((volatile uint32_t*)(GPIO_BASE + 0x04))
#define GPSET0           ((volatile uint32_t*)(GPIO_BASE + 0x1C))
#define GPCLR0           ((volatile uint32_t*)(GPIO_BASE + 0x28))
#define GPPUD            ((volatile uint32_t*)(GPIO_BASE + 0x94))
#define GPPUDCLK0        ((volatile uint32_t*)(GPIO_BASE + 0x98))

/* UART0 Registers */
#define UART0_BASE       (PERIPHERAL_BASE + 0x201000)
#define UART0_DR         ((volatile uint32_t*)(UART0_BASE + 0x00))
#define UART0_RSRECR     ((volatile uint32_t*)(UART0_BASE + 0x04))
#define UART0_FR         ((volatile uint32_t*)(UART0_BASE + 0x18))
#define UART0_ILPR       ((volatile uint32_t*)(UART0_BASE + 0x20))
#define UART0_IBRD       ((volatile uint32_t*)(UART0_BASE + 0x24))
#define UART0_FBRD       ((volatile uint32_t*)(UART0_BASE + 0x28))
#define UART0_LCRH       ((volatile uint32_t*)(UART0_BASE + 0x2C))
#define UART0_CR         ((volatile uint32_t*)(UART0_BASE + 0x30))
#define UART0_IFLS       ((volatile uint32_t*)(UART0_BASE + 0x34))
#define UART0_IMSC       ((volatile uint32_t*)(UART0_BASE + 0x38))
#define UART0_RIS        ((volatile uint32_t*)(UART0_BASE + 0x3C))
#define UART0_MIS        ((volatile uint32_t*)(UART0_BASE + 0x40))
#define UART0_ICR        ((volatile uint32_t*)(UART0_BASE + 0x44))
#define UART0_DMACR      ((volatile uint32_t*)(UART0_BASE + 0x48))

/* UART FR Register Bits */
#define UART_FR_RXFE     (1 << 4)  /* Receive FIFO empty */
#define UART_FR_TXFF     (1 << 5)  /* Transmit FIFO full */
#define UART_FR_RXFF     (1 << 6)  /* Receive FIFO full */
#define UART_FR_TXFE     (1 << 7)  /* Transmit FIFO empty */

/* GPIO Settings */
#define LED_GPIO         17        /* ACT LED on GPIO17 (変更可能) */

/**
 * Delay function (approximate)
 */
static void delay(uint32_t count)
{
    volatile uint32_t i;
    for (i = 0; i < count; i++) {
        __asm__ volatile("nop");
    }
}

/**
 * Initialize UART0
 */
void uart_init(uint32_t baudrate)
{
    /* UART0を無効化 */
    *UART0_CR = 0;
    
    /* GPIO 14, 15をAlt0（UART）に設定 */
    uint32_t ra = *GPFSEL1;
    ra &= ~((7 << 12) | (7 << 15));  /* GPIO14,15をクリア */
    ra |= (4 << 12) | (4 << 15);     /* Alt0に設定 */
    *GPFSEL1 = ra;
    
    /* プルアップ/ダウン無効化 */
    *GPPUD = 0;
    delay(150);
    *GPPUDCLK0 = (1 << 14) | (1 << 15);
    delay(150);
    *GPPUDCLK0 = 0;
    
    /* 割り込みクリア */
    *UART0_ICR = 0x7FF;
    
    /* ボーレート設定（3MHz UARTクロック想定） */
    /* Baud rate divisor = UARTCLK / (16 * Baud rate) */
    /* 例: 3000000 / (16 * 115200) = 1.627 -> IBRD=1, FBRD=40 */
    uint32_t divisor = (3000000 * 4) / baudrate;
    *UART0_IBRD = divisor >> 6;
    *UART0_FBRD = divisor & 0x3F;
    
    /* ライン制御: 8bit, FIFOイネーブル */
    *UART0_LCRH = (1 << 4) | (1 << 5) | (1 << 6);
    
    /* 割り込みマスク（受信割り込みイネーブル） */
    *UART0_IMSC = (1 << 4);  /* RXIM */
    
    /* UART有効化 */
    *UART0_CR = (1 << 0) | (1 << 8) | (1 << 9);  /* UARTEN, TXE, RXE */
}

/**
 * Send a character
 */
void uart_putc(char c)
{
    /* Transmit FIFOが空くまで待つ */
    while (*UART0_FR & UART_FR_TXFF);
    *UART0_DR = c;
}

/**
 * Receive a character (blocking)
 */
char uart_getc(void)
{
    /* Receive FIFOにデータが来るまで待つ */
    while (*UART0_FR & UART_FR_RXFE);
    return (*UART0_DR & 0xFF);
}

/**
 * Send a string
 */
void uart_puts(const char *str)
{
    while (*str) {
        if (*str == '\n') {
            uart_putc('\r');
        }
        uart_putc(*str++);
    }
}

/**
 * Check if data is available
 */
uint8_t uart_available(void)
{
    return !(*UART0_FR & UART_FR_RXFE);
}

/**
 * Print hexadecimal value
 */
void uart_put_hex(uint32_t value)
{
    const char hex[] = "0123456789ABCDEF";
    uart_puts("0x");
    for (int i = 7; i >= 0; i--) {
        uart_putc(hex[(value >> (i * 4)) & 0xF]);
    }
}

/**
 * Print decimal value
 */
void uart_put_dec(uint32_t value)
{
    char buffer[12];
    int i = 0;
    
    if (value == 0) {
        uart_putc('0');
        return;
    }
    
    while (value > 0) {
        buffer[i++] = '0' + (value % 10);
        value /= 10;
    }
    
    while (i > 0) {
        uart_putc(buffer[--i]);
    }
}

/**
 * Initialize GPIO for LED
 */
void gpio_init(void)
{
    /* GPIO17をOutputに設定 */
    uint32_t ra = *GPFSEL1;
    ra &= ~(7 << 21);      /* GPIO17クリア */
    ra |= (1 << 21);       /* Output設定 */
    *GPFSEL1 = ra;
    
    /* 初期状態: OFF */
    *GPCLR0 = (1 << LED_GPIO);
}

/**
 * Toggle LED
 */
void gpio_led_toggle(void)
{
    static uint8_t state = 0;
    
    if (state) {
        *GPCLR0 = (1 << LED_GPIO);  /* OFF */
    } else {
        *GPSET0 = (1 << LED_GPIO);  /* ON */
    }
    
    state = !state;
}

/**
 * Set LED state
 */
void gpio_led_set(uint8_t on)
{
    if (on) {
        *GPSET0 = (1 << LED_GPIO);
    } else {
        *GPCLR0 = (1 << LED_GPIO);
    }
}

/**
 * Millisecond delay
 */
void delay_ms(uint32_t ms)
{
    /* 簡易的な遅延（要調整） */
    delay(ms * 1000);
}
