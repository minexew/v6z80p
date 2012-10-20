
; App: SET.EXE Sets environment variables - v1.03 By Phil @ retroleum
; Usage: set var_name var_value (if no parameters supplied, en_vars are listed)
;
; Var_value can a string (in quotes) or a hex number or another envar name
; in brackets. Alternatively, var_value can be + (inc value) - (dec value)
; # (delete envar)
; 
;-------------------------------------------------------------------------------------
; Changes
;
; 1.04 - Changed "/../" (truncated path) to "/--/"
; 1.03 - Allow Envar data to be ascii string (4 chars in quotes)
;        "+" and "-" parameters to inc or dec value
;        "#" to delete the Envar
;        "=" allowed IE: "SET hats = 25"
;        Allow envar to be copy of other envar: EG: "SET HATS (CATS)"
;        Returns error codes $12 and $1f as appropriate
;
; 1.02 - Fixed bug - when listing EnvVars - first zero encountered stopped list 
; 1.01 - Env vars with % prefix are displayed as paths (and not allowed to be set)


;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
; Header code - Force program load location and test FLOS version.
;--------------------------------------------------------------------------------------

my_location	equ $f000
my_bank		equ $0e
include 	"flos_based_programs\code_library\program_header\force_load_location.asm"

required_flos	equ $594
include 	"flos_based_programs\code_library\program_header\test_flos_version.asm"

;---------------------------------------------------------------------------------------
	

	ld (args_pointer),hl

	ld a,(hl)			; examine argument text, if none show envars
	or a			
	jp z,show_vars
	
	push hl
	ld de,var_name
	ld b,4
evnclp	ld a,(hl)
	cp " "
	jr z,evncdone
	ld (de),a
	inc hl
	inc de
	djnz evnclp
evncdone	pop hl
	ld a,(var_name)
	cp "%"
	jp z,bad_name

	call next_arg	

;------------------------------------------------------------------------------------------------------------

	ld a,(hl)			;if "=" skip to next arg
	cp "="	
	call z,next_arg
	
	ld a,(hl)			;if var data is in quotes, treat as ASCII string (4 bytes max)
	cp $22
	jr nz,not_text
	
	ld b,4
	ld de,var_data
textloop	inc hl
	ld a,(hl)
	cp $22
	jp z,got_evd
	ld (de),a
	inc de
	djnz textloop
	jp got_evd

;------------------------------------------------------------------------------------------------------------

not_text	cp "#"				;remove envar?
	jr nz,not_delete
	
	ld hl,var_name
	call kjt_delete_envar
	ret
	
;-------------------------------------------------------------------------------------------------------------

not_delete

	cp "-"				;dec envar value?
	jr nz,not_dec
	
	ld hl,var_name
	call kjt_get_envar
	ret nz
	ld de,var_data
	ld bc,4
	ldir
	
	ld hl,var_data
	ld b,4
declp	ld a,(hl)
	sub 1
	ld (hl),a
	jr nc,incdecend
	inc hl
	djnz declp
	
incdecend	ld hl,var_name
	ld de,var_data
	call kjt_set_envar
	ret
	

;-------------------------------------------------------------------------------------------------------------	

not_dec	cp "+"				;inc envar value?
	jr nz,not_inc
	
	ld hl,var_name
	call kjt_get_envar
	ret nz
	ld de,var_data
	ld bc,4
	ldir
	
	ld hl,var_data
	ld b,4
inclp	inc (hl)
	jr nz,incdecend
	inc hl
	djnz inclp
	jr incdecend
		
;-------------------------------------------------------------------------------------------------------------

not_inc	cp "("				;copy envar value?
	jr nz,not_copy
	inc hl
	ld de,var_copy
	ld b,4
cename	ld a,(hl)	
	cp ")"
	jr z,cendone
	ld (de),a
	inc hl
	inc de
	djnz cename
	
cendone	ld hl,var_copy
	call kjt_get_envar
	ret nz
	ld bc,4
	ld de,var_data
	ldir
	ld hl,var_name
	ld de,var_data
	call kjt_set_envar
	ret

;--------------------------------------------------------------------------------------------------------------

not_copy

	ld b,8			; convert ascii to long word
lp4	ld a,(hl)
	or a
	jr z,got_evd
	cp " "
	jr z,got_evd
	push bc
	cp $60
	jr c,upcase
	sub $20
upcase	sub $3a			
	jr c,zeronine
	add a,$f9
zeronine	add a,$a
	push hl
	ld hl,(var_data)
	ld de,(var_data+2)
	ld b,4
rotquad	add hl,hl
	rl e
	rl d
	djnz rotquad
	ld (var_data),hl
	ld (var_data+2),de
	ld hl,var_data
	and $f
	or (hl)
	ld (hl),a
	pop hl
	inc hl
	pop bc
	djnz lp4
	
got_evd	ld hl,var_name		;set the environment variable
	ld de,var_data
	call kjt_set_envar
	ret
	
;------------------------------------------------------------------------------------------------------------

	
show_vars	

	ld hl,defined_vars_txt
	call kjt_print_string
	
	ld hl,fake_var_txt
	call kjt_get_envar		;just get start of list and max vars count
		
