;------------------------------------------------------------------------------------
; V6Z80P ROM code v6.12 - Compile with PASM0. This requires OSCA 652+
;------------------------------------------------------------------------------------
;
; This code is to be included into the actual FPGA configuration file as a ROM located
; at address $0. Its purpose is to initialize the hardware and download the boot code
; from the config EEPROM. This ROM code must fit in 512 bytes!

; The bootcode is loaded to $200. 3520 bytes are requested from EEPROM location $0f000,
; (if that fails timeout or CRC check, bootcode backup location $1f000 is tried.)

; This ROM code also contains some routines that are used by the bootcode (as RST routines)
 
;---------------------------------------------------------------------------------------

include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;--- variables -------------------------------------------------------------------------

cursor_pos	equ video_base+$1ffe	; cursor pos variable is held in video memory
bootcode_font	equ video_base+$1e80	; as is the bootcode font

;---------------------------------------------------------------------------------------
	org $0				; CPU reset vector
;---------------------------------------------------------------------------------------

reset	di				; Disable interrupts
	im 1				; Interrupt mode 1
	ld sp,new_rom_stack			; Set stack pointer
	jr start1

;---------------------------------------------------------------------------------------
	org $8
;---------------------------------------------------------------------------------------	

	jp get_hw_version			; rst $8 = get h/w version

start1	xor a
	out (sys_mem_select),a		; make sure at bank 0 / nothing paged in
	jr start2
	
;----------------------------------------------------------------------------------------
	org $10	
;----------------------------------------------------------------------------------------

	jp print_string			; rst $10 = print string (boot time code)

start2	out (sys_alt_write_page),a		; need video registers paged in at this stage
	jr waitblit
	
;----------------------------------------------------------------------------------------
	org $18	
;----------------------------------------------------------------------------------------

	jp pause_4ms			; rst $18 = pause 4 milliseconds

;-------- VIDEO INIT -----------------------------------------------------------------------
				
waitblit	ld a,(vreg_read)			; Check blitter is not running before commencing
	and 16				; (Palette 0 shows a non-black colour when waiting)
	ld (palette),a
	jr nz,waitblit
	
	ld b,a				; A will be zero coming off previous loop
	ld hl,spr_registers+$1ff		; clear palette / sprite registers
clrpalsp	ld (hl),a
	dec hl
	ld (hl),a
	dec hl
	djnz clrpalsp
	dec h
	dec h
	jp p,clrpalsp

	jr cont_init_gfx

;----------------------------------------------------------------------------------------
	org $38
;----------------------------------------------------------------------------------------
	
	jp irq_jp_inst		

;----------------------------------------------------------------------------------------

cont_init_gfx

	ld b,$17
	ld hl,vreg_xhws			; clear video registers - stop before
	call clear_mem			; blitwidth register ($217) 
	ld hl,vreg_xhws+$30			 
	ld b,$50				; continue after linedraw and clear other
	call clear_mem			; registers, bitplanes etc

	ld a,%01000000			; page video memory in
	out (sys_mem_select),a		; (selects high RAM page 0 also)
	ld hl,video_base			; clear vram 0-7fff for BIOS screen
	xor a
	ld c,32
clr_scr2	ld b,a
	call clear_mem
	dec c
	jr nz,clr_scr2
	out (sys_mem_select),a		; page video memory out

	ld hl,vreg_window
	ld (hl),$59			; set y window size/position (192 lines)
	jr cont_init_gfx2

;----------------------------------------------------------------------------------------
	org $66		
;----------------------------------------------------------------------------------------
	
	jp nmi_jp_inst			; NMI interrupt vector
	
;----------------------------------------------------------------------------------------

cont_init_gfx2

	ld a,%00000100
	ld (vreg_rasthi),a			; select x window register
	ld (hl),$8c			; set x window size/position (320 pixels)


;-------- MAIN SYSTEM INIT --------------------------------------------------------------

	xor a
	out (sys_ps2_joy_control),a		; release keyboard / mouse control lines
	out (sys_irq_enable),a		; zero all IRQ enables
	out (sys_audio_enable),a		; disable sound channels

	ld c,$10				; zero ports $10 to $20 inclusive (sound and
	ld b,a				; low_page setting)
	ld l,17
