;-----------------------------------------------------------------------
;"exec" - execute script V6.06
;
;Changes:
;
;6.06 - Fixed dir restore when swapping volumes
;6.05 - Allowed path for script file
;6.04 - Made load script line a subroutine so it can be used by programmable F-keys
;6.03 - Set load length = 24bit (optimized)
;6.02 - Support for loop (via GOTO envar and [xxxx] labels)
;6.01 - abort with CRTL + C
;
;Notes:  Scripts cannot launch scripts
;-----------------------------------------------------------------------


os_cmd_exec	ld a,(in_script_flag)			;test if already in a script
		or a
		jp nz,scr_error

		call fileop_preamble			;try to move to dir containing script file	
		ret nz
		
		ld de,script_fn				;copy the script filename (scripts cannot launch
		ld b,12					;scripts as this would require nested script filenames)
		call os_copy_ascii_run
		xor a
		ld (de),a
		
		call scr_clear_goto

		call os_get_dir_vol			;make a note of vol/dir that contains the script
		ld (script_dir),de
		ld (script_vol),a
		
		call cd_restore_vol_dir			;go back to original dir

		ld a,1
		ld (in_script_flag),a			;set the in-script flag


;----------------------------------------------------------------------------------------------------------
	
scr_begin	ld hl,0
		ld (script_file_offset),hl		; go to start of script

;----------------------------------------------------------------------------------------------------------


scrp_loop	ld a,(key_mod_flags)
		and 2
		jr z,noskip_script
		call os_get_key_press
		ld hl,script_aborted_msg
		cp $21
		jp z,scr_err2
	

noskip_script	call os_get_dir_vol			;store current volume
		ld (pre_script_vol),a
		
		ld a,(script_vol)			;swap to volume that contains the script
		call kjt_change_volume
		call fs_get_dir_block
		ld (pre_script_dir),de			;note what dir cluster was originally set for this volume
		ld de,(script_dir)			
		call os_update_dir_cluster_safe		;move to dir in volume that contains the script
		
		ld hl,script_fn				;locate the script file - this needs to be done every
		call os_find_file			;script line as external commands will have opened files
		jr nz,scr_ferr
		call script_load_line
		jr nz,scr_ferr
		ld (script_file_offset),iy
		ld (script_buffer_offset),hl
		
		call back_to_prescript_dir		;restore dir and go to volume we were in before loading the script file			
		

		ld a,(commandstring)			;Analyze the script line just loaded
		cp ";"					;if line is commented out with ";" at start, skip it
		jr z,scr_skpl
		cp "["					;Is this line a label?
		jr nz,scr_norm
		call scr_test_goto			;Yes, is goto mode (envar) set?
		jr nz,scr_skpl			
		ld de,commandstring+1			;Yes, is the label that set by the goto envar?
		ld b,4
scr_lablp	ld a,(hl)
		or a
		jr z,scr_ggl
		ld a,(de)
		cp "]"
		jr z,scr_ggl
		call os_uppercasify			;make label compare non case sensitive
		ld c,a
		ld a,(hl)
		call os_uppercasify
		cp c
		jr nz,scr_skpl
		inc hl
		inc de
		djnz scr_lablp
scr_ggl		call scr_clear_goto			;label match: get out of goto mode (remove envar)
		jr scr_skpl				;skip this line and continue parsing script
		
		
		
scr_norm	call scr_test_goto			;dont parse the command if a goto is set (as we're just scanning script)
		jr z,scr_skpl
		
		call os_parse_cmd_chk_ps		;attempt to launch commands (and check for spawn progs)
		call scr_test_goto			;if the command set a goto envar, start from start of script
		jp z,scr_begin	
		


scr_skpl	ld iy,(script_file_offset)		;skip <CR> etc when repositioning file pointer
		ld hl,(script_buffer_offset)
scrp_fnc	ld a,(hl)		
		or a
		jr z,scr_end				;if encounter a zero, its the end of the file
		cp $20
		jr nc,scrp_gnc				;if a space or higher, we have the next command
		inc hl		
		inc iy					;otherwise keep looking
		jr scrp_fnc

scrp_gnc	ld (script_file_offset),iy		;update file offset and loop
		jp scrp_loop	


;-----------------------------------------------------------------------------------------------

back_to_prescript_dir

		ld de,(pre_script_dir)			;restore dir and go to volume we were in before loading the script file
		ld a,(pre_script_vol)
		call restore_vol_dir			
		ret
		
scr_ferr	call back_to_prescript_dir		; return to dir selected prior to script
		ld a,$02				; error
		or a
		ret
		
;-----------------------------------------------------------------------------------------------
		
scr_end		call scr_test_goto			;was a goto still outstanding at end of script?
		jr z,scr_error				;if so show "script error"
		xor a
		ret
		
scr_error	ld hl,script_error_msg

scr_err2	call os_show_packed_text

scr_clear_goto

		ld hl,goto_txt			
		call os_delete_envar		
		xor a					;allows this routine to be used as exit jump too
		ret
		

scr_test_goto 

		ld hl,goto_txt				;Yes, is goto mode (envar) set?
		call os_get_envar	
		ret


goto_txt	db "GOTO",0


;------------------------------------------------------------------------------------------------

script_load_line
		
		ld hl,script_buffer			;clear script buffer and command string		
		ld de,commandstring
		ld b,OS_window_cols+1
		ld a,$20				;fill 'em with spaces
scrp_flp	ld (hl),0
		ld (de),a
		inc hl
		inc de
		djnz scrp_flp
		
		xor a
		ld hl,OS_window_cols			;only load enough chars for one line 
		call set_loadlength24
		ld ix,0
		ld iy,(script_file_offset)		;index from start of file
		call os_set_file_pointer

		ld hl,script_buffer			;load in part of the script	
		ld b,0
		call os_force_load			
		jr z,scrp_ok				;file system error?
		cp $1b			
		ret nz					;We dont mind if attempted to load beyond end of file
		
scrp_ok		ld iy,(script_file_offset)
		ld hl,script_buffer			;copy ascii from script buffer to command string
		ld de,commandstring
		ld b,OS_window_cols
scrp_cmd	ld a,(hl)
		cp $20
		jr c,scrp_eol
		ld (de),a
		inc hl
		inc de
		inc iy
		djnz scrp_cmd
scrp_eol	xor a
		ret

;------------------------------------------------------------------------------------------------

