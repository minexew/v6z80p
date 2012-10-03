;
; Demo of library routine "extract_path_and_filename" and kernal routine "kjt_parse_path"
; 
; Note: "extract_path_and_filename" should only be called if the path/filename string is expected to
; actually include a filename. Otherwise, you'd just call 'kjt_parse_path' immediately.
;
;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;--------------------------------------------------------------------------------------

max_path_length equ 40

	call extract_path_and_filename	;make "path_txt" and "filename_txt" strings from HL (IE: command args)
	
	ld hl,fn_txt			;show the new strings
	call kjt_print_string
	ld hl,filename_txt
	call kjt_print_string
	ld hl,cr_txt
	call kjt_print_string
	ld hl,pt_txt
	call kjt_print_string
	ld hl,path_txt
	call kjt_print_string
	ld hl,cr_txt
	call kjt_print_string
	
	
	ld hl,path_txt
	call kjt_parse_path			;change dir according to the path part of the string
	ret

fn_txt	db "FILENAME: ",0
pt_txt	db "PATH    : ",0
cr_txt	db 11,0
	
;--------------------------------------------------------------------------------------

include "string\inc\extract_path_and_filename.asm"

;--------------------------------------------------------------------------------------
