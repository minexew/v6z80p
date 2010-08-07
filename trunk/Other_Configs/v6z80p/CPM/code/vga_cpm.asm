
; Tests the 80 x 25 VGA charmap mode in the OSCAF660 varient for CP/M shenanigans.


;---Standard header for OSCA and OS -----------------------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	call kjt_get_version	; is the OSCA version = $Fxxx?
	ld a,d
	and $f0
	cp $f0
	jr z,cpm_osca		; if so, go to CP/M code
	
	xor a
	ret			; if not just exit quietly

;----------------------------------------------------------------------------------------	

cpm_osca

	xor a			;Make VRAM writes go to the first 8KB 
	ld (vreg_vidpage),a		;(80x25 charmap at VRAM $00000-$007cf)
		
	ld a,%01000000
	out (sys_mem_select),a	;Page in the video RAM to $2000

	ld hl,test_text		;copy some text to the charmap
	ld de,video_base
	ld bc,80*25
	ldir

my_loop	ld a,%00000000
	out (sys_mem_select),a	;Page out the video RAM

	call kjt_wait_key_press	;wait for key press
	
	ld a,%01000000
	out (sys_mem_select),a	;Page in the video RAM

	ld hl,video_base+1		;scroll text through video memory
	ld de,video_base		;on every keypress
	ld a,(de)
	ld bc,0+(80*25)-1
	ldir
	ld (video_base+$7cf),a
	jr my_loop
	


;----------------------------------------------------------------------------------------

test_text

	db "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
	db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.."
	db "It's a line of text thats exactly 80 characters long - trollolololo and whatever"
	db "Badgers badgers badgers badgers.. mushroom mushroom... snake! SNAAAKKKE??!??!?!!"
	db "Wibble hatstand wombats 4 dimensional hypercubes... aaaannnd relax, I mean loop."
	
	db "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
	db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.."
	db "It's a line of text thats exactly 80 characters long - trollolololo and whatever"
	db "Badgers badgers badgers badgers.. mushroom mushroom... snake! SNAAAKKKE??!??!?!!"
	db "Wibble hatstand wombats 4 dimensional hypercubes... aaaannnd relax, I mean loop."
	
	db "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
	db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.."
	db "It's a line of text thats exactly 80 characters long - trollolololo and whatever"
	db "Badgers badgers badgers badgers.. mushroom mushroom... snake! SNAAAKKKE??!??!?!!"
	db "Wibble hatstand wombats 4 dimensional hypercubes... aaaannnd relax, I mean loop."
	
	db "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
	db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.."
	db "It's a line of text thats exactly 80 characters long - trollolololo and whatever"
	db "Badgers badgers badgers badgers.. mushroom mushroom... snake! SNAAAKKKE??!??!?!!"
	db "Wibble hatstand wombats 4 dimensional hypercubes... aaaannnd relax, I mean loop."
	
	db "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
	db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.."
	db "It's a line of text thats exactly 80 characters long - trollolololo and whatever"
	db "Badgers badgers badgers badgers.. mushroom mushroom... snake! SNAAAKKKE??!??!?!!"
	db "Wibble hatstand wombats 4 dimensional hypercubes... aaaannnd relax, I mean loop."

;----------------------------------------------------------------------------------------