clploop	out (c),a
	inc c
	dec l
	jr nz,clploop	

	call set_timer			; timer @ 256 * 256 cycles between overflows + restart

	ld a,%00000001			; disable NMI switch
	ld hl,vreg_read
	bit 5,(hl)			; 60Hz mode?
	jr z,pal50hz			
	ld a,%00000101			; NMI inhibit + 60Hz mode
pal50hz	out (sys_hw_settings),a
	

;-------- DOWNLOAD BOOT CODE FROM EEPROM -------------------------------------------------	


dl_bcode	ld e,2				; attempts
	ld hl,databurst_sequence1		; tell PIC to send 3520 bytes from EEPROM addr $4800
init_db	push de
	in a,(sys_eeprom_byte)		; clear shift reg count with a read
	ld b,12
init_dblp	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz init_dblp

	ld a,$80
	out (sys_alt_write_page),a		; page out the video registers / allow access to SysRAM $200-$6FF

	ld hl,$ffff			; init CRC value
	exx
	ld hl,new_bootcode_location		; download loop.. 
	ld bc,new_bootcode_length-2		;                 
nxt_byte	call get_byte			; get byte from EEPROM
	jr c,to_error
	ld (hl),a				; copy to dest
	call do_crc
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,nxt_byte
	exx
	ld b,2				; last 2 bytes are CRC
getcrc_lp	ld c,a
	call get_byte
	jr c,to_error
	djnz getcrc_lp
	pop de
	ld b,a	
	xor a
	sbc hl,bc				;compare computed CRC to that in file
	jp z,new_bootcode_location		;start bootcode if equal	
	
	ld h,$0f				;if failed flash MMC/SD LED and video
dl_error	ld l,h				;and retry
	xor a
	out (sys_pic_comms),a		;ensure clock line is low ready for next attempt
	out (sys_alt_write_page),a		;need access to vregs for palette change					
	call palette_pause_500ms		;green = time out, magenta = crc error	
	ld hl,0
	call palette_pause_500ms

	dec e				;if already tried backup location, retry $4800 again
	jr z,dl_bcode			
	ld hl,databurst_sequence2		;try backup bootcode location ($14800)
	jr init_db

to_error	pop de
	ld h,$f0
	jr dl_error			; if waited about 1 second, timeout

;-------------------------------------------------------------------------------------------------------------
	
get_byte	ld d,0				; D counts timer overflows
	ld a,1<<pic_clock_input		; prompt PIC to send a byte by raising PIC clock line
	out (sys_pic_comms),a
wbc_byte	in a,(sys_hw_flags)			; have 8 bits been received?		
	bit 4,a
	jr nz,gbcbyte
	in a,(sys_irq_ps2_flags)		; check for timer overflow..
	and 4
	jr z,wbc_byte	
	out (sys_clear_irq_flags),a		; clear timer overflow flag
	inc d				; inc count of overflows,
	jr nz,wbc_byte			
	scf
	ret
gbcbyte	xor a			
	out (sys_pic_comms),a		; drop PIC clock line, PIC will then wait for next high 
	in a,(sys_eeprom_byte)		; read byte received, clear bit count
	ret				; carry flag will be clear IN/OUT above dont affect it
	

do_crc	exx
	xor h				; do CRC calculation		
	ld h,a			
	ld b,8
crcbyte	add hl,hl
	jr nc,crcnext
	ld a,h
	xor 10h
	ld h,a
	ld a,l
	xor 21h
	ld l,a
crcnext	djnz crcbyte
	exx
	ret
	
;------------------------------------------------------------------------------------------------
;--------- SIMPLIFIED TEXT PLOTTING ROUTINE -----------------------------------------------------
;------------------------------------------------------------------------------------------------

print_string

	ld a,%01000000			; page video memory into $2000-$3fff
	out (sys_mem_select),a		

	ld bc,(cursor_pos)			; prints ascii at current cursor position

prtstrlp	ld a,(hl)				; set hl to start of 0-termimated ascii string
	inc hl	
	or a			
	jr nz,noteos
		
	ld (cursor_pos),bc		
	
	out (sys_mem_select),a		; page video memory OUT of $2000-$3fff (A will be 0)	
	ret
	
noteos	cp 11				; is character a new line code LF+CR? (11)
	jr nz,nolf
	ld b,0
	inc c
	jr prtstrlp

	
