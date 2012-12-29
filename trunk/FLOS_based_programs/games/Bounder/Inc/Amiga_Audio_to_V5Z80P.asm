;----------------------------------------------------------------------------------------
; Amiga hardware values to V5Z80P conversion / hardware register updates
; For Z80 Protracker Player (requires "Z80_protracker_player.asm")
;----------------------------------------------------------------------------------------


update_sound_hardware


          ld c,audchan0_per                       ; set the 4 channels' period and volume
          ld iy,channel_data                      ; registers. These are always updated 
          call update_pervol                      ; every frame and require no special timing.
          ld a,(chan_1_enable)
          or a
          jr z,skpch1a
          ld c,audchan1_per
          ld iy,channel_data+vars_per_channel
          call update_pervol
skpch1a   ld c,audchan2_per                       
          ld iy,channel_data+(vars_per_channel*2)
          call update_pervol
;         ld c,audchan3_per             		;modded for bounder's sound fx
;         ld iy,channel_data+(vars_per_channel*3)
;         call update_pervol
          
	  
	  call wait_dma
	  
          
          ld e,%00000001                          ; now set the 4 channels' sample location
          ld c,audchan0_loc                       ; and length registers, * if triggered *
          ld iy,channel_data  
          bit 0,(iy+control_bits)
          call nz,update_start_loclen
          ld a,(chan_1_enable)
          or a
          jr z,skpch1b
          ld e,%00000010                          
          ld c,audchan1_loc                       
          ld iy,channel_data+vars_per_channel     
          bit 0,(iy+control_bits)
          call nz,update_start_loclen
skpch1b   ld e,%00000100                          
          ld c,audchan2_loc                       
          ld iy,channel_data+(vars_per_channel*2)
          bit 0,(iy+control_bits)
          call nz,update_start_loclen
;         ld e,%00001000                           
;         ld c,audchan3_loc                        
;         ld iy,channel_data+(vars_per_channel*3)
;         bit 0,(iy+control_bits)
;         call nz,update_start_loclen			;modded for bounder's sound fx

          
	  call wait_dma

          
          ld e,%00000001                          ; finally set the 4 channels' loop around values
          ld c,audchan0_loc                       ; for location and length registers, * if triggered *
          ld iy,channel_data  
          call update_loop_loclen
          ld a,(chan_1_enable)
          or a
          jr z,skpch1c
          ld e,%00000010                          
          ld c,audchan1_loc                       
          ld iy,channel_data+vars_per_channel     
          call update_loop_loclen
skpch1c   ld e,%00000100                          
          ld c,audchan2_loc                       
          ld iy,channel_data+(vars_per_channel*2)
          call update_loop_loclen
;         ld e,%00001000                           
;         ld c,audchan3_loc                        
;         ld iy,channel_data+(vars_per_channel*3)	;modded for bounder's sound fx
;         call update_loop_loclen
          ret



update_start_loclen

          ld a,e
          cpl
          ld b,a
          ld a,(HW_enabled_channels)
          and b
          ld (HW_enabled_channels),a
          out (sys_audio_enable),a                ; disable channel during loc/len update
          
          ld a,(iy+samp_loc_lo)                   ; lsb of WORD location
          ld b,(iy+samp_loc_hi)                   ; msb of WORD location
          out (c),a                               ; write WORD location to HW reg
          inc c                                   ; move to length reg port
          ld a,(iy+samp_len_lo)                   ; lsb of length in words
          ld b,(iy+samp_len_hi)                   ; msb of length in words
          out (c),a                               ; write WORD length to HW reg            
          ret


                                                  
update_loop_loclen

          res 0,(iy+control_bits)                 ; clear sample trigger bit
          ld a,(HW_enabled_channels)
          or e
          ld (HW_enabled_channels),a
          out (sys_audio_enable),a                ; enable channel to begin playing sound sample    
          
          ld a,(iy+samp_loop_loc_lo)              ; lsb of loop location (in words)
          ld b,(iy+samp_loop_loc_hi)              ; msb of loop location (in words)
          out (c),a                               ; write loop location (word address) to HW reg
          inc c                                   ; move to length register port
          ld a,(iy+samp_loop_len_lo)              ; lsb of loop length in words
          ld b,(iy+samp_loop_len_hi)              ; msb of loop length in words
          out (c),a                               ; write loop WORD length to HW reg
          ret
          
          
          
update_pervol

          ld l,(iy+period_lo)                     ; lsb of Amiga period
          ld h,(iy+period_hi)                     ; msb of Amiga period
          add hl,hl
          ld de,amiga_period_conv_table-(108*2)
          add hl,de
          ld a,(hl)                               ; z80 project period value (lo)
          inc hl                                  ;
          ld b,(hl)                               ; z80 project period value (hi)
          out (c),a                               ; write converted period to sample rate port
          
          inc c                                   ; move to volume register port
          ld b,(iy+volume)                        ; get channel's volume value
          ld a,(chan_1_enable)
          or a                                    ; half vol in-game
          jr nz,normvol
          srl b
normvol   ld a,b
          out (c),a                               ; write volume to HW register
          ret
          

;--------------------------------------------------------------------------------------------

chan_1_enable                 db 0

HW_enabled_channels           db 0

amiga_period_conv_table       incbin "FLOS_based_programs\games\Bounder\data\period_conv_table.bin" ; covers values 108 to 907

;========================================================================================
