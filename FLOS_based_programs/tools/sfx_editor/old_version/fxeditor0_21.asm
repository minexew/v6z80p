;********************************************************
;* Sound FX Editor for FLOS V0.20 - By Phil Ruston 2010 *
;********************************************************

;---Standard header for OSCA and FLOS ---------------------------------------------------------

include "kernal_jump_table.asm"
include "osca_hardware_equates.asm"
include "system_equates.asm"

	org $5000
	
;---------------------------------------------------------------------------------------------

display_width	equ 40
window_width_pixels	equ display_width*8
marker_y		equ 136
	
;--------- Test FLOS version ---------------------------------------------------------------------

	
	call kjt_get_version		; check running under FLOS v541+ 
	ld de,$555
	xor a
	sbc hl,de
	jr nc,flos_ok
	ld hl,old_flos_txt
	call kjt_print_string
	xor a
	ret

old_flos_txt

	db "Program requires FLOS v555+",11,11,0
	
flos_ok	
	
;--------- Initialize ------------------------------------------------------------------------

init_fx_ed

	call kjt_page_in_video		;clear first 64K of VRAM 
	ld c,0
cmlp3	ld a,c				
	ld (vreg_vidpage),a				
	ld hl,video_base		
cmlp2	ld a,$fe
	ld b,0
cmlp1	ld (hl),a
	inc l
	djnz cmlp1
	inc h
	ld a,h
	cp $40
	jr nz,cmlp2
	inc c
	ld a,c
	cp 8
	jr nz,cmlp3
	call kjt_page_out_video
	
	
	ld hl,63*window_width_pixels		; put y-line offsets in lookup table
	ld de,window_width_pixels		; for use by linedraw system 
	ld ix,ylookup_table			; (64 entries)
	ld b,64
sumtlp1	ld (ix),l
	ld (ix+1),h
	xor a
	sbc hl,de
	inc ix
	inc ix
	djnz sumtlp1
	
	
	ld hl,linedraw_constants		; copy the video offset constants to the 
	ld de,linedraw_lut0			; line draw hardware lookup table
	ld bc,16
	ldir
	

	ld a,13				; copy linecop list to linecop accessible memory			
	call kjt_forcebank
	ld hl,my_linecoplist
	ld de,$8000
	ld bc,end_my_linecoplist-my_linecoplist
	ldir				


	ld a,3				; first word of sample RAM is zero (used for silent loops)
	call kjt_force_bank
	ld hl,0
	ld ($8000),hl
	xor a				; first word of sample RAM is zero (used for silent loops)
	call kjt_force_bank


	ld hl,$000
	ld (palette+$1fc),hl		;set colours for chunky pixel mode / sprites
	ld hl,$0f0
	ld (palette+$1fe),hl
	ld hl,$fff
	ld (palette+$1fa),hl
	ld hl,$f00
	ld (palette+$1f8),hl
	ld hl,$00f
	ld (palette+$1f6),hl
	
	
	ld a,0
	ld hl,packed_sprites
	ld de,sprite_base
	ld bc,end_packed_sprites-packed_sprites
	call unpack_sprites


	ld hl,0				;2nd video pointer - used for split screen
	ld (bitplane0b_loc),hl
	ld (bitplane0b_loc+2),hl
	

	ld a,%00000001
	ld (vreg_sprctrl),a			; enable sprites


	call kjt_get_pen
	ld (pen_colour),a
	

	jp pressed_f1

	
;---------------------------------------------------------------------------------------
; Mainloop
;--------------------------------------------------------------------------------------
	
key_loop	

	call draw_cursor
	call kjt_wait_vrt		
	ld hl,$000
	call kjt_draw_cursor
	
	ld a,(mode)		;dont play fx if in preview on wave editor panel
	cp 1
	jr nz,oktoplfx
	ld a,(preview_mode)
	cp "Y"
	jr z,skipplfx
oktoplfx	call play_fx
	
skipplfx	call process_del_flags	;anything hooked onto variable changes?
	
	call highlight_dep
	call mode_2_editor
	
	call kjt_get_key
	or a
	jr z,key_loop
	ld (current_scancode),a	;store scancode
	ld a,b
	ld (current_asciicode),a	;store ascii version of key
	
	call kjt_get_key_mod_flags	
	and 1
	jr z,skipfkeys		;require shift for function keys
	ld a,(scr_edit_mode)
	or a
	jr nz,skipfkeys		;ignore functions keys if editing a script	
	ld a,(current_scancode)
	cp $05			
	jp z,pressed_f1		;f1
	cp $06
	jp z,pressed_f2		;f2
	cp $04
	jp z,pressed_f3		;f3
	cp $0c
	jp z,pressed_f4		;f4
	cp $03
	jp z,pressed_f5		;f5
	
skipfkeys

	ld a,(current_scancode)
	cp $72
	jp z,pressed_down		;arrow down
	cp $0d
	jp z,pressed_down		;tab
	cp $75
	jp z,pressed_up		;arrow up
	cp $4e
	jp z,pressed_minus		;-
	cp $55
	jp z,pressed_plus		;+
	cp $5a			
	jp z,pressed_enter		;enter
	cp $6b
	jp z,pressed_left		;<-
	cp $74
	jp z,pressed_right		;->
	cp $76			
	jp z,pressed_esc		;ESC
	cp $66
	jp z,pressed_bs		;backspace
	cp $14
	jp z,pressed_lctrl		;left control
	cp $12
	jp z,pressed_lshift		;left shift
	cp $71
	jp z,pressed_delete		;delete
		
	ld a,(current_asciicode)	;entered ascii
	or a
	jp nz,ascii_entry
	
	jp key_loop

;---------------------------------------------------------------------------------------

draw_cursor
	
	ld a,(mode)
	cp 2
	jr nz,notm2dc
	ld a,(scr_edit_mode)
	or a
	ret z
	ld bc,(scr_edit_pos)
	ld a,c
	add a,5
	ld c,a
	jr do_cursor

notm2dc	ld a,(ascii_entry_mode)
	or a
	ret z
	
	call locate_data_entry
	ld hl,input_string_offset		
	ld a,(ix+2)			
	and $3f
	cp (hl)
	jr nz,normcurs		;at last char position?	
	ld a,(hl)
	dec a
	jr lastcurs
	
normcurs	ld a,(hl)
lastcurs	add a,(ix)
	ld b,a
	ld c,(ix+1)	
do_cursor	call kjt_set_cursor_position
	ld hl,$c00
	call kjt_draw_cursor
	ret
	
;---------------------------------------------------------------------------------------

pressed_f1

	xor a
	ld (input_string_offset),a
	ld (ascii_entry_mode),a
	ld a,0
	ld (mode),a
	call kjt_clear_screen
	call no_markers
	call refresh_page
	jp key_loop

;----------------------------------------------------------------------------------------

pressed_f2
	
	xor a
	ld (input_string_offset),a
	ld (ascii_entry_mode),a
	ld a,1
	ld (mode),a
	call kjt_clear_screen
	call clear_wave_image
	call no_markers
	call refresh_page	
	jp key_loop

;----------------------------------------------------------------------------------------

pressed_f3

	xor a
	ld (scr_start_offset),a		;script editor
	ld bc,0
	ld (scr_edit_pos),bc
	ld (input_string_offset),a
	ld (ascii_entry_mode),a	
	ld a,2
	ld (mode),a
	call kjt_clear_screen
	call no_markers
	call refresh_page
	jp key_loop

;----------------------------------------------------------------------------------------

pressed_f4

	xor a
	ld (input_string_offset),a
	ld (ascii_entry_mode),a	
	ld a,3
	ld (mode),a
	call kjt_clear_screen
	call no_markers
	call refresh_page
	jp key_loop

;----------------------------------------------------------------------------------------

pressed_f5

	xor a
	ld (input_string_offset),a
	ld (ascii_entry_mode),a	
	ld a,4
	ld (mode),a
	call kjt_clear_screen
	call no_markers
	call refresh_page
	jp key_loop

;--------------------------------------------------------------------------------------

pressed_down

	ld a,(mode)
	cp 2
	jr nz,notm2d
	ld a,(scr_edit_mode)
	or a
	jr z,notm2d
	ld hl,scr_edit_pos
	ld a,(hl)
	cp 19
	jr z,edposmax
	inc (hl)
	jp key_loop
edposmax	ld hl,scr_start_offset
	inc (hl)
	call show_script_page_header
	call display_ascii_script 
	jp key_loop
	
notm2d	ld a,(ascii_entry_mode)
	or a
	jp nz,key_loop
	xor a
	ld (input_string_offset),a
	ld (ascii_entry_mode),a
	call unhighlight_dep

fnxtdep	ld a,(mode)
	ld e,a
	ld d,0
	ld hl,del_indices
	add hl,de
	inc (hl)
	call locate_data_entry
	ld a,(ix)
	cp $ff
	jr nz,ddeok1
	ld (hl),0
	call locate_data_entry
		
ddeok1	bit 6,(ix+2)		;skip the following check if entry is just a button
	jp nz,key_loop
	call locate_dep_charmap	;if the proceding colon is not displayed, skip to
	dec hl			;next data entry point - note: at least one
	dec hl			;DEP must be active
	ld a,(hl)			
	cp ":"
	jr nz,fnxtdep
	jp key_loop

;--------------------------------------------------------------------------------------

pressed_up

	ld a,(mode)
	cp 2
	jr nz,notm2u
	ld a,(scr_edit_mode)
	or a
	jr z,notm2u
	ld hl,scr_edit_pos
	ld a,(hl)
	or a
	jr z,edpostop
	dec (hl)
	jp key_loop
edpostop	ld hl,scr_start_offset
	dec (hl)
	ld a,(hl)
	cp $ff
	jr nz,sso_ok
	ld (hl),0
sso_ok	call show_script_page_header
	call display_ascii_script 
	jp key_loop

notm2u	ld a,(ascii_entry_mode)
	or a
	jp nz,key_loop
	xor a
	ld (input_string_offset),a
	ld (ascii_entry_mode),a
	call unhighlight_dep

fndpdep	ld a,(mode)
	ld e,a
	ld d,0
	ld hl,del_indices
	add hl,de
	dec (hl)			;move to previous var selection index
	ld a,(hl)
	cp $ff			;wrap around?
	jr nz,udeok

flde	inc (hl)
	call locate_data_entry	;find last entry
	ld a,(ix)
	cp $ff
	jr nz,flde
	dec (hl)			;use the one before the last

udeok	call locate_data_entry
	bit 6,(ix+2)		;skip the following if entry is just a button
	jp nz,key_loop
	call locate_dep_charmap	;if the colon is not displayed (option not
	dec hl			;displayed, find previous DEP) At least one
	dec hl			;dep must be active.
	ld a,(hl)			
	cp ":"
	jr nz,fndpdep
	jp key_loop
	
	
;--------------------------------------------------------------------------------------

pressed_left

	ld a,(scr_edit_mode)
	or a
	jp z,key_loop
	ld hl,scr_edit_pos+1
	ld a,(hl)
	or a
	jp z,key_loop
	dec (hl)
	jp key_loop

;--------------------------------------------------------------------------------------

pressed_right
	
	ld a,(scr_edit_mode)
	or a
	jp z,key_loop
	ld hl,scr_edit_pos+1
	ld a,(hl)
	cp 14
	jp z,key_loop
	inc (hl)
	jp key_loop
	
;--------------------------------------------------------------------------------------

pressed_minus

	xor a
	ld (input_string_offset),a

	call locate_data_entry
	ld a,(ix+5)
	ld (del_flag),a
	ld l,(ix+3)
	ld h,(ix+4)
	ld a,(ix+2)
	cp 2
	jr z,minusb
	cp 4
	jr z,minusw
	jp key_loop
	
minusb	dec (hl)
	call refresh_page
	jp key_loop
	
minusw	ld e,(hl)
	inc hl
	ld d,(hl)
	dec de
	ld (hl),d
	dec hl
	ld (hl),e
	call refresh_page
	jp key_loop

;---------------------------------------------------------------------------------------
	
pressed_plus

	xor a
	ld (input_string_offset),a
	
	call locate_data_entry
	ld a,(ix+5)
	ld (del_flag),a

	ld l,(ix+3)
	ld h,(ix+4)
	ld a,(ix+2)
	cp 2
	jr z,plusb
	cp 4
	jr z,plusw
	jp key_loop
	
plusb	inc (hl)
	call refresh_page
	jp key_loop
	
plusw	ld e,(hl)
	inc hl
	ld d,(hl)
	inc de
	ld (hl),d
	dec hl
	ld (hl),e
	call refresh_page
	jp key_loop
	
;---------------------------------------------------------------------------------------

ascii_entry

	ld a,(mode)
	cp 2
	jr nz,notm2ae
	ld a,(scr_edit_mode)
	or a
	jp z,notm2ae

	ld hl,(scr_edit_pos)		;put ascii char in script buffer
	ld a,(scr_start_offset)
	add a,l
	ld l,a
	ld c,h
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld b,0
	add hl,bc
	ld bc,script_ascii_buffer
	add hl,bc
	ld a,(current_asciicode)
	cp $61
	jr c,locase2
	sub $20
locase2	ld (hl),a	

	ld hl,(scr_edit_pos)		;plot char on screen
	push hl
	pop bc
	ld a,c
	add a,5
	ld c,a
	inc h
	ld (scr_edit_pos),hl
	ld a,h
	cp 15
	jr nz,go_plot
	ld h,14
	ld (scr_edit_pos),hl
	jr go_plot
	
notm2ae	ld a,(ascii_entry_mode)
	or a
	jp z,key_loop

	call locate_data_entry	
	bit 6,(ix+2)			;no data entry if just a button
	jp nz,key_loop	

	ld hl,input_string_offset		;at last char position?
	ld a,(ix+2)			
	and $3f
	cp (hl)
	jr nz,normchar
	ld a,(hl)
	dec a
	jr lastchar
	
