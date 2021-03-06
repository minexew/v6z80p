;---------------------------------------------------------------------------------------
; V6Z80P Spectrum 48 / 128 emulator FPGA ROM - minimal boot loader
;
; Loaded front-end file selector "spectrum/menu.zxp" to $800 and runs
; (if file is not found, menu code can be downloaded serially)
;
;---------------------------------------------------------------------------------------
;
; V0.11 - Updated to SDHC compatible SD card driver
;       - Changed "bootcode.exe" filename to "menu.zxp"
;
;---------------------------------------------------------------------------------------

mem_bank_port			equ 249		; in menu mode (IE: Spectrum code not running)

menu_code			equ $0800

fs_sector_buffer		equ $3c00
fs_vars				equ $3e00
stack	    			equ $3fc0

sna_address   			equ $3fe5	; IE: $4000 less 27 bytes (.sna header)
sna_header    			equ $ff00	; in buffer RAM page (not normal spectrum RAM)
restart_jp			equ $fff0

;----------------------------------------------------------------------------------------------
; File system variables
;----------------------------------------------------------------------------------------------

fs_cluster_size			equ fs_vars+0	
fs_fat1_loc_lba			equ fs_vars+1 
fs_root_dir_loc_lba		equ fs_vars+3 
fs_root_dir_sectors		equ fs_vars+5 
fs_file_length_working		equ fs_vars+7 
fs_file_working_cluster		equ fs_vars+11
fs_z80_working_address		equ fs_vars+13
fs_working_sector		equ fs_vars+15
fs_directory_cluster		equ fs_vars+17
fs_dir_entry_sector		equ fs_vars+19
fs_dir_entry_cluster		equ fs_vars+20
fs_dir_entry_line_offset	equ fs_vars+22
load_address			equ fs_vars+24

sector_lba0 			equ fs_vars+26
sector_lba1			equ fs_vars+27
sector_lba2			equ fs_vars+28
sector_lba3			equ fs_vars+29
sd_card_info			equ fs_vars+30			
fs_filename			equ fs_vars+31 		; 16 bytes

cmd_generic			equ fs_vars+48
cmd_generic_args		equ fs_vars+49
cmd_generic_crc			equ fs_vars+53

;---------------------------------------------------------------------------------------
	org $0				; CPU reset vector
;---------------------------------------------------------------------------------------


reset	di				; Disable interrupts
	im 1				; Interrupt mode 1
	ld sp,stack			; Set stack pointer low in memory

	xor a
	out (254),a			; Border = black
	out (mem_bank_port),a		; Actual Spectrum memory selected @ $4000-$ffff
	ld bc,$7ffd			; set ROM 0 / page 0 (this port is reset
	out (c),a			; in hardware on ESC from Spectrum mode also..)
	
	ld de,8				; Clear AY Amplitude registers
clrsnd	ld b,$ff
	out (c),e			; select reg
	ld b,$bf
	out (c),d			; write data to reg
	inc e
	ld a,e
	cp $0b
	jr nz,clrsnd
	
	ld hl,$4000			; fill vram with zeroes
	ld bc,$1800
	xor a
	call fill_mem
	ld bc,$300			; default attributes
	ld a,7
	call fill_mem
	
	jr start3			; jump over IRQ vector etc

		
;----------------------------------------------------------------------------------------
	org $38
;----------------------------------------------------------------------------------------
	
	ei
	reti				; IRQ interrupt vector

;----------------------------------------------------------------------------------------

	
fill_mem
	
	ld e,a
fm_loop	ld (hl),e
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,fm_loop
	ret


spectrum_txt	db "spectrum",0
menu_fn_txt	db "menu.zxp",0
	
;----------------------------------------------------------------------------------------
	org $66		
;----------------------------------------------------------------------------------------
	
	retn				; NMI interrupt vector

;----------------------------------------------------------------------------------------
	org $68				; DO NOT MOVE THESE JUMPS - MENU CODE RELIES ON POSITION	
;----------------------------------------------------------------------------------------
	
rom_restart_128_sna	

	jp restart_128_sna		;$68

rom_restart_48_sna

	jp restart_48_sna		;$6b


;---- LOOK FOR USERCODE.EXE ON DISK -----------------------------------------------------	


start3	call sd_initialize		; is SD card inserted?
	jr c,sdfail
	
;	ld a,(sd_card_info)		; TEST
;	ld ($401f),a			; TEST
;	ld a,$47			; TEST
;	ld ($581f),a			; TEST

	call fs_check_format		; is SD card FAT16?
	jr z,sdinitok
sdfail	and 7
	out (254),a			; show error type in border colour
	jr no_disk
	
sdinitok

	ld hl,spectrum_txt		; change to "spectrum" subdir from ROOT
	call fs_change_dir
	
	ld hl,menu_fn_txt		; Load user bootcode: "menu.zxp" to $800
	ld de,menu_code
	xor a
	call fs_load_file
	jp z,menu_code


;------- SHOW NO MENU MESSAGE -------------------------------------------------------


no_disk	ld hl,error_msg			
	ld de,$4100
	ld b,5
nucmlp	push bc
	ld bc,8
	ldir
	pop bc
	ld e,0
	inc d
	djnz nucmlp
	ld hl,$5800
	ld b,8
nucmalp	ld (hl),$d7
	inc hl
	djnz nucmalp

	
;------- WAIT FOR SERIAL DOWNLOAD OF MENU CODE ---------------------------------------------------

	di

	ld hl,serial_header		; load file header block
	call s_getblock			
	jp c,s_bad			; if carry set, there was an error / checksum was bad
	call s_goodack			; send "OK" to start the first block transfer

	ld hl,menu_code			; HL = Address at which to load usercode 
	ld de,(serial_header+17)	; Number of blocks to load
	ld a,(serial_header+16)
	or a
	jr z,s_gbloop
	inc de
