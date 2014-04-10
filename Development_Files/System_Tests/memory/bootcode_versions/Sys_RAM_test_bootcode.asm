;-----------------------------------------------------------------------------------------
; System Memory Test v1.01 - TO RUN AS BOOTCODE
;-----------------------------------------------------------------------------------------
;
; Fills $8000-$ffff (bank 0) with 01, bank 1 with 02 etc and checks,
; then..
; runs (mt_start to $ffff) bit test, followed by random byte test
; then..
; runs all banks @ $8000-$ffff..with bit test, followed by random bytes test
;
; Runs indefinately (no esc)
;-----------------------------------------------------------------------------------------

include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

textwindow_cols 	equ 40		                ; settings
textwindow_rows 	equ 25

mt_start		equ $1000		        ; first address 

number_of_banks	equ 15

;-----------------------------------------------------------------------------------------
	org new_bootcode_location	
;-----------------------------------------------------------------------------------------

                jp lets_go
	
;-----------------------------------------------------------------------------------------
	org $800
;-----------------------------------------------------------------------------------------
	
                
lets_go	        ld sp,crc_value
                xor a
                out (sys_alt_write_page),a
                        
                ld b,$17
                ld hl,vreg_xhws			        ; clear video registers pt1
                xor a
clrloop1	ld (hl),a
                inc hl
                djnz clrloop1
                
                ld hl,vreg_xhws+$30			 
                ld b,$50				; clear video registers pt2
                xor a
clrloop2	ld (hl),a
                inc hl
                djnz clrloop2			

                ld hl,vreg_window
                ld (hl),$59			        ; set y window size/position (192 lines)
                ld a,%00000100
                ld (vreg_rasthi),a			; select x window register
                ld (hl),$8c			        ; set x window size/position (320 pixels)
                        
                ld hl,0
                ld (palette),hl
                ld hl,$fff
                ld (palette+2),hl
                
                ld a,%00000111
                out (sys_clear_irq_flags),a		; clear all irqs at start

                
mem_loop	call clear_screen
                
                ld hl,memtest_txt
                call print_string

                ld c,1	                                ; TEST 1
                ld b,number_of_banks
loop1	        push bc
                ld a,c			                ; write 1s to bank1, 2s to bank 2 etc..
                out (sys_mem_select),a	                ; page in bank 0
                ld e,c
                call fill_bank
                pop bc
                inc c
                djnz loop1
                ld c,1	
                ld b,number_of_banks
loop2	        push bc
                ld a,c			
                out (sys_mem_select),a	
                ld e,c
                call test_bank_fill
                jr nz,fail1
                pop bc
                inc c
                djnz loop2
 

                ld a,%00000001
                out (sys_mem_select),a	                ; page in bank 0


                ld hl,unpaged_txt                       ; TEST 2        
                call print_string
                ld de,mt_start		
                call test_ram2		                ; test $1000-$FFFF, rotate byte, address-step
                jp nz,fail2
                ld de,mt_start		
                call test_ram		                ; test $1000-$FFFF, random bytes: all addresses, then readback
                jp nz,fail2
                

                ld hl,paged_txt                         ; TEST 3 
                call print_string  
                ld c,1			                ; test $8000-$ffff in every bank
                ld b,number_of_banks
loop3	        push bc
                ld a,c			
                out (sys_mem_select),a	
                ld de,$8000		
                call test_ram2                          ; test $1000-$FFFF, rotate byte, address-step
                jp nz,fail1
                ld de,$8000		
                call test_ram                           ; test $1000-$FFFF, random bytes: all addresses, then readback
                jp nz,fail1
                ld hl,dot_txt
                call print_string
                pop bc
                inc c
                djnz loop3
                
                ld hl,(pass_count)
                inc hl
                ld (pass_count),hl
                ld a,(pass_count+1)
                ld hl,pass_hex_txt
                call hex_to_ascii
                ld a,(pass_count)
                call hex_to_ascii
                ld hl,pass_txt
                call print_string
                
                call pause_long
                call pause_long
                
                jp mem_loop
                
