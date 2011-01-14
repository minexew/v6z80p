;------------------------------------------------------------------------------------------------------
; Spectrum 128 / 48 Emulator UserCode.exe
; Note: This uses its own filesystem routines, not those in FPGA boot ROM
;------------------------------------------------------------------------------------------------------
;
; Changes: v010 - added VGA50 option (Shift+v in menu)
;
;-------------------------------------------------------------------------------------------------------

sys_pic_comms		equ 248			; in menu mode (IE: Spectrum code not running)
mem_bank_port		equ 249			; in menu mode (IE: Spectrum code not running)

kjt_restart_128_snapshot	equ $28			; in FPGA ROM
kjt_restart_48_snapshot	equ $2b			; in FPGA ROM

stack	    		equ $3fe0

sna_address   		equ $3fe5			; IE: $4000 less 27 bytes (.sna header)

rom_tag			equ $ffe0			; $DICEFACE here if system previously booted
roms_present		equ $ffe4			; Bit 0 = Spec 128 ROM, bit 1 = Spec 48 ROM
old_dir			equ $ffe8			; These settings survive .sna load / reset
old_menu			equ $ffea
old_vga			equ $ffeb	

restart_jp		equ $fff0			; FPGA switches to real Spectrum after 2nd M1 here

;-----------------------------------------------------------------------------------------------

	org $800

;-----------------------------------------------------------------------------------------------

	di
	ld sp,stack
	xor a
	out (mem_bank_port),a	; Select actual Spectrum RAM at $4000-$FFFF
	ld bc,$7ffd
	out (c),a			; select page 0 at $c000 / ROM 0 / No protect

;-----------------------------------------------------------------------------------------------

	ld a,1	
	out (mem_bank_port),a
	
	ld hl,(rom_tag)		; find out if the system was started previously
	ld de,$D1CE		; (look for $DICEFACE ID)
	xor a
	sbc hl,de
	jr nz,no_prior
	ld hl,(rom_tag+2)
	ld de,$FACE
	xor a
	sbc hl,de
	jr nz,no_prior

	call fat16_check_format	; Redo FAT16 parameters
	ld hl,(old_dir)		; Emulator has been previously booted so
	ld (fs_directory_cluster),hl	; restore directory cluster and menu selection line
	ld a,(old_menu)
	ld (menu_sel),a		
	ld a,(roms_present)
	ld (roms_available),a
	ld a,(old_vga)
	ld (vga_mode),a
	xor a
	out (mem_bank_port),a
	out (254),a
	jp list_files

;-----------------------------------------------------------------------------------------------

no_prior	xor a
	ld (roms_available),a	
	out (mem_bank_port),a

	ld bc,0
	ld (cursor_pos),bc
	ld hl,greetings_txt		; Greeting text
	call print_string
	ld hl,$5800		; Greeting attribs
	ld bc,32
	ld a,$8e
	call fill_mem
	
	call reset_keyboard		; Warning! "Reset keyboard" affects port 254
	call sdc_init
	call fat16_check_format

	ld hl,specdir_fn		; change to "spectrum" subdir from ROOT
	call fat16_change_dir
	jp nz,load_error


;--------LOAD SPECTRUM 128 and 48 ROMS  ------------------------------------------------------
	
	ld hl,rom128_fn		; load Spectrum128 32KB ROM to $4000-$BFFF in buffer mem 01
	ld de,$4000
	call fat16_open_file
	jr nz,no128rom
	xor a
	out (mem_bank_port),a
	ld hl,loading_128rom_txt	; Note: print_string requires spectrum RAM selected
	call print_string		; to access screen
	ld a,1			; enable non-spectrum buffer mem 01: (Z80:$4000-$FFFF)
	out (mem_bank_port),a
	call fat16_read_data
	jp nz,load_error
gotrom128	ld hl,roms_available
	set 0,(hl)
	
