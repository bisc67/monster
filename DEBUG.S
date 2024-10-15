;trouble assembling with newest devpack 3 !!!!


; most code by author of lemmings
; changed/added a lot by The M.C.A.
; 
; BE VERY CAREFUL WHERE TO LOAD SECTORS/BOOT- RESET INSTEAD OF QUIT!!!!!!
;
; what can be updated:
; contr-t > insert text at adress...
; still problems with inserting/displaying labels(when starting with MySymbols!) 
; dma file save cannot be fragmented > optimize
; if low vectors(8-24) are changed by other programs BOOOOMMMM!!
; cartridge code needs to be carefully checked!
; contr-d > view directory


	
debugging	equ	0	;0=on(restore vecs)
strom	equ	0	;1 cartridge
help	equ	1
startup	equ	1	;0 cartridge

;----- equates -------------	
DmaVar	equ	1916	;size of dma stuff/4-1
varbase	equ	$30
scrwidth	equ	80*2
scrsize	equ	scrwidth*200
dis1x	equ	1
dis1y	equ	11
dis2x	equ	1
dis2y	equ	18
mem1x	equ	56
mem1y	equ	11
mem2x	equ	56
mem2y	equ	18
srx	equ	5	
sry	equ	9	
pcx	equ	5	
pcy	equ	0	
messagey	equ	28
watchy	equ	24
scrmax	equ	30
RegLine	equ	1
highlight	equ	0
BusErrVec	equ	$08
AddrErrVec	equ	$0c
IllErrVec	equ	$10
DivByZero	equ	$14
ChkVec	equ	$18
TrapvVec	equ	$1c
PrivVec	equ	$20
TraceVec	equ	$24
LineaVec	equ	$28
LinefVec	equ	$2c
Trap0Vec	equ	$80
Trap1Vec	equ	$84
Trap2Vec	equ	$88
Trap3Vec	equ	$8c
Trap4Vec	equ	$90
Trap5Vec	equ	$94
Trap6Vec	equ	$98
Trap7Vec	equ	$9c
Trap8Vec	equ	$a0
Trap9Vec	equ	$a4
Trap10Vec	equ	$a8
Trap11Vec	equ	$ac
Trap12Vec	equ	$b0
Trap13Vec	equ	$b4
Trap14Vec	equ	$b8
Trap15Vec	equ	$bc
TempA0	equ	varbase
TempD0	equ	varbase+4
varptr	equ	varbase+8
TraceBit	equ	15
ALTBIT	equ	0
CTRLBIT	equ	1
SHIFTBIT	equ	2
CAPSBIT	equ	3
CTRL	equ	1<<(CTRLBIT+8)
ALT	equ	1<<(ALTBIT+8)
brkptinstr	equ	$4afc		; ILLEGAL
RightArrow	equ	4
LeftArrow	equ	3
UpArrow	equ	1
DownArrow	equ	2
EndOfLine	equ	$d
Escape	equ	27
CTRLmake	equ	$1d
ALTmake	equ	$38
CAPSmake	equ	$3a
RIGHTshift	equ	$2a
LEFTshift	equ	$36
EscapeScan	equ	$01
kbdacia	equ	$fffffc00
longdelay	equ	49152
shortdelay	equ	4096

;------- macro's --------------

ReadByteInc	macro
	move.b	(a1)+,\1
	endm
PutByteInc	macro
	move.b	\1,(a1)+
	endm	
ReadWordInc	macro
	move.b	(a1)+,\1
	lsl	#8,\1
	move.b	(a1)+,\1
	endm
ReadLongInc	macro
	move.b	(a1)+,\1
	lsl	#8,\1
	move.b	(a1)+,\1
	swap	\1
	move.b	(a1)+,\1
	lsl	#8,\1
	move.b	(a1)+,\1
	endm
ReadWord	macro
	move.b	(a1),\1
	lsl	#8,\1
	move.b	1(a1),\1
	endm
setvec	macro
	lea	\1(pc),a1
	move.l	a1,(\2).w
	endm
exception	macro
	move.b	#\1,(varptr).w
	bra	reentermon
	endm
;----------------------------------------------------------
; Start part for ROM code
;----------------------------------------------------------
	ifne	strom

	dc.l	$fa52235f		;ROM id
	move.l	#$300000,sp		;was $e0000
	move.l	sp,varptr\w
	move.l	a1,TempA0
	bsr	do_reset
	bclr	#5,$fffffa09.w	;no key repeat
	movem.l	d0/a0-a1,-(a7)
	
	lea	OldVectors(a5),a0	;save 8-140!!!
	move.w	#BusErrVec,a1
	moveq	#($138/4)-1,d0
INcopyvecs1	move.l	(a1)+,(a0)+
	dbf	d0,INcopyvecs1
	movem.l	(a7)+,d0/a0-a1
	
	setvec	buserr,BusErrVec
	setvec	addrerr,AddrErrVec
	setvec	normbehandle,DivByZero
	setvec	trap3,Trap3Vec
	setvec	trap4,Trap4Vec
	setvec	trap5,Trap5Vec
	setvec	trap6,Trap6Vec
	setvec	trap7,Trap7Vec
	setvec	trap8,Trap8Vec
	setvec	trap9,Trap9Vec
	setvec	trap10,Trap10Vec
	setvec	trap11,Trap11Vec
	setvec	trap12,Trap12Vec
	setvec	trap15,Trap15Vec
	setvec	chkerr,ChkVec
	setvec	trapverr,TrapvVec
	setvec	priverr,PrivVec
	setvec	illegalerr,IllErrVec
	bra	start
	
;--------- reset all registers ------------

do_reset	move	#$2700,sr
	move.b	$ffff8260.w,d7
	andi	#3,d7
	reset
	bsr	re_synchro
	lea	$fffffa00.w,a0
	moveq	#0,d0
	movep.l	d0,1(a0)
	movep.l	d0,9(a0)
	movep.l	d0,$11(a0)
	move.b	#$48,$17(a0)
	bset	#2,3(a0)
	move.l	#$50ff0200,d0
	movep.l	d0,$21(a0)
	move.l	#$000051ff,d0
	movep.l	d0,$19(a0)
	move.l	#$001e6448,d0
	movep.l	d0,$11(a0)
	move.l	#$64000000,d0
	movep.l	d0,9(a0)
	move.l	#$7704001e,d0
	movep.l	d0,1(a0)
	move.b	#7,$ffff8800.w
	move.b	#$c0,$ffff8802.w
	move.b	#$e,$ffff8800.w
	move.b	#7,$ffff8802.w
	move.b	#3,$fffffc00.w
	move.b	#$96,$fffffc00.w
	move.b	#$80,$fffffc02.w
	move.b	#1,$fffffc02.w
	move.b	#8,$fffffc02.w
	move.b	#$1a,$fffffc02.w
	sf	$ffff820d.w
	sf	$ffff8264.w
	move.b	d7,$ffff8260.w
	rts
re_synchro	lea	$ffff8260.w,a2
	clr.b	(a2)
	moveq	#1,d2
	lea	$fffffa21.w,a0
	lea	$fffffa1b.w,a1
	move.b	#$10,(a1)
	move.b	#$f0,(a0)
	move.b	#8,(a1)
wt1	cmp.b	(a0),d2
	bne.s	wt1
wt2	move.b	(a0),d4
	move	#$267,d3
wt3	cmp.b	(a0),d4
	bne.s	wt2
	dbf	d3,wt3
	move.b	#$10,(a1)
	move.b	#2,$ffff820a.W
	rts
;---------------------------------------
start	move.l	TempA0,a1
	trap	#15		enter monitor
JustReturn	move.l	TempA0,a1
	jmp	(a6)		and return when done
	endc
;-------------------------------------------------------------------	
; PROGRAMFILE STARTUP
;-------------------------------------------------------------------
	ifne	startup
	
main	move.l	4(sp),a3		On ST, shrink allocated
	move.l	$c(a3),d0		memory so that another program
	add.l	$14(a3),d0		can be loaded in.
	add.l	$1c(a3),d0
	add.l	#$100,d0
	move.l	d0,-(sp)
	move.l	a3,-(sp)
	clr.w	-(sp)
	move.w	#$4a,-(sp)
	trap	#1
	add	#12,sp
	pea	start(pc)		Initialise monitor
	move.w	#38,-(sp)		in supervisor mode
	trap	#14
	trap	#15		Enter monitor!

Test	movem.l	$ffff8240.w,d0-d7	;all trash
	clr.l	-(a7)		;can be removed
	move.w	#$20,-(a7)
	trap	#1
	lea	$ffff8200.w,a0
	move.l	#$345000,d0
	lsr.w	#8,d0
	move.l	d0,(a0)
	clr.w	-(a7)
	moveq	#-1,d0
	move.l	d0,-(a7)
	move.l	d0,-(a7)
	move.w	#5,-(a7)
	trap	#14
	nop
test1	bsr.s	Test2
	divu	#0,d0
	bra.s	test1
Test2	moveq	#81,d0
	add.w	d0,a1
	rts
;--------------------------------------------	
start	lea	vars(pc),a0
	move.l	a0,d0
	clr.b	d0
	move.l	d0,a0
	lea	symboltable(pc),a1
	move.l	$ffff8200.w,d0
	asl.w	#8,d0
	and.l	#$ffffff,d0
	move.l	d0,videoquit(a0)
	move.l	d0,a2
;	clr.l	(a1)
	bsr	Initialise
	rts
	endc			/* startup */
	
	ifeq	startup
	movem.l	a0-a6/d0-d7,-(sp)	;ROM SAVE ALL
	bsr	Initialise
	movem.l	(sp)+,a0-a6/d0-d7
	rts
	endc
	
debuggerstart
;----------------------------------------------------------
; The monitor!
;----------------------------------------------------------
Monitor	bsr	DrawScreen
	bsr	INdovectors		Ensure vectors OK
MonitorLoop	lea	normbehandle(pc),a0	And bus error handler
	move.l	a0,intbehandle(a5)	back to the default
	lea	MyStack(a5),sp	Set the stack to the top
	bsr	GetKey
	bsr	UpperCase
	bsr	ClearMessageLine
	lea	KeyTable(pc),a0	Scan the key press table to see
FKloop	move.w	(a0)+,d1		which commands are bound to
	beq.s	MonitorLoop		specific keys
	move.w	(a0)+,d2
	cmp.w	d1,d0
	bne.s	FKloop
	lea	KeyTable(pc,d2.w),a1
	jmp	(a1)
KeyTable
;
; Keys can have the CTRL, ALT or CTRL+ALT bits set
; Form:		Keycode,routine offset		; Key press
;
	dc.w	CTRL!'A',StepNextInstr-KeyTable	; 
	dc.w	CTRL!'B',BreakPointHere-KeyTable	; CTRL B
	dc.w	CTRL!'C',QuitFromMonitor-KeyTable	; CTRL C
*	dc.w	29,GoDownload-KeyTable		; F10
	dc.w	9,SelectNextWindow-KeyTable	; <TAB>
	dc.w	22,SetSymbol-KeyTable		; f3
	dc.w	CTRL!'R',RunInstr-KeyTable	; contr R
	dc.w	CTRL!'S',SkipInstr-KeyTable	; contr S
	ifne	help
	dc.w	'H',HelpMe-KeyTable		; H
	endc
	dc.w	CTRL!'W',SetWorkSpc-KeyTable	; CTRL W
	dc.w	ALT!'N',SignedFl-KeyTable	; CTRL N
	dc.w	CTRL!'M',MoveProg-KeyTable	; CTRL M
	dc.w	CTRL!'Z',StepInstr-KeyTable	; F1
	dc.w	'G',SearchMemory-KeyTable	; G
	dc.w	'I',CopyMemory-KeyTable		; I
	dc.w	'M',SetWindowBase-KeyTable	; M
	dc.w	'N',SearchNext-KeyTable		; N
	dc.w	'O',Expression-KeyTable		; O
	dc.w	'V',ViewCopper-KeyTable		; V
	dc.w	ALT!'V',ViewBase-KeyTable	;alt V
	dc.w	'W',FillWith-KeyTable		; W
	dc.w	'B',BinaryFile-KeyTable		; B
	dc.w	CTRL!'L',ExecFileLoad-KeyTable	; contr l
	dc.w	ALT!'F',DmaFormatDisk-KeyTable	; ALT F
	dc.w	23,DmaReadFile-KeyTable		; F4
	dc.w	24,DmaWriteFile-KeyTable	; F5
	dc.w	25,DmaReadBoot-KeyTable		; F6
	dc.w	26,DmaWriteBoot-KeyTable		; F7
	dc.w	29,DmaWriteTrack-KeyTable	; F10
	dc.w	28,DmaReadTrack-KeyTable	; F9
	dc.w	ALT!'W',AddWatch-KeyTable	; ALT W
	dc.w	ALT!'E',EditWindow-KeyTable	; ALT E	
	dc.w	ALT!'R',SetRegister-KeyTable	; ALT R
	dc.w	ALT!'I',ReInitialise-KeyTable	; ALT I
	dc.w	ALT!'S',SplitWindow-KeyTable	; ALT S
	dc.w	ALT!'D',DeleteAWatch-KeyTable	; ALT D
	dc.w	ALT!'L',LockToRegister-KeyTable	; ALT L
	dc.w	ALT!'Z',ZoomWindow-KeyTable	; ALT Z
	dc.w	ALT!'B',SetBreakPoint-KeyTable	; ALT B
	dc.w	'V',ViewFlip-KeyTable		; V
	dc.w	DownArrow,NextLine-KeyTable	; down
	dc.w	UpArrow,PrevLine-KeyTable	; up
	dc.w	RightArrow,NextByte-KeyTable	; right
	dc.w	LeftArrow,PrevByte-KeyTable	; left
	dc.w	CTRL!DownArrow,NextPage-KeyTable	; CTRL down
	dc.w	CTRL!UpArrow,PrevPage-KeyTable	; CTRL up
	dc.w	0,0
;----------------------------------------------------------
SignedFl	not.b	SignedFlag(A5)
	bsr	update_disassembly
	bra	MonitorLoop

QuitFromMonitor
QuitMon	lea	QFMmsg(pc),a0	Confirm it
	bsr	confirm
	ifeq	debugging
	lea	OldVectors(a5),a0	If debugging, restore vectors
	move.w	#8,a1
	moveq	#7,d0
QMloop	move.l	(a0)+,(a1)+
	dbf	d0,QMloop
	endc
	sf	dispdrawn(a5)	Make sure display not drawn
	move.l	RegSSP(a5),a7
	bsr	settheirvideo
	move.l	videoquit(a5),d0
	bsr	setvidbase
	move.w	#$2200,sr
	move.w	#0,-(sp)
	trap	#1
	rts
*GoDownload	lea	GDmsg(pc),a0	Enter download for PDS
*	bsr	confirm		Enter via TRAP!
*	trap	#0
*	bra	MonitorLoop	
;----------------------------------------------------------
SelectNextWindow
	move.b	selectwin(a5),d0	Select next window
	addq	#1,d0		Only 1-4
	cmp.w	#3,d0
	bcs.s	WinOk
	bne.s	SNWcheck5
	tst.b	dis2active(a5)	If 3 not active, skip to 4
	bne.s	WinOk
	addq	#1,d0
SNWcheck5	cmp.w	#4,d0
	bne.s	SNWreset		If 4 not active, skip to 1
	tst.b	mem2active(a5)
	bne.s	WinOk
SNWreset	moveq	#0,d0
WinOk	move.b	d0,selectwin(a5)
	bsr	highlight_win	Highlight it
	bra	MonitorLoop		And back!
;----------------------------------------------------------
StepInstr	move.w	#1<<TraceBit,d1	We want to trace!
	st	singlestep(a5)	In single step
	bra.s	SInobreaks
StepInstrEnt
	lea	CantStep(pc),a0
	move.l	a0,intbehandle(a5)
	lea	breakpts(a5),a0	Set all the breakpoints
	lea	breakcont(a5),a2
* make extra bp's
	moveq	#3,d2
	move.w	#brkptinstr,d3
SImakebreak	move.l	(a0)+,d0		Get the address
	bmi.s	SInobreak		If -ve, skip this one
	move.l	d0,a1
	move.w	(a1),(a2)		Read previous contents
	move.w	d3,(a1)		Store an illegal
	cmp.w	(a1),d3		Did it work?
	bne	CantStep		Nope, abort with message
SInobreak	addq	#2,a2		Next store
	dbf	d2,SImakebreak	And again for more
SInobreaks	setvec	trace,TraceVec	Set up return vector
	ifeq	debugging
	setvec	illegalerr,IllErrVec
	endc
	sf	inmonitor(a5)	Out of monitor for Bus error
	lea	registers(a5),a0	Base of save area
	move.l	64(a0),sp		Set up SSP
	move.l	60(a0),a1		Set up USP
	move.l	a1,usp
	move.l	68(a0),-(sp)	Set up return addr
	bclr	#0,3(sp)
	move.w	72(a0),d0		Status reg
	and.w	#$7fff,d0
	or.w	d1,d0		Make sure tracing
	move.w	d0,-(sp)		Store on stack
	movem.l	(a0),d0-d7		Restore data regs
	movem.l	32(a0),a0-a6	Restore addr regs
	rte
;----------------------------------------------------------
StepNextInstr
	move.l	RegPC(a5),d0	Make sure PC is even
	bclr	#0,d0
	move.l	d0,a1
	bsr	DisAssemble		Disassemble to get addr of next instr
	lea	CantStep(pc),a0	Set up error handler
	move.l	a0,intbehandle(a5)
	move.l	a1,tempbreak(a5)	Set a temporary breakpoint
	move.w	(a1),tempcont(a5)
	move.w	#brkptinstr,(a1)	As before, if cant set, abort
	cmp.w	#brkptinstr,(a1)	ie, must be in ROM
	bne.s	CantStep
	bsr	settheirvideo	Set screen to theirs
	sf	singlestep(a5)	Not single stepping
	clr.b	prevchar(a5)	Make sure KBD ok.
	clr.b	kbdstatus(a5)
	bra	StepInstrEnt
CantStep	lea	NoStepMsg(pc),a0	If we cant step, abort
	bsr	PutAMessage		with a message.
	st	MsgLineClr(a5)
	lea	normbehandle(pc),a0
	move.l	a0,intbehandle(a5)
	bra	MonitorLoop
;----------------------------------------------------------
RunInstr	sf	dispdrawn(a5)	and run at full speed
	bsr	settheirvideo	after setting their
	moveq	#0,d1		breakpoints!
	clr.b	prevchar(a5)
	clr.b	kbdstatus(a5)
	bra	StepInstrEnt
;----------------------------------------------------------
SkipInstr	move.l	RegPC(a5),a1	Skip instruction by disassembling
	bsr	DisAssemble		to find base of next one
	move.l	a1,RegPC(a5)
	bsr	update_disp1	Redraw display
	bra	MonitorLoop
;----------------------------------------------------------
SetWindowBase
	bsr	CalcBaseReg		Sets a0 to the base of a window pointer
	move.l	a0,a2
	lea	WinBaseMsg(pc),a4	The message to put while editing
	bsr	ReadExpression	Read an expression
	bne	MonitorLoop		Escape? well quit then!
	move.l	d0,(a2)		Set the base and then
	bsr	update_display	draw the entire display
	bra	MonitorLoop
;----------------------------------------------------------
Expression	lea	ExprMsg(pc),a4
	bsr	ReadExpression	Get the expression value
	bne	MonitorLoop		Back if aborted
	move.l	d0,-(sp)
	lea	ExprMsg2(pc),a0	Put the message Result=$
	bsr	PutAMessage
	move.l	(sp),d0
	bsr	PrintHexLong	Print it as a long hex
	sub.w	#1,xpos(a5)
	moveq	#',',d0		Add a comma
	bsr	PrintChar
	bsr	PrintSpace		and a space
	move.l	(sp)+,d0		and then print it
	bsr	PrintDecLong	in decimal
	bra	MonitorLoop

;----------------------------------------------------------
FillWith	lea	FillMsg(pc),a0	Fill memory
	bsr	Get3Params		we need 3 parameters
	bne.s	FWexit		Aborted?
	move.l	d4,a1		start address
	move.l	d5,a0		end address
FWloop	cmp.l	a0,a1		finished?
	bhi.s	FWexit
	PutByteInc	d6		Nope, put a byte
	bra.s	FWloop
FWexit
	bsr	update_display	and update display
ClearToLoop	bsr	ClearMessageLine	Clear the message line
	bra	MonitorLoop
;----------------------------------------------------------
CopyMemory	lea	CopyMsg(pc),a0
	bsr	Get3Params
	bne.s	FWexit
	move.l	d4,a1		Source start
	move.l	d5,a0		source end
	move.l	d6,a2		Destination 
	cmp.l	a2,a1		is dest < start
	bcs.s	CMcopyrev
CMloop	cmp.l	a0,a1
	bhi.s	FWexit
	move.b	(a1)+,(a2)+
	bra.s	CMloop
	bra.s	FWexit
CMcopyrev	move.l	a0,d0
	sub.l	a1,d0
	add.l	d0,a2
CMcrloop	cmp.l	a0,a1
	bhi.s	FWexit
	move.b	-(a0),-(a2)
	bra.s	CMcrloop
;----------------------------------------------------------
; Returns three parameters in d4, d5 and d6
Get3Params	bsr	PutAMessage
	lea	otherbehand(pc),a0	Bus error during evaluation!
	move.l	a0,intbehandle(a5)
	clr.b	linebuffer(a5)	Set up for the edit
	moveq	#0,d2		line routine
	move.w	xpos(a5),templong(a5)
GTPloop	move.w	templong(a5),xpos(a5)
	bsr	EditLine		Get the line
	bne.s	GTPexit		Aborted?
	lea	linebuffer+1(a5),a1	Ensure pointer points to position
	sub.l	a1,a0		of error within the buffer
	move.l	a0,d2
	lea	linebuffer(a5),a0
	bsr	EvalNoErr		Evaluate
	tst.b	NoError(a5)		Error?
	bne.s	GTPerror		Yep, re do
	move.l	d0,d4		Store value
	cmp.w	#',',token(a5)	Must have a comma seperator
	bne.s	GTPerror
	bsr	EvalNoErr		Evaluate next
	tst.b	NoError(a5)		Error? redo
	bne.s	GTPerror
	move.l	d0,d5		Store value
	cmp.w	#',',token(a5)	Must be another comma
	bne.s	GTPerror
	bsr	EvalNoErr		Evaluate parameter
	tst.b	NoError(a5)
	bne.s	GTPerror
	tst.w	token(a5)		Must be at the end of the line
	bne.s	GTPerror		or we have an error
	move.l	d0,d6		Save parameter
GTPexitok	moveq	#0,d0		Set Z cos it was ok
GTPexit	rts
GTPerror	bsr	flashscreen
	lea	linebuffer+1(a5),a1	Set pointer to where error
	sub.l	a1,a0		occurred.
	move.l	a0,d2		and then re-edit
	bra.s	GTPloop
;----------------------------------------------------------
SearchNext	bsr	CalcBaseReg		Must be in a valid window!
	move.l	a0,a2
	move.l	(a2),a1		Get the address
	addq	#1,a1		next byte!
	move.l	a1,(a2)		and store it just in case
	lea	SearchMsg1(pc),a0	Warn them so they dont get
	bsr	PutAMessage		worried when nothing happens
	move.l	searchvalue(a5),d2	Get the value to search
	move.b	searchtype(a5),d0	And the type
	and.b	#$7f,d0		Mask of case sense bit
	cmp.b	#1,d0		Was it byte?
	beq	SMbmore
	cmp.b	#2,d0		Word?
	beq	SMwmore
	cmp.b	#3,d0		Long?
	beq	SMlmore
	cmp.b	#4,d0		String?
	beq	SMsmore
	cmp.b	#5,d0		Instruction?
	beq	SMimore
	bra	MonitorLoop		Oh well!
;----------------------------------------------------------
SearchMemory
	bsr	CalcBaseReg
	move.l	a0,a2
	lea	SearchMsg(pc),a0	Get which type of
	bsr	PutAMessage		data to search for
SMloop	bsr	GetCursoredKey	But put the cursor there
	bsr	UpperCase		first
	cmp.w	#'B',d0
	beq.s	SMbyte
	cmp.w	#'W',d0
	beq	SMword
	cmp.w	#'L',d0
	beq	SMlong
	cmp.w	#'T',d0
	beq	SMstring
	cmp.w	#'I',d0
	beq	SMinstr
	cmp.b	#Escape,d0
	beq	SMclear
	bra.s	SMloop
	
SMbyte	lea	SMbytemsg(pc),a0	Get the data byte
	move.l	#$ff,d2
	bsr	SMgetvalue
SMbmore	move.b	#1,searchtype(a5)	Set its type
	moveq	#-1,d0		Loop counter, we go for
;				64K bytes at a time	
SMbcsop	ReadByteInc	d3		Get the byte
	cmp.b	d3,d2		This one?
	beq.s	SMfoundB		Yup, exit
	dbf	d0,SMbcsop		Go for next
	bsr	CheckKeypress	If at 64K; check for
	beq.s	SMbcsop		abort key
	cmp.b	#EscapeScan,d0
	beq.s	SMfound
	bra.s	SMbcsop
SMfoundS	move.l	a3,a1		Point to the string
	bra.s	SMfound
SMfoundL	subq	#2,a1		Point to the long
SMfoundW	subq	#1,a1		  "          word
SMfoundB	subq	#1,a1		  " 	 byte
SMfound	move.l	a1,(a2)		Store the address found
	bsr	update_display	draw the display
SMclear	bra	ClearToLoop

SMword	lea	SMwordmsg(pc),a0	As byte routine!
	move.l	#$ffff,d2
	bsr	SMgetvalue
	move.b	#2,searchtype(a5)
SMwmore	ReadByteInc	d3
	lsl	#8,d3
	moveq	#-1,d0
SMWloop	ReadByteInc	d3
	cmp.w	d3,d2
	beq.s	SMfoundW
	lsl	#8,d3
	dbf	d0,SMWloop
	bsr	CheckKeypress
	beq.s	SMWloop
	cmp.b	#EscapeScan,d0
	beq.s	SMfound
	bra.s	SMWloop
	
