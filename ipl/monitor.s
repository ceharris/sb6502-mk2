		.include "ascii.h.s"
		.include "ansi.h.s"
		.include "hex.h.s"
		.include "monitor.h.s"
		.include "prog.h.s"
		.include "registers.h.s"
		.include "stdio.h.s"

		.global fill
		.global peek
		.global peek_one
		.global poke
		.global poke_one
		.global quit


		MEMORY_MODE = $0

		PARAGRAPH_SIZE = 16
		INPUT_BUF_SIZE = 64



		.segment "BSS"
input_buf:	
		.res INPUT_BUF_SIZE
input_buf_end:

		.segment "MONITOR"
monitor:
		ldiw1 0
		ldiw2 0
command:	
		jsr show_prompt	
		ldiw0 STDIO_BUF_ADDR
		jsr cgets
		pha			; preserve input terminator
		lda #LF		
		jsr cputc		; start a new line
		pla			; recover input terminator
		cmp #CTRL_C		; did input end with Ctrl-C?
		beq command		; yep... go back to the prompt

		lda STDIO_B0		; get input length
		beq command		; zero... go back to the prompt

		; handle the input
		ldy #0			; start at beginning of string
		jsr range_arg
		bcs @error
		sta b0			; save arg count
		cmp #0			; no args?
		bne @match_command
		tw2w1			; if no args, use current in w2
@match_command:
		lda (STDIO_W0),y	; get terminating char
		beq @peek
		cmp #':'
		beq @poke
		cmp #'<'
		beq @peek_one
		cmp #'>'
		beq @poke_one
		cmp #'*'
		beq @fill
		and #$df		; convert to upper case
		cmp #'H'
		beq @hex
		cmp #'I'
		beq @ijump
		cmp #'J'
		beq @jump
		cmp #'K'
		beq @call
		cmp #'Q'
		beq @quit
@error:
		lda #BEL
		jsr cputc
		jmp command
		
@peek:
		lda b0
		dec a			; A = arg count - 1
		bne @peek_two_args
		lda w1
		sta w2
		lda w1+1
		inc a
		sta w2+1
@peek_two_args:
		jsr peek
		jmp command

@peek_one:
		jsr peek_one
		jmp command

@poke:
		jsr poke		; poke hex bytes at addr w1
		jmp command

@poke_one:
		jsr poke_one
		jmp command

@fill:
		lda b0
		dec a			; A = arg count - 1
		beq @error		; must have two args
		jsr fill
		jmp command

@call:
		lda #>(command-1)
		pha
		lda #<(command-1)
		pha
		bra @jump

@hex:
		jsr hex_load
		jmp command
	
@ijump:
		; transfer vector address to w2
		tw1w2
		ldy #0

		; fetch the address stored in the vector into w1
		lda (w2),y
		sta w1
		iny
		lda (w2),y
		sta w1+1
@jump:
		jmp (w1)

@quit:
		lda #MEMORY_MODE
		jmp quit

;-----------------------------------------------------------------------
; _pbcd16:
; Prints a 16-bit BCD value.
;
; On entry:
;	AX = 16 bit value to print
;
; On return:
;	A clobbered
;
_pbcd16:
		cmp #0			; is MSB zero?
		beq @print_lsb		; go print it
		jsr _pbcd8		; print MSB
		txa
		jsr _pbcd8u		; print LSB
		rts
@print_lsb:
		txa
		jsr _pbcd8		; print LSB
		rts

;-----------------------------------------------------------------------
; _pbcd8:
; Prints an 8-bit BCD value.
;
; On entry:
;	A = 8-bit value to print
;
; On return:
;	A clobbered
;
_pbcd8:
		pha
		and #$f0		; is upper nibble zero?
		bne _pbcd_upper		; go print it
		bra _pbcd_lower
		; this entry point prints a leading zero
_pbcd8u:
		pha
_pbcd_upper:
		; move upper nibble to lower nibble
		lsr
		lsr
		lsr
		lsr
		; convert to ASCII digit
		clc
		adc #'0'
		jsr cputc
_pbcd_lower:
		pla			; recover arg to print
		and #$0f		; discard upper nibble
		; convert to ASCII digit
		clc
		adc #'0'
		jsr cputc
		rts

;-----------------------------------------------------------------------
; show_prompt
; Print the command prompt, which displays the default starting address
; for the next command executed.
;
; On entry:
;	w1 contains the last starting address used in a command
;
; On return:
;	w3 contains the previous of w2
;	w2 contains the same value as w1
;
show_prompt:
		lda w2
		sta w3
		lda w2+1
		sta w3+1

		lda w1
		sta w2
		lda w1+1
		sta w2+1

		ldx w2
		lda w2+1
		jsr phex16
		lda #'>'
		jsr cputc
		lda #SPC
		jsr cputc
		rts

;-----------------------------------------------------------------------
; range_arg:
; Get the address range args for a command. An address range can be
; specified as either lower (inclusive) and upper (exclusive) bounds
; separated by a hyphen (e.g. 4200-4300) or starting offset and length
; (e.g. 4200+100). Addresses and lengths are always interpreted as
; hexadecimal values.
;
; On entry:
;	STDIO_W0 is the address of a buffer containing the 
;           null-terminated input to be parsed for a range argument
;	Y is the current offset into the buffer
;
; On return:
;	Carry set iff an error was detected in the range specification
;	A = the number of address arguments found in the input (0..2)
;	If A > 0:
;		w1 = the lower bound of the range (inclusive)
;		w2 = the upper bound of the range (exclusive)
;	Else:
;		w1 and w2 are unchanged
;
range_arg:
		jsr address_arg		; get first address arg
		bcc @parse_range	; go if an address was parsed
		lda #0			; range has no args
		clc			; no error
		rts
