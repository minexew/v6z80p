;******************************************
; FPGA config updater v0.06 for PROSE/EZ80P
;******************************************

;----------------------------------------------------------------------------------------------

amoeba_version_req	equ	0				; 0 = dont care about HW version
prose_version_req	equ 0				; 0 = dont care about OS version
ADL_mode			equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location		equ 10000h			; anywhere in system ram

			include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

first_run		ld a,kr_clear_screen
				call.lil prose_kernal
				ld hl,app_msg
				call print_string

				in0 a,(port_pic_data)						; clear PIC receive buffer
			
				call short_pause

				call get_slot_count
						
				call get_boot_slot
				jp c,timeout
				ld (boot_slot),a
				inc a
				ld (target_slot),a
				ld hl,slot_count
				cp (hl)
				jr nz,go_slots
				xor a
				ld (target_slot),a
				jr go_slots

begin_app		ld a,kr_clear_screen
				call.lil prose_kernal
				
				ld hl,app_msg
				call print_string

go_slots		ld hl,slots_txt
				call print_string
				call show_slots
				
				ld hl,ascii_hex								;show target slot
				ld a,(target_slot)
				ld e,a
				ld a,kr_hex_byte_to_ascii
				call.lil prose_kernal
				ld hl,target_slot_txt
				call print_string
				ld hl,ascii_hex
				call print_string

				ld hl,ascii_hex								;show boot slot
				ld a,(boot_slot)
				ld e,a
				ld a,kr_hex_byte_to_ascii
				call.lil prose_kernal
				ld hl,boot_slot_txt
				call print_string
				ld hl,ascii_hex
				call print_string

					
				call get_sr
				jp c,timeout
				ld (current_sr),a
				ld hl,ascii_hex								;show sr
				ld a,(current_sr)
				ld e,a
				ld a,kr_hex_byte_to_ascii
				call.lil prose_kernal
				ld hl,sr_txt
				call print_string
				ld hl,ascii_hex
				call print_string
				
				call show_fw								;show fw
				jp c,timeout
				ld hl,ascii_hex
				ld e,a
				ld a,kr_hex_byte_to_ascii
				call.lil prose_kernal
				ld hl,firmware
				call print_string
				ld hl,ascii_hex
				call print_string
						
				ld hl,cr_txt
				call print_string

;-------------------------------------------------------------------------------------------------
;Menu
;-------------------------------------------------------------------------------------------------
		
				ld hl,menu_txt
				call print_string
			
menu			ld a,kr_wait_key
				call.lil prose_kernal
				cp 76h
				jr z,quit
				ld a,b
				cp 'c'
				jp z,select_target_slot
				cp 'r'
				jp z,reconfigure_from_target_slot
				cp 'm'
				jp z,make_slot_active
				cp 'w'
				jp z,download_write
				cp 'e'
				jp z,opt5_erase_slot
				cp 's'
				jp z,set_protection_bits
				
				jr menu
quit			xor a
				jp prose_return
				
;-------------------------------------------------------------------------------------------------

select_target_slot

				ld hl,select_slot_txt
				call print_string
ss_waitk		ld a,kr_get_string	
				call.lil prose_kernal
				or a
				jp z,begin_app
				ld a,kr_ascii_to_hex_word					; returns de = slot number
				call.lil prose_kernal
				or a
				jp nz,begin_app
				ld a,(slot_count)
				dec a
				cp e
				jp c,begin_app
				ld a,e
				ld (target_slot),a
				
				ld a,(boot_slot)
				ld hl,target_slot
				cp (hl)
				jr nz,sltok
				ld hl,bs_conf_txt
				call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				ld a,b
				cp 'y'
				jr z,sltok
				
				ld hl,target_slot
				inc (hl)
				ld a,(slot_count)
				cp (hl)
				jr nz,sltok
				ld (hl),0

sltok			jp begin_app

;-------------------------------------------------------------------------------------------------

