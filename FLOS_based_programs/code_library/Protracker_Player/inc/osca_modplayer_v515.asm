;----------------------------------------------------------------------------------------
; OSCA Protracker player - by Phil Ruston - www.retroleum.co.uk
; ---------------------------------------------------------------------------------------
;
; Changes in v5.15
; ----------------
;
; * Added paging routines for generic Z80 modplayer v5.07
; * Module is located with the EQUATES "pt_module_loc_lo" [15:0] and "pt_module_loc_hi" [23:16]
; * Master volume variable added (pt_master_volume, values 64: max to 0: silence)
; * Variable added to return triggered note info for equalizer if desired ("pt_channels_triggered")
;
;
;----------------------------------------------------------------------------------------
; BEWARE! BEWARE!  BEWARE! BEWARE!  BEWARE! BEWARE! BEWARE! BEWARE!  BEWARE! BEWARE!  
;----------------------------------------------------------------------------------------
;
; * The routine "osca_update_audio_hardware" uses entry 0 of the OSCA mult_table!
; * Locate this code in unpaged memory!
;
; ---------------------------------------------------------------------------------------
;
;
; To play mods:
; -------------
;
; Set the following EQUATES in main code:
; 
; "pt_module_loc_lo" = lower 16 bits of flat sysmem location of Protracker module (must be even)
; "pt_module_loc_hi" = upper 8 bits of music module address 
;
;
; Key routines:
; -------------
;
; "pt_set_sample_base"      - OPTIONAL! Sets the address (from A:HL) where the sample data is located.
;                             This address must be even. If the routine is called with an odd
;                             value in A:HL, the samples are assumed to follow the song_data
;                             as in a normal music module) - If needed, call this before "pt_init"
;
; "pt_init"                 - Call once to set the tune to its start point. Tune is unplayable if ZF is not
;                             set upon return.
;
; "osca_play_tracker"       - Call each frame to process and play tune. (This calls "pt_play"
;                             and "osca_update_audio_hardware", skipping every 6th update if OSCA
;                             is in 60Hz mode. If this feature is not required, EG running on Timer IRQs
;			      then "pt_play" then "osca_update_audio_hardware" can be called in sequence)
;
;----------------------------------------------------------------------------------------


;=========================================================================================
; V6Z80P/OSCA SPECIFIC CODE:
;
; Convert Amiga hardware values from Generic Z80 Protracker Player to OSCA spec
; and writes to OSCA hardware registers. Locate this in unpaged memory!
;=========================================================================================

firstchan_period              equ channel_data+period_lo
firstchan_volume              equ channel_data+volume
firstchan_location_lo         equ channel_data+samp_loc_00
firstchan_location_hi         equ channel_data+samp_loc_02
firstchan_length              equ channel_data+samp_len_lo
firstchan_control             equ channel_data+control_bits
firstchan_loop_loc_lo         equ channel_data+samp_loop_loc_00
firstchan_loop_loc_hi         equ channel_data+samp_loop_loc_02
firstchan_loop_len            equ channel_data+samp_loop_len_lo

secondchan_period             equ channel_data+vars_per_channel+period_lo
secondchan_volume             equ channel_data+vars_per_channel+volume
secondchan_location_lo        equ channel_data+vars_per_channel+samp_loc_00
secondchan_location_hi        equ channel_data+vars_per_channel+samp_loc_02
secondchan_length             equ channel_data+vars_per_channel+samp_len_lo
secondchan_control            equ channel_data+vars_per_channel+control_bits
secondchan_loop_loc_lo        equ channel_data+vars_per_channel+samp_loop_loc_00
secondchan_loop_loc_hi        equ channel_data+vars_per_channel+samp_loop_loc_02
secondchan_loop_len           equ channel_data+vars_per_channel+samp_loop_len_lo

