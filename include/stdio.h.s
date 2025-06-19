	.ifndef STDIO_H
		STDIO_H = 1

		.include "acia.h.s"
		.include "zeropage.h.s"

	.ifndef STDIO_BUF_ADDR
		STDIO_BUF_ADDR := $300		; can be anywhere in RAM
	.endif
	.ifndef STDIO_BUF_LEN
		STDIO_BUF_LEN := 80		; must be less than 256
	.endif

		cinit = acia_init
		cgetc = acia_getc

		.global cwaitc
		.global cputc
		.global cputcc
		.global cgets
		.global cputs

	.endif