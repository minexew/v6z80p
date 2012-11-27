;-----------------------------------------------------------------------------------------------------------

memory_tests	call kjt_clear_screen
		
		ld hl,memory_menu_text
		call kjt_print_string
			
mem_tlp		call kjt_wait_key_press
		cp $76
		jr nz,notquitmemt

		xor a
		ret

notquitmemt	ld a,b
		cp "1"
		jr z,test_sysmem
		cp "2"
		jp z,test_videomem
		jr mem_tlp

test_sysmem	call sys_mem_test
		jr memory_tests
		
test_videomem	call video_mem_test
		jr memory_tests
		
		
memory_menu_text
	
		db "Memory test menu",11,11
		db "Press:",11,11
		db "1. Test system RAM",11
		db "2. Test video RAM",11,11
		db "ESC - Quit to main menu",11,11,0

;-----------------------------------------------------------------------------------------------------------

sys_mem_test	ld hl,0
		ld (pass_count),hl
		
sysramtlp	call kjt_clear_screen
				
		ld hl,sys_memtest_txt
		call kjt_print_string

		call show_passes

		ld bc,$0002
		call kjt_set_cursor_position
		ld hl,bank_select_txt
		call kjt_print_string
	
		ld c,1					;part 1 - write 1s to bank1, 2s to bank 2 etc..		
		ld b,15
loop1		push bc
		ld a,c					
		out (sys_mem_select),a			
		ld e,c
		call fill_ram
		pop bc
		inc c
		djnz loop1
		
		ld c,1					;test writes were correct
		ld b,15
loop2		push bc
		ld a,c			
		out (sys_mem_select),a	
		ld e,c
		call test_ram_fill
		pop bc
		jp nz,sysmem_fail
		inc c
		djnz loop2
		
		
		
		ld hl,random_txt			;part 2 - read/write random bytes
		call kjt_print_string

		di					;test first 32KB of system RAM - need to move FLOS (and this program) to higher in RAM
		ld a,1
		out (sys_mem_select),a			;make sure sysram $08000-$0ffff is banked at CPU: $8000		
		ld a,%11000000
		out (sys_alt_write_page),a		;select sysram @ CPU:$0-$7ff for reading
		ld hl,$0								
		ld de,$8000
		ld bc,$8000
		ldir					;copy sysram $00000-$07fff to $08000-$0ffff
		ld a,1
		out (sys_low_page),a			;bank sysram $08000-0ffff into CPU: $0-$7fff
		ld a,%00100000
		out (sys_alt_write_page),a		;allow first 32KB of system RAM to appear at CPU $8000 for testing
		ld a,0
		out (sys_mem_select),a			;page first 32KB of sysRAM into CPU ($8000-$7fff)
		call rand_test_sysram
		push af
		push de
		ld hl,$0				;copy sysRAM $08000-$0ffff back to sysRAM $00000
		ld de,$8000
		ld bc,$8000
		ldir			
		ld a,0
		out (sys_low_page),a			;page sysram $00000-$07fff back to CPU:$0000-$7fff (as default)
		out (sys_alt_write_page),a
		ei
		pop de					;c:de = address if failed
		ld c,0
		pop af
		jp nz,sysmem_fail

		ld c,1					;now test rest of sysram -  $8000-$ffff for every bank 
		ld b,15
loop3		push bc
		ld a,c			
		out (sys_mem_select),a		
		call rand_test_sysram
		pop bc
		jp nz,sysmem_fail
		
		ld hl,dot_txt
		call kjt_print_string
		
		push bc
		call kjt_get_key	
		pop bc
		cp $76
		ret z
		
		inc c
		djnz loop3
	
		ld hl,(pass_count)
		inc hl
		ld (pass_count),hl
			
		jp sysramtlp


		
show_passes	ld bc,$0008
		call kjt_set_cursor_position
		ld hl,pass_txt
		call kjt_print_string
		ld hl,(pass_count)
		call print_decimal
		ld hl,cr_txt
		call kjt_print_string
		ret
			

;---------------------------------------------------------------------------------------------------

print_decimal
	
