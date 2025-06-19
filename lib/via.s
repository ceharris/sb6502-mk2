                .include "via.h.s"

via_reset:
                ; disable all interrupt sources
                lda #$7f
                sta VIA_IER

                ; default state for timers, shift register, and latches
                stz VIA_ACR

                ; all ports set as inputs
                stz VIA_DDRA
                stz VIA_DDRB

                rts