SMlong	lea	SMlongmsg(pc),a0	As word, byte routine
	moveq	#-1,d2
	bsr	SMgetvalue
	move.b	#3,searchtype(a5)

SMlmore	ReadByteInc	d3
	lsl.l	#8,d3
	ReadByteInc	d3
	lsl.l	#8,d3
	ReadByteInc	d3
	lsl.l	#8,d3
	moveq	#-1,d0
SMLloop	ReadByteInc	d3
	cmp.l	d3,d2
	beq.s	SMfoundL
	lsl.l	#8,d3
	dbf	d0,SMLloop
	bsr	CheckKeypress
	beq.s	SMLloop

	cmp.b	#EscapeScan,d0
	beq	SMfound
	bra.s	SMLloop
	
SMstring	lea	SMstrmsg(pc),a0	The string search is
	bsr	PutAMessage		a bit more awkward.
	bsr	GetLine		Get the string.
	bne	SMexit
	move.b	#4,searchtype(a5)	Check to see if it
	lea	SMstrmsg2(pc),a0	is to be case sensitive
	bsr	PutAMessage
SMwaitloop	bsr	GetCursoredKey
	bsr	UpperCase
	cmp.b	#'Y',d0
	beq.s	SMsensitive
	cmp.b	#Escape,d0
	beq	SMclear
	cmp.w	#CTRL!'C',d0
	beq	SMclear
	cmp.b	#'N',d0
	bne.s	SMwaitloop
	bset	#7,searchtype(a5)	Yup, set bit 7
	lea	linebuffer(a5),a0	and make the line
SMuploop	move.b	(a0),d0		uppercase
	beq.s	SMsensitive
	bsr	UpperCase
	move.b	d0,(a0)+
	bra.s	SMuploop
SMsensitive	lea	SearchMsg1(pc),a0	Put the searching...
	bsr	PutAMessage		message
	lea	searchvalue(a5),a0
	lea	linebuffer(a5),a1	and copy the linebuffer
	moveq	#14,d0		to the local search value
SMcpy	move.b	(a1)+,(a0)+
	beq.s	SMsmore
	dbf	d0,SMcpy
	clr.b	(a1)+
SMsmore	move.l	(a2),a3
	moveq	#-1,d1
SMSloop	lea	searchvalue(a5),a0	Base of string
	move.l	a3,a1
SMScheck	ReadByteInc	d0		Get a byte
	btst	#7,searchtype(a5)	Sensitive?
	beq.s	SMSnosense
	bsr	UpperCase		Nope, make it upper
SMSnosense	tst.b	(a0)		End of string?
	beq	SMfoundS		Yup, found it!
	cmp.b	(a0)+,d0		Is it the next char?
	beq.s	SMScheck		Yup, do next
	addq	#1,a3		Start again!
	dbf	d1,SMSloop		for 64K times!
	bsr	CheckKeypress	Check for escape
	beq.s	SMSloop
	cmp.b	#EscapeScan,d0
	beq	SMfound
	bra.s	SMSloop

SMinstr	lea	SMinstrmsg(pc),a0	The string search is
	bsr	PutAMessage		a bit more awkward.
	bsr	GetLine		Get the string.
	bne	SMexit
	move.b	#5,searchtype(a5)	;for next
	lea	searchvalue(a5),a0
	lea	linebuffer(a5),a1	and copy the linebuffer
	moveq	#14,d0		to the local search value
SMcpy1	move.b	(a1)+,d0
	bsr	UpperCase
	move.b	d0,(a0)+
	beq.s	SMimore
	dbf	d0,SMcpy1
	clr.b	(a0)+
	
SMimore	lea	SearchMsg1(pc),a0	;Put the searching...
	bsr	PutAMessage		;message
	move.l	(a2),a3
	addq.l	#1,a3		;setup get next opcode

SMSloop2	move.w	#1023,d1		;times before key
SMSloop1	move.l	a3,a1		;points to code
	bsr	DisAssemble	 	;to linebuffer
	lea	searchvalue(a5),a0	
	lea	linebuffer+20(a5),a1	;base of diss instr
	cmpi.b	#'?',(a1)		;illegal opcode
	beq.s	SMSno1		;skip makes faster
SMScheck1	move.b	(a0)+,d0		End of string?
	beq	SMfoundS		Yup, found it!

; 31 can be made shorter, each one less means speed up!!
	moveq	#31,d2		;length of linebuffer
SMScheck2	cmp.b	(a1)+,d0		
	dbeq	d2,SMScheck2	;Njep, do next
	bne.s	SMSno1
SMScheck3	tst.b	(a0)		;end of string?
	beq	SMfoundS
	cmpm.b	(a0)+,(a1)+		;is next one identical?
	bne.s	SMSno1
	bra.s	SMScheck3
SMSno1	addq.l	#2,a3		;get next one
	dbf	d1,SMSloop1		;for 1K times!
	bsr	CheckKeypress	;Check for escape
	beq.s	SMSloop2		;no key pressed
	cmp.b	#EscapeScan,d0
	beq	SMfoundS
	bra.s	SMSloop2
;---------------
SMgetvalue	move.l	a0,a4		Put the required message
	bsr	ClearMessageLine
	move.l	d2,-(sp)		Save the mask
	bsr	ReadExpression	Read the expression
	bne.s	SMexit
	move.l	d0,-(sp)
	lea	SearchMsg1(pc),a0
	bsr	PutAMessage
	move.l	(sp)+,d2		Make sure its in our range
	and.l	(sp)+,d2		Tough if its out it!
	move.l	d2,searchvalue(a5)	Store the old value
	move.l	(a2),a1		and get the base addr to search
	rts
SMexit	bra	ClearToLoop		Dont worry about stack,
;----------------------------------------------------------
; Returns a0 - address of the memory storage area.
; BEQ for disassembly; BNE for memory
CalcBaseReg	moveq	#0,d0
	move.b	selectwin(a5),d0
	move.w	d0,d1	
	subq	#1,d0		Are we at the watch window?
	bmi	MonitorLoop		Yup, give up now
	lsl	#2,d0		Point to the base of it
	lea	dis1pc(a5,d0.l),a0
	cmp.b	#1,d1		And set Z for Disassembly
	beq.s	CBRdis		windows only
	cmp.b	#3,d1
CBRdis	rts
;----------------------------------------------------------
NextByte	bsr.s	CalcBaseReg		To get next byte (or word)
	beq.s	NBdis		within a window, we get its
	add.l	#1,(a0)		base and then if it is a memory
	bsr	update_dump		window we add one otherwise
	bra	MonitorLoop		add 2 and update relevant
NBdis	add.l	#2,(a0)		display area.
	bsr	update_disassembly
	bra	MonitorLoop
;----------------------------------------------------------
PrevByte	bsr.s	CalcBaseReg		As NextByte
	beq.s	PBdis
	sub.l	#1,(a0)
	bsr	update_dump
	bra	MonitorLoop
PBdis	sub.l	#2,(a0)
	bsr	update_disassembly
	bra	MonitorLoop
;----------------------------------------------------------
NextLine	tst.b	selectwin(a5)	We can have a next watch!
	beq	NextWatch
	bsr.s	CalcBaseReg
	beq.s	NLdis
	add.l	#4,(a0)		For dump, just add 4
	bsr	update_dump
	bra	MonitorLoop
NLdis	move.l	(a0),a1		For disassembly, point to
	bsr	DisAssemble		next instruction
	move.l	a1,(a0)
	bsr	update_disassembly
	bra	MonitorLoop
NextWatch	move.w	watchptr(a5),d0	For next watch, scan
	lea	watchbuffer(a5),a0	watch buffer until we are
	add.w	d0,a0		at the end of the current
	tst.b	(a0)		watch. If this is the last
	beq	MonitorLoop		one, dont bother.
NWloop	addq	#1,d0
	tst.b	(a0)+
	bne.s	NWloop
	tst.b	1(a0)
	beq	MonitorLoop
	move.w	d0,watchptr(a5)	Update the watches
	bsr	update_watch
	bra	MonitorLoop
;----------------------------------------------------------
PrevLine	tst.b	selectwin(a5)	
	beq	PrevWatch
	bsr	CalcBaseReg
	beq.s	PrevLdis
	sub.l	#4,(a0)		Memory is easy!
	bsr	update_dump
	bra	MonitorLoop	
PrevLdis	move.l	(a0),a1		Disassembly not so easy,
	bsr	ZDevenup		we have to ensure we get a
	move.l	a1,(a0)		valid instruction!
	bsr	update_disassembly
	bra	MonitorLoop
PrevWatch	move.w	watchptr(a5),d0	Much as NextWatch except
	beq	MonitorLoop		backwards!
	lea	watchbuffer(a5),a0
	add.w	d0,a0
	subq	#1,a0
PWloop	subq	#1,a0
	subq	#1,d0
	beq.s	PWset
	tst.b	(a0)
	bne.s	PWloop
PWset	move.w	d0,watchptr(a5)
	bsr	update_watch
	bra	MonitorLoop
;----------------------------------------------------------
NextPage	bsr	CalcBaseReg		Each dump and disassembly window
	beq.s	NPdis1		have pointers to the next word 
	move.l	16(a0),(a0)		just off screen, this is moved
	bsr	update_dump		into the window base and the
	bra	MonitorLoop		screen is redrawn.
NPdis1	move.l	16(a0),(a0)
	bsr	update_disassembly
	bra	MonitorLoop
;----------------------------------------------------------
PrevPage	bsr	CalcBaseReg		Not so easy....
	move.b	selectwin(a5),d0
	subq	#1,d0		window #1
	beq.s	PPdis1
	subq	#1,d0		#2
	beq.s	PPmem1
	subq	#1,d0		#3
	beq.s	PPdis2
	subq	#1,d0		and #4
	beq.s	PPmem2
	bra	MonitorLoop
PPmem1	sub.l	#6*4,(a0)		Simple, just subtract enough
	tst.b	mem2active(a5)	for the window size.
	bne.s	PPnm2
	sub.l	#5*4,(a0)
PPnm2	bsr	update_dump
	bra	MonitorLoop
PPmem2	sub.l	#5*4,(a0)		Much the same as above
	bra.s	PPnm2
PPdis1	sub.l	#6*2,(a0)		As above but must even up
	tst.b	dis2active(a5)	the address so we point to
	bne.s	PPnd2		a valid instruction.
	sub.l	#5*2,(a0)
PPnd2	bra	PrevLdis
PPdis2	sub.l	#5*4,(a0)
	bra	PrevLdis
;----------------------------------------------------------
; Requires input in the form Reg=Value
SetRegister	clr.b	linebuffer(a5)	Make sure line empty
	moveq	#0,d2
SRreedit	pea	SRerror2(pc)	Set up for EditLine/
	move.l	sp,errorstack(a5)	Evaluate
	lea	SetRegMsg(pc),a0
	bsr	PutAMessage
	bsr	EditLine
	bne.s	SRExit
	lea	linebuffer(a5),a0	Copy the symbol
	bsr	nexttoken
	bsr	CopySymbol
	bne	EVALerror
	bsr	CheckMySymbols	If its not one of mine, bitch
	bne	EVALerror		and go again
	lea	breakpts(a5),a2	Don't allow BP0..3
	cmp.l	a2,a1
	bcc	EVALerror
	move.l	d1,-(sp)
	move.l	a1,a2
	cmp.w	#'=',token(a5)	Must have an =
	bne	EVALerror
	bsr	Evaluate		Evaluate the value
	bne	SRerror
	tst.w	token(a5)		Bitch if not at end of line
	bne	SRerror2
	move.w	d0,(a2)		Store the value
	move.l	(sp)+,d1
	bne.s	SRex
	move.l	d0,(a2)
SRex	bsr	update_disp1	update and quit
SRExit	bra	ClearToLoop
SRerror2	bsr	flashscreen		Flash it and update
SRerror	lea	linebuffer+1(a5),a3	pointer positions so
	sub.l	a3,a0		that it points to the
	move.l	a0,d2		cause of the error (or
	move.l	errorstack(a5),sp	just after!)
	bra.s	SRreedit
;----------------------------------------------------------
; Adds a symbol to the symbol table (if there is one!)
SetSymbol	clr.b	linebuffer(a5)	Make sure line empty
	moveq	#0,d2		Make sure symbol table
	move.l	symtable(a5),d0	pointer is even
	and.l	#$fffffe,d0		if it is zero,
	beq	MonitorLoop		abort it
	move.l	d0,symtable(a5)
SSreedit	pea	SSerror2(pc)	Set up stacks for edit/eval
	move.l	sp,errorstack(a5)
	lea	SetSymMsg(pc),a0	Much the same as above
	bsr	PutAMessage
	bsr	EditLine
	bne.s	SSExit
	lea	linebuffer(a5),a0
	bsr	nexttoken
	bsr	CopySymbol
	bne	EVALerror
	bsr	CheckMySymbols	Can't do one of mine!
	beq	EVALerror
	bsr	CheckSymbolTable	Does it exist?
	beq	SSsymthere		Yes, dont bother adding one
	lea	symbuffer(a5),a2	Now add this one to
	clr.l	(a1)		the end of the symbol table
	clr.l	4(a1)
	moveq	#7,d1		Maximum of 8 chars
	move.l	a1,a3
SScopysym	move.b	(a2)+,(a1)+
	dbeq	d1,SScopysym
	move.l	a3,a1
SSsymthere	lea	8(a1),a2		Now, evaluate expression
	cmp.w	#'=',token(a5)	To assign its value.
	bne	EVALerror		Dont tell anyone, but if they
	bsr	Evaluate		press escape after getting an
	bne	SSerror		error here, the old symbol isnt
	tst.w	token(a5)		deleted!
	bne	SSerror2
	move.l	d0,(a2)
SSex	bsr	update_display
SSExit	bra	ClearToLoop
SSerror2	bsr	flashscreen		Haven't I seen this code
SSerror	lea	linebuffer+1(a5),a3	somewhere before?
	sub.l	a3,a0
	move.l	a0,d2		Reset line pointer pos.
	move.l	errorstack(a5),sp
	bra	SSreedit
;----------------------------------------------------------
MoveProg	lea	MoveMonMsg(pc),a4	Shouldn't allow this
	bsr	ReadExpression	if on ROM. Moves the monitor
	bne	MonitorLoop		to anywhere in the memory map.
	and.l	#$fffffe,d0		Useful to get it out of the
	move.l	d0,a0		way when programs encroach on
	lea	debuggerend(pc),a2	it.
	lea	debuggerstart(pc),a1
	move.l	a2,d0
	sub.l	a1,d0
	lsr	#2,d0
	move.l	a0,a2
MPmoveit	move.l	(a1)+,(a0)+		Once moved, we want all the
	dbf	d0,MPmoveit		vectors to be redone. Cant use
	jmp	4(a2)		a branch cos of position independance
;----------------------------------------------------------
SetWorkSpc	lea	SetWrkMsg(pc),a4	Move the workspace
	bsr	ReadExpression
	bne	MonitorLoop
	clr.b	d0
	move.l	d0,a0		destination workspace
	move.l	a0,varptr\w	
	move.w	#(screenmem/4)-1,d0
SWScopy	move.l	(a5)+,(a0)+
	dbf	d0,SWScopy
	move.l	varptr\w,a5
	bsr	DrawScreen1
	bra	MonitorLoop
;---------------------------------------------------------
ViewBase	lea	ViewBaseMsg(pc),a4	;with input
	bsr	ReadExpression
	bne	MonitorLoop
	clr.b	d0		;$100 byte border
	move.l	pallete(a5),$ffff8240.w
	move.b	resolution(a5),$ffff8260.w
	bsr	SetBaseN
	bsr	GetKey
	bra	ViewNorm
;----------------------------------------------------------
ViewCopper	bsr	settheirvideo	Show their screen
	bsr	GetKey		until keypress
;----------------------------------------------------------
ViewNorm	bsr	setmyvideo		and then set back to
	bra	MonitorLoop		normal.
;----------------------------------------------------------
ViewFlip	tst.b	flipped(a5)		View flipping. Not
	bne.s	ViewNorm		so straight forward!
	st	flipped(a5)
	bsr	settheirvideo
	bra	MonitorLoop
settheirvideo
	sf	havepallete(a5)	on the ST only.
	move.l	pallete(a5),$ffff8240.w
	move.b	resolution(a5),$ffff8260.w
	move.l	copperbase(a5),d0
	bra	setvidbase
	
setmyvideo	sf	flipped(a5)		Much as above but
	tst.b	havepallete(a5)	On ST copies first
	bne.s	SMVhaveit		4 colours and resolution
	st	havepallete(a5)
	move.b	$ffff8260.w,resolution(a5)
	move.l	$ffff8240.w,pallete(a5)
SMVhaveit	lea	screenmem(a5),a0
	move.l	a0,d0
	bsr	setvidbase
	move.b	#$1,$ffff8260.w
	move.l	#$07770000,$ffff8240.w	;0000ffff
	rts

;----------------------------------------------------------
	ifne	help
HelpMe	bsr	ClearScreen		Dead simple help command
	lea	helpmsg(pc),a0
	bsr	printmessage
	bsr	GetKey
	bsr	DrawScreen
	bra	MonitorLoop
	endc
;----------------------------------------------------------
ReInitialise
	lea	ReInitMsg(pc),a0	Allows the workspace
	bsr	confirm		to be re-initialised if it
	bsr	ReInit		becomes corrupted.
	bra	Monitor
ReInit	movem.l	d0-d7/a0-a4,-(sp)
	move.l	a5,a0
	move.l	symtable(a5),a1
	move.l	copperbase(a5),a2
	bsr	Initialise
	movem.l	(sp)+,d0-d7/a0-a4
	rts

confirm	bsr	PutAMessage		Confirms a response.
CFloop	bsr	GetCursoredKey
	bsr	UpperCase		Exits back to caller only
	cmp.w	#'Y',d0		if 'Y' is pressed. Otherwise
	beq.s	CFdoit		it will return to the main
	cmp.w	#'N',d0		program loop.
	beq.s	CFdont
	cmp.b	#Escape,d0
	beq.s	CFdont
	cmp.w	#CTRL!'C',d0
	bne.s	CFloop
CFdont	bra	ClearToLoop
CFdoit	rts
;----------------------------------------------------------
EditWindow	tst.b	selectwin(a5)	Edits the Memory window
	beq	EditWatch		or a watch if in that window
	bsr	CalcBaseReg
	beq	MonitorLoop		cant do it in a disassembly (yet!)
	move.l	(a0),a2
	move.l	a0,a6
	lea	EditAbort(pc),a0
	move.l	a0,intbehandle(a5)
	lea	EditMemMsg(pc),a0
	bsr	PutAMessage
	move.w	#mem1y,a3		base offset
	move.w	#11,a4		Max offset
	tst.b	mem2active(a5)
	beq.s	EMnomem2
	move.w	#5,a4
	cmp.b	#2,selectwin(a5)
	beq.s	EMnomem2
	move.w	#4,a4
	move.w	#mem2y,a3
EMnomem2	moveq	#0,d2		X position within window
	moveq	#0,d3		Y position within window
EditMemRead	move.l	a2,a1
	ReadLongInc	d0
	move.l	d0,templong(a5)	Get the previous long word
EditMemLoop	move.w	a3,d0		Set the cursor position
	add.w	d3,d0
	move.w	d0,ypos(a5)
	moveq	#mem1x+9,d0
	lea	EditOffsets(pc),a0
	add.b	0(a0,d2.w),d0
	move.w	d0,xpos(a5)
	bsr	GetCursoredKey
	cmp.b	#Escape,d0
	beq	ExitEditMem
	cmp.w	#CTRL!'C',d0
	beq	ExitEditMem
	cmp.w	#LeftArrow,d0
	beq	EDTBack
	cmp.w	#RightArrow,d0
	beq	EDTForward
	cmp.w	#DownArrow,d0
	beq	EDTDown
	cmp.w	#UpArrow,d0
	beq	EDTUp
	cmp.w	#EndOfLine,d0
	beq.s	EditMemEnd
	bsr	UpperCase
	move.l	d0,d6
	cmp.w	#'0',d0
	bcs.s	EditMemLoop
	cmp.w	#'9',d0
	bls.s	EditMemOk
	cmp.w	#'A',d0
	bcs.s	EditMemLoop
	cmp.w	#'F',d0
	bhi.s	EditMemLoop
	subq	#7,d0
EditMemOk	and.l	#$0f,d0
	ror.l	#4,d0		Make it in the top 4 bits
	move.l	#$0fffffff,d4	The Mask!
	move.w	d2,d1		The shift count is taken
	lsl	#2,d1		from the Xpos*4
	ror.l	d1,d4		Shift mask
	lsr.l	d1,d0		Shift data
	move.l	templong(a5),d5	Get the long
	and.l	d4,d5		Delete old nibble
	or.l	d0,d5		set new nibble
	move.l	d5,templong(a5)	and store it
	move.l	d6,d0
	bsr	PrintChar
	bra.s	EDTForward
EditMemEnd	bsr	EDTStore
ExitEditMem	bsr	update_display
	bra	ClearToLoop
EDTStore	move.l	templong(a5),d0
	move.l	a2,a1
	rol.l	#8,d0
	PutByteInc	d0
	rol.l	#8,d0
	PutByteInc	d0
	rol.l	#8,d0
	PutByteInc	d0
	rol.l	#8,d0
	PutByteInc	d0
	movem.l	a2/d2-d3,-(sp)
	bsr	update_dump
	bsr	update_disassembly
	movem.l	(sp)+,a2/d2-d3
	rts
EditAbort	lea	EDabortMsg(pc),a0
	bsr	PutAMessage
	bsr	update_disp1
	bra	MonitorLoop
EDTBack	subq	#1,d2
	bpl	EditMemLoop
	moveq	#7,d2
	bra.s	EDTUp
EDTForward	addq	#1,d2
	cmp.w	#8,d2
	bcs	EditMemLoop
	moveq	#0,d2
	bra.s	EDTDown
EDTUp	bsr	EDTStore
	subq	#4,a2
	subq	#1,d3
	bpl	EditMemRead
	moveq	#0,d3
	move.l	a2,(a6)
	bra.s	EDTrefresh
EDTDown	bsr	EDTStore
	addq	#4,a2
	addq	#1,d3
	cmp.w	a4,d3
	bls	EditMemRead
	move.w	a4,d3
	add.l	#4,(a6)
EDTrefresh	movem.l	a2/d2-d3,-(sp)
	bsr	update_dump
	movem.l	(sp)+,a2/d2-d3
	bra	EditMemRead
EditOffsets	dc.b	0,1,2,3,5,6,7,8
AddWatch	lea	AddWatchMsg(pc),a4
	clr.b	linebuffer(a5)
	sf	delwatch(a5)
	bra.s	AddWatchEnt
;----------------------------------------------------------
EditWatch	lea	EdWatchMsg(pc),a4
	st	delwatch(a5)
	lea	watchbuffer(a5),a1
	lea	linebuffer(a5),a2
	add.w	watchptr(a5),a1
EWcopy	move.b	(a1)+,(a2)+
	tst.b	-1(a2)
	bne.s	EWcopy
AddWatchEnt	moveq	#0,d2
AWreedit	move.l	a4,a0
	bsr	PutAMessage
	bsr	EditLine
	bsr	ClearMessageLine
	tst.w	d0
	bne	MonitorLoop
	lea	linebuffer(a5),a0
	tst.b	(a0)
	beq.s	EWexit
	st	checking(a5)
	bsr	EvaluateWatch
	bne.s	EditError
	tst.b	delwatch(a5)
	beq.s	EWnodel
	bsr	DeleteWatch
EWnodel	lea	linebuffer(a5),a0
	moveq	#0,d1		Length of line including zero!
EWgetlen	addq	#1,d1
	tst.b	(a0)+
	bne.s	EWgetlen
	bsr	LengthWatch
	add.w	d1,d0
	cmp.w	#256,d0
	bcc.s	EditError2
	bsr	LengthWatch		d0 holds the length!
	lea	watchbuffer(a5),a1
	lea	linebuffer(a5),a0	A0 holds the line to insert
	lea	0(a1,d0.w),a2	A2 to hold very end of watch buffer
	add.w	watchptr(a5),a1	A1 holds current position in watch buffer
	lea	0(a2,d1.w),a3	A3 holds the new end of buffer
	clr.b	(a3)
	clr.b	1(a3)
	bra.s	EWmovent
EWmoveit	move.b	-(a2),-(a3)
EWmovent	cmp.l	a2,a1
	bne.s	EWmoveit
	bra.s	EWcopyent
EWcpy	move.b	(a0)+,(a1)+
EWcopyent	dbf	d1,EWcpy
EWexit	bsr	update_watch
	bra	MonitorLoop

EditError	bsr	flashscreen
	lea	linebuffer+1(a5),a1
	sub.l	a1,a0
	move.l	a0,d2
	bra	AWreedit
;	bsr	update_watch
;	bra	MonitorLoop
EditError2	lea	EditErrMsg(pc),a0
	bsr	PutAMessage
	bra	MonitorLoop
LengthWatch	moveq	#0,d0
	lea	watchbuffer(a5),a2
LWfindend	tst.b	(a2)		Is there no more?
	beq.s	LWfend2		Yes, skip
	addq	#1,a2		No, skip the zero
	addq	#1,d0
	bra.s	LWfindend
LWfend2	addq	#1,a2
	addq	#1,d0
	tst.b	(a2)		and find the end
	beq.s	LWatend
	bne.s	LWfindend		of the current message
	addq	#1,a2
	addq	#1,d0
	bra.s	LWfindend
LWatend	rts
;----------------------------------------------------------
DeleteAWatch
	bsr	DeleteWatch
	bsr	update_watch
	bra	MonitorLoop
;----------------------------------------------------------
DeleteWatch	movem.l	a0-a2/d0-d1,-(sp)
	lea	watchbuffer(a5),a0
	add.w	watchptr(a5),a0
	tst.b	(a0)		Must be at end!
	beq.s	DWexit
	move.l	a0,a1
DWfindnext	tst.b	(a1)+
	bne.s	DWfindnext
DWcopythem	tst.b	(a1)
	beq.s	DWdoneone
	move.b	(a1)+,(a0)+
	bra.s	DWcopythem
