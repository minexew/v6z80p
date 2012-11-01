; -----------------------------------------
; Demonstration of using the Load Requester
; -----------------------------------------
;
; Requires FLOS v602
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000

;----- MAIN REQUESTER CALL ----------------------------------------------------------------------------
	
	ld b,8				; x coord of requester (in characters)
	ld c,2				; y coord ""
	ld hl,my_filename		; location of filename
	call load_requester		; envoke the load requester
	jr z,reqok			; if ZF set on return all OK, ready to load file
	cp $ff				; otherwise, there was an error: 
	jr z,aborted			; if A = FF, the operation was aborted
	jr load_error			; if A is any other value, its a file system error
	
reqok	ld hl,load_buffer		; OK, load the actual file data 
	ld b,0				; 
	call kjt_read_from_file		; the load requester has already opened the file
	jr nz,load_error		; if ZF not set, handle any errors resulting from file load

load_ok	ld hl,loaded_ok_txt		; Show success message
	call kjt_print_string	
	xor a
	ret

my_filename

	db "Blah.txt",0
	
;--- OPTIONAL ERROR HANDLING ------------------------------------------------------------------------


aborted	ld hl,no_load_txt
	call kjt_print_string
	xor a
	ret
	
	
load_error

	or a				;if A =  0 the error was hardware related
	jr z,hw_error			;if A <> 0 its a file system error 
	push af			
	call file_error_requester
	ld hl,load_error_txt
	call kjt_print_string
	pop af
	ret


hw_error
	
	call hw_error_requester		;the user's program may loop back for another
	ld hl,hw_error_txt		;attempt (following saying yes to a drive remount)
	call kjt_print_string		;or just give up immediately, as is the case here.
	ret

;---------------------------------------------------------------------------------------------	
	
loaded_ok_txt

	db "File loaded OK",11,0
	
load_error_txt

	db "The filesystem returned an error:",11,11,0

no_load_txt

	db "The load was aborted.",11,0

hw_error_txt

	db "A hardware error was encountered.",11,0


;----------------------------------------------------------------------------
include	"flos_based_programs\code_library\requesters\inc\file_requesters.asm"
;----------------------------------------------------------------------------

load_buffer	db 0


