
; App: Assign - set a path environment variable. By Phil @ retroleum
; Usage: Assign "proxy_name" "path" (proxy name 3 chars max. If no path is
; supplied, the current dir is assigned)
;
; V1.00

;======================================================================================
; Standard header for OSCA and FLOS
;======================================================================================

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

;======================================================================================
; Program Location File Header:
; FLOS v568+ will use this data to load the program a specific location
; Earlier versions of FLOS will ignore it and load the program to $5000
;======================================================================================

my_location	equ $f000
my_bank		equ $0e


	org my_location	; desired load address
	
load_loc	db $ed,$00	; header ID (Invalid Z80 instruction)
	jr exec_addr	; jump over remaining header data
	dw load_loc	; location file should load to
	db my_bank	; upper bank the file should load to
	db 0		; dont truncate the program load

exec_addr	


;=======================================================================================	
; Location Check:
; As an earlier version of FLOS may have loaded the program, or it has
; simply been loaded into memory somwhere as a binary file we can check to
; see if it is in the desired location before the main code attempts to run.
;=======================================================================================

	push hl		; Tests to see if code is located in the correct place to run
	ld hl,sector_buffer	; use sector buffer location 0 for the test routine
	ld a,(hl)		; preserve the byte that was there
	ld (hl),$c9	; place a RET instruction there	
	call sector_buffer	; Call the RET, PC of true_loc is pushed on stack and returns back here
true_loc	ld (hl),a		; put the preserved byte back where RET was placed
	ld ix,0		
	add ix,sp		; get SP in IX
	ld l,(ix-2)	; HL = PC of true_loc from stack (load_loc + 8 + 11)
	ld h,(ix-1)
	ld de,true_loc-load_loc
	xor a
	sbc hl,de		; HL = actual location that program was loaded to
	push hl
	pop ix		
	ld e,(ix+4)
	ld d,(ix+5)	; DE = address where program is SUPPOSED to be located
	xor a
	sbc hl,de		; are we in the right place?
	pop hl	
	jr z,loc_ok	
	push ix		; No, so show an error message (using relative addressing)
	pop hl
	ld de,locer_txt-load_loc
	add hl,de
	call kjt_print_string
	xor a	
	ret

locer_txt	db "Program cannot run from this location.",11,0	

loc_ok	


;=======================================================================================		
;  Main Code starts here
;=======================================================================================


;--------- Test FLOS version -----------------------------------------------------------


required_flos equ $575


	push hl
	call kjt_get_version	
	ld de,required_flos 	
	xor a
	sbc hl,de
	pop hl
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	ld hl,hex_txt
	push hl
	ld a,d
	call kjt_hex_byte_to_ascii
	ld a,e
	call kjt_hex_byte_to_ascii
	pop hl
	inc hl
	call kjt_print_string
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v",0
hex_txt	db "----+",11,11,0

flos_ok


;-------- Parse command line arguments -------------------------------------------------


	push hl
	call kjt_get_dir_cluster	;by default, use the current drive and dir as the %proxy values
	ld (var_data),de
	ld (orig_cluster),de
	call kjt_get_volume_info
	ld (var_data+2),a
	ld (orig_volume),a
	xor a
	ld (var_data+3),a
	pop hl

fnd_para1	ld a,(hl)			; examine name argument text, if encounter 0: give up
	or a			
	jp z,no_args
	cp " "			; ignore leading spaces...
	jr nz,para1_ok
	inc hl
	jr fnd_para1

para1_ok	ld a,(hl)
	cp "%"
	jp z,inv_proxy
	push hl
	ld de,var_name+1
	ld b,3
evnclp	ld a,(hl)
	cp " "
	jr z,evncdone
	ld (de),a
	inc hl
	inc de
	djnz evnclp
evncdone	pop hl

fnd_spc	inc hl
	ld a,(hl)			; locate next space
	or a
	jp z,set_var
	cp " "
	jr nz,fnd_spc

fnd_para2	ld a,(hl)			; examine path argument text, if encounter 0: give up and use
	or a			; the current dir for path
	jp z,set_var
	cp " "			; ignore leading spaces...
	jr nz,para2_ok
	inc hl
	jr fnd_para2

para2_ok	push hl			
	pop ix			; analyse the path string
	ld a,(ix+4)
	cp ":"			; volume specified?
	jr nz,nxt_path
	ld de,vol_txt
	ld b,3
	push ix
	call kjt_compare_strings
	pop ix
	jp nc,bad_path
	ld a,(ix+3)		; get volume digit char
	sub $30
	push ix
	call kjt_change_volume
	pop ix
	jp nz,bad_path		; error if new volume is invalid

	ld de,5
	add ix,de			; move past "VOLx:"
	push ix
	call kjt_root_dir		; go to new drive's root block as drive has changed
	pop ix
	ld a,(ix)			; if "/" follows "VOLx:" then skip the fwdslash
	cp $2f
	jr nz,nxt_path
	inc ix

nxt_path	ld de,filename_txt		;step through args changing dirs as apt
	call skip_spaces
	jr z,path_done
cpypslp	ld a,(ix)
	cp $2f
	jr z,path_break
	cp 33
	jr c,path_break
	ld (de),a
	inc ix
	inc de
	jr cpypslp
	
path_break

	xor a
	ld (de),a			;zero terminate this dir string
	ld hl,filename_txt
	push ix
	call kjt_change_dir		
	pop ix
	jr nz,bad_path
	
	ld a,(ix)
	cp 33
	jr c,path_done
	inc ix
	jr nxt_path		;next char in path string
				

skip_spaces

	ld a,(ix)
	or a
	ret z
	cp 32
	ret nz
	inc ix
	jr skip_spaces


path_done

	call kjt_get_dir_cluster	;use this updated drive and dir as the %proxy values
	ld (var_data),de
	call kjt_get_volume_info
	ld (var_data+2),a

set_var	

	ld hl,var_name		;set the environment variable
	ld de,var_data
	call kjt_set_envar
	jr z,all_done
	ld hl,no_room_txt
	jr err_quit

all_done	ld a,(orig_volume)		;restore original current drive and dir
	call kjt_change_volume
	ld de,(orig_cluster)
	call kjt_set_dir_cluster
	xor a
	ret

no_args	ld hl,missing_args_txt
err_quit	call kjt_print_string
	jr all_done

inv_proxy	ld hl,bad_proxy_txt
	jr err_quit

bad_path	ld hl,bad_path_txt
	jr err_quit
		
;-------------------------------------------------------------------------------------------

vol_txt	   db "VOL",0

filename_txt ds 16,0

var_name	   db "%xxx",0

var_data     ds 5,0

orig_cluster dw 0

orig_volume  db 0

missing_args_txt	db 11,"ASSIGN.EXE (v1.00)",11,11
		db "Usage: ASSIGN PROXY [PATH]",11,11
		db "PROXY is a 3 character (maximum)",11
		db "environment variable to be used as",11
		db "a substitute for a long path string.",11
		db "Apps accepting paths can utilize the",11
		db "proxy (prefixed with %) to make a",11
		db "shortcut to the final dir.",11,11
		db "PATH is optional, if it isn't supplied",11
		db "then the current dir is used.",11,11,0
		

no_room_txt	db "Not enough space for assignment.",11,11,0
bad_path_txt	db "The path specified is invalid.",11,11,0
bad_proxy_txt	db "Bad proxy name.",11,11,0
		
;-------------------------------------------------------------------------------------------

