#include "rtos.h"
#include "ti_msp_dl_config.h"

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
    SYSCFG_DL_init();
    DL_GPIO_setPins(GPIO_GRP_0_PORT, GPIO_GRP_0_PIN_0_PIN); //Turns bottom red LED off

    rtos_task_create(&task1, task1_main);

    rtos_start(&task1);

    while (1)
    {
    }
}

//PA0 - single red LED, PB26, PB27, PB22 Red, green, blue