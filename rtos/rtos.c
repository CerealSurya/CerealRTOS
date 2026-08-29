#include "rtos.h"

#define INITIAL_XPSR 0x01000000UL

/* Global pointer to current task - placed in separate section to avoid stack collision */
rtos_task_t *current_task = 0; //__attribute__((section(".data.current_task"))) 

void rtos_task_create(rtos_task_t *task, void (*entry)(void))
{
    uint32_t *sp = &task->stack[RTOS_STACK_SIZE];

    /*
     * Hardware-saved exception frame.
     *
     * This is what the Cortex-M expects to find when
     * returning from an exception.
     */

    *(--sp) = INITIAL_XPSR;                 // xPSR
    *(--sp) = (uint32_t)entry | 1U;          // PC
    *(--sp) = (uint32_t)0;                  // LR
    *(--sp) = (uint32_t)0;                  // R12
    *(--sp) = (uint32_t)0;                  // R3
    *(--sp) = (uint32_t)0;                  // R2
    *(--sp) = (uint32_t)0;                  // R1
    *(--sp) = (uint32_t)0xBEEF;                  // R0

    /*
     * Software-saved registers.
     *
     * We aren't context-switching yet, so these just
     * need valid initial values.
     */
    // *(--sp) = 0;  // R4
    // *(--sp) = 0;  // R5
    // *(--sp) = 0;  // R6
    // *(--sp) = 0;  // R7
    // *(--sp) = 0;  // R8
    // *(--sp) = 0;  // R9
    // *(--sp) = 0;  // R10
    // *(--sp) = 0;  // R11

    task->sp = sp;
}