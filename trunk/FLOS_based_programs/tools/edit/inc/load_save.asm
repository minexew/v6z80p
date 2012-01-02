;------------------------------------------------------------------------------------------------------

save_req	ld hl,filename
	ld b,7
	ld c,1
	call save_requester
	jr z,commence_save
	cp $ff				;aborted?
	ret z
sav_error	or a
	jr nz,fil_error
dhw_error	call hw_error_requester
	jr save_req
fil_error	call file_error_requester
	jr save_req


commence_save


	call hl_to_filename
	ld hl,filename
	call kjt_create_file
	jr nz,fil_error
	
	ld hl,saving_txt
	xor a
	call alert_box
	
	ld a,16				;start at video page 16 (IE: $20000)
sf_nxtp	ld (vid_bank),a
	ld (vreg_vidpage),a
	call kjt_page_in_video
	ld hl,$2000			;copy an 8KB page of VRAM to work buffer in sysram
	ld bc,8192
	ld de,work_buffer
	ldir
	call kjt_page_out_video

	ld hl,(save_length)			
	ld a,(save_length+2)
	ld de,8192
	or a
	sbc hl,de				;will this be the last 8KB chunk to save?
	sbc a,0
	jr c,sf_lastpage
	ld (save_length),hl
	ld (save_length+2),a
	or h
	or l
	jr z,sf_lastpage
		
	ld ix,work_buffer			;source address
	ld b,0	
	ld de,8192			;c:de = save length of chunk
	ld c,0
	ld hl,filename
	call kjt_write_to_file		;append data to file
	jp nz,fil_error
	ld a,(vid_bank)			;get chunk from next video page
	inc a
	jr sf_nxtp

sf_lastpage

	add hl,de				;how many bytes left to save?
	ex de,hl
	ld c,0
	ld ix,work_buffer
	ld b,0
	ld hl,filename
	call kjt_write_bytes_to_file
	ret z
	jp fil_error
	
	
save_length	dw 0,0


	
;--------------------------------------------------------------------------------------


load_req	call update_text_file	;in case user cancels 

	ld hl,filename		;default filename
	ld b,7
	ld c,1
	call load_requester
	jr z,commence_load
	cp $ff
	ret z
	or a
	jr z,l_hwerror
load_err	call file_error_requester
	jr load_req
l_hwerror	call hw_error_requester
	jr load_req

	
commence_load
	
	ld a,(hl)			; hl points to filename at this point
	or a
	jp z,new_document
	call hl_to_filename		; replace with filename from requester in case its changed
	ld hl,filename		; does filename exist?
	call kjt_find_file		; if not, make a new document (but use the filename specified)
	jp nz,new_doc_same_filename		
	ld (file_length),iy		; LSW
	ld (file_length+2),ix	; MSW
	
	ld hl,loading_txt
	xor a
	call alert_box
	
	ld a,16
	ld (vid_bank),a		; data to load at video RAM $20000 onwards

vrloadlp	ld ix,0
	ld iy,8192
	call kjt_set_load_length	; load buffer (in system RAM) is 8k
	
	ld hl,work_buffer
	ld b,0
	call kjt_read_from_file	; load 8KB of file into buffer
	
	push af
	ld a,(vid_bank)
	ld (vreg_vidpage),a
	call kjt_page_in_video	; copy buffer to VRAM
	ld hl,work_buffer
	ld de,$2000		; IE: video_ram_window
	ld bc,8192
	ldir
	call kjt_page_out_video
	pop af
	jr nz,load_done		; will give EOF error at end of file 
	
	ld a,(vid_bank)
	inc a
	ld (vid_bank),a
	cp 64
	jr nz,vrloadlp

ftoobig	ld hl,file_too_big_txt
	ld a,1
	call alert_box
	call kjt_wait_key_press
	jp new_document
	
load_done	ld a,(file_length+2)
	ld hl,(file_length)
	add a,2
	ld (vram_text_end),hl
	ld (vram_text_end+2),a	; Flat address in VRAM where text ends (last char+1)
	
	call ahl_flat_to_vram_paged
	ld (vreg_vidpage),a
	call kjt_page_in_video
	ld (hl),0			;put a zero at end of file
	call kjt_page_out_video	
	
	xor a
	ld (cursor_y),a
	ld (cursor_x),a
	ld (char_pos),a

	xor a
	ret


;-----------------------------------------------------------------------------------------------
	

new_document

	ld hl,new_doc_txt
	call hl_to_filename

new_doc_same_filename
	
	ld hl,0
	ld (file_length),hl		
	ld (file_length+2),hl	
	ld hl,1
	ld (goto_line),hl
	jp load_done


;-----------------------------------------------------------------------------------------------------------------

hl_to_filename


	ld de,filename		; copy text at hl to filename string
	ld b,16
fnclp	ld a,(hl)
	or a
	jr z,fncdone
	cp " "
	jr z,fncdone
	ld (de),a
	inc hl
	inc de
	djnz fnclp
fncdone	xor a
	ld (de),a			; null terminate filename
	ret
	
;--------------------------------------------------------------------------------------

get_file_size

	ld de,0			;text data starts at VRAM $20000
	ld c,2
	ld hl,(vram_text_end)
	ld a,(vram_text_end+2)
	or a			;filesize (does not include terminating zero)
	sbc hl,de
	sbc a,c
	jp c,flen_err
	ld (save_length),hl
	ld (save_length+2),a
	or h
	or l
	ld a,(save_length+2)
	ret			;ZF is set if FL = 0

flen_err	xor a			;ZF is also set if FL < 0 for some reason
	ret
	
;--------------------------------------------------------------------------------------

vid_bank	  	db 0

file_length	dw 0,0

filename		ds 16,0

new_doc_txt	db "NEW.TXT",0
		
;--------------------------------------------------------------------------------------