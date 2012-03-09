
; Tests FLOS v599 filesystem work registers read/restore
; within a basic file handle orientated framework
;
; Loads part of a file, loads entire second, loads rest of first file.

;---Standard header for OSCA and FLOS ---------------------------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"


	org $5000
	
	ld hl,filename1			;open file 1 
	call get_file_handle
	ret nz
	ld (file_handle1),a			;file handle is returned in A

	ld hl,filename2			;open file 2
	call get_file_handle
	ret nz
	ld (file_handle2),a			;file handle is returned in A



	ld a,(file_handle1)			;focus on file 1
	call set_file_focus

	ld ix,0				;read $100 bytes of file 1 to $8000
	ld iy,$100
	call kjt_set_load_length
	
	ld hl,$8000
	ld b,0
	call kjt_set_load_address
	
	call kjt_continue_file_read
	ret nz
	



	ld a,(file_handle2)			;swap focus to file 2
	call set_file_focus
	
	ld hl,$9000
	ld b,0
	call kjt_set_load_address

	call kjt_continue_file_read		;read all of file2 to $9000
	ret nz





	ld a,(file_handle1)			;swap focus back to file 1
	call set_file_focus

	ld ix,0				;read remaining $23 bytes of file 1 (continues from prior addr)
	ld iy,$23
	call kjt_set_load_length
	
	call kjt_continue_file_read
	ret 

	
;----------------------------------------------------------------------------------------------

msg_bad		db "File not found, most likely..",11,0

filename1		db "test1.bin",0
filename2		db "test2.bin",0

file_handle1	db 0
file_handle2	db 0



;----------------------------------------------------------------------------------------------
; File handle orientated file access routines
; (These routines assume no other file access takes place between calls
; such as saving or loads that dont use these routines)
;----------------------------------------------------------------------------------------------

get_file_handle

; Set HL to address of filename
; Returns file handle in A (and makes this the active focus file)

	push hl
	ld a,(focused_file)
	call locate_file_slot		;save current fs_vars to currently open slot
	ex de,hl
	inc de
	call read_fs_vars
	pop hl
	
	call kjt_find_file			;look for a free slot in the table
	ret nz
	ld hl,open_file_data
	ld de,file_slot_size
	xor a
find_fe	bit 0,(hl)
	jr z,got_free_slot
	add hl,de
	inc a
	cp max_open_files
	jr nz,find_fe
	ld a,$81				;error - all available file slots are in use
	or a
	ret

got_free_slot
	
	set 0,(hl)			;mark slot as containing an open file
	ld (focused_file),a			;make this file the one in focus
	cp a				;return file handle in A (with zero flag set)
	ret


;-----------------------------------------------------------------------------------------------

close_file_x

; Set A to file handle

	cp max_open_files
	jr c,maxfok1
	ld a,$83				;error - handle out of range
	or a
	ret

maxfok1	call locate_file_slot
	res 0,(hl)
	xor a
	ret

;-----------------------------------------------------------------------------------------------


set_file_focus

	cp max_open_files
	jr c,maxfok2
	ld a,$83				;error - handle out of range
	or a
	ret

maxfok2	ld hl,focused_file
	cp (hl)
	ret z				;same file as active handle? If so, nothing to do.
	
	ld (handle_requested),a
	call locate_file_slot		;does the requested handle number have an open file?
	bit 0,(hl)
	jr nz,slotval
	ld a,$82				;error - the handle requiring focus is closed
	or a
	ret

slotval	push hl
	ld a,(focused_file)				
	call locate_file_slot		;save current fs_vars to currently open slot
	ex de,hl
	inc de
	call read_fs_vars
	pop hl				;now put the fs_vars from new slot into system's working regs			
	inc hl
	call restore_fs_vars
	
	ld a,(handle_requested)		;and set this as the focused file
	ld (focused_file),a
	xor a
	ret	
	
;-----------------------------------------------------------------------------------------------

read_fs_vars

	call kjt_get_fs_vars_location
	ld bc,$14
	ldir
	ret


restore_fs_vars


	ld (hl),0				;clear fs_filepointer_valid
	ex de,hl
	call kjt_get_fs_vars_location
	ex de,hl
	ld bc,$14
	ldir
	ret
	
	
;-----------------------------------------------------------------------------------------------

locate_file_slot

	push de
	ld hl,open_file_data-file_slot_size
	ld de,file_slot_size
	inc a
find_slot	add hl,de
	dec a
	jr nz,find_slot
	pop de
	ret
	
;----------------------------------------------------------------------------------------------

focused_file	db 0
handle_requested	db 0

max_open_files 	equ 8
file_slot_size	equ 32	

open_file_data	ds max_open_files*file_slot_size

;----------------------------------------------------------------------------------------------