;-----------------------------------------------------------------------------------------
                
fail1	        pop bc
fail2	        ld a,d
                push de
                ld hl,addr_txt
                call hex_to_ascii
                pop de
                ld a,e
                call hex_to_ascii
                ld hl,bank_hex
                in a,(sys_mem_select)
                call hex_to_ascii
                        
                ld hl,error_txt
                call print_string
loopend	        jp loopend


;-----------------------------------------------------------------------------------------

fill_bank	ld a,e
                push de
                push bc
                ld hl,$8000
	        ld (hl),a
                ld d,h
                ld e,l
                inc de
                ld bc,$7fff
                ldir
                pop bc
                pop de
                ret


test_bank_fill

                ld hl,$8000
frtloop	        ld a,(hl)
                cp e
                jr nz,badbyte
                inc hl
                ld a,h
                or l
                jr nz,frtloop
                xor a
                ret
badbyte	        push hl
                pop de
                xor a
                inc a
                ret
                
                
;-----------------------------------------------------------------------------------------

                
test_ram	push de

                ld hl,(pass_count)		;fill mem with random bytes
                ld (seed),hl
rloop1	        push de
                call rand16
                pop de
                ld a,h
                ld (de),a
                inc de
                ld a,l
                ld (de),a
                inc de
                ld a,d
                or e
                jr nz,rloop1
                
                pop de

                ld hl,(pass_count)		;test random bytes
                ld (seed),hl
vrloop1	        push de
                call rand16
                pop de
                ld a,(de)
                cp h
                jp nz,failed
                inc de
                ld a,(de)
                cp l
                jp nz,failed
                inc de
                ld a,d
                or e
                jr nz,vrloop1
                xor a
                ret

failed	        xor a
                inc a
                ret


;-----------------------------------------------------------------------------------------

test_ram2	ld h,d
                ld l,e

tr2_loop        ld (hl),$80                             ;rotate bit test 
                srl (hl)
                srl (hl)
                srl (hl)
                srl (hl)
                srl (hl)
                srl (hl)
                srl (hl)
                ld a,(hl)
                cp $01
                jp nz,failed2
                
                ld (hl),$fe                            ;rotate bit test2 
                rlc (hl)
                rlc (hl)
                rlc (hl)
                rlc (hl)
                rlc (hl)
                rlc (hl)
                rlc (hl)
                ld a,(hl)
                cp $7f
                jp nz,failed2
                               
                inc hl
                ld a,h
                or l
                jr nz,tr2_loop
                ret                
             
failed2	        ex de,hl
                xor a
                inc a
                ret
            

;---------------------------------------------------------------------------------------------------------------------

rand16	        ld	de,(seed)		
                ld	a,d
                ld	h,e
                ld	l,253
                or	a
                sbc	hl,de
                sbc	a,0
                sbc	hl,de
                ld	d,0
                sbc	a,d
                ld	e,a
                sbc	hl,de
                jr	nc,rand
                inc	hl
rand	        ld	(seed),hl		
                ret
                
;---------------------------------------------------------------------------------------------------------------------

hex_to_ascii

                ld e,a
                and $f0
                rrca
                rrca
                rrca
                rrca
                add a,$30
                cp $3a
                jr c,hdok1
                add a,7
hdok1	        ld (hl),a
                inc hl
                ld a,e
                and $f
                add a,$30
                cp $3a
                jr c,hdok2
                add a,7
hdok2	        ld (hl),a
                inc hl
                ret


;--------------------------------------------------------------------------------
; SIMPLIFIED TEXT PLOTTING ROUTINE
;--------------------------------------------------------------------------------

print_string:

                ld a,%01000000
                out (sys_mem_select),a	        ;page video memory into $2000-$3fff
                
                ld a,(cursor_x)		        ;prints ascii at current cursor position
                ld b,a
                ld a,(cursor_y)
                ld c,a
