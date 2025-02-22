.segment "CODE"
; ----------------------------------------------------------------------------
; "STR$" FUNCTION
; ----------------------------------------------------------------------------
STR:
        jsr     CHKNUM
        ldy     #$00
        jsr     FOUT1
        pla
        pla
LD353:
        lda     #<(STACK2-1)
        ldy     #>(STACK2-1)
.if STACK2 > $0100
        bne     STRLIT
.else
        beq     STRLIT
.endif
        
; ----------------------------------------------------------------------------
; GET SPACE AND MAKE DESCRIPTOR FOR STRING WHOSE
; ADDRESS IS IN FAC+3,4 AND WHOSE LENGTH IS IN A-REG
; ----------------------------------------------------------------------------
STRINI:
        ; get the address of the descriptor
        ldx     FAC_LAST-1
        ldy     FAC_LAST
        ; copy descriptor address to DSCPTR
        stx     DSCPTR
        sty     DSCPTR+1

; ----------------------------------------------------------------------------
; GET SPACE AND MAKE DESCRIPTOR FOR STRING WHOSE
; ADDRESS IS IN Y,X AND WHOSE LENGTH IS IN A-REG
; ----------------------------------------------------------------------------
STRSPA:
        jsr     GETSPA
        stx     FAC+1                   ; store LSB of allocated space
        sty     FAC+2                   ; store MSB of allocated space
        sta     FAC                     ; store length of allocated space
        rts

; ----------------------------------------------------------------------------
; BUILD A DESCRIPTOR FOR STRING STARTING AT Y,A
; AND TERMINATED BY $00 OR QUOTATION MARK
; RETURN WITH DESCRIPTOR IN A TEMPORARY
; AND ADDRESS OF DESCRIPTOR IN FAC+3,4
; ----------------------------------------------------------------------------
STRLIT:
        ldx     #$22
        stx     CHARAC
        stx     ENDCHR

; ----------------------------------------------------------------------------
; BUILD A DESCRIPTOR FOR STRING STARTING AT Y,A
; AND TERMINATED BY $00, (CHARAC), OR (ENDCHR)
;
; RETURN WITH DESCRIPTOR IN A TEMPORARY
; AND ADDRESS OF DESCRIPTOR IN FAC+3,4
; ----------------------------------------------------------------------------
STRLT2:
        ; save address of the string so we can index it
        sta     STRNG1
        sty     STRNG1+1
        ; put the address of the string into FAC
        sta     FAC+1
        sty     FAC+2
        ldy     #$FF                            ; initialize length counter
L3298:
        iny                                     ; increment length counter
        lda     (STRNG1),y                      ; fetch next character of string
        beq     L32A9                           ; go if ASCII NUL
        cmp     CHARAC                          
        beq     L32A5                           ; go if matches CHARAC
        cmp     ENDCHR                          
        bne     L3298                           ; continue if doesn't match ENDCHR
L32A5:
        cmp     #$22
        beq     L32AA                           ; go if we matched on ASCII quote
L32A9:
        clc                                     ; clear carry if we matched on NUL or not quote
L32AA:
        sty     FAC                             ; save string length
        tya                                     ; A = length
        adc     STRNG1                          ; A = LSB of end of string
        sta     STRNG2                          ; store string end LSB
        ldx     STRNG1+1                        ; X = MSB of string
        bcc     L32B6                           ; go if same memory page
        inx                                     ; end is in next memory page
L32B6:
        stx     STRNG2+1                        ; store string end MSB
        lda     STRNG1+1                        ; fetch MSB of string
.ifdef CONFIG_NO_INPUTBUFFER_ZP
        beq     LD399
        cmp     #>INPUTBUFFER
.endif
        ; go store descriptor in temp descriptor stack 
        ; (but only if string not in zero page?)
        bne     PUTNEW
LD399:
        ; if string is in the zero page, make space for it and relocate it
        tya                                     ; A = string length
        jsr     STRINI                          ; allocate space
        ldx     STRNG1                          ; X = LSB of the source string
        ldy     STRNG1+1                        ; Y = MSB of the source string
        jsr     MOVSTR                          ; copy string to new location