thirdchan_period              equ channel_data+(vars_per_channel*2)+period_lo
thirdchan_volume              equ channel_data+(vars_per_channel*2)+volume
thirdchan_location_lo         equ channel_data+(vars_per_channel*2)+samp_loc_00
thirdchan_location_hi         equ channel_data+(vars_per_channel*2)+samp_loc_02
thirdchan_length              equ channel_data+(vars_per_channel*2)+samp_len_lo
thirdchan_control             equ channel_data+(vars_per_channel*2)+control_bits
thirdchan_loop_loc_lo         equ channel_data+(vars_per_channel*2)+samp_loop_loc_00
thirdchan_loop_loc_hi         equ channel_data+(vars_per_channel*2)+samp_loop_loc_02
thirdchan_loop_len            equ channel_data+(vars_per_channel*2)+samp_loop_len_lo

fourthchan_period             equ channel_data+(vars_per_channel*3)+period_lo
fourthchan_volume             equ channel_data+(vars_per_channel*3)+volume
fourthchan_location_lo        equ channel_data+(vars_per_channel*3)+samp_loc_00
fourthchan_location_hi        equ channel_data+(vars_per_channel*3)+samp_loc_02
fourthchan_length             equ channel_data+(vars_per_channel*3)+samp_len_lo
fourthchan_control            equ channel_data+(vars_per_channel*3)+control_bits
fourthchan_loop_loc_lo        equ channel_data+(vars_per_channel*3)+samp_loop_loc_00
fourthchan_loop_loc_hi        equ channel_data+(vars_per_channel*3)+samp_loop_loc_02
fourthchan_loop_len           equ channel_data+(vars_per_channel*3)+samp_loop_len_lo

;----------------------------------------------------------------------------------------

osca_play_tracker
          
          in a,(sys_vreg_read)                    ; Is the OSCA video mode 50 or 60Hz?
          and 32                                  
          jr z,ok_play
          
          ld hl,ptfr_count                        ; 60 Hz, mode - need to skip every 6th frame
          inc (hl)
          ld a,(hl)
          cp 6
          jr nz,ok_play
          ld (hl),0
          ret
          
ok_play   call pt_play

osca_update_audio_hardware


          xor a                                   ; set up maths unit
          ld (mult_index),a
          ld hl,18308                             ; 16000000Hz / 7159090.5Hz * 16384 / 4
          ld (mult_table),hl                      ; to convert period values to OSCA spec
          
          ld hl,(firstchan_period)                ; Amiga period
          add hl,hl
          add hl,hl
          ld (mult_write),hl
          ld hl,(mult_read)
          ld (ch0_convper),hl                     
          ld hl,(secondchan_period)               ; Amiga period
          add hl,hl
          add hl,hl
          ld (mult_write),hl
          ld hl,(mult_read)
          ld (ch1_convper),hl
          ld hl,(thirdchan_period)                ; Amiga period
          add hl,hl
          add hl,hl
          ld (mult_write),hl
          ld hl,(mult_read)
          ld (ch2_convper),hl
          ld hl,(fourthchan_period)               ; Amiga period
          add hl,hl 
          add hl,hl
          ld (mult_write),hl
          ld hl,(mult_read)
          ld (ch3_convper),hl

          
          ld hl,firstchan_control                 ; find which channels are to be (re)triggered
          ld de,vars_per_channel                  
          ld b,4                                  
          ld c,%00000001
          ld a,%00000000      
rtchloop  bit 0,(hl)
          jr z,ch_no_rt
          res 0,(hl)
          or c
ch_no_rt  rlc c
          add hl,de
          djnz rtchloop
          ld d,a
          
;-----------------------------------------------------------------------------------------------------------
 
	  ld (pt_channels_triggered),a		  ; Just for external equalizer
	  
;-----------------------------------------------------------------------------------------------------------
                                                                                          
          call wait_dma                           ; wait for the start of a scan line (post audio DMA)
    
          ld a,d                                  ; temp. disable channels that need retriggering
          cpl                                     ; (no effect until start of next scanline)
          ld e,a
          in a,(sys_audio_enable)                  
          and e                                   
          out (sys_audio_enable),a                                              