DWdoneone	move.b	(a1)+,(a0)+
	tst.b	(a1)
	bne.s	DWcopythem
	clr.b	(a0)+
DWexit	movem.l	(sp)+,a0-a2/d0-d1
	rts
;----------------------------------------------------------
ZoomWindow 	bsr	CalcBaseReg
	beq	ZoomDis
	move.l	(a0),a1
	lea	ZoomYTable(pc),a0
	move.l	a0,ytable(a5)
	bsr	ClearScreen
ZMLoop	moveq	#scrmax-3,d2
	moveq	#0,d3
	move.l	a1,-(sp)
ZMlp1	move.l	a1,a2
	move.w	d3,ypos(a5)
	clr.w	xpos(a5)
	move.l	a1,d0
	bsr	PrintHexLong
	moveq	#7,d1
ZMphw	ReadWordInc	d0
	bsr	PrintHexWord
	dbf	d1,ZMphw
	move.l	a2,a1
	moveq	#15,d1
ZMphb	ReadByteInc	d0
	bsr	PrintSpecChar
	dbf	d1,ZMphb
	addq	#1,d3		Next line
	dbf	d2,ZMlp1
	move.l	(sp)+,a1
	
ZMKey	bsr	GetKey
	and.w	#~ALT,d0
	cmp.w	#EndOfLine,d0
	beq.s	ZMnextpage
	cmp.w	#' ',d0
	beq.s	ZMnextpage
	cmp.w	#CTRL!DownArrow,d0
	beq.s	ZMnextpage
	cmp.w	#CTRL!UpArrow,d0
	beq.s	ZMprevpage
	cmp.w	#DownArrow,d0
	beq.s	ZMnextline
	cmp.w	#UpArrow,d0
	beq.s	ZMprevline
	cmp.w	#RightArrow,d0
	beq.s	ZMnextbyte
	cmp.w	#LeftArrow,d0
	beq.s	ZMprevbyte
	cmp.b	#Escape,d0
	beq.s	ZMend
	cmp.w	#CTRL!'C',d0
	bne.s	ZMKey
ZMend	bsr	DrawScreen1
	bra	MonitorLoop
ZMnextpage	add.w	#(scrmax-3)*16,a1
	bra	ZMLoop
ZMnextline	add.w	#16,a1
	bra	ZMLoop
ZMnextbyte	addq	#1,a1
	bra	ZMLoop
ZMprevline	sub.w	#16,a1
	bra	ZMLoop
ZMprevpage	sub.w	#(scrmax-3)*16,a1
	bra	ZMLoop
ZMprevbyte	subq	#1,a1
	bra	ZMLoop
	
ZoomDis	move.l	(a0),a1
	bsr	ClearScreen
	lea	ZoomYTable(pc),a0
	move.l	a0,ytable(a5)
ZoomLoop	moveq	#scrmax-3,d2
	moveq	#0,d1
	moveq	#20,d7
	move.l	a1,a2
	bsr	UDloop
	move.l	a1,a3
ZoomKey	bsr	GetKey
	and.w	#~ALT,d0
	cmp.w	#EndOfLine,d0
	beq.s	ZDnextpage
	cmp.w	#' ',d0
	beq.s	ZDnextpage
	cmp.w	#CTRL!DownArrow,d0
	beq.s	ZDnextpage
	cmp.w	#CTRL!UpArrow,d0
	beq.s	ZDprevpage
	cmp.w	#DownArrow,d0
	beq.s	ZDnextline
	cmp.w	#UpArrow,d0
	beq.s	ZDprevline
	cmp.w	#RightArrow,d0
	beq.s	ZDnextword
	cmp.w	#LeftArrow,d0
	beq.s	ZDprevword
	cmp.b	#Escape,d0
	beq.s	ZDend
	cmp.w	#CTRL!'C',d0
	bne.s	ZoomKey
ZDend	bsr	DrawScreen1
	bra	MonitorLoop
ZDnextpage	move.l	a3,a1
	bra.s	ZoomLoop
ZDnextline	move.l	a2,a1
	bsr	DisAssemble
	bra.s	ZoomLoop
ZDprevline	move.l	a2,a1
ZDeven	bsr.s	ZDevenup	
	bra.s	ZoomLoop	
ZDprevword	lea	-2(a2),a1
	bra.s	ZoomLoop
ZDnextword	lea	2(a2),a1
	bra.s	ZoomLoop
ZDprevpage	move.l	a2,a1
	sub.l	#scrmax*2,a1
	bra.s	ZDeven
ZDevenup	move.l	a1,d2
	lea	-2(a1),a3
	moveq	#4,d4
ZDevenloop	subq	#2,a1
	move.l	a1,a2
	bsr	DisAssemble
	move.l	a1,d0
	move.l	a2,a1
	tst.b	illegal(a5)
	bne.s	ZDnotok
	cmp.l	d2,d0
	bne.s	ZDnotok
	move.l	a1,a3
ZDnotok	dbf	d4,ZDevenloop
	move.l	d2,a1
	move.l	a3,a1
ZDexit	rts
;----------------------------------------------------------
SplitWindow	bsr	CalcBaseReg
	beq	SplDis
	move.b	#4,selectwin(a5)
	not.b	mem2active(a5)
	bne.s	SWexit1
	move.b	#2,selectwin(a5)
SWexit1	bsr	update_dump
SWexit	bsr	draw_box
	bsr	highlight_win
	bra	MonitorLoop
SplDis	move.b	#3,selectwin(a5)
	not.b	dis2active(a5)
	bne.s	SDexit2
	move.b	#1,selectwin(a5)
SDexit2	bsr	update_disassembly
	bra.s	SWexit
;----------------------------------------------------------
LockToRegister
	clr.l	d0
	move.b	selectwin(a5),d0
	subq.b	#1,d0
	bmi	MonitorLoop
	lea	LockMsg(pc),a0
	bsr	PutAMessage
	bsr	GetLine
	bne.s	LTRexit
	lea	linebuffer(a5),a0
	bsr	nexttoken
	moveq	#0,d2
	tst.w	token(a5)
	beq.s	LTRreset
	bsr	CopySymbol
	bne.s	LTRerror
	bsr	CheckMySymbols
	bne.s	LTRerror
	tst.w	d1		Cant have SR
	bne.s	LTRerror
	tst.w	token(a5)
	bne.s	LTRerror
LTRreset	clr.b	d0
	move.b	selectwin(a5),d0
	subq	#1,d0
	move.b	d2,dis1lock(a5,d0.w)
LTRexit	bsr	highlight_win
	bsr	update_disp1
	bra	ClearToLoop
LTRerror	bsr	flashscreen
Abort	bra	ClearToLoop
;----------------------------------------------------------

BinaryFile	lea	BinFileMsg(pc),a0
	bsr	PutAMessage
BFloop	bsr	GetCursoredKey
	bsr	UpperCase
	cmp.b	#Escape,d0
	beq	Abort
	cmp.w	#'L',d0	
	beq.s	BFload
	cmp.w	#'S',d0
	bne.s	BFloop
; Binary file save
	lea	BinSaveMsg(pc),a4
	st	singlestep(a5)
	bsr	BFgetparams

	move.w	#0,-(sp)
	move.l	a0,-(sp)
	move.w	#$3c,-(sp)		fcreate
	move.w	#$2300,sr
	trap	#1
	move.w	#$2700,sr
	addq	#8,sp
	move.w	d0,templong(a5)
	bmi	BFopenerr

	move.l	d4,-(sp)
	move.l	d5,-(sp)
	move.w	templong(a5),-(sp)
	move.w	#$40,-(sp)		fwrite
	move.w	#$2300,sr
	trap	#1
	move.w	#$2700,sr
	add	#12,sp
	tst.l	d0
	bmi	BFwriteerr
	bra.s	BFexitclose

BFload	lea	BinLoadMsg(pc),a4
	sf	singlestep(a5)
	bsr	BFgetparams


	move.w	#0,-(sp)
	move.l	a0,-(sp)
	move.w	#$3d,-(sp)		fopen
	move.w	#$2300,sr
	trap	#1
	move.w	#$2700,sr
	addq	#8,sp
	move.w	d0,templong(a5)
	bmi.s	BFopenerr
	
	
	move.l	d4,-(sp)
	move.l	#1048576,-(sp)
	move.w	templong(a5),-(sp)
	move.w	#$3f,-(sp)		fread
	move.w	#$2300,sr
	trap	#1
	move.w	#$2700,sr
	add	#12,sp
	tst.l	d0
	bmi.s	BFreaderr

BFexitclose	move.w	templong(a5),-(sp)
	move.w	#$3e,-(sp)		fclose
	move.w	#$2300,sr
	trap	#1
	move.w	#$2700,sr
	bsr	update_display
	bra	ClearToLoop
	
BFopenerr	lea	openerrmsg(pc),a0
	bsr	PutAMessage
	bra	MonitorLoop

BFreaderr	lea	readerrmsg(pc),a0
	bsr	PutAMessage
	bra.s	BFexitclose

BFwriteerr	lea	writeerrmsg(pc),a0
	bsr	PutAMessage
	bra.s	BFexitclose
EFLerror	lea	execerrmsg(pc),a0
	bsr	PutAMessage
	bra	MonitorLoop
ExecFileLoad
	lea	ExecLoadMsg(pc),a0
	bsr	PutAMessage
	bsr	GetLine
	bne	Abort

	lea	linebuffer(a5),a0
EFLdelspc	cmp.b	#32,(a0)
	bne.s	EFLdone
	addq	#1,a0
	bra.s	EFLdelspc
	
EFLdone	clr.l	-(sp)		;0
	move.l	a0,-(sp)		;0
	move.l	a0,-(sp)
	move.w	#3,-(sp)
	move.w	#$4b,-(sp)		p_exec
	move.w	#$2300,sr
	trap	#1
	move.w	#$2700,sr
	add	#16,sp
	tst.l	d0
	bmi	EFLerror
	move.l	d0,a0
	move.l	8(a0),textptr(a5)
	move.l	8(a0),RegPC(a5)
	move.l	16(a0),dataptr(a5)
	move.l	24(a0),bssptr(a5)

	move.l	$c(a0),d0
	add.l	$14(a0),d0
	add.l	$1c(a0),d0
	add.l	#$100,d0
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	clr.w	-(sp)
	move.w	#$4a,-(sp)
	trap	#1
	addq	#4,sp
	move.l	(sp)+,a0		;basepage start
	move.l	(sp)+,d0		;reserved length
	lea	0(a0,d0.l),a1	;new stack
	move.l	a0,-(a1)
	lea	EFLterm(pc),a0
	move.l	a0,-(a1)
	move.l	a1,RegSSP-4(a5)	
; gives problems whem programs are packed!
	bsr	update_disp1
	bra	ClearToLoop
EFLterm	trap	#15
;-----------------------------------------
BFgetparams	move.l	a4,a0		;get 2 or 3 parameters
	bsr	PutAMessage
	lea	otherbehand(pc),a0
	move.l	a0,intbehandle(a5)
	clr.b	linebuffer(a5)
	moveq	#0,d2
	move.w	xpos(a5),templong(a5)
BFLloop	move.w	templong(a5),xpos(a5)
	bsr	EditLine
	bne	Abort
	lea	linebuffer(a5),a0
	move.w	#32,token(a5)
	lea	fnbuffer(a5),a2
	moveq	#32,d1
BFLCloop	bsr	nexttoken
	cmp.b	#',',d0
	beq.s	BFLeofn
	move.b	d0,(a2)+
	dbf	d1,BFLCloop
	bra.s	BFLerror
BFLeofn	clr.b	(a2)
	bsr	EvalNoErr
	tst.b	NoError(a5)
	bne.s	BFLerror
	move.l	d0,d4
	tst.b	singlestep(a5)
	beq.s	BFLno3
	cmp.w	#',',token(a5)
	bne.s	BFLerror
	bsr	EvalNoErr
	tst.b	NoError(a5)
	bne.s	BFLerror
	move.l	d0,d5
BFLno3	tst.w	token(a5)
	bne.s	BFLerror
BFLexitok	lea	fnbuffer(a5),a0
	moveq	#0,d0
	rts	
BFLerror	bsr	flashscreen
	lea	linebuffer+1(a5),a1
	sub.l	a1,a0
	move.l	a0,d2
	bra	BFLloop

; get parameters for	read/write track

DmaGetPar4	bsr	PutAMessage
	lea	otherbehand(pc),a0
	move.l	a0,intbehandle(a5)
	clr.b	linebuffer(a5)
	moveq	#0,d2
	move.w	xpos(a5),templong(a5)
BFLloop2	move.w	templong(a5),xpos(a5)
	bsr	EditLine
	bne	Abort
	lea	linebuffer(a5),a0
	move.w	#32,token(a5)
	bsr	EvalNoErr
	tst.b	NoError(a5)
	bne.s	BFLerror2
	move.l	d0,a6		;adres
	cmp.w	#',',token(a5)
	bne.s	BFLerror2
	bsr	EvalNoErr
	tst.b	NoError(a5)
	bne.s	BFLerror2
	move.l	d0,d5		;track
	cmp.w	#',',token(a5)
	bne.s	BFLerror2
	bsr	EvalNoErr
	tst.b	NoError(a5)
	bne.s	BFLerror2
	move.l	d0,d4		;start sector
	cmp.w	#',',token(a5)
	bne.s	BFLerror2
	bsr	EvalNoErr
	tst.b	NoError(a5)
	bne.s	BFLerror2
	move.l	d0,d7		;number of sectors
	cmp.w	#',',token(a5)
	bne.s	BFLerror2
	bsr	EvalNoErr
	tst.b	NoError(a5)
	bne.s	BFLerror2		;side
	tst.w	token(a5)
	bne.s	BFLerror2
	
	move.l	d5,d1		;track
	move.l	d0,d2		;side
	subq.l	#1,d7		;-1 for dbf
	move.l	d4,d0		;sector start
	rts
		
BFLerror2	bsr	flashscreen
	lea	linebuffer+1(a5),a1
	sub.l	a1,a0
	move.l	a0,d2
	bra	BFLloop2	
	
********************************************************
* DMA DISK I/O stuff
*********************************************************

;cluster entry's on disk may NOT be fragmented
;no check on disk space, so be sure it fits!!

;----------------------------------------------------------
DmaFormatDisk:
	movem.l	d0-d7/a1-a6,-(a7)
	lea	foryn(pc),a0
	bsr	confirm
	lea	FormatMsg(pc),a0
	bsr	PutAMessage
	move.l	varptr\w,a4
	bsr	format
	tst.w	fdc(a4)
	bmi	WrptError		;only writeprotect checked
	bne	WriteError		;write sect err
	bra	FormFin		;all ok
	
;-------------------------------------

DmaReadBoot movem.l	d0-d7/a1-a6,-(a7)
	lea	booryn(pc),a4
	bsr	ReadExpression
	bne	Cancel
	move.l	d0,(a7)
	move.l	d0,a6
	move.l	varptr\w,a4
	clr.w	fdc(a4)
	moveq.l	#1,d0
	moveq	#0,d1
	moveq	#0,d2  
	bsr	Hread
	tst.w	fdc(a4)
	bne	ReadError
	move.l  	#$e0e0707,$ffff8800.w
	movem.l	(a7)+,d0-d7/a1-a6
	move.l	d0,-(a7)		;to boot adres!
	bsr	ClearMessageLine
	move.w	sr,-(a7)
	move.l	$bc,-(a7)		;enter monitor
	rts
;----------------------------------------------------
DmaWriteBoot
	movem.l	d0-d7/a1-a6,-(a7)
	lea	boowyn(pc),a4
	bsr	ReadExpression
	bne	Cancel
	move.l	d0,a6
	move.l	varptr\w,a4
	move.l	a6,a0
	clr.l	d0
	move.w	#$ff,d1
.loop15	add.w	(a0)+,d0
	dbf	d1,.loop15		;magic
	sub.w	#$1234,d0
	sub.w	d0,-2(a0)	
	tst.w	fdc(a4)
	moveq.l	#1,d0
	moveq	#0,d1
	moveq	#0,d2  
	bsr	HWrite
	tst.w	fdc(a4)
	bmi	WrptError	
	bne	WriteError
	bra	BootWritten
	
*--------------------------------------------------------------------------
;dma read files from disk a
;d4=place a0=filename

DmaReadFile:
	movem.l	d0-d7/a1-a6,-(a7)
	lea	DmaLParamsMsg(pc),a4
	sf	singlestep(a5)
	bsr	BFgetparams
	move.l	a0,a6
	lea	DmaReadMsg(pc),a0
	bsr	PutAMessage
	move.l	varptr\w,a4
        	lea	buffer(a4),a5
        	move.w	#DmaVar,d0
.loop3  	clr.l	(a5)+
        	dbf	d0,.loop3
        	move.l  	d4,buffer(a4)              ;place to read
        	move.l	a6,a0
        	bsr     	ConvertName
        	bsr     	GetCluster1
        	bmi   	FileNotF
        	tst.w	fdc(a4)
	bne	ReadError
        	bsr     	Rclust
	tst.w	fdc(a4)
	bne	ReadError
	lea	DmaReadFinMsg(pc),a0	;all ok
	bra	PM1

;----------------------------------------------------------
; d4=filestart a0=filename  d5=length

DmaWriteFile:
	movem.l	d0-d7/a1-a6,-(a7)
	lea	DmaWParamsMsg(pc),a4
	st	singlestep(a5)
	bsr	BFgetparams
	move.l	a0,a6
	lea	DmaWriteMsg(pc),a0
	bsr	PutAMessage	
	move.l	varptr\w,a4
        	lea	buffer(a4),a5
        	move.w	#DmaVar,d0	;init buffer
.loop   	clr.l	(a5)+
        	dbf	d0,.loop
        	move.l  	d4,buffer(a4)                 ;place
        	move.l	d5,len(a4)
        	move.l	a6,a0
        	bsr     	ConvertName		
        	bsr     	GetCluster
        	tst.w	fdc(a4)
	bmi	WrptError	
	bne	WriteError
	lea	FileWrittenMsg(pc),a0
	bra	PM1
;----------------------------------------
DmaReadTrack
	movem.l	d0-d7/a1-a6,-(a7)
	lea	TrackLoadMsg(pc),a0
	bsr	DmaGetPar4
	move.l	varptr\w,a4
trackl1	bsr	Hread
	tst.w	fdc(a4)
	bne	ReadError
	addq.w	#1,d0
	lea	$200(a6),a6
	dbf	d7,trackl1
	lea	SectLoaded(pc),a0
	bra	PM1
*--------------------------------------------------------------------------
DmaWriteTrack
	movem.l	d0-d7/a1-a6,-(a7)
	lea	TrackWriteMsg(pc),a0
	bsr	DmaGetPar4
	move.l	varptr\w,a4
trackl2	bsr	HWrite
        	tst.w	fdc(a4)
	bmi	WrptError	
	bne	WriteError	
	addq.w	#1,d0
	lea	$200(a6),a6
	dbf	d7,trackl2
	lea	SectWritten(pc),a0
	bra	PM1
	
*--------------------------------------------------------------------------

FileNotF	lea	FileNotFMsg(pc),a0
	bra.s	PM1
BootWritten	lea	BootwMsg(pc),a0
	bra.s	PM1
FormFin	lea	FormFinMsg(pc),a0
	bra.s	PM1
WrptError	lea	WrProtMsg(pc),a0
	bra.s	PM1
ReadError	lea	ReadErrorMsg(pc),a0
	bra.s	PM1	
WriteError	lea	WriteErrorMsg(pc),a0	

PM1	move.l	#$0e0e0707,$ffff8800.w
	movem.l	(a7)+,d0-d7/a1-a6
	bsr	PutAMessage	
	st	MsgLineClr(a5)
	bra	MonitorLoop
	
Cancel	movem.l	(a7)+,d0-d7/a1-a6
	bsr	ClearMessageLine
	bra	MonitorLoop
;----------------------------------------
SectLoaded		dc.b	'Sector(s) Loaded',0
SectWritten		dc.b	'Sector(s) Written',0
FileNotFMsg		dc.b	'File Not Found !',0
DmaReadMsg		dc.b	'Loading File...',0
DmaWriteMsg		dc.b	'Writing File...',0
DmaReadFinMsg	dc.b	'File is Loaded.',0
FileWrittenMsg	dc.b	'File is Saved.',0 
BootwMsg		dc.b	'Boot is Written.',0
ReadErrorMsg	dc.b	'Cannot Read Sector !',0
WriteErrorMsg	dc.b	'Cannot Write Sector !',0
foryn		dc.b	'Do you really want to Format [Y/N]',0
FormatMsg		dc.b	'Formatting in Progress...',0
FormFinMsg		dc.b	'Format Finished.',0
WrProtMsg		dc.b	'Disk is WriteProtected !',0
booryn		dc.b	'Read Bootsector to Adress >',0
boowyn		dc.b	'Write Bootsector from Adress >',0
		even


format	clr.w	fdc(a4)		;init error flag
	lea	clustbuf(a4),a0	;create track in buffer
	moveq	#8,d0		;gaps + datavelden maken
	moveq	#1,d3
	lea	7000(a0),a1
	move.b	#$4e,d7
	move.w	#59,d1
.loop17	move.b	d7,(a0)+	;140*$4e
	dbf	d1,.loop17
pl_1	moveq	#11,d1
.pl3	clr.b	(a0)+
	dbf	d1,.pl3
	move.b	#$f5,(a0)+	;3 syncbytes
	move.b	#$f5,(a0)+
	move.b	#$f5,(a0)+
	move.b	#$fe,(a0)+	;adresveld marker
	clr.b	(a0)+		;track
	clr.b	(a0)+		;side
	move.b	d3,(a0)+	;sector nr
	addq.b	#1,d3
	move.b	#2,(a0)+	;only lowest 3 bits datasize
	move.b	#$f7,(a0)+	;checksum
	moveq	#21,d1
.pl4	move.b	d7,(a0)+
	dbf	d1,.pl4
	moveq	#11,d1
.pl7	clr.b	(a0)+
	dbf	d1,.pl7
	move.b	#$f5,(a0)+
	move.b	#$f5,(a0)+
	move.b	#$f5,(a0)+
	move.b	#$fb,(a0)+
	move.w	#$1ff,d1
.pl5	clr.b	(a0)+
	dbf	d1,.pl5
	move.b	#$f7,(a0)+
	moveq	#39,d1
.pl8	move.b	d7,(a0)+
	dbf	d1,.pl8
	dbf	d0,pl_1
.pl6	move.b	d7,(a0)+
	cmp.l	a1,a0		;fill up the end
	ble.s	.pl6

	move.l	#$0e0e0505,$ffff8800.w	;drive select/set head to 0
	bsr	set_0
	moveq	#1,d6		;add
	clr.l	d7		;set track 0

;------ write sidea/b 80x ----------------

wr_loop	move.l	#$0e0e0505,$ffff8800.w
	bsr	wr_trk
	tst.w	fdc(a4)
	bmi	DiskError
	lea	clustbuf+$4c(a4),a0	;restore track nr in buf
	moveq	#8,d0
.fmt3a	move.b	#1,1(a0)		;set side 2 nr
	lea	$264(a0),a0
	dbf	d0,.fmt3a
	move.l	#$0e0e0404,$ffff8800.w
	bsr	wr_trk	
	tst.w	fdc(a4)
	bmi	DiskError
	lea	clustbuf+$4c(a4),a0
	moveq	#8,d0
.fmt3	clr.b	1(a0)		;clear side
	addq.b	#1,(a0)		;icrease track nr
	lea	$264(a0),a0
	dbf	d0,.fmt3		;9 sectors
	bsr	step_in
	addq.b	#1,d7
	cmpi.b	#$50,d7		;format until 80
	bne	wr_loop

;------ create bpb bootblock -------

	lea	clustbuf(a4),a6
	move.l	a6,a0
	move.l	a6,a1
	move.w	#$ff,d0		;clear boot
.loop16	clr.l	(a1)+
	dbf	d0,.loop16
	move.b	#$20,6(a0)
	move.l	#$02020100,12(a0)	;disk bpb ds/10/80
	move.l	#$027000a0,16(a0)
	move.l	#$05f90500,20(a0)
	move.l	#$09000200,24(a0)
	
	moveq	#1,d0			;boot
	moveq	#0,d1
	moveq	#0,d2		
	bsr	HWrite
	tst.w	fdc(a4)
	bne.s	DiskError	
	lea	$200(a6),a6		;fat1+2
	move.l	#$f7ffff00,(a6)
	moveq	#2,d0	
	moveq	#0,d1
	moveq	#0,d2		
	bsr	HWrite
	tst.w	fdc(a4)
	bne.s	DiskError	
	moveq	#7,d0	
	moveq	#0,d1
	moveq	#0,d2		
	bsr	HWrite
DiskError	rts

set_0	moveq	#3,d4		;set head to track 0
	bsr	wrfdc
	bra	wait3

step_in	move.w	#$80,$ffff8606.w ;command reg fdc
	moveq	#$53,d4		;step in 3 mil
	bsr	wrfdc
	bra	wait3

wr_trk	lea	clustbuf(a4),a2	;track buffer
	pea	(a2)
	move.b	3(a7),$ffff860D.w
	move.b	2(a7),$ffff860B.w
	move.b	1(a7),$ffff8609.w
	move.l	(a7)+,a2
	lea	7000(a2),a3	;end adres
	move.w	#$190,$ffff8606.w	;dma clear
	move.w	#$90,$ffff8606.w
	move.w	#$190,$ffff8606.w
	moveq.w	#14,d4			;lengte=14*512	
	bsr	wrfdc
	move.w	#$180,$ffff8606.w	;command reg select write
	move.w	#$f0,d4		;write track
	bsr	wrfdc
wait2	move.l	#$80000,d4	;timeout variable
.w_2	btst	#5,$fffffa01.w	;einde commando?
	beq.s	irq		;jep
	subq.l	#1,d4		;timeout counter-1		
	beq	irq		;timeout 
	clr.l	-(a7)
	move.b	$ffff8609.w,1(a7)	;read dma adres
	move.b	$ffff860b.w,2(a7)	;internal add on dma adres
	move.b	$ffff860d.w,3(a7)
	movea.l	(a7)+,a2
	cmp.l	a3,a2		;until write completed
	blt.s	.w_2
