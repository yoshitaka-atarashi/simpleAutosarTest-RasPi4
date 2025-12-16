/*
 * Boot code for Raspberry Pi
 * This is a minimal boot stub for bare metal applications
 */

.section ".text.boot"

.global _start

_start:
    /* Get CPU ID - only CPU 0 should continue */
    mrc p15, 0, r0, c0, c0, 5
    and r0, r0, #3
    cmp r0, #0
    bne halt

    /* Set stack pointer */
    ldr sp, =__stack_end

    /* Clear BSS section */
    ldr r0, =__bss_start
    ldr r1, =__bss_end
    mov r2, #0

clear_bss:
    cmp r0, r1
    bge clear_bss_done
    str r2, [r0], #4
    b clear_bss

clear_bss_done:
    /* Enable VFP/NEON (if needed) */
    mrc p15, 0, r0, c1, c0, 2
    orr r0, r0, #0x300000    /* Single precision */
    orr r0, r0, #0xC00000    /* Double precision */
    mcr p15, 0, r0, c1, c0, 2
    isb
    mov r0, #0x40000000
    vmsr fpexc, r0

    /* Jump to C main function */
    bl main

halt:
    wfe
    b halt

.section ".data"
/* Data section */

.section ".bss"
/* BSS section */
