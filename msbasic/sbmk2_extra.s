
	.include "prog.h.s"
	.include "stdio.h.s"

	.setcpu "65c02" 
	.global GIVAYF
	.global CONINT
	.global COLD_START

	.segment "EXTRA"

; ----------------------------------------------------------------------------
; USR_INIT:
; Initialize all user-defined machine code vector slots to point to a routine 
; that raises "Undefined function" error.
; ----------------------------------------------------------------------------
USR_INIT:
	ldy	#0
@loop:
	lda	#<UFERR
	sta	USRVEC,y
	iny
	lda	#>UFERR
	sta	USRVEC,y
	iny
	cpy	#2*NUM_USR_VECS
	bcc	@loop
	rts

; ----------------------------------------------------------------------------
; "USR<n>" function
; ----------------------------------------------------------------------------
USR_FN:
	jsr	CHRGET			; get next char
	bcc	@usr_n			; looks like it's USR<n>()
	lda	#'0'			; USR0 by default
@usr_n:
	sec
	sbc	#'0'			; convert '0'..'9' to 0..9
	cmp	#NUM_USR_VECS
	bcc	@usr_vec
	jmp	SYNERR			; go if digit too big
@usr_vec:			
	asl				; multiply by 2
	tay				; use as an index
	lda	USRVEC,y		; fetch LSB of vector
	sta	USR+1			; store LSB of vector
	lda	USRVEC+1,y		; fetch MSB of vector
	sta	USR+2			; store MSB of vector
	jsr	CHRGOT
	bcs	@chk_open
	jsr 	CHRGET			; skip past digit
@chk_open:
	jsr	CHKOPN
	jsr     FRMEVL			; evaluate the argument
	jsr	CHRGOT
	cmp	#')'
	beq	@usr_jump
	jmp	SYNERR
@usr_jump:
	jsr	CHRGET
	jmp	USR

; ----------------------------------------------------------------------------
; "DEEK" FUNCTION
; ----------------------------------------------------------------------------
DEEK:
	jsr	GETADR			; get arg as address in LINNUM
        ldy     #$01			; Y=1 to get MSB
        lda     (LINNUM),y		; fetch MSB at address
        tax				; save MSB in X
        dey				; Y=0 to get LSB
        lda     (LINNUM),y		; fetch LSB address
        tya				; put MSB in Y
        txa				; put LSB in A
        jmp     GIVAYF			; put result in FAC

; ----------------------------------------------------------------------------
; "DOKE" STATEMENT
; ----------------------------------------------------------------------------
DOKE:
        jsr     FRMNUM			; get address arg in FAC
	jsr	GETADR			; get address in LINNUM
	jsr	CHKCOM			; check for a comma
	jsr	FRMNUM			; get value arg in FAC
	jsr	AYINT			; convert arg to signed int
	ldy	#0			; Y=0 to set LSB
	lda	FAC_LAST		; fetch LSB of value
        sta     (LINNUM),y		; store LSB of value
	iny				; Y=1 to set MSB
	lda	FAC_LAST-1		; fetch MSB of value
	sta	(LINNUM),y		; store MSB of value
        rts

GETC:
	jsr cwaitc
	jsr cputc
	rts

	MEMORY_MODE = $70
BYE:
	lda #MEMORY_MODE
	jmp soft_reset


	.include "reset.s"
	.global soft_reset


noop_isr:
	rti

dispatch_isr:
	jsr acia_isr
	jsr timer_isr
	rti

	.global acia_isr
	.global timer_isr
	
	.segment "MACHVECS"
	.word noop_isr
	.word noop_isr
	.word dispatch_isr