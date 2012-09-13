
 include "osca.asm"
 include "kernal.asm"
 include "system.asm"
 
 ld hl,palette
 ld a,(keymaps)
 ld de,kjt_print_string
 xor a
 ret
 db "stuff:"
 incbin junk.bin
 db ":end of stuff"

 