reconfigure_from_target_slot

				ld a,088h									; set the temp config address
				call send_byte_to_pic
				ld a,0b8h
				call send_byte_to_pic
				ld a,016h		
				call send_byte_to_pic
				ld a,(target_slot)	
				call send_byte_to_pic
				call get_byte_from_pic
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				ld a,088h									; reconfig now
				call send_byte_to_pic
				ld a,0a1h
				call send_byte_to_pic
				ld a,03fh		
				call send_byte_to_pic
				ld a,062h	
				call send_byte_to_pic
				call pause
				jp begin_app

;-------------------------------------------------------------------------------------------------

make_slot_active

				ld de,0										; known config in this slot?
				ld a,(target_slot)
				ld e,a
				ld hl,slots_valid
				add hl,de
				ld a,(hl)
				or a
				jr nz,slotval
				ld hl,noconf_txt							; nope! So confirm action.
				call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				ld a,b
				cp 'y'
				jp nz,begin_app

slotval			ld a,088h									; set the temp config address
				call send_byte_to_pic
				ld a,0b8h
				call send_byte_to_pic
				ld a,016h		
				call send_byte_to_pic
				ld a,(target_slot)	
				call send_byte_to_pic
				call get_byte_from_pic
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				call enable_pic_writes
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				
				ld a,088h									; make the config address active
				call send_byte_to_pic
				ld a,037h
				call send_byte_to_pic
				ld a,0d8h		
				call send_byte_to_pic
				ld a,006h		
				call send_byte_to_pic
				call get_byte_from_pic
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				
				call disable_pic_writes
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				
				call get_boot_slot
				jp c,timeout
				ld (boot_slot),a
				
				ld hl,bs_done
				call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin_app
				
;-------------------------------------------------------------------------------------------------

download_write
				ld hl,buffer
				ld bc,256*1024
				ld a,0ffh
clbuflp			ld (hl),a
				cpi
				jp pe,clbuflp
				
				ld hl,write_cfg
				call print_string
				
				ld hl,input_string
				ld (fn_addr),hl
				ld e,12
				ld a,kr_get_string	
				call.lil prose_kernal
				jp nz,serial_dl
								
				ld a,kr_find_file
				call.lil prose_kernal
				jp nz,load_error
				ld hl,buffer
				ld a,kr_read_file
				call.lil prose_kernal
				jp nz,load_error
				ld hl,cr_txt
				call print_string
				ld hl,cr_txt
				call print_string			
				jp dl_done
				

serial_dl		ld hl,download
				call print_string

get_hdr_loop	ld e,1										;tenths of a second before timeout
				ld hl,filename
				ld a,kr_serial_receive_header
				call.lil prose_kernal
				or a
				jr z,got_header
				
				cp 083h										;time out error?
				jr nz,comms_error
				ld a,kr_get_key
				call.lil prose_kernal
				cp 076h										;esc to abort
				jr nz,get_hdr_loop
				jp begin_app
				
got_header		ld (fn_addr),ix
				ld hl,receiving								; receiving
				call print_string

				ld a,kr_serial_receive_file
				ld hl,buffer
				call.lil prose_kernal
				jp nz,comms_error

dl_done			ld hl,(fn_addr)
				ld de,buffer+01ff90h						; append filename to config (start of slot+1ff90h)
				ld b,16
cfnlp			ld a,(hl)
				ld (de),a
				or a
				jr z,cfnd
				inc hl
				inc de
				djnz cfnlp
				xor a
				ld (de),a
cfnd

				call erase_slot
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				call check_erasure
				jp c,timeout
				jp nz,bad_erase
				


				call enable_pic_writes
				ret c
				cp 0
				ret nz

				ld hl,writing									; writing slot..	
				call print_string
				ld hl,buffer
				ld de,0
				ld a,(target_slot)
				sla a
				ld d,a											; page number
				ld bc,0200h										; pages to go 
