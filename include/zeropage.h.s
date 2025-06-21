        .ifndef ZEROPAGE_H
                ZEROPAGE_H = 1

        .ifdef ZP_MSBASIC
                ; MSBASIC makes a mess of upper zero page
                ; so we use a paragraph starting at 0 and
                ; allocate towards the top
zp_addr         .set 0

                .macro zp_var name, size
                name = zp_addr
zp_addr         .set zp_addr + size
                .endmacro

        .else
                ; Taliforth uses the lower part of the zero page, so we start 
                ; at the top and allocate towards the bottom.
zp_addr         .set $100

                .macro zp_var name, size
zp_addr         .set zp_addr - size
                name = zp_addr
                .endmacro
        .endif


                zp_var ACIA_TAIL, 1
                zp_var ACIA_HEAD, 1
                zp_var ACIA_BREAK, 2

                zp_var TIMER_DDDD, 2
                zp_var TIMER_HH, 1
                zp_var TIMER_MM, 1
                zp_var TIMER_SS, 1
                zp_var TIMER_CC, 1

                zp_var TIMER_TICKS, 4

                .ifndef ZP_MSBASIC
                zp_var STDIO_W0, 2
                zp_var STDIO_B1, 1
                zp_var STDIO_B0, 1
                .endif

        .endif