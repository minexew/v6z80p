;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 2.9.0 #5416 (Mar 22 2009) (MINGW32)
; This file was generated Sat Jun 12 17:24:30 2010
;--------------------------------------------------------
	.module pong
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _setfillstyle
	.globl _Game_LoadStateData
	.globl _main
	.globl _Game_Play
	.globl _Game_ReInit_Watcher
	.globl _Game_HandlePlayerInput_PauseMode
	.globl _Game_HandlePlayerInput_Bat
	.globl _Debug_CheckCurrentBank
	.globl _MUSIC_Init
	.globl _MUSIC_Silence
	.globl _Mod_LoadMusicModule
	.globl _Mod_FindHighestUsedPattern
	.globl _Sound_InitFx
	.globl _Sound_LoadFxDescriptors
	.globl _Sound_LoadSounds
	.globl _Sound_LoadSoundCode
	.globl _GameObjYouWin_Init
	.globl _GameObjRocket_Init
	.globl _helper_GameObjScore_IsScoreBlinkedAtLeast
	.globl _GameObjScore_SetScore
	.globl _GameObjScore_SetState
	.globl _GameObjScore_Init
	.globl _GameObjAnim_ShowOnlyFirstFrame
	.globl _GameObjAnim_EnableAnimation
	.globl _GameObjAnim_Init
	.globl _GameObj_Collide
	.globl _GameObj_InitCollideBox
	.globl _GameObj_Init
	.globl _PoolGameObj_FreeGameObj
	.globl _PoolGameObj_AllocateGameObjRocket
	.globl _PoolSprites_Init
	.globl _Joystick_GetInput
	.globl _Joystick_SelectJoystickPort
	.globl _Keyboard_IRQ_Handler
	.globl _Keyboard_GetLastPressedScancode
	.globl _Keyboard_Init
	.globl _Input_ClearPlayersInput
	.globl _Background_InitTilemap
	.globl _TileMap_Clear
	.globl _TileMap_FillTileDefinition
	.globl _Background_LoadTiles
	.globl _wait_y_window
	.globl _set_sprite_regs_optimized
	.globl _clear_shadow_sprite_regs
	.globl _LoadingIcon_Load
	.globl _LoadingIcon_Enable
	.globl _LoadingIcon_LoadSprites
	.globl _ChunkLoader_IsDone
	.globl _ChunkLoader_LoadChunk
	.globl _ChunkLoader_Init
	.globl _GetR
	.globl _Sys_ClearIRQFlags
	.globl _Util_LoadPalette
	.globl _Math_IsBoxHitBox
	.globl _delay
	.globl _inportb
	.globl _cur_color
	.globl _bufModFileHeader
	.globl _pool_game_obj
	.globl _allocatedSpriteNumbers
	.globl _pool_sprites
	.globl _keyboard_input_map
	.globl _keyboard
	.globl _player2_input
	.globl _player1_input
	.globl _spr_reg
	.globl _cl
	.globl _request_exit
	.globl _buffer
	.globl _debug
	.globl _game
	.globl _gameMenu
	.globl _YouWinAnim
	.globl _ball1
	.globl _batB
	.globl _batA
	.globl _scoreB
	.globl _scoreA
	.globl _loadingIcon
	.globl _g_ownAnimObjConst
	.globl _own_sp
	.globl _GameObj_SetPos
	.globl _GameObj_SetInUse
	.globl _GameObj_GetInUse
	.globl _DiagMessage
	.globl _load_file_to_buffer
	.globl _diag__FLOS_FindFile
	.globl _diag__FLOS_ForceLoad
	.globl _DiskIO_BeginDiskOperation
	.globl _DiskIO_EndDiskOperation
	.globl _DiskIO_VisualizeDiskError
	.globl _initgraph
	.globl _clear_sprite_regs
	.globl _DrawBat
	.globl _DrawBall
	.globl _set_sprite_regs_hw
	.globl _set_sprite_regs
	.globl _load_sprites
	.globl _TileMap_Fill
	.globl _irq_handler
	.globl _install_irq_handler
	.globl _Joystick_GetInputForPlayer
	.globl _Joystick_CheckInputAutoSwith
	.globl _Joystick_CheckInputAutoSwithForPlayer
	.globl _Joystick_IsSecondJoyNeedToBeReaded
	.globl _PoolSprites_AllocateSpriteNumber
	.globl _PoolSprites_FreeAllSprites
	.globl _PoolGameObj_Init
	.globl _PoolGameObj_AllocateGameObjAnim
	.globl _PoolGameObj_AllocateGameObj
	.globl _PoolGameObj_AddObjToActiveObjects
	.globl _PoolGameObj_RemoveObjFromActiveObjects
	.globl _PoolGameObj_ApplyFuncMoveToObjects
	.globl _PoolGameObj_ApplyFuncDrawToObjects
	.globl _GameObjAnim_Move
	.globl _GameObjAnim_Draw
	.globl _GameObjAnim_init_animation
	.globl _GameObjAnim_Free
	.globl _GameObjScore_Move
	.globl _GameObjScore_Draw
	.globl _GameObjScore_draw_score
	.globl _GameObjScore_UpdateScore
	.globl _GameObjScore_Draw_PlayerRocketsIndicator
	.globl _GameObjRocket_Move
	.globl _GameObjRocket_CheckCollision
	.globl _GameObjRocket_Draw
	.globl _GameObjRocket_AllocateAnimationObj
	.globl _GameObjRocket_Free
	.globl _GameObjBat_Init
	.globl _GameObjBat_SetState
	.globl _GameObjBat_Move
	.globl _GameObjBat_MoveUp
	.globl _GameObjBat_MoveDown
	.globl _GameObjBat_Draw
	.globl _GameObjBat_Fire
	.globl _GameObjBat_IsCanFireWithRocket
	.globl _GameObjBat_state_handler
	.globl _GameObjBall_Init
	.globl _GameObjBall_SetState
	.globl _GameObjBall_Move
	.globl _GameObjBall_CheckCollision
	.globl _GameObjBall_Draw
	.globl _GameObjYouWin_Move
	.globl _GameObjYouWin_Draw
	.globl _GameObjYouWin_AllocateAnimObjects
	.globl _GameObjYouWin_SetState
	.globl _helper_GameObjYouWin_StartAnimation
	.globl _GameObjGameMenu_Init
	.globl _GameObjGameMenu_Move
	.globl _GameObjGameMenu_Draw
	.globl _ai_update
	.globl _Debug_Move
	.globl _Debug_Draw
	.globl _Game_Initialize
	.globl _Game_InitializeMenuGameObjects
	.globl _Game_InitializeLevelGameObjects
	.globl _Game_Movebat
	.globl _Game_InitLevelBegining
	.globl _Game_RequestSetState
	.globl _Game_SetState
	.globl _Game_LoadSinTable
	.globl _Game_MarkFrameTime
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
_loadingIcon::
	.ds 513
_scoreA::
	.ds 35
_scoreB::
	.ds 35
_batA::
	.ds 32
_batB::
	.ds 32
_ball1::
	.ds 32
_YouWinAnim::
	.ds 42
_gameMenu::
	.ds 23
_game::
	.ds 15
_debug::
	.ds 2
_buffer::
	.ds 33
_request_exit::
	.ds 1
_cl::
	.ds 16
_spr_reg::
	.ds 9
_player1_input::
	.ds 4
_player2_input::
	.ds 4
_keyboard::
	.ds 3
_keyboard_input_map::
	.ds 21
_pool_sprites::
	.ds 1
_allocatedSpriteNumbers::
	.ds 35
_pool_game_obj::
	.ds 693
_bufModFileHeader::
	.ds 1084
_btmp:
	.ds 1
_wtmp:
	.ds 2
_Debug_Draw_counter_1_1:
	.ds 2
_Debug_Draw_corner_1_1:
	.ds 1
_Game_LoadStateData_tilesMenu_1_1:
	.ds 12
_Game_LoadStateData_tilesLevel_1_1:
	.ds 8
_Game_LoadStateData_gameStateData_1_1:
	.ds 24
_cur_color::
	.ds 2
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
;debug.c:24: static short counter = 0;
	ld	iy,#_Debug_Draw_counter_1_1
	ld	0 (iy),#0x00
	ld	iy,#_Debug_Draw_counter_1_1
	ld	1 (iy),#0x00
;debug.c:25: static byte corner = 0;     // 0 = top left corner, 1 = right bottom corner of collision box
	ld	iy,#_Debug_Draw_corner_1_1
	ld	0 (iy),#0x00
