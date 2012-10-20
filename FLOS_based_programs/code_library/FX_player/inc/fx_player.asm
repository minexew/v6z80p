
; *****************************************************************
; * Multichannel Sound FX player for V6Z80P by Phil Ruston. V2.00 *
; *****************************************************************
;
; Call "new_fx" with SFX number in A to initialize a new effect
;
; Call "play_fx" every frame to update registers / run scripts etc.
;
;SOURCE TAB SIZE = 10
;
;----------------------------------------------------------------------------------------

new_fx    
          or a                          ;Start a new sound effect. If A = 0, do nothing             
          ret z
          dec a
          and $1f
          ld e,a
          ld d,0
          ld hl,fx_data
          add hl,de
          ld a,(hl)                     ;get actual fx number from translation table
          ld l,a
          ld h,0
          add hl,hl
          add hl,hl
          add hl,hl
          add hl,hl
          ld de,fx_data
          add hl,de
          ld de,(fx_data+32)
          add hl,de
          ld (fx_base),hl               ;first two bytes @ HL are "fx priority" and "fx pri active"..
          
          xor a
          ld (fx_channel_mask),a
          ld ix,fx_init_chan_data0      
          ld b,1                        ;first mask bit
          ld c,0                        ;index to channel fx triplet.. IE: 0,3,6,9

fx_gicdlp ld iy,(fx_base)     
          ld l,(iy)                     ;L = priority level
          ld h,(iy+1)                   ;H = priority time
          ld e,c
          ld d,0
          add iy,de                     ;move to channel's 3 byte group
          ld a,(iy+2)                   ;get and store wave type
          ld (ix+12),a                  
          or a
          jr z,fx_gsinfo                ;skip this channel of the FX if no wave is defined for it
          ld a,l
          cp (ix+13)
          jp c,fx_gsinfo                ;skip this channel if priority of new fx is lower than that playing
          ld (ix+13),l                  ;set priority level
          ld (ix+14),h                  ;set priority active time
          ld a,(iy+3)                   ;get volume (00-FF)
          ld (ix+10),a                  
          ld a,(iy+4)                   ;get script number
          ld (ix+11),a                  
          xor a
          ld (ix+15),a                  ;reset frame wait countdown
          ld (ix+16),a                  ;reset script position
          ld (ix+17),a
          ld (ix+18),a                  ;reset loop position
          ld (ix+19),a
          ld (ix+20),a
          ld (ix+21),$02                ;default min period $0200
          ld (ix+22),a
          ld (ix+23),$20                ;default max period $2000
          ld (ix+26),a
          ld (ix+27),a                  ;default repeat point $FF00 = undefined
          ld (ix+28),$ff
          ld (ix+29),1                  ;set anti-lock flag on fx start, clear option bits
          ld a,(ix+12)                  ;get wave type
          call fx_setup_wave
          
fx_gsinfo ld de,30                      
          add ix,de                     ;move to next address in chan variables list
          sla b                         ;bit position for channel mask
          ld a,c
          add a,3                       ;move to next chan's position in fx list
          ld c,a
          cp 4*3
          jp nz,fx_gicdlp
          ret
          

;-----------------------------------------------------------------------------------------------