irq	move.w	$ffff8604.w,d0	;get fdc status
	move.w	#$80,$ffff8606.w	;kill last command
	move.w	#$d0,d4		;force irq
	bsr	wrfdc		;only with dma/read/write
.w_4	move.w	#$fa,d4
.w_3	dbf	d4,.w_3
	btst	#6,d0		;write prot?
	bne.s	.wrtpt
	clr.w	fdc(a4)		;ok
	rts
.wrtpt	move.w	#-1,fdc(a4)
	rts

wait3	move.l	#$40000,d4
.w_6	btst	#5,$fffffa01.w	;einde commando?
	beq.s	_rts
	subq.l	#1,d4		
	beq	force		;timeout 
	bra.s	.w_6

wrfdc	mulu	d6,d6
	move.w	d4,$ffff8604.w	;move in fdc
	mulu	d6,d6
_rts	rts	

;------ set filename capitols/spaces ------------

ConvertName:
	lea     	name_buf(a4),a1
        	moveq   	#$a,d5
.loop1  	move.b  	(a0)+,d0
        	beq.s   	.loop2
        	cmp.b	#':',d0	;if path given save a/b/c...
        	beq.s	.loop2
        	cmp.b   	#$2e,d0
        	beq.s   	.loop4
        	andi.b	#$df,d0
        	move.b  	d0,(a1)+
        	dbf     	d5,.loop1
        	rts
.loop2  	move.b  	#$20,(a1)+
      	dbf     	d5,.loop2
      	rts
.loop4	subq.w  	#3,d5
      	bmi.s   	.loop5
        	bsr.s   	.loop2
.loop5	moveq	#2,d1
.loop6	move.b  	(a0)+,d0
	andi.b	#$df,d0
	move.b	d0,(a1)+
	dbf	d1,.loop6
      	clr.b     	(a1)
	rts
      
; ------- read boot & setup disk bpb parameters ----

GetCluster:	lea	DmaBuffer(a4),a6
	moveq   	#1,d0 
	moveq	#0,d1
	moveq	#0,d2            
	bsr     	Hread              	;read boot
	tst.w	fdc(a4)
	bne	DiskError	
	clr.l	d0
	move.b  	22(a6),d0               ;sectors p fat
	move.b  	24(a6),sect_nm+1(a4)    ;sect p track
	move.b  	26(a6),sides+1(a4)      ;sides
	move.b	d0,fat_size+1(a4)
	addq.w	#1,d0			;bootcorrection
	ext.w	d0
	move.w	d0,fatstart(a4)
	subq.w	#1,d0	
	add.b     	d0,d0
	addq.b  	#1,d0
	move.b  	d0,fat_end+1(a4)
	moveq     	#0,d4
	move.b  	17(a6),d4         ;max aantal entry's in dir
	lsr.w   	#4,d4
	move.b  	d4,dir_size+1(a4)
	lea     	clust_st+1(a4),a5
	clr.b   	(a5)
	add.b   	d0,(a5)
	add.b   	d4,(a5)

;------- read directory & find 1st empty entry --------

	move.w  	d0,cur_dir(a4)
	bsr     	read              	;read dir
	tst.w	fdc(a4)
	bne	DiskError	
	move.w  	dir_size(a4),d7
	subq.w	#1,d7	  	;for dbf
dirnext	move.l  	a6,a5             	;dir buf
	moveq   	#$f,d6            	;max 16 files in 1 sector
dirtest	tst.l   	(a5)		
      	bne     	NextEnt

;------ found an empty one/set length in dir -----------	

	move.b	len+3(a4),$1c(a5)	;set length
	move.b	len+2(a4),$1d(a5)	;intel format
	move.b	len+1(a4),$1f(a5)
	move.b	len(a4),$1e(a5)
	move.l	len(a4),d1
	move.l	a5,len(a4)		;save start entry
	clr.l	d0
	divu	#$400,d1		;div by cluster size
	move.w	d1,d0
	swap	d1
	tst.w	d1		;remainder?
	beq.s	no_add
	addq.w	#1,d0		;number of clusters to write

no_add	move.w	d0,d5		
	lea	clustbuf(a4),a6	;get fat
	move.w   	fat_size(a4),d4
	bsr	_and3
	move.w	fatstart(a4),d0
Fatl3	bsr     	read  
	tst.w	fdc(a4)
	bne	DiskError
	lea	$200(a6),a6
	addq.w	#1,d0
	dbf	d4,Fatl3 
	
	lea	clustbuf-2(a4),a5	
	tst.w	2(a5)		;must start with fxffff
	beq	DiskError		;!!!!!!!!!!!!!
	lea	clustwbuf(a4),a3
	moveq	#0,d7		;start cluster point
	
;---- search for empty entry's ------------				

Fat1 	addq.l	#1,d7
	addq.l	#2,a5
	move.b  	(a5),d0
      	move.b  	1(a5),d1
      	andi.w  	#$ff,d0		;type 1
      	andi.w  	#$f,d1
      	lsl.w   	#8,d1
      	sf	d2		;type flag
      	add.w   	d1,d0
      	beq	EntryEnd
Fat2   	addq.l	#1,a5
   	addq.w	#1,d7		;my cluster count
  	move.b  	(a5),d0
      	move.b  	1(a5),d1	
      	rol.b   	#4,d0		;type2
      	andi.w  	#$f,d0
      	andi.w  	#$ff,d1
      	lsl.w   	#4,d1
     	st	d2
      	add.w   	d1,d0
      	bne     	Fat1
EntryEnd	move.w	d7,d6
	subq.w	#1,d6
	move.w	d6,(a3)+	;save for cluster write
 
;------ set/save directory entry only once -----
	
	tst.w	dirflag(a4)
	bne.s	_skip		
	move.l	len(a4),a0		;file entry
	move.w	d6,d0
	lsr	#8,d0
	andi.w	#$f,d0
	move.b	d6,$1a(a0)		;copy start cluster
	move.b	d0,$1b(a0)
	
	movem.l	d0-d2/a6,-(a7)
	movem.l 	name_buf(a4),d0-d2
	movem.l	d0-d2,(a0)
	move.w	cur_dir(a4),d0
	lea	DmaBuffer(a4),a6
	bsr	WriteSector
	not.w	dirflag(a4)
	movem.l	(a7)+,d0-d2/a6
	tst.w	fdc(a4)
	bne	DiskError

;----- move cluster numbers to fat -----
	
_skip	subq.w	#1,d5	;number of clusters left to write
	bmi.s	EndClust	;save all
	bne.s	End2
	move.w	#$ffff,d7	;last cluster in this file
End2	tst.b	d2
	bne.s	type2
type1	move.w	d7,d0		
	move.w	d0,d1
	lsr.w	#8,d1
	andi.w  	#$f,d1
	move.b	d0,(a5)
      	or.b	d1,1(a5)
      	bra	Fat2
type2	move.w	d7,d0
      	move.w	d0,d1
      	lsr.w	#4,d0
	lsl.w	#4,d1
	andi.w  	#$f0,d1
	or.b	d1,(a5)
      	move.b	d0,1(a5)
      	bra	Fat1
      	
_and3	cmpi.w	#3,d4
	ble.s	fl3
	subq.w	#1,d4	
	bra.s	_and3
fl3	subq.w	#1,d4	;for dbf
	rts
      	
	
;-------- write new fat table nr2 --------

EndClust:	lea	clustbuf(a4),a6	
	move.w   	fat_size(a4),d4
	bsr	_and3
	move.w	fatstart(a4),d0
Fatl4	bsr     	WriteSector 
	tst.w	fdc(a4)
	bne	DiskError
	lea	$200(a6),a6
	addq.w	#1,d0
	dbf	d4,Fatl4   
	 
;----- write fat table nr 1 -------	
	
	lea	clustbuf(a4),a6	
	move.w   	fat_size(a4),d4
	bsr	_and3
	move.w	fatstart(a4),d0
	sub.w	fat_size(a4),d0
Fatl5	bsr     	WriteSector 
	tst.w	fdc(a4)
	bne	DiskError
	lea	$200(a6),a6
	addq.w	#1,d0
	dbf	d4,Fatl5            

;------ write all file sectors to disk ------
	
	lea	clustwbuf(a4),a3	;cluster word tabel
Wrloop	move.w	(a3)+,d0
	bmi.s	WriteFin		; until $ffff
	move.l  	buffer(a4),a6           ;get place
	subq.w	#2,d0		;clust count starts with 2
	lsl.w   	#1,d0		;*2 for sector
	add.w	clust_st(a4),d0	;+dir+2*fat+boot
	bsr     	WriteSector
	tst.w	fdc(a4)
	bne	DiskError
	lea     	$200(a6),a6
	addq.w  	#1,d0
	bsr     	WriteSector
	tst.w	fdc(a4)
	bne	DiskError
	addi.l  	#$400,buffer(a4)                ;add cluster
	bra.s	Wrloop	

;------ dir search loop --------

NextEnt	lea     	32(a5),a5
	dbf     	d6,dirtest
	addq.w  	#1,cur_dir(a4)    ;next sector
	move.w	cur_dir(a4),d0
	lea	DmaBuffer(a4),a6
	bsr     	read              ;read next dir sector
	tst.w	fdc(a4)
	bne	DiskError
	dbf     	d7,dirnext
_err	moveq   #-1,d0	      ;error
      	rts

;----- end of routines all ok ----

WriteFin	
	moveq	#0,d0
	rts
      	

;----- write 1 sector uses bpb! ------ 
; in d0=sector number a6=transferadres

WriteSector:
      	movem.l d0-d5,-(a7)
      	moveq   #0,d1
      	moveq   #0,d2
      	moveq   #0,d3
      	moveq   #0,d4
      	moveq   #0,d5
      	move.w  sides(a4),d2
      	move.w  sect_nm(a4),d3	;sectors p/track
      	move.w  d0,d4
      	divu    d3,d4
      	move.w  d4,d5
      	divu    d2,d5
      	swap    d4
      	addq.w  #1,d4
      	move.w  d4,d0
      	move.w  d5,d1
      	swap    d5
      	move.w  d5,d2
      	bsr     HWrite
      	movem.l (a7)+,d0-d5
      	rts

;----- read 1 sector uses bpb! ------ 

read:	movem.l d0-d5,-(a7)
	moveq   #0,d1
      	moveq   #0,d2
      	moveq   #0,d3
      	moveq   #0,d4
      	moveq   #0,d5
      	move.w  sides(a4),d2		;convert sector nr to ..
      	move.w  sect_nm(a4),d3
      	move.w  d0,d4
      	divu    d3,d4
      	move.w  d4,d5
      	divu    d2,d5
      	swap    d4
      	addq.w  #1,d4
      	move.w  d4,d0
      	move.w  d5,d1
      	swap    d5
      	move.w  d5,d2
      	bsr.s   Hread
      	movem.l (a7)+,d0-d5
      	rts
      	
;------ select drive -------------------

sel_drv	move.l  #$e0e0505,$ffff8800.w	;side a
      	tst.w   d2
      	beq.s   .loop11
      	move.l  #$e0e0404,$ffff8800.w	;side b
.loop11	lea     $ffff8604.w,a0
      	lea     $ffff8606.w,a1
	rts

;------ dma seek/read sector -----------      	
      	
Hread: 	movem.l d4/d6/a0-a1,-(a7)
      	bsr.s   sel_drv
	move.w  #$84,(a1)
      	mulu    d6,d6
      	move.w  d0,(a0)
      	mulu    d6,d6
      	move.w  #$86,(a1)
      	mulu    d6,d6
      	move.w  d1,(a0)
      	mulu    d6,d6
      	move.w  #$80,(a1)
      	mulu    d6,d6
      	move.w  #$11,(a0)
      	mulu    d6,d6
      	move.l  #$80000,d4
.gpip:	subq.l  #1,d4
      	beq.s   force
      	btst    #5,$fffffa01.w
      	bne.s   .gpip
      	move.w  #$90,(a1)
      	move.w  #$190,(a1)
      	move.w  #$90,(a1)
      	mulu    d6,d6
      	move.w  #1,(a0)
      	move.l  a6,d4
      	move.b  d4,$ffff860d.w
      	lsr.l   #8,d4
      	move.b  d4,$ffff860b.w
      	lsr.l   #8,d4
      	move.b  d4,$ffff8609.w
	move.w  #$80,(a1)
      	mulu    d6,d6
      	move.w  #$80,(a0)
      	mulu    d6,d6
      	move.l  #$80000,d4
	bra     gpip4

;------------ timeout or other error ----------

force 	move.w    #$80,(a1)
      	mulu      d6,d6
      	move.w    #$d0,(a0)       ;force irq
      	move.w    #$250,d6
.loop9 	dbf       d6,.loop9
	move.w    #1,fdc(a4)
	movem.l (a7)+,d4/d6/a0-a1
      	rts

;---------- dma seek/write 1 sector ---------
     
HWrite 	movem.l d4/d6/a0-a1,-(a7)
      	bsr     sel_drv
	move.w  #$184,(a1)
      	mulu    d6,d6
      	move.w  d0,(a0)			;sector
      	mulu    d6,d6
      	move.w  #$186,(a1)
      	mulu    d6,d6
      	move.w  d1,(a0)			
      	mulu    d6,d6
      	move.w  #$180,(a1)
      	mulu    d6,d6
      	move.w  #$11,(a0)		
      	mulu    d6,d6
      	move.l  a6,d4
      	move.b  d4,$ffff860d.w
      	lsr.l   #8,d4
      	move.b  d4,$ffff860b.w
      	lsr.l   #8,d4
      	move.b  d4,$ffff8609.w
      	move.l  #$80000,d4
.gpip3	subq.l  #1,d4
      	beq     force		;timeout?
      	btst    #5,$fffffa01.w
      	bne.s   .gpip3
      	move.w  #$190,(a1)
      	move.w  #$90,(a1)
      	move.w  #$190,(a1)
      	mulu    d6,d6
      	mulu    d6,d6
      	move.w  #14,(a0)
      	move.w  #$180,(a1)
      	mulu    d6,d6
      	move.w  #$A0,(a0)		;write sector
      	mulu    d6,d6
     	move.l  #$80000,d4
gpip4	subq.l  #1,d4
      	beq     force
      	btst    #5,$fffffa01.w
      	bne.s   gpip4
	move.w  #$80,(a1)
      	move.w  (a0),d4
      	btst    #3,d4	;crc
      	bne     force
      	btst    #4,d4	;record not found
      	bne     force
      	clr.w   fdc(a4)
	movem.l (a7)+,d4/d6/a0-a1
	rts
	
;------ read 1st cluster/read fat/read rest of clusters --

Rclust:	move.w  cluster(a4),d0
      	move.w  #-1,cl_buf(a4)
.loop13	move.w  d0,cluster(a4)
      	cmp.w   #$fff,d0                  ;end of file?
      	beq     WriteFin
      	move.l  buffer(a4),a6                   ;get place
      	lsl.w   #1,d0
      	add.w   clust_st(a4),d0
      	subq.w  #4,d0
      	bsr     read	
      	tst.w   fdc(a4)
      	bne     _rts		
      	lea     512(a6),a6
      	addq.w  #1,d0
      	bsr     read
      	tst.w   fdc(a4)
      	bne     _rts
      	addi.l  #$400,buffer(a4)                
      	lea     DmaBuffer(a4),a6
      	bsr.s   .read1
      	tst.w   fdc(a4)
      	bne     _rts
      	bra.s   .loop13

.read1:	lea     512(a6),a3                ;setup end sector
      	move.w  cluster(a4),d0
      	move.w  cl_buf(a4),d1
      	move.w  d0,d2
      	lsr.w   #1,d0
      	lsl.w   #1,d0
      	sub.w   d0,d2
      	lsr.w   #1,d0
      	ext.l   d0
      	mulu    #3,d0
      	addi.w  #$200,d0
      	add.w   d2,d0
      	divu    #$200,d0
      	move.w  d0,cl_buf(a4)
      	move.w  d0,d3
      	cmp.w   d0,d1
      	beq.s   .loop12
      	bsr     read		;read fat
      	tst.w   fdc(a4)
      	bne     _rts
.loop12	clr.w   d0
      	lea     DmaBuffer(a4),a5
      	swap    d0
      	adda.w  d0,a5
      	move.w  cluster(a4),d0
      	divu    #2,d0
      	swap    d0
      	tst.w   d0
      	bne.s   xtype1
      	move.b  (a5)+,d0
      	cmpa.l  a3,a5
      	bne.s   atype1
      	addq.w  #1,d3
      	move.w  d0,-(a7)
      	move.w  d3,d0
      	bsr     read
      	move.w  (a7)+,d0
      	move.l  a6,a5
atype1:	move.b  (a5),d1
      	andi.w  #$ff,d0
      	andi.w  #$f,d1
      	lsl.w   #8,d1
      	add.w   d1,d0
      	rts
      	
xtype1:	move.b  (a5)+,d0
      	cmpa.l  a3,a5
      	bne.s   xtype2
      	addq.w  #1,d3
      	move.w  d0,-(a7)
      	move.w  d3,d0
      	bsr     read
      	move.w  (a7)+,d0
      	move.l  a6,a5
xtype2:	move.b  (a5),d1
      	rol.b   #4,d0
      	andi.w  #$f,d0
      	andi.w  #$ff,d1
      	lsl.w   #4,d1
      	add.w   d1,d0
      	rts

;-------- read boot/dir/get cluster start/get size -----------
; load dma files

GetCluster1 lea     DmaBuffer(a4),a6
      	moveq   #1,d0             	;sect
      	moveq   #0,d1
	moveq   #0,d2  
      	bsr     Hread              	;read boot
      	tst.w   fdc(a4)
      	bne     _rts
      	clr.l   d0
      	move.b  22(a6),d0               ;sectors p fat
      	move.b  24(a6),sect_nm+1(a4)    ;sect p track
      	move.b  26(a6),sides+1(a4)      ;sides
      	add.b   d0,d0
      	addq.b  #1,d0
      	move.b  d0,fat_end+1(a4)
      	moveq   #0,d4
      	move.b  17(a6),d4         	;aantal entry's in dir
      	lsr.w   #4,d4
      	move.b  d4,dir_size+1(a4)
      	lea     clust_st+1(a4),a5
      	clr.b   (a5)
      	add.b   d0,(a5)
      	add.b   d4,(a5)
      	move.w  d0,d3
      	bsr     read             ;read dir
      	tst.w   fdc(a4)
      	bne     _rts
   	move.w  dir_size(a4),d7
dirnext1  	move.l  a6,a5             ;dir buf
	moveq   #$f,d6            ;check dir for files
.loop5	bsr.s   CheckDir
      	beq.s   dfound            ;found
      	bmi.s   Edir
      	lea     32(a5),a5         ;next
      	dbf     d6,.loop5
      	addq.w  #1,d3             ;next sector
      	move.w  d3,d0
      	bsr     read              ;read next dir sector
      	tst.w   fdc(a4)
      	bne     _rts
      	dbf     d7,dirnext1
Edir	moveq   #-1,d0
      	rts
      	
dfound:	moveq   #0,d1
	move.b  27(a5),d1         ;get cluster start
      	move.b  26(a5),d0
      	lsl.w   #8,d1
      	add.w   d1,d0
      	move.w  d0,cluster(a4)
      	moveq  #0,d0
      	rts
;----------------------------
CheckDir:
	movem.l d1-d5,-(a7)               ;
      	movem.l (a5),d0-d2
      	tst.l   d0
      	beq.s   .E_ent
	clr.b   d2                        ;no folder attribut
	movem.l name_buf(a4),d3-d5
      	bne.s   .N_fnd
      	cmp.l   d1,d4
      	bne.s   .N_fnd
      	cmp.l   d2,d5
      	bne.s   .N_fnd
      	moveq   #0,d0             ;found
.lxx   	movem.l (a7)+,d1-d5
      	rts
.N_fnd:	moveq   #1,d0             ;not equal
      	bra.s     .lxx
.E_ent:	moveq   #-1,d0            ;end entry
      	bra.s     .lxx


;----------------------------------------------------------
BreakPointHere
	bsr	CalcBaseReg
	bne	MonitorLoop
	move.l	(a0),a0
BPHenter	bsr.s	FindBreak
	beq.s	BPHclear
	move.w	(a0),d0
	move.w	#brkptinstr,(a0)
	cmp.w	#brkptinstr,(a0)
	bne.s	BPHerror
	move.w	d0,(a0)
	move.l	a0,(a1)
	lea	BPHmsg1(pc),a0
	bra.s	BPHexit
BPHclear	moveq	#-1,d0
	move.l	d0,-(a1)
	lea	BPHmsg2(pc),a0
BPHexit	bsr	PutAMessage
	lea	normbehandle(pc),a0
	move.l	a0,intbehandle(a5)
	bsr	update_display
	bra	MonitorLoop
BPHerror	move.w	d0,(a0)
	lea	BPHerrmsg(pc),a0
	bsr	PutAMessage
	bra	MonitorLoop

FindBreak	lea	otherbehand(pc),a1
	move.l	a1,intbehandle(a5)
	lea	breakpts(a5),a1
	lea	breakcont(a5),a2
	moveq	#3,d0		
Fbcsop	cmp.l	(a1)+,a0
	beq.s	FBfoundone
	addq	#1,a2
	dbf	d0,Fbcsop
	lea	breakpts(a5),a1
	lea	breakcont(a5),a2
	moveq	#3,d0		
FBgetempty	tst.b	(a1)
	bmi.s	FBfoundempt
	addq	#4,a1
	addq	#2,a2
	dbf	d0,FBgetempty
	lea	NoMoreBrks(pc),a0
	bra.s	BPHexit
FBfoundempt	moveq	#1,d0
FBfoundone	rts
SetBreakPoint
	lea	SetBreakMsg(pc),a4
	bsr	ReadExpression
	bne	MonitorLoop
	move.l	d0,a0
	bra	BPHenter
;----------------------------------------------------------
GetKey	movem.l	a0/d1,-(sp)
GKloop	bsr	ReadKeyPress
	cmp.b	#$f6,d0
	bcs.s	GKno
	bsr	ReadKeyPress
	bsr	ReadKeyPress
	bra.s	GKloop
	
GKno	cmp.b	#CTRLmake,d0
	beq	ITSctrlmake
	cmp.b	#CTRLmake+$80,d0
	beq	ITSctrlbrk
	cmp.b	#ALTmake,d0
	beq	ITSaltmake
	cmp.b	#ALTmake+$80,d0
	beq	ITSaltbrk
	cmp.b	#CAPSmake,d0
	beq	ITScaps
	cmp.b	#LEFTshift,d0
	beq	ITSshftmake
	cmp.b	#RIGHTshift,d0
	beq	ITSshftmake
	cmp.b	#LEFTshift+$80,d0
	beq	ITSshftbrk
	cmp.b	#RIGHTshift+$80,d0
	beq	ITSshftbrk
	btst	#7,d0
	bne.s	GKloop
	and.w	#$7f,d0
	lea	SCnorm(pc),a0
	btst.b	#CAPSBIT,kbdstatus(a5)
	bne.s	KPcaps
	btst.b	#SHIFTBIT,kbdstatus(a5)
	beq.s	KPskip
KPcaps	lea	SCshift(pc),a0
KPskip	move.b	kbdstatus(a5),d1
	lsl	#8,d1
	and.w	#ALT!CTRL,d1
	move.b	0(a0,d0.w),d1
	move.w	d1,d0
	cmp.w	#127,d0
	bcs.s	KPdontup
	bsr	UpperCase
;	movem.l	d0-d7/a0-a6,-(sp)	;KBD VALUES TO SCREEN
;	clr.w	xpos(a5)		
;	clr.w	ypos(a5)		
;	bsr	PrintHexLong	
;	movem.l	(sp)+,d0-d7/a0-a6	
KPdontup	movem.l	(sp)+,a0/d1
	bclr	#6,$fffffa0f.w
	rts
ReadKeyPress
KPlp1	moveq	#0,d0
	move.w	repeatdel(a5),d1
KPloop	move.b	kbdacia\w,d0
	btst	#7,d0
	bne.s	KPgotone
KPnoint	dbf	d1,KPloop
	move.w	#shortdelay,repeatdel(a5)
	move.b	prevchar(a5),d0
	beq.s	KPlp1
	bra.s	KPok
KPgotone	btst	#0,d0
	bne.s	KPdone
	move.b	kbdacia+2\w,d0
	bra.s	KPlp1
KPdone	move.b	kbdacia+2\w,d0	; Key press
	bclr	#6,$fffffa11.w
	move.b	d0,prevchar(a5)
	move.w	#longdelay,repeatdel(a5)
	btst	#7,d0
	beq.s	KPok
	clr.b	prevchar(a5)
KPok	rts

	
ITScaps	bchg.b	#CAPSBIT,kbdstatus(a5)
	bra	GKloop
ITSctrlmake	bset.b	#CTRLBIT,kbdstatus(a5)
	bra	GKloop
ITSctrlbrk	bclr.b	#CTRLBIT,kbdstatus(a5)
	bra	GKloop
ITSaltmake	bset.b	#ALTBIT,kbdstatus(a5)
	bra	GKloop
ITSaltbrk	bclr.b	#ALTBIT,kbdstatus(a5)
	bra	GKloop
ITSshftmake	bset.b	#SHIFTBIT,kbdstatus(a5)
	bra	GKloop
ITSshftbrk	bclr.b	#SHIFTBIT,kbdstatus(a5)
	bra	GKloop

; returns Z=1 if no key; Z=0 otherwise
CheckKeypress
	move.b	kbdacia\w,d0
	btst	#7,d0
	beq.s	CKexit
	bsr	KPdone
	tst.b	d0
CKexit	rts	
;----------------------------------------------------------
UpperCase	cmp.b	#'a',d0
	bcs.s	NoUpper
	cmp.b	#'z',d0
	bhi.s	NoUpper
	sub.b	#32,d0
NoUpper	rts
;----------------------------------------------------------
ReadExpression
	moveq	#0,d2
	clr.b	linebuffer(a5)
