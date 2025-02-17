		.include "sound.h.s"


SND_NOISE_PERIOD = 6
SND_MIXER_CTRL = 7
SND_AMPLITUDE = 8
SND_ENV_PERIOD = 11
SND_ENV_SHAPE = 13
SND_IO_PORT= 14


		.segment "SYSTEM"

;-----------------------------------------------------------------------
; snd_rd_channel_period:
; Reads the tone period for a channel.
;
; On entry:
;	Y = channel number
; On return:
;	A,Y = channel period
;-----------------------------------------------------------------------
	.proc snd_rd_channel_period
		tya			; channel number to A
		and #3			; two bits only
		asl			; A = channel address
		sta SND_ADDR		; latch address
		ldy SND_DATA		; read period LSB
		inc a			; next address	
		sta SND_ADDR		; latch address
		lda SND_DATA		; read period MSB
		and #$0f		; want only lower nibble
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_wr_channel_period:
; Writes the tone period for a channel.
;
; On entry:
;	A,Y = channel period in lowest 12 bits and channel number in
;             upper 2 bits
;-----------------------------------------------------------------------
	.proc snd_wr_channel_period
		pha			; save upper bits of period
		; rotate channel bits into the lowest 2 bits
		rol			; bit 7 to carry
		rol			; bit 7 to bit 0, bit 6 to carry
		rol			; bit 7 to bit 1, bit 6 to bit 0
		and #3
		; multiply by two to get channel address
		asl			; A = channel address
		sta SND_ADDR		; latch address
		sty SND_DATA		; write LSB of period
		inc a			; next address
		sta SND_ADDR		; latch address
		pla			; recover upper bits of period
		sta SND_DATA		; write MSB of period	
		rts	
	.endproc


;-----------------------------------------------------------------------
; snd_wr_channel_note:
; Writes the period for a note to the 
;
; On entry:
;	A = (channel number)<<6 | note number