s_gbloop
	call s_getblock
	jr c,s_bad
	call s_goodack			; send "OK" to acknowledge block received OK	
	dec de
	ld a,d
	or e
	jr nz,s_gbloop
	jp menu_code

s_bad	xor a
	out (254),a
	inc a
	out (254),a
	jr s_bad


;-------- COPY SPECTRUM 128 ROMS FROM RAM BUFFER 01 TO LOW MEMORY-------------------------------------------------------

restart_128_sna

	xor a				; set ROM 0 / page 0
	ld bc,$7ffd
	out (c),a

	ld hl,sna_address		; copy sna header info to buffer area
	ld de,sna_header
	ld bc,27
	ldir

	ld hl,$4000			; copy first ROM (Spectrum 128: 0) from buffer RAM 
	ld de,$0			; $4000-$7fff to $0-$3fff
	ld bc,$4000
	ldir

	ld a,16				; set ROM 1 / page 0 
	ld bc,$7ffd
	out (c),a

	ld de,$0			; copy second ROM (Spectrum 128:1) from buffer RAM 01
	ld bc,$4000			; $8000-$bfff to $0-$3fff
	ldir

	ld sp,$ffc0			; ensures IRQ PC push doesnt overwrite anything important
	ei			
	halt
	di				; wait until just after an IRQ

	ld a,(restart_jp+4)		; set snapshot's restart ROM / page 
	ld bc,$7ffd
	out (c),a
	
	
;--------- RESTORE SNAPSHOT'S REGISTERS AND RESTART 128K SNAPSHOT CODE --------------------------------


	ld a,(sna_header)		; I reg
	ld i,a
	ld sp,sna_header+1		; HL',DE',BC',AF'
	pop hl
	pop de
	pop bc
	pop af
	exx
	ex af,af'
	pop hl				; HL,DE,BC,IY,IX
	pop de
	pop bc
	pop iy
	pop ix
	ld a,(sna_header+20)		; R reg
	ld r,a
	ld a,(sna_header+25)		; interrupt mode: 0, 1, or 2 (already in IM 1)
	or a
	jr nz,not_im0
	im 0				; set IM 0
not_im0	cp 2
	jr nz,not_im2
	im 2				; set IM 2
not_im2	ld a,(sna_header+26)			
	out (254),a			; set border colour

	ld a,(sna_header+19)		; Interrupt (bit 2 contains IFF2, 1=EI/0=DI)
	bit 2,a				; Start without final EI if IFF2 bit clear
	jr z,irq_off
	ld sp,sna_header+21		; AF reg
	pop af
	ld sp,(sna_header+23)		; SP reg		
	ei				; Enable interrupts before restart
	jp restart_jp			; restart program (M1 @ $fff0 starts switchover to Spectrum)		

irq_off	ld sp,sna_header+21		; AF reg
	pop af
	ld sp,(sna_header+23)		; SP reg		
	jp restart_jp			; restart program (M1 @ $fff0 starts switchover to Spectrum)		



;-------- COPY SPECTRUM 48'S ROM TO 0000-3FFF -------------------------------------------------------------------

restart_48_sna

	ld hl,sna_address		; Copy the sna header data to high RAM buffer		
	ld de,sna_header
	ld bc,27
	ldir

	ld hl,$4000			; copy Original Spectrum 48 ROM from buffer to $0000
	ld de,$0				
	ld bc,$4000
	ldir

	ld sp,$ffc0			; ensures IRQ PC push doesnt overwrite anything important

	ei				; wait until just after Spectrum frame IRQ before restarting snapshot  
	halt
	di
	

;--------- RESTORE REGISTERS AND RESTART 48K SNAPSHOT ------------------------------------------------------------------

	
	ld a,(sna_header)		; I reg
	ld i,a
	ld sp,sna_header+1		; HL',DE',BC',AF'
	pop hl
	pop de
	pop bc
	pop af
	exx
	ex af,af'
	pop hl				; HL,DE,BC,IY,IX
	pop de
	pop bc
	pop iy
	pop ix
	ld a,(sna_header+20)		; R reg
	ld r,a
	ld a,(sna_header+25)		; interrupt mode: 0, 1, or 2 (already in IM 1)
	or a
	jr nz,not_im0b
	im 0				; set IM 0
not_im0b
	cp 2
	jr nz,not_im2b
	im 2				; set IM 2
not_im2b
	ld a,(sna_header+26)			
	and 7
	out (254),a			; set border colour

	ld a,(sna_header+19)		; Interrupt (bit 2 contains IFF2, 1=EI/0=DI)
	bit 2,a				; Start without final EI if IFF2 bit clear
	jr z,irq_offb
	ld sp,sna_header+21		; AF reg
	pop af
	ld sp,(sna_header+23)		; SP reg		
	ei				; Enable interrupts before restart
	jp $66				; restart program with RETN @ $66 (switches to Spectrum ROM)			

irq_offb	

	ld sp,sna_header+21		; AF reg
	pop af
	ld sp,(sna_header+23)		; SP reg		
	jp $66				; restart program with RETN @ $66 (switches to Spectrum ROM)	


;-------------------------------------------------------------------------------------------------

include "Alternative_Configs\Phil\Spectrum_Emulator\z80_code\inc\load_essentials_for_rom_v103.asm"

include "Alternative_Configs\Phil\Spectrum_Emulator\z80_code\inc\serial_routines.asm"


error_msg	

	incbin "Alternative_Configs\Phil\Spectrum_Emulator\z80_code\inc\no_menu_gfx.bin"

;-------------------------------------------------------------------------------------------------


