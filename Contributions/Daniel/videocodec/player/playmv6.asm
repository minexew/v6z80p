prgbegin equ 05000h
audioper equ 781
xmin     equ $8 ;789ab
xmax     equ xmin+4
ymin     equ $3
ymax     equ ymin+5
include common.inc

	org 	prgbegin
	dw	0edh
	jr	init
	dw	prgbegin
	db	0
	db	1
	dw	prgend-prgbegin
	db	0
init	
	ld	(cmdlineptr),hl		
; clear variables
	ld	hl,varstart
	ld	de,varstart+1
	ld	bc,varend-varstart-1
	ld	(hl),0
	ldir
	ld	(oldsp),sp	
; test for version, open movie file
	call	kjt_get_version
	ld	de,-0588h  
	add	hl,de
	jp	nc,flos_nok

	ld	hl,(cmdlineptr)
findname
	ld	a,(hl)
	or	a
	jp	z,flos_nofile
	cp	020h
	jr	nz,namefound
skipspc
	inc	hl
	jr	findname
namefound
;	ld	hl,filename
	call kjt_find_file
	ret  nz
	ld	(cluster),de
	ld	(startcluster),de
	ld	(movply),iy
	ld	(movply+2),ix
	ld	(movsiz),iy
	ld	(movsiz+2),ix
	xor	a
	call	kjt_get_sector_read_addr
	ld	(smcsec+1),bc
	ld	(smcread+1),hl


; init 320x200 video mode @ vidram 0
	ld	a,%100
	ld	(vreg_vidctrl),a
	xor	a
	ld	(vreg_xhws),a
	ld	(vreg_rasthi),a
	ld	hl,bitplane0a_loc
	ld	bc,64
clrbp
	ld	(hl),a
	cpi
	jp	pe,clrbp
	dec	a
	ld	(bitplane1a_loc+3),a
	ld	a,2
	ld	(vreg_yhws_bplcount),a
	ld 	a,010h
	ld	(bitplane0a_loc+1),a
	add	a,a
	ld	(bitplane2a_loc+1),a
	ld	(bitplane2b_loc+1),a
	ld	a,ymin << 4 | ymax
	ld	(vreg_window),a  
	ld	a,%100
	ld	(vreg_rasthi),a
	ld	a,xmin << 4 | xmax
	ld	(vreg_window),a  
	ld	a,%10
	ld	(vreg_palette_ctrl),a
; init copper for Y*2
	ld	a,0eh
	out	(sys_mem_select),a
	ld	hl,copper
	ld	de,08000h
	ld	bc,copperend-copper
	ldir
	
; page in videoram @0e000h and sound-ram @08000h
	ld	a,%111
	out	(sys_vram_location),a
	ld	a,%01000100
	out	(sys_mem_select),a	
; clear videoram and soundram
	ld	a,2
	ld	(vreg_vidpage),a
	xor	a
	call	clearvid
	ld	a,1
	ld	(vreg_vidpage),a
	ld	a,0ffh
	call	clearvid
	xor	a
	ld	(vreg_vidpage),a
	ld	hl,08000h
	ld	de,08001h
	ld	bc,07fffh
	ld	(hl),a
	ldir

; set working page
	ld	a,2
	ld	(vreg_vidpage),a
; setup blitter
	ld	ix,blit_src_loc
	xor	a
	ld	(blit_src_loc),a
	ld	(ix+1),040h
	ld	(blit_dst_loc),a
	ld	(blit_dst_loc+1),a
	ld	(blit_src_mod),a
	ld	(blit_src_mod+1),a
	ld	(ix+6),202
	ld	(ix+8),%01000000
	ld	(blit_src_msb),a
	ld	(blit_dst_msb),a
; set palette
	ld	hl,pal
	ld	de,0
	ld	bc,palend-pal
	ldir
; enable copper
	xor	a
	ld 	(vreg_linecop_hi),a
	inc	a
	ld 	(vreg_linecop_lo),a