prtstrlp:	ld a,(hl)			;set hl to start of 0-termimated ascii string
                inc hl	
                or a			
                jr nz,noteos
                ld a,b			        ;updates cursor position on exit
                ld (cursor_x),a
                ld a,c
                ld (cursor_y),a
                
                xor a
                out (sys_mem_select),a	        ;page video memory out of $2000-$3fff
                ret
                
noteos: 	cp 11			        ;is character a LF+CR? (11)
                jr nz,nolf
                ld b,0
                jr linefeed
                
nolf	        cp 10
                jr nz,nocr
                ld b,0
                jr prtstrlp
                
nocr	        push hl
                push bc
                call plotchar
                pop bc
                pop hl
                inc b
                ld a,b
                cp textwindow_cols
                jr nz,prtstrlp
                ld b,0
linefeed:	inc c
                ld a,c
                cp textwindow_rows
                jr nz,prtstrlp
                ld c,textwindow_rows-1
                jr prtstrlp
                        
                
plotchar:	sub 32			        ; a = ascii code of character to plot
                ld h,0			        ; b = xpos, c = ypos
                ld l,a
                add hl,hl
                add hl,hl
                add hl,hl
                ld de,fontbase		        ; start of font 
                add hl,de
                push hl
                pop ix			        ; ix = first addr of char 
                
                ld hl,video_base
                ld de,textwindow_cols*8
                ld a,c
                or a
                jr z,gotymul
ymultlp	        add hl,de
                dec a
                jr nz,ymultlp
gotymul	        ld d,0
                ld e,b
                add hl,de			; hl = first dest addr		
                
                ld b,8
                ld de,textwindow_cols
pltchlp:	ld a,(ix)
                ld (hl),a
                inc ix
                add hl,de
                djnz pltchlp
                ret

;-------------------------------------------------------------------------------------

clear_screen

                ld a,%01000000
                out (sys_mem_select),a		;page video memory into $2000-$3fff
                ld hl,video_base
                ld bc,$2000
loop10	        ld (hl),0
                inc hl
                dec bc
                ld a,b
                or c
                jr nz,loop10
                xor a
                out (sys_mem_select),a
                ld (cursor_x),a
                ld (cursor_y),a
                ret	
                        
;-------------------------------------------------------------------------------------

pause_long
                                        
                ld b,0			        ;wait approx 1 second
twait2	        ld a,%00000100
                out (sys_clear_irq_flags),a	;clear timer overflow flag
twait1	        in a,(sys_irq_ps2_flags)	;wait for overflow flag to become set
                bit 2,a			
                jr z,twait1
                djnz twait2		        ;loop 256 times
                ret
                
;-------------------------------------------------------------------------------------

fontbase	incbin "development_files\system_tests\memory\data\philfont.bin"
	
;-----------------------------------------------------------------------------------------

cursor_x		db 0
cursor_y		db 0

memtest_txt	        db "SYSTEM RAM TEST V1.02",11
                        db "---------------------",11,11

                        db "Bank selection test..",11,11,0

pass_count	        db 0,0

pass_txt		db 11,11,"Pass:"
pass_hex_txt	        db "0000",10,0

error_txt		db 11,11,"Fail @ $"
addr_txt		db "---- "
Bank_txt		db "in bank: $"
bank_hex		db "--",0
	
unpaged_txt             db "Testing Flat RAM ($1000-$FFFF)..",11,11,0        
paged_txt	        db "Testing RAM Pages (15 x $8000-$FFFF)..",11,11,0

dot_txt		        db ".",0

seed		        dw 0



;**************************************************************************************************
	org new_bootcode_location+$dbe
;**************************************************************************************************
	
crc_value			dw $ffff	;replace with real CRC16 checksum word

;--------------------------------------------------------------------------------------------------
