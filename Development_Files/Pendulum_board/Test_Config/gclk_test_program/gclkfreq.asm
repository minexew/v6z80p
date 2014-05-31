;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"


;-------------------------------------------------------------------------------------
; THIS ONLY WORKS WITH THE VERSION OF OSCA MODIFIED TO COUNT CLOCK INPUTS ON GCLK PINS
;-------------------------------------------------------------------------------------

	org $5000
        
        call kjt_clear_screen

reloop  ld bc,0
        call kjt_set_cursor_position
            
        
;	ld hl,wait
;	call kjt_print_string	

        di                                              ; disable IRQs

        ld a,8
        out ($2b),a                                     ; reset/stop GCLK counter
        
;       ld a,0  				
;     	out (sys_timer),a			        ; Set the timer latch value (IRQ flag set every 16MHz / (256*256) cycles)
;
;       ld bc,488                                      ; wait 2 seconds
;lp3    in a,(sys_irq_ps2_flags)
;       and 4
;       jp z,lp3
;       ld  a,%00000100
;       out  (sys_clear_irq_flags),a                    ; Clear the timer IRQ flag
;       dec bc
;       ld a,b
;       or c
;       jr nz,lp3

	ld hl,msg
	call kjt_print_string	

        ld  a,%00000100
        out  (sys_clear_irq_flags),a                    ;Clear the timer IRQ flag

        ld a,0  				
      	out (sys_timer),a			        ;Set the timer latch value (IRQ flag set every 16MHz / (256*256) cycles)

        ld a,4
        out ($2b),a                                     ;start GCLK counter
        ld bc,2441                                      ;wait 10 seconds
lp1     in a,(sys_irq_ps2_flags)
        and 4
        jp z,lp1
        ld  a,%00000100
        out  (sys_clear_irq_flags),a                    ; Clear the timer IRQ flag
        dec bc
        ld a,b
        or c
        jr nz,lp1

        ld a,102				
        out (sys_timer),a
        ld  a,%00000100
        out  (sys_clear_irq_flags),a                    ; Clear the timer IRQ flag
        nop                                             ; A little extra time for accuracy
lp2     in a,(sys_irq_ps2_flags)
        and 4
        jp z,lp2
  

        
        ld a,0
        out ($2b),a                                     ;stop GCLK counter,read 0:7
        in a,(sys_serial_port)
	ld l,a
        
	ld a,1
        out ($2b),a                                     ;stop GCLK counter,read 8:15
        in a,(sys_serial_port)
	ld h,a
        
        ld a,2
        out ($2b),a                                     ;stop GCLK counter,read 23:16
        in a,(sys_serial_port)
	ld e,a
        
	ld a,3
        out ($2b),a                                     ;stop GCLK counter,read 31:24
        in a,(sys_serial_port)
	ld d,a
       
;        ld hl,$7600                                    ;test values: 28.000000 MHz
;        ld de,$10b0
        
;        ld hl,$ae70                                    ;test values: 28.375000 MHz
;        ld de,$10e9
        
       
        push de
        pop ix
        ld iy,result_dec_txt

        ld bc,$e100
        ld de,$05f5
        ld a,255
hmillp  inc a
        scf
        ccf
        sbc hl,bc
        push hl
        push ix
        pop hl
        sbc hl,de
        push hl
        pop ix
        pop hl
        jr nc,hmillp
        add a,$30
        cp $3a
        jp nc,range_error
        ld (iy),a
        add hl,bc
        push hl
        push ix
        pop hl
        adc hl,de
        push hl
        pop ix
        pop hl
        inc iy

        ld bc,$9680
        ld de,$0098
        ld a,255
tmillp  inc a
        scf
        ccf
        sbc hl,bc
        push hl
        push ix
        pop hl
        sbc hl,de
        push hl
        pop ix
        pop hl
        jr nc,tmillp
        add a,$30
        ld (iy),a
        add hl,bc
        push hl
        push ix
        pop hl
        adc hl,de
        push hl
        pop ix
        pop hl
        inc iy
        
        
        ld (iy),"."
        inc iy
        
        ld bc,$4240
        ld de,$000f
        ld a,255
millp   inc a
        scf
        ccf
        sbc hl,bc
        push hl
        push ix
        pop hl
        sbc hl,de
        push hl
        pop ix
        pop hl
        jr nc,millp
        add a,$30
        ld (iy),a
        add hl,bc
        push hl
        push ix
        pop hl
        adc hl,de
        push hl
        pop ix
        pop hl
        inc iy
        
        ld bc,$86a0
        ld de,$0001
        ld a,255
hthlp   inc a
        scf
        ccf
        sbc hl,bc
        push hl
        push ix
        pop hl
        sbc hl,de
        push hl
        pop ix
        pop hl
        jr nc,hthlp
        add a,$30
        ld (iy),a
        add hl,bc
        push hl
        push ix
        pop hl
        adc hl,de
        push hl
        pop ix
        pop hl
        inc iy
        
        ld bc,10000
        ld de,0
        ld a,255
tthlp   inc a
        scf
        ccf
        sbc hl,bc
        push hl
        push ix
        pop hl
        sbc hl,de
        push hl
        pop ix
        pop hl
        jr nc,tthlp
        add a,$30
        ld (iy),a
        add hl,bc
        push hl
        push ix
        pop hl
        adc hl,de
        push hl
        pop ix
        pop hl
        inc iy
        
  
        ld bc,1000
        ld de,0
        ld a,255
thlp    inc a
        scf
        ccf
        sbc hl,bc
        push hl
        push ix
        pop hl
        sbc hl,de
        push hl
        pop ix
        pop hl
        jr nc,thlp
        add a,$30
        ld (iy),a
        add hl,bc
        push hl
        push ix
        pop hl
        adc hl,de
        push hl
        pop ix
        pop hl
        inc iy

        ld bc,100
        ld de,0
        ld a,255
hlp     inc a
        scf
        ccf
        sbc hl,bc
        push hl
        push ix
        pop hl
        sbc hl,de
        push hl
        pop ix
        pop hl
        jr nc,hlp
        add a,$30
        ld (iy),a
        add hl,bc
        push hl
        push ix
        pop hl
        adc hl,de
        push hl
        pop ix
        pop hl
        inc iy

        ld bc,10
        ld de,0
        ld a,255
tlp     inc a
        scf
        ccf
        sbc hl,bc
        push hl
        push ix
        pop hl
        sbc hl,de
        push hl
        pop ix
        pop hl
        jr nc,tlp
        add a,$30
        ld (iy),a
        add hl,bc
        push hl
        push ix
        pop hl
        adc hl,de
        push hl
        pop ix
        pop hl
        inc iy
        
      
;        ld a,l                                         ;tenths
;        add a,$30
;        ld (iy),a

        
	ld hl,osc_txt
	call kjt_print_string
	ei
        
testesc call kjt_get_key
        cp $76
        jp nz,reloop
        
        xor a
        ret

range_error
        
        ld hl,bad_txt
	call kjt_print_string
        jr testesc
        

msg     db 11,"Counting GCLK ticks (every 10 seconds)",11,0

osc_txt db 11,"GCLK oscillator speed:"
	
result_dec_txt

        db "xx.xxxxxx MHz",0
        
bad_txt db 11,"Frequency invalid or > 99 MHz!",0