;Number in hl to decimal ASCII (thanks to z80 Bits)
;Modified to skip leading zeroes by Phil Ruston
;inputs:	hl = number to ASCII
;example: hl=300 outputs '300'
;destroys: af, bc, hl, de used

		ld d,4
		ld e,0
		ld bc,-10000
		call Num1b
		ld bc,-1000
		call Num1b
		ld bc,-100
		call Num1b
		ld c,-10
		call Num1b
		ld c,-1
Num1b		ld a,'0'-1
Num2b		inc a
		add hl,bc
		jr c,Num2b
		sbc hl,bc
		dec d
		jr z,notzerob
		cp "0"
		jr nz,notzerob
		bit 0,e
		ret z
notzerob	call print_char
		ld e,1
		ret

 	
;---------------------------------------------------------------------------------------------------
	
sysmem_fail		
		ld h,c				;convert bank (c) and hi-mem addr (de) to flat E:BC
		ld c,0
		ld l,0
		ld b,7
shmblp		add hl,hl
		rl c
		djnz shmblp
		
		res 7,d
		add hl,de
		ld e,c
		
		push hl
		pop bc
		jp show_mem_err_addr


;--------------------------------------------------------------------------------------------------

fill_ram	push hl
		push de
		push bc
		
		ld hl,$8000
		ld (hl),e
		push hl
		pop de
		inc de
		ld bc,$7fff
		ldir
		
		pop bc
		pop de
		pop hl
		ret


test_ram_fill	ld hl,$8000
frtloop		ld a,(hl)
		cp e
		jr nz,badbyte
		inc hl
		ld a,h
		or l
		jr nz,frtloop
		xor a
		ret

badbyte		push hl			;return bad location in DE
		pop de
		xor a
		inc a
		ret
	
	
;-----------------------------------------------------------------------------------------

	
rand_test_sysram

		ld de,$8000	
		ld hl,(pass_count)		;fill mem with random bytes
		ld (seed),hl
rloop1		exx
		call rand16
		exx
		ld a,(seed)
		ld (de),a
		inc de
		ld a,(seed+1)
		ld (de),a
		inc de
		ld a,d
		or e
		jr nz,rloop1
	
		ld de,$8000	
		ld hl,(pass_count)		;test random bytes
		ld (seed),hl
vrloop1		exx
		call rand16
		exx
		ld hl,(seed)
		ld a,(de)
		cp l
		jp nz,failed
		inc de
		ld a,(de)
		cp h
		jp nz,failed
		inc de
		ld a,d
		or e
		jr nz,vrloop1
		xor a
		ret

failed		xor a
		inc a
		ret
			
;---------------------------------------------------------------------------------------------------------------------

rand16		ld	de,(seed)		
		ld	a,d
		ld	h,e
		ld	l,253
		or	a
		sbc	hl,de
		sbc	a,0
		sbc	hl,de
		ld	d,0
		sbc	a,d
		ld	e,a
		sbc	hl,de
		jr	nc,rand
		inc	hl
rand		ld	(seed),hl		
		ret
	
;---------------------------------------------------------------------------------------------------------------------

video_mem_test	call kjt_clear_screen
		
		ld hl,testing_vmem_txt
		call kjt_print_string
		
		ld hl,0
		ld (pass_count),hl
		
vmtloop		ld bc,$0002
		call kjt_set_cursor_position
		
		ld a,32				;start page = 32 ($40000)
		call vmem_fill
		ld a,32
		call vmem_test
		jp nz,vmem_error
		
		call kjt_get_key	
		cp $76
		ret z
		
		call preserve_flos_display	
		ld a,0				;start page = 0 ($00000)
		call vmem_fill
		ld a,0
		call vmem_test
		push af
		push bc
		push de
		push hl
		call restore_flos_display	
		pop hl
		pop de
		pop bc
		pop af
		jp nz,vmem_error
		
		call kjt_get_key	
		cp $76
		ret z
		
		ld hl,(pass_count)
		inc hl
		ld (pass_count),hl
		
		call show_passes
		jr vmtloop
		
		
		
vmem_fill	ld (v_bank),a
		call kjt_page_in_video
		ld hl,(pass_count)
		ld (seed),hl
		ld b,32
vb_lp		ld a,(v_bank)
		ld (vreg_vidpage),a
		
		ld hl,$2000
ivbnklp		exx
		call rand16
		exx
		ld de,(seed)
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		bit 6,h
		jr z,ivbnklp
		
		ld a,(v_bank)
		inc a
		ld (v_bank),a
		djnz vb_lp
		call kjt_page_out_video
		xor a
		ret
		
		
