
;---------------------------------------------------------------------------------------------------
; "load_to_sprite_ram" - loads file from sd card direct to sprite RAM (no sysram buffer required)
;---------------------------------------------------------------------------------------------------
; SET:
; ----
; HL = location of filename (in current dir)
; C:DE = destination address (flat, linear) in sprite RAM ($0-$1ffff)
;
; ZF set on return if all OK, else A = disk error code
;
; Notes:
; ------
; Trashes all registers
; Changes value of "vreg_vidpage" (not restored)
; Temp opens sprite window at $1000-$1fff for writes (closed on return)
; Make sure non-FLOS stack (if used) is not located between $1000-$1fff
; Make sure non-FLOS IRQ code (if used) does not alter "vreg_vidpage" or any locations between $1000-$1fff
; If IRQ code changes "sys_mem_select" it must restore it.
;---------------------------------------------------------------------------------------------------


load_to_sprite_ram
		
		ex de,hl				; convert flat address to 4KB_page and cpu_address
		push hl
		ld a,c
		ld b,4
lsr_pagelp	add hl,hl
		rla
		djnz lsr_pagelp
		or $80
		ld (vreg_vidpage),a
		ld (lsr_sprpage),a
		pop hl
		ld a,h
		and $0f
		or  $10
		ld h,a
		ld (lsr_spraddr),hl
		ex de,hl
		
		in a,(sys_mem_select)			; page in sprite window (for writes) at $1000-$1fff
		ld (lsr_orig_mem_select),a
		or %10000000
		out (sys_mem_select),a
		
		call kjt_open_file
		jr nz,lsr_exit
		ld (lsr_remaining),iy
		ld (lsr_remaining+2),ix
		
lsr_loadloop	ld de,(lsr_remaining)
		ld a,(lsr_remaining+2)			; if remaining bytes in file >= 4096, set load length to 4096
		or a
		jr nz,lsr_setmaxl
		ld a,d
		cp $10
		jr c,lsr_llok
lsr_setmaxl	ld de,$1000

lsr_llok	ld hl,(lsr_spraddr)			; will proposed read length overlap end of Sprite window?
		dec de
		add hl,de
		inc de
		ld a,h
		cp $20
		jr c,lsr_isprwok
		ld hl,$2000				; if so, truncate load length on this pass
		ld de,(lsr_spraddr)
		xor a
		sbc hl,de
		ex de,hl
		
lsr_isprwok	ld (lsr_bytes_to_load),de
		push de
		pop iy
		ld ix,0
		call kjt_set_load_length
				
		ld b,0					; load data directly to sprite window
		ld hl,(lsr_spraddr)
		call kjt_read_from_file
		jr nz,lsr_exit
				
lsr_loadok	ld hl,(lsr_remaining)			; subtract bytes_to_load from remaining bytes
		ld a,(lsr_remaining+2)
		ld bc,(lsr_bytes_to_load)
		or a
		sbc hl,bc
		sbc a,0
		ld (lsr_remaining),hl
		ld (lsr_remaining+2),a
		or h
		or l
		jr nz,lsr_morebytes			; have all bytes been loaded?	
		xor a					; all done, quit without error
		
lsr_exit	push af
		ld a,(lsr_orig_mem_select)		; restore original mem_select value
		out (sys_mem_select),a
		pop af
		ret
		
lsr_morebytes	ld a,(lsr_sprpage)			; next sprite page
		inc a
		ld (lsr_sprpage),a
		ld (vreg_vidpage),a
		ld hl,$1000
		ld (lsr_spraddr),hl
		jr lsr_loadloop
		
		
lsr_bytes_to_load	dw 0
lsr_remaining		dw 0,0
lsr_sprpage		db 0
lsr_spraddr		dw 0
lsr_orig_mem_select	db 0

;-------------------------------------------------------------------------------------------------
	
	