normchar	ld a,(hl)
	inc (hl)
lastchar	add a,(ix)
	ld b,a
	ld c,(ix+1)
go_plot	ld a,(current_asciicode)
	cp $61
	jr c,locase
	sub $20
locase	call kjt_plot_char
	jp key_loop
	
;---------------------------------------------------------------------------------------

pressed_bs

	ld a,(ascii_entry_mode)
	or a
	jp z,key_loop

	call locate_data_entry
	ld hl,input_string_offset
	xor a
	or (hl)
	jp z,key_loop
	
	dec (hl)
	ld a,(hl)
	add a,(ix)
	ld b,a
	ld c,(ix+1)
	ld a,32
	call kjt_plot_char
	jp key_loop

;---------------------------------------------------------------------------------------

pressed_esc

	ld a,(scr_edit_mode)	;pressed escape during script edit?
	or a			
	jr z,escsfx
	call silence_fx
	call compile_script
	jr z,comp_ok
	push af
	ld bc,10
	call kjt_set_cursor_position
	pop af
	call show_comp_errors
	ld hl,fix_abandon_txt
	call print_string
wait_dec1	call kjt_wait_key_press
	cp $1c			;if press A = abandon the script edits
	jr nz,back2scr		;else return to editinf
	xor a
	ld (scr_edit_mode),a
	jp pressed_f3
	
back2scr	call kjt_clear_screen
	call show_script_page_header
	call display_ascii_script 
	jp key_loop
	
comp_ok	xor a			;compiled OK - rebuild script list (not done yet)
	ld (scr_edit_mode),a
	call locate_data_entry
	ld (hl),0			;reset DET index (item number)
	call refresh_page
	jp key_loop
	
escsfx	call kjt_clear_screen
	ld hl,quit_txt
	call kjt_print_string
	call ask_if_sure
	jr z,yes_quit
	ld a,(mode)
	or a
	jp z,pressed_f1
	cp 1
	jp z,pressed_f2
	cp 2
	jp z,pressed_f3
	cp 3
	jp z,pressed_f4
	cp 4
	jp z,pressed_f5
	
yes_quit	call kjt_flos_display
	xor a
	out (sys_audio_enable),a
	ret

;---------------------------------------------------------------------------------------

pressed_enter

	ld a,(mode)
	cp 2			;mode 2? (ascii script editor)
	jp nz,notm2pe
	ld a,(scr_edit_mode)
	or a
	jp z,notm2pe
	
insline	ld hl,(scr_edit_pos)	;insert a blank line (move everything down a place)
	ld h,0
	ld (scr_edit_pos),hl	;return cursor to left side
	ld a,(scr_start_offset)
	ld d,0
	ld e,a
	add hl,de
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,script_ascii_buffer
	add hl,de			; hl= postion in text at edit pos
	push hl
	pop ix
	ld hl,script_ascii_buffer+$0fe0
	ld de,script_ascii_buffer+$0ff0
creplp	ld bc,16
	lddr
	push hl
	push ix
	pop hl
	xor a
	sbc hl,de
	pop hl
	jr nz,creplp

	ld b,15
cbllp	ld a,32
	ld (de),a
	inc de
	djnz cbllp
	xor a
	ld (de),a
	
	call show_script_page_header
	call display_ascii_script 
	ld hl,(scr_edit_pos)
	inc l
	ld a,l
	cp 20
	jr nz,curyok
	ld l,19
curyok	ld (scr_edit_pos),hl	
	jp key_loop	

notm2pe	ld a,(ascii_entry_mode)	;already entering data in a DEL box?
	or a
	jr nz,accept_da

	call locate_data_entry	;just a button activation?
	bit 6,(ix+2)
	jr nz,accept_da
	
	ld l,(ix+3)
	ld h,(ix+4)
	ld de,original_data
	ld a,(ix+2)
	and $3f
	ld c,a
	ld b,0
	ldir			;save the original data from the box
	
	ld a,(ix+2)
	and $3f
	ld e,a
	ld b,(ix+0)
	ld c,(ix+1)
	push bc
clrstrlp	ld a,32			;when pressed enter at fresh box, clear its chars
	push de
	push bc
	call kjt_plot_char
	pop bc
	pop de
	inc b
	dec e
	jr nz,clrstrlp
	ld a,1
	ld (ascii_entry_mode),a
	pop bc
	call kjt_set_cursor_position	
	jp key_loop
	
accept_da	call update_var_entry
	xor a
	ld (input_string_offset),a
	ld (ascii_entry_mode),a
	call refresh_page
	jp key_loop

;---------------------------------------------------------------------------------------

pressed_delete

	ld a,(mode)
	cp 2			;mode 2? (ascii script editor)
	jp nz,key_loop
	ld a,(scr_edit_mode)
	or a
	jp z,key_loop

	ld hl,(scr_edit_pos)	
	ld a,(scr_start_offset)	;move all lines up one place
	ld h,0
	ld d,h
	ld e,a
	add hl,de
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,script_ascii_buffer
	add hl,de
	push hl
	pop de
	ld bc,16
	add hl,bc
scrmlu	ld bc,16
	ldir
	push hl
	ld bc,script_ascii_buffer+$1000
	xor a
	sbc hl,bc
	pop hl
	jr nz,scrmlu
	call display_ascii_script
	jp key_loop	
	

;---------------------------------------------------------------------------------------

pressed_lctrl
	
	ld a,(scr_edit_mode)
	or a
	jp nz,key_loop
	ld a,(current_fx)
	call new_fx
	jp key_loop
	
;---------------------------------------------------------------------------------------

pressed_lshift

	call silence_fx
	jp key_loop
	
;---------------------------------------------------------------------------------------

restore_original_data

	call locate_data_entry	
	ld e,(ix+3)
	ld d,(ix+4)
	ld hl,original_data
	ld a,(ix+2)
	and $3f
	ld c,a
	ld b,0
	ldir			
	ret
	
;----------------------------------------------------------------------------------------

refresh_page
	
	ld a,(del_flag)		;flagged ops dont refresh the page - their handlers
	or a			;do it themselves as required.
	ret nz
	
	ld a,(mode)
	or a
	jr z,rfp0
	cp 1
	jr z,rfp1
	cp 2
	jr z,rfp2
	cp 3
	jr z,rfp3
	cp 4
	jr z,rfp4
	ret

rfp0	call show_fx
	ret

rfp1	call show_wave
	ret

rfp2	call show_script
	ret

rfp3	call show_samples
	ret
	
rfp4	call show_loadsave
	ret
		
;---------------------------------------------------------------------------------------

process_del_flags

	ld a,(del_flag)		;any flagged var changes?
	or a
	ret z
	ld b,a
	xor a
	ld (del_flag),a
	
	ld a,b
	cp 1
	jr z,flag1
	cp 2
	jr z,flag2	
	cp 3
	jr z,flag3
	cp 4
	jr z,flag4
	cp 5
	jr z,flag5
	cp 6
	jr z,flag6
	cp 7
	jr z,flag7
	cp 8
	jp z,flag8
	cp 9
	jp z,flag9
	cp 10
	jp z,flag10
	ret
	
flag1	call locate_data_entry	;sample selection changed in wav editor
	ld l,(ix+3)		;pick up default start/end/per from sample list
	ld h,(ix+4)
	ld a,(hl)			;sample number
	dec a
	and $1f
	inc a
	ld (hl),a			;sample range = 1 to 21
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,sample_info
	add hl,de
	push hl
	pop ix
	ld a,(current_wave)		;set the locations that entered data goes to
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,wave_list
	add hl,de
	push hl
	pop iy
	call default_stloclen
	call clear_wave_image
	call no_markers
	call refresh_page
	ret

flag2	call clear_wave_image	;wave selection changed, clear the wave image
	call no_markers
	jr flag7

flag3	call load_sample
	call kjt_clear_screen
	call refresh_page
	ret

flag4	call load_project
	call kjt_clear_screen
	call refresh_page
	ret
		
flag5	call save_project
	call kjt_clear_screen
	call refresh_page
	ret
	
flag6	call optimized_data_save
	call kjt_clear_screen
	call refresh_page
	ret

flag7	call refresh_page		;clip st/end/loop/per etc changed - play wav if in preview mode
	ld a,(preview_mode)
	cp "N"
	ret z
pre_snd	ld a,(current_wave)		
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,wave_list
	add hl,de
	push hl
	pop ix
	ld a,(ix)
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	ld de,sample_loc_lens
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	
	call fx_wait_dma
	xor a
	out (sys_audio_enable),a
	
	ld l,(ix+1)
	ld h,(ix+2)
	add hl,de
	ld b,h
	ld c,$10
	out (c),l
	ld l,(ix+3)	;hl = end
	ld h,(ix+4)
	ld c,(ix+1)	;bc = start
	ld b,(ix+2)
	xor a
	sbc hl,bc
	ld b,h
	ld c,$11
	out (c),l
	inc c
	ld a,(ix+9)
	ld b,(ix+10)
	out (c),a
	inc c
	ld a,$40
	out (c),a

	call fx_wait_dma
	ld a,1
	out (sys_audio_enable),a

	ld c,$10
	ld a,(ix+11)
	cp "Y"
	jr z,preloop
	ld a,0
	ld b,a
	out (c),a
	inc c
	ld a,1
	out (c),a
	ret
	
preloop	ld l,(ix+5)	;hl = loop start
	ld h,(ix+6)
	add hl,de
	ld b,h
	out (c),l
	ld l,(ix+7)	
	ld h,(ix+8)	;hl = loop start
	ld c,(ix+5)
	ld b,(ix+6)	;bc = loop end
	xor a
	sbc hl,bc
	ld b,h
	ld c,$11
	out (c),l
	ret

flag8	call refresh_page
	ld a,(preview_mode)
	cp "Y"
	jp z,pre_snd
	xor a
	out (sys_audio_enable),a
	ret

flag9	xor a			;flag 9 - currrent script selection changed
	ld (scr_start_offset),a
	ld bc,0
	ld (scr_edit_pos),bc
	call kjt_clear_screen
	call refresh_page
	ret

flag10	ld a,1
	ld (scr_edit_mode),a
	call silence_fx
	ret
	
;---------------------------------------------------------------------------------------

