
system_info	call kjt_clear_screen
	
		ld hl,sys_info_string1
		call kjt_print_string
		
		call read_hw_id					;find PCB type, if possible
		ld a,b
		or a
		jr nz,newosca
		ld hl,pcb_types+1
		jr got_pcb
newosca		ld hl,pcb_types
		ld bc,end_pcb_types-pcb_types
		cpir
got_pcb		call kjt_print_string

		call kjt_get_version				;fill in osca/flos versions
		ld hl,osca
		ld a,d
		and $f						;mask upper bits in case of old FLOS
		ld d,a
		call hex_to_ascii_word
		call kjt_get_version
		ex de,hl
		ld hl,flos
		call hex_to_ascii_word
		
		call kjt_get_version				;fill in OS loaded by bootcode, if possible
		ld a,c
		or a
		jr nz,old_bcode
		ld hl,obcode
		ld e,(ix)
		ld d,(ix+1)
		call hex_to_ascii_word


old_bcode	ld hl,sys_info_string2
		call kjt_print_string	

		call kjt_get_version
		ld a,c
		or a
		jr nz,no_bdev
		ld a,(ix+3)
		ld hl,bootdev_types
		ld bc,end_bootdev_types-bootdev_types
		cpir
		jr z,got_bdev
no_bdev		ld hl,bootdev_types+1
got_bdev	call kjt_print_string

		call show_pic_firmware
		call show_eeprom_type
		call show_active_slot
		
		ld a,0
		call show_eeprom_bootcode
		ld a,1
		call show_eeprom_bootcode
		
		call show_eeprom_os_status
		
		call show_video_mode
		
		ld hl,crlf_txt
		call kjt_print_string
		
		call press_any_key
		ret
		

crlf_txt	db 11,0

;----------------------------------------------------------------------------------------------------------------
		
show_eeprom_bootcode

		ld d,a
		ld hl,pebc_txt
		or a
		jr z,pribc
		ld hl,bebc_txt
pribc		call kjt_print_string
			
		ld e,$fd
		call read_eeprom_page
		ld ix,page_buffer+$bc
		ld e,(ix)
		ld d,(ix+1)
		ld a,d					;if $0000, assume its a version before 617
		or e
		jr nz,ebc_ok1
		ld hl,old_ebc_txt
		call kjt_print_string
		ret
		
ebc_ok1		ld a,d					;if $ffff, assume its blank
		and e
		inc a
		jr nz,ebc_ok2
		ld hl,no_ebc_txt
		call kjt_print_string
		ret
		
ebc_ok2		ld hl,ebc_txt
		push hl
		call hex_to_ascii_word
		pop hl
		call kjt_print_string
		ret

	
pebc_txt	db 11,11,"Primary bootcode on EEPROM: ",0
bebc_txt	db 11,"Backup bootcode on EEPROM: ",0
ebc_txt		db "????",0		

old_ebc_txt	db "< 0617",0

no_ebc_txt	db "None",0


;--------------------------------------------------------------------------------------------------------------------
		
show_eeprom_os_status

		ld hl,os_txt
		call kjt_print_string
		
		ld de,$8
		call read_eeprom_page			;load from EEPROM $00800
		ld hl,page_buffer			; check if 
		ld de,z80_OS_txt			; bytes 0-7 are "Z80P*OS*"
		ld b,8					
cmposn		ld a,(de)				 
		cp (hl)
		jr nz,noeos				
		inc de
		inc hl
		djnz cmposn
		
		ld de,(page_buffer+$e)			;any label location?
		ld a,d
		or e
		jr nz,gotoslab
unkeos		ld hl,unkos_txt
		call kjt_print_string
		ret
		
gotoslab	ld hl,$0800				;move to page offset of label
		add hl,de
		jr c,unkeos
		ld e,h
		ld d,0
		push hl
		call read_eeprom_page
		pop hl
		ld h,0
		ld bc,page_buffer
		add hl,bc				;in-page label address
		ld bc,oslabel_txt
cpylab1		ld a,(bc)
		or a
		jr z,showoslab
		ld a,(hl)
		ld (bc),a
		or a
		jr z,showoslab
		inc bc
		inc l
		jr nz,cpylab1
		inc de					;in case label crosses page
		push bc
		call read_eeprom_page
		pop bc
		ld hl,page_buffer
cpylab2		ld a,(bc)
		or a
		jr z,showoslab
		ld a,(hl)
		ld (bc),a
		or a
		jr z,showoslab
		inc bc
		inc l
		jr nz,cpylab2
		
showoslab	ld hl,oslabel_txt
		call kjt_print_string
		ret
		
		
noeos		ld hl,noos_txt
		call kjt_print_string
		ret
		