fx_setup_wave
          
          dec a                         ;set A to wave type when calling this
          ld l,a
          ld h,0
          add hl,hl
          add hl,hl
          add hl,hl
          add hl,hl
          ld de,fx_data
          add hl,de
          ld de,(fx_data+34)
          add hl,de
          push hl
          pop iy                        ;iy = wave base
          
          ld a,(fx_channel_mask)        ;update trigger mask
          or b
          ld (fx_channel_mask),a

          ld a,(iy)                     ;get sample number
          dec a
          sla a
          sla a
          ld l,a
          ld h,0
          ld de,fx_data
          add hl,de
          ld de,(fx_data+36)            
          add hl,de                     ;entry = position in loc/len list
          ld e,(hl)
          inc hl
          ld d,(hl)
          ld (fx_sample_base),de        ;sample base location
          ld l,(iy+1)                   ;start marker
          ld h,(iy+2)
          add hl,de
          ld (ix),l
          ld (ix+1),h                   ;store samp (wave clip's) start
          
          ld e,(iy+1)                   ;start marker
          ld d,(iy+2)
          ld l,(iy+3)                   ;end marker
          ld h,(iy+4)         
          xor a
          sbc hl,de
          ld (ix+2),l
          ld (ix+3),h                   ;store samp (wave clip's) len
          
          ld l,(iy+9)                             
          ld h,(iy+10)
          ld (ix+4),l                   ;store samp (wave clip's) period
          ld (ix+5),h
          
          ld a,(iy+11)                  ;does this clip loop?
          cp "Y"
          jr z,fx_loopy
          ld (ix+6),0                   ;if not, loop back to first word of sample ram
          ld (ix+7),0                   ;using loop len = 1 (IE: silence)
          ld (ix+8),1
          ld (ix+9),0
          ret
          
fx_loopy  ld hl,(fx_sample_base)        ;sample loc
          ld e,(iy+5)                   ;loop start marker
          ld d,(iy+6)
          add hl,de
          ld (ix+6),l
          ld (ix+7),h                   ;store loop location
          
          ld e,(iy+5)                   ;loop start marker
          ld d,(iy+6)
          ld l,(iy+7)                   ;loop end marker
          ld h,(iy+8)         
          xor a
          sbc hl,de
          ld (ix+8),l
          ld (ix+9),h                   ;store loop length
          ret
                    
;--------------------------------------------------------------------------------------------

play_fx

          call fx_trigger_channels
          
          ld ix,fx_init_chan_data0      ;Channel variable base
          ld c,$12                      ;Channel's Port address+2 (Period)
          call fx_process_script
          
          ld ix,fx_init_chan_data1
          ld c,$16
          call fx_process_script
          
          ld ix,fx_init_chan_data2
          ld c,$1a
          call fx_process_script
                    
          ld ix,fx_init_chan_data3
          ld c,$1e
          call fx_process_script
          ret


;---------------------------------------------------------------------------------------------

fx_process_script
          
          
          ld a,(ix+14)                  ;deal with priority counter
          or a
          jr z,fx_pri0
          dec (ix+14)
          jr nz,fx_pri0                 
          ld (ix+13),0                  ;once priority counter reaches 0, clear the priorty level
          
fx_pri0   ld a,(ix+15)                  ;any frame wait delay active?
          or a
          jr z,scr_nofwd
          dec (ix+15)                   ;count down one frame and exit if not zero
          ret nz

scr_nofwd 
          
          ld a,(ix+11)                  ;script number to use, if 0 exit
          or a
          ret z

          dec a
          sla a
          sla a
          ld hl,fx_data                 ;locate script data
          ld e,a
          ld d,0
          add hl,de
          ld de,(fx_data+38)
          add hl,de
          ld e,(hl)
          inc hl
          ld d,(hl)           
          ld hl,fx_data
          add hl,de
          ld de,(fx_data+40)
          add hl,de                     ;hl = first byte of this script
          ld (fx_script_base),hl

scr_nxt_ins
          
          ld hl,(fx_script_base)
          ld e,(ix+16)
          ld d,(ix+17)                  ;de = current script PC
          add hl,de
          push hl
          pop iy
          
          ld a,(hl)                     ;script opcode byte
          cp 17                         ;crash protection if command > 16 is encountered
          jr c,scr_cmdir
          xor a
scr_cmdir sla a
          ld e,a
          ld d,0
          ld hl,script_cmd_locs         ;find code location for this command
          add hl,de
          ld e,(hl)
          inc hl
          ld d,(hl)
          ex de,hl
          call scr_cmd_call
          ld a,(ix+11)                  ;if the script number is now 0, we need
          or a                          ;to stop processing (end of script).
          ret z
          ld a,(ix+15)                  ;if a frame wait delay has been set
          or a                          ;escape from script processing
          ret nz
          jr scr_nxt_ins                ;otherwise, see what the next command is..

          
scr_cmd_call
          
          jp (hl)

;--------------------------------------------------------------------------------

          
scr_cmd0  ld a,(ix+28)                  
          cp $ff                        ;cmd 0 : DONE  (This will return to repeat
          jr z,scr_exit                 ;point as long as the anti-lock bit has been      
          bit 0,(ix+29)                 ;cleared by a wait command, otherwise
          jr nz,scr_exit                ;the script is aborted)
          ld l,(ix+27)
          ld h,(ix+28)
          ld (ix+16),l
          ld (ix+17),h
          ret

scr_exit  ld (ix+11),0                  ;clear script number: No more script processing.
          ret


;--------------------------------------------------------------------------------


scr_cmd1  ld a,(iy+1)                   ;set volume command
          ld (ix+10),a                  ;update volume var  
          srl a
          srl a
          inc c
          out (c),a                     ;update volume port
          dec c
          ld de,2
          call scr_pc_plus
          ret
          

;--------------------------------------------------------------------------------


scr_cmd2  ld a,(ix+10)                  ;add to volume command
          add a,(iy+1)
          jr nc,scr_vhok
          ld a,$ff
scr_vhok  ld (ix+10),a                  ;update volume var  
          cp $ff
          jr nz,scr_vnmx
          ld a,$40
          jr scr_setvp
scr_vnmx  srl a
          srl a
scr_setvp inc c                         
          out (c),a                     ;update volume port
          dec c
          ld de,2
          call scr_pc_plus
          ret


;--------------------------------------------------------------------------------


scr_cmd3  
          ld a,(ix+10)                  ;sub from volume command
          sub (iy+1)
          jr nc,scr_vlok
          xor a
scr_vlok  ld (ix+10),a                  ;update volume var  
          srl a
          srl a
          inc c                         
          out (c),a                     ;update volume port
          dec c
          ld de,2
          call scr_pc_plus
          ret


;--------------------------------------------------------------------------------


scr_cmd4  ld e,(iy+1)                   ;set period command
          ld d,(iy+2)
          ld (ix+4),e                   ;update period reg
          ld (ix+5),d
          ld b,d
          out (c),e                     ;update period port
          ld de,3
          call scr_pc_plus
          ret       
          

;--------------------------------------------------------------------------------
          
          
scr_cmd5  ld e,(iy+1)                   ;add to period command
          ld d,(iy+2)                   ;de = parameter word
          ld l,(ix+4)                   
          ld h,(ix+5)
          add hl,de                     ;new period value   
          ld e,(ix+22)                  
          ld d,(ix+23)                  ;de = max period
          push hl
          xor a
          sbc hl,de
          pop hl
          jr c,scr_phok

          ld a,(ix+29)                  ;if cycle option [2:1 of misc] = 0
          rrca                          ;then just fix at max period
          and 3
          ld b,a
          jr z,scr_gmin
          
          ld e,(ix+20)
          ld d,(ix+21)                  ;de = min period
          ld a,b                        ;if cycle option is 1 wrap to min period, no offset
          cp 1
          jr z,scr_gmin
          push de
          ld e,(ix+22)                  
          ld d,(ix+23)                  ;de = max period
          xor a
          sbc hl,de
          pop de
          add hl,de                     ;else wrap around to min period with offset
          ex de,hl
          
scr_gmin  ex de,hl
scr_phok  ld (ix+4),l
          ld (ix+5),h
          ld b,h              
          out (c),l                     ;update period port
          ld de,3
          call scr_pc_plus
          ret       


;--------------------------------------------------------------------------------


scr_cmd6  ld e,(iy+1)                   ;sub from period command
          ld d,(iy+2)                   ;de = parameter word
          ld l,(ix+4)                   
          ld h,(ix+5)
          xor a
          sbc hl,de                     ;hl = new period value        
          ld e,(ix+20)                  ;de = min period
          ld d,(ix+21)                  
          jr c,src_pgbz
          push hl
          xor a
          sbc hl,de                     ;check against min period
          pop hl
          jr nc,scr_plok                ;gone below min period value?
          
src_pgbz  ld a,(ix+29)                  ;yes.. if cycle option [2:1 of misc] = 0
          rrca                          ;then just fix at min period
          and 3
          ld b,a
          jr z,scr_smp

          ld e,(ix+22)                  
          ld d,(ix+23)                  
          ld a,b
          cp 1                          ;if option = 1 wrap to max period no offset
          jr z,scr_smp

          push de                       ;otherwise wrap to max period with offset
          ld e,(ix+20)                  
          ld d,(ix+21)                  ;de = min period
          xor a
          sbc hl,de
          pop de                        ;de = max period
          add hl,de
          ex de,hl
          
scr_smp   ex de,hl
scr_plok  ld (ix+4),l
          ld (ix+5),h
          ld b,h              
          out (c),l                     ;update period port
          ld de,3
          call scr_pc_plus
          ret       


;--------------------------------------------------------------------------------


scr_cmd7                      
          ld e,(iy+1)                   ;set max period
          ld d,(iy+2)                   ;de = parameter word
          ld (ix+22),e                  
          ld (ix+23),d
          ld de,3
          call scr_pc_plus
          ret       

;--------------------------------------------------------------------------------


scr_cmd8                      
          ld e,(iy+1)                   ;set min period
          ld d,(iy+2)                   ;de = parameter word
          ld (ix+20),e                  
          ld (ix+21),d
          ld de,3
          call scr_pc_plus
          ret       


;--------------------------------------------------------------------------------


scr_cmd9  ld e,(iy+1)                   ;random period
          ld d,(iy+2)                   ;de = parameter word (mask)
          ld a,(ix+24)
          and e
          ld l,a
          ld a,(ix+25)
          and d
          ld h,a
          ld e,(ix+20)
          ld d,(ix+21)                  ;add min period
          add hl,de
          push hl   
          ld e,(ix+22)                  
          ld d,(ix+23)                  ;check against max period
          xor a
          sbc hl,de
          pop hl
          jr c,scr_phok2
          ex de,hl
scr_phok2 ld (ix+4),l                   ;update period reg
          ld (ix+5),h
          ld b,h              
          out (c),l                     ;update period port
          call scr_randomize
          ld de,3
          call scr_pc_plus
          ret       

          
;--------------------------------------------------------------------------------


scr_cmd10 ld a,(iy+1)                   ;cmd 10 - wait n frames
          ld (ix+15),a                  ;set wait number of frames    
          or a
          jr z,scr_wnv                  ;if n = 0, do nothing
          res 0,(ix+29)                 ;wait clears the anti-lock flag
scr_wnv   ld de,2                       
          call scr_pc_plus
          ret       


;--------------------------------------------------------------------------------
          

scr_cmd11 ld a,(iy+1)
          or a                          ;loop 0 is same as loop 1
          jr z,scr_sl
          dec a
scr_sl    ld (ix+26),a                  ;set loop countdown 
          ld l,(ix+16)                  
          ld h,(ix+17)
          inc hl    
          inc hl
          ld (ix+18),l                  ;set loop position 
          ld (ix+19),h
          ld de,2
          call scr_pc_plus
          ret       


;--------------------------------------------------------------------------------
                                        

scr_cmd12 ld a,(ix+26)                  ;do loop command (ie: jump back)
          or a
          jr nz,scr_dolp                ;any loops to do?
          ld de,1
          call scr_pc_plus
          ret
scr_dolp  dec (ix+26)
          ld l,(ix+18)                  ;get loop position 
          ld h,(ix+19)        
          ld (ix+16),l                  ;reset PC
          ld (ix+17),h
          ret


;--------------------------------------------------------------------------------


scr_cmd13 ld l,(ix+16)                  ;set repeat position 
          ld h,(ix+17)
          inc hl
          ld (ix+27),l                  
          ld (ix+28),h
          set 0,(ix+29)                 ;Repeat is dangerous: sets the antilock flag
          ld de,1
          call scr_pc_plus
          ret       

                    
;--------------------------------------------------------------------------------

          
scr_cmd14 ld e,(iy+1)                   ;set random seed
          ld d,(iy+2)                   ;de = parameter word
          ld (ix+24),e
          ld (ix+25),d
          ld de,3
          call scr_pc_plus
          ret       

;--------------------------------------------------------------------------------


scr_cmd15 ld a,(iy+1)                   ;init a new clip..
          and $1f                       ;A = wav clip to init
          jr z,scr_badw

          ld e,a
          ld b,1                        ;need to have correct channel mask bit set in B
          ld a,c                        ;for fx_setup_wave routine
          srl a
          srl a
          and 3
          jr z,scr_sbit
scr_gbit  sla b
          dec a
          jr nz,scr_gbit
scr_sbit  ld a,e
          push bc
          call fx_setup_wave
          pop bc
scr_badw  ld de,2
          call scr_pc_plus
          ret

;--------------------------------------------------------------------------------

scr_cmd16 ld a,(iy+1)                   ;period cycle control
          sla a
          and 6
          ld e,a
          ld a,(ix+29)
          and $f9
          or e
          ld (ix+29),a
          ld de,2
          call scr_pc_plus
          ret

;--------------------------------------------------------------------------------         

scr_pc_plus
          
          ld l,(ix+16)                  ;advances script PC
          ld h,(ix+17)
          add hl,de
          ld (ix+16),l
          ld (ix+17),h
          ret

;---------------------------------------------------------------------------------


scr_randomize

          ld e,(ix+24)
          ld d,(ix+25)                  
          ld a,d
          ld h,e
          ld l,253
          or a
          sbc hl,de
          sbc a,0
          sbc hl,de
          ld d,0
          sbc a,d
          ld e,a
          sbc hl,de
          jr nc,rand
          inc hl
rand      ld (ix+24),l
          ld (ix+25),h                  
          ret


;=================================================================================

fx_trigger_channels


          call fx_wait_dma                        ; wait for the start of a scan line (post audio DMA)

;         ld hl,$0ff                              ; for testing only            
;         ld (palette),hl                         ; for testing only

          ld a,(fx_channel_mask)                  ; temp. disable channels that need retriggering
          ld l,a
          cpl                                     ; (no effect until start of next scanline)
          ld e,a
          in a,(sys_audio_enable)                  
          and e                                   
          out (sys_audio_enable),a                                              

          ld c,$10                                ; Do loc/len/per/vol for channels that have been
          bit 0,l                                 ; triggered
          jr z,fx_ndc0
          ld de,(fx_init_chan_data0)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data0+2)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data0+4)
          ld b,d
          out (c),e
          inc c
          ld a,(fx_init_chan_data0+10)
          srl a
          srl a
          out (c),a
          
fx_ndc0   ld c,$14
          bit 1,l   
          jr z,fx_ndc1
          ld de,(fx_init_chan_data1)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data1+2)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data1+4)
          ld b,d
          out (c),e
          inc c
          ld a,(fx_init_chan_data1+10)
          srl a
          srl a
          out (c),a
          
