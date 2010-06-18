
; Test low-level sector access routines

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000

;=======================================================================================

	ld hl,warn_txt
	call kjt_print_string
	call kjt_wait_key_press
	ld a,b
	cp "y"
	jp nz,quit
	ld hl,warn2_txt
	call kjt_print_string
	call kjt_wait_key_press
	ld a,b
	cp "y"
	jp nz,quit



	ld hl,writing_txt
	call kjt_print_string
	
	ld bc,0			;write sectors with a test pattern
	ld de,0
wr_loop	ld ix,sector_buffer
	ld b,128
lp1	ld (ix+0),e
	ld (ix+1),d
	ld (ix+2),c
	ld (ix+3),b
	inc ix
	inc ix
	inc ix
	inc ix
	djnz lp1
	push bc
	push de
	ld a,0
	call kjt_write_sector
	pop de
	pop bc
	jr nz,wrerr
	inc de
	ld a,d
	cp $40			;end at 8MB
	jr nz,wr_loop


	
	ld hl,reading_txt
	call kjt_print_string

	ld bc,0			;read back and compare sectors
	ld de,0
rd_loop	push bc
	push de
	ld a,0
	call kjt_read_sector
	pop de
	pop bc
	jr nz,rderr
	ld ix,sector_buffer
	ld b,128
lp2	ld a,(ix+0)
	cp e
	jr nz,verr
	ld a,(ix+1)
	cp d
	jr nz,verr
	ld a,(ix+2)
	cp c
	jr nz,verr
	ld a,(ix+3)
	cp b
	jr nz,verr
	inc ix
	inc ix
	inc ix
	inc ix
	djnz lp2
	ld b,0
	inc de
	ld a,d
	cp $40			;end at 8MB
	jr nz,rd_loop
	
	ld hl,ok_txt
	call kjt_print_string		
	xor a
	ret

quit	xor a
	ret

rderr	or a			;if A is zero then the error was hardware related
	jr z,hw_err		;HW error code would then be in B (if interested)
	ld hl,read_error_txt
	call kjt_print_string
	xor a
	ret
	
wrerr	or a			;if A is zero then the error was hardware related
	jr z,hw_err		;HW error code would then be in B (if interested)
	ld hl,write_error_txt		
	call kjt_print_string
	xor a
	ret
	
		
verr	ld hl,verify_error_txt
	call kjt_print_string
	xor a
	ret	
	
		
hw_err	ld hl,hw_err_txt		
	call kjt_print_string
	xor a
	ret

	
sect_err	ld hl,sect_err_txt		
	call kjt_print_string
	xor a
	ret
		
;--------------------------------------------------------------------------------------

warn_txt

	db "WARNING! This will corrupt the disk!",11,11
	db "Press 'y' to continue",11,11,0

warn2_txt	db "Sure???",11,11,0
	
	
read_error_txt

	db "Read Error!",11,0
	
	
write_error_txt

	db "Write Error!",11,0
	
	
verify_error_txt

	db "Verify Error!",11,0
	
	
hw_err_txt

	db "Hardware error",11,0
		
		
sect_err_txt

	db "Sector out of range error",11,0
		
		
ok_txt

	db "OK!",11,0
	

writing_txt

	db "Writing...",11,0
	

reading_txt

	db "Reading...",11,0
		
;--------------------------------------------------------------------------------------
			