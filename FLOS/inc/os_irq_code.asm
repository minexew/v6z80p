;----------------------------------------------------------------------------------------
; IRQ / NMI Routines v5.01
;----------------------------------------------------------------------------------------

os_irq_handler

	push af			; Maskable IRQ jumps here
	in a,(sys_irq_ps2_flags)	; Read irq status flags
	
	bit 0,a			; keyboard irq set?
	call nz,keyboard_irq_code	; call keyboard irq routine if so

	bit 1,a
	call nz,mouse_irq_code	; mouse IRQ?

	pop af			
	ei			; re-enable interrupts
	reti			; return to main code

;----------------------------------------------------------------------------------------
; Keyboard IRQ routine v5.02
;----------------------------------------------------------------------------------------

keyboard_irq_code

	push af			; buffer the keypresses, keep track of qualifiers
	push hl			
	
	ld a,(key_release_mode)
	or a
	jr z,key_pressed

	in a,(sys_keyboard_data)
	cp $e0
	jr z,kirq_done	
	cp $e1
	jr z,kirq_done	
	
	call qualifiers
	ld a,l
	cpl
	ld l,a
	ld a,(key_mod_flags)
	and l			;update qualifier key releases
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

	cp $f0			;is scancode a key released token?
	jr nz,not_krel
	ld a,1			;if so, so nothing except set the next irq to
	ld (key_release_mode),a	;treat scan code as a release code
	jr kirq_done
	
	
not_krel	push af
	call qualifiers
	ld a,(key_mod_flags)	;update qualifier presses
	or l
	ld (key_mod_flags),a
	
	ld hl,scancode_buffer
	ld a,(key_buf_wr_idx)		 
	add a,l
	ld l,a
	jr nc,kbhok
	inc h
kbhok	pop af
	ld (hl),a			; put key press scancode in buffer 	
	ld a,l
	add a,16
	ld l,a
	jr nc,kbhok2
	inc h
kbhok2	ld a,(key_mod_flags)	; also record qualifier status in buffer
	ld (hl),a	
	ld a,(key_buf_wr_idx)
	inc a
	and 15
	ld (key_buf_wr_idx),a	; advance the buffer location
	
kirq_done	ld a,%00000001
	out (sys_clear_irq_flags),a	; clear keyboard interrupt flag
	pop hl
	pop af
	ret


qualifiers

	ld l,$40
	cp $2f
	ret z

	ld l,$20
	cp $27
	ret z

	ld l,$10
	cp $59
	ret z

	ld l,$08
	cp $11
	ret z

	ld l,$04
	cp $1f

	ld l,$02
	cp $14
	ret z

	ld l,$01
	cp $12
	ret z
	
	ld l,0
	ret
	


;-----------------------------------------------------------------------------------------
; Mouse IRQ code v5.02
;-----------------------------------------------------------------------------------------

mouse_irq_code

	push af			; buffers the movement packet bytes
	push bc			; on the 3 byte, absolute mouse location and
	push de			; button registers are updated 
	push hl
	
	ld a,(use_mouse)		; mouse allowed to call IRQ code?
	or a
	jp z,no_mouse
	
	ld d,0		
	ld a,(mouse_packet_index)	; packet byte 0-2  
	ld e,a
	ld hl,mouse_packet	
	add hl,de
	in a,(sys_mouse_data)
	ld (hl),a
	inc e			; was this the third and last byte of packet?
	ld a,e
	cp 3
	jr nz,msubpkt

	ld a,(mouse_packet)		; update OS mouse registers, first the buttons
	ld c,a
	and %111
	ld (mouse_buttons),a
	
	ld d,0			; update the pointer x position
	bit 4,c
	jr z,mxsignpos
	dec d
mxsignpos	ld a,(mouse_packet+1)
	ld e,a
	ld hl,(mouse_disp_x)
	add hl,de
	ld (mouse_disp_x),hl
	ld hl,(mouse_pos_x)
	add hl,de			; add mouse displacement to absolute pointer pos
	ld (mouse_pos_x),hl
	bit 7,h			; check boundaries
	jr z,mleftok
	ld hl,0
	jr mfix_x
mleftok	ld de,(mouse_window_size_x)
	xor a
	sbc hl,de
	jr c,mrightok
	ex de,hl
mfix_x	ld (mouse_pos_x),hl

mrightok	ld d,0			; update pointer y position
	bit 5,c
	jr z,mysignpos
	dec d
mysignpos	ld a,(mouse_packet+2)
	ld e,a
	ld hl,(mouse_disp_y)	; mouse uses positive displacement = upwards	
	xor a			; motion so subtract value instead of adding
	sbc hl,de
	ld (mouse_disp_y),hl
	ld hl,(mouse_pos_y)
	xor a
	sbc hl,de			; mouse uses positive displacement = upwards
	ld (mouse_pos_y),hl		; motion so subtract value instead of adding
	bit 7,h			; check boundaries
	jr z,mtopok
	ld hl,0
	jr mfix_y
mtopok	ld de,(mouse_window_size_y)
	xor a
	sbc hl,de
	jr c,mbotok
	ex de,hl
mfix_y	ld (mouse_pos_y),hl
mbotok	xor a

msubpkt	ld (mouse_packet_index),a
	ld a,%00000010
	out (sys_clear_irq_flags),a	; clear mouse interrupt flag

no_mouse
	pop hl
	pop de
	pop bc
	pop af
	ret
	
;-----------------------------------------------------------------------------------------
	
	
os_nmi_freeze


	call os_store_CPU_regs
	pop hl			; gets the NMI return address
	ld (storepc),hl		; stores it for recorded PC
	ld hl,continue		; change return address for continue
	push hl			; to get out of NMI mode
	retn			; jump to continue
	
continue:	ld sp,stack		; Fix stack pointer to default - so wiping out
	di			; program's subroutines/maskable IRQ status
	im 1			; CPU IRQ: mode 1
	call initialize_os		; set up OS front end (disk system not reset)
	
	ld hl,nmi_freeze_txt	; show NMI break text
	call os_print_string	
		
	call os_cmd_r		; show registers
	
	ei			; enable mskable IRQs
	jp os_main_loop		; continue os/monitor operations

;---------------------------------------------------------------------------------------

os_no_nmi_freeze

	retn

;---------------------------------------------------------------------------------------
