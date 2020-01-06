;*       Tiny Basic port for Lion cpu/System
;*
;*         ported by Theodoulos Liontakis 2016
;*
;*          from  michael sullivan's 8086 port of
;*                               
;*                   Li-Chen Wang's
;*
;*                   8080 tiny basic 
;*
;* (c)copyleft
;* all wrongs reserved
;*
;*  New commands and fixed point arithmetic added


SDCBUF1	EQU	$2000  ;DS	514  Buffer 1 
SDCBUF2	EQU	$2202  ;DS	514  Buffer 2
FATBOOT	EQU	$2404  ;DS	2    Fat boot #sector 
FATROOT	EQU	$2406  ;DS	2    Root directory #sector 
FSTCLST	EQU	$2408  ;DS	2    First data #sector
FSTFAT	EQU	$240a  ;DS	2    First Fat first #sector
SDFLAG	EQU	$240c  ;DS	2    SD card initialized by rom=256
COUNTER     EQU	$240e  ;DS	2    General use counter increased by int 3 
FRAC1		EQU	$2410  ;DS	2    for fixed point multiplication-division
FRAC2		EQU  	$2412  ;DS	2               >>
RHINT0	EQU	$2414  ; Hardware interrupt 0
RHINT1	EQU	$2418  ; Hardware interrupt 1
RHINT2	EQU	$241c
RINT6		EQU	$2420
RINT7		EQU	$2424
RINT8		EQU	$2428
RINT9		EQU	$242c
RINT15	EQU	$2430
XCN         EQU   79
YCN         EQU   29
VMODE		EQU   $2434
SCOL		EQU   $2435
SHIFT       EQU	$2436
CAPSL       EQU	$2437
CIRCX		EQU	$2438
CIRCY		EQU	$243A
PLOTM		EQU	$243C
ROOTDIR	EQU	$243D
SECNUM      EQU   $243E
SECPFAT     EQU   $2440
FROOTDIR    EQU   $2442
RESRVB      EQU	$243E

ORG     	$2448  ;Ram

; RAM program ENTRY POINT
; A7 Reserved for decimal (was num2), in A6 fraction result of TSTNUM

START:	CLI
		MOV	A1,STACK 
		SETSP	A1
		STI
		JSR	CLRMEM
		IN	A1,24  ; get mode
		CMPI  A1,1
		JZ	VM1
		MOV	(DEFY),29
		MOV	(DEFX),79
		MOV   (PLOTM),1
		SETX  1589     ; set colors 
		MOV	A1,61152 
COLINIT:	OUT	A1,$F1F1
		JXAW	A1,COLINIT
		JR	12
VM1:		MOV	(DEFY),24
		MOV   (DEFX),52
		SETX	15   ; disable sprites mode 1
		MOV	A3,16391
		MOV	A4,16391+256
SPRLP1:	OUT.B A3,0
		OUT.B	A4,0
		ADD	A3,4096
		ADD	A4,4096
		OUT.B A3,0
		OUT.B	A4,0
		ADD	A3,4096
		ADD	A4,4096
		OUT.B A3,0
		OUT.B	A4,0
		SUB	A3,8184
		SUB   A4,8184
		JMPX	SPRLP1
		MOV	A1,$1F
		MOV.B	(SCOL),A1
		MOV	A3,(DEFY)
		MOV	(XX),A3     ;$001D ; Set INITIAL POS 
		MOV	A3,TITLE
		MOVI	A2,0
		MOVI	A0,0
		JSR	PRTSTG
		MOV	A3,TXTBGN
		MOV	A4,A3
		MOV	(TXTUNF),A3

RSTART:	CLI
		MOVI  A7,0
 		MOVI  A6,0
		MOV	A0,STACK
		SETSP	A0
		STI
		IN	A1,24
		MOV	(DEFY),29
		MOV	(DEFX),79
		CMPI	A1,1
		JNZ   ST2
		MOV	(DEFX),52
		MOV	(DEFY),24
ST2:		MOVI	A1,0
		MOV	(LOPVAR),A1
		MOV	(STKGOS),A1
		MOV	(CURRNT),A1
		;JSR	CRLF
		MOV	A5,(DEFY)
		MOV	(XX),A5
		MOV   A3,OK 
		MOVI	A0,0
		JSR	prtstg
ST3:		MOV   (UINT),0
		MOVHL	A0,0
		MOV.B	A0,'>'
		JSR	GETLN
		PUSH	A4         ; A4 end of text in buffer
		MOV 	A3,BUFFER
		JSR	TSTNUM
		MOVHL	A0,0
		JSR	IGNBLNK
		OR	A1,A1      ; A1 num 
		POP	A2
		JZ	DIRECT
		SUBI	A3,2
		MOV	A0,A1
		MOV	A4,A3
		JSR	STOSW  ; store lineno to 
		PUSH	A2
		PUSH  A3
		MOV	A0,A2
		SUB	A0,A3
		PUSH	A0
		JSR	FNDLN
		PUSH	A3
		JNZ	ST4
		PUSH	A3
		JSR	FNDNXT

		POP	A2
		MOV	A1,(TXTUNF)
		JSR	MVUP
		MOV	A1,A2
		MOV	(TXTUNF),A1
ST4:		
		POP	A2
		MOV	A1,(TXTUNF)

		POP	A0
		PUSH	A1
		CMPI.B A0,3
		JZ	RSTART
		ADD	A0,A1
		MOV	A1,A0	
		MOV	A3,TXTEND
		CMP	A1,A3
		JNC	QSORRY
		MOV	(TXTUNF),A1
		POP	A3
		JSR	MVDOWN
		POP	A3
		POP	A1
		JSR	MVUP
		JMP	ST3

TSTV:		
		MOVHL	A0,'@'
		JSR	IGNBLNK
		JC	RET2
		JNZ	TV1
		JSR	PARN
		SLL	A1,2
		PUSH	A3
		XCHG	A1,A3
		JSR	SIZE
		CMP	A1,A3
		JC	ASORRY
		MOV 	A1,TXTEND
		SUB	A1,A3
		POP	A3
		RET

TV1:		CMP.B	A0,122 ;'z'  ; TEST VARIABLE
		JA	RET22
		CMP.B	A0,97
            JAE   TV2
		CMP.B A0,'Z'
		JA    RET22
		CMP.B A0,'A'
		JC	RET2
TV2:		INC	A3
		MOV	A1,VARBGN
		SUB.B	A0,65
		AND	A0,$00FF
		SLL	A0,2
		ADD	A1,A0
RET2:		
		RET	
RET22:	
		CMP.B	A0,255
		RET

;----- TSTNUM

TSTNUM:
		MOVI	A1,0
		MOV	A6,0
		MOVHL	A2,A1
		MOVHL	A0,0
		JSR	IGNBLNK
TN1:
		CMP.B	A0,'.'
		JZ	DECIM
		CMP.B	A0,'0'
		JC	RET2
		CMP.B A0,':'
		JNC	RET2
		ADD	A2,$0100
		PUSH	A2
		MOVI	A2,10
		MULU	A1,A2
		MOVI	A0,0
            MOV.B	A0,(A3)
		SUB.B	A0,'0'
		MOVHL	A0,0
		INC	A3
		ADD	A1,A0
		POP	A2
		MOV.B A0,(A3)
		JP	TN1

NFR:		PUSH	A3
		MOV	A3,NFND
		JMP	ERROR
QHOW:
		PUSH	A3
AHOW:	
		MOV	A3,HOW
		JMP	ERROR

DECIM:	PUSH	A1
		PUSH	A2
		PUSH	A4
		MOVI	A4,1
		MOVI	A1,0
		MOVI	A0,0
TN2:		INC	A3
		MOV.B	A0,(A3)
		CMP.B	A0,'0'
		JC	DRET
		CMP.B A0,':'
		JNC	DRET
		MOVI	A2,10
		MULU	A1,A2
		SUB.B	A0,'0'
		CMP	A4,10000
		JZ	QHOW
		MOVI	A2,10
		MULU	A4,A2
		ADD	A1,A0
		JNC	TN2	
		JMP	QHOW
DRET:		MOVI	A2,0
		MOV	A0,15
DTOB2:	OR	A0,A0
		JN	DTOBEND
		SLL	A1,1		
		CMP	A1,A4
		JC	DTOB1
		BSET	A2,A0
		DEC	A0
		SUB	A1,A4
		JNZ	DTOB2
		JMP	DTOBEND
DTOB1:	DEC	A0
		JMP	DTOB2	
DTOBEND:	MOV	A6,A2
		POP	A4
		POP	A2
		POP	A1
		RET

TSTUNUM:
		MOVI	A1,0
		MOV	A6,0
		MOVHL	A2,A1
		MOVHL	A0,0
		JSR	IGNBLNK
