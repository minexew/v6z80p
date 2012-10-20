;
;SOURCE TAB SIZE = 10
;
;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;--------------------------------------------------------------------------------------
; Boing demo v1.07 - For 50Hz PAL		
; 30-08-2012: Uses bulk file loader.
;--------------------------------------------------------------------------------------

sprite_data 	equ $8000
tile_data		equ $8000

;--------------------------------------------------------------------------------------
; Program location / truncation header
;--------------------------------------------------------------------------------------

my_location equ $5000	; desired load address        
my_bank     equ $00 	; desired bank (used if location is $8000 to $FFFF)

          org my_location  ; desired load address

load_loc  db $ed,$00       		; header ID (Invalid but safe Z80 instruction)
          jr exec_addr     		; jump over remaining header data 
          dw load_loc      		; location file should load to 
          db my_bank       		; upper 32KB bank that file should load into
          db 01            		; control byte: 1=truncate using next 3 bytes
          dw prog_end-my_location       ; Load length 15:0 (if truncate feature required)
          db 0          		; Load length 23:16 (""                "")

exec_addr

;-------- Set up system for demo ------------------------------------------------------

	di			; disable interrupts at CPU
	xor a
	out (sys_irq_enable),a	; disable all irq sources
	ld a,%00000111
	in a,(sys_clear_irq_flags)	; clear irq flags 	

	xor a
	ld (vreg_sprctrl),a		; disable sprites
	call clear_video_ram
	call zero_palette
	
	xor a
	call progress_bar		; init progress bar


;-------- Load Samples ------------------------------------------------------------------------

	ld hl,samp_filename		; load sample data
	ld b,3			; bank 3 (audio ram base)
	ld de,$8000		; address to load to 
	call load_from_bulk_file
	jp nz,load_problem
	ld hl,0
	ld (force_sample_base),hl	; Force sample base location to $0
	call init_tracker		; Initialize mod with forced sample_base

	ld a,4
	call progress_bar

;-------- Load sprite files  -----------------------------------------------------------------------
	
	ld hl,sprites_fn1
	ld b,2			;bank 2
	ld de,sprite_data		;address to load to 
	call load_from_bulk_file
	jp nz,load_problem
	ld a,0			;sprite dest bank = 0 (each bank = 4KB)
	ld b,2			;source addr bank = 2	
	ld c,128/16		;sprite pages to copy (16 sprites per page)
	ld hl,sprite_data		;source addresss
	call upload_sprites

	ld a,6
	call progress_bar
	
	ld hl,sprites_fn2
	ld b,2			;bank 2
	ld de,sprite_data		;address to load to 
	call load_from_bulk_file
	jp nz,load_problem
	ld a,8			;sprite dest bank = 8 (each bank = 4KB)
	ld b,2			;source addr bank = 2	
	ld c,128/16		;sprite pages to copy (16 sprites per page)
	ld hl,sprite_data		;source addresss
	call upload_sprites

	ld a,8
	call progress_bar

	ld hl,sprites_fn3
	ld b,2			;bank 2
	ld de,sprite_data		;address to load to 
	call load_from_bulk_file
	jp nz,load_problem
	ld a,16			;sprite dest bank = 16 (each bank = 4KB)
	ld b,2			;source addr bank = 2	
	ld c,128/16		;sprite pages to copy (16 sprites per page)
	ld hl,sprite_data		;source addresss
	call upload_sprites

	ld a,10
	call progress_bar

	ld hl,sprites_fn4
	ld b,2			;bank 2
	ld de,sprite_data		;address to load to 
	call load_from_bulk_file
	jp nz,load_problem
	ld a,24			;sprite dest bank = 24 (each bank = 4KB)
	ld b,2			;source addr bank = 2	
	ld c,64/16		;sprite pages to copy (16 sprites per page)
	ld hl,sprite_data		;source addresss
	call upload_sprites

	ld a,12
	call progress_bar