lp1				push de
				push bc
				call write_eeprom_page
				pop bc
				pop de
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				inc de											;next page
				dec bc
				ld a,b
				or c
				jr nz,lp1

				call disable_pic_writes
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
			




				ld a,088h									; send "set up databurst address" command
				call send_byte_to_pic
				ld a,0d4h
				call send_byte_to_pic
				ld a,000h			
				call send_byte_to_pic						; send address low
				ld a,000h	
				call send_byte_to_pic						; send address mid
				ld a,(target_slot)
				sla a
				call send_byte_to_pic						; send address high

				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				ld a,088h									;send "set up databurst length" command
				call send_byte_to_pic
				ld a,0e2h
				call send_byte_to_pic
				ld a,00h			
				call send_byte_to_pic						;send len low
				ld a,00h	
				call send_byte_to_pic						;send len mid
				ld a,02h
				call send_byte_to_pic						;send len high (20000h bytes)
	
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				ld hl,verifying								; read back data..	
				call print_string

				ld a,088h									;send "start databurst" command
				call send_byte_to_pic
				ld a,0c0h
				call send_byte_to_pic
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				ld hl,buffer+020000h
				ld de,0
lp2				ld a,01h
				ld bc,port_pic_ctrl
				out (bc),a									; data out hi - pic responds by sending byte
				call get_byte_from_pic
				jp c,timeout
				ld (hl),a
				inc hl

				ld a,00h
				ld bc,port_pic_ctrl
				out (bc),a									; data out low - pic responds by sending next byte
				call get_byte_from_pic
				jp c,timeout
				ld (hl),a
				inc hl
				dec de
				ld a,d
				or e
				jr nz,lp2




				ld hl,buffer								;compare read back data to that which was written
				ld de,buffer+020000h
				ld b,0
lp4				push bc
				ld bc,0h
lp3				ld a,(de)
				cp (hl)
				jr nz,ver_bad
				inc hl
				inc de
				inc bc
				ld	a,b
				or c
				jr nz,lp3
				pop bc
				inc b
				ld a,b
				cp 2
				jr nz,lp4

				ld hl,completed								
				call print_string
				
				ld a,kr_wait_key
				call.lil prose_kernal
end_prog		jp begin_app

ver_bad			pop bc
				push hl
				push de
				ld hl,ver_fail
				call print_string
				ld hl,written
				call print_string
				pop de
				pop hl
				ld (bad_addr),de
				call show_mem							; shows HL (written) first
				ld hl,readback
				call print_string
				ld hl,(bad_addr)
				call show_mem							; then data read back
				
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin_app


;---------------------------------------------------------------------------------------

opt5_erase_slot

				call erase_slot
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				
				call check_erasure
				jp c,timeout
				ld hl,erase_ok_txt
				jr z,erase_ok
bad_erase		ld hl,erase_bad_txt
erase_ok		call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin_app			
				
;--------------------------------------------------------------------------------------

set_protection_bits

				ld hl,enter_sr_txt
				call print_string
				ld a,kr_get_string	
				call.lil prose_kernal
				or a
				jp z,begin_app
				ld a,kr_ascii_to_hex_word					; returns de = slot number
				call.lil prose_kernal
				or a
				jp nz,begin_app

				ld a,e
				ld (new_sr),a
				
				call enable_pic_writes
				jp c,timeout
				cp 0
				jp nz,bad_pic_response
				
				ld a,088h									; set SR command
				call send_byte_to_pic
				ld a,08bh
				call send_byte_to_pic
				ld a,08bh
				call send_byte_to_pic
				ld a,(new_sr)	
				call send_byte_to_pic
				
				call get_byte_from_pic						; wait for OK ack
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				call disable_pic_writes
				jp c,timeout
				cp 0
				jp nz,bad_pic_response

				ld hl,sr_set_txt
				call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin_app
				
;---------------------------------------------------------------------------------------

bad_pic_response
				
				ld hl,ascii_hex
				call hex_byte_to_ascii
				ld hl,report_byte
				call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin_app

timeout			ld hl,timeout_msg
				call print_string
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin_app



				

;--------- EEPROM SUBROUTINES ----------------------------------------------------------

write_eeprom_page

				ld a,d
				ld (page_hi),a
				ld a,e
				ld (page_med),a

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,098h
				call send_byte_to_pic
				ld a,000h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high

				ld b,64								;send 64 byte data packet to burn
