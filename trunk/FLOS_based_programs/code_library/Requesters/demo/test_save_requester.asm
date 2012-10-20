;-----------------------------------------------------------------------------
; Demonstration of the save file requester
;-----------------------------------------------------------------------------
;
;REQUIRES FLOS v562+
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;-----------------------------------------------------------------------------
	
	ld b,8				; x coord of requester (in characters)
	ld c,2				; y coord ""
	ld hl,my_filename		; default filename

	call save_requester
	jr z,reqok
	cp $ff				; if A = FF, the operation was aborted
	jr z,aborted
	jr sav_error
	
reqok	ld ix,data_to_save		; source address
	ld b,0				; source bank
	ld c,0				; bits 23:16 of length
	ld de,18			; bits 15:0 of length
	call kjt_save_file		
	jr c,hw_error
	jr nz,sav_error
	
	ld hl,saved_ok_txt
	call kjt_print_string	
	xor a
	ret

aborted	ld hl,no_save_txt
	call kjt_print_string
	xor a
	ret
	
sav_error	

	or a				;if A =  0 the error was hardware related
	jr z,hw_error			;if A <> 0 its a file system error 
	push af			
	call file_error_requester
	ld hl,save_error_txt
	call kjt_print_string
	pop af
	ret
	
hw_error	
	
	call hw_error_requester
	ld hl,hw_error_txt
	call kjt_print_string
	ret


saved_ok_txt

	db "File saved OK",11,0

save_error_txt

	db "Save error",11,0
	
no_save_txt

	db "The save was aborted.",11,0

hw_error_txt

	db "A hardware error was encountered.",11,0


;----------------------------------------------------------------------------
include	"flos_based_programs\code_library\requesters\inc\file_requesters.asm"
;----------------------------------------------------------------------------

my_filename

	db "Blah.txt",0
	
	
data_to_save

	db "BlahBlahBlahBlah",11,0


;---------------------------------------------------------------------------	

