.syntax unified
.cpu cortex-m0
.thumb

.global rtos_start
.global SVC_Handler
.extern current_task

.type rtos_start, %function
.type SVC_Handler, %function


/*
 * ---------------------------------------------------------
 * rtos_start()
 *
 * Called from main():
 *
 *     rtos_start(&task1);
 *
 * R0 = pointer to rtos_task_t
 *
 * We save the task pointer globally so SVC_Handler can
 * access it after the processor enters Handler mode.
 * ---------------------------------------------------------
 */

rtos_start:

    /*
     * Save task pointer.
     */
    LDR     R1, =current_task
    STR     R0, [R1]

    /*
     * Generate Supervisor Call.
     *
     * This moves the CPU into Handler mode and causes
     * SVC_Handler to execute.
     */
    SVC     #0

    /*
     * We should never return here.
     */
    B       .


.size rtos_start, .-rtos_start


/*
 * ---------------------------------------------------------
 * SVC_Handler()
 *
 * We arrive here in Handler mode.
 *
 * Goal:
 *
 *     PSP = task->sp
 *
 * Then return to Thread mode using PSP.
 * ---------------------------------------------------------
 */

SVC_Handler:

    /*
     * Load address of current_task.
     */
    LDR     R0, =current_task
    LDR     R0, [R0]

    /*
     * R0 = task->sp
     */
    LDR     R0, [R0]

    /*
     * PSP = task stack pointer.
     */
    MSR     PSP, R0

    /*
     * Tell the Cortex-M:
     *
     *   Return to Thread mode
     *   Use PSP
     *
     * 0xFFFFFFFD = EXC_RETURN w/ PSP
     */
    LDR     R0, =0xFFFFFFFD
    MOV     LR, R0

    /*
     * Exception return.
     *
     * Cortex-M recognizes LR as an EXC_RETURN value.
     */
    BX      LR //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //!This^^^ is where the error occurs to go into default handler


.size SVC_Handler, .-SVC_Handler