UTN1:
		CMP.B	A0,'0'
		JC	RET2
		CMP.B A0,':'  ; is digit ?
		JNC	RET2
		ADD	A2,$0100
		PUSH	A2
		MOVI	A2,10
		MULU	A1,A2
		CMPI	A2,0
		JNZ	QHOW
		MOVI	A0,0
            MOV.B	A0,(A3)
		SUB.B	A0,'0'
		MOVHL	A0,0
		INC	A3
		POP	A2
		ADD	A1,A0
		MOV.B A0,(A3)
		JNC	UTN1
		JMP   QHOW

;--------  tables ----
tab1:	
	TEXT	"LIS"
	DB	'T'+128
	DA	LIST
	TEXT	"NE"
	DB	'W'+128
	DA	NEW
	TEXT	"RU"
	DB	'N'+128
	DA	RUN
	TEXT	"BY"
	DB	'E'+128
	DA	NEW
	TEXT	"SLIS"
	DB	'T'+128
	DA	SLIST
	TEXT  "LOA"
	DB	'D'+128
	DA	LOAD
	TEXT  "SAV"
	DB	'E'+128
	DA	SAVE
	TEXT "FIN"
	DB	'D'+128
	DA	FIND
	TEXT	"DI"
	DB	'R'+128
	DA	DIR
	TEXT	"C"
	DB	'D'+128
	DA	CD


TAB2	TEXT	"PRIN"
	DB	'T'+128
	DA	PRINT
	TEXT	"I"
	DB	'F'+128
	DA	IFF
	TEXT	"NEX"
	DB	'T'+128
	DA	NEXT
	TEXT	"GOT"
	DB	'O'+128
	DA	GOTO
	TEXT	"GOSU"
	DB	'B'+128
	DA	GOSUB
	TEXT	"RETUR"
	DB	'N'+128
	DA	RETURN
	TEXT	"FO"
	DB	'R'+128
	DA	FOR
      TEXT	"PLO"
	DB	'T'+128
	DA	TPLOT
	TEXT	"PO"
	DB	'S'+128
      DA	ATCMD
	TEXT	"OUT"
	DB	'B'+128
	DA	OUTBCMD
	TEXT	"OU"
	DB	'T'+128
	DA	OUTCMD
	TEXT	"RE"
	DB	'M'+128
	DA	REM
	TEXT	"INPU"
	DB	'T'+128
	DA	INPUT
	DB	'?'+128
	DA	PRINT
	TEXT	"POK"
	DB	'E'+128
	DA	POKE
	TEXT	"COLO"
	DB	'R'+128
	DA	COLOR
	TEXT	"BEE"
	DB	'P'+128
	DA	BEEP
	TEXT  "LIN"
	DB    'E'+128
	DA	LINE
	TEXT  "CIRCL"
	DB    'E'+128
	DA	CIRCLE
	TEXT	"FCOLO"
	DB	'R'+128
	DA	FORE
	TEXT	"BCOLO"
	DB	'R'+128
	DA	BACK
	TEXT	"CLS"
	DB	'P'+128
	DA	CLSSP
	TEXT	"CL"
	DB	'S'+128
	DA	CLS
	TEXT	"LE"
	DB	'T'+128
	DA	LET
	TEXT	"SCREE"
	DB	'N'+128
	DA	SCREEN
	TEXT  "LCOD"
	DB	'E'+128
	DA	LCODE
	TEXT  "SCOD"
	DB	'E'+128
	DA	SCODE
	TEXT  "RCOD"
	DB	'E'+128
	DA	RCODE
	TEXT  "LSCR"
	DB	'N'+128
	DA	LSCRN
	TEXT  "GCOD"
	DB	'E'+128
	DA	GCODE
	TEXT  "DELET"
	DB	'E'+128
	DA	DELETE
	TEXT  "MOD"
	DB	'E'+128
	DA	MODE
	TEXT	"PMOD"
	DB	'E'+128
	DA	PLOTMD
	TEXT	"STO"
	DB	'P'+128
	DA	STOP
	DB 	128
	DA	DEFLT

TAB4	TEXT	"KE"
	DB	'Y'+128
	DA	KEY
	TEXT	"RN"
	DB	'D'+128
	DA	RND
	TEXT	"ROUN"
	DB	'D'+128
	DA	ROUND
	TEXT	"AB"
	DB	'S'+128
	DA	MYABS
	TEXT	"IN"
	DB	'P'+128
	DA	INP
	TEXT	"PEE"
	DB	'K'+128
	DA	PEEK
	TEXT	"IN"
	DB	'T'+128
	DA	TOINT
	TEXT	"JOY"
	DB	'1'+128
	DA	JOYST1
	TEXT	"JOY"
	DB	'2'+128
	DA	JOYST2
	TEXT	"SI"
	DB	'N'+128
	DA	SIN
	TEXT	"CO"
	DB	'S'+128
	DA	COS
	TEXT	"P"
	DB	'I'+128
	DA	PI
	TEXT	"SQR"
	DB	'T'+128
	DA	SQRT
;	TEXT	"EX"
;	DB	'P'+128
;	DA	EXPO
;	TEXT	"L"
;	DB	'N'+128
;	DA	LN
	TEXT  "TIME"
	DB	'R'+128
	DA	TIMER
	TEXT	"SIZ"
	DB	'E'+128
	DA	SIZE
	TEXT	"WAIT"
	DB	'K'+128
	DA	WAITK
	TEXT	"US"
	DB	'R'+128
	DA	USR
	TEXT	"SDINI"
	DB	'T'+128
	DA	SDINIT
	TEXT  "BTO"
	DB	'P'+128
	DA	BTOP
	DB	128
	DA	XP40

TAB5	DB	'T', 'O'+128
	DA	FR1
	DB	128
	DA	QWHAT

TAB6	TEXT	"STE"
	DB	'P'+128
	DA	FR2
	DB	128
	DA	FR3
TAB8	DB	'>'
	DB 	'='+128
	DA	XP11
	DB	'#'+128
	DA	XP12
	DB	'>'+128
	DA	XP13
	DB	'='+128
	DA	XP15
	DB	'<'
	DB	'='+128
	DA	XP14
	DB	'<'+128
	DA	XP16
	DB	128	
	DA	XP17


DIRECT:
	MOV	A1,TAB1
	DEC	A1
EXEC:	
	MOVHL	A0,0
	JSR	IGNBLNK
	PUSH	A3
EX1:
	MOV.B	A0,(A3)
      CMP.B A0,97
      JB	SKIPUP
      CMP.B A0,128
	JAE   SKIPUP
      AND.B	A0,$DF        ; UPPER CASE 
SKIPUP: INC	A3
	CMP.B	A0,'.'   
	JZ	EX4
	INC	A1
	MOV.B	A4,(A1)
	BCLR	A4,7
	XOR.B A4,A0
	JZ	EX2
EX0A:                   ; not equal 
	CMP.B	(A1),128
	JNC	EX0B
	INC	A1
	JMP	EX0A
EX0B:
	ADDI	A1,3     ; next keyword
	BTST	A1,0
	JZ	ALI2
	INC	A1
ALI2: POP	A3
	CMP.B (A1),128
	JZ	EX3A
	DEC	A1
	JMP	EXEC
EX4:
	INC	A1    ; found ending with .
	CMP.B	(A1),128
	JC	EX4
	JMP	EX3
EX2:
	CMP.B	(A1),128
	JC	EX1
EX3:
	POP	A0
EX3A:	INC	A1
	BTST	A1,0   ; ALIGN TO EVEN ADDRESS
	JZ	ALIG
	INC	A1
ALIG:	JMP 	(A1)
;--------------------

NEW:
	JMP	START

STOP:
	JSR	ENDCHK
	JMP	RSTART

RUN:
	JSR	ENDCHK
	MOV	A3,TXTBGN

RUNNXL:
	MOVI	A1,0
	JSR	FNDLNP
	JNC	RUNTSL
	JMP	RSTART

RUNTSL:
	MOV	(CURRNT),A3
	ADDI	A3,2
RUNSML:
	JSR	CHKIO
	MOV	A1,TAB2
	DEC	A1
	JMP	EXEC

GOTO:
	JSR	EXP
	PUSH	A3
	JSR	ENDCHK
	JSR	FNDLN
	JNZ	AHOW
	POP	A0
	JMP	RUNTSL

; ----------- LIST 
SLIST:
	MOV.B	(SER),1  ; REDIRECT TO SERIAL PORT

LIST:	MOVI	A5,0
	JSR	TSTNUM
	JSR	ENDCHK
	JSR	FNDLN
LS1:
	JNC	LS2
	MOV.B	(SER),0
	JMP	RSTART
LS2:
	JSR	PRTLN
	JSR	CHKIO
	INC	A5
	CMP	A5,23
	JB	LS3
	MOVI	A5,0
	JSR	WAITK
