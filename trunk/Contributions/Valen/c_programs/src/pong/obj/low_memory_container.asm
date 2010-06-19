;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 2.9.0 #5416 (Mar 22 2009) (MINGW32)
; This file was generated Tue Jun 08 18:28:01 2010
;--------------------------------------------------------
	.module low_memory_container
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _sound_fx__one
	.globl _Sound_NewFx
	.globl _Sound_PlayFx
	.globl _Sound_AddFxDesc
	.globl _Music_InitTracker
	.globl _Music_PlayTracker
	.globl _Music_UpdateSoundHardware
	.globl _Music_SetForceSampleBase
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
_btmp1:
	.ds 1
_wtmp1:
	.ds 2
_sound_fx__one::
	.ds 14
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
;low_memory_container.c:85: } sound_fx__one = {
	ld	hl,#_sound_fx__one
	ld	(hl),#0x80
	ld	a,#0x10
	ld	(#_sound_fx__one + 1),a
	ld	a,#0xFF
	ld	(#_sound_fx__one + 2),a
	ld	hl, #_sound_fx__one + 3
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	ld	hl, #_sound_fx__one + 5
	ld	(hl),#0x12
	inc	hl
	ld	(hl),#0x08
	ld	hl, #_sound_fx__one + 7
	ld	(hl),#0xD0
	inc	hl
	ld	(hl),#0x07
	ld	hl, #_sound_fx__one + 9
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	ld	hl, #_sound_fx__one + 11
	ld	(hl),#0x02
	inc	hl
	ld	(hl),#0x00
	ld	bc,#_sound_fx__one + 13
	ld	a,#0xFF
	ld	(bc),a
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _LOW_MEM_CODE
;low_memory_container.c:42: void Sound_NewFx(byte fx_number)
;	---------------------------------
; Function Sound_NewFx
; ---------------------------------
_Sound_NewFx_start::
_Sound_NewFx:
	push	ix
	ld	ix,#0
	add	ix,sp
;low_memory_container.c:44: if(!game.isSoundfxEnabled) return;
	ld	bc,#_game + 7
	ld	a,(bc)
	or	a,a
	jr	Z,00103$
;low_memory_container.c:45: btmp1 = fx_number;
	ld	a,4 (ix)
	ld	iy,#_btmp1
	ld	0 (iy),a
;low_memory_container.c:57: ENDASM();
;;
		   push af push bc push de push hl exx push af push bc push de push hl exx push ix push iy;
		   ld a,(#_btmp1)
		   di
		   push af ld a,#1 + #1 out (#0x00), a pop af;
	
		   call (0x8000 + 0x100 + 0)
		   push af ld a,#0 + #1 out (#0x00), a pop af;
		   ei
		   pop iy pop ix exx pop hl pop de pop bc pop af exx pop hl pop de pop bc pop af;
		   
00103$:
	pop	ix
	ret
_Sound_NewFx_end::
;low_memory_container.c:61: void Sound_PlayFx(void)
;	---------------------------------
; Function Sound_PlayFx
; ---------------------------------
_Sound_PlayFx_start::
_Sound_PlayFx:
;low_memory_container.c:63: if(!game.isSoundfxEnabled) return;
	ld	bc,#_game + 7
	ld	a,(bc)
	or	a,a
	ret	Z
;low_memory_container.c:65: DI();
		di 
;low_memory_container.c:66: SET_MUSIC_BANK;
	ld	a,#0x02
	out	(_io__sys_mem_select),a
;low_memory_container.c:72: ENDASM();
;;
		   push af push bc push de push hl exx push af push bc push de push hl exx push ix push iy;
	
		   call (0x8000 + 0x100 + 3)
		   pop iy pop ix exx pop hl pop de pop bc pop af exx pop hl pop de pop bc pop af;
		   
;low_memory_container.c:73: SET_PONG_MAIN_BANK;
	ld	a,#0x01
	out	(_io__sys_mem_select),a
;low_memory_container.c:74: EI();
		ei 
	ret
_Sound_PlayFx_end::
;low_memory_container.c:90: void Sound_AddFxDesc(byte fx_number,  SOUND_FX* p)
;	---------------------------------
; Function Sound_AddFxDesc
; ---------------------------------
_Sound_AddFxDesc_start::
_Sound_AddFxDesc:
	push	ix
	ld	ix,#0
	add	ix,sp
;low_memory_container.c:92: DI();
		di 
;low_memory_container.c:93: SET_MUSIC_BANK;
	ld	a,#0x02
	out	(_io__sys_mem_select),a
;low_memory_container.c:95: ((word*)SOUND_FX__FXLIST)[fx_number] = (word)p;
	ld	c,4 (ix)
	ld	b,#0x00
	sla	c
	rl	b
	ld	hl,#0x8000
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	e,5 (ix)
	ld	d,6 (ix)
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
;low_memory_container.c:96: SET_PONG_MAIN_BANK;
	ld	a,#0x01
	out	(_io__sys_mem_select),a
;low_memory_container.c:97: EI();
		ei 
	pop	ix
	ret
_Sound_AddFxDesc_end::
;low_memory_container.c:103: void Music_InitTracker(void)
;	---------------------------------
; Function Music_InitTracker
; ---------------------------------
_Music_InitTracker_start::
_Music_InitTracker:
;low_memory_container.c:114: ENDASM();
;;
		   push af push bc push de push hl exx push af push bc push de push hl exx push ix push iy;
		   di
		   push af ld a,#1 + #1 out (#0x00), a pop af;
	
		   call (0x8000 + 0x100 + 3*2)
		   push af ld a,#0 + #1 out (#0x00), a pop af;
		   ei
		   pop iy pop ix exx pop hl pop de pop bc pop af exx pop hl pop de pop bc pop af;
		   
	ret
_Music_InitTracker_end::
;low_memory_container.c:117: void Music_PlayTracker(void)
;	---------------------------------
; Function Music_PlayTracker
; ---------------------------------
_Music_PlayTracker_start::
_Music_PlayTracker:
;low_memory_container.c:128: ENDASM();
;;
		   push af push bc push de push hl exx push af push bc push de push hl exx push ix push iy;
		   di
		   push af ld a,#1 + #1 out (#0x00), a pop af;
	
		   call (0x8000 + 0x100 + 3*3)
		   push af ld a,#0 + #1 out (#0x00), a pop af;
		   ei
		   pop iy pop ix exx pop hl pop de pop bc pop af exx pop hl pop de pop bc pop af;
		   
	ret
_Music_PlayTracker_end::
;low_memory_container.c:131: void Music_UpdateSoundHardware(void)
;	---------------------------------
; Function Music_UpdateSoundHardware
; ---------------------------------
_Music_UpdateSoundHardware_start::
_Music_UpdateSoundHardware:
;low_memory_container.c:142: ENDASM();
;;
		   push af push bc push de push hl exx push af push bc push de push hl exx push ix push iy;
		   di
		   push af ld a,#1 + #1 out (#0x00), a pop af;
	
		   call (0x8000 + 0x100 + 3*4)
		   push af ld a,#0 + #1 out (#0x00), a pop af;
		   ei
		   pop iy pop ix exx pop hl pop de pop bc pop af exx pop hl pop de pop bc pop af;
		   
;low_memory_container.c:145: mm__mult_table = 0;     // restore sin table first entry
	ld	hl,#_mm__mult_table + 0
	ld	(hl), #0x00
	ld	hl,#_mm__mult_table + 1
	ld	(hl), #0x00
	ret
_Music_UpdateSoundHardware_end::
;low_memory_container.c:149: void Music_SetForceSampleBase(word base)
;	---------------------------------
; Function Music_SetForceSampleBase
; ---------------------------------
_Music_SetForceSampleBase_start::
_Music_SetForceSampleBase:
	push	ix
	ld	ix,#0
	add	ix,sp
;low_memory_container.c:151: wtmp1 = base;
	ld	a,4 (ix)
	ld	iy,#_wtmp1
	ld	0 (iy),a
	ld	a,5 (ix)
	ld	iy,#_wtmp1
	ld	1 (iy),a
;low_memory_container.c:163: ENDASM();
;;
		   push af push bc push de push hl exx push af push bc push de push hl exx push ix push iy;
		   ld hl,(#_wtmp1)
		   di
		   push af ld a,#1 + #1 out (#0x00), a pop af;
	
		   call (0x8000 + 0x100 + 3*5)
		   push af ld a,#0 + #1 out (#0x00), a pop af;
		   ei
		   pop iy pop ix exx pop hl pop de pop bc pop af exx pop hl pop de pop bc pop af;
		   
	pop	ix
	ret
_Music_SetForceSampleBase_end::
	.area _CODE
	.area _CABS
