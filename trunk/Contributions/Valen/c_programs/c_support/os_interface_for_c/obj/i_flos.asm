;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 2.9.0 #5416 (Mar 22 2009) (MINGW32)
; This file was generated Tue Jun 08 18:57:11 2010
;--------------------------------------------------------
	.module i_flos
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _pFunc
	.globl _g_flos_hw_lasterror
	.globl _g_flos_lasterror
	.globl _g_a1_byte_result
	.globl _MarkFrameTime
	.globl _FLOS_GetLastError
	.globl _FLOS_CheckDiskAvailable
	.globl _FLOS_MakeDir
	.globl _FLOS_ChangeDir
	.globl _FLOS_ParentDir
	.globl _FLOS_RootDir
	.globl _FLOS_DeleteDir
	.globl _FLOS_StoreDirPosition
	.globl _FLOS_RestoreDirPosition
	.globl _FLOS_GetTotalSectors
	.globl _FLOS_FindFile
	.globl _FLOS_SetLoadLength
	.globl _FLOS_SetFilePointer
	.globl _FLOS_ForceLoad
	.globl _FLOS_CreateFile
	.globl _FLOS_EraseFile
	.globl _FLOS_WriteBytesToFile
	.globl _FLOS_PrintString
	.globl _FLOS_ClearScreen
	.globl _FLOS_FlosDisplay
	.globl _FLOS_WaitVRT
	.globl _FLOS_SetPen
	.globl _FLOS_SetCursorPos
	.globl _FLOS_WaitKeyPress
	.globl _FLOS_GetKeyPress
	.globl _FLOS_DirListFirstEntry
	.globl _FLOS_DirListGetEntry
	.globl _FLOS_DirListNextEntry
	.globl _FLOS_GetDirName
	.globl _FLOS_GetVersion
	.globl _FLOS_PrintStringLFCR
	.globl _FLOS_GetCmdLine
	.globl _FLOS_SetSpawnCmdLine
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
;  ram data
;--------------------------------------------------------
	.area _DATA
_g_a1_byte_result::
	.ds 1
_g_flos_lasterror::
	.ds 1
_g_flos_hw_lasterror::
	.ds 1
_pFunc::
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
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;i_flos.c:44: void MarkFrameTime(ushort color)
;	---------------------------------
; Function MarkFrameTime
; ---------------------------------
_MarkFrameTime_start::
_MarkFrameTime:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:47: *p = color;
	ld	iy,#0x0000
	ld	a,4 (ix)
	ld	0 (iy),a
	ld	a,5 (ix)
	ld	1 (iy),a
	pop	ix
	ret
_MarkFrameTime_end::
;i_flos.c:55: byte FLOS_GetLastError(void) 
;	---------------------------------
; Function FLOS_GetLastError
; ---------------------------------
_FLOS_GetLastError_start::
_FLOS_GetLastError:
;i_flos.c:57: return g_flos_lasterror;
	ld	iy,#_g_flos_lasterror
	ld	l,0 (iy)
	ret
_FLOS_GetLastError_end::
;i_flos.c:76: BOOL FLOS_CheckDiskAvailable(void)
;	---------------------------------
; Function FLOS_CheckDiskAvailable
; ---------------------------------
_FLOS_CheckDiskAvailable_start::
_FLOS_CheckDiskAvailable:
;i_flos.c:79: CALL_FLOS_CODE(KJT_CHECK_DISK_AVAILABLE);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xD7
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:81: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:82: if(!result) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;i_flos.c:83: g_flos_lasterror = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	l, #0x81
	ld	a,(hl)
	ld	hl,#_g_flos_lasterror + 0
	ld	(hl), a
00102$:
;i_flos.c:86: return result;
	ld	l,c
	ret