wdplp1			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz wdplp1
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret c
				or a
				ret nz

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,098h
				call send_byte_to_pic
				ld a,040h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high
 
				ld b,64								;send 64 byte data packet to burn
wdplp2			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz wdplp2
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret c
				or a
				ret nz

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,098h
				call send_byte_to_pic	
				ld a,080h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high

				ld b,64								;send 64 byte data packet to burn
wdplp3			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz wdplp3
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret c
				or a
				ret nz

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,098h
				call send_byte_to_pic
				ld a,0c0h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high

				ld b,64								;send 64 byte data packet to burn
wdplp4			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz wdplp4
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret
				
;-------------------------------------------------------------------------------------------------------

new_write_eeprom_page

				ld a,d
				ld (page_hi),a
				ld a,e
				ld (page_med),a

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,099h
				call send_byte_to_pic
				ld a,000h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high
				ld a,128
				call send_byte_to_pic				;send number of bytes in packet

				ld b,128							;send 128 byte data packet to burn
nwdplp1			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz nwdplp1
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret c
				or a
				ret nz

				ld a,088h							;send "write to EEPROM" command
				call send_byte_to_pic
				ld a,099h
				call send_byte_to_pic
				ld a,080h			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high
				ld a,128
				call send_byte_to_pic				;send number of bytes in packet

				ld b,128							;send 128 byte data packet to burn
nwdplp2			ld a,(hl)
				call send_byte_to_pic
				inc hl
				djnz nwdplp2
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				ret 


;-------------------------------------------------------------------------------------------------------

read_eeprom_page

				push hl								;put page number to read to buffer in DE
				push de
				push bc
	
				ld a,d
				ld (page_hi),a
				ld a,e
				ld (page_med),a
		
				ld a,88h							;send "set databurst location" command
				call send_byte_to_pic
				ld a,0d4h
				call send_byte_to_pic
				ld a,0			
				call send_byte_to_pic				;send address low
				ld a,(page_med)	
				call send_byte_to_pic				;send address mid
				ld a,(page_hi)
				call send_byte_to_pic				;send address high
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				jr c,t_o
				cp 0
				jr nz,bpr
		
				ld a,88h							;send "set databurst location" command
				call send_byte_to_pic
				ld a,0e2h
				call send_byte_to_pic
				ld a,00			
				call send_byte_to_pic				;send length low
				ld a,01		
				call send_byte_to_pic				;send length mid
				ld a,00
				call send_byte_to_pic				;send length high
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				jr c,t_o
				cp 0
				jr nz,bpr

			
				ld a,88h							;send "start databurst" command
				call send_byte_to_pic
				ld a,0c0h
				call send_byte_to_pic
				call get_byte_from_pic				; pic should respond with 0x00 (OK)
				jr c,t_o
				cp 0
				jr nz,bpr

			
				ld hl,buffer
				ld b,128
rplp2			ld a,01h
				out0 (port_pic_ctrl),a			; data out hi - pic responds by sending byte
				call get_byte_from_pic
				jr c,t_o
				ld (hl),a
				inc hl
				ld a,00h
				out0 (port_pic_ctrl),a			; data out low - pic responds by sending next byte
				call get_byte_from_pic
				jr c,t_o
				ld (hl),a
				inc hl
				djnz rplp2

				xor a
				pop bc
				pop de
				pop hl
				ret

bpr				scf
				pop bc
				pop de
				pop hl
				ret

t_o				xor a
				scf
				pop bc
				pop de
				pop hl
				ret	
;-------------------------------------------------------------------------------------------------------

comms_error	
				ld hl,com_error
				call print_string

				call pause
				
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin_app

load_error	
				ld hl,load_error_txt
				call print_string

				call pause
				
				ld a,kr_wait_key
				call.lil prose_kernal
				jp begin_app
				
;-------------------------------------------------------------------------------------------------------

enable_pic_writes

;				ld hl,enable_wr								; enable eeprom writes..	
;				call print_string

				ld a,088h									; 88,25,fa,99 = enable programming (red led on)
				call send_byte_to_pic
				ld a,025h
				call send_byte_to_pic
				ld a,0fah
				call send_byte_to_pic
				ld a,099h
				call send_byte_to_pic

				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret

