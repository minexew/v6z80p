;-----------------------------------------------------------------------------
; Demo of Support code for Window drawing routines
;-----------------------------------------------------------------------------
;
; Requires FLOS v602
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"


	org $5000

;------------------------------------------------------------------------------
	
	call kjt_clear_screen
	ld hl,info_txt
	call kjt_print_string
	
	ld a,0			;window number
	ld b,8			;x
	ld c,2			;y
	call draw_window		

	ld a,2
	call w_set_element_selection

demo_loop

	ld a,$80
	call w_highlight_selected_element

	call kjt_wait_key_press
	cp $76
	jr z,quit
	
	call w_unhighlight_selected_element
	call w_next_selectable_element
	jr demo_loop
	
quit	xor a
	ret
		
info_txt	

	db "Press TAB to cycle through selectable",11,"elements.. ESC to quit.",0

;---------------------------------------------------------------------------------


	include "window_routines\inc\window_draw_routines.asm"
	include "window_routines\inc\window_support_routines.asm"
	

;------ My Window Descriptions -----------------------------------------------------

window_list	dw win_inf_load			;Window 0
		dw win_inf_save			;Window 1
		dw win_inf_new_dir		;Window 2
		dw win_inf_dir_exists		;Window 3
		dw win_inf_overwrite		;Window 4

;------ Window Info -----------------------------------------------------------

win_inf_load	db 0,0			;0 - position on screen of frame (x,y) 
		db 23,20		;2 - dimensions of frame (x,y)
		db 0			;4 - current element/gadget selected
		db 0			;5 - unused at present
		db 1,1			;6 - position of first element (x,y)
		dw win_element1		;8 - location of first element description
		db 5,1
		dw win_element2
		db 19,1
		dw win_element3
		db 1,3
		dw win_element4
		db 1,16
		dw win_element5
		db 10,16
		dw win_element6
		db 1,18
		dw win_element7
		db 16,18
		dw win_element8
		db 255			;255 = end of list of window elements
		
		
win_inf_save	db 0,0				 
		db 23,20				
		db 0				
		db 0				
		db 1,1
		dw win_element1			
		db 5,1
		dw win_element2
		db 19,1
		dw win_element3
		db 1,3
		dw win_element4
		db 1,16
		dw win_element5
		db 10,16
		dw win_element6
		db 1,18
		dw win_element9
		db 16,18
		dw win_element8
		db 255				


win_inf_new_dir	db 0,0
		db 10,7
		db 0
		db 0
		db 1,1
		dw win_element10
		db 1,5
		dw win_element11
		db 255


win_inf_dir_exists	

		db 0,0
		db 10,7
		db 0
		db 0
		db 1,1
		dw win_element12
		db 4,5
		dw win_element13
		db 255


win_inf_overwrite

		db 0,0
		db 13,7
		db 0
		db 0
		db 1,1
		dw win_element15
		db 2,5
		dw win_element13
		db 9,5
		dw win_element14
		db 255
		

;---- Window Elements ---------------------------------------------------------------------

		
win_element1	db 2			;0 = Element Type: 0=button, 1=data area, 2=info (text)
		db 3,1			;1/2 = dimensions of element x,y
		db 0			;3 = control bits (n0=selectable, b1=special line selection)
		db 0			;4 = event flag
		dw dir_txt		;5/6 = location of associated data
		
win_element2	db 1
		db 12,1
		db 0
		db 0
		
win_element3	db 0
		db 3,1
		db 1
		db 0
		dw new_txt

win_element4	db 1
		db 21,12
		db 3
		db 0
		dw line_selection
		
win_element5	db 2
		db 8,1
		db 0
		db 0
		dw filename_txt

win_element6	db 1
		db 12,1
		db 1
		db 0
		dw w_filename

win_element7	db 0
		db 4,1
		db 1
		db 0
		dw load_txt

win_element8	db 0
		db 6,1
		db 1
		db 0
		dw cancel_txt

win_element9	db 0
		db 4,1
		db 1
		db 0
		dw save_txt

win_element10	db 2
		db 8,3
		db 0
		db 0
		dw new_dir_txt

win_element11	db 1
		db 8,1
		db 1
		db 0
		dw w_dirname

win_element12	db 2
		db 8,4
		db 0
		db 0
		dw alr_exists_txt
		
win_element13	db 0
		db 2,1
		db 1
		db 0
		dw ok_txt
		
win_element14	db 0
		db 2,1
		db 1
		db 0
		dw no_txt		

win_element15	db 2
		db 11,3
		db 0
		db 0
		dw overwrite_txt

		
		
dir_txt		db "DIR",0
new_txt		db "NEW",0
filename_txt	db "FILENAME",0
save_txt	db "SAVE",0
cancel_txt	db "CANCEL",0
load_txt	db "LOAD",0
new_dir_txt	db "NEW DIR",11,11," NAME?",0
alr_exists_txt	db "ALREADY",11,11," EXISTS!",0
ok_txt		db "OK",0
no_txt		db "NO",0
overwrite_txt	db "FILE EXISTS",11,"OVERWRITE ?",0

w_filename	ds 14,0
w_dirname	ds 14,0
line_selection	db 0

;--------------------------------------------------------------------------------------