no128rom	ld hl,rom48_fn		; load Spectrum 48 16KB ROM to $4000-$BFFF in buffer mem 10
	ld de,$4000
	call fat16_open_file
	jr nz,no48rom
	xor a
	out (mem_bank_port),a
	ld hl,loading_48rom_txt	; Note: print_string requires spectrum RAM selected
	call print_string		; to access screen
	ld a,2
	out (mem_bank_port),a	; enable non-spectrum buffer mem 02: (Z80:$4000-$FFFF)
	call fat16_read_data
	jp nz,load_error
gotrom48	ld hl,roms_available
	set 1,(hl)
	
no48rom	ld hl,no_roms_txt		; Show error / quit if no ROMs were loaded.
	ld a,(roms_available)
	or a
	jp z,show_error

	ld a,1			
	out (mem_bank_port),a
	ld hl,$D1CE		; Put prior boot ID in memory
	ld (rom_tag),hl
	ld hl,$FACE
	ld (rom_tag+2),hl
	xor a
	ld (menu_sel),a
	call cache_settings
	xor a
	out (mem_bank_port),a
	

;---SHOW A LIST OF FILES -------------------------------------------------------------------------


list_files

	call clear_screen
	ld bc,0
	ld (cursor_pos),bc

	ld hl,files_txt
	call print_string

	call fat16_goto_first_dir_entry	
	
	ld hl,menu
	ld (menu_loc),hl
	ld b,44			; List first 44 files in dir
	ld c,0

nxtentry	push bc
	
	call fat16_get_dir_entry	; returns filename in hl
	jp nz,eodir		; if zf = not set, no more entries

	ld ix,(menu_loc)
	ld (ix+15),b		; mark menu entry as file (0) / directory (1)
	bit 0,b
	jr nz,oktolist		; show all dirs
		
	push hl			; is this a .sna file?
	pop ix
	ld b,9
chksna	ld a,"."			; find the "." in filename
	cp (ix)
	jr nz,nxtchar
	ld a,(ix+1)
	call uppercasify
	cp "S"
	jr nz,notsna
	ld a,(ix+2)
	call uppercasify
	cp "N"
	jr nz,notsna
	ld a,(ix+3)
	cp "A"
	jr z,oktolist
nxtchar	inc ix
	djnz chksna
notsna	jr anymore
	
oktolist	pop bc
	inc c			; inc entry count
	push bc		
	ld de,(menu_loc)
	push hl			; copy filename to menu
	ld b,12
cpyfn	ld a,(hl)
	or a
	jr z,restzeros
	ld (de),a
	inc hl
	inc de
	djnz cpyfn
	jr eofn
restzeros	ld (de),a
	inc de
	djnz restzeros
eofn	pop hl
	
	pop bc			
	push bc
	ld b,0			; cursor x = 0
	ld a,c
	add a,1			; cursor y = entry count + 1  
	ld c,a	
	cp 24
	jr c,leftside		; if y > 23, print on right side
	sub 22
	ld c,a
	ld b,16			;cursor x = 16

leftside	push bc	
	ld (cursor_pos),bc
	call print_string		; show filename
	pop bc
	ld a,b
	add a,8			; cursor y as above, cursor x = 13
	ld b,a
	ld (cursor_pos),bc
	ld ix,(menu_loc)		
	ld a,(ix+15)
	or a
	jr z,notdir
	ld hl,dir_txt		; if its a dir show "(d)"
	call print_string

notdir	ld hl,(menu_loc)
	ld de,16
	add hl,de
	ld (menu_loc),hl

anymore	call fat16_goto_next_dir_entry	; any more to list?
	jr nz,eodir
	pop bc
	dec b
	jp nz,nxtentry
	jr go_sel
		
eodir	pop bc

go_sel	ld a,c
	ld (max_entry),a
	

;-- MAIN FILE MENU SELECTION LOOP ----------------------------------------------------------

	ei
	
sel_loop	halt
	
	call delete_selbar		;move highlight up? (A)
	call test_up_key
	jr nz,not_up
	ld a,(menu_sel)
	sub 1
	jr nc,up_ok
	xor a
up_ok	ld (menu_sel),a
		
