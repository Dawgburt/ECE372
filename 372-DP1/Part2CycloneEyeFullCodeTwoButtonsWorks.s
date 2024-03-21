@Phil Nevins
@ECE 371 Microprocessor
@Design Project 2, Part 2
@This program will use a pushbutton to trigger an interrupt and cycle an LED
@The program will do this exactly: push button, LED Cyclone on, push button,
@LED cyclone off, push button, LED cyclone on...
@Program uses R0-R3, R5-R8

.text
.global _start
.global INT_DIRECTOR

_start:

LDR R13, =STACK1		@Point to base of STACK1 for SVC mode
ADD R13, R13, #0x1000	@Point to top of STACK1
CPS #0x12				@Switch to IRQ mode
LDR R13, =STACK2		@Point to IRQ STACK2
ADD R13, R13, #0x1000	@Point to top of STACK2
CPS #0x13				@Back to SVC mode

@Turn on GPIO1 CLK
MOV R0, #0x02			@Value to enable CLK for GPIO module
LDR R1, =0x44E000AC		@ADDR OF CM_PER_GPIO1_CLKCTRL Register
STR R0, [R1]			@Write #02 to register
LDR R0, =0x4804C000		@Base ADDR for GPIO1 Registers

@Detect Falling Edge on GPIO1_3 and eable to assert POINTRPEND1
ADD R1, R0, #0x14C		@R1 = ADDR of GPIO1_FALLINGDETECT Register
MOV R2, #0x00000008		@Load value for Bit 3 (GPIO1_3)
LDR R3, [R1]			@Read GPIO1_FALLINGDETECT register
ORR R3, R3, R2			@Modify (set bit 3)
STR R3, [R1]			@Write back
ADD R1, R0, #0x34 		@Addr of GPIO1_IRQSTATUS_SET_0 Register
STR R2, [R1]			@Enable GPIO1_3 request on POINTRPEND1

@Initialize INTC
LDR R1, =0x482000E8		@ADDR of INTC_MIR_CLEAR3 Register
MOV R2, #0x04			@Value to unmask INTC INT 98, GPIONT1A
STR R2, [R1]			@Write to INTC_MIR_CLEAR3 Register

@Make sure processor IRQ enabled in CPSR
MRS R3, CPSR			@Copy CPSR to R3
BIC R3, #0x80			@Clear bit 7
MSR CPSR_c, R3			@Write back to CPSR

@Program GPIO1_21-24 as output
LDR R0, =0xFE1FFFFF			@Load word to program GPIO1_21-24 to output
LDR R1, =0x4804C134			@Addr of GPIO1_OE Register
LDR R2, [R1]				@Read GPIO1_OE Register
AND R2, R2, R0				@Modify word read in with R0
STR R2, [R1]				@Write back to GPIO1_OE Register

@Wait for interrupt
WaitLoop: NOP
		B WaitLoop

INT_DIRECTOR:
STMFD SP!, {R0-R3, LR}	@Push registers on stack
LDR R0, =0x482000F8		@ADDR of INTC_PENDING_IRQ3 Register
LDR R1, [R0]			@Read INTC_PENDING_IRQ3 Register
TST R1, #0x00000004		@Test Bit 2
BEQ PASS_ON				@Not from GPIOINT1A, go to wait loop, Else
LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
LDR R1, [R0]			@Read STATUS Register
TST R1, #0x00000008		@Test if bit 3 = 1
BNE BUTTON_SVC			@If 1, go to button_svc
BEQ PASS_ON				@If 0, go to wait loop

PASS_ON:
	MOV R1, #0x00000008		@Value to turn off GPIO1_3 & INTC Interrupt request
	STR R1, [R0]			@Write to GPIO1_IRQSTATUS_0 Register

		@turn off NEWIRQA bit in INTC_CONTROL, so processor can respond to new IRQ
	LDR R0, =0x48200048		@ADDR of INTC_CONTROL Register
	MOV R1, #0x01				@Value to clear bit 0
	STR R1, [R0]			@Write to INTC_CONTROL Register

	MOV R5, #0x1E00000		@Load word to target GPIO1_21-24
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED1-4 OFF)

	MOV R8, #0x01
	LDMFD SP!, {R0-R3, LR}	@Restore Registers
	SUBS PC, LR, #4			@Pass execution onto wait LOOP

