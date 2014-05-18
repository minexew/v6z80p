;======================================================================================
; Standard equates for OSCA and FLOS
;======================================================================================

include "\equates\kernal_jump_table.asm"
include "\equates\osca_hardware_equates.asm"
include "\equates\system_equates.asm"

;-------------------------------------------------------------------------------------
; THIS ONLY WORKS WITH THE VERSION OF OSCA MODIFIED TO COUNT CLOCK INPUTS ON GCLK PINS
;-------------------------------------------------------------------------------------

	org $5000

	ld hl,wait
	call kjt_print_string	

        di                                              ; disable IRQs
        ld a,8
        out ($2b),a                                     ; reset/stop GCLK counter
        
        ld a,0  				
      	out (sys_timer),a			        ; Set the timer latch value (IRQ flag set every 16MHz / (256*256) cycles)

        ld bc,488                                      ; wait 2 seconds
lp3     in a,(sys_irq_ps2_flags)
        and 4
        jp z,lp3
        ld  a,%00000100
        out  (sys_clear_irq_flags),a                    ; Clear the timer IRQ flag
        dec bc
        ld a,b
        or c
        jr nz,lp3

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
	ld hl,hex+6
	call kjt_hex_byte_to_ascii
	ld a,1
        out ($2b),a                                     ;stop GCLK counter,read 8:15
        in a,(sys_serial_port)
	ld hl,hex+4
	call kjt_hex_byte_to_ascii
	ld a,2
        out ($2b),a                                     ;stop GCLK counter,read 23:16
        in a,(sys_serial_port)
	ld hl,hex+2
	call kjt_hex_byte_to_ascii
	ld a,3
        out ($2b),a                                     ;stop GCLK counter,read 31:24
        in a,(sys_serial_port)
	ld hl,hex
	call kjt_hex_byte_to_ascii

	ld hl,string
	call kjt_print_string
	ei
        xor a
        ret

wait    db 11,"Wait...",11,0
	
msg     db 11,"Counting GCLK ticks (In 10 seconds)",11,0
	
string	db 11,"Counted: $"
hex	db "xxxxxxxx GCLK ticks",11,11,0