; enable sound
	ld	a,0ffh
	out	(sys_audio_panning),a
	call waitdma
	xor	a
	out	(sys_audio_enable),a
	ld	a,040h
	out	(audchan0_vol),a
	out	(audchan1_vol),a
	out	(audchan2_vol),a
	out	(audchan3_vol),a

	ld	b,audioper>>8
	ld	a,audioper
	ld	c,audchan0_per
	out	(c),a
	ld	c,audchan1_per
	out	(c),a
	ld	c,audchan2_per
	out	(c),a
	ld	c,audchan3_per
	out	(c),a
	xor	a
	ld	b,0
	ld	c,audchan0_loc
	out	(c),a
	ld	c,audchan1_loc
	out	(c),a
	ld	c,audchan2_loc
	out	(c),a
	ld	c,audchan3_loc
	out	(c),a
	ld	b,2
	ld	c,audchan0_len
	out	(c),a
	ld	c,audchan1_len
	out	(c),a
	ld	c,audchan2_len
	out	(c),a
	ld	c,audchan3_len
	out	(c),a

	call kjt_wait_vrt
	call	waitdma
	ld	a,%1111
	out	(sys_audio_enable),a


main
	call	readframe
	ld	a,39
	ld	(blit_width),a
	xor	a

; double-buffer audo
	ld	a,(bufsel)
	inc	a
	and	1
	ld	(bufsel),a

	ld	b,0
	jr	nz,bs2
	ld	b,2
bs2
	ld	c,audchan0_loc
	out	(c),a
	ld	c,audchan1_loc
	out	(c),a
	ld	c,audchan2_loc
	out	(c),a
	ld	c,audchan3_loc
	out	(c),a

; check for framedrop
	ld   hl,0
	ld   (0),hl
	ld	a,%00010000
	in	a,(sys_audio_flags)
	bit	4,a
	jr	z,waitaudio
	ld 	hl,0f33h
	ld 	(0),hl
	ld	hl,(dropframes)
	inc	hl
	ld	(dropframes),hl
; wait for frame end
waitaudio
	in	a,(sys_audio_flags)
	bit	4,a
	jr	z,waitaudio
	out	(sys_clear_irq_flags),a	
	call	kjt_get_key
	or	a
	jp	nz,quit
; decrease playsize
	ld	bc,0
	ld	de,(framesiz)
	ld	hl,(movply)
	xor	a
	sbc	hl,de
	ld	(movply),hl
	ex	de,hl
	ld	hl,(movply+2)
	sbc	hl,bc
	ld	(movply+2),hl
	or	h
	or	l
	or	d
	or	e
	jp	nz,main

quit
	ld	a,05ah
	out	(sys_audio_panning),a
	call waitdma
	xor	a
	out  (sys_audio_enable),a
	out	(sys_vram_location),a
	out	(sys_mem_select),a	
	ld 	(vreg_linecop_hi),a
	ld 	(vreg_linecop_lo),a
	ld	(vreg_palette_ctrl),a
	call kjt_flos_display
	ld	de,dropstring
	ld	hl,(dropframes)
	call DispHL
	ld	hl,dropstring
skip0
	inc  hl
	ld	a,(hl)
	cp	'0'
	jr	z,skip0
	cp	' '
	jr	z,skipdrop
	call kjt_print_string
skipdrop
	xor	a
	ret

DispHL:
	ld	bc,-10000
	call	Num1
	ld	bc,-1000
	call	Num1
	ld	bc,-100
	call	Num1
	ld	c,-10
	call	Num1
	ld	c,-1
Num1	ld	a,'0'-1
Num2	inc	a
	add	hl,bc
	jr	c,Num2
	sbc	hl,bc
	ex	de,hl
	ld	(hl),a
	inc	hl
	ex	de,hl
	ret 

