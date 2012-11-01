;-----------------------------------------------------------------------------
; Demonstration of the save file requester (RS232 included)
;-----------------------------------------------------------------------------
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
	jr z,dsaveok
	cp $ff				; if A = FF, the operation was aborted
	jr z,aborted
	cp $fe				; If A = FE, the load is to be done serially
	jr z,rs232_save			; (header already loaded (@ IX, see KJT docs)
	jr sav_error
	
dsaveok	ld ix,data_to_save		; source address
	ld b,0				; source bank
	ld c,0				; bits 23:16 of length
	ld de,end_of_data-data_to_save	; bits 15:0 of length
	call kjt_save_file		
	jr nz,sav_error
	
	ld hl,saved_ok_txt
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
		
aborted	ld hl,no_save_txt
	call kjt_print_string
	xor a
	ret

hw_error	

	call hw_error_requester
	ld hl,hw_error_txt
	call kjt_print_string
	pop af
	ret



rs232_save

	call sending_requester
	ld ix,data_to_save		; source address
	ld b,0				; source bank
	ld c,0				; bits 23:16 of length
	ld de,end_of_data-data_to_save	; bits 15:0 of length
	call kjt_serial_send_file	; HL has been set to the filename by requester routine
	push af
	call w_restore_display
	pop af
	jr nz,ser_error			; if ZeroFlag is not set, there was problem
	ld hl,rs232sent_txt
	call kjt_print_string
	xor a
	ret
	
ser_error	

	push af
	ld hl,rs232_error_txt
	call kjt_print_string
	pop af
	ret


my_filename	db "Test.txt",0

data_to_save	db "Test-Test-Test-Test_End",10,13,0
end_of_data	

;---------------------------------------------------------------------------	
	
	
	
saved_ok_txt

	db "File saved to disk OK..",11,0

save_error_txt

	db "Save error",11,0
	
no_save_txt

	db "The save was aborted.",11,0

hw_error_txt

	db "A hardware error was encountered.",11,11,0

rs232sent_txt

	db "Data sent via RS232 OK..",11,0

rs232_error_txt

	db "A serial error occured..",11,11,0
		
;----------------------------------------------------------------------------
include	"flos_based_programs\code_library\requesters\inc\file_requesters_with_rs232.asm"
;----------------------------------------------------------------------------
	




