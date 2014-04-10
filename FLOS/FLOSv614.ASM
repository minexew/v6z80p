;----------------------------------------------------------------------------------------
; FLOS for OSCA by Phil Ruston 2008-2014
;----------------------------------------------------------------------------------------
;
; IMPORTANT:
; ----------
; If "flos_variables.asm" is changed, reassemble it first with *.symbol output
; in the Pasmo command line to create an up-to-date "flos_variables.symbol" file!
;
; A Note about VRAM paging in OSCA
; ---------------------------------
; The OS code and data loads at $1000 and can extend to $4fff.
; As this includes the video RAM page region $2000-$3fff ensure that
; video memory is not enabled when the Program Counter is between
; $2000-$3FFF and that no data from that area is required when
; VRAM is paged in.
;
;----------------------------------------------------------------------------------------

include "flos/inc/flos_variables.symbol"
include "equates/OSCA_hardware_equates.asm"
include "equates/system_equates.asm"


flos_version	equ $614

os_start	equ $1000

;----------------------------------------------------------------------------------------
; Assembly options
;----------------------------------------------------------------------------------------

max_volumes	equ 4

;----------------------------------------------------------------------------------------
	org os_start
;----------------------------------------------------------------------------------------

; 16 byte header
	
		db "Z80P*OS*"				; V6Z80P OS identifier

		dw os_high-os_low			; Length of file excluding header
		dw 0					; MSB of OS length
		dw 0					; CRC - filled in by external app

		dw flos_version_txt-os_start		; offset to OS label	

;----------------------------------------------------------------------------------------

os_low		jp os_first_run				; skip low memory data and routines
	
;----------------------------------------------------------------------------------------

include "flos/inc/FLOS_kernal_jump_table.asm"	        ; fixed location jump table	

include "flos/inc/FLOS_lowmem_code.asm"			; stuff to be kept out of video RAM area
	
;----------------------------------------------------------------------------------------

		

; =======================================================================================
;                                     START FLOS
; =======================================================================================


os_first_run	or a					; if A = 0, no boot data is being passed
		jr z,skipsbd
		ld (bootcode_version),hl
		ld (boot_info),bc			; [B: 1 = SD Card, 2 = EEPROM, 3= Serial]. [C (bit0) = Devices present at bootcode time]

skipsbd		xor a
		ld (master_commandstring),a
		

os_cold_start	di					; Disable irqs
		im 1					; CPU IRQ: mode 1
		ld sp,stack				; Set Stack pointer
		
		ld hl,OS_variables			; Clear OS system variables
		ld bc,256
		call os_bchl_memclear

		call set_irq_vectors                    ; put "JP irq_addr" and "JP nmi_addr" at $0a00 & $0a03. (Do this now in case NMI jumper on at start!)

		call initialize_os

		ei
		ld bc,$0801
		ld (cursor_y),bc
		ld hl,flos_version_txt			; show FLOS / OSCA versions
		call os_print_string
		call os_print_string
		call os_get_version		
		ld (osca_version),de
		ld hl,output_line
		call hexword_to_ascii
		call os_print_output_line_skip_zeroes
		ld bc,$0703
		ld (cursor_y),bc
		ld hl,author_txt
		call kjt_print_string
					
		call os_cmd_remount			; set up drives
		call os_new_line			; skip 1 line

		ld hl,boot_script_fn+1			; execute BOOT_RUN.SCR start-up script
		ld (os_args_start_lo),hl
		call os_cmd_exec			; this will check for master command too	
		call restore_bank_no_script		; restore bank (in case changed by bootscript) 

		
;============================================================================================


os_main_loop	ld de,$085f				; normal underscore cursor
		ld a,(insert_mode)
		or a
		jr z,undsc_c
		ld de,$1000				; full block cursor
undsc_c		call cursor_keywait
			


		ld a,(current_scancode)			; insert mode on/off?
		cp $70
		jr nz,os_notins
		ld a,(insert_mode)
		xor 1
		ld (insert_mode),a
		jr os_main_loop



