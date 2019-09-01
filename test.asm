; This program rapidly updates the colors
; of the screen and the border.

*=$C000   ; starting address of the program 
            ; parameter passing and return values
!address PARAM0 = $9000   ; 
!address PARAM1 = PARAM0 + 1
!address PARAM2 = PARAM1 + 1
!address RETVAL = PARAM2 + 1
!address CURRENTROW = RETVAL + 1
!address GAMETICKS0=CURRENTROW+1
!address GAMETICKS1 = GAMETICKS0 + 1
!address BOTTOMROW=PARAM0  
!address TOPROW=PARAM1
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
!address SPRITE0_BASEADDR = SPRITE0_PTR_VAL*$40
!address SPRITE1_BASEADDR = SPRITE1_PTR_VAL*$40
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
    ldy #$4
inc_ones
    inx 
    cpx #$0 ; If x rolled over, increment the $10s place represented by y
    bne inc_ones
    iny
    ldx #$0 ; start the 1s place back at 0
    cpy #$07 ; Adjust this value to control sprite speed
    bne inc_ones
    rts


init_transform:
    lda #$0 ; top row idx start at 0
    sta TOPROW ; 
    lda  #$3C ;beginning of the last row (62-2)
    sta BOTTOMROW
    rts


transform_sprite:
; disappear a top and bottom row in an interleving manner
    ldx TOPROW ;check middle byte and see if 0, if it is we are done with this row set
    inx ; middle byte
    lda SPRITE0_BASEADDR, x 
    beq toprow_done ; middle byte of top row is now 0
    dex ; set x back to the begining of row
    stx CURRENTROW
    jsr transform_once ; work on top row
toprow_done:
    ldx BOTTOMROW
    inx ;check the middle byte for 0, if it's 0 this row is finished
    lda SPRITE0_BASEADDR, x 
    beq bottomrow_done
    dex
    stx CURRENTROW
    jsr transform_once ; work on bottom row
    jmp end_transform_sprite
bottomrow_done:
    lda TOPROW                ; if bottom == top don't move the pointers
    cmp BOTTOMROW             ;      TODO change this to test if toprow < bottom row 
    beq end_transform_sprite   ; in this case do nothing for now
    ldx TOPROW
    inx
    lda SPRITE0_BASEADDR, x
    bne check_bottom_row
               ; a new one on the next iteration
    lda TOPROW
    clc
    adc #$3                 ; move row pointers 
                            ; by adding 3 to the top and subbing 3 from bottom
    sta TOPROW
check_bottom_row:
    ldx BOTTOMROW
    inx
    lda SPRITE0_BASEADDR, x
    bne end_transform_sprite
    lda BOTTOMROW
    sec
    sbc #$3
    sta BOTTOMROW
end_transform_sprite:
rts


;TODO after a bit is moved, return. 
;Each cycle this will be called for the bottom and top row
;and only one bit should be transformed
transform_once:
    ; msb
    ; byte pos 0 on row
    ldx CURRENTROW
    lda SPRITE0_BASEADDR, x
    beq midb ; jump to the middle byte; 
             ; if this is 0 then so is the lsb
    lsr SPRITE0_BASEADDR, x; shift bits right
    txa ; load the pointer to accumulator to add 2
    clc
    adc #$2 ;work on the lsb
    tax 
    asl SPRITE0_BASEADDR, x
        ; lsb
    rts
midb:
    ldx CURRENTROW
    inx
    lda #$0
    cmp SPRITE0_BASEADDR, x 
    beq end_transform_once 
    lda #$FF ; 1111 1111
    cmp SPRITE0_BASEADDR, x
    bne mid_pattern_two
    lda #$FE
    sta SPRITE0_BASEADDR, x
    jmp end_transform_once
mid_pattern_two:
    lda #$FE ; 0111 1110
    cmp SPRITE0_BASEADDR, x
    bne mid_pattern_three
    lda #$3C
    sta SPRITE0_BASEADDR, x
    jmp end_transform_once
mid_pattern_three:
    lda #$3C ; 0011 1100
    cmp SPRITE0_BASEADDR, x
    bne mid_pattern_four
    lda #$18 ; 
    sta SPRITE0_BASEADDR, x 
    jmp end_transform_once
mid_pattern_four:
    lda #$18 ; 0001 1000
    cmp SPRITE0_BASEADDR, x 
    bne end_transform_once
    lda #$0 ; 
    sta SPRITE0_BASEADDR, x 
end_transform_once:
    dex ; decrement x back to begining of row
    rts

; PARAM0 -  move count
main_loop:
    jsr init_transform
    lda #$0
    sta GAMETICKS0
    sta GAMETICKS1
run:    
    jsr delay
    jsr transform_sprite
    ldy SPRITE0_X
    iny
    sty SPRITE0_X ;inc x and y to move the sprite across screen
    sty SPRITE0_Y
    ldx GAMETICKS0 ; keep track of ticks 
    clc   
    inx 
    stx GAMETICKS0
    bcc ticks_no_carry
    ldx GAMETICKS1
    inx 
    stx GAMETICKS1
ticks_no_carry:
    jsr print_debug
    jmp run



pr_hexletter:
    clc        ; add 41 to get A-F
    adc #$41
    jsr PRINTSR
    rts

; print the value stored in x, as a hexadecimal character
print_hexbyte:
    txa
    and #$F0 
    lsr 
    lsr
    lsr
    lsr
    clc 
    cmp #$10
    bcs letter_msn; branch if (0xF0 & x) >= 10
    adc #$30    
    jsr PRINTSR
    jmp ms_nibble
letter_msn: ; letter most significant nibble
    jsr pr_hexletter
ms_nibble:
    txa 
    and #$0F 
    clc 
    cmp #$10 
    bcs letter_lsn 
    adc #$30
    jsr PRINTSR
    jmp print_hex_done
letter_lsn: ; letter least significant nibble
    jsr pr_hexletter
print_hex_done:
    rts





DEBUGSTR: 
    !pet $13, "game ticks: ",  0

print_debug:
    ldx #$0
print_debug_loop:

    lda DEBUGSTR, x
    beq end_print_debug
    jsr PRINTSR
    inx
    jmp print_debug_loop
end_print_debug
;    ldx GAMETICKS1
;    jsr print_hexbyte
    ldx GAMETICKS0
    jsr print_hexbyte
    rts

