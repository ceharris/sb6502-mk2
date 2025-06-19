        .ifndef VIA_H
                VIA_H = 1

                VIA_PA_LATCH = $1
                VIA_PB_LATCH = $2

                VIA_SR_DISABLE = $0
                VIA_SR_SHIFT_IN_T2 = $4
                VIA_SR_SHIFT_IN_PHI2 = $8
                VIA_SR_SHIFT_IN_CB1 = $c
                VIA_SR_SHIFT_OUT_FREE = $10
                VIA_SR_SHIFT_OUT_T2 = $14
                VIA_SR_SHIFT_OUT_PHI2 = $18
                VIA_SR_SHIFT_OUT_CB1 = $1c

                VIA_T2_CTRL_TIMED_INT = $0
                VIA_T2_CTRL_PULSE_COUNT = $20
                
                VIA_T1_CTRL_TIMED_INT = $0
                VIA_T1_CTRL_CONT_INT = $40
                VIA_T1_CTRL_TIMED_INT_ONE_SHOT = $80
                VIA_T1_CTRL_CONT_INT_SQU_WAVE = $c0

                VIA_IFR_IRQ = $80
                VIA_IFR_T1 = $40
                VIA_IFR_T2 = $20
                VIA_IFR_CB1 = $10
                VIA_IFR_CB2 = $8
                VIA_IFR_SR = $4
                VIA_IFR_CA1 = $2
                VIA_IFR_CA2 = $1

                VIA_IER_SET = $80
                VIA_IER_CLEAR = $00
                VIA_IER_T1 = $40
                VIA_IER_T2 = $20
                VIA_IER_CB1 = $10
                VIA_IER_CB2 = $8
                VIA_IER_SR = $4
                VIA_IER_CA1 = $2
                VIA_IER_CA2 = $1

        .endif