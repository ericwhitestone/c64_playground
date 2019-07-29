; This program rapidly updates the colors
; of the screen and the border.

                *=$C000   ; starting address of the program 

                BORDER = $d020
                SCREEN = $d021
                PRINTSR = $ffd2
                SPRITE0_COLOR = $D027
                SPRITE0_PTR_REG = $07F8
                SPRITE0_X = $D000
                SPRITE0_Y = $D001
                SPRITE_MSB = $D010
                SPRITE0_PTR_VAL = $40
                SPRITE0_BASEADDR = SPRITE0_PTR_VAL*$40

                ldx #$C9     ;Set background color
                stx SCREEN ;start screen color at 0
                stx BORDER ;start border color at 0
                jsr write_pattern ;write the sprite pattern in the 64 sprite bytes
                ; set up positioning of sprite 0
                ldx #$40 ; 64d y position
                stx SPRITE0_Y
                ldx #$0 
                stx SPRITE_MSB ; msb off to start
                ldx #$40 ; 64d x position
                stx SPRITE0_X

                ldx #$FF
loop            stx $D015   ; write FF to sprite enable 
                jmp loop


; subroutines

write_pattern   lda #$6F        ;store the byte pattern for the sprite
                ldx #SPRITE0_PTR_VAL ;store the sprite pointer val in x and write to sprite pointer reg
                stx SPRITE0_PTR_REG

                ldy #$0
write_byte      sta SPRITE0_BASEADDR, Y     ; $40 * $40 (sprite pointer * 64)
                iny             ; increment the idx
                cpy #$40        ; check if 64 bytes have been written
                bne write_byte  ; keep going until we hit 64 bytes
                rts


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