; inverses characters at current data entry location (highlight's entry area)

highlight_dep
	
	ld a,(ascii_entry_mode)
	or a
	ret nz
	
	call inverse_video

unhighlight_dep

	call locate_data_entry
	call locate_dep_charmap
		
	ld a,(ix+2)		;number of chars
	and $3f
	ld e,a
	ld b,(ix)
	ld c,(ix+1)
deplp	ld a,(hl)
	push bc
	push de
	push hl
	call kjt_plot_char
	pop hl
	pop de
	pop bc
	inc hl
	inc b
	dec e
	jr nz,deplp
	
	call normal_video
	ret

;------------------------------------------------------------------------------------------

locate_data_entry

	ld a,(mode)
	sla a
	ld e,a
	ld d,0
	ld hl,det_locs
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	push de
	pop ix
	
	ld a,(mode)
	ld e,a
	ld d,0
	ld hl,del_indices
	add hl,de
	ld e,(hl)
	ex de,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ex de,hl			;HL = Data entry index (item number)
	add ix,de			;ix = Data entry table entry address of the currently
	ret			;     selected item

locate_dep_charmap

	ld h,display_width
	ld e,(ix+1)		;y
	call multiply_HE
	ld e,(ix)			;x
	ld d,0
	add hl,de
	ld de,OS_charmap
	add hl,de			;charmap source for chars returns in HL
	ret
				
;---------------------------------------------------------------------------------------

show_byte

	push ix
	ld hl,byte_txt
	call kjt_hex_byte_to_ascii
	ld hl,byte_txt
	call print_string
	pop ix
	ret


show_word

	ld a,d
	call show_byte
	ld a,e
	call show_byte
	ret
	


print_string
	
	push bc
	push de
	push hl
	push ix
	call kjt_print_string
	pop ix
	pop hl
	pop de
	pop bc
	ret

;------------------------------------------------------------------------------------------

update_var_entry

; Takes ascii characters from display charmap at current data entry position and
; updates appropriate variable based on location

; Returns zero flag set if all OK
; Else A = 1, unknown datatype required
;      A = 2, invalid characters for entry
;      A = 3, data out of range

	call locate_data_entry
	ld a,(ix+5)
	ld (del_flag),a
	bit 6,(ix+2)
	jr z,notbut		;no var to update if a button
	xor a
	ret
	 
notbut	ld h,display_width
	ld e,(ix+1)		;y
	call multiply_HE
	ld e,(ix)			;x
	ld d,0
	add hl,de
	ld de,OS_charmap
	add hl,de			;charmap source for chars
	ld a,(ix+2)
	bit 7,a
	jr nz,string_entry
	and $3f
	cp 2
	jr z,byte_entry
	cp 4
	jr z,word_entry
	xor a
	inc a			;unknown data type required
	ret


string_entry
	
	and $3f
	ld c,a
	ld b,0
	ld e,(ix+3)
	ld d,(ix+4)
	ldir
	xor a
	ret

byte_entry

	call kjt_ascii_to_hex_word
	or a
	jr nz,bad_hex
	ld l,(ix+3)
	ld h,(ix+4)
	ld (hl),e
	xor a
	ret
	
word_entry

	call kjt_ascii_to_hex_word
	or a
	jr nz,bad_hex
	ld l,(ix+3)
	ld h,(ix+4)
	ld (hl),e
	inc hl
	ld (hl),d
	xor a
	ret
	

bad_hex	ld a,2
	or a
	ret


;-----------------------------------------------------------------------------------------
	
inverse_video

	ld a,(pen_colour)
	rrca
	rrca
	rrca
	rrca
	call kjt_set_pen
	ret
	
normal_video

	ld a,(pen_colour)
	call kjt_set_pen
	ret
				
;---------------------------------------------------------------------------------------
; Draw page 0 - TOP LEVEL FX edit
;---------------------------------------------------------------------------------------

show_fx	ld bc,0
	call kjt_set_cursor_position

	ld a,(current_fx)			;set the memory locations which the entered data goes to
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,fx_list
	add hl,de
	ld (del_priority),hl
	inc hl
	ld (del_active),hl
	inc hl
	ld (del_ch0wav),hl
	inc hl
	ld (del_ch0vol),hl
	inc hl
	ld (del_ch0script),hl
	inc hl
	ld (del_ch1wav),hl
	inc hl
	ld (del_ch1vol),hl
	inc hl
	ld (del_ch1script),hl
	inc hl
	ld (del_ch2wav),hl
	inc hl
	ld (del_ch2vol),hl
	inc hl
	ld (del_ch2script),hl
	inc hl
	ld (del_ch3wav),hl
	inc hl
	ld (del_ch3vol),hl
	inc hl
	ld (del_ch3script),hl

	ld de,$11
	ld (vreg_linecop_lo),de		; set Linecop address ($0010) and activate.

	call inverse_video
	ld hl,sfxed_txt
	call kjt_print_string
	call normal_video
	
	ld a,(current_fx)
	cp $21
	jr c,nmaxfx
	ld a,1
	ld (current_fx),a
	jr show_fx
nmaxfx	or a
	jr nz,nminfx
	ld a,$20
	ld (current_fx),a
	jr show_fx
nminfx	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,fx_list
	add hl,de
	push hl
	pop ix
	
	ld hl,fx_txt
	call print_string
	ld a,(current_fx)
	call show_byte
	ld hl,pri_txt
	call print_string
	ld a,(ix+0)
	call show_byte	
	ld hl,act_txt
	call print_string
	ld a,(ix+1)
	call show_byte
	ld hl,l1_txt
	call print_string
	
	ld b,4			;4 channels to do
	ld c,0
chloop	push bc
	ld hl,ch_txt
	call print_string
	pop bc
	push bc
	ld a,c
	call show_byte
	ld hl,l2_txt
	call print_string
	
	ld hl,wave_txt
	call print_string
	ld a,(ix+2)
	or a
	jr nz,chused
	ld hl,wnu_txt
	call print_string
	jr nxt_ch

chused	call show_byte
	ld hl,vol_txt
	call print_string
	ld a,(ix+3)
	call show_byte
	
	ld hl,scr_txt
	call print_string
	ld a,(ix+4)
	or a
	jr nz,scrused
	ld hl,snu_txt
	call print_string
	jr nxt_ch	
scrused	call show_byte

nxt_ch	ld de,3
	add ix,de
	pop bc
	inc c
	djnz chloop
	ret
	
		
;------------------------------------------------------------------------------------------
; Draw page 1 - WAVE edit
;---------------------------------------------------------------------------------------

show_wave	

	ld bc,0
	call kjt_set_cursor_position
	ld de,1
	ld (vreg_linecop_lo),de	; set Linecop address ($0000) and activate (bit 0 set)

	ld a,(current_wave)		; set the locations that entered data goes to
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,wave_list
	add hl,de
	ld (del_samplesel),hl
	inc hl
	ld (del_start),hl
	ld de,2
	add hl,de
	ld (del_end),hl
	add hl,de
	ld (del_loop_start),hl
	add hl,de
	ld (del_loop_end),hl
	add hl,de
	ld (del_period),hl
	add hl,de
	ld (del_loop),hl

	call inverse_video
	ld hl,waved_txt
	call kjt_print_string
	call normal_video
	
	ld a,(current_wave)
	cp $21
	jr c,nmaxwav
	ld a,1
	ld (current_wave),a
	jr show_wave
nmaxwav	or a
	jr nz,nminwav
	ld a,$20
	ld (current_wave),a
	jr show_wave
nminwav	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,wave_list
	add hl,de
	push hl
	pop ix
	
	ld hl,wav_txt
	call print_string
	ld a,(current_wave)
	call show_byte
	
	ld hl,prev_txt
	call print_string
	ld hl,n_txt
	ld a,(preview_mode)
	cp "N"
	jr z,noprev
	ld hl,y_txt
noprev	call print_string
		
	ld hl,l3_txt
	call print_string
	
	ld hl,samp_txt
	call print_string
	ld a,(ix)			;sample number used
	call show_byte
	ld hl,sfn_txt
	call print_string
	ld a,(ix)
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,sample_info
	add hl,de
	push hl
	pop iy
	ld a,(iy+18)		;is sample length > 0?
	or (iy+19)
	jr nz,wfnok
	ld hl,undefined_txt
	call print_string
	ld b,10
bl_loop	ld hl,blank_txt
	call print_string
	djnz bl_loop
	call clear_wave_image
	call no_markers
	ret
wfnok	call print_string		;show filename
	
	ld hl,sst_txt
	call print_string
	
	ld l,(ix)				;get sample's full size to test
	ld h,0				;trim limits
	dec hl
	add hl,hl
	add hl,hl
	ld de,sample_loc_lens
	add hl,de		
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld (current_full_sample_length),de	
	ld l,(ix+1)
	ld h,(ix+2)
	xor a
	sbc hl,de				;test start position against full length of sample
	jr c,stook
	ld de,(current_full_sample_length)
	dec de
	ld (ix+1),e
	ld (ix+2),d
stook	ld e,(ix+1)
	ld d,(ix+2)
	ld (current_start),de
	call show_word			;clip's offset from sample start

	ld hl,slen_txt
	call print_string
	
	ld l,(ix+1)			;play start pos
	ld h,(ix+2)
	ld e,(ix+3)			;play end pos
	ld d,(ix+4)
	xor a
	sbc hl,de				;compare start with end pos
	jr c,endstok
	ld l,(ix+1)
	ld h,(ix+2)
	inc hl
	ld (ix+3),l			;end = start + 1
	ld (ix+4),h

endstok	ld e,(ix+3)
	ld d,(ix+4)			;play end pos
	ld hl,(current_full_sample_length)	
	xor a
	sbc hl,de				;compare end pos with total sample length
	jr nc,sepok
	ld de,(current_full_sample_length)
	ld (ix+3),e
	ld (ix+4),d	
sepok	ld (current_end),de
	call show_word			;clip's end pos
	
	ld hl,per_txt
	call print_string	
	ld e,(ix+9)
	ld d,(ix+10)
	call show_word
	
	ld hl,loop_txt
	call print_string	
	ld a,(ix+11)
	ld (current_loop),a
	cp "Y"
	jr z,yesloop
	ld (ix+11),"N"
	ld hl,n_txt
	call print_string
	ld b,4
blines2	ld hl,blank_txt
	call print_string
	djnz blines2
	jp skiploop

yesloop	ld hl,y_txt
	call print_string
	ld hl,lst_txt
	call print_string
	ld l,(ix+5)			;sample loop offset from start
	ld h,(ix+6)
	ld de,(current_full_sample_length)
	xor a
	sbc hl,de				;compare loop start pos with full sample length
	jr c,lstook
	ld de,(current_full_sample_length)
	dec de
	ld (ix+5),e
	ld (ix+6),d
lstook	ld e,(ix+5)
	ld d,(ix+6)	
	ld (current_loop_start),de
	call show_word	
	
	ld hl,llen_txt
	call print_string
	ld l,(ix+5)	
	ld h,(ix+6)
	ld e,(ix+7)
	ld d,(ix+8)
	xor a
	sbc hl,de
	jr c,lendstok			;compare loop start and loop end
	ld l,(ix+5)	
	ld h,(ix+6)
	inc hl
	ld (ix+7),l
	ld (ix+8),h

lendstok	ld e,(ix+7)
	ld d,(ix+8)			
	ld hl,(current_full_sample_length)
	xor a
	sbc hl,de
	jr nc,lsepok			;compare loop end with length
	ld de,(current_full_sample_length)
	ld (ix+7),e
	ld (ix+8),d	
lsepok	ld (current_loop_end),de
	call show_word
	
	
skiploop	ld l,(ix)				;scale waveform to fit on screen (get 320 points)
	ld h,0				;hl = sample number used (starts at 1)
	dec hl
	add hl,hl
	add hl,hl
	ld de,sample_loc_lens
	add hl,de				;HL  = start of sample locations table
	push hl
	pop iy
	ld e,(iy+0)			;DE = absolute word location in sample RAM (0-65535)
	ld d,(iy+1)
	ld a,d
	rlca
	rlca
	and 3				;convert to bank number and 8000-ffff address
	add a,4
	exx
	ld b,a				;store the source bank 
	exx 
	ex de,hl
	add hl,hl
	set 7,h				;hl source address
	ld (sample_base),hl
	
	ld e,(iy+2)			;DE = number of words in entire sample
	ld d,(iy+3)			
	ld (total_sample_length),de
	sla e
	rl d
	ld (mult_table+256),de		;DE = total length of sample in bytes (32KB limit)
	ld a,128
	ld (mult_index),a
	
	ld hl,0				;get points from this wave to represent it on screen
	ld bc,window_width_pixels		;number of points
	ld de,wave_points
dwloop	ld (mult_write),hl			;scaling step, 0 to 16384 in steps of (16384/320)		
	ld a,51				;IE:16384/window_width_pixels
	add a,l
	ld l,a
	jr nc,nocarry1
	inc h
nocarry1	exx
	ld hl,(sample_base)			
	ld de,(mult_read)
	add hl,de				;index in wave
	jr nc,sbankok
	inc b				;next bank
	ld de,(sample_base)
	res 7,d
	ld (sample_base),de
sbankok	ld a,b
	out (sys_mem_select),a
	ld a,(hl)				;get sample byte
	sra a
	sra a
	add a,32				;convert to 0-64 range (pixel y)
	exx 
	ld (de),a
	xor a
	out (sys_mem_select),a	
	inc de
	dec bc
	ld a,b
	or c
	jr nz,dwloop
	
lines	ld bc,319				; draw the wave using linedraw system
	ld hl,wave_points
	ld ix,line_coords
	ld de,0				; xcoord 
dlloop	ld (ix+0),e			; start x
	ld (ix+1),d
	inc de
	ld (ix+4),e			; end x
	ld (ix+5),d		
	ld a,(hl)				; y coord
	ld (ix+2),a			; start y
	inc hl
	ld a,(hl)
	ld (ix+6),a			; end y
	exx
	ld a,$ff				; line colour
	call draw_line
	exx
	dec bc
	ld a,b
	or c
	jr nz,dlloop
	

	ld bc,window_width_pixels-1
	ld (end_marker_x),bc
	ld (loop_end_marker_x),bc
	inc bc
	ld de,(total_sample_length)		;DE = total length of sample in words	
	ld (mult_table+256),de		
	ld a,128				;find locations for marker sprites (slow+crude maths here)
	ld (mult_index),a
	ld hl,0						
	ld ix,0
mrkloop	ld (mult_write),hl					
	ld de,51				;IE: 16384 / 320		
	add hl,de
	push hl

	ld hl,(mult_read)
	ld de,(current_start)
	xor a
	sbc hl,de
	jr z,gotsmx
	jr c,notgsmx
gotsmx	ld (start_marker_x),ix
	ld de,$ffff
	ld (current_start),de

notgsmx	ld hl,(mult_read)
	ld de,(current_loop_start)
	xor a
	sbc hl,de
	jr z,gotlsmx
	jr c,notglmx
gotlsmx	ld (loop_start_marker_x),ix
	ld de,$ffff
	ld (current_loop_start),de

notglmx	ld hl,(mult_read)
	ld de,(current_end)
	xor a
	sbc hl,de
	jr z,gotemx
	jr c,notgemx
gotemx	ld (end_marker_x),ix
	ld de,$ffff
	ld (current_end),de

notgemx	ld hl,(mult_read)
	ld de,(current_loop_end)
	xor a
	sbc hl,de
	jr z,gotlemx
	jr c,notgelmx
gotlemx	ld (loop_end_marker_x),ix
	ld de,$ffff
	ld (current_loop_end),de

notgelmx	pop hl
	inc ix
	dec bc
	ld a,b
	or c
	jr nz,mrkloop

	ld hl,(start_marker_x)		;start end sprites
	ld de,marker_y
	ld a,0
	ld ix,sprite_registers+8
	call update_sprite_register
	ld hl,(end_marker_x)
	ld de,6
	xor a
	sbc hl,de
	ld de,marker_y
	ld a,4
	ld ix,sprite_registers+12
	call update_sprite_register
	
	ld a,(current_loop)
	cp "Y"
	jr z,showlm
	ld hl,sprite_registers
	ld b,8
nsmlp	ld (hl),0
	inc hl
	djnz nsmlp
	ret

showlm	ld hl,(loop_start_marker_x)		;loop start end sprites
	ld de,marker_y
	ld a,8
	ld ix,sprite_registers+0
	call update_sprite_register
	ld hl,(loop_end_marker_x)
	ld de,6
	xor a
	sbc hl,de
	ld de,marker_y
	ld a,12
	ld ix,sprite_registers+4
	call update_sprite_register
nolpsprs	ret
	

;-------------------------------------------------------------------------------------------------------
; Draw Page 2 - Script Editor
;-------------------------------------------------------------------------------------------------------

show_script

script_ascii_buffer equ $f000
	
	call show_script_page_header
	ld hl,0
	ld (script_lines),hl
		
	ld hl,fx_data
	ld de,(fx_data+38)
	add hl,de
	ld (scr_table),hl
	ld hl,fx_data
	ld de,(fx_data+40)
	add hl,de
	ld (scr_base),hl
		
	ld hl,script_ascii_buffer
	push hl
	ld de,$1000
	add hl,de
	ex de,hl
	pop hl
cbmem2	ld b,15
cbmem1	ld (hl),32
	inc hl
	djnz cbmem1
	ld (hl),0
	inc hl
	ld a,h
	cp d
	jr nz,cbmem2
	
	ld a,(current_script)		;convert the current script into an
	dec a				;ascii file in buffer space at $f000
	sla a
	sla a
	ld e,a
	ld d,0
	ld hl,(scr_table)
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)				
	ld hl,(scr_base)
	add hl,de
	ex de,hl				;de = first byte (opcode) of current script
	ld ix,script_ascii_buffer-16		;ix = buffer address for ascii version of script
		
