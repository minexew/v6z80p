;--------------------------------------------------------------------------------------------------
;--------- Mouse functions ------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------

os_enable_mouse

; Set: HL/DE = window size mouse pointer is to work within

		ld a,1
		out (sys_irq_enable),a

		ld (mouse_window_size_x),hl	 
		ld (mouse_window_size_y),de

		ld hl,use_mouse
		ld (hl),1				; set bit 0 - driver enabled
		inc hl					; clear other mouse vars (consecutive bytes)
		ld c,17
		call os_chl_memclear_short


os_enable_irq	ld a,(use_mouse)
		rlca
		and 2
		or %10000001
		out (sys_irq_enable),a
		ret
	


os_get_mouse_position

; Returns: ZF = Set: X coord in HL, y coord in DE, buttons in A
;          ZF = Not set: Mouse driver not initialized.

		ld a,(use_mouse)			; is mouse driver enabled?	
		and 1
		xor 1
		ret nz
		ld hl,(mouse_pos_x)		
		ld de,(mouse_pos_y)
mouse_end	xor a
		ld a,(mouse_buttons)
		ret


os_get_mouse_motion

		ld a,(use_mouse)			; is mouse driver enabled?	
		and 1
		xor 1
		ret nz
		di
		push bc
		ld hl,(mouse_disp_x)		
		push hl
		ld de,(old_mouse_disp_x)
		xor a
		sbc hl,de
		pop de
		ld (old_mouse_disp_x),de
		ex de,hl
		
		ld hl,(mouse_disp_y)		
		push hl
		ld bc,(old_mouse_disp_y)
		xor a
		sbc hl,bc
		pop bc
		ld (old_mouse_disp_y),bc
		ex de,hl
		pop bc
		ei
		jr mouse_end
	