not_up	call test_down_key		;move highlight down? (Q)
	jr nz,not_down
	ld a,(max_entry)
	ld b,a
	ld a,(menu_sel)
	inc a
	cp b
	jr nz,down_ok
	dec b
	ld a,b
down_ok	ld (menu_sel),a

not_down	call test_right_key		;move highlight right (P)?
	jr nz,not_right
	ld a,(menu_sel)
	cp 22
	jr nc,not_right
	ld a,(max_entry)
	dec a
	ld b,a
	ld a,(menu_sel)
	add a,22
	cp b
	jr c,nmax_r
	ld a,b
nmax_r	ld (menu_sel),a

not_right	call test_left_key		;move highlight left (O)?
	jr nz,not_left
	ld a,(menu_sel)
	cp 22
	jr c,not_left		
	sub 22
	jr nc,nmin_l
	xor a
nmin_l	ld (menu_sel),a

not_left	call test_select_key	;pressed Enter?
	jr z,select_sna

	call test_b_key		;pressed B?
	jr z,go_basic
	
	call test_config1_key
	ld b,1
	jr z,go_cfg
	call test_config2_key
	ld b,2
	jr z,go_cfg
	call test_config3_key
	ld b,3
	jr z,go_cfg
	
	call test_vga50_key
	call z,swap_vga_mode
	
not_sel	call draw_selbar
	jp sel_loop
	

;--------------------------------------------------------------------------------------

go_basic	ld hl,sna_address		; boot Spectrum 128 BASIC
dumsnah	ld (hl),0			; clear .sna header
	inc hl
	ld a,h
	cp $40
	jr nz,dumsnah
	
	ld a,1			
	out (mem_bank_port),a	; Select buffer RAM 01 @ $4000-$FFFF (contains spec 128 ROM) 
	ld hl,$c300
	ld (restart_jp),hl		; set up "NOP, JP xxxx" at $fff0, this is the switchover point
	ld hl,0
	ld (restart_jp+2),hl
	ld a,0			; port $7ffd value for ROM's restart code
	ld (restart_jp+4),a
	jp kjt_restart_128_snapshot	; restart .sna - note: A Jump not a Call
	
;---------------------------------------------------------------------------------------------

go_cfg	ld a,1			; delete ROM tag from memory
	out (mem_bank_port),a
	ld hl,0
	ld (rom_tag),hl

	ld a,b
	sla a
	ld (cfg_msb),a
	ld hl,reconfig_sequence	; tell PIC to set reconfig base (not permanently) and
	ld b,7			; restart FPGA
cfg_dlp	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz cfg_dlp
	jp sel_loop		; the FPGA should have now restarted

		
;----LOAD AND START THE SELECTED SNA FILE ----------------------------------------------------


select_sna

	call cache_settings

	di

	ld a,(menu_sel)		; Load a snapshot and start it if successful
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,menu
	add hl,de			; get its filename from the menu
	push hl
	pop ix
	ld a,(ix+15)		; is this a directory?
	or a
	jr z,notadir
	ld a,"."			; is the dir "." or ".."?
	cp (hl)
	jr z,dotdir
	call fat16_change_dir	; if not change to dir in filename
	xor a
	ld (menu_sel),a
	call cache_settings
	jp list_files
dotdir	cp (ix+1)			; is this "." or ".."?
	jr z,pardir
	call fat16_root_dir
	xor a
	ld (menu_sel),a
	jp list_files	
pardir	call fat16_parent_dir
	xor a
	ld (menu_sel),a
	jp list_files
	

