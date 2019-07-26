; This program rapidly updates the colors
; of the screen and the border.

*=$C000   ; starting address of the program 

BORDER = $d020
SCREEN = $d021
PRINTSR = $ffd2
SPRITE0_PTR = $07F8


write_pattern   lda #$07        ;store the byte pattern for the sprite
                ldy #$0
write_byte      sta $4640, Y      ; $8(segment multplier)*$64 + $4000
                iny             ; increment the idx
                cpy #$64        ; check if 64 bytes have been written
                bne write_byte  ; keep going until we hit 64 bytes
                rts

        ldx #$0     ;set x to 0
        stx SCREEN ;start screen color at 0
        stx BORDER ;start border color at 0
        jsr write_pattern ;write the sprite pattern in the 64 sprite bytes
        ldx #$25 ;store 8 in x,
        stx SPRITE0_PTR ; write 8 to be the value of the sprite pointer,
                        ; this is the value that is used to derive $200 used as the start of the sprite data
        ldx $FFFF
loop    stx $D015   ; write FFFF to sprite enable 
        jmp loop

;start_cycle     inc SCREEN  ; increase screen colour 
;                inc BORDER  ; increase border colour
;                jsr delay
;                jmp start_cycle   ; repeat
;
;
;delay           ldy #$0
;rollover        inx
;                bne rollover
;                iny
;                tya 
;                jsr PRINTSR
;                bne rollover
;                rts