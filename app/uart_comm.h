/**
 * UART Communication Driver Header
 * For Raspberry Pi UART0
 */

#ifndef UART_COMM_H
#define UART_COMM_H

#include <stdint.h>

/**
 * Initialize UART with specified baud rate
 * @param baudrate: Baud rate (e.g., 9600, 115200)
 */
void uart_init(uint32_t baudrate);

/**
 * Send a single character
 * @param c: Character to send
 */
void uart_putc(char c);

/**
 * Receive a single character (blocking)
 * @return: Received character
 */
char uart_getc(void);

/**
 * Send a null-terminated string
 * @param str: String to send
 */
void uart_puts(const char *str);

/**
 * Check if receive data is available
 * @return: 1 if data available, 0 otherwise
 */
uint8_t uart_available(void);

/**
 * Print hexadecimal value
 * @param value: 32-bit value to print
 */
void uart_put_hex(uint32_t value);

/**
 * Print decimal value
 * @param value: 32-bit value to print
 */
void uart_put_dec(uint32_t value);

/**
 * Initialize GPIO for LED
 */
void gpio_init(void);

/**
 * Toggle LED state
 */
void gpio_led_toggle(void);

/**
 * Set LED state
 * @param on: 1 for ON, 0 for OFF
 */
void gpio_led_set(uint8_t on);

/**
 * Millisecond delay
 * @param ms: Delay time in milliseconds
 */
void delay_ms(uint32_t ms);

#endif /* UART_COMM_H */
