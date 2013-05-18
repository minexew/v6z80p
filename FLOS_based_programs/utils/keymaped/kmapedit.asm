; KEYMAP EDITOR - v1.01 by Phil Ruston 2013
; ------------------------------------------
;
; v1.01 - added sprite offset for FLOS in 60Hz mode
;
;---Standard header for OSCA and FLOS -----------------------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

	org $5000	

;----------------------------------------------------------------------------------------------

max_path_length equ 40

                call save_dir_vol
                call kmapedit_go
                call restore_dir_vol
                ret
          
;-----------------------------------------------------------------------------------------------

kmapedit_go	call get_video_mode
		and 1
		jr z,paltv
		ld a,$4c
		ld (sprite_pos),a
paltv		call remove_cursor
                call kjt_clear_screen
                 
		xor a
		ld de,0
		ld bc,spr_end-kb_spr
		ld hl,kb_spr
		call unpack_sprites
	

		ld hl,colours
		ld de,palette+(248*2)
		ld bc,16
		ldir					;set sprite colours

		call sprites_on                        ;enable OSCA sprites - use most basic mode
	
		ld b,15                                 ;set sprite registers
		ld hl,128+(8*4)+2                       ;first x coord
		          
		ld ix,sprite_registers
spreglp		ld (ix+0),l                             ;set x coord low
		ld (ix+3),e                             ;set def low
		ld a,d
		rlca
		rlca
		and 4
		ld c,a
		ld a,h
		and 1
		or $50					; height of sprite
		or c
		ld (ix+1),a                             ;set msbs
		ld a,(sprite_pos)
		ld (ix+2),a                             ;set y coord low
          
		ld a,l                                  ;next x coord
		add a,16
		ld l,a
		jr nc,xcomok
		inc h
          
xcomok   	ld a,e                                  ;next def
		add a,5
		ld e,a
		jr nc,defmok
		inc d

defmok   	inc ix                                  ;next spr reg
		inc ix
		inc ix
		inc ix
          
		djnz spreglp


		ld hl,util_text
		call kjt_print_string
		
;--------------------------------------------------------------------------

		call show_ascii_keys

main_loop	call kjt_wait_vrt
		call kjt_get_key
	
		ld (kc_pressed),a
		or a
		call nz,highlight_key

		call kjt_get_key_mod_flags		;has qualifier status changed
		ld hl,0
		ld e,a
		and $11
		jr z,no_shift
		ld hl,$62
		jr no_alt
no_shift	ld a,e
		and $0c
		jr z,no_alt
		ld hl,$62*2
no_alt		push hl
		pop bc
		ld de,(qual_offset)
		xor a
		sbc hl,de
		jr z,qual_same
		ld (qual_offset),bc
		call show_ascii_keys

qual_same	call qual_highlight

		ld a,(kc_pressed)
		cp 6
		jp z,inc_km_value			;f1 pressed
		cp 5
		jp z,dec_km_value			;f2 pressed
		
                ld e,a
                call kjt_get_key_mod_flags              ;CTRL needs to be pressed for following to work..
                and 2
                jp z,main_loop
		ld a,e
                cp $78
                jp z,load_km
                cp $07
                jp z,save_km
                cp $76					;ESC pressed
		jp nz,main_loop
		         
                call remove_cursor
		
                call sprites_off                        ;disable OSCA sprites - use most basic mode
                
                call kjt_clear_screen
                
                xor a
		ret

;----------------------------------------------------------------------------		

sprites_on	ld a,1
		ld (vreg_sprctrl),a                     ;enable OSCA sprites - use most basic mode
                ret

sprites_off     ld a,0
		ld (vreg_sprctrl),a                     ;enable OSCA sprites - use most basic mode
                ret
                
;----------------------------------------------------------------------------		


inc_km_value	ld a,(old_kc_sel)
		or a
                jp z,main_loop
                ld hl,keymap
		ld de,(qual_offset)
		add hl,de
		ld e,a
		ld d,0
		add hl,de
		inc (hl)
                ld a,(hl)
                cp $20
                jr nc,redraw_chars
                ld (hl),$20
		
redraw_chars	call show_ascii_keys
		call show_codes
                jp main_loop