list_scr	push ix
	pop hl
	ld bc,16
	add hl,bc
	jp c,scr_toobig
	ld a,l
	and $f0
	ld l,a
	push hl
	pop ix					
	ld b,15				;clear 15 byte ascii line with spaces, null terminate
wstas	ld (hl),32
	inc hl
	djnz wstas
	ld (hl),0
	
	ld hl,script_commands
fndcmd	ld a,(de)
	cp (hl)				;does the opcode match?
	jr z,got_scmd
fndncmd	inc hl
	ld a,(hl)
	cp $ff
	jr z,lastscmd
	or a
	jr nz,fndncmd
	inc hl				;skip the 0 termination
	jr fndcmd
lastscmd	ld hl,unk_scrent-2
	
got_scmd	inc hl				;skip opcode
	ld c,(hl)				;get parameter size
	inc hl				;skip parameter size
	push ix
	pop iy
opclp	ld a,(hl)
	or a
	jr z,cpdopc
	ld (iy),a				;copy opcode - if encounter a zero, opcode done
	inc hl
	inc iy
	jr opclp

cpdopc	push hl
	ld hl,(script_lines)
	inc hl
	ld (script_lines),hl
	pop hl
	
	push bc
	ld bc,7				;move write position to 7 chars across for parameter
	add ix,bc
	pop bc
	ld a,(de)
	or a
	jr z,endofscr			;was it a "done" command?		
	inc de
	ld a,c
	or a
	jr z,list_scr			;no parameters for this opcode
scr_para	cp 2			
	jr z,scrshw
	ld a,(de)
	push ix
	pop hl
	call kjt_hex_byte_to_ascii
	inc de
	jr list_scr
scrshw	inc de
	ld a,(de)
	push ix
	pop hl
	call kjt_hex_byte_to_ascii
	inc ix
	inc ix
	dec de
	ld a,(de)
	push ix
	pop hl
	call kjt_hex_byte_to_ascii
	inc de
	inc de
	jp list_scr

endofscr	push ix
	pop hl
	ld bc,16
	add hl,bc
	jp c,scr_toobig
	ld a,l
	and $f0
	ld l,a
	push hl
	pop ix

display_ascii_script

	ld a,(scr_start_offset)		;write the ascii version to the screen
	cp 234
	jr c,sposok
	ld a,234
	ld (scr_start_offset),a
sposok	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,script_ascii_buffer
	add hl,de
	ld b,0
	ld c,5
shscr	ld (scr_cursor_pos),bc
	call kjt_set_cursor_position
	call print_string
	ld bc,16
	add hl,bc
	ld bc,(scr_cursor_pos)
	inc c
	ld a,c
	cp 25
	jr nz,shscr
	
	
	ld b,22
	ld c,5
	call kjt_set_cursor_position
	call inverse_video
	ld hl,scr_cmd_list_txt
	call kjt_print_string
	call normal_video
	ld e,17
	ld ix,script_opcode_list
	ld b,26
	ld c,7
scmdlp	call kjt_set_cursor_position
	ld l,(ix)
	ld h,(ix+1)
	inc hl
	inc hl
	push ix
	push bc
	push de
	call kjt_print_string
	pop de
	pop bc
	pop ix
	inc ix
	inc ix
	inc c
	dec e
	jr nz,scmdlp
		
	ret
	

scrfw	ret

scr_toobig
	
	ret


mode_2_editor

	ld a,(mode)
	cp 2
	ret nz

	
	ret
	
	
show_script_page_header
 
 	xor a
	ld (scr_allow_scroll),a
	ld bc,0
	call kjt_set_cursor_position
	ld de,$11
	ld (vreg_linecop_lo),de		; set Linecop address ($0010) and activate.

	call inverse_video
	ld hl,script_ed_txt
	call kjt_print_string
	call normal_video
	ld hl,script_no_txt
	call kjt_print_string
	ld a,(current_script)
	dec a
	and $1f
	inc a
	ld (current_script),a
	call show_byte
	ld hl,underline_txt
	call kjt_print_string
	ret


;------------------------------------------------------------------------------------------------------

script_compilation_buffer equ $e000

compile_script

	ld hl,script_ascii_buffer
	ld iy,script_compilation_buffer	
	
scancmds	ld (comp_line),hl		;for error report
	ld ix,script_commands

findcmd	push ix
	pop de			;address of command number
	inc ix
	inc ix			;ix = first ascii byte of command

findcmdch	ld b,10
ffcocmd	ld a,(hl)			;get byte from edited text
	cp 32
	jr nz,notspc		;skip any spaces on the line
	inc hl
	djnz ffcocmd
	ld a,4			;if more than 8 spaces, give up on the line
	or a			;error 4 - malformed line
	ret

notspc	or a			;if encounter a zero in ascii area, consider it
	jr z,no_done		;end of script before DONE encountered: error!	

tryrest	ld a,(ix)			
	or a
	jr z,thiscmd		;reached a zero in list of commands = found command
	cp (hl)
	jr nz,notthcmd		
	inc hl			;test more characters
	inc ix
	jr tryrest
	
notthcmd	inc ix			;move to next command - find following zero
	ld a,(ix)
	or a
	jr nz,notthcmd
	ld hl,(comp_line)
	inc ix			;skip the terminating zero
	ld a,(ix)		
	cp $ff			;is the next byte $ff? (last command)
	jr nz,findcmd
unk_cmd	ld a,1			;error code 1 = unknown command
	or a
	ret

thiscmd	ld a,(de)			;command number
	ld (iy),a
	or a
	jr z,compdone		;if 0 = reached "DONE"
	inc iy
	inc de
	ld a,(de)			;number of bytes in argument
	or a
	jr z,gonxtl
	push hl
	push de
	call kjt_ascii_to_hex_word
	push de
	pop bc
	or a
	jr z,hexok
	pop de
	pop hl
	ld a,3			;error code 3 = bad hex in argument
	or a
	ret
	
hexok	pop de			;fill in argument byte 1		
	pop hl
	ld (iy),c
	inc iy
	ld a,(de)
	cp 1
	jr z,gonxtl
	ld (iy),b
	inc iy
	
gonxtl	ld hl,(comp_line)
	ld de,16
	add hl,de			;next script line
	push hl
	ld de,script_ascii_buffer+$ff0
	xor a
	sbc hl,de
	pop hl
	jp c,scancmds
	
no_done	ld a,2			;error code 2 = script too big (no DONE command)
	or a
	ret
	

		
compdone  inc iy
	push iy
	pop hl
	xor a
	ld de,script_compilation_buffer
	sbc hl,de
	ld (new_script_length),hl

	ld hl,scripts		;Take all the original scripts and fit them
	ld de,(total_scripts_length)	;end-to-end in a new buffer
	add hl,de			
	ld (script_rebuild_buffer_loc),hl
	ld a,(current_script)	
	ld c,a
	ld a,33
	sub c
	ld c,a			;C = (33 - script number being replaced)
	ld iy,script_loc_lens
	ld b,32
scr_rblp	ld a,b
	cp c
	jr z,scriptnu		;dont include the current script number (being replaced)
	ld e,(iy)
	ld d,(iy+1)		;de = existing location
	push de
	push hl
	ld de,(script_rebuild_buffer_loc)
	xor a
	sbc hl,de
	ld (iy),l			;update the location pointer
	ld (iy+1),h
	pop hl
	pop de
	ld ix,scripts
	add ix,de
	ld e,(iy+2)		;length of script
	ld d,(iy+3)
nscrblp	ld a,(ix)
	ld (hl),a
	inc ix
	inc hl
	dec de
	ld a,d
	or e
	jr nz,nscrblp
scriptnu	inc iy
	inc iy
	inc iy
	inc iy
	djnz scr_rblp
		
	ld a,(current_script)	;put location of new script (end of collated data loc) in location table
	dec a			
	sla a
	sla a			
	ld e,a
	ld d,0
	ld ix,script_loc_lens
	add ix,de
	push hl
	ld de,(script_rebuild_buffer_loc)
	xor a
	sbc hl,de
	ld (ix),l
	ld (ix+1),h
	ld hl,(new_script_length)	;also add length of new script
	ld (ix+2),l
	ld (ix+3),h
	pop hl
	
	ld de,script_compilation_buffer	;copy the compiled script to the end of the collated data
	ex de,hl
	ld bc,(new_script_length)
	ldir 
	ex de,hl
	ld de,(script_rebuild_buffer_loc)	;update total script length
	xor a
	sbc hl,de
	ld (total_scripts_length),hl
	
	ld hl,(script_rebuild_buffer_loc)	;finally, replace old scripts with new ones.
	ld de,scripts
	ld bc,(total_scripts_length)
	ldir

	ld hl,2350
	ld de,(total_scripts_length)
	add hl,de
	ld (proj_header_size),hl		;update length of project header
	
	xor a				;returns ZF set, A = 0, all done
	ret				;IY = last address of script in compilation buffer + 1
		
;------------------------------------------------------------------------------------------------------

show_comp_errors

	push af
	ld hl,script_error_txt
	call kjt_print_string
	pop af
	cp 1
	call z,unkcmde
	cp 2
	call z,scr2bige
	cp 3
	call z,hexbade
	cp 4
	call z,malfe
	call print_string
	ld hl,(comp_line)
	call print_string
	ret
	
unkcmde	ld hl,unknown_cmd_txt
	ret
scr2bige	ld hl,script_too_big_txt
	ret
hexbade	ld hl,bad_hex_txt
	ret
malfe	ld hl,malformed_txt
	ret		
			
;------------------------------------------------------------------------------------------------------
	
new_line	ld hl,cr_txt
	call print_string
	ret
	
;-------------------------------------------------------------------------------------------------------
; Draw Page 3 - Sample Loader
;-------------------------------------------------------------------------------------------------------

show_samples

	ld bc,0
	call kjt_set_cursor_position

	ld de,$11
	ld (vreg_linecop_lo),de		; set Linecop address ($0010) and activate.

	call inverse_video
	ld hl,sample_load_txt
	call kjt_print_string
	call normal_video

	ld hl,sample_bank_txt
	call kjt_print_string
	
	ld ix,sample_info
	ld b,5
ssblp2	ld c,4
ssblp1	push bc
	call kjt_set_cursor_position
	push ix
	pop hl
	ld a,(ix)
	or a
	jr nz,fnisu
	ld hl,undefined_txt
fnisu	call print_string
	ld bc,32
	add ix,bc
	pop bc
	inc c
	ld a,c
	cp 20
	jr nz,ssblp1
	ld a,b
	ld b,27
	cp 27
	jr nz,ssblp2
	ret
	
;-------------------------------------------------------------------------------------------------------
; Draw Page 4 - Load / Save
;-------------------------------------------------------------------------------------------------------

show_loadsave

	ld bc,0
	call kjt_set_cursor_position

	ld de,$11
	ld (vreg_linecop_lo),de		; set Linecop address ($0010) and activate.

	call inverse_video
	ld hl,project_loadsave_txt
	call kjt_print_string
	call normal_video

	ld hl,loadsavepage_txt
	call kjt_print_string
	
	ld b,12
	ld c,5
	call kjt_set_cursor_position
	ld hl,proj_filename
	call print_string
	ld b,24
	ld c,14
	call kjt_set_cursor_position
	ld hl,opt_data_fn
	call print_string
	ld b,24
	ld c,16
	call kjt_set_cursor_position
	ld hl,opt_samples_fn
	call print_string
	ret
	
;-------------------------------------------------------------------------------------------------------

draw_line

; Note coord system has y=0 at the highest location in VRAM
; set IX to coords (startx,starty,endx,endy)
; set A = linecolour
; Limitation: y = 0 to 63 max (entries in lookup table)


	ld hl,vreg_read
ld_wait1	bit 4,(hl)		; ensure any previous line draw / blit op is complete
	jr nz,ld_wait1		; before restarting line draw setup

	ld (linedraw_colour),a

next_line	ld c,0			; reset the octant code / address MSBs
	ld l,(ix+2)		; y0 LSB
	ld h,c
	add hl,hl
	ld de,ylookup_table
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	ld e,(ix)			
	ld d,(ix+1)		; de = x0
	add hl,de			; hl = video start address
	jr nc,no_sacar
	inc c
no_sacar	ld (linedraw_reg2),hl	; Hardware line draw constant: Start Address [15:0]
	sla c			; shift line address MSBs to [11:9] of octant code reg

	ld l,(ix+4)			
	ld h,(ix+5)		; hl = x1
	xor a			; clear carry flag
	sbc hl,de			; hl = delta_x (x1-x0)
	bit 7,h
	jr z,xdeltapos		; is delta_x positive?
	ex de,hl			; make it positive if not
	xor a
	ld l,a
	ld h,a
	sbc hl,de			
	set 4,c			; update octant settings bit 4
	
xdeltapos	ld (delta_x),hl		; stash delta_x
	ld e,(ix+2)		
	ld d,(ix+3)		; de = y0
	ld l,(ix+6)
	ld h,(ix+7)		; hl = y1
	xor a
	sbc hl,de			; hl = delta y (y1-y0)
	bit 7,h
	jr z,ydeltapos		; is delta_y positive?
	ex de,hl			; make it positive if not
	xor a
	ld l,a
	ld h,a
	sbc hl,de			
	set 5,c			; update octant settings bit 5