os_txt		db 11,"OS on EEPROM: ",0
z80_OS_txt	db "Z80P*OS*"

noos_txt	db "None",0
unkos_txt	db "Yes, but no label.",0

oslabel_txt	ds 32,$ff					;label can be 32 chars max
		db 0
		
;--------------------------------------------------------------------------------------------------------------------
		
		
show_video_mode
		ld hl,vmode_txt
		call kjt_print_string
		
	        ld b,0                                            
	
		ld a,(vreg_read)                        ;60 Hz?
		bit 5,a
		jr z,not_60hz
		set 0,b

not_60hz	in a,(sys_hw_flags)                     ;VGA jumper on?
		bit 5,a
		jr z,not_vga
		set 1,b

not_vga  	ld a,b			                 ;0=PAL, 1=NTSC, 2=VGA
		add a,$10
		ld hl,vid_list
		ld bc,end_vid_list-vid_list
		cpir
		call kjt_print_string
		ret
		
vmode_txt	db 11,11,"Video mode: ",0

vid_list	db $10,"PAL TV 50Hz",0
		db $11,"NTSC TV 60Hz",0
		db $12,"VGA 50Hz",0
		db $13,"VGA 60Hz",0
		
end_vid_list	db "Unknown",0
		
;----------------------------------------------------------------------------------------------------------------
	
	
hex_to_ascii_word

		ld a,d
		call kjt_hex_byte_to_ascii
		ld a,e
		call kjt_hex_byte_to_ascii
		ret
	

;----------------------------------------------------------------------------------------------------------------


read_hw_id	ld b,16				;bit number to read
		ld c,sys_hw_flags		;port to read from
verloop		dec b
		in a,(c)			;serial data is bit 7
		inc b
		sla a				;force into carry flag
		rl e				;word ends up in DE
		rl d
		djnz verloop			;next bit
		
		ld a,d				;mask off top 4 bits of hardware ID
		ld b,d
		and $f
		ld d,a
		srl b
		srl b
		srl b
		srl b
		ret

;---------------------------------------------------------------------------------------------------------------


show_active_slot

		ld a,$88                                ; send PIC the command to prompt it to
		call send_byte_to_pic                   ; return the slot pointer MSB
		ld a,$76
		call send_byte_to_pic
	    
		ld hl,active_slot                       ; read bits from PIC RB7 
		call read_pic_byte
		srl (hl)
		ld a,(hl)                               ; if slot returns $00, the PIC code does not support the command
		or a                                    ; so cannot show active slot text
		jr nz,got_acts
	
		ld hl,old_pic_fw
		jr endit
	  
got_acts	ld hl,act_slot_figures
		call kjt_hex_byte_to_ascii
		  
		ld hl,act_slot_text                     ; show the active slot
		call kjt_print_string
		ld hl,act_slot_figures
endit		call kjt_print_string
		xor a
		ret
          

;--------------------------------------------------------------------------------------

show_pic_firmware

		ld hl,pic_fw_text
		call kjt_print_string
		  
		ld a,$88                                ; send PIC the command to prompt it to
		call send_byte_to_pic                   ; return its firmware byte
		ld a,$4e
		call send_byte_to_pic
		ld hl,pic_fw_byte                       ; read bits from PIC RB7 
		call read_pic_byte
		ld a,(hl)                               
		or a                                    
		jr nz,got_fw
		ld hl,pic_fw_unknown_text
		jr fw_end
		  
got_fw  	ld hl,pic_fw_figures+1
		call kjt_hex_byte_to_ascii
		ld hl,pic_fw_figures                              ; show pic fw
fw_end		call kjt_print_string
		xor a
		ret


;--------------------------------------------------------------------------------------

        
read_pic_byte	ld (hl),0
		ld c,8                                                   
nxt_bit		sla (hl)
		ld a,1<<pic_clock_input                 ; prompt PIC to present next bit by raising PIC clock line
		out (sys_pic_comms),a
		ld b,128                                ; wait a while so PIC can keep up..
pause_lp1	djnz pause_lp1
		xor a                                   ; drop clock line again
		out (sys_pic_comms),a
		in a,(sys_hw_flags)                     ; read the bit into shifter
		bit 3,a
		jr z,nobit
		set 0,(hl)
nobit		ld b,128
pause_lp2	djnz pause_lp2
		dec c
		jr nz,nxt_bit
		ret

;--------------------------------------------------------------------------------------

show_eeprom_type

		in a,(sys_eeprom_byte)                  ; clear shift reg count with a read
		ld a,$88                                ; send PIC the command to prompt the EEPROM to
		call send_byte_to_pic                   ; return its ID code byte
		ld a,$53
		call send_byte_to_pic
			
		ld d,32                                 ; D counts timer overflows
		ld a,1<<pic_clock_input                 ; prompt PIC to send a byte by raising PIC clock line
		out (sys_pic_comms),a