;-----------------------------------------------------------------------
	.proc snd_wr_channel_note
		pha			; preserve channel number
		and #$3f			; six bits only
		asl			; multiply by 2 for table offset
		tay			; note table index
		pla			; recover channel number
		; rotate channel number to lowest two bits
		rol			; bit 7 to carry
		rol			; bit 7 to bit 0, bit 6 to carry
		rol			; bit 7 to bit 1, bit 6 to bit 0
		and #3			; two bits only
		asl			; A=tone period LSB register
		pha			; preserve register address
		sta SND_ADDR		; latch address
		lda snd_notes,y		; fetch LSB of note period
		sta SND_DATA		; write to period LSB register
		pla			; recover register address
		inc a			; A=tone period MSB register
		sta SND_ADDR		; latch address
		lda snd_notes+1,y	; fetch MSB of note period
		sta SND_DATA		; write to period MSB register
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_rd_noise_period:
; Reads the noise generator period.
;
; On return:
;	A = noise period
;-----------------------------------------------------------------------
	.proc snd_rd_noise_period
		ldy #SND_NOISE_PERIOD	; load register address
		sty SND_ADDR		; latch address
		lda SND_DATA		; read noise period
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_wr_noise_period:
; Writes the noise generator period.
;
; On entry:
;	A = Noise period (5 bits)
;-----------------------------------------------------------------------
	.proc snd_wr_noise_period
		ldy #SND_NOISE_PERIOD	; load register address
		sty SND_ADDR		; latch address
		sta SND_DATA		; write noise period
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_rd_mixer_control:
; Reads the mixer and I/O control register.
;
; On return:
;	A = mixer and I/O control register bits
;-----------------------------------------------------------------------
	.proc snd_rd_mixer_control
		ldy #SND_MIXER_CTRL	; load register address
		sty SND_ADDR		; latch address
		lda SND_DATA		; read mixer control
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_wr_mixer_control:
; Configures the mixer and I/O control register.
;
; On entry:
;	A = (IO enable)<<6 | (CBA noise enable)<<3 | (CBA tone enable)
;-----------------------------------------------------------------------
	.proc snd_wr_mixer_control
		ldy #SND_MIXER_CTRL	; load register address
		sty SND_ADDR		; latch address
		sta SND_DATA		; write mixer control
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_rd_channel_amplitude:
; Reads a channel's amplitude
;
; On entry:
;	A = channel number
;-----------------------------------------------------------------------
	.proc snd_rd_channel_amplitude
		and #3			; two bits only
		clc
		adc #SND_AMPLITUDE	; A = register address
		sta SND_ADDR		; latch address
		lda SND_DATA		; fetch mode and amplitude
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_wr_channel_amplitude:
; Writes a channel's amplitude
;
; On entry:
;	A = channel<<6 | mode<<4 | amplitude
;-----------------------------------------------------------------------
	.proc snd_wr_channel_amplitude
		pha			; preserve mode and amplitude
		; rotate channel bits into the lowest 2 bits
		rol			; bit 7 to carry
		rol			; bit 7 to bit 0, bit 6 to carry
		rol			; bit 7 to bit 1, bit 6 to bit 0
		and #3			; two bits only
		clc
		adc #SND_AMPLITUDE	; A = register address
		sta SND_ADDR		; latch address
		pla			; recover mode and amplitude
		and #$1f		; five bits only
		sta SND_DATA		; write mode and amplitude		
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_rd_envelope_period:
; Reads the envelope period.
;
; On return:
;	A,Y = envelope period
;-----------------------------------------------------------------------
	.proc snd_rd_envelope_period
		lda #SND_ENV_PERIOD
		sta SND_ADDR		; latch LSB register address
		ldy SND_DATA		; fetch period LSB
		inc a			; A = MSB register address
		sta SND_ADDR		; latch address
		lda SND_DATA		; fetch period MSB
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_wr_envelope_period:
; Writes the envelope period.
;
; On entry:
;	A,Y = envelope period
;-----------------------------------------------------------------------
	.proc snd_wr_envelope_period
		pha			; preserve period MSB
		lda #SND_ENV_PERIOD
		sta SND_ADDR		; latch LSB register address
		sty SND_DATA		; write period LSB
		inc a			; A = MSB register address
		sta SND_ADDR		; latch address
		pla			; recover period MSB
		sta SND_DATA		; write period MSB
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_rd_envelope_shape:
; Reads the envelope shape.
;
; On return:
;	A = envelope shape
;-----------------------------------------------------------------------
	.proc snd_rd_envelope_shape
		lda #SND_ENV_SHAPE	; load register address
		sta SND_ADDR		; latch address
		lda SND_DATA		; read shape
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_wr_envelope_shape:
; Writes the envelope shape.
;
; On return:
;	A = envelope shape
;-----------------------------------------------------------------------
	.proc snd_wr_envelope_shape
		ldy #SND_ENV_SHAPE	; load register address
		sty SND_ADDR		; latch address
		sta SND_DATA		; write shape
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_rd_io_port:
; Reads an I/O port
;
; On entry:
;	A = port number (0 or 1)
; On return:
;	port value (8 bits)
;-----------------------------------------------------------------------
	.proc snd_rd_io_port
		lsr			; set carry if port B
		lda #SND_IO_PORT	; load base register address
		adc #0			; increment if port B
		sta SND_ADDR		; latch address
		lda SND_DATA		; read I/O register
		rts
	.endproc


;-----------------------------------------------------------------------
; snd_wr_io_port:
; Write an I/O port
;
; On entry:
;	A = port number (0 or 1)
;	Y = value to write
;-----------------------------------------------------------------------
	.proc snd_wr_io_port
		lsr			; set carry if port B
		lda #SND_IO_PORT	; load base register address
		adc #0			; increment if port B
		sta SND_ADDR		; latch address
		sty SND_DATA		; write I/O register
		rts
	.endproc