;-------- Load tile files  -----------------------------------------------------------------------

	ld hl,tiles_fn1		;filename loc
	ld b,2			;bank 2
	ld de,tile_data		;address to load to 
	call load_from_bulk_file
	jp nz,load_problem
	ld a,8			;tile dest bank (each bank = 8KB)
	ld b,2			;source addr bank = 2	
	ld c,128/32		;tile pages to copy (32 per page)
	ld hl,tile_data		;source addresss
	call upload_tiles

	ld a,15
	call progress_bar

	ld hl,tiles_fn2		;filename loc
	ld b,2			;bank 2
	ld de,tile_data		;address to load to 
	call load_from_bulk_file
	jp nz,load_problem
	ld a,12			;tile dest bank (each bank = 8KB)
	ld b,2			;source addr bank = 2	
	ld c,128/32		;tile pages to copy (32 per page)
	ld hl,tile_data		;source addresss
	call upload_tiles

	ld a,18
	call progress_bar
	
	ld hl,tiles_fn3		;filename loc
	ld b,2			;bank 2
	ld de,tile_data		;address to load to 
	call load_from_bulk_file
	jp nz,load_problem

	call zero_palette

	ld a,4			;tile dest bank (each bank = 8KB)
	ld b,2			;source addr bank = 2	
	ld c,128/32		;tile pages to copy (32 per page)
	ld hl,tile_data		;source addresss
	call upload_tiles


;--------- Init Video ------------------------------------------------------------------------


	ld a,%10001011		
	ld (vreg_vidctrl),a		; select tile mode / dual pf / wide border / pf A to use blockset B
	ld a,$8f	
	ld (vreg_rastlo),a		; split line number req'd
	ld a,$2e			; 	
	ld (vreg_window),a		; 256 line display
	ld a,%00000110		; Switch to x window pos reg. Enable Raster IRQ, Position MSB = 0
	ld (vreg_rasthi),a		
	ld a,$6e			
	ld (vreg_window),a		; Start = 96 Stop = 480 (Window Width = 368 pixels with wideborder)
	
	ld hl,colours		; write palette
	ld de,palette
	ld b,0
pwloop	ld c,(hl)
	inc hl
	ld a,(hl)
	inc hl
	ld (de),a
	inc de
	ld a,c
	ld (de),a
	inc de
	djnz pwloop


	ld hl,spr_registers		;zero all sprite registers
	ld b,0
wsprrlp	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	djnz wsprrlp


	ld a,%00000000		; clear the tile map where logo will be
	ld (vreg_vidpage),a		; select the 1st video page to access tile maps
	in a,(sys_mem_select)
	or %01000000
	out (sys_mem_select),a	; page in vram
	ld hl,video_base+$400
	ld b,0
	ld a,$8f
clmap2lp	ld (hl),a
	inc hl
	ld (hl),a
	inc hl
	ld (hl),a
	inc hl
	ld (hl),a
	inc hl
	djnz clmap2lp

	ld a,$80
	ld de,32-14
	ld hl,video_base+$700	;draw in logo in map buffer 3 for blitter to
	ld c,5			;copy during demo
drawllp2	ld b,14
drawllp1	ld (hl),a
	inc a
	inc hl
	djnz drawllp1
	inc a
	inc a
	add hl,de
	dec c
	jr nz,drawllp2

	ld hl,video_base+$800	;draw in circuit pattern for blitter during demo
	ld d,40
	ld c,0
dbglp2	ld b,40
	xor a
dbgloop	and $f
	or c
	ld (hl),a
	inc hl
	inc a
	djnz dbgloop
	ld a,c
	add a,$10
	ld c,a
	dec d
	jr nz,dbglp2
	in a,(sys_mem_select)
	and %10111111
	out (sys_mem_select),a	; page out vram

	ld d,ascii_translate/256	; convert ascii to char tile values
	ld hl,scrolling_message
smaclp	ld a,(hl)
	or a
	jr z,smacdone
	ld e,a
	ld a,(de)
	add a,208
	ld (hl),a
	inc hl
	jr smaclp
