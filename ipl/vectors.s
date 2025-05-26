		.include "acia.h.s"

		.global ipl

		.segment "CODE"
noop_isr:
		rti

		.segment "IPLVECS"
		jmp acia_putc
		jmp acia_getc
		jmp acia_ready

		.segment "MACHVECS"
		.word noop_isr
		.word ipl
		.word acia_isr