_FLOS_CheckDiskAvailable_end::
;i_flos.c:91: BOOL FLOS_MakeDir(const char* pDirName)
;	---------------------------------
; Function FLOS_MakeDir
; ---------------------------------
_FLOS_MakeDir_start::
_FLOS_MakeDir:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:94: *PTRTO_I_DATA(I_DATA, word) = (word) pDirName;
	ld	iy,#0x5080
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:96: CALL_FLOS_CODE(KJT_MAKE_DIR);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xE0
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:98: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:99: if(!result) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;i_flos.c:100: g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	l, #0x81
	ld	a,(hl)
	ld	iy,#_g_flos_lasterror
	ld	0 (iy),a
;i_flos.c:101: g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
	ld	l, #0x82
	ld	a,(hl)
	ld	hl,#_g_flos_hw_lasterror + 0
	ld	(hl), a
00102$:
;i_flos.c:104: return result;
	ld	l,c
	pop	ix
	ret
_FLOS_MakeDir_end::
;i_flos.c:107: BOOL FLOS_ChangeDir(const char* pDirName)
;	---------------------------------
; Function FLOS_ChangeDir
; ---------------------------------
_FLOS_ChangeDir_start::
_FLOS_ChangeDir:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:110: *PTRTO_I_DATA(I_DATA, word) = (word) pDirName;
	ld	iy,#0x5080
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:112: CALL_FLOS_CODE(KJT_CHANGE_DIR);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xE3
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:114: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:115: if(!result) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;i_flos.c:116: g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	l, #0x81
	ld	a,(hl)
	ld	iy,#_g_flos_lasterror
	ld	0 (iy),a
;i_flos.c:117: g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
	ld	l, #0x82
	ld	a,(hl)
	ld	hl,#_g_flos_hw_lasterror + 0
	ld	(hl), a
00102$:
;i_flos.c:120: return result;
	ld	l,c
	pop	ix
	ret
_FLOS_ChangeDir_end::
;i_flos.c:123: BOOL FLOS_ParentDir(void)
;	---------------------------------
; Function FLOS_ParentDir
; ---------------------------------
_FLOS_ParentDir_start::
_FLOS_ParentDir:
;i_flos.c:126: CALL_FLOS_CODE(KJT_PARENT_DIR);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xE6
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:128: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:129: if(!result) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;i_flos.c:130: g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	l, #0x81
	ld	a,(hl)
	ld	iy,#_g_flos_lasterror
	ld	0 (iy),a
;i_flos.c:131: g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
	ld	l, #0x82
	ld	a,(hl)
	ld	hl,#_g_flos_hw_lasterror + 0
	ld	(hl), a
00102$:
;i_flos.c:134: return result;
	ld	l,c
	ret
_FLOS_ParentDir_end::
;i_flos.c:139: void FLOS_RootDir(void)
;	---------------------------------
; Function FLOS_RootDir
; ---------------------------------
_FLOS_RootDir_start::
_FLOS_RootDir:
;i_flos.c:142: CALL_FLOS_CODE(KJT_ROOT_DIR);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xE9
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	ret
_FLOS_RootDir_end::
;i_flos.c:154: BOOL FLOS_DeleteDir(const char* pDirName)
;	---------------------------------
; Function FLOS_DeleteDir
; ---------------------------------
_FLOS_DeleteDir_start::
_FLOS_DeleteDir:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:157: *PTRTO_I_DATA(I_DATA, word) = (word) pDirName;
	ld	iy,#0x5080
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:159: CALL_FLOS_CODE(KJT_DELETE_DIR);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xEC
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:161: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:162: if(!result) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;i_flos.c:163: g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	l, #0x81
	ld	a,(hl)
	ld	iy,#_g_flos_lasterror
	ld	0 (iy),a
;i_flos.c:164: g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
	ld	l, #0x82
	ld	a,(hl)
	ld	hl,#_g_flos_hw_lasterror + 0
	ld	(hl), a
00102$:
;i_flos.c:167: return result;
	ld	l,c
	pop	ix
	ret
