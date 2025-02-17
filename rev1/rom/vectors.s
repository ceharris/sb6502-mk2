		.import monitor_cold
		.import acia_isr

		.segment "MACHINE"
		.word 0			; IRQ0
		.word 0			; IRQ1
		.word 0			; IRQ2
		.word 0			; IRQ3
		.word acia_isr		; IRQ4
		.word 0			; IRQ5
		.word 0			; IRQ6
		.word 0			; IRQ7
		.word 0			; unused
		.word 0			; unused
		.word 0			; unused
		.word 0			; unused
		.word 0			; unused
		.word 0			; NMI vector
		.word monitor_cold	; RESET vector
		.word acia_isr		; IRQ vector