REloop	move.l	a4,a0
	bsr	PutAMessage
	bsr	EditLine
	bne.s	ExitReadExp
	lea	linebuffer(a5),a0
	bsr	Evaluate
	beq.s	ExitOk
	lea	linebuffer+1(a5),a1
	sub.l	a1,a0
	move.l	a0,d2
	bra.s	REloop
ExitOk	bsr	ClearMessageLine
	or.w	#4,sr		Set Z
	rts
ExitReadExp	bsr	ClearMessageLine
	and.w	#$fffb,sr		Clear Z
	rts
;----------------------------------------------------------
Evaluate	move.l	sp,errorstack(a5)
	sf	InWatch(a5)
	sf	NoError(a5)
	move.w	#10,token(a5)
	bsr	nexttoken
	bsr	EVALexpr
	tst.w	token(a5)
	bne	EVALerror
	rts
EvalNoErr	move.l	sp,errorstack(a5)
	sf	NoError(a5)
	st	InWatch(a5)
	move.w	#10,token(a5)
	bsr	nexttoken
	bsr	EVALexpr
	rts
;
; <expr>	::=	<term> {<+ or - or ~> <term>}*
;
EVALexpr	move.l	d3,-(sp)		local v1,v2
	bsr	EVALterm
	move.l	d0,d3		v1=term()
EEloop	cmp.w	#'+',token(a5)
	beq.s	EEhaveplus
	cmp.w	#'-',token(a5)
	beq.s	EEhaveminus
	move.l	d3,d0
	move.l	(sp)+,d3
	rts
EEhaveplus	bsr	nexttoken
	bsr	EVALterm
	add.l	d0,d3
	bra.s	EEloop
EEhaveminus	bsr	nexttoken
	bsr	EVALterm
	sub.l	d0,d3
	bra.s	EEloop
;
; <term>	::=	<fact> {<* or /> <fact>}*
;
EVALterm	move.l	d3,-(sp)		local v1,v2
	bsr	EVALfact
	move.l	d0,d3		v1=term()
ETloop	cmp.w	#'*',token(a5)
	beq.s	EThavetimes
	cmp.w	#'/',token(a5)
	beq.s	EThavedivide
	move.l	d3,d0
	move.l	(sp)+,d3
	rts
EThavetimes	bsr	nexttoken
	bsr	EVALfact
	movem.l	d1/d2/d4,-(sp)
	moveq	#31,d4
	moveq	#0,d2		result
ETmulloop	lsl.l	#1,d2
	lsl.l	#1,d0
	bcc.s	ETnoadd
	add.l	d3,d2
ETnoadd	dbf	d4,ETmulloop
	move.l	d2,d3
	movem.l	(sp)+,d1/d2/d4
	bra.s	ETloop
	dc.w	$4afb
EThavedivide
	bsr	nexttoken
	bsr	EVALfact
; divide 32 by 32
;	movem.l	d1/d2/d4,-(sp)
;	moveq	#31,d4
;	moveq	#0,d2
;ETdivloop	lsr.l	#1,d0
;	bcc.s	ETnodiv
;	add.l	d3,d2
;ETnodiv	lsr.l	#1,d3
;	dbf	d4,ETdivloop
;	move.l	d2,d3
;	movem.l	(sp)+,d1/d2/d4
	tst.w	d0
	beq.s	ETitszero
	divu	d0,d3
	and.l	#$7fff,d3
	bra.s	ETloop
ETitszero	moveq	#0,d3
	bra.s	ETloop
;
; <fact>	::=	<item> {<& or ! or ^> <item>}*
;
EVALfact	move.l	d3,-(sp)		local v1,v2
	bsr	EVALitem
	move.l	d0,d3		v1=term()
EFloop	cmp.w	#'&',token(a5)
	beq.s	EFhaveand
	cmp.w	#'!',token(a5)
	beq.s	EFhaveor
	cmp.w	#'^',token(a5)
	beq.s	EFhaveeor
	cmp.w	#'>',token(a5)
	beq.s	EFhaveshr
	cmp.w	#'<',token(a5)
	beq.s	EFhaveshl
	move.l	d3,d0
	move.l	(sp)+,d3
	rts
EFhaveand	bsr	nexttoken
	bsr	EVALitem
	and.l	d0,d3
	bra.s	EFloop
EFhaveor	bsr	nexttoken
	bsr	EVALitem
	or.l	d0,d3
	bra.s	EFloop
EFhaveeor	bsr	nexttoken
	bsr	EVALitem
	eor.l	d0,d3
	bra.s	EFloop
EFhaveshr	bsr	nexttoken
	cmp.w	#'>',d0
	bne	EVALerror
	bsr	nexttoken
	bsr	EVALitem
	lsr.l	d0,d3
	bra.s	EFloop
EFhaveshl	bsr	nexttoken
	cmp.w	#'<',d0
	bne	EVALerror
	bsr	nexttoken
	bsr	EVALitem
	lsl.l	d0,d3
	bra	EFloop

;
; <item>	::= "[" <expr> "]" | "("<expr>")" | "~"<item>|<dec>
;	    |"$"<dec-digit><hex-number>
;
EVALitem	cmp.w	#$28,token(a5)	;(
	bne.s	EInotbrexp
	bsr	nexttoken
	bsr	EVALexpr
	cmp.w	#')',token(a5)
	bne	EVALerror
	move.l	d0,-(sp)
	bsr	nexttoken
	move.l	(sp)+,d0
	rts
EInotbrexp	
	cmp.w	#'[',token(a5)
	bne.s	EInotcurexp
	bsr	nexttoken
	bsr	EVALexpr
	cmp.w	#']',token(a5)
	bne	EVALerror
	move.l	a1,-(sp)
	move.l	d0,a1
	bsr	nexttoken
	moveq	#'L',d1
	cmp.w	#'.',token(a5)
	bne.s	EInosize
	bsr	nexttoken
	move.w	token(a5),d0
	bsr	UpperCase
	move.w	d0,d1
	bsr	nexttoken
EInosize	cmp.w	#'B',d1
	beq.s	EIsizebyte
	cmp.w	#'W',d1
	beq.s	EIsizeword
	cmp.w	#'L',d1
	beq.s	EIsizelong
	bra	EVALerror
EIsizebyte	ReadByteInc	d0
	move.l	(sp)+,a1
	rts
EIsizeword	ReadWordInc	d0
	move.l	(sp)+,a1
	rts
EIsizelong	ReadLongInc	d0
	move.l	(sp)+,a1
	rts
EInotcurexp	cmp.w	#'~',token(a5)
	bne.s	EInotnot
	bsr	nexttoken
	bsr	EVALitem
	not.l	d0
	rts
EInotnot	cmp.w	#'$',token(a5)	
	beq	EIhexnumb2
	cmp.w	#'%',token(a5)
	beq	EIbinnumber
	cmp.w	#'+',token(a5)
	beq	EIexitnow
	cmp.w	#'-',token(a5)
	beq	EIexitnow
	cmp.w	#'\',token(a5)	
	beq	EIdecnumber
	move.w	token(a5),d0	
	bsr	UpperCase
	cmp.B	#'A',d0		;adres reg?
	beq.s	ARegs
	cmp.w	#'D',d0		;data reg?
	beq.s	ARegs		;yep
	BRA.S	NoRegs
ARegs	cmpi.b	#'0',1(a0)
	blt.s	regs2
	move.b	(a0),d0
	sub.b	#'0',d0		;make hex
	andi.b	#$f8,d0		;0-7?
	beq.s	regs2
	move.w	token(a5),d0	
	bra.s	NoRegs
	
regs2	move.w	token(a5),d0	
	bra	EVALsymbol
	
NoRegs	move.w	token(a5),d0	
	cmp.b	#'S',1(a0)		;bss
	beq	EVALsymbol
	cmp.b	#'s',1(a0)		;bss
	beq	EVALsymbol
	cmp.b	#'T',1(a0)		;data
	beq	EVALsymbol
	cmp.b	#'t',1(a0)		;data
	beq	EVALsymbol
	cmp.b	#'P',(a0)
	beq	EVALsymbol
	cmp.b	#'p',(a0)
	beq	EVALsymbol
	bra	EIhexnumb3
	
EIhexnumb2	bsr	nexttoken		
	move.w	token(a5),d0	
EIhexnumb3	bsr	UpperCase		
	cmp.w	#'0',d0		
	bcs	EVALsymbol		
	cmp.w	#'9',d0		
	bls.s	EIhexnumber		
	cmp.w	#'A',d0		
	bcs	EVALsymbol		
	cmp.w	#'F',d0		
	bhi	EVALsymbol		
	bra	EIhexnumber
	
	
EIdecnumber	bsr	nexttoken	
	cmp.w	#'0',token(a5)
	bcs	EVALsymbol
	cmp.w	#'9',token(a5)
	bhi	EVALsymbol
	move.l	d3,-(sp)
	moveq	#0,d3
	move.w	token(a5),d3	
	sub.w	#'0',d3
EIgetnumloop
	bsr	nexttoken
	move.w	token(a5),d0
	sub.w	#'0',d0
	bcs.s	EIfinito
	cmp.w	#10,d0
	bcc.s	EIfinito
	add.l	d3,d3
	move.l	d3,-(sp)
	lsl.l	#2,d3
	add.l	(sp)+,d3
	add.l	d0,d3
	bra.s	EIgetnumloop
EIfinito	move.l	d3,d0
	move.l	(sp)+,d3
	rts
EIexitnow	clr.l	d0
	rts
EIhexnumber	bsr	hexdigit2		
	bne         EVALerror
	move.l	d3,-(sp)
	moveq	#0,d3
	move.w	d0,d3
EIhexloop	bsr	hexdigit
	bne.s	EIexit
	lsl.l	#4,d3
	add.l	d0,d3
	bra.s	EIhexloop
EIexit	move.l	d3,d0
	move.l	(sp)+,d3
	rts
EIbinnumber	clr.l	d0
	bsr	nexttoken
	sub.w	#'0',d0
	bcs	EVALerror
	cmp.w	#1,d0
	bhi	EVALerror
	move.l	d3,-(sp)
	move.l	d0,d3
EIbinloop	bsr	nexttoken
	sub.w	#'0',d0
	bcs.s	EIexit
	cmp.w	#1,d0
	bhi.s	EIexit
	lsl.l	#1,d3
	add.l	d0,d3
	bra.s	EIbinloop
hexdigit	moveq	#0,d0
	bsr	nexttoken		;if dec
hexdigit2	move.w	token(a5),d0	;weg
	bsr	UpperCase
	cmp.w	#'0',d0
	bcs.s	EIerror
	cmp.w	#'9',d0
	bls.s	EIexitok
	cmp.w	#'A',d0
	bcs.s	EIerror
	cmp.w	#'F',d0
	bhi.s	EIerror
	subq	#7,d0		; hex letter!
EIexitok	sub.w	#'0',d0
	or.w	#4,sr		Set Z
	rts
EIerror	moveq	#1,d0
	rts

;
; Here we must have a symbol. First collect it into the symbol buffer
; and search the primary (mine) symbol table. If not there, search the
; linker symbol table.
;
EVALsymbol
	movem.l	a1-a3/d1-d3,-(sp)
	bsr	CopySymbol
; Here we have a symbol in the symbol table. Now we scan it.
	bsr	CheckMySymbols
	beq.s	ESFoundIt
	bsr	CheckSymbolTable
	bne	EVALerror
	move.l	8(a1),d0
	bra.s	ESFinito
; Found one of the internal symbols. Now check to see if we have
; .B .W or .L following. Default being .L
ESFoundIt	moveq	#'L',d2
	cmp.w	#'.',token(a5)
	bne.s	ESFIok
	bsr	nexttoken
	move.w	token(a5),d0
	bsr	UpperCase
	move.w	d0,d2
	bsr	nexttoken
ESFIok	tst.w	d1
	beq.s	ESNotSR
	subq	#2,a1 
	cmp.w	#'L',d2
	bne.s	ESNotSR
	moveq	#'W',d2
ESNotSR	ReadLongInc	d0
	cmp.w	#'L',d2
	beq.s	ESFinito
	and.l	#$ffff,d0
	cmp.w	#'W',d2
	beq.s	ESFinito
	and.w	#$ff,d0
	cmp.w	#'B',d2
	bne	EVALerror
ESFinito	movem.l	(sp)+,a1-a3/d1-d3
	rts
; Valid only if char is '0'..'9'; 'A'..'Z'; 'a'..'z'; '_'
EVALchar	move.w	token(a5),d0
;	btst	#CaseSense,flags(a5)
;	beq.s	ECNoCS
	bsr	UpperCase
ECNoCS	cmp.w	#'0',d0
	bcs.s	ECCharInv
	cmp.w	#'9',d0
	bls.s	ECCharOk
	cmp.w	#'_',d0
	beq.s	ECCharOk
	cmp.w	#'A',d0
	bcs.s	ECCharInv
	cmp.w	#'Z',d0
	bls.s	ECCharOk
	cmp.w	#'a',d0
	bcs.s	ECCharInv
	cmp.w	#'z',d0
	bhi.s	ECCharInv
ECCharOk	moveq	#1,d1
	rts
ECCharInv	moveq	#0,d1
	rts
CopySymbol	lea	symbuffer(a5),a1
	moveq	#7,d2		Maximum of 8 characters
	bsr	EVALchar
	beq	EVALerror
CSloop	move.b	d0,(a1)+
	bsr	nexttoken
	bsr	EVALchar		Next Char to do
	beq.s	CSdone		Invalid ?
	dbf	d2,CSloop
CSdone	clr.b	(a1)+
	rts
; This checks to see if the symbol in the symbuffer is in the
; internal symbol table. If so, it returns its address with Z flag
; set, otherwise Z will be reset. D1 will be Non zero if the size
; is not LONG. A1 points to the symbol value
CheckMySymbols
	lea	MySymbols(pc),a2
	lea	MySymOfs(pc),a1
	moveq	#1,d2
CMSloop	tst.b	(a2)
	beq.s	CMSSymNotFound
	moveq	#7,d1
	lea	symbuffer(a5),a3
CMSloop2	tst.b	(a2)
	beq.s	CMSFoundSym
CMSNotFndSym
	cmp.b	(a3)+,(a2)+
	bne.s	CMSnotthis
	dbf	d1,CMSloop2
CMSFoundSym	tst.b	(a3)
	bne.s	CMSnotthis
	move.w	(a1),d1
	move.w	d1,d0
	and.w	#$7fff,d0
	move.l	a5,a1
	add.w	d0,a1
	and.w	#$8000,d1
	moveq	#0,d0
	rts
CMSnotthis	tst.b	(a2)+
	bne.s	CMSnotthis
	addq	#2,a1
	addq	#1,d2
	bra.s	CMSloop
CMSSymNotFound
	moveq	#1,d0
	rts
CheckSymbolTable
	move.l	symtable(a5),d0
	and.l	#$fffffe,d0
	move.l	d0,a2
	beq	CSTnosym
CSTloop	move.l	a2,a1
	tst.b	(a2)
	beq.s	CSTnosym
	bmi.s	CSTnosym
	lea	symbuffer(a5),a3
	moveq	#7,d1
CSTlp2	move.b	(a2)+,d0
	beq.s	CSTeos
	bsr	UpperCase
	cmp.b	(a3)+,d0
	bne.s	CSTgtnxt
	dbf	d1,CSTlp2
	bra.s	CSTeos
CSTgtnxt	lea	12(a1),a2
	bra.s	CSTloop	
CSTeos	tst.b	(a3)
	bne.s	CSTgtnxt
;	lea	8(a1),a1
	moveq	#0,d0		Found it!
	rts
CSTnosym	move.l	a2,a1
	moveq	#1,d0
	rts
; On exit a0 points to required symbol.
; BEQ if not found; BNE if found
FindSymValue
	move.l	a2,-(sp)
	move.l	d1,-(sp)
	move.l	varptr\w,a2
	move.l	symtable(a2),d1
	and.l	#$fffffe,d1
	beq.s	FSVnosym
	move.l	d1,a2
FSVloop	move.l	a2,a0
	tst.b	(a2)
	beq.s	FSVnosym
FSVgtnxt	lea	8(a2),a2
	cmp.l	(a2)+,d0
	bne.s	FSVloop
	move.l	(sp)+,d1
	move.l	(sp)+,a2
	moveq	#0,d2		;!!!! movem.l!!!!
	rts
FSVnosym	move.l	(sp)+,d1
	move.l	(sp)+,a2
	moveq	#1,d2
	rts
AddASym	movem.l	a0/a2/d2/d0,-(sp)
	bsr	FindSymValue
	bne.s	AASexit
	lea	linebuffer+9(a5),a2
	moveq	#7,d0
AASloop	move.b	(a0)+,d2
	beq.s	AASexit
	move.b	d2,(a2)+
	dbf	d0,AASloop
AASexit	movem.l	(sp)+,a0/a2/d2/d0
	rts
;---------------------------------------------------------------------
nexttoken	tst.w	token(a5)
	beq.s	NTeof
	moveq	#0,d0
	move.b	(a0)+,d0
	move.w	d0,token(a5)
	cmp.w	#32,d0		;space
	beq.s	nexttoken
NTeof	rts

EVALerror	move.l	errorstack(a5),sp
	st	NoError(a5)
	tst.b	InWatch(a5)
	bne.s	EEexit
	bsr	flashscreen
EEexit	clr.w	token(a5)
	and.w	#$fffb,sr		Return Z=0
	rts	
flashscreen	move.l	a0,-(sp)
	lea	$ffff8240.w,a0
	not.w	(a0)
	move.w	#12900,d1
FSloop	dbf	d1,FSloop
	not.w	(a0)
	move.l	(sp)+,a0
	rts
;---------------------------------------------------------------------
GetCursoredKey
	bsr	PutCursor
	bsr	GetKey
	bra	PutCursor
;---------------------------------------------------------------------
GetLine	clr.b	linebuffer(a5)
	moveq	#0,d2
EditLine	move.w	#32,token(a5)
	lea	linebuffer(a5),a3
	move.l	a3,a0
	moveq	#0,d3		D3 holds the length of the line
	tst.w	d2		If d2=0, then point to start of
	bne.s	GLlength		line.
	move.w	d3,d2		d2 holds position
GLlength	tst.b	(a0)+
	beq.s	GLendofline
	addq	#1,d3
	bra.s	GLlength
GLendofline	move.w	xpos(a5),templong(a5)
GLloop	lea	linebuffer(a5),a0
	move.w	templong(a5),xpos(a5)
	move.w	#messagey,ypos(a5)
	bsr	printmessage
	move.w	xpos(a5),templong+2(a5)
	move.w	#'G'+128,d0
	bsr	PrintChar
	move.w	d2,d0
	add.w	templong(a5),d0
	move.w	d0,xpos(a5)
	bsr	GetCursoredKey	Get a key press
	cmp.b	#Escape,d0		Was it escape?
	beq	GLaborted		Yes, command aborted
	cmp.w	#CTRL!'C',d0	CTRL-C?
	beq	GLaborted		Yes, abort it!
	cmp.w	#EndOfLine,d0	Was it return?
	beq.s	GLexit		Yes, line complete
	cmp.w	#8,d0		Was it delete?
	beq.s	GLdelete
	cmp.w	#127,d0		Delete forward?
	beq	GLdelfwd
	cmp.w	#CTRL!'X',d0	CTRL-X?, delete line
	beq	GLdelline
	cmp.w	#LeftArrow,d0
	beq	GLback
	cmp.w	#RightArrow,d0
	beq	GLforward
	cmp.w	#CTRL!LeftArrow,d0
	beq	GLbol
	cmp.w	#CTRL!RightArrow,d0
	beq	GLeol
	cmp.w	#32,d0		Non printable?
	bcs	GLloop		Yes, forget this char
	cmp.w	#127,d0		> 128, skip
	bcc	GLloop
	cmp.w	#78,templong+2(a5)	Space to insert more?
	bcc	GLloop		Nope, go back
	lea	0(a3,d3.w),a0	End of buffer
	lea	0(a3,d2.w),a1	Position in buffer!
GLinsert	cmp.l	a1,a0
	bcs.s	GLinsend
	move.b	(a0),1(a0)
	subq	#1,a0
	bra.s	GLinsert	
GLinsend	move.b	d0,0(a3,d2.w)	Put char in buffer
	addq	#1,d2		One less char to get
	addq	#1,d3
	clr.b	0(a3,d3.w)
	bra	GLloop
GLexit	clr.b	0(a3,d3.w)		Terminate list
	moveq	#0,d0		Finished ok
	rts
GLaborted	moveq	#1,d0		Finished with error
	rts
GLdelete	tst.w	d2		at the start of the buffer?
	beq	GLloop		yes, can't delete!
	lea	0(a3,d2.w),a0
GLdelloop	tst.b	(a0)
	beq.s	GLdelend
	move.b	(a0)+,-2(a0)
	bra.s	GLdelloop	
GLdelend	subq	#1,d2
	subq	#1,d3
	clr.b	0(a3,d3.w)
	bra	GLloop
GLdelfwd	cmp.w	d2,d3
	beq	GLloop
	addq	#1,d2
	bra.s	GLdelete
GLdelline	moveq	#0,d2
	moveq	#0,d3
	clr.b	(a3)
	move.w	templong(a5),xpos(a5)
GLdlloop	move.w	#128+'G',d0
	bsr	PrintChar
	cmp.w	#78,xpos(a5)
	bcs.s	GLdlloop
	bra	GLloop
GLback	tst.w	d2
	beq	GLloop
	subq	#1,d2
	bra	GLloop
GLforward	cmp.w	d2,d3
	bls	GLloop
	addq	#1,d2
	bra	GLloop
GLeol	move.w	d3,d2
	bra	GLloop
GLbol	moveq	#0,d2
	bra	GLloop
;--------------------------------------------------------------------
; This is used to initialise the monitor. A0 points to the workspace.
; A1 points to a symbol table. If zero, no symbols are defined. This
; is used to store internal symbols. It is NOT re-initialised!!!
;
Initialise	move.l	a0,varptr\w
	move.l	varptr\w,a5
	move.l	a1,symtable(a5)
	move.l	a2,copperbase(a5)
	ifeq	debugging
	lea	OldVectors(a5),a0
	move.w	#BusErrVec,a1
	moveq	#7,d0
INcopyvecs	move.l	(a1)+,(a0)+
	dbf	d0,INcopyvecs
	endc
	clr.b	flags(a5)
	lea	normbehandle(pc),a0
	move.l	a0,intbehandle(a5)

	sf	mem2active(a5)
	sf	dis2active(a5)
	sf	dispdrawn(a5)
	moveq	#-1,d0
	moveq	#4,d1
	lea	tempbreak(a5),a0
INclrbrks	move.l	d0,(a0)+
	dbf	d1,INclrbrks
	move.b	#1,selectwin(a5)
	move.b	#18,dis1lock(a5)
	clr.b	dis2lock(a5)
	clr.b	mem1lock(a5)
	clr.b	mem2lock(a5)
	clr.l	mem1pc(a5)
	clr.l	mem2pc(a5)
	clr.l	dis1pc(a5)
	clr.l	dis2pc(a5)
	clr.l	mem1end(a5)
	clr.l	mem2end(a5)
	clr.l	dis1end(a5)
	clr.l	dis2end(a5)
	clr.w	watchptr(a5)
	clr.b	searchtype(a5)

	lea	watchbuffer(a5),a0
	lea	testexpr(pc),a1
INlp	move.b	(a1)+,(a0)+
	cmp.b	#'$',(a1)
	bne.s	INlp
INNoCop	move.l	#'MCA!',valid(a5)

INdovectors	lea	unknown(pc),a2
	move.w	#BusErrVec,a1
	moveq	#7,d0
INsetvecs	move.l	a2,(a1)+
	dbf	d0,INsetvecs

	setvec	buserr,BusErrVec
	setvec	addrerr,AddrErrVec
	setvec	normbehandle,DivByZero
	setvec	trap3,Trap3Vec
	setvec	trap5,Trap5Vec
	setvec	trap6,Trap6Vec
	setvec	trap7,Trap7Vec
	setvec	trap8,Trap8Vec
	setvec	trap9,Trap9Vec
	setvec	trap10,Trap10Vec
	setvec	trap11,Trap11Vec
	setvec	trap12,Trap12Vec
	setvec	trap15,Trap15Vec
	setvec	chkerr,ChkVec
	setvec	trapverr,TrapvVec
	setvec	priverr,PrivVec
	setvec	illegalerr,IllErrVec
	clr.b	kbdstatus(a5)
	clr.b	prevchar(a5)
	rts
	
setvidbase	movem.l	d0/A0,-(sp)
	bsr.s	Sync
	lea	screenmem(a5),a0
	cmp.l	a0,d0
	beq.s	no_newset
	move.l	d0,copperbase(a5)	;if program changes videoadres!	
no_newset	bsr	Write_d0
	movem.l	(sp)+,d0/A0
	rts
	
Sync	movem.w	d1-d2,-(a7)	
svbloop	move.b	$ffff8209.w,d1
	moveq	#100,d2
svb1	dbf	d2,svb1
	cmp.b	$ffff8209.w,d1
	bne.s	svbloop
	movem.w	(a7)+,d1-d2
	rts
Write_d0	and.l	#$ffffff,d0
	asr.w	#8,d0
	move.l	d0,$ffff8200.w
	rts
SetBaseN	bsr.s	Sync
	bra.s	Write_d0
;----------------------------------------------------------
DrawScreen	move.l	varptr\w,a5
	bsr	update_locks
DrawScreen1	bsr	setmyvideo
	bsr	ClearScreen
DrawScrNoClr
	clr.w	xpos(a5)
	clr.w	ypos(a5)
	lea	NormYtable(pc),a0
	move.l	a0,ytable(a5)
	lea	mytext(pc),a0
	bsr	printmessage
	bsr	draw_box
	bsr	highlight_win
	st	dispdrawn(a5)
update_display
	tst.b	dispdrawn(a5)
	beq.s	DrawScreen
	bsr	update_disassembly
	bsr	update_registers
	bsr	update_watch
	bra	update_dump
update_disp1
	bsr	update_locks
	bra.s	update_display
ClearScreen	lea	screenmem(a5),a0
	moveq	#0,d1
	move	#(scrsize/4)-1,d0
