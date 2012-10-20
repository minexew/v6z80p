
;==================================================================================================
; Single channel, scripted sound FX player - By Phil Ruston '08
; V1.01
;==================================================================================================

; call "new_fx" with fx number in A to initialize a new effect, first fx number is $01
; call "play_fx" each frame to play the effects

; each effect has the following structure:
;
; byte $00       - Priority level (0-255)
;      $01       - Time (in frames) that this effect is active (for priority system) (0-255)
;      $02       - Volume of sample (0-255)
;      $03-$04   - Location of sample (word address in 128KB Sample RAM)
;      $05-$06   - Length of sample (in words)
;      $07-$08   - Period of sample
;      $09-$0a   - Loop location of sample (word address in 128KB Sample RAM)
;      $0b-$0c   - Loop length of sample (in words)
;      $0d-$xxxx - First command byte (FX scripts can be as long as required)
;
; Command bytes and parameters:
;
; $00 - Do nothing (except skip this byte)
; $01 - Start a new sample, Parameters: (byte) Vol, (words) Loc, Len, Per, Loop_loc, Loop_len 
; $02 - Add to period, Parameter: byte value to add $00-$FF
; $03 - Sub from period, Parameter: byte value to sub 00-$FF
; $04 - Add to volume, Parameter: byte value to add $00-$FF
; $05 - Sub from volume, Parameter: byte value to sub $00-$FF
; $06 - Set new period, Parameter: New period word $0000-$FFFF
; $07 - Set new volume, Parameter new volume byte $00-$FF
; $08 - Loop point, Parameter: byte - Number of loops $00-$FF, $00=infinite loops
; $09 - Wait n frames, parameter: loops $00-$FF (byte)
; $0a - Loop back to loop point (no parameters)
; $0b - Set minimum period for modulation (cmd $02/$03). Parameter: Value $0000-$FFFF (default $200)
; $0c - Set maximum period for modulation (cmd $02/$03). Parameter Value $0000-$FFFF (default $1000)
; $0d - Set random period (no args)
; $0e - Reset random seed (no args)
; $0f - Set repeat point (no args)
; $10 - Goto repeat point (no args)
; $FF - End of fx script (no parameters)

;-------------------------------------------------------------------------------------------------


new_fx    push hl
          push de
          push bc
          ld l,a                                  ;call to start a new FX, set A = fx number
          ld e,a                                  ;new fx will be started if it has higher/equal
          ld h,0                                  ;prioity to that being played
          dec l
          add hl,hl
          ld bc,fx_list
          add hl,bc
          ld c,(hl)
          inc hl
          ld b,(hl)
          ld a,(bc)
          ld l,a
          ld a,(fx_current_priority)
          cp l
          jr c,go_fx
          jr z,go_fx
          jr no_fx

go_fx     ld a,l
          ld (fx_current_priority),a
          ld a,e
          ld (fx_change),a
          inc bc
          ld a,(bc)
          ld (fx_current_time),a
          inc bc
          ld (fx_current_addr),bc
no_fx     pop bc
          pop de
          pop hl
          ret


;---------------------------------------------------------------------------------------------------


play_fx   ld a,(fx_change)                        ; new fx waiting?
          or a
          jr z,fx_continue
          ld (fx_current_fx),a
          xor a
          ld (fx_change),a
          ld bc,(fx_current_addr)                 ; start new fx
          ld hl,$1000
          ld (fx_max_per),hl
          ld hl,$200
          ld (fx_min_per),hl
          jp fx_ns2
          
          
fx_continue

          ld hl,fx_current_time                   ; dec active time count of current fx
          ld a,(hl)
          or a
          jr z,fx_ctzero
          dec (hl)                                ; if if reaches zero, set priority to zero 
          jr nz,fx_ctnz
fx_ctzero xor a
          ld (fx_current_priority),a



fx_ctnz   ld hl,fx_wait_count                     ; no activity during wait frames
          ld a,(hl)
          or a
          jr z,fx_scan
          dec (hl)
          ret nz


fx_scan   ld a,(fx_current_fx)
          or a
          ret z
fx_fcmd   ld bc,(fx_current_addr)                 ; read fx script
          ld a,(bc)                               ; get command number
          cp $ff
          ret z
          or a
          jr nz,fx_gotcmd
fx_notcmd inc bc
          ld (fx_current_addr),bc
          jr fx_fcmd
          