wbc_byte2	in a,(sys_hw_flags)                     ; have 8 bits been received?            
		bit 4,a
		jr nz,gbcbyte2
		in a,(sys_irq_ps2_flags)                ; check for timer overflow..
		and 4
		jr z,wbc_byte2      
		out (sys_clear_irq_flags),a             ; clear timer overflow flag
		dec d                                   ; dec count of overflows,
		jr nz,wbc_byte2                                             
		xor a                                   ; if waited too long give up (and drop PIC clock)
		out (sys_pic_comms),a
		jr no_id                                
gbcbyte2	xor a                         
		out (sys_pic_comms),a                   ; drop PIC clock line, PIC will then wait for next high 
		in a,(sys_eeprom_byte)                  ; read byte received, clear bit count

		push af
		ld hl,eeprom_id_text
		call kjt_print_string
		pop af

		cp $bf                                  ; If SST25VF type EEPROM is present, we'll have received
		jr nz,non_sst                           ; manufacturer's ID ($BF) not the capacity

		ld hl,sst25vf_text
		call kjt_print_string         
		ld a,$88                                ; Use alternate "Get EEPROM ID" command to find ID 
		call send_byte_to_pic                   
		ld a,$6c
		call send_byte_to_pic
		ld hl,eeprom_id_byte                              
		call read_pic_byte
		ld a,(hl)
		jr got_eid
		  
non_sst		push af
		ld hl,at25x_text
		call kjt_print_string
		pop af
got_eid		ld (eeprom_id_byte),a         
		sub $11   
		ld l,a
		ld h,0
		add hl,hl
		add hl,hl
		add hl,hl
		add hl,hl
		ld de,eeprom_id_list
		add hl,de
		call kjt_print_string

		ld a,(eeprom_id_byte)
		sub $10
		ld b,a
		ld a,1
slotslp		sla a
		djnz slotslp
		ld (number_of_slots),a
		ret

no_id		ld hl,no_id_text
		call kjt_print_string
		ret


;-------- EEPROM CONSTANTS -------------------------------------------------------------

pic_data_input	 equ 0	; from FPGA to PIC (bit 0 of sys_pic_comms)
pic_clock_input	 equ 1	; from FPGA to PIC (bit 1 of sys_pic_comms)
pic_clock_output equ 3	; from PIC to FPGA (bit 3 of sys_hw_flags) 

;----------------------------------------------------------------------------------------------------------	

send_byte_to_pic

; put byte to send in A
; Bit rate ~ 50KHz (Transfer ~ 4.7KBytes/Second)

		push bc
		push de
		ld c,a			
		ld d,8
bit_loop
		xor a
		rl c
		jr nc,zero_bit
		set pic_data_input,a
zero_bit
		out (sys_pic_comms),a		; present new data bit
		set pic_clock_input,a
		out (sys_pic_comms),a		; raise clock line
		
		ld b,12
psbwlp1		djnz psbwlp1			; keep clock high for 10 microseconds
			
		res pic_clock_input,a
		out (sys_pic_comms),a		; drop clock line
		
		ld b,12
psbwlp2		djnz psbwlp2			; keep clock low for 10 microseconds
		
		dec d
		jr nz,bit_loop

		ld b,60				; short wait between bytes ~ 50 microseconds
pdswlp		djnz pdswlp			; allows time for PIC to act on received byte
		pop de				; (PIC will wait 300 microseconds for next clock high)
		pop bc
		ret			


;-------------------------------------------------------------------------------------------


wait_pic_busy	push de
		ld de,0
	
wait_pic	in a,(sys_irq_ps2_flags)	; check for timer overflow..
		and 4
		jr z,test_pic	
		out (sys_clear_irq_flags),a	; clear timer overflow flag
		inc de				; inc count of overflows
		ld a,d
		cp 5
		jr nz,test_pic			; every 256 DE increments = 1 second		
		pop de
		scf				; timed out error - carry flag set
		ret
	
test_pic	in a,(sys_hw_flags)		; if PIC is holding its clock output high it is
		bit pic_clock_output,a		; busy and cannot accept data bytes at this time
		jr nz,wait_pic
		pop de
		scf
		ccf				; carry flag zero if OK
		ret

;---------------------------------------------------------------------------------

