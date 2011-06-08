; test sprites

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

			ld hl,message_txt				; ADL mode program
			ld a,kr_print_string			; desired kernal routine
			call.lil prose_kernal			; call PROSE routine		
			
			call test_code

			ld a,1
			out0 (port_video_mode),a		; enable sprites
			xor a
			jp.lil prose_return				; back to OS

;-------------------------------------------------------------------------------------------
; Test code
;-----------------------------------------------------------------------------------------------

sprite_registers	equ 0f40000h

test_code
			
			ld hl,colours
			ld de,hw_palette+(16*2)
			ld bc,64*2
			ldir

			ld a,3
			out0 (port_video_mode),a		; enable sprites

;---------------------------------------------------------------------------------------------

waitvrt1	in0 a,(port_hw_flags)
			bit 5,a
			jr z,waitvrt1
waitvrt2	in0 a,(port_hw_flags)
			bit 5,a
			jr nz,waitvrt2

;---------------------------------------------------------------------------------------------
			
			ld a,(sine)
			ld d,a
			ld a,(cosine)
			ld e,a

			ld a,7
			ld ix,xcoord1
			
makecoords	ld hl,0
			ld l,d
			add hl,hl
			ld bc,sine_table
			add hl,bc
			ld hl,(hl)
			ld bc,400
			add hl,bc
			ld (ix),l
			ld (ix+1),h
			
			ld hl,0
			ld l,e
			add hl,hl
			ld bc,sine_table
			add hl,bc
			ld hl,(hl)
			ld bc,240
			add hl,bc
			ld (ix+2),l
			ld (ix+3),h
			
			push af
			ld a,e
			add a,15
			ld e,a
			ld a,d
			add a,20
			ld d,a
			lea ix,ix+8

			pop af
			dec a
			jr nz,makecoords

			ld a,(sine)
			add a,2
			ld (sine),a
			ld a,(cosine)
			sub a,1
			ld (cosine),a
			
			ld hl,(frame_base)
			ld de,96*6
			add hl,de
			push hl
			ld de,96*6*7
			xor a
			sbc hl,de
			pop hl
			jr nz,noanlp
			ld hl,0
noanlp		ld (frame_base),hl
			ld ix,def1
			ld b,7
anim1		ld (ix),l
			ld (ix+1),h
			lea ix,ix+8
			djnz anim1
			
			
;---------------------------------------------------------------------------------------------
		
			ld ix,sprite_registers
			ld a,6
			ld hl,(xcoord1)
			ld de,(def1)
boing1lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord1)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl1)
			ld (ix+4),c
			ld (ix+5),b
			ld (ix+6),e
			ld (ix+7),d
			lea ix,ix+8
			ld bc,16
			add hl,bc
			ld bc,96
			ex de,hl
			add hl,bc
			ex de,hl
			dec a
			jr nz,boing1lp

			ld a,6
			ld hl,(xcoord2)
			ld de,(def2)
boing2lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord2)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl2)
			ld (ix+4),c
			ld (ix+5),b
			ld (ix+6),e
			ld (ix+7),d
			lea ix,ix+8
			ld bc,16
			add hl,bc
			ld bc,96
			ex de,hl
			add hl,bc
			ex de,hl
			dec a
			jr nz,boing2lp
			
			ld a,6
			ld hl,(xcoord3)
			ld de,(def3)
boing3lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord3)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl3)
			ld (ix+4),c
			ld (ix+5),b
			ld (ix+6),e
			ld (ix+7),d
			lea ix,ix+8
			ld bc,16
			add hl,bc
			ld bc,96
			ex de,hl
			add hl,bc
			ex de,hl
			dec a
			jr nz,boing3lp		
			
			ld a,6
			ld hl,(xcoord4)
			ld de,(def4)
boing4lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord4)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl4)
			ld (ix+4),c
			ld (ix+5),b
			ld (ix+6),e
			ld (ix+7),d
			lea ix,ix+8
			ld bc,16
			add hl,bc
			ld bc,96
			ex de,hl
			add hl,bc
			ex de,hl
			dec a
			jr nz,boing4lp			
			
			ld a,6
			ld hl,(xcoord5)
			ld de,(def5)
boing5lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord5)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl5)
			ld (ix+4),c
			ld (ix+5),b
			ld (ix+6),e
			ld (ix+7),d
			lea ix,ix+8
			ld bc,16
			add hl,bc
			ld bc,96
			ex de,hl
			add hl,bc
			ex de,hl
			dec a
			jr nz,boing5lp			
			
			ld a,6
			ld hl,(xcoord6)
			ld de,(def6)