fx_gotcmd cp $01
          jp z,fx_new_samp
          cp $02
          jp z,fx_add_period
          cp $03
          jp z,fx_sub_period
          cp $04
          jp z,fx_add_vol
          cp $05
          jp z,fx_sub_vol
          cp $06
          jp z,fx_set_abs_period
          cp $07
          jp z,fx_set_abs_vol
          cp $08
          jp z,fx_set_loop
          cp $09
          jp z,fx_wait_frames
          cp $0a
          jp z,fx_loopback
          cp $0b
          jp z,fx_set_min_period
          cp $0c
          jp z,fx_set_max_period
          cp $0d
          jp z,fx_set_random_period
          cp $0e
          jp z,fx_reset_seed
          cp $0f
          jp z,fx_set_repeat_point
          cp $10
          jp z,fx_goto_repeat_point
          
          jp fx_notcmd


fx_new_samp

          inc bc
fx_ns2    ld a,(bc)                               ;start volume
          ld (fx_current_vol),a
          inc bc
          call fx_set_hw_loclen
          inc bc
          inc bc
          inc bc
          inc bc
          ld a,(bc)                               ;start period lsb
          inc bc
          ld (fx_current_per),a                   
          ld a,(bc)                               ;start period msb
          inc bc
          ld (fx_current_per+1),a
          call fx_set_hw_period
          call fx_set_hw_volume
          inc bc
          inc bc
          inc bc
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan
                    

          
fx_add_period

          inc bc
          ld a,(bc)
          ld e,a
          ld d,0
          ld hl,(fx_current_per)
          add hl,de
          ld (fx_current_per),hl
          ld de,(fx_max_per)
          xor a
          sbc hl,de
          jr c,fx_aperok
          ld de,(fx_min_per)
          add hl,de
          ld (fx_current_per),hl
fx_aperok call fx_set_hw_period
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan
          
          
fx_sub_period

          inc bc
          ld a,(bc)
          ld e,a
          ld d,0
          ld hl,(fx_current_per)
          xor a
          sbc hl,de
          ld (fx_current_per),hl
          ld de,(fx_min_per)
          xor a
          sbc hl,de
          jr nc,fx_persok
          ld de,(fx_max_per)
          add hl,de
          ld (fx_current_per),hl
fx_persok call fx_set_hw_period
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan
          
          
fx_add_vol

          inc bc
          ld a,(bc)
          ld e,a
          ld a,(fx_current_vol)
          add a,e
          jr nc,fx_volaok
          ld a,$ff  
fx_volaok ld (fx_current_vol),a
          call fx_set_hw_volume
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan


fx_sub_vol

          inc bc
          ld a,(bc)
          ld e,a
          ld a,(fx_current_vol)
          sub e
          jr nc,fx_volsok
          xor a
fx_volsok ld (fx_current_vol),a
          call fx_set_hw_volume
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan


fx_set_abs_period

          inc bc
          ld a,(bc)
          ld (fx_current_per),a
          inc bc
          ld a,(bc)
          ld (fx_current_per+1),a
          call fx_set_hw_period
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan


fx_set_abs_vol

          inc bc
          ld a,(bc)
          ld (fx_current_vol),a
          call fx_set_hw_volume
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan


fx_set_loop

          inc bc
          ld a,(bc)
          ld (fx_loops),a
          inc bc
          ld (fx_current_addr),bc
          ld (fx_loop_addr),bc
          jp fx_scan


fx_wait_frames

          inc bc
          ld a,(bc)
          ld (fx_wait_count),a
          inc bc
          ld (fx_current_addr),bc
          ret
          

fx_loopback

          ld a,(fx_loops)
          or a
          jr z,fx_infl
fx_eol    dec a
          ld (fx_loops),a
          jr nz,fx_infl
          inc bc                                  ;get out of loop
          ld (fx_current_addr),bc
          jp fx_scan

fx_infl   ld bc,(fx_loop_addr)
          ld (fx_current_addr),bc
          jp fx_scan



fx_set_min_period

          inc bc
          ld a,(bc)
          ld (fx_min_per),a
          inc bc
          ld a,(bc)
          ld (fx_min_per+1),a
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan


fx_set_max_period


          inc bc
          ld a,(bc)
          ld (fx_max_per),a
          inc bc
          ld a,(bc)
          ld (fx_max_per+1),a
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan


