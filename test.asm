; This program rapidly updates the colors
; of the screen and the border.

*=$C000   ; starting address of the program 

BORDER = $d020
SCREEN = $d021
PRINTSR = $ffd2

start   inc SCREEN  ; increase screen colour 
        inc BORDER  ; increase border colour
        jsr delay
        jmp start   ; repeat

delay   ldx #$0 
round   iny ; increment the x index register to 0
        ;jsr PRINTSR ;print the character that is in accumulator
        bne round
        txa
        jsr PRINTSR
        inx
        bne round
        rts  


