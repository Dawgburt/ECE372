.text
.global _start
.global INT_DIRECTOR
_start:
@Set up stacks for supervisor mode and IRQ mode of the processor
		LDR R13,=SVC_STACK			@Point to base of SVC_STACK
		ADD R13,R13,#0x1000			@Point to top of SVC_STACK
		CPS #0x12					@Switch to IRQ mode
		LDR R13,=IRQ_STACK			@Point to base of IRQ_STACK
		ADD R13,R13,#0x1000			@Point to top of IRQ_STACK
		CPS #0x13					@Switch to SVC mode

@Turn on GPIO1 CLK
		MOV R0,#0x02				@Value to enable clock for a GPIO module
		LDR R1,=0x44E000AC			@Address of CM_PER_GPIO1_CLKCTRL register
		STR R0,[R1]					@Write 0x02 to address in R1
		LDR R0,=0x4804C000			@Base Address for GPIO1
		ADD R4,R0,#0x190			@Address offset for GPIO1_CLEARDATAOUT
		MOV R7,#0x01E00000			@Laod Value to turn off LEDs 24-21
		STR R7,[R4]					@Write to GPIO1_CLEARDATAOUT

@Program GPIO1_24-GPIO1_21 as output
		ADD R1,R0,#0x0134			@Add offset for GPIO1_OE address
		LDR R6,[R1] 				@READ current GPIO output enable register
		MOV R7,#0xFE1FFFFF			@Word to enable GPIO1_24-GPIO1_21 as an output
		AND R6,R7,R6				@MODIFY Clear bit 24-21
		STR R6,[R1]					@WRITE to GPIO1 Output Enable register

@Turn on GPIO_1 AUX Functional CLK, Enable debounce on GPIO1_3 and set timing
		LDR R3,=0x44E000AC			@Address of CM_PER_GPIO1_CLKCTRL
		LDR R4,=0x00040002			@Turn on Aux Funct CLK, bit 18 and CLK
		STR R4,[R3]					@write value to register
		ADD R1,R0,#0x0150			@Make GPIO1_DEBOUNCABLE register address
		MOV R2,#0x00000008			@Load value of GPIO1 for bit 3
		STR R2,[R1]					@Enable GPIO1_3 debounce
		ADD R1,R0,#0x154			@GPIO1_DEBOUNCING TIME
		MOV R2,#0xA0				@Number 31 Microseconds debounce intervals-1
		STR R2,[R1]					@Enable GPIO1 debounce for 5ms on all GPIO1 same

@Detect falling edge on GPIO1_3 and enable to assert POINTRPEND1
		ADD R1,R0,#0x14C			@R1=address of GPIO1_FALLINGDETECT
		MOV R2,#0x00000008			@Load value for bit 3
		LDR R3,[R1]					@Read GPIO1_FALLINGDETECT
		ORR R3,R3,R2				@Set bit 3
		STR R3,[R1]					@Write back
		ADD R1,R0,#0x34				@Add offset for GPIO1_IRQSTATUS_SET_0
		STR R2,[R1]					@Enable GPIO1_3 request on POINTERPEND1