; ----------------------------------------------------------------------------
; STORE DESCRIPTOR IN TEMPORARY DESCRIPTOR STACK
;
; THE DESCRIPTOR IS NOW IN FAC, FAC+1, FAC+2
; PUT ADDRESS OF TEMP DESCRIPTOR IN FAC+3,4 (or FAC+2,3 in small model)
; ----------------------------------------------------------------------------
PUTNEW:
        ldx     TEMPPT                  ; get current temp stack pointer 
        cpx     #TEMPST+9               ; compare to end of stack
        bne     PUTEMP                  ; go if stack not exhausted
        ldx     #ERR_FRMCPX             ; load error code
JERR:
        jmp     ERROR                   ; raise error
PUTEMP:
        lda     FAC                     ; A = string length
        sta     0,x                     ; store length in temp descriptor entry
        lda     FAC+1                   ; A = LSB of string address
        sta     1,x                     ; store LSB in temp descriptor entry
        lda     FAC+2                   ; A = MSB of string address
        sta     2,x                     ; store LSB in temp descriptor entry
        ldy     #$00                    
        stx     FAC_LAST-1              ; put LSB of descriptor into FAC
        sty     FAC_LAST                ; put MSB (zero page) of descriptor into FAC
.ifdef CONFIG_2
        sty     FACEXTENSION            ; zero out FACEXTENSION (why?)
.endif
        dey                             ; Y = $FF
        sty     VALTYP                  ; VALTYP = $FF (string)
        stx     LASTPT                  ; save previous temp stack pointer
        ; TEMPPT += 3 to account for new entry
        inx                            
        inx
        inx
        stx     TEMPPT                  ; store new temp stack pointer
        rts

; ----------------------------------------------------------------------------
; MAKE SPACE FOR STRING AT BOTTOM OF STRING SPACE
; (A)=# BYTES SPACE TO MAKE
;
; RETURN WITH (A) SAME,
;	AND Y,X = ADDRESS OF SPACE ALLOCATED
; ----------------------------------------------------------------------------
GETSPA:
        lsr     DATAFLG
L32F1:
        pha                             ; preserve length

        ; set Y,A = FRETOP - length to allocate
        eor     #$FF
        sec
        adc     FRETOP
        ldy     FRETOP+1
        bcs     L32FC
        dey

L32FC:
        cpy     STREND+1                ; range check
        bcc     L3311                   ; go if space exhausted
        bne     L3306                   
        cmp     STREND                  ; range check
        bcc     L3311                   ; go if space exhausted
L3306:
        sta     FRETOP                  ; save new FRETOP value
        sty     FRETOP+1
        ; store the address of the allocated space for use in MOVSTR
        sta     FRESPC                 
        sty     FRESPC+1
        tax                             ; X = LSB of allocated space
        pla                             ; recover length
        rts
L3311:
        ldx     #ERR_MEMFULL            ; error code
        lda     DATAFLG                 
        bmi     JERR                    ; raise error if we already cleaned up
        jsr     GARBAG                  ; clean up the garbage
        lda     #$80            
        sta     DATAFLG                 ; reset DATAFLG
        pla                             ; recover length
        bne     L32F1                   ; try again

; ----------------------------------------------------------------------------
; SHOVE ALL REFERENCED STRINGS AS HIGH AS POSSIBLE
; IN MEMORY (AGAINST HIMEM), FREEING UP SPACE
; BELOW STRING AREA DOWN TO STREND.
; ----------------------------------------------------------------------------
GARBAG:

.ifdef CONST_MEMSIZ
        ldx     #<CONST_MEMSIZ
        lda     #>CONST_MEMSIZ
.else
        ldx     MEMSIZ
        lda     MEMSIZ+1
.endif
FINDHIGHESTSTRING:
        stx     FRETOP
        sta     FRETOP+1
        ldy     #$00
        sty     FNCNAM+1