LS3:	JSR	FNDLNP
	JMP	LS1

FIND:
	JSR	TSTNUM
	JSR	ENDCHK
	JSR	FNDLN
	JC	RSTART
	JSR	PRTLN
	JMP	ST3

PRINT:
	MOVI.B A2,3
	MOVHL	A0,59
	JSR	IGNBLNK
	JNZ	PR2
	JSR	CRLF
	JMP	RUNSML
PR2:
	MOVHL	A0,13
	JSR	IGNBLNK
	JNZ	PR0
	JSR	CRLF
	JMP	RUNNXL
PR0:	
	MOVHL	A0,'#'
	JSR	IGNBLNK
	JNZ	PR1
	JSR	EXP
	MOV.B	A2,A1
	JMP	PR3
PR1:
	JSR	QTSTG
	JMP	PR8
PR3:
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	PR6
	JSR	FIN
	JMP	PR0
PR6:
	MOVHL	A0,'\'
	JSR	IGNBLNK
	JZ	FINISH
	JSR	CRLF
	JMP	FINISH
PR8:
	JSR	EXP
	PUSH	A2
	JSR	PRTNUM
	MOV	A1,A7
	OR	A1,A1
	JZ	PR9
	MOV.B	A0,'.'
	JSR	CHROUT
	JSR	FRACTION
PR9:	POP	A2
	JMP	PR3

FRACTION:
	PUSH	A3
	PUSH	A4
	MOVI	A4,0
	MOV	A3,5000
	SETX	14
FRA1:	BTST	A1,15
	JZ	FRA2
	ADD	A4,A3
FRA2:	SRL	A3,1
	SLL	A1,1
	JMPX	FRA1
	ADC	A4,0
	MOV	A1,A4
	MOVI	A2,3
	JSR	PRTUNUM
	POP	A4
	POP	A3
	RET

;--------------  GOSUB

GOSUB:
	JSR	PUSHA
	JSR	EXP
	PUSH	A3
	JSR	FNDLN
	JNZ	AHOW
	MOV	A1,(CURRNT)
	PUSH	A1
	MOV	A1,(STKGOS)
	PUSH	A1
	MOVI	A1,0
	MOV	(LOPVAR),A1
	GETSP	A0
	ADD	A1,A0
	MOV	(STKGOS),A1
	JMP	RUNTSL

RETURN:
	JSR	ENDCHK
	MOV	A1,(STKGOS)
	OR	A1,A1
	JZ	QWHAT
	SETSP	A1
	POP	A1
	MOV	(STKGOS),A1
	POP	A1
	MOV	(CURRNT),A1
	POP	A3
	JSR	POPA
	JMP 	FINISH

; ----------for

FOR:	JSR	PUSHA
	JSR	SETVAL
	DEC	A1
	MOV	(LOPVAR),A1
	MOV	A1,TAB5
	DEC	A1
	JMP	EXEC
FR1:
	JSR	EXP
	MOV	(LOPLMT),A1
	MOV	A1,TAB6
	DEC	A1
	JMP	EXEC
FR2:
	JSR	EXP
	JMP	FR4
FR3:
	MOVI	A1,1
FR4:
	MOV	(LOPINC),A1
FR5:
	MOV	A1,(CURRNT)
	MOV	(LOPLN),A1
	XCHG	A1,A3
	MOV	(LOPPT),A1
	MOVI	A2,10
	MOV	A1,(LOPVAR)
	XCHG	A3,A1
	MOV	A1,A2
	GETSP	A0
	ADD	A1,A0
	JMP	FR7A
FR7:
	ADD	A1,A2
FR7A:
	MOVHL	A0,(A1)
	INC	A1
	MOV.B	A0,(A1)
	DEC	A1
	OR	A0,A0
	JZ	FR8
	CMP	A0,A3
	JNZ	FR7
	XCHG	A3,A1
	MOVI	A1,0
	GETSP	A0
	ADD	A1,A0
	MOV	A2,A1
	MOVI	A1,10
	ADD	A1,A3
	JSR	MVDOWN
	SETSP	A1
FR8:
	MOV	A1,(LOPPT)
	XCHG	A1,A3
	JMP 	FINISH
NEXT:
	JSR	TSTV
	JC	QWHAT
	MOV	(VARNXT),A1
NX0:
	PUSH	A3
	XCHG	A3,A1
	MOV	A1,(LOPVAR)
	MOVLH	A0,A1
	OR.B	A0,A1
	JZ	AWHAT
	CMP	A3,A1
	JZ	NX3
	POP	A3
	JSR	POPA
	MOV	A1,(VARNXT)
	JMP	NX0
NX3:
	MOVHL	A3,(A1)
	INC	A1
	MOV.B	A3,(A1)
	MOV	A1,(LOPINC)
	PUSH	A1
	ADD	A1,A3
	XCHG	A3,A1
	MOV	A1,(LOPVAR)
	SWAP	A3
	MOV.B	(A1),A3
	INC	A1
	SWAP 	A3
	MOV.B	(A1),A3
	MOV	A1,(LOPLMT)
	POP	A0
	SWAP	A0
	OR 	A0,A0
	JP	NX1
	XCHG	A1,A3
NX1:
	JSR	CKHLDE2
	POP	A3
	JC	NX2
	MOV	A1,(LOPLN)
	MOV	(CURRNT),A1
	MOV	A1,(LOPPT)
	XCHG	A3,A1
	JMP 	FINISH
NX2:
	JSR	POPA
	JMP 	FINISH	

; ------------ EXPRES

SIZE:
	MOV	A1,TXTEND  ;VARBGN
	SUB	A1,(TXTUNF) ;A3
RET10:
	RET

; ------------ DIVIDE

DIVIDE:  ; INT 4/9 Div A2 by A1 res in A1,A0
	MOV	A2,A1
	MOV	A1,A3
	CMP	(UINT),0
	JNZ	DV1
	MOVI	A0,9
	INT	4
	JMP	DVE
DV1:	MOVI	A0,6
	INT	5
DVE:	MOV	A2,A1
	XCHG	A0,A1
	RET

UDIVIDE:  ; INT 4/9 Div A2 by A1 res in A1,A0
	MOV	A2,A1
	MOV	A1,A3
	MOVI	A0,6
	INT	5
	MOV	A2,A1
	XCHG	A0,A1
	RET

	
DIVIDE2:  ; INT 5/1 Div A2 by A1 res in A1,A0
	MOV	A2,A1
	MOV	A1,A3
	MOVI	A0,1
	INT	5
	MOV	A2,A1
	XCHG	A0,A1
	RET

CHKSGN:
	OR	A1,A1
	JP	RET11
CHGSGN:
	NOT	A1
      NEG   A7
	ADC	A1,0
	XOR	A2,$8000
RET11:
	RET

CKHLDE:
	MOV	A0,A1
	XOR	A0,A3
	JP	CK1
	XCHG	A3,A1
CK1:	CMP	A1,A3
	JNZ   CK2
	MOV	A0,A7
	BTST	A1,15
	JZ	CK3
	NEG	A4
CK3:	BTST	A3,15
	JZ	CK4
	NEG	A0
CK4:	CMP	A4,A0 ;(NUM2)
CK2:	RET


CKHLDE2:
	MOV	A0,A1
	XOR	A0,A3
	JP	CK11
	XCHG	A3,A1
CK11:	CMP	A1,A3
	RET

;---- GETVAL FIN

SETVAL:
	JSR	TSTV
	JC	QWHAT
	PUSH	A1
	MOVHL	A0,'='
	JSR	IGNBLNK
	JNZ	QWHAT
	JSR	EXP
	MOV	A2,A1
	POP	A1
	MOV	(A1),A2
	ADDI	A1,2
	MOV	(A1),A7
	DEC	A1
	RET

FINISH:
	JSR	FIN
	JMP	QWHAT

FIN:
	MOVHL	A0,59
	JSR	IGNBLNK
	JNZ	FI1
	POP	A0
	JMP	RUNSML
FI1:
	MOVHL	A0,13
	JSR	IGNBLNK
	JNZ	FI2
	POP	A0
	JMP	RUNNXL
FI2:
	RET

ENDCHK:
	MOVHL	A0,13
	JSR	IGNBLNK
	JZ	FI2
QWHAT:
	PUSH	A3
AWHAT:
	MOV	A3,WHAT
ERROR:
	SUB.B	A0,A0
	JSR	PRTSTG
	POP	A3
	MOV	A1,(CURRNT)
	CMPI	A1,0
	JZ	RSTART
	JN	INPERR
	MOV	A4,A1
	JSR	LODSW
	JSR	FNDLN
	MOV	A3,A1
	JSR	PRTLN
	POP	A2
ERR2:
	JMP	RSTART
QSORRY:
	PUSH	A3
ASORRY:
	MOV	A3,SORRY
	JMP	ERROR