DSloop	move.l	d1,(a0)+
	dbf	d0,DSloop
	clr.w	xpos(a5)
	clr.w	ypos(a5)
	lea	charset1(pc),a0
	move.l	a0,charset(a5)
	rts
;----------------------------------------------------------
highlight_win
	lea	titlemsg(pc),a0
	lea	dis1lock(a5),a1
	moveq	#2,d2
	moveq	#0,d3
HWloop	bsr	highlight_one
HWskipreg	dbf	d2,HWloop
	tst.b	dis2active(a5)
	beq.s	HWnodis2
	movem.l	a0/a1,-(sp)
	bsr	highlight_one	
	movem.l	(sp)+,a0/a1
HWnodis2	addq	#3,a0
	addq	#1,a1
HWskipone	tst.b	(a0)+
	bne.s	HWskipone
	tst.b	mem2active(a5)
	beq.s	HWnomem2
	bsr	highlight_one
HWnomem2	rts
highlight_one
	move.b	(a0)+,d3		Window #
	move.b	(a0)+,ypos+1(a5)
	move.b	(a0)+,xpos+1(a5)
	cmp.b	selectwin(a5),d3
	bne.s	HOskip
	bset.b	#highlight,flags(a5)
HOskip	bsr	printmessage
	tst.w	d3		Is it window #0?
	beq.s	HOskipreg
	move.l	a0,-(sp)
	moveq	#0,d0
	move.b	(a1)+,d0		Is it bound to a reg?
	beq.s	HOnothighlit	Nope, dont do it
	subq	#1,d0
	bmi.s	HOnothighlit
	add.w	d0,d0
	lea	LockRegTab(pc,d0.w),a0
	bsr	PrintSpace
	move.b	(a0)+,d0
	bsr	PrintChar
	move.b	(a0)+,d1
	move.b	d1,d0
	bsr	PrintChar
	cmp.b	#'S',d1
	bne.s	HOnotSP
	move.b	#'P',d0
	bsr	PrintChar
HOnotSP	move.l	(sp)+,a0
HOskipreg	bclr	#highlight,flags(a5)
	rts
HOnothighlit
	bclr	#highlight,flags(a5)
	lea	NoHighMsg(pc),a0
	bsr	printmessage
	bra.s	HOnotSP
LockRegTab	dc.b	"D0D1D2D3D4D5D6D7"
	dc.b	"A0A1A2A3A4A5A6A7"
	dc.b	"SRPCSPUSSSM1M2M3M4"
	even
draw_box	lea	NoSplit(pc),a0
	tst.b	dis2active(a5)
	beq.s	DBnodis2
	lea	SplitDis(pc),a0
	tst.b	mem2active(a5)
	beq.s	DBnomem2
	lea	SplitBoth(pc),a0
	bra.s	DBnomem2
DBnodis2	tst.b	mem2active(a5)
	beq.s	DBnomem2
	lea	SplitMem(pc),a0
DBnomem2	clr.w	xpos(a5)
	move.w	#dis2y-1,ypos(a5)
	bsr	printmessage
	rts
;----------------------------------------------------------
update_locks
	lea	dis1pc(a5),a0
	lea	MySymOfs(pc),a1
	lea	dis1end(a5),a3
	lea	dis1lock(a5),a4
	moveq	#3,d1
ULloop	moveq	#0,d0
	move.b	(a4)+,d0
	beq.s	ULnolock
	subq	#1,d0
	add.w	d0,d0
	move.w	0(a1,d0.w),d0
	move.l	0(a5,d0.w),d0
	cmp.l	(a0),d0
	bls.s	ULupdate
	move.l	(a0),d2
	cmp.l	(a3),d2
	bcc.s	ULupdate
	cmp.l	(a3),d0
	bcs.s	ULnolock
ULupdate	move.l	d0,(a0)
ULnolock	addq	#4,a0
	addq	#4,a3
	dbf	d1,ULloop
	rts

;----------------------------------------------------------
update_disassembly
	move.w	#dis1y,d1
	move.l	dis1pc(a5),a1
	moveq	#5,d2
	tst.b	dis2active(a5)
	bne.s	UDdis2there
	addq	#6,d2
	bsr.s	UDdrawthem
	move.l	a1,dis1end(a5)
	rts
UDdis2there	bsr.s	UDdrawthem
	move.l	a1,dis1end(a5)
	move.l	dis2pc(a5),a1
	move.w	#dis2y,d1
	moveq	#4,d2
	bsr	UDdrawthem
	move.l	a1,dis2end(a5)
	rts
UDdrawthem	moveq	#20,d7
UDloop	move.l	a1,d3
	bsr	DisAssemble
	move.l	d3,d0
	bsr	AddASym
	lea	linebuffer(a5),a0
	move.b	#0,54(a0)
	move.w	d1,ypos(a5)
	move.w	#dis1x,xpos(a5)
	cmp.l	RegPC(a5),d3
	bne.s	UDnotpc
	bset	#highlight,flags(a5)
UDnotpc	move.l	a2,-(sp)
	moveq	#'0',d0
	lea	breakpts(a5),a2
	cmp.l	(a2)+,d3
	beq.s	UDbreak1
	cmp.l	(a2)+,d3
	beq.s	UDbreak2
	cmp.l	(a2)+,d3
	beq.s	UDbreak3
	cmp.l	(a2)+,d3
	bne.s	UDnobreak	
	addq	#1,d0
UDbreak3	addq	#1,d0
UDbreak2	addq	#1,d0
UDbreak1	move.b	d0,19(a0)
UDnobreak	move.l	(sp)+,a2
	bsr	printmessage
	bclr	#highlight,flags(a5)
	addq	#1,d1
	dbf	d2,UDloop
	rts
;----------------------------------------------------------
update_registers
	lea	registers(a5),a0
	lea	RegPositions(pc),a3
	moveq	#7,d1
UR1loop	move.w	(a3)+,xpos(a5)
	move.w	(a3)+,ypos(a5)
	move.l	(a0)+,a1		;d0-d7
	move.l	a1,d0
	bsr	PrintHexLong
	bsr	PrintSpecChar
	add.w	#1,xpos(a5)
*	ReadWordInc	d0
*	bsr	PrintHxWd2
	ReadWordInc	d0
	bsr	PrintHexWord
	ReadWordInc	d0
	bsr	PrintHexWord
	dbf	d1,UR1loop
	moveq	#8,d1
UR2loop	move.w	(a3)+,xpos(a5)	;a0-a7
	move.w	(a3)+,ypos(a5)
	move.l	(a0)+,a1
	move.l	a1,d0
	move.l	d0,-(a7)
	bsr	PrintHexLong	;adres
	ReadWordInc	d0
	bsr	PrintHexWord
	ReadWordInc	d0
	bsr	PrintHexWord
	ReadWordInc	d0
	bsr	PrintHexWord
	ReadWordInc	d0
	bsr	PrintHexWord
	ReadWordInc	d0
	bsr	PrintHexWord
	ReadWordInc	d0
	bsr	PrintHexWord
	ReadWordInc	d0
	bsr	PrintHexWord	;7 words
	move.l	(a7)+,a1
	ReadByteInc	d0
	bsr	PrintSpecChar
	ReadByteInc	d0
	bsr	PrintSpecChar
	ReadByteInc	d0
	bsr	PrintSpecChar
	ReadByteInc	d0
	bsr	PrintSpecChar
	addq	#1,d2
	dbf	d1,UR2loop
	move.l	(a0)+,a1
*	move.l	a0,-(sp)
*	moveq	#10,d7
*	bsr	DisAssemble		;pc+instruction
*	move.w	#pcx,xpos(a5)
*	move.w	#pcy,ypos(a5)
*	lea	linebuffer(a5),a0
*	cmp.b	#32,35(a0)
*	bne.s	URskip
*	move.b	#128+65,35(a0)
*URskip	clr.b	53(a0)		
*	bsr	printmessage	;set pc+instr
*	move.l	(sp)+,a0
	move.w	#srx,xpos(a5)
	move.w	#sry,ypos(a5)
	move.w	(a0)+,d1
	move.w	d1,d0
	bsr	PrintHexWord	;sr
	lea	SRbits(pc),a2
	moveq	#6,d3		;flags
USRloop	moveq	#0,d0
	move.b	(a2)+,d2
	move.b	(a2)+,d0
	btst	d2,d1
	bne.s	SRbitset
	moveq	#'-',d0
SRbitset	bsr	PrintChar
	dbf	d3,USRloop
*	move.w	#srx+19,xpos(a5)	;ipl
*	lsr	#8,d1
*	and.w	#7,d1
*	moveq	#'0',d0
*	add	d1,d0
*	bsr	PrintChar
	rts
SRbits	dc.b	15,'T',13,'S',4,'X',3,'N',2,'Z',1,'V',0,'C'
	even
RegPositions
	dc.w	5,1,5,2,5,3,5,4	;d0-d3
	dc.w	5,5,5,6,5,7,5,8	;d4-d7
	dc.w	31,1,31,2,31,3,31,4	;a0-a3
	dc.w	31,5,31,6,31,7,31,8	;a4-a7
	dc.w	31,9		;ssp
	
;----------------------------------------------------------
update_dump	move.l	mem1pc(a5),a1
	moveq	#5,d1
	moveq	#mem1y,d2
	tst.b	mem2active(a5)
	bne.s	UDmem2there
	addq	#6,d1
	bsr.s	UpDloop
	move.l	a1,mem1end(a5)
	rts
UDmem2there	bsr.s	UpDloop
	move.l	a1,mem1end(a5)
	move.l	mem2pc(a5),a1
	moveq	#mem2y,d2
	moveq	#4,d1
	bsr	UpDloop
	move.l	a1,mem2end(a5)
	rts
UpDloop	move.w	#mem1x,xpos(a5)
	move.w	d2,ypos(a5)
	move.l	a1,d0
	bsr	PrintHexLong
	move.l	a1,-(sp)
	ReadWordInc	d0
	bsr	PrintHexWord
	ReadWordInc	d0
	bsr	PrintHexWord
	move.l	(sp)+,a1
	ReadByteInc	d0
	bsr	PrintSpecChar
	ReadByteInc	d0
	bsr	PrintSpecChar
	ReadByteInc	d0
	bsr	PrintSpecChar
	ReadByteInc	d0
	bsr	PrintSpecChar
	addq	#1,d2
	dbf	d1,UpDloop	
	rts
;----------------------------------------------------------
update_watch
	lea	watchbuffer(a5),a0
	sf	checking(a5)
	add.w	watchptr(a5),a0
	moveq	#3,d6		Do four watches!
	moveq	#watchy,d5
UWloop	move.w	d5,ypos(a5)
	move.w	#1,xpos(a5)
	movem.l	d3-d6,-(sp)
	bsr	EvaluateWatch
	beq.s	UWevalok
UWnext	tst.b	(a0)+
	bne.s	UWnext
UWevalok	movem.l	(sp)+,d3-d6
	addq	#1,d5
	dbf	d6,UWloop
	rts
;----------------------------------------------------------
; This will display the watches in the watch window, reevaluating
; the expressions every time! Note, here they CANNOT FAIL!
; expression format is:
; <expr> [,<expr>][.B|.W|.L|.A|.S]
; Returns Z=1 if watch evaluated ok; otherwise Z=0
; On entry A0 points to the watch to evaluate
EvaluateWatch
	moveq	#0,d1
	tst.b	(a0)
	beq	EWFinishEvaluate
	move.l	a0,a3
	bsr	EvalNoErr
	tst.b	NoError(a5)
	bne	EWFinishEvaluate
	move.l	d0,d3		d3 = address
	moveq	#1,d4
	moveq	#'W',d5
	cmp.w	#',',token(a5)
	bne.s	EWNoAmount
	bsr	EvalNoErr
	tst.b	NoError(a5)
	bne	EWFinishEvaluate
	move.l	d0,d4		d4 = amount
EWNoAmount	cmp.w	#'.',token(a5)
	bne.s	EWNoSize
	bsr	nexttoken
	move.w	token(a5),d0
	bsr	UpperCase
	move.w	d0,d5		d5 = type
	bsr	nexttoken	
EWNoSize	tst.w	token(a5)
	sne	NoError(a5)
	bne	EWFinishEvaluate
	cmp.w	#'B',d5
	beq.s	EWsizeok
	cmp.w	#'W',d5
	beq.s	EWsizeok
	cmp.w	#'L',d5
	beq.s	EWsizeok
	cmp.w	#'A',d5
	beq.s	EWsizeok
	cmp.w	#'S',d5
	beq.s	EWsizeok
	st	NoError(a5)
	bra.s	EWFinishEvaluate
EWsizeok	tst.b	checking(a5)
	bne.s	EWfinito
	moveq	#14,d1		Max of 15 chars to print
EWprexpr	tst.b	(a3)
	beq.s	EWendprexp
	moveq	#0,d0
	move.b	(a3)+,d0
	bsr	PrintChar
	dbf	d1,EWprexpr
EWendprexp	tst.b	(a3)
	beq.s	EWnocont
	moveq	#'>',d0
	bset	#highlight,flags(a5)
	bsr	PrintChar
	bclr	#highlight,flags(a5)
EWnocont	bsr	PrintSpace
	moveq	#'=',d0
	bsr	PrintChar
	bsr	PrintSpace
	move.l	d3,d0
	bsr	PrintHexLong
	move.l	d3,a1
	sub.w	#1,xpos(a5)
	moveq	#':',d0
	bsr	PrintChar
	bsr	PrintSpace
	cmp.b	#'B',d5
	beq.s	EWPrintBytes
	cmp.b	#'W',d5
	beq.s	EWPrintWords
	cmp.b	#'L',d5
	beq.s	EWPrintLongs
	cmp.b	#'A',d5
	beq.s	EWPrintAscii
	cmp.b	#'S',d5
	beq.s	EWPrintString
EWFinishEvaluate
	cmp.w	#79,xpos(a5)
	beq.s	EWfinito
	moveq	#32,d0
	bsr	PrintChar
	bra.s	EWFinishEvaluate
EWfinito	tst.b	NoError(a5)
	rts

EWPrintBytes
	bra.s	PBenter
Pbcsop	cmp.w	#77,xpos(a5)
	bcc.s	EWFinishEvaluate
	ReadByteInc	d0
	bsr	PrintHexByte
PBenter	dbf	d4,Pbcsop
	bra.s	EWFinishEvaluate

EWPrintWords
	bra.s	PWenter
PWSloop	cmp.w	#75,xpos(a5)
	bcc.s	EWFinishEvaluate
	ReadWordInc	d0
	bsr	PrintHexWord
PWenter	dbf	d4,PWSloop
	bra.s	EWFinishEvaluate

EWPrintLongs
	bra.s	PLenter
PLloop	cmp.w	#71,xpos(a5)
	bcc.s	EWFinishEvaluate
	ReadLongInc	d0
	bsr	PrintHexLong
PLenter	dbf	d4,PLloop
	bra.s	EWFinishEvaluate

EWPrintAscii
	bra.s	PAenter
PAloop	cmp.w	#79,xpos(a5)
	bcc.s	EWFinishEvaluate
	ReadByteInc	d0
	bsr	PrintSpecChar
PAenter	dbf	d4,PAloop
	bra.s	EWFinishEvaluate

EWPrintString
	move.b	#'"',d0
	bsr	PrintChar
	bra.s	PSenter
PSloop	cmp.w	#78,xpos(a5)
	bcc.s	PSFinishStr
	ReadByteInc	d0
	cmp.w	#32,d0
	bcs.s	PSFinishStr
	cmp.w	#128,d0
	bcc.s	PSFinishStr
	bsr	PrintChar
PSenter	dbf	d4,PSloop
PSFinishStr	move.b	#'"',d0
	bsr	PrintChar
	bra	EWFinishEvaluate
;------------------------------------------------------------------------
; 68000 disassembler
; On entry: A1=base of the instruction.
;
; Trashes nothing.
; On exit: a1=next instruction.
;
Length	equr	d7	The length of the instruction is in d7
Instr	equr	d6	The instruction is held in this reg
Dot	equr	d5	This is a constant '.'
Const15	equr	d4	This is a constant 0x0f
;-------------------------------------------------------------------------
; This is the main section for disassembly.
; It uses the table described at the end of this listing
;
	
DisAssemble	movem.l	d0-d7/a0/a2-a6,-(sp)
	move.l	a1,d0
	and.l	#$fffffe,d0
	move.l	d0,a1
	moveq	#53,d0		Clear the buffer to spaces
	lea	DisAsmErr(pc),a6
	move.l	a6,intbehandle(a5)
	move.l	a7,errorstack(a5)
	lea	linebuffer(a5),a6
Clrloop	move.b	#32,0(a6,d0.w)
	dbf	d0,Clrloop
	moveq	#'.',Dot		Set up the register constants
	moveq	#15,Const15
	sf	illegal(a5)
	lea	linebuffer(a5),a6	A6 to the start of the buffer
	move.l	a1,d0		Put the current PC value in
	bclr	#0,d0		Make sure disassemble addr
	move.l	d0,a1		is even (round down)
	bsr	CopyAddr		the output buffer
	lea	linebuffer(a5),a6
	add.w	d7,a6		A6 points to position of instr
	move.l	a6,lineptr(a5)
	lea	8(a6),a5		A5 points to a tabbed position
	ReadWordInc	Instr		Read instruction
	pea	finished(pc)	Push the address of return sub.
	lea	Inst_Table(pc),a0
GetInstlp	movem.w	(a0)+,d0-d2		Read mask,check value and routine
	move.l	(a0)+,d3		Read the first 4 inst chars
	tst.w	d0		Are we at the end of the table?
	beq.s	Invalid_op		Yes, its invalid
	move.w	Instr,d7
	and.w	d0,d7		Clear bits not to be checked
	cmp.w	d1,d7		check with compare value
	bne.s	GetInstlp		Not the same, go back
	lea	Inst_Table(pc),a0	Otherwise jump to its service
	add.w	d2,a0		routine
	move.l	d3,(a6)+
	jmp	(a0)
;-------------------------------------------------------------------------
; When disassembly is finished, we come here. The disassembled text is
; displayed on the screen, all registers are returned.
;
finished
	move.l	varptr\w,a5
	lea	normbehandle(pc),a0
	move.l	a0,intbehandle(a5)
	move.l	errorstack(a5),sp	
	movem.l	(sp)+,d0-d7/a0/a2-a6
	rts
;--------------------------------------------------------------------------
DisAsmErr	move.l	varptr\w,a5
	move.l	lineptr(a5),a6
	move.l	#'MEMO',(a6)+
	move.l	#'RY U',(a6)+
	move.l	#'NREA',(a6)+
	move.l	#'DABL',(a6)+
	move.l	#'E!  ',(a6)+
	move.l	#'    ',(a6)+
	move.l	#'    ',(a6)+
	addq	#2,a1
	bra.s	finished
;--------------------------------------------------------------------------
; We come here when there is an invalid instruction. We then put up
; ??? and then the actual instruction word.
;
Invalid_op	bsr.s	InvalidMode
	subq	#2,a1
	bra	ImmedW
;--------------------------------------------------------------------------
InvalidMode	moveq	#'?',d0
	move.b	d0,(a6)+
	move.b	d0,(a6)+
	move.b	d0,(a6)+
	move.l	varptr\w,a0
	st	illegal(a0)
	rts
;--------------------------------------------------------------------------
SizeIn67DL	bsr.s	SizeIn67		Get the size
	move.b	Dot,(a6)+		and then place it in the 
	move.b	Length,(a6)+	buffer with a '.' first
	move.l	a5,a6		Align to start of Opcode field
	rts
;-------------------------------------------------------------------------
; This routine extracts the instruction size from bits 6 and 7 in the
; instruction word. The valid modes are:
; 	00 - byte
;	01 - word
;	10 - long word
;	11 - invalid
; The size is returned in d7 (or Length)
;
SizeIn67	move.w	Instr,d0
	lsr	#6,d0
	and.w	#3,d0
	move.b	sizetab(pc,d0.w),Length
	cmp.b	#'?',Length
	bne.s	S67notinv
	move.l	varptr\w,a0
	st	illegal(a0)
S67notinv	rts
sizetab	dc.b	'BWL?'
;-------------------------------------------------------------------------
; This routine caters for the MOVEQ instruction. It is fairly special since
; it is the only one which uses the lower byte of the instruction field
; as the immediate data.
moveq_op	move.l	#'Q.L ',(a6)+
	move.b	#'#',(a6)+
	move.b	Instr,d0		Get the value
	ext.w	d0		Sign extend it to long word size
	ext.l	d0
	bsr	CopyNum		and put it in the buffer
	move.b	#',',(a6)+		Also, put its following parameter
	bra	DDDIn9b
;-------------------------------------------------------------------------
; The address register required as a parameter is specified in bits 0 to
; 2 of the instruction.
;
AAAIn02SP	move.l	a5,a6		Move to TAB position
AAAIn02	bsr.s	ReadModReg		Read the MOD/REG bits
	bra.s	Mode1		and then go to the 'An' routine
ReadModReg	move.w	Instr,d0		Mod is in bits 0-2
	move.w	Instr,d1		Reg is in bits 3-5
	lsr	#3,d0
	rts
sizetab2 dc.b	'?BLW'
;--------------------------------------------------------------------------
; Miscellaneous routines which eventually call the mode/rm section
;
SSModRegSPD	subq	#1,a6		Here for 3 character instructions
SSModReg	bsr.s	SizeIn67DL		Here for instrs with the size in 6&7
ModRegSetPos
	move.l	a5,a6		Set to tab position
ModReg	bsr.s	ReadModReg		Read the mod and register fields
	bra.s	EAcommon		and then deal with the mode
;--------------------------------------------------------------------------
; Move is here on its own, it is the only instruction which has a second
; mod,reg field. Its a bit awkward since mod and reg are reversed in order.
; Also the size of the instruction is specified in bits 12 and 13.
;
move_op	move.w	Instr,d0		Get the length, note its not
	rol.w	#4,d0		the same order as other instructions
	and.w	#3,d0
	move.b	sizetab2(pc,d0.w),Length
	cmp.b	#'?',Length
	bne.s	MOnotinv
	move.l	varptr\w,a0
	st	illegal(a0)
MOnotinv	move.b	Dot,(a6)+
	move.b	Length,(a6)+
	bsr.s	SourceEA
;------------------------------------------------------------------------
; EA is in the dest bits ie 6-11
;
DestEA	move.b	#',',(a6)+
	move.w	Instr,d0		Dest Mode
	lsr	#6,d0
	move.w	d0,d1		Dest Reg
	lsr	#3,d1
	bra.s	EAcommon
;-------------------------------------------------------------------------
; EA is in the source bits ie bits 0-5
;
SourceEA	move.l	a5,a6
	bsr	ReadModReg
;-------------------------------------------------------------------------
;
; This routine will form an addressing mode from the mode in d0 and reg
; in d1
;
EAcommon	and.w	#7,d0		Ensure values between 0
	and.w	#7,d1		and 7 for Mod and Reg
	lea	eatab(pc),a0	Jump to the service routine for mod
Jump_Table	add.w	d0,d0
	add.w	0(a0,d0.w),a0
	jmp	(a0)
eatab	dc.w	Mode0-eatab
	dc.w	Mode1-eatab
	dc.w	Mode2-eatab
	dc.w	Mode3-eatab
	dc.w	Mode4-eatab
	dc.w	Mode5-eatab
	dc.w	Mode6-eatab
	dc.w	Mode7-eatab
;-------------------------------------------------------------------------
; Dn
;
Mode0	move.b	#'D',(a6)+
M01C	move.w	d1,d0
	and.w	#7,d0
	bra	CopyHexNibble
;-------------------------------------------------------------------------
; An
;
Mode1	move.b	#'A',(a6)+
	bra.s	M01C
;-------------------------------------------------------------------------
; -(An)
;
Mode4	move.b	#'-',(a6)+
;-------------------------------------------------------------------------
; (An)
;
Mode2	move.b	#40,(a6)+
	bsr.s	Mode1
	move.b	#')',(a6)+
	rts
;-------------------------------------------------------------------------
; (An)+
;
Mode3	bsr.s	Mode2
	move.b	#'+',(a6)+
	rts
;-------------------------------------------------------------------------
; nn(An)
;
Mode5	ReadWordInc d0
	ext.l	d0
	move.l	a5,-(a7)
	move.l	varptr\w,a5
	tst.b	SignedFlag(a5)
	beq.s	Sign
	move.l	(a7)+,a5
	bsr	CopyNum		
	bra.s	Mode2
Sign	move.l	(a7)+,a5
	bsr	SignedCopyNum
	bra.s	Mode2
;-------------------------------------------------------------------------
; nn.B(An,Rn)
;
Mode6	ReadWordInc d3
	move.w	d3,d0
	cmp.w	#255,d0
	bls.s	M6ok
	move.l	varptr\w,a0
	st	illegal(a0)
M6ok	ext.w	d0
	ext.l	d0
	bsr	SignedCopyNum
	move.b	#40,(a6)+
	bsr	Mode1
	bra	PutAnyReg	
;-------------------------------------------------------------------------
; Misc, the correct mode also uses the Reg field (in d1)
; Mode 7 is an 'extended mode' for extra instruction forms.
; ie the absolute and PC relative addressing modes.
;
Mode7	lea	Mode7Tab(pc),a0
	move.l	d1,d0
	bra	Jump_Table
Mode7Tab	dc.w	Mode70-Mode7Tab
	dc.w	Mode71-Mode7Tab
	dc.w	Mode72-Mode7Tab
	dc.w	Mode73-Mode7Tab
	dc.w	ImmedBWL-Mode7Tab
	dc.w	InvalidMode-Mode7Tab
	dc.w	InvalidMode-Mode7Tab
	dc.w	InvalidMode-Mode7Tab
;-------------------------------------------------------------------------
; nnnn.W
;
Mode70	ReadWordInc d0
	ext.l	d0
	bsr	NumOrSym
	move.b	Dot,(a6)+
	move.b	#'W',(a6)+
	rts
;-------------------------------------------------------------------------
; nnnn.L
;
Mode71	ReadLongInc	d0
	bra	NumOrSym
;-------------------------------------------------------------------------
; nn.W(pc)
;
Mode72	move.l	a1,a0
	ReadWordInc	d0
	add.w	d0,a0
	move.l	a0,d0
	bsr	NumOrSym
	bsr.s	Putbrpc
	move.b	#')',(a6)+
	rts