os_notins	ld hl,cursor_x			
		cp $6c					; home key pressed?
		jp z,os_home
		


		cp $6b					; arrow key moving cursor left?		
		jr nz,os_ntlft
		dec (hl)
		jp p,os_main_loop
		ld (hl),OS_window_cols-1		; wrapped around
		jr os_main_loop




os_ntlft	cp $74					; arrow key moving cursor RIGHT?
		jp z,cursor_right




os_ntrig	ld hl,cursor_y				; PAGE UP (cursor to top left)
		cp $7d
		jr nz,npage_up
		call os_cursor_x_home
		jr page_up



npage_up	cp $7a					; PAGE DOWN (cursor to bottom, new line)
		jr nz,npage_dwn
		call os_cursor_x_home
		call page_dwn_main
		jr os_main_loop



npage_dwn	cp $75					; arrow key moving CURSOR UP?
		jr nz,os_ntup
		dec (hl)
		jp p,os_main_loop
page_up		ld (hl),0				; top limit reached
		jr os_main_loop




os_ntup		cp $72
		jr nz,os_ntdwn				; arrow key moving CURSOR DOWN?
		call cursor_down_main		
		jr os_main_loop




os_ntdwn	cp $71					; DELETE pressed?
		jr nz,os_nodel		
		ld a,(cursor_x)				; shift chars of this line back onto cursor pos
		ld b,a
		inc b
		jr os_chrbk



os_nodel	cp $69					; END pressed?
		jr nz,os_noend
		ld bc,(cursor_y)			; move cursor to right of last non-space char on line
		ld b,OS_window_cols-1
os_feol		call os_get_charmap_xy
		ld a,(hl)
		cp " "
		jr z,os_tchl
		ld a,b
		cp OS_window_cols-1
		jr z,os_geol
		inc b
		jr os_geol
os_tchl		djnz os_feol
os_geol		ld (cursor_y),bc
		jp os_main_loop
		
		
		

os_noend	cp $66					; BACKSPACE pressed?
		jr nz,os_nbksp
		ld a,(cursor_x)				; shift chars of this line back from cursor pos
		or a					; (unless at column 0)
		jp z,os_main_loop
		ld b,a
		dec a
		ld (cursor_x),a				; shift cursor back a char
os_chrbk	call mult_cursor_y_window_cols
		ex de,hl
		ld l,b
		ld h,0
		add hl,de
		push hl
		ld de,OS_charmap
		add hl,de				; hl = first source char
		ld d,h
		ld e,l
		dec de					; de = dest
		ld a,OS_window_cols
		sub b
		ld c,a
		ld b,0					; bc = number of chars to do
		push bc
		ldir
		ld a,32
		ld (de),a				; put a space at right side
		pop bc
		pop hl
		call attributes_left			; ensures this routine is below $2000
		call os_redraw_line
		jp os_main_loop




os_nbksp	cp $5a					; pressed ENTER?
		jp z,os_enter_pressed



	
		ld hl,function_key_list			; pressed F1-F9?
		ld b,9
tst_fkey	cp (hl)
		jr nz,nxtfkey
		ld a,$3a
		sub b
		ld (fkey_filename+1),a
		call cd_store_vol_dir    		; note current dir/volume
		call os_check_volume_format
		jr nz,nofkstr				; make sure disk is available
		ld hl,fkey_filename
		call os_find_file			; look for file called Fx.CMD (where x is relevant f-key)
		jr z,fkey_gfn
		
		ld hl,key_txt				; not found, try to change to "%key" envar dir assignment
		call envar_cmd_init
		jr nz,nofkstr				; if envar doesnt exist, quit
		ld hl,fkey_filename
		call os_find_file			; if Fx.CMD file doesn't exist here either quit
		jr nz,nofkstr	
fkey_gfn	ld hl,0
		ld (script_file_offset),hl
		call script_load_line			; use the script load line subroutine to get file 
		jr nz,nofkstr				; contents cleanly into command string (strips any CR,LF etc)
		ld hl,commandstring	
		call os_print_string
		call cd_restore_vol_dir 		; go back to original dir
		jp gotcmdstr				; treat string as an entered command
nofkstr		call cd_restore_vol_dir 				
		jp os_main_loop				; no key file - back to main loop