.ifdef CONFIG_2
        sty     FNCNAM	; GC bugfix!
.endif
        lda     STREND
        ldx     STREND+1
        sta     LOWTR
        stx     LOWTR+1
        lda     #TEMPST
        ldx     #$00
        sta     INDEX
        stx     INDEX+1
L333D:
        cmp     TEMPPT
        beq     L3346
        jsr     CHECK_VARIABLE
        beq     L333D
L3346:
        lda     #BYTES_PER_VARIABLE
        sta     DSCLEN
        lda     VARTAB
        ldx     VARTAB+1
        sta     INDEX
        stx     INDEX+1
L3352:
        cpx     ARYTAB+1
        bne     L335A
        cmp     ARYTAB
        beq     L335F
L335A:
        jsr     CHECK_SIMPLE_VARIABLE
        beq     L3352
L335F:
        sta     HIGHDS
        stx     HIGHDS+1
        lda     #$03	; OSI GC bugfix -> $04 ???
        sta     DSCLEN
L3367:
        lda     HIGHDS
        ldx     HIGHDS+1
L336B:
        cpx     STREND+1
        bne     L3376
        cmp     STREND
        bne     L3376
        jmp     MOVE_HIGHEST_STRING_TO_TOP
L3376:
        sta     INDEX
        stx     INDEX+1
.ifdef CONFIG_SMALL
        ldy     #$01
.else
        ldy     #$00
        lda     (INDEX),y
        tax
        iny
.endif
        lda     (INDEX),y
        php
        iny
        lda     (INDEX),y
        adc     HIGHDS
        sta     HIGHDS
        iny
        lda     (INDEX),y
        adc     HIGHDS+1
        sta     HIGHDS+1
        plp
        bpl     L3367
.ifndef CONFIG_SMALL
        txa
        bmi     L3367
.endif
        iny
        lda     (INDEX),y
  .ifdef CONFIG_11
        ldy     #$00	; GC bugfix
  .endif
        asl     a
        adc     #$05
        adc     INDEX
        sta     INDEX
        bcc     L33A7
        inc     INDEX+1
L33A7:
        ldx     INDEX+1
L33A9:
        cpx     HIGHDS+1
        bne     L33B1
        cmp     HIGHDS
        beq     L336B
L33B1:
        jsr     CHECK_VARIABLE
        beq     L33A9

; ----------------------------------------------------------------------------
; PROCESS A SIMPLE VARIABLE
; ----------------------------------------------------------------------------
CHECK_SIMPLE_VARIABLE:
.ifndef CONFIG_SMALL
        lda     (INDEX),y
        bmi     CHECK_BUMP
.endif
        iny
        lda     (INDEX),y
        bpl     CHECK_BUMP
        iny

; ----------------------------------------------------------------------------
; IF STRING IS NOT EMPTY, CHECK IF IT IS HIGHEST
; ----------------------------------------------------------------------------
CHECK_VARIABLE:
        lda     (INDEX),y
        beq     CHECK_BUMP
        iny
        lda     (INDEX),y
        tax
        iny
        lda     (INDEX),y
        cmp     FRETOP+1
        bcc     L33D5
        bne     CHECK_BUMP
        cpx     FRETOP
        bcs     CHECK_BUMP
L33D5:
        cmp     LOWTR+1
        bcc     CHECK_BUMP
        bne     L33DF
        cpx     LOWTR
        bcc     CHECK_BUMP
L33DF:
        stx     LOWTR
        sta     LOWTR+1
        lda     INDEX
        ldx     INDEX+1
        sta     FNCNAM
        stx     FNCNAM+1
        lda     DSCLEN
        sta     Z52

; ----------------------------------------------------------------------------
; ADD (DSCLEN) TO PNTR IN INDEX
; RETURN WITH Y=0, PNTR ALSO IN X,A
; ----------------------------------------------------------------------------
CHECK_BUMP:
        lda     DSCLEN
        clc
        adc     INDEX
        sta     INDEX
        bcc     L33FA
        inc     INDEX+1