boing6lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord6)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl6)
			ld (ix+4),c
			ld (ix+5),b
			ld (ix+6),e
			ld (ix+7),d
			lea ix,ix+8
			ld bc,16
			add hl,bc
			ld bc,96
			ex de,hl
			add hl,bc
			ex de,hl
			dec a
			jr nz,boing6lp			
			
			
			ld a,6
			ld hl,(xcoord7)
			ld de,(def7)
boing7lp	ld (ix),l
			ld (ix+1),h
			ld bc,(ycoord7)
			ld (ix+2),c
			ld (ix+3),b
			ld bc,(height_ctrl7)
			ld (ix+4),c
			ld (ix+5),b
			ld (ix+6),e
			ld (ix+7),d
			lea ix,ix+8
			ld bc,16
			add hl,bc
			ld bc,96
			ex de,hl
			add hl,bc
			ex de,hl
			dec a
			jr nz,boing7lp

			ld a,kr_get_key
			call.lil prose_kernal
			cp 76h
			jp nz,waitvrt1
			ret

;-----------------------------------------------------------------------------------------------
			
		
xcoord1			dw 0
ycoord1			dw 0
def1			dw 0
height_ctrl1	dw 96

xcoord2			dw 0
ycoord2			dw 0
def2			dw 0
height_ctrl2	dw 96

xcoord3			dw 0
ycoord3			dw 0
def3			dw 0
height_ctrl3	dw 96

xcoord4			dw 0
ycoord4			dw 0
def4			dw 0
height_ctrl4	dw 96

xcoord5			dw 0
ycoord5			dw 0
def5			dw 0
height_ctrl5	dw 96

xcoord6			dw 0
ycoord6			dw 0
def6			dw 0
height_ctrl6	dw 96

xcoord7			dw 0
ycoord7			dw 0
def7			dw 0
height_ctrl7	dw 96

sine			db 0
cosine			db 0

frame_count		db 0
frame_base		dw24 0

