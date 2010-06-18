; Check if current playercall must be proccessed
; out: CF 1 - yes, current playercall must be proccessed
;      CF 0 - no, current playercall must be omited
is_this_playercall_must_be_proccessed
	call is_current_videomode_50Hz	
	ret c				; return immediately, if we are in 50Hz mode 
					; here, we are in 60Hz mode
	call is_current_60Hz_frame_must_be_proccessed
	ret

; This routine must be called only in 60Hz mode.
; Routine check if current frame must be proccessed or omited.
; Each 6th frame is omited.
; out: CF 1 - yes, current frame must be processed 
;      CF 0 - no,  current frame must be omited
is_current_60Hz_frame_must_be_proccessed
	ld a,(player_frame_counter)
	cp 5				; is this a 6th frame ?
	jr nz,regularFrame
	or a
	ret
regularFrame
	scf
	ret

; out: CF 1 - yes, 50Hz video mode active
;      CF 0 - no,
is_current_videomode_50Hz
	ld a,(vreg_read)
	and 32				; 60Hz flag
	jr z, curr_vmode_50Hz
	or a
	ret
curr_vmode_50Hz	
	scf
	ret

advance_60Hz_to_50Hz_counter
	ld a,(player_frame_counter)	; advance counter (counter is used by "60Hz fix" routines)
	inc a				
        cp 6				
	jr nz,plr_l1
	xor a
plr_l1	ld (player_frame_counter),a
        ret


player_frame_counter db 0