;---------------------------------------------------------------------------------------------------------------
; Write Period / Volume of all channels and Loc and Len of triggered channels
;---------------------------------------------------------------------------------------------------------------

	  ld ix,pt_master_vol

          ld hl,(ch0_convper)                     ; b = period value (hi)
          ld b,h                                  ; a = period value (lo)
          ld c,audchan0_per   
          out (c),l                               ; 16 bit write
          ld a,(firstchan_volume)                 ; volume value
          cp (ix)
	  jr c,mvch0ok				  ; if master volume is lower than chan vol, use master vol
	  ld a,(ix)
mvch0ok	  out (audchan0_vol),a                    ; write volume to HW register

          bit 0,d                                 ; set loc and len if triggered
          jr z,nnllch0        
          ld hl,(firstchan_location_lo)
          ld a,(firstchan_location_hi)
          srl a                                   ; covert A:HL to word address
          rr h
          rr l
          ld b,h                                   
          ld c,audchan0_loc
          out (c),l                               ; 16 bit loc write
          out (audchan0_loc_hi),a                 ; extra loc hi bits (for OSCAv672+)  
          
          ld hl,(firstchan_length)                
          ld b,h                                   
          inc c
          out (c),l                               ; 16 bit len write

nnllch0   

	  ld hl,(ch1_convper)                     ; b = period value (hi)
          ld b,h                                  ; a = period value (lo)
          ld c,audchan1_per   
          out (c),l                               ; 16 bit write
          ld a,(secondchan_volume)                ; volume value
          cp (ix)
	  jr c,mvch1ok				  ; if master volume is lower than chan vol, use master vol
	  ld a,(ix)
mvch1ok	  out (audchan1_vol),a                    ; write volume to HW register

          bit 1,d                                 ; set loc and len if triggered
          jr z,nnllch1        
          ld hl,(secondchan_location_lo)
          ld a,(secondchan_location_hi)
          srl a                                   ; covert A:HL to word address
          rr h
          rr l
          ld b,h                                   
          ld c,audchan1_loc
          out (c),l                               ; 16 bit loc write
          out (audchan1_loc_hi),a                 ; extra loc hi bits (for OSCAv672+)  
          
          ld hl,(secondchan_length)
          ld b,h                                   
          inc c
          out (c),l                               ; 16 bit len write

nnllch1
	
	  ld hl,(ch2_convper)                     ; b = period value (hi)
          ld b,h                                  ; a = period value (lo)
          ld c,audchan2_per   
          out (c),l                               ; 16 bit write
          ld a,(thirdchan_volume)
          cp (ix)
	  jr c,mvch2ok				  ; if master volume is lower than chan vol, use master vol
	  ld a,(ix)
mvch2ok	  out (audchan2_vol),a                    ; write volume to HW register

          bit 2,d                                 ; set loc and len if triggered
          jr z,nnllch2
          ld hl,(thirdchan_location_lo)
          ld a,(thirdchan_location_hi)
          srl a                                   ; covert A:HL to word address
          rr h
          rr l
          ld b,h                                   
          ld c,audchan2_loc
          out (c),l                               ; 16 bit loc write
          out (audchan2_loc_hi),a                 ; extra loc hi bits (for OSCAv672+)  

          ld hl,(thirdchan_length)
          ld b,h                                   
          inc c
          out (c),l                               ; 16 bit len write


nnllch2   

	
	  ld hl,(ch3_convper)                     ; b = period value (hi)
          ld b,h                                  ; a = period value (lo)
          ld c,audchan3_per   
          out (c),l                               ; 16 bit write
          ld a,(fourthchan_volume)
          cp (ix)
	  jr c,mvch3ok				  ; if master volume is lower than chan vol, use master vol
	  ld a,(ix)
