		.include "keypad.h.s"
		.include "registers.h.s"

		KB_PORT	= $8080
		KB_RING_SIZE = 16		; must be a power of 2

		.segment "DATA"

		.export kb_ring
		.export kb_head
		.export kb_tail
kb_ring:
		.res KB_RING_SIZE
kb_head:
		.res 1
kb_tail:
		.res 1
kb_bits:
		.res 2
kb_last:
		.res 2
kb_latch:
		.res 2

		.segment "SYSTEM"

;-----------------------------------------------------------------------
; kb_init:
; Initializes the keypad scanner and ring buffer.
;
	.proc kb_init
		phy
		lda #$ff
		sta KB_PORT
		lda #0
		sta kb_head
		sta kb_tail
		ldy #2
@next:
		dey
		sta kb_bits,y
		sta kb_last,y
		sta kb_latch,y
		iny
		dey
		bne @next
@done:	
		ply
		rts
	.endproc


;------------------------------------------------------------------------
; kb_scan:
; Scans the keypad.
; 
; On entry:
;	kb_bits = last scan result
; On return:
;	kb_last = kb_bits as it was on entry
; 	kb_bits = latest scan result
;	b0 clobbered
;
	.proc kb_scan
		phx
		; save last scan result
		lda kb_bits
		sta kb_last
		lda kb_bits+1
		sta kb_last+1
		; start with column 0
		lda #1
@next_column:
		and #$0f		; there are just four columns
		beq @done		; go if we've done them all
		; shift kb_bits left by four for next column
		ldx #4			; there are four rows per column
@shift_over:
		asl kb_bits		
		rol kb_bits+1
		dex
		bne @shift_over
		; read the selected column and merge into result
		pha			; preserve column mask
		eor #$ff		; complement column mask
		sta KB_PORT		; zero bit selects the column
		lda KB_PORT		; read the column
		eor #$ff		; now we have ones for pressed keys
		and #$0f		; there are just four rows
		ora kb_bits		; merge in prior result
		sta kb_bits		; store new result
		pla			; recover column mask
		asl			; select next column
		bra @next_column
@done:
		; deselect all columns
		lda #$0f
		sta KB_PORT
		plx
		rts

	.endproc

;----------------------------------------------------------------------
; kb_input:
; Enqueue key make/break events based on last scanned state of the
; keypad. This method should be called after a call to kb_scan and it
; assumes that calls to kb_scan are delayed in time sufficient to 
; debounce the key buttons.
;
; On entry:
;	kb_bits = current state of keypad
;	kb_last = previous state of keypad
;	kb_latch = latched state of keypad
;
; On return:
;	kb_latch = new latched state of the keypad
; 	kb_head, kb_tail updated if make/break events detected
;	b0, b1 clobbered
;
	.proc kb_input
		phx
		phy
	
		ldy #2			; size of key state arrays
@do_make:
		dey

		; get debounced state of each key
		; (assumes suitable delay between calls to kb_scan)
		lda kb_bits,y
		and kb_last,y

		sta b0			; b0 = debounced state of keys
		lda kb_latch,y		; A = latched state of keys
		eor #$ff		
		and b0			; A = newly pressed keys
		sta b1			; b1 = newly pressed keys
		ldx #8			; look at 8 bits
@next_make:
		rol			; put key bit into carry
		bcc @no_make		; go if key not processed
		jsr kb_put		; put make event into queue (Y,X,CS)
@no_make:
		dex
		bne @next_make
@do_break:
		lda b0			; A = debounced state of keys
		eor #$ff		; A = keys that aren't pressed
		and kb_latch,y		; A = newly released keys
		sta b0			; b0 = newly released keys
		eor #$ff		; A is now zero for each released key
		ldx #8			; look at 8 bits
@next_break:
		rol			; put key bit into carry
		bcs @no_break		; go if key not released
		jsr kb_put		; put break event into queue (Y,X,CC)
@no_break:
		dex
		bne @next_break

		lda b0			; A = newly released keys
		eor #$ff
		and kb_latch,y		; clear newly released keys in latch
		ora b1			; set newly pressed keys in latch
		sta kb_latch,y

		iny
		dey
		bne @do_make

		ply
		plx
		rts
	.endproc


;----------------------------------------------------------------------
; kb_put:
; Enqueues a keypad make/break event.
;
; On entry:
;	X = key bit number (1..8)
;	Y = key byte number (0..1)
;	carry set for make or clear for break
;
; On return:
;	kb_ring[(kb_tail - 1) mod KB_RING_SIZE] = (8*Y + X - 1) OR $80*C
;	kb_tail = kb_tail' + 1
;
	.proc kb_put
		pha
		phy
		php			; preserve carry flag
		txa			; A = bit number 1..8
		dec a			; A = bit number 0..7
		dey
		bne @is_lower
		clc
		adc #8			; add 8 if in upper byte
@is_lower:
		plp			; recover carry flag
		bcc @is_break		; go if break event
		ora #$80		; set high order bit for make event
@is_break:
		pha			; preserve scan code
		lda kb_tail		; get ring tail index
		tay			; Y = current tail index
		inc a			; A = next tail index
		and #KB_RING_SIZE-1	; modulo ring size
		cmp kb_head		; tail==head => ring full
		beq @ring_full		; go if ring full
		sta kb_tail		; save new tail index
		pla			; recover scan code
		sta kb_ring,y		; put scan code into ring
		bra @done
@ring_full:
		pla			; discard scan code
@done:
		ply
		pla
		rts
	.endproc


;----------------------------------------------------------------------
; kb_get:
; Dequeues a keypad make/break event if one is available.
; 
; On return:
;	A = next input scan code if carry set
;
	.proc kb_get
		lda kb_head
		cmp kb_tail
		bne @fetch_code
		clc			; indicate none available
		rts
@fetch_code:
		phy
		tay			; Y = ring head index
		lda kb_ring,y		; fetch scan code
		pha			; preserve scan code
		iny			; next head index
		tya			; A = head index
		and #KB_RING_SIZE-1	; modulo ring size
		sta kb_head		; save new head index
		pla
		ply
		sec			; indicate scan code returned
		rts
	.endproc

