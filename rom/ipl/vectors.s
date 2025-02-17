
		.global ipl
		.global acia_isr

		.segment "CODE"
noop_isr:
		rti
	
		.segment "MACHVECS"
		.word noop_isr
		.word ipl
		.word acia_isr
