; Demonstration of using the Load Requester library (RS232 included)
;
; REQUIRES FLOS v562+
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"


load_buffer equ $8000

	org $5000

;-----------------------------------------------------------------------------
	
	ld b,8			; x coord of requester (in characters)
	ld c,2			; y coord ""
	ld hl,my_filename		; default filename

	call load_requester
	jr z,dloadok
	cp $ff			; if A = FF, the operation was aborted
	jr z,aborted
	cp $fe			; If A = FE, the load is to be done serially
	jr z,rs232_load		; (header already loaded (@ IX, see KJT docs)
	jr load_error
	
dloadok	ld hl,load_buffer		; address to load data to note: "kjt_find_file" has
	ld b,0			; already been called by requester
	call kjt_force_load
	jr nz,load_error		
	ld hl,loaded_ok_txt		;loaded ok
	call kjt_print_string	
	xor a
	ret

rs232_load
	
	call receiving_requester
	ld hl,load_buffer		; address to download data to
	ld b,0			; bank selection for load
	call kjt_serial_receive_file
	push af
	call w_restore_display
	pop af
	jr nz,load_error		; EG: A=8:Memory out of range, A=f:checksum bad
	ld hl,serial_loaded_ok_txt
	call kjt_print_string	
	xor a
	ret

aborted	ld hl,no_load_txt
	call kjt_print_string
	xor a
	ret


load_error

	or a			;if A =  0 the error was hardware related
	jr z,hw_error		;if A <> 0 its a file system error 
	push af			
	call file_error_requester
	ld hl,load_error_txt
	call kjt_print_string
	pop af
	ret


hw_error	call hw_error_requester	;the user's program may loop back for another
	ld hl,hw_error_txt		;attempt (following saying yes to a drive remount)
	call kjt_print_string	;or just give up immediately, as is the case here.
	ret


	
	
loaded_ok_txt

	db "File loaded OK",11,0

serial_loaded_ok_txt

	db "File received OK",11,0
		
load_error_txt

	db "The system returned an error:",11,11,0

no_load_txt

	db "The load was aborted.",11,0

hw_error_txt

	db "A hardware error was encountered.",11,0

	
;----------------------------------------------------------------------------
include	"file_requesters_with_rs232.asm"
;----------------------------------------------------------------------------

my_filename

	db "Blah.txt",0
	

;---------------------------------------------------------------------------	
	


