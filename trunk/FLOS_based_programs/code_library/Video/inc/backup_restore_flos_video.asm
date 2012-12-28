
;-----------------------------------------------------------------------------------------------------

backup_flos_video 

; Mainly for old programs - copy FLOS video $10000-$1ffff to $60000
		
		ld bc,$0106
dofvblit	call blit64
		xor a				;restore blit MSBs to 0 (for backwards compatibility)
		ld (blit_src_msb),a
		ld (blit_dst_msb),a
		ret
		

restore_flos_video

; Mainly for old programs - copy stored FLOS display data from $60000-$6ffff to $10000

		ld bc,$0601
		jr dofvblit

;-----------------------------------------------------------------------------------------------------

blit64		xor a                         ;put source modulo in A 
		ld (blit_src_mod),a           ;set source modulo
		ld (blit_dst_mod),a           ;set dest modulo 

		ld h,a                        ;source is at VRAM $00000
		ld l,a
		ld (blit_src_loc),hl          ;set source address [15:0]
		ld (blit_dst_loc),hl          ;set dest address [15:0]
		
		ld a,b                        ;put source address in A:HL
		ld (blit_src_msb),a           ;set source address MSB [18:16]
		ld a,c                        ;put dest address in A:HL
		ld (blit_dst_msb),a           ;set dest address MSB [18:16]
					    
		ld a,%01000000                ;set blitter control to ascending mode, modulo 
		ld (blit_misc),a              ;high bits set to zero, transparency: off

		ld a,256-1                    ;put height-1 of blit in A
		ld (blit_height),a            ;set height of blit
		ld (blit_width),a             ;set width of blit and start blit 
		nop
		nop
waitbl64	in a,(sys_vreg_read)          
		bit 4,a                       ;make sure blitter is not busy
		jr nz,waitbl64
		ret
		   
;-------------------------------------------------------------------------------------------------------------