smacdone	ld (hl),$8e		; loop char

	ld a,%00000011
	ld (vreg_sprctrl),a		; Enable sprites  / set priority mode (masked by colours 128-255)	
	
	ld hl,irq_handler		
	ld (irq_vector),hl
	ld a, %10000000
	out (sys_irq_enable),a	;master irq enable
	ei
	

;------------------------------------------------------------------------------------------------------


wvrtstart	ld a,(vreg_read)		;wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend

	ld a,(paused)
	or a
	jr z,notpaused
	in a,(sys_irq_ps2_flags)	;get out of pause mode?
	and 1
	jr z,wvrtstart
	in a,(sys_keyboard_data)
	cp $4d
	jr nz,wvrtstart
	xor a
	ld (paused),a
	jr wvrtstart

notpaused	

	in a,(sys_irq_ps2_flags)	;enter pause mode?
	and 1
	jr z,routines
	in a,(sys_keyboard_data)
	cp $4d
	jr nz,routines
	ld a,1
	ld (paused),a
	jr wvrtstart


routines	ld a,(counter)
	inc a
	ld (counter),a
	
;	ld hl,$f0f
;	ld (palette),hl

	call sprite_reg_update
	
	call update_bgnd_scroll
	
	call draw_logo
	
	call do_scrolling_msg
	
	call animate_boings
	
	call play_tracker		;main tracker code
	call update_sound_hardware	;update sound hardware
	
;	ld hl,0
;	ld (palette),hl
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		; loop if ESC key not pressed
	
	xor a
	out (sys_audio_enable),a	; silence channels
	ld a,$ff			; and quit (restart OS)
	ret

;------------------------------------------------------------------------------------------------------


sprite_reg_update

	ld ix,boing_xcoord		
	ld iy,spr_registers
	ld b,5			;number of large boing balls
bbsprlp	push bc
	ld a,(boing_def_l)
	ld e,a
	ld c,(ix)			; get ball's x coordinate
	ld l,(ix+$10)		; get ball's arc index for y
	ld h,arc_table_l/256
	ld a,160			; flip arc pattern so bounce is at the bottom
	sub (hl)
	add a,$11			; offset from top of display
	ld l,a			; L = y coord for this ball
	ld b,6			; 6 sprites per large ball
bbsrloop	ld d,$60			; height of sprite (6 blocks)
	ld a,c
	sla a			; x coord * 2 
	ld (iy),a			
	jr nc,xnmsb
	ld d,$61			
xnmsb	ld (iy+1),d		; height / x msb
	ld (iy+2),l		; y coord
	ld (iy+3),e		; definition
	ld a,e
	add a,6			; next sprites block number
	ld e,a
	ld a,c
	add a,8			; next sprites x xoord
	ld c,a
	inc iy
	inc iy
	inc iy
	inc iy
	djnz bbsrloop
	inc ix
	pop bc
	djnz bbsprlp
	

	ld b,4			;number of medium boing balls
mbsprlp	push bc
	ld a,(boing_def_m)
	ld e,a
	ld c,(ix)			; get ball's x coordinate
	ld l,(ix+$10)		; get ball's arc index for y
	ld h,arc_table_m/256
	ld a,192			; flip arc pattern so bounce is at the bottom
	sub (hl)
	add a,$11			; offset from top of display
	ld l,a			; L = y coord for this ball
	ld b,4			; 4 sprites per medium ball
mbsrloop	ld d,$44			; height of sprite (4 blocks)
	ld a,c
	sla a			; x coord * 2 
	ld (iy),a			
	jr nc,mxnmsb
	ld d,$45			
mxnmsb	ld (iy+1),d		; height / x msb / def msb
	ld (iy+2),l		; y coord
	ld (iy+3),e		; definition
	ld a,e
	add a,4			; next sprites block number
	ld e,a
	ld a,c
	add a,8			; next sprites x xoord
	ld c,a
	inc iy
	inc iy
	inc iy
	inc iy
	djnz mbsrloop
	inc ix
	pop bc
	djnz mbsprlp

	
	ld b,3			;number of small boing balls