ydeltapos	ld (delta_y),hl		; stash delta_y
	ld de,(delta_x)		; hl = delta_y, de = delta_x
	xor a
	sbc hl,de			; hl = (delta_y - delta_x)
	jr c,horiz_seg		; if delta_x > delta_y then the line has horizontal segments

	xor a			; vertical segment code.. 
	ex de,hl			; de = (delta_y - delta_x)
	ld l,a			
	ld h,a			; hl = 0
	sbc hl,de			; hl = (delta_x - delta_y)
	add hl,hl
	ld (linedraw_reg0),hl	; Hardware linedraw Constant: 2 x (delta_x - delta_y)	
	ld hl,(delta_x)
	add hl,hl
	ld (linedraw_reg1),hl	; Hardware Linedraw Constant: 2 x delta_x	
	set 6,c			; update octant settings
	ld de,(delta_y)		; de = line length
	jp line_len
	
horiz_seg	add hl,hl
	ld (linedraw_reg0),hl	; Hardware Linedraw Constant: 2 x (delta_y - delta_x)
	ld hl,(delta_y)
	add hl,hl
	ld (linedraw_reg1),hl	; Hardware Linedraw Constant: 2 x delta_y

line_len	ld a,d			; de = line length (assumes length < $0200, as it should be)
	or c			; OR in the octant / addr MSB bits
	ld d,a			; DE = composite of MSB,octant code and line length

	ld (linedraw_reg3),de	; line length, octant code, y address MSB & Start line draw.
	ret
	

;-------------------------------------------------------------------------------------------------------------------

linedraw_constants

	dw (65536-window_width_pixels)+1
	dw (65536-window_width_pixels)-1
	dw window_width_pixels+1	
	dw window_width_pixels-1
	dw 1
	dw 65535
	dw (65536-window_width_pixels)
	dw window_width_pixels



delta_x	dw 0
delta_y	dw 0


line_coords

	dw 0,0	;start x / y
	dw 0,0	;end x / y

;-------------------------------------------------------------------------------------------------------------------

clear_wave_image
	
	ld hl,0+(64*window_width_pixels)
	ld (blit_src_loc),hl	
	ld hl,0
	ld (blit_dst_loc),hl
	xor a
	ld (blit_src_msb),a
	ld (blit_dst_msb),a
	ld (blit_dst_mod),a
	ld (blit_src_mod),a
	ld a,%01000000
	ld (blit_misc),a		
	ld a,159
	ld (blit_height),a
	ld a,127
	ld (blit_width),a		;160 * 128 = clear 320*64 pixels 
	call wait_blit
	ret

;----------------------------------------------------------------------------------------------------------------

no_markers

	ld b,16
	ld hl,spr_registers		; by default, remove sprite markers
wsplp	ld (hl),0
	inc hl
	djnz wsplp
	ret
	
;------------------------------------------------------------------------------------------------------------


wait_blit
	ld hl,vreg_read
bl_wait	bit 4,(hl)		; ensure any previous blit op is complete
	jr nz,bl_wait		
	ret

;------------------------------------------------------------------------------------------------------------

ask_if_sure

	ld hl,sure_txt
	call kjt_print_string
	call kjt_wait_key_press	;returns ZF set if "Y"
	cp $35
	ret		

;---------------------------------------------------------------------------------------
; Project loading dept.
;---------------------------------------------------------------------------------------

load_project

	ld b,0
	ld c,21
	call kjt_set_cursor_position

	ld hl,loading_txt
	call kjt_print_string
	
	ld hl,proj_filename
	call kjt_find_file
	jr z,proj_exists
pload_err	ld hl,fnf_txt		; file not found, replace old filename with
pload_er2	call kjt_print_string	; "undefined"
	call kjt_wait_key_press
	ret

proj_exists

	ld ix,0			; load the first 4 bytes (size headers)
	ld iy,4
	call kjt_set_load_length
	ld hl,proj_header_size
	ld b,0
	call kjt_force_load		
	ld hl,hload_error_txt
	jr nz,pload_er2
			
	ld ix,0			; load the header itself
	ld hl,(proj_header_size)			
	dec hl
	dec hl
	dec hl
	dec hl
	push hl
	pop iy
	call kjt_set_load_length
	ld hl,proj_header_size+4
	ld b,0
	call kjt_force_load
	ld hl,hload_error_txt
	jr nz,pload_er2
	
	ld hl,(total_samples_size)	; load the samples
	ld de,0
	add hl,hl
	rl e
	push de
	pop ix
	push hl
	pop iy
	call kjt_set_load_length
	ld hl,$8000
	ld b,3
	call kjt_force_load
	ld hl,sload_error_txt
	jr nz,pload_er2
	
	ld hl,file_loaded_txt
	call kjt_print_string	
	call kjt_wait_key_press
	ret

;---------------------------------------------------------------------------------------
; Project saving dept.
;---------------------------------------------------------------------------------------

save_project

	ld b,0
	ld c,21
	call kjt_set_cursor_position

	ld hl,proj_filename
	call kjt_find_file
	jr nz,proj_fn_ok
psave_err	ld hl,file_exists_txt	; file already exists
psave_er2	call kjt_print_string	
	call kjt_wait_key_press
	ret

proj_fn_ok

	ld b,0
	ld c,21
	call kjt_set_cursor_position
	ld hl,saving_txt
	call kjt_print_string

	ld ix,proj_header_size	; save the header (non sample part)
	ld b,0
	ld de,(proj_header_size)
	ld c,0
	ld hl,proj_filename
	call kjt_save_file
	ld hl,hsave_error_txt
	jr nz,psave_er2
	
	ld c,0
	ld hl,(total_samples_size)	; append the samples
	add hl,hl
	rl c
	ex de,hl	
	ld hl,proj_filename
	ld ix,$8000
	ld b,3
	call kjt_write_bytes_to_file
	ld hl,ssave_error_txt
	jr nz,psave_er2	
	
psaved	ld hl,proj_filename		;verify file (cehck exists and correct size)
	call kjt_find_file
	ld bc,0
	ld hl,(total_samples_size)
	add hl,hl
	rl c
	ld de,(proj_header_size)
	add hl,de
	jr nc,vnocar
	inc c
vnocar	ex de,hl
	xor a
	push iy
	pop hl
	sbc hl,de
	jr nz,saveerror
	xor a
	push ix
	pop hl
	sbc hl,bc
	jr z,saved_ok
saveerror ld hl,ver_error_txt
	jp psave_er2
	
saved_ok	ld hl,file_saved_txt
	call kjt_print_string	
	call kjt_wait_key_press
	ret


;---------------------------------------------------------------------------------------
; Optimized files saving dept.
;---------------------------------------------------------------------------------------

optimized_data_save	

work_buffer equ $c000		;Optimized FX data is put here for saving

	ld b,0
	ld c,20
	call kjt_set_cursor_position

	ld hl,optimizing_txt
	call kjt_print_string

	ld iy,fx_list		;create a list of used fx number slots	
	ld hl,required_fx_list
	ld b,32	
	ld c,1	
mrfxlist	ld a,(iy+2)		;if this effect has a wave specified on any
	or (iy+5)			;of its channels, then its a required FX
	or (iy+8)
	or (iy+11)
	jr z,fxennu
	ld (hl),c
	inc hl
fxennu	inc c
	ld de,16
	add iy,de
	djnz mrfxlist
	xor a
	ld de,required_fx_list
	sbc hl,de
	ld a,l
	ld (number_of_required_fx),a
	or a
	jp z,no_fx_defined

	
	ld hl,work_buffer		;clear 46 byte header
	ld b,46			
clofxl	ld (hl),0
	inc hl
	djnz clofxl
	
	
	ld ix,required_fx_list	;populate the optimized fx translation header	
	ld c,0
	ld a,(number_of_required_fx)
	ld b,a
moindfxl	ld e,(ix)
	dec e
	ld d,0
	ld hl,work_buffer
	add hl,de
	ld (hl),c
	inc ix
	inc c
	djnz moindfxl


	
	ld hl,46			
	ld (work_buffer+32),hl	; set "offset to fx"
	ld hl,work_buffer
	ld de,(work_buffer+32)
	add hl,de
	ld (opt_fx_address),hl


	
	ld de,(opt_fx_address)	; collate the required fx data to the work buffer
	ld ix,required_fx_list	; the clip and script references will be updated
	ld a,(number_of_required_fx)	; later
	ld b,a
mofxl	ld a,(ix)
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	push bc
	ld bc,fx_list
	add hl,bc
	ld bc,16
	ldir
	pop bc
	inc ix
	djnz mofxl
	ld (opt_clips_address),de
	ld hl,work_buffer
	ex de,hl
	xor a
	sbc hl,de
	ld (work_buffer+34),hl	;set "offset to clips"
	
	
	
	ld e,1			;create a list of required scripts
	ld d,32
	ld hl,required_scripts_list
fsreqlp	ld iy,(opt_fx_address)			
	ld a,(number_of_required_fx)
	ld b,a
scfxfs	ld a,e
	cp (iy+4)
	jr z,scrreq
	cp (iy+7)
	jr z,scrreq
	cp (iy+10)
	jr z,scrreq
	cp (iy+13)
	jr z,scrreq
	push bc
	ld bc,16
	add iy,bc
	pop bc
	djnz scfxfs
	jr scnotreq
scrreq	ld (hl),e
	inc hl
scnotreq	inc e
	dec d
	jr nz,fsreqlp
	ld de,required_scripts_list
	xor a
	sbc hl,de
	ld a,l
	ld (number_of_required_scripts),a
	

				
	ld hl,required_clips_list	;create a list of used clips 
	ld b,32	
	ld c,1			;clip to look for in "used fx list"
fcreqlp	push hl
	push bc
	ld a,(number_of_required_fx)
	ld b,a
	ld iy,(opt_fx_address)
scfxfc	ld a,c
	cp (iy+2)
	jr z,clreq
	cp (iy+5)
	jr z,clreq
	cp (iy+8)
	jr z,clreq
	cp (iy+11)
	jr z,clreq
	call check_for_script_reference	;need to also check the in-used scripts
	jr z,clreq			;in case any script references this clip
	ld de,16				;with a CLIP instruction.
	add iy,de
	djnz scfxfc
	pop bc
	pop hl
	jr clnotreq
clreq	pop bc
	pop hl
	ld (hl),c
	inc hl
clnotreq	inc c
	djnz fcreqlp
	ld de,required_clips_list
	xor a
	sbc hl,de
	ld a,l
	ld (number_of_required_clips),a
	


	ld de,(opt_clips_address)		;collate the required clips to the new
	ld ix,required_clips_list		;data buffer 
	ld a,(number_of_required_clips)
	ld b,a
mocllp	ld l,(ix)
	dec l
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	push bc
	ld bc,wave_list
	add hl,bc
	ld bc,16
	ldir
	pop bc
	inc ix
	djnz mocllp
	ld (opt_samples_loclens),de
	ld hl,work_buffer
	ex de,hl
	xor a
	sbc hl,de
	ld (work_buffer+36),hl		;set offset to loc/lens



	ld hl,(opt_fx_address)		;in the optimized fx buffer, change the clip numbers
	ld a,(number_of_required_fx)		;to their optimized values
	ld e,a
swcliplp	push hl				;for each new FX...
	pop ix
	ld d,4				;for each channel of FX...
lffchans	ld a,(number_of_required_clips)
	ld b,a
	ld c,1				;clip number to look for
	ld iy,required_clips_list
fclntr	ld a,(ix+2)
	or a
	jr z,ncltoch			;if this channel's clip = 0, nothing to change
	cp (iy)
	jr z,gclntr
	inc c
	inc iy
	djnz fclntr
	jp nz,compilation_error1		;didnt find clip number to replace
gclntr	ld (ix+2),c
ncltoch	inc ix
	inc ix
	inc ix
	dec d
	jr nz,lffchans	
	ld bc,16
	add hl,bc
	dec e
	jr nz,swcliplp
	


	ld hl,required_samples_list		;create a list of samples used by in-use clips
	ld e,32	
	ld c,1				;sample to look for in "used clips list"
samreqlp	ld ix,(opt_clips_address)	
	ld a,(number_of_required_clips)
	ld b,a
scsamfc	ld a,(ix)				;a = sample number used by this clip
	cp c
	jr nz,sampnreq
	ld (hl),c
	inc hl
	jr nxticlos
sampnreq	push de
	ld de,16
	add ix,de
	pop de
	djnz scsamfc
nxticlos	inc c
	dec e
	jr nz,samreqlp
	ld de,required_samples_list
	xor a
	sbc hl,de
	ld a,l
	ld (number_of_required_samples),a



	ld de,(opt_samples_loclens)		;make optimized sample loc/len list 
	ld ix,required_samples_list		;(only make entries for the samples required)
	ld iy,1				;new location tally
	ld a,(number_of_required_samples)
	ld b,a
mosamll	push bc
	push iy
	pop hl
	ld a,l
	ld (de),a				;update loc lo
	inc de
	ld a,h
	ld (de),a				;update loc hi
	inc de
	ld a,(ix)				;sample number
	dec a
	sla a
	sla a
	ld c,a
	ld b,0
	ld hl,sample_loc_lens+2
	add hl,bc
	ld a,(hl)
	ld c,a
	ld (de),a				;copy len lo
	inc hl
	inc de
	ld a,(hl)
	ld b,a
	ld (de),a				;copy len hi
	inc de
	add iy,bc				;add len to tally
	pop bc
	inc ix
	djnz mosamll
	ld (opt_scripts_loclens),de
	ex de,hl
	ld de,work_buffer
	xor a
	sbc hl,de
	ld (work_buffer+38),hl		;set scripts offset



	ld hl,(opt_clips_address)		;in the optimized clips buffer, change the sample numbers
	ld a,(number_of_required_clips)	;to their optimized values
	ld e,a
swsamlp	ld a,(number_of_required_samples)
	ld b,a
	ld c,1
	ld iy,required_samples_list
