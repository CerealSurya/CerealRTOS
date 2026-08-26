#include "rtos.h"

#define INITIAL_XPSR 0x01000000UL
#define EXC_RETURN_THREAD_PSP 0xFFFFFFFDUL

void rtos_task_create(rtos_task_t *task, void (*entry)(void))
{
    /*
     * Cortex-M stacks grow downward.
     *
     * Start at the top of our task's stack.
     */
    uint32_t *sp = &task->stack[RTOS_STACK_SIZE];

    /*
     * Hardware exception stack frame.
     *
     * Cortex-M will expect this exact layout when
     * returning from an exception.
     */

    *(--sp) = INITIAL_XPSR;       // xPSR
    *(--sp) = (uint32_t)entry;    // PC
    *(--sp) = 0;                  // LR
    *(--sp) = 0;                  // R12
    *(--sp) = 0;                  // R3
    *(--sp) = 0;                  // R2
    *(--sp) = 0;                  // R1
    *(--sp) = 0;                  // R0

    /*
     * Software-saved registers.
     *
     * These are restored by rtos_start/context-switch code.
     */
    *(--sp) = 0;  // R4
    *(--sp) = 0;  // R5
    *(--sp) = 0;  // R6
    *(--sp) = 0;  // R7
    *(--sp) = 0;  // R8
    *(--sp) = 0;  // R9
    *(--sp) = 0;  // R10
    *(--sp) = 0;  // R11

    task->sp = sp;
}

