; Definitions  -- references to 'UM' are to the User Manual.

; Timer Stuff -- UM, Table 173

T0	equ	0xE0004000		; Timer 0 Base Address
T1	equ	0xE0008000

IR	equ	0			; Add this to a timer's base address to get actual register address
TCR	equ	4
MCR	equ	0x14
MR0	equ	0x18
Mode_USR equ 0x10
Mode_IRQ equ 0x12
Mode_SYS equ 0x1F

TimerCommandReset	equ	2
TimerCommandRun	equ	1
TimerModeResetAndInterrupt	equ	3
TimerResetTimer0Interrupt	equ	1
TimerResetAllInterrupts	equ	0xFF

; VIC Stuff -- UM, Table 41
VIC	equ	0xFFFFF000		; VIC Base Address
IntEnable	equ	0x10
VectAddr	equ	0x30
VectAddr0	equ	0x100
VectCtrl0	equ	0x200

Timer0ChannelNumber	equ	4	; UM, Table 63
Timer0Mask	equ	1<<Timer0ChannelNumber	; UM, Table 63
IRQslot_en	equ	5		; UM, Table 58

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
IO1PIN	EQU	0xE0028010

	AREA	InitialisationAndMain, CODE, READONLY
	IMPORT	main

; (c) Mike Brady, 2014â€“2016.

	EXPORT	start
start
	