;-----

REM:
	MOVI	A1,0
	JMP	IFF1A

IFF:
	JSR	EXP
IFF1A:
	CMPI	A1,0
	JNZ	RUNSML
	JSR	FNDSKP
	JNC	RUNTSL
	JMP	RSTART

INPERR:
	MOV	A1,(STKINP)
	CLI
	SETSP	A1
	STI
	POP	A1
	MOV	(CURRNT),A1
	POP	A3
	POP	A3

INPUT:

	PUSH	A3
	JSR	QTSTG
	JMP	IP2
	JSR	TSTV
	JC	IP4
	JMP	IP3
IP2:
	PUSH	A3
	JSR	TSTV
	JC	QWHAT
	MOV.B A2,(A3)
	XOR.B	A0,A0  ; SUB
	MOV.B	(A3),A0
	POP	A3
	JSR	PRTSTG
	MOV.B	A0,A2
	DEC	A3
	MOV.B	(A3),A0
IP3:
	PUSH	A3
	XCHG	A1,A3
	MOV	A1,(CURRNT)
	PUSH	A1
	MOV	(CURRNT),-999
	GETSP	A0
	MOV	(STKINP),A0
	PUSH	A3
	MOV.B	A0,':'
	JSR	GETLN
IP3A:
	MOV	A3,BUFFER
	JSR	EXP
	NOP              ;jsr	endchk
	NOP
	NOP
	POP	A3
	XCHG	A1,A3
	SWAP	A3
	MOV.B	(A1),A3
	SWAP	A3
	INC	A1
	MOV.B	(A1),A3
	INC	A1
	SWAP	A7
	MOV.B	(A1),A7
	SWAP	A7
	INC	A1
	MOV.B	(A1),A7
	POP	A1
	MOV	(CURRNT),A1
	POP	A3
IP4:
	POP	A0
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	FINISH
	JMP	INPUT
	

DEFLT:
	MOV.B	A0,(A3)
	CMPI.B A0,13
	JZ	FINISH
LET:
	JSR	SETVAL
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	FINISH
	JMP	LET

;-----
EXP:	MOV	A7,0
	JSR	EXPR2
	MOV	A4,A7 ;********************
	PUSH	A1
	PUSH	A4
	
EXPR1:
	MOV	A1,TAB8
	DEC	A1
	JMP 	EXEC
XP11:
	JSR	XP18
	JC	RET4
	MOV.B	A1,A0
	RET
XP12:
	JSR	XP18
	JZ	RET4
	MOV.B	A1,A0
RET4:
	RET
XP13:
	JSR	XP18
	JBE	RET5
	MOV.B	A1,A0
RET5:
	RET
XP14:
	JSR	XP18
	MOV.B	A1,A0
	JBE	RET6
	MOVLH	A1,A1
RET6:
	RET
XP15:
	JSR	XP18
	JNZ	RET7
	MOV.B A1,A0
RET7:
	RET
XP16:
	JSR	XP18
	JNC	RET8
	MOV.B	A1,A0
RET8:
	RET
XP17:
	POP	A4
	POP	A1
	MOV	A7,A4 ;*************
	RET
XP18:
	MOV.B	A0,A2
	POP	A1
	POP	A4
	POP	A2
	PUSH	A1
	PUSH	A2
	PUSH	A4
	MOV.B	A2,A0
	JSR	EXPR2
	XCHG	A1,A3
	POP	A4
	POP	A0
	PUSH	A1
	MOV	A1,A0
	JSR	CKHLDE
	MOV	A7,0
	POP	A3
	MOVI	A1,0
	MOVI.B A0,1
	RET

EXPR2:
	MOVHL	A0,'-'
	JSR	IGNBLNK
	JNZ	XP21
	MOVI	A1,0
	JMP	XP26
XP21:
	MOVHL	A0,'+'
	JSR	IGNBLNK
XP22:
	JSR	EXPR3
XP23:
	MOVHL	A0,'+'
	JSR	IGNBLNK
	JNZ	XP25
	PUSH	A1
	MOV	A4,A7
	PUSH	A4
	JSR	EXPR3
XP24:
	XCHG	A1,A3
	POPX
	POP	A0
	PUSH	A1
	MOV	A1,A0
	MOV	A0,A7
	MOVX A4	
	ADD	A4,A0
	ADC	A1,A3
	MOV	A7,A4
	POP	A3
	JO	QHOW
	JMP	XP23
XP25:
	MOVHL	A0,'-'
	JSR	IGNBLNK
	JNZ	RET9
XP26:
	PUSH	A1
	MOV	A4,A7
	PUSH	A4
	JSR	EXPR3
	JSR	CHGSGN
	JMP	XP24

EXPR3:
	JSR	EXPR4
XP31:
	MOVHL	A0,'*'
	JSR	IGNBLNK
	JNZ	XP34
	PUSH	A1
	MOV	A4,A7
	PUSH	A4
	JSR	EXPR4
	XCHG	A1,A3
	POP	A4
	POP	A0
	PUSH	A1
	PUSH	A0
	PUSH	A2
	MOV	(FRAC2),A4
	MOV	A4,A7
	MOV	(FRAC1),A4
	MOV	A1,A3
	MOV	A2,A0
	MOVI	A0,0   ;
	INT	5      ; Multiplcation A1*A2 res in A1
	MOV	A4,(FRAC1)
	MOV	A7,A4
	CMPI	A0,0   ; check overflow
	POP	A2
	POP	A0
	JNZ	AHOW
	JMP	XP35
XP34:
	MOVHL	A0,'/'
	JSR	IGNBLNK
	JNZ	XP44
      PUSH	A1
	MOV	A4,A7
	PUSH	A4
	JSR	EXPR4
	XCHG	A1,A3
	POP	A4
	POP	A0
	PUSH	A1          ; a3
	MOV	(FRAC2),A4
	MOV	A4,A7
	MOV	(FRAC1),A4
	MOV	A1,A0           ; dividend
	MOV	A0,A3		   ; divider
	OR	A0,A4 ;(FRAC1)
	JZ	AHOW
	PUSH	A2
	JSR	DIVIDE2
	MOV	A4,(FRAC1)
	MOV	A7,A4
	MOV	A1,A2
	POP	A2
XP35:
	POP	A3
	JMP	XP31


XP44:
	MOVHL	A0,'%'
	JSR	IGNBLNK
	JNZ	XP55
	PUSH	A1
	JSR	EXPR4
	XCHG	A1,A3
	POP	A0
	PUSH	A1
	MOV	A1,A0
	OR	A3,A3
	JZ	AHOW
	PUSH	A2
	JSR	DIVIDE
	MOVI	A7,0
	POP	A2
	JMP	XP35

XP55:
	MOVHL	A0,124     ;'|'
	JSR	IGNBLNK
	JNZ	RET9
	PUSH	A1
	JSR	EXPR4
	XCHG	A1,A3
	POP	A0
	PUSH	A1
	MOV	A1,A0
	OR	A3,A3
	JZ	AHOW
	PUSH	A2
	JSR	DIVIDE
	MOVI	A7,0
	MOV	A1,A2
	POP	A2
	JMP	XP35


EXPR4:
	MOV	A1,TAB4
	DEC	A1
	JMP	EXEC
XP40:   		
	JSR	TSTV  ; VARIABLE ?
	JC	XP41
	MOV	A0,(A1)
	ADDI	A1,2
	XCHG	A1,A0
	MOV	A4,(A0)
	MOV	A7,A4
RET9:
	RET
XP41:	
	CMP	(UINT),0
	JNZ	UIN
	JSR	TSTNUM	; NUMBER ?
	JMP	NUIN
UIN:  JSR   TSTUNUM
NUIN:	MOVLH A0,A2
	OR.B	A0,A0
	JZ	PARN
	MOV	A4,A6
	MOV	A7,A4
	RET
PARN:
	MOVHL	A0,'('
	JSR	IGNBLNK
	JNZ	PARN1
	JSR	EXP
PARN1:
	MOVHL	A0,')'
	JSR	IGNBLNK
	JNZ	XP43
XP42:
	RET
XP43:
	JMP	QWHAT

	
MYABS:
	JSR	PARN
	JSR	CHKSGN
	OR	A0,A1
	JP	RET10
	JMP	QHOW

;-----  my ROUTINES

LSCRN:
	PUSH	A5
	PUSH	A4
	MOVI	A5,0
	MOV	A4,FNAME3 
	CMP	(SDFLAG),256
	JNZ	QHOW
	MOVHL	A0,34
	JSR	IGNBLNK
	JNZ	QWHAT
	PUSHX
	PUSH	A1
	SETX	7
SLD1: MOV.B	A0,(A3)
	CMP.B	A0,31
	JBE	QWHAT
	MOV.B	(A4),32
	CMP.B	A0,34
	JZ	SLD2
	INC	A3
	MOV.B	(A4),A0