sbsprlp	push bc
	ld a,(boing_def_s)
	add a,128
	ld e,a
	ld c,(ix)			; get ball's x coordinate
	ld l,(ix+$10)		; get ball's arc index for y
	ld h,arc_table_s/256
	ld a,208			; flip arc pattern so bounce is at the bottom
	sub (hl)
	add a,$11			; offset from top of display
	ld l,a			; L = y coord for this ball
	ld b,3			; 3 sprites per large ball
sbsrloop	ld d,$34			; height of sprite (6 blocks)
	ld a,c
	sla a			; x coord * 2 
	ld (iy),a			
	jr nc,sxnmsb
	ld d,$35			
sxnmsb	ld (iy+1),d		; height / x msb / def msb
	ld (iy+2),l		; y coord
	ld (iy+3),e		; definition
	ld a,e
	add a,3			; next sprites block number
	ld e,a
	ld a,c
	add a,8			; next sprites x xoord
	ld c,a
	inc iy
	inc iy
	inc iy
	inc iy
	djnz sbsrloop
	inc ix
	pop bc
	djnz sbsprlp
	ret
	
	
	
animate_boings


	ld ix,boing_xcoord		
	ld b,5			; number of large boings
anboings	ld a,(ix+$50)		; wait until boing has been released
	or a
	jr z,brelease
	call release_time
	jr bnxtboing
brelease	ld a,(ix)			; xcoord
	add a,(ix+$20)		; add displacement
	ld (ix),a			
	ld c,a
	ld a,(ix+$40)		; trapped check
	or a
	jr nz,btrapped
	ld a,c
	cp 128
	jr nc,bdirok
	cp 96
	jr c,bdirok
	ld (ix+$40),1		; mark as trapped if between these limits
btrapped	ld a,c
	cp 196
	jr nc,bswpdir
	cp 58
	jr nc,bdirok
bswpdir	ld a,(ix+$20)		; negate x displacement if out of bounds
	cpl
	inc a
	ld (ix+$20),a
bdirok	ld a,(ix+$10)		; update y arc index
	add a,(ix+$30)
	ld (ix+$10),a
bnxtboing	inc ix
	djnz anboings
	ld a,(boing_def_l)		; update definition
	add a,36			; skip 6 * 6 blocks
	cp 36*7
	jr nz,bdefok
	xor a
bdefok	ld (boing_def_l),a
		
	
	ld b,4			; number of medium boings
manboings	ld a,(ix+$50)		; wait until boing has been released
	or a
	jr z,mrelease
	call release_time
	jr mnxtboing
mrelease	ld a,(ix)			; xcoord
	add a,(ix+$20)		; add displacement
	ld (ix),a			
	ld c,a
	ld a,(ix+$40)		; trapped check
	or a
	jr nz,mtrapped
	ld a,c
	cp 128
	jr nc,mbdirok
	cp 96
	jr c,mbdirok
	ld (ix+$40),1		; mark as trapped if between these limits
mtrapped	ld a,c
	cp 210
	jr nc,mbswpdir
	cp 58
	jr nc,mbdirok
mbswpdir	ld a,(ix+$20)		; negate x displacement if out of bounds
	cpl
	inc a
	ld (ix+$20),a
mbdirok	ld a,(ix+$10)		; update y arc index
	add a,(ix+$30)
	ld (ix+$10),a
mnxtboing	inc ix
	djnz manboings
	ld a,(boing_def_m)		; update definition
	add a,16			; skip 6 * 6 blocks
	cp 16*7
	jr nz,mbdefok
	xor a
mbdefok	ld (boing_def_m),a
		
	
	ld b,3			; number of small boings
sanboings	ld a,(ix+$50)		; wait until boing has been released
	or a
	jr z,srelease
	call release_time
	jr snxtboing