vmem_test	ld (v_bank),a
		call kjt_page_in_video
		ld b,32
		ld hl,(pass_count)
		ld (seed),hl
		
vb_lp2		ld a,(v_bank)
		ld (vreg_vidpage),a
		
		ld hl,$2000
ivbnklp2	exx
		call rand16
		exx
		ld de,(seed)
		ld a,(hl)
		cp e
		ret nz
	        inc hl
		ld a,(hl)
		cp d
		ret nz
		inc hl
		bit 6,h
		jr z,ivbnklp2
		
		ld a,(v_bank)
		inc a
		ld (v_bank),a
		djnz vb_lp2
		call kjt_page_out_video
		xor a
		ret
		
vmem_error	push hl
		
		ld a,(v_bank)
		ld l,0
		ld h,a
		ld e,0
		ld b,5
shvmblp		add hl,hl
		rl e
		djnz shvmblp

		pop bc
		ld a,b
		and $1f
		ld b,a
		add hl,bc
		push hl
		pop bc
		
show_mem_err_addr

		ld hl,err_addr_txt				;address in E:BC
		ld a,e
		push bc
		call kjt_hex_byte_to_ascii
		pop bc
		ld a,b
		push bc
		call kjt_hex_byte_to_ascii
		pop bc
		ld a,c
		call kjt_hex_byte_to_ascii
		
		ld bc,$0008
		call kjt_set_cursor_position
		
		ld hl,vmemerr_txt
		call kjt_print_string
		
		call press_any_key
		
		ret				

vmemerr_txt	db "ERROR AT: $"
err_addr_txt	db "xxxxxx",11,11,0

;-----------------------------------------------------------------------------------------------------------------

		
preserve_flos_display

		ld a,$01			;move FLOS display to $7ffff
		ld hl,$0000			;source object is at VRAM $010000
		ld (blit_src_loc),hl		;set source address
		ld (blit_src_msb),a		;set source address msb
		ld a,$07
		ld hl,$0000			;destination for object is VRAM $70000-$7ffff
		ld (blit_dst_loc),hl		;(moves along one pixel each frame)
		ld (blit_dst_msb),a
blitmain	ld a,0
		ld (blit_dst_mod),a		;set destination video 	
		ld (blit_src_mod),a		;set source modulo
		ld a,%01000000			;set blitter to ascending mode (modulo 
		ld (blit_misc),a		;high bits set to zero, transparency: off)
		ld a,255
		ld (blit_height),a		;set height of blit object (in lines)
		ld a,255
		ld (blit_width),a		;set width of blit object (in bytes) and start blit		
		call wait_blit
		ret

restore_flos_display
		
		ld a,$07			;move FLOS display to $7ffff
		ld hl,$0000			;source object is at VRAM $010000
		ld (blit_src_loc),hl		;set source address
		ld (blit_src_msb),a		;set source address msb
		ld a,$01
		ld hl,$0000			;destination for object is VRAM $70000-$7ffff
		ld (blit_dst_loc),hl		;(moves along one pixel each frame)
		ld (blit_dst_msb),a
		jr blitmain

wait_blit	in a,(sys_vreg_read)		
		bit 4,a 			;busy wait for blit to complete
		jr nz,wait_blit
		ret
		
;---------------------------------------------------------------------------------------------------------------------

press_any_key

		ld hl,press_key_txt
		call kjt_print_string
		call kjt_wait_key_press
		ret

press_key_txt	db 11,11,"Press any key to continue..",11,0

		
;---------------------------------------------------------------------------------------------------------------------

testing_vmem_txt	

		db "Testing 512KB video RAM....",11,11
		db "(Garbage will appear on screen",11
		db "during tests..) ESC to quit",11,0
		
sys_memtest_txt	db "Testing System RAM $00000-$7FFFF",11,11
		db "ESC to quit",11,11,0

bank_select_txt	db "Bank selection test..",11,11,0

random_txt	db "OK",11,11,"Random byte write/verify test..",11,11,0

pass_count	db 0,0

pass_txt	db 11,11,"Pass count:",0
cr_txt		db 13,0

dot_txt		db ".",0

seed		dw 0

v_bank		db 0

;-------------------------------------------------------------------------------------------------------------------
