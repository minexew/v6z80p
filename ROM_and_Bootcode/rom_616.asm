;------------------------------------------------------------------------------------
; V6Z80P ROM code v6.16 - Compile with PASM0. This requires OSCA 660+
;------------------------------------------------------------------------------------
;
; This code is to be included into the actual FPGA configuration file as a ROM located
; at address $0. Its purpose is to initialize the hardware and download the boot code.
; Max size of this ROM code is 512 bytes.

; The bootcode is loaded to $200. 3520 bytes are requested from EEPROM location $0f000,
; if that fails (timeout or CRC check), bootcode backup location $1f000 is tried. If both
; locations fail the bootcode can be loaded serially (115200 baud). Serial load is forced
; immediately if UP+RIGHT+FIRE are selected by joystick in port A. 

;---------------------------------------------------------------------------------------

include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;---------------------------------------------------------------------------------------
	org $0				; CPU reset vector
;---------------------------------------------------------------------------------------

reset	di				; Disable interrupts
	im 1				; Interrupt mode 1
	ld sp,new_rom_stack			; Set stack pointer

	xor a				; A = 0
	ld h,a				; 
	ld l,a				; HL = 0
	out (sys_mem_select),a		; ensure nothing paged in
	out (sys_alt_write_page),a		; video registers paged in at this stage
	out (sys_low_page),a		; ensure lowr page is $00000
	out (sys_irq_enable),a		; zero all IRQ enables
	out (sys_audio_enable),a		; disable sound channels
	out (sys_ps2_joy_control),a		; select joystick A
	out (sys_vram_location),a		; vram @ $2000
	out (sys_timer),a			; timer @ 256 * 256 cycles between overflows + restart
	
	ld (palette),hl			; display = black
	ld (vreg_sprctrl),a			; disable sprites
	
	inc a				; A = 1
	out (sys_hw_settings),a		; Disable NMI switch
	
	ld a,4				
	ld (vreg_vidctrl),a			; disable video
	jr start_delay

;------------------------------------------------------------------------------------------

set_timer

; put timer reload value in A before calling, remember - timer counts upwards!

	out (sys_timer),a			; load and restart timer
	ld a,%00000100
	jr clr_tirq			; clear timer overflow flag

;------------------------------------------------------------------------------------------
	
test_timer

; zero flag is set on return if timer has not overflowed

	in a,(sys_irq_ps2_flags)		; check for timer overflow..
	and 4
	ret z	
clr_tirq	out (sys_clear_irq_flags),a		; clear timer overflow flag
	ret
		

;----------------------------------------------------------------------------------------
	org $38
;----------------------------------------------------------------------------------------
	
	jp irq_jp_inst		

;----------------------------------------------------------------------------------------

palette_pause_500ms				
	
	ld (palette),hl			; change background colour to HL
				
pause_500ms

	ld b,128				; wait 0.5 seconds
phs_lp	xor a				; set timer to count 256 x 65536 cycles
	call set_timer
pause_lp	call test_timer
	jr z,pause_lp
	djnz phs_lp
	
	ld h,b				; then change background to black
	ld l,b
	ld (palette),hl
	ret	
	
;----------------------------------------------------------------------------------------

start_delay

	ld a,%01011010			; set audio channels as original system
	out (sys_audio_panning),a
					
sdlp	inc hl				; wait ensures config PIC is ready for commands
	ld a,h				; (HL will be zero going in..)
	or l
	jr nz,sdlp
	
	in a,(sys_joy_com_flags)		; if UP, RIGHT + FIRE skip EEPROM bootcode test
	and %00111111
	cp  %00011001
	jp z,serial_bcode
	jr eeprom_bcode
			
;----------------------------------------------------------------------------------------
	org $66		
;----------------------------------------------------------------------------------------
	
	jp nmi_jp_inst			; NMI interrupt vector
	
	
;-----------------------------------------------------------------------------------------
;-------- DOWNLOAD BOOT CODE FROM EEPROM -------------------------------------------------	
;-----------------------------------------------------------------------------------------

eeprom_bcode

	ld a,$80
	out (sys_alt_write_page),a		; page out the video registers (allow read/writes to sysRAM $200-$7ff)

	ld e,2				; attempts
	ld hl,databurst_sequence1		; tell PIC to send 3520 bytes from EEPROM addr $4800
init_db	push de
	in a,(sys_eeprom_byte)		; clear shift reg count with a read
	ld b,12
init_dblp	ld a,(hl)
	call send_byte_to_pic
	inc hl
	djnz init_dblp

	ld hl,$ffff			; init CRC value
	exx
	ld hl,new_bootcode_location		; download loop.. 
	ld bc,new_bootcode_length-2		                 
nxt_byte	call get_eeprom_byte		; get byte from EEPROM
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
	call get_eeprom_byte
	jr c,to_error
	djnz getcrc_lp
	pop de
	ld b,a	
	xor a
	sbc hl,bc				; compare computed CRC to that in file
	jp z,new_bootcode_location		; start bootcode if equal	
	
	ld h,$0f				; if failed flash display 