srelease	ld a,(ix)			; xcoord
	add a,(ix+$20)		; add displacement
	ld (ix),a			
	ld c,a
	ld a,(ix+$40)		; trapped check
	or a
	jr nz,strapped
	ld a,c
	cp 128
	jr nc,sbdirok
	cp 96
	jr c,sbdirok
	ld (ix+$40),1		; mark as trapped if between these limits
strapped	ld a,c		
	cp 218
	jr nc,sbswpdir
	cp 58
	jr nc,sbdirok
sbswpdir	ld a,(ix+$20)		; negate x displacement if out of bounds
	cpl
	inc a
	ld (ix+$20),a
sbdirok	ld a,(ix+$10)		; update y arc index
	add a,(ix+$30)
	ld (ix+$10),a
snxtboing	inc ix
	djnz sanboings
	ld a,(boing_def_s)		; update definition
	add a,9			; skip 6 * 6 blocks
	cp 9*7
	jr nz,sbdefok
	xor a
sbdefok	ld (boing_def_s),a
	ret
	

release_time

	ld a,(release_go)
	or a
	ret z
	dec (ix+$50)
	ret
	
;---------------------------------------------------------------------------------------------------------	

update_bgnd_scroll

	ld a,(scroll_x)
	add a,2
	ld (scroll_x),a
	ld a,(scroll_y)
	add a,1
	ld (scroll_y),a
		
	ld a,(scroll_x)
	cpl
	and $f
	ld (vreg_xhws),a

	ld a,(scroll_y)
	and $f
	ld (vreg_yhws_bplcount),a
	
	ld a,(logo_y_pos)
	cpl
	and $0f
	or $80
	ld (vreg_yhws_bplcount),a
	
	
	ld a,(scroll_y)		; add on y offset from top of map
	and $f0
	rrca
	rrca
	rrca
	ld l,a
	ld h,0
	ld de,multlist40
	add hl,de
	ld e,(hl)
	inc hl
	ld a,(hl)
	add a,8			; source page in vram
	ld d,a
	ex de,hl		
	ld a,(scroll_x)		; add on x offset from left of map
	rrca
	rrca
	rrca
	rrca
	and $f
	ld e,a
	ld d,0
	add hl,de
	ld (blit_src_loc),hl	;src
	ld hl,$0 
	ld (blit_dst_loc),hl	;dest
	ld a,40-24		
	ld (blit_src_mod),a
	ld a,32-24
	ld (blit_dst_mod),a
	ld a,15
	ld (blit_height),a
	ld a,%01000000
	ld (blit_misc),a
	ld a,24-1
	ld (blit_width),a
	nop			;ensures blit has begun
	nop
waitblit	ld a,(vreg_read)		;wait for blit to complete
	bit 4,a 
	jr nz,waitblit
	ret


;--------------------------------------------------------------------------------------------------------	

draw_logo	

	ld de,$406
	ld a,(logo_y_pos)		; draw logo on PF B, Buffer 0 with blitter
	and $f0
	ld l,a
	ld h,0
	add hl,hl
	add hl,de
	ld (blit_dst_loc),hl	;dest
	ld hl,$700 
	ld (blit_src_loc),hl	;source
	ld a,32-14		
	ld (blit_src_mod),a
	ld a,32-14
	ld (blit_dst_mod),a
	ld a,5
	ld (blit_height),a
	ld a,%01000000
	ld (blit_misc),a
	ld a,14-1
	ld (blit_width),a
	nop			;ensures blit has begun
	nop
waitblit2	ld a,(vreg_read)		;wait for blit to complete
	bit 4,a 
	jr nz,waitblit2
	
	ld hl,logo_disp
	ld a,(logo_y_pos)
	add a,(hl)
	ld (logo_y_pos),a
	cp $20
	jr nc,nstlogo
	ld (hl),0
nstlogo	ret
	
;----------------------------------------------------------------------------------------------------

