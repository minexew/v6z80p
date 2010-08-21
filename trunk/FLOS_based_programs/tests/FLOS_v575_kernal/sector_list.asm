; Shows how to Obtain a list of the sectors a file occupies

;---Standard header for OSCA and FLOS ----------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"


	org $5000

;-----------------------------------------------------------------------------------------
	
	ld hl,sector_list
	ld (sector_list_addr),hl		
	ld hl,0
	ld (sector_count),hl
	
	ld hl,filename
	call kjt_find_file
	or a
	ret nz
	ld (length_hi),ix
	ld (length_lo),iy
	ld (cluster),de			;first cluster used for file
	xor a
	ld (sector),a			;init sector in cluster = 0

nxt_sec	ld a,(sector)			;A  = sector within the cluster
	ld de,(cluster)			;DE = cluster location
	call kjt_file_sector_list		;obtain a sector number, updating A and DE for next sector 
	ld (cluster),de			;also, HL returns pointing to LSB of LBA (4 bytes)
	ld (sector),a

	ld de,(sector_list_addr)		;copy the LBA to my sector list
	ld bc,4
	ldir
	ld (sector_list_addr),de
	
	ld hl,(sector_count)
	inc hl
	ld (sector_count),hl
		
	ld hl,(length_lo)			;subtract a sector (512 bytes) from length of file
	ld bc,512
	xor a
	sbc hl,bc
	ld (length_lo),hl
	ld hl,(length_hi)		
	ld bc,0
	sbc hl,bc
	ld (length_hi),hl
	jr c,lst_sec			;if there's a carry, end of file
	ld hl,(length_lo)
	ld a,h
	or l
	ld hl,(length_hi)
	or h
	or l				;or if length of file is now zero, end of file
	jr nz,nxt_sec			

lst_sec	



dest equ $8000

	ld hl,dest			;now read in the files by loading the sectors from list
	ld (dest_addr),hl
	ld ix,sector_list

rseclp	ld e,(ix)
	ld d,(ix+1)
	ld c,(ix+2)
	ld b,(ix+3)
	xor a
	push ix
	call kjt_read_sector
	pop ix

	ld bc,4
	add ix,bc
	
	ld de,(dest_addr)			;copy the sector to dest
	ld hl,sector_buffer
	ld bc,512
	ldir
	ld (dest_addr),de
	
	ld hl,(sector_count)
	dec hl
	ld (sector_count),hl
	ld a,h
	or l
	jr nz,rseclp

	xor a
	ret
	
;-----------------------------------------------------------------------------------------

filename	db "test2.bin",0

length_lo	dw 0
length_hi	dw 0

sector	db 0
cluster	dw 0

sector_list_addr	dw 0

sector_count	dw 0

dest_addr		dw 0

;-----------------------------------------------------------------------------------------

		org $5100

sector_list 	db 0

;-----------------------------------------------------------------------------------------
