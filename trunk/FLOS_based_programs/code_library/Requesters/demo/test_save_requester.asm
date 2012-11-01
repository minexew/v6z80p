;-----------------------------------------
; Demonstration of the save file requester
;-----------------------------------------
;
; Requires FLOS v602
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000


;------ MAIN FILE REQUESTER CALL -----------------------------------------------------
	
	
	ld b,8				; x coord of requester (in characters)
	ld c,2				; y coord ""
	ld hl,my_filename		; default filename
	call save_requester		; envoke the save requester
	jr z,reqok			; If ZF set on return, all OK ready to save data
	cp $ff				; if A = FF, the operation was aborted
	jr z,aborted
	jr save_error
	
reqok	ld ix,data_to_save		; source address
	ld b,0				; source bank
	ld c,0				; bits 23:16 of length
	ld de,end_of_data-data_to_save	; bits 15:0 of length 
	call kjt_save_file		; save the actual file data
	jr nz,save_error		; if ZF set, all was OK. Else handle errors
	
	ld hl,saved_ok_txt		; show success message
	call kjt_print_string	
	xor a
	ret


my_filename	db "Blah.txt",0
	
data_to_save	db "Blah-Blah-Blah-Blah",10,13,0
end_of_data	db 0

	
;----- OPTIONAL ERROR HANDLING -----------------------------------------------------


aborted	ld hl,no_save_txt
	call kjt_print_string
	xor a
	ret
	
save_error	

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


