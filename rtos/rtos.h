#ifndef RTOS_H
#define RTOS_H

#include <stdint.h>

#define RTOS_STACK_SIZE 256

typedef struct
{
    uint32_t *sp;
    uint32_t stack[RTOS_STACK_SIZE] __attribute__((aligned(8)));;
} rtos_task_t;

void rtos_task_create(rtos_task_t *task, void (*entry)(void));
void rtos_start(rtos_task_t *task);

#endif