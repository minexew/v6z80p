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

tilemap_location	equ hw_vram_a+60000h

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

			ld ix,tilemap_location				;make a 256x256 map in VRAM
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
			ld ix,tilemap_location
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
			ld (ix+08h),hl						; same tilemap line offset (80000h-(160-2))
			ld hl,2+(tilemap_width-160)
			ld (ix+0ch),hl						; next tilemap line offset (modulo)

			ld a,0
			ld (ix+10h),a						; set x hardware scroll position
			ld a,0
			ld (ix+11h),a						; set y hw scroll position
			
;---------------------------------------------------------------------------------------------

waitvrt1	in0 a,(port_hw_flags)
			bit 5,a
			jr z,waitvrt1
waitvrt2	in0 a,(port_hw_flags)
			bit 5,a
			jr nz,waitvrt2

			ld a,4
			out0 (port_video_mode),a			; enable tilemap mode
		
xhws_lp		ld a,kr_wait_key
			call.lil prose_kernal
			
			ret
			
			ld a,(xhws)
			inc a
			ld (xhws),a
			and 7
			ld (tilemap_registers+10h),a		; advance x hardware scroll position 1 pixel		
			jr nz,xhws_lp

yhws_lp		ld a,kr_wait_key
			call.lil prose_kernal

			ld a,(yhws)
			inc a
			ld (yhws),a
			and 7
			ld (tilemap_registers+11h),a		; advance y hardware scroll position 1 line		
			jr nz,yhws_lp		
			
			ret
			
;---------------------------------------------------------------------------------------------

xhws		db 0
yhws		db 0

			include '8x8_tiles1.asm'
			include '8x8_tiles2.asm'
			include 'palette.asm'
			include 'testmap.asm'
			
;---------------------------------------------------------------------------------------------
		
		