do_scrolling_msg

	in a,(sys_mem_select)	;draw line of chars
	or %01000000
	out (sys_mem_select),a	;page video ram into address space 

	ld de,video_base+$400	;erase previous scrolling msg line
	ld a,(scroll_msg_ypos)
	and $f0
	ld l,a
	ld h,0
	add hl,hl
	add hl,de
	ld a,$8f
	ld b,24/4
delsmlp	ld (hl),a
	inc hl
	ld (hl),a
	inc hl
	ld (hl),a
	inc hl
	ld (hl),a
	inc hl
	djnz delsmlp


	ld a,(scroll_msg_bounce)	; get arc index
	add a,4
	ld (scroll_msg_bounce),a
	ld l,a
	ld h,arc_table_s/256
	ld a,208			; flip arc pattern so bounce is at the bottom
	sub (hl)
	srl a
	add a,$98			; offset from top of display
	ld (scroll_msg_ypos),a
	

	ld a,(scroll_msg_xfine)	;update scrolling message pointer
	sub 4
	ld (scroll_msg_xfine),a
	jr nc,noismp
	ld a,$c
	ld (scroll_msg_xfine),a
	ld hl,(scrolltextpointer)
	inc hl
	ld a,(hl)
	cp $f7			;if char = "*", cue the balls!
	jr nz,nostar
	ld a,1
	ld (release_go),a
	jr norssmp
nostar	ld a,(hl)
	cp $8e
	jr nz,norssmp
	ld hl,scroll_msg_loop
norssmp	ld (scrolltextpointer),hl


noismp	ld de,video_base+$400
	ld a,(scroll_msg_ypos)
	and $f0
	ld l,a
	ld h,0
	add hl,hl
	add hl,de
	ex de,hl
	ld hl,(scrolltextpointer)
	ld bc,24
	ldir

	in a,(sys_mem_select)
	and %10111111
	out (sys_mem_select),a	;page video ram out of address space 
	ret


;---------------------------------------------------------------------------------------------------------


irq_handler

	push af			; Maskable IRQ jumps here
	push bc

;	ld a,$ff
;	ld (palette),a
	
	ld a,(scroll_msg_xfine)
	rrca
	rrca
	rrca
	rrca
	and $f0
	ld b,a
	ld a,(scroll_x)
	cpl
	and $f
	or b
	ld (vreg_xhws),a
	
	ld a,(scroll_msg_ypos)
	cpl
	and $0f
	or $80
	ld (vreg_yhws_bplcount),a

	ld a,%10000000
	ld (vreg_rasthi),a		; clear irq flag (leaves rest of register intact)
	
	pop bc
	pop af			
	ei			; re-enable interrupts
	reti			; return to main code


;---------------------------------------------------------------------------------------------------------

load_problem

	ld hl,palette+2		; if load error, progress bar goes red. Stops.
	ld (hl),$00
	inc hl
	ld (hl),$0f
stophere	jp stophere

;------------------------------------------------------------------------------------------------------

upload_sprites

;Before call, set A  = 4KB sprite bank (destination) IE: Def block 0-511 / 16 
;                 HL = source address
;                 B  = source bank number
;                 C  = number of sprites to upload (must all be in same source bank)

	push af
	call kjt_getbank
	ld (temp_bank),a

	ld a,b
	call kjt_forcebank	

	in a,(sys_mem_select)	;upload sprites
	or %10000000		;page in sprite ram @ $1000	
	out (sys_mem_select),a		

	pop af
	or %10000000
	ld b,c
sprcopylp	ld (vreg_vidpage),a		;select sprite bank
	push bc
	ld de,sprite_base
	ld bc,256*16		;copy 16 sprites to sprite ram page (4096 bytes)
	ldir
	inc a
	pop bc
	djnz sprcopylp			

	in a,(sys_mem_select)
	and %01111111
	out (sys_mem_select),a	;page out sprite ram

	ld a,(temp_bank)
	call kjt_forcebank
	ret

;------------------------------------------------------------------------------------------------------


upload_tiles

