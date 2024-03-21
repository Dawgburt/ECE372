@Phil Nevins
@ECE 371 Microprocessor
@Design Project 2, Part 2
@This program will use a pushbutton to trigger an interrupt and cycle an LED
@The program will do this exactly: push button, LED Cyclone on, push button,
@LED cyclone off, push button, LED cyclone on...The cyclone will start
@where it was interrupted at
@Program uses R0-R5

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
MOV R2, #0x20			@Unmask INTC INT 69, Timer3 interrupt
STR R2, [R1, #0xC8]		@Write to INTC_MIR_CLEAR_2 register
MOV R2, #0x04			@Value to unmask INTC INT 98, GPIONT1A
STR R2, [R1, #0xE8]		@Write to INTC_MIR_CLEAR3 Register

@Turn on Timer3 CLK
MOV R2, #0x2			@Value to enable Timer3 CLK
LDR R1, =0x44E00084		@Addr of CM_PER_TIMER3_CLKCTRL
STR R2, [R1]			@Turn on
LDR R1, =0x44E0050C		@Addr of CLKSEL_TIMER3_CLK Register**
STR R2, [R1]			@Select 32 KHz CLK for Timer3

@Initiliaze Timer3 Registers, with count, overflow, interrupt generation
LDR R1, =0x48042000		@Base addr for timer3 registers
MOV R2, #0x1			@Value to reset timer3
STR R2, [R1, #0x10]		@Write to Timer3 CFG register
MOV R2, #0x2			@Value to enable overflow interrupt
STR R2, [R1, #0x2C]		@Write to timer3 IRQENABLE_SET
LDR R2, =0xFFFF0000		@Count value for 2 seconds
STR R2, [R1, #0x40]		@Timer3 TLDR load register (Reload value)
STR R2, [R1, #0x3C]		@Write to Timer3 TCRR count register

@Turn on GPIO_1 AUX Functional CLK, Enable DEBOUNCE on GPIO1_3 and Set Time
LDR R0,	=0x4804C000			@Base addr for GPIO1
LDR R1,	=0x44E000AC			@Addr of CM_PER_GPIO1_CLKCTRL
LDR R2,	=0x00040002			@Value to turn on Aux Funct CLK, bit 18 and CLK
STR R2,	[R1]				@Write value to CMP_PER_GPIO_CLKCTRL
ADD R1,	R0,	#0x0150			@Addr of GPIO1_DEBOUNCABLE
MOV R2,	#0x00000008			@Load value of GPIO1 for bit 3
STR R2,	[R1]				@Enable GPIO1_3 debounce
ADD R1,	R0,	#0x154			@Addr of GPIO1_DEBOUNCING TIME
MOV R2,	#0xA0				@Value for 31 Micro-Seconds debounce interval
STR R2,	[R1]				@Write to GPIO1_DEBOUNCING TIME

@Program GPIO1_21-24 as output
LDR R0, =0xFE1FFFFF			@Load word to program GPIO1_21-24 to output
LDR R1, =0x4804C134			@Addr of GPIO1_OE Register
LDR R2, [R1]				@Read GPIO1_OE Register
AND R2, R2, R0				@Modify word read in with R0
STR R2, [R1]				@Write back to GPIO1_OE Register

@Make sure processor IRQ enabled in CPSR
MRS R3, CPSR			@Copy CPSR to R3
BIC R3, #0x80			@Clear bit 7
MSR CPSR_c, R3			@Write back to CPSR

@Turn all LEDs off
MOV R0, #0x1E00000		@Load word to target GPIO1_21-24
LDR R1, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
STR R0, [R1]			@Write to GPIO1_CLEARDATAOUT (This turns LED1-4 OFF)

@Wait for interrupt
WaitLoop: NOP
		B WaitLoop

INT_DIRECTOR:
		STMFD SP!,{R0-R4,LR}		@Push registers onto stack
		LDR R0,=0x482000F8			@Addr of INTC-PENDING_IRQ3
		LDR R1,[R0]					@Read INTC-PENDING_IRQ3
		TST R1,#0x00000004			@Test bit 2
		BEQ TCHK					@Not from GPIOINT1A, check if Timer3, Else
		LDR R0,=0x4804C02C			@Load addr of GPIO1_IRQSTATUS_0
		LDR R1,[R0]					@Read Status register to see if button press
		TST R1,#0x00000008			@Check if bit 3 = 1
		BNE BUTTON_SVC				@If bit 3 = 1 button is pressed service it
		LDR R0,=0x48200048			@Else, Go back. INTC_CONTROL register
		MOV R1,#01					@Value of clear bit 0
		STR R1,[R0]					@Write to INTC_CONTROL register
		LDMFD SP!,{R0-R4,LR}		@Restore Registers
		SUBS PC,LR,#4				@Pass execution to wait LOOP for now

TCHK:
		LDR R1,=0x482000D8			@Addr of INTC_PENDING_IRQ2 register
		LDR R0,[R1]					@Read value
		TST R0,#0x20				@Check if the interrupt from Timer3 (bit 5)
		BEQ PASS_ON					@No return, Yes check overflow
		LDR R1,=0x48042028			@Addr of Timer3 IRQSTATUS register
		LDR R0,[R1]					@Read Value
		TST R0,#0x2					@Check bit 1
		BNE LEDFunction				@If overflow, go LEDFunction

PASS_ON:
		MOV R1,#0x02				@Value to turn Timer3 off
		LDR R0,=0x48042028			@Load addr of IRQSTATUS Timer3
		STR R1,[R0]					@Write to IRQSTATUS Timer3

@turn off NEWIRQA bit in INTC_CONTROL, so processor can respond to new IRQ
		LDR R0,=0x48200048			@Addr of INTC_CONTROL register
		MOV R1,#01					@Value to clear bit 0
		STR R1,[R0]					@Write to INTC_CONTROL register

		LDMFD SP!,{R0-R4,LR}		@Restore Registers
		SUBS PC,LR,#4				@Pass execution to wait LOOP for now

BUTTON_SVC:
		MOV R1,#0x00000008			@Value turns off GPIO1_3 Interrupt Request
		STR R1,[R0]					@Write to GPIO1_IRQSTATUS_0 register
		LDR R2,=LED_Flag			@Load pointer to LED_Flag
		LDR R3,[R2]					@Load value from LED_Flag
		CMP R3,#0x00				@Compare LED_Flag value to 0
		BEQ LEDFunction_ON			@Branch if equal go to LEDFunction_ON
		BNE LEDFunction_OFF			@Branch if not equal go to LEDFunction_OFF

LEDFunction_OFF:
		MOV R4,#0x00				@Value to change LED_Flag state & Turn off Timer3
		STR R4,[R2]					@Write to LED_Flag
		LDR R2,=0x48042038			@Load addr to DMTIMER3_TCLR
		STR R4,[R2]					@Write to DMTIMER3_TCLR to turn timer3 off
		LDR R2,=BUFFER				@Load pointer to BUFFER
		LDR R5,=Current_State		@Load pointer to Current_State
		LDR R3,[R2]					@Load value from BUFFER
		STR R3,[R5]					@Store BUFFER value into Current_State
		LDR R0,=0x4804C190			@Load addr of GPIO1_CLEARDATAOUT
		MOV R1,#0x01E00000			@Value to clear bits 24-21
		STR R1,[R0]					@Write to GPIO1_CLEARDATAOUT
		B BACK						@Branch to BACK

LEDFunction_ON:
		MOV R4,#0x01				@Value to change LED_Flag state
		STR R4,[R2]					@Write to LED_Flag
		LDR R0,=USRLEDCYCLE			@Load pointer to USRLEDCYCLE
		LDR R1,=Current_State		@Load pointer to Current_State
		LDR R2,[R1]					@Load value from Current_State into R2
		LDR R3,[R0,R2]				@Add Current_State offset to base addr in USRLEDCYCLE
		LDR R4,=0x4804C194			@Load GPIO1_SETDATAOUT addr
		STR R3,[R4]					@Write to GPIO1_SETDATAOUTR register
		MOV R3,#0x3					@Load Value into auto realod and start Timer3
		LDR R4,=0x48042038			@Load addr for Timer3 TCLR register
		STR R3,[R4]					@Write to Timer3 TCLR register

BACK:
		LDR R0,=0x48200048			@Addr of INTC_CONTROL register
		MOV R1,#0x01				@Value to enable new IRQ response in INTC
		STR R1,[R0]					@Write
		LDMFD SP!,{R0-R4,LR}		@Restore Registers
		SUBS PC,LR,#4				@Return from IRQ interrupt

LEDFunction:
		LDR R1,=0x48042028			@Load addr of Timer3 IRQSTATUS register
		MOV R2,#0x2					@Value to reset Timer3 Overflow IRQ request
		STR R2,[R1]					@Write
		LDR R0,=USRLEDCYCLE			@Load pointer to USRLEDCYCLE
		LDR R1,=BUFFER				@Load pointer to BUFFER
		LDR R3,[R1]					@Load value in BUFFER to increment
		LDR R2,=0x4804C190			@Load addr of GPIO1_CLEARDATAOUT
		LDR R4,[R0,R3]				@Load value of the sum of R3 and R0
		STR R4,[R2]					@Write to GPIO1_CLEARDATAOUT to turn off LED
		CMP R3,#20					@Compare value of R3 to 20
		MOVEQ R3,#0x00				@If R3 = #20 reset value to 0
		ADDMI R3,R3,#04				@If R3 > #20, increment R3 by #04
		STR R3,[R1]					@Store in BUFFER
		LDR R2,=0x4804C194			@Load addr of GPIO1_SETDATAOUT
		LDR R4,[R0,R3]				@Load R4 with R3 + R0
		STR R4,[R2]					@Write to GPIO1_SETDATAOUT to turn on next LED

		LDR R0,=0x48200048			@Addr of INTC_CONTROL register
		MOV R1,#01					@Value to clear bit 0
		STR R1,[R0]					@Write to INTC_CONTROL register

		LDMFD SP!,{R0-R4,LR}		@Restore Registers
		SUBS PC,LR,#4				@Pass execution to wait LOOP for now

.data
.align 2

USRLEDCYCLE: 	.word 0x01000000, 0x00800000, 0x00400000, 0x00200000, 0x00400000, 0x00800000
Current_State:  .word 0x0
BUFFER: 		.word 0x0
LED_Flag: 			.word 0x0



STACK1:
	.rept 1024
	.word 0x0000
	.endr

STACK2:
	.rept 1024
	.word 0x0000
	.endr

.END
