
 include "../equates/osca.asm"
 include "../equates/kernal.asm"
 include "../equates/system.asm"
 
 ld hl,palette
 ld a,(keymaps)
 ld de,kjt_print_string
 xor a
 ret
 db "stuff:"
 incbin vol0:asmtest/data/junk.bin
 db ":end of stuff"

 