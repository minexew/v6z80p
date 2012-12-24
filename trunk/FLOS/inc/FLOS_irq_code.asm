
;----------------------------------------------------------------------------------------

os_irq_handler

		push af			; Maskable IRQ jumps here
		in a,(sys_irq_ps2_flags)	; Read irq status flags
		
		bit 0,a				; keyboard irq set?
		call nz,keyboard_irq_code	; call keyboard irq routine if so

		bit 1,a
		call nz,mouse_irq_code		; mouse IRQ?

		pop af			
		ei				; re-enable interrupts
		reti				; return to main code

;----------------------------------------------------------------------------------------
; Keyboard IRQ routine v5.02
;----------------------------------------------------------------------------------------

keyboard_irq_code

		push af			; buffer the keypresses, keep track of qualifiers
		push hl			
		push bc
		
		ld a,(key_release_mode)
		or a
		jr z,key_pressed

		in a,(sys_keyboard_data)
		cp $e0
		jr z,kirq_done	
		cp $e1
		jr z,kirq_done	
		
		call qualifiers
		ld a,c
		cpl
		ld c,a
		ld a,(key_mod_flags)
		and c				; update qualifier key releases
		ld (key_mod_flags),a
		xor a
		ld (key_release_mode),a

		jr kirq_done
	
key_pressed

		in a,(sys_keyboard_data)
		cp $e0
		jr z,kirq_done	
		cp $e1
		jr z,kirq_done	

		cp $f0				; is scancode a key released token?
		jr nz,not_krel
		ld a,1				; if so, so nothing except set the next irq to
		ld (key_release_mode),a		; treat scan code as a release code
		jr kirq_done
	
	
not_krel	push af
		call qualifiers
		ld a,(key_mod_flags)		;update qualifier presses
		or c
		ld (key_mod_flags),a
		
		ld hl,scancode_buffer
		ld a,(key_buf_wr_idx)		 
		add a,l
		ld l,a
		jr nc,kbhok
		inc h
kbhok		pop af
		ld (hl),a			; put key press scancode in buffer 	
		ld a,l
		add a,16
		ld l,a
		jr nc,kbhok2
		inc h
kbhok2		ld a,(key_mod_flags)		; also record qualifier status in buffer
		ld (hl),a	
		ld a,(key_buf_wr_idx)
		inc a
		and 15
		ld (key_buf_wr_idx),a		; advance the buffer location
			
kirq_done	ld a,%00000001
		out (sys_clear_irq_flags),a	; clear keyboard interrupt flag

		pop bc
		pop hl
		pop af
		ret


qualifiers

		ld hl,qualklist	
		ld c,$40		
qual_lp		cp (hl)		
		ret z		
		srl c		
		ret z		
		inc hl		
		jr qual_lp	
		
	
qualklist	db $2f,$27,$59,$11,$1f,$14,$12


;-----------------------------------------------------------------------------------------
; Mouse IRQ code v5.03
;-----------------------------------------------------------------------------------------

mouse_irq_code

; buffers the movement packet bytes. On the 3rd byte, the
; mouse location and button registers are updated 

		push af			
		push bc			
		push de			
		push hl
		
		ld a,(use_mouse)		; mouse allowed to call IRQ code?
		or a
		jp z,no_mouse
		
		ld d,0		
		ld a,(mouse_packet_index)	; packet byte 0-2  
		ld e,a
		ld hl,mouse_packet	
		add hl,de
		ld c,sys_mouse_data
		in e,(c)			 
		ld (hl),e
		
		or a				; if this is packet index 0, we can check if bit 3 is set
		jr nz,not_idx0			; as should always be case. If it is not we know the byte
		bit 3,e				; received is not actually the first of the packet so we
		jr z,mbotok			; should ignore it. This can help with misaligned packets.
			
not_idx0	inc a				; was this the third and last byte of packet?
		cp 3
		jr nz,msubpkt

		ld a,(mouse_packet)		; update OS mouse registers, first the buttons
		ld c,a
		and %111
		ld (mouse_buttons),a
		
		ld d,0				; update the pointer x position
		bit 4,c
		jr z,mxsignpos
		dec d
mxsignpos	ld a,(mouse_packet+1)
		ld e,a
		ld hl,(mouse_disp_x)	
		add hl,de			; add mouse displacement to displacement total
		ld (mouse_disp_x),hl
		ld hl,(mouse_pos_x)
		add hl,de			; add mouse displacement to absolute pointer pos
		ld (mouse_pos_x),hl
		bit 7,h				; check boundaries
		jr z,mleftok
		ld hl,0
		jr mfix_x
mleftok		ld de,(mouse_window_size_x)
		xor a
		sbc hl,de
		jr c,mrightok
		ex de,hl
mfix_x		ld (mouse_pos_x),hl

mrightok	ld d,0				; update pointer y position
		bit 5,c
		jr z,mysignpos
		dec d
mysignpos	ld a,(mouse_packet+2)
		ld e,a
		ld hl,(mouse_disp_y)		; mouse uses positive displacement = upwards	
		xor a				; motion so subtract value instead of adding
		sbc hl,de
		ld (mouse_disp_y),hl
		ld hl,(mouse_pos_y)
		xor a
		sbc hl,de			; mouse uses positive displacement = upwards
		ld (mouse_pos_y),hl		; motion so subtract value instead of adding
		bit 7,h				; check boundaries
		jr z,mtopok
		ld hl,0
		jr mfix_y
mtopok		ld de,(mouse_window_size_y)
		xor a
		sbc hl,de
		jr c,mbotok
		ex de,hl
mfix_y		ld (mouse_pos_y),hl
mbotok		xor a

msubpkt		ld (mouse_packet_index),a
		ld a,%00000010
		out (sys_clear_irq_flags),a	; clear mouse interrupt flag

no_mouse
		pop hl
		pop de
		pop bc
		pop af
		ret
		
;-----------------------------------------------------------------------------------------
; NMI code v6.01
;-----------------------------------------------------------------------------------------

os_allow_nmi_freeze

		ld hl,os_nmi_freeze		; allow NMI freezer
		ld (nmi_vector),hl	 
		ret
			
;-----------------------------------------------------------------------------------------
	
os_nmi_freeze

	
		call os_store_CPU_regs
		pop hl				; gets the NMI return address
		ld (pc_store),hl		; stores it for recorded PC
		ld hl,continue			; change return address for continue
		push hl			; to get out of NMI mode
		retn				; jump to continue
	
continue	ld sp,stack			; Fix stack pointer to default - so wiping out
		di				; program's subroutines/maskable IRQ status
		im 1				; CPU IRQ: mode 1
		xor a
		out (sys_mem_select),a		; make sure VRAM etc is not paged in
		out (sys_alt_write_page),a

		call nmi_freeze_os_init		; set up OS front end (disk system not reset)
		call restore_bank_no_script	; restore original FLOS bank
		call restore_dir_vol		; restore original FLOS dir
		
		ld hl,nmi_freeze_txt		; show NMI break text
		call os_print_string	
			
		call os_cmd_r			; show registers
		
		ei				; enable mskable IRQs
		jp os_main_loop			; continue os/monitor operations

;---------------------------------------------------------------------------------------

os_no_nmi_freeze

		retn

;---------------------------------------------------------------------------------------
