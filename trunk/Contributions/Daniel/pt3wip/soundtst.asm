include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;cyczx EQU 35 ;140 ; 1750000/12500*8
;soundbuffer equ 500 ; bufsize in bytes: 12500hz / 50hz
;samplerate EQU 533; 1000 ;16000000/(soundbuffer*50) ; 1280 -> 16M/12500hz

cyczx EQU 17 ;17 ;140 ; 1750000/12500*8
cyczxenv EQU cyczx 
soundbuffer equ 250 ; bufsize in bytes: 12500hz / 50hz
;samplerate EQU 1064 ; for 60hz debug
samplerate EQU 1280;1062;1280 ;16000000/(soundbuffer*50) ; 1280 -> 16M/12500hz

bsam MACRO
    LD A,4
    OUT (sys_mem_select),A
ENDM
bram MACRO
    XOR A
    OUT (sys_mem_select),A
ENDM


    org $5000
;    jp main
    jp load
setregs
    xor a
    ld (smc1hi+1),a
    ld (smc2hi+1),a
    ld (smc3hi+1),a
    dec a
    ld (smc1nze+1),a
    ld (smc2nze+1),a
    ld (smc3nze+1),a

    ld hl,(AYREGS+Env)
    ld (env1per+1),hl
   
 
dochan MACRO ton,ampl,smccnt,smcout,smcper,smcvol,smchi,envc,chnbit,nzebit,smcnze
    LD HL,(AYREGS+ton)
    ld (smcper+1),hl
    ld a,h
    or l
    jr nz,_noreset
    ld (smccnt+1),hl
    ld (smcout+1),a
_noreset
    ld a,(AYREGS+Mixer)
    bit chnbit,a
    jr z,_nohi
    ld a,$ff
    ld (smchi+1),a
_nohi
    ld a,(AYREGS+ampl)
    bit 4,a
    jr nz,_envon
    LD H,volv6>>8
    LD L,A
    ld a,(hl)
    ld (smcvol+1),A
    ld a,2
    jr _envoff
_envon
    ld a,0
_envoff
    ld (envc-1),a
    ld a,(AYREGS+Mixer)
    bit nzebit,a
    ld a,0
    jr z,_nzeon
    ld a,2
_nzeon
    ld (smcnze-1),a


ENDM
    dochan TonA,AmplA,smc1cnt,smc1out,smc1per,smc1vol,smc1hi,envc1,0,3,nzec1
    dochan TonB,AmplB,smc2cnt,smc2out,smc2per,smc2vol,smc2hi,envc2,1,4,nzec2
    dochan TonC,AmplC,smc3cnt,smc3out,smc3per,smc3vol,smc3hi,envc3,2,5,nzec3

    ld a,(AYREGS+EnvTp)
    and a
    ret m
    and %110
    add a,a
    add a,a
    add a,a
    add a,a
    add a,$20
    ld (envselect+1),a
    ld hl,0
    ld (env1cnt+1),hl
    ret

main
    call waitdma
    ld a,0
    out (sys_audio_enable),a
    ld a,soundbuffer>>1
    ld bc,audchan0_len
    out (c),a
    ld bc,audchan1_len
    out (c),a
    ld bc,audchan2_len
    out (c),a
    ld bc,audchan3_len
    out (c),a
    xor a
    ld c,audchan0_loc
    out (c),a
    ld b,1
    ld c,audchan1_loc
    out (c),a
    ld c,audchan2_loc
    out (c),a
    ld b,2
    ld c,audchan3_loc
    out (c),a
    ld a,$40
    out (audchan0_vol),a
;    ld a,$0
    out (audchan1_vol),a
;    ld a,$0
    out (audchan2_vol),a
;    ld a,$0
    out (audchan3_vol),a
    ld b,samplerate>>8
    ld a,samplerate&$FF
    ld c,audchan0_per
    out (c),a
    ld c,audchan1_per
    out (c),a
    ld c,audchan2_per
    out (c),a
    ld c,audchan3_per
    out (c),a
    call waitdma
    ld a,%1111
    out (sys_audio_enable),a
  
    di
    ld a,($A01)
    ld (oldirq),a
    ld a,($A02)
    ld (oldirq+1),a
    
    ld a,timerproc&$FF
    ld ($A01),a
    ld a,timerproc>>8
    ld ($A02),a
    ld a,%11110111
    out (sys_clear_irq_flags),a

    ld a,%10001000 
    out (sys_irq_enable),a
    ei
    ld hl,testmod
    call START+3
  