notadir	ld (filename_loc),hl
	ld de,restart_pc		; attempt to load the four bytes of Spectrum 128 info
	call fat16_open_file	; HL = filename
	jp nz,load_error
	ld hl,0
	ld de,4
	call fat16_set_load_length
	ld hl,0
	ld de,49179
	call fat16_set_file_pointer
	call fat16_read_data	; if load fails, assume its a 48KB snapshot
	jp z,load128
	ld a,(roms_available)	; was the Spectrum 48 ROM loaded?
	bit 1,a
	jp z,no_48_rom_error
	ld hl,(filename_loc)	; load header + 49152 bytes (entire spectrum 48 snapshot)
	ld de,sna_address
	call fat16_open_file	; load into actual Spectrum RAM
	jp nz,load_error
	call fat16_read_data
	jp nz,load_error
	call debug_it		; HOLD D TO SHOW MEMORY CONTENTS
	ld a,2			
	out (mem_bank_port),a	; Select buffer RAM 02 @ $4000-$FFFF (contains original Spectrum 48 ROM)
	ld hl,$45ed
	ld (restart_jp),hl		; set up "RETN" at $fff0 (2 byte instruction) this is the switchover point
	ld a,$20			; select page 0 at $c000, ROM 0 and lock bank register for spectrum mode
	ld bc,$7ffd
	out (c),a
	jp kjt_restart_48_snapshot
	
	
load128	ld a,(roms_available)	; Was the Spectrum 128 ROM loaded
	bit 0,a
	jp z,no_128_rom_error
	ld a,(port_7ffd_value)	; select relevant page at $c000
	and 7
	ld bc,$7ffd
	out (c),a

	ld hl,(filename_loc)	; load header + banks [5], [2], [x] - first 49179 bytes
	ld de,sna_address
	call fat16_open_file
	jp nz,load_error
	ld hl,0
	ld de,49179
	call fat16_set_load_length
	call fat16_read_data
	jp nz,load_error

	ld hl,(filename_loc)		
	ld de,$c000
	call fat16_open_file
	jp nz,load_error
	ld hl,0
	ld de,49183
	call fat16_set_file_pointer	; skip PC/port7ffd/tr_dos bytes
	xor a
nxt_bank	ld (load_bank),a
	ld a,(port_7ffd_value)
	and 7
	ld b,a
	ld a,(load_bank)		; skip if bank if its the same as one already loaded
	cp 2
	jr z,skipbank
	cp 5
	jr z,skipbank
	cp b
	jr z,skipbank
	ld bc,$7ffd		; set relevent bank @ $c000
	out (c),a
	and 7
	out (254),a		; test: border colour = bank number
	ld hl,0
	ld de,16384
	call fat16_set_load_length	
	call fat16_read_data
	jp nz,load_error
skipbank	ld a,(load_bank)
	inc a
	cp 8
	jr nz,nxt_bank

	call debug_it		; HOLD D TO SHOW MEMORY DUMP!
	
go_sna128	ld a,1			
	out (mem_bank_port),a	; Select buffer RAM 01 @ $4000-$FFFF (Spec 128 ROM) 
	ld hl,$c300
	ld (restart_jp),hl		; set up "NOP, JP xxxx" at $fff0, this is the switchover point
	ld hl,(restart_pc)
	ld (restart_jp+2),hl
	ld a,(port_7ffd_value)	; save snapshot's port $7ffd value for restart code
	ld (restart_jp+4),a
	jp kjt_restart_128_snapshot	; restart .sna - note: A Jump not a Call
	

;------------------------------------------------------------------------------------------

no_48_rom_error

	ld hl,rom48error_txt
	jr show_error

no_128_rom_error

	ld hl,rom128error_txt
	jr show_error
	
load_error

	ld hl,load_error_txt
			
show_error

	push hl
	xor a
	out (mem_bank_port),a		; Select actual Spectrum RAM at $4000-$FFFF
	call clear_screen
	ld bc,0
	ld (cursor_pos),bc
	pop hl
	call print_string
	ei
	ld b,100
wait1	halt
	djnz wait1
	jp 0


;-----------------------------------------------------------------------------------------------

print_string

	ld bc,(cursor_pos)			; prints ascii at current cursor position
prtstrlp	ld a,(hl)				; set hl to start of 0-termimated ascii string
	inc hl	
	or a			
	jr nz,noteos

set_cursor

	ld (cursor_pos),bc		
	ret
	
noteos	cp 11				; is character a new line code LF+CR? (11)
	jr nz,nolf
	ld b,0
	inc c
	jr prtstrlp
	
