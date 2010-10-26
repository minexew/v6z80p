
; Tests relocate VRAM feature of OSCA v664


vram equ $e000


;---Standard header for OSCA and FLOS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

	org $5000

;-------- Set up display window------------------------------------------------

start	ld a,0
	ld (vreg_rasthi),a		; select y window reg
	ld a,$5a
	ld (vreg_window),a		; set y window size/position (200 lines)
	ld a,%00000100
	ld (vreg_rasthi),a		; select x window reg
	ld a,$8c
	ld (vreg_window),a		; set x window size/position (320 pixels)
	
	ld a,0
	ld (vreg_yhws_bplcount),a	; set 1 bitplane display
		
	ld a,0
	ld (vreg_vidctrl),a		; set bitmap mode + normal border + video enabled

	ld a,0
	ld (vreg_vidpage),a		; read / writes to VRAM page 0

	ld hl,0
	ld (bitplane0a_loc),hl	; start address of video datafetch for window [15:0]
	ld a,0
	ld (bitplane0a_loc+2),a	; start address of video datafetch for window [18:16]

	
;---------Set up palette -----------------------------------------------------


	ld hl,palette		; background = black, colour 1 = white
	ld (hl),0
	inc hl
	ld (hl),0
	inc hl
	ld (hl),$ff
	inc hl
	ld (hl),$0f

;-----------------------------------------------------------------------------------

	ld a,vram/$2000
	out (sys_vram_location),a		; Locate 8KB VRAM page at Z80 $6000-$7FFF

	ld a,%01000000
	out (sys_mem_select),a	; page in VRAM
	
loopit	call do_stuff
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,loopit		; loop if ESC key not pressed

	ld a,1
	out (sys_vram_location),a		; Locate 8KB VRAM page at Z80 $2000-$3FFF (default)

	ld a,%00000000
	out (sys_mem_select),a	; page out VRAM

	ld a,$ff			; and quit (restart OS)
	ret


;--------------------------------------------------------------------------------------------------------

do_stuff	

	ld bc,8192		; write 8KB of stuff to VRAM
	ld hl,vram
lp1	ld (hl),l
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,lp1
	
	ld bc,8192		; clear 8KB of VRAM
	ld hl,vram
lp2	ld (hl),0
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,lp2	
	ret

;------------------------------------------------------------------------------------------------------