waitloop
    in a,(sys_keyboard_data)	
    cp $76
    jr z,endloop
    ld a,(timerlpd)
    or a
    jr z,waitloop
    xor a
    ld (timerlpd),a
    ld hl,$077
    ld (palette),hl
    call bufswap
    call framecode
    ld hl,$f00
	ld (palette),hl
    call START+5
	ld hl,$007
    ld (palette),hl
 
    in a,(sys_keyboard_data)
    cp $76
    jr nz,waitloop
endloop    
    xor a
    out (sys_audio_enable),a	
    
    di
    ld a,(oldirq)
    ld ($a01),a
    ld a,(oldirq+1)
    ld ($a02),a
    xor a
    out (sys_timer),A
    ld A,%10000011
    out (sys_irq_enable),A
    ei
  
  
    xor a			
    ret

timerlpd db 0

timerproc
    push af
    in a,(sys_audio_enable)
    bit 4,a
    jr nz,newtimer
    ld a,%11100000
    out (sys_clear_irq_flags),a
    pop af
    ei
    reti
    db $C3
    dw 0
oldirq dw 0

newtimer
    ld a,1
    ld (timerlpd),a
skipreload
    ld a,%00010000
    out (sys_clear_irq_flags),a
    pop af
    ei
    reti

    org (($+256)/256)*256
framecode
    in a,(sys_mem_select)
    ld (smcbank+1),a
    ld a,4
    out (sys_mem_select),a


    ld e,0

soundloop
    ld d,soundb1>>8
;    ld a,(bufadd)
;    add a,d
;    ld d,a

env1cnt
    ld hl,0
env1out
    ld a,0
env1smc
    ld bc,cyczxenv
    sbc hl,bc
    jr nc,noreloadenv
env1per
    ld bc,0
    add hl,bc
    jr c,_nores
    ld bc,cyczx
    add hl,bc
_nores
    inc a
    and 31 
    ld (env1out+1),a
noreloadenv
envselect
    or $00

    ld (env1cnt+1),hl
    ld l,a
    ld h,volv6>>8
    ld a,(hl)
    jr envc1
envc1
    ld (smc1vol+1),a
    jr envc2
envc2
    ld (smc2vol+1),a
    jr envc3
envc3
    ld (smc3vol+1),a

;    ld bc,(env1smc+1)
;    ld a,b
;    or c
;    ld bc,0
;    jr nz,_skiploadcyc
;    ld bc,cyczxenv
;_skiploadcyc
;    ld (env1smc+1),bc

nze1cnt
    ld hl,0
    inc hl
    ld a,h
    and 7
    ld h,a
    ld (nze1cnt+1),hl
    add a,noise>>8
    ld h,a
    ld a,(hl)
    jr nzec1
nzec1
    ld (smc1nze+1),a
    jr nzec2
nzec2
    ld (smc2nze+1),a
    jr nzec3
nzec3
    ld (smc3nze+1),a

smc1cnt
    ld hl,0
smc1out
    ld a,0
    ld bc,cyczx
    sbc hl,bc  
    jr nc,noreload1

smc1per
    ld bc,0
    add hl,bc
    jr c,_nores
    ld bc,cyczx
    add hl,bc
_nores
    xor %11111111
    ld (smc1out+1),a
noreload1
smc1hi
    or $00
smc1vol
    and $00 
smc1nze
    and $00
    ld (de),a
    ld (smc1cnt+1),hl

    inc d
    inc d

smc2cnt
    ld hl,0
loop2
smc2out
    ld a,0
    ld bc,cyczx
    sbc hl,bc  
    jr nc,noreload2

smc2per
    ld bc,0
    add hl,bc
    jr c,_nores
    ld bc,cyczx
    add hl,bc
_nores
    xor %11111111
    ld (smc2out+1),a
noreload2
smc2hi
    or $00
smc2vol
    and $00 
smc2nze
    and $00 
    ld (de),a
    ld (smc2cnt+1),hl

    inc d
    inc d

smc3cnt
    ld hl,0
loop3
smc3out
    ld a,0
    ld bc,cyczx
    sbc hl,bc  
    jr nc,noreload3

smc3per
    ld bc,0
    add hl,bc
    jr c,_nores
    ld bc,cyczx
    add hl,bc
_nores
    xor %11111111
    ld (smc3out+1),a
noreload3
smc3hi
    or $00
smc3vol
    and $00 
smc3nze
    and $00 
    ld (de),a
    ld (smc3cnt+1),hl

    inc e           
    ld a,soundbuffer
    cp e
    jp nz,soundloop