dec_km_value	ld a,(old_kc_sel)
		or a
                jp z,main_loop
                ld hl,keymap
		ld de,(qual_offset)
		add hl,de
		ld e,a
		ld d,0
		add hl,de
		dec (hl)
		ld a,(hl)
		cp $20
		jr nc,redraw_chars
		inc (hl)
		jp main_loop

;----------------------------------------------------------------------------		

		
highlight_key	ld hl,old_kc_sel		;if same as previous, dont do anything
		cp (hl)
		ret z
		
		call cursor_preamble		;if new key is not a keymapped type dont do anything
		ret nz
		
		ld hl,old_kc_sel
		ld a,(hl)			;remove old cursor
		call cursor_preamble
		jr nz,no_uhlk	
		call remove_cursor
                
no_uhlk		ld a,(kc_pressed)
		ld (old_kc_sel),a
		call cursor_preamble
		ret nz
		call kjt_set_cursor_position
		ld (cursor_loc),bc
                ld hl,$1800
		call kjt_draw_cursor
		
show_codes	ld bc,$0003
		call kjt_set_cursor_position
		ld hl,scancode_txt
		call kjt_print_string
                ld a,(old_kc_sel)
		call show_byte
		ld hl,asciicode_txt
		call kjt_print_string
		ld a,(old_kc_sel)
	        ld e,a
                ld d,0
                ld hl,keymap
                add hl,de
                ld de,(qual_offset)
                add hl,de
                ld a,(hl)
                or a
                jr nz,ascii_set
                ld hl,no_ascii_txt
                jr shc_end
ascii_set       ld (asciichar_txt+2),a
                call show_byte
                ld hl,asciichar_txt
shc_end         call kjt_print_string
                ret		
			

cursor_preamble

		ld hl,kc_list
		ld bc,13+12+12+11
		cpir
		ret nz
		
	
		dec hl
		ld bc,kc_list
		xor a
		sbc hl,bc
		add hl,hl
		ld bc,kc_locs
		add hl,bc
		ld a,(hl)
		add a,7
		ld c,a
		inc hl
		ld a,(hl)
		add a,5
		ld b,a
		xor a
		ret


remove_cursor   ld bc,(cursor_loc)
                call kjt_set_cursor_position
                ld hl,0
                call kjt_draw_cursor
                ret
                
;------------------------------------------------------------------------------------

show_ascii_keys

		ld ix,kc_list
		ld iy,kc_locs
		ld b,13+12+12+11

kdloop		push bc
		ld a,(iy)
		add a,7
		ld c,a
		ld a,(iy+1)
		add a,5
		ld b,a
		
		ld a,(ix)
		ld e,a
		ld d,0
		ld hl,keymap
		add hl,de
		ld de,(qual_offset)
		add hl,de
		ld a,(hl)
		or a
                jr nz,char_ok
                ld a," "
char_ok		call kjt_plot_char		

no_asciival	inc ix
		inc iy
		inc iy
		pop bc
		djnz kdloop
		ret
		
;------------------------------------------------------------------------------------


qual_highlight	ld hl,(qual_offset)
		ld a,h
		or l
		jr nz,qual_actv
		
		ld de,0
		ld (palette+508),de
		ld de,0
		ld (palette+506),de
		ret
		
qual_actv	ld de,$62
		xor a
		sbc hl,de
		jr nz,alt_actv
		ld de,$ccc
		ld (palette+508),de
		ld de,$000
		ld (palette+506),de
		ret

alt_actv	ld de,$000
		ld (palette+508),de
		ld de,$ccc
		ld (palette+506),de
		ret
		
		
;------------------------------------------------------------------------------------

show_byte	push af
		push hl
		ld hl,hex_txt+1
		call kjt_hex_byte_to_ascii
		ld hl,hex_txt
		call kjt_print_string
		pop hl
		pop af
		ret

hex_txt		db "$xx",0

scancode_txt	db "SCAN CODE: ",0
asciicode_txt	db " => ASCII CODE: ",0
asciichar_txt   db " ( )   ",0
no_ascii_txt    db "[None set]",0

cursor_loc      db 0,0

;------------------------------------------------------------------------------------

load_km         call io_preamble
                ld hl,0
                ld b,8
                ld c,2
                call load_requester
                jr nz,load_error		; if ZF set on return all OK, ready to load file
                					
lreqok	        ld hl,keymap    		; OK, load the actual file data 
                ld b,0				; 
                call kjt_read_from_file		; the load requester has already opened the file
                jr nz,load_error		; if ZF not set, handle any errors resulting from file load

