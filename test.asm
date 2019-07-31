; This program rapidly updates the colors
; of the screen and the border.

                *=$C000   ; starting address of the program 
;
                BORDER = $d020
                SCREEN = $d021
                PRINTSR = $ffd2
                SPRITE0_COLOR = $D027
                SPRITE0_PTR_REG = $07F8
                SPRITE1_PTR_REG = $07F9
                SPRITE0_X = $D000
                SPRITE0_Y = $D001
                SPRITE1_X = $D002
                SPRITE1_Y = $D003
                SPRITE_MSB = $D010
                SPRITE0_PTR_VAL = $40 ;$F0 $20 works, $40 $60 does not
                SPRITE1_PTR_VAL = $40
                SPRITE0_BASEADDR = SPRITE0_PTR_VAL*$40
                SPRITE1_BASEADDR = SPRITE1_PTR_VAL*$40
                CLEAR_SCREEN = $FF81

                jsr CLEAR_SCREEN 
                ldx #$00     ;Set background color
                stx SCREEN ;start screen color at 0
                stx BORDER ;start border color at 0
                jsr write_pattern ;write the sprite pattern in the 64 sprite bytes
                ldx #$1
                ldy #$0
                jsr position_sprite  
                ldx #$40
                ldy #$1
                jsr position_sprite  
                
                ;all sprite cfg
                ldx #$03
                stx $D015   ; write FF to sprite enable 
                ldx #$0 
                stx SPRITE_MSB ; msb off to start

loop            jmp loop


; subroutines

write_pattern   lda #$FF ;store the byte pattern for the sprite
                ldx #SPRITE0_PTR_VAL ;store the sprite pointer val in x and write to sprite pointer reg
                stx SPRITE0_PTR_REG
                rts

                ldy #$0
write_byte      sta SPRITE0_BASEADDR, Y ; write the pattern in a to the 64 bytes of the sprit register, indexed by y
                iny             ; increment the idx
                cpy #$40        ; check if 64 bytes have been written
                bne write_byte  ; keep going until we hit 64 bytes
                rts

; Position sprite
; parameters
; x regsister - stepping to be added to the positions
; y sprite # 0-8
; set up positioning of sprite y
position_sprite 
    tya  ; multiply the sprite # by 2
    asl 
    tay
    txa  ; load the arg into a
    adc #$40  ; 64d y position + stepping stored in accumulator
    sta SPRITE0_Y, Y
    txa  ; init a with stepping arg again 
    adc #$70 ;  add the stepping to x pos
    sta SPRITE0_X, Y ;write x position
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