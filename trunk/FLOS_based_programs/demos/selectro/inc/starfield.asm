;---------------------------------------------------------------------------------------------------
          
set_up_starfield_sprites

number_of_stars equ 64

		ld hl,packed_star_sprites	
		ld a,$0						 
		ld de,$8000					 ; flat dest address in sprite RAM = $08000
		ld bc,end_of_star_sprites-packed_star_sprites
		call unpack_sprites

      
		ld ix,star_pos_list          		; set up some random star x positions
		ld iy,star_pos_list+256			
		ld hl,0
		ld de,$f147
		ld c,31
		ld b,number_of_stars         		
suspllp   	ld a,h					; h = "random" value.
		cp $b8					; If byte > $b8, invert it and multiply by 2 (ideally we want values between 0-$16f for stars)
		jr c,stinra					
		neg
		rla
stinra	 	rla					; multiply "random value" (0-$b7) by 2
		ld (ix),a				; set LSB of star position
		ld a,0
		rla
		ld (iy),a				; set MSB of star position
		add hl,de
		ld a,h					; mangle the bits to make a fairly random value
		add a,c
		inc c
		rrca 
		xor b
		sub e
		ld h,a
		inc ix
		inc iy
		djnz suspllp
		  
		  
		ld ix,spr_registers+(0*4)		; set Y and Def sprite registers for all stars (sprite reg 0 = first star)
		ld b,number_of_stars
		ld de,4					; offset to next sprite register
		ld c,0+(2*8)+1				; first y coordinate
		ld l,0					; star sprite definition block counter
		
istsplp   	ld (ix+2),c   				; set a y coord                
		ld a,c
		add a,4					; next y coord is 4 lines down
		ld c,a
		  
		ld a,l			
		and $07			
		add a,128
		ld (ix+3),a				; set a definition
		inc l					; use sprite defs 128-136 for stars
				  
		add ix,de
		djnz istsplp
		ret
		  
          

;----------------------------------------------------------------------------------------------------------
		
animate_starfield

		call move_starfield				; update star coordinates
		call update_starfield_sprite_registers		; update star sprite registers
		ret
		
;----------------------------------------------------------------------------------------------------------

move_starfield
	
		ld hl,star_pos_list
		ld e,number_of_stars/8
stflp2		ld b,8
		ld c,9

stflp1		ld a,(hl)
		sub c					;move star coord left "c" pixels
		ld (hl),a
		jp nc,stposok2				;has the sub caused a carry?
		
		inc h					;sub 1 from MSB
		dec (hl)
		jp p,stposok1				;is star coord MSB now negative?
		ld (hl),$01				;if so, put star at right side, set MSB back to 1
		dec h
		ld a,(hl)				;add $90 to LSB
		add a,$90
		ld (hl),a
		inc h					;compensate for following "dec h"
		
stposok1	dec h

stposok2	inc l					;move to next star coordinate
		dec c					;next star motion displacement (1 to 8)
		djnz stflp1
		dec e
		jp nz,stflp2	
		ret

          
;---------------------------------------------------------------------------------------------------


update_starfield_sprite_registers

		ld bc,4					; constant: bytes to next sprite register
		ld de,0+(6*16)-1			; constant: x start window pos
		exx
          
		ld ix,spr_registers+(0*4)		; use sprite register 0 onwards         
		ld hl,star_pos_list
		ld b,number_of_stars             	; update sprite reg x coords

starloop 	ld a,(hl)				; get start coord LSB in A
		ex af,af'
		inc h
		ld a,(hl)				; get star coord MSB in A'
		dec h
		exx					; put star coord MSB in H
		ld h,a					
		ex af,af'
		ld l,a					; put star coord LSB in L
		add hl,de				; add display window constant
		ld (ix),l				; put LSB of star coord in spr register + 0 (x lsb)
		ld a,h
		or $10					; Or sprite height to MSB (1 sprite block)
		ld (ix+1),a				; put x MSB and def in sprite register + 1 (misc bits)
		add ix,bc
		exx
	  
		inc l         				; next sprite coord
		djnz starloop
		ret       
 
;--------------------------------------------------------------------------------------------------------------

packed_star_sprites	incbin "flos_based_programs\demos\selectro\data\stars_sprites_packed.bin"
end_of_star_sprites

star_colours          	incbin "flos_based_programs\demos\selectro\data\stars_palette.bin"
star_tint_colours	incbin "flos_based_programs\demos\selectro\data\stars_tint_palette.bin"

star_pos_list		org ($+$ff) & $ff00		; page align following data

			ds 512,0			; $000+ = LSBs, $100+ = MSBs

;--------------------------------------------------------------------------------------------------------------

