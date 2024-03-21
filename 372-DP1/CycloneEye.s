@Phil Nevins
@ECE 371 Microprocessor I
@Design Project 2, Part 1, Cyclone Eye
@LED 0 turns on, then LED1, then LED2, then LED3, then LED2, then LED1,
@then it repeats. Each LED stays on for 1 second using a delay timing loop
@Program uses R0-2, R5-7 and R9-10

.text
.global _start
_start:

@Initiliaze CLK
MOV R9, #0x02				@Value to enable CLKs for GPIO modules
LDR R10, =0x44E000AC		@Addr of CM_PER_GPIO1_CLKCTRL Register
STR R9, [R10]				@Write 0x02 to CLKCTRL Register

@Program GPIO1_21-24 as output
LDR R0, =0xFE1FFFFF			@Load word to program GPIO1_21-24 to output
LDR R1, =0x4804C134			@Addr of GPIO1_OE Register
LDR R2, [R1]				@Read GPIO1_OE Register
AND R2, R2, R0				@Modify word read in with R0
STR R2, [R1]				@Write back to GPIO1_OE Register

@LED3
LED3ON:						@Turn on LED3 Function
	MOV R5, #0x01000000		@Load word to target GPIO1_24
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B LED3OFF				@Branch to L2R_LED3OFF

LED3OFF:					@Turn off LED3 Function
	MOV R5, #0x01000000		@Load word to target GPIO1_24
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B L2R_LED2ON				@Branch to L2R_LED2ON

@LED2
L2R_LED2ON:						@Turn on LED2 Function
	MOV R5, #0x00800000		@Load word to target GPIO1_23
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B L2R_LED2OFF				@Branch to L2R_LED2OFF

L2R_LED2OFF:					@Turn off LED2 Function
	MOV R5, #0x00800000		@Load word to target GPIO1_23
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B L2R_LED1ON				@Branch to L2R_LED1ON

@LED1
L2R_LED1ON:						@Turn on LED1 Function
	MOV R5, #0x00400000		@Load word to target GPIO1_22
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B L2R_LED1OFF				@Branch to L2R_LED1OFF

L2R_LED1OFF:					@Turn off LED1 Function
	MOV R5, #0x00400000		@Load word to target GPIO1_22
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B LED0ON				@Branch to L2R_LED0ON

@LED0
LED0ON:						@Turn on LED0 Function
	MOV R5, #0x00200000		@Load word to target GPIO1_21
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B LED0OFF				@Branch to L2R_LED0OFF

LED0OFF:					@Turn off LED0 Function
	MOV R5, #0x00200000		@Load word to target GPIO1_21
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B R2L_LED1ON				@Branch to R2L_LED1ON

@This is where it reverses direction
@LED1
R2L_LED1ON:						@Turn on LED1 Function
	MOV R5, #0x00400000		@Load word to target GPIO1_22
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B R2L_LED1OFF				@Branch to R2L_LED1OFF

R2L_LED1OFF:					@Turn off LED1 Function
	MOV R5, #0x00400000		@Load word to target GPIO1_22
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B R2L_LED2ON				@Branch to R2L_LED2ON

@LED2
R2L_LED2ON:						@Turn on LED2 Function
	MOV R5, #0x00800000		@Load word to target GPIO1_23
	LDR R6, =0x4804C194		@Load addr of GPIO1_SETDATAOUT
	STR R5, [R6]			@Write to GPIO1_SETDATAOUT (This turns LED ON)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B R2L_LED2OFF				@Branch to R2L_LED2OFF

R2L_LED2OFF:					@Turn off LED2 Function
	MOV R5, #0x00800000		@Load word to target GPIO1_23
	LDR R6, =0x4804C190		@Load addr of GPIO1_CLEARDATAOUT
	STR R5, [R6]			@Write to GPIO1_CLEARDATAOUT (This turns LED OFF)
	LDR R7, =0x00333333		@Load Delay Timer value (one second)
	BL Delay1Sec			@Branch to delay timer function
	B LED3ON				@Branch to R2L_LED3ON


Delay1Sec:					@One Second Delay Loop
	SUBS R7, R7, #1			@Subtract 1 from delay timer value
	BNE Delay1Sec			@Loop until delay timer value is 0
	MOV PC, LR				@Branch back to LEDON/OFF

.end
