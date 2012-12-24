;---------------------------------------------------------------------------------------
; CORE KEYBOARD ROUTINES V6.05
;---------------------------------------------------------------------------------------

os_wait_key_press

; Busy waits for a keypress.
; Handles the modifier keys (key_mod_flags):
; Returns scancode in A and ASCII code in B (B=$00 if no valid ascii char)
; (ASCII code is modifed by shift / alt key status)


		push de
		ld d,c
		push hl
wait_kbuf	call get_kb_buffer_indexes	; HL = buffer read index. A = buffer write index
		cp (hl)				; if read and write indexes are same, buffer is empty
		jr z,wait_kbuf		

new_key		call get_buffer_loc		; HL = location in scancode buffer
		ld c,(hl)			; c = scan code 			
		ld b,0				; b = 0 (no valid ascii equivalent by default)
		
		ld a,l				; move to qualifier part of buffer
		add a,16
		ld l,a
		jr nc,kbhok3
		inc h
kbhok3		ld a,(hl)			; get qualifier status
		
		bit 1,a
		jr nz,gotkdone			; no ASCII conversion if CTRL is pressed
		
		ld hl,keymaps+$100		; ascii conversion table (with "ALT" pressed)	
		bit 3,a
		jr nz,got_kmap	
		ld hl,keymaps			; unshifted key
		and $11			
		jr z,got_kmap
		ld hl,keymaps+$80		; shifted key

got_kmap	ld a,c				; retrieve scan code
		cp $62
		jr nc,gotkdone
		add a,l				; use scancode as index in ascii translation table	
		jr nc,ncfsos		
		inc h
ncfsos		ld l,a
invalsc		ld b,(hl)			; b = ascii version of keycode

gotkdone	ld a,(key_buf_rd_idx)		; advance the buffer read index one byte
		inc a				; and return with keypress info in A and B
		and 15
		ld (key_buf_rd_idx),a			
		ld a,c				; restore scancode into a
		pop hl
		ld c,d
		pop de
		ret


;------------------------------------------------------------------------------------

os_get_key_press
	
; Gets a keycode on-the-fly - If one is available in the keyboard buffer	
; Returns scancode in A (0 if no scancode in buffer)	
; Returns ASCII code translation in B (0 if no code or invalid ascii translation)
; (ASCII code is modifed by shift key status)


		push de
		ld d,c
		push hl
		call get_kb_buffer_indexes	; HL = buffer read index. A = buffer write index
		cp (hl)				; compare..
		jr nz,new_key			; if read and write indexes are not same, there's a keypress
		xor a			
		ld b,a
		pop hl
		ld c,d
		pop de
		ret

;--------------------------------------------------------------------------------

get_kb_buffer_indexes


		ld hl,key_buf_wr_idx		; buffer write index			
		ld a,(key_buf_rd_idx)		; buffer read index
		ret


get_buffer_loc

		ld hl,scancode_buffer	
		add a,l
		jr nc,kbblncar
		inc h
kbblncar	ld l,a
		ret
		
;--------------------------------------------------------------------------------