nolf	push hl
	push bc
	
	sub $2a				; adjust ascii code to character definition offset
	jr c,charbad
	cp 50
	jr c,charok
charbad	xor a
charok	ld h,0				; b = xpos, c = ypos
	ld l,a
	ld de,font			; start of font 
	add hl,de
	push hl
	pop ix				; ix = first addr of char 
	
	ld a,c				; coords to vram address
	and 7
	rrca
	rrca
	rrca
	or b
	ld l,a
	ld a,c
	and $18
	or $40
	ld h,a

	inc h				; start 1 line down (6 line font)
	
	ld de,50				; offset to next line of char
	ld b,6
pltchlp	ld a,(ix)
	ld (hl),a
	add ix,de
	inc h				; next spectrum display line
	djnz pltchlp	
	
	pop bc
	pop hl
	inc b
	jr prtstrlp

;---------------------------------------------------------------------------------------

fill_mem	ld e,a
fm_loop	ld (hl),e
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,fm_loop
	ret
		
;---------------------------------------------------------------------------------------

cache_settings

	ld a,1
	out (mem_bank_port),a
	ld hl,(fs_directory_cluster)
	ld (old_dir),hl		; store current dir and menu pos in buffer area
	ld a,(menu_sel)
	ld (old_menu),a
	ld a,(roms_available)
	ld (roms_present),a
	ld a,(vga_mode)
	ld (old_vga),a
	xor a
	out (mem_bank_port),a
	ret
	
;--------------------------------------------------------------------------------------

clear_screen

	ld hl,$4000
	ld bc,$1800
clrslp	ld (hl),0
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,clrslp
	
	ld bc,$300
clratlp	ld (hl),7
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,clratlp
	ret


;--------------------------------------------------------------------------------------

draw_selbar

	call get_bar_loc
	ld b,12
	ld a,$16
	jr selbarlp
		
		
delete_selbar

	call get_bar_loc
	ld b,12
	ld a,$07
selbarlp	ld (hl),a
	inc hl
	djnz selbarlp
	ret


get_bar_loc
	
	ld bc,0
	ld a,(menu_sel)
	cp 22
	jr c,blefts
	sub 22
	ld bc,16
blefts	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,$5800+(2*32)
	add hl,de
	add hl,bc
	ret
	
	
;-------------------------------------------------------------------------------------------

swap_vga_mode

	ld a,(vga_mode)
	xor $80
	ld (vga_mode),a
	out (sys_pic_comms),a
	ret

;---------------------------------------------------------------------------------------------------------


test_up_key
	
	ld bc,$effe
	in a,(c)				;read spectrum keyboard matrix for UP
	bit 3,a
	jr z,q_press
	xor a
	jr nouprep
q_press	ld a,(up_time)
	inc a
	cp 12
	jr nz,nouprep
	ld a,1
nouprep	ld (up_time),a
	cp 1
	ret

	
test_down_key

	ld bc,$effe
	in a,(c)				;read spectrum keyboard matrix for DOWN
	bit 4,a
	jr z,a_press
	xor a
	jr nodwnrep
a_press	ld a,(down_time)
	inc a
	cp 12
	jr nz,nodwnrep
	ld a,1
nodwnrep	ld (down_time),a
	cp 1
	ret
	
	
	
test_right_key

	ld bc,$effe
	in a,(c)				;read spectrum keyboard matrix for RIGHT
	bit 2,a
	jr z,p_press
	xor a
	jr norigrep
p_press	ld a,(right_time)
	inc a
	cp 12
	jr nz,norigrep
	ld a,1
norigrep	ld (right_time),a
	cp 1
	ret
	
	
		
test_left_key

	ld bc,$f7fe
	in a,(c)				;read spectrum keyboard matrix for LEFT
	bit 4,a
	jr z,o_press
	xor a
	jr nolefrep
o_press	ld a,(left_time)
	inc a
	cp 12
	jr nz,nolefrep
	ld a,1
nolefrep	ld (left_time),a
	cp 1
	ret
	
	
		
