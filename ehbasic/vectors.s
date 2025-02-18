
		.global acia_isr

		.segment "CODE"
noop_isr:
		rti
	
		.segment "MACHVECS"
		.word noop_isr
		.word noop_isr
		.word acia_isr