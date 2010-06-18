;---Standard header for V5Z80P and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

timer1   EQU 251
timer2   EQU 250

	ORG $5000
    JP load 
    JP update_sound_hardware
main
copbyt MACRO xA,xB
    LD A,(xA)
    LD (xB),A
ENDM

bsam MACRO
    LD A,4
    OUT (sys_mem_select),A
ENDM
bram MACRO
    XOR A
    OUT (sys_mem_select),A
ENDM
    copbyt $A01,oldirq
    copbyt $A02,oldirq+1

    DI
    LD A,IRQH&$FF
    LD ($A01),A
    LD A,IRQH>>8
    LD ($A02),A
    LD A,timer1 
    OUT (sys_timer),A
    LD A,%10000101 
    OUT (sys_irq_enable),A

    LD HL,$8000
    bsam
    call dosampl 
    call dosampl
    call dosampl 
    call dosampl 

    LD HL,$8800
    LD BC,$800
    LD DE,noiserom
noiseloop
    LD A,(DE)
    LD (HL),A

    INC HL
    INC DE
    DEC BC
    LD A,B
    OR C
    JR NZ,noiseloop
    
    bram
    LD A,0
    LD B,0
    LD C,audchan0_loc
    OUT (C),A
    LD A,8
    LD C,audchan1_loc
    OUT (C),A
    LD A,12
    LD C,audchan2_loc
    OUT (C),A
    LD A,4
    LD B,0
    LD C,audchan0_len
    OUT (C),A
    LD C,audchan1_len
    OUT (C),A
    LD C,audchan2_len
    OUT (C),A
    LD A,7
    OUT (sys_audio_enable),A
    
    LD HL,testmod
    CALL START+3
    EI
;--------- Main loop ---------------------------------------------------------------------	
	
waitloop
    ld a,(timer_counter)
    cp a
    jr nz,waitloop
	call kjt_get_key		; non-waiting key press test
	or a
	jr z,waitloop		; loop if no key pressed

    di
    copbyt oldirq  ,$a01
    copbyt oldirq+1,$a02
    xor a
    OUT (sys_timer),A
    ld A,%10000011
    out (sys_irq_enable),A
    ei

	xor a
	out (sys_audio_enable),a	; silence channels
	xor a			; and quit
	ret

; -- V62149
dosampl 
    LD B,0
copyloop 
    LD (HL),$7F
    INC HL
    LD (HL),$7F
    INC HL
    LD (HL),$7F
    INC HL
    LD (HL),$7F
    INC HL
    LD (HL),$80
    INC HL
    LD (HL),$80
    INC HL
    LD (HL),$80
    INC HL
    LD (HL),$80
    INC HL
    DJNZ copyloop
    ret

    org (($+256)/256)*256

volv6
    db 00,00,00,01,01,02,03,04,06,09,13,17,25,34,48,64
env8
    db 64,48,34,25,17,13,09,06,04,03,02,01,01,00,00,00 
envA
    db 64,34,17,09,04,02,01,00,00,01,02,04,09,17,34,64
envC
    db 00,00,00,01,01,02,03,04,06,09,13,17,25,34,48,64
envE
    db 00,01,02,04,09,17,34,64,64,34,17,09,04,02,01,00
    db 00,00,00,00,00,00,00,01,01,01,02,02,03,03,04,04,05,06,08,09,11,13,15,17,21,25,29,34,40,48,56,64,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

update_sound_hardware
	xor a				; set up maths unit
	ld (mult_index),a
;	ld hl,18308			; 16000000Hz / 7159090.5Hz * 16384 / 4
;   ld hl,37449
    ld hl,2304
	ld (mult_table),hl			; to convert period values to V5Z80P spec
    LD HL,(AYREGS+Env)
    ld (mult_write),hl
    ld a,(mult_read)
    ld (buzzspd),a 
    ld hl,18724
	ld (mult_table),hl			; to convert period values to V5Z80P spec

writeper MACRO ofs,v6,xbit
    LD HL,(AYREGS+ofs)
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
	ld (mult_write),hl
	ld hl,(mult_read)
    LD B,H
    LD C,v6
    LD A,L
    OUT (C),A
ENDM 

writevol MACRO ofs,v6,mac
    LD C,v6
    LD A,(AYREGS+ofs)
    BIT 4,A
    JR NZ,_prepenv
    LD L,A
    ld a,(hl)
    OUT (C),A
    LD A,02
    LD (mac),A
    JR _noenv
_prepenv
    LD A,00
    LD (mac),A
_noenv
ENDM
;    waith
    writeper TonA,audchan0_per,3
    writeper TonB,audchan1_per,4
    writeper TonC,audchan2_per,5

    LD H,volv6>>8

    writevol AmplA,audchan0_vol,envsmcA-1
    writevol AmplB,audchan1_vol,envsmcB-1
    writevol AmplC,audchan2_vol,envsmcC-1

    