fx_ndc1   ld c,$18
          bit 2,l   
          jr z,fx_ndc2
          ld de,(fx_init_chan_data2)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data2+2)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data2+4)
          ld b,d
          out (c),e
          inc c
          ld a,(fx_init_chan_data2+10)
          srl a
          srl a
          out (c),a
                    
fx_ndc2   ld c,$1c
          bit 3,l   
          jr z,fx_ndc3
          ld de,(fx_init_chan_data3)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data3+2)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data3+4)
          ld b,d
          out (c),e
          inc c
          ld a,(fx_init_chan_data3+10)
          srl a
          srl a
          out (c),a
fx_ndc3


          call fx_wait_dma                        ; wait for the start of a scan line (post audio DMA)

;         ld hl,$f0f                              ; for testing only            
;         ld (palette),hl                         ; for testing only

          ld a,(fx_channel_mask)                  ; re-enable channels
          ld l,a
          in a,(sys_audio_enable)                  
          or l                                    
          out (sys_audio_enable),a                                              

          ld c,$10                                ;do the loop loc/lens of triggered channels
          bit 0,l
          jr z,fx_ndc0l
          ld de,(fx_init_chan_data0+6)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data0+8)
          ld b,d
          out (c),e

fx_ndc0l  ld c,$14
          bit 1,l
          jr z,fx_ndc1l
          ld de,(fx_init_chan_data1+6)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data1+8)
          ld b,d
          out (c),e

