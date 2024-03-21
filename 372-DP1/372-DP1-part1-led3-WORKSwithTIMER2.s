@Phil Nevins
@ECE 371 Microprocessor
@Design Project 2, Part 2 Single LED
@This program will use a pushbutton to trigger an interrupt and cycle an LED
@The program will do this exactly: push button, LED3 cycle on, push button,
@LED3 cycle off, push button, LED3 cycle on...
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
LDR R1, =0x48200000		@Base Addr for INTC
MOV R2, #0x2			@Value to reset INTC
STR R2, [R1,#0x10]		@Write to INTC Config Register
MOV R2, #0x10			@Unmask INTC INT 68, Timer2 interrupt
STR R2, [R1, #0xC8]		@Write to INTC_MIR_CLEAR_2 register
MOV R2, #0x04			@Value to unmask INTC INT 98, GPIONT1A
STR R2, [R1, #0xE8]		@Write to INTC_MIR_CLEAR3 Register

@Turn on Timer2 CLK
MOV R2, #0x2			@Value to enable Timer2 CLK
LDR R1, =0x44E00080		@Addr of CM_PER_TIMER2_CLKCTRL
STR R2, [R1]			@Turn on
LDR R1, =0x44E00508		@Addr of PRCMCLKSEL_TIMER2 Register
STR R2, [R1]			@Select 32 KHz CLK for Timer2

@Initiliaze Timer2 Registers, with count, overflow, interrupt generation
LDR R1, =0x48040000		@Base addr for timer2 registers
MOV R2, #0x1			@Value to reset timer 2
STR R2, [R1, #0x10]		@Write to Timer2 CFG register
MOV R2, #0x2			@Value to enable overflow interrupt
STR R2, [R1, #0x2C]		@Write to timer2 IRQENABLE_SET
LDR R2, =0xFFFF0000		@Count value for 2 seconds
STR R2, [R1, #0x40]		@Timer2 TLDR load register (Reload value)
STR R2, [R1, #0x3C]		@Write to Timer2 TCRR count register

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
	LDR R1, =0x482000F8		@ADDR of INTC_PENDING_IRQ3 Register
	LDR R2, [R1]			@Read INTC_PENDING_IRQ3 Register
	TST R2, #0x00000004		@Test Bit 2
	BEQ TCHK				@Not from GPIOINT1A, go to wait loop, Else
	LDR R0, =0x4804C02C		@Load GPIO1_IRQSTATUS_0 Register ADDR
	LDR R1, [R0]			@Read STATUS Register
	TST R1, #0x00000008		@Test if bit 3 = 1
	BNE BUTTON_SVC			@If 1, go to button_svc
	LDR R0, =0x48200048		@Else, go back. INTC_CONTROL Register
	MOV R1, #0x1			@Value to clear bit 0
	STR R1, [R0]			@Write to INTC_CONTROL Register
	LDMFD SP!, {R0-R3, LR}	@Restore Registers
	SUBS PC, LR, #4			@Pass execution to wait loop for now

TCHK:
	LDR R1, =0x482000D8		@Addr of INTC_PENDING_IRQ2 Register
	LDR R0, [R1]			@Read value
	TST R0, #0x10			@Check if interrupt from timer2
	BEQ PASS_ON				@No, return. Yes, check for overflow
	LDR R1, =0x48040028		@Addr of Timer2 IRQStatus Register
	LDR R0, [R1]			@Read value
	TST R0, #0x02			@Check bit 1
	BNE LED3ON		@If overflow, go to LED3Function

PASS_ON:					@Else go back to wait loop
	MOV R1, #0x00000008		@Value to turn off GPIO1_3 & INTC Interrupt request
	STR R1, [R0]			@Write to GPIO1_IRQSTATUS_0 Register

@turn off NEWIRQA bit in INTC_CONTROL, so processor can respond to new IRQ
	LDR R0, =0x48200048		@ADDR of INTC_CONTROL Register
	MOV R1, #0x01				@Value to clear bit 0
	STR R1, [R0]			@Write to INTC_CONTROL Register

	MOV R5, #0x1E00000		@Load word to target GPIO1_21-24
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED1-4 OFF)

	LDMFD SP!, {R0-R3, LR}	@Restore Registers
	SUBS PC, LR, #4			@Pass execution onto wait LOOP

BUTTON_SVC:
	MOV R1, #0x00000008		@Value to turn off GPIO1_3 & INTC Interrupt request
	STR R1, [R0]			@Write to GPIO1_IRQSTATUS_0 Register

@Turn on LED on GPIO_24
	LDR R0, =0x4804C194		@Load addr of GPIO1_SETDATAOUT Register
	MOV R1, #0x01000000		@Load value to turn on GPIO1_24
	STR R1, [R0]			@Write to GPIO1_SETDATAOUT Register
	MOV R2, #0x03			@Load value to auto reload timer and start
	LDR R1, =0x48040038		@Addr of Timer2 TCLR Register
	STR R2, [R1]			@Write to TCLR Register

@turn off NEWIRQA bit in INTC_CONTROL, so processor can respond to new IRQ
	LDR R0, =0x48200048		@ADDR of INTC_CONTROL Register
	MOV R1, #01				@Value to clear bit 0
	STR R1, [R0]			@Write to INTC_CONTROL Register
	LDMFD SP!, {R0-R3, LR}	@Restore Registers
	SUBS PC, LR, #4			@Pass execution to wait loop for now

@LED3
LED3ON:
@turn off timer 2 interrupt request and enable INT for next IRQ
	LDR R1, =0x48040028		@Load addr of Timer2 IRQSTATUS register**
	MOV R2, #0x02			@Value to reset Timer2 overflow IRQ request
	STR R2, [R1]			@Write
	LDR R1, =0x4804C000		@Base addr for GPIO1
	LDR R2, [R1, #0x013C]	@Read value from GPIO1_DATAOUT
	TST R2, #0x01000000		@Test if bit 24 = 1
	MOV R2, #0x01000000		@value to set or clear bit 24
	BNE LED3OFF				@LED on, go turn off
	STR R2, [R1, #0x194]	@LED OFF, turn on with GPIO1_SETDATAOUT
	B BACK					@Back to wait loop

LED3OFF:
	STR R2, [R1, #0x190]	@Turn LED off with GPIO1_CLEARDATAOUT

BACK:
	LDR R1, =0x48200048		@Addr of INTC_CONTROL Register
	MOV R2, #0x01			@Value to enable new IRQ response in INTC
	STR R2, [R1]			@Write
	LDMFD SP!, {R0 - R3, LR}	@Restore Registers
	SUBS PC, LR, #4			@Return from IRQ interrupt procedure



.data
.align 2
STACK1:	.rept 1024			@Stack1
		.word 0x0000
		.endr

STACK2:	.rept 1024			@Stack2
		.word 0x0000
		.endr
.END