test_select_key

	ld bc,$bffe
	in a,(c)				;read spectrum keyboard matrix for enter
	bit 0,a
	jr z,ent_press
	xor a
	jr noentrep
ent_press	ld a,(sel_time)
	inc a
	cp 12
	jr nz,noentrep
	ld a,1
noentrep	ld (sel_time),a
	cp 1
	ret



test_b_key

	ld bc,$7ffe
	in a,(c)				;read spectrum keyboard matrix for B key
	bit 4,a
	jr z,b_press
	xor a
	jr nobankrep
b_press	ld a,(bank_time)
	inc a
	cp 12
	jr nz,nobankrep
	ld a,1
nobankrep	ld (bank_time),a
	cp 1
	ret



test_config1_key
	
	ld bc,$fefe			;shift pressed?
	in a,(c)
	bit 0,a
	ret nz
	ld bc,$f7fe
	in a,(c)				;read spectrum keyboard matrix for 1 key
	bit 0,a
	ret
	
test_config2_key

	ld bc,$fefe			;shift pressed?
	in a,(c)
	bit 0,a
	ret nz
	ld bc,$f7fe
	in a,(c)				;read spectrum keyboard matrix for 2 key
	bit 1,a
	ret

test_config3_key

	ld bc,$fefe			;shift pressed?
	in a,(c)
	bit 0,a
	ret nz
	ld bc,$f7fe
	in a,(c)				;read spectrum keyboard matrix for 3 key
	bit 2,a
	ret
	
test_vga50_key

	ld bc,$fefe			;shift pressed?
	in a,(c)
	bit 0,a
	ret nz
	bit 4,a				;v pressed?
	jr z,vs_press
	xor a
	jr novsrep
vs_press	ld a,(vs_time)
	inc a
	cp 100
	jr nz,novsrep
	ld a,1
novsrep	ld (vs_time),a
	cp 1
	ret
	
	
;------------------------------------------------------------------------------------------	

send_byte_to_pic

pic_data_input	equ 0	; from FPGA to PIC
pic_clock_input	equ 1	; from FPGA to PIC

; put byte to send in A
; Bit rate ~ 50KHz (Transfer ~ 4.7KBytes/Second)

	push bc
	push de
	ld c,a			
	ld d,8
bit_loop	xor a
	rl c
	jr nc,zero_bit
	set pic_data_input,a
zero_bit	out (sys_pic_comms),a		; present new data bit
	set pic_clock_input,a
	out (sys_pic_comms),a		; raise clock line
	
	ld b,12
psbwlp1	djnz psbwlp1			; keep clock high for 10 microseconds
		
	res pic_clock_input,a
	out (sys_pic_comms),a		; drop clock line
	
	ld b,12
psbwlp2	djnz psbwlp2			; keep clock low for 10 microseconds
	
	dec d
	jr nz,bit_loop

	ld b,60				; short wait between bytes ~ 50 microseconds
pdswlp	djnz pdswlp			; allows time for PIC to act on received byte
	pop de				; (PIC will wait 300 microseconds for next clock high)
	pop bc
	ret			


;--------------------------------------------------------------------------------------


include "reset_keyboard.asm"

include "fat16_load_essentials.asm"

include "sdc_load_essentials_128.asm"

include "debug.asm"

;---------------------------------------------------------------------------------------

