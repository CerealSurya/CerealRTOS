    .syntax unified
    .cpu cortex-m0plus
    .thumb

    .global rtos_start
    .global SVC_Handler
    .global PendSV_Handler
    .extern current_task
    .extern next_task

    .type rtos_start, %function
    .type SVC_Handler, %function
    .type PendSV_Handler, %function

/*
 * ---------------------------------------------------------
 * rtos_start()
 *
 * Called from main():
 *     rtos_init();
 *     rtos_start(&task1);
 * R0 = pointer to rtos_task_t
 * We save the task pointer globally so SVC_Handler can
 * access it after the processor enters Handler mode.
 * One-time HW init (PendSV priority + SysTick) is now
 * in rtos_init() in rtos.c - no manual SHPR / PUSH/POP
 * needed here.
 * ---------------------------------------------------------
 */
    .thumb_func
rtos_start:
    LDR     R1, =current_task
    STR     R0, [R1]
    SVC     #0
    B       .

    .size rtos_start, .-rtos_start


/*
 * ---------------------------------------------------------
 * SVC_Handler()
 * First task start. Runs in Handler mode (MSP).
 * current_task->sp points to R4 (software frame low).
 * Layout from sp:
 *   0:R4, 4:R5, 8:R6, 12:R7, 16:R8, 20:R9, 24:R10, 28:R11,
 *   32:R0,36:R1,40:R2,44:R3,48:R12,52:LR,56:PC,60:xPSR
 * We restore R4-R11, then set PSP = sp+32 (hardware frame)
 * and exception-return to Thread/PSP.
 * ---------------------------------------------------------
 */
    .thumb_func
SVC_Handler:
    LDR     R0, =current_task
    LDR     R0, [R0]
    LDR     R0, [R0]          /* R0 = task->sp (points to R4) */

    /* Restore R4-R11 */
    LDR     R4, [R0, #0]
    LDR     R5, [R0, #4]
    LDR     R6, [R0, #8]
    LDR     R7, [R0, #12]
    LDR     R1, [R0, #16]
    MOV     R8, R1
    LDR     R1, [R0, #20]
    MOV     R9, R1
    LDR     R1, [R0, #24]
    MOV     R10, R1
    LDR     R1, [R0, #28]
    MOV     R11, R1

    ADDS    R0, #32           /* R0 now = hardware frame (R0) */
    MSR     PSP, R0

    /* Barrier before exception return */
    DSB
    ISB

    /* EXC_RETURN = 0xFFFFFFFD : return to Thread, use PSP */
    LDR     R0, =0xFFFFFFFD
    MOV     LR, R0
    BX      LR

    .size SVC_Handler, .-SVC_Handler
