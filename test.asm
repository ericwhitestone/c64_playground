; This program rapidly updates the colors
; of the screen and the border.

*=$c000   ; starting address of the program 

BORDER = $d020
SCREEN = $d021
PRINTSR = $ffd2

start   inc SCREEN  ; increase screen colour 
        inc BORDER  ; increase border colour
        jsr delay
        jmp start   ; repeat

delay   inx ; increment the x index register to 0
        txa ; store the result in accumulator
        jsr PRINTSR ;print the character that is in accumulator
        bne delay 
        rts  