L33FA:
        ldx     INDEX+1
        ldy     #$00
        rts

; ----------------------------------------------------------------------------
; FOUND HIGHEST NON-EMPTY STRING, SO MOVE IT
; TO TOP AND GO BACK FOR ANOTHER
; ----------------------------------------------------------------------------
MOVE_HIGHEST_STRING_TO_TOP:
.ifdef CONFIG_2
        lda     FNCNAM+1	; GC bugfix
        ora     FNCNAM
.else
        ldx     FNCNAM+1
.endif
        beq     L33FA
        lda     Z52
.ifndef CONFIG_10A
        sbc     #$03
.else
        and     #$04
.endif
        lsr     a
        tay
        sta     Z52
        lda     (FNCNAM),y
        adc     LOWTR
        sta     HIGHTR
        lda     LOWTR+1
        adc     #$00
        sta     HIGHTR+1
        lda     FRETOP
        ldx     FRETOP+1
        sta     HIGHDS
        stx     HIGHDS+1
        jsr     BLTU2
        ldy     Z52
        iny
        lda     HIGHDS
        sta     (FNCNAM),y
        tax
        inc     HIGHDS+1
        lda     HIGHDS+1
        iny
        sta     (FNCNAM),y
        jmp     FINDHIGHESTSTRING

; ----------------------------------------------------------------------------
; CONCATENATE TWO STRINGS
; ----------------------------------------------------------------------------
CAT:
        lda     FAC_LAST
        pha
        lda     FAC_LAST-1
        pha
        jsr     FRM_ELEMENT
        jsr     CHKSTR
        pla
        sta     STRNG1
        pla
        sta     STRNG1+1
        ldy     #$00
        lda     (STRNG1),y
        clc
        adc     (FAC_LAST-1),y
        bcc     L3454
        ldx     #ERR_STRLONG
        jmp     ERROR
L3454:
        jsr     STRINI
        jsr     MOVINS
        lda     DSCPTR
        ldy     DSCPTR+1
        jsr     FRETMP
        jsr     MOVSTR1
        lda     STRNG1
        ldy     STRNG1+1
        jsr     FRETMP
        jsr     PUTNEW
        jmp     FRMEVL2

; ----------------------------------------------------------------------------
; GET STRING DESCRIPTOR POINTED AT BY (STRNG1)
; AND MOVE DESCRIBED STRING TO (FRESPC)
; ----------------------------------------------------------------------------
MOVINS:
        ldy     #$00
        lda     (STRNG1),y
        pha
        iny
        lda     (STRNG1),y
        tax
        iny
        lda     (STRNG1),y
        tay
        pla

; ----------------------------------------------------------------------------
; MOVE STRING AT (Y,X) WITH LENGTH (A)
; TO DESTINATION WHOSE ADDRESS IS IN FRESPC,FRESPC+1
; ----------------------------------------------------------------------------
MOVSTR:
        ; set up base source address to index
        stx     INDEX                   
        sty     INDEX+1
MOVSTR1:
        tay                             ; Y = string length
        beq     L3490                   ; go if empty string?
        pha                             ; preserve length
        ; copy the string from source to destination
L3487:
        dey                             ; decrement remaining length
        lda     (INDEX),y               ; copy from source
        sta     (FRESPC),y              ; to destination
        tya                             ; A = remaining length
        bne     L3487                   ; continue until done
        pla                             ; recover length
L3490:
        ; add string length to FRESPC
        clc                             
        adc     FRESPC                  
        sta     FRESPC
        bcc     L3499
        inc     FRESPC+1
L3499:
        rts

; ----------------------------------------------------------------------------
; IF (FAC) IS A TEMPORARY STRING, RELEASE DESCRIPTOR
; ----------------------------------------------------------------------------
FRESTR:
        jsr     CHKSTR

; ----------------------------------------------------------------------------
; IF STRING DESCRIPTOR POINTED TO BY FAC+3,4 IS
; A TEMPORARY STRING, RELEASE IT.
; ----------------------------------------------------------------------------
FREFAC:
        lda     FAC_LAST-1
        ldy     FAC_LAST

