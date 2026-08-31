    .syntax unified
    .cpu cortex-m0plus
    .thumb

    .global PendSV_Handler
    .extern current_task
    .extern next_task
    .type PendSV_Handler, %function

/*
 * save_software_stack_asm(rtos_task_t *task)
 * 
 * Arguments:
 *   R0 = pointer to rtos_task_t (current_task)
 * 
 * This function saves the callee-saved registers (R4-R11) to the task's stack
 * and updates the task's stack pointer.
 * 
 * rtos_task_t structure:
 *   offset 0: uint32_t *sp  (stack pointer)
 */
.global save_software_stack_asm
.type save_software_stack_asm, %function

save_software_stack_asm:
    /* Register aliases for this function */
    task_ptr .req r0      /* R0: pointer to task structure */
    sp_ptr .req r1         /* R1: task's stack pointer */
    temp .req r2           /* R2: temporary working register */
    offset .req r3         /* R3: offset/value register */

    /* Load task's stack pointer from task->sp (at offset 0) */
    ldr sp_ptr, [task_ptr]
    
    /* Decrement stack pointer by 32 bytes (8 registers * 4 bytes) */
    /* Use temp as working register for arithmetic */
    mov temp, sp_ptr
    movs offset, #16
    subs temp, temp, offset
    subs temp, temp, offset
    
    /* Store R4-R7 (low registers, can use direct str) */
    str r4, [temp, #0]
    str r5, [temp, #4]
    str r6, [temp, #8]
    str r7, [temp, #12]
    
    /* Store R8-R11 (high registers, must move to temp first) */
    mov offset, r8
    str offset, [temp, #16]
    mov offset, r9
    str offset, [temp, #20]
    mov offset, r10
    str offset, [temp, #24]
    mov offset, r11
    str offset, [temp, #28]
    
    /* Store updated stack pointer back to task->sp */
    str temp, [task_ptr]
    
    /* Return to caller */
    bx lr
    
    .size save_software_stack_asm, .-save_software_stack_asm


/*
 * ---------------------------------------------------------
 * PendSV_Handler()
 * Full context switch. Also runs in Handler mode (MSP).
 * PSP holds current task's stack (points to hardware frame
 * R0 after hardware push). We save R4-R11 below it.
 * ---------------------------------------------------------
 */
    .thumb_func
PendSV_Handler:
    MRS     R0, PSP           /* R0 = current PSP (hardware frame) */

    LDR     R1, =current_task
    LDR     R1, [R1]          /* R1 = current_task */
    CMP     R1, #0
    BEQ     PendSV_load_next  /* no task to save (first switch) */

    /* Make room for R4-R11 (32 bytes) */
    SUBS    R0, #32
    /* Save low regs */
    STR     R4, [R0, #0]
    STR     R5, [R0, #4]
    STR     R6, [R0, #8]
    STR     R7, [R0, #12]
    /* Save high regs via temp R2 */
    MOV     R2, R8
    STR     R2, [R0, #16]
    MOV     R2, R9
    STR     R2, [R0, #20]
    MOV     R2, R10
    STR     R2, [R0, #24]
    MOV     R2, R11
    STR     R2, [R0, #28]

    /* Save updated sp to current_task->sp */
    STR     R0, [R1]

PendSV_load_next:
    LDR     R1, =next_task
    LDR     R1, [R1]          /* R1 = next_task */
    CMP     R1, #0
    BEQ     PendSV_exit       /* no next task, nothing to restore */

    LDR     R0, [R1]          /* R0 = next_task->sp (points to R4) */

    /* Restore R4-R11 */
    LDR     R4, [R0, #0]
    LDR     R5, [R0, #4]
    LDR     R6, [R0, #8]
    LDR     R7, [R0, #12]
    LDR     R2, [R0, #16]
    MOV     R8, R2
    LDR     R2, [R0, #20]
    MOV     R9, R2
    LDR     R2, [R0, #24]
    MOV     R10, R2
    LDR     R2, [R0, #28]
    MOV     R11, R2

    ADDS    R0, #32           /* R0 = hardware frame */
    MSR     PSP, R0

    /* current_task = next_task */
    LDR     R2, =current_task
    STR     R1, [R2]

    /* Optional: clear next_task */
    /* LDR R2, =next_task; MOVS R1, #0; STR R1, [R2] */

    DSB
    ISB

PendSV_exit:
    LDR     R0, =0xFFFFFFFD
    MOV     LR, R0
    BX      LR

    .size PendSV_Handler, .-PendSV_Handler