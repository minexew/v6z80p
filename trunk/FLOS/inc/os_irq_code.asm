;----------------------------------------------------------------------------------------
; IRQ / NMI Routines v5.00
;----------------------------------------------------------------------------------------

os_irq_handler

	push af			; Maskable IRQ jumps here
	in a,(sys_irq_ps2_flags)	; Read irq status flags
	bit 0,a			; keyboard irq set?
	call nz,keyboard_irq_code	; call keyboard irq routine if so
	bit 1,a
	call nz,mouse_irq_code	; mouse IRQ?
	bit 2,a
	call nz,timer_irq_code	; timer IRQ?
	bit 3,a
	call nz,video_irq_code	; video IRQ?
	pop af			
	ei			; re-enable interrupts
	reti			; return to main code

;---------------------------------------------------------------------------------------

video_irq_code

	ld a,%10000000
	ld (vreg_rasthi),a		; clears video IRQ
	ret


timer_irq_code

	ld a,%00000100
	out (sys_clear_irq_flags),a	;clears timer IRQ
	ret

;----------------------------------------------------------------------------------------
; Keyboard IRQ routine v5.00
;----------------------------------------------------------------------------------------

keyboard_irq_code

	push af			; buffers the scan code bytes
	push hl			
			
	ld a,(sub_keycode_idx)	; multi-byte keycode sub index 
	ld hl,key_buf_wr_idx	
	add a,(hl)		; add buffer index
	ld hl,scancode_buffer	
	and 31
	add a,l
	jr nc,kbblnc
	inc h
kbblnc	ld l,a						
	in a,(sys_keyboard_data)	; get the keycode
	cp $e0			; ignore/discard any E0 scan code bytes
	jr z,sccdiz
	cp $e1			; ignore/discard any E1 scan code bytes
	jr z,sccdiz
	ld (hl),a			; put scancode into keyboard buffer
	
	ld l,1			; 1 = default number of bytes expected in a keycode
	cp $f0			; was scancode = $F0 (release key)?
	jr nz,kcnot_f0
	ld l,2			; if so set the "bytes expected" counter to 2
kcnot_f0	ld a,l
	ld (sub_keycode_countdown),a	
	
	ld hl,sub_keycode_idx
	inc (hl)			; increment sub-scancode index
	ld a,(hl)			
	ld hl,sub_keycode_countdown	
	dec (hl)			; decrement "bytes in scancode" count
	jr nz,sccdiz
	ld hl,key_buf_wr_idx	; if zero the full keycode sequence is in
	add a,(hl)		; so the actual scancode buffer position can
	and 31			; be updated
	ld (hl),a
	xor a
	ld (sub_keycode_idx),a	; sub-scancode counter is reset to zero
	
sccdiz	ld a,%00000001
	out (sys_clear_irq_flags),a	; clear keyboard interrupt flag
	pop hl
	pop af
	ret


;-----------------------------------------------------------------------------------------
; Mouse IRQ code v5.01
;-----------------------------------------------------------------------------------------

mouse_irq_code

	push af			; buffers the movement packet bytes
	push bc			; on the 3 byte, absolute mouse location and
	push de			; button registers are updated 
	push hl
	
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