; ----------------------------------------------------------------------------
; IF STRING DESCRIPTOR WHOSE ADDRESS IS IN Y,A IS
; A TEMPORARY STRING, RELEASE IT.
; RETURNS WITH Y, X and INDEX = address of the string, and A = string length
; ----------------------------------------------------------------------------
FRETMP:
        ; point INDEX to the descriptor
        sta     INDEX
        sty     INDEX+1
        jsr     FRETMS                  ; sets Z if a temporary string
        php
        ldy     #$00
        lda     (INDEX),y               ; A = string length
        pha                             ; preserve length
        iny                              
        lda     (INDEX),y               ; A = LSB of string address
        tax                             ; X = LSB of string address
        iny                     
        lda     (INDEX),y               ; A = MSB of string address
        tay                             ; Y = MSB of string address
        pla                             ; recover string length
        plp                             ; recover flags from FRETMS
        bne     L34CD                   ; go if the not a temp string
        ; release memory allocated for the string if possible
        cpy     FRETOP+1
        bne     L34CD
        cpx     FRETOP
        bne     L34CD
        pha                             ; preserve string length
        clc
        adc     FRETOP
        sta     FRETOP
        bcc     L34CC
        inc     FRETOP+1
L34CC:
        pla
L34CD:
        ; point INDEX to the address of the string
        stx     INDEX
        sty     INDEX+1
        rts

; ----------------------------------------------------------------------------
; RELEASE TEMPORARY DESCRIPTOR IF Y,A = LASTPT
; ----------------------------------------------------------------------------
FRETMS:
        cpy     LASTPT+1
        bne     L34E2
        cmp     LASTPT
        bne     L34E2
        sta     TEMPPT
        sbc     #$03
        sta     LASTPT
        ldy     #$00                    ; set zero flag if it was a temp
L34E2:
        rts

; ----------------------------------------------------------------------------
; "CHR$" FUNCTION
; ----------------------------------------------------------------------------
CHRSTR:
        jsr     CONINT
        txa
        pha
        lda     #$01
        jsr     STRSPA
        pla
        ldy     #$00
        sta     (FAC+1),y
        pla
        pla
        jmp     PUTNEW

; ----------------------------------------------------------------------------
; "LEFT$" FUNCTION
; ----------------------------------------------------------------------------
LEFTSTR:
        jsr     SUBSTRING_SETUP
        cmp     (DSCPTR),y
        tya
SUBSTRING1:
        bcc     L3503
        lda     (DSCPTR),y
        tax
        tya
L3503:
        pha
SUBSTRING2:
        txa
SUBSTRING3:
        pha
        jsr     STRSPA
        lda     DSCPTR
        ldy     DSCPTR+1
        jsr     FRETMP
        pla
        tay
        pla
        clc
        adc     INDEX
        sta     INDEX
        bcc     L351C
        inc     INDEX+1
L351C:
        tya
        jsr     MOVSTR1
        jmp     PUTNEW

; ----------------------------------------------------------------------------
; "RIGHT$" FUNCTION
; ----------------------------------------------------------------------------
RIGHTSTR:
        jsr     SUBSTRING_SETUP
        clc
        sbc     (DSCPTR),y
        eor     #$FF
        jmp     SUBSTRING1

; ----------------------------------------------------------------------------
; "MID$" FUNCTION
; ----------------------------------------------------------------------------
MIDSTR:
        lda     #$FF
        sta     FAC_LAST
        jsr     CHRGOT
        cmp     #$29
        beq     L353F
        jsr     CHKCOM
        jsr     GETBYT
L353F:
        jsr     SUBSTRING_SETUP
.ifdef CONFIG_2
        beq     GOIQ
.endif
        dex
        txa
        pha
        clc
        ldx     #$00
        sbc     (DSCPTR),y
        bcs     SUBSTRING2
        eor     #$FF
        cmp     FAC_LAST
        bcc     SUBSTRING3
        lda     FAC_LAST
        bcs     SUBSTRING3

