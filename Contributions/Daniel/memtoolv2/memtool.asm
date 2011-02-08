; ram cleaner/randomizer - d.illgen 20110802
;
; writes to:
; main-ram   05000h-7ffffh 
; video-ram  00000h-7ffffh 
; sprite-ram 00000h-1ffffh - twice ;)
;

sys_mem_select equ 0
vreg_vidpage equ 0206h

    org  05000h
    di
    ld   de,013fh
    ld   a,%11000000
    out  (sys_mem_select),a
vidbankloop
    ld   a,e
    ld   (0),a
    ld   (vreg_vidpage),a
    or   080h
    and  09fh
    ld   (vreg_vidpage),a
    ld   hl,01000h
    ld   bc,03000h
    call fillloop
    dec  e
    ld   a,e
    cp   0ffh
    jp   nz,vidbankloop

    ld   de,010fh
bankloop
    ld   a,e
    out  (sys_mem_select),a
    ld   hl,08000h
    ld   bc,08000h
    call fillloop
    dec  e
    ld   a,e
    ld   (1),a
    jp   nz,bankloop
    ld   hl,prgend
    ld   bc,08000h-prgend

fillloop
 if clearmem
    xor  a
 else
    ld   a,d
    and  0b8h
    scf
    jp   po,noclr
    ccf
noclr
    ld   a,d
    rla
    ld   d,a
 endif
    ld   (hl),a
    cpi  
    jp   pe,fillloop
    xor  a
    ld   a,0ffh
    ei
    ret

prgend