@parse_range:
		lda b0
		sta w1			; save LSB of lower bound
		lda b1
		sta w1+1		; save MSB of lower bound
		lda (STDIO_W0),y	; A = character after address
		bne @check_range_type	; go if not end of input
@one_arg:
		lda #1			; range has just one arg
		clc			; no error
		rts

@check_range_type:
		cmp #'-'		; is it 'start-end'?
		beq @range_start_end
		cmp #'+'		; is it 'start+length'?
		beq @range_start_length

		; if it's not a range separator, assume that it
		; has meaning as a command, so return without 
		; indicating an error
		bra @one_arg

@range_start_end:
		iny			; skip delimiter
		jsr address_arg
		bcs @error		; go if no address
		lda b0
		sta w2
		lda b1
		sta w2+1
		bra @two_args

@range_start_length:
		iny			; skip delimiter
		jsr address_arg		; parse an address
		bcs @error		; go if no address

		; add length in b1b0 to w1 to get upper bound in w2
		clc
		lda b0
		adc w1
		sta w2
		lda b1
		adc w1+1
		sta w2+1
@two_args:
		lda #2			; range has two args
		clc			; no error
		rts
@error:
		sec
		rts

;-----------------------------------------------------------------------
; address_arg:
; Get an address argument for a command. The address may be either a
; sequence of ASCII hexadecimal digits or the character '.' to indicate
; the current address stored in the w1 pointer.
; 
; On return:
;	carry clear if and only if an address was read
;
address_arg:
		dey			; compensate for first INY below
@strip:
		iny
		lda (STDIO_W0),y	; fetch input char
		cmp #SPC	
		beq @strip		; skip over spaces
		cmp #TAB
		beq @strip		; skip over tabs
		cmp #','
		beq @comma_arg
		cmp #'.'
		bne @check_hex		; not a dot

		; dot (.) means "use current value of w1"
		iny
		ldx w1
		lda w1+1
		bra @done

@comma_arg:
		; comma (,) means "use current value of w2"
		iny
		ldx w3
		lda w3+1
		bra @done

@check_hex:
		phy			; save input pointer
		jsr hextok		; scan ahead for hex digits
		bne @found_hex		; go if we got at least one hex digit
		ply			; recover input pointer
		sec			; set carry to indicate no address
		rts
@found_hex:
		ply			; recover input pointer
		jsr ihex16		; parse the address
@done:
		stx b0			; store the LSB
		sta b1			; store the MSB
		clc			; clear carry to indicate address read
		rts

;-----------------------------------------------------------------------
; hex_load:
; Loads a sequence of Intel Hex records from standard input.
;
;
hex_load:
		ldy #<ihex_prompt
		lda #>ihex_prompt
		jsr cputs

@next_rec:
		ldy #0
		jsr cgets
		pha				; preserve input terminator
		lda #LF		
		jsr cputc		; output newline
		pla				; recover input terminator
		cmp #CTRL_C		; terminated by Ctrl-C?
		bne @find_rec
		rts
@find_rec:
		lda (STDIO_W0),y	; get next input char
		beq @next_rec		; next record on null terminator
		iny

		cmp #':'			; start of record?
		bne @find_rec
		
		lda #0
		sta b2				; b2 = initial checksum

		; read record length
		jsr @read_byte
		bcc @syntax_error
		lda b0
		sta b1				; b1 = record length

		; read address MSB
		jsr @read_byte
		bcc @syntax_error
		lda b0
		sta w1+1			; w1 MSB = address MSB

		; read address LSB
		jsr @read_byte
		bcc @syntax_error
		lda b0
		sta w1				; w1 LSB = address LSB

		; read record type
		jsr @read_byte
		bcc @syntax_error
		lda b0
		beq @data_rec		; go if type 0 (data record)
		cmp #1
		bne @syntax_error	; go if not type 1 (EOF record)

		; end of file record
@eof_rec:
		jsr @read_byte		; read checksum
		lda b2				; A = record checksum
		bne @checksum_error
		rts
		
@data_rec:
		lda b1				; A = record length
		beq @data_rec_end
		dec b1
		jsr @read_byte
		bcc @syntax_error
		phy
		ldy #0
		lda b0
		sta (w1),y			; store input byte
		ply
		; increment w1
		inc w1
		bne @data_rec
		inc w1+1
		bra @data_rec
@data_rec_end:
		jsr @read_byte		; read checksum
		bcc @syntax_error
		lda b2				; A = record checksum
		bne @checksum_error
		jmp @next_rec

@checksum_error:
		ldy #<checksum_msg
		lda #>checksum_msg
		bra @error
@syntax_error:
		ldy #<syntax_msg
		lda #>syntax_msg
@error:
		jsr cputs
		rts

@read_byte:
		lda #2
		jsr ihex8
		sta b0
		lda b2			; A = checksum
		clc
		adc b0			; update checksum
		sta b2			; store new checksum 
		sec				; carry set indicates success
		rts


		.segment "RODATA"

ihex_prompt: 	
		.byte "<Ctrl-C to stop>", LF, NUL
syntax_msg:
		.byte "syntax error", LF, BEL, NUL
checksum_msg:
		.byte "bad checksum", LF, BEL, NUL