dl_error	ld l,h				
	xor a
	out (sys_pic_comms),a		; ensure clock line is low ready for next attempt
	call palette_pause_500ms		; green = time out, magenta = crc error	
	dec e				; if already tried backup location, allow serial load bootcode
	jr z,serial_bcode			
	ld hl,databurst_sequence2		; try backup bootcode location
	jr init_db

to_error	pop de
	ld h,$f0
	jr dl_error			; if waited about 1 second, timeout

;-------------------------------------------------------------------------------------------------------------
	
get_eeprom_byte	

	ld d,0				; D counts timer overflows
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
;------- DOWNLOAD BOOTCODE SERIALLY --------------------------------------------------------
;-------------------------------------------------------------------------------------------

serial_bcode	

	ld a,$80
	out (sys_alt_write_page),a		; page out the video registers (allow read/writes to sysRAM $200-$7ff)

	ld hl,$555
	ld (palette),hl			; display = grey = serial download mode
		
	ld a,1
	out (sys_baud_rate),a		; use 115200 baud
	in a,(sys_serial_port)		; clear serial buffer flag by reading port

serhdrlp	ld hl,new_bootcode_location
	call s_getblock			; get header block 
	jr c,serhdrlp			; if CF set, Timed out waiting: Retry.
	jr z,shdr_ok			; if ZF set, all OK
s_bad	ld de,$5858			; otherwise checksum bad: send "XX" to host to
	call send_serial_bytes		; stop file transfer.
	ld hl,$f00
	call palette_pause_500ms		; Comms error: flash screen red and reset 
	rst 0
	
shdr_ok	call s_goodack			; send "OK" to start the first block transfer
	ld hl,new_bootcode_location		; HL = Address to load OS to
	ld de,(new_bootcode_location+17)	; Number of blocks to load
	ld a,(new_bootcode_location+16)
	or a
	jr z,s_gbloop
	inc de
s_gbloop	call s_getblock
	jr c,s_bad
	jr nz,s_bad
	call s_goodack			; send "OK" to acknowledge block received OK	
	dec de
	ld a,d
	or e
	jr nz,s_gbloop
	jp new_bootcode_location		; Loaded OK, run the code

	
;----------------------------------------------------------------------------------------------
; SERIAL CODE
;-----------------------------------------------------------------------------------------------

s_getblock

; Loads a block of 256 bytes to HL (L must be 0), and 2 extra bytes for CRC checksum
; Zero flag set = All OK. Zero flag not set = CRC error
; Carry flag is set = timed out

; NOTE: Bank switching / overflow from $ffff test is not performed in this ROM-based version

	ld c,0
	exx
	ld hl,$ffff			; initial CRC checksum value
	exx
s_lgb	call receive_serial_byte
	ret c				; timed out if carry = 1	
	
	push hl				; if destination > $0fc0 dont write the byte to
	push de
	ld de,new_bootcode_location+$0dc0	; memory as it'll overwrite stack data
	scf
	ccf
	sbc hl,de
	pop de
	pop hl
	jr nc,dwrbyte
	
	ld (hl),a
dwrbyte	call crc_calc
	inc hl				; hl = next dest address for data bytes
	dec c
	jr nz,s_lgb
	exx				; hl = calculated CRC

	call receive_serial_byte		; get 2 more bytes - block checksum in bc
	ret c
	ld c,a
	call receive_serial_byte
	ret c		
	ld b,a
	
	xor a				; compare checksum
	sbc hl,bc
	exx				; put address back in HL before exit
	ret z

	xor a
	inc a				; Zero flag not set = CRC error
	ret

	
;-------------------------------------------------------------------------------------------


crc_calc
	exx
	xor h				; do CRC calculation from A, to 'HL		
	ld h,a				
	ld b,8
rxcrcbyte	add hl,hl
	jr nc,rxcrcnext
	ld a,h
	xor 10h
	ld h,a
	ld a,l
	xor 21h
	ld l,a
rxcrcnext	djnz rxcrcbyte
	exx
	ret

		
;--------------------------------------------------------------------------------------------


s_goodack	push de
	ld de,$4f4b			; send "OK" ack to host
	call send_serial_bytes
	pop de
	ret


;---------------------------------------------------------------------------------------------
		

receive_serial_byte
	
	ld b,0
wait_sb	in a,(sys_joy_com_flags)		; if bit 6 of status flags = 1, byte is in buffer 
	bit 6,a
	jr nz,sbyte_in
	in a,(sys_irq_ps2_flags)
	and 4				; if bit 2 of status flags = 1, timer has overflowed
	jr z,wait_sb
	out (sys_clear_irq_flags),a		; clear timer overflow flag
	djnz wait_sb				
	scf 				; time out after 1 second
	ret
sbyte_in	in a,(sys_serial_port)		; get serial byte in A - this also clears bit 6 of status flags
	or a			
	ret
	
	
;------------------------------------------------------------------------------------------------

send_serial_bytes

; set D to the first byte to send
; and E to the second byte to send

	ld c,2
s_wait	in a,(sys_joy_com_flags)		; ensure no byte is still being transmitted
	bit 7,a
	jr nz,s_wait
	ld a,d
	out (sys_serial_port),a
	ld b,32				; limit send speed (gap between bytes)
ssplim	djnz ssplim
	ld d,e
	dec c
	jr nz,s_wait
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
	
	db 0,"ROM616"			; just ID bytes - not essential