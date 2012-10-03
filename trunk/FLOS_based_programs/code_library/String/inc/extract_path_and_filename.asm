;--------------------------------------------------------------------------------------

extract_path_and_filename

; Makes two new strings called FILENAME_TXT and PATH_TXT containing the
; relevent sections from a source string,

; EG: HL (Source)  = "VOL0:HATS/BERETS/RASP.BIN"
;     Filename_txt = "RASP.BIN"
;     Path_txt     = "VOL0:HATS/BERETS/"
;
; Note: If source string does not end in a "/" then the last delineated part is taken as
; the filename.

; USE:
; ----
; Set up "max_path_length" equate (normally 40)
;
; Set HL to path/filename string (null or space terminates parsing)
; HL/DE/BC preserved
; If ZF set on return, OK, else path was too long for buffer (A=$15, error "Filename too long")


	push hl
	push de
	push bc
	
	push hl			;push source string addr
	
	push hl
	ld hl,filename_txt		;clear filename and path buffers
	ld bc,13
	xor a
	call kjt_bchl_memfill
	ld hl,path_txt
	ld bc,max_path_length
	xor a
	call kjt_bchl_memfill
	pop hl
	
	
pth_mark	ld e,l
	ld d,h
pth_lp1	ld a,(hl)
	or a
	jr z,pth_end		;null or space terminates the path/filename string
	cp $20
	jr z,pth_end
	inc hl
	cp $2f			;ie: "/"
	jr z,pth_mark
	cp ":"
	jr z,pth_mark
	jr pth_lp1
	
	
pth_end	push de			;push split address from DE	
	ld hl,filename_txt
	ld b,12
pth_fnlp	ld a,(de)			;copy everything after the last "/" to isolated filename string
	or a
	jr z,pth_fend
	cp " "
	jr z,pth_fend
	ld (hl),a
	inc de
	inc hl
	djnz pth_fnlp
pth_fend	pop hl			;pop split address into HL

	pop de			;pop source string address into DE
	xor a
	sbc hl,de			;if path part is 0 chars long, nothing to copy
	jr z,pth_done
	ld b,h
	ld c,l
	ld hl,max_path_length
	xor a
	sbc hl,bc
	jr nc,pth_mlok
	ld a,$15
	or a
	ret
	
pth_mlok	ex de,hl			;hl = source string address
	ld de,path_txt		;de = dest for path part
	ldir			;bc - length of path section.. copy to isolated string
	
pth_done	pop bc
	pop de
	pop hl
	xor a
	ret
		

;----------------------------------------------------------------------------------------

path_txt	ds max_path_length,0
	db 0
	
filename_txt

	ds 13,0
	
;--------------------------------------------------------------------------------------
	
	
