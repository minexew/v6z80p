;-------------------------------------------------------------------------------------------------------------------------------
; PROCESS COMMANDS...
;-------------------------------------------------------------------------------------------------------------------------------
	
os_enter_pressed
		
		call mult_cursor_y_window_cols		; put the line at the cursor y location into the command string buffer
		ld de,OS_charmap
		add hl,de
		call copy_to_command_string
		xor a
		ld (de),a

gotcmdstr	ld (cursor_x),a				; home the cursor at the left
		ld hl,cursor_y				; move cursor down a line
		call cursor_down_main
			
		call os_getbank				; save the bank the OS was in before any commands launched
		ld (bank_pre_cmd),a		

		call os_parse_cmd_chk_ps

		call restore_bank_no_script
		jp os_main_loop


;-------------------------------------------------------------------------------------------------------------------------------

os_parse_cmd_chk_ps

		call os_parse_command_line
		cp $fe					; new command issued by exiting program?
		jr z,newxcmd

chk_cmdr	ld hl,master_commandstring		; has a master command been set up?
		ld a,(key_mod_flags)
		and 2					; if CTRL is held - abort and cancel master command
		jr z,nskpcmdr
		xor a
		ld (hl),a
		ret
	
nskpcmdr	ld a,(hl)
		or a
		ret z

newxcmd		call copy_to_command_string		; yes, loop around util it is disabled
		jr os_parse_cmd_chk_ps



;--------------------------------------------------------------------------------------------------------------------------------

cmd_vol		equ scratch_pad
cmd_dir		equ scratch_pad+1
program_header	equ scratch_pad+4

os_parse_command_line

		ld a,1
		ld (store_registers),a			; by default (external) commands store registers on return
		

		ld hl,commandstring			; attempt to interpret command
		ld b,OS_window_cols			; max string length = width of window in chars
		push hl
		call uppercasify_string			; make sure command string is all upper case
		pop hl
		call os_scan_for_non_space		; scan from hl until finds a non-space or zero
		or a					; if its a zero, give up parsing line
		ret z


		ld de,dictionary-1			; scan dictionary for command names
		push de
compcstr	pop de
		push hl
		pop iy
notacmd		inc de
		ld a,(de)
		or a					; last dictionary entry?
		jp z,os_no_kernal_command_found
		jp p,notacmd				; command names have prefix bytes $80-$9f
		cp $a0
		jr nc,notacmd
		sla a
		ld c,a
		ld b,0					; command code's execution address word index 
		push de
cmdnscan	inc de
		ld a,(de)
		cp (iy)
		inc iy
		jr z,cmdnscan				; this char matches - test the next

nomatch		ld a,(de)				; this char doesnt match (but the previous chars did)
		or a					; is it the end of a command dictionary entry ($80+)?
		jp p,compcstr				; look for next command in dictionary

posmatch	ld a,(iy-1)				; if next command string char is a space, the command matches
		cp 32
		jr nz,compcstr				; look for next command in dictionary

		pop de				
		push iy				; INTERNAL OS command found! Move arg location to HL	
		pop hl
		call os_scan_for_non_space
		ld (os_args_start_lo),hl		; hl = 1st non-space char after command 
		
		ld hl,os_cmd_locs
		add hl,bc
		ld c,(hl)				; get low byte of INTERNAL command routine address
		inc hl
		ld b,(hl)				; get high byte of INTERNAL command routine address
		push bc 
		pop ix					; ix = addr of command subroutine code

		xor a
		ld (store_registers),a			; internal commands dont store the registers on return
		ld hl,(os_args_start_lo)		; hl = 1st char after command + a space 
		call os_exec_command			; call internal command
		jp extcmd_r


;-----------------------------------------------------------------------------------------------------------------------------------------------------
; Is command "VOLx:" or "G" ?
;-----------------------------------------------------------------------------------------------------------------------------------------------------