;-------------------------------------------------------------------------
; Places (PC in the buffer
; 
Putbrpc	move.b	#40,(a6)+
	move.b	#'P',(a6)+
	move.b	#'C',(a6)+
	rts
;-------------------------------------------------------------------------
; nn.B(pc,Rn)
;
Mode73	move.l	a1,a0
	ReadWordInc	d3
	move.w	d3,d0
	cmp.w	#255,d0
	bls.s	M73ok
	move.l	varptr\w,a0
	st	illegal(a0)
M73ok	ext.w	d0
	ext.l	d0
	add.l	a0,d0
	bsr	NumOrSym
	bsr.s	Putbrpc
;-------------------------------------------------------------------------
; This routine produces the required 'An' or 'Dn' as used in the
; PC relative adressing modes.
;
PutAnyReg
	move.b	#',',(a6)+
	moveq	#'D',d0
	btst	Const15,d3
	beq.s	PAR1
	moveq	#'A',d0
PAR1	move.b	d0,(a6)+
	move.w	d3,d0
	rol.w	#4,d0
	and.w	#7,d0
	bsr	CopyHexNibble
	move.b	Dot,(a6)+
	moveq	#'W',d0
	btst	#11,d3
	beq.s	PAR2
	moveq	#'L',d0
PAR2	move.b	d0,(a6)+
	move.b	#')',(a6)+
	rts
;-------------------------------------------------------------------------
; Immediate addressing modes, for byte word and long word. The value is
; read from the current 'PC' value.
;
ImmedW	moveq	#'W',Length
ImmedBWL	move.l	a5,a6
	move.b	#'#',(a6)+
	clr.l	d0
	ReadWordInc d0
	cmp.b	#'L',Length
	bne.s	IWIsNotLong
	swap	d0
	ReadWordInc d0
IWIsNotLong	cmp.b	#'B',Length
	bne.s	IWIsNotByte
	cmp.w	#255,d0
	bls.s	IWIsNotByte
	move.l	varptr\w,a0
	st	illegal(a0)
IWIsNotByte	bra	CopyNum
;--------------------------------------------------------------------------
; SUBX and ADDX instructions. Their mode is
; Dx,Dy or -(Ax),-(Ay) only.
;
sbadx_op	lea	DDDIn9b(pc),a4
	btst	#3,Instr
	beq.s	CmpmEnt
	lea	Mode4(pc),a4
CmpmEnt	bsr	SizeIn67DL
	move.w	Instr,d1
	jsr	(a4)
	move.b	#',',(a6)+
	move.w	Instr,d1
	rol.w	#7,d1
	jmp	(a4)
;--------------------------------------------------------------------------
; CMPM instruction, basically the same as SUBX and ADDX except the only
; mode allowed is (Ax)+,(Ay)+
;
cmpm_op	lea	Mode3(pc),a4
	bra.s	CmpmEnt
;--------------------------------------------------------------------------
; Here the CMP instruction is catered for, also the routine to cater for
; instructions which have a data register, the size and a mode/register
; fields are done.
;
cmp_op	subq	#1,a6
DDDSSModReg	bsr	SSModReg
	move.b	#',',(a6)+
DDDIn9b	move.w	Instr,d1
	rol.w	#7,d1
	bra	Mode0
;--------------------------------------------------------------------------
; EOR is in a class of its own. It is the only instruction whose form
; is EOR.s Dn,<ea>
;
eor_op	subq	#1,a6
	bsr	SizeIn67DL
	bsr.s	DDDIn9b
	move.b	#',',(a6)+
	bra	ModReg	
;-------------------------------------------------------------------------
; Deal with instructions of the form
; Inst.s <ea>,An
;
AAASModReg	moveq	#'W',Length
	btst	#8,Instr
	beq.s	AAAexit
	moveq	#'L',Length
AAAexit	move.b	Dot,(a6)+
	move.b	Length,(a6)+
	move.l	a5,a6
	bsr	ModReg
AAAIn9bCom	move.b	#',',(a6)+
AAAIn9b	move.w	Instr,d1
	rol.w	#7,d1
	bra	Mode1
;--------------------------------------------------------------------------
; OR and AND are almost the same as CMP and EOR except that both operands
; may be swapped.
;
or_op	subq	#1,a6
and_op	subq	#1,a6
	bsr	SizeIn67DL
	lea	DDDIn9b(pc),a2
	lea	ModReg(pc),a3
	btst	#8,Instr
	bra	GoA2A3Swap
;--------------------------------------------------------------------------
; All of the immediate logical instructions are done here. This is since
; the operand can also be the SR or the CCR.
;
ori_op	subq	#1,a6
andi_op	move.w	Instr,d0	Get Instruction bit-pattern
	and.w	#%10111111,d0
	cmp.w	#%00111100,d0	if its this one, then its the
	bne.s	subaddi_op	same as SUBADDI otherwise its
	bsr	ImmedW	got CCR and SR as its destinations
	move.l	#'CCR ',-(sp)
	btst	#6,Instr	Which is denoted by the state of
	beq.s	FromSP2A6	bit 6 in the instruction field
	move.l	#'SR  ',(sp)
FromSP2A6	move.b	#',',(a6)+	This section copies 3 bytes from
	move.b	(sp),(a6)+	the stack into the buffer. It is
	move.b	1(sp),(a6)+	used by all of the CCR,SR routines.
	move.b	2(sp),(a6)+
	addq	#4,sp
	rts
;-------------------------------------------------------------------------
; Again as a move, it just has to be awkward.
;
moveccrsr_op	move.l	a5,a6
	btst	#10,Instr
	beq.s	MVFromSR
	bsr	ModReg
	move.l	#'CCR ',-(sp)
	btst	#9,Instr
	beq.s	MVToCCR
	move.l	#'SR  ',(sp)
MVToCCR	bra.s	FromSP2A6
MVFromSR	move.w	#'SR',(a6)+
	move.b	#',',(a6)+
	bra	ModReg
;--------------------------------------------------------------------------
; The EXT.W Dn or EXT.L Dn instruction.
;
ext_op	subq	#1,a6
	bsr.s	SizeInBit6
DDDIn02	bsr	ReadModReg
	bra	Mode0
;-------------------------------------------------------------------------
; The size of the instruction is specified in bit 6 of the bit-pattern.
; Also, the buffer position is advanced to the TAB stop.
;
SizeInBit6	moveq	#'W',Length
	btst	#6,Instr
	beq.s	SIBskip
	moveq	#'L',Length
SIBskip	move.b	Dot,(a6)+
	move.b	Length,(a6)+
	move.l	a5,a6
	rts
;--------------------------------------------------------------------------
; Miscellaneous immediate mode instructions use this.
;
subaddi_op	bsr	SizeIn67DL
	bsr	ImmedBWL
CommaModReg 	move.b	#',',(a6)+
	bra	ModReg
;--------------------------------------------------------------------------
; SUBQ and ADDQ, also deals with quick values located in bits 9-11
;
sbadq_op	bsr	SizeIn67DL
DoQuickVal	move.l	a5,a6
	move.b	#'#',(a6)+
	move.w	Instr,d0
	rol.w	#7,d0
	and.l	#7,d0
	bne.s	DQVskip
	moveq	#8,d0
DQVskip	bsr	CopyNum
	bra.s	CommaModReg
;--------------------------------------------------------------------------
; Trap has the trap number in bits 0-3
;
trap_op	move.l	a5,a6
	move.b	#'#',(a6)+
	move.b	#'$',(a6)+
	move.b	Instr,d0
	bra	CopyHexNibble
;--------------------------------------------------------------------------
; The shift and rotate class of instructions.
;
sar_op	subq	#4,a6
	bsr	SizeIn67		Get the size
	moveq	#2,d1
	cmp.b	#'?',Length		If its invalid then its trying to
	bne.s	SARNotFrMem		work from memory and its bits
	moveq	#8,d1		9 and 10 which determine which shift
SARNotFrMem	move.w	Instr,d0		Otherwise its bits 3 and 4
	lsr	d1,d0
	and.w	#%110,d0
	move.w	RotOps(pc,d0.w),(a6)+
	cmp.b	#%100,d0
	bne.s	SARNotRoX		Check for ROXL/ROXR, if so add an X
	move.b	#'X',(a6)+
SARNotRoX	moveq	#'R',d0		Check for right and left, specified
	btst	#8,Instr		by bit #8
	beq.s	SARnotleft
	moveq	#'L',d0
SARnotleft	move.b	d0,(a6)+
	move.b	Dot,(a6)+
	cmp.b	#'?',Length
	beq.s	SARFromMem
	move.b	Length,(a6)+
	btst	#5,Instr
	bne.s	SrcIsData
	bne	DDDIn9b
	and.w	#%0000111000000111,Instr
	bra	DoQuickVal
SARFromMem	move.l	varptr\w,a0
	sf	illegal(a0)
	move.b	#'W',(a6)+
	bra	ModRegSetPos
SrcIsData	move.l	a5,a6
	bsr	DDDIn9b
	move.b	#',',(a6)+
	bra	DDDIn02
RotOps	dc.b	'ASLSRORO'
;--------------------------------------------------------------------------
bcc_op
	subq	#3,a6
	move.w	Instr,d0
	lsr	#7,d0
	and.w	#$1e,d0
	cmp.w	#4,d0
	bcc.s	BCC2
	add	#32,d0
BCC2	bsr.s	DoCond1
	move.l	a1,d0
	move.b	Instr,d1
	ext.w	d1
	beq.s	BCCnotshort
	move.b	Dot,(a6)+
	move.b	#'S',(a6)+
	bra.s	BCCskip
BCCnotshort	ReadWordInc d1
BCCskip	move.l	a5,a6
	add.w	d1,d0
	bra	NumOrSym
;--------------------------------------------------------------------------
dbcc_op	subq	#2,a6
	bsr.s	DoCond
	move.l	a5,a6
	bsr	DDDIn02
	ReadWord	d0 
	ext.l	d0
	add.l	a1,d0
	addq	#2,a1
	move.b	#',',(a6)+
	bra	NumOrSym
DoCond	move.w	Instr,d0
	lsr	#7,d0
	and.w	#$1e,d0
DoCond1	move.b	condtab(pc,d0.w),(a6)+
	move.b	condtab+1(pc,d0.w),(a6)+	
	rts
condtab	dc.b	'T F HILSCCCSNEEQ'
	DC.B	'VCVSPLMIGELTGTLE'
	dc.b	'RASR'
scc_op
	subq	#3,a6
	bsr.s	DoCond
	move.l	a5,a6
	bra	ModReg	
;--------------------------------------------------------------------------
asbcd_op	lea	Mode0(pc),a4
	btst	#3,Instr
	beq.s	ASBskip
	lea	Mode4(pc),a4
ASBskip	move.l	a5,a6
	move.w	Instr,d1
	jsr	(a4)
	move.b	#',',(a6)+
	move.w	Instr,d1
	rol.w	#7,d1
	jmp	(a4)
;--------------------------------------------------------------------------
movem_op	move.b	#'M',(a6)+
	bsr	SizeInBit6
	ReadWordInc d2
	btst	#10,Instr		Pushing or popping?
	beq.s	MMpopping		If zero, then popping
	move.w	d2,-(a7)		;new
	bsr	ModReg
	move.w	(a7)+,d2		;new
	move.b	#',',(a6)+
	

MMDumpEnt	moveq	#'D',d0
	move.w	d2,-(sp)
	and.w	#$ff,d2
	moveq	#0,d3
	bsr.s	MMDumpCom
	moveq	#'A',d0
	move.w	(sp)+,d2
	lsr	#8,d2
MMDumpCom 	moveq	#'0'-1,d1
MMDumpLoop	addq	#1,d1
	tst.w	d2
	beq.s	MMFinished
	lsr	#1,d2		Is this registers bit set?
	bcc.s	MMDumpLoop
	tas	d3
	beq.s	MMNoSlash
	move.b	#'/',(a6)+
MMNoSlash	move.b	d0,(a6)+
	move.b	d1,(a6)+
	btst	#0,d2		Any more for a possible list?
	beq.s	MMDumpLoop
MMListLoop	btst	#0,d2
	beq.s	MMListEnd
	addq	#1,d1
 	lsr	#1,d2
	bcs.s	MMListLoop
MMListEnd	move.b	#'-',(a6)+
	move.b	d0,(a6)+
	move.b	d1,(a6)+
	bra.s	MMDumpLoop
MMFinished	rts

MMpopping	moveq	#15,d1
	move.w	d2,d0
MMpoplp	lsr	#1,d0
	roxl.w	#1,d2
	dbf	d1,MMpoplp
	bsr.s	MMDumpEnt
	move.b	#',',(a6)+
	bra	ModReg
;--------------------------------------------------------------------------
bit_op	move.l	a5,a6
	move.w	Instr,d0
	and.w	#$0f00,d0
	cmp.w	#$0800,d0
	beq.s	BOItsImmed
	bsr	DDDIn9b
	bra.s	BOskip
BOItsImmed	bsr	ImmedW
BOskip	move.b	#',',(a6)+
	bra	ModReg
;--------------------------------------------------------------------------
divmul_op	move.l	a5,a6
	bsr	ModReg
	move.b	#',',(a6)+
	bra	DDDIn9b	
;--------------------------------------------------------------------------
halt_op	move.w	#'T ',(a6)+
	bra	return_op
;--------------------------------------------------------------------------
trapv_op	move.w	#'V ',(a6)+
	bra	return_op
;--------------------------------------------------------------------------
illegal_op	move.l	#'GAL ',(a6)+
	bra	return_op
;--------------------------------------------------------------------------
lea_op	lea	AAAIn9b(pc),a2
	bra.s	chklnkent
;--------------------------------------------------------------------------
chk_op	lea	DDDIn9b(pc),a2 
chklnkent	move.l	a5,a6
	bsr	ModReg
	move.b	#',',(a6)+
	jmp	(a2)
;--------------------------------------------------------------------------
link_op	bsr	AAAIn02SP
	ReadWordInc	d0
	ext.l	d0
	move.b	#',',(a6)+
	move.b	#'#',(a6)+
	bra	CopyNum
;--------------------------------------------------------------------------
movep_op	move.b	#'P',(a6)+
	lea	Mode0(pc),a2
	lea	Mode5(pc),a3
	bsr	SizeInBit6
	btst	#7,Instr
GoA2A3Swap	bne.s	GoA2A3
	exg	a2,a3
GoA2A3	jsr	(a2)
	move.b	#',',(a6)+
	jmp	(a3)
;--------------------------------------------------------------------------
moveusp_op 	move.l	a5,a6
	lea	USEusp(pc),a2
	lea	AAAIn02(pc),a3
	btst	#3,Instr
	bra.s	GoA2A3Swap
USEusp	move.b	#'U',(a6)+
	move.b	#'S',(a6)+
	move.b	#'P',(a6)+
	rts
;--------------------------------------------------------------------------
exgdxdy_op	lea	DDDIn9b(pc),a2
	lea	DDDIn02(pc),a3
	bra.s	exg_common
exgaxay_op	lea	AAAIn9b(pc),a2
	bra.s	exg_1
exgdxay_op	lea	DDDIn9b(pc),a2
exg_1	lea	AAAIn02(pc),a3
exg_common	move.l	a5,a6
	bra.s	GoA2A3

;--------------------------------------------------------------------------
; Here, d0 holds an absolute value. This should be scanned for in
; the symbol table. If a corresponding symbol is found then the
; symbol is inserted. Otherwise the number is inserted
;
NumOrSym	
	bsr	FindSymValue
	bne	CopyNum
	moveq	#7,d0
NOSfoundone	move.b	(a0)+,d1
	beq.s	NOSend
	move.b	d1,(a6)+
	dbeq	d0,NOSfoundone
NOSend	rts
;--------------------------------------------------------------------------
CopyHexNibble
	move.l	d0,-(sp)
	and.w	Const15,d0
	move.b	hextable(pc,d0.w),(a6)+
	move.l	(sp)+,d0
	rts
;--------------------------------------------------------------------------
CopyAddr	movem.l	d0-d3,-(sp)
	moveq	#1,d2
	moveq	#6,d1
	bra.s	CopyEnt
;--------------------------------------------------------------------------
CopyWord	movem.l	d0-d3,-(sp)
	moveq	#1,d2
	moveq	#2,d1
	swap	d0
	bra.s	CopyEnt
;--------------------------------------------------------------------------
SignedCopyNum
	tst.l	d0
	bpl.s	CopyNum
	move.b	#'-',(a6)+
	neg.l	d0
	bra.s	CopyNum
;--------------------------------------------------------------------------
CommaCopyNum
	move.b	#',',(a6)+
;--------------------------------------------------------------------------
CopyNum	movem.l	d0-d3,-(sp)
	move.b	#'$',(a6)+
	moveq	#6,d1
	moveq	#0,d2
CopyEnt	rol.l	#4,d0
	move.l	d0,d3
	and.w	Const15,d3
	bne.s	CENonZero
	tst.b	d2
	beq.s	CESkip
CENonZero	move.b	hextable(pc,d3.w),(a6)+
	st	d2
CESkip	dbf	d1,CopyEnt	
	rol.l	#4,d0
	and.w	Const15,d0
	move.b	hextable(pc,d0.w),(a6)+
	movem.l	(sp)+,d0-d3
return_op	rts
hextable	dc.b	'0123456789ABCDEF'
PutAMessage	tst.b	MsgLineClr(a5)
	beq.s	PMclear
	bsr	ClearMessageLine
PMclear	st	MsgLineClr(a5)
	move.w	#messagey,ypos(a5)
	move.w	#1,xpos(a5)
	bra	printmessage
ClearMessageLine
	tst.b	MsgLineClr(a5)
	beq.s	return_op
	clr.b	MsgLineClr(a5)
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#messagey,ypos(a5)
	clr.w	xpos(a5)
	lea	ClearCmdText(pc),a0
	bsr	printmessage
	move.l	(sp)+,a0
	move.l	(sp)+,d0
	rts
PrintSpecChar
	and.w	#127,d0
	cmp.w	#32,d0
	bcc	PrintChar
	moveq	#'.',d0
	bra	PrintChar
PrintHexByte
	movem.l	d0-d3,-(sp)
	swap	d0
	lsl	#8,d0
	move.l	d0,d1
	moveq	#1,d2
	moveq	#0,d3
	bra.s	PHLloop
PrintHexWord
	movem.l	d0-d3,-(sp)
	swap	d0
	move.l	d0,d1
	moveq	#3,d2
	moveq	#0,d3
	bra.s	PHLloop
PrintHxWd2
	movem.l	d0-d3,-(sp)
	swap	d0
	move.l	d0,d1
	moveq	#3,d2
	moveq	#0,d3
PHWloop	rol.l	#4,d1
	move.w	d1,d0
	and.w	#$f,d0
	move.b	HexTab(pc,d0.w),d0
	bsr	PrintChar
	dbf	d2,PHWloop
	movem.l	(sp)+,d0-d3
	rts
PrintHexLong
	movem.l	d0-d3,-(sp)
	move.l	d0,d1
	moveq	#7,d2
	moveq	#0,d3
PHLloop	rol.l	#4,d1
	move.w	d1,d0
	and.w	#$f,d0
	move.b	HexTab(pc,d0.w),d0
	bsr	PrintChar
	dbf	d2,PHLloop
	cmp.w	#79,xpos(a5)
	bcc.s	PHLskip
	bsr	PrintSpace
PHLskip	movem.l	(sp)+,d0-d3
	rts
HexTab	dc.b	'0123456789ABCDEF'
PrintDecLong
	move.l	d0,d3
	tst.l	d3
	bpl.s	PDLnotneg
	neg.l	d3
	moveq	#'-',d0
	bsr	PrintChar
PDLnotneg	lea	DecTable(pc),a2
PDLloop	move.l	(a2)+,d1
	beq.s	PDLend
	moveq	#'0'-1,d0
PDLloop2	addq	#1,d0
	sub.l	d1,d3
	bpl.s	PDLloop2
	add.l	d1,d3
	bsr	PrintChar
	bra.s	PDLloop
PDLend	rts
DecTable	dc.l	1000000000
	dc.l	100000000
	dc.l	10000000
	dc.l	1000000
	dc.l	100000
	dc.l	10000
	dc.l	1000
	dc.l	100
	dc.l	10
	dc.l	1
	dc.l	0
printmessage
PMloop	moveq	#0,d0
	move.b	(a0)+,d0
	beq	ExitPrint
	bsr	PrintChar
	bra	PMloop
ExitPrint	rts
Ystart	set	0

ZoomYTable	rept	scrmax
	dc.w	Ystart
Ystart	set	Ystart+(7*scrwidth)
	endr
	
Xposition
Xstart	set	0
	rept	90


	dc.w	$00+Xstart,$01+Xstart
Xstart	set	Xstart+4
	endr
	
NormYtable
	dc.w	0,4*scrwidth,11*scrwidth,18*scrwidth
Ystart	set	25*scrwidth	+(7*scrwidth)	;4
	rept	scrmax-3
	
	dc.w	Ystart
Ystart	set	Ystart+(7*scrwidth)
	endr

PutCursor	movem.l	a2/d0,-(sp)
	bsr	CalculateCoords
	not.b	(a2)
	not.b	scrwidth(a2)
	not.b	scrwidth*2(a2)
	not.b	scrwidth*3(a2)
	not.b	scrwidth*4(a2)
	not.b	scrwidth*5(a2)
	not.b	scrwidth*6(a2)
	movem.l	(sp)+,a2/d0
	rts
CalculateCoords
	lea	screenmem(a5),a2
	move.w	ypos(a5),d0
	add.w	d0,d0
	move.l	ytable(a5),a0
	add.w	0(a0,d0.w),a2
	move.w	xpos(a5),d0
	add.w	d0,d0
	lea	Xposition(pc),a0
	add.w	0(a0,d0.w),a2
	rts
PrintSpace	movem.l	d0/a0-a2,-(sp)
PrintSpace2	bsr	CalculateCoords
	btst	#highlight,flags(a5)
	sne	d0
	move.b	d0,(a2)
	move.b	d0,scrwidth(a2)
	move.b	d0,scrwidth*2(a2)
	move.b	d0,scrwidth*3(a2)
	move.b	d0,scrwidth*4(a2)
	move.b	d0,scrwidth*5(a2)
	bra.s	PMnoHL	
PrintChar	movem.l	d0/a0-a2,-(sp)
	sub	#32,d0
	bcs	do_control
	lsl	#3,d0
	move.l	charset(a5),a1
	addq	#1,a1
	add	d0,a1
	bsr	CalculateCoords
	move.b	(a1)+,(a2)
	move.b	(a1)+,scrwidth(a2)
	move.b	(a1)+,scrwidth*2(a2)
	move.b	(a1)+,scrwidth*3(a2)
	move.b	(a1)+,scrwidth*4(a2)
	move.b	(a1)+,scrwidth*5(a2)
	move.b	(a1)+,scrwidth*6(a2)
	btst.b	#highlight,flags(a5)
	beq.s	PMnoHL
	not.b	(a2)
	not.b	scrwidth(a2)
	not.b	scrwidth*2(a2)
	not.b	scrwidth*3(a2)
	not.b	scrwidth*4(a2)
	not.b	scrwidth*5(a2)
PMnoHL	move.w	xpos(a5),d0
	addq	#1,d0
	cmp.w	#80,d0
	bcc.s	do_crlf
	move.w	d0,xpos(a5)
DCexit	movem.l	(sp)+,d0/a0-a2
	rts
do_control
	add	#32,d0
	cmp.b	#9,d0
	beq.s	do_tabstop
	cmp.b	#10,d0
	beq.s	do_crlf
	cmp.b	#11,d0
	beq.s	do_charset2
	cmp.b	#12,d0
	beq.s	do_charset1
	cmp.b	#14,d0
	beq.s	do_highlight
	bra.s	DCexit
do_charset1
	lea	charset1(pc),a1
	move.l	a1,charset(a5)
	bra.s	DCexit
do_charset2
	lea	charset2(pc),a1
	move.l	a1,charset(a5)
	bra.s	DCexit
do_highlight
	bchg	#highlight,flags(a5)
	bra.s	DCexit
do_tabstop	move.w	xpos(a5),d0
	addq	#1,d0
	lea	TabStops(pc),a1
NextTabstop	move.l	d1,-(sp)
NTloop	move.w	(a1)+,d1
	beq.s	TSexit
	cmp.w	d1,d0
	bhi.s	NTloop
	move.w	d1,d0
TSexit	move.l	(sp)+,d1
	move.w	d0,xpos(a5)
	bra.s	DCexit
TabStops
	dc.w	20,36,40,55,60,79,0
do_crlf	clr.w	xpos(a5)
	move.w	ypos(a5),d0
	addq	#1,d0
	cmp.w	#scrmax,d0
	bls.s	do_crok
	moveq	#0,d0
do_crok	move.w	d0,ypos(a5)
	bra	DCexit
; The exception handlers!
unknown	exception	27
buserr	addq	#8,sp
	move.l	a0,TempA0\w
	move.l	varptr\w,a0		In the monitor?
	tst.b	inmonitor(a0)	yes, just return
	bne.s	dotherte
	move.b	#2,varptr\w		Error #2
	bra.s	adbecom
addrerr	addq	#8,sp
	move.l	a0,TempA0\w
	move.l	varptr\w,a0
	tst.b	inmonitor(a0)	Are we in monitor?
	bne.s	dotherte		yes, just return
	move.b	#3,varptr\w		Error #3
adbecom	move.l	d0,TempD0\w
	move.l	-6(sp),templong(a0)	Store the address of the error
	move.l	2(sp),a0		and find the instr that
	move.w	-2(sp),d0		caused it
AEloop	subq	#2,a0
	cmp.w	(a0),d0		Got it?
	bne.s	AEloop		Nope, next instruction
AEfound	move.l	a0,2(sp)		Point to that instr
	move.l	TempD0\w,d0
	bra	skipmove
dotherte	move.l	intbehandle(a0),-(sp)	hit other handler
	move.l	TempA0\w,a0
	rts
normbehandle
	rte
otherbehand	lea	bemsg(pc),a0
	bsr	PutAMessage
	bra	MonitorLoop

illegalerr	move.b	#1,varptr\w		Set breakpoint error
	move.l	a0,TempA0\w
	move.l	varptr\w,a0
	move.l	2(sp),a0		If we don't have the
	cmp.w	#brkptinstr,(a0)	illegal instr, bitch
	beq	skipmove
	move.b	#4,varptr\w		Set an illegal instr
	bra	skipmove
chkerr	exception	5
trapverr	exception	6
priverr	exception	7
trace	exception	0		Trace doesn't cause one!
linea	exception	9
linef	exception	10
trap1	exception	12
trap2	exception	13
trap3	exception	14
trap4	exception	15
trap5	exception	16
trap6	exception	17
trap7	exception	18
trap8	exception	19
trap9	exception	20
trap10	exception	21
trap11	exception	22
trap12	exception	23
trap13	exception	24
trap14	exception	25
trap15	move.l	a1,-(sp)
	setvec	buserr,BusErrVec
	setvec	addrerr,AddrErrVec
	move.l	(sp)+,a1
	exception	26

reentermon	move.l	a0,TempA0\w
	move.l	varptr\w,a0
skipmove	move.w	#$2700,sr
	move.l	varptr\w,a0
	lea	registers(a0),a0
	movem.l	d0-d7,(a0)
	move.l	TempA0,32(a0)
	movem.l	a1-a6,36(a0)
	move.l	usp,a1
	move.l	a1,60(a0)
	move.w	(sp)+,72(a0)
	move.l	(sp)+,68(a0)
	bclr	#0,71(a0)
	move.l	sp,64(a0)
	move.l	varptr\w,a5
	lea	MyStack(a5),sp
	cmp.l	#'MCA!',valid(a5)
	beq.s	REworkok
	bsr	ReInit
REworkok	st	inmonitor(a5)
	lea	normbehandle(pc),a1
	move.l	a1,intbehandle(a5)
	clr.b	68(a0)
	move.l	68(a0),d2
	moveq	#-1,d3
	moveq	#3,d1
	tst.b	singlestep(a5)
	bne.s	RMskipclear
	clr.b	prevchar(a5)
	lea	tempbreak(a5),a1	Always clear tempbreak
	lea	breakcont(a5),a2
	move.l	(a1)+,d0
	bmi.s	RMclrbrk
	move.l	d0,a3
	move.w	tempcont(a5),(a3)
	move.l	d3,tempbreak(a5)
RMclrbrk	
	move.l	(a1)+,d0
	bmi.s	RMnobreak
	and.l	#$ffffff,d0		Hit this breakpt?
	move.l	d0,a3
	cmp.l	d2,a3
	bne.s	RMnotthis
	sf	flipped(a5)
	move.l	d3,-4(a1)
RMnotthis	move.w	(a2),(a3)
RMnobreak	addq	#2,a2
	dbf	d1,RMclrbrk
RMskipclear	sf	singlestep(a5)
	tst.b	dispdrawn(a5)
	bne.s	RMddrawn
	bsr	DrawScreen
RMddrawn	moveq	#0,d1
	move.b	varptr\w,d1
	beq.s	RMnoreason
	subq	#1,d1
	beq.s	RMnosetvid
	sf	flipped(a5)
RMnosetvid	tst.b	flipped(a5)
	bne.s	RMviewcont
	bsr	setmyvideo
RMviewcont	move.w	#messagey,ypos(a5)
	move.w	#1,xpos(a5)
	lea	reentmsg(pc),a0
	bra.s	RMfmsgent
RMfmsgloop	tst.b	(a0)+
	bne.s	RMfmsgloop
	tst.b	(a0)
	bne.s	RMfmsgent
	addq	#1,a0
	bra.s	RMunknown
RMfmsgent	dbf	d1,RMfmsgloop
RMunknown	move.l	a0,-(sp)
	bsr	printmessage
	lea	reentmsg1(pc),a0
	bsr	printmessage
	move.l	(sp)+,a0
RMnoreason	move.b	varptr\w,d0
	cmp.b	#2,d0		Bus or addr err?
	beq.s	RMputaddr
	cmp.b	#3,d0
	bne.s	RMnotbe
RMputaddr	lea	bemsg2(pc),a0
	bsr	printmessage
	move.l	templong(a5),d0
	bsr	PrintHexLong
RMnotbe	bsr	update_disp1
Skip_update	st	MsgLineClr(a5)
	sf	varptr\w
	bra	MonitorLoop

MySymbols	dc.b	'D0',0,'D1',0,'D2',0,'D3',0,'D4',0,'D5',0,'D6',0,'D7',0
	dc.b	'A0',0,'A1',0,'A2',0,'A3',0,'A4',0,'A5',0,'A6',0,'A7',0
	dc.b	'SR',0,'PC',0,'SP',0,'USP',0,'SSP',0
	dc.b	'M1',0,'M2',0,'M3',0,'M4',0
	dc.b	'BP0',0,'BP1',0,'BP2',0,'BP3',0,'SYMTAB',0
	dc.b	'VIDPTR',0
	dc.b	'BSS',0,'DATA',0,'TEXT',0
	dc.b	0,0,0,0
	even
MySymOfs	dc.w	registers+$00,registers+$04,registers+$08,registers+$0c
	dc.w	registers+$10,registers+$14,registers+$18,registers+$1c
	dc.w	registers+$20,registers+$24,registers+$28,registers+$2c
	dc.w	registers+$30,registers+$34,registers+$38,registers+$3c
	dc.w	RegSR+$8000,RegPC,registers+$3c,registers+$3c,RegSSP
	dc.w	dis1pc,mem1pc
	dc.w	dis2pc,mem2pc
	dc.w	breakpts,breakpts+4
	dc.w	breakpts+8,breakpts+12	
	dc.w	symtable,copperbase
	dc.w	bssptr,dataptr,textptr
mytext
	dc.b	11
	dc.b	"dggggggggggggggggggggggggghgggggggggggggggggggggggggggggggggggggggggggggggggggge"
	dc.b	"aD0:                      aA0:                                                 a"
	dc.b	"aD1:                      aA1:                                                 a"
	dc.b	"aD2:                      aA2:                                                 a"
	dc.b	"aD3:                      aA3:                                                 a"
	dc.b	"aD4:                      aA4:                                                 a"
	dc.b	"aD5:                      aA5:                                                 a"
	dc.b	"aD6:                      aA6:                                                 a"
	dc.b	"aD7:                      aA7:                                                 a"
	dc.b	"aSR:                      aSSP                                                 a"
	dc.b	"jM1 DISASSEMBLYgggggggggggigggggggggggggggggggggggggggghM2 MEMORYggggggggggggggk"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"a				a		a"
	dc.b	"jWATCH AREAggggggggggggggggggggggggggggggggggggggggggggigggggggggggggggggggggggk"
	dc.b	"a						a"
	dc.b	"a						a"
	dc.b	"a						a"
	dc.b	"a						a"
ClearCmdText
	dc.b	11,"bggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggc",12,0
	dc.b	12,0
SplitDis	dc.b	11,"jM3 DISASSEMBLYggggggggggggggggggggggggggggggggggggggggk",12,0
SplitMem	dc.b	11,"a				jM4 MEMORYggggggggggggggk",12,0
SplitBoth	dc.b	11,"jM3 DISASSEMBLYggggggggggggggggggggggggggggggggggggggggfM4 MEMORYggggggggggggggk",12,0
NoSplit	dc.b	11,"a				a		a",12,0
	even
; This table, in the first word contains a mask; the second contains
; a value; 3rd an offset to its routine ; 4th is a long word which
; contains the first four characters of the instruction.
; what is done is: the instruction word is anded with the mask; then
; compared with the value. If it is the same a jump to the routine
; is made. Also, the four characters are copied into the output buffer.
; This means that some of the instructions take only 10 bytes to process!
; at the end of the table, there is an invalid result.
;
Inst_Table
	dc.w	$ff00,$0000,ori_op-Inst_Table
	dc.b	'ORI '
	dc.w	$ff00,$0200,andi_op-Inst_Table
	dc.b	'ANDI'
	dc.w	$ff00,$0400,subaddi_op-Inst_Table
	dc.b	'SUBI'
	dc.w	$ff00,$0600,subaddi_op-Inst_Table
	dc.b	'ADDI'
	dc.w	$ff00,$0a00,andi_op-Inst_Table
	dc.b	'EORI'
	dc.w	$ff00,$0c00,subaddi_op-Inst_Table
	dc.b	'CMPI'
	dc.w	$f138,$0108,movep_op-Inst_Table
	dc.b	'MOVE'
	dc.w	$f0c0,$0000,bit_op-Inst_Table
	dc.b	'BTST'
	dc.w	$f0c0,$0040,bit_op-Inst_Table
	dc.b	'BCHG'
	dc.w	$f0c0,$0080,bit_op-Inst_Table
	dc.b	'BCLR'
	dc.w	$f0c0,$00c0,bit_op-Inst_Table
	dc.b	'BSET'

	dc.w	$c000,$0000,move_op-Inst_Table
	dc.b	'MOVE'

	dc.w	$f9c0,$40c0,moveccrsr_op-Inst_Table
	dc.b	'MOVE'
	dc.w	$ff00,$4000,SSModReg-Inst_Table
	dc.b	'NEGX'
	dc.w	$ff00,$4400,SSModRegSPD-Inst_Table
	dc.b	'NEG '
	dc.w	$ff00,$4600,SSModRegSPD-Inst_Table
	dc.b	'NOT '
	dc.w	$ffc0,$4800,ModRegSetPos-Inst_Table
	dc.b	'NBCD'
	dc.w	$ff00,$4200,SSModRegSPD-Inst_Table
	dc.b	'CLR '
	dc.w	$ffb8,$4880,ext_op-Inst_Table
	dc.b	'EXT '
	dc.w	$fff0,$4840,ModRegSetPos-Inst_Table
	dc.b	'SWAP'
	dc.w	$ffc0,$4840,ModRegSetPos-Inst_Table
	dc.b	'PEA '
	dc.w	$ffff,$4afc,illegal_op-Inst_Table
	dc.b	'ILLE'
	dc.w	$ffc0,$4ac0,ModRegSetPos-Inst_Table
	dc.b	'TAS '
	dc.w	$ff00,$4a00,SSModRegSPD-Inst_Table
	dc.b	'TST '
	dc.w	$fb80,$4880,movem_op-Inst_Table
	dc.b	'MOVE'
	dc.w	$fff0,$4e40,trap_op-Inst_Table
	dc.b	'TRAP'
	dc.w	$fff8,$4e50,link_op-Inst_Table
	dc.b	'LINK'
	dc.w	$fff8,$4e58,AAAIn02SP-Inst_Table
	dc.b	'UNLK'
	dc.w	$fff0,$4e60,moveusp_op-Inst_Table
	dc.b	'MOVE'
	dc.w	$ffff,$4e70,halt_op-Inst_Table
	dc.b	'RESE'
	dc.w	$ffff,$4e71,return_op-Inst_Table
	dc.b	'NOP '
	dc.w	$ffff,$4e72,ImmedW-Inst_Table
	dc.b	'STOP'
	dc.w	$ffff,$4e73,return_op-Inst_Table
	dc.b	'RTE '
	dc.w	$ffff,$4e76,trapv_op-Inst_Table
	dc.b	'TRAP'
	dc.w	$ffff,$4e75,return_op-Inst_Table
	dc.b	'RTS '
	dc.w	$ffff,$4e77,return_op-Inst_Table
	dc.b	'RTR '
	dc.w	$ffc0,$4e80,ModRegSetPos-Inst_Table
	dc.b	'JSR '
	dc.w	$ffc0,$4ec0,ModRegSetPos-Inst_Table
	dc.b	'JMP '
	dc.w	$f1c0,$4180,chk_op-Inst_Table
	dc.b	'CHK '
	dc.w	$f1c0,$41c0,lea_op-Inst_Table	
	dc.b	'LEA '

	dc.w	$f0f8,$50c8,dbcc_op-Inst_Table
	dc.b	'DBcc'
	dc.w	$f0c0,$50c0,scc_op-Inst_Table
	dc.b	'Scc '
	dc.w	$f100,$5000,sbadq_op-Inst_Table
	dc.b	'ADDQ'
	dc.w	$f100,$5100,sbadq_op-Inst_Table
	dc.b	'SUBQ'

	dc.w	$f000,$6000,bcc_op-Inst_Table
	dc.b	'Bcc '

	dc.w	$f100,$7000,moveq_op-Inst_Table
	dc.b	'MOVE'

	dc.w	$f1f0,$8100,asbcd_op-Inst_Table
	dc.b	'SBCD'
	dc.w	$f1c0,$80c0,divmul_op-Inst_Table
	dc.b	'DIVU'
	dc.w	$f1c0,$81c0,divmul_op-Inst_Table
	dc.b	'DIVS'
	dc.w	$f000,$8000,or_op-Inst_Table
	dc.b	'OR  '

	dc.w	$f0c0,$90c0,AAASModReg-Inst_Table
	dc.b	'SUBA'
	dc.w	$f130,$9100,sbadx_op-Inst_Table
	dc.b	'SUBX'
	dc.w	$f000,$9000,and_op-Inst_Table
	dc.b	'SUB.'

	dc.w	$f0c0,$b0c0,AAASModReg-Inst_Table
	dc.b	'CMPA'
	dc.w	$f138,$b108,cmpm_op-Inst_Table
	dc.b	'CMPM'
	dc.w	$f100,$b000,cmp_op-Inst_Table
	dc.b	'CMP '
	dc.w	$f100,$b100,eor_op-Inst_Table
	dc.b	'EOR '

	dc.w	$f1f0,$c100,asbcd_op-Inst_Table
	dc.b	'ABCD'
	dc.w	$f1c0,$c0c0,divmul_op-Inst_Table
	dc.b	'MULU'
	dc.w	$f1c0,$c1c0,divmul_op-Inst_Table
	dc.b	'MULS'
	dc.w	$f1f8,$c140,exgdxdy_op-Inst_Table
	dc.b	'EXG '
	dc.w	$f1f8,$c148,exgaxay_op-Inst_Table
	dc.b	'EXG '
	dc.w	$f1f8,$c188,exgdxay_op-Inst_Table
	dc.b	'EXG '
	dc.w	$f000,$c000,and_op-Inst_Table
	dc.b	'AND '

	dc.w	$f0c0,$d0c0,AAASModReg-Inst_Table
	dc.b	'ADDA'
	dc.w	$f130,$d100,sbadx_op-Inst_Table
	dc.b	'ADDX'
	dc.w	$f000,$d000,and_op-Inst_Table
	dc.b	'ADD '

	dc.w	$f000,$e000,sar_op-Inst_Table
	dc.b	'    '
	dc.w	0
	
	
; Scancode tables!!!!
SCnorm	dc.b	0,27,'1234567890-=',8,9
	dc.b	'qwertyuiop[]',13,0,'as'
	dc.b	"dfghjkl;'`",0,'#zxcv'
	dc.b	'bnm,./',0,0,0,' ',0,20,21,22,23,24
	dc.b	25,26,27,28,29,0,0,0,1,0,'-',3,0,4,'+',0
	dc.b	2,0,0,127,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	'\',0,0,'()/*7894561230.',13

SCshift	dc.b	0,27,'!"œ$%^&*()_+',8,9
	dc.b	'QWERTYUIOP{}',13,0,'AS'
	dc.b	"DFGHJKL:@_",0,'~ZXCV'
	dc.b	'BNM<>?',0,0,0,' ',0,0,0,0,0,0
	dc.b	25,26,27,28,29,0,0,0,1,0,'-',3,0,4,'+',0
	dc.b	2,0,0,127,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	'|',0,0,'()/*7894561230.',13
	


; Now, the copious amounts of messages!
bemsg	dc.b	'Command aborted due to BUS/ADDRESS error',0
EDabortMsg	dc.b	'Edit aborted due to BUS/ADDRESS error',0
bemsg2	dc.b	' on accessing address $',0
NoStepMsg	dc.b	'Cannot set temporary breakpoint!',0
BPHerrmsg	dc.b	'Cannot set breakpoint!',0
BPHmsg1	dc.b	'Breakpoint SET',0
BPHmsg2	dc.b	'Breakpoint CLEARED',0
SetBreakMsg	dc.b	'Set/Clear Breakpoint > ',0
NoMoreBrks	dc.b	'No more breakpoints left!',0
SetWrkMsg	dc.b	'Set DEBUGGER workspace > ',0
MoveMonMsg	dc.b	'Relocate DEBUGGER to > ',0
WinBaseMsg	dc.b	'Modify window base > ',0
ExprMsg	dc.b	'Enter expression > ',0
LockMsg	dc.b	'Lock window to register > ',0
ReInitMsg	dc.b	'Are you sure you want to reinitialise the workspace [Y/N] ? ',0
;GDmsg	dc.b	'Are you sure you want to go to download [Y/N] ? ',0
QFMmsg	dc.b	'Are you sure you want to quit [Y/N] ? ',0
;runmsg	dc.b	'Are you sure you want to run [Y/N] ? ',0
ViewBaseMsg	dc.b	'View Video Base > ',0
ExprMsg2	dc.b	'Result=$',0
testexpr
*	ifne	startup
*	dc.b	'a0+4,100.s',0
*	dc.b	'[a7+4],40.b',0
*	dc.b	'123,40.a',0
*	dc.b	'a0+d4+a3,10.l',0
*	dc.b	0,'$'
*	endc
*	ifeq	startup
	dc.b	'BP0',0
	dc.b	'BP1',0
	dc.b	'BP2',0
	dc.b	'BP3',0
	dc.b	0,'$'
	even
*	endc
SetRegMsg	dc.b	"Enter Register=Value > ",0
SetSymMsg	dc.b	"Enter Label=Value > ",0
EditMemMsg	dc.b	"Enter hexadecimal and then RETURN to accept or ESCAPE to abort.",0
EdWatchMsg	dc.b	"Edit Watch > ",0
AddWatchMsg	dc.b	"Add Watch > ",0
SearchMsg	dc.b	"Search for Byte, Word, Long, Text, Instruction ? ",0
SMbytemsg	dc.b	"Byte to find > ",0
SMwordmsg	dc.b	"Word to find > ",0
SMlongmsg	dc.b	"Longword to find > ",0
SMstrmsg	dc.b	"String to find > ",0
SMinstrmsg	dc.b	"Instruction to find > ",0
SMstrmsg2	dc.b	"Search case sensitive [Y/N] ? ",0
SearchMsg1	dc.b	"Searching...",0
FillMsg	dc.b	"Fill start, end, with > ",0
CopyMsg	dc.b	"Copy start, end, dest > ",0
EditErrMsg	dc.b	"The WATCH buffer is full, line deleted!",0
NoHighMsg	dc.b	11,'gggg',12,0
BinFileMsg	dc.b	'Binary Load/Save [L/S] ? ',0
BinSaveMsg	dc.b	'Binary Save File,start,length > ',0
BinLoadMsg	dc.b	'Binary Load File,start > ',0
ExecLoadMsg	dc.b	'Load an Executable File > ',0
openerrmsg	dc.b	'Cannot open file',0
readerrmsg	dc.b	'Cannot read from file',0
writeerrmsg	dc.b	'Cannot write to file',0
execerrmsg	dc.b	'Cannot load executable file',0
DmaLParamsMsg	dc.b	'DMA Read - Filename,start > ',0
DmaWParamsMsg	dc.b	'DMA Write - Filename,start,length > ',0
TrackWriteMsg	dc.b	'Sector Save- Adr,Trk(0-52),stsec(1-ff),numb,sd(0-1) >',0
TrackLoadMsg	dc.b	'Sector Load- Adr,Trk(0-52),stsec(1-ff),numb,sd(0-1) >',0

titlemsg	dc.b	1,10,1,"M1 Disassembly",0
	dc.b	2,10,56,"M2 Memory",0
	dc.b	0,23,1,"Watch Area",0
	dc.b	3,17,1,"M3 Disassembly",0
	dc.b	4,17,56,"M4 Memory",0
reentmsg1	dc.b	" exception",0
reentmsg	dc.b	"Breakpoint",0		1
	dc.b	"Bus error",0		2
	dc.b	"Address error",0		3
	dc.b	"Illegal instruction",0		4
	dc.b	"CHK",0			5
	dc.b	"TRAPV",0			6
	dc.b	"Privilege",0		7
	dc.b 	"Trace",0			8
	dc.b	"Line 1010",0		9
	dc.b	"Line 1111",0		10
	dc.b	"TRAP #0",0			11
	dc.b	"TRAP #1",0			12
	dc.b	"TRAP #2",0			13
	dc.b	"TRAP #3",0			14
	dc.b	"TRAP #4",0			15
	dc.b	"TRAP #5",0			16
	dc.b	"TRAP #6",0			17
	dc.b	"TRAP #7",0			18
	dc.b	"TRAP #8",0			19
	dc.b	"TRAP #9",0			20
	dc.b	"TRAP #10",0		21
	dc.b	"TRAP #11",0		22
	dc.b	"TRAP #12",0		23
	dc.b	"TRAP #13",0		24
	dc.b	"TRAP #14",0		25
	dc.b	"TRAP #15",0		26
	dc.b	"Unknown",0			27
	even
	ifne	help
helpmsg	dc.b	10,10,10
	dc.b	'^A  Breakpoint and run            F3  Set label value',10	
	dc.b	'^B  Breakpoint here               F4  Read DMA files',10
	dc.b	'^C  Quit monitor                  F5  Write DMA files',10
	dc.b	'^L  Load executable               F6  Load Bootsector',10
	dc.b	'^M  Move debugger                 F7  Write Bootsector + Magic',10
	dc.b	'^R  Run full speed                F9  DMA Read Sectors',10
	dc.b	'^S  Skip instruction              F10 DMA Write Sectors',10            
	dc.b	'^V  View any Video Adress         *B  Breakpoint at',10
	dc.b	'^W  Set workspace                 *D  Delete watch',10
	dc.b	'^Z  Single Step                   *E  Edit memory/watch',10
	dc.b	'B   Load/Save Binary(system!)     *F  Format Disk 80/10',10
	dc.b	'G   Find value                    *I  Initialise workspace',10
	dc.b	'M   Set window base               *L  Lock window to reg.',10	
	dc.b	'N   Search next                   *N  Toggle Signed-Unsigned',10	
	dc.b	'O   Evaluate expression           *R  Set register',10	
	dc.b	'V   View other screen             *S  Split window',10	          
	dc.b	'W   Fill memory with              *W  Add watch',10                     
	dc.b	'TAB Next window                   *Z  Zoom window',10,10
	dc.b	'^   Means control plus            *   Means alt plus',10
	dc.b	10,'Press any key....',0
	even
	endc
	ifne	startup
symboltable	dc.b	"Program",0
	dc.l	$4afb0001
	dc.b	"identifi"
	dc.l	$12345678
	dc.b	"LowMemor"
	dc.l	1
	ds.l	100
	dc.l	0
	even
	endc

charset1	incbin	charset1.bin
charset2	incbin	charset2.bin
	even
debuggerend
;----------------------------------------------------------
; VARIABLE OFFSETS
;----------------------------------------------------------
	section	bss
	rsreset
valid	rs.l	1
charset	rs.l	1
ytable	rs.l	1
intbehandle	rs.l	1
registers	rs.l	16
RegSSP	rs.l	1
RegPC	rs.l	1
RegSR	rs.w	1
copperbase	rs.l	1
videoquit	rs.l	1	;new
xpos	rs.w	1
ypos	rs.w	1
flags	rs.b	1
selectwin	rs.b	1
symtable	rs.l	1
illegal	rs.b	1
SignedFlag	rs.b	1
dis1lock	rs.b	1
mem1lock	rs.b	1
dis2lock	rs.b	1
mem2lock	rs.b	1
dis1pc	rs.l	1
mem1pc	rs.l	1
dis2pc	rs.l	1
mem2pc	rs.l	1
dis1end	rs.l	1
mem1end	rs.l	1
dis2end	rs.l	1
mem2end	rs.l	1
dis2active	rs.b	1
mem2active	rs.b	1
templong	rs.l	1
tempbreak	rs.l	1
breakpts	rs.l	4
tempcont	rs.w	1
breakcont	rs.w	4
symbuffer	rs.b	16
bssptr	rs.l	1
dataptr	rs.l	1
textptr	rs.l	1
fnbuffer	rs.b	16
havepallete	rs.b	1
resolution	rs.b	1
pallete	rs.l	1	
repeatdel	rs.w	1
token	rs.w	1
watchptr	rs.w	1
errorstack	rs.l	1
lineptr	rs.l	1
searchvalue	rs.b	16
StackSpace	rs.l	80
MyStack	rs.l	0
MsgLineClr	rs.b	1
InWatch	rs.b	1
delwatch	rs.b	1
checking	rs.b	1
searchtype	rs.b	1
singlestep	rs.b	1
inmonitor	rs.b	1
dispdrawn	rs.b	1
kbdstatus	rs.b	1
prevchar	rs.b	1
NoError	rs.b	1
flipped	rs.b	1
watchbuffer	rs.l	64
linebuffer	rs.b	80
OldVectors	rs.b	$140-8		;save lowmem

;---- dma stuff ---------------------
buffer  	rs.l	1
cluster     rs.w     	1
clust_st    rs.w     	1
dir_size    rs.w	1
fat_end     rs.w	1
cl_buf      rs.w	1
fat_size    rs.w	1
sect_nm     rs.w	1
sides       rs.w	1
name_buf    rs.l	3
len     	rs.l	1
fatflag	rs.w	1
fatstart	rs.w	1
cur_dir	rs.w	1
dirflag	rs.w	1
fdc	rs.w	1
clustbuf	rs.b	2560		;len = max 5 sectors
clustwbuf	rs.b	2560
DmaBuffer   rs.b	2560
EndBuf
;-------------------------------------
temprs	rs.b	0
	rs.b	256-(temprs&$ff)
screenmem	rs.b	scrsize		
varlength	rs.b	0
	
	ifne	startup	
	ds.b	256		;make at $100 border
vars
	ds.b	varlength
	even
	section	bss
	ds.b	33*1024		;$8400 reserve
	endc
	end

