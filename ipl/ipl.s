
		.include "acia.h.s"
		.include "ansi.h.s"
		.include "ascii.h.s"
		.include "conf.h.s"
		.include "forth.h.s"
		.include "hex.h.s"
		.include "loader.h.s"
		.include "monitor.h.s"
		.include "ports.h.s"
		.include "stdio.h.s"
		.include "timer.h.s"

		.global ipl


		.segment "RODATA"
id_message:
		ansi_reset
		ansi_home
		ansi_erase_display
		.byte BEL, "SB6502 Mk2", LF
		.byte "Press <Ctrl-C> to go to monitor or <Ctrl-F> for Forth", LF, NUL

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

		sei								; inhibit interrupts
		cld								; clear decimal mode
		ldx #$ff		
		txs								; initialize stack

		jsr timer_init					; initialize VIA timer
		jsr acia_init					; initialize ACIA
		cli								; allow interrupts

		; display startup message
		ldy #<id_message
		lda #>id_message
		jsr cputs

		; run the loader with default memory model
		lda #CONF_MODE_RAMLW_ROM
		jsr loader

		; if we returned, it means the user wants the monitor or Forth
		cmp #CTRL_F
		bne @monitor
		jmp forth
@monitor:
		jmp monitor