os_no_kernal_command_found

		call test_vol_string			; is command VOLx: ?
		jr nc,novolcmd
		ld b,a
		ld a,(ix+5)				; there must be a space after the colon for it to count as a change vol command
		cp " "
		jr nz,novolcmd
		ld a,b
		call os_change_volume			; changes volume and assumes previously selected dir for that volune
		jp nz,extcmderf				; treat error codes as if external command as routine use ZF error system
		call fs_test_dir_cluster
		jp nz,cd_show_path			; if not root dir, show path		
		xor a
		ret

novolcmd	ld a,(hl)				; special case for "G" command, this is internal but the code it
		cp "G"					; will be executing will be external, so it should treated as
		jr nz,not_g_cmd				; an external command
		inc hl
		ld a,(hl)
		dec hl
		cp " "
		jr nz,not_g_cmd
		inc hl
		call os_scan_for_non_space
		ld (os_args_start_lo),hl		; hl = 1st non-space char after command 
		or a
		jr nz,gotgargs
		ld a,$1f				; quit with error message
		jp show_erm
gotgargs	call ascii_to_hexw_no_scan		; returns DE = goto address
		or a
		jp nz,show_erm
		call os_allow_nmi_freeze	
		push de
		pop ix
		call backwards_compatibility
		call get_pre_launch_regs
		jp do_cmd
not_g_cmd	ld (os_args_start_lo),hl		; attempt to load external OS command from current dir / volume
	
	
;-----------------------------------------------------------------------------------------------------------------------------------------------------
; Process executable file (external command)
;-----------------------------------------------------------------------------------------------------------------------------------------------------


		call cd_store_vol_dir 			; cache pre-command dir and volume (that which is active on the command line)

		call fileop_preamble			; changes dir (parses path) for commands with path prefix
		jp nz,show_erm				; if path was invalid, show error and quit
		
		ld (cmd_filename_addr),hl

		call os_move_to_next_arg
		ld (os_args_start_lo),hl

;		call os_check_volume_format	
;		jr nz,os_tryasgnpath			; make sure volume is available

		call find_executable			; look for file in dir now selected
		jr z,got_external_cmd		 
		
		call cd_restore_vol_dir 		; return to original dir/vol (in case a path was changed)
		
		ld a,(path_flag)			; if a path was specified, then do not look in assigned paths
		or a					; for command
		jp nz,unknown_cmd
		
	
os_tryasgnpath	ld a,$30				; look for assigned envars with name %EX0 to %EX9
asgn_pathlp	ld (ex_path_txt+3),a
		ld hl,ex_path_txt
		call envar_cmd_init
		jr nz,no_asgn_vol			; if ZF not set, volume unchanged		
		call find_executable			; sucessfully changed to assigned dir - is the program here?
		jr z,got_external_cmd
		call cd_restore_vol_dir
no_asgn_vol	ld a,(ex_path_txt+3)			; try next %EXn envar		
		inc a
		cp $3a
		jr nz,asgn_pathlp			; all %EXn: assigns checked - didn't find command

unknown_cmd	ld a,$0b
		jp show_erm				
		
os_ndfxc	call cd_restore_vol_dir 		; routine pushes/pops AF
		jp show_erm
		
hw_err_restore	call cd_restore_vol_dir 		
		jp os_hwerr
	

;---------------------------------------------------------------------------------------------------------------------------------------------------
	
got_external_cmd

		call os_get_dir_vol			; store the dir and vol the command loaded from (only for potential use by program itself)
		ld (cmd_vol),a
		ld (cmd_dir),de
		ld hl,(os_args_start_lo)		
		call os_scan_for_non_space		; set args start to first non-space character
		ld (os_args_start_lo),hl

		xor a
		ld (exe_bank),a				; by default executables start with bank set to 0
		ld hl,11
		call set_loadlength24			; load the first 11 bytes into a buffer (scratch_pad+4)
		ld hl,program_header
		ld (fs_z80_address),hl
		call fs_read_data_command
		jr c,hw_err_restore			; hardware error?
		jr z,excmd_rdh_ok
		cp $1b					; if file sys error = $1b (file smaller than header size, it's OK it just
		jr z,excmd_noheader			; has no header)
		jp show_erm
		
