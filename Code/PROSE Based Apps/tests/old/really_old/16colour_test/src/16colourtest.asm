; Test 16 colour display mode

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------


		ld a,1
		out0 (040h),a					;enable 16 colour mode
	
		ld hl,colours
		ld de,hw_palette
		ld bc,16*2
		ldir
		
		ld de,hw_vram_a
		ld b,100
loopit	push bc
		ld hl,test_data1
		ld bc,320
		ldir
		pop bc
		djnz loopit
		



		ld de,hw_vram_a+640
		ld (reg),de
		ld a,0f0h
		ld (val),a

myloop	ld a,(val)
		ld hl,(reg)
		ld (hl),a	


		ld b,16
		ld hl,0
lp1		inc hl
		ld a,h
		or l
		jr nz,lp1
		djnz lp1

		
		ld a,(val)
		cp 0ffh
		jr z,next
		ld a,0ffh
		ld (val),a
		jr myloop
		
next	ld hl,(reg)
		inc hl
		ld (reg),hl
		ld a,0f0h
		ld (val),a
		jr myloop
		
		
		ld a,0
		out0 (040h),a					;disable 16 colour mode
		xor a
		jp.lil prose_return				; back to OS

;-----------------------------------------------------------------------------------------------

reg		dw24 0
val		db 0

colours

		dw 0000h,000fh,0f00h,0f0fh,00f0h,00ffh,0ff0h,0fffh
		dw 0222h,0444h,0666h,0888h,0aaah,0ccch,0eeeh,0fffh
	
test_data1

		db 001h,002h,003h,004h,005h,006h,007h,008h,009h,00ah,00bh,00ch,00dh,00eh,00fh,000h

		db 010h,020h,030h,040h,050h,060h,070h,080h,090h,0a0h,0b0h,0c0h,0d0h,0e0h,0f0h,000h

		db 001h,023h,045h,067h,089h,0abh,0cdh,0efh,0,0,0,0,0,0,0,0
		
		blkb 320-48,0
		
;-----------------------------------------------------------------------------------------------
		
		