flos_nofile
	ld	a,0dh
	db	1
flos_nok	
	ld	a,024h
	or	a
	ret
abort
	ld	sp,(oldsp)
	ld	hl,0ffffh
	ld	(dropframes),hl
	jp	quit

clearvid
	ld	hl,0e000h
	ld	de,0e001h
	ld	bc,01fffh
	ld	(hl),a
	ldir
	ret
readframe
	xor	a
	ld	(framesiz+1),a
; load audio
	ld 	de,(cluster)
	ld	b,2
	exx
	ld 	bc,0400h
	ld	hl,08000h
	ld	a,(bufsel)
	and	1
	jr   z,skipaddbuf
	add	hl,bc
skipaddbuf
	exx
	call readloop
; load video
	ld	b,1
	exx
	ld	hl,0a000h
	exx
	call readloop
     ld	a,(0a000h)
	cp	16			; failsafe
	jp	nc,abort		;
	cp	15
	jr	z,directload
	ld	b,a
	or	a
	jr	z,skipaddload
	call readloop
skipaddload
	ld	(cluster),de
; depack video
	ld	hl,0a001h
decomploop
 	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	a,d
	or	e
	jr	z,skipdecomp
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ldir
	jr 	decomploop
skipdecomp	
     ret

directload
	exx
	ld	hl,0a001h
	ld	de,0e000h
	ld	bc,01ffh
	ldir
	ex	de,hl
	exx
	ld	b,15
	call readloop
	ld	(cluster),de
	ret

readloop
	push	bc
	ld	a,(secofs)
	call	kjt_file_sector_list
	ld	(secofs),a
	ld	hl,framesiz+1
	inc	(hl)
	inc	(hl)
	exx
smcsec
	ld	(0),hl
smcread
	call	0
	exx
	pop	bc
	djnz readloop
	ret

waitdma	
	ld a,(vreg_read)		;wait for LSB for scanline count to change
	and $40
	ld b,a
loop2
	ld a,(vreg_read)
	and $40
	cp b
	jr z,loop2
	ret

varstart
dropframes
	dw 0
bufsel  db 0
movsiz
	dw 0,0
movply
	dw 0,0
framesiz
	dw 0
secofs
	db 0
cluster
	dw 0
startcluster
	dw 0
oldsp
	dw 0
varend

cmdlineptr
	dw 0
pal
	dw 0,0,0,0,0,0555h,0aaah,0fffh
palend

copper
    copwait ymin*8
rept 50,count
    copsel  bitplane0a_loc
    copstp  (((count*2) *40)) & 0ffh
    copsto  (((count*2) *40) >> 8) & 0ffh
    copsel  bitplane1a_loc
    copstp  (((count*2) *40)) & 0ffh
    copsto  ((((count*2)*40) >> 8)+10h) & 0ffh
    copsel  vreg_vidctrl
    copstw  %00000000
    copstw  %00000000
    copsel  bitplane0b_loc
    copstp  (((count*2+1) *40)) & 0ffh
    copsto  (((count*2+1) *40) >> 8) & 0ffh
    copsel  bitplane1b_loc
    copstp  (((count*2+1) *40)) & 0ffh
    copsto  ((((count*2+1)*40) >> 8)+10h) & 0ffh
    copsel  vreg_vidctrl
    copstw  %00100000
    copstw  %00100000
endm    
    copwait 01ffh

copperend

;filename db 'nexus7.mv6',0
;filename db 'neuro.mv6',0
;filename db 'summer.mv6',0

dropstring db '00000 frame(s) dropped',13,10,0

;align 512
prgend
; mem: 
; 05000h-05fffh:player
; 08000h-083ffh:audiobuf
; 0a000h-0bfffh:readbuf
; 0e000h-0ffffh:video

;vidram:
; 00000-00fff: bp1 
; 01000-01fff: bp2
; 04000-05fff: blitbuf

; vim: set noet ts=5:
