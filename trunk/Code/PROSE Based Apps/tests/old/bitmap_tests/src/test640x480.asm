;test 640x480 256 colour mode
;----------------------------------------------------------------------------------------------

ADL_mode		equ 1				; 0 if user program is Z80 mode type, 1 if not
load_location	equ 10000h			; anywhere in system ram

				include	'PROSE_header.asm'

;---------------------------------------------------------------------------------------------

bm_datafetch	equ 640
bm_modulo		equ 0
bm_pixel_step	equ 1
bm_base			equ 0

begin_app		ld a,0
				ld (video_control_regs),a			;256 colours, no pixel doubling, no line doubling
				ld a,0
				ld (video_control_regs+1),a			;sprites off
				ld a,0
				ld (video_control_regs+2),a			;bitmap uses palette 0
				
				ld ix,bitmap_parameters				; set up bitmap mode parameters 
				ld (ix),bm_base
				ld (ix+04h),bm_pixel_step
				ld (ix+08h),0
				ld (ix+0ch),bm_modulo
				ld (ix+10h),0+(bm_datafetch/8)-1			
				
				ld hl,pic							;copy pic to vram
				ld de,vram_a_addr
				ld bc,640*480
				ldir
				
				ld hl,colours						;copy palette data
				ld de,palette_regs
				ld bc,256*2
				ldir	
				
				ld a,kr_wait_key
				call.lil prose_kernal
				
				ld a,0ffh
				jp prose_return						;restart prose on exit

;----------------------------------------------------------------------------------------------

include	'sunflowers_640x480_chunky.asm'

include 'sunflowers_640x480_12bit_palette.asm'

;------------------------------------------------------------------------------------------------