fsntr	ld a,(hl)
	cp (iy)
	jr z,gsntr
	inc c
	inc iy
	djnz fsntr
	jp compilation_error2		;didn't find sample number to replace
gsntr	ld (hl),c				;replace the sample selection byte
	ld bc,16
	add hl,bc
	dec e
	jr nz,swsamlp
	

	ld de,(opt_scripts_loclens)		;make optimized script loc/len list 
	ld (end_of_opt_fx_data),de
	ld a,(number_of_required_scripts)	;(only make entries for the scripts required)
	or a
	jp z,skipopscr
	ld ix,required_scripts_list		
	ld iy,0				;new location tally
	ld a,(number_of_required_scripts)
	ld b,a
moscrll	push bc
	push iy
	pop hl
	ld a,l
	ld (de),a				;update loc lo
	inc de
	ld a,h
	ld (de),a				;update loc hi
	inc de
	ld a,(ix)				;script number
	dec a
	sla a
	sla a
	ld c,a
	ld b,0
	ld hl,script_loc_lens+2
	add hl,bc
	ld a,(hl)
	ld c,a
	ld (de),a				;copy len lo
	inc hl
	inc de
	ld a,(hl)
	ld b,a
	ld (de),a				;copy len hi
	inc de
	add iy,bc				;add len to tally
	pop bc
	inc ix
	djnz moscrll
	ld (opt_scripts_address),de
	ex de,hl
	ld de,work_buffer
	xor a
	sbc hl,de
	ld (work_buffer+40),hl		;set scripts offset


	
	ld de,(opt_scripts_address)		;collate the required scripts
	ld ix,required_scripts_list
	ld a,(number_of_required_scripts)
	ld b,a
crscrlp	push bc
	ld a,(ix)
	dec a
	sla a
	sla a
	ld c,a
	ld b,0
	ld iy,script_loc_lens
	add iy,bc
	ld l,(iy)
	ld h,(iy+1)
	ld bc,scripts
	add hl,bc
	ld c,(iy+2)
	ld b,(iy+3)
	ldir
	pop bc
	inc ix
	djnz crscrlp
	ld (end_of_opt_fx_data),de
		


	ld hl,(opt_scripts_address)		;update any CLIP [n] reference in script data
	ld a,(number_of_required_scripts)
	ld b,a
fssloop	ld a,(hl)				;get opcode byte. DONE = end of script,
	or a
	jr z,eoascript
	cp 15				;is it a CLIP Opcode?
	jr nz,naclopc
	inc hl				;move to CLIP's argument (clip number to replace)
	ld a,(number_of_required_clips)
	ld e,a
	ld c,1
	ld ix,required_clips_list
frclipn	ld a,(ix)
	cp (hl)
	jr z,gotnewc
	inc ix
	inc c
	dec e
	jr nz,frclipn
	jp compilation_error3
gotnewc	ld (hl),c				;replace the clip number
	dec hl
naclopc	sla a
	ld e,a
	ld d,0
	ld ix,script_opcode_list
	add ix,de
	ld e,(ix)
	ld d,(ix+1)
	inc de
	ld a,(de)				;get number of bytes in command argument
	ld e,a
	ld d,0
	inc de				;inc to skip opcode itself also
	add hl,de
	jr fssloop
eoascript	inc hl
	djnz fssloop
	
	
	
	
skipopscr	
	ld hl,opt_data_fn		; check desired filename
	call kjt_find_file
	jr nz,save_opt_data
	ld hl,file_exists_txt	; file already exists
	call kjt_print_string	
	call kjt_wait_key_press
	ret

save_opt_data
	
	ld hl,(end_of_opt_fx_data)
	ld de,work_buffer
	xor a
	sbc hl,de
	jp c,save_odf_error
	ex de,hl			; DE = length
	ld ix,work_buffer		; IX = source address
	ld b,0			; bank = 0
	ld c,0			; C lenth MSB = 0
	ld hl,opt_data_fn		
	call kjt_save_file
	jp nz,save_odf_error
	ld hl,opt_data_saved_txt	; optimized data saved...
	call kjt_print_string	


	
	
optimized_samples_save

	ld hl,opt_samples_fn	; check desired filename
	call kjt_find_file
	jr nz,ok2sopsam
	ld hl,file_exists_txt	; file already exists
	call kjt_print_string	
	call kjt_wait_key_press
	ret

ok2sopsam	ld ix,$8000		; create the samples file - save first 2 zero bytes
	ld b,3			; bank = 3
	ld de,2			; len = 2
	ld c,0
	ld hl,opt_samples_fn		
	call kjt_save_file
	jr nz,ofs_error

	ld a,(number_of_required_samples)
	or a
	jr z,optssok
	ld b,a
	ld iy,required_samples_list
sampsvlp	push iy
	push bc
	ld a,(iy)
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	ld de,sample_loc_lens
	add hl,de
	push hl
	pop ix
	ld l,(ix+2)		;length of sample
	ld h,(ix+3)
	ld a,h
	or l
	jr z,nxtossv		;if its length is zero, skip it.
	ld c,0
	add hl,hl
	rl c
	ex de,hl			;C:DE = length of sample in bytes
	ld a,(ix+1)		;location high byte
	rlca
	rlca
	and 3
	add a,3
	ld b,a			;B = source bank
	ld l,(ix)
	ld h,(ix+1)
	add hl,hl
	set 7,h
	push hl
	pop ix			;ix = source of data
	ld hl,opt_samples_fn	;hl = filename
	call kjt_write_bytes_to_file
	jr nz,oss_bad
	
nxtossv	pop bc
	pop iy
	inc iy
	djnz sampsvlp
	
optssok	ld hl,opt_samples_saved_txt	;optimized samples saved...
	call kjt_print_string	
	call kjt_wait_key_press
	ret
	
oss_bad	pop bc
	pop iy

ofs_error	ld hl,save_error_txt
ab_opts	call kjt_print_string
	call kjt_wait_key_press
	ret

compilation_error1

	ld hl,comp_error1_txt
	jr ab_opts

compilation_error2

	ld hl,comp_error2_txt
	jr ab_opts
	
compilation_error3

	ld hl,comp_error3_txt
	jr ab_opts
			
save_odf_error

	ld hl,optdatasave_error_txt
	jr ab_opts
	
no_fx_defined

	ld hl,no_fx_txt
	jr ab_opts

;---------------------------------------------------------------------------------------

check_for_script_reference

	ld a,(number_of_required_scripts)
	or a
	jr nz,cfsref
	inc a				;return with ZF clear if no scripts in use
	ret
	
cfsref	push iy
	push ix
	push bc
	push de
	push hl
	ld ix,required_scripts_list		;returns with zero flag set if there's
	ld a,(number_of_required_scripts)	;a CLIP instruction that references 
	ld b,a				;the clip number in C
cfscrrlp	ld a,(ix)
	dec a
	sla a
	sla a
	ld e,a
	ld d,0
	ld iy,script_loc_lens
	add iy,de
	ld l,(iy)
	ld h,(iy+1)
	ld de,scripts
	add hl,de				;hl = location of this script
	
inscrlp	ld a,(hl)				;get opcode byte
	or a
	jr z,endoftscr
	cp 15				;CLIP instruction?
	jr nz,nxtcmd
	inc hl
	ld a,(hl)				;does the CLIP instruction reference this clip?
	cp c
	jr z,cfsrexit
	dec hl
	ld a,(hl)
	
nxtcmd	sla a
	ld e,a
	ld d,0
	ld ix,script_opcode_list
	add ix,de
	ld e,(ix)
	ld d,(ix+1)
	inc de
	ld a,(de)				;get number of byte in command argument
	ld e,a
	ld d,0
	inc de				;inc to skip opcode itself also
	add hl,de
	jr inscrlp
	
endoftscr	inc ix
	djnz cfscrrlp
	xor a	
	inc a				;ZF not set, no reference to this clip

cfsrexit	pop hl
	pop de
	pop bc
	pop ix
	pop iy
	ret
	

;---------------------------------------------------------------------------------------
; Sample loading dept.
;---------------------------------------------------------------------------------------

load_sample

	ld b,0
	ld c,21
	call kjt_set_cursor_position
	ld hl,loading_txt
	call kjt_print_string
	
	call locate_data_entry
	ld l,(ix+3)
	ld h,(ix+4)		; HL = location of filename
	call kjt_find_file
	jp nz,sfnf_err
		
		
check_sample_format
	
	
	ld ix,0			; check .wav type and size
	ld iy,44			; load first 44 bytes of file
	call kjt_set_load_length

	ld hl,wav_header
	ld b,0
	call kjt_force_load		; load wav file header
	jp nz,sfnf_err
	
	ld hl,(wav_header+40)
	inc hl
	bit 7,h
	jp nz,wavbig
	ld de,(wav_header+42)
	ld a,d
	or e
	jp nz,wavbig
	dec hl
	srl h
	rr l	
	ld (new_samp_length),hl	; length of new sample in words
	xor a
	ld de,$4000		; 32KB max
	sbc hl,de
	jp nc,wavbig

	ld a,(wav_header+8)		; check file format
	cp "W"
	jp nz,badwav
	ld a,(wav_header+9)
	cp "A"
	jp nz,badwav
	ld a,(wav_header+22)	; 1 = mono
	cp 1
	jp nz,badwav

	ld bc,(wav_header+24)	; sample rate
	ld hl,$2400		; convert to period
	ld e,$f4
	ld ix,0
divloop	xor a
	sbc hl,bc
	jr nc,nobo
	dec e
	ld a,e
	cp $ff
	jr z,divdone
nobo	inc ix
	jr divloop
divdone	ld (new_samp_period),ix
	push ix
	pop hl
	xor a
	ld de,$210
	sbc hl,de
	jp c,badwav

	ld a,(wav_header+32)	; 1 = 8 bit
	cp 1
	jp nz,badwav
	
	
rebuild_sample_list

	call locate_data_entry
	ld a,(hl)			;A = DET index (item number)
	ld l,a			
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,sample_info
	add hl,de
	push hl
	pop iy
	ld (iy+18),0		;zero this log entry's sample length so it'll be skipped when
	ld (iy+19),0		;rebuilding the sample list

	ld ix,sample_info
	ld iy,1			;destination address (word loc)
	ld de,$8002		;destination in sample RAM
	ld c,8			;destination bank in sample BUFFER RAM (memselect port value)
	ld b,32			;sample slots to check

samnumlp	xor a
	out (sys_mem_select),a	;make sure we're in bank 0 to read this info
	ld l,(ix+16)
	ld h,(ix+17)		;sample's original source address (word loc)

	push hl
	push iy
	pop hl
	ld (ix+16),l		;set sample's new source address
	ld (ix+17),h
	pop hl

	exx
	ld l,(ix+18)
	ld h,(ix+19)		;number of words to copy
	ld a,h			
	or l
	jr z,nextsamp		;if theres no words in this entry, skip it
nextword	exx

	push hl
	ld a,h
	rlca
	rlca
	and 3
	or $14
	out (sys_mem_select),a	;set source bank for read
	add hl,hl
	set 7,h
	ld a,c
	out (sys_alt_write_page),a	;set dest bank for write 
	ld a,(hl)			 
	ld (de),a			;copy byte 1
	inc hl
	inc de
	ld a,d
	or e
	jr nz,same_wrb1
	inc c
	ld de,$8000
same_wrb1	ld a,(hl)
	ld (de),a			;copy byte 2
	inc de
	ld a,d
	or e
	jr nz,same_wrb2
	inc c
	ld de,$8000
same_wrb2	pop hl

	inc hl			;inc source address
	inc iy			;inc dest address (word count)
	exx		
	dec hl			;dec word count
	ld a,h
	or l
	jr nz,nextword
nextsamp	exx
	
	push bc			;next sample log entry
	ld bc,32
	add ix,bc
	pop bc
	dec b
	jr nz,samnumlp
	xor a
	out (sys_mem_select),a	;DE = address for new sample to load to / C = FLOS bank
	dec c
	ld a,c
	ld (new_samp_bank),a
	ld (new_samp_addr_cpu),de
	ld (new_samp_addr_word),iy


load_in_the_new_wav_data
		
			
	ld ix,0			
	ld iy,(new_samp_length)
	add iy,iy
	call kjt_set_load_length
	
	ld hl,(new_samp_addr_cpu)
	ld a,(new_samp_bank)	;load the new sample data at end of compiled data
	ld b,a
	call kjt_force_load
	jp nz,loadbad


convert_new_sample_data

	ld a,(new_samp_bank)	;convert the samples to signed
	call kjt_forcebank
	ld hl,(new_samp_addr_cpu)
	ld bc,(new_samp_length)
	sla c
	rl b
convsamlp	ld a,(hl)
	sub $80
	ld (hl),a
	inc hl
	ld a,h
	or l
	jr nz,convsb
	call kjt_inc_bank
	ld hl,$8000
convsb	dec bc
	ld a,b
	or c
	jr nz,convsamlp
	xor a
	call kjt_forcebank



	call locate_data_entry	;set length/per of this sample
	ld l,(ix+3)
	ld h,(ix+4)		;HL = address where data for this DET entry goes
	push hl
	pop iy
	ld hl,(new_samp_addr_word)
	ld (iy+16),l
	ld (iy+17),h
	ld bc,(new_samp_length)
	ld (iy+18),c
	ld (iy+19),b
	ld de,(new_samp_period)
	ld (iy+20),e
	ld (iy+21),d
	add hl,bc
	ld (total_samples_size),hl

	ld c,4			;copy the buffered samples to sample RAM
	ld a,c
	out (sys_alt_write_page),a
	ld a,c
	add a,$14
	out (sys_mem_select),a
	push bc
	ld hl,$8002
	ld de,$8002
	ld bc,$7ffe
	ldir
	pop bc
	inc c
	ld b,3