;pong.c:427: static LoadTilesDescription tilesMenu[] = {
	ld	hl,#_Game_LoadStateData_tilesMenu_1_1
	ld	(hl),#<__str_13
	inc	hl
	ld	(hl),#>__str_13
	ld	hl, #_Game_LoadStateData_tilesMenu_1_1 + 2
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	ld	hl, #_Game_LoadStateData_tilesMenu_1_1 + 4
	ld	(hl),#<__str_14
	inc	hl
	ld	(hl),#>__str_14
	ld	hl, #_Game_LoadStateData_tilesMenu_1_1 + 4+1
	inc	hl
	ld	(hl),#0x60
	inc	hl
	ld	(hl),#0x01
	ld	hl, #_Game_LoadStateData_tilesMenu_1_1 + 8
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	ld	hl, #_Game_LoadStateData_tilesMenu_1_1 + 8+1
	inc	hl
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;pong.c:431: static LoadTilesDescription tilesLevel[] = {
	ld	hl,#_Game_LoadStateData_tilesLevel_1_1
	ld	(hl),#<__str_15
	inc	hl
	ld	(hl),#>__str_15
	ld	hl, #_Game_LoadStateData_tilesLevel_1_1 + 2
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	ld	hl, #_Game_LoadStateData_tilesLevel_1_1 + 4
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	ld	hl, #_Game_LoadStateData_tilesLevel_1_1 + 4+1
	inc	hl
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;pong.c:442: } gameStateData[] = {
	ld	hl,#_Game_LoadStateData_gameStateData_1_1
	ld	(hl),#0x01
	ld	a,#0x03
	ld	(#_Game_LoadStateData_gameStateData_1_1 + 1),a
	ld	hl, #_Game_LoadStateData_gameStateData_1_1 + 2
	ld	(hl),#<_Game_LoadStateData_tilesMenu_1_1
	inc	hl
	ld	(hl),#>_Game_LoadStateData_tilesMenu_1_1
	ld	hl, #_Game_LoadStateData_gameStateData_1_1 + 4
	ld	(hl),#<__str_16
	inc	hl
	ld	(hl),#>__str_16
	ld	hl, #_Game_LoadStateData_gameStateData_1_1 + 6
	ld	(hl),#<__str_17
	inc	hl
	ld	(hl),#>__str_17
	ld	a,#0x01
	ld	(#_Game_LoadStateData_gameStateData_1_1 + 8),a
	ld	bc,#_Game_LoadStateData_gameStateData_1_1 + 8
	ld	e,c
	ld	d,b
	inc	de
	ld	a,#0x00
	ld	(de),a
	ld	e,c
	ld	d,b
	inc	de
	inc	de
	ld	l,e
	ld	h,d
	ld	(hl),#<_Game_LoadStateData_tilesMenu_1_1
	inc	hl
	ld	(hl),#>_Game_LoadStateData_tilesMenu_1_1
	ld	hl,#0x0004
	add	hl,bc
	ld	(hl),#<__str_16
	inc	hl
	ld	(hl),#>__str_16
	ld	hl,#0x0006
	add	hl,bc
	ld	(hl),#<__str_17
	inc	hl
	ld	(hl),#>__str_17
	ld	a,#0x00
	ld	(#_Game_LoadStateData_gameStateData_1_1 + 16),a
	ld	bc,#_Game_LoadStateData_gameStateData_1_1 + 16
	ld	e,c
	ld	d,b
	inc	de
	ld	a,#0x01
	ld	(de),a
	ld	e,c
	ld	d,b
	inc	de
	inc	de
	ld	l,e
	ld	h,d
	ld	(hl),#<_Game_LoadStateData_tilesLevel_1_1
	inc	hl
	ld	(hl),#>_Game_LoadStateData_tilesLevel_1_1
	ld	hl,#0x0004
	add	hl,bc
	ld	e,l
	ld	d,h
	ld	(hl),#<__str_18
	inc	hl
	ld	(hl),#>__str_18
	ld	hl,#0x0006
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	(hl),#<__str_19
	inc	hl
	ld	(hl),#>__str_19
;pong.c:53: BOOL request_exit = FALSE;              // exit program request flag
	ld	iy,#_request_exit
	ld	0 (iy),#0x00
;keyboard.c:11: player_input player1_input = {FALSE, FALSE, FALSE, KEYBOARD};
	ld	hl,#_player1_input
	ld	(hl),#0x00
	ld	a,#0x00
	ld	(#_player1_input + 1),a
	ld	(#_player1_input + 2),a
	ld	bc,#_player1_input + 3
	ld	a,#0x00
	ld	(bc),a
;keyboard.c:12: player_input player2_input = {FALSE, FALSE, FALSE, KEYBOARD};
	ld	hl,#_player2_input
	ld	(hl),#0x00
	ld	a,#0x00
	ld	(#_player2_input + 1),a
	ld	(#_player2_input + 2),a
	ld	bc,#_player2_input + 3
	ld	a,#0x00
	ld	(bc),a
;keyboard.c:31: keyboard_input_map_t keyboard_input_map[] = {
	ld	hl,#_keyboard_input_map
	ld	(hl),#0x1C
	ld	hl, #_keyboard_input_map + 1
	ld	(hl),#<_player1_input
	inc	hl
	ld	(hl),#>_player1_input
	ld	a,#0x1A
	ld	(#_keyboard_input_map + 3),a
	ld	bc,#_keyboard_input_map + 3+1
	ld	de,#_player1_input + 1
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	bc,#_keyboard_input_map + 6
	ld	a,#0x3B
	ld	(bc),a
	ld	hl, #_keyboard_input_map + 6
	inc	hl
	ld	(hl),#<_player2_input
	inc	hl
	ld	(hl),#>_player2_input
	ld	a,#0x3A
	ld	(#_keyboard_input_map + 9),a
	ld	bc,#_keyboard_input_map + 9+1
	ld	de,#_player2_input + 1
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	a,#0x22
	ld	(#_keyboard_input_map + 12),a
	ld	bc,#_keyboard_input_map + 12+1
	ld	de,#_player1_input + 2
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	a,#0x41
	ld	(#_keyboard_input_map + 15),a
	ld	bc,#_keyboard_input_map + 15+1
	ld	de,#_player2_input + 2
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	a,#0x4D
	ld	(#_keyboard_input_map + 18),a
	ld	bc,#_keyboard_input_map + 18+1
	ld	de,#_game + 5
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;obj_.h:35: void GameObj_SetPos(GameObj* this, int x, int y)
;	---------------------------------
; Function GameObj_SetPos
; ---------------------------------
_GameObj_SetPos_start::
_GameObj_SetPos:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_.h:37: this->x = x;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	l,c
	ld	h,b
	inc	hl
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
;obj_.h:38: this->y = y;
	ld	l,c
	ld	h,b
	inc	hl
	inc	hl
	inc	hl
	ld	a,8 (ix)
	ld	(hl),a
	inc	hl
	ld	a,9 (ix)
	ld	(hl),a
	pop	ix
	ret
_GameObj_SetPos_end::
_own_sp:
	.dw #0x6A80
;obj_.h:42: void GameObj_SetInUse(GameObj* this, BOOL inUse)
;	---------------------------------
; Function GameObj_SetInUse
; ---------------------------------
_GameObj_SetInUse_start::
_GameObj_SetInUse:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_.h:44: this->in_use = inUse;
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	pop	iy
	ld	a,6 (ix)
	ld	(iy),a
	pop	ix
	ret
_GameObj_SetInUse_end::
;obj_.h:47: BOOL GameObj_GetInUse(GameObj* this)
;	---------------------------------
; Function GameObj_GetInUse
; ---------------------------------
_GameObj_GetInUse_start::
_GameObj_GetInUse:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_.h:49: return this->in_use;
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	pop	iy
	ld	c,(iy)
	ld	l,c
	pop	ix
	ret
_GameObj_GetInUse_end::
;pong.c:67: char inportb(int a) {return a;}
;	---------------------------------
; Function inportb
; ---------------------------------
_inportb_start::
_inportb:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	l,4 (ix)
	pop	ix
	ret
_inportb_end::
;pong.c:68: void delay(int a) {a;}
;	---------------------------------
; Function delay
; ---------------------------------
_delay_start::
_delay:
	push	ix
	ld	ix,#0
	add	ix,sp
	pop	ix
	ret
_delay_end::
;math.c:18: BOOL Math_IsBoxHitBox(const RECT* p1, const RECT* p2)
;	---------------------------------
; Function Math_IsBoxHitBox
; ---------------------------------
_Math_IsBoxHitBox_start::
_Math_IsBoxHitBox:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-22
	add	hl,sp
	ld	sp,hl
;math.c:25: left1 = p1->x;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	l,c
	ld	h,b
	ld	a,(hl)
	ld	-2 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-1 (ix),a
	ld	a,-2 (ix)
	ld	-16 (ix),a
	ld	a,-1 (ix)
	ld	-15 (ix),a
;math.c:26: left2 = p2->x;
	ld	a,6 (ix)
	ld	-20 (ix),a
	ld	a,7 (ix)
	ld	-19 (ix),a
	ld	l,-20 (ix)
	ld	h,-19 (ix)
	ld	a,(hl)
	ld	-4 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-3 (ix),a
	ld	a,-4 (ix)
	ld	-18 (ix),a
	ld	a,-3 (ix)
	ld	-17 (ix),a
;math.c:27: right1 = p1->x + p1->width;
	ld	hl,#0x0004
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-2 (ix)
	add	a,e
	ld	e,a
	ld	a,-1 (ix)
	adc	a,d
	ld	d,a
	ld	-6 (ix),e
	ld	-5 (ix),d
;math.c:28: right2 = p2->x + p2->width;
	ld	a,-20 (ix)
	add	a,#0x04
	ld	l, a
	ld	a, -19 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-4 (ix)
	add	a,e
	ld	e,a
	ld	a,-3 (ix)
	adc	a,d
	ld	d,a
	ld	-8 (ix),e
	ld	-7 (ix),d
;math.c:29: top1 = p1->y;
	ld	l,c
	ld	h,b
	inc	hl
	inc	hl
	ld	a,(hl)
	ld	-10 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-9 (ix),a
	ld	a,-10 (ix)
	ld	-22 (ix),a
	ld	a,-9 (ix)
	ld	-21 (ix),a
;math.c:30: top2 = p2->y;
	ld	e,-20 (ix)
	ld	d,-19 (ix)
	ex	de,hl
	inc	hl
	inc	hl
	ld	a,(hl)
	ld	-12 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-11 (ix),a
	ld	e,-12 (ix)
	ld	d,-11 (ix)
;math.c:31: bottom1 = p1->y + p1->height;
	ld	hl,#0x0006
	add	hl,bc
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,-10 (ix)
	add	a,c
	ld	c,a
	ld	a,-9 (ix)
	adc	a,b
	ld	b,a
	ld	-14 (ix),c
	ld	-13 (ix),b
;math.c:32: bottom2 = p2->y + p2->height;
	ld	a,-20 (ix)
	add	a,#0x06
	ld	l, a
	ld	a, -19 (ix)
	adc	a, #0x00
	ld	h,a
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,-12 (ix)
	add	a,c
	ld	c,a
	ld	a,-11 (ix)
	adc	a,b
	ld	b,a
;math.c:34: if (bottom1 < top2) return(FALSE);
	ld	a,-14 (ix)
	sub	a,e
	ld	a,-13 (ix)
	sbc	a,d
	jp	P,00102$
	ld	l,#0x00
	jr	00109$
00102$:
;math.c:35: if (top1 > bottom2) return(FALSE);
	ld	a,c
	sub	a,-22 (ix)
	ld	a,b
	sbc	a,-21 (ix)
	jp	P,00104$
	ld	l,#0x00
	jr	00109$
00104$:
;math.c:37: if (right1 < left2) return(FALSE);
	ld	a,-6 (ix)
	sub	a,-18 (ix)
	ld	a,-5 (ix)
	sbc	a,-17 (ix)
	jp	P,00106$
	ld	l,#0x00
	jr	00109$
00106$:
;math.c:38: if (left1 > right2) return(FALSE);
	ld	a,-8 (ix)
	sub	a,-16 (ix)
	ld	a,-7 (ix)
	sbc	a,-15 (ix)
	jp	P,00108$
	ld	l,#0x00
	jr	00109$
00108$:
;math.c:40: return(TRUE);
	ld	l,#0x01
00109$:
	ld	sp,ix
	pop	ix
	ret
_Math_IsBoxHitBox_end::
;math.c:45: static inline word HW_MATH_MUL(word n1, word n2)
;	---------------------------------
; Function HW_MATH_MUL
; ---------------------------------
_HW_MATH_MUL:
	push	ix
	ld	ix,#0
	add	ix,sp
;math.c:48: mm__mult_table = n1;
	ld	a,4 (ix)
	ld	iy,#_mm__mult_table
	ld	0 (iy),a
	ld	a,5 (ix)
	ld	iy,#_mm__mult_table
	ld	1 (iy),a
;math.c:49: mm__mult_index = 0;
	ld	iy,#_mm__mult_index
	ld	0 (iy),#0x00
;math.c:50: mm__mult_write = n2;
	ld	a,6 (ix)
	ld	iy,#_mm__mult_write
	ld	0 (iy),a
	ld	a,7 (ix)
	ld	iy,#_mm__mult_write
	ld	1 (iy),a
;math.c:52: a = mm__mult_read;
	ld	hl,(_mm__mult_read)
;math.c:53: mm__mult_table = 0;     // restore sin table first entry
	ld	iy,#_mm__mult_table
	ld	0 (iy),#0x00
	ld	iy,#_mm__mult_table
	ld	1 (iy),#0x00
;math.c:54: return a;
	pop	ix
	ret
;math.c:58: static inline word HW_SIN_MUL(byte angle, word n2)
;	---------------------------------
; Function HW_SIN_MUL
; ---------------------------------
_HW_SIN_MUL:
	push	ix
	ld	ix,#0
	add	ix,sp
;math.c:60: mm__mult_index = angle;
	ld	a,4 (ix)
	ld	iy,#_mm__mult_index
	ld	0 (iy),a
;math.c:61: mm__mult_write = n2;
	ld	a,5 (ix)
	ld	iy,#_mm__mult_write
	ld	0 (iy),a
	ld	a,6 (ix)
	ld	iy,#_mm__mult_write
	ld	1 (iy),a
;math.c:62: return mm__mult_read;
	ld	hl,(_mm__mult_read)
	pop	ix
	ret
;util.c:5: void DiagMessage(char* pMsg, char* pFilename)
;	---------------------------------
; Function DiagMessage
; ---------------------------------
_DiagMessage_start::
_DiagMessage:
	push	ix
	ld	ix,#0
	add	ix,sp
;util.c:9: err = FLOS_GetLastError();
	call	_FLOS_GetLastError
	ld	c,l
;util.c:11: if(game.isFLOSVideoMode) {
	ld	de,#_game + 9
	ld	a,(de)
	or	a,a
	jr	Z,00103$
;util.c:15: FLOS_PrintString(pMsg);
	push	bc
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;util.c:16: FLOS_PrintString(pFilename);
	push	bc
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;util.c:18: FLOS_PrintString(" OS_err: $");
	push	bc
	ld	hl,#__str_0
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;util.c:19: _uitoa(err, buffer, 16);
	ld	b,#0x00
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	bc
	call	__uitoa
	pop	af
	pop	af
	inc	sp
;util.c:20: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;util.c:21: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_1
	push	hl
	call	_FLOS_PrintString
	pop	af
00103$:
	pop	ix
	ret
_DiagMessage_end::
__str_0:
	.ascii " OS_err: $"
	.db 0x00
__str_1:
	.db 0x0B
	.db 0x00
;util.c:28: BOOL Util_LoadPalette(const char* pFilename)
;	---------------------------------
; Function Util_LoadPalette
; ---------------------------------
_Util_LoadPalette_start::
_Util_LoadPalette:
	push	ix
	ld	ix,#0
	add	ix,sp
;util.c:31: if(!load_file_to_buffer(pFilename, 0, (byte*)0x0000, 0x200, 0))
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0200
	push	hl
	ld	h, #0x00
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
;util.c:32: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00102$
	ld	l,a
	jr	00103$
00102$:
;util.c:34: *((ushort*)PALETTE) = 0;
	ld	iy,#0x0000
	ld	0 (iy),#0x00
	ld	1 (iy),#0x00
;util.c:35: return TRUE;
	ld	l,#0x01
00103$:
	pop	ix
	ret
_Util_LoadPalette_end::
;util.c:40: void Sys_ClearIRQFlags(byte flags)
;	---------------------------------
; Function Sys_ClearIRQFlags
; ---------------------------------
_Sys_ClearIRQFlags_start::
_Sys_ClearIRQFlags:
	push	ix
	ld	ix,#0
	add	ix,sp
;util.c:42: io__sys_clear_irq_flags = flags;
	ld	a,4 (ix)
	out	(_io__sys_clear_irq_flags),a
	pop	ix
	ret
_Sys_ClearIRQFlags_end::
;util.c:46: byte GetR(void)  __naked
;	---------------------------------
; Function GetR
; ---------------------------------
_GetR_start::
_GetR:
;util.c:54: __endasm;
;
		   push af
		   ld a,r
		   ld l,a
		   pop af
		   ret
		   
;disk_io.c:3: BOOL load_file_to_buffer(char *pFilename, dword file_offset, byte* buf, dword len, byte bank)
;	---------------------------------
; Function load_file_to_buffer
; ---------------------------------
_load_file_to_buffer_start::
_load_file_to_buffer:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-7
	add	hl,sp
	ld	sp,hl
;disk_io.c:8: r = diag__FLOS_FindFile(&myFile, pFilename);
	ld	hl,#0x0000
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	push	bc
	call	_diag__FLOS_FindFile
	pop	af
	pop	af
;disk_io.c:9: if(!r) {
;disk_io.c:11: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00102$
	ld	l,a
	jr	00105$
00102$:
;disk_io.c:14: FLOS_SetLoadLength(len);
	ld	l,14 (ix)
	ld	h,15 (ix)
	push	hl
	ld	l,12 (ix)
	ld	h,13 (ix)
	push	hl
	call	_FLOS_SetLoadLength
	pop	af
	pop	af
;disk_io.c:15: FLOS_SetFilePointer(file_offset);
	ld	l,8 (ix)
	ld	h,9 (ix)
	push	hl
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	call	_FLOS_SetFilePointer
	pop	af
	pop	af
;disk_io.c:17: r = diag__FLOS_ForceLoad( buf, bank );
	ld	a,16 (ix)
	push	af
	inc	sp
	ld	l,10 (ix)
	ld	h,11 (ix)
	push	hl
	call	_diag__FLOS_ForceLoad
	pop	af
	inc	sp
	ld	b,l
	ld	c,b
;disk_io.c:18: if(!r) {
	xor	a,a
;disk_io.c:20: return FALSE;
	or	a,c
	jr	NZ,00104$
	ld	l,a
	jr	00105$
00104$:
;disk_io.c:23: return TRUE;
	ld	l,#0x01
00105$:
	ld	sp,ix
	pop	ix
	ret
_load_file_to_buffer_end::
;disk_io.c:28: BOOL diag__FLOS_FindFile(FLOS_FILE* const pFile, const char* pFilename)
;	---------------------------------
; Function diag__FLOS_FindFile
; ---------------------------------
_diag__FLOS_FindFile_start::
_diag__FLOS_FindFile:
	push	ix
	ld	ix,#0
	add	ix,sp
;disk_io.c:32: BEGIN_DISK_OPERATION();
	call	_DiskIO_BeginDiskOperation
;disk_io.c:33: r = FLOS_FindFile(pFile, pFilename);
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_FLOS_FindFile
	pop	af
	pop	af
	ld	c,l
;disk_io.c:34: END_DISK_OPERATION(r);
	push	bc
	ld	a,c
	push	af
	inc	sp
	call	_DiskIO_EndDiskOperation
	inc	sp
	pop	bc
;disk_io.c:35: if(!r) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;disk_io.c:36: DiagMessage("FindFile failed: ", pFilename);
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	ld	hl,#__str_2
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;disk_io.c:37: return FALSE;
	ld	l,#0x00
	jr	00103$
00102$:
;disk_io.c:40: return TRUE;
	ld	l,#0x01
00103$:
	pop	ix
	ret
_diag__FLOS_FindFile_end::
__str_2:
	.ascii "FindFile failed: "
	.db 0x00
;disk_io.c:43: BOOL diag__FLOS_ForceLoad(const byte* address, const byte bank)
;	---------------------------------
; Function diag__FLOS_ForceLoad
; ---------------------------------
_diag__FLOS_ForceLoad_start::
_diag__FLOS_ForceLoad:
	push	ix
	ld	ix,#0
	add	ix,sp
;disk_io.c:47: BEGIN_DISK_OPERATION();
	call	_DiskIO_BeginDiskOperation
;disk_io.c:48: r = FLOS_ForceLoad(address, bank);
	ld	a,6 (ix)
	push	af
	inc	sp
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_FLOS_ForceLoad
	pop	af
	inc	sp
	ld	c,l
;disk_io.c:49: END_DISK_OPERATION(r);
	push	bc
	ld	a,c
	push	af
	inc	sp
	call	_DiskIO_EndDiskOperation
	inc	sp
	pop	bc
;disk_io.c:50: if(!r) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;disk_io.c:51: DiagMessage("ForceLoad failed: ", "");
	ld	hl,#__str_4
	push	hl
	ld	hl,#__str_3
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;disk_io.c:52: return FALSE;
	ld	l,#0x00
	jr	00103$
00102$:
;disk_io.c:55: return TRUE;
	ld	l,#0x01
00103$:
	pop	ix
	ret
_diag__FLOS_ForceLoad_end::
__str_3:
	.ascii "ForceLoad failed: "
	.db 0x00
__str_4:
	.db 0x00
;disk_io.c:73: void ChunkLoader_Init(char* pFilename, /*FLOS_FILE* file,*/ byte* buf, byte bank)
;	---------------------------------
; Function ChunkLoader_Init
; ---------------------------------
_ChunkLoader_Init_start::
_ChunkLoader_Init:
	push	ix
	ld	ix,#0
	add	ix,sp
;disk_io.c:75: cl.pFilename = pFilename;
	ld	hl,#_cl
	ld	a,4 (ix)
	ld	(hl),a
	inc	hl
	ld	a,5 (ix)
	ld	(hl),a
;disk_io.c:77: cl.buf       = buf;
	ld	hl, #_cl + 9
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
;disk_io.c:78: cl.bank      = bank;
	ld	bc,#_cl + 11
	ld	a,8 (ix)
	ld	(bc),a
;disk_io.c:80: cl.file.size   = -1;        // set -1 as "first chunk load" marker
	ld	bc,#_cl + 2+1+1
	ld	l,c
	ld	h,b
	inc	hl
	ld	(hl),#0xFF
	inc	hl
	ld	(hl),#0xFF
	inc	hl
	ld	(hl),#0xFF
	inc	hl
	ld	(hl),#0xFF
;disk_io.c:81: cl.file_offset = 0;
	ld	hl, #_cl + 12
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	pop	ix
	ret
_ChunkLoader_Init_end::
;disk_io.c:86: BOOL ChunkLoader_LoadChunk(void)
;	---------------------------------
; Function ChunkLoader_LoadChunk
; ---------------------------------
_ChunkLoader_LoadChunk_start::
_ChunkLoader_LoadChunk:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-12
	add	hl,sp
	ld	sp,hl
;disk_io.c:91: if(cl.file.size == -1) {
	ld	hl, #_cl + 2+1+1
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,c
	inc	a
	jr	NZ,00115$
	ld	a,b
	inc	a
	jr	NZ,00115$
	ld	a,e
	inc	a
	jr	NZ,00115$
	ld	a,d
	inc	a
	jr	Z,00116$
00115$:
	jr	00104$
00116$:
;disk_io.c:92: if(!diag__FLOS_FindFile(&cl.file, cl.pFilename))
	ld	hl,#_cl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	de,#_cl + 2
	push	bc
	push	de
	call	_diag__FLOS_FindFile
	pop	af
	pop	af
;disk_io.c:93: return FALSE;
	ld	c,l
	xor	a,a
	or	a,l
	jr	NZ,00104$
	ld	l,a
	jp	00107$
00104$:
;disk_io.c:97: (cl.file_offset+0x1000 <  cl.file.size) ?  (num_bytes = 0x1000) :  (num_bytes = cl.file.size - cl.file_offset);
	ld	hl, #_cl + 12
	ld	a,(hl)
	ld	-8 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-7 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-6 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-5 (ix),a
	ld	a,-8 (ix)
	add	a,#0x00
	ld	-12 (ix),a
	ld	a,-7 (ix)
	adc	a,#0x10
	ld	-11 (ix),a
	ld	a,-6 (ix)
	adc	a,#0x00
	ld	-10 (ix),a
	ld	a,-5 (ix)
	adc	a,#0x00
	ld	-9 (ix),a
	ld	hl, #_cl + 2+1+1
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-12 (ix)
	sub	a,c
	ld	a,-11 (ix)
	sbc	a,b
	ld	a,-10 (ix)
	sbc	a,e
	ld	a,-9 (ix)
	sbc	a,d
	jr	NC,00109$
	ld	-4 (ix),#0x00
	ld	-3 (ix),#0x10
	ld	-2 (ix),#0x00
	ld	-1 (ix),#0x00
	jr	00110$
00109$:
	ld	a,c
	sub	a,-8 (ix)
	ld	c,a
	ld	a,b
	sbc	a,-7 (ix)
	ld	b,a
	ld	a,e
	sbc	a,-6 (ix)
	ld	e,a
	ld	a,d
	sbc	a,-5 (ix)
	ld	d,a
	ld	-4 (ix),c
	ld	-3 (ix),b
	ld	-2 (ix),e
	ld	-1 (ix),d
00110$:
;disk_io.c:99: FLOS_SetLoadLength(num_bytes);
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	call	_FLOS_SetLoadLength
	pop	af
	pop	af
;disk_io.c:100: if(!diag__FLOS_ForceLoad(cl.buf, cl.bank))
	ld	hl,#_cl + 11
	ld	c,(hl)
	ld	de,#_cl + 9
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,c
	push	af
	inc	sp
	push	de
	call	_diag__FLOS_ForceLoad
	pop	af
	inc	sp
;disk_io.c:101: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00106$
	ld	l,a
	jr	00107$
00106$:
;disk_io.c:103: cl.file_offset  += num_bytes;
	ld	hl,#_cl + 12
	ld	-12 (ix),l
	ld	-11 (ix),h
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,e
	add	a,-4 (ix)
	ld	e,a
	ld	a,d
	adc	a,-3 (ix)
	ld	d,a
	ld	a,c
	adc	a,-2 (ix)
	ld	c,a
	ld	a,b
	adc	a,-1 (ix)
	ld	b,a
	ld	l,-12 (ix)
	ld	h,-11 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
;disk_io.c:105: return TRUE;
	ld	l,#0x01
00107$:
	ld	sp,ix
	pop	ix
	ret
_ChunkLoader_LoadChunk_end::
;disk_io.c:109: BOOL ChunkLoader_IsDone(void)
;	---------------------------------
; Function ChunkLoader_IsDone
; ---------------------------------
_ChunkLoader_IsDone_start::
_ChunkLoader_IsDone:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;disk_io.c:111: return (cl.file_offset >= cl.file.size);
	ld	hl, #_cl + 12
	ld	a,(hl)
	ld	-4 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-3 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-2 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-1 (ix),a
	ld	hl, #_cl + 2+1+1
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-4 (ix)
	sub	a,c
	ld	a,-3 (ix)
	sbc	a,b
	ld	a,-2 (ix)
	sbc	a,e
	ld	a,-1 (ix)
	sbc	a,d
	ld	a,#0x00
	rla
	or	a,a
	sub	a,#0x01
	ld	a,#0x00
	rla
	ld	l,a
	ld	sp,ix
	pop	ix
	ret
_ChunkLoader_IsDone_end::
;disk_io.c:116: void DiskIO_BeginDiskOperation(void)
;	---------------------------------
; Function DiskIO_BeginDiskOperation
; ---------------------------------
_DiskIO_BeginDiskOperation_start::
_DiskIO_BeginDiskOperation:
;disk_io.c:120: DI();
		di 
	ret
_DiskIO_BeginDiskOperation_end::
;disk_io.c:123: void DiskIO_EndDiskOperation(BOOL isOperationOk)
;	---------------------------------
; Function DiskIO_EndDiskOperation
; ---------------------------------
_DiskIO_EndDiskOperation_start::
_DiskIO_EndDiskOperation:
	push	ix
	ld	ix,#0
	add	ix,sp
;disk_io.c:127: if(!isOperationOk) {
	xor	a,a
	or	a,4 (ix)
	jr	NZ,00102$
;disk_io.c:128: DiskIO_VisualizeDiskError();
	call	_DiskIO_VisualizeDiskError
00102$:
;disk_io.c:131: EI();
		ei 
	pop	ix
	ret
_DiskIO_EndDiskOperation_end::
;disk_io.c:134: void DiskIO_VisualizeDiskError(void)
;	---------------------------------
; Function DiskIO_VisualizeDiskError
; ---------------------------------
_DiskIO_VisualizeDiskError_start::
_DiskIO_VisualizeDiskError:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;disk_io.c:136: ushort* p = (ushort*) PALETTE;
	ld	-2 (ix),#0x00
	ld	-1 (ix),#0x00
;disk_io.c:141: color = 0xf00;
	ld	-4 (ix),#0x00
	ld	-3 (ix),#0x0F
;disk_io.c:143: for(t=0; t<6; t++) {
	ld	d,#0x00
00108$:
	ld	a,d
	sub	a,#0x06
	jr	NC,00112$
;disk_io.c:144: *p = color;
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,-4 (ix)
	ld	(hl),a
	inc	hl
	ld	a,-3 (ix)
	ld	(hl),a
;disk_io.c:145: for(i=0; i<25;i++) {        // delay
	ld	b,#0x00
00104$:
	ld	a,b
	sub	a,#0x19
	jr	NC,00107$
;disk_io.c:146: FLOS_WaitVRT();
	push	bc
	push	de
	call	_FLOS_WaitVRT
	pop	de
	pop	bc
;disk_io.c:147: for(k=0; k<10000; k++);
	ld	c,#0x10
	ld	e,#0x27
00103$:
	ld	l,c
	ld	h,e
	dec	hl
	ld	c,l
	ld	e,h
	ld	a,c
	or	a,e
	jr	NZ,00103$
;disk_io.c:145: for(i=0; i<25;i++) {        // delay
	inc	b
	jr	00104$
00107$:
;disk_io.c:149: color ^= 0xf00;
	ld	a,-3 (ix)
	xor	a,#0x0F
	ld	-3 (ix),a
;disk_io.c:143: for(t=0; t<6; t++) {
	inc	d
	jr	00108$
00112$:
	ld	sp,ix
	pop	ix
	ret
_DiskIO_VisualizeDiskError_end::
;loading_icon.c:5: BOOL LoadingIcon_LoadSprites(void)
;	---------------------------------
; Function LoadingIcon_LoadSprites
; ---------------------------------
_LoadingIcon_LoadSprites_start::
_LoadingIcon_LoadSprites:
;loading_icon.c:7: const char *pFilename = SPRITES_DISKETTE_FILENAME;
;loading_icon.c:10: if(!load_file_to_buffer(pFilename, 0, (byte*)BUF_FOR_LOADING_SPRITES_4KB, size, PONG_BANK))
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0900
	push	hl
	ld	h, #0xF0
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#__str_5
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
;loading_icon.c:11: return FALSE;
	ld	c,l
	xor	a,a
	or	a,l
	jr	NZ,00102$
	ld	l,a
	ret
00102$:
;loading_icon.c:14: PAGE_IN_SPRITE_RAM();
	in	a,(_io__sys_mem_select)
	or	a,#0x80
	out	(_io__sys_mem_select),a
;loading_icon.c:15: SET_SPRITE_PAGE(31);
	ld	iy,#_mm__vreg_vidpage
	ld	0 (iy),#0x9F
;loading_icon.c:16: memcpy((byte*)SPRITE_BASE+4096-size, (byte*)BUF_FOR_LOADING_SPRITES_4KB, size);
	ld	de,#0x1700
	ld	hl,#0xF000
	ld	bc,#0x0900
	ldir
;loading_icon.c:17: PAGE_OUT_SPRITE_RAM();
	in	a,(_io__sys_mem_select)
	ld	c,a
	and	a,#0x7F
	out	(_io__sys_mem_select),a
;loading_icon.c:19: loadingIcon.isLoaded = TRUE;
	ld	hl,#_loadingIcon
	ld	(hl),#0x01
;loading_icon.c:20: return TRUE;
	ld	l,#0x01
	ret
_LoadingIcon_LoadSprites_end::
__str_5:
	.ascii "LOAD_ICO.SPR"
	.db 0x00
;loading_icon.c:23: void LoadingIcon_Enable(BOOL isEnable)
;	---------------------------------
; Function LoadingIcon_Enable
; ---------------------------------
_LoadingIcon_Enable_start::
_LoadingIcon_Enable:
	push	ix
	ld	ix,#0
	add	ix,sp
;loading_icon.c:28: if(isEnable) {
	xor	a,a
	or	a,4 (ix)
	jp	Z,00104$
;loading_icon.c:29: if(!loadingIcon.isLoaded)
	ld	hl,#_loadingIcon
	ld	a,(hl)
	or	a,a
;loading_icon.c:30: return;
	jp	Z,00106$
;loading_icon.c:34: game.shadow_sprite_register_bank = 0;
	ld	bc,#_game + 12
	ld	a,#0x00
	ld	(bc),a
;loading_icon.c:35: SET_LIVE_SPRITE_REGISTER_BANK(game.shadow_sprite_register_bank);
	ld	a,(bc)
	ld	c,a
	sla	c
	sla	c
	ld	a,c
	or	a,#0x09
	ld	hl,#_mm__vreg_sprctrl + 0
	ld	(hl), a
;loading_icon.c:37: clear_sprite_regs();
	call	_clear_sprite_regs
;loading_icon.c:39: set_sprite_regs(SPRITE_NUM_DISKETTE   , x,    y, 3, SPRITE_DEF_NUM_DISKETTE  , FALSE);
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x01F7
	push	hl
	ld	a,#0x03
	push	af
	inc	sp
	ld	hl,#0x00B0
	push	hl
	ld	l, #0xA0
	push	hl
	ld	a,#0x00
	push	af
	inc	sp
	call	_set_sprite_regs
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
;loading_icon.c:40: set_sprite_regs(SPRITE_NUM_DISKETTE+1 , x+16, y, 3, SPRITE_DEF_NUM_DISKETTE+3, FALSE);
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x01FA
	push	hl
	ld	a,#0x03
	push	af
	inc	sp
	ld	hl,#0x00B0
	push	hl
	ld	l, #0xB0
	push	hl
	ld	a,#0x01
	push	af
	inc	sp
	call	_set_sprite_regs
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
;loading_icon.c:41: set_sprite_regs(SPRITE_NUM_DISKETTE+2 , x+32, y, 3, SPRITE_DEF_NUM_DISKETTE+6, FALSE);
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x01FD
	push	hl
	ld	a,#0x03
	push	af
	inc	sp
	ld	hl,#0x00B0
	push	hl
	ld	l, #0xC0
	push	hl
	ld	a,#0x02
	push	af
	inc	sp
	call	_set_sprite_regs
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
;loading_icon.c:43: memcpy((byte*)PALETTE, (byte*)loadingIcon.palette, 0x200);
	ld	hl,#_loadingIcon + 1
	ld	de,#0x0000
	ld	bc,#0x0200
	ldir
	jr	00106$
00104$:
;loading_icon.c:45: clear_sprite_regs();
	call	_clear_sprite_regs
00106$:
	pop	ix
	ret
_LoadingIcon_Enable_end::
;loading_icon.c:53: BOOL LoadingIcon_Load(void)
;	---------------------------------
; Function LoadingIcon_Load
; ---------------------------------
_LoadingIcon_Load_start::
_LoadingIcon_Load:
;loading_icon.c:55: if(!LoadingIcon_LoadSprites())
	call	_LoadingIcon_LoadSprites
;loading_icon.c:56: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00102$
	ld	l,a
	ret
00102$:
;loading_icon.c:58: if(!load_file_to_buffer(PALETTE_DISKETTE_FILENAME, 0, (byte*)loadingIcon.palette, 0x200, PONG_BANK))
	ld	bc,#_loadingIcon + 1
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0200
	push	hl
	push	bc
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#__str_6
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
;loading_icon.c:59: return FALSE;
	ld	c,l
	xor	a,a
	or	a,l
	jr	NZ,00104$
	ld	l,a
	ret
00104$:
;loading_icon.c:60: loadingIcon.palette[0] = 0;
	ld	hl, #_loadingIcon + 1
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;loading_icon.c:62: return TRUE;
	ld	l,#0x01
	ret
_LoadingIcon_Load_end::
__str_6:
	.ascii "LOAD_ICO.PAL"
	.db 0x00
;sprites.c:4: void initgraph(void)
;	---------------------------------
; Function initgraph
; ---------------------------------
_initgraph_start::
_initgraph:
;sprites.c:7: mm__vreg_vidctrl = TILE_MAP_MODE|WIDE_LEFT_BORDER;       //|DUAL_PLAY_FIELD;
	ld	hl,#_mm__vreg_vidctrl + 0
	ld	(hl), #0x03
;sprites.c:10: mm__vreg_ext_vidctrl = EXTENDED_TILE_MAP_MODE;
	ld	hl,#_mm__vreg_ext_vidctrl + 0
	ld	(hl), #0x01
;sprites.c:13: mm__vreg_rasthi = 0;
	ld	hl,#_mm__vreg_rasthi + 0
	ld	(hl), #0x00
;sprites.c:15: mm__vreg_window = (Y_WINDOW_START<<4)|Y_WINDOW_STOP;
	ld	hl,#_mm__vreg_window + 0
	ld	(hl), #0x3D
;sprites.c:17: mm__vreg_rasthi = SWITCH_TO_X_WINDOW_REGISTER;
	ld	hl,#_mm__vreg_rasthi + 0
	ld	(hl), #0x04
;sprites.c:19: mm__vreg_window = (X_WINDOW_START<<4)|X_WINDOW_STOP;
	ld	hl,#_mm__vreg_window + 0
	ld	(hl), #0x6E
;sprites.c:21: clear_sprite_regs();
	call	_clear_sprite_regs
;sprites.c:24: mm__vreg_sprctrl = SPRITE_ENABLE|DOUBLE_BUFFER_SPRITE_REGISTER_MODE;
	ld	hl,#_mm__vreg_sprctrl + 0
	ld	(hl), #0x09
;sprites.c:27: mm__vreg_yhws_bplcount = 0;         //pf A
	ld	hl,#_mm__vreg_yhws_bplcount + 0
	ld	(hl), #0x00
;sprites.c:28: mm__vreg_yhws_bplcount = 0x80 | 0;  //pf B
	ld	hl,#_mm__vreg_yhws_bplcount + 0
	ld	(hl), #0x80
;sprites.c:30: mm__vreg_xhws = 0;       //pf A and pf B
	ld	hl,#_mm__vreg_xhws + 0
	ld	(hl), #0x00
;sprites.c:32: game.isFLOSVideoMode = FALSE;
	ld	a,#0x00
	ld	(#_game + 9),a
	ret
_initgraph_end::
;sprites.c:36: void clear_sprite_regs(void)
;	---------------------------------
; Function clear_sprite_regs
; ---------------------------------
_clear_sprite_regs_start::
_clear_sprite_regs:
;sprites.c:40: for(p = (byte*)SPR_REGISTERS; p < (byte*)(SPR_REGISTERS+0x200); p++)
	ld	bc,#0x0400
00101$:
	ld	a,c
	sub	a,#0x00
	ld	a,b
	sbc	a,#0x06
	ret	NC
;sprites.c:41: *p = 0;
	ld	a,#0x00
	ld	(bc),a
;sprites.c:40: for(p = (byte*)SPR_REGISTERS; p < (byte*)(SPR_REGISTERS+0x200); p++)
	inc	bc
	jr	00101$
_clear_sprite_regs_end::
;sprites.c:46: void clear_shadow_sprite_regs(void)
;	---------------------------------
; Function clear_shadow_sprite_regs
; ---------------------------------
_clear_shadow_sprite_regs_start::
_clear_shadow_sprite_regs:
;sprites.c:50: p = (byte*)SPR_REGISTERS + (game.shadow_sprite_register_bank*64*4);
	ld	hl,#_game + 12
	ld	c,(hl)
	ld	b,c
	ld	c,#0x00
	ld	hl,#0x0400
	add	hl,bc
	ld	c,l
	ld	b,h
;sprites.c:51: memset(p, 0, 0x100);
	ld	hl,#0x0100
	push	hl
	ld	a,#0x00
	push	af
	inc	sp
	push	bc
	call	_memset
	pop	af
	pop	af
	inc	sp
	ret
_clear_shadow_sprite_regs_end::
;sprites.c:55: void DrawBat(int x1,int y1,int x2,int y2)
;	---------------------------------
; Function DrawBat
; ---------------------------------
_DrawBat_start::
_DrawBat:
	push	ix
	ld	ix,#0
	add	ix,sp
;sprites.c:67: if(x1<160) {
	ld	a,4 (ix)
	sub	a,#0xA0
	ld	a,5 (ix)
	sbc	a,#0x00
	jp	P,00102$
;sprites.c:68: num_bat = 0; x_flip = TRUE;  p = &batA;
	ld	bc,#0x0100
	ld	de,#_batA
	jr	00103$
00102$:
;sprites.c:70: num_bat = 1; x_flip = FALSE; p = &batB;
	ld	bc,#0x0001
	ld	de,#_batB
00103$:
;sprites.c:85: if(p->state != NORMAL)
	ld	hl,#0x0017
	add	hl,de
	ld	a,(hl)
	or	a,a
	jr	Z,00105$
;sprites.c:86: y1 = SPRITE_Y_OFFSCREEN;
	ld	6 (ix),#0x00
	ld	7 (ix),#0x01
00105$:
;sprites.c:89: set_sprite_regs(num_bat, x1-4,  y1, spr_height, spr_def, x_flip);
	ld	a,4 (ix)
	add	a,#0xFC
	ld	e,a
	ld	a,5 (ix)
	adc	a,#0xFF
	ld	d,a
	push	bc
	inc	sp
	ld	hl,#0x0002
	push	hl
	ld	a,#0x02
	push	af
	inc	sp
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	push	de
	ld	a,c
	push	af
	inc	sp
	call	_set_sprite_regs
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
	pop	ix
	ret
_DrawBat_end::
;sprites.c:93: void DrawBall(int x_center,int y_center,int r1,int r2)
;	---------------------------------
; Function DrawBall
; ---------------------------------
_DrawBall_start::
_DrawBall:
	push	ix
	ld	ix,#0
	add	ix,sp
	dec	sp
;sprites.c:96: word spr_def = 0;   /* sprite_definition_number*/
	ld	bc,#0x0000
;sprites.c:99: if(ball1.state == DYING)
	ld	de,#_ball1 + 29
	ld	a,(de)
	ld	-1 (ix),a
	sub	a,#0x01
	jr	NZ,00102$
;sprites.c:100: spr_def = SPRITE_DEF_NUM_DYING_BALL + (ball1.dying_time/8);
	ld	hl,#_ball1 + 31
	ld	e,(hl)
	srl	e
	srl	e
	srl	e
	ld	d,#0x00
	ld	hl,#0x000E
	add	hl,de
	ld	c,l
	ld	b,h
00102$:
;sprites.c:103: x_center -= 8;
	ld	a,4 (ix)
	add	a,#0xF8
	ld	4 (ix),a
	ld	a,5 (ix)
	adc	a,#0xFF
	ld	5 (ix),a
;sprites.c:104: y_center -= 8;
	ld	a,6 (ix)
	add	a,#0xF8
	ld	6 (ix),a
	ld	a,7 (ix)
	adc	a,#0xFF
	ld	7 (ix),a
;sprites.c:106: if(ball1.state == DIE)
	ld	a,-1 (ix)
	sub	a,#0x02
	jr	NZ,00104$
;sprites.c:107: y_center = SPRITE_Y_OFFSCREEN;
	ld	6 (ix),#0x00
	ld	7 (ix),#0x01
00104$:
;sprites.c:109: set_sprite_regs(SPRITE_NUM_BALL, x_center,  y_center, spr_height, spr_def, FALSE);
	ld	a,#0x00
	push	af
	inc	sp
	push	bc
	ld	a,#0x01
	push	af
	inc	sp
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	ld	a,#0x03
	push	af
	inc	sp
	call	_set_sprite_regs
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
	ld	sp,ix
	pop	ix
	ret
_DrawBall_end::
;sprites.c:117: /*static inline*/ void set_sprite_regs_hw(byte sprite_number, byte x, byte misc, byte y, byte sprite_definition_number)
;	---------------------------------
; Function set_sprite_regs_hw
; ---------------------------------
_set_sprite_regs_hw_start::
_set_sprite_regs_hw:
	push	ix
	ld	ix,#0
	add	ix,sp
;sprites.c:122: if (game.shadow_sprite_register_bank == 0)
	ld	bc,#_game + 12
	ld	a,(bc)
	or	a,a
	jr	NZ,00102$
;sprites.c:123: p = (byte *) SPR_REGISTERS;
	ld	bc,#0x0400
	jr	00103$
00102$:
;sprites.c:125: p = (byte *) SPR_REGISTERS + 0x100;     // add offset of shadow sprite register bank
	ld	bc,#0x0500
00103$:
;sprites.c:127: p += ((sprite_number*4));
	ld	e,4 (ix)
	ld	d,#0x00
	sla	e
	rl	d
	sla	e
	rl	d
	ld	a,c
	add	a,e
	ld	c,a
	ld	a,b
	adc	a,d
	ld	b,a
;sprites.c:128: *p =  x;                            p++;
	ld	a,5 (ix)
	ld	(bc),a
	inc	bc
;sprites.c:129: *p =  misc;                         p++;
	ld	a,6 (ix)
	ld	(bc),a
	inc	bc
;sprites.c:130: *p =  y;                            p++;
	ld	a,7 (ix)
	ld	(bc),a
	inc	bc
;sprites.c:131: *p =  sprite_definition_number;
	ld	a,8 (ix)
	ld	(bc),a
	pop	ix
	ret
_set_sprite_regs_hw_end::
;sprites.c:136: void set_sprite_regs(byte sprite_number, int x, int y, byte height, word sprite_definition_number, BOOL x_flip)
;	---------------------------------
; Function set_sprite_regs
; ---------------------------------
_set_sprite_regs_start::
_set_sprite_regs:
	push	ix
	ld	ix,#0
	add	ix,sp
;sprites.c:142: x =  x + X_WINDOW_START*16;
	ld	a,5 (ix)
	add	a,#0x60
	ld	5 (ix),a
	ld	a,6 (ix)
	adc	a,#0x00
	ld	6 (ix),a
;sprites.c:143: x =  x + 16;  // + wide left border
	ld	a,5 (ix)
	add	a,#0x10
	ld	5 (ix),a
	ld	a,6 (ix)
	adc	a,#0x00
	ld	6 (ix),a
;sprites.c:145: y =  y + Y_WINDOW_START*8 + 1;
	ld	a,7 (ix)
	add	a,#0x19
	ld	7 (ix),a
	ld	a,8 (ix)
	adc	a,#0x00
	ld	8 (ix),a
;sprites.c:148: reg_misc = GET_WORD_9TH_BIT(x)                                  |
	ld	c,5 (ix)
	ld	a,6 (ix)
	and	a,#0x01
	ld	c,a
	ld	b,#0x00
;sprites.c:149: GET_WORD_9TH_BIT(y) << 1                             |
	ld	e,7 (ix)
	ld	a,8 (ix)
	and	a,#0x01
	ld	e,a
	sla	e
	ld	d,#0x00
	ld	a,e
	or	a,c
	ld	e,a
	ld	a,d
	or	a,b
	ld	d,a
;sprites.c:150: GET_WORD_9TH_BIT(sprite_definition_number) << 2      |
	ld	a,11 (ix)
	and	a,#0x01
	ld	c,a
	sla	c
	sla	c
	ld	b,#0x00
	ld	a,e
	or	a,c
	ld	e,a
	ld	a,d
	or	a,b
	ld	d,a
;sprites.c:151: ((x_flip&1) << 3)                                    |
	ld	a,12 (ix)
	and	a,#0x01
	rlca
	rlca
	rlca
	and	a,#0xF8
	ld	c,a
	ld	b,#0x00
	ld	a,e
	or	a,c
	ld	e,a
	ld	a,d
	or	a,b
	ld	d,a
;sprites.c:152: (height << 4)
	ld	a,9 (ix)
	rlca
	rlca
	rlca
	rlca
	and	a,#0xF0
	ld	c,a
	ld	b,#0x00
	ld	a,e
	or	a,c
	ld	e,a
	ld	a,d
	or	a,b
;sprites.c:158: ,(byte)sprite_definition_number);
	ld	c,10 (ix)
	ld	b,7 (ix)
;sprites.c:155: (byte)x,
	ld	d,5 (ix)
;sprites.c:154: set_sprite_regs_hw(sprite_number,
	ld	a,c
	push	af
	inc	sp
	push	bc
	inc	sp
	ld	a,e
	push	af
	inc	sp
	push	de
	inc	sp
	ld	a,4 (ix)
	push	af
	inc	sp
	call	_set_sprite_regs_hw
	pop	af
	pop	af
	inc	sp
	pop	ix
	ret
_set_sprite_regs_end::
;sprites.c:178: void set_sprite_regs_optimized(void)
;	---------------------------------
; Function set_sprite_regs_optimized
; ---------------------------------
_set_sprite_regs_optimized_start::
_set_sprite_regs_optimized:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-6
	add	hl,sp
	ld	sp,hl
;sprites.c:183: spr_reg.x += X_WINDOW_START*16;
	ld	bc,#_spr_reg + 1
	ld	l,c
	ld	h,b
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	hl,#0x0060
	add	hl,de
	ex	de,hl
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
;sprites.c:184: spr_reg.x +=  16;  // + wide left border
	ld	hl,#0x0010
	add	hl,de
	ex	de,hl
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
;sprites.c:186: spr_reg.y +=  Y_WINDOW_START*8 + 1;
	ld	hl,#_spr_reg + 3
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	hl,#0x0019
	add	hl,bc
	ld	-4 (ix),l
	ld	-3 (ix),h
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,-4 (ix)
	ld	(hl),a
	inc	hl
	ld	a,-3 (ix)
	ld	(hl),a
;sprites.c:189: spr_reg.reg_misc =
	ld	hl,#_spr_reg + 8
	ld	-2 (ix),l
	ld	-1 (ix),h
;sprites.c:190: GET_WORD_9TH_BIT(spr_reg.x)      |
	ld	a,d
	and	a,#0x01
	ld	-6 (ix),a
	ld	-5 (ix),#0x00
;sprites.c:191: GET_WORD_9TH_BIT(spr_reg.y) << 1 |
	ld	c,-4 (ix)
	ld	a,-3 (ix)
	and	a,#0x01
	ld	c,a
	sla	c
	ld	b,#0x00
	ld	a,-6 (ix)
	or	a,c
	ld	-6 (ix),a
	ld	a,-5 (ix)
	or	a,b
	ld	-5 (ix),a
;sprites.c:192: ((spr_reg.x_flip&1) << 3)        |
	ld	bc,#_spr_reg + 7
	ld	a,(bc)
	and	a,#0x01
	rlca
	rlca
	rlca
	and	a,#0xF8
	ld	c,a
	ld	b,#0x00
	ld	a,-6 (ix)
	or	a,c
	ld	-6 (ix),a
	ld	a,-5 (ix)
	or	a,b
	ld	-5 (ix),a
;sprites.c:193: (spr_reg.height << 4)
	ld	bc,#_spr_reg + 5
	ld	a,(bc)
	rlca
	rlca
	rlca
	rlca
	and	a,#0xF0
	ld	b,#0x00
	or	a,-6 (ix)
	ld	c,a
	ld	a,b
	or	a,-5 (ix)
	ld	-6 (ix),c
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,-6 (ix)
	ld	(hl),a
;sprites.c:203: p = (byte*)(SPR_REGISTERS + (spr_reg.sprite_number*4)
	ld	hl,#_spr_reg
	ld	b,(hl)
	ld	c,b
	ld	b,#0x00
	sla	c
	rl	b
	sla	c
	rl	b
	ld	hl,#0x0400
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
;sprites.c:204: + (game.shadow_sprite_register_bank*0x100U));       // add offset of shadow sprite register bank
	ld	hl,#_game + 12
	ld	c,(hl)
	ld	b,c
	ld	c,#0x00
	ld	a,-2 (ix)
	add	a,c
	ld	c,a
	ld	a,-1 (ix)
	adc	a,b
	ld	b,a
;sprites.c:206: *p =  (byte) spr_reg.x;                     p++;
	ld	a,e
	ld	(bc),a
	inc	bc
;sprites.c:207: *p =         spr_reg.reg_misc;              p++;
	ld	a,-6 (ix)
	ld	(bc),a
	inc	bc
;sprites.c:208: *p =  (byte) spr_reg.y;                     p++;
	ld	a,-4 (ix)
	ld	(bc),a
	inc	bc
;sprites.c:209: *p =         spr_reg.sprite_definition_number;
	ld	de,#_spr_reg + 6
	ld	a,(de)
	ld	(bc),a
	ld	sp,ix
	pop	ix
	ret
_set_sprite_regs_optimized_end::
;sprites.c:215: BOOL load_sprites(void)
;	---------------------------------
; Function load_sprites
; ---------------------------------
_load_sprites_start::
_load_sprites:
;sprites.c:218: char *pFilename = SPRITES_FILENAME;
;sprites.c:224: ChunkLoader_Init(pFilename, /*&myFile,*/ (byte*)BUF_FOR_LOADING_SPRITES_4KB, PONG_BANK);
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0xF000
	push	hl
	ld	hl,#__str_7
	push	hl
	call	_ChunkLoader_Init
	pop	af
	pop	af
	inc	sp
;sprites.c:226: while(!ChunkLoader_IsDone()) {
	ld	c,#0x00
00103$:
	push	bc
	call	_ChunkLoader_IsDone
	ld	a,l
	pop	bc
	ld	b,a
	or	a,a
	jr	NZ,00105$
;sprites.c:227: if(!ChunkLoader_LoadChunk())
	push	bc
	call	_ChunkLoader_LoadChunk
	ld	a,l
	pop	bc
	ld	b,a
;sprites.c:228: return FALSE;
	or	a,a
	jr	NZ,00102$
	ld	l,a
	ret
00102$:
;sprites.c:231: PAGE_IN_SPRITE_RAM();
	in	a,(_io__sys_mem_select)
	or	a,#0x80
	out	(_io__sys_mem_select),a
;sprites.c:232: SET_SPRITE_PAGE(sprite_page);
	ld	a,c
	or	a,#0x80
	ld	iy,#_mm__vreg_vidpage
	ld	0 (iy),a
;sprites.c:233: memcpy((byte*)SPRITE_BASE, (byte*)BUF_FOR_LOADING_SPRITES_4KB, 0x1000);
	push	bc
	ld	de,#0x1000
	ld	hl,#0xF000
	ld	bc,#0x1000
	ldir
	pop	bc
;sprites.c:234: PAGE_OUT_SPRITE_RAM();
	in	a,(_io__sys_mem_select)
	ld	b,a
	and	a,#0x7F
	out	(_io__sys_mem_select),a
;sprites.c:236: sprite_page++;
	inc	c
	jr	00103$
00105$:
;sprites.c:239: return TRUE;
	ld	l,#0x01
	ret
_load_sprites_end::
__str_7:
	.ascii "PONG.SPR"
	.db 0x00
;sprites.c:246: void wait_y_window(void)
;	---------------------------------
; Function wait_y_window
; ---------------------------------
_wait_y_window_start::
_wait_y_window:
;sprites.c:258: do{
00101$:
;sprites.c:259: b = mm__vreg_read;
;sprites.c:260: } while( (b&4) == 0 );
	ld	a,(#_mm__vreg_read+0)
	and	a,#0x04
	jr	Z,00101$
	ret
_wait_y_window_end::
;background.c:13: BOOL Background_LoadTiles(const char* pFilename, word vram_addr)
;	---------------------------------
; Function Background_LoadTiles
; ---------------------------------
_Background_LoadTiles_start::
_Background_LoadTiles:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;background.c:15: byte video_page = vram_addr/0x20;
	ld	c,6 (ix)
	ld	b,7 (ix)
	srl	b
	rr	c
	srl	b
	rr	c
	srl	b
	rr	c
	srl	b
	rr	c
	srl	b
	rr	c
;background.c:16: word video_offset = (vram_addr&0x1F) * 0x100;
	ld	a,6 (ix)
	and	a,#0x1F
	ld	-1 (ix),a
;background.c:17: if(video_offset!=0 && video_offset!=0x1000) return FALSE;
	ld	-2 (ix),#0x00
	ld	a, #0x00
	or	a,-1 (ix)
	jr	Z,00102$
	ld	a,-2 (ix)
	or	a,a
	jr	NZ,00120$
	ld	a,-1 (ix)
	sub	a,#0x10
	jr	Z,00102$
00120$:
	ld	l,#0x00
	jp	00111$
00102$:
;background.c:22: ChunkLoader_Init(pFilename,/*&myFile,*/ (byte*)BUF_FOR_LOADING_BACKGROUND_4KB, 0);
	push	bc
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0xF000
	push	hl
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_ChunkLoader_Init
	pop	af
	pop	af
	inc	sp
	pop	bc
;background.c:24: while(!ChunkLoader_IsDone()) {
00108$:
	push	bc
	call	_ChunkLoader_IsDone
	ld	a,l
	pop	bc
	ld	b,a
	or	a,a
	jp	NZ,00110$
;background.c:25: if(!ChunkLoader_LoadChunk())
	push	bc
	call	_ChunkLoader_LoadChunk
	ld	a,l
	pop	bc
	ld	b,a
;background.c:26: return FALSE;
	or	a,a
	jr	NZ,00105$
	ld	l,a
	jr	00111$
00105$:
;background.c:29: PAGE_IN_VIDEO_RAM();
	in	a,(_io__sys_mem_select)
	or	a,#0x40
	out	(_io__sys_mem_select),a
;background.c:30: SET_VIDEO_PAGE(video_page);
	ld	iy,#_mm__vreg_vidpage
	ld	0 (iy),c
;background.c:31: memcpy((byte*)(VIDEO_BASE + video_offset), (byte*)BUF_FOR_LOADING_BACKGROUND_4KB, 0x1000);
	ld	a,-2 (ix)
	add	a,#0x00
	ld	b,a
	ld	a,-1 (ix)
	adc	a,#0x20
	ld	e,a
	ld	l,b
	ld	h,a
	push	bc
	ex	de,hl
	ld	hl,#0xF000
	ld	bc,#0x1000
	ldir
	pop	bc
;background.c:32: PAGE_OUT_VIDEO_RAM();
	in	a,(_io__sys_mem_select)
	ld	b,a
	and	a,#0xBF
	out	(_io__sys_mem_select),a
;background.c:35: video_offset += 0x1000;
	ld	a,-2 (ix)
	add	a,#0x00
	ld	-2 (ix),a
	ld	a,-1 (ix)
	adc	a,#0x10
	ld	-1 (ix),a
;background.c:36: if(video_offset >= 0x2000) {
	ld	a,-2 (ix)
	sub	a,#0x00
	ld	a,-1 (ix)
	sbc	a,#0x20
	jp	C,00108$
;background.c:37: video_offset = 0;
	ld	-2 (ix),#0x00
	ld	-1 (ix),#0x00
;background.c:38: video_page++;
	inc	c
	jp	00108$
00110$:
;background.c:42: return TRUE;
	ld	l,#0x01
00111$:
	ld	sp,ix
	pop	ix
	ret
_Background_LoadTiles_end::
;background.c:45: void TileMap_FillTileDefinition(word tileNumber, byte fillValue)
;	---------------------------------
; Function TileMap_FillTileDefinition
; ---------------------------------
_TileMap_FillTileDefinition_start::
_TileMap_FillTileDefinition:
	push	ix
	ld	ix,#0
	add	ix,sp
;background.c:48: byte video_page   = tileNumber/0x20;
	ld	c,4 (ix)
	ld	b,5 (ix)
	srl	b
	rr	c
	srl	b
	rr	c
	srl	b
	rr	c
	srl	b
	rr	c
	srl	b
	rr	c
;background.c:49: word video_offset = (tileNumber&0x1F) * 0x100;
	ld	a,4 (ix)
	and	a,#0x1F
	ld	e,a
	ld	d,e
	ld	e,#0x00
;background.c:51: PAGE_IN_VIDEO_RAM();
	in	a,(_io__sys_mem_select)
	or	a,#0x40
	out	(_io__sys_mem_select),a
;background.c:52: SET_VIDEO_PAGE(video_page);
	ld	hl,#_mm__vreg_vidpage + 0
	ld	(hl), c
;background.c:53: memset((byte*)(VIDEO_BASE) + video_offset, fillValue, 0x100); //fill tile def
	ld	hl,#0x2000
	add	hl,de
	ld	c,l
	ld	b,h
	ld	hl,#0x0100
	push	hl
	ld	a,6 (ix)
	push	af
	inc	sp
	push	bc
	call	_memset
	pop	af
	pop	af
	inc	sp
;background.c:54: PAGE_OUT_VIDEO_RAM();
	in	a,(_io__sys_mem_select)
	ld	c,a
	and	a,#0xBF
	out	(_io__sys_mem_select),a
	pop	ix
	ret
_TileMap_FillTileDefinition_end::
;background.c:58: void TileMap_Clear(void)
;	---------------------------------
; Function TileMap_Clear
; ---------------------------------
_TileMap_Clear_start::
_TileMap_Clear:
;background.c:66: TileMap_FillTileDefinition(2047, 0);
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x07FF
	push	hl
	call	_TileMap_FillTileDefinition
	pop	af
	inc	sp
;background.c:67: TileMap_Fill(2047);
	ld	hl,#0x07FF
	push	hl
	call	_TileMap_Fill
	pop	af
	ret
_TileMap_Clear_end::
;background.c:73: void TileMap_Fill(word tileNumber)
;	---------------------------------
; Function TileMap_Fill
; ---------------------------------
_TileMap_Fill_start::
_TileMap_Fill:
	push	ix
	ld	ix,#0
	add	ix,sp
;background.c:75: PAGE_IN_VIDEO_RAM();
	in	a,(_io__sys_mem_select)
	or	a,#0x40
	out	(_io__sys_mem_select),a
;background.c:76: SET_VIDEO_PAGE(TILEMAPS_VIDEO_PAGE);
	ld	hl,#_mm__vreg_vidpage + 0
	ld	(hl), #0x38
;background.c:77: memset((byte*)(VIDEO_BASE),         (byte)tileNumber,           0x200); //LSB
	ld	c,4 (ix)
	ld	hl,#0x0200
	push	hl
	ld	a,c
	push	af
	inc	sp
	ld	h, #0x20
	push	hl
	call	_memset
	pop	af
	pop	af
	inc	sp
;background.c:78: memset((byte*)(VIDEO_BASE+0x800),   (byte)(tileNumber >> 8),    0x200); //MSB
	ld	c,5 (ix)
	ld	hl,#0x0200
	push	hl
	ld	a,c
	push	af
	inc	sp
	ld	h, #0x28
	push	hl
	call	_memset
	pop	af
	pop	af
	inc	sp
;background.c:79: PAGE_OUT_VIDEO_RAM();
	in	a,(_io__sys_mem_select)
	ld	c,a
	and	a,#0xBF
	out	(_io__sys_mem_select),a
	pop	ix
	ret
_TileMap_Fill_end::
;background.c:85: void Background_InitTilemap(word firstTileDef)
;	---------------------------------
; Function Background_InitTilemap
; ---------------------------------
_Background_InitTilemap_start::
_Background_InitTilemap:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-8
	add	hl,sp
	ld	sp,hl
;background.c:91: PAGE_IN_VIDEO_RAM();
	in	a,(_io__sys_mem_select)
	or	a,#0x40
	out	(_io__sys_mem_select),a
;background.c:92: SET_VIDEO_PAGE(TILEMAPS_VIDEO_PAGE);
	ld	iy,#_mm__vreg_vidpage
	ld	0 (iy),#0x38
;background.c:94: for(y=0; y<240/16; y++)
	ld	-2 (ix),#0x00
	ld	-8 (ix),#0x00
	ld	-7 (ix),#0x00
00105$:
	ld	a,-2 (ix)
	sub	a,#0x0F
	jp	NC,00108$
;background.c:95: for(x=0; x<368/16; x++) {
	ld	a,4 (ix)
	add	a,-8 (ix)
	ld	-6 (ix),a
	ld	a,5 (ix)
	adc	a,-7 (ix)
	ld	-5 (ix),a
	ld	-1 (ix),#0x00
00101$:
	ld	a,-1 (ix)
	sub	a,#0x17
	jp	NC,00107$
;background.c:96: tile_num = firstTileDef + (y*(368/16)) + x;
	ld	c,-1 (ix)
	ld	b,#0x00
	ld	a,-6 (ix)
	add	a,c
	ld	e,a
	ld	a,-5 (ix)
	adc	a,b
	ld	d,a
	ld	-4 (ix),e
	ld	-3 (ix),d
;background.c:97: p = (byte*)(VIDEO_BASE + (y*TILE_MAP_WIDTH_IN_BLOCKS) + x);
	ld	e,-2 (ix)
	ld	d,#0x00
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	ld	hl,#0x2000
	add	hl,de
	ex	de,hl
	ld	a,e
	add	a,c
	ld	c,a
	ld	a,d
	adc	a,b
	ld	b,a
;background.c:99: p++;
	inc	bc
;background.c:101: *p         = tile_num & 0xFF;
	ld	a,-4 (ix)
	ld	(bc),a
;background.c:102: *(p+0x800) = tile_num >> 8;
	ld	hl,#0x0800
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	e,-3 (ix)
	ld	d,#0x00
	ld	a,e
	ld	(bc),a
;background.c:95: for(x=0; x<368/16; x++) {
	inc	-1 (ix)
	jp	00101$
00107$:
;background.c:94: for(y=0; y<240/16; y++)
	ld	a,-8 (ix)
	add	a,#0x17
	ld	-8 (ix),a
	ld	a,-7 (ix)
	adc	a,#0x00
	ld	-7 (ix),a
	inc	-2 (ix)
	jp	00105$
00108$:
;background.c:105: PAGE_OUT_VIDEO_RAM();
	in	a,(_io__sys_mem_select)
	ld	c,a
	and	a,#0xBF
	out	(_io__sys_mem_select),a
	ld	sp,ix
	pop	ix
	ret
_Background_InitTilemap_end::
;keyboard.c:38: void Input_ClearPlayersInput(void)
;	---------------------------------
; Function Input_ClearPlayersInput
; ---------------------------------
_Input_ClearPlayersInput_start::
_Input_ClearPlayersInput:
;keyboard.c:40: player1_input.up = player1_input.down = player1_input.fire1 = FALSE;
	ld	bc,#_player1_input + 1
	ld	de,#_player1_input + 2
	ld	a,#0x00
	ld	(de),a
	ld	(bc),a
	ld	hl,#_player1_input
	ld	(hl),#0x00
;keyboard.c:41: player2_input.up = player2_input.down = player2_input.fire1 = FALSE;
	ld	bc,#_player2_input + 1
	ld	de,#_player2_input + 2
	ld	a,#0x00
	ld	(de),a
	ld	(bc),a
	ld	hl,#_player2_input
	ld	(hl),#0x00
	ret
_Input_ClearPlayersInput_end::
;keyboard.c:44: void Keyboard_Init(void)
;	---------------------------------
; Function Keyboard_Init
; ---------------------------------
_Keyboard_Init_start::
_Keyboard_Init:
;keyboard.c:46: DI();
		di 
;keyboard.c:47: keyboard.is_looking_for_second_byte_of_scancode = FALSE;
	ld	hl,#_keyboard
	ld	(hl),#0x00
;keyboard.c:48: keyboard.prev_pressed_scancode = 0;
	ld	bc,#_keyboard + 2
	ld	a,#0x00
	ld	(bc),a
;keyboard.c:49: EI();
		ei 
	ret
_Keyboard_Init_end::
;keyboard.c:52: byte Keyboard_GetLastPressedScancode(void)
;	---------------------------------
; Function Keyboard_GetLastPressedScancode
; ---------------------------------
_Keyboard_GetLastPressedScancode_start::
_Keyboard_GetLastPressedScancode:
;keyboard.c:54: return keyboard.prev_pressed_scancode;
	ld	hl,#_keyboard + 2
	ld	l,(hl)
	ret
_Keyboard_GetLastPressedScancode_end::
;keyboard.c:57: void Keyboard_IRQ_Handler()
;	---------------------------------
; Function Keyboard_IRQ_Handler
; ---------------------------------
_Keyboard_IRQ_Handler_start::
_Keyboard_IRQ_Handler:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-14
	add	hl,sp
	ld	sp,hl
;keyboard.c:63: scancode = io__sys_keyboard_data;
	in	a,(_io__sys_keyboard_data)
;keyboard.c:65: if(scancode == 0xF0) {
	ld	-1 (ix),a
	sub	a,#0xF0
	jr	NZ,00102$
;keyboard.c:66: keyboard.is_looking_for_second_byte_of_scancode = TRUE;
	ld	hl,#_keyboard
	ld	(hl),#0x01
;keyboard.c:68: return;
	jp	00129$
00102$:
;keyboard.c:71: if(keyboard.is_looking_for_second_byte_of_scancode) {
	ld	hl,#_keyboard
	ld	a,(hl)
	or	a,a
	jp	Z,00108$
;keyboard.c:72: keyboard.is_looking_for_second_byte_of_scancode = FALSE;
	ld	(hl),#0x00
;keyboard.c:74: table = keyboard_input_map;
	ld	c,#<_keyboard_input_map
	ld	d,#>_keyboard_input_map
;keyboard.c:75: for(i=0; i<sizeof(keyboard_input_map)/sizeof(keyboard_input_map[0]); i++) {
	ld	b,c
	ld	e,d
	ld	-2 (ix),#0x07
00125$:
;keyboard.c:76: if(scancode == table->scancode)
	ld	l,b
	ld	h,e
	ld	d,(hl)
	ld	a,-1 (ix)
	sub	d
	jr	NZ,00104$
;keyboard.c:77: *(table->pVar) = FALSE;
	ld	a,b
	add	a,#0x01
	ld	l,a
	ld	a,e
	adc	a,#0x00
	ld	h,a
	ld	d,(hl)
	inc	hl
	ld	c,(hl)
	ld	l,d
	ld	h,c
	ld	(hl),#0x00
00104$:
;keyboard.c:78: table++;
	ld	a,b
	add	a,#0x03
	ld	b,a
	ld	a,e
	adc	a,#0x00
	ld	e,a
	dec	-2 (ix)
;keyboard.c:75: for(i=0; i<sizeof(keyboard_input_map)/sizeof(keyboard_input_map[0]); i++) {
	xor	a,a
	or	a,-2 (ix)
	jr	NZ,00125$
;keyboard.c:81: if(scancode == keyboard.prev_pressed_scancode)
	ld	hl,#_keyboard + 2
	ld	c,(hl)
	ld	a,-1 (ix)
	sub	c
	jr	NZ,00106$
;keyboard.c:82: keyboard.last_typed_scancode = scancode;
	ld	bc,#_keyboard + 1
	ld	a,-1 (ix)
	ld	(bc),a
00106$:
;keyboard.c:84: return;
	jp	00129$
00108$:
;keyboard.c:88: table = keyboard_input_map;
	ld	c,#<_keyboard_input_map
	ld	d,#>_keyboard_input_map
;keyboard.c:89: for(i=0; i<sizeof(keyboard_input_map)/sizeof(keyboard_input_map[0]); i++) {
	ld	hl,#_player1_input + 1
	ld	-14 (ix),l
	ld	-13 (ix),h
	inc	hl
	ld	-12 (ix),l
	ld	-11 (ix),h
	ld	hl,#_player2_input + 1
	ld	-4 (ix),l
	ld	-3 (ix),h
	inc	hl
	ld	-6 (ix),l
	ld	-5 (ix),h
	ld	hl,#_game + 3
	ld	-8 (ix),l
	ld	-7 (ix),h
	ld	-10 (ix),c
	ld	-9 (ix),d
	ld	-2 (ix),#0x07
00128$:
;keyboard.c:90: if(scancode == table->scancode) {
	ld	l,-10 (ix)
	ld	h,-9 (ix)
	ld	d,(hl)
	ld	a,-1 (ix)
	sub	d
	jp	NZ,00120$
;keyboard.c:91: *(table->pVar) = TRUE;
	ld	e,-10 (ix)
	ld	d,-9 (ix)
	ex	de,hl
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,#0x01
	ld	(de),a
;keyboard.c:97: if(table->pVar == &player1_input.up || table->pVar == &player1_input.down ||
	push	bc
;	direct compare
	ld	c,e
	ld	a,#<_player1_input
	sub	c
	jr	NZ,00156$
;	direct compare
	ld	c,d
	ld	a,#>_player1_input
	sub	c
	jr	NZ,00156$
	pop	bc
	jr	00109$
00156$:
	pop	bc
	ld	a,e
	sub	-14 (ix)
	jr	NZ,00157$
	ld	a,d
	sub	-13 (ix)
	jr	Z,00109$
00157$:
;keyboard.c:98: table->pVar == &player1_input.fire1)
	ld	a,e
	sub	-12 (ix)
	jr	NZ,00158$
	ld	a,d
	sub	-11 (ix)
	jr	Z,00159$
00158$:
	jr	00110$
00159$:
00109$:
;keyboard.c:99: player1_input.input_type = KEYBOARD;
	ld	bc,#_player1_input + 3
	ld	a,#0x00
	ld	(bc),a
00110$:
;keyboard.c:101: if(!game.is_one_player_mode)
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	a,(hl)
	or	a,a
	jr	NZ,00120$
;keyboard.c:102: if(table->pVar == &player2_input.up || table->pVar == &player2_input.down ||
	push	bc
;	direct compare
	ld	c,e
	ld	a,#<_player2_input
	sub	c
	jr	NZ,00160$
;	direct compare
	ld	c,d
	ld	a,#>_player2_input
	sub	c
	jr	NZ,00160$
	pop	bc
	jr	00113$
00160$:
	pop	bc
	ld	a,e
	sub	-4 (ix)
	jr	NZ,00161$
	ld	a,d
	sub	-3 (ix)
	jr	Z,00113$
00161$:
;keyboard.c:103: table->pVar == &player2_input.fire1)
	ld	a,e
	sub	-6 (ix)
	jr	NZ,00162$
	ld	a,d
	sub	-5 (ix)
	jr	Z,00163$
00162$:
	jr	00120$
00163$:
00113$:
;keyboard.c:104: player2_input.input_type = KEYBOARD;
	ld	a,#0x00
	ld	(#_player2_input + 3),a
00120$:
;keyboard.c:107: table++;
	ld	a,-10 (ix)
	add	a,#0x03
	ld	-10 (ix),a
	ld	a,-9 (ix)
	adc	a,#0x00
	ld	-9 (ix),a
;keyboard.c:108: keyboard.prev_pressed_scancode = scancode;   // remember last pressed scancode
	ld	bc,#_keyboard + 2
	ld	a,-1 (ix)
	ld	(bc),a
	dec	-2 (ix)
;keyboard.c:89: for(i=0; i<sizeof(keyboard_input_map)/sizeof(keyboard_input_map[0]); i++) {
	xor	a,a
	or	a,-2 (ix)
	jp	NZ,00128$
;keyboard.c:112: if(scancode == SC_ESC)
	ld	a,-1 (ix)
	sub	a,#0x76
	jr	NZ,00129$
;keyboard.c:113: request_exit = TRUE;
	ld	hl,#_request_exit + 0
	ld	(hl), #0x01
00129$:
	ld	sp,ix
	pop	ix
	ret
_Keyboard_IRQ_Handler_end::
;keyboard.c:120: void irq_handler() NAKED
;	---------------------------------
; Function irq_handler
; ---------------------------------
_irq_handler_start::
_irq_handler:
;keyboard.c:135: ENDASM()
;
		   push af push bc push de push hl exx push af push bc push de push hl exx push ix push iy
	
		   in a,(0x01) ; Read irq status flags
		   bit 0,a ; keyboard irq set?
		   call nz,_Keyboard_IRQ_Handler ; call keyboard irq routine if so
	
		   ld a,#0x01
		   out (0x02),a ; clear keyboard interrupt flag
	
		   pop iy pop ix exx pop hl pop de pop bc pop af exx pop hl pop de pop bc pop af
		   ei
		   reti
		   
;keyboard.c:139: void install_irq_handler(void)
;	---------------------------------
; Function install_irq_handler
; ---------------------------------
_install_irq_handler_start::
_install_irq_handler:
;keyboard.c:141: DI();
		di 
;keyboard.c:142: *((word*)IRQ_VECTOR) = (word)&irq_handler;
	ld	iy,#0x0A01
	ld	c,#<_irq_handler
	ld	b,#>_irq_handler
	ld	0 (iy),c
	ld	1 (iy),b
;keyboard.c:143: io__sys_irq_enable = 0x81;      // enable: master irq, keyb
	ld	a,#0x81
	out	(_io__sys_irq_enable),a
;keyboard.c:144: EI();
		ei 
	ret
_install_irq_handler_end::
;joystick.c:10: void Joystick_SelectJoystickPort(byte portNumber)
;	---------------------------------
; Function Joystick_SelectJoystickPort
; ---------------------------------
_Joystick_SelectJoystickPort_start::
_Joystick_SelectJoystickPort:
	push	ix
	ld	ix,#0
	add	ix,sp
;joystick.c:12: io__sys_ps2_joy_control = portNumber & 1;
	ld	a,4 (ix)
	and	a,#0x01
	out	(_io__sys_ps2_joy_control),a
	pop	ix
	ret
_Joystick_SelectJoystickPort_end::
;joystick.c:15: void Joystick_GetInput(void)
;	---------------------------------
; Function Joystick_GetInput
; ---------------------------------
_Joystick_GetInput_start::
_Joystick_GetInput:
;joystick.c:19: Joystick_CheckInputAutoSwith();
	call	_Joystick_CheckInputAutoSwith
;joystick.c:21: if(player1_input.input_type == JOY)
	ld	bc,#_player1_input + 3
	ld	a,(bc)
	sub	a,#0x01
	jr	NZ,00102$
;joystick.c:22: Joystick_GetInputForPlayer(0);
	ld	a,#0x00
	push	af
	inc	sp
	call	_Joystick_GetInputForPlayer
	inc	sp
00102$:
;joystick.c:24: if(Joystick_IsSecondJoyNeedToBeReaded())
	call	_Joystick_IsSecondJoyNeedToBeReaded
	xor	a,a
	or	a,l
	ret	Z
;joystick.c:25: if(player2_input.input_type == JOY)
	ld	bc,#_player2_input + 3
	ld	a,(bc)
	sub	a,#0x01
	jr	Z,00115$
	ret
00115$:
;joystick.c:26: Joystick_GetInputForPlayer(1);
	ld	a,#0x01
	push	af
	inc	sp
	call	_Joystick_GetInputForPlayer
	inc	sp
	ret
_Joystick_GetInput_end::
;joystick.c:33: void Joystick_GetInputForPlayer(byte playerNumber)
;	---------------------------------
; Function Joystick_GetInputForPlayer
; ---------------------------------
_Joystick_GetInputForPlayer_start::
_Joystick_GetInputForPlayer:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;joystick.c:38: Joystick_SelectJoystickPort(playerNumber);
	ld	a,4 (ix)
	push	af
	inc	sp
	call	_Joystick_SelectJoystickPort
	inc	sp
;joystick.c:39: v = io__sys_joy_com_flags;
	in	a,(_io__sys_joy_com_flags)
	ld	-1 (ix),a
;joystick.c:41: pPI = (playerNumber == 0) ? &player1_input : &player2_input;
	xor	a,a
	or	a,4 (ix)
	sub	a,#0x01
	ld	a,#0x00
	rla
	or	a,a
	jr	Z,00103$
	ld	hl,#_player1_input
	ex	de,hl
	jr	00104$
00103$:
	ld	hl,#_player2_input
	ex	de,hl
00104$:
;joystick.c:42: pPI->up    = (v & JOY_UP_MASK) ? TRUE : FALSE;
	ld	c,e
	ld	b,d
	ld	a,-1 (ix)
	and	a,#0x01
	jr	Z,00105$
	ld	-2 (ix),#0x01
	jr	00106$
00105$:
	ld	-2 (ix),#0x00
00106$:
	ld	a,-2 (ix)
	ld	(bc),a
;joystick.c:43: pPI->down  = (v & JOY_DOWN_MASK) ? TRUE : FALSE;
	ld	c,e
	ld	b,d
	inc	bc
	ld	a,-1 (ix)
	and	a,#0x02
	jr	Z,00107$
	ld	-2 (ix),#0x01
	jr	00108$
00107$:
	ld	-2 (ix),#0x00
00108$:
	ld	a,-2 (ix)
	ld	(bc),a
;joystick.c:44: pPI->fire1 = (v & JOY_FIRE1_MASK) ? TRUE : FALSE;
	ld	c,e
	ld	b,d
	inc	bc
	inc	bc
	ld	a,-1 (ix)
	and	a,#0x10
	jr	Z,00109$
	ld	e,#0x01
	jr	00110$
00109$:
	ld	e,#0x00
00110$:
	ld	a,e
	ld	(bc),a
	ld	sp,ix
	pop	ix
	ret
_Joystick_GetInputForPlayer_end::
;joystick.c:50: void Joystick_CheckInputAutoSwith(void)
;	---------------------------------
; Function Joystick_CheckInputAutoSwith
; ---------------------------------
_Joystick_CheckInputAutoSwith_start::
_Joystick_CheckInputAutoSwith:
;joystick.c:52: Joystick_CheckInputAutoSwithForPlayer(0);
	ld	a,#0x00
	push	af
	inc	sp
	call	_Joystick_CheckInputAutoSwithForPlayer
	inc	sp
;joystick.c:54: if(Joystick_IsSecondJoyNeedToBeReaded()) {
	call	_Joystick_IsSecondJoyNeedToBeReaded
	xor	a,a
	or	a,l
	ret	Z
;joystick.c:55: Joystick_CheckInputAutoSwithForPlayer(1);
	ld	a,#0x01
	push	af
	inc	sp
	call	_Joystick_CheckInputAutoSwithForPlayer
	inc	sp
	ret
_Joystick_CheckInputAutoSwith_end::
;joystick.c:60: void Joystick_CheckInputAutoSwithForPlayer(byte playerNumber)
;	---------------------------------
; Function Joystick_CheckInputAutoSwithForPlayer
; ---------------------------------
_Joystick_CheckInputAutoSwithForPlayer_start::
_Joystick_CheckInputAutoSwithForPlayer:
	push	ix
	ld	ix,#0
	add	ix,sp
;joystick.c:64: pPI = (playerNumber == 0) ? &player1_input : &player2_input;
	xor	a,a
	or	a,4 (ix)
	sub	a,#0x01
	ld	a,#0x00
	rla
	or	a,a
	jr	Z,00107$
	ld	hl,#_player1_input
	ld	c,l
	ld	b,h
	jr	00108$
00107$:
	ld	hl,#_player2_input
	ld	c,l
	ld	b,h
00108$:
;joystick.c:66: Joystick_SelectJoystickPort(playerNumber);
	push	bc
	ld	a,4 (ix)
	push	af
	inc	sp
	call	_Joystick_SelectJoystickPort
	inc	sp
	pop	bc
;joystick.c:67: v = io__sys_joy_com_flags;
	in	a,(_io__sys_joy_com_flags)
;joystick.c:68: if(v & JOY_UP_MASK || v & JOY_DOWN_MASK || v & JOY_FIRE1_MASK)
	ld	e,a
	and	a,#0x01
	jr	NZ,00101$
	ld	a,e
	and	a,#0x02
	jr	NZ,00101$
	ld	a,e
	and	a,#0x10
	jr	Z,00105$
00101$:
;joystick.c:69: pPI->input_type = JOY;
	inc	bc
	inc	bc
	inc	bc
	ld	a,#0x01
	ld	(bc),a
00105$:
	pop	ix
	ret
_Joystick_CheckInputAutoSwithForPlayer_end::
;joystick.c:73: BOOL Joystick_IsSecondJoyNeedToBeReaded(void)
;	---------------------------------
; Function Joystick_IsSecondJoyNeedToBeReaded
; ---------------------------------
_Joystick_IsSecondJoyNeedToBeReaded_start::
_Joystick_IsSecondJoyNeedToBeReaded:
;joystick.c:75: return (!game.is_one_player_mode || game.game_state == MENU || game.game_state == CREDITS);
	ld	hl,#_game + 3
	ld	c,(hl)
	xor	a,a
	or	a,c
	sub	a,#0x01
	ld	a,#0x00
	rla
	or	a,a
	jr	NZ,00107$
	ld	hl,#_game
	ld	a,(hl)
	sub	a,#0x01
	jr	Z,00107$
	ld	c,#0x00
	jr	00108$
00107$:
	ld	c,#0x01
00108$:
	xor	a,a
	or	a,c
	jr	NZ,00104$
	ld	hl,#_game
	ld	a,(hl)
	sub	a,#0x02
	jr	Z,00104$
	ld	c,#0x00
	jr	00105$
00104$:
	ld	c,#0x01
00105$:
	ld	l,c
	ret
_Joystick_IsSecondJoyNeedToBeReaded_end::
;pool_sprites.c:22: void PoolSprites_Init(void)
;	---------------------------------
; Function PoolSprites_Init
; ---------------------------------
_PoolSprites_Init_start::
_PoolSprites_Init:
;pool_sprites.c:24: memset(&pool_sprites, 0, sizeof(pool_sprites));
	ld	hl,#0x0001
	push	hl
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#_pool_sprites
	push	hl
	call	_memset
	pop	af
	pop	af
	inc	sp
;pool_sprites.c:25: PoolSprites_FreeAllSprites();
	jp	_PoolSprites_FreeAllSprites
_PoolSprites_Init_end::
;pool_sprites.c:30: byte PoolSprites_AllocateSpriteNumber(byte count)
;	---------------------------------
; Function PoolSprites_AllocateSpriteNumber
; ---------------------------------
_PoolSprites_AllocateSpriteNumber_start::
_PoolSprites_AllocateSpriteNumber:
	push	ix
	ld	ix,#0
	add	ix,sp
	dec	sp
;pool_sprites.c:33: byte* pNumBuffer = allocatedSpriteNumbers;
;pool_sprites.c:36: for(i=0; i<count; i++) {
	ld	c,#0x00
	ld	-1 (ix),#0x00
00103$:
	ld	a,-1 (ix)
	sub	a,4 (ix)
	jr	NC,00106$
;pool_sprites.c:37: if(pool_sprites.spr_number_offset >= POOL_SPR__LAST_SPRITE)
	ld	hl,#_pool_sprites
	ld	e,(hl)
	ld	a,e
	sub	a,#0x31
	jr	C,00102$
;pool_sprites.c:38: return i;
	ld	l,c
	jr	00107$
00102$:
;pool_sprites.c:39: *(pNumBuffer+i) = pool_sprites.spr_number_offset;
	ld	a,#<_allocatedSpriteNumbers
	add	a,-1 (ix)
	ld	l,a
	ld	a,#>_allocatedSpriteNumbers
	adc	a,#0x00
	ld	h,a
	ld	(hl),e
;pool_sprites.c:40: pool_sprites.spr_number_offset++;
	ld	hl,#_pool_sprites
	ld	a,(hl)
	inc	a
	ld	(hl),a
;pool_sprites.c:36: for(i=0; i<count; i++) {
	inc	-1 (ix)
	ld	c,-1 (ix)
	jr	00103$
00106$:
;pool_sprites.c:45: return i;
	ld	l,c
00107$:
	ld	sp,ix
	pop	ix
	ret
_PoolSprites_AllocateSpriteNumber_end::
;pool_sprites.c:48: void PoolSprites_FreeAllSprites(void)
;	---------------------------------
; Function PoolSprites_FreeAllSprites
; ---------------------------------
_PoolSprites_FreeAllSprites_start::
_PoolSprites_FreeAllSprites:
;pool_sprites.c:50: pool_sprites.spr_number_offset = POOL_SPR__FIRST_SPRITE;
	ld	hl,#_pool_sprites
	ld	(hl),#0x0E
	ret
_PoolSprites_FreeAllSprites_end::
;pool_gameobj.c:30: void PoolGameObj_Init(void)
;	---------------------------------
; Function PoolGameObj_Init
; ---------------------------------
_PoolGameObj_Init_start::
_PoolGameObj_Init:
;pool_gameobj.c:32: memset(&pool_game_obj, 0, sizeof(pool_game_obj));
	ld	hl,#0x02B5
	push	hl
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#_pool_game_obj
	push	hl
	call	_memset
	pop	af
	pop	af
	inc	sp
	ret
_PoolGameObj_Init_end::
;pool_gameobj.c:36: GameObjAnim* PoolGameObj_AllocateGameObjAnim(void)
;	---------------------------------
; Function PoolGameObj_AllocateGameObjAnim
; ---------------------------------
_PoolGameObj_AllocateGameObjAnim_start::
_PoolGameObj_AllocateGameObjAnim:
;pool_gameobj.c:39: return (GameObjAnim*) PoolGameObj_AllocateGameObj((GameObj*)pool_game_obj.pool_GameObjAnim,
	ld	a,#0x25
	push	af
	inc	sp
	ld	hl,#0x000F
	push	hl
	ld	hl,#_pool_game_obj
	push	hl
	call	_PoolGameObj_AllocateGameObj
	pop	af
	pop	af
	inc	sp
	ret
_PoolGameObj_AllocateGameObjAnim_end::
;pool_gameobj.c:43: GameObjRocket* PoolGameObj_AllocateGameObjRocket(void)
;	---------------------------------
; Function PoolGameObj_AllocateGameObjRocket
; ---------------------------------
_PoolGameObj_AllocateGameObjRocket_start::
_PoolGameObj_AllocateGameObjRocket:
;pool_gameobj.c:45: return (GameObjRocket*) PoolGameObj_AllocateGameObj((GameObj*)pool_game_obj.pool_GameObjRocket,
	ld	bc,#_pool_game_obj + 555
	ld	a,#0x24
	push	af
	inc	sp
	ld	hl,#0x0002
	push	hl
	push	bc
	call	_PoolGameObj_AllocateGameObj
	pop	af
	pop	af
	inc	sp
	ret
_PoolGameObj_AllocateGameObjRocket_end::
;pool_gameobj.c:53: void PoolGameObj_FreeGameObj(GameObj* gameObj)
;	---------------------------------
; Function PoolGameObj_FreeGameObj
; ---------------------------------
_PoolGameObj_FreeGameObj_start::
_PoolGameObj_FreeGameObj:
	push	ix
	ld	ix,#0
	add	ix,sp
;pool_gameobj.c:55: PoolGameObj_RemoveObjFromActiveObjects(gameObj);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_PoolGameObj_RemoveObjFromActiveObjects
	pop	af
;pool_gameobj.c:56: gameObj->in_use = FALSE;
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	pop	iy
	ld	(iy),#0x00
	pop	ix
	ret
_PoolGameObj_FreeGameObj_end::
;pool_gameobj.c:62: GameObj* PoolGameObj_AllocateGameObj(GameObj* pPool, word poolSize, byte objSize)
;	---------------------------------
; Function PoolGameObj_AllocateGameObj
; ---------------------------------
_PoolGameObj_AllocateGameObj_start::
_PoolGameObj_AllocateGameObj:
	push	ix
	ld	ix,#0
	add	ix,sp
;pool_gameobj.c:67: for(i=0; i<poolSize; i++) {
	ld	bc,#0x0000
00103$:
	ld	a,c
	sub	a,6 (ix)
	ld	a,b
	sbc	a,7 (ix)
	jr	NC,00106$
;pool_gameobj.c:68: gameObj = pPool;
	ld	e,4 (ix)
	ld	d,5 (ix)
;pool_gameobj.c:69: if(!gameObj->in_use) {
	ld	a,(de)
	or	a,a
	jr	NZ,00102$
;pool_gameobj.c:70: gameObj->in_use = TRUE;
	ld	a,#0x01
	ld	(de),a
;pool_gameobj.c:71: PoolGameObj_AddObjToActiveObjects(gameObj);
	push	de
	push	de
	call	_PoolGameObj_AddObjToActiveObjects
	pop	af
;pool_gameobj.c:72: return gameObj;
	pop	hl
	jr	00107$
00102$:
;pool_gameobj.c:74: pPool = (GameObj*) ( ((byte*)pPool) + objSize );     // move ptr to next obj in pool
	ld	a,e
	add	a,8 (ix)
	ld	e,a
	ld	a,d
	adc	a,#0x00
	ld	d,a
	ld	4 (ix),e
	ld	5 (ix),d
;pool_gameobj.c:67: for(i=0; i<poolSize; i++) {
	inc	bc
	jr	00103$
00106$:
;pool_gameobj.c:76: return NULL;
	ld	hl,#0x0000
00107$:
	pop	ix
	ret
_PoolGameObj_AllocateGameObj_end::
;pool_gameobj.c:81: BOOL PoolGameObj_AddObjToActiveObjects(GameObj* obj)
;	---------------------------------
; Function PoolGameObj_AddObjToActiveObjects
; ---------------------------------
_PoolGameObj_AddObjToActiveObjects_start::
_PoolGameObj_AddObjToActiveObjects:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;pool_gameobj.c:85: for(p = pool_game_obj.active_objects;
	ld	bc,#_pool_game_obj + 629
	ld	e,c
	ld	d,b
	ld	-2 (ix),e
	ld	-1 (ix),d
	ld	hl,#0x0040
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,-2 (ix)
	ld	-4 (ix),a
	ld	a,-1 (ix)
	ld	-3 (ix),a
00103$:
;pool_gameobj.c:86: p < pool_game_obj.active_objects + (sizeof(pool_game_obj.active_objects) / sizeof(p));
	ld	a,-4 (ix)
	sub	a,c
	ld	a,-3 (ix)
	sbc	a,b
	jp	P,00106$
;pool_gameobj.c:88: if(*p == NULL) {
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,e
	or	a,d
	jr	NZ,00105$
;pool_gameobj.c:89: *p = obj;
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,4 (ix)
	ld	(hl),a
	inc	hl
	ld	a,5 (ix)
	ld	(hl),a
;pool_gameobj.c:90: return TRUE;
	ld	l,#0x01
	jr	00107$
00105$:
;pool_gameobj.c:87: p++)
	ld	a,-4 (ix)
	add	a,#0x02
	ld	-4 (ix),a
	ld	a,-3 (ix)
	adc	a,#0x00
	ld	-3 (ix),a
	ld	a,-4 (ix)
	ld	-2 (ix),a
	ld	a,-3 (ix)
	ld	-1 (ix),a
	jr	00103$
00106$:
;pool_gameobj.c:93: return FALSE;
	ld	l,#0x00
00107$:
	ld	sp,ix
	pop	ix
	ret
_PoolGameObj_AddObjToActiveObjects_end::
;pool_gameobj.c:98: BOOL PoolGameObj_RemoveObjFromActiveObjects(GameObj* obj)
;	---------------------------------
; Function PoolGameObj_RemoveObjFromActiveObjects
; ---------------------------------
_PoolGameObj_RemoveObjFromActiveObjects_start::
_PoolGameObj_RemoveObjFromActiveObjects:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;pool_gameobj.c:102: for(p = pool_game_obj.active_objects;
	ld	bc,#_pool_game_obj + 629
	ld	e,c
	ld	d,b
	ld	-2 (ix),e
	ld	-1 (ix),d
	ld	hl,#0x0040
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,-2 (ix)
	ld	-4 (ix),a
	ld	a,-1 (ix)
	ld	-3 (ix),a
00103$:
;pool_gameobj.c:103: p < pool_game_obj.active_objects + (sizeof(pool_game_obj.active_objects) / sizeof(p));
	ld	a,-4 (ix)
	sub	a,c
	ld	a,-3 (ix)
	sbc	a,b
	jp	P,00106$
;pool_gameobj.c:105: if(*p == obj) {
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,e
	sub	4 (ix)
	jr	NZ,00112$
	ld	a,d
	sub	5 (ix)
	jr	Z,00113$
00112$:
	jr	00105$
00113$:
;pool_gameobj.c:106: *p = NULL;
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;pool_gameobj.c:107: return TRUE;
	ld	l,#0x01
	jr	00107$
00105$:
;pool_gameobj.c:104: p++)
	ld	a,-4 (ix)
	add	a,#0x02
	ld	-4 (ix),a
	ld	a,-3 (ix)
	adc	a,#0x00
	ld	-3 (ix),a
	ld	a,-4 (ix)
	ld	-2 (ix),a
	ld	a,-3 (ix)
	ld	-1 (ix),a
	jr	00103$
00106$:
;pool_gameobj.c:110: return FALSE;
	ld	l,#0x00
00107$:
	ld	sp,ix
	pop	ix
	ret
_PoolGameObj_RemoveObjFromActiveObjects_end::
;pool_gameobj.c:121: void PoolGameObj_ApplyFuncMoveToObjects()
;	---------------------------------
; Function PoolGameObj_ApplyFuncMoveToObjects
; ---------------------------------
_PoolGameObj_ApplyFuncMoveToObjects_start::
_PoolGameObj_ApplyFuncMoveToObjects:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;pool_gameobj.c:127: APPLY_FUNC_TO_ACTIVE_OBJECTS(pMoveFunc);
	ld	bc,#_pool_game_obj + 629
	ld	-2 (ix),#0x00
	ld	-1 (ix),#0x00
00103$:
	ld	a,-2 (ix)
	sub	a,#0x20
	ld	a,-1 (ix)
	sbc	a,#0x00
	jp	NC,00107$
	ld	e,-2 (ix)
	ld	d,-1 (ix)
	sla	e
	rl	d
	ld	a,c
	add	a,e
	ld	e,a
	ld	a,b
	adc	a,d
	ld	l,e
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-4 (ix),e
	ld	-3 (ix),d
	ld	a,-4 (ix)
	or	a,-3 (ix)
	jr	Z,00105$
	ld	a,-4 (ix)
	add	a,#0x13
	ld	l, a
	ld	a, -3 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	bc
	push	de
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	ex	de,hl
	ld	de,#00115$
	push	de
	jp	(hl)
00115$:
	pop	af
	pop	de
	pop	bc
00105$:
	inc	-2 (ix)
	jr	NZ,00116$
	inc	-1 (ix)
00116$:
	jp	00103$
00107$:
	ld	sp,ix
	pop	ix
	ret
_PoolGameObj_ApplyFuncMoveToObjects_end::
;pool_gameobj.c:130: void PoolGameObj_ApplyFuncDrawToObjects()
;	---------------------------------
; Function PoolGameObj_ApplyFuncDrawToObjects
; ---------------------------------
_PoolGameObj_ApplyFuncDrawToObjects_start::
_PoolGameObj_ApplyFuncDrawToObjects:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;pool_gameobj.c:136: APPLY_FUNC_TO_ACTIVE_OBJECTS(pDrawFunc);
	ld	bc,#_pool_game_obj + 629
	ld	-2 (ix),#0x00
	ld	-1 (ix),#0x00
00103$:
	ld	a,-2 (ix)
	sub	a,#0x20
	ld	a,-1 (ix)
	sbc	a,#0x00
	jp	NC,00107$
	ld	e,-2 (ix)
	ld	d,-1 (ix)
	sla	e
	rl	d
	ld	a,c
	add	a,e
	ld	e,a
	ld	a,b
	adc	a,d
	ld	l,e
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-4 (ix),e
	ld	-3 (ix),d
	ld	a,-4 (ix)
	or	a,-3 (ix)
	jr	Z,00105$
	ld	a,-4 (ix)
	add	a,#0x15
	ld	l, a
	ld	a, -3 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	bc
	push	de
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	ex	de,hl
	ld	de,#00115$
	push	de
	jp	(hl)
00115$:
	pop	af
	pop	de
	pop	bc
00105$:
	inc	-2 (ix)
	jr	NZ,00116$
	inc	-1 (ix)
00116$:
	jp	00103$
00107$:
	ld	sp,ix
	pop	ix
	ret
_PoolGameObj_ApplyFuncDrawToObjects_end::
;obj_.c:1: void GameObj_Init(GameObj* this)
;	---------------------------------
; Function GameObj_Init
; ---------------------------------
_GameObj_Init_start::
_GameObj_Init:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_.c:3: this->extra_field1 = 0;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0011
	add	hl,bc
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	pop	ix
	ret
_GameObj_Init_end::
;obj_.c:6: void GameObj_InitCollideBox(GameObj* this)
;	---------------------------------
; Function GameObj_InitCollideBox
; ---------------------------------
_GameObj_InitCollideBox_start::
_GameObj_InitCollideBox:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-10
	add	hl,sp
	ld	sp,hl
;obj_.c:11: this->col_width  = HW_MATH_MUL(0.8 * 16384, this->width);
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0009
	add	hl,bc
	ld	-6 (ix),l
	ld	-5 (ix),h
	ld	hl,#0x0005
	add	hl,bc
	ld	a,(hl)
	ld	-8 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-7 (ix),a
	ld	e,-8 (ix)
	ld	d,-7 (ix)
;math.c:48: mm__mult_table = n1;
	ld	iy,#_mm__mult_table
	ld	0 (iy),#0x33
	ld	iy,#_mm__mult_table
	ld	1 (iy),#0x33
;math.c:49: mm__mult_index = 0;
	ld	iy,#_mm__mult_index
	ld	0 (iy),#0x00
;math.c:50: mm__mult_write = n2;
	ld	iy,#_mm__mult_write
	ld	0 (iy),e
	ld	iy,#_mm__mult_write
	ld	1 (iy),d
;math.c:52: a = mm__mult_read;
	ld	hl,(_mm__mult_read)
	ld	-2 (ix),l
	ld	-1 (ix),h
;math.c:53: mm__mult_table = 0;     // restore sin table first entry
	ld	hl,#_mm__mult_table + 0
	ld	(hl), #0x00
	ld	hl,#_mm__mult_table + 1
	ld	(hl), #0x00
;obj_.c:11: this->col_width  = HW_MATH_MUL(0.8 * 16384, this->width);
	ld	l,-6 (ix)
	ld	h,-5 (ix)
	ld	a,-2 (ix)
	ld	(hl),a
	inc	hl
	ld	a,-1 (ix)
	ld	(hl),a
;obj_.c:12: this->col_height = HW_MATH_MUL(0.8 * 16384, this->height);
	ld	hl,#0x000B
	add	hl,bc
	ld	-6 (ix),l
	ld	-5 (ix),h
	ld	hl,#0x0007
	add	hl,bc
	ld	a,(hl)
	ld	-10 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-9 (ix),a
	ld	e,-10 (ix)
	ld	d,-9 (ix)
;math.c:48: mm__mult_table = n1;
	ld	iy,#_mm__mult_table
	ld	0 (iy),#0x33
	ld	iy,#_mm__mult_table
	ld	1 (iy),#0x33
;math.c:49: mm__mult_index = 0;
	ld	iy,#_mm__mult_index
	ld	0 (iy),#0x00
;math.c:50: mm__mult_write = n2;
	ld	iy,#_mm__mult_write
	ld	0 (iy),e
	ld	iy,#_mm__mult_write
	ld	1 (iy),d
;math.c:52: a = mm__mult_read;
	ld	hl,(_mm__mult_read)
	ld	-4 (ix),l
	ld	-3 (ix),h
;math.c:53: mm__mult_table = 0;     // restore sin table first entry
	ld	hl,#_mm__mult_table + 0
	ld	(hl), #0x00
	ld	hl,#_mm__mult_table + 1
	ld	(hl), #0x00
;obj_.c:12: this->col_height = HW_MATH_MUL(0.8 * 16384, this->height);
	ld	l,-6 (ix)
	ld	h,-5 (ix)
	ld	a,-4 (ix)
	ld	(hl),a
	inc	hl
	ld	a,-3 (ix)
	ld	(hl),a
;obj_.c:14: this->col_x_offset = (this->width - this->col_width) / 2;
	ld	hl,#0x000D
	add	hl,bc
	ld	-6 (ix),l
	ld	-5 (ix),h
	ld	a,-8 (ix)
	sub	a,-2 (ix)
	ld	e,a
	ld	a,-7 (ix)
	sbc	a,-1 (ix)
	ld	d,a
	srl	d
	rr	e
	ld	l,-6 (ix)
	ld	h,-5 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_.c:15: this->col_y_offset = (this->height - this->col_height) / 2;
	ld	hl,#0x000F
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,-10 (ix)
	sub	a,-4 (ix)
	ld	e,a
	ld	a,-9 (ix)
	sbc	a,-3 (ix)
	ld	d,a
	srl	d
	rr	e
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	sp,ix
	pop	ix
	ret
_GameObj_InitCollideBox_end::
;obj_.c:25: BOOL GameObj_Collide(GameObj* this, GameObj* other)
;	---------------------------------
; Function GameObj_Collide
; ---------------------------------
_GameObj_Collide_start::
_GameObj_Collide:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-18
	add	hl,sp
	ld	sp,hl
;obj_.c:33: left1 = this->x + this->col_x_offset;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	l,c
	ld	h,b
	inc	hl
	ld	a,(hl)
	ld	-14 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-13 (ix),a
	ld	hl,#0x000D
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-14 (ix)
	add	a,e
	ld	e,a
	ld	a,-13 (ix)
	adc	a,d
	ld	d,a
	ld	-2 (ix),e
	ld	-1 (ix),d
;obj_.c:34: left2 = other->x + other->col_x_offset;
	ld	a,6 (ix)
	ld	-14 (ix),a
	ld	a,7 (ix)
	ld	-13 (ix),a
	ld	e,-14 (ix)
	ld	d,-13 (ix)
	ex	de,hl
	inc	hl
	ld	a,(hl)
	ld	-16 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-15 (ix),a
	ld	a,-14 (ix)
	add	a,#0x0D
	ld	l, a
	ld	a, -13 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-16 (ix)
	add	a,e
	ld	e,a
	ld	a,-15 (ix)
	adc	a,d
	ld	d,a
	ld	-4 (ix),e
	ld	-3 (ix),d
;obj_.c:35: right1 = left1 + this->col_width;
	ld	hl,#0x0009
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-2 (ix)
	add	a,e
	ld	e,a
	ld	a,-1 (ix)
	adc	a,d
	ld	d,a
	ld	-6 (ix),e
	ld	-5 (ix),d
;obj_.c:36: right2 = left2 + other->col_width;
	ld	a,-14 (ix)
	add	a,#0x09
	ld	l, a
	ld	a, -13 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-4 (ix)
	add	a,e
	ld	e,a
	ld	a,-3 (ix)
	adc	a,d
	ld	d,a
	ld	-8 (ix),e
	ld	-7 (ix),d
;obj_.c:37: top1 = this->y + this->col_y_offset;
	ld	hl,#0x0003
	add	hl,bc
	ld	a,(hl)
	ld	-16 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-15 (ix),a
	ld	hl,#0x000F
	add	hl,bc
	ld	a,(hl)
	ld	-18 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-17 (ix),a
	ld	a,-16 (ix)
	add	a,-18 (ix)
	ld	e,a
	ld	a,-15 (ix)
	adc	a,-17 (ix)
	ld	d,a
	ld	-10 (ix),e
	ld	-9 (ix),d
;obj_.c:38: top2 = other->y + this->col_y_offset;
	ld	a,-14 (ix)
	add	a,#0x03
	ld	l, a
	ld	a, -13 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,e
	add	a,-18 (ix)
	ld	e,a
	ld	a,d
	adc	a,-17 (ix)
	ld	d,a
;obj_.c:39: bottom1 = top1 + this->col_height;
	ld	hl,#0x000B
	add	hl,bc
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,-10 (ix)
	add	a,c
	ld	c,a
	ld	a,-9 (ix)
	adc	a,b
	ld	b,a
	ld	-12 (ix),c
	ld	-11 (ix),b
;obj_.c:40: bottom2 = top2 + other->col_height;
	ld	a,-14 (ix)
	add	a,#0x0B
	ld	l, a
	ld	a, -13 (ix)
	adc	a, #0x00
	ld	h,a
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,e
	add	a,c
	ld	c,a
	ld	a,d
	adc	a,b
	ld	b,a
;obj_.c:42: if (bottom1 < top2) return(FALSE);
	ld	a,-12 (ix)
	sub	a,e
	ld	a,-11 (ix)
	sbc	a,d
	jp	P,00102$
	ld	l,#0x00
	jr	00109$
00102$:
;obj_.c:43: if (top1 > bottom2) return(FALSE);
	ld	a,c
	sub	a,-10 (ix)
	ld	a,b
	sbc	a,-9 (ix)
	jp	P,00104$
	ld	l,#0x00
	jr	00109$
00104$:
;obj_.c:45: if (right1 < left2) return(FALSE);
	ld	a,-6 (ix)
	sub	a,-4 (ix)
	ld	a,-5 (ix)
	sbc	a,-3 (ix)
	jp	P,00106$
	ld	l,#0x00
	jr	00109$
00106$:
;obj_.c:46: if (left1 > right2) return(FALSE);
	ld	a,-8 (ix)
	sub	a,-2 (ix)
	ld	a,-7 (ix)
	sbc	a,-1 (ix)
	jp	P,00108$
	ld	l,#0x00
	jr	00109$
00108$:
;obj_.c:48: return(TRUE);
	ld	l,#0x01
00109$:
	ld	sp,ix
	pop	ix
	ret
_GameObj_Collide_end::
;obj_anim.c:6: void GameObjAnim_Init(GameObjAnim* this, int x, int y/*, byte offset*/)
;	---------------------------------
; Function GameObjAnim_Init
; ---------------------------------
_GameObjAnim_Init_start::
_GameObjAnim_Init:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_anim.c:8: this->gobj.x = x;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	l,c
	ld	h,b
	inc	hl
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
;obj_anim.c:9: this->gobj.y = y;
	ld	hl,#0x0003
	add	hl,bc
	ld	a,8 (ix)
	ld	(hl),a
	inc	hl
	ld	a,9 (ix)
	ld	(hl),a
;obj_anim.c:11: this->is_Xflip = FALSE;
	ld	hl,#0x001E
	add	hl,bc
	ex	de,hl
	ld	a,#0x00
	ld	(de),a
;obj_anim.c:12: this->isLoopAnim = TRUE;
	ld	hl,#0x0024
	add	hl,bc
	ex	de,hl
	ld	a,#0x01
	ld	(de),a
;obj_anim.c:15: this->gobj.pMoveFunc = &GameObjAnim_Move;
	ld	hl,#0x0013
	add	hl,bc
	ld	e,l
	ld	(hl),#<_GameObjAnim_Move
	inc	hl
	ld	(hl),#>_GameObjAnim_Move
;obj_anim.c:16: this->gobj.pDrawFunc = &GameObjAnim_Draw;
	ld	hl,#0x0015
	add	hl,bc
	ld	b,h
	ld	(hl),#<_GameObjAnim_Draw
	inc	hl
	ld	(hl),#>_GameObjAnim_Draw
	pop	ix
	ret
_GameObjAnim_Init_end::
;obj_anim.c:21: void GameObjAnim_Move(GameObjAnim* this)
;	---------------------------------
; Function GameObjAnim_Move
; ---------------------------------
_GameObjAnim_Move_start::
_GameObjAnim_Move:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_anim.c:24: }
	pop	ix
	ret
_GameObjAnim_Move_end::
;obj_anim.c:26: void GameObjAnim_Draw(GameObjAnim* this)
;	---------------------------------
; Function GameObjAnim_Draw
; ---------------------------------
_GameObjAnim_Draw_start::
_GameObjAnim_Draw:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-29
	add	hl,sp
	ld	sp,hl
;obj_anim.c:30: byte def_pitch = 0;
	ld	-4 (ix),#0x00
;obj_anim.c:32: if(!this->isAnimEnabled)
	ld	e,4 (ix)
	ld	d,5 (ix)
	ld	hl,#0x0023
	add	hl,de
	ld	a,(hl)
	or	a,a
;obj_anim.c:33: return;
	jp	Z,00114$
;obj_anim.c:34: Game_MarkFrameTime(0x0f0);
	push	de
	ld	hl,#0x00F0
	push	hl
	call	_Game_MarkFrameTime
	pop	af
	pop	de
;obj_anim.c:38: if(this->spr_count != PoolSprites_AllocateSpriteNumber(this->spr_count))
	ld	hl,#0x0019
	add	hl,de
	ld	-6 (ix),l
	ld	-5 (ix),h
	ld	c,(hl)
	push	bc
	push	de
	ld	a,c
	push	af
	inc	sp
	call	_PoolSprites_AllocateSpriteNumber
	inc	sp
	ld	b,l
	pop	de
	ld	a,b
	pop	bc
	ld	b,a
	ld	a,c
	sub	b
;obj_anim.c:39: return;
;obj_anim.c:44: for(i=0;i<this->spr_count;i++)  {
	jp	NZ,00114$
	ld	hl,#0x0021
	add	hl,de
	ld	-20 (ix),l
	ld	-19 (ix),h
	ld	hl,#0x001A
	add	hl,de
	ld	-8 (ix),l
	ld	-7 (ix),h
	ld	hl,#0x001E
	add	hl,de
	ld	-10 (ix),l
	ld	-9 (ix),h
	ld	hl,#0x001B
	add	hl,de
	ld	-12 (ix),l
	ld	-11 (ix),h
	ld	hl,#0x0003
	add	hl,de
	ld	-14 (ix),l
	ld	-13 (ix),h
	ld	hl,#0x0001
	add	hl,de
	ld	-16 (ix),l
	ld	-15 (ix),h
	ld	hl,#0x001D
	add	hl,de
	ld	-18 (ix),l
	ld	-17 (ix),h
	ld	-1 (ix),#0x00
00110$:
	ld	l,-6 (ix)
	ld	h,-5 (ix)
	ld	a,-1 (ix)
	sub	a,(hl)
	jp	NC,00113$
;obj_anim.c:45: def = ((this->spr_anim_def_offset/256U) * this->spr_height)  + def_pitch;
	ld	l,-20 (ix)
	ld	h,-19 (ix)
	inc	hl
	ld	b,(hl)
	ld	-22 (ix),b
	ld	-21 (ix),#0x00
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	a,(hl)
	ld	-23 (ix),a
	ld	c, a
	ld	b,#0x00
	push	de
	push	bc
	ld	l,-22 (ix)
	ld	h,-21 (ix)
	push	hl
	call	__mulint_rrx_s
	pop	af
	pop	af
	ld	-21 (ix),h
	ld	-22 (ix),l
	pop	de
	ld	c,-4 (ix)
	ld	b,#0x00
	ld	a,-22 (ix)
	add	a,c
	ld	c,a
	ld	a,-21 (ix)
	adc	a,b
	ld	b,a
	ld	-3 (ix),c
	ld	-2 (ix),b
;obj_anim.c:49: /*FALSE*/this->is_Xflip);
	ld	l,-10 (ix)
	ld	h,-9 (ix)
	ld	a,(hl)
	ld	-22 (ix),a
;obj_anim.c:48: this->spr_def_start + def,
	ld	l,-12 (ix)
	ld	h,-11 (ix)
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,c
	add	a,-3 (ix)
	ld	-25 (ix),a
	ld	a,b
	adc	a,-2 (ix)
	ld	-24 (ix),a
;obj_anim.c:46: set_sprite_regs(allocatedSpriteNumbers[i], this->gobj.x + i*16,  this->gobj.y,
	ld	l,-14 (ix)
	ld	h,-13 (ix)
	ld	a,(hl)
	ld	-27 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-26 (ix),a
	ld	l,-16 (ix)
	ld	h,-15 (ix)
	ld	a,(hl)
	ld	-29 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-28 (ix),a
	ld	c,-1 (ix)
	ld	b,#0x00
	sla	c
	rl	b
	sla	c
	rl	b
	sla	c
	rl	b
	sla	c
	rl	b
	ld	a,-29 (ix)
	add	a,c
	ld	-29 (ix),a
	ld	a,-28 (ix)
	adc	a,b
	ld	-28 (ix),a
	ld	a,#<_allocatedSpriteNumbers
	add	a,-1 (ix)
	ld	c,a
	ld	a,#>_allocatedSpriteNumbers
	adc	a,#0x00
	ld	b,a
	ld	a,(bc)
	ld	c,a
	push	de
	ld	a,-22 (ix)
	push	af
	inc	sp
	ld	l,-25 (ix)
	ld	h,-24 (ix)
	push	hl
	ld	a,-23 (ix)
	push	af
	inc	sp
	ld	l,-27 (ix)
	ld	h,-26 (ix)
	push	hl
	ld	l,-29 (ix)
	ld	h,-28 (ix)
	push	hl
	ld	a,c
	push	af
	inc	sp
	call	_set_sprite_regs
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
	pop	de
;obj_anim.c:63: def_pitch += this->spr_def_pitch;
	ld	l,-18 (ix)
	ld	h,-17 (ix)
	ld	c,(hl)
	ld	a,-4 (ix)
	add	a,c
	ld	-4 (ix),a
;obj_anim.c:44: for(i=0;i<this->spr_count;i++)  {
	inc	-1 (ix)
	jp	00110$
00113$:
;obj_anim.c:66: this->spr_anim_def_offset += this->spr_anim_def_step;
	ld	l,-20 (ix)
	ld	h,-19 (ix)
	ld	a,(hl)
	ld	-29 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-28 (ix),a
	ld	hl,#0x001F
	add	hl,de
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,-29 (ix)
	add	a,c
	ld	c,a
	ld	a,-28 (ix)
	adc	a,b
	ld	b,a
	ld	l,-20 (ix)
	ld	h,-19 (ix)
	ld	(hl),c
	inc	hl
	ld	(hl),b
;obj_anim.c:72: if( (this->spr_anim_def_offset/256U) >= this->spr_anim_frames)
	ld	-29 (ix),b
	ld	-28 (ix),#0x00
	ld	hl,#0x0018
	add	hl,de
	ld	a,(hl)
	ld	c,a
	ld	b,#0x00
	ld	a,-29 (ix)
	sub	a,c
	ld	a,-28 (ix)
	sbc	a,b
	jr	C,00109$
;obj_anim.c:73: if(this->isLoopAnim)
	ld	hl,#0x0024
	add	hl,de
	ld	a,(hl)
	or	a,a
	jr	Z,00106$
;obj_anim.c:74: GameObjAnim_init_animation(this);
	push	de
	call	_GameObjAnim_init_animation
	pop	af
	jr	00109$
00106$:
;obj_anim.c:76: GameObjAnim_Free(this);
	push	de
	call	_GameObjAnim_Free
	pop	af
00109$:
;obj_anim.c:79: Game_MarkFrameTime(0xf00);
	ld	hl,#0x0F00
	push	hl
	call	_Game_MarkFrameTime
	pop	af
00114$:
	ld	sp,ix
	pop	ix
	ret
_GameObjAnim_Draw_end::
;obj_anim.c:82: void GameObjAnim_EnableAnimation(GameObjAnim* this, BOOL isEnable)
;	---------------------------------
; Function GameObjAnim_EnableAnimation
; ---------------------------------
_GameObjAnim_EnableAnimation_start::
_GameObjAnim_EnableAnimation:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;obj_anim.c:85: this->isAnimEnabled = isEnable;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0023
	add	hl,bc
	ex	de,hl
	ld	a,6 (ix)
	ld	(de),a
;obj_anim.c:86: this->spr_anim_def_step = this->spr_anim_frames*256U / this->spr_anim_time;
	ld	hl,#0x001F
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	hl,#0x0018
	add	hl,bc
	ld	a,(hl)
	ld	-3 (ix),a
	ld	-4 (ix),#0x00
	ld	hl,#0x0017
	add	hl,bc
	ld	e,(hl)
	ld	d,#0x00
	push	bc
	push	de
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	call	__divuint_rrx_s
	pop	af
	pop	af
	ex	de,hl
	pop	bc
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_anim.c:88: GameObjAnim_init_animation(this);
	push	bc
	call	_GameObjAnim_init_animation
	pop	af
	ld	sp,ix
	pop	ix
	ret
_GameObjAnim_EnableAnimation_end::
;obj_anim.c:92: void GameObjAnim_init_animation(GameObjAnim* this)
;	---------------------------------
; Function GameObjAnim_init_animation
; ---------------------------------
_GameObjAnim_init_animation_start::
_GameObjAnim_init_animation:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_anim.c:96: this->spr_anim_def_offset = 0 ;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0021
	add	hl,bc
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	pop	ix
	ret
_GameObjAnim_init_animation_end::
;obj_anim.c:101: void GameObjAnim_ShowOnlyFirstFrame(GameObjAnim* this)
;	---------------------------------
; Function GameObjAnim_ShowOnlyFirstFrame
; ---------------------------------
_GameObjAnim_ShowOnlyFirstFrame_start::
_GameObjAnim_ShowOnlyFirstFrame:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_anim.c:103: this->spr_anim_time      = 0;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ex	de,hl
	ld	a,#0x00
	ld	(de),a
;obj_anim.c:104: this->spr_anim_frames    = 0;
	ld	hl,#0x0018
	add	hl,bc
	ex	de,hl
	ld	a,#0x00
	ld	(de),a
;obj_anim.c:105: GameObjAnim_EnableAnimation(this,TRUE);
	ld	a,#0x01
	push	af
	inc	sp
	push	bc
	call	_GameObjAnim_EnableAnimation
	pop	af
	inc	sp
	pop	ix
	ret
_GameObjAnim_ShowOnlyFirstFrame_end::
;obj_anim.c:109: void GameObjAnim_Free(GameObjAnim* this)
;	---------------------------------
; Function GameObjAnim_Free
; ---------------------------------
_GameObjAnim_Free_start::
_GameObjAnim_Free:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_anim.c:111: PoolGameObj_FreeGameObj( (GameObj*)this );
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	call	_PoolGameObj_FreeGameObj
	pop	af
	pop	ix
	ret
_GameObjAnim_Free_end::
;obj_score.c:2: void GameObjScore_Init(GameObjScore* this, int x, int y)
;	---------------------------------
; Function GameObjScore_Init
; ---------------------------------
_GameObjScore_Init_start::
_GameObjScore_Init:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_score.c:4: this->gobj.x = x;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	l,c
	ld	h,b
	inc	hl
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
;obj_score.c:5: this->gobj.y = y;
	ld	hl,#0x0003
	add	hl,bc
	ld	a,8 (ix)
	ld	(hl),a
	inc	hl
	ld	a,9 (ix)
	ld	(hl),a
;obj_score.c:7: this->gobj.pMoveFunc = &GameObjScore_Move;
	ld	hl,#0x0013
	add	hl,bc
	ld	e,l
	ld	(hl),#<_GameObjScore_Move
	inc	hl
	ld	(hl),#>_GameObjScore_Move
;obj_score.c:8: this->gobj.pDrawFunc = &GameObjScore_Draw;
	ld	hl,#0x0015
	add	hl,bc
	ld	e,l
	ld	d,h
	ld	(hl),#<_GameObjScore_Draw
	inc	hl
	ld	(hl),#>_GameObjScore_Draw
;obj_score.c:10: this->state = NORMAL;
	ld	hl,#0x0017
	add	hl,bc
	ex	de,hl
	ld	a,#0x00
	ld	(de),a
;obj_score.c:12: this->is_show = TRUE;
	ld	hl,#0x0020
	add	hl,bc
	ex	de,hl
	ld	a,#0x01
	ld	(de),a
;obj_score.c:13: this->off_time_counter = this->off_num_switches = 0;
	ld	hl,#0x001E
	add	hl,bc
	ex	de,hl
	ld	hl,#0x001F
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,#0x00
	ld	(bc),a
	ld	(de),a
	pop	ix
	ret
_GameObjScore_Init_end::
;obj_score.c:18: void GameObjScore_Move(GameObjScore* this)
;	---------------------------------
; Function GameObjScore_Move
; ---------------------------------
_GameObjScore_Move_start::
_GameObjScore_Move:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-6
	add	hl,sp
	ld	sp,hl
;obj_score.c:20: if(this->state == BLINKING) {
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	a,(hl)
	sub	a,#0x03
	jp	NZ,00106$
;obj_score.c:21: if(this->off_time_counter > 25) {
	ld	hl,#0x001E
	add	hl,bc
	ld	-4 (ix),l
	ld	-3 (ix),h
	ld	e,(hl)
	ld	a,#0x19
	sub	a,e
	jr	NC,00104$
;obj_score.c:22: this->off_num_switches++;
	ld	hl,#0x001F
	add	hl,bc
	ld	-6 (ix),l
	ld	-5 (ix),h
	ld	e,(hl)
	inc	e
	ld	l,-6 (ix)
	ld	h,-5 (ix)
	ld	(hl),e
;obj_score.c:23: this->off_time_counter = 0;
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	(hl),#0x00
;obj_score.c:25: if(this->off_num_switches & 1)
	ld	a,e
	and	a,#0x01
	jr	Z,00104$
;obj_score.c:26: Sound_NewFx(SOUND_FX_LASER_SHOT);
	push	bc
	ld	a,#0x07
	push	af
	inc	sp
	call	_Sound_NewFx
	inc	sp
	pop	bc
00104$:
;obj_score.c:28: this->off_time_counter++;
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	inc	(hl)
;obj_score.c:30: this->is_show = this->off_num_switches & 1;
	ld	hl,#0x0020
	add	hl,bc
	ld	-6 (ix),l
	ld	-5 (ix),h
	ld	hl,#0x001F
	add	hl,bc
	ld	a,(hl)
	and	a,#0x01
	ld	l,-6 (ix)
	ld	h,-5 (ix)
	ld	(hl),a
00106$:
;obj_score.c:34: if(this->score >= MAX_SCORE_FOR_LEVEL &&
	ld	hl,#0x0018
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,e
	sub	a,#0x0A
	ld	a,d
	sbc	a,#0x00
	jp	M,00114$
;obj_score.c:35: this->state == BLINKING && this->off_num_switches >= 8) {
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,(hl)
	sub	a,#0x03
	jr	NZ,00114$
	ld	hl,#0x001F
	add	hl,bc
	ld	a,(hl)
	sub	a,#0x08
	jr	C,00114$
;obj_score.c:36: if(this == &scoreA)
	push	bc
;	direct compare
	ld	a,#<_scoreA
	sub	c
	jr	NZ,00128$
;	direct compare
	ld	c,b
	ld	a,#>_scoreA
	sub	c
	jr	NZ,00128$
	pop	bc
	jr	00129$
00128$:
	pop	bc
	jr	00108$
00129$:
;obj_score.c:37: helper_GameObjYouWin_StartAnimation(0);
	ld	a,#0x00
	push	af
	inc	sp
	call	_helper_GameObjYouWin_StartAnimation
	inc	sp
	jr	00114$
00108$:
;obj_score.c:39: helper_GameObjYouWin_StartAnimation(1);
	ld	a,#0x01
	push	af
	inc	sp
	call	_helper_GameObjYouWin_StartAnimation
	inc	sp
00114$:
	ld	sp,ix
	pop	ix
	ret
_GameObjScore_Move_end::
;obj_score.c:44: void GameObjScore_Draw(GameObjScore* this)
;	---------------------------------
; Function GameObjScore_Draw
; ---------------------------------
_GameObjScore_Draw_start::
_GameObjScore_Draw:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_score.c:46: if(this->is_show) {
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0020
	add	hl,bc
	ld	a,(hl)
	or	a,a
	jr	Z,00102$
;obj_score.c:47: GameObjScore_draw_score(this);
	push	bc
	push	bc
	call	_GameObjScore_draw_score
	pop	af
	pop	bc
00102$:
;obj_score.c:50: GameObjScore_Draw_PlayerRocketsIndicator(this);
	push	bc
	call	_GameObjScore_Draw_PlayerRocketsIndicator
	pop	af
	pop	ix
	ret
_GameObjScore_Draw_end::
;obj_score.c:56: void GameObjScore_draw_score(GameObjScore* this)
;	---------------------------------
; Function GameObjScore_draw_score
; ---------------------------------
_GameObjScore_draw_score_start::
_GameObjScore_draw_score:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-9
	add	hl,sp
	ld	sp,hl
;obj_score.c:60: char* p = this->score_str;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x001A
	add	hl,bc
	ld	-3 (ix),l
	ld	-2 (ix),h
;obj_score.c:61: int x = this->gobj.x; int y =  this->gobj.y;
	ld	l,c
	ld	h,b
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-5 (ix),e
	ld	-4 (ix),d
	ld	hl,#0x0003
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-7 (ix),e
	ld	-6 (ix),d
;obj_score.c:65: spr1_def = SPRITE_DEF_NUM_DIGIT + (p[0] - 0x30);
	ld	l,-3 (ix)
	ld	h,-2 (ix)
	ld	a,(hl)
	add	a,#0xD4
	ld	-1 (ix),a
;obj_score.c:66: if(p[1] != 0)
	ld	e,-3 (ix)
	ld	d,-2 (ix)
	inc	de
	ld	a,(de)
	ld	e,a
	or	a,a
	jr	Z,00102$
;obj_score.c:67: spr2_def = SPRITE_DEF_NUM_DIGIT + (p[1] - 0x30);
	ld	a,e
	add	a,#0xD4
	ld	d,a
	jr	00103$
00102$:
;obj_score.c:69: spr2_def = 0xff;
	ld	d,#0xFF
00103$:
;obj_score.c:74: set_sprite_regs(this->sprite_num  , x,      y, spr_height, spr1_def, FALSE);
	ld	a,-1 (ix)
	ld	-9 (ix),a
	ld	-8 (ix),#0x00
	ld	hl,#0x001D
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,(bc)
	ld	e,a
	push	bc
	push	de
	ld	a,#0x00
	push	af
	inc	sp
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	push	hl
	ld	a,#0x01
	push	af
	inc	sp
	ld	l,-7 (ix)
	ld	h,-6 (ix)
	push	hl
	ld	l,-5 (ix)
	ld	h,-4 (ix)
	push	hl
	ld	a,e
	push	af
	inc	sp
	call	_set_sprite_regs
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
	pop	de
	pop	bc
;obj_score.c:75: if(spr2_def == 0xff)
	ld	a,d
	inc	a
	jr	NZ,00105$
;obj_score.c:76: y = 256;        // put sprite off-screen
	ld	-7 (ix),#0x00
	ld	-6 (ix),#0x01
00105$:
;obj_score.c:77: set_sprite_regs(this->sprite_num+1, x+16,   y, spr_height, spr2_def, FALSE);
	ld	-9 (ix),d
	ld	-8 (ix),#0x00
	ld	a,-5 (ix)
	add	a,#0x10
	ld	e,a
	ld	a,-4 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,(bc)
	ld	c,a
	inc	c
	ld	a,#0x00
	push	af
	inc	sp
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	push	hl
	ld	a,#0x01
	push	af
	inc	sp
	ld	l,-7 (ix)
	ld	h,-6 (ix)
	push	hl
	push	de
	ld	a,c
	push	af
	inc	sp
	call	_set_sprite_regs
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
	ld	sp,ix
	pop	ix
	ret
_GameObjScore_draw_score_end::
;obj_score.c:84: void GameObjScore_UpdateScore(GameObjScore* this)
;	---------------------------------
; Function GameObjScore_UpdateScore
; ---------------------------------
_GameObjScore_UpdateScore_start::
_GameObjScore_UpdateScore:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_score.c:87: _uitoa(this->score, this->score_str, 10);
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x001A
	add	hl,bc
	ex	de,hl
	ld	hl,#0x0018
	add	hl,bc
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,#0x0A
	push	af
	inc	sp
	push	de
	push	bc
	call	__uitoa
	pop	af
	pop	af
	inc	sp
	pop	ix
	ret
_GameObjScore_UpdateScore_end::
;obj_score.c:91: void GameObjScore_SetState(GameObjScore* this, ObjState state)
;	---------------------------------
; Function GameObjScore_SetState
; ---------------------------------
_GameObjScore_SetState_start::
_GameObjScore_SetState:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;obj_score.c:95: if(state == this->state)
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	e,(hl)
	ld	a,6 (ix)
	sub	e
	jr	NZ,00102$
;obj_score.c:96: return;
	jr	00105$
00102$:
;obj_score.c:97: this->state = state;
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,6 (ix)
	ld	(hl),a
;obj_score.c:99: if(this->state == BLINKING) {
	ld	a,6 (ix)
	sub	a,#0x03
	jr	NZ,00105$
;obj_score.c:101: this->off_time_counter = this->off_num_switches = this->is_show = 0;
	ld	hl,#0x001E
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	hl,#0x001F
	add	hl,bc
	ex	de,hl
	ld	hl,#0x0020
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,#0x00
	ld	(bc),a
	ld	(de),a
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	(hl),#0x00
00105$:
	ld	sp,ix
	pop	ix
	ret
_GameObjScore_SetState_end::
;obj_score.c:106: void GameObjScore_SetScore(GameObjScore* this, short score)
;	---------------------------------
; Function GameObjScore_SetScore
; ---------------------------------
_GameObjScore_SetScore_start::
_GameObjScore_SetScore:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_score.c:108: this->score = score;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0018
	add	hl,bc
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
;obj_score.c:109: GameObjScore_UpdateScore(this);
	push	bc
	call	_GameObjScore_UpdateScore
	pop	af
	pop	ix
	ret
_GameObjScore_SetScore_end::
;obj_score.c:121: BOOL helper_GameObjScore_IsScoreBlinkedAtLeast(byte num)
;	---------------------------------
; Function helper_GameObjScore_IsScoreBlinkedAtLeast
; ---------------------------------
_helper_GameObjScore_IsScoreBlinkedAtLeast_start::
_helper_GameObjScore_IsScoreBlinkedAtLeast:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_score.c:123: return ((scoreA.state == BLINKING  && scoreA.off_num_switches >= num) ||
	ld	bc,#_scoreA + 23
	ld	a,(bc)
	sub	a,#0x03
	jr	NZ,00106$
	ld	bc,#_scoreA + 31
	ld	a,(bc)
	sub	a,4 (ix)
	ld	a,#0x00
	rla
	or	a,a
	sub	a,#0x01
	ld	a,#0x00
	rla
	or	a,a
	jr	NZ,00107$
00106$:
	ld	c,#0x00
	jr	00108$
00107$:
	ld	c,#0x01
00108$:
	xor	a,a
	or	a,c
	jr	NZ,00104$
;obj_score.c:124: (scoreB.state == BLINKING  && scoreB.off_num_switches >= num));
	ld	bc,#_scoreB + 23
	ld	a,(bc)
	sub	a,#0x03
	jr	NZ,00109$
	ld	bc,#_scoreB + 31
	ld	a,(bc)
	sub	a,4 (ix)
	ld	a,#0x00
	rla
	or	a,a
	sub	a,#0x01
	ld	a,#0x00
	rla
	or	a,a
	jr	NZ,00110$
00109$:
	ld	c,#0x00
	jr	00111$
00110$:
	ld	c,#0x01
00111$:
	xor	a,a
	or	a,c
	jr	NZ,00104$
	ld	c,a
	jr	00105$
00104$:
	ld	c,#0x01
00105$:
	ld	l,c
	pop	ix
	ret
_helper_GameObjScore_IsScoreBlinkedAtLeast_end::
;obj_score.c:136: void GameObjScore_Draw_PlayerRocketsIndicator(GameObjScore* this)
;	---------------------------------
; Function GameObjScore_Draw_PlayerRocketsIndicator
; ---------------------------------
_GameObjScore_Draw_PlayerRocketsIndicator_start::
_GameObjScore_Draw_PlayerRocketsIndicator:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-7
	add	hl,sp
	ld	sp,hl
;obj_score.c:142: for(i=0; i<this->num_rockets; i++)
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0022
	add	hl,bc
	ld	-3 (ix),l
	ld	-2 (ix),h
	ld	-1 (ix),#0x00
00101$:
	ld	l,-3 (ix)
	ld	h,-2 (ix)
	ld	a,-1 (ix)
	sub	a,(hl)
	jp	NC,00105$
;obj_score.c:144: this->gobj.x + i*8, this->gobj.y + 16, spr_height,
	ld	hl,#0x0003
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	hl,#0x0010
	add	hl,de
	ld	-5 (ix),l
	ld	-4 (ix),h
	ld	l,c
	ld	h,b
	inc	hl
	ld	a,(hl)
	ld	-7 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-6 (ix),a
	ld	e,-1 (ix)
	ld	d,#0x00
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	ld	a,-7 (ix)
	add	a,e
	ld	-7 (ix),a
	ld	a,-6 (ix)
	adc	a,d
	ld	-6 (ix),a
;obj_score.c:143: set_sprite_regs(this->sprite_num_RocketsIndicator + i,
	ld	hl,#0x0021
	add	hl,bc
	ld	a,(hl)
	add	a,-1 (ix)
	ld	e,a
	push	bc
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x003A
	push	hl
	ld	a,#0x01
	push	af
	inc	sp
	ld	l,-5 (ix)
	ld	h,-4 (ix)
	push	hl
	ld	l,-7 (ix)
	ld	h,-6 (ix)
	push	hl
	ld	a,e
	push	af
	inc	sp
	call	_set_sprite_regs
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
	pop	bc
;obj_score.c:142: for(i=0; i<this->num_rockets; i++)
	inc	-1 (ix)
	jp	00101$
00105$:
	ld	sp,ix
	pop	ix
	ret
_GameObjScore_Draw_PlayerRocketsIndicator_end::
;obj_rocket.c:13: void GameObjRocket_Init(GameObjRocket* this, int x, int y)
;	---------------------------------
; Function GameObjRocket_Init
; ---------------------------------
_GameObjRocket_Init_start::
_GameObjRocket_Init:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;obj_rocket.c:16: GameObj_Init((GameObj*)this);
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	call	_GameObj_Init
	pop	af
;obj_rocket.c:18: this->gobj.x = x;
	ld	a,4 (ix)
	ld	-4 (ix),a
	ld	a,5 (ix)
	ld	-3 (ix),a
	ld	e,-4 (ix)
	ld	d,-3 (ix)
	ex	de,hl
	inc	hl
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
;obj_rocket.c:19: this->gobj.y = y;
	ld	a,-4 (ix)
	add	a,#0x03
	ld	l, a
	ld	a, -3 (ix)
	adc	a, #0x00
	ld	h,a
	ld	a,8 (ix)
	ld	(hl),a
	inc	hl
	ld	a,9 (ix)
	ld	(hl),a
;obj_rocket.c:20: this->gobj.width  = 16*2;
	ld	a,-4 (ix)
	add	a,#0x05
	ld	l, a
	ld	a, -3 (ix)
	adc	a, #0x00
	ld	h,a
	ld	(hl),#0x20
	inc	hl
	ld	(hl),#0x00
;obj_rocket.c:21: this->gobj.height = 16;
	ld	a,-4 (ix)
	add	a,#0x07
	ld	l, a
	ld	a, -3 (ix)
	adc	a, #0x00
	ld	h,a
	ld	(hl),#0x10
	inc	hl
	ld	(hl),#0x00
;obj_rocket.c:23: this->my_x = (dword)x << 8;
	ld	a,-4 (ix)
	add	a,#0x1B
	ld	-2 (ix),a
	ld	a,-3 (ix)
	adc	a,#0x00
	ld	-1 (ix),a
	ld	e,6 (ix)
	ld	d,7 (ix)
	ld	a,7 (ix)
	rla	
	sbc	a,a
	ld	c,a
	ld	b,a
	ld	a,#0x08
	push	af
	inc	sp
	push	bc
	push	de
	call	__rlulong_rrx_s
	pop	af
	pop	af
	inc	sp
	ld	b,h
	ld	c,l
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	(hl),c
	inc	hl
	ld	(hl),b
	inc	hl
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_rocket.c:25: GameObj_InitCollideBox((GameObj*)this);
	ld	c,-4 (ix)
	ld	b,-3 (ix)
	push	bc
	call	_GameObj_InitCollideBox
	pop	af
;obj_rocket.c:27: this->gobj.pMoveFunc = &GameObjRocket_Move;
	ld	a,-4 (ix)
	add	a,#0x13
	ld	c,a
	ld	a,-3 (ix)
	adc	a,#0x00
	ld	b,a
	ld	l,c
	ld	h,a
	ld	(hl),#<_GameObjRocket_Move
	inc	hl
	ld	(hl),#>_GameObjRocket_Move
;obj_rocket.c:28: this->gobj.pDrawFunc = &GameObjRocket_Draw;
	ld	a,-4 (ix)
	add	a,#0x15
	ld	c,a
	ld	a,-3 (ix)
	adc	a,#0x00
	ld	b,a
	ld	l,c
	ld	h,a
	ld	(hl),#<_GameObjRocket_Draw
	inc	hl
	ld	(hl),#>_GameObjRocket_Draw
;obj_rocket.c:31: if(x < SCREEN_WIDTH/2) {
	ld	a,6 (ix)
	sub	a,#0xB8
	ld	a,7 (ix)
	sbc	a,#0x00
	jp	P,00102$
;obj_rocket.c:32: this->x_speed = 2 << 8;
	ld	a,-4 (ix)
	add	a,#0x1F
	ld	l, a
	ld	a, -3 (ix)
	adc	a, #0x00
	ld	h,a
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x02
;obj_rocket.c:33: this->x_speed_acc = 0x0010;
	ld	a,-4 (ix)
	add	a,#0x21
	ld	l, a
	ld	a, -3 (ix)
	adc	a, #0x00
	ld	h,a
	ld	(hl),#0x10
	inc	hl
	ld	(hl),#0x00
;obj_rocket.c:34: this->isMovingToTheRight = TRUE;
	ld	a,-4 (ix)
	add	a,#0x23
	ld	c,a
	ld	a,-3 (ix)
	adc	a,#0x00
	ld	b,a
	ld	a,#0x01
	ld	(bc),a
	jr	00103$
00102$:
;obj_rocket.c:37: this->x_speed = -2 << 8;
	ld	a,-4 (ix)
	add	a,#0x1F
	ld	l, a
	ld	a, -3 (ix)
	adc	a, #0x00
	ld	h,a
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0xFE
;obj_rocket.c:38: this->x_speed_acc = -0x0010;
	ld	a,-4 (ix)
	add	a,#0x21
	ld	l, a
	ld	a, -3 (ix)
	adc	a, #0x00
	ld	h,a
	ld	(hl),#0xF0
	inc	hl
	ld	(hl),#0xFF
;obj_rocket.c:39: this->isMovingToTheRight = FALSE;
	ld	a,-4 (ix)
	add	a,#0x23
	ld	c,a
	ld	a,-3 (ix)
	adc	a,#0x00
	ld	b,a
	ld	a,#0x00
	ld	(bc),a
00103$:
;obj_rocket.c:43: GameObjRocket_AllocateAnimationObj(this);
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	call	_GameObjRocket_AllocateAnimationObj
	pop	af
	ld	sp,ix
	pop	ix
	ret
_GameObjRocket_Init_end::
;obj_rocket.c:47: void GameObjRocket_Move(GameObjRocket* /*restrict*/ this)
;	---------------------------------
; Function GameObjRocket_Move
; ---------------------------------
_GameObjRocket_Move_start::
_GameObjRocket_Move:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-13
	add	hl,sp
	ld	sp,hl
;obj_rocket.c:55: this->my_x += this->x_speed;
	ld	a,4 (ix)
	ld	-5 (ix),a
	ld	a,5 (ix)
	ld	-4 (ix),a
	ld	a,-5 (ix)
	add	a,#0x1B
	ld	-3 (ix),a
	ld	a,-4 (ix)
	adc	a,#0x00
	ld	-2 (ix),a
	ld	l,-3 (ix)
	ld	h,-2 (ix)
	ld	a,(hl)
	ld	-13 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-12 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-11 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-10 (ix),a
	ld	a,-5 (ix)
	add	a,#0x1F
	ld	-7 (ix),a
	ld	a,-4 (ix)
	adc	a,#0x00
	ld	-6 (ix),a
	ld	l,-7 (ix)
	ld	h,-6 (ix)
	ld	a,(hl)
	ld	-9 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-8 (ix),a
	ld	c,-9 (ix)
	ld	b,-8 (ix)
	ld	a,-8 (ix)
	rla	
	sbc	a,a
	ld	e,a
	ld	d,a
	ld	a,-13 (ix)
	add	a,c
	ld	c,a
	ld	a,-12 (ix)
	adc	a,b
	ld	b,a
	ld	a,-11 (ix)
	adc	a,e
	ld	e,a
	ld	a,-10 (ix)
	adc	a,d
	ld	d,a
	ld	l,-3 (ix)
	ld	h,-2 (ix)
	ld	(hl),c
	inc	hl
	ld	(hl),b
	inc	hl
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_rocket.c:56: this->gobj.x = ((dword)this->my_x >> 8);
	ld	a,-5 (ix)
	add	a,#0x01
	ld	-13 (ix),a
	ld	a,-4 (ix)
	adc	a,#0x00
	ld	-12 (ix),a
	ld	a,#0x08
	push	af
	inc	sp
	push	de
	push	bc
	call	__rrulong_rrx_s
	pop	af
	pop	af
	inc	sp
	ld	b,h
	ld	c,l
	ld	l,-13 (ix)
	ld	h,-12 (ix)
	ld	(hl),c
	inc	hl
	ld	(hl),b
;obj_rocket.c:59: speed = ((word)this->x_speed >> 8);
	ld	c,-9 (ix)
	ld	b,-8 (ix)
	ld	c,b
;obj_rocket.c:60: if( (speed > 0 && speed < 4) || (speed < 0 && speed > -4) )
	ld	a,#0x00
	ld	b,a
	sub	a,c
	jp	P,00105$
	ld	a,c
	sub	a,#0x04
	jp	M,00101$
00105$:
	ld	a,c
	bit	7,a
	jr	Z,00102$
	ld	a,#0xFC
	sub	a,c
	jp	P,00102$
00101$:
;obj_rocket.c:61: this->x_speed += this->x_speed_acc;
	ld	a,-5 (ix)
	add	a,#0x21
	ld	l, a
	ld	a, -4 (ix)
	adc	a, #0x00
	ld	h,a
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,-9 (ix)
	add	a,c
	ld	c,a
	ld	a,-8 (ix)
	adc	a,b
	ld	b,a
	ld	l,-7 (ix)
	ld	h,-6 (ix)
	ld	(hl),c
	inc	hl
	ld	(hl),b
00102$:
;obj_rocket.c:64: if(this->isMovingToTheRight){
	ld	a,-5 (ix)
	add	a,#0x23
	ld	c,a
	ld	a,-4 (ix)
	adc	a,#0x00
	ld	b,a
	ld	a,(bc)
	or	a,a
	jr	Z,00107$
;obj_rocket.c:65: xo = 0; xo1 = 16*1;     //xo2 = 16*2;
	ld	c,#0x00
	ld	-1 (ix),#0x10
	jr	00108$
00107$:
;obj_rocket.c:67: xo = 16*1; xo1 = 0;     //xo2 = 0;
	ld	c,#0x10
	ld	-1 (ix),#0x00
00108$:
;obj_rocket.c:69: GameObj_SetPos(&this->animObj->gobj,  this->gobj.x + xo,   this->gobj.y);
	ld	a,-5 (ix)
	add	a,#0x03
	ld	e,a
	ld	a,-4 (ix)
	adc	a,#0x00
	ld	d,a
	ld	l,e
	ld	h,a
	ld	a,(hl)
	ld	-9 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-8 (ix),a
	ld	l,-13 (ix)
	ld	h,-12 (ix)
	ld	a,(hl)
	ld	-7 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-6 (ix),a
	ld	a,c
	rla	
	sbc	a,a
	ld	b,a
	ld	a,-7 (ix)
	add	a,c
	ld	-7 (ix),a
	ld	a,-6 (ix)
	adc	a,b
	ld	-6 (ix),a
	ld	a,-5 (ix)
	add	a,#0x17
	ld	l, a
	ld	a, -4 (ix)
	adc	a, #0x00
	ld	h,a
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	push	de
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	push	hl
	ld	l,-7 (ix)
	ld	h,-6 (ix)
	push	hl
	push	bc
	call	_GameObj_SetPos
	pop	af
	pop	af
	pop	af
;obj_rocket.c:70: GameObj_SetPos(&this->animObj1->gobj, this->gobj.x + xo1,  this->gobj.y);
	pop	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	l,-13 (ix)
	ld	h,-12 (ix)
	ld	a,(hl)
	ld	-9 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-8 (ix),a
	ld	e,-1 (ix)
	ld	a,-1 (ix)
	rla	
	sbc	a,a
	ld	d,a
	ld	a,-9 (ix)
	add	a,e
	ld	-9 (ix),a
	ld	a,-8 (ix)
	adc	a,d
	ld	-8 (ix),a
	ld	a,-5 (ix)
	add	a,#0x19
	ld	l, a
	ld	a, -4 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	bc
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	push	hl
	push	de
	call	_GameObj_SetPos
	pop	af
	pop	af
	pop	af
;obj_rocket.c:73: cur_x = this->gobj.x;
	ld	l,-13 (ix)
	ld	h,-12 (ix)
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
;obj_rocket.c:74: width = this->gobj.width;
	ld	a,-5 (ix)
	add	a,#0x05
	ld	l, a
	ld	a, -4 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
;obj_rocket.c:76: if(cur_x > SCREEN_WIDTH || cur_x + width < 0){
	ld	a,#0x70
	sub	a,c
	ld	a,#0x01
	sbc	a,b
	jp	M,00109$
	ld	a,c
	add	a,e
	ld	c,a
	ld	a,b
	adc	a,d
	ld	b,a
	bit	7,a
	jr	Z,00110$
00109$:
;obj_rocket.c:77: GameObjRocket_Free(this);
	ld	l,-5 (ix)
	ld	h,-4 (ix)
	push	hl
	call	_GameObjRocket_Free
	pop	af
00110$:
;obj_rocket.c:80: GameObjRocket_CheckCollision(this);
	ld	l,-5 (ix)
	ld	h,-4 (ix)
	push	hl
	call	_GameObjRocket_CheckCollision
	pop	af
	ld	sp,ix
	pop	ix
	ret
_GameObjRocket_Move_end::
;obj_rocket.c:86: void GameObjRocket_CheckCollision(GameObjRocket* this)
;	---------------------------------
; Function GameObjRocket_CheckCollision
; ---------------------------------
_GameObjRocket_CheckCollision_start::
_GameObjRocket_CheckCollision:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;obj_rocket.c:92: gameObj = &this->gobj;
	ld	c,4 (ix)
	ld	b,5 (ix)
;obj_rocket.c:98: if(this->isMovingToTheRight)
	ld	hl,#0x0023
	add	hl,bc
	ld	a,(hl)
	or	a,a
	jr	Z,00102$
;obj_rocket.c:100: pBatCandidateForKill = &batB;
	ld	-2 (ix),#<_batB
	ld	-1 (ix),#>_batB
	jr	00103$
00102$:
;obj_rocket.c:102: pBatCandidateForKill = &batA;
	ld	-2 (ix),#<_batA
	ld	-1 (ix),#>_batA
00103$:
;obj_rocket.c:110: if(pBatCandidateForKill->state == NORMAL) {
	ld	a,-2 (ix)
	add	a,#0x17
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,(de)
	or	a,a
	jr	NZ,00108$
;obj_rocket.c:114: if(GameObj_Collide((GameObj*)this, (GameObj*)pBatCandidateForKill))
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	push	bc
	call	_GameObj_Collide
	pop	af
	pop	af
	xor	a,a
	or	a,l
	jr	Z,00108$
;obj_rocket.c:115: GameObjBat_SetState(pBatCandidateForKill, DYING);
	ld	a,#0x01
	push	af
	inc	sp
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_GameObjBat_SetState
	pop	af
	inc	sp
00108$:
	ld	sp,ix
	pop	ix
	ret
_GameObjRocket_CheckCollision_end::
;obj_rocket.c:129: void GameObjRocket_Draw(GameObjRocket* this)
;	---------------------------------
; Function GameObjRocket_Draw
; ---------------------------------
_GameObjRocket_Draw_start::
_GameObjRocket_Draw:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_rocket.c:131: this;
	pop	ix
	ret
_GameObjRocket_Draw_end::
;obj_rocket.c:152: void GameObjRocket_AllocateAnimationObj(GameObjRocket* this)
;	---------------------------------
; Function GameObjRocket_AllocateAnimationObj
; ---------------------------------
_GameObjRocket_AllocateAnimationObj_start::
_GameObjRocket_AllocateAnimationObj:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-13
	add	hl,sp
	ld	sp,hl
;obj_rocket.c:161: } ownAnimObj[] = { {&this->animObj}, {&this->animObj1}, /*{&this->animObj2}*/
	ld	hl,#0x0006
	add	hl,sp
	ex	de,hl
	ld	a,4 (ix)
	ld	-11 (ix),a
	ld	a,5 (ix)
	ld	-10 (ix),a
	ld	a,-11 (ix)
	add	a,#0x17
	ld	c,a
	ld	a,-10 (ix)
	adc	a,#0x00
	ld	b,a
	ex	de,hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
	ld	hl,#0x0006
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	hl,#0x0002
	add	hl,bc
	ld	-9 (ix),l
	ld	-8 (ix),h
	ld	a,-11 (ix)
	add	a,#0x19
	ld	e,a
	ld	a,-10 (ix)
	adc	a,#0x00
	ld	d,a
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_rocket.c:164: pConst = g_ownAnimObjConst;
;obj_rocket.c:165: for(i=0; i<sizeof(ownAnimObj)/sizeof(ownAnimObj[0]); i++) {
	ld	a,-11 (ix)
	add	a,#0x23
	ld	-9 (ix),a
	ld	a,-10 (ix)
	adc	a,#0x00
	ld	-8 (ix),a
	ld	-11 (ix),#<_g_ownAnimObjConst
	ld	-10 (ix),#>_g_ownAnimObjConst
	ld	-3 (ix),#0x00
00105$:
	ld	a,-3 (ix)
	sub	a,#0x02
	jp	NC,00109$
;obj_rocket.c:166: obj = PoolGameObj_AllocateGameObjAnim();
	push	bc
	call	_PoolGameObj_AllocateGameObjAnim
	ex	de,hl
	pop	bc
	ld	-2 (ix),e
	ld	-1 (ix),d
;obj_rocket.c:167: p = ownAnimObj[i].ptr;
	ld	a,-3 (ix)
	add	a,a
	add	a,c
	ld	l,a
	ld	a,b
	adc	a,#0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	de
	pop	iy
;obj_rocket.c:168: *p = obj;
	ld	a,-2 (ix)
	ld	0 (iy),a
	ld	a,-1 (ix)
	ld	1 (iy),a
;obj_rocket.c:171: if(obj) {
	ld	a,-2 (ix)
	or	a,-1 (ix)
	jp	Z,00104$
;obj_rocket.c:172: GameObjAnim_Init(obj, 0, SPRITE_Y_OFFSCREEN);         // initialy put offscreen
	push	bc
	ld	hl,#0x0100
	push	hl
	ld	h, #0x00
	push	hl
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_GameObjAnim_Init
	pop	af
	pop	af
	pop	af
	pop	bc
;obj_rocket.c:173: obj->spr_anim_time      = pConst->spr_anim_time;
	ld	a,-2 (ix)
	add	a,#0x17
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	l,-11 (ix)
	ld	h,-10 (ix)
	ld	a,(hl)
	ld	(de),a
;obj_rocket.c:174: obj->spr_anim_frames    = pConst->spr_anim_frames;
	ld	a,-2 (ix)
	add	a,#0x18
	ld	-13 (ix),a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	-12 (ix),a
	ld	e,-11 (ix)
	ld	d,-10 (ix)
	inc	de
	ld	a,(de)
	ld	l,-13 (ix)
	ld	h,-12 (ix)
	ld	(hl),a
;obj_rocket.c:175: obj->spr_count          = pConst->spr_count;
	ld	a,-2 (ix)
	add	a,#0x19
	ld	-13 (ix),a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	-12 (ix),a
	ld	e,-11 (ix)
	ld	d,-10 (ix)
	inc	de
	inc	de
	ld	a,(de)
	ld	l,-13 (ix)
	ld	h,-12 (ix)
	ld	(hl),a
;obj_rocket.c:176: obj->spr_height         = pConst->spr_height;
	ld	a,-2 (ix)
	add	a,#0x1A
	ld	-13 (ix),a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	-12 (ix),a
	ld	a,-11 (ix)
	add	a,#0x03
	ld	e,a
	ld	a,-10 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,(de)
	ld	l,-13 (ix)
	ld	h,-12 (ix)
	ld	(hl),a
;obj_rocket.c:177: obj->spr_def_start      = pConst->spr_def_start;
	ld	a,-2 (ix)
	add	a,#0x1B
	ld	-13 (ix),a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	-12 (ix),a
	ld	a,-11 (ix)
	add	a,#0x04
	ld	l, a
	ld	a, -10 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	l,-13 (ix)
	ld	h,-12 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_rocket.c:178: obj->spr_def_pitch      = pConst->spr_def_pitch;
	ld	a,-2 (ix)
	add	a,#0x1D
	ld	-13 (ix),a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	-12 (ix),a
	ld	a,-11 (ix)
	add	a,#0x06
	ld	e,a
	ld	a,-10 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,(de)
	ld	l,-13 (ix)
	ld	h,-12 (ix)
	ld	(hl),a
;obj_rocket.c:179: GameObjAnim_EnableAnimation(obj,TRUE);
	push	bc
	ld	a,#0x01
	push	af
	inc	sp
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_GameObjAnim_EnableAnimation
	pop	af
	inc	sp
	pop	bc
;obj_rocket.c:181: if(this->isMovingToTheRight){
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	ld	a,(hl)
	or	a,a
	jr	Z,00104$
;obj_rocket.c:182: obj->is_Xflip = TRUE;
	ld	a,-2 (ix)
	add	a,#0x1E
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,#0x01
	ld	(de),a
00104$:
;obj_rocket.c:186: pConst++;
	ld	a,-11 (ix)
	add	a,#0x07
	ld	-11 (ix),a
	ld	a,-10 (ix)
	adc	a,#0x00
	ld	-10 (ix),a
;obj_rocket.c:165: for(i=0; i<sizeof(ownAnimObj)/sizeof(ownAnimObj[0]); i++) {
	inc	-3 (ix)
	jp	00105$
00109$:
	ld	sp,ix
	pop	ix
	ret
_GameObjRocket_AllocateAnimationObj_end::
_g_ownAnimObjConst:
	.db #0x0C
	.db #0x03
	.db #0x01
	.db #0x01
	.dw #0x007A
	.db #0x00
	.db #0x32
	.db #0x01
	.db #0x01
	.db #0x01
	.dw #0x0079
	.db #0x00
;obj_rocket.c:192: void GameObjRocket_Free(GameObjRocket* this)
;	---------------------------------
; Function GameObjRocket_Free
; ---------------------------------
_GameObjRocket_Free_start::
_GameObjRocket_Free:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_rocket.c:195: PoolGameObj_FreeGameObj( (GameObj*)this->animObj );
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	bc
	push	de
	call	_PoolGameObj_FreeGameObj
	pop	af
	pop	bc
;obj_rocket.c:196: PoolGameObj_FreeGameObj( (GameObj*)this->animObj1 );
	ld	hl,#0x0019
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	bc
	push	de
	call	_PoolGameObj_FreeGameObj
	pop	af
	pop	bc
;obj_rocket.c:199: PoolGameObj_FreeGameObj( (GameObj*)this );
	push	bc
	call	_PoolGameObj_FreeGameObj
	pop	af
	pop	ix
	ret
_GameObjRocket_Free_end::
;obj_bat.c:1: void GameObjBat_Init(GameObjBat* this, int x, int y)
;	---------------------------------
; Function GameObjBat_Init
; ---------------------------------
_GameObjBat_Init_start::
_GameObjBat_Init:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_bat.c:4: GameObj_Init((GameObj*)this);
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	call	_GameObj_Init
	pop	af
;obj_bat.c:6: this->gobj.pMoveFunc = &GameObjBat_Move;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0013
	add	hl,bc
	ld	e,l
	ld	(hl),#<_GameObjBat_Move
	inc	hl
	ld	(hl),#>_GameObjBat_Move
;obj_bat.c:7: this->gobj.pDrawFunc = &GameObjBat_Draw;
	ld	hl,#0x0015
	add	hl,bc
	ld	e,l
	ld	(hl),#<_GameObjBat_Draw
	inc	hl
	ld	(hl),#>_GameObjBat_Draw
;obj_bat.c:9: this->gobj.x = x;
	ld	l,c
	ld	h,b
	inc	hl
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
;obj_bat.c:10: this->gobj.y = y;
	ld	hl,#0x0003
	add	hl,bc
	ld	a,8 (ix)
	ld	(hl),a
	inc	hl
	ld	a,9 (ix)
	ld	(hl),a
;obj_bat.c:11: this->gobj.width  = BAT_WIDTH;
	ld	hl,#0x0005
	add	hl,bc
	ld	(hl),#0x08
	inc	hl
	ld	(hl),#0x00
;obj_bat.c:12: this->gobj.height = BAT_HEIGHT;
	ld	hl,#0x0007
	add	hl,bc
	ld	(hl),#0x20
	inc	hl
	ld	(hl),#0x00
;obj_bat.c:13: GameObj_InitCollideBox((GameObj*)this);
	ld	e,c
	ld	d,b
	push	bc
	push	de
	call	_GameObj_InitCollideBox
	pop	af
	pop	bc
;obj_bat.c:15: this->state = NORMAL;
	ld	hl,#0x0017
	add	hl,bc
	ex	de,hl
	ld	a,#0x00
	ld	(de),a
;obj_bat.c:16: this->max_dying_time = 250;
	ld	hl,#0x0018
	add	hl,bc
	ex	de,hl
	ld	a,#0xFA
	ld	(de),a
;obj_bat.c:17: this->dying_time = 0;
	ld	hl,#0x0019
	add	hl,bc
	ex	de,hl
	ld	a,#0x00
	ld	(de),a
;obj_bat.c:18: this->rocket_creation_time = 0;
	ld	hl,#0x001A
	add	hl,bc
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;obj_bat.c:19: this->rocket = NULL;
	ld	hl,#0x001C
	add	hl,bc
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;obj_bat.c:21: this->pScore = (x < SCREEN_WIDTH/2) ? &scoreA : &scoreB;
	ld	hl,#0x001E
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,6 (ix)
	sub	a,#0xB8
	ld	a,7 (ix)
	sbc	a,#0x00
	jp	P,00103$
	ld	hl,#_scoreA
	ex	de,hl
	jr	00104$
00103$:
	ld	hl,#_scoreB
	ex	de,hl
00104$:
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
	pop	ix
	ret
_GameObjBat_Init_end::
;obj_bat.c:24: void GameObjBat_SetState(GameObjBat* this, ObjState state)
;	---------------------------------
; Function GameObjBat_SetState
; ---------------------------------
_GameObjBat_SetState_start::
_GameObjBat_SetState:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;obj_bat.c:31: if(state == this->state)
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ld	-4 (ix),l
	ld	-3 (ix),h
	ld	e,(hl)
	ld	a,6 (ix)
	sub	e
	jr	NZ,00102$
;obj_bat.c:32: return;
	jp	00107$
00102$:
;obj_bat.c:33: this->state = state;
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	a,6 (ix)
	ld	(hl),a
;obj_bat.c:35: if(this->state == DYING) {
	ld	a,6 (ix)
	sub	a,#0x01
	jp	NZ,00107$
;obj_bat.c:39: obj = PoolGameObj_AllocateGameObjAnim();
	push	bc
	call	_PoolGameObj_AllocateGameObjAnim
	ex	de,hl
	pop	bc
	ld	-2 (ix),e
	ld	-1 (ix),d
;obj_bat.c:44: if(obj) {
	ld	a,-2 (ix)
	or	a,-1 (ix)
	jp	Z,00104$
;obj_bat.c:45: x = this->gobj.x;
	ld	l,c
	ld	h,b
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
;obj_bat.c:46: x > SCREEN_WIDTH/2 ? ( x -= 12) : (x -= 4);
	ld	a,#0xB8
	sub	a,e
	ld	a,#0x00
	sbc	a,d
	jr	NC,00109$
	ld	a,e
	add	a,#0xF4
	ld	e,a
	ld	a,d
	adc	a,#0xFF
	ld	d,a
	jr	00110$
00109$:
	ld	a,e
	add	a,#0xFC
	ld	e,a
	ld	a,d
	adc	a,#0xFF
	ld	d,a
00110$:
;obj_bat.c:48: GameObjAnim_Init(obj, x/*(this->xcoordinate - 4)*/ /*+i*16*/, this->gobj.y /*+i*8*/);
	ld	l,c
	ld	h,b
	inc	hl
	inc	hl
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	push	bc
	push	de
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_GameObjAnim_Init
	pop	af
	pop	af
	pop	af
;obj_bat.c:49: obj->spr_anim_time      = 50;   //-(i*10);
	ld	a,-2 (ix)
	add	a,#0x17
	ld	c,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	b,a
	ld	a,#0x32
	ld	(bc),a
;obj_bat.c:50: obj->spr_anim_frames    = 7;
	ld	a,-2 (ix)
	add	a,#0x18
	ld	c,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	b,a
	ld	a,#0x07
	ld	(bc),a
;obj_bat.c:51: obj->spr_count          = 2;
	ld	a,-2 (ix)
	add	a,#0x19
	ld	c,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	b,a
	ld	a,#0x02
	ld	(bc),a
;obj_bat.c:52: obj->spr_height         = 2;
	ld	a,-2 (ix)
	add	a,#0x1A
	ld	c,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	b,a
	ld	a,#0x02
	ld	(bc),a
;obj_bat.c:53: obj->spr_def_start      = SPRITE_DEF_NUM_BANG1;
	ld	a,-2 (ix)
	add	a,#0x1B
	ld	l, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h,a
	ld	(hl),#0x15
	inc	hl
	ld	(hl),#0x00
;obj_bat.c:54: obj->spr_def_pitch      = 7*2;
	ld	a,-2 (ix)
	add	a,#0x1D
	ld	c,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	b,a
	ld	a,#0x0E
	ld	(bc),a
;obj_bat.c:55: obj->isLoopAnim         = FALSE;
	ld	a,-2 (ix)
	add	a,#0x24
	ld	c,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	b,a
	ld	a,#0x00
	ld	(bc),a
;obj_bat.c:56: GameObjAnim_EnableAnimation(obj,TRUE);
	ld	a,#0x01
	push	af
	inc	sp
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_GameObjAnim_EnableAnimation
	pop	af
	inc	sp
00104$:
;obj_bat.c:61: Sound_NewFx(SOUND_FX_SPLASH);
	ld	a,#0x0C
	push	af
	inc	sp
	call	_Sound_NewFx
	inc	sp
00107$:
	ld	sp,ix
	pop	ix
	ret
_GameObjBat_SetState_end::
;obj_bat.c:66: void GameObjBat_Move(GameObjBat* this)
;	---------------------------------
; Function GameObjBat_Move
; ---------------------------------
_GameObjBat_Move_start::
_GameObjBat_Move:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_bat.c:68: GameObjBat_state_handler(this);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_GameObjBat_state_handler
	pop	af
	pop	ix
	ret
_GameObjBat_Move_end::
;obj_bat.c:71: void GameObjBat_MoveUp(GameObjBat* this)
;	---------------------------------
; Function GameObjBat_MoveUp
; ---------------------------------
_GameObjBat_MoveUp_start::
_GameObjBat_MoveUp:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_bat.c:74: if(this->state != NORMAL)
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ld	a,(hl)
	or	a,a
;obj_bat.c:75: return;
	jr	NZ,00105$
;obj_bat.c:78: if (this->gobj.y > 0) // Move only when bat is not touching the top so it doesnt jump out of screen.
	inc	bc
	inc	bc
	inc	bc
	ld	l,c
	ld	h,b
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,#0x00
	sub	a,e
	ld	a,#0x00
	sbc	a,d
	jp	P,00105$
;obj_bat.c:81: this->gobj.y --;
	dec	de
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
00105$:
	pop	ix
	ret
_GameObjBat_MoveUp_end::
;obj_bat.c:89: void GameObjBat_MoveDown(GameObjBat* this)
;	---------------------------------
; Function GameObjBat_MoveDown
; ---------------------------------
_GameObjBat_MoveDown_start::
_GameObjBat_MoveDown:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;obj_bat.c:92: if(this->state != NORMAL)
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ld	a,(hl)
	or	a,a
;obj_bat.c:93: return;
	jr	NZ,00105$
;obj_bat.c:95: if (this->gobj.y + this->gobj.height < GAME_FIELD_MAX_SCREEN_Y) // Make sure bat doesnot go below the screen.
	ld	hl,#0x0003
	add	hl,bc
	ld	e,l
	ld	d,h
	ld	a,(hl)
	ld	-2 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-1 (ix),a
	ld	hl,#0x0007
	add	hl,bc
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,-2 (ix)
	add	a,c
	ld	c,a
	ld	a,-1 (ix)
	adc	a,b
	ld	b,a
	ld	a,c
	sub	a,#0xF0
	ld	a,b
	sbc	a,#0x00
	jp	P,00105$
;obj_bat.c:98: this->gobj.y ++;
	ld	c,-2 (ix)
	ld	b,-1 (ix)
	inc	bc
	ex	de,hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
00105$:
	ld	sp,ix
	pop	ix
	ret
_GameObjBat_MoveDown_end::
;obj_bat.c:105: void GameObjBat_Draw(GameObjBat* this)
;	---------------------------------
; Function GameObjBat_Draw
; ---------------------------------
_GameObjBat_Draw_start::
_GameObjBat_Draw:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;obj_bat.c:108: this->gobj.x + this->gobj.width, this->gobj.y + this->gobj.height);
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0003
	add	hl,bc
	ld	a,(hl)
	ld	-2 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-1 (ix),a
	ld	hl,#0x0007
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-2 (ix)
	add	a,e
	ld	-4 (ix),a
	ld	a,-1 (ix)
	adc	a,d
	ld	-3 (ix),a
	ld	l,c
	ld	h,b
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	l,c
	ld	h,b
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,e
	add	a,c
	ld	c,a
	ld	a,d
	adc	a,b
	ld	b,a
;obj_bat.c:107: DrawBat (this->gobj.x, this->gobj.y,
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	push	bc
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	push	de
	call	_DrawBat
	pop	af
	pop	af
	pop	af
	pop	af
	ld	sp,ix
	pop	ix
	ret
_GameObjBat_Draw_end::
;obj_bat.c:112: void GameObjBat_Fire(GameObjBat* this)
;	---------------------------------
; Function GameObjBat_Fire
; ---------------------------------
_GameObjBat_Fire_start::
_GameObjBat_Fire:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;obj_bat.c:118: if(this->state != NORMAL)
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ld	a,(hl)
	or	a,a
;obj_bat.c:119: return;
	jp	NZ,00107$
;obj_bat.c:128: if(GameObjBat_IsCanFireWithRocket(this)) {
	push	bc
	push	bc
	call	_GameObjBat_IsCanFireWithRocket
	pop	af
	ld	e,l
	pop	bc
	xor	a,a
	or	a,e
	jp	Z,00107$
;obj_bat.c:130: new_obj = PoolGameObj_AllocateGameObjRocket();
	push	bc
	call	_PoolGameObj_AllocateGameObjRocket
	ex	de,hl
	pop	bc
	ld	-2 (ix),e
	ld	-1 (ix),d
;obj_bat.c:131: if(new_obj){
	ld	a,-2 (ix)
	or	a,-1 (ix)
	jp	Z,00104$
;obj_bat.c:132: GameObjRocket_Init(new_obj, this->gobj.x, this->gobj.y);
	ld	hl,#0x0003
	add	hl,bc
	ld	a,(hl)
	ld	-4 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-3 (ix),a
	ld	l,c
	ld	h,b
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	bc
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	push	de
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_GameObjRocket_Init
	pop	af
	pop	af
	pop	af
	pop	bc
;obj_bat.c:134: new_obj->gobj.extra_field1 = (word) this;
	ld	a,-2 (ix)
	add	a,#0x11
	ld	-4 (ix),a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	-3 (ix),a
	ld	e,4 (ix)
	ld	d,5 (ix)
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_bat.c:136: this->rocket = new_obj;
	ld	hl,#0x001C
	add	hl,bc
	ld	a,-2 (ix)
	ld	(hl),a
	inc	hl
	ld	a,-1 (ix)
	ld	(hl),a
00104$:
;obj_bat.c:139: this->pScore->num_rockets--;
	ld	hl,#0x001E
	add	hl,bc
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	hl,#0x0022
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,(bc)
	dec	a
	ld	(bc),a
;obj_bat.c:140: Sound_NewFx(SOUND_FX_ROCKET);
	ld	a,#0x0B
	push	af
	inc	sp
	call	_Sound_NewFx
	inc	sp
00107$:
	ld	sp,ix
	pop	ix
	ret
_GameObjBat_Fire_end::
;obj_bat.c:150: BOOL GameObjBat_IsCanFireWithRocket(GameObjBat* this)
;	---------------------------------
; Function GameObjBat_IsCanFireWithRocket
; ---------------------------------
_GameObjBat_IsCanFireWithRocket_start::
_GameObjBat_IsCanFireWithRocket:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;obj_bat.c:154: if(!this->rocket) {
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x001C
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,e
	or	a,d
	jr	NZ,00106$
;obj_bat.c:155: isCanFire = TRUE;
	ld	e,#0x01
	jr	00107$
00106$:
;obj_bat.c:158: if(GameObj_GetInUse((GameObj*)this->rocket) && (GameObjBat*)this->rocket->gobj.extra_field1 == this)
	push	bc
	push	de
	call	_GameObj_GetInUse
	pop	af
	ld	e,l
	pop	bc
	xor	a,a
	or	a,e
	jr	Z,00102$
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	hl,#0x0011
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,e
	sub	c
	jr	NZ,00116$
	ld	a,d
	sub	b
	jr	Z,00117$
00116$:
	jr	00102$
00117$:
;obj_bat.c:159: isCanFire = FALSE;
	ld	e,#0x00
	jr	00107$
00102$:
;obj_bat.c:161: isCanFire = TRUE;
	ld	e,#0x01
00107$:
;obj_bat.c:165: if(this->pScore->num_rockets == 0)
	ld	hl,#0x001E
	add	hl,bc
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	hl,#0x0022
	add	hl,bc
	ld	a,(hl)
;obj_bat.c:166: isCanFire = FALSE;
	or	a,a
	jr	NZ,00109$
	ld	e,a
00109$:
;obj_bat.c:169: return isCanFire;
	ld	l,e
	ld	sp,ix
	pop	ix
	ret
_GameObjBat_IsCanFireWithRocket_end::
;obj_bat.c:172: void GameObjBat_state_handler(GameObjBat* this)
;	---------------------------------
; Function GameObjBat_state_handler
; ---------------------------------
_GameObjBat_state_handler_start::
_GameObjBat_state_handler:
	push	ix
	ld	ix,#0
	add	ix,sp
	dec	sp
;obj_bat.c:174: if(this->state == DYING) {
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ld	a,(hl)
	sub	a,#0x01
	jr	NZ,00105$
;obj_bat.c:175: if(this->dying_time++ >= this->max_dying_time)
	ld	hl,#0x0019
	add	hl,bc
	ex	de,hl
	ld	a,(de)
	ld	-1 (ix),a
	inc	a
	ld	(de),a
	ld	hl,#0x0018
	add	hl,bc
	ld	a,-1 (ix)
	sub	a,(hl)
	jr	C,00105$
;obj_bat.c:176: GameObjBat_SetState(this, DIE);
	ld	a,#0x02
	push	af
	inc	sp
	push	bc
	call	_GameObjBat_SetState
	pop	af
	inc	sp
00105$:
	ld	sp,ix
	pop	ix
	ret
_GameObjBat_state_handler_end::
;obj_ball.c:10: void GameObjBall_Init(GameObjBall* this)
;	---------------------------------
; Function GameObjBall_Init
; ---------------------------------
_GameObjBall_Init_start::
_GameObjBall_Init:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;obj_ball.c:14: GameObj_Init((GameObj*)this);
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	call	_GameObj_Init
	pop	af
;obj_ball.c:16: GameObjBall_SetState(this, NORMAL);
	ld	a,#0x00
	push	af
	inc	sp
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_GameObjBall_SetState
	pop	af
	inc	sp
;obj_ball.c:18: this->max_dying_time = 50;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x001E
	add	hl,bc
	ex	de,hl
	ld	a,#0x32
	ld	(de),a
;obj_ball.c:19: this->dying_time = 0;
	ld	hl,#0x001F
	add	hl,bc
	ex	de,hl
	ld	a,#0x00
	ld	(de),a
;obj_ball.c:21: this->radius = 3;
	ld	hl,#0x0017
	add	hl,bc
	ld	(hl),#0x03
	inc	hl
	ld	(hl),#0x00
;obj_ball.c:22: this->speedx = 2;
	ld	hl,#0x0019
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	(hl),#0x02
	inc	hl
	ld	(hl),#0x00
;obj_ball.c:23: srand((int) GetR()*256 + (~GetR()) ); // Seed rand a random number
	push	bc
	call	_GetR
	ld	e,l
	pop	bc
	ld	-3 (ix),e
	ld	-4 (ix),#0x00
	push	bc
	call	_GetR
	ld	e,l
	pop	bc
	ld	d,#0x00
	ld	a,e
	cpl
	ld	e,a
	ld	a,d
	cpl
	ld	d,a
	ld	a,-4 (ix)
	add	a,e
	ld	e,a
	ld	a,-3 (ix)
	adc	a,d
	ld	d,a
	push	bc
	push	de
	call	_srand
	pop	af
	pop	bc
;obj_ball.c:24: this->speedy = rand ()%1;// Sets speed from 0 to 2 depending upon remainder.
	ld	hl,#0x001B
	add	hl,bc
	ld	-4 (ix),l
	ld	-3 (ix),h
	push	bc
	call	_rand
	ex	de,hl
	pop	bc
	push	bc
	ld	hl,#0x0001
	push	hl
	push	de
	call	__modsint_rrx_s
	pop	af
	pop	af
	ex	de,hl
	pop	bc
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_ball.c:25: if (rand() % 2 == 0)
	push	bc
	call	_rand
	ex	de,hl
	pop	bc
	push	bc
	ld	hl,#0x0002
	push	hl
	push	de
	call	__modsint_rrx_s
	pop	af
	pop	af
	ex	de,hl
	pop	bc
	ld	a,e
	or	a,d
	jr	NZ,00102$
;obj_ball.c:27: this->speedx = - this->speedx; // Generate Random X direction.
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	xor	a,a
	sbc	a,e
	ld	e,a
	ld	a,#0x00
	sbc	a,d
	ld	d,a
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_ball.c:28: this->speedy = - this->speedy; // Generate Random Y direction.
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	xor	a,a
	sbc	a,e
	ld	e,a
	ld	a,#0x00
	sbc	a,d
	ld	d,a
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
00102$:
;obj_ball.c:31: this->gobj.x = 320/2;
	ld	l,c
	ld	h,b
	inc	hl
	ld	(hl),#0xA0
	inc	hl
	ld	(hl),#0x00
;obj_ball.c:32: this->gobj.y = 250/2;
	ld	hl,#0x0003
	add	hl,bc
	ld	(hl),#0x7D
	inc	hl
	ld	(hl),#0x00
;obj_ball.c:34: this->gobj.pMoveFunc = &GameObjBall_Move;
	ld	hl,#0x0013
	add	hl,bc
	ld	e,l
	ld	(hl),#<_GameObjBall_Move
	inc	hl
	ld	(hl),#>_GameObjBall_Move
;obj_ball.c:35: this->gobj.pDrawFunc = &GameObjBall_Draw;
	ld	hl,#0x0015
	add	hl,bc
	ld	e,l
	ld	d,h
	ld	(hl),#<_GameObjBall_Draw
	inc	hl
	ld	(hl),#>_GameObjBall_Draw
;obj_ball.c:39: this->gobj.col_x_offset = this->gobj.col_y_offset = this->gobj.col_width = this->gobj.col_height = 0;
	ld	hl,#0x000D
	add	hl,bc
	ld	-4 (ix),l
	ld	-3 (ix),h
	ld	hl,#0x000F
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	hl,#0x0009
	add	hl,bc
	ex	de,hl
	ld	hl,#0x000B
	add	hl,bc
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	ex	de,hl
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
	ld	sp,ix
	pop	ix
	ret
_GameObjBall_Init_end::
;obj_ball.c:42: void GameObjBall_SetState(GameObjBall* this, ObjState state)
;	---------------------------------
; Function GameObjBall_SetState
; ---------------------------------
_GameObjBall_SetState_start::
_GameObjBall_SetState:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_ball.c:44: if(state == this->state)
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x001D
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,(bc)
	ld	e,a
	ld	a,6 (ix)
	sub	e
	jr	NZ,00102$
;obj_ball.c:45: return;
	jp	00111$
00102$:
;obj_ball.c:46: this->state = state;
	ld	a,6 (ix)
	ld	(bc),a
;obj_ball.c:48: if(state == DIE){
	ld	a,6 (ix)
	sub	a,#0x02
	jp	NZ,00108$
;obj_ball.c:49: if(scoreA.score >= MAX_SCORE_FOR_LEVEL) {
	ld	hl, #_scoreA + 24
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,c
	sub	a,#0x0A
	ld	a,b
	sbc	a,#0x00
	jp	M,00104$
;obj_ball.c:50: GameObjBat_SetState(&batB, DYING);
	ld	a,#0x01
	push	af
	inc	sp
	ld	hl,#_batB
	push	hl
	call	_GameObjBat_SetState
	pop	af
	inc	sp
00104$:
;obj_ball.c:53: if(scoreB.score >= MAX_SCORE_FOR_LEVEL) {
	ld	hl, #_scoreB + 24
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,c
	sub	a,#0x0A
	ld	a,b
	sbc	a,#0x00
	jp	M,00106$
;obj_ball.c:54: GameObjBat_SetState(&batA, DYING);
	ld	a,#0x01
	push	af
	inc	sp
	ld	hl,#_batA
	push	hl
	call	_GameObjBat_SetState
	pop	af
	inc	sp
00106$:
;obj_ball.c:58: GameObjScore_SetState(game.pScore_to_blink, BLINKING);
	ld	hl, #_game + 10
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,#0x03
	push	af
	inc	sp
	push	bc
	call	_GameObjScore_SetState
	pop	af
	inc	sp
00108$:
;obj_ball.c:61: if(state == DYING) {
	ld	a,6 (ix)
	sub	a,#0x01
	jr	NZ,00111$
;obj_ball.c:62: Sound_NewFx(SOUND_FX_CRUNCH);
	ld	a,#0x04
	push	af
	inc	sp
	call	_Sound_NewFx
	inc	sp
00111$:
	pop	ix
	ret
_GameObjBall_SetState_end::
;obj_ball.c:67: void GameObjBall_Move(GameObjBall* this)
;	---------------------------------
; Function GameObjBall_Move
; ---------------------------------
_GameObjBall_Move_start::
_GameObjBall_Move:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-11
	add	hl,sp
	ld	sp,hl
;obj_ball.c:69: if(this->state == DYING) {
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x001D
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	a,(hl)
	sub	a,#0x01
	jr	NZ,00104$
;obj_ball.c:70: if(this->dying_time++ >= this->max_dying_time)
	ld	hl,#0x001F
	add	hl,bc
	ex	de,hl
	ld	a,(de)
	ld	-5 (ix),a
	inc	a
	ld	(de),a
	ld	hl,#0x001E
	add	hl,bc
	ld	a,-5 (ix)
	sub	a,(hl)
	jr	C,00104$
;obj_ball.c:71: GameObjBall_SetState(this, DIE);
	push	bc
	ld	a,#0x02
	push	af
	inc	sp
	push	bc
	call	_GameObjBall_SetState
	pop	af
	inc	sp
	pop	bc
00104$:
;obj_ball.c:77: if(this->state != NORMAL)
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,(hl)
	or	a,a
;obj_ball.c:78: return;
	jp	NZ,00111$
;obj_ball.c:80: this->gobj.x += this->speedx;
	ld	hl,#0x0001
	add	hl,bc
	ld	-4 (ix),l
	ld	-3 (ix),h
	ld	a,(hl)
	ld	-2 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-1 (ix),a
	ld	hl,#0x0019
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-2 (ix)
	add	a,e
	ld	e,a
	ld	a,-1 (ix)
	adc	a,d
	ld	d,a
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_ball.c:81: this->gobj.y += this->speedy;
	ld	hl,#0x0003
	add	hl,bc
	ld	-4 (ix),l
	ld	-3 (ix),h
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	hl,#0x001B
	add	hl,bc
	ld	-2 (ix),l
	ld	-1 (ix),h
	ld	a,(hl)
	ld	-7 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-6 (ix),a
	ld	a,e
	add	a,-7 (ix)
	ld	-11 (ix),a
	ld	a,d
	adc	a,-6 (ix)
	ld	-10 (ix),a
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	a,-11 (ix)
	ld	(hl),a
	inc	hl
	ld	a,-10 (ix)
	ld	(hl),a
;obj_ball.c:83: if ( this->gobj.y - this->radius < 0 ) {
	ld	hl,#0x0017
	add	hl,bc
	ld	-9 (ix),l
	ld	-8 (ix),h
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-11 (ix)
	sub	a,e
	ld	e,a
	ld	a,-10 (ix)
	sbc	a,d
	ld	d,a
	bit	7,a
	jr	Z,00108$
;obj_ball.c:84: this->speedy = -this->speedy; // Reflect From Top
	xor	a,a
	sbc	a,-7 (ix)
	ld	e,a
	ld	a,#0x00
	sbc	a,-6 (ix)
	ld	d,a
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_ball.c:85: Sound_NewFx(SOUND_FX_BOUNCE);
	push	bc
	ld	a,#0x03
	push	af
	inc	sp
	call	_Sound_NewFx
	inc	sp
	pop	bc
00108$:
;obj_ball.c:87: if ( this->gobj.y + this->radius > GAME_FIELD_MAX_SCREEN_Y ) {
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	a,(hl)
	ld	-11 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-10 (ix),a
	ld	l,-9 (ix)
	ld	h,-8 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-11 (ix)
	add	a,e
	ld	e,a
	ld	a,-10 (ix)
	adc	a,d
	ld	d,a
	ld	a,#0xF0
	sub	a,e
	ld	a,#0x00
	sbc	a,d
	jp	P,00110$
;obj_ball.c:88: this->speedy = -this->speedy; // Reflect From Bottom
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	xor	a,a
	sbc	a,e
	ld	e,a
	ld	a,#0x00
	sbc	a,d
	ld	d,a
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_ball.c:89: Sound_NewFx(SOUND_FX_BOUNCE);
	push	bc
	ld	a,#0x03
	push	af
	inc	sp
	call	_Sound_NewFx
	inc	sp
	pop	bc
00110$:
;obj_ball.c:92: GameObjBall_CheckCollision(this);
	push	bc
	call	_GameObjBall_CheckCollision
	pop	af
00111$:
	ld	sp,ix
	pop	ix
	ret
_GameObjBall_Move_end::
;obj_ball.c:97: void GameObjBall_CheckCollision(GameObjBall* this)
;	---------------------------------
; Function GameObjBall_CheckCollision
; ---------------------------------
_GameObjBall_CheckCollision_start::
_GameObjBall_CheckCollision:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-8
	add	hl,sp
	ld	sp,hl
;obj_ball.c:99: if(this->state != NORMAL)
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x001D
	add	hl,bc
	ld	a,(hl)
	or	a,a
;obj_ball.c:100: return;
	jp	NZ,00121$
;obj_ball.c:102: if ( this->gobj.x - this->radius <= GAME_FIELD_X_BORDER)
	ld	l,c
	ld	h,b
	inc	hl
	ld	a,(hl)
	ld	-2 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-1 (ix),a
	ld	hl,#0x0017
	add	hl,bc
	ld	a,(hl)
	ld	-4 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-3 (ix),a
	ld	a,-2 (ix)
	sub	a,-4 (ix)
	ld	e,a
	ld	a,-1 (ix)
	sbc	a,-3 (ix)
	ld	d,a
	ld	a,#0x0A
	sub	a,e
	ld	a,#0x00
	sbc	a,d
	jp	M,00111$
;obj_ball.c:104: if (this->gobj.y > batA.gobj.y && this->gobj.y < batA.gobj.y+batA.gobj.height && batA.state == NORMAL)
	ld	hl,#0x0003
	add	hl,bc
	ld	a,(hl)
	ld	-6 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-5 (ix),a
	ld	de,#_batA + 3
	ex	de,hl
	ld	a,(hl)
	ld	-8 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-7 (ix),a
	ld	a,-8 (ix)
	sub	a,-6 (ix)
	ld	a,-7 (ix)
	sbc	a,-5 (ix)
	jp	P,00106$
	ld	de,#_batA + 7
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-8 (ix)
	add	a,e
	ld	e,a
	ld	a,-7 (ix)
	adc	a,d
	ld	d,a
	ld	a,-6 (ix)
	sub	a,e
	ld	a,-5 (ix)
	sbc	a,d
	jp	P,00106$
	ld	de,#_batA + 23
	ld	a,(de)
	or	a,a
	jp	NZ,00106$
;obj_ball.c:106: this->speedx = - this->speedx;
	ld	hl,#0x0019
	add	hl,bc
	ld	-8 (ix),l
	ld	-7 (ix),h
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	xor	a,a
	sbc	a,e
	ld	e,a
	ld	a,#0x00
	sbc	a,d
	ld	d,a
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_ball.c:107: this->speedy = rand () % 3;// Sets speed from depending upon remainder.
	ld	hl,#0x001B
	add	hl,bc
	ld	-8 (ix),l
	ld	-7 (ix),h
	call	_rand
	ex	de,hl
	ld	hl,#0x0003
	push	hl
	push	de
	call	__modsint_rrx_s
	pop	af
	pop	af
	ex	de,hl
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_ball.c:108: if (rand() % 2 == 0) this->speedy = - this->speedy; // Generate Random Y direction.
	call	_rand
	ex	de,hl
	ld	hl,#0x0002
	push	hl
	push	de
	call	__modsint_rrx_s
	pop	af
	pop	af
	ld	d,h
	ld	a,l
	or	a,d
	jr	NZ,00104$
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	xor	a,a
	sbc	a,e
	ld	e,a
	ld	a,#0x00
	sbc	a,d
	ld	d,a
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
00104$:
;obj_ball.c:109: Sound_NewFx(SOUND_FX_BOUNCE);
	ld	a,#0x03
	push	af
	inc	sp
	call	_Sound_NewFx
	inc	sp
	jr	00107$
00106$:
;obj_ball.c:113: GameObjBall_SetState(this, DYING);
	ld	a,#0x01
	push	af
	inc	sp
	push	bc
	call	_GameObjBall_SetState
	pop	af
	inc	sp
;obj_ball.c:114: GameObjScore_SetScore(&scoreB, scoreB.score + 1);
	ld	de,#_scoreB + 24
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	de
	push	de
	ld	hl,#_scoreB
	push	hl
	call	_GameObjScore_SetScore
	pop	af
	pop	af
;obj_ball.c:115: game.pScore_to_blink = &scoreB;
	ld	de,#_game + 10
	ld	l,e
	ld	h,d
	ld	(hl),#<_scoreB
	inc	hl
	ld	(hl),#>_scoreB
00107$:
;obj_ball.c:117: return;
	jp	00121$
00111$:
;obj_ball.c:120: if ( this->gobj.x +  this->radius > SCREEN_WIDTH - GAME_FIELD_X_BORDER)
	ld	a,-2 (ix)
	add	a,-4 (ix)
	ld	e,a
	ld	a,-1 (ix)
	adc	a,-3 (ix)
	ld	d,a
	ld	a,#0x66
	sub	a,e
	ld	a,#0x01
	sbc	a,d
	jp	P,00121$
;obj_ball.c:123: if (this->gobj.y > batB.gobj.y && this->gobj.y < batB.gobj.y+batB.gobj.height && batB.state == NORMAL)
	ld	hl,#0x0003
	add	hl,bc
	ld	a,(hl)
	ld	-8 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-7 (ix),a
	ld	de,#_batB + 3
	ex	de,hl
	ld	a,(hl)
	ld	-6 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-5 (ix),a
	ld	a,-6 (ix)
	sub	a,-8 (ix)
	ld	a,-5 (ix)
	sbc	a,-7 (ix)
	jp	P,00115$
	ld	de,#_batB + 7
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-6 (ix)
	add	a,e
	ld	e,a
	ld	a,-5 (ix)
	adc	a,d
	ld	d,a
	ld	a,-8 (ix)
	sub	a,e
	ld	a,-7 (ix)
	sbc	a,d
	jp	P,00115$
	ld	de,#_batB + 23
	ld	a,(de)
	or	a,a
	jp	NZ,00115$
;obj_ball.c:125: this->speedx = - this->speedx;
	ld	hl,#0x0019
	add	hl,bc
	ld	-8 (ix),l
	ld	-7 (ix),h
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	xor	a,a
	sbc	a,e
	ld	e,a
	ld	a,#0x00
	sbc	a,d
	ld	d,a
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_ball.c:126: this->speedy = rand ()%3;// Sets speed from depending upon remainder.
	ld	hl,#0x001B
	add	hl,bc
	ld	-8 (ix),l
	ld	-7 (ix),h
	call	_rand
	ex	de,hl
	ld	hl,#0x0003
	push	hl
	push	de
	call	__modsint_rrx_s
	pop	af
	pop	af
	ex	de,hl
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
;obj_ball.c:127: if (rand() % 2 == 0) this->speedy = - this->speedy; // Generate Random Y direction.
	call	_rand
	ex	de,hl
	ld	hl,#0x0002
	push	hl
	push	de
	call	__modsint_rrx_s
	pop	af
	pop	af
	ld	d,h
	ld	a,l
	or	a,d
	jr	NZ,00113$
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	xor	a,a
	sbc	a,e
	ld	e,a
	ld	a,#0x00
	sbc	a,d
	ld	d,a
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
00113$:
;obj_ball.c:128: Sound_NewFx(SOUND_FX_BOUNCE);
	ld	a,#0x03
	push	af
	inc	sp
	call	_Sound_NewFx
	inc	sp
	jr	00116$
00115$:
;obj_ball.c:132: GameObjBall_SetState(this, DYING);
	ld	a,#0x01
	push	af
	inc	sp
	push	bc
	call	_GameObjBall_SetState
	pop	af
	inc	sp
;obj_ball.c:133: GameObjScore_SetScore(&scoreA, scoreA.score + 1);
	ld	hl, #_scoreA + 24
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	bc
	push	bc
	ld	hl,#_scoreA
	push	hl
	call	_GameObjScore_SetScore
	pop	af
	pop	af
;obj_ball.c:134: game.pScore_to_blink = &scoreA;
	ld	bc,#_game + 10
	ld	l,c
	ld	h,b
	ld	(hl),#<_scoreA
	inc	hl
	ld	(hl),#>_scoreA
00116$:
;obj_ball.c:136: return;
00121$:
	ld	sp,ix
	pop	ix
	ret
_GameObjBall_CheckCollision_end::
;obj_ball.c:141: void GameObjBall_Draw(GameObjBall* this)
;	---------------------------------
; Function GameObjBall_Draw
; ---------------------------------
_GameObjBall_Draw_start::
_GameObjBall_Draw:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;obj_ball.c:143: DrawBall (this->gobj.x, this->gobj.y, this->radius, this->radius);
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ld	a,(hl)
	ld	-2 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-1 (ix),a
	ld	hl,#0x0003
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	l,c
	ld	h,b
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	push	de
	push	bc
	call	_DrawBall
	pop	af
	pop	af
	pop	af
	pop	af
	ld	sp,ix
	pop	ix
	ret
_GameObjBall_Draw_end::
;obj_youwin.c:1: void GameObjYouWin_Init(GameObjYouWin* this, int x, int y)
;	---------------------------------
; Function GameObjYouWin_Init
; ---------------------------------
_GameObjYouWin_Init_start::
_GameObjYouWin_Init:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_youwin.c:4: GameObj_Init((GameObj*)this);
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	call	_GameObj_Init
	pop	af
;obj_youwin.c:6: this->gobj.x = x;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	l,c
	ld	h,b
	inc	hl
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
;obj_youwin.c:7: this->gobj.y = y;
	ld	hl,#0x0003
	add	hl,bc
	ld	a,8 (ix)
	ld	(hl),a
	inc	hl
	ld	a,9 (ix)
	ld	(hl),a
;obj_youwin.c:8: this->gobj.width  = 16*2;
	ld	hl,#0x0005
	add	hl,bc
	ld	(hl),#0x20
	inc	hl
	ld	(hl),#0x00
;obj_youwin.c:9: this->gobj.height = 16;
	ld	hl,#0x0007
	add	hl,bc
	ld	(hl),#0x10
	inc	hl
	ld	(hl),#0x00
;obj_youwin.c:11: this->state = NORMAL;
	ld	hl,#0x0017
	add	hl,bc
	ex	de,hl
	ld	a,#0x00
	ld	(de),a
;obj_youwin.c:12: this->angle = 0;
	ld	hl,#0x0026
	add	hl,bc
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;obj_youwin.c:13: this->lifeTime = 0;
	ld	hl,#0x0028
	add	hl,bc
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;obj_youwin.c:18: this->gobj.pMoveFunc = &GameObjYouWin_Move;
	ld	hl,#0x0013
	add	hl,bc
	ld	e,l
	ld	(hl),#<_GameObjYouWin_Move
	inc	hl
	ld	(hl),#>_GameObjYouWin_Move
;obj_youwin.c:19: this->gobj.pDrawFunc = &GameObjYouWin_Draw;
	ld	hl,#0x0015
	add	hl,bc
	ld	e,l
	ld	(hl),#<_GameObjYouWin_Draw
	inc	hl
	ld	(hl),#>_GameObjYouWin_Draw
;obj_youwin.c:21: GameObjYouWin_AllocateAnimObjects(this);
	push	bc
	call	_GameObjYouWin_AllocateAnimObjects
	pop	af
	pop	ix
	ret
_GameObjYouWin_Init_end::
;obj_youwin.c:28: void GameObjYouWin_Move(GameObjYouWin* this)
;	---------------------------------
; Function GameObjYouWin_Move
; ---------------------------------
_GameObjYouWin_Move_start::
_GameObjYouWin_Move:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-20
	add	hl,sp
	ld	sp,hl
;obj_youwin.c:31: short x_center = this->gobj.x + SPR_YOUWIN_WIDTH*16/2;
	ld	a,4 (ix)
	ld	-16 (ix),a
	ld	a,5 (ix)
	ld	-15 (ix),a
	ld	e,-16 (ix)
	ld	d,-15 (ix)
	ex	de,hl
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	hl,#0x0030
	add	hl,de
	ld	-3 (ix),l
	ld	-2 (ix),h
;obj_youwin.c:32: short y_center = this->gobj.y + SPR_YOUWIN_HEIGHT*16/2;
	ld	a,-16 (ix)
	add	a,#0x03
	ld	l, a
	ld	a, -15 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	hl,#0x0040
	add	hl,de
	ld	-5 (ix),l
	ld	-4 (ix),h
;obj_youwin.c:33: byte angle = this->angle/256;   // get integer part of fixet point value
	ld	a,-16 (ix)
	add	a,#0x26
	ld	-10 (ix),a
	ld	a,-15 (ix)
	adc	a,#0x00
	ld	-9 (ix),a
	ld	l,-10 (ix)
	ld	h,-9 (ix)
	ld	a,(hl)
	ld	-12 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-11 (ix),a
	ld	e, a
	ld	d,#0x00
;math.c:60: mm__mult_index = angle;
	ld	iy,#_mm__mult_index
	ld	0 (iy),e
;math.c:61: mm__mult_write = n2;
	ld	iy,#_mm__mult_write
	ld	0 (iy),#0x4B
	ld	iy,#_mm__mult_write
	ld	1 (iy),#0x00
;math.c:62: return mm__mult_read;
	ld	bc,(_mm__mult_read)
;obj_youwin.c:36: radius = HW_SIN_MUL(angle, 75);
	ld	-6 (ix),c
;obj_youwin.c:38: for(i=0; i<NUM_EMERLADS; i++) {
	ld	a,-16 (ix)
	add	a,#0x18
	ld	-14 (ix),a
	ld	a,-15 (ix)
	adc	a,#0x00
	ld	-13 (ix),a
	ld	-1 (ix),#0x00
00107$:
	ld	a,-1 (ix)
	sub	a,#0x07
	jp	NC,00110$
;obj_youwin.c:39: this->emerlads[i]->gobj.x = x_center + HW_SIN_MUL(angle, radius) - 20/2;
	ld	a,-1 (ix)
	add	a,a
	ld	d,a
	ld	a,-14 (ix)
	add	a,d
	ld	d,a
	ld	a,-13 (ix)
	adc	a,#0x00
	ld	l,d
	ld	h,a
	ld	a,(hl)
	ld	-18 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-17 (ix),a
	ld	a,-18 (ix)
	add	a,#0x01
	ld	-20 (ix),a
	ld	a,-17 (ix)
	adc	a,#0x00
	ld	-19 (ix),a
	ld	a,-6 (ix)
	ld	-8 (ix),a
	ld	a,-6 (ix)
	rla	
	sbc	a,a
	ld	-7 (ix),a
	ld	c,-8 (ix)
	ld	b,-7 (ix)
;math.c:60: mm__mult_index = angle;
	ld	iy,#_mm__mult_index
	ld	0 (iy),e
;math.c:61: mm__mult_write = n2;
	ld	iy,#_mm__mult_write
	ld	0 (iy),c
	ld	iy,#_mm__mult_write
	ld	1 (iy),b
;math.c:62: return mm__mult_read;
	ld	bc,(_mm__mult_read)
;obj_youwin.c:39: this->emerlads[i]->gobj.x = x_center + HW_SIN_MUL(angle, radius) - 20/2;
	ld	a,-3 (ix)
	add	a,c
	ld	c,a
	ld	a,-2 (ix)
	adc	a,b
	ld	b,a
	ld	a,c
	add	a,#0xF6
	ld	c,a
	ld	a,b
	adc	a,#0xFF
	ld	b,a
	ld	l,-20 (ix)
	ld	h,-19 (ix)
	ld	(hl),c
	inc	hl
	ld	(hl),b
;obj_youwin.c:40: this->emerlads[i]->gobj.y = y_center + HW_SIN_MUL(angle+0x100/4, radius) - 16/2;
	ld	a,-18 (ix)
	add	a,#0x03
	ld	-20 (ix),a
	ld	a,-17 (ix)
	adc	a,#0x00
	ld	-19 (ix),a
	ld	hl,#_mm__mult_index
	ld	a,e
	add	a,#0x40
	ld	(hl),a
;math.c:61: mm__mult_write = n2;
	ld	a,-8 (ix)
	ld	iy,#_mm__mult_write
	ld	0 (iy),a
	ld	a,-7 (ix)
	ld	iy,#_mm__mult_write
	ld	1 (iy),a
;math.c:62: return mm__mult_read;
	ld	hl,(_mm__mult_read)
	ld	d,l
	ld	c,h
;obj_youwin.c:40: this->emerlads[i]->gobj.y = y_center + HW_SIN_MUL(angle+0x100/4, radius) - 16/2;
	ld	a,-5 (ix)
	add	a,d
	ld	d,a
	ld	a,-4 (ix)
	adc	a,c
	ld	c,a
	ld	a,d
	add	a,#0xF8
	ld	d,a
	ld	a,c
	adc	a,#0xFF
	ld	c,a
	ld	l,-20 (ix)
	ld	h,-19 (ix)
	ld	(hl),d
	inc	hl
	ld	(hl),c
;obj_youwin.c:42: angle += (256/NUM_EMERLADS);
	ld	a,e
	add	a,#0x24
	ld	e,a
;obj_youwin.c:38: for(i=0; i<NUM_EMERLADS; i++) {
	inc	-1 (ix)
	jp	00107$
00110$:
;obj_youwin.c:44: this->angle += (word)(1.5*256);
	ld	a,-12 (ix)
	add	a,#0x80
	ld	c,a
	ld	a,-11 (ix)
	adc	a,#0x01
	ld	b,a
	ld	l,-10 (ix)
	ld	h,-9 (ix)
	ld	(hl),c
	inc	hl
	ld	(hl),b
;obj_youwin.c:46: if(/*this->lifeTime >= 5*50*/ player1_input.fire1 || player2_input.fire1)
	ld	bc,#_player1_input + 2
	ld	a,(bc)
	or	a,a
	jr	NZ,00101$
	ld	bc,#_player2_input + 2
	ld	a,(bc)
	or	a,a
	jr	Z,00102$
00101$:
;obj_youwin.c:47: GameObjYouWin_SetState(this, DIE);
	ld	a,#0x02
	push	af
	inc	sp
	ld	l,-16 (ix)
	ld	h,-15 (ix)
	push	hl
	call	_GameObjYouWin_SetState
	pop	af
	inc	sp
00102$:
;obj_youwin.c:49: this->lifeTime++;
	ld	a,-16 (ix)
	add	a,#0x28
	ld	c,a
	ld	a,-15 (ix)
	adc	a,#0x00
	ld	b,a
	ld	l,c
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	de
	ld	l,c
	ld	h,b
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	sp,ix
	pop	ix
	ret
_GameObjYouWin_Move_end::
;obj_youwin.c:54: void GameObjYouWin_Draw(GameObjYouWin* this)
;	---------------------------------
; Function GameObjYouWin_Draw
; ---------------------------------
_GameObjYouWin_Draw_start::
_GameObjYouWin_Draw:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_youwin.c:56: this;
	pop	ix
	ret
_GameObjYouWin_Draw_end::
;obj_youwin.c:59: void GameObjYouWin_AllocateAnimObjects(GameObjYouWin* this)
;	---------------------------------
; Function GameObjYouWin_AllocateAnimObjects
; ---------------------------------
_GameObjYouWin_AllocateAnimObjects_start::
_GameObjYouWin_AllocateAnimObjects:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-9
	add	hl,sp
	ld	sp,hl
;obj_youwin.c:66: x = this->gobj.x;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	l,c
	ld	h,b
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-4 (ix),e
	ld	-3 (ix),d
;obj_youwin.c:67: y = this->gobj.y;
	ld	hl,#0x0003
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-6 (ix),e
	ld	-5 (ix),d
;obj_youwin.c:68: obj = PoolGameObj_AllocateGameObjAnim();
	push	bc
	call	_PoolGameObj_AllocateGameObjAnim
	ex	de,hl
	pop	bc
	ld	-2 (ix),e
	ld	-1 (ix),d
;obj_youwin.c:69: if(obj) {
	ld	a,-2 (ix)
	or	a,-1 (ix)
	jp	Z,00114$
;obj_youwin.c:70: GameObjAnim_Init(obj, x,  y);
	push	bc
	ld	l,-6 (ix)
	ld	h,-5 (ix)
	push	hl
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_GameObjAnim_Init
	pop	af
	pop	af
	pop	af
	pop	bc
;obj_youwin.c:71: obj->spr_count          = 6;
	ld	a,-2 (ix)
	add	a,#0x19
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,#0x06
	ld	(de),a
;obj_youwin.c:72: obj->spr_height         = 8;
	ld	a,-2 (ix)
	add	a,#0x1A
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,#0x08
	ld	(de),a
;obj_youwin.c:73: obj->spr_def_start      = SPRITE_DEF_NUM_YOUWIN;
	ld	a,-2 (ix)
	add	a,#0x1B
	ld	l, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h,a
	ld	(hl),#0x49
	inc	hl
	ld	(hl),#0x00
;obj_youwin.c:74: obj->spr_def_pitch      = 8;
	ld	a,-2 (ix)
	add	a,#0x1D
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,#0x08
	ld	(de),a
;obj_youwin.c:76: GameObjAnim_ShowOnlyFirstFrame(obj);
	push	bc
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_GameObjAnim_ShowOnlyFirstFrame
	pop	af
	pop	bc
;obj_youwin.c:80: for(i=0; i<NUM_EMERLADS; i++) {
00114$:
	ld	hl,#0x0018
	add	hl,bc
	ld	-9 (ix),l
	ld	-8 (ix),h
	ld	-7 (ix),#0x00
00105$:
	ld	a,-7 (ix)
	sub	a,#0x07
	jp	NC,00109$
;obj_youwin.c:81: obj = PoolGameObj_AllocateGameObjAnim();
	call	_PoolGameObj_AllocateGameObjAnim
	ld	d,h
	ld	-2 (ix),l
	ld	-1 (ix),d
;obj_youwin.c:82: if(obj) {
	ld	a,-2 (ix)
	or	a,-1 (ix)
	jp	Z,00107$
;obj_youwin.c:83: GameObjAnim_Init(obj, x + i*32,  y);
	ld	e,-7 (ix)
	ld	d,#0x00
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	ld	a,-4 (ix)
	add	a,e
	ld	e,a
	ld	a,-3 (ix)
	adc	a,d
	ld	d,a
	ld	l,-6 (ix)
	ld	h,-5 (ix)
	push	hl
	push	de
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_GameObjAnim_Init
	pop	af
	pop	af
	pop	af
;obj_youwin.c:84: obj->spr_count          = 2;
	ld	a,-2 (ix)
	add	a,#0x19
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,#0x02
	ld	(de),a
;obj_youwin.c:85: obj->spr_height         = 1;
	ld	a,-2 (ix)
	add	a,#0x1A
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,#0x01
	ld	(de),a
;obj_youwin.c:86: obj->spr_def_start      = SPRITE_DEF_NUM_EMERALD;
	ld	a,-2 (ix)
	add	a,#0x1B
	ld	l, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h,a
	ld	(hl),#0x3B
	inc	hl
	ld	(hl),#0x00
;obj_youwin.c:87: obj->spr_def_pitch      = 7;
	ld	a,-2 (ix)
	add	a,#0x1D
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,#0x07
	ld	(de),a
;obj_youwin.c:89: obj->spr_anim_time      = 250;
	ld	a,-2 (ix)
	add	a,#0x17
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,#0xFA
	ld	(de),a
;obj_youwin.c:90: obj->spr_anim_frames    = 7;
	ld	a,-2 (ix)
	add	a,#0x18
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,#0x07
	ld	(de),a
;obj_youwin.c:91: GameObjAnim_EnableAnimation(obj, TRUE);
	ld	a,#0x01
	push	af
	inc	sp
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_GameObjAnim_EnableAnimation
	pop	af
	inc	sp
;obj_youwin.c:93: obj->spr_anim_def_offset = i * 256U;
	ld	a,-2 (ix)
	add	a,#0x21
	ld	e,a
	ld	a,-1 (ix)
	adc	a,#0x00
	ld	d,a
	ld	b, -7 (ix)
	ld	c,#0x00
	ex	de,hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
;obj_youwin.c:95: this->emerlads[i] = obj;
	ld	a,-7 (ix)
	add	a,a
	ld	c,a
	ld	a,-9 (ix)
	add	a,c
	ld	l, a
	ld	a, -8 (ix)
	adc	a, #0x00
	ld	h,a
	ld	a,-2 (ix)
	ld	(hl),a
	inc	hl
	ld	a,-1 (ix)
	ld	(hl),a
00107$:
;obj_youwin.c:80: for(i=0; i<NUM_EMERLADS; i++) {
	inc	-7 (ix)
	jp	00105$
00109$:
	ld	sp,ix
	pop	ix
	ret
_GameObjYouWin_AllocateAnimObjects_end::
;obj_youwin.c:100: void GameObjYouWin_SetState(GameObjYouWin* this, ObjState state)
;	---------------------------------
; Function GameObjYouWin_SetState
; ---------------------------------
_GameObjYouWin_SetState_start::
_GameObjYouWin_SetState:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_youwin.c:104: if(state == this->state)
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	hl,#0x0017
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	a,(bc)
	ld	e,a
	ld	a,6 (ix)
	sub	e
	jr	NZ,00102$
;obj_youwin.c:105: return;
	jr	00103$
00102$:
;obj_youwin.c:106: this->state = state;
	ld	a,6 (ix)
	ld	(bc),a
00103$:
	pop	ix
	ret
_GameObjYouWin_SetState_end::
;obj_youwin.c:111: void helper_GameObjYouWin_StartAnimation(byte num_player)
;	---------------------------------
; Function helper_GameObjYouWin_StartAnimation
; ---------------------------------
_helper_GameObjYouWin_StartAnimation_start::
_helper_GameObjYouWin_StartAnimation:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_youwin.c:115: x = ((SCREEN_WIDTH/2) - SPR_YOUWIN_WIDTH*16)/2;
	ld	bc,#0x002C
;obj_youwin.c:117: if(num_player == 1) {
	ld	a,4 (ix)
	sub	a,#0x01
	jr	NZ,00102$
;obj_youwin.c:118: x = x + SCREEN_WIDTH/2;
	ld	bc,#0x00E4
00102$:
;obj_youwin.c:122: if(YouWinAnim.gobj.in_use) return;
	ld	hl,#_YouWinAnim
	ld	a,(hl)
	or	a,a
	jr	NZ,00105$
;obj_youwin.c:124: YouWinAnim.gobj.in_use = TRUE;
	ld	hl,#_YouWinAnim
	ld	(hl),#0x01
;obj_youwin.c:125: GameObjYouWin_Init(&YouWinAnim, x, y);
	ld	hl,#0x0038
	push	hl
	push	bc
	ld	hl,#_YouWinAnim
	push	hl
	call	_GameObjYouWin_Init
	pop	af
	pop	af
	pop	af
;obj_youwin.c:126: PoolGameObj_AddObjToActiveObjects(&YouWinAnim.gobj);
	ld	hl,#_YouWinAnim
	push	hl
	call	_PoolGameObj_AddObjToActiveObjects
	pop	af
;obj_youwin.c:130: GameObjScore_SetState(&scoreA, NORMAL); scoreA.is_show = TRUE;
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#_scoreA
	push	hl
	call	_GameObjScore_SetState
	pop	af
	inc	sp
	ld	a,#0x01
	ld	(#_scoreA + 32),a
;obj_youwin.c:131: GameObjScore_SetState(&scoreB, NORMAL); scoreB.is_show = TRUE;
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#_scoreB
	push	hl
	call	_GameObjScore_SetState
	pop	af
	inc	sp
	ld	a,#0x01
	ld	(#_scoreB + 32),a
;obj_youwin.c:133: game.isSoundfxEnabled = FALSE;
	ld	a,#0x00
	ld	(#_game + 7),a
;obj_youwin.c:134: game.isMusicEnabled   = TRUE;
	ld	a,#0x01
	ld	(#_game + 8),a
00105$:
	pop	ix
	ret
_helper_GameObjYouWin_StartAnimation_end::
;obj_gamemenu.c:1: void GameObjGameMenu_Init(GameObjGameMenu* this, int x, int y)
;	---------------------------------
; Function GameObjGameMenu_Init
; ---------------------------------
_GameObjGameMenu_Init_start::
_GameObjGameMenu_Init:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_gamemenu.c:4: GameObj_Init((GameObj*)this);
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	call	_GameObj_Init
	pop	af
;obj_gamemenu.c:6: this->gobj.x = x;
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	l,c
	ld	h,b
	inc	hl
	ld	a,6 (ix)
	ld	(hl),a
	inc	hl
	ld	a,7 (ix)
	ld	(hl),a
;obj_gamemenu.c:7: this->gobj.y = y;
	ld	hl,#0x0003
	add	hl,bc
	ld	a,8 (ix)
	ld	(hl),a
	inc	hl
	ld	a,9 (ix)
	ld	(hl),a
;obj_gamemenu.c:8: this->gobj.width  = 0;
	ld	hl,#0x0005
	add	hl,bc
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;obj_gamemenu.c:9: this->gobj.height = 0;
	ld	hl,#0x0007
	add	hl,bc
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;obj_gamemenu.c:11: this->gobj.pMoveFunc = &GameObjGameMenu_Move;
	ld	hl,#0x0013
	add	hl,bc
	ld	e,l
	ld	(hl),#<_GameObjGameMenu_Move
	inc	hl
	ld	(hl),#>_GameObjGameMenu_Move
;obj_gamemenu.c:12: this->gobj.pDrawFunc = &GameObjGameMenu_Draw;
	ld	hl,#0x0015
	add	hl,bc
	ld	b,h
	ld	(hl),#<_GameObjGameMenu_Draw
	inc	hl
	ld	(hl),#>_GameObjGameMenu_Draw
	pop	ix
	ret
_GameObjGameMenu_Init_end::
;obj_gamemenu.c:16: void GameObjGameMenu_Move(GameObjGameMenu* this)
;	---------------------------------
; Function GameObjGameMenu_Move
; ---------------------------------
_GameObjGameMenu_Move_start::
_GameObjGameMenu_Move:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_gamemenu.c:18: BOOL isBeginLevel = FALSE;
;obj_gamemenu.c:19: byte is_one_player_mode = FALSE;
	ld	bc,#0x0000
;obj_gamemenu.c:22: if (game.game_state == MENU) {
	ld	hl,#_game
	ld	a,(hl)
	sub	a,#0x01
	jr	NZ,00110$
;obj_gamemenu.c:23: if(player1_input.fire1) {
	ld	de,#_player1_input + 2
	ld	a,(de)
	or	a,a
	jr	Z,00102$
;obj_gamemenu.c:24: player1_input.fire1 = FALSE;
	ld	a,#0x00
	ld	(de),a
;obj_gamemenu.c:25: isBeginLevel       = TRUE;
;obj_gamemenu.c:26: is_one_player_mode = TRUE;
	ld	bc,#0x0101
00102$:
;obj_gamemenu.c:28: if(player2_input.fire1) {
	ld	de,#_player2_input + 2
	ld	a,(de)
	or	a,a
	jr	Z,00104$
;obj_gamemenu.c:29: player2_input.fire1 = FALSE;
	ld	a,#0x00
	ld	(de),a
;obj_gamemenu.c:30: isBeginLevel       = TRUE;
;obj_gamemenu.c:31: is_one_player_mode = FALSE;
	ld	bc,#0x0001
00104$:
;obj_gamemenu.c:34: if(Keyboard_GetLastPressedScancode() == SC_1) {
	push	bc
	call	_Keyboard_GetLastPressedScancode
	ld	e,l
	pop	bc
	ld	a,e
	sub	a,#0x16
	jr	NZ,00106$
;obj_gamemenu.c:36: Game_RequestSetState(CREDITS);
	push	bc
	ld	a,#0x02
	push	af
	inc	sp
	call	_Game_RequestSetState
	inc	sp
	pop	bc
00106$:
;obj_gamemenu.c:39: if(isBeginLevel) {
	xor	a,a
	or	a,c
	jr	Z,00110$
;obj_gamemenu.c:40: Game_RequestSetState(LEVEL);
	push	bc
	ld	a,#0x00
	push	af
	inc	sp
	call	_Game_RequestSetState
	inc	sp
	pop	bc
;obj_gamemenu.c:41: game.is_one_player_mode = is_one_player_mode;
	ld	de,#_game + 3
	ld	a,b
	ld	(de),a
00110$:
;obj_gamemenu.c:47: if (game.game_state == CREDITS) {
	ld	hl,#_game
	ld	a,(hl)
	sub	a,#0x02
	jr	NZ,00117$
;obj_gamemenu.c:50: if(Keyboard_GetLastPressedScancode() != 0 || player1_input.fire1 || player2_input.fire1) {
	call	_Keyboard_GetLastPressedScancode
	xor	a,a
	or	a,l
	jr	NZ,00111$
	ld	bc,#_player1_input + 2
	ld	a,(bc)
	or	a,a
	jr	NZ,00111$
	ld	bc,#_player2_input + 2
	ld	a,(bc)
	or	a,a
	jr	Z,00117$
00111$:
;obj_gamemenu.c:51: Game_RequestSetState(MENU);
	ld	a,#0x01
	push	af
	inc	sp
	call	_Game_RequestSetState
	inc	sp
00117$:
	pop	ix
	ret
_GameObjGameMenu_Move_end::
;obj_gamemenu.c:56: void GameObjGameMenu_Draw(GameObjGameMenu* this)
;	---------------------------------
; Function GameObjGameMenu_Draw
; ---------------------------------
_GameObjGameMenu_Draw_start::
_GameObjGameMenu_Draw:
	push	ix
	ld	ix,#0
	add	ix,sp
;obj_gamemenu.c:58: this;
	pop	ix
	ret
_GameObjGameMenu_Draw_end::
;ai.c:3: void ai_update(void)
;	---------------------------------
; Function ai_update
; ---------------------------------
_ai_update_start::
_ai_update:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-6
	add	hl,sp
	ld	sp,hl
;ai.c:11: int rocketY = batA.rocket->gobj.y;
	ld	bc,#_batA + 28
	ld	l,c
	ld	h,b
	ld	a,(hl)
	ld	-6 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-5 (ix),a
	ld	a,-6 (ix)
	add	a,#0x03
	ld	l, a
	ld	a, -5 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-2 (ix),e
	ld	-1 (ix),d
;ai.c:12: int rocketX = batA.rocket->gobj.x;
	ld	e,-6 (ix)
	ld	d,-5 (ix)
	ex	de,hl
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-4 (ix),e
	ld	-3 (ix),d
;ai.c:13: if(batA.rocket && batA.rocket->gobj.in_use &&
	ld	l,c
	ld	h,b
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,e
	or	a,d
	jp	Z,00102$
	ld	l,c
	ld	h,b
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,(bc)
	or	a,a
	jr	Z,00102$
;ai.c:14: rocketY > batB.gobj.y && rocketY < batB.gobj.y + batB.gobj.height &&
	ld	hl, #_batB + 3
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,c
	sub	a,-2 (ix)
	ld	a,b
	sbc	a,-1 (ix)
	jp	P,00102$
	ld	de,#_batB + 7
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,c
	add	a,e
	ld	c,a
	ld	a,b
	adc	a,d
	ld	b,a
	ld	a,-2 (ix)
	sub	a,c
	ld	a,-1 (ix)
	sbc	a,b
	jp	P,00102$
;ai.c:15: rocketX > SCREEN_WIDTH/2) {
	ld	a,#0xB8
	sub	a,-4 (ix)
	ld	a,#0x00
	sbc	a,-3 (ix)
	jp	P,00102$
;ai.c:17: GameObjBat_MoveUp(&batB); return;
	ld	hl,#_batB
	push	hl
	call	_GameObjBat_MoveUp
	pop	af
	jp	00118$
00102$:
;ai.c:20: if(ball1.gobj.y <  batB.gobj.y + batB.gobj.height/2)
	ld	hl, #_ball1 + 3
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	de,#_batB + 3
	ex	de,hl
	ld	a,(hl)
	ld	-6 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-5 (ix),a
	ld	de,#_batB + 7
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	bc
	ld	hl,#0x0002
	push	hl
	push	de
	call	__divsint_rrx_s
	pop	af
	pop	af
	ld	d,h
	ld	e,l
	pop	bc
	ld	a,-6 (ix)
	add	a,e
	ld	e,a
	ld	a,-5 (ix)
	adc	a,d
	ld	d,a
	ld	a,c
	sub	a,e
	ld	a,b
	sbc	a,d
	jp	P,00108$
;ai.c:21: GameObjBat_MoveUp(&batB);      //movebat ('J');
	ld	hl,#_batB
	push	hl
	call	_GameObjBat_MoveUp
	pop	af
00108$:
;ai.c:22: if(ball1.gobj.y >  batB.gobj.y + batB.gobj.height/2)
	ld	hl, #_ball1 + 3
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	de,#_batB + 3
	ex	de,hl
	ld	a,(hl)
	ld	-6 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-5 (ix),a
	ld	de,#_batB + 7
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	bc
	ld	hl,#0x0002
	push	hl
	push	de
	call	__divsint_rrx_s
	pop	af
	pop	af
	ex	de,hl
	pop	bc
	ld	a,-6 (ix)
	add	a,e
	ld	e,a
	ld	a,-5 (ix)
	adc	a,d
	ld	d,a
	ld	a,e
	sub	a,c
	ld	a,d
	sbc	a,b
	jp	P,00110$
;ai.c:23: GameObjBat_MoveDown(&batB);      //movebat ('M');
	ld	hl,#_batB
	push	hl
	call	_GameObjBat_MoveDown
	pop	af
00110$:
;ai.c:25: if(GameObjBat_IsCanFireWithRocket(&batB))
	ld	hl,#_batB
	push	hl
	call	_GameObjBat_IsCanFireWithRocket
	pop	af
	xor	a,a
	or	a,l
	jp	Z,00118$
;ai.c:26: if(ball1.speedx < 0 && ball1.speedy == 0 &&
	ld	hl, #_ball1 + 25
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,b
	bit	7,a
	jp	Z,00118$
	ld	hl, #_ball1 + 27
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,c
	or	a,b
	jr	NZ,00118$
;ai.c:27: ball1.gobj.y > batB.gobj.y &&  ball1.gobj.y < batB.gobj.y + batB.gobj.height)     // /*(RAND() & 0x1F) == 0*/)
	ld	hl, #_ball1 + 3
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	de,#_batB + 3
	ex	de,hl
	ld	a,(hl)
	ld	-6 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-5 (ix),a
	ld	a,-6 (ix)
	sub	a,c
	ld	a,-5 (ix)
	sbc	a,b
	jp	P,00118$
	ld	de,#_batB + 7
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-6 (ix)
	add	a,e
	ld	e,a
	ld	a,-5 (ix)
	adc	a,d
	ld	d,a
	ld	a,c
	sub	a,e
	ld	a,b
	sbc	a,d
	jp	P,00118$
;ai.c:28: GameObjBat_Fire(&batB);
	ld	hl,#_batB
	push	hl
	call	_GameObjBat_Fire
	pop	af
00118$:
	ld	sp,ix
	pop	ix
	ret
_ai_update_end::
;sound_fx/sound_fx.c:8: BOOL Sound_LoadSoundCode(void)
;	---------------------------------
; Function Sound_LoadSoundCode
; ---------------------------------
_Sound_LoadSoundCode_start::
_Sound_LoadSoundCode:
;sound_fx/sound_fx.c:10: return load_file_to_buffer("SFXPROXY.BIN", 0, (byte*)SOUND_FX_CODE,
	ld	a,#0x01
	push	af
	inc	sp
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x2000
	push	hl
	ld	h, #0x80
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#__str_8
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
	ret
_Sound_LoadSoundCode_end::
__str_8:
	.ascii "SFXPROXY.BIN"
	.db 0x00
;sound_fx/sound_fx.c:14: BOOL Sound_LoadSounds(void)
;	---------------------------------
; Function Sound_LoadSounds
; ---------------------------------
_Sound_LoadSounds_start::
_Sound_LoadSounds:
;sound_fx/sound_fx.c:19: return load_file_to_buffer("SFX.SAM", 0, sfx_samples_addr, 65536, sfx_samples_bank);
	ld	a,#0x03
	push	af
	inc	sp
	ld	hl,#0x0001
	push	hl
	ld	hl,#0x10000
	push	hl
	ld	h, #0x80
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#__str_9
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
	ret
_Sound_LoadSounds_end::
__str_9:
	.ascii "SFX.SAM"
	.db 0x00
;sound_fx/sound_fx.c:25: BOOL Sound_LoadFxDescriptors(void)
;	---------------------------------
; Function Sound_LoadFxDescriptors
; ---------------------------------
_Sound_LoadFxDescriptors_start::
_Sound_LoadFxDescriptors:
;sound_fx/sound_fx.c:27: return load_file_to_buffer("ALL_FX.BIN", 0, (byte*)SOUND_FX_DESC, 464, BANK_MUSIC_STUFF);
	ld	a,#0x01
	push	af
	inc	sp
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x01D0
	push	hl
	ld	hl,#0xA000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#__str_10
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
	ret
_Sound_LoadFxDescriptors_end::
__str_10:
	.ascii "ALL_FX.BIN"
	.db 0x00
;sound_fx/sound_fx.c:32: void Sound_InitFx()
;	---------------------------------
; Function Sound_InitFx
; ---------------------------------
_Sound_InitFx_start::
_Sound_InitFx:
;sound_fx/sound_fx.c:49: Sound_AddFxDesc(0, (SOUND_FX*) (SOUND_FX_DESC + 0x00) );
	ld	hl,#0xA000
	push	hl
	ld	a,#0x00
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:50: Sound_AddFxDesc(1, (SOUND_FX*) (SOUND_FX_DESC + 0x20) );
	ld	hl,#0xA020
	push	hl
	ld	a,#0x01
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:51: Sound_AddFxDesc(2, (SOUND_FX*) (SOUND_FX_DESC + 0x50) );
	ld	hl,#0xA050
	push	hl
	ld	a,#0x02
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:52: Sound_AddFxDesc(3, (SOUND_FX*) (SOUND_FX_DESC + 0x70) );
	ld	hl,#0xA070
	push	hl
	ld	a,#0x03
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:53: Sound_AddFxDesc(4, (SOUND_FX*) (SOUND_FX_DESC + 0x90) );
	ld	hl,#0xA090
	push	hl
	ld	a,#0x04
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:55: Sound_AddFxDesc(5, (SOUND_FX*) (SOUND_FX_DESC + 0xc0) );
	ld	hl,#0xA0C0
	push	hl
	ld	a,#0x05
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:56: Sound_AddFxDesc(6, (SOUND_FX*) (SOUND_FX_DESC + 0xe0) );
	ld	hl,#0xA0E0
	push	hl
	ld	a,#0x06
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:57: Sound_AddFxDesc(7, (SOUND_FX*) (SOUND_FX_DESC + 0x100) );
	ld	hl,#0xA100
	push	hl
	ld	a,#0x07
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:58: Sound_AddFxDesc(8, (SOUND_FX*) (SOUND_FX_DESC + 0x120) );
	ld	hl,#0xA120
	push	hl
	ld	a,#0x08
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:59: Sound_AddFxDesc(9, (SOUND_FX*) (SOUND_FX_DESC + 0x140) );
	ld	hl,#0xA140
	push	hl
	ld	a,#0x09
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:60: Sound_AddFxDesc(10, (SOUND_FX*) (SOUND_FX_DESC + 0x150) );
	ld	hl,#0xA150
	push	hl
	ld	a,#0x0A
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:61: Sound_AddFxDesc(11, (SOUND_FX*) (SOUND_FX_DESC + 0x170) );
	ld	hl,#0xA170
	push	hl
	ld	a,#0x0B
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:62: Sound_AddFxDesc(12, (SOUND_FX*) (SOUND_FX_DESC + 0x180) );
	ld	hl,#0xA180
	push	hl
	ld	a,#0x0C
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:63: Sound_AddFxDesc(13, (SOUND_FX*) (SOUND_FX_DESC + 0x190) );
	ld	hl,#0xA190
	push	hl
	ld	a,#0x0D
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:64: Sound_AddFxDesc(14, (SOUND_FX*) (SOUND_FX_DESC + 0x1a0) );
	ld	hl,#0xA1A0
	push	hl
	ld	a,#0x0E
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
;sound_fx/sound_fx.c:65: Sound_AddFxDesc(15, (SOUND_FX*) (SOUND_FX_DESC + 0x1b0) );
	ld	hl,#0xA1B0
	push	hl
	ld	a,#0x0F
	push	af
	inc	sp
	call	_Sound_AddFxDesc
	pop	af
	inc	sp
	ret
_Sound_InitFx_end::
;sound_fx/sound_fx.c:72: byte Mod_FindHighestUsedPattern(const byte* pPatternData)
;	---------------------------------
; Function Mod_FindHighestUsedPattern
; ---------------------------------
_Mod_FindHighestUsedPattern_start::
_Mod_FindHighestUsedPattern:
	push	ix
	ld	ix,#0
	add	ix,sp
;sound_fx/sound_fx.c:75: byte pat = 0;
;sound_fx/sound_fx.c:76: for(i=0; i<128; i++)
	ld	bc,#0x0000
00103$:
	ld	a,b
	sub	a,#0x80
	jr	NC,00106$
;sound_fx/sound_fx.c:77: if(pPatternData[i] > pat)
	ld	a,4 (ix)
	add	a,b
	ld	e,a
	ld	a,5 (ix)
	adc	a,#0x00
	ld	d,a
	ld	a,(de)
	ld	e,a
	ld	a,c
	sub	a,e
	jr	NC,00105$
;sound_fx/sound_fx.c:78: pat = pPatternData[i];
	ld	c,e
00105$:
;sound_fx/sound_fx.c:76: for(i=0; i<128; i++)
	inc	b
	jr	00103$
00106$:
;sound_fx/sound_fx.c:80: return pat;
	ld	l,c
	pop	ix
	ret
_Mod_FindHighestUsedPattern_end::
;sound_fx/sound_fx.c:85: BOOL Mod_LoadMusicModule(const char* pFilename)
;	---------------------------------
; Function Mod_LoadMusicModule
; ---------------------------------
_Mod_LoadMusicModule_start::
_Mod_LoadMusicModule:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-19
	add	hl,sp
	ld	sp,hl
;sound_fx/sound_fx.c:95: r = diag__FLOS_FindFile(&myFile, pFilename);
	ld	hl,#0x000C
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	push	bc
	call	_diag__FLOS_FindFile
	pop	af
	pop	af
	ld	a,l
;sound_fx/sound_fx.c:96: if(!r) return FALSE;
	or	a,a
	jr	NZ,00102$
	ld	l,a
	jp	00109$
00102$:
;sound_fx/sound_fx.c:97: fileLen = myFile.size;
	ld	hl,#0x000C
	add	hl,sp
	inc	hl
	inc	hl
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-11 (ix),c
	ld	-10 (ix),b
	ld	-9 (ix),e
	ld	-8 (ix),d
;sound_fx/sound_fx.c:100: if(!load_file_to_buffer(pFilename, 0, bufModFileHeader, 1084, 0))
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x043C
	push	hl
	ld	hl,#_bufModFileHeader
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
;sound_fx/sound_fx.c:101: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00104$
	ld	l,a
	jp	00109$
00104$:
;sound_fx/sound_fx.c:105: pat = Mod_FindHighestUsedPattern(bufModFileHeader + 952);
	ld	bc,#_bufModFileHeader + 952
	push	bc
	call	_Mod_FindHighestUsedPattern
	pop	af
	ld	c,l
;sound_fx/sound_fx.c:106: patLen = 1084 + (pat+1)*4*256;
	ld	b,#0x00
	inc	bc
	ld	a,c
	add	a,a
	add	a,a
	ld	b,a
	ld	c,#0x00
	ld	hl,#0x043C
	add	hl,bc
	ld	c,l
	ld	b,h
;sound_fx/sound_fx.c:107: sampleLen = fileLen - (dword)patLen;
	ld	-19 (ix),c
	ld	-18 (ix),b
	ld	-17 (ix),#0x00
	ld	-16 (ix),#0x00
	ld	a,-11 (ix)
	sub	a,-19 (ix)
	ld	c,a
	ld	a,-10 (ix)
	sbc	a,-18 (ix)
	ld	b,a
	ld	a,-9 (ix)
	sbc	a,-17 (ix)
	ld	e,a
	ld	a,-8 (ix)
	sbc	a,-16 (ix)
	ld	d,a
	ld	-15 (ix),c
	ld	-14 (ix),b
	ld	-13 (ix),e
	ld	-12 (ix),d
;sound_fx/sound_fx.c:114: if(!load_file_to_buffer(pFilename, 0, (byte*) SOUND_MOD_PATTERN_DATA, patLen, BANK_MUSIC_STUFF))
	ld	a,#0x01
	push	af
	inc	sp
	ld	l,-17 (ix)
	ld	h,-16 (ix)
	push	hl
	ld	l,-19 (ix)
	ld	h,-18 (ix)
	push	hl
	ld	hl,#0xA200
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
;sound_fx/sound_fx.c:115: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00106$
	ld	l,a
	jr	00109$
00106$:
;sound_fx/sound_fx.c:118: if(!load_file_to_buffer(pFilename, patLen, (byte*) 0x8000, sampleLen, BANK_MOD_SAMPLE1))
	ld	a,#0x05
	push	af
	inc	sp
	ld	l,-13 (ix)
	ld	h,-12 (ix)
	push	hl
	ld	l,-15 (ix)
	ld	h,-14 (ix)
	push	hl
	ld	hl,#0x8000
	push	hl
	ld	l,-17 (ix)
	ld	h,-16 (ix)
	push	hl
	ld	l,-19 (ix)
	ld	h,-18 (ix)
	push	hl
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
;sound_fx/sound_fx.c:119: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00108$
	ld	l,a
	jr	00109$
00108$:
;sound_fx/sound_fx.c:121: return TRUE;
	ld	l,#0x01
00109$:
	ld	sp,ix
	pop	ix
	ret
_Mod_LoadMusicModule_end::
;sound_fx/sound_fx.c:126: void MUSIC_Silence(void)
;	---------------------------------
; Function MUSIC_Silence
; ---------------------------------
_MUSIC_Silence_start::
_MUSIC_Silence:
;sound_fx/sound_fx.c:128: Music_InitTracker();
	call	_Music_InitTracker
;sound_fx/sound_fx.c:129: Music_UpdateSoundHardware();
	jp	_Music_UpdateSoundHardware
_MUSIC_Silence_end::
;sound_fx/sound_fx.c:132: void MUSIC_Init(void)
;	---------------------------------
; Function MUSIC_Init
; ---------------------------------
_MUSIC_Init_start::
_MUSIC_Init:
;sound_fx/sound_fx.c:134: Music_SetForceSampleBase(0x10000/2);
	ld	hl,#0x8000
	push	hl
	call	_Music_SetForceSampleBase
	pop	af
;sound_fx/sound_fx.c:135: Music_InitTracker();
	jp	_Music_InitTracker
_MUSIC_Init_end::
;debug.c:5: void Debug_Move(void)
;	---------------------------------
; Function Debug_Move
; ---------------------------------
_Debug_Move_start::
_Debug_Move:
;debug.c:8: if(keyboard.last_typed_scancode == SC_A) {
	ld	bc,#_keyboard + 1
	ld	a,(bc)
	sub	a,#0x1C
	jr	Z,00110$
	ret
00110$:
;debug.c:9: keyboard.last_typed_scancode = 0;
	ld	a,#0x00
	ld	(bc),a
;debug.c:11: debug.offset_gameobj_for_debug_render++;
	ld	hl,#_debug
	ld	c,(hl)
	inc	c
	ld	(hl),c
;debug.c:12: if(debug.offset_gameobj_for_debug_render >= POOL_OBJ__MAX_OBJECTS)
	ld	a,c
	sub	a,#0x20
	ret	C
;debug.c:13: debug.offset_gameobj_for_debug_render = 0;
	ld	(hl),#0x00
	ret
_Debug_Move_end::
;debug.c:19: void Debug_Draw(void)
;	---------------------------------
; Function Debug_Draw
; ---------------------------------
_Debug_Draw_start::
_Debug_Draw:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-8
	add	hl,sp
	ld	sp,hl
;debug.c:27: if(counter & 0x80) {
	ld	a,(#_Debug_Draw_counter_1_1+0)
	and	a,#0x80
	jr	Z,00102$
;debug.c:28: counter = 0;
	ld	hl,#_Debug_Draw_counter_1_1 + 0
	ld	(hl), #0x00
	ld	hl,#_Debug_Draw_counter_1_1 + 1
	ld	(hl), #0x00
;debug.c:29: corner ^= 1;
	ld	a,(#_Debug_Draw_corner_1_1+0)
	xor	a,#0x01
	ld	hl,#_Debug_Draw_corner_1_1 + 0
	ld	(hl), a
00102$:
;debug.c:31: counter++;
	ld	iy,#_Debug_Draw_counter_1_1
	inc	0 (iy)
	jr	NZ,00121$
	ld	iy,#_Debug_Draw_counter_1_1
	inc	1 (iy)
00121$:
;debug.c:35: for(i=debug.offset_gameobj_for_debug_render; i<POOL_OBJ__MAX_OBJECTS; i++) {
	ld	hl,#_debug
	ld	c,(hl)
	ld	b,#0x00
	ld	hl,#_pool_game_obj + 629
	ld	-6 (ix),l
	ld	-5 (ix),h
00108$:
	ld	a,c
	sub	a,#0x20
	ld	a,b
	sbc	a,#0x00
	jp	NC,00112$
;debug.c:36: obj = pool_game_obj.active_objects[i];
	ld	e,c
	ld	d,b
	sla	e
	rl	d
	ld	a,-6 (ix)
	add	a,e
	ld	e,a
	ld	a,-5 (ix)
	adc	a,d
	ld	l,e
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	-2 (ix),e
	ld	-1 (ix),d
;debug.c:37: if( obj && obj->in_use) {
	ld	a,-2 (ix)
	or	a,-1 (ix)
	jp	Z,00110$
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,(hl)
	or	a,a
	jp	Z,00110$
;debug.c:38: x = obj->x + obj->col_x_offset;
	ld	e,-2 (ix)
	ld	d,-1 (ix)
	ex	de,hl
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,-2 (ix)
	add	a,#0x0D
	ld	l, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,c
	add	a,e
	ld	e,a
	ld	a,b
	adc	a,d
	ld	c,e
	ld	b,a
;debug.c:39: y = obj->y + obj->col_y_offset;
	ld	a,-2 (ix)
	add	a,#0x03
	ld	l, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h,a
	ld	a,(hl)
	ld	-8 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-7 (ix),a
	ld	a,-2 (ix)
	add	a,#0x0F
	ld	l, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-8 (ix)
	add	a,e
	ld	e,a
	ld	a,-7 (ix)
	adc	a,d
	ld	d,a
	ld	-4 (ix),e
	ld	-3 (ix),d
;debug.c:40: if(corner == 1) {
	ld	a,(#_Debug_Draw_corner_1_1+0)
	sub	a,#0x01
	jr	NZ,00104$
;debug.c:41: x +=  obj->col_width;
	ld	a,-2 (ix)
	add	a,#0x09
	ld	l, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,c
	add	a,e
	ld	c,a
	ld	a,b
	adc	a,d
	ld	b,a
;debug.c:42: y +=  obj->col_height;
	ld	a,-2 (ix)
	add	a,#0x0B
	ld	l, a
	ld	a, -1 (ix)
	adc	a, #0x00
	ld	h,a
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,-4 (ix)
	add	a,e
	ld	-4 (ix),a
	ld	a,-3 (ix)
	adc	a,d
	ld	-3 (ix),a
00104$:
;debug.c:46: set_sprite_regs(SPRITE_NUM_DEBUG_POINT1, x, y, 1,
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x0004
	push	hl
	ld	a,#0x01
	push	af
	inc	sp
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	push	hl
	push	bc
	ld	a,#0x32
	push	af
	inc	sp
	call	_set_sprite_regs
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
;debug.c:49: return;
	jr	00112$
00110$:
;debug.c:35: for(i=debug.offset_gameobj_for_debug_render; i<POOL_OBJ__MAX_OBJECTS; i++) {
	inc	bc
	jp	00108$
00112$:
	ld	sp,ix
	pop	ix
	ret
_Debug_Draw_end::
;debug.c:55: BOOL Debug_CheckCurrentBank(void)
;	---------------------------------
; Function Debug_CheckCurrentBank
; ---------------------------------
_Debug_CheckCurrentBank_start::
_Debug_CheckCurrentBank:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-10
	add	hl,sp
	ld	sp,hl
;debug.c:58: byte b = io__sys_mem_select;
	in	a,(_io__sys_mem_select)
	ld	c,a
;debug.c:61: if((b-1) != PONG_BANK) {
	ld	e,c
	ld	d,#0x00
	dec	de
	ld	a,e
	or	a,d
	jr	Z,00102$
;debug.c:62: FLOS_PrintStringLFCR("ERR: Not good cur bank.");
	push	bc
	ld	hl,#__str_11
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
	pop	bc
;debug.c:63: _ultoa(b, buf, 16);
	ld	hl,#0x0002
	add	hl,sp
	ld	-10 (ix),l
	ld	-9 (ix),h
	ld	b,#0x00
	ld	de,#0x0000
	ld	a,#0x10
	push	af
	inc	sp
	ld	l,-10 (ix)
	ld	h,-9 (ix)
	push	hl
	push	de
	push	bc
	call	__ultoa
	pop	af
	pop	af
	pop	af
	inc	sp
;debug.c:64: FLOS_PrintString("Cur hardware bank: $");
	ld	hl,#__str_12
	push	hl
	call	_FLOS_PrintString
	pop	af
;debug.c:65: FLOS_PrintStringLFCR(buf);
	ld	hl,#0x0002
	add	hl,sp
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;debug.c:66: buffer[0] = 'E'; buffer[1] = 'R';   // put  E R as "was error" marker
	ld	hl,#_buffer
	ld	(hl),#0x45
	ld	a,#0x52
	ld	(#_buffer + 1),a
;debug.c:67: return FALSE;
	ld	l,#0x00
	jr	00103$
00102$:
;debug.c:70: return TRUE;
	ld	l,#0x01
00103$:
	ld	sp,ix
	pop	ix
	ret
_Debug_CheckCurrentBank_end::
__str_11:
	.ascii "ERR: Not good cur bank."
	.db 0x00
__str_12:
	.ascii "Cur hardware bank: $"
	.db 0x00
;pong.c:110: void Game_Initialize(void) // Initialize the game.
;	---------------------------------
; Function Game_Initialize
; ---------------------------------
_Game_Initialize_start::
_Game_Initialize:
;pong.c:112: memset(&YouWinAnim, 0, sizeof(YouWinAnim));
	ld	hl,#0x002A
	push	hl
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#_YouWinAnim
	push	hl
	call	_memset
	pop	af
	pop	af
	inc	sp
;pong.c:115: game.is_paused = game.is_user_pressed_pause = FALSE;
	ld	bc,#_game + 4
	ld	de,#_game + 5
	ld	a,#0x00
	ld	(de),a
	ld	(bc),a
;pong.c:116: game.is_debug_mode = FALSE;
;pong.c:117: game.shadow_sprite_register_bank = 0;
	ld	a,#0x00
	ld	(#_game + 6),a
	ld	(#_game + 12),a
;pong.c:118: game.global_time = 0;
	ld	hl, #_game + 13
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;pong.c:120: debug.offset_gameobj_for_debug_render = 0;
	ld	hl,#_debug
	ld	(hl),#0x00
;pong.c:124: PoolGameObj_Init();
	call	_PoolGameObj_Init
;pong.c:126: PoolSprites_Init();
	jp	_PoolSprites_Init
_Game_Initialize_end::
;pong.c:130: void Game_InitializeMenuGameObjects(void) // Initialize
;	---------------------------------
; Function Game_InitializeMenuGameObjects
; ---------------------------------
_Game_InitializeMenuGameObjects_start::
_Game_InitializeMenuGameObjects:
;pong.c:132: gameMenu.gobj.in_use = TRUE;
	ld	hl,#_gameMenu
	ld	(hl),#0x01
;pong.c:133: GameObjGameMenu_Init(&gameMenu, 0, 0);
	ld	hl,#0x0000
	push	hl
	ld	l, #0x00
	push	hl
	ld	hl,#_gameMenu
	push	hl
	call	_GameObjGameMenu_Init
	pop	af
	pop	af
	pop	af
;pong.c:134: PoolGameObj_AddObjToActiveObjects(&gameMenu.gobj);
	ld	hl,#_gameMenu
	push	hl
	call	_PoolGameObj_AddObjToActiveObjects
	pop	af
	ret
_Game_InitializeMenuGameObjects_end::
;pong.c:137: void Game_InitializeLevelGameObjects(void) // Initialize
;	---------------------------------
; Function Game_InitializeLevelGameObjects
; ---------------------------------
_Game_InitializeLevelGameObjects_start::
_Game_InitializeLevelGameObjects:
;pong.c:141: batA.gobj.in_use = TRUE;
	ld	hl,#_batA
	ld	(hl),#0x01
;pong.c:142: GameObjBat_Init(&batA, GAME_FIELD_X_BORDER - BAT_WIDTH, 237/2);
	ld	hl,#0x0076
	push	hl
	ld	l, #0x02
	push	hl
	ld	hl,#_batA
	push	hl
	call	_GameObjBat_Init
	pop	af
	pop	af
	pop	af
;pong.c:143: PoolGameObj_AddObjToActiveObjects(&batA.gobj);
	ld	hl,#_batA
	push	hl
	call	_PoolGameObj_AddObjToActiveObjects
	pop	af
;pong.c:147: batB.gobj.in_use = TRUE;
	ld	hl,#_batB
	ld	(hl),#0x01
;pong.c:148: GameObjBat_Init(&batB, SCREEN_WIDTH - GAME_FIELD_X_BORDER, 237/2);
	ld	hl,#0x0076
	push	hl
	ld	hl,#0x0166
	push	hl
	ld	hl,#_batB
	push	hl
	call	_GameObjBat_Init
	pop	af
	pop	af
	pop	af
;pong.c:149: PoolGameObj_AddObjToActiveObjects(&batB.gobj);
	ld	hl,#_batB
	push	hl
	call	_PoolGameObj_AddObjToActiveObjects
	pop	af
;pong.c:153: ball1.gobj.in_use = TRUE;
	ld	hl,#_ball1
	ld	(hl),#0x01
;pong.c:154: GameObjBall_Init(&ball1);
	push	hl
	call	_GameObjBall_Init
	pop	af
;pong.c:155: PoolGameObj_AddObjToActiveObjects(&ball1.gobj);
	ld	hl,#_ball1
	push	hl
	call	_PoolGameObj_AddObjToActiveObjects
	pop	af
;pong.c:158: scoreA.gobj.in_use = TRUE;
	ld	hl,#_scoreA
	ld	(hl),#0x01
;pong.c:159: GameObjScore_Init(&scoreA, (SCREEN_WIDTH/2)-16*4, 0);
	ld	hl,#0x0000
	push	hl
	ld	l, #0x78
	push	hl
	ld	hl,#_scoreA
	push	hl
	call	_GameObjScore_Init
	pop	af
	pop	af
	pop	af
;pong.c:160: scoreA.sprite_num = SPRITE_NUM_SCORE_A_DIGIT;
	ld	a,#0x04
	ld	(#_scoreA + 29),a
;pong.c:161: scoreA.sprite_num_RocketsIndicator = SPRITE_NUM_PLAYER_A_NUM_ROCKETS;
	ld	a,#0x08
	ld	(#_scoreA + 33),a
;pong.c:162: PoolGameObj_AddObjToActiveObjects(&scoreA.gobj);
	ld	hl,#_scoreA
	push	hl
	call	_PoolGameObj_AddObjToActiveObjects
	pop	af
;pong.c:163: GameObjScore_UpdateScore(&scoreA);
	ld	hl,#_scoreA
	push	hl
	call	_GameObjScore_UpdateScore
	pop	af
;pong.c:166: scoreB.gobj.in_use = TRUE;
	ld	hl,#_scoreB
	ld	(hl),#0x01
;pong.c:167: GameObjScore_Init(&scoreB, (SCREEN_WIDTH/2)+16*2, 0);
	ld	hl,#0x0000
	push	hl
	ld	l, #0xD8
	push	hl
	ld	hl,#_scoreB
	push	hl
	call	_GameObjScore_Init
	pop	af
	pop	af
	pop	af
;pong.c:168: scoreB.sprite_num = SPRITE_NUM_SCORE_B_DIGIT;
	ld	a,#0x06
	ld	(#_scoreB + 29),a
;pong.c:169: scoreB.sprite_num_RocketsIndicator = SPRITE_NUM_PLAYER_B_NUM_ROCKETS;
	ld	a,#0x0B
	ld	(#_scoreB + 33),a
;pong.c:170: PoolGameObj_AddObjToActiveObjects(&scoreB.gobj);
	ld	hl,#_scoreB
	push	hl
	call	_PoolGameObj_AddObjToActiveObjects
	pop	af
;pong.c:171: GameObjScore_UpdateScore(&scoreB);
	ld	hl,#_scoreB
	push	hl
	call	_GameObjScore_UpdateScore
	pop	af
	ret
_Game_InitializeLevelGameObjects_end::
;pong.c:177: void Game_Movebat(char input)
;	---------------------------------
; Function Game_Movebat
; ---------------------------------
_Game_Movebat_start::
_Game_Movebat:
	push	ix
	ld	ix,#0
	add	ix,sp
;pong.c:179: switch (input)
	ld	a,4 (ix)
	sub	a,#0x41
	jr	Z,00101$
	ld	a,4 (ix)
	sub	a,#0x4A
	jr	Z,00103$
	ld	a,4 (ix)
	sub	a,#0x4D
	jr	Z,00104$
	ld	a,4 (ix)
	sub	a,#0x5A
	jr	Z,00102$
	jr	00106$
;pong.c:181: case 'A' :
00101$:
;pong.c:182: GameObjBat_MoveUp(&batA);
	ld	hl,#_batA
	push	hl
	call	_GameObjBat_MoveUp
	pop	af
;pong.c:183: break;
	jr	00106$
;pong.c:185: case 'Z' :
00102$:
;pong.c:186: GameObjBat_MoveDown(&batA);
	ld	hl,#_batA
	push	hl
	call	_GameObjBat_MoveDown
	pop	af
;pong.c:187: break;
	jr	00106$
;pong.c:188: case 'J' :
00103$:
;pong.c:189: GameObjBat_MoveUp(&batB);
	ld	hl,#_batB
	push	hl
	call	_GameObjBat_MoveUp
	pop	af
;pong.c:190: break;
	jr	00106$
;pong.c:192: case 'M' :
00104$:
;pong.c:193: GameObjBat_MoveDown(&batB);
	ld	hl,#_batB
	push	hl
	call	_GameObjBat_MoveDown
	pop	af
;pong.c:195: }
00106$:
	pop	ix
	ret
_Game_Movebat_end::
;pong.c:204: void Game_HandlePlayerInput_Bat(void)
;	---------------------------------
; Function Game_HandlePlayerInput_Bat
; ---------------------------------
_Game_HandlePlayerInput_Bat_start::
_Game_HandlePlayerInput_Bat:
;pong.c:206: if (player1_input.up)  Game_Movebat ('A');
	ld	hl,#_player1_input
	ld	a,(hl)
	or	a,a
	jr	Z,00102$
	ld	a,#0x41
	push	af
	inc	sp
	call	_Game_Movebat
	inc	sp
00102$:
;pong.c:207: if (player1_input.down)  Game_Movebat ('Z');
	ld	bc,#_player1_input + 1
	ld	a,(bc)
	or	a,a
	jr	Z,00104$
	ld	a,#0x5A
	push	af
	inc	sp
	call	_Game_Movebat
	inc	sp
00104$:
;pong.c:208: if (player1_input.fire1)  GameObjBat_Fire(&batA);
	ld	bc,#_player1_input + 2
	ld	a,(bc)
	or	a,a
	jr	Z,00106$
	ld	hl,#_batA
	push	hl
	call	_GameObjBat_Fire
	pop	af
00106$:
;pong.c:209: if (player2_input.fire1)  GameObjBat_Fire(&batB);
	ld	bc,#_player2_input + 2
	ld	a,(bc)
	or	a,a
	jr	Z,00108$
	ld	hl,#_batB
	push	hl
	call	_GameObjBat_Fire
	pop	af
00108$:
;pong.c:211: if(game.is_one_player_mode)
	ld	bc,#_game + 3
	ld	a,(bc)
	or	a,a
	jr	Z,00114$
;pong.c:212: ai_update();
	jp	_ai_update
00114$:
;pong.c:214: if (player2_input.up)  Game_Movebat ('J');
	ld	hl,#_player2_input
	ld	a,(hl)
	or	a,a
	jr	Z,00110$
	ld	a,#0x4A
	push	af
	inc	sp
	call	_Game_Movebat
	inc	sp
00110$:
;pong.c:215: if (player2_input.down)  Game_Movebat ('M');
	ld	bc,#_player2_input + 1
	ld	a,(bc)
	or	a,a
	ret	Z
	ld	a,#0x4D
	push	af
	inc	sp
	call	_Game_Movebat
	inc	sp
	ret
_Game_HandlePlayerInput_Bat_end::
;pong.c:219: void Game_HandlePlayerInput_PauseMode(void)
;	---------------------------------
; Function Game_HandlePlayerInput_PauseMode
; ---------------------------------
_Game_HandlePlayerInput_PauseMode_start::
_Game_HandlePlayerInput_PauseMode:
;pong.c:221: if(game.is_user_pressed_pause) {
	ld	bc,#_game + 5
	ld	a,(bc)
	or	a,a
	jr	Z,00102$
;pong.c:222: game.is_user_pressed_pause = FALSE;
	ld	a,#0x00
	ld	(bc),a
;pong.c:223: game.is_paused ^= 1;
	ld	bc,#_game + 4
	ld	a,(bc)
	xor	a,#0x01
	ld	(bc),a
00102$:
;pong.c:226: if(keyboard.last_typed_scancode == SC_D) {
	ld	bc,#_keyboard + 1
	ld	a,(bc)
	sub	a,#0x23
	jr	Z,00110$
	ret
00110$:
;pong.c:227: keyboard.last_typed_scancode = 0;
	ld	a,#0x00
	ld	(bc),a
;pong.c:228: game.is_debug_mode ^= 1;
	ld	bc,#_game + 6
	ld	a,(bc)
	xor	a,#0x01
	ld	(bc),a
;pong.c:230: game.is_paused ^= 1;
	ld	bc,#_game + 4
	ld	a,(bc)
	xor	a,#0x01
	ld	(bc),a
	ret
_Game_HandlePlayerInput_PauseMode_end::
;pong.c:236: void Game_ReInit_Watcher(void)
;	---------------------------------
; Function Game_ReInit_Watcher
; ---------------------------------
_Game_ReInit_Watcher_start::
_Game_ReInit_Watcher:
;pong.c:239: if(scoreA.score >= MAX_SCORE_FOR_LEVEL || scoreB.score >= MAX_SCORE_FOR_LEVEL) {
	ld	hl, #_scoreA + 24
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,c
	sub	a,#0x0A
	ld	a,b
	sbc	a,#0x00
	jp	P,00107$
	ld	hl, #_scoreB + 24
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,c
	sub	a,#0x0A
	ld	a,b
	sbc	a,#0x00
	jp	M,00108$
00107$:
;pong.c:240: if(YouWinAnim.gobj.in_use && YouWinAnim.state == DIE) {
	ld	hl,#_YouWinAnim
	ld	a,(hl)
	or	a,a
	ret	Z
	ld	bc,#_YouWinAnim + 23
	ld	a,(bc)
	sub	a,#0x02
	jr	Z,00119$
	ret
00119$:
;pong.c:242: Game_RequestSetState(MENU);
	ld	a,#0x01
	push	af
	inc	sp
	call	_Game_RequestSetState
	inc	sp
	ret
00108$:
;pong.c:248: if(ball1.state == DIE
	ld	bc,#_ball1 + 29
	ld	a,(bc)
	sub	a,#0x02
	jr	Z,00121$
	ret
00121$:
;pong.c:250: && helper_GameObjScore_IsScoreBlinkedAtLeast(4)
	ld	a,#0x04
	push	af
	inc	sp
	call	_helper_GameObjScore_IsScoreBlinkedAtLeast
	inc	sp
	xor	a,a
	or	a,l
	ret	Z
;pong.c:252: Game_Initialize();
	call	_Game_Initialize
;pong.c:253: Game_InitializeLevelGameObjects();
	jp	_Game_InitializeLevelGameObjects
_Game_ReInit_Watcher_end::
;pong.c:260: void Game_Play(void)
;	---------------------------------
; Function Game_Play
; ---------------------------------
_Game_Play_start::
_Game_Play:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-12
	add	hl,sp
	ld	sp,hl
;pong.c:262: while (!request_exit) // Check wether key press is ESC if so exit loop
	ld	hl,#_game + 4
	ld	-10 (ix),l
	ld	-9 (ix),h
	ld	de,#_game + 4
	ld	-2 (ix),e
	ld	-1 (ix),d
	ld	-4 (ix),e
	ld	-3 (ix),d
	ld	hl,#_game + 8
	ld	-6 (ix),l
	ld	-5 (ix),h
	ld	-8 (ix),e
	ld	-7 (ix),d
00123$:
	xor	a,a
	ld	hl,#_request_exit + 0
	or	a,(hl)
	jp	NZ,00126$
;pong.c:264: FLOS_WaitVRT();
	push	de
	call	_FLOS_WaitVRT
	pop	de
;pong.c:266: Game_MarkFrameTime(0xf00);
	push	de
	ld	hl,#0x0F00
	push	hl
	call	_Game_MarkFrameTime
	pop	af
	pop	de
;pong.c:267: SET_LIVE_SPRITE_REGISTER_BANK(game.shadow_sprite_register_bank^1);
	ld	bc,#_game + 12
	ld	a,(bc)
	xor	a,#0x01
	ld	c,a
	sla	c
	sla	c
	ld	a,c
	or	a,#0x09
	ld	hl,#_mm__vreg_sprctrl + 0
	ld	(hl), a
;pong.c:268: clear_shadow_sprite_regs();
	push	de
	call	_clear_shadow_sprite_regs
	pop	de
;pong.c:272: Sound_PlayFx();
	push	de
	call	_Sound_PlayFx
	pop	de
;pong.c:274: Game_HandlePlayerInput_PauseMode();
	push	de
	call	_Game_HandlePlayerInput_PauseMode
	pop	de
;pong.c:275: if(!game.is_paused)
	ld	l,-10 (ix)
	ld	h,-9 (ix)
	ld	a,(hl)
	or	a,a
	jr	NZ,00102$
;pong.c:276: Joystick_GetInput();
	push	de
	call	_Joystick_GetInput
	pop	de
00102$:
;pong.c:277: PoolSprites_FreeAllSprites();
	push	de
	call	_PoolSprites_FreeAllSprites
	pop	de
;pong.c:280: if(!game.is_paused && game.game_state == LEVEL) {
	ld	a,(de)
	or	a,a
	jr	NZ,00104$
	ld	hl,#_game
	ld	a,(hl)
	or	a,a
	jr	NZ,00104$
;pong.c:281: Game_HandlePlayerInput_Bat();
	push	de
	call	_Game_HandlePlayerInput_Bat
	pop	de
00104$:
;pong.c:284: if(!game.is_paused)
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	ld	a,(hl)
	or	a,a
	jr	NZ,00107$
;pong.c:285: PoolGameObj_ApplyFuncMoveToObjects();
	push	de
	call	_PoolGameObj_ApplyFuncMoveToObjects
	pop	de
00107$:
;pong.c:292: PoolGameObj_ApplyFuncDrawToObjects();
	push	de
	call	_PoolGameObj_ApplyFuncDrawToObjects
	pop	de
;pong.c:293: if(game.is_paused && game.is_debug_mode) {
	ld	l,-4 (ix)
	ld	h,-3 (ix)
	ld	a,(hl)
	or	a,a
	jr	Z,00109$
	ld	bc,#_game + 6
	ld	a,(bc)
	or	a,a
	jr	Z,00109$
;pong.c:294: Debug_Move();
	push	de
	call	_Debug_Move
	pop	de
;pong.c:295: Debug_Draw();
	push	de
	call	_Debug_Draw
	pop	de
00109$:
;pong.c:302: Game_ReInit_Watcher();
	push	de
	call	_Game_ReInit_Watcher
	pop	de
;pong.c:304: if(game.isMusicEnabled) {
	ld	l,-6 (ix)
	ld	h,-5 (ix)
	ld	a,(hl)
	or	a,a
	jr	Z,00112$
;pong.c:305: Music_PlayTracker();
	push	de
	call	_Music_PlayTracker
	pop	de
;pong.c:306: Music_UpdateSoundHardware();
	push	de
	call	_Music_UpdateSoundHardware
	pop	de
00112$:
;pong.c:310: if(game.isRequestSetState) {
	ld	bc,#_game + 1
	ld	a,(bc)
	or	a,a
	jr	Z,00116$
;pong.c:311: game.isRequestSetState = FALSE;
	ld	a,#0x00
	ld	(bc),a
;pong.c:312: if(!Game_SetState(game.new_state))
	ld	hl,#_game + 2
	ld	c,(hl)
	push	de
	ld	a,c
	push	af
	inc	sp
	call	_Game_SetState
	inc	sp
	ld	c,l
	pop	de
	xor	a,a
	or	a,c
;pong.c:313: return;
	jp	Z,00126$
00116$:
;pong.c:317: game.shadow_sprite_register_bank ^= 1;
	ld	hl,#_game + 12
	ld	-12 (ix),l
	ld	-11 (ix),h
	ld	a,(hl)
	xor	a,#0x01
	ld	l,-12 (ix)
	ld	h,-11 (ix)
	ld	(hl),a
;pong.c:318: if(!game.is_paused)
	ld	l,-8 (ix)
	ld	h,-7 (ix)
	ld	a,(hl)
	or	a,a
	jr	NZ,00118$
;pong.c:319: game.global_time++;
	ld	hl,#_game + 13
	ld	-12 (ix),l
	ld	-11 (ix),h
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	bc
	ld	l,-12 (ix)
	ld	h,-11 (ix)
	ld	(hl),c
	inc	hl
	ld	(hl),b
00118$:
;pong.c:320: Game_MarkFrameTime(0x000);
	push	de
	ld	hl,#0x0000
	push	hl
	call	_Game_MarkFrameTime
	pop	af
	pop	de
;pong.c:322: if(Keyboard_GetLastPressedScancode() == SC_LSHIFT) {
	push	de
	call	_Keyboard_GetLastPressedScancode
	ld	c,l
	pop	de
	ld	a,c
	sub	a,#0x12
	jr	NZ,00120$
;pong.c:323: debug.isShowFrameTime ^= 1; keyboard.prev_pressed_scancode = 0;
	ld	hl,#_debug + 1
	ld	-12 (ix),l
	ld	-11 (ix),h
	ld	a,(hl)
	xor	a,#0x01
	ld	l,-12 (ix)
	ld	h,-11 (ix)
	ld	(hl),a
	ld	a,#0x00
	ld	(#_keyboard + 2),a
00120$:
;pong.c:338: if(!Debug_CheckCurrentBank()) {
	push	de
	call	_Debug_CheckCurrentBank
	ld	c,l
	pop	de
	xor	a,a
	or	a,c
	jp	NZ,00123$
;pong.c:339: Game_MarkFrameTime(0x00F);
	push	de
	ld	hl,#0x000F
	push	hl
	call	_Game_MarkFrameTime
	pop	af
	pop	de
;pong.c:343: ENDASM();
;;
		           di
		           halt
		           
	jp	00123$
00126$:
	ld	sp,ix
	pop	ix
	ret
_Game_Play_end::
;pong.c:352: void Game_InitLevelBegining(void)
;	---------------------------------
; Function Game_InitLevelBegining
; ---------------------------------
_Game_InitLevelBegining_start::
_Game_InitLevelBegining:
;pong.c:354: scoreA.score = 0;  // Intialize score
	ld	hl, #_scoreA + 24
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;pong.c:355: scoreB.score = 0;
	ld	hl, #_scoreB + 24
	ld	(hl),#0x00
	inc	hl
	ld	(hl),#0x00
;pong.c:356: scoreA.num_rockets = scoreB.num_rockets = 3;
	ld	bc,#_scoreA + 34
	ld	de,#_scoreB + 34
	ld	a,#0x03
	ld	(de),a
	ld	(bc),a
	ret
_Game_InitLevelBegining_end::
;pong.c:362: int main (void)
;	---------------------------------
; Function main
; ---------------------------------
_main_start::
_main:
;pong.c:365: game.isRequestSetState = FALSE;
	ld	a,#0x00
	ld	(#_game + 1),a
;pong.c:366: loadingIcon.isLoaded = FALSE;
	ld	hl,#_loadingIcon
	ld	(hl),#0x00
;pong.c:367: game.isFLOSVideoMode = TRUE;
	ld	a,#0x01
	ld	(#_game + 9),a
;pong.c:368: debug.isShowFrameTime = FALSE;
	ld	a,#0x00
	ld	(#_debug + 1),a
;pong.c:374: if(!Debug_CheckCurrentBank())
	call	_Debug_CheckCurrentBank
	xor	a,a
	or	a,l
	jr	NZ,00102$
;pong.c:375: return NO_REBOOT;
	ld	hl,#0x0000
	ret
00102$:
;pong.c:377: initgraph();
	call	_initgraph
;pong.c:378: Game_SetState(STARTUP);
	ld	a,#0x03
	push	af
	inc	sp
	call	_Game_SetState
	inc	sp
;pong.c:380: if(!LoadingIcon_Load())
	call	_LoadingIcon_Load
	xor	a,a
	or	a,l
	jr	NZ,00104$
;pong.c:381: return NO_REBOOT;
	ld	hl,#0x0000
	ret
00104$:
;pong.c:385: if(!Game_LoadSinTable())
	call	_Game_LoadSinTable
	xor	a,a
	or	a,l
	jr	NZ,00106$
;pong.c:386: return REBOOT;
	ld	hl,#0x00FF
	ret
00106$:
;pong.c:387: if(!Sound_LoadSoundCode())
	call	_Sound_LoadSoundCode
	xor	a,a
	or	a,l
	jr	NZ,00108$
;pong.c:388: return REBOOT;
	ld	hl,#0x00FF
	ret
00108$:
;pong.c:390: if(!Sound_LoadSounds())
	call	_Sound_LoadSounds
	xor	a,a
	or	a,l
	jr	NZ,00110$
;pong.c:391: return REBOOT;
	ld	hl,#0x00FF
	ret
00110$:
;pong.c:392: if(!Sound_LoadFxDescriptors())
	call	_Sound_LoadFxDescriptors
	xor	a,a
	or	a,l
	jr	NZ,00112$
;pong.c:393: return REBOOT;
	ld	hl,#0x00FF
	ret
00112$:
;pong.c:394: Sound_InitFx();
	call	_Sound_InitFx
;pong.c:398: if(!load_sprites())
	call	_load_sprites
	xor	a,a
	or	a,l
	jr	NZ,00114$
;pong.c:399: return REBOOT;
	ld	hl,#0x00FF
	ret
00114$:
;pong.c:401: Keyboard_Init();
	call	_Keyboard_Init
;pong.c:402: install_irq_handler();
	call	_install_irq_handler
;pong.c:404: if(!Game_SetState(MENU))
	ld	a,#0x01
	push	af
	inc	sp
	call	_Game_SetState
	inc	sp
	xor	a,a
	or	a,l
	jr	NZ,00116$
;pong.c:405: return REBOOT;
	ld	hl,#0x00FF
	ret
00116$:
;pong.c:406: Game_Play (); // Game Engine
	call	_Game_Play
;pong.c:410: Sys_ClearIRQFlags(CLEAR_IRQ_KEYBOARD);
	ld	a,#0x01
	push	af
	inc	sp
	call	_Sys_ClearIRQFlags
	inc	sp
;pong.c:411: return REBOOT;
	ld	hl,#0x00FF
	ret
_main_end::
;pong.c:414: void Game_RequestSetState(GameState state)
;	---------------------------------
; Function Game_RequestSetState
; ---------------------------------
_Game_RequestSetState_start::
_Game_RequestSetState:
	push	ix
	ld	ix,#0
	add	ix,sp
;pong.c:416: game.isRequestSetState = TRUE;
	ld	a,#0x01
	ld	(#_game + 1),a
;pong.c:417: game.new_state = state;
	ld	bc,#_game + 2
	ld	a,4 (ix)
	ld	(bc),a
	pop	ix
	ret
_Game_RequestSetState_end::
;pong.c:421: BOOL Game_LoadStateData(GameState state, GameState prev_state)
;	---------------------------------
; Function Game_LoadStateData
; ---------------------------------
_Game_LoadStateData_start::
_Game_LoadStateData:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	dec	sp
;pong.c:457: for(i=0 ;i<num; i++)
	ld	c,#0x00
00104$:
;pong.c:458: if(state == gameStateData[i].s && prev_state == gameStateData[i].prev_s)
	ld	a,c
	cp	a,#0x03
	jr	NC,00107$
	rlca
	rlca
	rlca
	and	a,#0xF8
	ld	b, a
	add	a,#<_Game_LoadStateData_gameStateData_1_1
	ld	e,a
	ld	a,#>_Game_LoadStateData_gameStateData_1_1
	adc	a,#0x00
	ld	d,a
	ld	a,(de)
	ld	e,a
	ld	a,4 (ix)
	sub	e
	jr	NZ,00106$
	ld	a,#<_Game_LoadStateData_gameStateData_1_1
	add	a,b
	ld	b,a
	ld	a,#>_Game_LoadStateData_gameStateData_1_1
	adc	a,#0x00
	ld	e,a
	inc	b
	jr	NZ,00139$
	inc	e
00139$:
	ld	l,b
	ld	h,e
	ld	b,(hl)
	ld	a,5 (ix)
	sub	b
	jr	Z,00107$
;pong.c:459: break;
00106$:
;pong.c:457: for(i=0 ;i<num; i++)
	inc	c
	jr	00104$
00107$:
;pong.c:460: if(i == num) return TRUE;    // state was not found in struct, just return
	ld	a,c
	sub	a,#0x03
	jr	NZ,00109$
	ld	l,#0x01
	jp	00123$
00109$:
;pong.c:462: TileMap_Clear();
	push	bc
	call	_TileMap_Clear
	pop	bc
;pong.c:463: LoadingIcon_Enable(TRUE);
	push	bc
	ld	a,#0x01
	push	af
	inc	sp
	call	_LoadingIcon_Enable
	inc	sp
	pop	bc
;pong.c:466: pTilesDesc = gameStateData[i].tiles;
	ld	a,c
	rlca
	rlca
	rlca
	and	a,#0xF8
	ld	-3 (ix),a
	add	a,#<_Game_LoadStateData_gameStateData_1_1
	ld	l,a
	ld	a,#>_Game_LoadStateData_gameStateData_1_1
	adc	a,#0x00
	ld	h,a
	inc	hl
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
;pong.c:467: while(pTilesDesc->pFilenameTiles != NULL) {
00112$:
	ld	l,e
	ld	h,d
	ld	a,(hl)
	ld	-2 (ix),a
	inc	hl
	ld	a,(hl)
	ld	-1 (ix),a
	ld	a,-2 (ix)
	or	a,-1 (ix)
	jr	Z,00114$
;pong.c:468: if(!Background_LoadTiles(pTilesDesc->pFilenameTiles, pTilesDesc->vramAddrTiles))
	ld	c,e
	ld	b,d
	ld	l,c
	ld	h,b
	inc	hl
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	push	de
	push	bc
	ld	l,-2 (ix)
	ld	h,-1 (ix)
	push	hl
	call	_Background_LoadTiles
	pop	af
	pop	af
	ld	c,l
	pop	de
	xor	a,a
;pong.c:469: return FALSE;
	or	a,c
	jr	NZ,00111$
	ld	l,a
	jp	00123$
00111$:
;pong.c:470: pTilesDesc++;
	inc	de
	inc	de
	inc	de
	inc	de
	jr	00112$
00114$:
;pong.c:475: pFilename = gameStateData[i].pFilenameMusic;
	ld	a,#<_Game_LoadStateData_gameStateData_1_1
	add	a,-3 (ix)
	ld	l,a
	ld	a,#>_Game_LoadStateData_gameStateData_1_1
	adc	a,#0x00
	ld	h,a
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
;pong.c:476: if(pFilename) {
	ld	a,c
	or	a,b
	jr	Z,00118$
;pong.c:477: if(!Mod_LoadMusicModule(pFilename))
	push	bc
	call	_Mod_LoadMusicModule
	pop	af
;pong.c:478: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00116$
	ld	l,a
	jr	00123$
00116$:
;pong.c:479: MUSIC_Init();
	call	_MUSIC_Init
00118$:
;pong.c:482: LoadingIcon_Enable(FALSE);
	ld	a,#0x00
	push	af
	inc	sp
	call	_LoadingIcon_Enable
	inc	sp
;pong.c:484: pFilename = gameStateData[i].pFilenamePalette;
	ld	a,#<_Game_LoadStateData_gameStateData_1_1
	add	a,-3 (ix)
	ld	e,a
	ld	a,#>_Game_LoadStateData_gameStateData_1_1
	adc	a,#0x00
	ld	d,a
	ld	hl,#0x0006
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	c,e
	ld	b,d
;pong.c:485: if(pFilename) {
	ld	a,c
	or	a,b
	jr	Z,00122$
;pong.c:486: if(!Util_LoadPalette(pFilename))
	push	bc
	call	_Util_LoadPalette
	pop	af
;pong.c:487: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00122$
	ld	l,a
	jr	00123$
00122$:
;pong.c:489: Background_InitTilemap(0);
	ld	hl,#0x0000
	push	hl
	call	_Background_InitTilemap
	pop	af
;pong.c:491: return TRUE;
	ld	l,#0x01
00123$:
	ld	sp,ix
	pop	ix
	ret
_Game_LoadStateData_end::
__str_13:
	.ascii "MENU.TIL"
	.db 0x00
__str_14:
	.ascii "CREDITS.TIL"
	.db 0x00
__str_15:
	.ascii "B1.TIL"
	.db 0x00
__str_16:
	.ascii "BALLDRE2.MOD"
	.db 0x00
__str_17:
	.ascii "MENU.PAL"
	.db 0x00
__str_18:
	.ascii "MONDAY.MOD"
	.db 0x00
__str_19:
	.ascii "B1.PAL"
	.db 0x00
;pong.c:494: BOOL Game_SetState(GameState state)
;	---------------------------------
; Function Game_SetState
; ---------------------------------
_Game_SetState_start::
_Game_SetState:
	push	ix
	ld	ix,#0
	add	ix,sp
;pong.c:498: if(state == game.game_state)
	ld	hl,#_game
	ld	c,(hl)
	ld	a,4 (ix)
	sub	c
	jr	NZ,00102$
;pong.c:499: return TRUE;
	ld	l,#0x01
	jp	00119$
00102$:
;pong.c:501: prev_game_state = game.game_state;
;pong.c:502: game.game_state = state;
	ld	hl,#_game
	ld	a,4 (ix)
	ld	(hl),a
;pong.c:504: if(state == LEVEL) {
	xor	a,a
	or	a,4 (ix)
	jr	NZ,00106$
;pong.c:505: game.isMusicEnabled = FALSE;
	ld	de,#_game + 8
	ld	a,#0x00
	ld	(de),a
;pong.c:506: game.isSoundfxEnabled = TRUE;
	ld	de,#_game + 7
	ld	a,#0x01
	ld	(de),a
;pong.c:508: MUSIC_Silence();
	push	bc
	call	_MUSIC_Silence
	pop	bc
;pong.c:510: if(!Game_LoadStateData(state, prev_game_state))
	push	bc
	ld	a,c
	push	af
	inc	sp
	ld	a,4 (ix)
	push	af
	inc	sp
	call	_Game_LoadStateData
	pop	af
	ld	a,l
	pop	bc
	ld	b,a
;pong.c:511: return FALSE;
	or	a,a
	jr	NZ,00104$
	ld	l,a
	jp	00119$
00104$:
;pong.c:515: Game_InitLevelBegining();
	push	bc
	call	_Game_InitLevelBegining
	pop	bc
;pong.c:516: Game_Initialize();
	push	bc
	call	_Game_Initialize
	pop	bc
;pong.c:517: Game_InitializeLevelGameObjects();
	push	bc
	call	_Game_InitializeLevelGameObjects
	pop	bc
00106$:
;pong.c:519: if(state == MENU) {
	ld	a,4 (ix)
	sub	a,#0x01
	jr	NZ,00114$
;pong.c:520: game.isMusicEnabled = TRUE;
	ld	de,#_game + 8
	ld	a,#0x01
	ld	(de),a
;pong.c:521: game.isSoundfxEnabled = FALSE;
	ld	de,#_game + 7
	ld	a,#0x00
	ld	(de),a
;pong.c:523: if(prev_game_state == CREDITS)
	ld	a,c
	sub	a,#0x02
	jr	NZ,00108$
;pong.c:524: Background_InitTilemap(0);
	push	bc
	ld	hl,#0x0000
	push	hl
	call	_Background_InitTilemap
	pop	af
	pop	bc
00108$:
;pong.c:525: if(prev_game_state == LEVEL)
	xor	a,a
	or	a,c
	jr	NZ,00110$
;pong.c:526: MUSIC_Silence();
	push	bc
	call	_MUSIC_Silence
	pop	bc
00110$:
;pong.c:528: if(!Game_LoadStateData(state, prev_game_state))
	ld	a,c
	push	af
	inc	sp
	ld	a,4 (ix)
	push	af
	inc	sp
	call	_Game_LoadStateData
	pop	af
;pong.c:529: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00112$
	ld	l,a
	jr	00119$
00112$:
;pong.c:532: Game_Initialize();
	call	_Game_Initialize
;pong.c:533: Game_InitializeMenuGameObjects();
	call	_Game_InitializeMenuGameObjects
00114$:
;pong.c:536: if(state == CREDITS) {
	ld	a,4 (ix)
	sub	a,#0x02
	jr	NZ,00116$
;pong.c:539: Background_InitTilemap(TILES_CREDITS_VRAM_ADDR/0x100);
	ld	hl,#0x0160
	push	hl
	call	_Background_InitTilemap
	pop	af
00116$:
;pong.c:542: if(state == STARTUP) {
	ld	a,4 (ix)
	sub	a,#0x03
	jr	NZ,00118$
;pong.c:543: TileMap_Clear();
	call	_TileMap_Clear
00118$:
;pong.c:548: Keyboard_Init();
	call	_Keyboard_Init
;pong.c:549: Input_ClearPlayersInput();
	call	_Input_ClearPlayersInput
;pong.c:550: return TRUE;
	ld	l,#0x01
00119$:
	pop	ix
	ret
_Game_SetState_end::
;pong.c:577: void setfillstyle (int color1,int color2)
;	---------------------------------
; Function setfillstyle
; ---------------------------------
_setfillstyle_start::
_setfillstyle:
	push	ix
	ld	ix,#0
	add	ix,sp
;pong.c:580: cur_color = color2;
	ld	a,6 (ix)
	ld	hl,#_cur_color + 0
	ld	(hl), a
	ld	a,7 (ix)
	ld	hl,#_cur_color + 1
	ld	(hl), a
	pop	ix
	ret
_setfillstyle_end::
;pong.c:591: BOOL Game_LoadSinTable(void)
;	---------------------------------
; Function Game_LoadSinTable
; ---------------------------------
_Game_LoadSinTable_start::
_Game_LoadSinTable:
;pong.c:593: if(!load_file_to_buffer("SINE_TAB.BIN", 0, (byte*)MULT_TABLE, 0x200, 0))
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0200
	push	hl
	ld	h, #0x06
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0000
	push	hl
	ld	hl,#__str_20
	push	hl
	call	_load_file_to_buffer
	ld	iy,#0x000D
	add	iy,sp
	ld	sp,iy
;pong.c:594: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00102$
	ld	l,a
	ret
00102$:
;pong.c:595: return TRUE;
	ld	l,#0x01
	ret
_Game_LoadSinTable_end::
__str_20:
	.ascii "SINE_TAB.BIN"
	.db 0x00
;pong.c:598: void Game_MarkFrameTime(ushort color)
;	---------------------------------
; Function Game_MarkFrameTime
; ---------------------------------
_Game_MarkFrameTime_start::
_Game_MarkFrameTime:
	push	ix
	ld	ix,#0
	add	ix,sp
;pong.c:600: if(debug.isShowFrameTime)
	ld	bc,#_debug + 1
	ld	a,(bc)
	or	a,a
	jr	Z,00103$
;pong.c:601: MarkFrameTime(color);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_MarkFrameTime
	pop	af
00103$:
	pop	ix
	ret
_Game_MarkFrameTime_end::
	.area _CODE
	.area _CABS
