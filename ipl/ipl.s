
		.include "ansi.h.s"
		.include "ascii.h.s"
		.include "conf.h.s"
		.include "hex.h.s"
		.include "loader.h.s"
		.include "ports.h.s"
		.include "stdio.h.s"

		.global ipl

		.segment "RODATA"
id_message:
		ansi_reset
		ansi_home
		ansi_erase_display
		.byte BEL, "SB6502 Mk2", LF, NUL


		.segment "CODE"

;-----------------------------------------------------------------------
; ipl:
; Initial program load. This routine puts the hardware into a known
; configuration, and then executes the loader.
;
ipl:
		; make sure we're in the default memory mode
		lda #CONF_MODE_RAMLW_ROM
		sta CONF_REG

		sei			; inhibit interrupts
		cld			; clear decimal mode
		ldx #$ff		
		txs			; initialize stack

		jsr cinit		; initialize standard I/O

		; display startup message
		ldy #<id_message
		lda #>id_message
		jsr cputs

		; run the loader with default memory model
		lda #CONF_MODE_RAMLW_ROM
		jmp loader
