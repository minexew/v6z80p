include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

    org $5000
fnd_para
    ld a,(hl)
    or a    
    jr z,no_fn
    cp " "          
    jr nz,fn_ok
skp_spc inc hl
    jr fnd_para
    
no_fn   
    ld hl,nfn_text
    call kjt_print_string
    xor a
    ret
    
fn_ok
    ld de,filename  
cpyfn   
    ld a,(hl)
    or a
    jr z,fntex
    cp " "
    jr z,fntex
    cp "."
    jr z,fntex
    ld (de),a
    inc de
    inc hl
    jr cpyfn
    
fntex   
    ld hl,fntext
fntexlp 
    ld a,(hl)
    or a
    jr z,fntexdone
    ld (de),a
    inc hl
    inc de
    jr fntexlp

fntexdone
    
    
    ld hl,filename  
    call kjt_find_file
    jp nz,load_problem

    ld a,15 ; $1E000
    ld (vreg_vidpage),a


    ld b,0
    ld hl,fntdata
    call kjt_force_load     
    jp nz,load_problem

    in a,(sys_mem_select)
    or $40
    out (sys_mem_select),a

    ld bc,$300
    ld hl,fntdata
    ld de,video_base+$400
    ldir

	ld bc,$300		; make inverse charset (@ $1E800)
	ld hl,video_base+$400
	ld de,video_base+$800
invloop	
    ld a,(hl)
	cpl
	ld (de),a
	inc hl
	inc de
	dec bc
	ld a,b
	or c
	jr nz,invloop

    in a,(sys_mem_select)
    and $1f 
    out (sys_mem_select),a

    xor a
    ret
   
load_problem    

    ld hl,load_error_text+2
    call kjt_hex_byte_to_ascii
    ld hl,load_error_text
    call kjt_print_string
    xor a
    ret


nfn_text   
    db "Usage: chfnt [font]",11,0
fntext          
    db ".FNT",0

oldbnk
    db 0

load_error_text 
    db 11,"$xx - loading error!",11,0

filename    ds 32,0

fntdata

