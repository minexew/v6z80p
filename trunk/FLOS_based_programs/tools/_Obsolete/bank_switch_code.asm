
	org 0
	
	di
	ld hl,relocate_code
	ld de,$4000
	ld bc,end_of_relocate_code-relocate_code
	ldir
	jp $4000

relocate_code

	ld a,0
	out (127),a
	rst 0

end_of_relocate_code
