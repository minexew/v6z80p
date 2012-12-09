
;----------------------------------------------------------------------------------------------
; "load_to_video_ram" - loads file from sd card direct to video RAM (no sysram buffer required)
;----------------------------------------------------------------------------------------------
; SET:
; ----
; HL = location of filename (in current dir)
; C:DE = destination address (flat, linear) in video RAM ($0-$7ffff)
;
; ZF set on return if all OK, else A = disk error code
;
; Notes:
; ------
; Trashes all registers
; Changes value of "vreg_vidpage" (not restored)
; Temp moves vram_location window to $e000-$ffff - replaced to FLOS standard $2000-$3fff on return
; Make sure this routine is not located between $e000-$ffff 
; Make sure non-FLOS IRQ code (if used) is located between $e000-$ffff, that IRQ code does not alter
; "vreg_vidpage", "sys_vram_location" or read/write any locations between $e000-$ffff. 
; If IRQ code changes "sys_mem_select" it must restore it.
; Make sure non-FLOS stackpointer (if used) is not located between $e000-$ffff
;---------------------------------------------------------------------------------------------------


load_to_video_ram
		
		ex de,hl				; convert flat address to 8KB page and video window address
		push hl
		ld a,c
		ld b,3
lvr_pagelp	add hl,hl
		rla
		djnz lvr_pagelp
		ld (vreg_vidpage),a
		ld (lvr_vidpage),a
		pop hl
		ld a,h
		and $1f
		or  $e0
		ld h,a
		ld (lvr_vidaddr),hl
		ex de,hl
		
		ld a,7
		out (sys_vram_location),a		; locate window memory window at Z80 $e000-$ffff
		in a,(sys_mem_select)			 
		ld (lvr_orig_mem_select),a
		or %01000000
		out (sys_mem_select),a			; open the video window in CPU address space
		
		call kjt_open_file
		jr nz,lvr_ferr
		ld (lvr_remaining),iy
		ld (lvr_remaining+2),ix
		
lvr_loadloop	ld de,(lvr_remaining)
		ld a,(lvr_remaining+2)			; if remaining bytes in file >= 8192, set load length to 8192
		or a
		jr nz,lvr_setmaxl
		ld a,d
		cp $20
		jr c,lvr_llok
lvr_setmaxl	ld de,$2000

lvr_llok	ld hl,(lvr_vidaddr)			; will proposed read length overlap end of video window?
		dec de
		add hl,de
		inc de
		jr nc,lvr_ividwok
		ld hl,$0				; if so, truncate load length on this pass
		ld de,(lvr_vidaddr)
		xor a
		sbc hl,de
		ex de,hl
		
lvr_ividwok	ld (lvr_bytes_to_load),de
		push de
		pop iy
		ld ix,0
		call kjt_set_load_length
				
		ld b,0					; load data directly to video window
		ld hl,(lvr_vidaddr)
		call kjt_read_from_file
		jr nz,lvr_ferr
				
lvr_loadok	ld hl,(lvr_remaining)			; subtract bytes_to_load from remaining bytes
		ld a,(lvr_remaining+2)
		ld de,(lvr_bytes_to_load)
		or a
		sbc hl,de
		sbc a,0
		ld (lvr_remaining),hl
		ld (lvr_remaining+2),a
		or h
		or l
		jr nz,lvr_morebytes			; have all bytes been loaded?	
		xor a					; all done, quit with no error
		
lvr_ferr	push af
		ld a,(lvr_orig_mem_select)		; restore original mem_select value
		out (sys_mem_select),a
		ld a,1
		out (sys_vram_location),a		; location video window back at FLOS standard (Z80 $2000)
		pop af
		ret
		
lvr_morebytes	ld a,(lvr_vidpage)			; next video page
		inc a
		ld (lvr_vidpage),a
		ld (vreg_vidpage),a
		ld hl,$e000
		ld (lvr_vidaddr),hl
		jr lvr_loadloop
		
		
lvr_bytes_to_load	dw 0
lvr_remaining		dw 0,0
lvr_vidpage		db 0
lvr_vidaddr		dw 0
lvr_orig_mem_select	db 0

;-------------------------------------------------------------------------------------------------
	
	