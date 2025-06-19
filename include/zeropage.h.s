        .ifndef ZEROPAGE_H
                ZEROPAGE_H = 1

                ; Taliforth uses the lower part of the zero page, so we start 
                ; at the top and allocate towards the bottom.
zp_addr         .set $100

                .macro zp_var name, size
zp_addr         .set zp_addr - size
                name = zp_addr
                .endmacro

                zp_var ACIA_TAIL, 1
                zp_var ACIA_HEAD, 1

                zp_var TIMER_DDDD, 2
                zp_var TIMER_HH, 1
                zp_var TIMER_MM, 1
                zp_var TIMER_SS, 1
                zp_var TIMER_CC, 1

                zp_var TIMER_TICKS, 4
                zp_var STDIO_W0, 2
                zp_var STDIO_B1, 1
                zp_var STDIO_B0, 1
        .endif