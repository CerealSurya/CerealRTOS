#include "rtos.h"
#include "ti_msp_dl_config.h"

rtos_task_t task1;
rtos_task_t task2;

void task1_main(void)
{
    while (1)
    {
        DL_GPIO_setPins(GPIO_GRP_0_PORT, GPIO_GRP_0_PIN_0_PIN);
    }
}

void task2_main(void)
{
    while (1)
    {
        DL_GPIO_clearPins(GPIO_GRP_0_PORT, GPIO_GRP_0_PIN_0_PIN);
    }
}

int main(void)
{
    SYSCFG_DL_init();
    rtos_init();

    rtos_task_create(&task1, task1_main);
    rtos_task_create(&task2, task2_main);
    rtos_start(&task1); 
    rtos_start(&task2);
}

//PA0 - single red LED, PB26, PB27, PB22 Red, green, blue