cbbtosr	push bc
	ld a,c
	out (sys_alt_write_page),a
	ld a,c
	add a,$14
	out (sys_mem_select),a
	ld hl,$8000
	ld de,$8000
	ld bc,$8000
	ldir
	pop bc
	inc c
	djnz cbbtosr
	xor a
	out (sys_mem_select),a


update_waves
	
	call locate_data_entry	;update any waves that use this sample number to default start/end/period
	ld a,(hl)			;A = sample number (ie: entry index)
	inc a
	ld l,(ix+3)
	ld h,(ix+4)
	push hl
	pop ix
	ld b,32
	ld iy,wave_list
updeflp	cp (iy)
	call z,default_stloclen
	ld de,16
	add iy,de
	djnz updeflp
	
	ld ix,sample_info		;update the location / length list (as used by the FX player)
	ld iy,sample_loc_lens
	ld b,32
ulolelst	ld e,(ix+16)		;start
	ld d,(ix+17)
	ld (iy),e		
	ld (iy+1),d
	ld e,(ix+18)		;len
	ld d,(ix+19)
	ld (iy+2),e
	ld (iy+3),d	
	ld de,32
	add ix,de
	ld de,4
	add iy,de
	djnz ulolelst
	ret

sfnf_err	ld hl,fnf_txt		
sload_err	call kjt_print_string	
	call restore_original_data	; put the original filename back if sample file not found
	call refresh_page		 
	call kjt_wait_key_press
	ret

wavbig	ld hl,samp_too_big_txt
	jr sload_err

badwav	ld hl,samp_bad_format_txt
	jr sload_err

loadbad	call locate_data_entry	; if sample data did not load correctly, remove this sample
	ld b,(ix+0)
	ld c,(ix+1)
	call kjt_set_cursor_position
	ld hl,undefined_txt
	call kjt_print_string
	call update_var_entry	
	xor a
	ld (del_flag),a		; hide that we've updated flagged variable
	call locate_data_entry
	ld l,(ix+3)
	ld h,(ix+4)
	push hl
	pop iy
	ld (iy+18),0		; set sample length to zero (no bytes defined)
	ld (iy+19),0
	ld hl,badload_txt
	jr sload_err

;-----------------------------------------------------------------------------------------

default_stloclen

; ix = sample base (source)
; iy = wave base (dest)
	
	ld (iy+1),0		;default start
	ld (iy+2),0		;""
	ld (iy+5),0		;default loop start
	ld (iy+6),0		;""
	ld e,(ix+18)		
	ld (iy+3),e		;default end lo
	ld (iy+7),e		;default loop end lo
	ld e,(ix+19)		
	ld (iy+4),e		;default end hi
	ld (iy+8),e		;default loop end hi
	ld e,(ix+20)		
	ld (iy+9),e		;default period lo
	ld e,(ix+21)		
	ld (iy+10),e		;default period hi
	ld (iy+11),"Y"		;loop on by default
	ret

		
;----- 8x8 multiply---------------------------------------------------------------------

multiply_HE

	ld l,0			; Multiply H by E, result in HL
	ld d,l
	sla h		
	jr nc,muliter1
	ld l,e
muliter1	add hl,hl		
	jr nc,muliter2	
	add hl,de		
muliter2	add hl,hl		
	jr nc,muliter3	
	add hl,de		
muliter3	add hl,hl		
	jr nc,muliter4	
	add hl,de		
muliter4	add hl,hl		
	jr nc,muliter5	
	add hl,de		
muliter5	add hl,hl		
	jr nc,muliter6	
	add hl,de		
muliter6	add hl,hl		
	jr nc,muliter7	
	add hl,de		
muliter7	add hl,hl		
	jr nc,muliter8	
	add hl,de		
muliter8	ret


;---------------------------------------------------------------------------------------
; Unpacks my RLE packed data to sprite RAM - Phil_V5Z80P @ Retroleum.co.uk 2008
; Keeps destination within $1000-$1fff and updates vreg_vidpage as required
;----------------------------------------------------------------------------------------

unpack_sprites

;set  A = initial sprite bank (0-31)
;set HL = source address of packed file
;set DE = destination address for unpacked data (within sprite page $1000-$1fff)
;set BC = length of packed file

	dec bc			; less 1 to skip match token
	push hl
	pop ix
	exx
	ld b,a
	exx
	or $80
	ld (vreg_vidpage),a		; select initial sprite bank

	in a,(sys_mem_select)
	and $1f
	or $80
	out (sys_mem_select),a	; page in sprite memory
	
	inc hl
unp_gtok	ld a,(ix)			; get token byte
unp_next	bit 5,d			; test for next sprite page
	jp z,nchsb1
	exx
	inc b
	ld a,b
	or $80
	ld (vreg_vidpage),a
	exx
	ld d,$10
	ld a,(ix)
nchsb1	cp (hl)			; is byte at source location same as token?
	jr z,unp_brun		; if it is, there's a byte run to expand
	ldi			; if not, simply copy this byte to destination
	jp pe,unp_next		; last byte of source?
	jr packend
	
unp_brun	push bc			; stash B register
	inc hl		
	ld a,(hl)			; get byte value
	inc hl		
	ld b,(hl)			; get run length
	inc hl
	
unp_rllp	ld (de),a			; write byte value, byte run length
	inc de		
	bit 5,d			; test for next sprite page
	jp z,nchsb2
	ld c,a
	exx
	inc b
	ld a,b
	or $80
	ld (vreg_vidpage),a
	exx
	ld d,$10
	ld a,c
nchsb2	djnz unp_rllp
	
	pop bc	
	dec bc			; last byte of source?
	dec bc
	dec bc
	ld a,b
	or c
	jp nz,unp_gtok

packend	in a,(sys_mem_select)	;page out sprite memory
	and $7f
	out (sys_mem_select),a	
	ret

;-------------------------------------------------------------------------------------------------
; Update sprite register
;-------------------------------------------------------------------------------------------------

x_win_offset equ $7f		;offset from display window edge
	
update_sprite_register

; set ix to sprite register base
; hl = x coord
; de = y coord
; a  = definition (only using 0-255 here)
; height hardwired to 64 pixels here

	ld bc,x_win_offset
	add hl,bc
	ld bc,(y_win_offset)
	ex de,hl
	add hl,bc
	ex de,hl
	ld (ix+3),a		;def
	ld (ix+0),l		;x lsb
	ld (ix+2),e		;y lsb
	sla d			
	ld a,h
	or d
	or $40
	ld (ix+1),a		;msbs etc
	ret

y_win_offset

	dw $29

;---------------------------------------------------------------------------------------

	include "fx_player.asm"
	
;---------------------------------------------------------------------------------------

my_linecoplist	

	dw $c008		;wait for line $08
	dw $8201		;set register $201 (vreg_victrl)
	dw $0000		;write 0 to register (bitmap bitplane mode)
	dw $c0b0		;wait for line $b0
	dw $00a0		;write $80 to register (switch to chunky pixel mode)
	dw $8243		;select register $243 (reset video counter)
	dw $0000		;write $00, reset counter
	dw $c1ff		;wait for line $1ff (end of list)


	dw $c008		;wait for line $08
	dw $8201		;set register $201 (vreg_victrl)
	dw $0000		;write 0 to register (bitmap bitplane mode)
	dw $c1ff		;wait for line $1ff (end of list)

		
end_my_linecoplist	db 0

;---------------------------------------------------------------------------------------


ylookup_table	ds 64*2,0


;---------------------------------------------------------------------------------------
; Locations of data entry tables
;---------------------------------------------------------------------------------------

det_locs	dw fx_ed_del		;mode 0
	dw wave_ed_del		;mode 1
	dw script_ed_del		;mode 2
	dw sample_load_del		;mode 3
	dw loadsave_del		;mode 4
	
;---------------------------------------------------------------------------------------
; Data entry location list for fx editor	
;-----------------------------------------------------------------------------------------

; x,y
; 5:0 = numbers of chars, bit 6=button only (no data entry), bit 7 = ascii string
; location for data in memory
; flag (allows main program to sense particular var changes)
; not used

fx_ed_del

		db 4,2
		db 2
		dw current_fx
		db 0
		dw 0
	
		db 19,2
		db 2
del_priority	dw 0
		db 0
		dw 0

		db 30,2
		db 2
del_active	dw 0
		db 0
		dw 0

	
		db 9,7
		db 2
del_ch0wav	dw 0
		db 0
		dw 0
	
		db 23,7
		db 2
del_ch0vol	dw 0
		db 0
		dw 0

		db 9,8
		db 2
del_ch0script	dw 0
		db 0
		dw 0

	
		db 9,12
		db 2
del_ch1wav	dw 0
		db 0
		dw 0
	
		db 23,12
		db 2
del_ch1vol	dw 0
		db 0
		dw 0

		db 9,13
		db 2
del_ch1script	dw 0
		db 0
		dw 0

	
		db 9,17
		db 2
del_ch2wav	dw 0
		db 0
		dw 0
	
		db 23,17
		db 2
del_ch2vol	dw 0
		db 0
		dw 0

		db 9,18
		db 2
del_ch2script	dw 0
		db 0
		dw 0

	
		db 9,22
		db 2
del_ch3wav	dw 0
		db 0
		dw 0
	
		db 23,22
		db 2
del_ch3vol	dw 0
		db 0
		dw 0

		db 9,23
		db 2
del_ch3script	dw 0
		db 0
		dw 0
	
		db $ff
	
;---------------------------------------------------------------------------------------
; Data entry location list for wave editor
;----------------------------------------------------------------------------------------

wave_ed_del	db 6,2
		db 2
		dw current_wave
		db 2			;flag 2 : changed wave selection
		dw 0
		
		db 22,2
		db $81
		dw preview_mode
		db 8			;flag 8 : changed preview setting
		dw 0
	
		db 9,5
		db 2
del_samplesel	dw 0
		db 1			;flag 1 : changed sample selection
		dw 0
	
		db 15,7
		db 4
del_start		dw 0
		db 7			;flag 7 : updated loc/len/per/lp/lloc/llen
		dw 0
	
		db 15,8
		db 4
del_end		dw 0
		db 7
		dw 0
	
		db 9,10
		db 4
del_period	dw 0
		db 7
		dw 0
	
		db 9,12
		db $81
del_loop		dw 0
		db 7
		dw 0
	
		db 21,14
		db 4
del_loop_start	dw 0
		db 7
		dw 0
	
		db 21,15
		db 4
del_loop_end	dw 0
		db 7
		dw 0
	
		db $ff

;---------------------------------------------------------------------------------------
; Data entry location list for script editor
;----------------------------------------------------------------------------------------

script_ed_del	db 9,2
		db 2
		dw current_script
		db 9			; Flag 9 = current script changed		
		dw 0
		
		db 14,2
		db $c4
		dw 0
		db 10			; Flag 10 = activate edit mode		
		dw 0
		
		db $ff
				
;---------------------------------------------------------------------------------------
; Data entry location list for sample loader
;----------------------------------------------------------------------------------------

sample_load_del	db 5,4
		db $8c
		dw sample_info+$000
		db 3			;flag 3 = load sample
		dw 0

		db 5,5
		db $8c
		dw sample_info+$020
		db 3
		dw 0
		
		db 5,6
		db $8c
		dw sample_info+$040
		db 3
		dw 0

		db 5,7
		db $8c
		dw sample_info+$060
		db 3
		dw 0

		db 5,8
		db $8c
		dw sample_info+$080
		db 3
		dw 0

		db 5,9
		db $8c
		dw sample_info+$0a0
		db 3
		dw 0
		
		db 5,10
		db $8c
		dw sample_info+$0c0
		db 3
		dw 0

		db 5,11
		db $8c
		dw sample_info+$0e0
		db 3
		dw 0

		db 5,12
		db $8c
		dw sample_info+$100
		db 3
		dw 0
		
		db 5,13
		db $8c
		dw sample_info+$120
		db 3
		dw 0
		
		db 5,14
		db $8c
		dw sample_info+$140
		db 3
		dw 0

		db 5,15
		db $8c
		dw sample_info+$160
		db 3
		dw 0

		db 5,16
		db $8c
		dw sample_info+$180
		db 3
		dw 0

		db 5,17
		db $8c
		dw sample_info+$1a0
		db 3
		dw 0
		
		db 5,18
		db $8c
		dw sample_info+$1c0
		db 3
		dw 0

		db 5,19
		db $8c
		dw sample_info+$1e0
		db 3
		dw 0

		db 27,4
		db $8c
		dw sample_info+$200
		db 3
		dw 0
		
		db 27,5
		db $8c
		dw sample_info+$220
		db 3
		dw 0
		
		db 27,6
		db $8c
		dw sample_info+$240
		db 3
		dw 0

		db 27,7
		db $8c
		dw sample_info+$260
		db 3
		dw 0

		db 27,8
		db $8c
		dw sample_info+$280
		db 3
		dw 0

		db 27,9
		db $8c
		dw sample_info+$2a0
		db 3
		dw 0
		
		db 27,10
		db $8c
		dw sample_info+$2c0
		db 3
		dw 0

		db 27,11
		db $8c
		dw sample_info+$2e0
		db 3
		dw 0

		db 27,12
		db $8c
		dw sample_info+$300
		db 3
		dw 0
		
		db 27,13
		db $8c
		dw sample_info+$320
		db 3
		dw 0
		
		db 27,14
		db $8c
		dw sample_info+$340
		db 3
		dw 0

		db 27,15
		db $8c
		dw sample_info+$360
		db 3
		dw 0

		db 27,16
		db $8c
		dw sample_info+$380
		db 3
		dw 0

		db 27,17
		db $8c
		dw sample_info+$3a0
		db 3
		dw 0
		
		db 27,18
		db $8c
		dw sample_info+$3c0
		db 3
		dw 0

		db 27,19
		db $8c
		dw sample_info+$3e0
		db 3
		dw 0

		db $ff

