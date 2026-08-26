.syntax unified
.cpu cortex-m0
.thumb

.global Reset_Handler
.global Default_Handler
.global HardFault_Handler
.global NMI_Handler
.global MemManage_Handler
.global BusFault_Handler
.global UsageFault_Handler
.global SVC_Handler
.global DebugMon_Handler
.global PendSV_Handler
.global SysTick_Handler

.section .intvecs
.align 2

interruptVectors:
    .word 0x20002000
    .word Reset_Handler
    .word NMI_Handler
    .word HardFault_Handler
    .word MemManage_Handler
    .word BusFault_Handler
    .word UsageFault_Handler
    .word 0
    .word 0
    .word 0
    .word SVC_Handler
    .word DebugMon_Handler
    .word 0
    .word PendSV_Handler
    .word SysTick_Handler
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0

.text
.thumb_func

Default_Handler:
    B .

HardFault_Handler:
    B .

NMI_Handler:
    B .

MemManage_Handler:
    B .

BusFault_Handler:
    B .

UsageFault_Handler:
    B .

SVC_Handler:
    B .

DebugMon_Handler:
    B .

PendSV_Handler:
    B .

SysTick_Handler:
    B .

Reset_Handler:
    .global _c_int00
    b _c_int00

.size Reset_Handler, .-Reset_Handler