lp2	push bc	
	ld a,(hl)
	or a
	jr z,skp_ev
	
	push hl
	ld de,var_name
	ld bc,4
	ldir
	ld hl,var_name
	call kjt_print_string	;show env_var name
	pop hl
	
	push hl

	ld de,4
	add hl,de
	ld de,var_data
	ld bc,4
	ldir

	ld a,(var_name)		;is it an assign type envar? IE:"%xxx"
	cp "%"
	jr z,show_assign

	ld de,var_data+3		;show env_var databytes
	ld hl,hex_output_txt+4
	ld b,4
lp1	ld a,(de)
	push de
	call kjt_hex_byte_to_ascii
	pop de
	dec de
	djnz lp1
	call kjt_get_cursor_position
	ld b,4
	call kjt_set_cursor_position
	ld hl,hex_output_txt	
	call kjt_print_string

show_next_envar	

	pop hl
skp_ev	ld de,8
	add hl,de
	pop bc
	djnz lp2
	xor a
	ret
	

show_assign

	ld hl,equals_txt
	call kjt_print_string
	
	call kjt_get_dir_cluster	;show the en_var as a path
	ld (orig_cluster),de
	call kjt_get_volume_info
	ld (orig_volume),a

	ld a,(var_data+2)
	call kjt_change_volume
	ld de,(var_data)
	call kjt_set_dir_cluster
	call show_path
	ld a,(orig_volume)	
	call kjt_change_volume
	ld de,(orig_cluster)
	call kjt_set_dir_cluster

	ld hl,new_line_txt
	call kjt_print_string
	jr show_next_envar
	
	
;------------------------------------------------------------------------------------------------------------
	
missing_value
	
	ld a,$1f
	or a
	ret

bad_name	ld a,$12
	or a
	ret
	
;-------------------------------------------------------------------------------------------

show_path

	max_chars equ 32			;max allowable window width for path (min 28)
		
	ld c,max_chars-9			;Paths always have "VOL0:" and may also have "/../"
	ld b,0				;untruncated dir count
	ld de,text_buffer
	ld a,$2f
	ld (de),a
	inc de
	
gdnlp	push bc
	push de
	call kjt_get_dir_name		;are we at ROOT?
	pop de
	pop bc
	push hl
	pop ix
	ld a,(ix+4)
	cp ":"
	jr z,ds_end
		
cpy_dn	ld a,c				;is the text buffer full?
	or a
	jr z,trunc

	ld a,(hl)				;copy dir name char
	cp 33				
	jr c,eodn				;unless its 0 or space
	ld (de),a
	inc hl
	inc de
	dec c				;is text buffer full?
	jr cpy_dn
eodn	ld a,$2f				;add a "/"
	ld (de),a
	ld (last_full),de			;note the position of the end of this untruncated entry
	inc de
	inc b				;increase count of untruncated dir names
	dec c				;dec char buffer count
				
ndirup	push bc
	push de
	call kjt_parent_dir
	ret nz				;error return
	pop de
	pop bc
	jr gdnlp				 

trunc	ld de,0

ds_end	push de
	call kjt_root_dir
	call kjt_get_dir_name
	call kjt_print_string		;show the volume name
	pop de
	
	xor a
	or b				;if no dir names in buffer, all done
	ret z
	
	ld hl,trunc_txt			;if the dir list was truncated show "/--/"
	ld a,e
	or d
	call z,kjt_print_string	

notrutxt	ld hl,(last_full)			;position of trailing "/"
	inc hl
nxtdlev	ld a,b
	cp 1
	jr nz,notlast
	dec hl
	ld (hl),0
	jr dnbacklp
notlast	ld (hl),0				;replace with zero (stop print)
	dec hl
dnbacklp	dec hl
	ld a,(hl)
	cp $2f				;find preceeding "/"
	jr nz,dnbacklp
	inc hl
	push hl
	call kjt_print_string		;show dir name
	pop hl
	djnz nxtdlev			;any more dirs?
	xor a
	ret
			

last_full dw 0

trunc_txt	db "/--/",0

text_buffer ds max_chars+8,0

;-------------------------------------------------------------------------------------------

next_arg	ld hl,(args_pointer)
	call fnextarg
	ld (args_pointer),hl
	ret
	
fnextarg	inc hl
	ld a,(hl)			; locate next arg, ZF is NOT set if found
	or a
	ret z
	cp " "
	jr nz,fnextarg
nxtarg2	inc hl
	ld a,(hl)
	cp " "
	ret nz
	or a
	ret z
	jr nxtarg2
	
;-------------------------------------------------------------------------------------------

args_pointer	dw 0
	
var_name		ds 5,0
var_data  	ds 5,0
var_copy		ds 5,0

missing_value_txt	db "No value given for variable.",11,11,0

hex_output_txt	db " = $xxxxxxxx",11,0

fake_var_txt	db "@@@@",0
defined_vars_txt	db 11,"Environment variables:",11
		db "----------------------",11,11,0

badname_txt	db "Illegal variable name.",11,11,0

orig_cluster	dw 0

orig_volume  	db 0

new_line_txt	db 11,0

equals_txt	db " = ",0
	
;-------------------------------------------------------------------------------------------