;---------------------------------------------------------------------------------------
; Data entry location list for Data load/save
;----------------------------------------------------------------------------------------
			
			
loadsave_del	db 12,5
		db $8c
		dw proj_filename
		db 0
		dw 0

		db 2,7
		db $c4
		dw 0
		db 4			;flag 4 = load project
		dw 0
		
		db 11,7
		db $c4
		dw 0
		db 5			;flag 5 = save project
		dw 0

		db 24,14
		db $8c
		dw opt_data_fn
		db 0
		dw 0
		
		db 24,16
		db $8c
		dw opt_samples_fn
		db 0
		dw 0
		
		db 2,18
		db $c4
		dw 0
		db 6			;flag 6 = save optimized files
		dw 0

		db $ff		
		
	
;-------------------------------------------------------------------------------------

current_scancode	db 0
current_asciicode	db 0
mode		db 0	;0 = fx edit, 1 = wave edit
current_fx	db 1
current_wave	db 1
del_indices	ds 8,0	;one index per mode
input_string_offset db 0
del_flag		db 0
preview_mode	db "N"
pen_colour  	db $38

original_data	ds 32,0
quit_txt		db 11,"Quit the SFX editor..",0

;------------------------------------------------------------------------------------

sample_base 		dw 0	
total_sample_length		dw 0
current_full_sample_length 	dw 0

wave_points		ds window_width_pixels,0

packed_sprites 		incbin "sprites_packed.bin"
end_packed_sprites		db 0

current_start       	dw 0
current_end        	 	dw 0
current_loop_start 	 	dw 0
current_loop_end    	dw 0
start_marker_x		dw 0
end_marker_x  		dw 0
loop_start_marker_x		dw 0
loop_end_marker_x		dw 0
current_loop		db 0
ascii_entry_mode		db 0

;------------------------------------------------------------------------------

sfxed_txt	db "SOUND FX EDITOR 0.20 - TOP LEVEL        ",0
		
byte_txt	db "xx",0

fx_txt	db 11,"FX: ",0
pri_txt	db " - Priority: ",0
act_txt	db " Active: ",0
l1_txt	db 11,"--------------------------------",0
	
ch_txt	db 11,11,"Channel: ",0
l2_txt	db 11,"-----------",0
wave_txt	db 11," Clip  : ",0
vol_txt	db " at Volume: ",0
scr_txt	db 11," Script: ",0
		
wnu_txt	db "--              ",11,"             ",0
snu_txt	db "--",0

;--------------------------------------------------------------------------------

waved_txt	db "SOUND FX EDITOR 0.20 - WAVE SELECTOR    ",0
		
wav_txt	db 11,"Clip: ",0
prev_txt	db "   Preview? : ",0
l3_txt	db 11,"--------",0

samp_txt	db 11,11," Sample: ",0
sfn_txt	db " - ",0

nsamp_txt db "--                                    ",11,0
blank_txt db "                                      ",11,0

sst_txt   db 11,11," Start offset: ",0
slen_txt  db 11,   " End Point   : ",0

per_txt	db 11,11," Period: ",0

loop_txt  db 11,11," Loop? : ",0
y_txt	db "Y",0
n_txt	db "N",0
lst_txt   db 11,11,"  Loop Start Offset: ",0
llen_txt	db 11,   "  Loop End Point   : ",0

undefined_txt	db "UNDEFINED    ",0

;--------------------------------------------------------------------------------

sample_load_txt

	db "SOUND FX EDITOR 0.20 - SAMPLE LOADER    ",0

sample_bank_txt

	db 11,"           ** SAMPLE BANK **",11,11	

	db "01 :                  11 :             ",11
	db "02 :                  12 :             ",11
	db "03 :                  13 :             ",11
	db "04 :                  14 :             ",11
	db "05 :                  15 :             ",11
	db "06 :                  16 :             ",11
	db "07 :                  17 :             ",11
	db "08 :                  18 :             ",11
	db "09 :                  19 :             ",11
	db "0A :                  1A :             ",11
	db "0B :                  1B :             ",11
	db "0C :                  1C :             ",11
	db "0D :                  1D :             ",11
	db "0E :                  1E :             ",11
	db "0F :                  1F :             ",11
	db "10 :                  20 :             ",0

loading_txt	db "LOADING... ",0
fnf_txt		db "File Not Found!",0
samp_too_big_txt	db "Error! Sample is > 32KB",0
samp_bad_format_txt	db "Error! Incorrect format",0
sampmemfull_txt	db "Sample memory full!",0
badload_txt	db "Uknown loading error!",0

new_samp_length	dw 0
new_samp_period	dw 0
new_samp_addr_word	dw 0
new_samp_addr_cpu	dw 0
new_samp_bank	db 0

wav_header	ds 64,0
	
;--------------------------------------------------------------------------------

project_loadsave_txt

	db "SOUND FX EDITOR 0.20 - DATA LOAD/SAVE   ",0

loadsavepage_txt

	db 11,"Full FX Editor Project:"
	db 11,"-----------------------",11
	db 11," FILENAME :             ",11
	db 11," [LOAD] / [SAVE]",11,11,11
	
	db 11,"Optimized Files for FX Player:"
	db 11,"------------------------------",11
	db 11," FX DATA FILENAME     :             ",11
	db 11," SAMPLE DATA FILENAME :             ",11
	db 11," [SAVE]",0

proj_filename	db "PROJECT1.FXP",0
opt_data_fn	db "FXDATA.BIN  ",0
opt_samples_fn	db "SAMPLES.BIN ",0

file_exists_txt	db "File Exists - Choose a new filename!",0
saving_txt	db "Saving.. ",0
save_error_txt	db "Error!",0
file_saved_txt	db "SAVED OK!",0
file_loaded_txt	db "Loaded OK!",0
load_error_txt	db "Error!",0
hload_error_txt	db "Error loading header!",0
sload_error_txt	db "Error loading samples!",0
ssave_error_txt	db "Error saving samples!",0
hsave_error_txt	db "Error saving header!",0
ver_error_txt	db "Verify error!",0
 
;--------------------------------------------------------------------------------

script_ed_txt

	db "SOUND FX EDITOR 0.20 - SCRIPT EDITOR    ",0
	
script_no_txt

		db 11,"Script : ",0
underline_txt	db "  [EDIT]",11,"-----------",11,11,0
	

scr_cmd_list_txt	db " SCRIPT COMMANDS ",0

script_commands

;command number, bytes in argument, ASCII name, 0

scrop0	db 0,0,"DONE",0
scrop1	db 1,1,"SETVOL",0
scrop2	db 2,1,"ADDVOL",0
scrop3	db 3,1,"SUBVOL",0
scrop4	db 4,2,"SETPER",0
scrop5	db 5,2,"ADDPER",0
scrop6	db 6,2,"SUBPER",0
scrop7	db 7,2,"MAXPER",0
scrop8	db 8,2,"MINPER",0
scrop9	db 9,2,"RNDPER",0
scrop10	db 10,1,"WAIT",0
scrop11	db 11,1,"LOOP",0
scrop12	db 12,0,"GOLOOP",0
scrop13	db 13,0,"REPEAT",0
scrop14	db 14,2,"SETRND",0
scrop15	db 15,1,"CLIP",0
scrop16	db 16,1,"PERCYC",0
	db 0,0,$ff

script_opcode_list	dw scrop0,scrop1,scrop2,scrop3,scrop4,scrop5,scrop6,scrop7
		dw scrop8,scrop9,scrop10,scrop11,scrop12,scrop13,scrop14,scrop15
		dw scrop16
		
unk_scrent	db "??????",0
scr_blank		db "                ",0
	
cr_txt		db 11,0

script_error_txt	db "-------------------------------------",11,0
unknown_cmd_txt	db "Script Error:                        ",11,"Unknown command: ",0
script_too_big_txt  db "Script Error:                        ",11,"No DONE command!",0
bad_hex_txt	db "Script Error:                        ",11,"Bad argument on line: ",0
malformed_txt	db "Script Error:                        ",11,"Malformed Line:" ,0
fix_abandon_txt	db "                                     ",11
		db "Press:                               ",11
		db "                                     "
		db 11,"[A] to Abandon the edited script",11
		db "    or any other key to fix it.",11
		db "-------------------------------------",0

sure_txt		db 11,11,"Sure? (Y/N)",11,11,0
		
scr_edit_mode	db 0

scr_cursor_pos	dw 0

current_script	db 1

scr_start_offset	db 0			;Scroll position in script
scr_edit_pos	dw 0			;Line 0 to 19
scr_allow_scroll	db 0

script_lines	dw 0
comp_line		dw 0

scr_base		dw 0
scr_table		dw 0

new_script_length		dw 0
total_scripts_length	dw 32

script_rebuild_buffer_loc	dw 0

;--------------------------------------------------------------------------------

required_fx_list		ds 32,0
number_of_required_fx	db 0

required_samples_list	ds 32,0
number_of_required_samples	db 0

required_clips_list		ds 32,0
number_of_required_clips	db 0

required_scripts_list	ds 32,0
number_of_required_scripts	db 0

opt_fx_address		dw 0
opt_clips_address		dw 0
opt_scripts_address 	dw 0
opt_samples_loclens		dw 0
opt_scripts_loclens		dw 0

end_of_opt_fx_data		dw 0

comp_error1_txt		db "Error: Re-numbering clips",0
comp_error2_txt		db "Error: Re-numbering samples",0
comp_error3_txt		db "Error: Re-numbering script CLIP cmds",0
optdatasave_error_txt	db "Error saving optimized data!",0
opt_data_saved_txt		db "Optimized data saved OK..",11,0
opt_samples_saved_txt	db "Relevant samples saved OK...",0
no_fx_txt			db "No FX to save!",0
optimizing_txt		db "Optimizing...",11,0

;--------------------------------------------------------------------------------

exit_txt	db 11,11,0

;-------------------------------------------------------------------------------------
; The contents of this 42 byte FX data header allows the sound fx data to be optimized
;-------------------------------------------------------------------------------------

fx_data	db $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f ; (00)
	db $10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f
	
	dw 46	;offset to FX           (@ 32)
	dw 558	;offset to waves        (@ 34)
	dw 1070	;offset to locs         (@ 36)
	dw 2222	;offset to script table (@ 38)
	dw 2350 	;offset to script base  (@ 40)
	

;*********************************************************************************
;* Data unique to a project starts here                                          *
;*********************************************************************************

proj_header_size	dw 2382	;in bytes (2350 + 32 "DONE only" 1-byte scripts)
total_samples_size	dw 1	;in words (always at least one word for non-loops)

;--------------------------------------------------------------------------------

fx_list	

;0 - priority
;1 - time priority is effective
;2 - chan0 - wave
;3 - chan0 - volume
;4 - chan0 - script
;-----------------------------
;(repeat for other 3 channels)
;-----------------------------
;15 - not used (padding)
;16 - not used (padding)

	
	ds 32*16,0	; max 32 individual fx types, 16 bytes each
		
;--------------------------------------------------------------------------------

wave_list

REPT 32
	db 1		; which sample to use (samples begin at $01)
	dw $0000,$0000	; this clip's start offset / end
	dw $0000,$0000	; this clip's loop start offset / end
	dw $0000		; this clip's period
	db "N"		; loop on or off (ascii "Y" or "N")
	ds 4,0		; not currently used - padded to 16 bytes per entry
ENDM

;---------------------------------------------------------------------------------

sample_loc_lens

	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0	 ; absolute locations in sample RAM / length
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
	dw 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
	
	
;---------------------------------------------------------------------------------	
; This section is used by the editor GUI, the player itself does not require it 
;---------------------------------------------------------------------------------	

sample_info

	ds 32*32,0			; max 32 samples

; 0 - filename			
;16 - start loc (words into sample RAM)	
;18 - length in words (if 0, no samples)	
;20 - period			0
;22 - padding to 32 bytes per entry
	
;--------------------------------------------------------------------------------

script_loc_lens

	dw scr1-scripts,1
	dw scr2-scripts,1
	dw scr3-scripts,1
	dw scr4-scripts,1	
	dw scr5-scripts,1
	dw scr6-scripts,1
	dw scr7-scripts,1	
	dw scr8-scripts,1
	dw scr9-scripts,1
	dw scr10-scripts,1
	dw scr11-scripts,1
	dw scr12-scripts,1
	dw scr13-scripts,1
	dw scr14-scripts,1
	dw scr15-scripts,1
	dw scr16-scripts,1
	dw scr17-scripts,1
	dw scr18-scripts,1
	dw scr19-scripts,1
	dw scr20-scripts,1
	dw scr21-scripts,1
	dw scr22-scripts,1
	dw scr23-scripts,1
	dw scr24-scripts,1
	dw scr25-scripts,1
	dw scr26-scripts,1
	dw scr27-scripts,1
	dw scr28-scripts,1
	dw scr29-scripts,1
	dw scr30-scripts,1
	dw scr31-scripts,1
	dw scr32-scripts,1
		
;---------------------------------------------------------------------------------

scripts
	
scr1	db 0
scr2	db 0
scr3	db 0
scr4	db 0
scr5	db 0
scr6	db 0
scr7	db 0
scr8	db 0
scr9	db 0
scr10	db 0
scr11	db 0
scr12	db 0
scr13	db 0
scr14	db 0
scr15	db 0
scr16	db 0
scr17	db 0
scr18	db 0
scr19	db 0
scr20	db 0
scr21	db 0
scr22	db 0
scr23	db 0
scr24	db 0
scr25	db 0
scr26	db 0
scr27	db 0
scr28	db 0
scr29	db 0
scr30	db 0
scr31	db 0
scr32	db 0

;--------------------------------------------------------------------------------
; END - Dont put any code or data after here. Uused internally for buffers.
;--------------------------------------------------------------------------------