@Initialize INTC
		LDR R1,=0x48200000			@Base address for INTC
		MOV R2,#0x02				@Value to reset INTC
		STR R2,[R1,#0x10]			@Write to INTC config register
		MOV R2,#0x20				@Unmask INTC INT 69, Timer3 Interrupt bit 5
		STR R2,[R1,#0xC8]			@Write to INTC_MIR_CLEAR2 register
		MOV R2,#0x04				@Value to unmask INTC INT 98, GPIOINTA
		STR R2,[R1,#0xE8]			@Write to INTC_MIR_CLEAR3 register

@Turn on Timer3 CLK
		MOV R2,#0x2					@Value to enable Timer3 CLK
		LDR R1,=0x44E00084			@Address of CM_PER_TIMER3_CLKCTRL
		STR R2,[R1]					@Turn on
		LDR R1,=0x44E0050C			@Address of CM_DPLL_CLKSEL_TIMER3_CLK register
		STR R2,[R1]					@Select 32 KHz CLK for Timer3

@Initialize Timer3 registers, with count, overflow, interrupt generation
		LDR R1,=0x48042000			@Base address for Timer3 registers
		MOV R2,#0x1					@Value to reset Timer3
		STR R2,[R1,#0x10]			@Write to Timer3 CFG register
		MOV R2,#0x02				@Value to enable overflow interrupt
		STR R2,[R1,#0x2C]			@Write to Timer3 IRQENABLE_SET
		LDR R2,=0xFFFF0000			@Count Value for 2 seconds
		STR R2,[R1, #0x40]			@Timer3 TLDR load register (reload value)
		STR R2,[R1, #0x3C]			@Write to Timer3 TCRR count register


@Turn off new IRQ bit in INTC_CONTROL
		LDR R1,=0x48200048			@Load address of INTC_CONTROL
		MOV R2,#0x01				@Value to clear bit 0
		STR R2,[R1]					@Write to INTC_CONTROL
		LDR R1,=0x48042028			@Load address of Timer3 IRQSTATUS register
		MOV R2,#0x2					@Value to reset Timer3 Overflow IRQ request
		STR R2,[R1]					@Write

@Make sure processor IRQ enabled in CSPR
		MRS R3,CPSR					@Copy CPSR to R3
		BIC R3,#0x80				@Clear bit 7
		MSR CPSR_c, R3				@Write back to CPSR

@Wait for interupt
LOOP:   NOP							@Loop to wait for interrupt
		B LOOP

@INT_DIRECTOR branch
INT_DIRECTOR:
		STMFD SP!,{R0-R4,LR}		@Push registers onto stack
		LDR R0,=0x482000F8			@Address of INTC-PENDING_IRQ3
		LDR R1,[R0]					@Read INTC-PENDING_IRQ3
		TST R1,#0x00000004			@Test bit 2
		BEQ TCHK					@Not from GPIOINT1A, check if Timer3, Else
		LDR R0,=0x4804C02C			@Load Address of GPIO1_IRQSTATUS_0
		LDR R1,[R0]					@Read Status register to see if button press
		TST R1,#0x00000008			@Check if bit 3 = 1
		BNE BUTTON_SVC				@If bit 3 = 1 button is pressed service it
		LDR R0,=0x48200048			@Else, Go back. INTC_CONTROL register
		MOV R1,#01					@Value of clear bit 0
		STR R1,[R0]					@Write to INTC_CONTROL register
		LDMFD SP!,{R0-R4,LR}		@Restore Registers
		SUBS PC,LR,#4				@Pass execution to wait LOOP for now

TCHK:
		LDR R1,=0x482000D8			@Address of INTC_PENDING_IRQ2 register
		LDR R0,[R1]					@Read value
		TST R0,#0x20				@Check if the interrupt from Timer3 bit 5
		BEQ PASS_ON					@No, return,Yes check CHECKFLAG
		LDR R1,=0x48042028			@Address of Timer3 IRQSTATUS register
		LDR R0,[R1]					@Read Value
		TST R0,#0x2					@Check bit 1
		BNE LED						@If overflow, then go toggle LED

PASS_ON:
		MOV R1,#0x02				@Value to turn Timer3 off
		LDR R0,=0x48042028			@Load address of IRQSTATUS Timer3
		STR R1,[R0]					@Write to IRQSTATUS Timer3
		LDR R0,=0x48200048			@Address of INTC_CONTROL register
		MOV R1,#01					@Value to clear bit 0
		STR R1,[R0]					@Write to INTC_CONTROL register
		LDMFD SP!,{R0-R4,LR}		@Restore Registers
		SUBS PC,LR,#4				@Pass execution to wait LOOP for now

@BUTTON_SVC branch for button service interrupt
BUTTON_SVC:
		MOV R1,#0x00000008			@Value turns off GPIO1_3 Interrupt Request
		STR R1,[R0]					@Write to GPIO1_IRQSTATUS_0 register

@Load CHECKFLAG test, invert,  and store bit
		LDR R2,=CHECKFLAG			@Load pointer to CHECKFLAG array
		LDR R3,[R2]					@Load value from CHECKFLAG
		CMP R3,#0x00				@Compare CHECKFLAG value to 0
		BEQ TURN_LED_ON				@Branch if equal to LED_TURN_ON
		CMP R3,#0x00				@Compare CHECKFLAG value to 0
		BNE TURN_LED_OFF			@Branch if not equal to LED_TURN_OFF

TURN_LED_OFF:
		MOV R5,#0x00				@Move value to change CHECKFLAG state
		STR R5,[R2]					@Write to CHECKFLAG
		LDR R2,=0x48042038			@Load address to DMTIMER3_TCLR
		STR R5,[R2]					@Write to DMTIMER3_TCLR to turn timer off
		LDR R2,=BUFFER				@Load pointer to BUFFER array
		LDR R6,=STATE				@Load pointer to STATE array
		LDR R3,[R2]					@Load value from BUFFER array
		STR R3,[R6]					@store BUFFER value into STATE
		LDR R0,=0x4804C190			@Load address of GPIO1_CLEARDATAOUT
		MOV R1,#0x01E00000			@Value to clear bits 24-21
		STR R1,[R0]					@Write to GPIO1_CLEARDATAOUT
		B BACK						@Branch to BACK

TURN_LED_ON:
		MOV R5,#0x01				@Move value to change CHECKFLAG state
		STR R5,[R2]					@Write to CHECKFLAG
		LDR R0,=LEDCYCLE			@Load pointer to LEDCYCLE array
		LDR R1,=STATE				@Load pointer to STATE array
		LDR R2,[R1]					@Load value from STATE array into R2
		LDR R3,[R0,R2]				@Add STATE offset to base address in LEDCYCLE
		LDR R4,=0x4804C194			@Load GPIO1_SETDATAOUT address
		STR R3,[R4]					@Write to GPIO1_SETDATAOUTR register
		MOV R3,#0x3					@Load Value into auto realod and start Timer3
		LDR R4,=0x48042038			@Load address for Timer3 TCLR register38
		STR R3,[R4]					@Write to Timer3 TCLR register

BACK:
		LDR R0,=0x48200048			@Address of INTC_CONTROL register
		MOV R1,#0x01				@Value to enable new IRQ response in INTC
		STR R1,[R0]					@Write
		LDMFD SP!,{R0-R4,LR}		@Restore Registers
		SUBS PC,LR,#4				@Return from IRQ interrupt

LED:
@Turn off Timer3 interrupt request and enable INTC for next IRQ
		LDR R1,=0x48042028			@Load address of Timer3 IRQSTATUS register
		MOV R2,#0x2					@Value to reset Timer3 Overflow IRQ request
		STR R2,[R1]					@Write
		LDR R0,=LEDCYCLE			@Load pointer to LEDCYCLE array
		LDR R1,=BUFFER				@Load pointer to BUFFER array
		LDR R3,[R1]					@Load value in BUFFER array to increment
		LDR R2,=0x4804C190			@Load address of GPIO1_CLEARDATAOUT
		LDR R4,[R0,R3]				@Load value of the sum of R3 and R0
		STR R4,[R2]					@Write to GPIO1_CLEARDATAOUT to turn off LED
		CMP R3,#20					@Compare value of R3 to 20
		MOVEQ R3,#0x00				@If it equals 20 reset value to 0
		ADDMI R3,R3,#04				@If larger than 20 add 4 to the value of R3 to increment
		STR R3,[R1]					@Store increment value back to BUFFER
		LDR R2,=0x4804C194			@Load address of GPIO1_SETDATAOUT
		LDR R4,[R0,R3]				@Load value from the sum of R3 and R0
		STR R4,[R2]					@Write to GPIO1_SETDATAOUT to turn on next LED

@Turn off new IRQ bit in INTC_CONTROL
		LDR R1,=0x48200048			@Load address of INTC_CONTROL
		MOV R2,#0x01				@Value to clear bit 0
		STR R2,[R1]					@Write to INTC_CONTROL
		LDMFD SP!,{R0-R4,LR}		@Restore Registers
		SUBS PC,LR,#4				@Pass execution to wait LOOP for now



.data
.align 2
@Set up arrays for holder values and cycle values
LEDCYCLE: .word 0x01000000, 0x00800000, 0x00400000, 0x00200000, 0x00400000, 0x00800000
CHECKFLAG: .word 0x0
BUFFER: .word 0x0
STATE: .word 0x0
@Set up stacks for supervisor mode and IRQ mode of the processor
SVC_STACK:
	.rept 1024
	.word 0x0000
	.endr
IRQ_STACK:
	.rept 1024
	.word 0x0000
	.endr
.END