fx_set_random_period

          call fx_rand16
          ld a,h
          and $07
          ld h,a
          ld de,$220
          add hl,de
          ld (fx_current_per),hl
          call fx_set_hw_period
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan


fx_reset_seed

          ld hl,$4981
          ld (fx_seed),hl
          inc bc
          ld (fx_current_addr),bc
          jp fx_scan
          
          
fx_set_repeat_point

          inc bc
          ld (fx_current_addr),bc
          ld (fx_repeat_point),bc
          jp fx_scan


fx_goto_repeat_point

          ld bc,(fx_repeat_point)
          ld (fx_current_addr),bc
          jp fx_scan



fx_rand16 ld        de,(fx_seed)                  
          ld        a,d
          ld        h,e
          ld        l,253
          or        a
          sbc       hl,de
          sbc       a,0
          sbc       hl,de
          ld        d,0
          sbc       a,d
          ld        e,a
          sbc       hl,de
          jr        nc,fx_rand
          inc       hl
fx_rand   ld        (fx_seed),hl                  
          ret
          
          
;-------- V5Z80P Hardware level routines ---------------------------------------------------------------

; This is currently set to play FX only on the forth channel (channel_3).
; If music is being played, the forth channel must be disabled in
; the Protracker player as this routine does not (yet) "cut in" to
; play the sample. If other channels are being used for FX, their
; active bits music be OR'd with the audio enable writes here so
; that they are not disturbed.


fx_set_hw_loclen

          push bc
          push bc
          pop ix
          
          ld hl,vreg_read                         ; wait for display window part of scan line (sound dma done)
xwait1    bit 1,(hl)
          jr nz,xwait1
xwait2    bit 1,(hl)                                        
          jr z,xwait2
          
          ld a,%00000000                          ; NOTE!! Include other channel bits other channels in use
          out (sys_audio_enable),a                ; Disable channel during loc/len update
          
          ld c,audchan3_loc
          ld a,(ix)                               ; lsb of WORD location
          ld b,(ix+1)                             ; msb of WORD location
          out (c),a                               ; write WORD location to HW reg
          inc c                                   ; move to length reg port
          ld a,(ix+2)                             ; lsb of length in words
          ld b,(ix+3)                             ; msb of length in words
          out (c),a                               ; write WORD length to HW reg            


          ld hl,vreg_read                          ; wait one scan line (sound dma done)
xwait1b   bit 1,(hl)
          jr nz,xwait1b
xwait2b   bit 1,(hl)                                        
          jr z,xwait2b

          ld a,%00001000                          ; NOTE!! Include other channel bits other channels in use
          out (sys_audio_enable),a                ; Restart audio DMA

          ld c,audchan3_loc
          ld a,(ix+6)                             ; lsb of WORD loop location
          ld b,(ix+7)                             ; msb of WORD loop location
          out (c),a                               ; write WORD location to HW reg
          inc c                                   ; move to length reg port
          ld a,(ix+8)                             ; lsb of loop length in words
          ld b,(ix+9)                             ; msb of loop length in words
          out (c),a                               ; write WORD length to HW reg            

          pop bc
          ret
          

          
fx_set_hw_period

          push bc                                 
          ld c,audchan3_per
          ld a,(fx_current_per+1)                 ; z80 project period value (hi)
          ld b,a
          ld a,(fx_current_per)                   ; z80 project period value (lo)
          out (c),a                               ; write converted period to sample rate port
          pop bc
          ret
          

          
fx_set_hw_volume

          ld a,(fx_current_vol)                    
          cp $ff                                  
          jr nz,fx_vnm                            ;If volume is $ff, use full HW volume value $40
          ld a,$40
          jr fx_fhwv          
fx_vnm    srl a                                   ;scale volume to HW range
          srl a
fx_fhwv   out (audchan3_vol),a
          ret
                    
          
;-----------------------------------------------------------------------------------------------------

fx_change           db 0
fx_current_fx       db 0
fx_current_addr     dw 0
fx_current_priority db 0
fx_current_time     db 0
fx_current_vol      db 0
fx_current_per      dw 0
fx_wait_count       db 0
fx_loop_addr        dw 0
fx_loops            db 0
fx_min_per          dw $0200
fx_max_per          dw $1000
fx_repeat_point     dw 0
fx_seed             dw $4981

;------------------------------------------------------------------------------------------------------

