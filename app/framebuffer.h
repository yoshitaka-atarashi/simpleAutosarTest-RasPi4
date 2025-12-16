/**
 * @file framebuffer.h
 * @brief HDMI Framebuffer driver for Raspberry Pi 4
 * 
 * Provides simple text output to HDMI display via framebuffer
 */

#ifndef FRAMEBUFFER_H
#define FRAMEBUFFER_H

#include <stdint.h>

/* Initialize framebuffer (HDMI output) */
int fb_init(void);

/* Print string to screen */
void fb_puts(const char* str);

/* Print single character */
void fb_putc(char c);

/* Print hexadecimal number */
void fb_put_hex(uint32_t value);

/* Print decimal number */
void fb_put_dec(uint32_t value);

/* Clear screen */
void fb_clear(void);

/* Set text color (RGB) */
void fb_set_color(uint8_t r, uint8_t g, uint8_t b);

#endif /* FRAMEBUFFER_H */
