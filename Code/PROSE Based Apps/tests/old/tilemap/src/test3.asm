; test tilemap mode

;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram (above PROSE)

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------
; ADL-mode user program follows..
;---------------------------------------------------------------------------------------------

			
			call test_code

			ld a,1
			out0 (port_video_mode),a		; disable spites/tilemap. Enable 16 colour mode.
			xor a
			jp.lil prose_return				; back to OS

;-------------------------------------------------------------------------------------------
; Test code
;-----------------------------------------------------------------------------------------------

tilemap_registers	equ 0fc0000h

tilemap_location	equ 60000h					; in VRAM

tilemap_width	equ 256*2

test_code
			
			ld hl,colours
			ld de,hw_palette
			ld bc,256*2
			ldir

			ld hl,tiles1						;copy 64 tiles tile set1 to tile location 0
			ld de,hw_vram_a
			ld bc,4096
			ldir
			ld hl,tiles2						;copy 64 tiles to tile location 64
			ld bc,4096
			ldir

			ld ix,hw_vram_a+tilemap_location	;make a 256x256 map in VRAM
			ld d,32
lp4			push ix
			pop hl
			ld e,32

lp3			push hl
			push de
			ld de,0								;begin with tile 0 
			ld c,8
lp2			ld b,8
lp1			ld (hl),e							;tile lsb
			inc hl
			ld (hl),d							;tile msb
			inc hl
			inc de
			djnz lp1
			push de
			ld de,tilemap_width-16
			add hl,de
			pop de
			dec c
			jr nz,lp2
			pop de
			pop hl

			ld bc,16
			add hl,bc
			dec e
			jr nz,lp3
			ld bc,tilemap_width*8
			add ix,bc
			dec d
			jr nz,lp4


			ld hl,testmap						;overlay with some other testmap data
			ld ix,tilemap_location+hw_vram_a
			ld e,0
ntline		ld b,32
ntbyte		ld c,80h
mtmlp		ld a,(hl)
			and c
			jr z,notile
			ld (ix),64							;LSB of tile def
			ld (ix+1),0							;MSB of tile def
notile		inc ix
			inc ix
			srl c
			jr nz,mtmlp
			inc hl
			djnz ntbyte
			dec e
			jr nz,ntline
			
skip
			
			ld ix,tilemap_registers
			ld hl,tilemap_location				; set tilemap control registers 
			ld (ix),hl							; start of tilemap in VRAM
			ld hl,2
			ld (ix+04h),hl						; tilemap address increment per tile (2 bytes)
			ld hl,2+(80000h-160)
			ld (ix+08h),hl						; same tilemap line offset 2+(80000h-160)
			ld hl,2+(tilemap_width-160)
			ld (ix+0ch),hl						; next tilemap line offset (modulo)

			ld a,0
			ld (ix+10h),a						; set x hardware scroll position
			ld a,0
			ld (ix+11h),a						; set y hw scroll position
			
			call wait_vrt
			
			ld a,4
			out0 (port_video_mode),a			; enable tilemap mode

;			ld a,kr_wait_key
;			call.lil prose_kernal
;			ret
			

;---------------------------------------------------------------------------------------------

my_loop		call wait_vrt

			ld ix,tilemap_registers

			ld hl,0
			ld hl,(sine)
			ld de,1
			add hl,de
			ld (sine),hl
			ld a,h
			and 3									;sine table has 1024 entries
			ld h,a
			add hl,hl
			ld de,sine_table
			add hl,de
			ld de,0
			ld e,(hl)
			inc hl
			ld d,(hl)
			ex de,hl
			ld de,704							
			add.sis hl,de							;range is -703 to +703
			ld a,l
skip2		and 7
			ld (ix+10h),a							;set x hw scroll register
			srl h
			rr l
			srl h
			rr l
			srl h
			rr l
			xor a
			add hl,hl
			push hl
			pop bc									;x map location


			ld hl,(cos)
			ld de,2
			xor a
			sbc hl,de
			jr nc,cosok
			ld de,1024								;sine table has 1024 entries
			add hl,de
cosok		ld (cos),hl
			add hl,hl
			ld de,sine_table
			add hl,de
			ld e,(hl)
			inc hl
			ld d,(hl)
			ex de,hl
			ld de,704							;range is -703 to +703
			add.sis hl,de
			ld a,l
			and 7
			ld (ix+11h),a						;set y hw scroll register
			ld a,l
			and 0f8h
			ld l,a
			add hl,hl							;convert y to map lines
			add hl,hl
			add hl,hl
			add hl,hl
			add hl,hl
			add hl,hl							;y map location

;			ld hl,0
			add hl,bc							;add x coord
			ld bc,tilemap_location
			add hl,bc
			ld (ix),hl							; set map start register
	
			ld a,kr_get_key
			call.lil prose_kernal
			cp 076h
			jp nz,my_loop
			
			ret

;---------------------------------------------------------------------------------------------

wait_vrt

waitvrt1	in0 a,(port_hw_flags)
			bit 5,a
			jr z,waitvrt1
waitvrt2	in0 a,(port_hw_flags)
			bit 5,a
			jr nz,waitvrt2
			ret
						
;---------------------------------------------------------------------------------------------

sine		dw24 0
cos			dw24 129

			include '8x8_tiles1.asm'
			include '8x8_tiles2.asm'
			include 'palette.asm'
			include 'testmap.asm'
			include 'big_sine_table.asm'
			
;---------------------------------------------------------------------------------------------
		
		