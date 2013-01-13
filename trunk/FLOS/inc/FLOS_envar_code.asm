;--------------------------------------------------------------------------------------------
; Environment variable code
;--------------------------------------------------------------------------------------------

os_get_envar

;Set: 	HL = name of required variable (null terminated string, 4 ascii bytes max)

;Returns:	HL = address of variable data
;         ZF = Not Set: Couldn't find variable (A = $2b)


		ld c,max_envars
		ld de,env_var_list

ev_find		ld b,4
		push bc
		call os_compare_strings
		pop bc
		jr nc,ev_notsam
		ex de,hl
		ld a,l
		add a,4
		ld l,a
		xor a
		ret
	
ev_notsam	ld a,e					;next envar address
		add a,8
		ld e,a
		dec c
		jr nz,ev_find
	
		ld b,max_envars
		ld hl,env_var_list
		ld a,$2b				;ZF not set, didnt find envar
		or a
		ret


;--------------------------------------------------------------------------------------------

os_set_envar

;HL = addr of variable name (4 bytes max ASCII, zero terminated)
;DE = addr of data for variable (4 bytes max)

;Returns:

;ZF = Not Set: No enough space for new variable (A = $2c)

		push de
		push hl				;cache new data location on stack
		call os_delete_envar			;remove existing var of this name (doesnt matter if didn't exist)
		
		ld hl,env_var_list			;find a free slot
		ld de,8	
		ld b,max_envars				;max number of environment vars
ev_fsp		ld a,(hl)
		or a
		jr z,ev_wrdat
		add hl,de
		djnz ev_fsp
		pop hl					;level the stack
		pop de					;""           ""
		ld a,$2c
		or a					;zf not set, no space for new var
		ret
		
ev_wrdat	call page_out_hw_registers
		ex de,hl
		pop hl					;pop name loc off stack
		ld bc,4
		ldir
		pop hl					;pop data loc off stack
		ld bc,4
		ldir
env_wrend	call page_in_hw_registers
		xor a
		ret
		
;--------------------------------------------------------------------------------------------

os_delete_envar

;Set    :	HL = name of required variable (null terminated string, 4 bytes max)
;Returns: Nothing relevent

		call os_get_envar
		ret nz
		ld a,l
		and $f8
		ld l,a
		call page_out_hw_registers
		xor a
		ld (hl),a				;zero first byte = entry is available
		jr env_wrend


;-------------------------------------------------------------------------------------------

os_remove_assigns

		ld hl,env_var_list			;remove any envars that are assignments
		ld b,max_envars				;this is mainly used for the mount command
ev_dasgn	ld a,(hl)				;(disk swaps invalidate assigns).
		cp "%"
		jr nz,ev_nasgn

		push hl
		push bc
		call os_delete_envar
		pop bc
		pop hl

ev_nasgn	ld de,8	
		add hl,de
		djnz ev_dasgn
		ret
;-------------------------------------------------------------------------------------------