excmd_rdh_ok	ld hl,(program_header)
		ld de,$00ed				; does program have a special FLOS location header?
		xor a
		sbc hl,de
		jr z,loc_header
excmd_noheader	call fs_open_file_command		; not a special FLOS header so load as normal
		jr c,hw_err_restore			; (open file again to update values)
		jr nz,os_ndfxc
		ld hl,(fs_z80_address)			; set HL (load/start address to $5000)
		jr readcode
	
	
loc_header	call fs_open_file_command		; file has special FLOS header, open file again	
		jr c,hw_err_restore
		jr nz,os_ndfxc
		ld hl,(program_header+4)		; replace normal load address from header
		ld (fs_z80_address),hl
		ld a,h
		cp $50
		jp nc,osok
		ld a,$26				; if prog tries to load below $5000, exit with warning
		jr os_ndfxc

	
osok		ld a,(program_header+6)			; replace normal load bank from header
		ld (fs_z80_bank),a	
		ld (exe_bank),a
		inc hl
		inc hl					; code execution address (just in case "$de,$00" should cause a problem..)

		ld a,(program_header+7)			; is there a load length specified?
		or a
		jr z,readcode				; if byte at 7 = 0, load whole file
		push hl
		ld hl,(program_header+8)		; get load length 15:0
		ld a,(program_header+10)		; get load length 23:8
		call set_loadlength24			; set the load length
		pop hl
	
readcode	ld (os_extcmd_jmp_addr),hl		; store code execution address
		call fs_read_data_command		; read in the actual program file
		call cd_restore_vol_dir 		; go back to original dir/vol (routine pushes/pops AF)
		jp c,os_hwerr				; drive error?
		jp nz,show_erm				; file system error?
		
		ld a,(exe_bank)				; set the bank that the program requires
		call os_forcebank
		call os_allow_nmi_freeze
		ld hl,os_extcmd_jmp_addr		; address of external command held at this address
		ld c,(hl)				; get low byte of command routine address
		inc hl
		ld b,(hl)				; get high byte of command routine address
		push bc 
		call backwards_compatibility		; Set Audio loc base to $2xxxx and LineCop base to $7xxxx
		pop ix					; IX = addr of command subroutine code
		ld hl,(os_args_start_lo)		; HL = first non-space char after command 
		ld iy,fs_file_length			; IY = location of file_length and file_start_cluster (+8)
		ld a,(cmd_vol)				; A  = volume the command loaded from
		ld de,(cmd_dir)				; DE = dir the command loaded from
do_cmd		call os_exec_command			; a call allows commands to return with "ret"



extcmd_r	push af				; <-FIRST INSTRUCTION ON RETURN FROM EXTERNAL COMMAND	
		xor a
		out (sys_alt_write_page),a		; restore critical system settings for FLOS
		ld a,(store_registers)
		or a
		jr z,skp_strg
		push hl
		ld hl,(com_start_addr)
		ld (pc_store),hl
		pop hl
		pop af
		call os_store_CPU_regs			; store registers and flags on return
		push af
skp_strg	pop af

cntuasr		push af				; Set "ERR" envar to exiting program's error code
		ld de,0
		ld (scratch_pad+2),de
		ld e,a					; LSB = Error code from A
		jr z,nohwerrev
		or a
		jr nz,nohwerrev
		ld d,b					; MSB = Hardware error code from B (if applic)
nohwerrev	ld (scratch_pad),de
		ld de,scratch_pad	
		push hl				; Preserve HL (for A=$FE program launches)
		ld hl,err_txt
		push bc				; Preserve B (in case of h/w error code)
		call os_set_envar		
		pop bc
		pop hl
		pop af	

		ld de,os_no_nmi_freeze	
		ld (nmi_vector),de	 		; prevent NMIs taking any action

