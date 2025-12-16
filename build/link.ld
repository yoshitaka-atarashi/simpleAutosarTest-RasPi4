/*
 * Linker Script for Raspberry Pi Bare Metal
 * Trampoline AUTOSAR OS
 */

/* Entry point */
ENTRY(_start)

/* Memory layout for Raspberry Pi */
MEMORY
{
    /* Raspberry Pi loads kernel at 0x8000 */
    ram : ORIGIN = 0x8000, LENGTH = 128M
}

SECTIONS
{
    /* Code section */
    .text : {
        KEEP(*(.text.boot))
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
    } > ram

    /* Read-write data */
    .data : {
        *(.data*)
        . = ALIGN(4);
    } > ram

    /* BSS section (zero-initialized data) */
    .bss : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > ram

    /* Stack (grows downward) */
    .stack : {
        . = ALIGN(8);
        __stack_start = .;
        . = . + 0x10000; /* 64KB stack */
        __stack_end = .;
    } > ram

    /* Heap */
    .heap : {
        . = ALIGN(8);
        __heap_start = .;
        . = . + 0x100000; /* 1MB heap */
        __heap_end = .;
    } > ram

    /* Discard unwanted sections */
    /DISCARD/ : {
        *(.comment)
        *(.gnu*)
        *(.note*)
        *(.eh_frame*)
    }
}

/* End of RAM */
__ram_end = ORIGIN(ram) + LENGTH(ram);
