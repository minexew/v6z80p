
include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"

org     $5000

        ld      hl, uno
        LD      (hl),03h

        ld      iy, due
        LD      (IY+00h),00h

        LD      D,$02
loop:
        LD      HL, due

        ld      a, d
        sub     (hl)
        jp      po, Salto1
        xor     $80

Salto1:
        jp      m, Salto2
        ld      hl, Text
        call    kjt_print_string

        dec     d

        jr      loop

Salto2:

        xor     a
        ret

uno     ds 1
due     ds 1
Text    db "Ok2",10,13,0