extcmderf	jr z,not_errc				; if ZERO FLAG is set, the program completed OK
		or a		
		jp z,os_hwe1				; if A = 0 and zero flag is not set, there was a hardware error
		cp $ff					; Not a hardware error, is report code: FF - restart?
		jp z,os_cold_start
		cp $fe					; if command wants to spawn a new command, return now
		ret z
		or a					; if A = 80+, show no error
		jp m,not_errc			
		jp show_erm				; else show the relevent error code message 	
not_errc	cp $ff					; no error but check for a = $ff on return anyway (OS needs to restart..)
		jp z,os_cold_start
		ret


os_exec_command
	
		ld (com_start_addr),ix			;temp store start address of executable
		jp (ix)					;jump to command code
	

;--------------------------------------------------------------------------------------------------------------------------------------------
; Subroutines..
;--------------------------------------------------------------------------------------------------------------------------------------------		

get_pre_launch_regs
	
		call os_move_to_next_arg		; at start, HL = first argument location
		call os_get_dir_vol			; at start, DE = dir block, A = current volume
		ret




envar_cmd_init
		call get_dirvol_from_envar
		ret nz
		push de				
		call os_change_volume			; if a different volume. the dir selection for the original volume
		pop de					; will be automatically saved
		ret nz
		push de
		call fs_get_dir_block			; the dir we need to cache is the one used by THIS new volume
		ld (original_dir_cd_cmd),de			
		pop de
		call os_update_dir_cluster_safe		; now we can change to the target dir in the new volume
		xor a
		ret


;--------------------------------------------------------------------------------------------------------------------------------

os_set_commander

		ld de,master_commandstring		;copy cannot be  > 40 as the command string
		jr copy_wcb				;is stored at $0FE8-$100F
			
	

copy_to_command_string

		ld de,commandstring		
copy_wcb	ld bc,OS_window_cols-2	
		ldir
		ret	

;--------------------------------------------------------------------------------------------------------------------------------


find_executable	

		ld hl,(cmd_filename_addr)
		ld de,scratch_pad			; copy the command name to the scratch_pad and append .exe
		ld b,12
		ld c,0
ccmdtlp		ld a,(hl)			
		or a
		jr z,goteocmd
		cp " "
		jr z,goteocmd
		cp "."
		jr nz,no_cmd_dot
		inc c
no_cmd_dot	ld (de),a
		inc de
		inc hl
		djnz ccmdtlp
goteocmd	xor a
		ld (de),a

		ld a,c					; is there already a file extension supplied?
		or a
		jr nz,find_exe_se			; if so, only look for that exact file
		
		ld hl,exe_txt				; if not, first look for .exe
		call find_exe
		ret z
		ld hl,flx_txt				; then look for .flx
		
find_exe	call append_ext
find_exe_se	ld hl,scratch_pad
		push de
		call os_find_file
		pop de
		ret
		
append_ext	ld bc,5					; add chars ".exe" or ".flx" and zero	
		push de
		ldir	
		pop de
		ret

;--------------------------------------------------------------------------------------------------------------------------------
; Error Reporting..
;--------------------------------------------------------------------------------------------------------------------------------

os_hwe1		ld a,b					; If ZF is set, but A = 0, show hardware error code from B
os_hwerr	ld hl,hex_byte_txt		
		call hexbyte_to_ascii	
		ld hl,hw_err_msg
		call os_show_packed_text
		xor a
		ret


show_erm	ld b,a					; the program reported an error - show the relevant error message
		ld c,0
		ld hl,packed_msg_list
findmsg		ld a,(hl)
		cp $ff
		ret z					; quit if cant find message
		inc hl
		or a
		jp p,findmsg				; is this an index marker?
		inc c
		ld a,b					; compare index count - is this the right message?
		cp c
		jr nz,findmsg
		
		call show_packed_text_and_cr
		xor a
		ret

;--------------------------------------------------------------------------------------------------------------------------------
	