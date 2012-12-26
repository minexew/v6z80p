
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
		
gotoslab	ld hl,$0800				;move to eeprom page where label resides
		add hl,de
		jr c,unkeos
		ld e,h
		ld d,0
		call read_eeprom_page
		ld h,0
		push hl
		pop ix
		ld bc,page_buffer
		add ix,bc				;in-page label address
		ld iy,oslabel_txt
		ld b,32
cpyoslab	ld a,(ix)
		ld (iy),a
		or a
		jr z,showoslab
		inc ix
		inc iy
		inc l
		jr z,nextepage
cpyoslab_cont	djnz cpyoslab
		
showoslab	ld hl,oslabel_txt
		call kjt_print_string
		ret
		
nextepage	inc de					;in case label crosses page
		call read_eeprom_page
		ld ix,page_buffer
		jr cpyoslab_cont
				
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

		call get_active_slot              ; if ZF not set, the PIC code does not support the command
		jr z,got_acts                     ; so cannot show active slot text

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
		  
		call get_pic_fw                         ; if fw byte > $00, the PIC firmware is v618+
 		jr z,got_fw
		ld hl,pic_fw_unknown_text
		jr fw_end
 		  
got_fw  	ld hl,pic_fw_figures+1
		call kjt_hex_byte_to_ascii
		ld hl,pic_fw_figures                    ; show pic fw
fw_end		call kjt_print_string
		xor a
		ret



;--------------------------------------------------------------------------------------

show_eeprom_type
		
		ld hl,eeprom_id_text
		call kjt_print_string
		
		call get_eeprom_size
		jr nz,no_id
		
		ld hl,sst25vf_text
		bit 0,e
		jr nz,sst_type_epr
		ld hl,at25x_text
sst_type_epr	call kjt_print_string
		
		ld a,d
		ld hl,epr_id_list
		ld bc,end_id_list-epr_id_list
		cpir
		call kjt_print_string
		ret
		
no_id		ld hl,no_id_text
		call kjt_print_string
		ret


;----------------------------------------------------------------------------------------------------------------
 
		include "flos_based_programs\code_library\eeprom\inc\eeprom_subroutines.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_read.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_interogation.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_slot_list.asm"

;----------------------------------------------------------------------------------------------------------------
 		  
eeprom_id_text      db "EEPROM type: ",0
at25x_text          db "25x",0
sst25vf_text        db "SST25VF",0

epr_id_list	    db $11,"20 (256KB)",11,0
                    db $12,"40 (512KB)",11,0
                    db $13,"80 (1MB)",11,0
                    db $14,"16 (2MB)",11,0
                    db $15,"32 (4MB)",11,0
                    db $16,"64 (8MB)",11,0
end_id_list	    db 0

no_id_text          db "EEPROM type: Unknown, 25x40?",0

act_slot_text       db "FPGA power-on boot slot: ",0
act_slot_figures    db "xx",0         	

old_pic_fw	    db "FPGA boot slot: Unknown (Old PIC FW)",11,0 

pic_fw_text         db 11,"Config PIC firmware: ",0
pic_fw_figures      db "6xx",11,0
pic_fw_unknown_text db "Unknown (Old?)",11,0

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
