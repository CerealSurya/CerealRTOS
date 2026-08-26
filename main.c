#include "rtos.h"

rtos_task_t task1;

void task1_main(void)
{
    while (1)
    {
        // Task 1 code
    }
}

int main(void)
{
    rtos_task_create(&task1, task1_main);

    rtos_start(&task1);

    while (1)
    {
    }
}