;-------------------------------------------------------------------------------------------------------

disable_pic_writes

;				ld hl,disable_wr							; disable eeprom writes..	
;				call print_string

				ld a,088h									; 88,1f = disable programming (green led on)
				call send_byte_to_pic
				ld a,01fh
				call send_byte_to_pic

				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret
				
;-------------------------------------------------------------------------------------------------------
	
get_byte_from_pic

; Returns byte in A. If carry set, wait timed out.

				push de
				push bc
				ld b,32
				ld de,0
pcwbib			in0 a,(port_hw_flags)
				and 1										;check bit 0 (buffer status) if set, a byte has been received
				jr nz,pcbib
				dec de
				ld a,d
				or e
				jr nz,pcwbib
				djnz pcwbib
				pop bc
				pop de
				scf											; carry flag set = timed out
				ret

pcbib			in0 a,(port_pic_data)						; get the byte - this clears the buffer flag
				or a										; clear carry
				pop bc
				pop de
				ret

;------------------------------------------------------------------------------------------	

send_byte_to_pic

; put byte to send in A
						
														
				push af
				xor a
				out0 (port_pic_ctrl),a					; ensure data_out is not being forced high 

wpbusy			in0 a,(port_hw_flags)						; check bit 2 to ensure output serializer is not busy
				and 4
				jr nz,wpbusy

				pop af
				out0 (port_pic_data),a
				ret


;				ld b,0										; force a short delay between bytes
;pdswlp			djnz pdswlp						
;				pop bc											
;				ret


;-------------------------------------------------------------------------------------------

show_mem	

; set hl to address to show

				ld b,16
shmlp			ld (show_addr),hl
				push bc
				call show_mline
				pop bc
				ld hl,(show_addr)
				ld de,16
				add hl,de
				djnz shmlp
				ret


show_mline		ld a,(show_addr+2)
				ld hl,mem_line
				call hex_byte_to_ascii
				ld a,(show_addr+1)
				call hex_byte_to_ascii
				ld a,(show_addr)
				call hex_byte_to_ascii
				inc hl
				ld de,(show_addr)
				ld b,16
smlp			ld a,(de)
				push de
				call hex_byte_to_ascii
				pop de
				inc hl
				inc de
				djnz smlp

				ld hl,mem_line
				call print_string
				ret

;--------------------------------------------------------------------------------------------------

print_string	ld a,kr_print_string
				call.lil prose_kernal
				ret


hex_byte_to_ascii

				ld e,a
				ld a,kr_hex_byte_to_ascii
				call.lil prose_kernal
				ret

;--------------------------------------------------------------------------------------------------
	
pause			ld de,32768							;wait 1 sec
				ld a,kr_time_delay
				call.lil prose_kernal
				ret
				
short_pause		ld de,8192							;wait 0.25 sec
				ld a,kr_time_delay
				call.lil prose_kernal
				ret	
				
;--------------------------------------------------------------------------------------------------
	
show_slots		ld a,0
id_loop			ld (working_slot),a
				ld e,a
				ld hl,slot_hex+1
				ld a,kr_hex_byte_to_ascii
				call.lil prose_kernal
				ld hl,slot_hex
				call print_string
				
				ld hl,0
				ld a,(working_slot)			;read in EEPROM page that contains the ID string
				ld h,a
				add hl,hl
				ld de,01ffh
				add hl,de
				ex de,hl
				call read_eeprom_page
				jr c,pic_error
				
				ld hl,buffer+090h			;location of ID (filename ASCII) = start of slot+1ff90h
				ld a,(hl)
				or a
				jr z,unk_id
				bit 7,a
				jr z,id_ok
unk_id			ld hl,unknown_txt
				call print_string
				ld c,0
				jr nxtslot
id_ok			call print_string
				ld c,1
				
nxtslot			ld a,(working_slot)
				ld de,0
				ld e,a
				ld hl,slots_valid
				add hl,de
				ld (hl),c
				
				ld hl,slot_count
				inc a
				cp (hl)
				jr nz,id_loop
				xor a
				ret

	
