
;-----------------------------------------------------------------------------------------------------

save_dir_vol

	push af
	push hl
	push de
	push bc
	
	call kjt_get_volume_info
	ld (orig_vol),a
	call kjt_get_dir_cluster
	ld (orig_dir),de
	
	pop bc
	pop de
	pop hl
	pop af
	ret
	
	
restore_dir_vol

	push af
	push hl
	push de
	push bc

	ld a,(orig_vol)
	call kjt_change_volume
	ld de,(orig_dir)
	call kjt_set_dir_cluster

	pop bc
	pop de
	pop hl
	pop af
	ret
	
orig_dir	dw 0

orig_vol	db 0

;-----------------------------------------------------------------------------------------------------