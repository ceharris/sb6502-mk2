;-----------------------------------------------------------------------
; reset.s
;
; This file contains a `soft_reset` reset function. It should be used
; as an include file in another source module.
;
; The syntax used here should work for either of the ca64 or 64tass
; assembler. It might also work for vasm.
;

; We're not including ports.h.s here, because include works differently
; on different assemblers.

_ACIA_CTRL := $FFF0
_ACIA_RESET := $3

_CONF_REG := $FFF4
_CONF_ROM_DISABLE = $20

_IPL_VECTOR := $F000
_PIVOT_VECTOR := $F0


;-----------------------------------------------------------------------
; pivot_fn:
; This small function is copied to the zero page and then executed to
; pivot back to the IPL program in ROM.
;
; On entry:
;       A = current mode bits for the configuation register
;
pivot_fn:
                ; clear the mode bit that disables the ROM
                and #<~_CONF_ROM_DISABLE
                sta _CONF_REG

		; jump back to the IPL program
                jmp _IPL_VECTOR

_PIVOT_FN_LENGTH := *-pivot_fn


;-----------------------------------------------------------------------
; soft_reset:
; Jump to this entry point to perform a soft reset of the system and
; go back to the IPL program.
;
; On entry:
;       A = current memory mode bits
;
soft_reset:
                pha                     ; save the mode bits
		; quiesce the system
                sei
                cld
                ; reset the ACIA used for the console
                lda #_ACIA_RESET
                sta _ACIA_CTRL

                ; copy the pivot function to low memory
                ldx #_PIVOT_FN_LENGTH
                ldy #0
copy_pivot:
                lda pivot_fn,y
                sta _PIVOT_VECTOR,y
                iny
                dex
                bne copy_pivot

                pla                     ; recover mode bits
                jmp _PIVOT_VECTOR