pic_error		push hl
				push de
				push bc
				ld hl,picerr_txt
				ld e,a
				ld a,kr_hex_byte_to_ascii
				call.lil prose_kernal
				ld hl,picerr_txt
				call print_string
				pop bc
				pop de
				pop hl
				ld c,0
				jr nxtslot
				

;--------------------------------------------------------------------------------------------------

get_slot_count
	
				ld a,088h									; 88,53 = return EEPROM ID code
				call send_byte_to_pic
				ld a,53h
				call send_byte_to_pic
				call get_byte_from_pic						
				ld (eeprom_id),a
				ret c
				sub a,10h							
				inc a
				ld b,a
				ld a,1
scloop			dec b
				jr z,gotsc
				sla a
				jr scloop
gotsc			ld (slot_count),a
				ret

;--------------------------------------------------------------------------------------------------

get_boot_slot				
				ld a,088h									; 88,76 = return boot slot selection
				call send_byte_to_pic
				ld a,76h
				call send_byte_to_pic
				call get_byte_from_pic						;pic should respond with slot byte
				ret


;--------------------------------------------------------------------------------------------------				

get_sr				
				ld a,088h									; 88,76 = return SR
				call send_byte_to_pic
				ld a,06h
				call send_byte_to_pic
				call get_byte_from_pic						
				ret				

;--------------------------------------------------------------------------------------------------				

erase_slot		ld hl,erase									; erase slot..	
				call print_string

				call enable_pic_writes
				ret c
				cp 0
				ret nz
				
				ld a,088h									; send "erase 64KB EEPROM block" command
				call send_byte_to_pic
				ld a,0f5h
				call send_byte_to_pic
				ld a,000h		
				call send_byte_to_pic						; send address low - note: 64KB granularity
				ld a,000h		
				call send_byte_to_pic						; send address mid - note: 64KB granularity
				ld a,(target_slot)
				sla a
				call send_byte_to_pic						; send address high - note: 64KB granularity
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret c
				cp 0
				ret nz

				ld a,088h									; send "erase 64KB EEPROM block" command
				call send_byte_to_pic
				ld a,0f5h
				call send_byte_to_pic
				ld a,000h			
				call send_byte_to_pic						; send address low - note: 64KB granularity
				ld a,000h		
				call send_byte_to_pic						; send address mid - note: 64KB granularity
				ld a,(target_slot)
				sla a
				or 1
				call send_byte_to_pic						; send address high - note: 64KB granularity
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret c 
				cp 0
				ret nz

				call disable_pic_writes
				ret
				
;--------------------------------------------------------------------------------------------------				

check_erasure

				ld hl,chkerase								; verify erase - read back data..	
				call print_string

				ld a,088h									; send "set up databurst address" command
				call send_byte_to_pic
				ld a,0d4h
				call send_byte_to_pic
				ld a,000h			
				call send_byte_to_pic						; send address low
				ld a,000h	
				call send_byte_to_pic						; send address mid
				ld a,(target_slot)
				sla a
				call send_byte_to_pic						; send address high

				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret c
				cp 0
				ret nz

				ld a,088h									; send "set up databurst length" command
				call send_byte_to_pic
				ld a,0e2h
				call send_byte_to_pic
				ld a,00h			
				call send_byte_to_pic						; send len low
				ld a,00h	
				call send_byte_to_pic						; send len mid
				ld a,02h
				call send_byte_to_pic						; send address high
	
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret c
				cp 0
				ret nz


				ld a,088h									;send "start databurst" command
				call send_byte_to_pic
				ld a,0c0h
				call send_byte_to_pic
				call get_byte_from_pic						; pic should respond with 0x00 (OK)
				ret c
				cp 0
				ret nz

				ld de,0
lpve			ld a,01h
				ld bc,port_pic_ctrl
				out (bc),a									; data out hi - pic responds by sending byte
				call get_byte_from_pic
				ret c
				cp 0ffh
				ret nz

				ld a,00h
				ld bc,port_pic_ctrl
				out (bc),a									; data out low - pic responds by sending next byte
				call get_byte_from_pic
				ret c
				cp 0ffh
				ret nz

				dec de
				ld a,d
				or e
				jr nz,lpve
				xor a
				ret

