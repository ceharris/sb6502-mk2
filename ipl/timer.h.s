    .ifndef TIMER_H
            TIMER_H = 1
            .include "ports.h.s"
            .include "via.h.s"

            .global timer_init
            .global timer_isr

    .endif