nolf	push hl
	push bc
	
	sub $2a				; adjust ascii code to character definition offset
	jr nc,tnc
	xor a
tnc	ld h,0				; b = xpos, c = ypos
	ld l,a
	ld de,bootcode_font			; start of font 
	add hl,de
	push hl
	pop ix				; ix = first addr of char 
	
	ld hl,video_base-(40*8)
	ld de,40*8
	ld a,c
	inc a
ymultlp	add hl,de
	dec a
	jr nz,ymultlp
gotymul	ld d,0
	ld e,b
	add hl,de				; hl = first dest addr		
	
	ld d,0
	ld b,6
pltchlp	ld a,(ix)
	ld (hl),a
	ld e,50				; offset to next line of char
	add ix,de
	ld e,40
	add hl,de
	djnz pltchlp	
	
	pop bc
	pop hl
	inc b
	jr prtstrlp
	

;---------------------------------------------------------------------------------------------------------

get_hw_version

	ld hl,OS_location			; show hardware version (4 digit BCD)
 	push hl
 	ld b,15				; bit number to read
	ld c,sys_hw_flags			; port to read from
	ld d,4
verloop2	ld e,4
	ld (hl),$03			; Decimal ascii base >> 4
verloop1	in a,(c)				; serial data is bit 7
	sla a				; force into carry flag
	rl (hl)				; word ends up in DE
	dec b
	dec e
	jr nz,verloop1			; next bit
	inc hl
	dec d
	jr nz,verloop2
	ld (hl),d				; zero terminate string
	pop hl				; return hardware version string (4 digit BCD)
	ret
	
;---------------------------------------------------------------------------------------------------------

palette_pause_500ms				
	
	ld (palette),hl			; change background colour to HL and wait 0.5 seconds
	
pause_500ms

	ld b,128
phs_lp	rst $18
	djnz phs_lp
	ret

;---------------------------------------------------------------------------------------------------------
	
pause_4ms
	push af
	xor a				; set timer to count 256 x 65536 cycles
	call set_timer
pause_lp	call test_timer
	jr z,pause_lp			
	pop af
	ret

;------------------------------------------------------------------------------------------

set_timer

; put timer reload value in A before calling, remember - timer counts upwards!

	out (sys_timer),a			;load and restart timer
	ld a,%00000100
	jr clr_tirq			;clear timer overflow flag

;------------------------------------------------------------------------------------------
	
test_timer

; zero flag is set on return if timer has not overflowed

	in a,(sys_irq_ps2_flags)		;check for timer overflow..
	and 4
	ret z	
clr_tirq	out (sys_clear_irq_flags),a		;clear timer overflow flag
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
zero_bit	out (sys_pic_comms),a	; present new data bit
	set pic_clock_input,a
	out (sys_pic_comms),a	; raise clock line
	
	ld b,12
psbwlp1	djnz psbwlp1		; keep clock high for 10 microseconds
		
	res pic_clock_input,a
	out (sys_pic_comms),a	; drop clock line
	
	ld b,12
psbwlp2	djnz psbwlp2		; keep clock low for 10 microseconds
	
	dec d
	jr nz,bit_loop

	ld b,60			; short wait between bytes ~ 50 microseconds
pdswlp	djnz pdswlp		; allows time for PIC to act on received byte
	pop de			; (PIC will wait 300 microseconds for next clock high)
	pop bc
	ret			

	
;-------------------------------------------------------------------------------------------

clear_mem	xor a
clrloop	ld (hl),a
	inc hl
	djnz clrloop
	ret
	
;-------------------------------------------------------------------------------------------

databurst_sequence1

	db $88,$d4,$00,$f0,$00		; set address to $f000 ($88,$d4,low,mid,high)
	db $88,$e2,$c0,$0d,$00		; set length to $DC0  ($88,$e2,low,mid,high)
	db $88,$c9			; begin transfer!

databurst_sequence2

	db $88,$d4,$00,$f0,$01		; set address to $1f000 ($88,$d4,low,mid,high)
	db $88,$e2,$c0,$0d,$00		; set length to $DC0  ($88,$e2,low,mid,high)
	db $88,$c9
		
;------------------------------------------------------------------------------------------
	