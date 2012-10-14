;---------------------------------
; OS SYMBOLS / EQUATES V5.01
;---------------------------------

; Assemble this prior to os_code to create symbols included into that file

;--------------------------------------------------------------------------------------------

include "OSCA_hardware_equates.asm"
include "system_equates.asm"

OS_window_cols equ 40
OS_window_rows equ 25

;--------------------------------------------------------------------------------------------


;------------------------------------------
; VARIABLES USED BY OS - 256 BYTES MAXIMUM!
;------------------------------------------

	org OS_variables 

sector_lba0	db 0		; keep this byte order
sector_lba1	db 0
sector_lba2	db 0
sector_lba3	db 0

a_store1		db 0		
bc_store1		db 0,0
de_store1		db 0,0
hl_store1		db 0,0
a_store2		db 0
bc_store2		db 0,0
de_store2		db 0,0
hl_store2		db 0,0
storeix		db 0,0
storeiy		db 0,0
storesp		db 0,0
storepc		db 0,0
storef	  	db 0
store_registers	db 0
com_start_addr	dw 0

;--------------------------------------------------------------------------------------------

cursor_y		db 0		;keep this byte order 
cursor_x		db 0		;(allows read as word with y=LSB) 

;---------------------------------------------------------------------------------------------
		
current_scancode	db 0
current_asciicode	db 0

cursorflashtimer	db 0
cursorstatus	db 0

memmonaddrl	db 0
memmonaddrh	db 0

cmdop_start_address	db 0,0
cmdop_end_address	db 0,0

os_linecount	db 0

commandstring	ds OS_window_cols+2,0
output_line	ds OS_window_cols+2,0
				
os_args_start_lo	db 0
os_args_start_hi	db 0

os_extcmd_jmp_addr	dw 0

banksel_cache	db 0

;---------------------------------------------------------------------------------------
; Script related
;---------------------------------------------------------------------------------------

script_buffer		ds OS_window_cols+2,0
script_file_offset		dw 0
script_buffer_offset	dw 0
in_script_flag		db 0
script_dir		dw 0
script_vol		db 0
script_fn			ds 13,0
script_unused		db 0

;---------------------------------------------------------------------------------------
; Keyboard buffer and registers
;---------------------------------------------------------------------------------------

scancode_buffer		ds 32,0

key_buf_wr_idx		db 0
key_buf_rd_idx		db 0
key_release_mode		db 0		
not_currently_used		db 0
key_mod_flags		db 0
insert_mode		db 0

;--------------------------------------------------------------------------------------
; Mouse related
;--------------------------------------------------------------------------------------

use_mouse			db 0	; Do not change the order of these 18 bytes
mouse_packet		db 0,0,0	
mouse_buttons		db 0
mouse_packet_index		db 0
mouse_pos_x		dw 0	
mouse_pos_y		dw 0
mouse_disp_x		dw 0	
mouse_disp_y		dw 0	
old_mouse_disp_x		dw 0
old_mouse_disp_y		dw 0

mouse_window_size_x		dw 0
mouse_window_size_y		dw 0

;=======================================================================================
