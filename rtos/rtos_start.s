.syntax unified
.cpu cortex-m0
.thumb

.global rtos_start
.type rtos_start, %function

.text
.thumb_func

rtos_start:

    /*
     * R0 = pointer to rtos_task_t
     *
     * struct:
     *   offset 0: sp
     *   offset 4: stack[]
     */

    LDR     R0, [R0]

    /*
     * Restore R4-R7.
     *
     * Cortex-M0 does not support the Cortex-M3/M4-style
     * arbitrary high-register LDM instruction we used before.
     */
    POP     {R4-R7}

    /*
     * We need to restore R8-R11 as well.
     *
     * Cortex-M0's PUSH/POP instructions only directly
     * address R4-R7.
     *
     * Load the upper registers through low registers.
     */

    POP     {R1-R3}

    MOV     R8, R1
    MOV     R9, R2
    MOV     R10, R3

    POP     {R1}

    MOV     R11, R1

    /*
     * This implementation is intentionally simplified.
     * The next step is to make the context layout and
     * restoration sequence match exactly.
     */

    MSR     PSP, R0

    /*
     * Return to Thread mode using PSP.
     */
    LDR     R0, =0xFFFFFFFD
    MOV     LR, R0

    BX      LR

.size rtos_start, .-rtos_start