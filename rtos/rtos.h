#ifndef RTOS_H
#define RTOS_H

#include <stdint.h>
#include <stddef.h>

#define RTOS_STACK_SIZE 256
#define RTOS_MAX_TASKS 10
typedef struct
{
    uint32_t *sp;
    uint32_t stack[RTOS_STACK_SIZE] __attribute__((aligned(8)));;
} rtos_task_t;

void rtos_task_create(rtos_task_t *task, void (*entry)(void));
void rtos_start(rtos_task_t *task);
void schedule(void);
void save_software_stack(void);
void save_software_stack_asm(rtos_task_t *task);

/* SysTick / PendSV helpers */
void SysTick_Handler(void);
void PendSV_Handler(void); /* implemented in assembly */
void rtos_systick_init(uint32_t ticks);
void rtos_init(void); /* one-time HW init: PendSV priority + SysTick */
void rtos_trigger_pendsv(void);
void rtos_yield(void);

/* scheduler state - accessed from assembly */
extern rtos_task_t *current_task;
extern rtos_task_t *next_task;

#endif