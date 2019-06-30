/*
* PrakUE4_TGI1_Zahlenschloss.asm
*
*  Created: 6/16/2019 9:25:12 PM
*  Author: Ilija K. & Josi Brauer
*  Version: 8
*/

; Variable Declaration
.def Digit = R20
.def Fail = R19
.def ButtonStates = R18
.def Temp = R23
; Own Variables
.def InputCount = R24
.def LastState = R25
.def Counter = R17
.def Zero = R16

	RCALL INIT_STACK
	RCALL INIT_PORTS


MAIN:
	RCALL INIT_VARS
; LoopCounter
	LDI Counter, 0x04
	CLR InputCount				;Lower Nibble is the one displayed
LOOP:
	RCALL DISPLAY_ATTEMPT_NUM
	RCALL POLL_BUTTONS
	RCALL INPUT_PROOFING
	DEC Counter
	BRNE LOOP
	RCALL CHECK_FAIL
	RCALL WAIT_ENTER
	JMP MAIN

WAIT_KEYPRESS:
	MOV Temp, ButtonStates	;Save prev.
	IN ButtonStates, PORTA
	CPSE Temp, ButtonStates
	JMP WAIT_KEYPRESS
	RET

WAIT_ENTER:
	;MOV Temp, ButtonStates	;Save prev. ;Deprecated prolly 'cuz of Tristate
	IN ButtonStates, PINA

	ANDI ButtonStates, 0b10000000
	;CP Temp, ButtonStates
	BREQ WAIT_ENTER
	RET


WAIT_INCREMENTOR:
	MOV Temp, ButtonStates	;Save prev.
	IN ButtonStates, PORTA

	ANDI ButtonStates, 0b00000001
	CP Temp, ButtonStates
	INC DIGIT
	JMP WAIT_INCREMENTOR

EXIT_INCREMENTOR:
	RET

;  Procedure

POLL_BUTTONS:
	CLR Digit
	OUT PORTD, Digit
	IN ButtonStates, PINA
POLL_LOOP:
	IN Temp, PINA		;Read Raw-Input

	SBRS ButtonStates, 0		; Check for Incrmntr-Input
	RJMP NEXT_IF
	SBRS Temp, 0
	RCALL INCREMENTOR

NEXT_IF:
	SBRS ButtonStates, 7
	RJMP SKIP1
	SBRS Temp, 7
	RET

SKIP1:
	MOV ButtonStates, Temp
	RJMP POLL_LOOP

INCREMENTOR:
	INC Digit

	LDI Temp, 10				;Req. For Modulo Base 10
	CP Digit, Temp
	BRNE SKIP_SUB
	SUBI Digit, 10

	;Implicit Return statement because of end

SKIP_SUB:
	out PortD, Digit
	RET

INIT_PORTS:
	LDI Temp, 0b01111110	;PA7,PA0: IN
	OUT DDRA, Temp
	;OUT PORTA, Temp			;Tristate

	LDI Temp, 0b11111111	;PB0-5: OUT
	OUT DDRB, Temp

	LDI Temp, 0b11111111	;PD0-3: OUT
	OUT DDRD, Temp
	RET

INIT_STACK:
	LDI Temp, high(RAMEND)
	OUT SPH, Temp
	LDI Temp, low(RAMEND)
	OUT SPL, Temp
	RET

INIT_VARS:
	CLR LastState
	CLR Fail
	CLR Temp
	CLR Zero

	LDI ZH, high(CODE<<1)	;No idea what '<<' is for!?
	LDI ZL, low(CODE<<1)
	RET

DISPLAY_ATTEMPT_NUM:
	SEC							; Set Carry
	ROL InputCount				; Successively adds 1s at the end
	OUT PORTB, InputCount
	RET

INPUT_PROOFING:
	LPM Temp, Z+
	CPSE Digit, Temp
	INC Fail
	RET

CHECK_FAIL:
	RCALL GREEN_LIGHT
	CPSE Fail, Zero
	RCALL RED_LIGHT
	RET

RED_LIGHT:
	CBI PORTB, 4
	SBI PORTB, 5
	RET

GREEN_LIGHT:
	SBI PORTB, 4
	RET

; //////////////END///////////////
CODE: .DB 0, 8, 1, 5	;Previously @ DSEG
