		.include "acia.h.s"
		.include "timer.h.s"

		.global ipl

		.segment "CODE"
noop_isr:
		rti

dispatch_isr:
		jsr acia_isr
		jsr timer_isr
		rti

		.segment "IPLVECS"
		jmp acia_putc
		jmp acia_getc
		jmp acia_ready
		jmp acia_setbrk

		.segment "MACHVECS"
		.word noop_isr
		.word ipl
		.word dispatch_isr