nxtfkey		inc hl
		djnz tst_fkey
			

	
		ld a,(current_asciicode)		; not a direction, bkspace, del, enter or f-key 1-9 
		or a					; if scancode is not an ascii char
		jr z,os_nvdun				; zero is returned, skip plotting char.
	
		call flip_char_case
		
		ld d,a					; need to print character on screen 
		ld a,(insert_mode)			; check for insert mode
		or a
		jr nz,os_schi
		ld a,(cursor_x)				; shift chars of this line right from cursor pos
		cp OS_window_cols-1			; (unless at rightmost column or insert mode active)
		jr z,os_schi
		ld b,a
		push de
		call mult_cursor_y_window_cols	
		ld de,OS_charmap+OS_window_cols-2
		add hl,de				; hl = first source char
		ld d,h
		ld e,l
		inc de					; de = dest
		ld a,OS_window_cols-1
		sub b
		ld c,a
		ld b,0					; bc = number of chars to do
		lddr
		ld c,a
		ld b,0	
		call attributes_right			; ensure this routine is below $2000 as it 
		call os_redraw_line			; pages in Video RAM
		pop de
		
os_schi		ld bc,(cursor_y)
		ld a,d
		call os_plotchar		
	
cursor_right	ld hl,cursor_x				; move cursor right after char displayed
		inc (hl)
		ld a,(hl)
		cp OS_window_cols			; wrapped around?
		jr nz,os_nvdun
os_home		ld (hl),0
os_nvdun	jp os_main_loop

;------------------------------------------------------------------------------------------------


cursor_down_main
		
		inc (hl)				; assumes HL = cursor_y variable
		ld a,(hl)
		cp OS_window_rows
		ret nz
page_dwn_main	ld (hl),OS_window_rows-1		; bottom limit reached, scroll the screen
		call scroll_up
		ret
		
		
;==============================================================================================
; Internal commands
;==============================================================================================

include "flos\inc\commands\b.asm"
include "flos\inc\commands\c.asm"
include "flos\inc\commands\cd.asm"
include "flos\inc\commands\colon.asm"
include "flos\inc\commands\d.asm"
include "flos\inc\commands\del.asm"
include "flos\inc\commands\dir.asm"
include "flos\inc\commands\f.asm"
include "flos\inc\commands\format.asm"
include "flos\inc\commands\h.asm"
include "flos\inc\commands\gtr.asm"
include "flos\inc\commands\lb.asm"
include "flos\inc\commands\m.asm"
include "flos\inc\commands\md.asm"
include "flos\inc\commands\r.asm"
include "flos\inc\commands\rd.asm"
include "flos\inc\commands\rn.asm"
include "flos\inc\commands\sb.asm"
include "flos\inc\commands\rx.asm"
include "flos\inc\commands\tx.asm"
include "flos\inc\commands\t.asm"
include "flos\inc\commands\mount.asm"
include "flos\inc\commands\colour.asm"
include "flos\inc\commands\exec.asm"
include "flos\inc\commands\ltn.asm"
include "flos\inc\commands\list_cmd.asm"

os_cmd_unused	ret			; <- dummy command


;--------------------------------------------------------------------------------------------------
; Main support code
;--------------------------------------------------------------------------------------------------

include "FLOS/inc/FLOS_command_launch_code.asm"
include "FLOS/inc/FLOS_string_code.asm"
include "FLOS/inc/FLOS_mouse_code.asm"
include "FLOS/inc/FLOS_memory_code.asm"
include "FLOS/inc/FLOS_text_code.asm"
include "FLOS/inc/FLOS_misc_hardware_code.asm"
include	"flos/inc/FLOS_int_command_common_code.asm"	
include	"flos/inc/FLOS_diskop_code.asm"
include	"flos/inc/FLOS_envar_code.asm"	
include	"flos/inc/FLOS_serial_code_v104.asm"		
include	"flos/inc/fat16_code_v127.asm"
include	"flos/inc/FLOS_sdcard_driver_v113.asm"	
	 
include	"flos/inc/FLOS_data.asm"			
	

;================================================================================================
	
		db 0				; address marker for start of safe user RAM
os_high		end		
;================================================================================================