;Before call, set A  = 8KB video page (destination granularity = 32 blocks) 
;                 HL = source address
;                 B  = source bank number
;                 C  = number of tiles to upload (must all be in same source bank)

	push af

	call kjt_getbank
	ld (temp_bank),a

	ld a,b
	call kjt_forcebank	

	in a,(sys_mem_select)	;upload data
	or %01000000		;page in video ram @ $2000
	out (sys_mem_select),a		

	pop af
	and $0f
	ld b,c
tilecpylp	ld (vreg_vidpage),a		;select video bank access
	push bc
	ld de,video_base
	ld bc,256*32		;copy 32 tiles to vram page (8192 bytes)
	ldir
	inc a			;next vram page
	pop bc
	djnz tilecpylp			

	in a,(sys_mem_select)
	and %10111111
	out (sys_mem_select),a	;page out video ram

	ld a,(temp_bank)
	call kjt_forcebank
	ret


;---------------------------------------------------------------------------------------------------------	
	

clear_video_ram


	call kjt_page_in_video	 
	ld (save_sp),sp		
	ld hl,$0000
	ld a,$0f				
nxt_bank	ld (vreg_vidpage),a		; bitplane select		
	ld sp,video_base+8192		
	ld c,4
clr_scr2	ld b,0
clr_scr1	push hl			; 8 * 256 * 4 = 8192 bytes
	push hl
	push hl
	push hl
	djnz clr_scr1
	dec c
	jr nz,clr_scr2
	sub 1
	jr nc,nxt_bank
	ld sp,(save_sp)
	call kjt_page_out_video
	ret

;----------------------------------------------------------------------------------------------------

zero_palette

	ld hl,palette
	ld b,0
zploop	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	djnz zploop
	ret
	
;----------------------------------------------------------------------------------------------------

; Show progress bar.. 
; Clear bitmap screen before calling and set A to 1-20 for length of bar
; If A = 0, display mode and palette is initialized (and empty bar shown)
		
progress_bar
		
	push af
	call kjt_page_in_video
	
	ld a,%00000000		;access bank 0
	ld (vreg_vidpage),a	
	ld a,%00000000		;use loc reg set 0, video enable
	ld (vreg_vidctrl),a	
			
	ld hl,video_base+(124*32)+5
	ld (hl),$03
	ld b,20
lblp1	inc hl
	ld (hl),255
	djnz lblp1
	inc hl
	ld (hl),$c0
	ld ix,video_base+(125*32)+5
	ld de,32
	ld b,8
lblp2	ld (ix),$02
	ld (ix+21),$40
	add ix,de
	djnz lblp2
	ld hl,video_base+(133*32)+5
	ld (hl),$03
	ld b,20
lblp3	inc hl
	ld (hl),255
	djnz lblp3
	inc hl
	ld (hl),$c0

	pop af
	or a
	jr z,init_pb
	ld ix,video_base+(128*32)+6
lblp4	ld (ix+$c0),$ff
	ld (ix+$e0),$ff
	ld (ix+$00),$ff
	ld (ix+$20),$ff
	ld (ix+$40),$ff
	ld (ix+$60),$ff
	inc ix
	dec a
	jr nz,lblp4

exitpb	call kjt_page_out_video
	ret

	
init_pb	ld a,%00000000		; go to y window pos register
	ld (vreg_rasthi),a		 
	ld a,$2e			; 256 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$bb
	ld (vreg_window),a		; 256 bit width window
	
	ld a,0			; Use 1 bitplane
	ld (vreg_yhws_bplcount),a
		
	ld hl,bitplane0a_loc	;initialize bitplane pointers.
	xor a
	ld (hl),a
	inc hl
	ld (hl),a
	inc hl
	ld (hl),a

	ld hl,$fff		; progress bar colours
	ld (palette+2),hl
	ld hl,0
	ld (palette),hl

	jr exitpb
	
;---------------------------------------------------------------------------------------------------------	

bulkfile_fn	db "boing.exe",0		;if this is same as main program, adust index_start

index_start_lo	equ prog_end-my_location	;low word of offset to bulkfile

