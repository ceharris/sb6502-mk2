                .include "timer.h.s"
                .include "zeropage.h.s"

                ; PHI2 clock has a frequency of 1.8432 MHz
                ; Divide by 100 to get a 100 Hz tick rate
                TIMER_PERIOD = 18432

timer_init:
                stz TIMER_DDDD+1
                stz TIMER_DDDD
                stz TIMER_HH
                stz TIMER_MM
                stz TIMER_SS
                stz TIMER_CC
                stz TIMER_TICKS+3
                stz TIMER_TICKS+2
                stz TIMER_TICKS+1
                stz TIMER_TICKS+0

                ; configure T1 for continuous interrupts
                lda VIA_ACR
                ora #VIA_T1_CTRL_CONT_INT
                sta VIA_ACR

                ; enable T1 interrupts
                lda VIA_IER
                ora #VIA_IER_SET | VIA_IER_T1
                sta VIA_IER

                ; configure T1 period
                lda #<TIMER_PERIOD
                sta VIA_T1CL
                lda #>TIMER_PERIOD
                sta VIA_T1CH            ; timer starts here

                rts

timer_isr:
                pha
                lda VIA_IFR
                asl                     ; carry = IRQ bit
                bcc @done               ; go if no IRQ
                asl                     ; carry = T1 bit
                bcc @done               ; go if not timer 1

                lda VIA_T1CL            ; read counter to reset interrupt

                inc TIMER_TICKS
                bne @update_chrono
                inc TIMER_TICKS + 1
                bne @update_chrono
                inc TIMER_TICKS + 2
                bne @update_chrono
                inc TIMER_TICKS + 3

@update_chrono:
                sed                     ; chrono fields are BCD
                
                ; increment centiseconds
                clc
                lda TIMER_CC
                adc #1
                sta TIMER_CC
                bcc @done

                ; increment seconds
                lda TIMER_SS
                adc #0
                sta TIMER_SS
                cmp #$60
                bne @done
                stz TIMER_SS
                sec

                ; increment minutes
                lda TIMER_MM
                adc #0
                sta TIMER_MM
                cmp #$60
                bne @done
                stz TIMER_MM
                sec

                ; increment hours
                lda TIMER_HH
                adc #0
                sta TIMER_HH
                cmp #$24
                bne @done
                stz TIMER_HH
                sec

                ; increment days
                lda TIMER_DDDD
                adc #0
                sta TIMER_DDDD
                bcc @done
                lda TIMER_DDDD+1
                adc #0
                sta TIMER_DDDD+1
@done:
                cld
                pla
                rts                     ; note this is not 'rti'
                                        ; as we expect to be called
                                        ; from vectors.s