read_eeprom_page

		push hl			;put page number to read to buffer in DE
		push de
		push bc
		
		ld a,d
		ld (page_hi),a
		ld a,e
		ld (page_med),a
		
		in a,(sys_eeprom_byte)		;at outset, clear input byte shift count with a read
		
		ld a,$88			;send "set databurst location" command
		call send_byte_to_pic
		ld a,$d4
		call send_byte_to_pic
		ld a,$00			
		call send_byte_to_pic		;send address low
		ld a,(page_med)	
		call send_byte_to_pic		;send address mid
		ld a,(page_hi)
		call send_byte_to_pic		;send address high
		
		ld a,$88			;send "set databurst location" command
		call send_byte_to_pic
		ld a,$e2
		call send_byte_to_pic
		ld a,$00			
		call send_byte_to_pic		;send length low
		ld a,$01	
		call send_byte_to_pic		;send length mid
		ld a,$00
		call send_byte_to_pic		;send length high
		
		ld a,$88			;send "start databurst" command
		call send_byte_to_pic
		ld a,$c9
		call send_byte_to_pic

		ld hl,page_buffer		; download loop.. 
		ld bc,$100			; page = 256 bytes                 
nxt_byte
		ld d,0				; D counts timer overflows
		ld a,1<<pic_clock_input		; raise clock to prompt PIC to send a byte
		out (sys_pic_comms),a
wbc_byte
		in a,(sys_hw_flags)		; have 8 bits been received?		
		bit 4,a
		jr nz,gbcbyte
		in a,(sys_irq_ps2_flags)	; check for timer overflow..
		and 4
		jr z,wbc_byte	
		out (sys_clear_irq_flags),a	; clear timer overflow flag
		inc d				; inc count of overflows,
		jr nz,wbc_byte			
		ld a,1				; timed out error
		pop bc
		pop de
		pop hl
		ret
					
gbcbyte		xor a				; drop pic clock
		out (sys_pic_comms),a	
		in a,(sys_eeprom_byte)		; read byte received (clears bit count)
		ld (hl),a			; copy to dest, loop back to wait for next byte
		inc hl
		dec bc
		ld a,b
		or c
		jr nz,nxt_byte
		pop bc
		pop de
		pop hl
		xor a
		ret
		

;----------------------------------------------------------------------------------------------------------------
 		  
eeprom_id_text      db "EEPROM type: ",0
at25x_text          db "25*",0
sst25vf_text        db "SST25VF",0

eeprom_id_list      db "20 (256KB)",11,0,0,0,0,0  ;id = $11
                    db "40 (512KB)",11,0,0,0,0,0  ;id = $12
                    db "80 (1MB)  ",11,0,0,0,0,0  ;id = $13
                    db "16 (2MB)  ",11,0,0,0,0,0  ;id = $14
                    db "32 (4MB)  ",11,0,0,0,0,0  ;id = $15
                    db "64 (8MB)  ",11,0,0,0,0,0  ;id = $16


no_id_text          db "EEPROM type: Unknown, probably 25x40",0

eeprom_id_byte      db 0
working_slot        db 0

number_of_slots     db 4                          ;including slot 0


active_slot         db 0
act_slot_text       db "FPGA power-on boot slot: ",0
act_slot_figures    db "xx",0         	

old_pic_fw	    db "FPGA boot slot: Unknown (Old PIC FW)",11,0 

pic_fw_text         db 11,"Config PIC firmware: ",0
pic_fw_figures      db "6xx",11,0
pic_fw_unknown_text db "Unknown (Old version)",11,0
pic_fw_byte         db 0

		    org ($+$ff)&$ff00
		    
page_buffer	    ds 256,0

page_lo	 	    db 0
page_med	    db 0
page_hi		    db 0

;==============================================================================================================
 	
	
sys_info_string1

		db "SYSTEM INFORMATION:",11
		db "-------------------",11,11
		
		db "PCB version : ",0


sys_info_string2

		db "Active OSCA version: "
osca		db "????",11
		db "Active FLOS version: "
flos		db "????",11
		db 11,"OS loaded by bootcode version: "
obcode		db "????",11						;must be 4 chars
		
		db "OS loaded from: ",0


sys_info_string3

		db "EEPROM type: ",0
		db "Config PIC firmware: ",0
		db "Active slot:",0
				
;----------------------------------------------------------------------------------------------------------------
 
	
pcb_types	db $ff,"???? (old OSCA)",11,0
		db 1,"V6Z80P (original)",11,0
		db 2,"V6Z80P+ v1.0",11,0
		db 3,"V6Z80P+ V1.1",11,0

end_pcb_types

	
bootdev_types	db $ff,"?? (old bootcode/FLOS)",11,0
		db 1,"SD CARD",11,0
		db 2,"EEPROM",11,0
		db 3,"SERIAL LINK",11,0
	
end_bootdev_types

;----------------------------------------------------------------------------------------------------------------