index_start_hi	equ 0			;hi word of offset to bulkfile


	include "bulk_file_loader.asm"

;---------------------------------------------------------------------------------------------------------	


temp_bank		db 0

		include "50Hz_60Hz_Protracker_Code_v513.asm"

samp_filename	db "TUNE03.SAM",0

		org (($+2)/2)*2		;WORD align song module in RAM

music_module	incbin "tune03.pat"

;----------------------------------------------------------------------------------------------------------

save_sp		dw 0
counter		db 0
	
multlist40	dw 0,40,80,120,160,200,240,280,320,360,400,440,480,520,560,600
	
sprites_fn1	db "SPRITES1.BIN",0
sprites_fn2	db "SPRITES2.BIN",0
sprites_fn3	db "SPRITES3.BIN",0
sprites_fn4	db "SPRITES4.BIN",0

tiles_fn1		db "CTILES1.BIN",0
tiles_fn2		db "CTILES2.BIN",0
tiles_fn3		db "LFTILES.BIN",0

load_err_msg	db "LOAD ERROR!",11,0

colours		incbin "palette.bin"

;---------------------------------------------------------------------------------------------------------	


		org (($+256)/256)*256

arc_table_l	incbin "arc_table_l.bin"

arc_table_m	incbin "arc_table_m.bin"

arc_table_s	incbin "arc_table_s.bin"

ascii_translate	db $2f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $2f,$26,$00,$00,$00,$00,$00,$2c,$2a,$2b,$27,$2e,$25,$2d,$24,$00
		db $1a,$1b,$1c,$1d,$1e,$1f,$20,$21,$22,$23,$28,$00,$00,$00,$00,$29
		db $00,$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e
		db $0f,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

;---------------------------------------------------------------------------------------------------------	



boing_xcoord	db $40,$f0,$f0,$f0,$f0,$f0,$f0,$f0
		db $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0

boing_yidx	db $10,$f0,$50,$95,$e0,$63,$26,$70
		db $20,$d0,$30,$66,$00,$00,$00,$00

boing_disp	db $01,$ff,$fe,$02,$ff,$00,$01,$ff
		db $ff,$02,$fe,$01,$00,$00,$00,$00
		
bounce_speed	db $02,$03,$04,$02,$05,$02,$04,$03
		db $03,$05,$02,$03,$00,$00,$00,$00

boing_trapped	db $01,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		
boing_release	db $00,$10,$20,$30,$40,$50,$60,$70
		db $80,$90,$a0,$b0,$00,$00,$00,$00

boing_def_l	db 0
boing_def_m	db 0
boing_def_s	db 0

scroll_x		db 0
scroll_y		db 0

logo_y_pos	db $20
logo_disp		db $0

release_go	db 0


;---------------------------------------------------------------------------------------------------------	

scrolling_message	db "                                                               "
		db "** CUE THE BALLS! **              "
scroll_msg_loop	DB "                              WELCOME TO ANOTHER Z80 PROJECT DEMO..   "
		DB "THIS TIME DEMONSTRATING THE DUAL PLAYFIELD TILE GRAPHICS MODE WITH LOTS "
		DB "OF LARGE SPRITES BOUNCING AROUND AND 90 PERCENT OF RASTER TIME LEFT UNUSED :)  "
		DB "GREETINGS TO: GREY, HUW, STEVE, DICK, BOOTBLOCK, JIM, DANIEL, ALAN, GEOFF, "
		DB "ALL C64 + AMIGA SCENERS FROM 'BACK IN THE DAY' AND RETRO FANS EVERYWHERE! "
		DB "CODED BY PHIL RUSTON (WWW.RETROLEUM.CO.UK) 20-09-2007... BE SEEING YOU!"
		DB "                         ",0
		DB "                          "


scrolltextpointer	dw scrolling_message

scroll_msg_xfine	db $00
scroll_msg_ypos	db $80
scroll_msg_bounce	db 0

paused		db 0

;=========================================================================================================	
prog_end
;=========================================================================================================