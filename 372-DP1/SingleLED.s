@Phil Nevins
@ECE 371 Microprocessor I
@Design Project 2, Part 1, Single LED
@This program will turn USR3 LED (GPIO1_24) on for one second and off for one second
@This pattern will be repeated forever
@Program uses R0-2, R5-7 and R9-10

.text
.global _start
_start:

@Initiliaze CLK
MOV R9, #0x02				@Value to enable CLKs for GPIO modules
LDR R10, =0x44E000AC		@Addr of CM_PER_GPIO1_CLKCTRL Register
STR R9, [R10]				@Write 0x02 to CLKCTRL Register

@Program GPIO1_24 as output
LDR R0, =0xFEFFFFFF			@Load word to program GPIO1_24 to output
LDR R1, =0x4804C134			@Addr of GPIO1_OE Register
LDR R2, [R1]				@Read GPIO1_OE Register
AND R2, R2, R0				@Modify word read in with R0
STR R2, [R1]				@Write back to GPIO1_OE Register

LED3ON:						@Turn on LED3 Function
	MOV R5, #0x01000000		@Load word to target GPIO1_24
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B LED3OFF				@Branch to LED3OFF

LED3OFF:					@Turn off LED3 Function
	MOV R5, #0x01000000		@Load word to target GPIO1_24
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B LED3ON				@Branch to LED3ON

Delay1Sec:					@One Second Delay Loop
	SUBS R7, R7, #1			@Subtract 1 from delay timer value
	BNE Delay1Sec			@Loop until delay timer value is 0
	MOV PC, LR				@Branch back to LEDON/OFF

.end