snd_notes:
		.word $06AE	; C 2   65.406 Hz (  65.416 Hz,  0.010%)
		.word $064E	; C#2   69.296 Hz (  69.306 Hz,  0.020%)
		.word $05F4	; D 2   73.416 Hz (  73.399 Hz, -0.020%)
		.word $059E	; D#2   77.782 Hz (  77.789 Hz,  0.010%)
		.word $054D	; E 2   82.407 Hz (  82.432 Hz,  0.030%)
		.word $0501	; F 2   87.307 Hz (  87.323 Hz,  0.020%)
		.word $04B9	; F#2   92.499 Hz (  92.523 Hz,  0.030%)
		.word $0475	; G 2   97.999 Hz (  98.037 Hz,  0.040%)
		.word $0435	; G#2  103.826 Hz ( 103.863 Hz,  0.040%)
		.word $03F9	; A 2  110.000 Hz ( 109.991 Hz, -0.010%)
		.word $03C0	; A#2  116.541 Hz ( 116.521 Hz, -0.020%)
		.word $038A	; B 2  123.471 Hz ( 123.466 Hz,  0.000%)
		.word $0357	; C 3  130.813 Hz ( 130.831 Hz,  0.010%)
		.word $0327	; C#3  138.591 Hz ( 138.613 Hz,  0.020%)
		.word $02FA	; D 3  146.832 Hz ( 146.799 Hz, -0.020%)
		.word $02CF	; D#3  155.563 Hz ( 155.578 Hz,  0.010%)
		.word $02A7	; E 3  164.814 Hz ( 164.743 Hz, -0.040%)
		.word $0281	; F 3  174.614 Hz ( 174.510 Hz, -0.060%)
		.word $025D	; F#3  184.997 Hz ( 184.894 Hz, -0.060%)
		.word $023B	; G 3  195.998 Hz ( 195.903 Hz, -0.050%)
		.word $021B	; G#3  207.652 Hz ( 207.534 Hz, -0.060%)
		.word $01FC	; A 3  220.000 Hz ( 220.198 Hz,  0.090%)
		.word $01E0	; A#3  233.082 Hz ( 233.043 Hz, -0.020%)
		.word $01C5	; B 3  246.942 Hz ( 246.933 Hz,  0.000%)
		.word $01AC	; C 4  261.626 Hz ( 261.357 Hz, -0.100%)
		.word $0194	; C#4  277.183 Hz ( 276.883 Hz, -0.110%)
		.word $017D	; D 4  293.665 Hz ( 293.597 Hz, -0.020%)
		.word $0168	; D#4  311.127 Hz ( 310.724 Hz, -0.130%)
		.word $0153	; E 4  329.628 Hz ( 329.972 Hz,  0.100%)
		.word $0140	; F 4  349.228 Hz ( 349.564 Hz,  0.100%)
		.word $012E	; F#4  369.994 Hz ( 370.399 Hz,  0.110%)
		.word $011D	; G 4  391.995 Hz ( 392.493 Hz,  0.130%)
		.word $010D	; G#4  415.305 Hz ( 415.839 Hz,  0.130%)
		.word $00FE	; A 4  440.000 Hz ( 440.396 Hz,  0.090%)
		.word $00F0	; A#4  466.164 Hz ( 466.086 Hz, -0.020%)
		.word $00E2	; B 4  493.883 Hz ( 494.959 Hz,  0.220%)
		.word $00D6	; C 5  523.251 Hz ( 522.713 Hz, -0.100%)
		.word $00CA	; C#5  554.365 Hz ( 553.765 Hz, -0.110%)
		.word $00BE	; D 5  587.330 Hz ( 588.740 Hz,  0.240%)
		.word $00B4	; D#5  622.254 Hz ( 621.448 Hz, -0.130%)
		.word $00AA	; E 5  659.255 Hz ( 658.004 Hz, -0.190%)
		.word $00A0	; F 5  698.456 Hz ( 699.129 Hz,  0.100%)
		.word $0097	; F#5  739.989 Hz ( 740.799 Hz,  0.110%)
		.word $008F	; G 5  783.991 Hz ( 782.242 Hz, -0.220%)
		.word $0087	; G#5  830.609 Hz ( 828.597 Hz, -0.240%)
		.word $007F	; A 5  880.000 Hz ( 880.792 Hz,  0.090%)
		.word $0078	; A#5  932.328 Hz ( 932.172 Hz, -0.020%)
		.word $0071	; B 5  987.767 Hz ( 989.917 Hz,  0.220%)
		.word $006B	; C 6 1046.502 Hz (1045.426 Hz, -0.100%)
		.word $0065	; C#6 1108.731 Hz (1107.531 Hz, -0.110%)
		.word $005F	; D 6 1174.659 Hz (1177.480 Hz,  0.240%)
		.word $005A	; D#6 1244.508 Hz (1242.896 Hz, -0.130%)
		.word $0055	; E 6 1318.510 Hz (1316.007 Hz, -0.190%)
		.word $0050	; F 6 1396.913 Hz (1398.258 Hz,  0.100%)
		.word $004C	; F#6 1479.978 Hz (1471.850 Hz, -0.550%)
		.word $0047	; G 6 1567.982 Hz (1575.502 Hz,  0.480%)
		.word $0043	; G#6 1661.219 Hz (1669.562 Hz,  0.500%)
		.word $0040	; A 6 1760.000 Hz (1747.822 Hz, -0.690%)
		.word $003C	; A#6 1864.655 Hz (1864.344 Hz, -0.020%)
		.word $0039	; B 6 1975.533 Hz (1962.467 Hz, -0.660%)
		.word $0035	; C 7 2093.005 Hz (2110.578 Hz,  0.840%)
		.word $0032	; C#7 2217.461 Hz (2237.213 Hz,  0.890%)
		.word $0030	; D 7 2349.318 Hz (2330.430 Hz, -0.800%)
		.word $002D	; D#7 2489.016 Hz (2485.792 Hz, -0.130%)