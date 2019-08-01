; This program rapidly updates the colors
; of the screen and the border.

                *=$C000   ; starting address of the program 

                BORDER = $d020
                SCREEN = $d021
                PRINTSR = $ffd2
                SPRITE0_COLOR_REG = $D027
                SPRITE_COLOR_VAL = $07
                SPRITE0_PTR_REG = $07F8
                SPRITE0_X = $D000
                SPRITE0_Y = $D001
                SPRITE1_X = $D002
                SPRITE1_Y = $D003
                SPRITE_MSB = $D010
                ;when using bank 0, addresses $1000 - $1FFF are unuable for video
                ; sprite blocks $40 - $7F
                SPRITE0_PTR_VAL = $3F 
                SPRITE1_PTR_VAL = $3F
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
                jsr position_color_sprite  
                ldx #$40
                ldy #$1
                jsr position_color_sprite  
                
                ;all sprite cfg
                ldx #$03
                stx $D015   ; write FF to sprite enable 
                ldx #$0 
                stx SPRITE_MSB ; msb off to start
                jsr main_loop


; subroutines

write_pattern   
    lda #$FF ;store the byte pattern for the sprite
    ldx #SPRITE0_PTR_VAL ;store the sprite pointer val in x and write to sprite pointer reg
    stx SPRITE0_PTR_REG   ; set sprite 0 data location
    stx SPRITE0_PTR_REG+1 ; set sprite 1 data location
    ldy #$0
write_byte      
    sta SPRITE0_BASEADDR, Y ; write the pattern in a to the 64 bytes of the sprit register, indexed by y
    iny             ; increment the idx
    cpy #$40        ; check if 64 bytes have been written
    bne write_byte  ; keep going until we hit 64 bytes
    rts

; Position sprite
; parameters
; x regsister - stepping to be added to the positions
; y sprite # 0-8
; set up positioning of sprite y
position_color_sprite
                          ; First use y to index into the color reg, they are stepped by 1
                          ; Then, shift y to multiply by 2 because position registers step by 2 for each sprite
                          ; since x and y positions are adjacent
    lda #SPRITE_COLOR_VAL ;load the color val in a
    sta SPRITE0_COLOR_REG, Y ; write the color val in this indexed sprite color reg
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

; count to $FFFF using x and y registers
delay:
    ldx #$0
    ldy #$0
inc_ones
    inx 
    cpx #$0 ; If x rolled over, increment the $10s place represented by y
    bne inc_ones
    iny
    ldx #$0 ; start the 1s place back at 0
    cpy #$0F ; Adjust this value to control sprite speed
    bne inc_ones
    rts
    

main_loop:
    jsr delay
move_sprite:
    ldy SPRITE0_X
    iny
    sty SPRITE0_X
    sty SPRITE0_Y
    jmp main_loop