smcbank
    ld a,$00
    out (sys_mem_select),a
;    ld hl,$007		; border colour = blue 
;	ld (palette),hl
    ret 
bufswap  
;    xor a
;    out (sys_audio_enable),a	; silence channels
  
    ld a,(soundloop+1)
    and 1
    ld a,$81
    ld (soundloop+1),a
    ld a,0
    jp z,noadd

doadd
    ld a,$80
    ld (soundloop+1),a

noadd
    ld b,0
    ld c,audchan0_loc
    out (c),a
    ld b,1
    ld c,audchan1_loc
    out (c),a
    ld b,1
    ld c,audchan2_loc
    out (c),a
    ld b,2
    ld c,audchan3_loc
    out (c),a
noclr
 

 ;   ld a,%1111
;    out (sys_audio_enable),a	; silence channels
    ret

 
soundb1 equ $8000
soundb2 equ $8200
soundb3 equ $8400
     

    org (($+256)/256)*256
volv6
;    db 00,00,00,01,01,02,03,04,06,09,13,17,25,34,48,64
    db 000,001,002,003,005,007,010,017,020,032,045,057,072,090,107,127
    db 000,001,002,003,005,007,010,017,020,032,045,057,072,090,107,127
env8
;    db 64,48,34,25,17,13,09,06,04,03,02,01,01,00,00,00 
;    db 127,107,090,072,057,045,032,020,017,010,007,005,003,002,001,000
    db 127,112,096,080,068,059,051,042,035,031,026,022,018,016,013,011
    db 009,008,007,006,005,004,003,003,002,001,001,001,000,000,000,000
envA
;    db 64,34,17,09,04,02,01,00,00,01,02,04,09,17,34,64
;    db 127,090,057,032,017,007,003,001,001,003,007,017,032,057,090,127
    db 127,096,068,051,035,026,018,013,009,007,005,003,002,001,000,000
    db 000,000,001,002,003,005,007,009,013,018,026,035,051,068,096,127
envC
;    db 00,00,00,01,01,02,03,04,06,09,13,17,25,34,48,64
;    db 000,001,002,003,005,007,010,017,020,032,045,057,072,090,107,127
    db 000,000,000,000,001,001,001,002,003,003,004,005,006,007,008,009
    db 011,013,016,018,022,026,031,035,042,051,059,068,080,096,112,127
envE
;    db 00,01,02,04,09,17,34,64,64,34,17,09,04,02,01,00
;    db 001,003,007,017,032,057,090,127,127,090,057,032,017,007,003,001
    db 000,000,001,002,003,005,007,009,013,018,026,035,051,068,096,127
    db 127,096,068,051,035,026,018,013,009,007,005,003,002,001,000,000

    org (($+256)/256)*256
noise
  incbin noisedata.raw

waitdma
    ld a,(vreg_read)
    and $40
    ld b,a
_loop2
    ld a,(vreg_read)
    and $40
    cp b
    jr z,_loop2
    ret

load
fnd_para
	ld a,(hl)
	or a	
	jr z,no_fn
	cp " "			
	jr nz,fn_ok
skp_spc	inc hl
	jr fnd_para
	
no_fn	
    ld hl,nfn_text
	call kjt_print_string
	xor a
	ret
	
fn_ok
	
	ld de,modu_filename	
cpyfn	
    ld a,(hl)
	or a
	jr z,modex
	cp " "
	jr z,modex
	cp "."
	jr z,modex
	ld (de),a
	inc de
	inc hl
	jr cpyfn
	
modex	
    ld hl,mod_ext
modexlp	
    ld a,(hl)
	or a
	jr z,modexdone
	ld (de),a
	inc hl
	inc de
	jr modexlp

modexdone
	
	
	ld hl,modu_filename	
	call kjt_find_file
	jp nz,load_problem

	ld b,0
	ld hl,testmod
	call kjt_force_load		
	jp nz,load_problem

    jp main


load_problem	

	ld hl,load_error_text+2
	call kjt_hex_byte_to_ascii
	ld hl,load_error_text
	call kjt_print_string
	xor a
	ret


nfn_text		db "V6 YM2149 b20092408 by insane/altair",11,"Usage: pt3play [filename]",11,0
mod_ext         	db ".PT3",0

load_error_text	db 11,"$xx - loading error!",11,0

modu_filename   	ds 32,0


  include "vt.asm"

testmod
;  incbin testt1.pt3
;  incbin aywin.pt3
;  incbin arte.pt3
;
