	AREA	AsmTemplate, CODE, READONLY
	IMPORT	main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011.

	EXPORT	start
start
	mov r0, #0xc0000000
	mov r1, #0xf0000000
	subs r3,r1,r0

stop	B	stop

	END