; ----------------------------------------------------------------------------
; COMMON SETUP ROUTINE FOR LEFT$, RIGHT$, MID$:
; REQUIRE ")"; POP RETURN ADRS, GET DESCRIPTOR
; ADDRESS, GET 1ST PARAMETER OF COMMAND
; ----------------------------------------------------------------------------
SUBSTRING_SETUP:
        jsr     CHKCLS
        pla
.ifndef CONFIG_11
        sta     JMPADRS+1
        pla
        sta     JMPADRS+2
.else
        tay
        pla
        sta     Z52
.endif
        pla
        pla
        pla
        tax
        pla
        sta     DSCPTR
        pla
        sta     DSCPTR+1
.ifdef CONFIG_11
        lda     Z52
        pha
        tya
        pha
.endif
        ldy     #$00
        txa
.ifndef CONFIG_2
        beq     GOIQ
.endif
.ifndef CONFIG_11
        inc     JMPADRS+1
        jmp     (JMPADRS+1)
.else
        rts
.endif

; ----------------------------------------------------------------------------
; "LEN" FUNCTION
; ----------------------------------------------------------------------------
LEN:
        jsr     GETSTR
SNGFLT1:
        jmp     SNGFLT

; ----------------------------------------------------------------------------
; IF LAST RESULT IS A TEMPORARY STRING, FREE IT
; MAKE VALTYP NUMERIC, RETURN LENGTH IN Y-REG
; ----------------------------------------------------------------------------
GETSTR:
        jsr     FRESTR
        ldx     #$00
        stx     VALTYP
        tay
        rts

; ----------------------------------------------------------------------------
; "ASC" FUNCTION
; ----------------------------------------------------------------------------
ASC:
        jsr     GETSTR
        beq     GOIQ
        ldy     #$00
        lda     (INDEX),y
        tay
.ifndef CONFIG_11A
        jmp     SNGFLT1
.else
        jmp     SNGFLT
.endif
; ----------------------------------------------------------------------------
GOIQ:
        jmp     IQERR

; ----------------------------------------------------------------------------
; SCAN TO NEXT CHARACTER AND CONVERT EXPRESSION
; TO SINGLE BYTE IN X-REG
; ----------------------------------------------------------------------------
GTBYTC:
        jsr     CHRGET

; ----------------------------------------------------------------------------
; EVALUATE EXPRESSION AT TXTPTR, AND
; CONVERT IT TO SINGLE BYTE IN X-REG
; ----------------------------------------------------------------------------
GETBYT:
        jsr     FRMNUM

; ----------------------------------------------------------------------------
; CONVERT (FAC) TO SINGLE BYTE INTEGER IN X-REG
; ----------------------------------------------------------------------------
CONINT:
        jsr     MKINT
        ldx     FAC_LAST-1
        bne     GOIQ
        ldx     FAC_LAST
        jmp     CHRGOT

; ----------------------------------------------------------------------------
; "VAL" FUNCTION
; ----------------------------------------------------------------------------
VAL:
        jsr     GETSTR
        bne     L35AC
        jmp     ZERO_FAC
L35AC:
        ldx     TXTPTR
        ldy     TXTPTR+1
        stx     STRNG2
        sty     STRNG2+1
        ldx     INDEX
        stx     TXTPTR
        clc
        adc     INDEX
        sta     DEST
        ldx     INDEX+1
        stx     TXTPTR+1
        bcc     L35C4
        inx
L35C4:
        stx     DEST+1
        ldy     #$00
        lda     (DEST),y
        pha
        lda     #$00
        sta     (DEST),y
        jsr     CHRGOT
        jsr     FIN
        pla
        ldy     #$00
        sta     (DEST),y

; ----------------------------------------------------------------------------
; COPY STRNG2 INTO TXTPTR
; ----------------------------------------------------------------------------
POINT:
        ldx     STRNG2
        ldy     STRNG2+1
        stx     TXTPTR
        sty     TXTPTR+1
        rts

