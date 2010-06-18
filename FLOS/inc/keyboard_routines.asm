;---------------------------------------------------------------------------------------
; CORE KEYBOARD ROUTINES V6.02
;---------------------------------------------------------------------------------------

os_wait_key_press

; Busy waits for a keypress.
; Handles the following modifier keys (key_mod_flags):
;
; Bit 0 = Left shift (12)
;     1 = Left/Right CTRL (14)
;     2 = Left GUI (1F)
;     3 = Left/Right Alt (11)
;     4 = Right shift (59)
;     5 = Right GUI (27)
;
; Returns scancode in A and ASCII code in B (B=$00 if no valid ascii char)
; (ASCII code is modifed by shift / alt key status)


	push de
	ld d,c
	push hl
wait_kbuf	call get_kb_buffer_indexes	; HL = buffer read index. A = buffer write index
	cp (hl)			; if read and write indexes are same, buffer is empty
	jr z,wait_kbuf		; (or is currently accepting a sequence of keycode bytes)

	call get_buffer_loc		; HL = location in scancode buffer
	ld a,(hl)			; get first byte of scan code 			
	ld b,0			; set b = 0 (no valid ascii equivalent by default)
	ld c,a			; c = scan code
	cp $f0			; is this a key release byte? 
	jr nz,not_key_rel
	call key_released		; handle it and then return to waiting for a key *PRESS*
	jr wait_kbuf		; 
		
not_key_rel

	call find_qual		; not a release code, next check modifier keys
	jr nz,notqualon
	ld a,(key_mod_flags)
	or e			; set the appropriate bit
	ld (key_mod_flags),a	
	jr gotkdone		; exit wait loop and return with keycodes
	
notqualon	ld hl,keymaps+$100		; select appropriate ascii conversion table	
	ld a,(key_mod_flags)		
	bit 3,a
	jr nz,got_kmap	
	ld hl,keymaps		; unshifted
	and $11			
	jr z,got_kmap
	ld hl,keymaps+$80		; shifted 
got_kmap	ld a,c			; retrieve scan code
	cp $62
	jr nc,invalsc
	add a,l			; use scancode as index in ascii translation table	
	jr nc,ncfsos		
	inc h
ncfsos	ld l,a
invalsc	ld b,(hl)			; b = ascii version of keycode

gotkdone	ld a,(key_buf_rd_idx)	; advance the buffer read index one byte
	inc a			; and return with keypress info in A and B
	and 31
	ld (key_buf_rd_idx),a			
	ld a,c			; restore scancode into a
	pop hl
	ld c,d
	pop de
	ret


key_released

	call get_kb_buffer_indexes	; HL = buffer read index. A = buffer write index
	inc a			; advance the read index one byte to find released key
	and 31
	ld (key_buf_rd_idx),a		
	cp (hl)			; if at end of buffer go no further as something
	ret z			; has gone wrong
	
	call get_buffer_loc		; HL = location in scancode buffer. The next byte in the 
	ld a,(hl)			; buffer should be the code for the key which was released.
	cp $f0			; If this is a release code too, something went
	jr z,key_released		; spoony - loop until find the release code
		
gotrelkey	call find_qual		; its a release code, check modifier keys
	jr nz,notqloff
	ld a,e
	cpl
	ld e,a
	ld a,(key_mod_flags)	; clear the appropriate bit
	and e
	ld (key_mod_flags),a	
	
notqloff	ld a,(key_buf_rd_idx)	; advance the buffer read index one byte
	inc a
	and 31
	ld (key_buf_rd_idx),a
	ret			


;------------------------------------------------------------------------------------


find_qual	ld hl,qualifiers
	ld e,$40
fq_loop	cp (hl)
	ret z			;zero flag set if found a match, qual bit in d
	inc hl
	srl e
	jr nz,fq_loop
	inc e			;zero flag not set if didnt find a match
	ret

	
qualifiers 
	db $2f,$27,$59,$11,$1f,$14,$12


;------------------------------------------------------------------------------------

os_get_key_press
	
; Gets a keycode on-the-fly if one is available	
; Returns scancode in A (0 if no scancode in buffer)	
; Returns ASCII code translation in B (0 if no code or invalid ascii translation)
; (ASCII code is modifed by shift key status)


	push de
	ld d,c
	push hl
	call get_kb_buffer_indexes	; HL = buffer read index. A = buffer write index
	cp (hl)			; compare..
	jr z,kbbufie		; if read and write indexes are same, buffer is empty
	
	call get_buffer_loc		; HL = location in scancode buffer
	ld a,(hl)			; get first byte of scan code 			
	ld b,0			; set b = 0 (no valid ascii equivalent by default)
	ld c,a			; c = scan code
	cp $f0			; is this a key release byte? 
	jp nz,not_key_rel		; process/exit via normal press key handling routine
	call key_released		; handle it and then return with no key data

kbbufie	xor a			; returns 0 in A and B if no key in buffer
	ld b,a
	pop hl
	ld c,d
	pop de
	ret

;--------------------------------------------------------------------------------

get_kb_buffer_indexes


	ld hl,key_buf_wr_idx	; buffer write index			
	ld a,(key_buf_rd_idx)	; buffer read index
	ret


get_buffer_loc

	ld hl,scancode_buffer	
	add a,l
	jr nc,kbblncar
	inc h
kbblncar	ld l,a
	ret
		
;--------------------------------------------------------------------------------
