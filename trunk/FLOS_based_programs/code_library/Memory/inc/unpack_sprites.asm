;---------------------------------------------------------------------------------------
; Unpacks V6Z80P RLE format packed data to sprite RAM using flat address for sprite destination
; version: 0.02
;
; Notes:
; Source file must fit in continuous Z80 address space (routine cannot handle source banking)
;----------------------------------------------------------------------------------------

unpack_sprites

;set A:DE = flat sprite RAM address (0-$1ffff)
;set HL = Z80 source address of packed file
;set BC = length of packed file in bytes
	
		ex de,hl			; convert flat address to 4KB_page and cpu_address
		push bc
		push hl
		ld b,4
unps_lp		add hl,hl
		rla
		djnz unps_lp
		or $80
		ld (vreg_vidpage),a		; set init sprite page
		exx
		ld b,a
		exx
		pop hl
		pop bc 
		ex de,hl
		ld a,d
		and $0f
		or  $10
		ld d,a
		in a,(sys_mem_select)
		and $1f
		or $80
		out (sys_mem_select),a        ; page in sprite memory
		
		dec bc                        ; packed file length less 1 to skip match token
		push hl
		pop ix	
          
		inc hl
unp_gtok  	ld a,(ix)                     ; get token byte
unp_next 	bit 5,d                       ; test for next sprite page
		jp z,nchsb1
		exx
		inc b
		ld a,b
		or $80
		ld (vreg_vidpage),a
		exx
		ld d,$10
		ld a,(ix)
nchsb1   	cp (hl)                       ; is byte at source location same as token?
		jr z,unp_brun                 ; if it is, there's a byte run to expand
		ldi                           ; if not, simply copy this byte to destination
		jp pe,unp_next                ; last byte of source?
		jr packend
          
unp_brun  	push bc                       ; stash B register
		inc hl              
		ld a,(hl)                     ; get byte value
		inc hl              
		ld b,(hl)                     ; get run length
		inc hl
          
unp_rllp 	ld (de),a                     ; write byte value, byte run length
		inc de              
		bit 5,d                       ; test for next sprite page
		jp z,nchsb2
		ld c,a
		exx
		inc b
		ld a,b
		ld (vreg_vidpage),a
		exx
		ld d,$10
		ld a,c
nchsb2    	djnz unp_rllp
          
		pop bc    
		dec bc                        ; last byte of source?
		dec bc
		dec bc
		ld a,b
		or c
		jp nz,unp_gtok
	
packend  	in a,(sys_mem_select)         ; page out sprite window
		and $7f
		out (sys_mem_select),a        
		ret

;--------------------------------------------------------------------------------------------------