fx_ndc1l  ld c,$18
          bit 2,l
          jr z,fx_ndc2l
          ld de,(fx_init_chan_data2+6)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data2+8)
          ld b,d
          out (c),e

fx_ndc2l  ld c,$1c
          bit 3,l
          jr z,fx_ndc3l
          ld de,(fx_init_chan_data3+6)
          ld b,d
          out (c),e
          inc c
          ld de,(fx_init_chan_data3+8)
          ld b,d
          out (c),e
fx_ndc3l  
          xor a
          ld (fx_channel_mask),a

;         ld hl,$000                              ; for testing only            
;         ld (palette),hl                         ; for testing only

          ret


;---------------------------------------------------------------------------------------------
          
fx_wait_dma

          in a,(sys_vreg_read)                    ;wait for LSB for scanline count to change
          and $40
          ld b,a
fx_dmalp  in a,(sys_vreg_read)
          and $40
          cp b
          jr z,fx_dmalp
          ret       
          
;----------------------------------------------------------------------------------------------

silence_fx

          in a,(sys_audio_enable)                  
          and $f0                                 
          out (sys_audio_enable),a                                              
          ld hl,fx_init_chan_data0
          ld b,30*4
          xor a
fx_clchdl ld (hl),a
          inc hl
          djnz fx_clchdl
          ret

