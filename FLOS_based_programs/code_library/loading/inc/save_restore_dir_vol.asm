;---------------------------------------------------------------------------------------
; Book-end routines to store all directory positions for all the volumes.
; This is achieved by reading the current cluster position and it is
; assumed the volumes and dirs remain unchanged (ie: not deleted) during the
; operation between them
;---------------------------------------------------------------------------------------

save_dir_vol

		push af				; these book-end routines assume the volumes and
		push bc				; dirs remain unchanged (ie: not deleted) during the
		push de				; operation between them
		push hl
		push ix
		push iy
		call kjt_get_volume_info
		ld (srdv_orig_vol),a

		ld hl,orig_cluster_list
		xor a
sadv_lp1	push af
		push hl
		call kjt_change_volume
		call kjt_get_dir_cluster
		pop hl
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
stodv_novol	pop af
		inc a
		cp 10
		jr nz,sadv_lp1
		jr restore_orgvol			;start program in the volume original active




restore_dir_vol

		push af				; these book-end routines assume the volumes and
		push bc				; dirs remain unchanged (ie: not deleted) during the
		push de				; operation between them
		push hl
		push ix
		push iy
		
		ld hl,orig_cluster_list
		xor a
rodv_lp		push af
		push hl
		call kjt_change_volume
		pop hl
		jr z,rodv_volok
		inc hl
		inc hl
		jr skprestdir
rodv_volok	ld e,(hl)
		inc hl
		ld d,(hl)
		inc hl
		call kjt_set_dir_cluster
skprestdir	pop af	
		inc a
		cp 10
		jr nz,rodv_lp
		
restore_orgvol	ld a,(srdv_orig_vol)
		call kjt_change_volume
		pop iy
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		ret


orig_cluster_list

		ds 20,0

srdv_orig_vol	db 0

;-----------------------------------------------------------------------------------------------------