writenze MACRO nbit,smc ;3=a 4=b 5=c   bit = zero -> noise enabled
    LD B,$62
    LD A,(AYREGS+Mixer)
    BIT nbit,A
    JR nz,_nonoise
    LD B,$63
_nonoise
    LD A,B
    LD (smc),A
ENDM
;    waith
    writenze 3,noisesmc1
    writenze 4,noisesmc2
    writenze 5,noisesmc3
   
;    LD A,0
;    OUT (sys_audio_enable),A
;    LD A,7
;    OUT (sys_audio_enable),A
    
    
    LD A,(AYREGS+EnvTp)
    AND A
    RET M
    AND %00000110
    ADD A,A
    ADD A,A
    ADD A,A
    ADD A,$10
    LD (wavesel+1),A
    ld a,(buzzspd)
    ld (buzzcnt),a
    xor a
    ld (buzzpos),a
    RET

; -- IRQ HANDLER --
IRQH
    push af
    in a,(sys_irq_ps2_flags)
    bit 2,a
    jr nz,newtimer
    pop af
    db $C3
oldirq dw 0

; -- buzzer + player
newtimer
    push hl
    ld a,(timer_counter)
    dec a
    ld (timer_counter),a
    jr nz,timerfinish

	ld hl,$ff0 		; border colour = green
    ld (palette),hl
    ld a,timer2
    ld (timer_counter),a
    exx
    call START+5
;    call update_sound_hardware

    exx	
timerfinish
    ld hl,$0f7
	ld (palette),hl
 
    ld a,(buzzcnt)
    dec a
    ld (buzzcnt),a
    jr nz,nobuzzinc

    ld a,(buzzspd)
    ld (buzzcnt),a
    ld a,(buzzpos)
    inc a
    and 15
    ld (buzzpos),a
nobuzzinc
    ld a,(buzzpos)
wavesel
    or $00
    ld l,a
    ld h,volv6>>8
    ld a,(hl)
    jr envsmcA
envsmcA
    out (audchan0_vol),a
    jr envsmcB
envsmcB
    out (audchan1_vol),a
    jr envsmcC
envsmcC
    out (audchan2_vol),a

; jp skipit
    ld a,(noisepos)
    dec a
    ld (noisepos),a
    ld h,0
    ld l,a
    ld bc,noiserom
    add hl,hl
    add hl,hl
    add hl,hl

    add hl,bc

wvcopy MACRO
    ld a,(hl)
    ld (bc),a
    inc hl
    inc bc
ENDM    


    ld bc,$8000
    ld d,squarerom>>8
    ld e,h
    bsam
noisesmc1
    ld h,d

    REPT 8
      wvcopy
    ENDM

noisesmc2
    ld h,d
    REPT 8
      wvcopy
    ENDM

noisesmc3
    ld h,d
    REPT 8
      wvcopy
    ENDM
    bram 
skipit
    ld hl,$007		; border colour = blue 
	ld (palette),hl
    ld a,%00000100
    out (sys_clear_irq_flags),a
    pop hl
    pop af
    ei
    reti

timer_counter db timer2
buzzspd db 4 
buzzcnt db 1 
buzzpos db 0
oldnoise db 0
noisepos dw 1

    org (($+256)/256)*256
noiserom
    incbin noisedata.raw
squarerom
    incbin squaredat.raw
   
load

fnd_para	ld a,(hl)			; find actual argument text, if encounter 0
	or a			; then give up
	jr z,no_fn
	cp " "			
	jr nz,fn_ok
skp_spc	inc hl
	jr fnd_para
	
no_fn	ld hl,nfn_text
	call kjt_print_string
	xor a
	ret
	
fn_ok
	
	ld de,modu_filename		; create extended filename
cpyfn	ld a,(hl)
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
	
modex	ld hl,mod_ext		;append ".mod" to filename
modexlp	ld a,(hl)
	or a
	jr z,modexdone
	ld (de),a
	inc hl
	inc de
	jr modexlp

modexdone
	
	
	ld hl,modu_filename		; load pattern data
	call kjt_find_file
	jp nz,load_problem

	ld b,0
	ld hl,testmod
	call kjt_force_load		; load the first 1084 bytes of the module
	jp nz,load_problem

    jp main


load_problem	

	ld hl,load_error_text+2
	call kjt_hex_byte_to_ascii
	ld hl,load_error_text
	call kjt_print_string
	xor a
	ret


nfn_text		db "V62149 PT3 Player v0.9 by insane/altair",11,"Usage: pt3play [filename]",11,0
mod_ext         	db ".PT3",0

load_error_text	db 11,"$xx - loading error!",11,0

modu_filename   	ds 32,0

include "vt.asm"

testmod
;  incbin Chuta.pt3
;  incbin testt1.pt3
;  incbin ARTe_ST1.pt3
;  incbin CC000ID.pt3



