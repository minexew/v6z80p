
scroll_char_width	equ 12		; within a 16 pixel wide frame

;-------------------------------------------------------------------------------------------------

max_amplitude equ 64

init_sine_scroller

		ld de,scroll_bitmap_loc_lo			; dest = a:de
		ld a,scroll_bitmap_loc_hi
		ld bc,$0					; number of bytes = bc
		call clear_vram		

		ld hl,sinescrollfont				; load font to vram
		ld de,scroll_font_loc_lo
		ld a,scroll_font_loc_hi
		ld bc,end_sinescrollfont-sinescrollfont
		call unpack_to_vram
		 
		ld hl,sine_table    				; upload sine table to math unit
		ld de,mult_table
		ld bc,$200
		ldir

		xor a						; build y-line address lookup list positives
		ld hl,ss_y_list
		ld de,0+((max_amplitude/2)-1)*bitmap_width
		ld bc,bitmap_width
ss_iyl   	ld (hl),e
		inc h
		ld (hl),d
		dec h
		inc l
		ex de,hl
		or a
		sbc hl,bc
		ex de,hl
		inc a
		cp max_amplitude/2
		jr nz,ss_iyl
		  
		xor a						; build y-line address lookup list negatives									
		ld hl,ss_y_list+255
		ld de,0+((max_amplitude/2)*bitmap_width)
		ld bc,bitmap_width
ss_iy2    	ld (hl),e
		inc h
		ld (hl),d
		dec h
		dec l
		ex de,hl
		add hl,bc
		ex de,hl
		inc a
		cp max_amplitude/2
		jr nz,ss_iy2
			    
		ld hl,scrolling_message
		ld (scrolling_message_ptr),hl

		ld a,16-scroll_char_width
		ld (scroll_fine),a
		ret


;-------------------------------------------------------------------------------------------------

draw_sine_scroller
	
		call wait_blit
		
		ld hl,(sine_table)
		ld (mult_table),hl			; restore entry 0 of mult table (destroyed by music player)
		
		ld a,scroll_font_loc_hi
		ld (blit_src_msb),a			; MSB of addr blitter gets font data from
		ld a,scroll_bitmap_loc_hi
		ld (blit_dst_msb),a			; MSB of addr blitter writes scroll text to

		ld a,47					; blits are all 48 lines tall
		ld (blit_height),a
	 
		ld a,15					; src modulo for char plots (each char sits in a 16 pixel wide frame)
		ld (blit_src_mod),a				
		
		ld hl,bitmap_width-1
		ld a,l					; dest modulo lower bits
		ld (blit_dst_mod),a				
		ld a,h					
		rlca
		rlca
		and %00001100				; dest modulo upper bits
		or  %01000000				; ascending blit mode
		ld (blit_misc),a			

		ld hl,max_amplitude/2
		ld (mult_write),hl			; put amplitude of sine scroll as multiplier

		ld bc,0					; initial plot position x coord  
		exx
		ld a,(scroll_fine)                 	; scroll fine is initial slice within a character
		ld e,a					; forms LSB of source since each font char is multiple of 256
		ld a,(sine_pos)
		ld b,a					; b = initial sinus step
		ld hl,(scrolling_message_ptr)

ss_chlp 	ld a,(hl)				; get ASCII char
		sub 32					; less 32
		rlca					; each separate font character is 1024 bytes in size
		rlca					; so multiply MSB by 4 
		ld d,a					; DE  = final source address [15:0]
          
ss_chsl 	ld a,b
		ld (mult_index),a			; sine value
		exx
		bit 0,b					; is this the last x coord (368 slices to do)?
		jp z,ss_notl
		ld a,c
		cp (bitmap_width & $ff)
		jp z,ss_done
	
ss_notl		ld hl,(mult_read)			; gives +/- max amplitude
		ld h,ss_y_list/256			; obtain actual video address for this scanline from a look up table
		ld e,(hl)
		inc h
		ld d,(hl)				; de = left side address of revelent scanline
		ex de,hl
		add hl,bc				; add the x coordinate 
          
