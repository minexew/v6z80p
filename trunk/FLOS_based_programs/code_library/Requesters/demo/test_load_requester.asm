; Demonstration of using the Load Requester library
;
; Requires FLOS v562
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"


load_buffer equ $8000


	org $5000

;-----------------------------------------------------------------------------
	
	ld b,8				; x coord of requester (in characters)
	ld c,2				; y coord ""
	ld hl,my_filename		; default filename

	call load_requester
	jr z,reqok
	cp $ff				; if A = FF, the operation was aborted
	jr z,aborted
	jr load_error
	
reqok	ld hl,load_buffer		; address to load data to - note: "kjt_find_file" has
	ld b,0				; already been called by requester
	call kjt_force_load
	jr nz,load_error

load_ok	ld hl,loaded_ok_txt
	call kjt_print_string	
	xor a
	ret


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

my_filename

	db "Blah.txt",0
	
;---------------------------------------------------------------------------	
	