_FLOS_DeleteDir_end::
;i_flos.c:171: void FLOS_StoreDirPosition(void)
;	---------------------------------
; Function FLOS_StoreDirPosition
; ---------------------------------
_FLOS_StoreDirPosition_start::
_FLOS_StoreDirPosition:
;i_flos.c:173: CALL_FLOS_CODE(KJT_STORE_DIR_POSITION);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x76
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	ret
_FLOS_StoreDirPosition_end::
;i_flos.c:176: void FLOS_RestoreDirPosition(void)
;	---------------------------------
; Function FLOS_RestoreDirPosition
; ---------------------------------
_FLOS_RestoreDirPosition_start::
_FLOS_RestoreDirPosition:
;i_flos.c:178: CALL_FLOS_CODE(KJT_RESTORE_DIR_POSITION);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x79
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	ret
_FLOS_RestoreDirPosition_end::
;i_flos.c:181: dword FLOS_GetTotalSectors(void)
;	---------------------------------
; Function FLOS_GetTotalSectors
; ---------------------------------
_FLOS_GetTotalSectors_start::
_FLOS_GetTotalSectors:
;i_flos.c:183: CALL_FLOS_CODE(KJT_GET_TOTAL_SECTORS);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xFB
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
;i_flos.c:185: return  *PTRTO_I_DATA(I_DATA, dword);
	ld	hl,#0x5080
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	l,c
	ld	h,b
	ret
_FLOS_GetTotalSectors_end::
;i_flos.c:189: BOOL FLOS_FindFile(FLOS_FILE* const pFile, const char* pFileName)
;	---------------------------------
; Function FLOS_FindFile
; ---------------------------------
_FLOS_FindFile_start::
_FLOS_FindFile:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	dec	sp
;i_flos.c:192: *PTRTO_I_DATA(I_DATA, word) = (word) pFileName;
	ld	iy,#0x5080
	ld	c,6 (ix)
	ld	b,7 (ix)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:194: CALL_FLOS_CODE(KJT_FIND_FILE);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xEF
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00107$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00107$:
;i_flos.c:196: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	a,(hl)
	ld	-1 (ix),a
