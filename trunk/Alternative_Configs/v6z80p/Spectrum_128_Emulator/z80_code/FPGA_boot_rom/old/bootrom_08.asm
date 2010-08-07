;---------------------------------------------------------------------------------------
; V6Z80P Spectrum 48 / 128 FPGA ROM v0.08 - minimal boot loader
;---------------------------------------------------------------------------------------

mem_bank_port	equ 249			; in menu mode (IE: Spectrum code not running)

user_code		equ $0800

fs_sector_buffer	equ $3c00
fs_vars		equ $3e00
stack	    	equ $3fc0

msg_time		equ $3fe4
sna_address   	equ $3fe5			; IE: $4000 less 27 bytes (.sna header)
sna_header    	equ $ff00			; in buffer RAM page (not normal spectrum RAM)
restart_jp	equ $fff0

;----------------------------------------------------------------------------------------------
; File system variables
;----------------------------------------------------------------------------------------------

fs_cluster_size		equ fs_vars+0	
fs_fat1_loc_lba		equ fs_vars+1 
fs_root_dir_loc_lba		equ fs_vars+3 
fs_root_dir_sectors		equ fs_vars+5 
fs_file_length_working	equ fs_vars+7 
fs_file_working_cluster	equ fs_vars+11
fs_z80_working_address	equ fs_vars+13
fs_working_sector		equ fs_vars+15
fs_directory_cluster	equ fs_vars+17
fs_dir_entry_sector		equ fs_vars+19
fs_dir_entry_cluster	equ fs_vars+20
fs_dir_entry_line_offset	equ fs_vars+22
load_address		equ fs_vars+24
sector_lba0 		equ fs_vars+26
sector_lba1		equ fs_vars+27
sector_lba2		equ fs_vars+28
sector_lba3		equ fs_vars+29
mmc_sdc			equ fs_vars+30			
fs_filename		equ fs_vars+31 ; 16 bytes

;---------------------------------------------------------------------------------------
	org $0				; CPU reset vector
;---------------------------------------------------------------------------------------

reset	di				; Disable interrupts
	im 1				; Interrupt mode 1
	ld sp,stack			; Set stack pointer low in memory

	xor a
	out (254),a			; Border = black
	out (mem_bank_port),a		; Actual Spectrum memory selected @ $4000-$ffff
	jr start1
	
;---------------------------------------------------------------------------------------
; KERNAL JUMP TABLE
;---------------------------------------------------------------------------------------

	org $10
	
kjt_check_format		jp fs_check_format		;$10
kjt_load_file		jp fs_load_file		;$13
kjt_change_dir		jp fs_change_dir		;$16
kjt_parent_dir		jp fs_parent_dir		;$19
kjt_root_dir		jp fs_root_dir		;$1c
kjt_goto_first_dir_entry	jp fs_goto_first_dir_entry	;$1f
kjt_fs_get_dir_entry	jp fs_get_dir_entry		;$22
kjt_goto_next_dir_entry	jp fs_goto_next_dir_entry	;$25
kjt_restart_128_sna		jp restart_128_sna		;$28
kjt_restart_48_sna		jp restart_48_sna		;$2b
		
;----------------------------------------------------------------------------------------
	org $38
;----------------------------------------------------------------------------------------
	
	ei
	reti				; IRQ interrupt vector

;----------------------------------------------------------------------------------------


start1	xor a				; set ROM 0 / page 0 (this port is reset
	ld bc,$7ffd			; in hardware on ESC from Spectrum mode also..)
	out (c),a
	
	ld de,8				; Clear AY Amplitude registers
clrsnd	ld b,$ff
	out (c),e				; select reg
	ld b,$bf
	out (c),d				; write data to reg
	inc e
	ld a,e
	cp $0b
	jr nz,clrsnd
	
	jr start2

;----------------------------------------------------------------------------------------
	org $66		
;----------------------------------------------------------------------------------------
	
	retn				; NMI interrupt vector

;----------------------------------------------------------------------------------------

fill_mem	ld e,a
fm_loop	ld (hl),e
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,fm_loop
	ret
	

;---- LOOK FOR USERCODE.EXE ON DISK -----------------------------------------------------	


start2	ld hl,$4000			; fill vram with zeroes
	ld bc,$1800
	xor a
	call fill_mem
	ld bc,$300			; default attributes
	ld a,7
	call fill_mem
	
	call fs_check_format		; is SD card inserted and FAT16?
	jr nz,no_disk

	ld hl,spectrum_txt			; change to "spectrum" subdir from ROOT
	call fs_change_dir
	jr nz,no_disk
	
	ld hl,usercode_txt			; Load user bootcode: "usercode.exe" to $800
	ld de,user_code
	xor a
	call fs_load_file
	jp z,user_code


;------- SHOW NO USERCODE MESSAGE -------------------------------------------------------

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

	
;------- WAIT FOR SERIAL DOWNLOAD OF USER CODE ---------------------------------------------------

	di

	ld hl,serial_header			; load file header block
	call s_getblock			
	jp c,s_bad			; if carry set, there was an error / checksum was bad
	call s_goodack			; send "OK" to start the first block transfer

	ld hl,user_code			; HL = Address at which to load usercode 
	ld de,(serial_header+17)		; Number of blocks to load
	ld a,(serial_header+16)
	or a
	jr z,s_gbloop
	inc de
