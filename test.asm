; This program rapidly updates the colors
; of the screen and the border.

*=$C000   ; starting address of the program 
            ; parameter passing and return values
PARAM0 = $9000   ; 
PARAM1 = PARAM0 + 1
PARAM2 = PARAM1 + 1
RETVAL = PARAM2 + 1
MOVE_COUNT = RETVAL + 1
BORDER = $d020
SCREEN = $d021
PRINTSR = $ffd2
SPRITE0_COLOR_REG = $D027
SPRITE_COLOR_VAL = $07
!address SPRITE0_PTR_REG = $07F8
!address SPRITE0_X = $D000
!address SPRITE0_Y = $D001
!address SPRITE1_X = $D002
!address SPRITE1_Y = $D003
!address SPRITE_MSB = $D010
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
lda #$0
sta PARAM0
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
    cpy #$3F ; Adjust this value to control sprite speed
    bne inc_ones
    rts

transform_sprite:
    ; row aliases to use the param storage
    BOTTOMROW=PARAM0  
    TOPROW=PARAM1
    CURRENTROW=PARAM2
    lda SPRITE0_BASEADDR
    sta TOPROW
    lda #$3C
    sta BOTTOMROW
new_row:
    ldy TOPROW
    sty CURRENTROW
    jsr disappear_row
    lda BOTTOMROW
    cmp TOPROW ; if the bottome row and top row are == then end sub
    beq sprite_transformed
    sta CURRENTROW
    jsr disappear_row
    ; move the bottom and top row pointers accordingly
    lda BOTTOMROW
    sbc #$3
    sta BOTTOMROW
    lda TOPROW
    adc #$3
    sta TOPROW
    jmp new_row
    ;sprite transformed ends the subroutine
sprite_transformed:
    rts

disappear_row:
    ; msb
    ; byte pos 0 on row
    ldx #$0
    lda CURRENTROW, X
    cmp #$0 ; if msb is 0 skip to the middle byte
    beq midb ; jump to the middle byte; 
            ; if this is 0 then so is the lsb
    lsr CURRENTROW, X ; shift bits right
        ; lsb
    inx
    inx ; Process the lsb
    asl CURRENTROW, X
    jmp disappear_row 
midb:
    dex
    lda #$0
    cmp CURRENTROW, X 
    beq end_row
    lda #$FF ; 1111 1111
    cmp CURRENTROW, X
    bne mid_pattern_two
    lda #$FE
    sta CURRENTROW, X
    jmp end_row
mid_pattern_two:
    lda #$FE ; 0111 1110
    cmp CURRENTROW, X
    bne mid_pattern_three
    lda #$3C
    sta CURRENTROW, x
    jmp end_row
mid_pattern_three:
    lda #$3C ; 0011 1100
    cmp CURRENTROW, X 
    bne mid_pattern_four
    lda #$18 ; 
    sta CURRENTROW, X 
mid_pattern_four:
    lda #$18 ; 0001 1000
    cmp CURRENTROW, X 
    bne end_row
    lda #$0 ; 
    sta CURRENTROW, X 
end_row:
;    inx 
;    inx
rts


; PARAM0 -  move count
main_loop:
    lda PARAM0
    sta MOVE_COUNT
run:    
    jsr delay
    ldy MOVE_COUNT
    sty PARAM0
    jsr transform_sprite
    ldy SPRITE0_X
    iny
    sty SPRITE0_X ;inc x and y to move the sprite across screen
    sty SPRITE0_Y
    inc MOVE_COUNT
    jmp run

DEBUGSTR: 
    !pet "hello, this is a c64 program! *we got here*", 0
print_debug:
    ldx #$0
print_debug_loop:

    lda DEBUGSTR, x
    cmp #$0
    beq end_print_debug
    jsr PRINTSR
    inx
    jmp print_debug_loop
end_print_debug
    rts