BUTTON_SVC:
	MOV R1, #0x00000008		@Value to turn off GPIO1_3 & INTC Interrupt request
	STR R1, [R0]			@Write to GPIO1_IRQSTATUS_0 Register
@turn off NEWIRQA bit in INTC_CONTROL, so processor can respond to new IRQ
	LDR R0, =0x48200048		@ADDR of INTC_CONTROL Register
	MOV R1, #0x01				@Value to clear bit 0
	STR R1, [R0]			@Write to INTC_CONTROL Register

TST R8, #0x01
BNE CycloneEye
BEQ PASS_ON

CycloneEye:
MOV R8, #0x00

@LED3
LED3ON:						@Turn on LED3 Function
	MOV R5, #0x01000000		@Load word to target GPIO1_24
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)

	@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B LED3OFF				@Branch to L2R_LED3OFF


LED3OFF:					@Turn off LED3 Function
	MOV R5, #0x01000000		@Load word to target GPIO1_24
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B L2R_LED2ON				@Branch to L2R_LED2ON

@LED2
L2R_LED2ON:						@Turn on LED2 Function
	MOV R5, #0x00800000		@Load word to target GPIO1_23
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B L2R_LED2OFF				@Branch to L2R_LED2OFF

L2R_LED2OFF:					@Turn off LED2 Function
	MOV R5, #0x00800000		@Load word to target GPIO1_23
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B L2R_LED1ON				@Branch to L2R_LED1ON

@LED1
L2R_LED1ON:						@Turn on LED1 Function
	MOV R5, #0x00400000		@Load word to target GPIO1_22
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B L2R_LED1OFF				@Branch to L2R_LED1OFF

L2R_LED1OFF:					@Turn off LED1 Function
	MOV R5, #0x00400000		@Load word to target GPIO1_22
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B LED0ON				@Branch to L2R_LED0ON

@LED0
LED0ON:						@Turn on LED0 Function
	MOV R5, #0x00200000		@Load word to target GPIO1_21
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B LED0OFF				@Branch to L2R_LED0OFF

LED0OFF:					@Turn off LED0 Function
	MOV R5, #0x00200000		@Load word to target GPIO1_21
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B R2L_LED1ON				@Branch to R2L_LED1ON

@This is where it reverses direction
@LED1
R2L_LED1ON:						@Turn on LED1 Function
	MOV R5, #0x00400000		@Load word to target GPIO1_22
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B R2L_LED1OFF				@Branch to R2L_LED1OFF

R2L_LED1OFF:					@Turn off LED1 Function
	MOV R5, #0x00400000		@Load word to target GPIO1_22
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B R2L_LED2ON				@Branch to R2L_LED2ON

@LED2
R2L_LED2ON:						@Turn on LED2 Function
	MOV R5, #0x00800000		@Load word to target GPIO1_23
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B R2L_LED2OFF				@Branch to R2L_LED2OFF

R2L_LED2OFF:					@Turn off LED2 Function
	MOV R5, #0x00800000		@Load word to target GPIO1_23
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)

		@Check if new IRQ Request has been submitted
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE PASS_ON

	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B LED3ON				@Branch to R2L_LED3ON

Delay1Sec:					@One Second Delay Loop
	SUBS R7, R7, #1			@Subtract 1 from delay timer value
	BNE Delay1Sec			@Loop until delay timer value is 0
	MOV PC, LR				@Branch back to LEDON/OFF
@END OF CODE FROM PART 1

.data
.align 2
STACK1:	.rept 1024			@Stack1
		.word 0x0000
		.endr

STACK2:	.rept 1024			@Stack2
		.word 0x0000
		.endr
.END