load_ok	        ld hl,loaded_ok_txt		; Show success message
returnmain      call print_and_wait
                jp kmapedit_go
                
load_error      ld hl,load_fail_txt		; Show fail message
                jr returnmain
                
print_and_wait  call kjt_print_string
                ld hl,pressany_txt
                call kjt_print_string
                call kjt_wait_key_press
                ret

pressany_txt    db 11,11,"*** Press any key ***",0

loaded_ok_txt   db "Keymap loaded OK",0
load_fail_txt   db "ERROR! - KEYMAP DID NOT LOAD",0

;------------------------------------------------------------------------------------

save_km         call io_preamble
                ld b,8				; x coord of requester (in characters)
                ld c,2				; y coord ""
                ld hl,km_filename		; default filename
                call save_requester		; envoke the save requester
                jr nz,save_error		; If ZF set on return, all OK ready to save data
                
sreqok	        ld ix,keymap    		; source address
                ld b,0				; source bank
                ld c,0				; bits 23:16 of length
                ld de,$62*3                     ; bits 15:0 of length 
                call kjt_save_file		; save the actual file data
                jr nz,save_error		; if ZF set, all was OK. Else handle errors
	
                ld hl,saved_ok_txt		; show success message
                jp returnmain	
                
save_error      ld hl,save_fail_txt		; Show fail message
                jp returnmain
              
km_filename	db "keymap.bin",0

saved_ok_txt    db "Keymap saved OK",0
save_fail_txt   db "ERROR! - SAVE FAILED",0

;------------------------------------------------------------------------------------

io_preamble     call remove_cursor
                call sprites_off
                call kjt_clear_screen
                ret

;------------------------------------------------------------------------------------

		include "flos_based_programs/code_library/memory/inc/unpack_sprites.asm"
		
                include "flos_based_programs/code_library/loading/inc/save_restore_dir_vol.asm"
		
                include "flos_based_programs/code_library/requesters/inc/file_requesters_with_rs232.asm"
		
		include "flos_based_programs/code_library/video/inc/get_video_mode.asm"

;------------------------------------------------------------------------------------

kc_list		db $0e,$16,$1e,$26,$25,$2e,$36,$3d,$3e,$46,$45,$4e,$55
		db $15,$1d,$24,$2d,$2c,$35,$3c,$43,$44,$4d,$54,$5b
		db $1c,$1b,$23,$2b,$34,$33,$3b,$42,$4b,$4c,$52,$5d
		db $61,$1a,$22,$21,$2a,$32,$31,$3a,$41,$49,$4a
		
kc_locs		db 0,0, 0,2, 0,4, 0,6, 0,8, 0,10, 0,12, 0,14, 0,16, 0,18, 0,20, 0,22, 0,24
		db 2,3, 2,5, 2,7, 2,9, 2,11, 2,13, 2,15, 2,17, 2,19, 2,21, 2,23, 2,25
		db 4,4, 4,6, 4,8, 4,10, 4,12, 4,14, 4,16, 4,18, 4,20, 4,22, 4,24, 4,26
		db 6,3, 6,5, 6,7, 6,9, 6,11, 6,13, 6,15, 6,17, 6,19, 6,21, 6,23
		

old_kc_sel	db 0
kc_pressed	db 0
kc_sel		db 0
key_index	db 0
		
qual_offset	dw 0

sprite_pos	db $5c

;------------------------------------------------------------------------------------

                
kb_spr		incbin "FLOS_based_programs\utils\keymaped\data\sprites_packed.bin"
spr_end		db 0

colours		incbin "FLOS_based_programs\utils\keymaped\data\colours.bin"	

util_text	db "       FLOS KEYMAP EDITOR V1.01",11
		db "       ------------------------",11
                db 11,"PRESS A KEY...",11,11,11,11,11,11,11,11,11,11,11,11,11,11,"KEYS:-",11,11
                db "F1/F2    : ASCII CODE -/+",11
                db "CTRL+ESC : QUIT",11
                db "CTRL+F11 : LOAD KEYMAP",11
                db "CTRL+F12 : SAVE KEYMAP",0  

;-------------------------------------------------------------------------------------

keymap		ds $62,$0
		ds $62,$0
		ds $62,$0
                
;-------------------------------------------------------------------------------------