SLD2:	JXAB	A4,SLD1
	MOVHL	A0,34   
	JSR	IGNBLNK
	JNZ	QWHAT
	MOVHL	A0,44    
	JSR	IGNBLNK
	JNZ	QWHAT
	MOV	A4,A3
	MOV   (UINT),1
	JSR	EXP
	MOV   (UINT),0
	MOV	A4,FNAME3
	PUSH	A3
	PUSH	A5
	MOV	A3,A1          ; load address
	MOVI	A0,13
	INT	5              ; LOAD SCREEN
	POP	A5
	POP	A3
	CMPI	A0,0
	JZ	QHOW
SLD3:	POP	A1
	POPX
	POP	A4
	POP	A5
	JMP	FINISH
; ---------------------------
LCODE:
	PUSH	A5
	PUSH	A4
	MOVI	A5,1
	MOV	A4,FNAME2
	JMP	LCODI
LOAD:	
	PUSH	A5
	PUSH	A4
	MOVI	A5,0
	MOV	A4,FNAME
	
LCODI: 
	CMP	(SDFLAG),256
	JNZ	QHOW
	MOVHL	A0,34
	JSR	IGNBLNK
	JNZ	QWHAT
	PUSHX
	PUSH	A1
	SETX	7
LD1:  MOV.B	A0,(A3)
	CMP.B	A0,31
	JBE	QWHAT
	MOV.B	(A4),32
	CMP.B	A0,34
	JZ	LD2
	INC	A3
	MOV.B	(A4),A0
LD2:	JXAB	A4,LD1
	INC	A4
	MOVHL	A0,34   
	JSR	IGNBLNK
	JNZ	QWHAT
	CMPI	A5,0  ; load or lcode
	JZ	LD4
	MOVHL	A0,44     ;lcode
	JSR	IGNBLNK
	JNZ	QWHAT
	MOV	A4,A3
	MOV   (UINT),1
	JSR	EXP
	MOV   (UINT),0
	MOV	A4,FNAME2
	JMP	LD6
LD4:	MOV	A4,FNAME
	MOV	A1,TXTBGN
LD6:	PUSH	A3
	PUSH	A4
	MOV	A3,A1          ; load address
	MOVI	A0,2
	INT	5              ; LOAD FILE
	POP	A4
	POP	A3
	CMPI	A0,0
	JZ	NFR
	CMPI	A5,0
	JNZ	LD3
	ADD	A1,TXTBGN
LD7:	MOV	(TXTUNF),A1
LD3:	POP	A1
	POPX
	POP	A4
	POP	A5
	JMP	FINISH
	
;--------------------------

DELAY: PUSHX
	 SETX	65000
LDDL:  JMPX	LDDL    ;delay
	 POPX
	 RET

DIR:
	PUSHX
	PUSH	A2
	PUSH	A4
	PUSH	A5
	MOVI	A0,13
	JSR	CHROUT
	MOVI	A5,0
TBF4:	MOV	A1,(FATROOT)
	ADD	A1,A5
	MOVI	A0,13
	MOV	A2,SDCBUF1
	INT	4              ; Load Root Folder 1st sector
	CMPI	A5,0
	JNZ	TBF3
	SETX	7
	PUSH	A2
TBF7:	MOV.B	A0,(A2)
	INC	A2
	JSR	CHROUT             ; print volume name
	JMPX	TBF7
	MOVI	A0,13
	JSR	CHROUT
	MOVI	A0,13
	JSR	CHROUT
	POP	A2
	MOV.B	(A2),$E5
	ADD	A2,32
	MOV.B	(A2),$E5
	SUB	A2,32
TBF3:	JSR	DELAY
	MOVI	A4,0
TBF1:	CMP.B	(A2),0     ; empty
	JZ	TBF5
	CMP.B	(A2),$E5   ; deleted entry
	JZ	TBF6
	CMP.B	(A2),46
	JB	TBF6
	PUSH	A2
	SETX	7
TBF2: MOV.B	A0,(A2)
	INC	A2
	JSR	CHROUT
	JMPX	TBF2
	MOV	A0,46     ; print .
	JSR	CHROUT
	SETX	2
TBF22: MOV.B	A0,(A2)
	INC	A2
	JSR	CHROUT
	JMPX	TBF22
	ADD	A2,17
	MOV	A1,(A2)
	SWAP	A1	;FILE SIZE
	MOV	A0,32
	JSR	CHROUT
	MOV	A0,32
	JSR	CHROUT
	MOV	A0,32
	JSR	CHROUT
	PUSH	A4
	MOV	A2,4
	MOV	A0,A1	
	MOV	(LZERO),0
	JSR	PRTUNUM
	MOV	(LZERO),1
	POP	A4
	MOVI	A0,13
	JSR	CHROUT
	POP	A2       
TBF6:	ADD	A2,32
	ADD	A4,32
	CMP	A4,512
	JNZ	TBF1  ; search same sector
	INC	A5
	CMP	A5,32  ;if not last root dir sector 
	JNZ	TBF4   ;load next sector and continue search
TBF5:	POP	A5
	POP	A4
	POP	A2
	POPX
	JMP	FINISH


;------------------------------

SCODE:
	PUSH	A5
	PUSH	A4
	MOVI	A5,1
	MOV	A4,FNAME2
	JMP	SCODI
SAVE:	
	PUSH	A5
	PUSH	A4
	MOVI	A5,0
	MOV	A4,FNAME
	
SCODI: 
	CMP	(SDFLAG),256
	JNZ	QHOW
	MOVHL	A0,34
	JSR	IGNBLNK
	JNZ	QWHAT
	PUSHX
	PUSH	A1
	PUSH	A6
	PUSH	A7
	SETX	7
SD1:  MOV.B	A0,(A3)
	CMP.B	A0,31
	JBE	QWHAT
	MOV.B	(A4),32
	CMP.B	A0,34
	JZ	SD2
	INC	A3
	MOV.B	(A4),A0
SD2:	JXAB	A4,SD1
	MOVHL	A0,34   
	JSR	IGNBLNK
	JNZ	QWHAT
	CMPI	A5,0  ; save or scode
	JZ	SD4
	MOVHL	A0,44     ;scode
	JSR	IGNBLNK
	JNZ	QWHAT
	MOV	A4,A3
	MOV   (UINT),1
	JSR	EXP
	MOV   (UINT),0
	PUSH	A1
	MOVHL	A0,44     ;scode
	JSR	IGNBLNK
	JNZ	QWHAT
	MOV   (UINT),1
	JSR	EXP
	MOV   (UINT),0
	MOV	A7,A1
	POP	A1
	MOV	A4,FNAME2
	JMP	SD6
SD4:	MOV	A4,FNAME
	MOV	A1,TXTBGN
	MOV	A7,(TXTUNF)
	SUB	A7,TXTBGN
	;INC	A7
SD6:	PUSH	A3
	PUSH	A5
	MOV	A6,A1          ; save address
	MOVI	A0,5
	INT	5              ; save FILE
	POP	A5
	POP	A3
	CMPI	A0,0
	JZ	QHOW
SD3:	POP	A7
	POP	A6
	POP	A1
	POPX
	POP	A4
	POP	A5
	JMP	FINISH


;-----------------------------

DELNAME    TEXT  "            "

DELETE:
	CMP	(SDFLAG),256
	JNZ	QHOW
	MOVHL	A0,34
	JSR	IGNBLNK
	JNZ	QWHAT
	MOV	A4,DELNAME
	SETX	5
	NTOM  A4,$2020
	MOV	A4,DELNAME
	SETX	10
DEL1: CMP.B	(A3),34  ; '"'
	JZ	DEL2
	CMP.B	(A3),13
	JZ	DEL2
	CMP.B	(A3),46  ; '.'
	JNZ	DELN
	SETX	3
	MOV	A4,=(DELNAME+8)
	JMP	DSKP
DELN:	MOV.B	(A4),(A3)
	INC	A4
DSKP:	JXAB	A3,DEL1
	INC	A3
DEL2:	MOVHL	A0,34
	JSR	IGNBLNK
	JNZ	QWHAT
	MOV	A4,DELNAME
	MOVI	A0,4
	INT	5
	MOV	A4,A3
	JMP	FINISH

;-----------------------

CD: 	CMP	(SDFLAG),256
	JNZ	QHOW
	MOV	A4,DELNAME
	SETX	5
	NTOM  A4,$2020
	MOVHL	A0,46
	JSR	IGNBLNK
	JNZ	CD3
	MOV.B	(DELNAME),$2E  ; 46 '.'
	CMP.B (A3),46
	JNZ	CD4
	MOV	(DELNAME),$2E2E
	INC	A3
	JMP	CD4
CD3:	MOVHL	A0,34
	JSR	IGNBLNK
	JNZ	QWHAT
	MOV	A4,DELNAME
	SETX	10
