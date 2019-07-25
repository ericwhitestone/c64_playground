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


delay    ldy #$0
rollover inx
         bne rollover
         iny
         tya 
         jsr PRINTSR
         bne rollover
         rts