s_gbloop	call s_getblock
	jr c,s_bad
	call s_goodack			; send "OK" to acknowledge block received OK	
	dec de
	ld a,d
	or e
	jr nz,s_gbloop
	jp user_code

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

	ld hl,sna_address			; copy sna header info to buffer area
	ld de,sna_header
	ld bc,27
	ldir

	ld hl,$4000			; copy first ROM (Spectrum 128: 0) from buffer RAM 
	ld de,$0				; $4000-$7fff to $0-$3fff
	ld bc,$4000
	ldir

	ld a,16				; set ROM 1 / page 0 
	ld bc,$7ffd
	out (c),a

	ld de,$0				; copy second ROM (Spectrum 128:1) from buffer RAM 01
	ld bc,$4000			; $8000-$bfff to $0-$3fff
	ldir

	ld a,(restart_jp+4)			; set snapshot's restart ROM / page 
	ld bc,$7ffd
	out (c),a
	ei			
	halt
	di				; wait until just after an IRQ
	
	
;--------- RESTORE SNAPSHOT'S REGISTERS AND RESTART 128K SNAPSHOT CODE --------------------------------


	ld a,(sna_header)			;I reg
	ld i,a
	ld sp,sna_header+1			;HL',DE',BC',AF'
	pop hl
	pop de
	pop bc
	pop af
	exx
	ex af,af'
	pop hl				;HL,DE,BC,IY,IX
	pop de
	pop bc
	pop iy
	pop ix
	ld a,(sna_header+20)		;R reg
	ld r,a
	ld a,(sna_header+25)		;interrupt mode: 0, 1, or 2 (already in IM 1)
	or a
	jr nz,not_im0
	im 0				;set IM 0
not_im0	cp 2
	jr nz,not_im2
	im 2				;set IM 2
not_im2	ld a,(sna_header+26)			
	out (254),a			;set border colour

	ld a,(sna_header+19)		;Interrupt (bit 2 contains IFF2, 1=EI/0=DI)
	bit 2,a				;Start without final EI if IFF2 bit clear
	jr z,irq_off
	ld sp,sna_header+21			;AF reg
	pop af
	ld sp,(sna_header+23)		;SP reg		
	ei				;Enable interrupts before restart
	jp restart_jp			;restart program (M1 @ $fff0 starts switchover to Spectrum)		

irq_off	ld sp,sna_header+21			;AF reg
	pop af
	ld sp,(sna_header+23)		;SP reg		
	jp restart_jp			;restart program (M1 @ $fff0 starts switchover to Spectrum)		



;-------- COPY SPECTRUM 48'S ROM TO 0000-3FFF -------------------------------------------------------------------

restart_48_sna

	ld hl,sna_address			; Copy the sna header data to high RAM buffer		
	ld de,sna_header
	ld bc,27
	ldir

	ld hl,$4000			; copy Original Spectrum 48 ROM from buffer to $0000
	ld de,$0				; no stack ops beyond this point!
	ld bc,$4000
	ldir

	ei
	halt
	di
	

;--------- RESTORE REGISTERS AND RESTART 48K SNAPSHOT ------------------------------------------------------------------

	
	ld a,(sna_header)			;I reg
	ld i,a
	ld sp,sna_header+1			;HL',DE',BC',AF'
	pop hl
	pop de
	pop bc
	pop af
	exx
	ex af,af'
	pop hl				;HL,DE,BC,IY,IX
	pop de
	pop bc
	pop iy
	pop ix
	ld a,(sna_header+20)		;R reg
	ld r,a
	ld a,(sna_header+25)		;interrupt mode: 0, 1, or 2 (already in IM 1)
	or a
	jr nz,not_im0b
	im 0				;set IM 0
not_im0b	cp 2
	jr nz,not_im2b
	im 2				;set IM 2
not_im2b	ld a,(sna_header+26)			
	out (254),a			;set border colour

	ld a,(sna_header+19)		;Interrupt (bit 2 contains IFF2, 1=EI/0=DI)
	bit 2,a				;Start without final EI if IFF2 bit clear
	jr z,irq_offb
	ld sp,sna_header+21			;AF reg
	pop af
	ld sp,(sna_header+23)		;SP reg		
	ei				;Enable interrupts before restart
	ld a,0
	out (mem_bank_port),a
	jp $66				;restart program with RETN (switches to Spectrum ROM)		

irq_offb	ld sp,sna_header+21			;AF reg
	pop af
	ld sp,(sna_header+23)		;SP reg		
	ld a,0
	out (mem_bank_port),a
	jp $66				;restart program with RETN (switches to Spectrum ROM)		

;-------------------------------------------------------------------------------------------------

include "load_essentials_for_rom.asm"

include "serial_routines.asm"

;-------------------------------------------------------------------------------------------------

spectrum_txt	db "spectrum",0
usercode_txt	db "usercode.exe",0

;-------------------------------------------------------------------------------------------------

error_msg		incbin "no_usercode_gfx.bin"

;-------------------------------------------------------------------------------------------------