blitwait	ld a,(vreg_read)
		and $10
		jr nz,blitwait

		ld (blit_dst_loc),hl			; write destination address into blitter register
		inc bc					; advance the x plotting coord for next slice  
		exx				
		ld (blit_src_loc),de			; write the source address into blitter
		inc de					; inc blit source for next slice
		xor a
		ld (blit_width),a			; set the width (1 byte) and start blit

		inc b					; inc in-frame sinus value
		bit 4,e					; if source address (char slice) has bit 4 set, an entire character has been drawn
		jp z,ss_chsl				; if not loop around for next slice of same source character
		ld e,4					; characters are 12 pixels wide (aligned to right side of 16 pixel wide block) 
		inc hl					; inc message char address
		jp ss_chlp				; loop around, new character
		  

ss_done 	ld hl,sine_pos				; now that the entire sine scroller has been drawn we can update        
		dec (hl)				; the variables for the next frame.. First, shift the sine position

		ld hl,scroll_fine 			; now advance the scroll index
		ld a,(hl)				
		add a,3					
		ld (hl),a				; scroller x-motion (speed) each frame is 3 pixels
		bit 4,a			
		ret z					; if still within a char frame, no more to do
		
		add a,16-scroll_char_width		; reposition slice index to left side of char
		and $f
		ld (hl),a				
		ld hl,(scrolling_message_ptr)
		inc hl
		ld (scrolling_message_ptr),hl		; and advance the message source char pointer
		
		ld de,bitmap_width/scroll_char_width	; finally, need to test for message wrap
		add hl,de
		ld a,(hl)				; look ahead n chars to detect end of message 
		or a
		ret nz
		ld hl,scrolling_message			; reset message to start
		ld (scrolling_message_ptr),hl
		ret

;-------------------------------------------------------------------------------------------------------------

sinescrollfont		incbin "flos_based_programs\demos\selectro\data\font1216_packed.bin"
end_sinescrollfont	

scrolly_palette		incbin "flos_based_programs\demos\selectro\data\font1216_palette.bin"

reflection_palette	incbin "flos_based_programs\demos\selectro\data\font1216_reflect_palette.bin"

scrolling_message_ptr	dw 0

scroll_fine		db 0

sine_pos		dw 0

sine_table             incbin "flos_based_programs\demos\selectro\data\sine_table.bin"

            		org ($+255) & $FF00         ;page align
          
ss_y_list           	ds 256,0 	            ;lsbs
			ds 256,0        	    ;msbs
		    
		    
scrolling_message	ds bitmap_width/scroll_char_width," "

			db "     HELLO AND WELCOME TO A MUSIC SELECTRO FOR OSCA ON THE V6Z80P BY PHIL OF RETROLEUM 2012...  "
			db "PRESS UP AND DOWN CURSORS TO SCROLL THROUGH THE TUNES AND PRESS ENTER TO SELECT ONE TO PLAY...  "
			db "GREETINGS TO RETRO FANS EVERYWHERE AND ESPECIALLY ALL THE V6Z80P OWNERS - IN RANDOM ORDER: "
			db "ALESSANDRO D, MIGUEL G, TONY F, MICHAL J, DANIEL I, VALEN, MARTIN L, JOHN B, JOUNI K, SLAWOMIR B, "
			db "BRANISLAV B, JOHN S, KRYSTIAN W, JAKUB W, ADAM D, MACIEJ W, TOR A, MANUEL S, ARCHIE R, ALEXANDER S, "
			db "ANDREAS G, ALASTAIR B, FABIO Z, MILAN T, ENZO C, MARTIN M, MASSIMINO B, MIKE, FLEMMING D, "
			db "GUSTAVO P, JULIO M, GRAHAM C, JIM B, IAN C, YONGLAK, XAVIER T, NUNO P, DYLAN D, "
			db "HENK K, ERIK L, PETER MCQ AND ANYONE I MISSED.. (LET ME KNOW!) "
			db"               ALL CODE AND GRAPHICS BY PHIL 2012 - BE SEEING YOU!             "

			ds bitmap_width/scroll_char_width," "
			db 0

;-------------------------------------------------------------------------------------------------------------

