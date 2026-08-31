#include "rtos.h"
#include <ti/devices/msp/msp.h>

#define INITIAL_XPSR 0x01000000UL

/* Global pointer to current task - placed in separate section to avoid stack collision */
rtos_task_t *current_task = 0; //__attribute__((section(".data.current_task"))) 

/* Next task to be scheduled */
rtos_task_t *next_task = 0;

/* Task registry - tracks all created tasks for scheduling */
static rtos_task_t *task_registry[RTOS_MAX_TASKS];
static uint32_t num_tasks = 0; 

void rtos_task_create(rtos_task_t *task, void (*entry)(void))
{
    uint32_t *sp = &task->stack[RTOS_STACK_SIZE];

    // Ensure 8-byte alignment for exception stacking (Cortex-M requirement)
    sp = (uint32_t *)((uintptr_t)sp & ~7UL);

    /*
     * Hardware-saved exception frame - pushed first (at higher address).
     *
     * This is what the Cortex-M expects to find when
     * returning from an exception (popped automatically
     * on exception return).
     *
     * After creation layout is:
     *   at sp+32: R0
     *   at sp+36: R1
     *   at sp+40: R2
     *   at sp+44: R3
     *   at sp+48: R12
     *   at sp+52: LR
     *   at sp+56: PC
     *   at sp+60: xPSR  (top of stack)
     * Standard: push xPSR first (highest addr), R0 last of this block.
     */
    *(--sp) = INITIAL_XPSR;                 // xPSR
    *(--sp) = (uint32_t)entry | 1U;          // PC (Thumb bit)
    *(--sp) = (uint32_t)0xFFFFFFFDUL;       // LR (dummy EXC_RETURN, not used)
    *(--sp) = (uint32_t)0;                  // R12
    *(--sp) = (uint32_t)0;                  // R3
    *(--sp) = (uint32_t)0;                  // R2
    *(--sp) = (uint32_t)0;                  // R1
    *(--sp) = (uint32_t)0xFFFF;                  // R0

    /*
     * Software-saved registers - pushed second (at lower address).
     *
     * PendSV will save/restore R4-R11 at [sp+0 .. sp+28].
     * sp after this block points to R4 (lowest address), matching
     * PendSV's STR R4, [sp, #0] .. STR R11, [sp, #28] and SVC's
     * LDR R4, [sp, #0] .. LDR R11, [sp, #28] + ADDS #32 to reach HW.
     */
    *(--sp) = (uint32_t)0;                  // R11
    *(--sp) = (uint32_t)0;                  // R10
    *(--sp) = (uint32_t)0;                  // R9
    *(--sp) = (uint32_t)0;                  // R8
    *(--sp) = (uint32_t)0;                  // R7
    *(--sp) = (uint32_t)0;                  // R6
    *(--sp) = (uint32_t)0;                  // R5
    *(--sp) = (uint32_t)0xBEEF;              // R4

    task->sp = sp;

    /* Register task in the RTOS task registry */
    if (num_tasks < RTOS_MAX_TASKS)
    {
        task_registry[num_tasks] = task;
        num_tasks++;
    }
}

/*
 * save_software_stack - Save callee-saved registers (R4-R11) to current task's stack
 * 
 * This function must be called before a context switch to save the actual register
 * values. Calls save_software_stack_asm() which performs the actual register save.
 */
void save_software_stack(void)
{
    if (current_task == 0)
        return;

    /* Call assembly function to save R4-R11 and update stack pointer */
    save_software_stack_asm(current_task);
}

void schedule(void)
{
    if (num_tasks == 0)
        return;
    if (num_tasks == 1)
    {
        next_task = current_task;
        return;
    }
    /* Find current task index and switch to next registered task */
    uint32_t current_index = 0;
    
    for (uint32_t i = 0; i < num_tasks; i++)
    {
        if (task_registry[i] == current_task)
        {
            current_index = i;
            break;
        }
    }
    
    /* Move to next task, wrapping around to beginning if needed */
    uint32_t next_index = (current_index + 1) % num_tasks;
    next_task = task_registry[next_index];
}

void rtos_trigger_pendsv(void)
{
    SCB->ICSR = SCB_ICSR_PENDSVSET_Msk;
    __DSB();
    __ISB();
}

void rtos_yield(void)
{
    schedule();
    rtos_trigger_pendsv();
}

void rtos_systick_init(uint32_t ticks)
{
    /* PendSV lowest priority (3), SysTick medium (1) so SysTick can pend PendSV.
     * SVC stays at 0 (highest) so it isn't preempted.
     */
    NVIC_SetPriority(PendSV_IRQn, (1UL << __NVIC_PRIO_BITS) - 1UL);
    NVIC_SetPriority(SysTick_IRQn, 1UL);
    /* SysTick_Config expects ticks = reload+1 */
    (void)SysTick_Config(ticks);
}

void rtos_init(void)
{
    /* One-time hardware setup. Separated from rtos_start() so
     * assembly stays minimal and readable. CMSIS handles the SHPR
     * priority encoding - no manual 0xE000ED20 / BICS / ORRS needed.
     * 32000 ticks = 1ms at 32MHz.
     */
    rtos_systick_init(64000);
}

void SysTick_Handler(void)
{
    schedule();
    rtos_trigger_pendsv();
}