CD1: CMP.B	(A3),34  ; '"'
	JZ	CD2
	CMP.B	(A3),13
	JZ	CD2
	CMP.B	(A3),46  ; '.'
	JNZ	CDN
	SETX	3
	MOV	A4,=(DELNAME+8)
	JMP	CSKP
CDN:	MOV.B	(A4),(A3)
	INC	A4
CSKP:	JXAB	A3,CD1
	INC	A3
CD2:	MOVHL	A0,34
	JSR	IGNBLNK
	JNZ	QWHAT
CD4:	MOV	A4,DELNAME
	MOV	A0,16
	INT	5
	CMP   (DELNAME),$2E2E
	JZ	CD5
	CMPI	A0,0
	JZ	QHOW
CD6:	ADD   A0,(FSTCLST)
	SUBI	A0,2
	MOV	(FATROOT),A0
	JMP	FINISH
CD5:  CMPI	A0,0
	JNZ	CD6
	MOV	A0,(FSTCLST)
	SUB	A0,32
	MOV	(FATROOT),A0
	JMP	FINISH

;-------------------------------
RCODE:
	MOV   (UINT),1 
	JSR	EXP
	MOV   (UINT),0
	JSR	A1
	JMP	FINISH
;---------------------------

GCODE:
	MOV   (UINT),1
	JSR	EXP
	MOV	A5,A1
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	QWHAT
	JSR	EXP
	MOV   (UINT),0
	DEC	A1
	SETX  A1
GCWAIT:
	MOVI	A0,0
	INT	4           ; Get byte
	BTST	A0,1        ; if availiable
	JNZ	GC1
	MOVI	A0,7
	INT	4
	BTST	A0,2
	JZ	GCWAIT
	CMP	A1,$76   ; ESC
	JZ    QWHAT
	JMP   GCWAIT
GC1:  
	MOV.B (A5),A1
	JXAB  A5,GCWAIT
	JMP	FINISH

;------------------------------
CLS:	
	MOVI	A0,3
	INT	4
	JMP	FINISH


CLSSP:	SETX	15   ; disable sprites
		MOV	A0,16391
		MOV	A5,16391+256
SPRLP:	OUT.B A0,0
		OUT.B	A5,0
		ADD	A0,4096
		ADD	A5,4096
		OUT.B A0,0
		OUT.B	A5,0
		ADD	A0,4096
		ADD	A5,4096
		OUT.B A0,0
		OUT.B	A5,0
		SUB	A0,8184
		SUB   A5,8184
		JMPX	SPRLP
		JMP	FINISH

ATCMD:
	JSR	EXP
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	QWHAT
	PUSH	A1
	JSR	EXP
	MOV.B	A0,A1
	POP	A1
	MOV.B	(XX),A0 
	MOV.B	(YY),A1		
	JMP 	FINISH


COLOR:
	JSR	EXP
	CMP	A1,(DEFY)
	JA	QWHAT
	MOV	A5,A1
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	QWHAT
	JSR	EXP
	CMP	A1,(DEFX)
	JA	QWHAT
	MULU	A5,80
	ADD	A5,A1
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	QWHAT
	JSR	EXP
	ADD	A5,61152 
	OUT.B	A5,A1
	JMP 	FINISH

FORE: JSR	EXP
	AND.B	A1,$0F
	MOV.B	A5,(SCOL)
	AND.B	A5,$F0
	OR.B	A5,A1
	MOV.B	(SCOL),A5
	JMP 	FINISH

BACK: JSR	EXP
	AND.B	A1,$0F
	SLL	A1,4
	MOV.B	A5,(SCOL)
	AND.B	A5,$0F
	OR.B	A5,A1
	MOV.B	(SCOL),A5
	JMP 	FINISH

SCREEN:
	JSR	EXP
	SETX	1199
	MOVHL	A1,A1
	MOV	A5,61152 		
	NTOI	A5,A1
	JMP 	FINISH

PLOTMD:
	JSR	EXP
	MOV.B	(PLOTM),A1
	JMP 	FINISH

MODE:
	JSR	EXP
	CMPI	A1,1
	JNZ	MOD0
	MOV	A0,24
	MOV.B (SCOL),$1F
	JMP   MODX
MOD0:	MOV	A0,29
	MOV   (DEFX),105
	SETX  1589     ; set colors 
	MOV	A5,61152
	NTOI  A5,$F1F1 
	JR	6
MODX:	MOV   (DEFX),52
	MOV	(DEFY),A0
	OUT	24,A1
	MOV.B (VMODE),A1		
	MOVI	A0,3
	INT	4
	JMP 	FINISH

TPLOT:
	PUSH 	A2
	JSR	EXP
	CMP	A1,639
	JA	PLTX
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	QWHAT
	MOV	A5,A1
	JSR	EXP
	CMP	A1,239
	JA	PLTX
	MOV	A2,A1
	MOV	A1,A5
	MOVI	A0,2
	INT	4
PLTX:	JSR	IGNTOCR
	POP	A2
	JMP 	FINISH

LINE: PUSH 	A2
	PUSH	A4
	JSR	EXP
	PUSH	A1
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	QWHAT
	JSR	EXP
	PUSH	A1
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	QWHAT
	JSR	EXP
	PUSH	A1
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	QWHAT
	JSR	EXP
	MOV	A5,A3
	MOV	A4,A1
	POP	A3
	POP	A2
	POP	A1
	MOVI	A0,14
	INT	5
	MOV	A3,A5
	POP	A4
	POP	A2
	JMP   FINISH

CIRCLE: 
	PUSH 	A2
	JSR	EXP
	PUSH	A1
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	QWHAT
	JSR	EXP
	PUSH	A1
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	QWHAT
	JSR	EXP
	MOV	A5,A3
	MOV	A3,A1
	POP	A2
	POP	A1
	MOV	A0,17
	INT	5
	MOV	A3,A5
	POP	A2
	JMP   FINISH



BEEP:
	JSR	EXP
	MOV	A5,A1
	MOVHL	A0,44
	MOV	A1,4
	JSR	IGNBLNK
	JNZ	BEE1
	JSR	EXP
BEE1:	MULU	A1,8192
	ADD	A1,A5
	OUT	8,A1
	JMP 	FINISH

POKE:
	MOV   (UINT),1
	JSR	EXP
	MOV   (UINT),0
	MOVHL	A0,44
	JSR	IGNBLNK
	JZ	POK2
	JMP	QWHAT
POK2:	DEC	A1
POK1: INC	A1
	PUSH	A1
	MOV	(UINT),1
	JSR	EXP
	MOV	(UINT),0
	MOV.B	A0,A1
	POP	A1
	MOV.B	(A1),A0
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	FINISH
	JMP	POK1

OUTBCMD:
	MOV   (UINT),1
	JSR	EXP
	MOV   (UINT),0
	MOVHL	A0,44
	JSR	IGNBLNK
	JZ	OUTB2
	JMP	QWHAT
OUTB2: DEC	A1
OUTB1: INC	A1
	PUSH	A1
	MOV	(UINT),1
	JSR	EXP
	MOV	(UINT),0
	MOV.B	A0,A1
	POP	A1
	OUT.B	A1,A0
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	FINISH
	JMP	OUTB1

PEEK:
	MOV   (UINT),1
	JSR	EXP
	MOV   (UINT),0
	MOV.B	A1,(A1)
	MOVHL	A1,0
	RET

JOYST1:
	IN	A1,22
	NOT	A1
	AND	A1,31
	RET

JOYST2:
	IN	A1,22
	SWAP	A1
	NOT	A1
	AND	A1,31
	RET

TIMER:
	IN	A1,20
	BCLR	A1,15
	RET

TOINT:
	JSR	PARN
	BTST	A1,15
	JZ	TOI1
	INC	A1
TOI1:	MOV	A7,0
	RET

ROUND:
	JSR	PARN
	MOV	A0,A7
	ADD	A0,$8000
	ADC	A1,0
	MOV	A7,0
	RET

RND:	JSR	PARN
	OR	A1,A1
	JN	QHOW
	JNZ	RND1
	MOVI	A1,0
	RET
RND1:	
	MOV	A0,(RAND)
	PUSH  A2
	MOV 	A2,997
	MULU	A2,A0
      IN    A0,20
      ADD   A2,A0
      MOV   (RAND),A2
	MOVI	A0,6
	INT	5     ; DIV by A1
	MOV	A1,A0
	INC	A1
      POP   A2
	RET

PI:	MOVI	A1,3
	MOV	A7,$243F
	RET

BTOP:	MOV	A1,(TXTUNF)
      BTST  A1,0
	JRZ   2
	INC   A1
	MOVI	A7,0
	RET

