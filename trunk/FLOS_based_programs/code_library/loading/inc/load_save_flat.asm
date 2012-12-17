
;-----------------------------------------------------------------------------------------------------
; "load_flat" - Load file to system RAM using flat memory address
;
; Set:
; A:HL = Dest address ($0-$7ffff)
; IY   = Location of filename
;-----------------------------------------------------------------------------------------------------

		
load_flat	call convert_flat_to_banked
		push hl
		pop ix
		ld b,a
		push iy
		pop hl
		call kjt_load_file
		ret


;------------------------------------------------------------------------------------------------------
; "save_flat" - Save file from system RAM using flat memory address
;
; Set:
; A:HL = Sysram source address ($0-$7ffff)
; C:DE = Number of bytes to save
; IY   = Location of filename
;-----------------------------------------------------------------------------------------------------


save_flat	call convert_flat_to_banked
		push hl
		pop ix
		ld b,a
		push iy
		pop hl
		call kjt_save_file
		ret


;-------------------------------------------------------------------------------------------------------

convert_flat_to_banked

		push hl			;in: a:hl= flat addr, out: a=flos bank / hl=addr
		add hl,hl
		pop hl
		rl a
		ret z
		dec a
		set 7,h
		ret
		
;--------------------------------------------------------------------------------------------------------