;i_flos.c:197: if(result) {
	xor	a,a
	or	a,-1 (ix)
	jr	Z,00102$
;i_flos.c:198: pFile->z80_address = *PTRTO_I_DATA(I_DATA+3, word);
	ld	e,4 (ix)
	ld	d,5 (ix)
	ld	l, #0x83
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	l,e
	ld	h,d
	ld	(hl),c
	inc	hl
	ld	(hl),b
;i_flos.c:200: pFile->z80_bank    = *PTRTO_I_DATA(I_DATA+2, byte);
	ld	c,e
	ld	b,d
	inc	bc
	inc	bc
	ld	hl,#0x5082
	ld	a,(hl)
	ld	(bc),a
;i_flos.c:201: pFile->size        = *PTRTO_I_DATA(I_DATA+5, dword);
	ld	hl,#0x0003
	add	hl,de
	ld	-3 (ix),l
	ld	-2 (ix),h
	ld	hl,#0x5085
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	l,-3 (ix)
	ld	h,-2 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
	jr	00103$
00102$:
;i_flos.c:204: g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	hl,#0x5081
	ld	a,(hl)
	ld	iy,#_g_flos_lasterror
	ld	0 (iy),a
;i_flos.c:205: g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
	ld	l, #0x82
	ld	a,(hl)
	ld	hl,#_g_flos_hw_lasterror + 0
	ld	(hl), a
00103$:
;i_flos.c:208: return result; 
	ld	l,-1 (ix)
	ld	sp,ix
	pop	ix
	ret
_FLOS_FindFile_end::
;i_flos.c:211: void FLOS_SetLoadLength(const dword len)
;	---------------------------------
; Function FLOS_SetLoadLength
; ---------------------------------
_FLOS_SetLoadLength_start::
_FLOS_SetLoadLength:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:213: *PTRTO_I_DATA(I_DATA, dword) = (dword) len;
	ld	iy,#0x5080
	ld	a,4 (ix)
	ld	0 (iy),a
	ld	a,5 (ix)
	ld	1 (iy),a
	ld	a,6 (ix)
	ld	2 (iy),a
	ld	a,7 (ix)
	ld	3 (iy),a
;i_flos.c:215: CALL_FLOS_CODE(KJT_SET_LOAD_LENGTH);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x1F
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	pop	ix
	ret
_FLOS_SetLoadLength_end::
;i_flos.c:219: void FLOS_SetFilePointer(const dword p)
;	---------------------------------
; Function FLOS_SetFilePointer
; ---------------------------------
_FLOS_SetFilePointer_start::
_FLOS_SetFilePointer:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:221: *PTRTO_I_DATA(I_DATA, dword) = (dword) p;
	ld	iy,#0x5080
	ld	a,4 (ix)
	ld	0 (iy),a
	ld	a,5 (ix)
	ld	1 (iy),a
	ld	a,6 (ix)
	ld	2 (iy),a
	ld	a,7 (ix)
	ld	3 (iy),a
;i_flos.c:223: CALL_FLOS_CODE(KJT_SET_FILE_POINTER);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x1C
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	pop	ix
	ret
_FLOS_SetFilePointer_end::
;i_flos.c:226: BOOL FLOS_ForceLoad(const byte* address, const byte bank)
;	---------------------------------
; Function FLOS_ForceLoad
; ---------------------------------
_FLOS_ForceLoad_start::
_FLOS_ForceLoad:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:229: *PTRTO_I_DATA(I_DATA,   word) = (word) address;
	ld	iy,#0x5080
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:230: *PTRTO_I_DATA(I_DATA+2, byte) = (byte) bank;
	ld	iy,#0x5082
	ld	a,6 (ix)
	ld	(iy),a
;i_flos.c:232: CALL_FLOS_CODE(KJT_FORCE_LOAD);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x19
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:234: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:235: if(!result) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;i_flos.c:236: g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	l, #0x81
	ld	a,(hl)
	ld	iy,#_g_flos_lasterror
	ld	0 (iy),a
;i_flos.c:237: g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
	ld	l, #0x82
	ld	a,(hl)
	ld	hl,#_g_flos_hw_lasterror + 0
	ld	(hl), a
00102$:
;i_flos.c:240: return result; 
	ld	l,c
	pop	ix
	ret
_FLOS_ForceLoad_end::
;i_flos.c:249: BOOL FLOS_CreateFile(const byte* pFilename)
;	---------------------------------
; Function FLOS_CreateFile
; ---------------------------------
_FLOS_CreateFile_start::
_FLOS_CreateFile:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:255: *PTRTO_I_DATA(I_DATA,   word) = (word) pFilename;
	ld	iy,#0x5080
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:256: *PTRTO_I_DATA(I_DATA+2, word) = (word) default_z80_address;
	ld	iy,#0x5082
	ld	0 (iy),#0x00
	ld	1 (iy),#0x00
;i_flos.c:257: *PTRTO_I_DATA(I_DATA+4, byte) = (byte) default_z80_bank;
	ld	iy,#0x5084
	ld	(iy),#0x00
;i_flos.c:259: CALL_FLOS_CODE(KJT_CREATE_FILE);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x0A
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:261: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:262: if(!result) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;i_flos.c:263: g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	l, #0x81
	ld	a,(hl)
	ld	iy,#_g_flos_lasterror
	ld	0 (iy),a
;i_flos.c:264: g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
	ld	l, #0x82
	ld	a,(hl)
	ld	hl,#_g_flos_hw_lasterror + 0
	ld	(hl), a
00102$:
;i_flos.c:267: return result; 
	ld	l,c
	pop	ix
	ret
_FLOS_CreateFile_end::
;i_flos.c:271: BOOL FLOS_EraseFile(const byte* pFilename)
;	---------------------------------
; Function FLOS_EraseFile
; ---------------------------------
_FLOS_EraseFile_start::
_FLOS_EraseFile:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:274: *PTRTO_I_DATA(I_DATA,   word) = (word) pFilename;
	ld	iy,#0x5080
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:276: CALL_FLOS_CODE(KJT_ERASE_FILE);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xF8
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:278: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:279: if(!result) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;i_flos.c:280: g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	l, #0x81
	ld	a,(hl)
	ld	iy,#_g_flos_lasterror
	ld	0 (iy),a
;i_flos.c:281: g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
	ld	l, #0x82
	ld	a,(hl)
	ld	hl,#_g_flos_hw_lasterror + 0
	ld	(hl), a
00102$:
;i_flos.c:284: return result; 
	ld	l,c
	pop	ix
	ret
_FLOS_EraseFile_end::
;i_flos.c:289: BOOL FLOS_WriteBytesToFile(const byte* pFilename, byte* address, const byte bank, const dword len)
;	---------------------------------
; Function FLOS_WriteBytesToFile
; ---------------------------------
_FLOS_WriteBytesToFile_start::
_FLOS_WriteBytesToFile:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:292: *PTRTO_I_DATA(I_DATA,   word)  = (word) pFilename;
	ld	iy,#0x5080
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:293: *PTRTO_I_DATA(I_DATA+2, word)  = (word) address;
	ld	iy,#0x5082
	ld	c,6 (ix)
	ld	b,7 (ix)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:294: *PTRTO_I_DATA(I_DATA+4, byte)  = bank;
	ld	iy,#0x5084
	ld	a,8 (ix)
	ld	(iy),a
;i_flos.c:295: *PTRTO_I_DATA(I_DATA+5, dword) = len;
	ld	iy,#0x5085
	ld	a,9 (ix)
	ld	0 (iy),a
	ld	a,10 (ix)
	ld	1 (iy),a
	ld	a,11 (ix)
	ld	2 (iy),a
	ld	a,12 (ix)
	ld	3 (iy),a
;i_flos.c:297: CALL_FLOS_CODE(KJT_WRITE_BYTES_TO_FILE);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x13
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:299: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:300: if(!result) {
	xor	a,a
	or	a,c
	jr	NZ,00102$
;i_flos.c:301: g_flos_lasterror    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	l, #0x81
	ld	a,(hl)
	ld	iy,#_g_flos_lasterror
	ld	0 (iy),a
;i_flos.c:302: g_flos_hw_lasterror = *PTRTO_I_DATA(I_DATA+2, byte);
	ld	l, #0x82
	ld	a,(hl)
	ld	hl,#_g_flos_hw_lasterror + 0
	ld	(hl), a
00102$:
;i_flos.c:305: return result; 
	ld	l,c
	pop	ix
	ret
_FLOS_WriteBytesToFile_end::
;i_flos.c:311: void FLOS_PrintString(const char* string)
;	---------------------------------
; Function FLOS_PrintString
; ---------------------------------
_FLOS_PrintString_start::
_FLOS_PrintString:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:313: *PTRTO_I_DATA(I_DATA, word) = (word) string;
	ld	iy,#0x5080
	ld	c,4 (ix)
	ld	b,5 (ix)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:315: CALL_FLOS_CODE(KJT_PRINT_STRING);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xB3
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	pop	ix
	ret
_FLOS_PrintString_end::
;i_flos.c:319: void FLOS_ClearScreen(void)
;	---------------------------------
; Function FLOS_ClearScreen
; ---------------------------------
_FLOS_ClearScreen_start::
_FLOS_ClearScreen:
;i_flos.c:321: CALL_FLOS_CODE(KJT_CLEAR_SCREEN);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xB6
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	ret
_FLOS_ClearScreen_end::
;i_flos.c:326: void FLOS_FlosDisplay(void)
;	---------------------------------
; Function FLOS_FlosDisplay
; ---------------------------------
_FLOS_FlosDisplay_start::
_FLOS_FlosDisplay:
;i_flos.c:328: CALL_FLOS_CODE(KJT_FLOS_DISPLAY);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x64
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	ret
_FLOS_FlosDisplay_end::
;i_flos.c:334: void FLOS_WaitVRT(void)
;	---------------------------------
; Function FLOS_WaitVRT
; ---------------------------------
_FLOS_WaitVRT_start::
_FLOS_WaitVRT:
;i_flos.c:336: CALL_FLOS_CODE(KJT_WAIT_VRT);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xBF
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	ret
_FLOS_WaitVRT_end::
;i_flos.c:340: void FLOS_SetPen(byte color)
;	---------------------------------
; Function FLOS_SetPen
; ---------------------------------
_FLOS_SetPen_start::
_FLOS_SetPen:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:343: *PTRTO_I_DATA(I_DATA,   byte) = color;
	ld	iy,#0x5080
	ld	a,4 (ix)
	ld	(iy),a
;i_flos.c:345: CALL_FLOS_CODE(KJT_SET_PEN);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x55
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	pop	ix
	ret
_FLOS_SetPen_end::
;i_flos.c:349: BOOL FLOS_SetCursorPos(byte x, byte y)
;	---------------------------------
; Function FLOS_SetCursorPos
; ---------------------------------
_FLOS_SetCursorPos_start::
_FLOS_SetCursorPos:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:353: *PTRTO_I_DATA(I_DATA,   byte) = (byte) x;
	ld	iy,#0x5080
	ld	a,4 (ix)
	ld	(iy),a
;i_flos.c:354: *PTRTO_I_DATA(I_DATA+1, byte) = (byte) y;
	ld	iy,#0x5081
	ld	a,5 (ix)
	ld	(iy),a
;i_flos.c:356: CALL_FLOS_CODE(KJT_SET_CURSOR_POSITION);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x34
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
;i_flos.c:358: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:360: return result; 
	ld	l,c
	pop	ix
	ret
_FLOS_SetCursorPos_end::
;i_flos.c:366: void FLOS_WaitKeyPress(byte* pASCII, byte* pScancode)
;	---------------------------------
; Function FLOS_WaitKeyPress
; ---------------------------------
_FLOS_WaitKeyPress_start::
_FLOS_WaitKeyPress:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:369: CALL_FLOS_CODE(KJT_WAIT_KEY_PRESS);
	ld	hl,#_pFunc + 0
	ld	(hl), #0xFE
	ld	iy,#_pFunc
	ld	1 (iy),#0x50
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
;i_flos.c:371: *pScancode = *PTRTO_I_DATA(I_DATA,   byte);
	ld	c,6 (ix)
	ld	b,7 (ix)
	push	bc
	pop	iy
	ld	hl,#0x5080
	ld	a,(hl)
	ld	(iy),a
;i_flos.c:372: *pASCII    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	pop	iy
	ld	l, #0x81
	ld	a,(hl)
	ld	(iy),a
	pop	ix
	ret
_FLOS_WaitKeyPress_end::
;i_flos.c:377: BOOL FLOS_GetKeyPress(byte* pASCII, byte* pScancode)
;	---------------------------------
; Function FLOS_GetKeyPress
; ---------------------------------
_FLOS_GetKeyPress_start::
_FLOS_GetKeyPress:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:380: CALL_FLOS_CODE(KJT_GET_KEY);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x01
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:382: *pScancode = *PTRTO_I_DATA(I_DATA,   byte);
	ld	c,6 (ix)
	ld	b,7 (ix)
	push	bc
	pop	iy
	ld	hl,#0x5080
	ld	c,(hl)
	ld	(iy),c
;i_flos.c:383: *pASCII    = *PTRTO_I_DATA(I_DATA+1, byte);
	ld	e,4 (ix)
	ld	d,5 (ix)
	push	de
	pop	iy
	ld	l, #0x81
	ld	a,(hl)
	ld	(iy),a
;i_flos.c:386: return (*pScancode == 0) ?  FALSE : TRUE;
	xor	a,a
	or	a,c
	sub	a,#0x01
	ld	a,#0x00
	rla
	or	a,a
	jr	Z,00103$
	ld	c,#0x00
	jr	00104$
00103$:
	ld	c,#0x01
00104$:
	ld	l,c
	pop	ix
	ret
_FLOS_GetKeyPress_end::
;i_flos.c:391: void FLOS_DirListFirstEntry(void)
;	---------------------------------
; Function FLOS_DirListFirstEntry
; ---------------------------------
_FLOS_DirListFirstEntry_start::
_FLOS_DirListFirstEntry:
;i_flos.c:393: CALL_FLOS_CODE(KJT_DIR_LIST_FIRST_ENTRY);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x3D
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
	ret
_FLOS_DirListFirstEntry_end::
;i_flos.c:399: BOOL FLOS_DirListGetEntry(FLOS_DIR_ENTRY* pEntry)
;	---------------------------------
; Function FLOS_DirListGetEntry
; ---------------------------------
_FLOS_DirListGetEntry_start::
_FLOS_DirListGetEntry:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	dec	sp
;i_flos.c:403: CALL_FLOS_CODE(KJT_DIR_LIST_GET_ENTRY);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x40
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:405: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
	ld	a,(hl)
	ld	-1 (ix),a
;i_flos.c:406: if(result) {
	xor	a,a
	or	a,-1 (ix)
	jp	Z,00102$
;i_flos.c:407: pEntry->pFilename = (const char*) ( *PTRTO_I_DATA(I_DATA+1, word) );
	ld	e,4 (ix)
	ld	d,5 (ix)
	ld	l, #0x81
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	l,e
	ld	h,d
	ld	(hl),c
	inc	hl
	ld	(hl),b
;i_flos.c:408: pEntry->file_flag =                 *PTRTO_I_DATA(I_DATA+3, byte);
	ld	hl,#0x0006
	add	hl,de
	ld	c,l
	ld	b,h
	ld	hl,#0x5083
	ld	a,(hl)
	ld	(bc),a
;i_flos.c:409: pEntry->err_code  =                 *PTRTO_I_DATA(I_DATA+4, byte);
	ld	hl,#0x0007
	add	hl,de
	ld	c,l
	ld	b,h
	ld	hl,#0x5084
	ld	a,(hl)
	ld	(bc),a
;i_flos.c:410: pEntry->len       =                 *PTRTO_I_DATA(I_DATA+5, dword);
	ld	hl,#0x0002
	add	hl,de
	ld	-3 (ix),l
	ld	-2 (ix),h
	ld	hl,#0x5085
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	l,-3 (ix)
	ld	h,-2 (ix)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
00102$:
;i_flos.c:416: return result; 
	ld	l,-1 (ix)
	ld	sp,ix
	pop	ix
	ret
_FLOS_DirListGetEntry_end::
;i_flos.c:422: byte FLOS_DirListNextEntry(void)
;	---------------------------------
; Function FLOS_DirListNextEntry
; ---------------------------------
_FLOS_DirListNextEntry_start::
_FLOS_DirListNextEntry:
;i_flos.c:426: CALL_FLOS_CODE(KJT_DIR_LIST_NEXT_ENTRY);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x43
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
;i_flos.c:428: result = *PTRTO_I_DATA(I_DATA, byte);
	ld	hl,#0x5080
;i_flos.c:430: return result; 
	ld	l,(hl)
	ret
_FLOS_DirListNextEntry_end::
;i_flos.c:436: const char* FLOS_GetDirName(void)
;	---------------------------------
; Function FLOS_GetDirName
; ---------------------------------
_FLOS_GetDirName_start::
_FLOS_GetDirName:
;i_flos.c:441: CALL_FLOS_CODE(KJT_GET_DIR_NAME);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x67
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00106$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00106$:
;i_flos.c:443: result = *PTRTO_I_DATA(I_DATA,   byte);
	ld	hl,#0x5080
	ld	c,(hl)
;i_flos.c:444: w      = *PTRTO_I_DATA(I_DATA+1, word);
	ld	l, #0x81
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
;i_flos.c:446: return (result ? (const char*)w : NULL);
	xor	a,a
	or	a,c
	jr	Z,00103$
	ld	c,e
	ld	b,d
	jr	00104$
00103$:
	ld	bc,#0x0000
00104$:
	ld	l,c
	ld	h,b
	ret
_FLOS_GetDirName_end::
;i_flos.c:452: void FLOS_GetVersion(word* os_version_word, word* hw_version_word)
;	---------------------------------
; Function FLOS_GetVersion
; ---------------------------------
_FLOS_GetVersion_start::
_FLOS_GetVersion:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:455: CALL_FLOS_CODE(KJT_GET_VERSION);
	ld	hl,#_pFunc + 0
	ld	(hl), #0x31
	ld	iy,#_pFunc
	ld	1 (iy),#0x51
	ld	hl,#00103$
	push	hl
	ld	hl,(_pFunc)
	jp	(hl)
00103$:
;i_flos.c:457: *os_version_word = *PTRTO_I_DATA(I_DATA+0, word);
	ld	c,4 (ix)
	ld	b,5 (ix)
	push	bc
	pop	iy
	ld	hl,#0x5080
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	0 (iy),c
	ld	1 (iy),b
;i_flos.c:458: *hw_version_word = *PTRTO_I_DATA(I_DATA+2, word);
	ld	c,6 (ix)
	ld	b,7 (ix)
	push	bc
	pop	iy
	ld	hl,#0x5082
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	0 (iy),c
	ld	1 (iy),b
	pop	ix
	ret
_FLOS_GetVersion_end::
;i_flos.c:465: void FLOS_PrintStringLFCR(const char* string)
;	---------------------------------
; Function FLOS_PrintStringLFCR
; ---------------------------------
_FLOS_PrintStringLFCR_start::
_FLOS_PrintStringLFCR:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:467: FLOS_PrintString(string);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_FLOS_PrintString
	pop	af
;i_flos.c:468: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_0
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	ix
	ret
_FLOS_PrintStringLFCR_end::
__str_0:
	.db 0x0B
	.db 0x00
;i_flos.c:474: char* FLOS_GetCmdLine(void)
;	---------------------------------
; Function FLOS_GetCmdLine
; ---------------------------------
_FLOS_GetCmdLine_start::
_FLOS_GetCmdLine:
;i_flos.c:476: return flos_cmdline;
	ld	hl,(_flos_cmdline)
	ret
_FLOS_GetCmdLine_end::
;i_flos.c:481: BOOL FLOS_SetSpawnCmdLine(const char* line)
;	---------------------------------
; Function FLOS_SetSpawnCmdLine
; ---------------------------------
_FLOS_SetSpawnCmdLine_start::
_FLOS_SetSpawnCmdLine:
	push	ix
	ld	ix,#0
	add	ix,sp
;i_flos.c:483: if(strlen(line) >= SPAWN_CMD_LINE_BUFFER_LEN)
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_strlen
	pop	af
	ld	b,h
	ld	a,l
	sub	a,#0x28
	ld	a,b
	sbc	a,#0x00
	jp	M,00102$
;i_flos.c:484: return FALSE;
	ld	l,#0x00
	jr	00103$
00102$:
;i_flos.c:486: flos_spawn_cmd[0] = 0;              // reset string len (in buffer) len to 0
	ld	hl,#_flos_spawn_cmd
	ld	(hl),#0x00
;i_flos.c:487: strcat(flos_spawn_cmd, line);
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	ld	hl,#_flos_spawn_cmd
	push	hl
	call	_strcat
	pop	af
	pop	af
;i_flos.c:488: return TRUE;
	ld	l,#0x01
00103$:
	pop	ix
	ret
_FLOS_SetSpawnCmdLine_end::
	.area _CODE
	.area _CABS