SQRT: PUSH	A2
	PUSH	A4
	PUSH	A0
	JSR	PARN
	SRL	A7,1
	SRL	A1,1
	JNC	SQ1
	BSET	A7,15  ; Set Xo = A/2
SQ1:	MOV	A5,A1
	MOV	A6,A7  ; copy A/2 to A5A6
	SETX	5       ; 6 interations
SQ2:	MOV	A2,A5
	MOV	(FRAC2),A6
	MOV	(FRAC1),A7
	PUSH	A1
	PUSH	A7
	MOVI	A0,1
	INT	5
	MOV	A7,(FRAC1)
	POP	A4
	POP	A2
	SRL	A4,1
	SRL	A2,1
	JNC	SQ3
	BSET	A4,15
SQ3: 	ADD	A7,A4
	ADC	A1,A2
	JMPX	SQ2
	POP	A0
	POP	A4
	POP	A2
	RET

;EXPO:	RET
;LN:	RET

SINP11	EQU	$0001
SINP12	EQU	$45F3
SINP21	EQU	$0000
SINP22	EQU	$67C0


COS:	PUSH	A2
	PUSH	A4
	PUSH	A0
	JSR	PARN
	MOV	A0,A7
	ADD	A0,$921F	
	ADC	A1,1
	CMPI	A1,3
	JRZ	4
	JL	CSSK
	SUBI	A1,7
	SUB	A0,$487E
	JC	CSSK
	INC	A1
CSSK:
	MOV	A7,A0
	JMP	COSI


SIN:  PUSH	A2
	PUSH	A4
	PUSH	A0
	JSR	PARN

COSI:	PUSH	A3
	MOV	(FRAC2),SINP12 ;A2
	MOV	(FRAC1),A7
	MOVI	A2,1
	PUSH	A1                 ; save parameter
	MOVI	A0,0
	INT	5                  ; X*1.27323954
	POP	A0	;get param
	PUSH	A1    ; save res
	PUSH	(FRAC1) ;A2
	MOV	A1,A0 	; get param again
	PUSH	A1    	; save again
	MOV	(FRAC2),SINP22 ;A2
	MOV	(FRAC1),A7
	MOVI	A2,0       ;(SINP21)
	MOVI	A0,0
	INT	5          ; X*0.405284735
	POP	A2
	PUSH	A2           ;  again save 
	MOV	A0,A7
	MOV	(FRAC2),A0
	MOVI	A0,0        ; X*X*0.405284735
	INT   5       
	MOV	A2,(FRAC1)  ; result in A1A2
	POP	A0 ; get param
	POP	A4 ; first result
	POP	A3
	BTST	A0,15
	JZ   SIN1
	ADD	A2,A4 
	ADC	A1,A3
	JMP	SIN2
SIN1:
	NOT	A1
	NEG	A2
	ADC	A1,0
	ADD	A2,A4
	ADC	A1,A3
SIN2: MOV	A7,A2
	POP	A3
	POP	A0
	POP	A4
	POP	A2
	RET


WAITK:
	MOVI	A0,0
	INT	4           ; Get keyboard code
	BTST	A0,1        ; if availiable
	JNZ	WK1
	MOVI	A0,7
	INT	4
	BTST	A0,2
	JZ	WAITK
	MOVI	A0,10
	INT	4
WK1:
	RET	

KEY:  MOVI  A1,0
	MOVI	A0,0
	INT	4           ; Get keyboard code
	BTST	A0,1        ; if availiable
	JNZ	WK2
	MOVI	A0,7
	INT	4
	BTST	A0,2
	JZ	WK2
	MOVI	A0,10
	INT	4
WK2:
	RET	


SDINIT:
	MOVI	A0,11
	INT	4
	MOV	A1,A0
	MOVI	A0,3
	INT	5
	MOV	A0,(SDFLAG)
	RET


CLRMEM:	PUSH	A1
		PUSH	A0
		PUSHX
		MOV	A1,TXTBGN
		MOV	A0,TXTEND
		SUB	A0,A1
		SRL	A0,1
		DEC	A0
		SETX	A0	
		NTOM	A1,0
		MOV	A1,VARBGN
		MOV	A0,STKLMT
		SUB	A0,A1
		SRL	A0,1
		DEC	A0
		SETX	A0	
		NTOM  A1,0
		POPX
		POP	A0
		POP	A1
		RET

;----- GETLN
GETLN:
		jsr	chrout
		push	a1
		mov	a4,BUFFER  ; a4<->di
GL1:
		MOVI	A0,0
		INT	4           ; Get keyboard code for serial port
		BTST  A0,1
		JNZ   KEYIN
		BTST	A0,2        ; if availiable
		JZ	GL1
GL6:		MOVI	A0,7
		INT	4
		BTST	A0,2
		JZ	GL1
		MOVI	A0,10
		INT	4
KEYIN:
		MOV	A0,A1      ; CHAR IN A0
		CMP.B	A0,97
		JC	SKP2
		CMP.B	A0,122
		JA	SKP2
		;AND.B	A0,$DF        ; UPPER CASE 
SKP2:	      CMPI.B A0,8       ; BS
		JNZ   GL2
		CMP	A4,BUFFER
		JBE	GL1
		DEC.B	(XX)
		JP	GL4
		MOV.B	(XX),0
		JMP	GL1
GL4:		DEC	A4
		PUSH	A2
		MOV	A2,(XX)
		MOVI	A0,4
		MOV	A1,32
		INT	4
		POP	A2
		JMP	gl1
GL2:		MOV.B	(A4),A0
		INC	A4
		CMPI.B A0,13
		JZ    GL1E
		CMP	A4,BUFEND
		JZ	gl3
		JSR	CHROUT
		JMP	GL1
GL3:		
		DEC	A4
		JMP	GL1
GL1E:		
		JSR	CHROUT
		POP	A1
		MOV	A3,A4
		RET
		
FNDLN:	
		OR	A1,A1
		JN	QHOW
		MOV	A3,TXTBGN
FNDLNP:
FL1:		
		MOV	A0,(TXTUNF)
		DEC	A0
		CMP	A0,A3
		JC	RET13
		MOV	A4,A3
		mov.b	a0,(a4)
		swap	a0
		inc	a4
		mov.b	a0,(a4)
		CMP	A0,A1
		JC	FNDNXT
RET13:
		RET

FNDNXT:	
		INC	A3
FL2:
		INC	A3
FNDSKP:
		MOV.B	A0,(A3)
		CMPI.B  A0,13
		JNZ	FL2
		INC	A3
		JMP	FL1


; ----  CHROUT
CRLF:
		MOVI	A0,$0D
CHROUT:	
		OR.B	A0,A0
		JZ	RET9
		PUSH	A0
		CMPI.B A0,$0D
		JZ	CR_SCRL
		PUSH	A1
		PUSH 	A2
		MOV	A1,A0
		MOV	A2,(XX)
		MOV	A0,4
		CMP.B	(SER),1   ; REDIRECT TO SERIAL ?
		JNZ	NRMI
		MOVI	A0,1
;		SETX	10000    ;  DELAY FOR SERIAL TRANSMIT
;DLY:		NOP
;		JMPX	DLY
NRMI:		INT	4
		SWAP	A2
		MOV	A0,(DEFX)
		DEC	A0
		CMP.B	A2,A0
		JBE	SKP4
		JSR 	CRLF
		MOV	A2,-1	
SKP4:		INC.B	A2
		MOV.B	(XX),A2
		POP	A2
		POP	A1
		POP	A0
		RET

CR_SCRL:	PUSH	A1
		MOVI	a0,6
		CMP.B	(SER),1
		JNZ	NRMI2
;		SETX	10000    ;  DELAY FOR SERIAL TRANSMIT
;DLY3:		NOP
;		JMPX	DLY3
		MOVI	A1,13
		MOVI	A0,1
NRMI2:
		INT	4
		CMP.B	(SER),1
		JNZ	SKP3
;		SETX	10000    ;  DELAY FOR SERIAL TRANSMIT
;DLY2:		NOP
;		JMPX	DLY2
		MOVI	A0,1
		MOVI	A1,10
		INT	4
SKP3:		MOV.B	(XX),0
		POP	A1
		POP	A0
		RET

CHKIO:
	IN	A0,6
	AND   A0,6
	JNZ	CI0
	RET
CI0:	PUSH	A1
	MOVI	A0,0
	INT	4           ; Get keyboard code
	BTST	A0,1        ; if availiable
	JNZ	CI1
	MOV	A0,7
	INT	4
	BTST	A0,2
	JZ	IDONE
	MOV	A0,10
	INT	4
CI1:	
	CMP.B	A1,27
	JNZ	IDONE
	JMP	RSTART
IDONE:
	POP	A1
	RET

PRTSTG:     
	MOVHL	A2,A0
PS1:
	MOV.B A0,(A3)
	INC	A3
	CMPHL	A2,A0
	JNZ	PS2
	RET