; Initialise the VIC
	ldr	r0,=VIC			; looking at you, VIC!

	ldr	r1,=irqhan
	str	r1,[r0,#VectAddr0] 	; associate our interrupt handler with Vectored Interrupt 0

	mov	r1,#Timer0ChannelNumber+(1<<IRQslot_en)
	str	r1,[r0,#VectCtrl0] 	; make Timer 0 interrupts the source of Vectored Interrupt 0

	mov	r1,#Timer0Mask
	str	r1,[r0,#IntEnable]	; enable Timer 0 interrupts to be recognised by the VIC

	mov	r1,#0
	str	r1,[r0,#VectAddr]   	; remove any pending interrupt (may not be needed)

; Initialise Timer 0
	ldr	r0,=T0			; looking at you, Timer 0!

	mov	r1,#TimerCommandReset
	str	r1,[r0,#TCR]

	mov	r1,#TimerResetAllInterrupts
	str	r1,[r0,#IR]

	ldr	r1,=(14745600/200)-1	 ; 5 ms = 1/200 second (14745600/200)-1
	str	r1,[r0,#MR0]

	mov	r1,#TimerModeResetAndInterrupt
	str	r1,[r0,#MCR]

	mov	r1,#TimerCommandRun
	str	r1,[r0,#TCR]

;from here, initialisation is finished, so it should be the main body of the main program
;init 
;------------------------------------------
;init thread0 with a stack and 
;in the lr store the start of the thread
	ldr r0,=TZERO
	add r0,r0,#52
	mov r1,#Mode_USR
	str r1,[r0]

	;set as usermode
	add r0,r0,#4
	ldr r1,=SPZERO
	add r1,r1,#256
	str r1,[r0]

	add r0,r0,#4
	ldr r1,=Thread0
	str r1,[r0]


;init thread1 with a stack and 
;in the lr store the start of the thread
	ldr r0,=TONE
	add r0,r0,#52
	mov r1,#Mode_USR
	str r1,[r0]
	
	;set as usermode
	add r0,r0,#4
	ldr r1,=SPONE
	add r1,r1,#256
	str r1,[r0]
	
	add r0,r0,#4
	ldr r1,=Thread1
	str r1,[r0]
	
	mov r0,#1
	mov r1,#2
	mov r2,#3
	mov r3,#4
	mov r4,#5
	mov r5,#6
	mov r6,#7
	mov r7,#8
	mov r8,#9
	mov r9,#10
	mov r10,#11
	mov r11,#12
	mov r12,#13


bloop	B	bloop

  		
;main program execution will never drop below the statement above.

	AREA	InterruptStuff, CODE, READONLY
irqhan	sub	lr,lr,#4
	ldr sp,=IRQSP
	add sp,sp,#256
	stmfd	sp!,{r0-r1,lr}	; the lr will be restored to the pc
;counter---------------------
	;LDR r0,=COUNTER
	;ldr r1,[r0]
	;add r1,r1,#5
    ;str r1, [r0]  
;----------------------------
here
;-----SKIP FIRST STASH---------
	ldr r0,=STARTFLAG
	ldr r1,[r0]
	cmp r1,#0x0
	add r1,r1,#1
	str r1,[r0]
	beq firstStart
;------------------------------
;-------STASH------------------
;choose which thread
	ldr r0,=FLAG
	ldr r1,[r0]
	cmp r1,#0x0
	add r1,r1,#1
	str r1,[r0]
	beq STASH0
	b STASH1
		
STASH0
	;load r0 to r0 in tzero
	ldr r0,=TZERO
	pop {r1}
	str r1,[r0]
	pop {r1}
	add r0,r0,#4
	str r1,[r0]
	stmfa r0!,{r2-r12}
	add r0,r0,#4
	mrs r1,spsr
	str r1,[r0]
	
	;go to sys mode and save what where the stack was
	msr cpsr_c,#Mode_SYS
	add r0,r0,#4
	str sp,[r0]
	msr cpsr_c,#Mode_IRQ
	;return to irq mode
	;store the lr in memory
	pop {r1}
	add r0,r0,#4
	str r1,[r0]
	b dispach
STASH1
;reset the counter
	;load r0 to r0 in tzero
	ldr r0,=FLAG
	mov r1,#0x0
	str r1,[r0]

	ldr r0,=TONE
	pop {r1}
	str r1,[r0]
	pop {r1}
	add r0,r0,#4
	str r1,[r0]
	stmfa r0!,{r2-r12}
	add r0,r0,#4
	mrs r1,spsr
	str r1,[r0]
	
	;go to sys mode and save what where the stack was
	msr cpsr_c,#Mode_SYS
	add r0,r0,#4
	str sp,[r0]
	msr cpsr_c,#Mode_IRQ
	;return to irq mode
	;store the lr in memory
	pop {r1}
	add r0,r0,#4
	str r1,[r0]
	b dispach
;------------------------------
firstStart
	pop {r0}
	pop {r0}
	pop {r0}
dispach
	;b here
;this is where we stop the timer from making the interrupt request to the VIC
;i.e. we 'acknowledge' the interrupt
	ldr	r0,=T0
	mov	r1,#TimerResetTimer0Interrupt
	str	r1,[r0,#IR]	   	; remove MR0 interrupt request from timer

;here we stop the VIC from making the interrupt request to the CPU:
	ldr	r0,=VIC
	mov	r1,#0
	str	r1,[r0,#VectAddr]	; reset VIC
;---------DISPACH-----------------
;choose which thread
	ldr r0,=FLAG
	ldr r1,[r0]
	cmp r1,#0x0

	beq DISPACH0
	b DISPACH1
	
DISPACH0
	;go to user mode
	ldr r0,=TZERO
	add r0,r0,#52
	ldr r1,[r0]
	msr cpsr_cxsf,r1
	add r0,r0,#4
	ldr sp,[r0]
	add r0,r0,#4
	ldr lr,[r0]
	ldr r0,=TZERO
	add r0,r0,#4
	ldmfd r0!,{r1-r12}
	ldr r0,=TZERO
	ldr r0,[r0]
	bx lr

DISPACH1

	ldr r0,=TONE
	add r0,r0,#52
	ldr r1,[r0]
	msr cpsr_cxsf,r1
	add r0,r0,#4
	ldr sp,[r0]
	add r0,r0,#4
	ldr lr,[r0]
	ldr r0,=TONE
	add r0,r0,#4
	ldmfd r0!,{r1-r12}
	ldr r0,=TONE
	ldr r0,[r0]
	bx lr
	
	AREA	Subroutines, CODE, READONLY

;------------------------------------------------------------
Thread0
;init 
	ldr	r1,=IO1DIR
	ldr	r2,=0x000f0000	;select P1.19--P1.16
	str	r2,[r1]		;make them outputs
	ldr	r1,=IO1SET
	str	r2,[r1]		;set them to turn the LEDs off
	ldr	r2,=IO1CLR
; r1 points to the SET register
; r2 points to the CLEAR register

	ldr	r5,=0x00100000	; end when the mask reaches this value
wloop	ldr	r3,=0x00040000	; start with P1.16.
floop	str	r3,[r2]	   	; clear the bit -> turn on the LED

;delay for about a half second
	ldr	r4,=2000000
dloop	subs	r4,r4,#1
	bne	dloop

	str	r3,[r1]		;set the bit -> turn off the LED
	mov	r3,r3,lsl #1	;shift up to next bit. P1.16 -> P1.17 etc.
	cmp	r3,r5
	bne	floop
	b	wloop
;------------------------------------------------------------
Thread1
	ldr	r1,=IO1DIR
	ldr	r2,=0x000f0000	;select P1.19--P1.16
	str	r2,[r1]		;make them outputs
	ldr	r1,=IO1SET
	str	r2,[r1]		;set them to turn the LEDs off
	ldr	r2,=IO1CLR
; r1 points to the SET register
; r2 points to the CLEAR register

	ldr	r5,=0x00040000	; end when the mask reaches this value
xloop	ldr	r3,=0x00010000	; start with P1.16.
cloop	str	r3,[r2]	   	; clear the bit -> turn on the LED

;delay for about a half second
	ldr	r4,=2000000
vloop	subs	r4,r4,#1
	bne	vloop

	str	r3,[r1]		;set the bit -> turn off the LED
	mov	r3,r3,lsl #1	;shift up to next bit. P1.16 -> P1.17 etc.
	cmp	r3,r5
	bne	cloop
	b	xloop
;------------------------------------------------------------
	AREA	DataStuff, DATA, READWRITE
TABLE	;Hex numbers for 7-seg display
	DCD 0X71000000 ;F
	DCD 0X79000000 ;E
	DCD 0X5E000000 ;D
	DCD 0X39000000 ;C
	DCD 0X7C000000 ;B
	DCD 0X77000000 ;A
	DCD 0X6F000000 ;9
	DCD 0X7F000000 ;8
	DCD 0X07000000 ;7
	DCD 0X7D000000 ;6
	DCD 0X6D000000 ;5
	DCD 0X66000000 ;4
	DCD 0X4F000000 ;3
	DCD 0X5B000000 ;2
	DCD 0X06000000 ;1
	DCD 0x3F000000 ;0
COUNTER 
	DCD 0X00000000 ;space for COUNTER set to zero to start
TZERO;space to store the registers for each of the threads when they get interruped
	DCD 0X00000000	;r0-r12 +sp + lr
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000
	DCD 0X00000000	;cpsr
	DCD 0X00000000	;sp
	DCD 0X00000000	;lr	
TONE
	DCD 0X00000000	;r0-12 +sp + lr
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000	
	DCD 0X00000000
	DCD 0X00000000
	DCD 0X00000000	;cpsr
	DCD 0X00000000  ;sp
	DCD 0X00000000	;lr
FLAG
	DCD 0X00000000
STARTFLAG
	DCD 0X00000000
SPZERO				;give 2kb of space for the stack pointers for each thread
	space 2048
SPONE
	space 2048
IRQSP
	space 2048

	END