;-------------------------------------------------------------------------------------------------

script_cmd_locs

          dw scr_cmd0, scr_cmd1, scr_cmd2, scr_cmd3, scr_cmd4, scr_cmd5, scr_cmd6, scr_cmd7
          dw scr_cmd8, scr_cmd9, scr_cmd10, scr_cmd11, scr_cmd12, scr_cmd13, scr_cmd14, scr_cmd15
          dw scr_cmd16
          
;-------------------------------------------------------------------------------------------------
; Variables:
;-------------------------------------------------------------------------------------------------

fx_base             dw 0
fx_sample_base      dw 0
fx_channel_mask     db 0

fx_script_base      dw 0

;----------------------------------------------------------------------------------------------

fx_init_chan_data0   ds 30,0
fx_init_chan_data1   ds 30,0
fx_init_chan_data2   ds 30,0
fx_init_chan_data3   ds 30,0


;For each channel
;----------------
;0 - loc
;2 - len
;4 - period
;6 - loop loc
;8 - loop len
;10 - volume
;11 - script
;12 - wave type
;13 - priority
;14 - priority active time
;15 - frame wait countdown
;16 - script position
;18 - loop position
;20 - min period
;22 - max period
;24 - random seed
;26 - loop countdown 
;27 - repeat position
;29 - misc bits:
;     bit  0 = anti-lock flag (protection for any Repeats without Waits)
;     bits 1:2 = period wrap control, 0 = fix at min/max, 1 = loop no offset, 2 = loop with offset 
;---------------------------------------------------------------------------------------------

