;-----------------------------------------------------------------------------------------
; Video Memory Test - fills video memory pages with random bytes then verifies
;-----------------------------------------------------------------------------------------

include "OSCA_hardware_equates.asm"
include "system_equates.asm"

textwindow_cols 	equ 40		; settings
textwindow_rows 	equ 25

mt_start		equ video_base	; first address 

number_of_pages	equ 64

;-----------------------------------------------------------------------------------------
	org new_bootcode_location	
;-----------------------------------------------------------------------------------------

	jp lets_go
	
;-----------------------------------------------------------------------------------------
	org $800	
;-----------------------------------------------------------------------------------------

lets_go	ld sp,crc_value
	xor a
	out (sys_alt_write_page),a
	
	ld b,$17
	ld hl,vreg_xhws			; clear video registers pt1
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
	ld (hl),$59			; set y window size/position (192 lines)
	ld a,%00000100
	ld (vreg_rasthi),a			; select x window register
	ld (hl),$8c			; set x window size/position (320 pixels)
		
	ld a,%00000111
	out (sys_clear_irq_flags),a		; clear all irqs at start
	
mem_loop	call clear_screen
	ld hl,memtest_txt
	call print_string
	call pause_long
	call pause_long

	ld a,%01000000
	out (sys_mem_select),a		;video ram is paged in during test


;--------- write phase --------------------------------------------------------------------
	
	ld hl,(pass_count)
	ld (seedtemp),hl
	ld a,0
	ld (video_page),a
	
mem_loop1	ld a,(video_page)
	and $7f
	ld (vreg_vidpage),a

	ld hl,(seedtemp)		;fill mem with random bytes
	ld (seed),hl
	ld de,mt_start
rloop1	push de
	call rand16
	pop de
	ld a,h
	ld (de),a
	inc de
	ld a,l
	ld (de),a
	inc de
	ld a,d
	cp $40
	jr nz,rloop1
	
	in a,(sys_irq_ps2_flags)	; reset on keyboard irq.
	bit 0,a				
	jp nz,$0
		
	ld hl,(seedtemp)
	inc hl
	ld (seedtemp),hl
	ld a,(video_page)		; next video page
	inc a
	ld (video_page),a
	cp number_of_pages
	jp nz,mem_loop1


;---------- verify phase ---------------------------------------------------------------------
	
	
	ld hl,(pass_count)
	ld (seedtemp),hl
	ld a,0
	ld (video_page),a
	
mem_loop2	ld a,(video_page)
	and $7f
	ld (vreg_vidpage),a

	ld hl,(seedtemp)		;test random bytes
	ld (seed),hl
	ld de,mt_start
vrloop1	push de
	call rand16
	pop de
	ld a,(de)
	cp h
	jp nz,fail
	inc de
	ld a,(de)
	cp l
	jp nz,fail
	inc de
	ld a,d
	cp $40
	jr nz,vrloop1

	in a,(sys_irq_ps2_flags)	; reset on keyboard irq.
	bit 0,a				
	jp nz,$0	

	ld hl,(seedtemp)
	inc hl
	ld (seedtemp),hl
	ld a,(video_page)		; next video page
	inc a
	ld (video_page),a
	cp number_of_pages
	jp nz,mem_loop2

;--------------------------------------------------------------------------------------------------------

	ld hl,(pass_count)
	inc hl
	ld (pass_count),hl
	ld a,(pass_count+1)
	ld hl,pass_no_txt
	call hex_to_ascii
	ld a,(pass_count)
	call hex_to_ascii
	jp mem_loop
	
;-----------------------------------------------------------------------------------------
		
fail	
	ld a,d
	push de
	ld hl,addr_txt
	call hex_to_ascii
	pop de
	ld a,e
	call hex_to_ascii
	
	ld e,0
	ld a,e
clrabp	ld (vreg_vidpage),a
	ld hl,video_base		; clear all bitplanes
	ld bc,$2000
flp	ld (hl),0
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,flp
	inc e
	ld a,e
	cp 8
	jr nz,clrabp

	ld hl,0
	ld (palette),hl
	ld hl,$ffff
	ld (palette+2),hl
	
	xor a
	ld (vreg_vidpage),a

	ld hl,error_txt
	call print_string

loopend	jp loopend
	
		
;---------------------------------------------------------------------------------------------------------------------

rand16	ld	de,(seed)		
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
rand	ld	(seed),hl		
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
hdok1	ld (hl),a
	inc hl
	ld a,e
	and $f
	add a,$30
	cp $3a
	jr c,hdok2
	add a,7
hdok2	ld (hl),a
	inc hl
	ret
	
;--------------------------------------------------------------------------------
; SIMPLIFIED TEXT PLOTTING ROUTINE
;--------------------------------------------------------------------------------

print_string:

	ld a,%01000000
	out (sys_mem_select),a	;page video memory into $2000-$3fff
	
	ld a,(cursor_x)		;prints ascii at current cursor position
	ld b,a
	ld a,(cursor_y)
	ld c,a
prtstrlp:	ld a,(hl)			;set hl to start of 0-termimated ascii string
	inc hl	
	or a			
	jr nz,noteos
	ld a,b			;updates cursor position on exit
	ld (cursor_x),a
	ld a,c
	ld (cursor_y),a
	
	xor a
	out (sys_mem_select),a	;page video memory out of $2000-$3fff
	ret
	
noteos:	cp 11			;is character a LF+CR? (11)
	jr nz,nolf
	ld b,0
	jr linefeed
	
nolf	cp 10
	jr nz,nocr
	ld b,0
	jr prtstrlp
	
nocr	push hl
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
		
	
plotchar:	sub 32			; a = ascii code of character to plot
	ld h,0			; b = xpos, c = ypos
	ld l,a
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,fontbase		; start of font 
	add hl,de
	push hl
	pop ix			; ix = first addr of char 
	
	ld hl,video_base
	ld de,textwindow_cols*8
	ld a,c
	or a
	jr z,gotymul
ymultlp	add hl,de
	dec a
	jr nz,ymultlp
gotymul	ld d,0
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
	
	xor a
	ld (vreg_vidpage),a
	ld a,%01000000
	out (sys_mem_select),a		;page video memory into $2000-$3fff
	ld hl,video_base
	ld bc,$2000
loop1	ld (hl),0
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,loop1
	xor a
	out (sys_mem_select),a
	ld (cursor_x),a
	ld (cursor_y),a
	ret	
		
;-------------------------------------------------------------------------------------

pause_long
				
	ld b,0			;wait approx 1 second
twait2	ld a,%00000100
	out (sys_clear_irq_flags),a	;clear timer overflow flag
twait1	in a,(sys_irq_ps2_flags)	;wait for overflow flag to become set
	bit 2,a			
	jr z,twait1
	djnz twait2		;loop 256 times
	ret
	
;-------------------------------------------------------------------------------------

fontbase	incbin "philfont.bin"
	
;-----------------------------------------------------------------------------------------

cursor_x		db 0
cursor_y		db 0

memtest_txt	db "Testing Video Memory",11,11
		db "Garbage will appear on screen",11
		db "between each pass. Any key to quit",11,11,11
		db "PASS: $"
pass_no_txt	db "0000",0
		
error_txt		db 11,11,"Fail @ $"
addr_txt		db "----",0
		
seed		dw 0

pass_count	dw 0

video_page	db 0

seedtemp		dw 0


;**************************************************************************************************
	org new_bootcode_location+$dbe
;**************************************************************************************************
	
crc_value			dw $ffff	;replace with real CRC16 checksum word

;--------------------------------------------------------------------------------------------------
