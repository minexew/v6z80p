;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 2.9.0 #5416 (Mar 22 2009) (MINGW32)
; This file was generated Tue Jun 08 18:21:49 2010
;--------------------------------------------------------
	.module test1
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _buf
	.globl _buffer
	.globl _myFile
	.globl _pFilename
	.globl _own_sp
	.globl _proccess_cmd_line
	.globl _TestVersion
	.globl _test1
	.globl _test2
	.globl _test3
	.globl _test4
	.globl _PrintCurDirName
	.globl _test5
	.globl _test6
	.globl _DiagMessage
	.globl _PrintNum
	.globl _WaitKeyPress
	.globl _GetSP
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
;  ram data
;--------------------------------------------------------
	.area _DATA
_pFilename::
	.ds 2
_myFile::
	.ds 7
_buffer::
	.ds 33
_buf::
	.ds 8
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
;test1.c:47: int main (void)
;	---------------------------------
; Function main
; ---------------------------------
_main_start::
_main:
;test1.c:50: MarkFrameTime(0x00f);
	ld	hl,#0x000F
	push	hl
	call	_MarkFrameTime
	pop	af
;test1.c:51: FLOS_ClearScreen();
	call	_FLOS_ClearScreen
;test1.c:53: proccess_cmd_line();
	call	_proccess_cmd_line
