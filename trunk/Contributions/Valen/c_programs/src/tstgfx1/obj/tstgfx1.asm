;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 2.9.0 #5416 (Mar 22 2009) (MINGW32)
; This file was generated Sun Jun 13 14:08:44 2010
;--------------------------------------------------------
	.module tstgfx1
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _SetPalette
	.globl _FillVideoMem
	.globl _SetVideoMode
	.globl _myPalette
	.globl _own_sp
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
_io__sys_mem_select	=	0x0000
_io__sys_keyboard_data	=	0x0002
_io__sys_ps2_joy_control	=	0x0003
_io__sys_joy_com_flags	=	0x0005
_io__sys_irq_enable	=	0x0001
_io__sys_clear_irq_flags	=	0x0002
;--------------------------------------------------------
;  ram data
;--------------------------------------------------------
	.area _DATA
_mm__vreg_xhws	=	0x0200
_mm__vreg_vidctrl	=	0x0201
_mm__vreg_window	=	0x0202
_mm__vreg_yhws_bplcount	=	0x0203
_mm__vreg_rasthi	=	0x0204
_mm__vreg_vidpage	=	0x0206
_mm__vreg_sprctrl	=	0x0207
_mm__mult_write	=	0x0208
_mm__mult_index	=	0x020a
_mm__vreg_ext_vidctrl	=	0x020c
_mm__vreg_read	=	0x0700
_mm__mult_read	=	0x0704
_mm__mult_table	=	0x0600
_mm__bitplane0a_loc__byte0	=	0x0240
_mm__bitplane0a_loc__byte1	=	0x0241
_mm__bitplane0a_loc__byte2	=	0x0242
_mm__bitplane0a_loc__byte3	=	0x0243
;--------------------------------------------------------
; overlayable items in  ram 
;--------------------------------------------------------
	.area _OVERLAY
;--------------------------------------------------------
; external initialized ram data
;--------------------------------------------------------
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;tstgfx1.c:27: void SetVideoMode(void)
;	---------------------------------
; Function SetVideoMode
; ---------------------------------
_SetVideoMode_start::
_SetVideoMode:
;tstgfx1.c:30: mm__vreg_vidctrl = BITMAP_MODE|CHUNKY_PIXEL_MODE;
	ld	hl,#_mm__vreg_vidctrl + 0
	ld	(hl), #0x80
;tstgfx1.c:34: mm__vreg_rasthi = 0;
	ld	hl,#_mm__vreg_rasthi + 0
	ld	(hl), #0x00
;tstgfx1.c:35: mm__vreg_window = (Y_WINDOW_START<<4)|Y_WINDOW_STOP;
	ld	hl,#_mm__vreg_window + 0
	ld	(hl), #0x5A
;tstgfx1.c:37: mm__vreg_rasthi = SWITCH_TO_X_WINDOW_REGISTER;
	ld	hl,#_mm__vreg_rasthi + 0
	ld	(hl), #0x04
;tstgfx1.c:38: mm__vreg_window = (X_WINDOW_START<<4)|X_WINDOW_STOP;
	ld	hl,#_mm__vreg_window + 0
	ld	(hl), #0x8C
;tstgfx1.c:41: mm__bitplane0a_loc__byte0 = 0;      // [7:0] bits
	ld	hl,#_mm__bitplane0a_loc__byte0 + 0
	ld	(hl), #0x00
;tstgfx1.c:42: mm__bitplane0a_loc__byte1 = 0;      // [15:8] 
	ld	hl,#_mm__bitplane0a_loc__byte1 + 0
	ld	(hl), #0x00
;tstgfx1.c:43: mm__bitplane0a_loc__byte2 = 0;      // [18:16] 
	ld	hl,#_mm__bitplane0a_loc__byte2 + 0
	ld	(hl), #0x00
	ret
_SetVideoMode_end::
_own_sp:
	.dw #0xFFFF
;tstgfx1.c:47: void FillVideoMem(void)
;	---------------------------------
; Function FillVideoMem
; ---------------------------------
_FillVideoMem_start::
_FillVideoMem:
;tstgfx1.c:54: for(i=0; i<totalVideoPages; i++) {
	ld	bc,#0x0000
00101$:
	ld	a,b
	sub	a,#0x08
	ret	NC
;tstgfx1.c:55: PAGE_IN_VIDEO_RAM();        
	in	a,(_io__sys_mem_select)
	or	a,#0x40
	out	(_io__sys_mem_select),a
;tstgfx1.c:56: SET_VIDEO_PAGE(i);
	ld	hl,#_mm__vreg_vidpage + 0
	ld	(hl), b
;tstgfx1.c:57: memset((byte*)(VIDEO_BASE), colorIndex, 0x2000);        // fill 8KB video page
	push	bc
	ld	hl,#0x2000
	push	hl
	ld	a,c
	push	af
	inc	sp
	ld	l, #0x00
	push	hl
	call	_memset
	pop	af
	pop	af
	inc	sp
	pop	bc
;tstgfx1.c:58: PAGE_OUT_VIDEO_RAM();
	in	a,(_io__sys_mem_select)
	ld	e,a
	and	a,#0xBF
	out	(_io__sys_mem_select),a
;tstgfx1.c:59: colorIndex += 1;
	inc	c
;tstgfx1.c:54: for(i=0; i<totalVideoPages; i++) {
	inc	b
	jr	00101$
_FillVideoMem_end::
;tstgfx1.c:76: void SetPalette(void)
;	---------------------------------
; Function SetPalette
; ---------------------------------
_SetPalette_start::
_SetPalette:
;tstgfx1.c:79: memcpy((void*) PALETTE, myPalette, sizeof(myPalette));
	ld	de,#0x0000
	ld	hl,#_myPalette
	ld	bc,#0x0010
	ldir
	ret
_SetPalette_end::
_myPalette:
	.dw #0x0000
	.dw #0x0FFF
	.dw #0x0F00
	.dw #0x00F0
	.dw #0x000F
	.dw #0x0FF0
	.dw #0x00FF
	.dw #0x0F0F
;tstgfx1.c:82: int main(void)
;	---------------------------------
; Function main
; ---------------------------------
_main_start::
_main:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;tstgfx1.c:87: SetVideoMode();
	call	_SetVideoMode
;tstgfx1.c:88: SetPalette();
	call	_SetPalette
;tstgfx1.c:89: FillVideoMem();
	call	_FillVideoMem
;tstgfx1.c:91: FLOS_WaitKeyPress(&asciicode, &scancode);
	ld	hl,#0x0000
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	hl,#0x0001
	add	hl,sp
	push	bc
	push	hl
	call	_FLOS_WaitKeyPress
	pop	af
	pop	af
;tstgfx1.c:92: FLOS_FlosDisplay();
	call	_FLOS_FlosDisplay
;tstgfx1.c:94: return NO_REBOOT;
	ld	hl,#0x0000
	ld	sp,ix
	pop	ix
	ret
_main_end::
	.area _CODE
	.area _CABS
