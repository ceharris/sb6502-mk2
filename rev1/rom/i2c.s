
DATA_PORT = $8080
CTRL_PORT = $8081

CPIN = $80
CESO = $40
CES1 = $20
CES2 = $10
CENI = $08
CSTA = $04
CSTO = $02
CACK = $01
SPIN = CPIN
SZER = $04
SSTS = $02
SBER = $01
SLRB = $08
SAAS = $04
SLAB = $02
SBB = $01


OWN_ADDR_REG = CPIN
CLOCK_REG = CPIN | ES1
VECTOR_REG = CPIN | ES2

FN_START = CPIN | CESO | CSTA | CACK
FN_REPT_START = CECO | CSTA | CACK
FN_STOP = CPIN | CESO | CSTO | CACK
FN_NOP = CPIN | CESO | CACK

SIG_NACK = CESO

OWN_ADDR = $55
CLOCK_12MHZ_90KHZ = $1C




	.proc i2c_init
		; select register S0' (own address)
		lda #OWN_ADDR_REG
		sta CTRL_PORT
		; set our address
		lda #OWN_ADDR
		sta DATA_PORT
		; select register S2 (clock register)
		lda #CLOCK_REG
		sta CTRL_PORT
		; select 12 MHz clock input, 90 kHz serial clock
		lda #CLOCK_12MHZ_90KHZ
		sta DATA_PORT
		; enable serial interface in idle state
		lda #FN_NOP
		sta CTRL_PORT
		rts
	.endproc


;-----------------------------------------------------------------------
; i2c_master_transmit:
; Use master transmitter mode to transmit a sequence of bytes to a slave.
;
; On entry:
; 	Y,A = pointer to buffer containing (7-bit) slave address
;	      followed by the data bytes to send
;       X = total length of the buffer (address + data length)
;
; On return:
;	X = 0 if transmission completed; else X = number of bytes 
;	remaining to be sent when slave's negative acknowledgment was
;	received
;	w0 clobbered
;
	.proc i2c_master_transmit
		; put the data pointer into w0
		sta w0
		sty w0+1
		ldy #0

		; wait for I2C bus to be idle
@await_bus_idle:
		lda CTRL_PORT		; fetch status
		and #SBB		; isolate BB bit
		beq @await_bus_idle	; BB=0 indicates bus busy

		lda (w0),y		; get slave address
		asl			; shift in R/W=0
		sta DATA_PORT		; write slave address to controller
		lda FN_START		; select START
		sta CTRL_PORT		; signal START and transmit slave address
@next:
		dex
		iny
		lda CTRL_PORT		; fetch status
@await_transfer:
		asl			; put PIN bit into carry
		bcs @await_transfer	; wait for transmission to finish
		and #(SLRB << 1)	; isolate LRB bit
		bne @done		; go if slave negative ACK
		txa			; get remaining count
		beq @done		; go if we're done
		lda (w0),y		; get byte to send
		sta DATA_PORT		; transmit data byte
		jmp @next
@done:
		lda FN_STOP		; select STOP
		sta CTRL_PORT		; signal STOP and return to idle
		rts
	.endproc


;-----------------------------------------------------------------------
; i2c_master_receive:
; Use master receiver mode to receive a sequence of bytes to a slave.
;
; On entry:
; 	Y,A = pointer to buffer containing the 7-bit slave address followed
;	      by space for data bytes
;       X = total length of the buffer (including the address)
;
; On return:
;	X = remaining length of the buffer
;	w0 clobbered
;
	.proc i2c_master_receive
		; put the data pointer into w0
		sta w0
		sty w0+1
		ldy #0

		lda (w0),y		; fetch slave address
		sec
		rol			; rotate in R/W=1
		sta DATA_PORT		; write slave address to controller


		; wait for I2C bus to be idle
@await_bus_idle:
		lda CTRL_PORT		; fetch status
		and #SBB		; isolate BB bit
		beq @await_bus_idle	; BB=0 indicates bus busy

		lda FN_START		; select START
		sta CTRL_PORT		; signal START and transmit slave address
		bne @first		; go if more than one byte
@next:
		iny
@first:
		dex
		beq @last		; go if this is the last byte
		lda CTRL_PORT		; fetch status
@await_transfer:
		asl			; put PIN bit into carry
		bcs @await_transfer	; wait for transmission to finish
		and #(SLRB << 1)	; isolate LRB bit
		bne @error		; go if slave negative ACK
		lda DATA_PORT		; receive data byte
		sta (w0),y		; store received byte
		jmp @next
@last:
		; signal negative acknowledgment
		lda SIG_NACK		
		sta CTRL_PORT
		; receive and store last byte
		lda DATA_PORT
		sta (w0),y
		; wait for finish
@await_last:
		asl	
		bcs @await_last
		; signal STOP
		lda FN_STOP
		sta CTRL_PORT
@done:
		lda FN_STOP		; select STOP
		sta CTRL_PORT		; signal STOP and return to idle
		rts
	.endproc
