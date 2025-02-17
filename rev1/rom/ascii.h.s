	.ifndef ASCII_H
	
		ASCII_H = 1

		NUL = $0
		ETX = $3
		EOT = $4
		BEL = $7
		BS = $8
		TAB = $9
		LF = $a
		FF = $c
		CR = $d
		EM = $19
		ESC = $1b
		SPC = $20
		DEL = $7f

		CTRL_C = ETX
		CTRL_D = EOT
		CTRL_Y = EM

	.endif