PS2:
	JSR	CHROUT
	CMPI.B A0,13
	JNZ	PS1
	RET	

QTSTG:
	MOVHL	A0,34
	JSR	IGNBLNK
	JNZ	QT3
	MOV.B	A0,34
QT1:
	JSR	PRTSTG
	CMPI.B A0,13
	POP	A1
	JNZ	QT2
	JMP	RUNNXL
QT2:
	ADDI	A1,4
	JMP	A1
QT3:
	MOVHL	A0,39
	JSR	IGNBLNK
	JNZ	QT4
	MOV.B	A0,39
	JMP	QT1
QT4:
	MOVHL	A0,92
	JSR	IGNBLNK
	JNZ	QT5
	POP	A1
	JMP	QT2
QT5:
	RET

	;---------  DISPLAY NUMBER -----

PRTUNUM:  ; UNSIGNED 
	PUSH	A3
	MOVI	A3,10	
	PUSH	A3
	MOVHH	A2,A3
	MOV	A4,A2
PUN2:
	JSR	UDIVIDE ; unsigned div A1 by A3 res in A2,A1
	OR	A2,A2
	JZ	PUN3
	PUSH	A1
	DEC.B	A4
	MOV	A1,A2
	JMP	PUN2
PUN3:
	MOV	A2,A4
PUN4:
	DEC.B	A2
	OR.B	A2,A2 
	JN	PUN5
	MOV.B	A0,'0'
	CMP	(LZERO),1
	JRZ	4
	MOV.B	A0,32
	JSR	CHROUT
	JMP	PUN4
PUN5:
	MOVLH	A0,A2
	JSR	CHROUT
	MOV.B	A3,A1
PUN6:
	MOV.B	A0,A3
	CMPI.B A0,10
	POP	A3
	JZ	RET14
	ADD.B	A0,48
	JSR	CHROUT
	JMP	PUN6
;----------------------------------

PRTNUM:	            ;signed
	PUSH	A3
	MOVI	A3,10	
	PUSH	A3
	MOVHH	A2,A3
	DEC.B	A2
	JSR	CHKSGN 
	JP	PN1
	MOVHL	A2,'-'
	DEC.B	A2
PN1:
	MOV	A4,A2
PN2:
	JSR	DIVIDE     ; integer div A1 by A3 res in A2,A1
	OR	A2,A2
	JZ	PN3
	PUSH	A1
	DEC.B	A4
	MOV	A1,A2
	JMP	PN2
PN3:
	MOV	A2,A4
PN4:
	DEC.B	A2
	OR.B	A2,A2 
	JN	PN5
	MOV.B	A0,32
	JSR	CHROUT
	JMP	PN4
PN5:
	MOVLH	A0,A2
	JSR	CHROUT
	MOV.B	A3,A1
PN6:
	MOV.B	A0,A3
	CMPI.B A0,10
	POP	A3
	JZ	RET14
	ADD.B	A0,48
	JSR	CHROUT
	JMP	PN6

PRTLN:
	MOV	A4,A3
	JSR	LODSW
	MOV	A1,A0
	ADDI	A3,2
PRTLN1:
	MOV.B	A2,4
	JSR	PRTNUM
	MOV.B	A0,32
	JSR	CHROUT
	SUB.B	A0,A0
	JSR	PRTSTG
RET14:
	RET

;---------- MVUP MVDOWN

MVUP:
	CMP	A3,A1
	JZ	RET15
	MOV.B	(A2),(A3)  ; replace 4 lines
	INC	A3
	INC	A2
	JMP	MVUP

MVDOWN:
	CMP	A3,A2
	JZ	RET15
MD1:
	DEC	A3
	DEC	A1
	MOV.B (A1),(A3)
	JMP	MVDOWN

POPA:
	POP	A2
	POP	A1
	MOV	(LOPVAR),A1
	OR	A1,A1
	JZ	PP1
	POP	A1
	MOV	(LOPINC),A1
	POP	A1
	MOV	(LOPLMT),A1
	POP	A1
	MOV	(LOPLN),A1
	POP	A1
	MOV	(LOPPT),A1
PP1:	PUSH	A2   ; return address
RET15:
	RET

PUSHA:
	MOV	A1,STKLMT
	JSR	CHGSGN
	POP	A2
	GETSP	A0
	ADD	A1,A0
	JNC	QSORRY

	MOV	A1,(LOPVAR)
	OR	A1,A1
	JZ	PU1
	MOV	A1,(LOPPT)
	PUSH	A1
	MOV	A1,(LOPLN)
	PUSH	A1
	MOV	A1,(LOPLMT)
	PUSH	A1
	MOV	A1,(LOPINC)
	PUSH	A1
	MOV	A1,(LOPVAR)
PU1:
	PUSH	A1
	PUSH	A2
	RET

;----------- ignblnk ---------

IGNBLNK:   ; eat whitespace including a0 high

ign1:
	mov.b	a0,(a3)
	cmp.b	a0,32
	jnz	ign2
	inc	a3
	jmp	ign1
ign2:
	swap	a0
	cmp.b	(a3),a0
	swap  a0

	jnz	_ret
	inc	a3
	cmp.b a0,a0
_ret:	ret

IGNTOCR:  ; ignore chars till next statement
	MOV.B	A0,(A3)
	CMPI.B A0,13
	JZ	IGNCRE
	CMP.B	A0,59
	JZ	IGNCRE		
	INC	A3
	JMP	IGNTOCR
IGNCRE:
	RET
	
;--------------------------------

STOSW: 
	swap	a0
	mov.b	(a4),a0
	inc	a4
	swap	a0
	mov.b	(a4),a0
	inc	a4
	RET
LODSW: 
	mov.b	a0,(a4)
	swap	a0
	inc	a4
	mov.b	a0,(a4)
	inc	a4
	RET
;----------ADDED

OUTCMD:
	MOV   (UINT),1
	JSR	EXP
	MOV   (UINT),0
	MOVHL	A0,44
	JSR	IGNBLNK
	JZ	OUT2
	JMP	QWHAT
OUT2: ADDI	A1,2
OUT1: SUBI	A1,2
	PUSH	A1
	MOV	(UINT),1
	JSR	EXP
	MOV	(UINT),0
	MOV	A0,A1
	POP	A1
	OUT	A1,A0
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	FINISH
	JMP	OUT1

INP:	MOV	(UINT),1
	JSR	PARN
	MOV	(UINT),0
	IN	A1,A1
	RET

; 'usr(i(,j))'
;
; usr call a machine language subroutine at location 'i'  if
; the optional parameter 'j' is used its value is passed  in
; hl. the value of the function should be returned in hl.

USR:
	PUSH	A2
	MOVHL	A0,'('
	JSR	IGNBLNK
	JNZ	QWHAT
	JSR	EXP
	MOVHL	A0,')'
	JSR	IGNBLNK
	JNZ	PASPRM
	PUSH	A3
	MOV	A3,USRET
	PUSH	A3
	PUSH	A1
	RET
PASPRM:
	MOVHL	A0,44
	JSR	IGNBLNK
	JNZ	USRET1
	PUSH	A1
	JSR	EXP
	MOVHL	A0,')'
	JSR	IGNBLNK
	JNZ	USRET1
	POP	A2
	PUSH	A3
	MOV	A3,USRET
	PUSH	A3
	PUSH	A2
	RET
USRET:
	POP	A3
USRET1:
	POP	A2
	RET

;outio:
; 	out $FFFF,A1
; 	ret

;INPIO:
;	IN	A1,$FFFF
;	RET
;-----------------------------------------------------
; DATA
UINT		DW	0
LZERO		DW	1

DUMMY		DW	0
XX		DB	0
YY		DB	0
DEFY		DW	29
DEFX		DW	79

FNAME       TEXT	"        BAS"
		DB	13
FNAME2      TEXT	"        BIN"
		DB	13
FNAME3      TEXT	"        SCR"
		DB	13
TITLE		TEXT	"TINY BASIC for LION SYSTEM 2016"
		DB	13
how		TEXT  "How?"
		DB	$0d
OK		TEXT	"OK"
		DB	13
what		TEXT    "What?"
		DB	$0d
sorry		TEXT    "Sorry"
		DB    $0d
NFND		TEXT    "Not found"
		DB    $0d

SER		DB	0,0
RAND		DW	983
CURRNT	DW	0
STKGOS	DW	0
VARNXT	DW	0
STKINP	DW	0
LOPVAR	DW	0
LOPINC	DW	0
LOPLMT	DW	0
LOPLN		DW	0
LOPPT		DW	0

TXTUNF	DA    TXTBGN
TXTBGN	DS	42000   ; program space
TXTEND	DS	4

BUFFER	DS	120
BUFEND:

VARBGN	DS	256

STKLMT	DS	2048
STACK:	



