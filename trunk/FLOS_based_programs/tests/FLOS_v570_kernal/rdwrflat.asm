; Tests kernal routines to read and write to FLAT addressed RAM


;---Standard source header for OSCA and FLOS ------------------------------------------

include "kernal_jump_table.asm"	; essential equates
include "OSCA_hardware_equates.asm"	; ""	""
include "system_equates.asm"		; ""	""

	org $5000
	
;--------------------------------------------------------------------------------------


	ld hl,message1
	call kjt_print_string
	
	ld e,0			;fill memory $5200-$7ffff
	ld hl,$5200
	
memwrlp	ld a,l
	push hl
	push de
	call kjt_write_sysram_flat	;A -> (E:HL)
	pop de
	pop hl
	inc hl
	
	ld a,h
	push hl
	push de
	call kjt_write_sysram_flat	;A -> (E:HL)
	pop de
	pop hl
	inc hl
	
	ld a,e
	push hl
	push de
	call kjt_write_sysram_flat	;A -> (E:HL)
	pop de
	pop hl
	inc hl

	ld a,0
	push hl
	push de
	call kjt_write_sysram_flat	;A -> (E:HL)
	pop de
	pop hl
	inc hl

	ld a,h
	or l
	jr nz,memwrlp
	inc e
	ld a,e
	cp 8
	jr nz,memwrlp
	
	nop
	nop
	nop
	
	
	ld hl,message2
	call kjt_print_string
	ld e,0
	ld hl,$5200		;read memory $5200-$7ffff verifying what was written
	
memrdlp	push hl
	push de
	call kjt_read_sysram_flat	;A <- (E:HL)
	pop de
	pop hl
	cp l
	jp nz,bad
	inc hl
	
	push hl
	push de
	call kjt_read_sysram_flat	;A <- (E:HL)
	pop de
	pop hl
	cp h
	jp nz,bad
	inc hl
	
	push hl
	push de
	call kjt_read_sysram_flat	;A <- (E:HL)
	pop de
	pop hl
	cp e
	jp nz,bad
	inc hl
	
	push hl
	push de
	call kjt_read_sysram_flat	;A <- (E:HL)
	pop de
	pop hl
	cp 0
	jp nz,bad
	inc hl

	ld a,h
	or l
	jr nz,memrdlp
	inc e
	ld a,e
	cp 8
	jr nz,memrdlp
	
	ld hl,message3
	call kjt_print_string
	xor a
	ret

bad	ld hl,message4
	call kjt_print_string
	xor a
	ret


message1	db "Writing..",11,0
message2	db "Reading..",11,0
message3	db "OK",11,0
message4	db "Bytes do not match!",11,0


	