/*
* PrakUE4_TGI1_Zahlenschloss.asm
*
*  Created: 6/16/2019 9:25:12 PM
*  Author: Ilija K. & Josi Brauer
*  Version: 6
*/ 

; Variable Declaration
.def Digit = R20
.def Fail = R19
.def ButtonStates = R18
.def Temp = R23
; Own Variables
.def InputCount = R24
.def LastState = R25
.DSEG
.ORG $0100
; Deprecated CODE

.CSEG
;.ORG $0000

;TODO: USE TRI-STATE PORTX ADDITIONALLY TO DDRX!!!
; Init. of PortA,B,D 
LDI Temp, 0b01111110	;PA7,PA0: IN
OUT DDRA, Temp
;OUT PORTA, Temp			;Tristate

LDI Temp, 0b11111111	;PB0-5: OUT
OUT DDRB, Temp		

LDI Temp, 0b11111111	;PD0-3: OUT
OUT DDRD, Temp

; Init. of Stackpointer
LDI Temp, high(RAMEND)
OUT SPH, Temp
LDI Temp, low(RAMEND)
OUT SPL, Temp

; Init States
CLR LastState

; Main Loop
MAIN:
	CLR Fail
	CLR Temp
	
	LDI ZH, high(CODE<<1)	;No idea what '<<' is for!?
	LDI ZL, low(CODE<<1)
	;4x

;(NEXT_DIGIT0)
	LDI InputCount, 0x01
	OUT PORTB, InputCount	
	CALL POLL_BUTTONS
	;Compr
	LPM Temp, Z+
	;CP Digit, Temp ;Deprecated
	CPSE Digit, Temp
	INC Fail

;NEXT_DIGIT1:
	LDI InputCount, 0b00000011
	OUT PORTB, InputCount
	CALL POLL_BUTTONS
	;Compr
	LPM Temp, Z+ ;Temp should be "CodeDigit"
	;CP Digit, Temp ;Deprecated
	CPSE Digit, Temp
	INC Fail

;NEXT_DIGIT2:
	LDI InputCount, 0b00000111
	OUT PORTB, InputCount
	CALL POLL_BUTTONS
	;Compr
	LPM Temp, Z+
	;CP Digit, Temp ; Depr.
	CPSE Digit, Temp
	INC Fail

;NEXT_DIGIT3:
	LDI InputCount, 0b00001111
	OUT PORTB, InputCount
	CALL POLL_BUTTONS
	;Compr
	LPM Temp, Z+
	;CP Digit, Temp ;Deprecated
	CPSE Digit, Temp
	INC Fail
	

;CHECK_FAIL:
	TST Fail			;Activates Z- or N-Flag
	BREQ GREEN_LIGHT			;Reacts to Z-Flag
	LDI Temp, 0b00101111
	OUT PORTB, Temp		;Redlight
	JMP NEXT

GREEN_LIGHT:
	LDI Temp, 0b00011111
	OUT PORTB, Temp; DDRB 

NEXT:
	CALL WAIT_ENTER
	JMP MAIN

WAIT_KEYPRESS:
	MOV Temp, ButtonStates	;Save prev.
	IN ButtonStates, PORTA
	CP Temp, ButtonStates 
	BRCS EXIT_KEYPRESS
	JMP WAIT_KEYPRESS

EXIT_KEYPRESS:
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
				
; //////////////END///////////////
CODE: .DB 0, 8, 1, 5	;Previously @ DSEG