;--------------------------------------------------------------------------------------------------------------

show_fw
				ld a,088h									; 88,4e = return PIC firmware version
				call send_byte_to_pic
				ld a,04eh
				call send_byte_to_pic
				call get_byte_from_pic						;pic should respond with FIRMWARE version byte
				ret
				
;--------------------------------------------------------------------------------------------------------------


			
app_msg			db 11,'*********************************',11
				db    '** Config EEPROM Updater V0.06 **',11
				db    '*********************************',11,11,0

go				db 11,"*** Start! ***",11,11,0

write_cfg		db 'Enter Filename or Press ENTER to download config file:',11,11,0
download		db "Waiting for config file.. [Esc to quit]",11,0
receiving		db "Receiving file..",11,0
received		db "File received.",11,0
enable_wr		db "Enabling EEPROM writes..",11,0	
erase			db "Erasing Slot..",11,0
chkerase		db "Checking Erasure..",11,0
writing   	  	db "Writing data to EEPROM..",11,0
disable_wr		db "Disabling EEPROM writes..",11,0
dbaddr			db "Set databurst address..",11,0
dblen			db "Set databurst length..",11,0
databurst		db "Initiating Databurst..",11,0
verifying		db "Verifying data..",11,0
completed		db "Completed OK..",11,0
com_error		db "Comms error! Serial Buffer:",11,0

ver_fail		db 11,"******* Verify failed! *******",11,11,0

pic_ok			db "PIC responds: $00 - OK.",11,0
erase_ok_txt	db "Confirmed: Erased OK.",11,0
erase_bad_txt	db "Error: Erase failed.",11,0

report_byte		db 11,"Error - Received byte $"
ascii_hex		db "xx",11,0
firmware		db "PIC Firmware   : ",0
timeout_msg 	db "Timed out.",11,0

page_hi			db 0
page_med		db 0
page_lo			db 0

show_addr		db 0,0,0
bad_addr		db 0,0,0
mem_line		db "xxyyzz 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ",11,0

boot_slot_txt	db 'Boot up slot   : ',0
target_slot_txt	db 11,11,'Target slot    : ',0
target_slot		db 0
select_slot_txt	db 'Enter target slot number..',0

menu_txt		db 11,'Select:',11
				db    '-------',11,11
				db '[C] - Change target slot',11
				db '[R] - Restart from target slot',11
				db '[M] - Make target slot the default boot slot',11
				db '[W] - Write config file to target slot',11
				db '[E] - Erase target slot',11
				db '[S] - Set EEPROM Status Register (Protection bits)',11
				db 11,'ESC - Quit',11,11,0

cr_txt			db 11,0

filename		db '*',0

written			db 'Data written:',11,0
readback		db 'Data read in:',11,0

slot_count		db 1
working_slot	db 0
slots_txt		db 'Slots:',11
				db '------',11,0
slot_hex		db 11,'xx - ',0
unknown_txt		db 'Unknown / Blank',0

fn_addr			dw24 0

bs_done			db 'OK, boot slot changed..',0
boot_slot		db 0
bs_conf_txt		db 11,11,'Sure you want the target to be the current boot slot? (y/n)',0

picerr_txt		db 'xx <-PIC ERROR CODE',11,0

noconf_txt		db 11,'Warning! Unknown data in this slot. Continue (y/n) ?',11,11,0

eeprom_id		db 0

enter_sr_txt	db 'Enter new hex value for Status Register (Protection bits): ',0
sr_set_txt		db 11,11,'OK. Status Register updated..',0
new_sr			db 0

current_sr		db 0
sr_txt			db 11,'Status Register: ',0

slots_valid		blkb 32,0

input_string	blkb 16,0

load_error_txt	db 11,11,'Load Error.. File not found?',0

;--------------------------------------------------------------------------------------------------
buffer			db 0			; dont put anything after here
;--------------------------------------------------------------------------------------------------

