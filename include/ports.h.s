	.ifndef PORTS_H
		PORTS_H = 1

		IO_EXT0 = $FF00
		IO_EXT1 = $FF80 
		IO_EXT2 = $FFC0

		ACIA_BASE = $FFF0
		ACIA_CTRL = ACIA_BASE+0
		ACIA_DATA = ACIA_BASE+1
		CONF_REG = $FFF4

		CONF_M0 = $10
		CONF_M1 = $20
		CONF_M2 = $40
		
		CONF_RAM_UPPER = CONF_M0
		CONF_ROM_DISABLE = CONF_M1
		CONF_WINDOW_DISABLE = CONF_M2

		; Memory configurations
		;
		; Lower half of RAM, window enabled, ROM enabled (default mode)
		CONF_MODE_RAMLW_ROM = 0
		; Lower half of RAM, window disabled, ROM enabled
		CONF_MODE_RAML_ROM = CONF_WINDOW_DISABLE
		; Lower half of RAM, window enabled, ROM disabled
		CONF_MODE_RAMLW = CONF_ROM_DISABLE
		; Lower half of RAM, window disabled, ROM disabled
		CONF_MODE_RAML = CONF_ROM_DISABLE|CONF_WINDOW_DISABLE
		; Upper half of RAM, window enabled, ROM enabled
		CONF_MODE_RAMHW_ROM = CONF_RAM_UPPER
		; Upper half of RAM, window disabled, ROM enabled
		CONF_MODE_RAMH_ROM = CONF_RAM_UPPER|CONF_WINDOW_DISABLE
		; Upper half of RAM, window enabled, ROM disabled
		CONF_MODE_RAMHW = CONF_RAM_UPPER|CONF_ROM_DISABLE
		; Upper half of RAM, window disabled, ROM disabled
		CONF_MODE_RAMH = CONF_RAM_UPPER|CONF_ROM_DISABLE|CONF_WINDOW_DISABLE
	
	.endif