sine_table:
                db 000h,000h,005h,000h,00Ah,000h,00Fh,000h,014h,000h,018h,000h,01Dh,000h,022h,000h
                db 027h,000h,02Ch,000h,031h,000h,035h,000h,03Ah,000h,03Fh,000h,043h,000h,048h,000h
                db 04Dh,000h,051h,000h,056h,000h,05Ah,000h,05Eh,000h,063h,000h,067h,000h,06Bh,000h
                db 06Fh,000h,073h,000h,077h,000h,07Bh,000h,07Fh,000h,083h,000h,086h,000h,08Ah,000h
                db 08Dh,000h,091h,000h,094h,000h,097h,000h,09Bh,000h,09Eh,000h,0A1h,000h,0A4h,000h
                db 0A6h,000h,0A9h,000h,0ACh,000h,0AEh,000h,0B0h,000h,0B3h,000h,0B5h,000h,0B7h,000h
                db 0B9h,000h,0BBh,000h,0BCh,000h,0BEh,000h,0BFh,000h,0C1h,000h,0C2h,000h,0C3h,000h
                db 0C4h,000h,0C5h,000h,0C6h,000h,0C6h,000h,0C7h,000h,0C7h,000h,0C8h,000h,0C8h,000h
                db 0C8h,000h,0C8h,000h,0C8h,000h,0C7h,000h,0C7h,000h,0C6h,000h,0C6h,000h,0C5h,000h
                db 0C4h,000h,0C3h,000h,0C2h,000h,0C1h,000h,0BFh,000h,0BEh,000h,0BCh,000h,0BBh,000h
                db 0B9h,000h,0B7h,000h,0B5h,000h,0B3h,000h,0B0h,000h,0AEh,000h,0ACh,000h,0A9h,000h
                db 0A6h,000h,0A4h,000h,0A1h,000h,09Eh,000h,09Bh,000h,097h,000h,094h,000h,091h,000h
                db 08Dh,000h,08Ah,000h,086h,000h,083h,000h,07Fh,000h,07Bh,000h,077h,000h,073h,000h
                db 06Fh,000h,06Bh,000h,067h,000h,063h,000h,05Eh,000h,05Ah,000h,056h,000h,051h,000h
                db 04Dh,000h,048h,000h,043h,000h,03Fh,000h,03Ah,000h,035h,000h,031h,000h,02Ch,000h
                db 027h,000h,022h,000h,01Dh,000h,018h,000h,014h,000h,00Fh,000h,00Ah,000h,005h,000h
                db 000h,000h,0FBh,0FFh,0F6h,0FFh,0F1h,0FFh,0ECh,0FFh,0E8h,0FFh,0E3h,0FFh,0DEh,0FFh
                db 0D9h,0FFh,0D4h,0FFh,0CFh,0FFh,0CBh,0FFh,0C6h,0FFh,0C1h,0FFh,0BDh,0FFh,0B8h,0FFh
                db 0B3h,0FFh,0AFh,0FFh,0AAh,0FFh,0A6h,0FFh,0A2h,0FFh,09Dh,0FFh,099h,0FFh,095h,0FFh
                db 091h,0FFh,08Dh,0FFh,089h,0FFh,085h,0FFh,081h,0FFh,07Dh,0FFh,07Ah,0FFh,076h,0FFh
                db 073h,0FFh,06Fh,0FFh,06Ch,0FFh,069h,0FFh,065h,0FFh,062h,0FFh,05Fh,0FFh,05Ch,0FFh
                db 05Ah,0FFh,057h,0FFh,054h,0FFh,052h,0FFh,050h,0FFh,04Dh,0FFh,04Bh,0FFh,049h,0FFh
                db 047h,0FFh,045h,0FFh,044h,0FFh,042h,0FFh,041h,0FFh,03Fh,0FFh,03Eh,0FFh,03Dh,0FFh
                db 03Ch,0FFh,03Bh,0FFh,03Ah,0FFh,03Ah,0FFh,039h,0FFh,039h,0FFh,038h,0FFh,038h,0FFh
                db 038h,0FFh,038h,0FFh,038h,0FFh,039h,0FFh,039h,0FFh,03Ah,0FFh,03Ah,0FFh,03Bh,0FFh
                db 03Ch,0FFh,03Dh,0FFh,03Eh,0FFh,03Fh,0FFh,041h,0FFh,042h,0FFh,044h,0FFh,045h,0FFh
                db 047h,0FFh,049h,0FFh,04Bh,0FFh,04Dh,0FFh,050h,0FFh,052h,0FFh,054h,0FFh,057h,0FFh
                db 05Ah,0FFh,05Ch,0FFh,05Fh,0FFh,062h,0FFh,065h,0FFh,069h,0FFh,06Ch,0FFh,06Fh,0FFh
                db 073h,0FFh,076h,0FFh,07Ah,0FFh,07Dh,0FFh,081h,0FFh,085h,0FFh,089h,0FFh,08Dh,0FFh
                db 091h,0FFh,095h,0FFh,099h,0FFh,09Dh,0FFh,0A2h,0FFh,0A6h,0FFh,0AAh,0FFh,0AFh,0FFh
                db 0B3h,0FFh,0B8h,0FFh,0BDh,0FFh,0C1h,0FFh,0C6h,0FFh,0CBh,0FFh,0CFh,0FFh,0D4h,0FFh
                db 0D9h,0FFh,0DEh,0FFh,0E3h,0FFh,0E8h,0FFh,0ECh,0FFh,0F1h,0FFh,0F6h,0FFh,0FBh,0FFh
colours:
                db 00Fh,00Bh,000h,00Eh,000h,00Ch,000h,00Fh,011h,00Fh,011h,00Fh,022h,00Fh,000h,003h
                db 011h,008h,033h,00Fh,022h,00Ah,044h,00Eh,044h,00Ch,066h,00Eh,044h,007h,077h,00Ch
                db 099h,00Fh,000h,007h,000h,004h,000h,002h,000h,002h,011h,004h,022h,006h,0DDh,00Fh
                db 000h,003h,000h,005h,012h,004h,011h,002h,077h,008h,0CCh,00Ch,0EEh,00Eh,000h,000h
                db 022h,004h,0DDh,00Eh,033h,004h,055h,006h,001h,001h,099h,009h,0AAh,00Bh,0EEh,00Fh
                db 022h,002h,034h,004h,0DDh,00Dh,08Eh,006h,000h,00Ah,0FFh,00Fh,0FFh,00Fh,0FFh,00Fh
                db 0EEh,00Eh,0FFh,00Fh,0EEh,00Fh,000h,00Fh,000h,00Fh,000h,003h,011h,00Eh,022h,00Dh
                db 077h,00Fh,055h,009h,000h,000h,0BBh,00Fh,0CCh,00Fh,0EEh,00Fh,0FFh,00Fh,0FFh,00Fh

;-----------------------------------------------------------------------------------------------
	
message_txt

		db '(Load sprites to $c00000..)',11,0


;-----------------------------------------------------------------------------------------------
		
		