font		 DB $00,$00,$00,$00,$00,$06,$7C,$38,$FC,$FC,$1E,$FE,$7E,$FE,$7C,$7C
        		 DB $00,$00,$3C,$00,$3C,$7C,$7C,$7C,$FC,$7C,$FC,$FE,$FE,$7C,$E6,$7C
         		 DB $7E,$E6,$E0,$C6,$E6,$7C,$FC,$7C,$FC,$7E,$FE,$E6,$E6,$C6,$C6,$CE
         		 DB $FE,$18,$00,$18,$00,$00,$00,$0E,$CE,$78,$0E,$0E,$3E,$E0,$E0,$06
         		 DB $E6,$CE,$18,$30,$70,$00,$0E,$EE,$E6,$E6,$E6,$E6,$E6,$E0,$E0,$E6
         		 DB $E6,$38,$1C,$EC,$E0,$EE,$F6,$E6,$E6,$E6,$E6,$E0,$38,$E6,$E6,$C6
        		 DB $6C,$CE,$1E,$3C,$00,$18,$00,$00,$00,$1C,$DE,$38,$7E,$3C,$76,$FC
        		 DB $FC,$0C,$7C,$7E,$18,$30,$70,$7E,$0E,$0E,$EE,$E6,$FC,$E0,$E6,$F8
         		 DB $E0,$E0,$E6,$38,$1C,$F8,$E0,$FE,$FE,$E6,$E6,$E6,$E6,$7C,$38,$E6
         		 DB $E6,$C6,$38,$CE,$3C,$3C,$00,$7E,$00,$7E,$00,$38,$F6,$38,$E0,$0E
         		 DB $E6,$0E,$E6,$18,$E6,$0E,$00,$00,$70,$00,$0E,$3C,$EE,$FE,$E6,$E0
         		 DB $E6,$E0,$F8,$EE,$FE,$38,$1C,$EC,$E0,$D6,$FE,$E6,$FC,$E2,$FC,$0E
         		 DB $38,$E6,$E6,$D6,$7C,$7E,$78,$18,$00,$18,$18,$00,$18,$70,$E6,$38
          	 DB $E0,$0E,$FF,$0E,$E6,$38,$E6,$CE,$18,$30,$70,$7E,$0E,$00,$E0,$E6
         		 DB $E6,$E6,$E6,$E0,$E0,$E6,$E6,$38,$DC,$E6,$E0,$C6,$EE,$E6,$E0,$EC
          	 DB $E6,$CE,$38,$E6,$6C,$FE,$EE,$0E,$F0,$00,$00,$18,$30,$00,$18,$E0
         		 DB $7C,$7C,$FE,$FC,$06,$FC,$7C,$38,$7C,$7C,$18,$60,$3C,$00,$3C,$38
          	 DB $7C,$E6,$FC,$7C,$FC,$FE,$E0,$7C,$E6,$7C,$78,$E6,$FE,$C6,$E6,$7C
         		 DB $E0,$76,$E6,$7C,$38,$7C,$38,$6C,$C6,$FC,$FE,$18

;---------------------------------------------------------------------------------------	

greetings_txt 	db " SPECTRUM 48,128 EMULATOR V0.10",11,11,0

files_txt		db "FILES:",11,11,0

loading_128rom_txt	db "LOADING SPECTRUM 128 ROM..",11,11,0

loading_48rom_txt	db "LOADING SPECTRUM 48 ROM..",11,11,0

load_error_txt	db "LOAD ERROR",0

no_roms_txt	db "NO SPECTRUM ROMS",0

dir_txt		db " <D>",0

cr_txt		db 11,0         		 

rom128error_txt	db "NEEDS SPECTRUM 128 ROM",0

rom48error_txt	db "NEEDS SPECTRUM 48 ROM",0

;---------------------------------------------------------------------------------------	

specdir_fn	db "spectrum",0
rom128_fn		db "zxspe128.rom",0
rom48_fn		db "zxspec48.rom",0

;--------------------------------------------------------------------------------------

reconfig_sequence	db $88,$b8,$00,$00		; set config base ($88,$b8,x,y,z) 
cfg_msb		db $00,$88,$a1		; reconfig now ($88,$a1) (this is dynamically updated)

;--------------------------------------------------------------------------------------

roms_available	db 0
cursor_pos	dw 0
load_bank		db 0
filename_loc	dw 0
menu_loc		dw 0
menu_sel		db 0
max_entry		db 0
up_time	 	db 0
down_time		db 0
left_time  	db 0
right_time 	db 0
sel_time	 	db 0
bank_time 	db 0
vga_mode		db 0
vs_time		db 0

restart_pc	dw 0
port_7ffd_value	db 0
tr_dos		db 0

menu		ds 44*16,0

;---------------------------------------------------------------------------------------