;test1.c:55: if(!TestVersion()) {
	call	_TestVersion
	xor	a,a
	or	a,l
	jr	NZ,00102$
;test1.c:56: FLOS_PrintString("FLOS v");
	ld	hl,#__str_0
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:57: _uitoa(OS_VERSION_REQ, buffer, 16);
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	ld	hl,#0x0555
	push	hl
	call	__uitoa
	pop	af
	pop	af
	inc	sp
;test1.c:58: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:59: FLOS_PrintStringLFCR("+ req. to run this program");
	ld	hl,#__str_1
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:60: return NO_REBOOT;
	ld	hl,#0x0000
	ret
00102$:
;test1.c:64: CALL_TEST(1);
	call	_test1
	xor	a,a
	or	a,l
	jr	NZ,00104$
	ld	hl,#0x0F00
	push	hl
	call	_MarkFrameTime
	pop	af
	ld	hl,#0x0000
	ret
00104$:
;test1.c:65: CALL_TEST(2);
	call	_test2
	xor	a,a
	or	a,l
	jr	NZ,00106$
	ld	hl,#0x0F00
	push	hl
	call	_MarkFrameTime
	pop	af
	ld	hl,#0x0000
	ret
00106$:
;test1.c:66: CALL_TEST(3);
	call	_test3
	xor	a,a
	or	a,l
	jr	NZ,00108$
	ld	hl,#0x0F00
	push	hl
	call	_MarkFrameTime
	pop	af
	ld	hl,#0x0000
	ret
00108$:
;test1.c:67: CALL_TEST(4);
	call	_test4
	xor	a,a
	or	a,l
	jr	NZ,00110$
	ld	hl,#0x0F00
	push	hl
	call	_MarkFrameTime
	pop	af
	ld	hl,#0x0000
	ret
00110$:
;test1.c:68: CALL_TEST(5);
	call	_test5
	xor	a,a
	or	a,l
	jr	NZ,00112$
	ld	hl,#0x0F00
	push	hl
	call	_MarkFrameTime
	pop	af
	ld	hl,#0x0000
	ret
00112$:
;test1.c:69: CALL_TEST(6);
	call	_test6
	xor	a,a
	or	a,l
	jr	NZ,00114$
	ld	hl,#0x0F00
	push	hl
	call	_MarkFrameTime
	pop	af
	ld	hl,#0x0000
	ret
00114$:
;test1.c:72: FLOS_PrintStringLFCR("TEST OK");
	ld	hl,#__str_2
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:78: return NO_REBOOT;
	ld	hl,#0x0000
	ret
_main_end::
_own_sp:
	.dw #0x8000
__str_0:
	.ascii "FLOS v"
	.db 0x00
__str_1:
	.ascii "+ req. to run this program"
	.db 0x00
__str_2:
	.ascii "TEST OK"
	.db 0x00
;test1.c:82: void proccess_cmd_line(void)
;	---------------------------------
; Function proccess_cmd_line
; ---------------------------------
_proccess_cmd_line_start::
_proccess_cmd_line:
;test1.c:86: cmdline = FLOS_GetCmdLine();
	call	_FLOS_GetCmdLine
	ld	b,h
	ld	c,l
;test1.c:88: pFilename =  (cmdline == NULL) ? "NOFILE" : cmdline;
	ld	a,c
	or	a,b
	jr	NZ,00103$
	ld	hl,#__str_3
	ex	de,hl
	jr	00104$
00103$:
	ld	e,c
	ld	d,b
00104$:
	ld	hl,#_pFilename + 0
	ld	(hl), e
	ld	hl,#_pFilename + 1
	ld	(hl), d
	ret
_proccess_cmd_line_end::
__str_3:
	.ascii "NOFILE"
	.db 0x00
;test1.c:101: BOOL TestVersion(void)
;	---------------------------------
; Function TestVersion
; ---------------------------------
_TestVersion_start::
_TestVersion:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
	push	af
;test1.c:106: FLOS_GetVersion(&os_version_word, &hw_version_word);
	ld	hl,#0x0000
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	hl,#0x0002
	add	hl,sp
	push	bc
	push	hl
	call	_FLOS_GetVersion
	pop	af
	pop	af
;test1.c:107: FLOS_PrintString("OS: ");
	ld	hl,#__str_4
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:108: PrintNum(os_version_word);
	ld	c,-2 (ix)
	ld	b,-1 (ix)
	ld	hl,#0x0000
	push	hl
	push	bc
	call	_PrintNum
	pop	af
	pop	af
;test1.c:109: FLOS_PrintString("   HW: ");
	ld	hl,#__str_5
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:110: PrintNum(hw_version_word);
	ld	c,-4 (ix)
	ld	b,-3 (ix)
	ld	hl,#0x0000
	push	hl
	push	bc
	call	_PrintNum
	pop	af
	pop	af
;test1.c:111: FLOS_PrintStringLFCR("");
	ld	hl,#__str_6
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:113: if(os_version_word < OS_VERSION_REQ)
	ld	a,-2 (ix)
	sub	a,#0x55
	ld	a,-1 (ix)
	sbc	a,#0x05
	jr	NC,00102$
;test1.c:114: return FALSE;
	ld	l,#0x00
	jr	00103$
00102$:
;test1.c:117: return TRUE;
	ld	l,#0x01
00103$:
	ld	sp,ix
	pop	ix
	ret
_TestVersion_end::
__str_4:
	.ascii "OS: "
	.db 0x00
__str_5:
	.ascii "   HW: "
	.db 0x00
__str_6:
	.db 0x00
;test1.c:123: BOOL test1(void)
;	---------------------------------
; Function test1
; ---------------------------------
_test1_start::
_test1:
;test1.c:127: r = FLOS_CheckDiskAvailable();
	call	_FLOS_CheckDiskAvailable
;test1.c:128: if(!r) {
	xor	a,a
	or	a,l
	jr	NZ,00102$
;test1.c:129: DiagMessage("CheckDiskAvailable failed: ", "");
	ld	hl,#__str_8
	push	hl
	ld	hl,#__str_7
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:130: return FALSE;
	ld	l,#0x00
	ret
00102$:
;test1.c:136: r = FLOS_FindFile(&myFile, pFilename);
	ld	hl,(_pFilename)
	push	hl
	ld	hl,#_myFile
	push	hl
	call	_FLOS_FindFile
	pop	af
	pop	af
	ld	b,l
	ld	c,b
;test1.c:137: if(!r) {
	xor	a,a
	or	a,c
	jr	NZ,00104$
;test1.c:138: DiagMessage("FindFile failed: ", pFilename);
	ld	hl,(_pFilename)
	push	hl
	ld	hl,#__str_9
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:139: return FALSE;
	ld	l,#0x00
	ret
00104$:
;test1.c:143: FLOS_PrintString("FindFile: ");
	ld	hl,#__str_10
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:144: FLOS_PrintString(pFilename);
	ld	hl,(_pFilename)
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:145: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_11
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:147: _ultoa(myFile.size, buffer, 16);
	ld	hl, #_myFile + 3
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	de
	push	bc
	call	__ultoa
	pop	af
	pop	af
	pop	af
	inc	sp
;test1.c:148: FLOS_PrintString("Size: $");
	ld	hl,#__str_12
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:149: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:151: _ultoa(myFile.z80_address, buffer, 16);
	ld	hl,#_myFile
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	de,#0x0000
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	de
	push	bc
	call	__ultoa
	pop	af
	pop	af
	pop	af
	inc	sp
;test1.c:152: FLOS_PrintString(" Addr: $");
	ld	hl,#__str_13
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:153: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:155: _ultoa(myFile.z80_bank, buffer, 16);
	ld	hl,#_myFile + 2
	ld	c,(hl)
	ld	b,#0x00
	ld	de,#0x0000
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	de
	push	bc
	call	__ultoa
	pop	af
	pop	af
	pop	af
	inc	sp
;test1.c:156: FLOS_PrintString(" Bank: $");
	ld	hl,#__str_14
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:157: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:158: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_11
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:160: return TRUE;
	ld	l,#0x01
	ret
_test1_end::
__str_7:
	.ascii "CheckDiskAvailable failed: "
	.db 0x00
__str_8:
	.db 0x00
__str_9:
	.ascii "FindFile failed: "
	.db 0x00
__str_10:
	.ascii "FindFile: "
	.db 0x00
__str_11:
	.db 0x0B
	.db 0x00
__str_12:
	.ascii "Size: $"
	.db 0x00
__str_13:
	.ascii " Addr: $"
	.db 0x00
__str_14:
	.ascii " Bank: $"
	.db 0x00
;test1.c:166: BOOL test2(void)
;	---------------------------------
; Function test2
; ---------------------------------
_test2_start::
_test2:
;test1.c:173: FLOS_SetLoadLength(8);
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0008
	push	hl
	call	_FLOS_SetLoadLength
	pop	af
	pop	af
;test1.c:175: r = FLOS_ForceLoad( buf, 0 );
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#_buf
	push	hl
	call	_FLOS_ForceLoad
	pop	af
	inc	sp
;test1.c:176: if(!r) {
	xor	a,a
	or	a,l
	jr	NZ,00102$
;test1.c:177: DiagMessage("ForceLoad failed: ", pFilename);
	ld	hl,(_pFilename)
	push	hl
	ld	hl,#__str_15
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:178: return FALSE;
	ld	l,#0x00
	ret
00102$:
;test1.c:181: FLOS_PrintString("Data at $0000: ");
	ld	hl,#__str_16
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:182: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_17
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:184: for(i=0; i<8; i++) {
	ld	b,#0x00
00105$:
	ld	a,b
	sub	a,#0x08
	jr	NC,00108$
;test1.c:185: _itoa(buf[i], buffer, 16);
	ld	a,#<_buf
	add	a,b
	ld	e,a
	ld	a,#>_buf
	adc	a,#0x00
	ld	d,a
	ld	a,(de)
	ld	e,a
	ld	d,#0x00
	push	bc
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	de
	call	__itoa
	pop	af
	pop	af
	inc	sp
	pop	bc
;test1.c:186: FLOS_PrintString("  ");
	push	bc
	ld	hl,#__str_18
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;test1.c:187: FLOS_PrintString(buffer);
	push	bc
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;test1.c:184: for(i=0; i<8; i++) {
	inc	b
	jr	00105$
00108$:
;test1.c:190: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_17
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:193: FLOS_SetFilePointer(0x10);
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0010
	push	hl
	call	_FLOS_SetFilePointer
	pop	af
	pop	af
;test1.c:194: FLOS_SetLoadLength(8);
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x0008
	push	hl
	call	_FLOS_SetLoadLength
	pop	af
	pop	af
;test1.c:195: r = FLOS_ForceLoad( buf, 0 );
	ld	a,#0x00
	push	af
	inc	sp
	ld	hl,#_buf
	push	hl
	call	_FLOS_ForceLoad
	pop	af
	inc	sp
	ld	b,l
	ld	c,b
;test1.c:196: if(!r) {
	xor	a,a
	or	a,c
	jr	NZ,00104$
;test1.c:197: DiagMessage("ForceLoad failed: ", pFilename);
	ld	hl,(_pFilename)
	push	hl
	ld	hl,#__str_15
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:198: return FALSE;
	ld	l,#0x00
	ret
00104$:
;test1.c:200: FLOS_PrintString("Data at $0010: ");
	ld	hl,#__str_19
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:201: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_17
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:203: for(i=0; i<8; i++) {
	ld	c,#0x00
00109$:
	ld	a,c
	sub	a,#0x08
	jr	NC,00112$
;test1.c:204: _itoa(buf[i], buffer, 16);
	ld	a,#<_buf
	add	a,c
	ld	e,a
	ld	a,#>_buf
	adc	a,#0x00
	ld	d,a
	ld	a,(de)
	ld	b,a
	ld	e,#0x00
	push	bc
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	ld	l,b
	ld	h,e
	push	hl
	call	__itoa
	pop	af
	pop	af
	inc	sp
	pop	bc
;test1.c:205: FLOS_PrintString("  ");
	push	bc
	ld	hl,#__str_18
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;test1.c:206: FLOS_PrintString(buffer);
	push	bc
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;test1.c:203: for(i=0; i<8; i++) {
	inc	c
	jr	00109$
00112$:
;test1.c:208: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_17
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:211: return TRUE;
	ld	l,#0x01
	ret
_test2_end::
__str_15:
	.ascii "ForceLoad failed: "
	.db 0x00
__str_16:
	.ascii "Data at $0000: "
	.db 0x00
__str_17:
	.db 0x0B
	.db 0x00
__str_18:
	.ascii "  "
	.db 0x00
__str_19:
	.ascii "Data at $0010: "
	.db 0x00
;test1.c:214: BOOL test3(void)
;	---------------------------------
; Function test3
; ---------------------------------
_test3_start::
_test3:
;test1.c:220: blocks = FLOS_GetTotalSectors();
	call	_FLOS_GetTotalSectors
	ld	b,h
	ld	c,l
;test1.c:222: FLOS_PrintString("Drive total sectors: $");
	push	bc
	push	de
	ld	hl,#__str_20
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	de
	pop	bc
;test1.c:223: _ultoa(blocks, buffer, 16);
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	de
	push	bc
	call	__ultoa
	pop	af
	pop	af
	pop	af
	inc	sp
;test1.c:224: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:225: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_21
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:228: FLOS_PrintStringLFCR("Creating file... ");
	ld	hl,#__str_22
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:229: pFilename = "MYTEST.TMP";
;test1.c:230: r = FLOS_CreateFile(pFilename);
	ld	hl,#__str_23
	push	hl
	call	_FLOS_CreateFile
	pop	af
;test1.c:231: if(!r) {
	xor	a,a
	or	a,l
	jr	NZ,00102$
;test1.c:232: DiagMessage("CreateFile failed: ", pFilename);
	ld	hl,#__str_23
	push	hl
	ld	hl,#__str_24
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:233: return FALSE;
	ld	l,#0x00
	ret
00102$:
;test1.c:238: FLOS_PrintStringLFCR("Writing bytes to file...");
	ld	hl,#__str_25
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:239: r = FLOS_WriteBytesToFile(pFilename, (byte*) 0x1000, 0, 0x2000);
	ld	hl,#0x0000
	push	hl
	ld	hl,#0x2000
	push	hl
	ld	a,#0x00
	push	af
	inc	sp
	ld	h, #0x10
	push	hl
	ld	hl,#__str_23
	push	hl
	call	_FLOS_WriteBytesToFile
	ld	iy,#0x0009
	add	iy,sp
	ld	sp,iy
	ld	b,l
	ld	c,b
;test1.c:240: if(!r) {
	xor	a,a
	or	a,c
	jr	NZ,00104$
;test1.c:241: DiagMessage("WriteBytesToFile failed: ", pFilename);
	ld	hl,#__str_23
	push	hl
	ld	hl,#__str_26
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:242: return FALSE;
	ld	l,#0x00
	ret
00104$:
;test1.c:246: FLOS_PrintStringLFCR("Erasing file... ");
	ld	hl,#__str_27
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:247: r = FLOS_EraseFile(pFilename);
	ld	hl,#__str_23
	push	hl
	call	_FLOS_EraseFile
	pop	af
	ld	b,l
	ld	c,b
;test1.c:248: if(!r) {
	xor	a,a
	or	a,c
	jr	NZ,00106$
;test1.c:249: DiagMessage("EraseFile failed: ", pFilename);
	ld	hl,#__str_23
	push	hl
	ld	hl,#__str_28
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:250: return FALSE;
	ld	l,#0x00
	ret
00106$:
;test1.c:253: return TRUE;
	ld	l,#0x01
	ret
_test3_end::
__str_20:
	.ascii "Drive total sectors: $"
	.db 0x00
__str_21:
	.db 0x0B
	.db 0x00
__str_22:
	.ascii "Creating file... "
	.db 0x00
__str_23:
	.ascii "MYTEST.TMP"
	.db 0x00
__str_24:
	.ascii "CreateFile failed: "
	.db 0x00
__str_25:
	.ascii "Writing bytes to file..."
	.db 0x00
__str_26:
	.ascii "WriteBytesToFile failed: "
	.db 0x00
__str_27:
	.ascii "Erasing file... "
	.db 0x00
__str_28:
	.ascii "EraseFile failed: "
	.db 0x00
;test1.c:256: BOOL test4(void)
;	---------------------------------
; Function test4
; ---------------------------------
_test4_start::
_test4:
;test1.c:260: const char* pDirName = "TMPDIR";
;test1.c:262: FLOS_PrintStringLFCR("Creating dir... ");
	ld	hl,#__str_30
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:263: r = FLOS_MakeDir(pDirName);
	ld	hl,#__str_29
	push	hl
	call	_FLOS_MakeDir
	pop	af
;test1.c:264: if(!r) {
	xor	a,a
	or	a,l
	jr	NZ,00102$
;test1.c:265: DiagMessage("MakeDir failed: ", pDirName);
	ld	hl,#__str_29
	push	hl
	ld	hl,#__str_31
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:266: return FALSE;
	ld	l,#0x00
	ret
00102$:
;test1.c:269: FLOS_PrintStringLFCR("Change dir... ");
	ld	hl,#__str_32
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:270: r = FLOS_ChangeDir(pDirName);
	ld	hl,#__str_29
	push	hl
	call	_FLOS_ChangeDir
	pop	af
	ld	b,l
	ld	c,b
;test1.c:271: if(!r) {
	xor	a,a
	or	a,c
	jr	NZ,00104$
;test1.c:272: DiagMessage("ChangeDir failed: ", pDirName);
	ld	hl,#__str_29
	push	hl
	ld	hl,#__str_33
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:273: return FALSE;
	ld	l,#0x00
	ret
00104$:
;test1.c:277: if(!PrintCurDirName())
	call	_PrintCurDirName
;test1.c:278: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00106$
	ld	l,a
	ret
00106$:
;test1.c:281: FLOS_PrintStringLFCR("Parent dir... ");
	ld	hl,#__str_34
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:282: r = FLOS_ParentDir();
	call	_FLOS_ParentDir
	ld	b,l
	ld	c,b
;test1.c:283: if(!r) {
	xor	a,a
	or	a,c
	jr	NZ,00108$
;test1.c:284: DiagMessage("ParentDir failed: ", "");
	ld	hl,#__str_36
	push	hl
	ld	hl,#__str_35
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:285: return FALSE;
	ld	l,#0x00
	ret
00108$:
;test1.c:289: FLOS_PrintStringLFCR("Deleting dir... ");
	ld	hl,#__str_37
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:290: r = FLOS_DeleteDir(pDirName);
	ld	hl,#__str_29
	push	hl
	call	_FLOS_DeleteDir
	pop	af
	ld	b,l
	ld	c,b
;test1.c:291: if(!r) {
	xor	a,a
	or	a,c
	jr	NZ,00110$
;test1.c:292: DiagMessage("DeleteDir failed: ", pDirName);
	ld	hl,#__str_29
	push	hl
	ld	hl,#__str_38
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:293: return FALSE;
	ld	l,#0x00
	ret
00110$:
;test1.c:296: FLOS_PrintStringLFCR("ROOT dir... ");
	ld	hl,#__str_39
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:297: FLOS_RootDir();
	call	_FLOS_RootDir
;test1.c:300: if(!PrintCurDirName())
	call	_PrintCurDirName
;test1.c:301: return FALSE;
	xor	a,a
	or	a,l
	jr	NZ,00112$
	ld	l,a
	ret
00112$:
;test1.c:304: return TRUE;
	ld	l,#0x01
	ret
_test4_end::
__str_29:
	.ascii "TMPDIR"
	.db 0x00
__str_30:
	.ascii "Creating dir... "
	.db 0x00
__str_31:
	.ascii "MakeDir failed: "
	.db 0x00
__str_32:
	.ascii "Change dir... "
	.db 0x00
__str_33:
	.ascii "ChangeDir failed: "
	.db 0x00
__str_34:
	.ascii "Parent dir... "
	.db 0x00
__str_35:
	.ascii "ParentDir failed: "
	.db 0x00
__str_36:
	.db 0x00
__str_37:
	.ascii "Deleting dir... "
	.db 0x00
__str_38:
	.ascii "DeleteDir failed: "
	.db 0x00
__str_39:
	.ascii "ROOT dir... "
	.db 0x00
;test1.c:307: BOOL PrintCurDirName(void)
;	---------------------------------
; Function PrintCurDirName
; ---------------------------------
_PrintCurDirName_start::
_PrintCurDirName:
;test1.c:311: FLOS_PrintString("Dirname: ");
	ld	hl,#__str_40
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:312: p = FLOS_GetDirName();
	call	_FLOS_GetDirName
	ld	b,h
	ld	c,l
;test1.c:313: if(!p) {
	ld	a,c
	or	a,b
	jr	NZ,00102$
;test1.c:314: DiagMessage("FLOS_GetDirName failed: ", "");
	ld	hl,#__str_42
	push	hl
	ld	hl,#__str_41
	push	hl
	call	_DiagMessage
	pop	af
	pop	af
;test1.c:315: return FALSE;
	ld	l,#0x00
	ret
00102$:
;test1.c:317: FLOS_PrintStringLFCR(p);
	push	bc
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:319: return TRUE;
	ld	l,#0x01
	ret
_PrintCurDirName_end::
__str_40:
	.ascii "Dirname: "
	.db 0x00
__str_41:
	.ascii "FLOS_GetDirName failed: "
	.db 0x00
__str_42:
	.db 0x00
;test1.c:323: BOOL test5(void)
;	---------------------------------
; Function test5
; ---------------------------------
_test5_start::
_test5:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;test1.c:330: FLOS_PrintStringLFCR("FLOS_WaitKeyPress... press any key");
	ld	hl,#__str_43
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:331: FLOS_WaitKeyPress(&asciicode, &scancode);
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
;test1.c:332: FLOS_PrintString("scancode: $");
	ld	hl,#__str_44
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:333: _ultoa(scancode, buffer, 16);
	ld	c,-2 (ix)
	ld	b,#0x00
	ld	de,#0x0000
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	de
	push	bc
	call	__ultoa
	pop	af
	pop	af
	pop	af
	inc	sp
;test1.c:334: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:335: FLOS_PrintString(" ascii: $");
	ld	hl,#__str_45
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:336: _ultoa(asciicode, buffer, 16);
	ld	c,-1 (ix)
	ld	b,#0x00
	ld	de,#0x0000
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	push	de
	push	bc
	call	__ultoa
	pop	af
	pop	af
	pop	af
	inc	sp
;test1.c:337: FLOS_PrintStringLFCR(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:342: r = FLOS_SetCursorPos(10, 18);
	ld	hl,#0x120A
	push	hl
	call	_FLOS_SetCursorPos
	pop	af
	ld	a,l
;test1.c:343: if(!r)
;test1.c:344: return FALSE;
	or	a,a
	jr	NZ,00102$
	ld	l,a
	jr	00103$
00102$:
;test1.c:345: FLOS_PrintStringLFCR("SetCursorPos... ");
	ld	hl,#__str_46
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:348: return TRUE;
	ld	l,#0x01
00103$:
	ld	sp,ix
	pop	ix
	ret
_test5_end::
__str_43:
	.ascii "FLOS_WaitKeyPress... press any key"
	.db 0x00
__str_44:
	.ascii "scancode: $"
	.db 0x00
__str_45:
	.ascii " ascii: $"
	.db 0x00
__str_46:
	.ascii "SetCursorPos... "
	.db 0x00
;test1.c:352: BOOL test6(void)
;	---------------------------------
; Function test6
; ---------------------------------
_test6_start::
_test6:
	push	ix
	ld	ix,#0
	add	ix,sp
	ld	hl,#-12
	add	hl,sp
	ld	sp,hl
;test1.c:357: FLOS_PrintStringLFCR("Press ENTER key to DIR test...");
	ld	hl,#__str_47
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:359: WaitKeyPress(0x5A);
	ld	a,#0x5A
	push	af
	inc	sp
	call	_WaitKeyPress
	inc	sp
;test1.c:361: FLOS_ClearScreen();
	call	_FLOS_ClearScreen
;test1.c:363: FLOS_PrintStringLFCR("Dir list:");
	ld	hl,#__str_48
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
;test1.c:365: FLOS_DirListFirstEntry();
	call	_FLOS_DirListFirstEntry
;test1.c:366: while(1) {
	ld	hl,#0x0004
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	hl,#0x0006
	add	hl,bc
	ld	-10 (ix),l
	ld	-9 (ix),h
	ld	hl,#0x0007
	add	hl,bc
	ld	-12 (ix),l
	ld	-11 (ix),h
00109$:
;test1.c:367: FLOS_DirListGetEntry(&e);
	ld	hl,#0x0004
	add	hl,sp
	push	hl
	call	_FLOS_DirListGetEntry
	pop	af
;test1.c:368: if(e.err_code == END_OF_DIR) break;
	ld	l,-12 (ix)
	ld	h,-11 (ix)
	ld	a,(hl)
	sub	a,#0x24
	jp	Z,00110$
;test1.c:370: FLOS_PrintString(e.pFilename);
	ld	hl,#0x0004
	add	hl,sp
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	de
	call	_FLOS_PrintString
	pop	af
;test1.c:372: if(e.file_flag == 1)
	ld	l,-10 (ix)
	ld	h,-9 (ix)
	ld	a,(hl)
	sub	a,#0x01
	jr	NZ,00104$
;test1.c:373: FLOS_PrintStringLFCR("  (DIR)");
	ld	hl,#__str_49
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
	jr	00105$
00104$:
;test1.c:375: FLOS_PrintString("  $");
	ld	hl,#__str_50
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:376: PrintNum(e.len);
	ld	hl,#0x0004
	add	hl,sp
	inc	hl
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	push	bc
	push	de
	call	_PrintNum
	pop	af
	pop	af
;test1.c:377: FLOS_PrintStringLFCR("");
	ld	hl,#__str_51
	push	hl
	call	_FLOS_PrintStringLFCR
	pop	af
00105$:
;test1.c:380: if(FLOS_DirListNextEntry() == END_OF_DIR) break;
	call	_FLOS_DirListNextEntry
	ld	a,l
	sub	a,#0x24
	jp	NZ,00109$
00110$:
;test1.c:387: return TRUE;
	ld	l,#0x01
	ld	sp,ix
	pop	ix
	ret
_test6_end::
__str_47:
	.ascii "Press ENTER key to DIR test..."
	.db 0x00
__str_48:
	.ascii "Dir list:"
	.db 0x00
__str_49:
	.ascii "  (DIR)"
	.db 0x00
__str_50:
	.ascii "  $"
	.db 0x00
__str_51:
	.db 0x00
;test1.c:390: void DiagMessage(char* pMsg, char* pFilename)
;	---------------------------------
; Function DiagMessage
; ---------------------------------
_DiagMessage_start::
_DiagMessage:
	push	ix
	ld	ix,#0
	add	ix,sp
;test1.c:394: err = FLOS_GetLastError();
	call	_FLOS_GetLastError
	ld	c,l
;test1.c:396: FLOS_PrintString(pMsg);
	push	bc
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;test1.c:397: FLOS_PrintString(pFilename);
	push	bc
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;test1.c:399: FLOS_PrintString(" OS_err: $");
	push	bc
	ld	hl,#__str_52
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	bc
;test1.c:400: _uitoa(err, buffer, 16);
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
;test1.c:401: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
;test1.c:402: FLOS_PrintString(PS_LFCR);
	ld	hl,#__str_53
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	ix
	ret
_DiagMessage_end::
__str_52:
	.ascii " OS_err: $"
	.db 0x00
__str_53:
	.db 0x0B
	.db 0x00
;test1.c:408: void PrintNum(dword n)
;	---------------------------------
; Function PrintNum
; ---------------------------------
_PrintNum_start::
_PrintNum:
	push	ix
	ld	ix,#0
	add	ix,sp
;test1.c:410: _ultoa(n, buffer, 16);
	ld	a,#0x10
	push	af
	inc	sp
	ld	hl,#_buffer
	push	hl
	ld	l,6 (ix)
	ld	h,7 (ix)
	push	hl
	ld	l,4 (ix)
	ld	h,5 (ix)
	push	hl
	call	__ultoa
	pop	af
	pop	af
	pop	af
	inc	sp
;test1.c:411: FLOS_PrintString(buffer);
	ld	hl,#_buffer
	push	hl
	call	_FLOS_PrintString
	pop	af
	pop	ix
	ret
_PrintNum_end::
;test1.c:415: void WaitKeyPress(byte scancode)
;	---------------------------------
; Function WaitKeyPress
; ---------------------------------
_WaitKeyPress_start::
_WaitKeyPress:
	push	ix
	ld	ix,#0
	add	ix,sp
	push	af
;test1.c:417: byte cur_asciicode = 0, cur_scancode = 0;
	ld	-1 (ix),#0x00
	ld	-2 (ix),#0x00
;test1.c:419: while(cur_scancode != scancode) {
00101$:
	ld	a,-2 (ix)
	sub	4 (ix)
	jr	Z,00104$
;test1.c:420: FLOS_WaitKeyPress(&cur_asciicode, &cur_scancode);
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
	jr	00101$
00104$:
	ld	sp,ix
	pop	ix
	ret
_WaitKeyPress_end::
;test1.c:426: word GetSP(void)  NAKED
;	---------------------------------
; Function GetSP
; ---------------------------------
_GetSP_start::
_GetSP:
;test1.c:432: __endasm;
;
		   ld hl,#0
		   add hl,sp
		   ret
		   
	.area _CODE
	.area _CABS
