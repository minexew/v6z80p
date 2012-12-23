;---------------------------------------------------------------------------------------
; Unpacks V6Z80P RLE format packed data to video RAM using flat address for destination
; version: 0.01
;
; Notes:
; Source file must fit in continuous Z80 address space (routine cannot handle source banking)
; Video window assumed to be at default $2000-$3fff
;----------------------------------------------------------------------------------------

unpack_to_vram

;set A:DE = flat VRAM RAM address (0-$7ffff)
;set HL = Z80 source address of packed file
;set BC = length of packed file in bytes
	
		ex de,hl			; convert flat address to 8KB_page and cpu_address
		push bc
		push hl
		
		ld b,3
unpvid_lp	add hl,hl
		rla
		djnz unpvid_lp
		ld (vreg_vidpage),a		; set init video page
		exx
		ld b,a
		exx
		
		pop hl
		pop bc 
		ex de,hl
		ld a,d
		and %00011111
		or  %00100000
		ld d,a
		in a,(sys_mem_select)
		or %01000000
		out (sys_mem_select),a        ; page in video memory
		
		dec bc                        ; packed file length less 1 to skip match token
		push hl
		pop ix	
          
		inc hl
unpv_gtok  	ld a,(ix)                     ; get token byte
unpv_next 	bit 6,d                       ; test for next video page (assumes video window at $2000)
		jp z,unpv_nchsb1
		exx
		inc b
		ld a,b
		ld (vreg_vidpage),a
		exx
		ld d,$20
		ld a,(ix)
unpv_nchsb1   	cp (hl)                       ; is byte at source location same as token?
		jr z,unpv_brun                ; if it is, there's a byte run to expand
		ldi                           ; if not, simply copy this byte to destination
		jp pe,unpv_next               ; last byte of source?
		jr unpv_end
          
unpv_brun  	push bc                       ; stash B register
		inc hl              
		ld a,(hl)                     ; get byte value
		inc hl              
		ld b,(hl)                     ; get run length
		inc hl
          
unpv_rllp 	ld (de),a                     ; write byte value, byte run length
		inc de              
		bit 6,d                       ; test for next sprite page
		jp z,unpv_nchsb2
		ld c,a
		exx
		inc b
		ld a,b
		ld (vreg_vidpage),a
		exx
		ld d,$20
		ld a,c
unpv_nchsb2    	djnz unpv_rllp
          
		pop bc    
		dec bc                        ; last byte of source?
		dec bc
		dec bc
		ld a,b
		or c
		jp nz,unpv_gtok
	
unpv_end 	in a,(sys_mem_select)         ; page out video window
		and %10111111
		out (sys_mem_select),a        
		ret

;--------------------------------------------------------------------------------------------------
