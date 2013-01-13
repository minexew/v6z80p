;-----------------------------------------------------------------------------------------------
; Common routines called by internal commands
;-----------------------------------------------------------------------------------------------

os_bad_args_error
		
		ld a,$12
		or a
		ret
		
os_no_fn_error	

		ld a,$0d
		or a
		ret

os_no_start_addr
		
		ld a,$16
		or a
		ret

os_invalid_bank	

		ld a,$21
		or a
		ret
	
os_range_error	

		ld a,$1e
		or a
		ret

os_no_args_error

		ld a,$1f
		or a
		ret	

os_invalid_device

		ld a,$22
		or a	
		ret


;----------------------------------------------------------------------------------------------------------------------


fileop_preamble
				
		ld a,(hl)				;check args actually exist
		or a
		jr z,fop_nofn2	

		push hl				;note: on exit HL points at start of filename (not path)
		ld d,h
		ld e,l
path_finder	ld a,(hl)				;split path and filename from HL
		or a
		jr z,pf_end				;look for end of path/filename string (space or null)
		cp " "
		jr z,pf_end
		inc hl
		jr path_finder

pf_end		dec hl					;now go back and look for seperator ":", "/" or "\"
		ld a,(hl)
		cp ":"
		jr z,pf_start
		call compare_slashes			; "/" or "\" ?
		jr z,pf_start		
		cp " "
		jr z,pf_start				; a space prefix = char before start of string
		push hl				
		xor a
		sbc hl,de				; dont go back further than first character!
		pop hl
		jr nz,pf_end
		dec hl
			
pf_start	inc hl
		ld d,h
		ld e,l					; DE = filename part address

		ld c,(hl)				; temporarily put "<space>,<null>" at end of path part
		ld (hl)," "
		inc hl
		ld b,(hl)
		ld (hl),0
		
		pop hl					; retrieve original HL
		
		push hl
		xor a
		sbc hl,de
		pop hl
		jr nz,pf_haspth			
		ld hl,null_txt				; if path addr = fn addr, no path to parse: give it a dummy path		
		inc a
		
pf_haspth	xor 1
		ld (path_flag),a
		push bc
		push de
		call cd_parse_path
		pop hl
		pop de
		
		ld (hl),e				; restore characters at split point (dont use B reg, as may be used
		inc hl					; for driver error code)
		ld (hl),d
		dec hl
		ret nz					; return already if error from path parsing
		
		ld a,(hl)				; otherwise examine filename
		cp " "					; is one present?
		jr z,fop_nofn
		xor a
		ret
		
fop_nofn	call cd_restore_vol_dir			; need to restore dir as calling routine will exit before the fileop

fop_nofn2	ld a,$0d				; missing filename error
		or a
		ret

;-------------------------------------------------------------------------------------------

os_dont_store_registers

		xor a
		ld (store_registers),a
		ret

;-------------------------------------------------------------------------------------------

hexword_or_bust

; Set HL to string address:
; Returns to parent routine ONLY if the string is valid hex (OR no hex found) in which case:
; DE = hex word. 
; If no hex found, the zero flag is set (and A = error code $1f)
; If chars are invalid hex, returns to grandparent (IE: main OS) with error code

		call ascii_to_hexword		
		cp $1f
		ret z

		or a
		jr nz,bad_hex
		inc a				; returns with ZF NOT set if valid hex
		ret

bad_hex		pop hl				; remove parent return address from stack
		or a	
		ret			 
	
;------------------------------------------------------------------------------------------		


get_start_and_end

		call ascii_to_hexword			;get start address
		ld (cmdop_start_address),de
		inc hl
		jr z,st_addrok
		pop hl					;this pop is remove originating call addr from the stack
		cp $1f					;bad hex error code
		jr nz,c_badhex
		ld a,$16				;no start address error code
c_badhex	or a
		ret
	
st_addrok	call ascii_to_hexword			;get end address
		ld (cmdop_end_address),de
		inc hl
		ret z
		pop hl					;this pop is remove originating call addr from the stack
		cp $1f					;bad hex error code
		jr nz,c_badhex
		ld a,$1c				;no end address error code
		ret
	
;------------------------------------------------------------------------
		