mvch3ok	  out (audchan3_vol),a                    ; write volume to HW register
          
          bit 3,d                                 ; set loc and len if triggered
          jr z,nnllch3
          ld hl,(fourthchan_location_lo)
          ld a,(fourthchan_location_hi)
          srl a                                   ; covert A:HL to word address
          rr h
          rr l
          ld b,h                                   
          ld c,audchan3_loc
          out (c),l                               ; 16 bit loc write
          out (audchan3_loc_hi),a                 ; extra loc hi bits (for OSCAv672+)  
          
          ld hl,(fourthchan_length)
          ld b,h                                   
          inc c
          out (c),l                               ; 16 bit len write

nnllch3   


;----------------------------------------------------------------------------------------------------------------

          call wait_dma                           ; wait for next line (loc/len values written above          

          in a,(sys_audio_enable)                 ; restart retriggered audio channels (no effect until
          or d                                    ; start of next scan line)
          out (sys_audio_enable),a

          
;----------------------------------------------------------------------------------------------------------------
; Rewrite loc and len for loop if triggered
;----------------------------------------------------------------------------------------------------------------


          bit 0,d                                  
          jr z,nnlllch0
          ld hl,(firstchan_loop_loc_lo)           ; redo loc and len for loop if triggered
          ld a,(firstchan_loop_loc_hi)
          srl a                                   ; convert to WORD location
          rr h
          rr l
          ld b,h                                   
          ld c,audchan0_loc
          out (c),l                               ; 16 bit loc write
          out (audchan0_loc_hi),a                 ; extra loc hi bits (for OSCAv672+)  
          
          ld hl,(firstchan_loop_len)
          ld b,h                                   
          inc c
          out (c),l                               ; 16 bit len write
          
nnlllch0  


	  bit 1,d                                 
          jr z,nnlllch1                           ; redo loc and len for loop if triggered
          ld hl,(secondchan_loop_loc_lo)
          ld a,(secondchan_loop_loc_hi)
          srl a                                   ; convert to WORD location
          rr h
          rr l
          ld b,h                                   
          ld c,audchan1_loc
          out (c),l                               ; 16 bit loc write
          out (audchan1_loc_hi),a                 ; extra loc hi bits (for OSCAv672+)  
          
          ld hl,(secondchan_loop_len)
          ld b,h                                   
          inc c
          out (c),l                               ; 16 bit len write

nnlllch1

         
	  bit 2,d                                 
          jr z,nnlllch2                           ; redo loc and len for loop if triggered
          ld hl,(thirdchan_loop_loc_lo)
          ld a,(thirdchan_loop_loc_hi)
          srl a                                   ; convert to WORD location
          rr h
          rr l
          ld b,h                                   
          ld c,audchan2_loc
          out (c),l                               ; 16 bit loc write
          out (audchan2_loc_hi),a                 ; extra loc hi bits (for OSCAv672+)  
          
          ld hl,(thirdchan_loop_len)
          ld b,h                                   
          inc c
          out (c),l                               ; 16 bit len write
                              
nnlllch2 


	  bit 3,d                                 
          jr z,nnlllch3                           ; redo loc and len for loop if triggered
          ld hl,(fourthchan_loop_loc_lo)
          ld a,(fourthchan_loop_loc_hi)
          srl a                                   ; convert to WORD location
          rr h
          rr l
          ld b,h                                   
          ld c,audchan3_loc
          out (c),l                               ; 16 bit loc write
          out (audchan3_loc_hi),a                 ; extra loc hi bits (for OSCAv672+)  
          
          ld hl,(fourthchan_loop_len)
          ld b,h                                   
          inc c
          out (c),l                               ; 16 bit len write
          
nnlllch3  ret

;------------------------------------------------------------------------------------------

wait_dma  in a,(sys_vreg_read)                    ;wait for LSB for scanline count to change
          and $40
          ld b,a
loop2     in a,(sys_vreg_read)
          and $40
          cp b
          jr z,loop2
          ret

;------------------------------------------------------------------------------------------

pt_read_module_byte	

; set DE to offset from start of module for byte required
; byte is returned in A
	  
	  push hl
          push de
	  push bc
	  ld a,pt_module_loc_hi
	  ld hl,pt_module_loc_lo
	  add hl,de
	  adc a,0
	  ld e,a
	  call kjt_read_sysram_flat		; FLOS call (get byte from E:HL in A) - if FLOS not available
	  pop bc				; the equivalent routine must be unpaged RAM
	  pop de
	  pop hl
	  ret


pt_get_note_row

; Copies 16 bytes of pattern data from flat A:HL to "pt_note_row"
; A:HL = source address
	  
	  exx					; This is pretty slow - if an optimized non-kernal calling routine
	  ld hl,pt_note_row			; is used, it must be in unpaged memory (and be careful with
	  exx					; location of pt_note_row: it may also need to be put in unpaged ram	  				
	  ld d,16				; if routine does not restore original bank after each byte read)
	  ld e,a
pt_gnrlp  push hl
	  push de
	  call kjt_read_sysram_flat		; FLOS call (get byte from E:HL in A) - if FLOS not available
	  pop de				; the equivalent routine must be in unpaged RAM
	  pop hl
	  exx
	  ld (hl),a
	  inc hl
	  exx
	  ld bc,1				
	  add hl,bc				
	  jp nc,pt_gnrnc
	  inc e
pt_gnrnc  dec d
	  jr nz,pt_gnrlp
	  ret



pt_zero_byte

;set A:HL to address to write zero to

	 push hl				; zeroes the byte at A:HL
	 push de
	 push bc
	 push af
	 ld e,a
	 xor a
	 call kjt_write_sysram_flat
	 pop af
	 pop bc
	 pop de
	 pop hl
  	 ret
	  
;------------------------------------------------------------------------------------------
	  
ch0_convper     	dw 0                    ; for Amiga period -> OSCA conversion
ch1_convper     	dw 0
ch2_convper     	dw 0
ch3_convper     	dw 0

ptfr_count      	db 0                    ; for 60Hz->50Hz conversion

pt_master_vol		db 64

pt_channels_triggered	db 0			; for equalizer support
         

;-----------------------------------------------------------------------------------------
; An example of a faster OSCA / non-FLOS "pt_get_note_row" routine (untested).
;-----------------------------------------------------------------------------------------
;
;pt_get_note_row
;
; Copies 16 bytes of pattern data from flat A:HL to unpaged memory (IE: below $8000)
;	  
;	  sla h					; Convert A:HL flat address to OSCA mem_select page:address	
;	  rla					; Note: If A:HL < $10000, page = 0 (addr = $0-$ffff)
;	  cp 2					;       If A:HL > $0FFFF, page = 2+ (addr = $8000-$ffff)
;	  ccf
;	  rr h
;	  
;	  ld b,a
;         in a,(sys_mem_select)
;         push af
;	  ld a,b
;	  out (sys_mem_select),a
;	  
;	  ld de,pt_note_row			; "pt_note_row" must be in unpaged memory
;	  ld bc,8
;pt_cnrlp ldi
;	  ldi
;	  jp p,pt_cnrd
;	  ld a,h				; need to check for source page overflow $ffff->$0 
;	  or l					; (only on evens since module is WORD aligned)
;	  jp nz,pt_cnrlp
;	  in a,(sys_mem_select)
;	  inc a
;	  out (sys_mem_select),a
;	  ld h,$80
;	  jp pt_cnrlp 
;	  
;pt_cnrlp pop af
;	  out (sys_mem_select),a
;	  ret
;
; pt_note_row ds 16,0				; THIS DATA ARRAY WOULD NEED TO BE IN UNPAGED MEMORY!

	
;=========================================================================================
; END OF V6Z80P OSCA SPECIFIC CODE
;=========================================================================================


	include "FLOS_based_programs\code_library\Protracker_Player\inc\generic_z80_modplayer.asm"

