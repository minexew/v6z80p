
;---Standard header for OSCA and FLOS -------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"

;--------------------------------------------------------------------------------------
;
; Game v1.03  - Rocket sound fx fixed 31/12/2010
;
; Game v1.02  - Updated 12/05/2010:
;
; Added keyboard controls Q,A,O,P
; ESC to quit on title screen instead of space bar                    
; High score saved on exit
; Returns to FLOS on exit instead of rebooting
;
;--------------------------------------------------------------------------------------

number_of_levels    equ 10


map_width           equ 16
scroll_width        equ 16
wintop_rasterline   equ $18
winleft_position    equ $9f
load_buffer         equ $c000
load_buffer_bank    equ 2
level_data          equ $8000           ;in bank 1


;--------------------------------------------------------------------------------------

          org $5000
          
          jp bounder_start

;--------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------
; Keyboard IRQ routine - highly unoptimized!
; Make sure this routine doesn't get located in the paged memory area (IE: $8000-$FFFF)
;----------------------------------------------------------------------------------------

up_scancode         equ $15
down_scancode       equ $1c
left_scancode       equ $44
right_scancode      equ $4d
fire_scancode       equ $14

; key_directions bits: 0 = up, 1 = down, 2 = left, 3 = right, 4 = fire, 6 = most recent horiz, 7 = most recent vert


my_irq_handler

          push af                       ; Maskable IRQ jumps here
          in a,(sys_irq_ps2_flags)      ; Read irq status flags
          bit 0,a                       ; keyboard irq set?
          call nz,keyboard_irq_code     ; call keyboard irq routine if so
          pop af                        
          ei                            ; re-enable interrupts
          reti                          ; return to main code
          

keyboard_irq_code

          push af                       ; treats keyboard as joystick, IE: direction persist until key released
          push hl                       
          
          ld hl,key_directions
          in a,(sys_keyboard_data)      ; get the keycode
          cp $f0
          jr nz,not_rel                 ; is it a "key released" prefhl byte
          ld a,1
          ld (key_release),a            ; if so, set a flag and take no further action
          jp key_done
          
not_rel   cp up_scancode                ; up scancode received?
          jr nz,knotup
          ld a,(key_release)            ; was $f0 received previously (key released)?
          or a
          jr z,press_u
          xor a                         ; this is a key release
          ld (key_release),a
          res 0,(hl)
          jp key_done
press_u   set 0,(hl)                    ; set up on
          res 7,(hl)                    ; most recently up
          jp key_done
          
knotup    cp down_scancode
          jr nz,knotdown
          ld a,(key_release)            
          or a
          jr z,press_d
          xor a
          ld (key_release),a
          res 1,(hl)
          jp key_done
press_d   set 1,(hl)
          set 7,(hl)                    ; most recently down
          jp key_done
          
knotdown  cp left_scancode              ; up scancode received?
          jr nz,knotleft
          ld a,(key_release)            ; was $f0 received previously (key released)?
          or a
          jr z,press_l
          xor a                         ; this is a key release
          ld (key_release),a
          res 2,(hl)
          jp key_done
press_l   set 2,(hl)                    ; set left on
          res 6,(hl)                    ; most recently left
          jp key_done
          
knotleft  cp right_scancode
          jr nz,knotright
          ld a,(key_release)            
          or a
          jr z,press_r
          xor a
          ld (key_release),a
          res 3,(hl)
          jp key_done
press_r   set 3,(hl)                    ;set right on
          set 6,(hl)                    ;most recently right
          jp key_done


knotright cp fire_scancode
          jr nz,knotfire
          ld a,(key_release)            
          or a
          jr z,press_fir
          xor a
          ld (key_release),a
          res 4,(hl)
          jr key_done
press_fir set 4,(hl)
          jr key_done


knotfire  cp $76                        ;ESC key code
          jr nz,key_notesc
          ld a,(key_release)            
          or a
          jr z,press_esc
          xor a
          ld (key_release),a
          ld (esc_keytime),a
          jr key_done
press_esc ld a,1
          ld (esc_keytime),a
          jr key_done

key_notesc

          xor a
          ld (key_release),a            ; for any other key

key_done  ld a,%00000001
          out (sys_clear_irq_flags),a   ; clear keyboard interrupt flag
          pop hl
          pop af
          ret
          
          
;--------------------------------------------------------------------------------------
; Variables which must not be place in the paged RAM area
;--------------------------------------------------------------------------------------

bank_cache          db 0                

key_directions      db 0
esc_keytime         db 0
key_release         db 0
directions          db 0                ;OR sum of joystick and keyboard

;=======================================================================================

bounder_start
          
          ld hl,hs_filename             ; load hi-score if exists
          call kjt_find_file
          jr nz,no_hs
          ld ix,0
          ld iy,6
          call kjt_set_load_length      ; ensure load size is 6 bytes
          ld hl,highscore
          ld b,0
          call kjt_force_load

no_hs     ld hl,maths_sin_table         ; upload sine table to math unit
          ld de,$0600
          ld bc,$200
          ldir      

          ld a,%10000000                ;page in sprites
          out (sys_mem_select),a
          ld (vreg_vidpage),a
          ld hl,sprite_base             ;clear sprite def 0
          ld b,0
zsp0lp    ld (hl),0
          inc hl
          djnz zsp0lp
          ld a,0
          out (sys_mem_select),a
          
          ld hl,load_sprites_fn         ;sprites for "LOADING" logo stay resident
          ld de,$b5                     
          call load_sprite_data
          jp nz,load_error

          call fade_in_loading
          
          ld hl,enemy_sprites_fn        
          ld de,$c0                     
          call load_sprite_data
          jp nz,load_error

          ld hl,bg_tiles_fn             
          ld c,0                        ;destination video bank
          ld b,8                        ;number of 8KB chunks to load
          call load_tile_data
          jp nz,load_error


          ld hl,ttmod_samp_filename     ;load in music samples
          call kjt_find_file
          jp nz,load_error
          ld hl,music_samples_addr
          ld b,music_samples_bank
          call kjt_force_load
          jp nz,load_error

          ld hl,sfx_filename            ;load in sfx samples
          call kjt_find_file
          jp nz,load_error
          ld hl,sfx_samples_addr
          ld b,sfx_samples_bank
          call kjt_force_load
          jp nz,load_error

          call fade_out_loading
          
          jp title_screen
          
;=========================================================================================================
          
start_new_game

          call silence_audio
          
          call fade_in_loading                    

          ld hl,fg_tiles_fn             ;load tile definitions (bank 0) for background
          ld c,8                        
          ld b,8                        
          call load_tile_data
          jp nz,load_error

          ld hl,global_sprites_fn       ;load in non-enemy sprites
          ld de,1                       
          call load_sprite_data
          jp nz,load_error

          call fade_out_loading

;--------- Init Game Video + System settings -------------------------------------------------------------

          ld a,%10010001                
          ld (vreg_vidctrl),a           ; select dual pf/tile mode/pfA:blkset A/pfB:blkset B
          xor a
          ld (vreg_rasthi),a            ; use y window pos reg
          ld a,$3d                      
          ld (vreg_window),a            ; 240 line display (masks last line)
          ld a,%00000100                
          ld (vreg_rasthi),a            ; Switch to x window pos reg.
          ld a,$aa                      
          ld (vreg_window),a            ; Window Width = 256 pixels with wideborder
          
          call zero_palette
          ld hl,game_colours            ; fade routine to use game palette
          ld (colour_base),hl
          
          call wipe_sprites
          
          ld a,%00000000                ; disable sprites until game runs
          ld (vreg_sprctrl),a

          ld a,0
          out (sys_ps2_joy_control),a   ; select joystick 0

          di        
          ld hl,my_irq_handler          ; set IRQ vector for custom keyboard code 
          ld (irq_vector),hl    
          ld a,%00000001
          out (sys_clear_irq_flags),a   ; clear keyboard irq flag 
          ld a,%10000001                
          out (sys_irq_enable),a        ; enable keyboard interrupts
          xor a
          ld (key_directions),a
          ei


;--------- Initialize a new game  -------------------------------------------------------------------------
          
          ld de,0
          call init_status_line_sprites
          ld de,$100
          call init_status_line_sprites
          
          ld a,$74                      ; ensure animated tiles are initialized
          ld b,3    
          call copy_tile                          
          ld a,$84                      
          ld b,6    
          call copy_tile                          
          ld a,$84                      
          ld b,7    
          call copy_tile                          
          ld a,$84                      
          ld b,8    
          call copy_tile                          

          ld hl,variables_start
          ld bc,variables_end-variables_start
wipevars  ld (hl),0
          inc hl
          dec bc
          ld a,b
          or c
          jr nz,wipevars
          
          ld a,5                        
          ld (lives),a
          ld a,5
          ld (jumps_msd),a              
          ld a,0
          ld (jumps_lsd),a
          
          ld a,0                        
          ld (level),a
          
          call init_level

;-----------------------------------------------------------------------------------------------
; GAME ROUTINES CALLED AT VRT
;----------------------------------------------------------------------------------------------

wvrtstart call wait_vrt
          
          ld hl,counter
          inc (hl)

          ld a,(counter)                ;Select the "live" sprite register buffer
          rlca
          rlca
          and %00000100
          or  %00001001       
          ld (vreg_sprctrl),a

          ld a,(wiggle_applied)         ;apply x-wiggle offset to sprites
          ld b,a
          rrca
          rrca
          rrca
          rrca
          or b
          ld (vreg_xhws),a

          call replace_block
          call scroll_screen
          call update_map_pos

          call wiggle
          call anim_tiles
          call red_glow
          call game_palette_fade

          
          call play_tracker   
          call update_sound_hardware
          ld a,(game_over)
          or a
          call z,play_fx

          call ball_move
          call anim_bonus_objects
          call trigger_enemies
          call enemy_handler
          call timed_events

          call setup_sprites
          
          ld a,(end_of_level)
          cp 100
          call z,init_bonus_round
          
          ld a,(bonus_round_end)
          cp 200
          call z,next_level

          ld a,(game_over)
          cp 150
          jp z,title_screen

          jr wvrtstart
          

;====== Core Game routines ==================================================================

ball_move
          ld a,(game_start_delay)
          or a
          jr z,ctrl_on
          dec a
          ld (game_start_delay),a
          ret
          
ctrl_on   ld a,(search_scroll)
          or a
          jr z,nosearch
          dec a
          ld (search_scroll),a
          ret nz
          call reposition_ball
          jr z,repbok
          ld a,16
          ld (search_scroll),a
          ret

repbok    ld a,100
          ld (recommence_scroll),a
          ld a,150
          ld (ball_shield),a
          xor a
          ld (scroll_active),a
          ld (ball_anim_delay),a
          ld (ball_status),a
          ld (ball_bump),a
          ld (super_bounce),a
          ld a,1
          ld (ball_frame),a
          ret
          
nosearch
          ld a,(recommence_scroll)
          or a
          jr z,ball_code
          dec a
          ld (recommence_scroll),a
          or a
          jr nz,ball_code
          ld a,1
          ld (scroll_active),a

ball_code ld a,(counter)
          and 1
          jr z,go_ball
          ld a,(ball_shield)
          or a
          jr z,go_ball
          dec a
          ld (ball_shield),a

go_ball   ld a,(ball_status)            ; if check if ball is not in normal playing mode
          or a
          jp nz,ball_anim

          ld b,$f8                      ; first, check if scrolling has caused top of ball
          ld c,$f8                      ; to collide with a solid wall
          call find_tile_under_ball      
          call get_block_flags
          and 1
          jr nz,scbhit
          ld b,$07
          ld c,$f8
          call find_tile_under_ball
          call get_block_flags
          and 1
          jr z,noscbhit
scbhit    ld a,(ball_y)                 ; if so, push ball one pixel down
          inc a
          ld (ball_y),a
          cp $e8                        ; has ball been forced out screen?
          jr c,notofsc
          call set_ball_explode_big
notofsc

noscbhit

          ld a,(ball_bump)              ;has a bumper flicked the ball?
          or a
          jr z,nobbump
          ld c,a
          dec a
          ld l,a
          ld h,0
          ld de,bump_data
          add hl,de
          ld b,(hl)
          ld a,(ball_bump_dir)
          or a
          jr z,nnegbb
          ld a,b
          neg
          ld b,a
nnegbb    ld a,(ball_x)
          add a,b
          ld (ball_x),a       
          inc c
          ld a,c
          cp 32
          jr nz,bbumpok
          xor a
bbumpok   ld (ball_bump),a
          


nobbump   ld a,(ball_x)
          ld (old_ball_x),a
          ld a,(ball_y)
          ld (old_ball_y),a
          
          ld b,2                        ;default ball speed
          ld a,(ball_frame)             ;adjust speed based on animation frame
          cp 8
          jr nz,bm_ntd
          ld b,0
          jr move_it
bm_ntd    cp 7
          jr nz,mb_neobf
          ld a,(ball_anim_delay)
          cp 3
          jr nc,bm_slow
          jr move_it
mb_neobf  cp 1
          jr nz,move_it
          ld a,(ball_anim_delay)
          cp 1
          jr nc,move_it
bm_slow   ld b,1
                    
move_it   ld a,b
          ld (ball_speed),a
          call get_directions
          ld a,(directions)             
          bit 2,a                       ; move left?
          jr z,notbleft
          ld a,(ball_x)
          sub b
          cp $8
          jr nc,blfok
          ld a,$8
blfok     ld (ball_x),a
          ld b,$f8                      ; check if way is clear for ball to go left
          ld c,$f8                       
          call find_tile_under_ball      
          call get_block_flags
          and 1
          jr nz,nogoleft
          ld b,$f8
          ld c,$08
          call find_tile_under_ball
          call get_block_flags
          and 1
          jr z,notbright
nogoleft  ld a,(old_ball_x)
          ld (ball_x),a
          jr notbright

          
notbleft  ld a,(directions)             ; move right?       
          bit 3,a                       
          jr z,notbright
          ld a,(ball_x)
          add a,b
          cp $f8
          jr c,lrgok
          ld a,$f8
lrgok     ld (ball_x),a
          ld b,$07                      ; check if way is clear for ball to go right
          ld c,$f8                       
          call find_tile_under_ball                                    
          call get_block_flags
          and 1
          jr nz,nogoright
          ld b,$07
          ld c,$08
          call find_tile_under_ball
          call get_block_flags
          and 1
          jr z,notbright
nogoright ld a,(old_ball_x)
          ld (ball_x),a



notbright ld a,(ball_speed)
          ld b,a
          ld a,(directions)             ; move up ?
          bit 0,a
          jr z,notbup
          ld a,(ball_y)
          sub b
          cp $8
          jr nc,bupok
          ld a,$8
bupok     ld (ball_y),a
          ld b,$f8                      ; check if way is clear for ball to go up
          ld c,$f8                       
          call find_tile_under_ball      
          call get_block_flags
          and 1
          jr nz,nogoup
          ld b,$07
          ld c,$f8
          call find_tile_under_ball
          call get_block_flags
          and 1
          jr z,notbup
nogoup    ld a,(old_ball_y)
          ld (ball_y),a


notbup    ld a,(directions)             ; move down?
          bit 1,a
          jr z,notbdown
          ld a,(ball_y)
          add a,b
          cp $e8
          jr c,bdwok
          ld a,$e8
bdwok     ld (ball_y),a
          ld b,$f8                      ; check if way is clear for ball to go down
          ld c,$08             
          call find_tile_under_ball       
          call get_block_flags
          and 1
          jr nz,nogodown
          ld b,$07
          ld c,$08
          call find_tile_under_ball
          call get_block_flags
          and 1
          jr z,notbdown
nogodown  ld a,(old_ball_y)
          ld (ball_y),a
notbdown

dont_move_ball
                    
          
ball_anim
          xor a
          ld (rebound_frame),a

          ld a,(ball_status)            
          or a
          jp nz,ba_nnorm
          ld a,(ball_anim_delay)        ;0 = normal play mode, bounce animation
          inc a
          cp 4
          jp nz,ba_safr       
          ld a,(ball_frame)
          inc a
          cp 5                          ;ball about to drop from highest point?
          jr nz,ba_nhigh
          ld a,(super_bounce)
          or a
          jr z,ba_nrmb
          ld a,$17                      ;switch to high bounce frames
          jp ba_nfl 
ba_nrmb   ld a,5
          jp ba_nfl
ba_nhigh  cp $1e                        ;last frame of super bounce?
          jr nz,ba_nlfsb
          xor a
          ld (super_bounce),a           ;zero super bounce flag
          ld a,5                        ;switch back to normal ball frames
          jp ba_nfl

ba_nlfsb  cp 9                          ;has ball hit the floor (ie: at bounce frame) ?
          jp nz,ba_nfl        

          ld a,1
          ld (rebound_frame),a
          ld a,(sprite_tile_colis)      ;has ball hit a sprite tile?
          or a
          jr nz,ba_notsb
          
          call decrement_br_jumps
          call floor_collision_tests    ;check against background tiles
          ld a,(bonus_round_new_bonus_level)
          ld (bonus_round_bonus_level),a

          ld a,(ball_land_aggregate)
          cp 4                          ;all tiles below ball must be "fall through" type to fall
          jr nz,solidgnd
          ld a,1
          ld (ball_status),a            ;set 1 = falling
          ld a,5
          call new_fx                   ;sound effect
          xor a
          ld (scroll_active),a
          ld (recommence_scroll),a
          ld (ball_fall_exp_w),a
          ld a,9
          ld (ball_frame),a
          jr ba_setd

solidgnd  cp 2                          ;ball landed on solid ground but was it safe ground?
          jr nz,notburst
          ld a,(ball_shield)            ;dont explode if shield is on
          or a
          jr nz,ba_notsb
          call set_ball_explode_big     ;landed on dangerous tile
          jr ba_setd

notburst  cp $10                        ;landed in water?
          jr nz,notsink
          ld a,(ball_shield)            ;dont splashdown if shield is on
          or a
          jr nz,ba_notsb
          ld a,$25
          ld (ball_frame),a
          ld a,5
          ld (ball_status),a            ; set to splashdown mode
          ld a,12
          call new_fx                   ; sound effect
          xor a
          ld (scroll_active),a
          ld (recommence_scroll),a
          ld (sinking_ball_anim_delay),a
          ld a,$2a
          ld (sinking_ball_frame),a
          jr ba_setd
          

notsink   ld a,(trig_high_bounce)
          or a                          ;initialize a super bounce?
          jr z,ba_notsb
          ld a,1
          ld (super_bounce),a
          ld a,9
          call new_fx                   ;sound effect (big jump)
ba_notsb  ld a,3
          call new_fx                   ;sound effect (land normally) 
          ld a,1
ba_nfl    ld (ball_frame),a
ba_setd   xor a
ba_safr   ld (ball_anim_delay),a
          jp ball_anim_done   
          
          
ba_nnorm  cp 1                          ; is ball falling?
          jr nz,ba_nofall
          ld a,(ball_anim_delay)
          inc a
          cp 5
          jr nz,ba_fnnf
          ld a,(ball_frame)
          or a
          jr nz,ba_ffninc
          ld a,(ball_fall_exp_w)
          inc a
          ld (ball_fall_exp_w),a
          cp 4
          jr nz,ba_fdz
          ld a,2                        ;set ball mode 2 = exploding (small)
          ld (ball_status),a
          ld a,4
          call new_fx                   ;sound effect
          ld a,$10
          ld (ball_frame),a
          ld a,1
          ld (wiggle_index),a
          xor a
          jr ba_fnnf
ba_ffninc inc a
          cp $10
          jr nz,ba_stfa
          xor a
          jr ba_stfa
ba_stfa   ld (ball_frame),a
ba_fdz    xor a
ba_fnnf   ld (ball_anim_delay),a
          jp ball_anim_done

          
ba_nofall cp 2
          jr nz,ba_nsmexp               ;is ball exploding after falling (small)
          ld a,(ball_anim_delay)
          inc a
          cp 4
          jr nz,ba_smninc
          ld a,(ball_frame)
          inc a
          cp $17
          jr nz,ba_stex
          ld a,3
          ld (ball_status),a            ;set ball mode 3 = delay after exploding
          xor a
ba_stex   ld (ball_frame),a
          ld a,0
ba_smninc ld (ball_anim_delay),a
          jp ball_anim_done


ba_nsmexp cp 3                          ;is it a delay after ball explosion?
          jp nz,nobade
          ld a,(ball_anim_delay)
          inc a
          cp 50
          jp nz,ba_rgd
          ld a,(bonus_round)            ;if in bonus round, dont lose a life
          or a                          ;just end the bonus stage - with no jump bonus
          jr z,noboro
          ld a,100
          ld (bonus_round_end),a
          ld a,255
          ld (game_start_delay),a
          jp ball_anim_done
          
noboro    ld a,(cheat)
          or a
          jr nz,nllca
          ld a,(lives)                  ;lose a life
          sub 1
          jr nc,life_ok
          ld hl,$1da                    ;"game" text object
          ld de,$90
          ld a,$37
          call trigger_enemy_nonmap
          ld hl,$72                     ;"over" text object
          ld de,$a2
          ld a,$38
          call trigger_enemy_nonmap
          ld a,1
          ld (game_over),a
          ld a,$ff
          ld (ball_status),a
          
          call silence_audio
          ld hl,$c000                   ;play last bar of title tune
          ld (force_sample_base),hl     
          call init_tracker             ;initialize mod with forced sample_base
          ld a,6
          ld (songspeed),a              ;speed for title tune
          ld a,9
          ld (songpos),a                ;play last section of title tune
          ld a,10
          ld (music_module+950),a       ;force end of song position for title tune
          ld a,1
          ld (chan_1_enable),a          ;all channels in use
          jp ball_anim_done
          
life_ok   ld (lives),a
nllca     call reposition_ball
          jr z,reposok                  ; was a safe respawn site found?
          ld a,16
          ld (search_scroll),a
          ld a,1
          ld (scroll_active),a
          ld a,8
          ld (ball_status),a            ; ball in limbo
          jp ball_anim_done
          
reposok   xor a
          ld (ball_status),a
          ld (ball_bump),a
          ld (super_bounce),a
          ld a,1
          ld (ball_frame),a

          ld a,(end_of_map)
          or a
          jr nz,ba_nrscrl
          ld a,100
          ld (recommence_scroll),a
ba_nrscrl ld a,150
          ld (ball_shield),a
          xor a
          ld (scroll_active),a
ba_rgd    ld (ball_anim_delay),a
          jp ball_anim_done

nobade    cp 4                          ; large ball explosion?
          jr nz,ba_nlex
          ld a,(ball_exp_air_offset)
          add a,$1
          ld (ball_exp_air_offset),a
          ld a,(ball_exp_air_delay)
          inc a
          cp 3
          jr nz,ba_smfs
          ld a,(ball_exp_air_frame)
          or a
          jr z,ba_smend
          inc a
          cp $17
          jr nz,ba_smok
ba_smend  xor a
ba_smok   ld (ball_exp_air_frame),a
          xor a
ba_smfs   ld (ball_exp_air_delay),a
          ld a,(ball_anim_delay)
          inc a
          cp 4
          jr nz,ba_leninc
          ld a,(ball_frame)
          inc a
          cp $25
          jr nz,ba_lexok
          ld a,3
          ld (ball_status),a            ;set ball mode 3 = delay after exploding
          xor a
ba_lexok  ld (ball_frame),a
          ld a,0
ba_leninc ld (ball_anim_delay),a
          jp ball_anim_done

ba_nlex   cp 5                          ;splashdown anim?
          jr nz,ball_not_splashdown
          ld a,(ball_anim_delay)
          inc a
          cp 5
          jr nz,ba_spninc
          ld a,(ball_frame)
          inc a
          cp $2a
          jr nz,ba_splok
          ld a,3
          ld (ball_status),a            ;set ball mode 3 = delay after sinking
          xor a
ba_splok  ld (ball_frame),a
          ld a,0
ba_spninc ld (ball_anim_delay),a

          ld a,(sinking_ball_anim_delay)
          inc a
          cp 6
          jr nz,ba_sbninc
          ld a,(sinking_ball_frame)
          or a
          jr z,ba_sbninc
          inc a
          cp $2f
          jr nz,ba_sbok
          xor $2d
ba_sbok   ld (sinking_ball_frame),a
          xor a
ba_sbninc ld (sinking_ball_anim_delay),a
          jp ball_anim_done

ball_not_splashdown

          cp 6                          ;ball going down teleport?
          jp nz,ball_not_tpin
          ld a,(ball_anim_delay)
          inc a
          cp 3
          jr nz,ba_tpini
          ld a,(ball_frame)
          inc a
          cp $10
          jr nz,ba_tpiok
          ld a,(end_of_level)
          or a
          jr z,neoltp
          ld a,$ff                      ;if gone down goal set ball to $ff (do nothing)
          ld (ball_status),a
          xor a
          ld (ball_frame),a
          jp ball_anim_done
neoltp    ld a,7
          ld (ball_status),a            ;set ball mode 7 = emerge from teleport
          ld ix,enemy_list
          ld b,16
scenfexlp ld a,(ix+enemy_status)
          or a
          jr z,tpsne
          ld a,(ix+enemy_type)
          cp $04                        ;$04 = Enemy Object ID for teleport exit
          jr z,tpfexpos
          cp $45
          jr z,tpfexpos                 ;$45 = ""  "" 
tpsne     ld de,16
          add ix,de
          djnz scenfexlp
          ld a,$80                      ;if for some reason we cant find the exit object
          ld (ball_x),a                 ;centre ball on screen 
          ld a,$70
          ld (ball_y),a
          ld a,$f
          jr ba_tpiok
tpfexpos  ld l,(ix+enemy_xlsb)
          ld h,(ix+enemy_xlsb)
          ld de,winleft_position
          xor a
          sbc hl,de
          ld a,l
          add a,8
          ld (ball_x),a
          ld l,(ix+enemy_ylsb)
          ld h,(ix+enemy_ylsb)
          ld de,wintop_rasterline
          xor a
          sbc hl,de
          ld a,l
          add a,8
          ld (ball_y),a
          ld a,$f
ba_tpiok  ld (ball_frame),a
          ld a,0
ba_tpini  ld (ball_anim_delay),a
          jr ball_anim_done


ball_not_tpin

          cp $7                         ;is ball emerging from teleport?
          jr nz,ball_not_exitingtp      
          ld a,(ball_anim_delay)
          inc a
          cp 3
          jr nz,ba_tpxnd
          ld a,(ball_frame)
          dec a
          cp $8
          jr nz,ba_tpxney
          xor a
          ld (ball_status),a            ;set ball mode 0 = normal play
          ld a,1
          ld (scroll_active),a
          ld a,8
ba_tpxney ld (ball_frame),a
          xor a
ba_tpxnd  ld (ball_anim_delay),a

ball_not_exitingtp


ball_anim_done
          
          ret

;--------------------------------------------------------------------------------------------------

get_directions

          push af
          push bc
          ld a,(key_directions)                   ;read direction bits
          ld b,a
          and %0011
          cp  %0011                               ;are up and down pressed together?
          jr nz,gotkbv
          bit 7,b                                 ;if so, mask off to give the most recent key press
          jr z,priup
          ld a,b
          and %11100
          or  %00010
          ld b,a
          jr gotkbv
priup     ld a,b
          and %11100
          or  %00001
          ld b,a
gotkbv    ld a,b
          and %1100
          cp  %1100                               ;are left and right pressed together?
          jr nz,gotkbh
          bit 6,b                                 ;if so, mask off to give the most recent key press
          jr z,prileft
          ld a,b
          and %10011
          or  %01000
          ld b,a
          jr gotkbh
prileft   ld a,b
          and %10011
          or  %00100
          ld b,a

gotkbh    in a,(sys_joy_com_flags)
          or b
          ld (directions),a
          pop bc
          pop af
          ret
          

;-------------------------------------------------------------------------------------------------

          
window_offset_adjust

; set b = 8bit x pos and c = 8bit y pos
; outputs 16bit x in hl and y in de

          ld hl,wintop_rasterline       
          ld a,b
          ld b,0
          add hl,bc
          ex de,hl                      ;de = y
          ld hl,winleft_position        
          ld c,a
          add hl,bc                     ;hl = x   
          ret       
          

;---------------------------------------------------------------------------------------------

floor_collision_tests

          ld bc,0
          ld (prev_change_block_addr1),bc
          ld (prev_change_block_addr2),bc
          ld (prev_change_block_addr3),bc
          ld (prev_change_block_addr4),bc
          xor a
          ld (ball_land_aggregate),a
          ld (trig_high_bounce),a
          ld b,$fc                      
          ld c,$fc                                ; northwest landspot
          call find_tile_under_ball      
          ld (tile_under_ball),a
          ld (active_tile_mapaddr),hl
          call tile_tests
          ld (prev_change_block_addr1),hl
          
          ld b,$03                                ; northeast land spot
          ld c,$fc
          call find_tile_under_ball
          ld (tile_under_ball),a
          ld (active_tile_mapaddr),hl
          call tile_tests
          ld (prev_change_block_addr2),hl
          
          ld b,$fc                                ; southwest land spot
          ld c,$03
          call find_tile_under_ball
          ld (tile_under_ball),a
          ld (active_tile_mapaddr),hl
          call tile_tests
          ld (prev_change_block_addr3),hl
          
          ld b,$03                                ; southeast land spot
          ld c,$03
          call find_tile_under_ball
          ld (tile_under_ball),a
          ld (active_tile_mapaddr),hl
          call tile_tests
          ld (prev_change_block_addr4),hl
          ret
          

tile_tests
          
          ld a,(tile_under_ball)        
          ld b,a
          cp 2                                    ; is it an arrow?
          jr nz,ntrighb
          ld a,1
          ld (trig_high_bounce),a

ntrighb   ld a,b
          call get_block_flags
          ld c,a
          ld a,(ball_land_aggregate)
          or c
          ld (ball_land_aggregate),a
          
          ld a,b
          cp 3                                    ; is it a question mark?
          jr nz,notsurprise
          ld bc,(fg_map_base)                     ; yes!              
          ld hl,(active_tile_mapaddr)
          xor a
          sbc hl,bc
          ld bc,(trig_base)
          add hl,bc
          call go_level_data_bank
          ld e,(hl)                               ; get the trigger byte at this map spot
          call go_bank_zero
          push de
          push hl
          call init_bonus_object
          pop hl
          pop de
          ld d,4                                  ; replace tile in map with a tick if in bonus round 
          ld a,(bonus_round)                      ; if not, tick if trig is <12 or a cross if => 12
          or a
          jr nz,goodsup                 
          ld a,e                        
          cp 12
          jr c,goodsup
          ld d,5
goodsup   ld hl,(active_tile_mapaddr)
          call go_level_data_bank
          ld (hl),d                               ; replace map byte (d=replacement tile)
          call go_bank_zero
          
          ld a,(active_tile_y)                    ; replace tile in charmap with d, first in map being displayed 
          ld l,a
          ld h,0
          ld b,h
          add hl,hl                               ; multiply by 32 for internal tile map y offset
          add hl,hl
          add hl,hl
          add hl,hl
          add hl,hl
          ld a,(active_tile_x)
          ld c,a
          add hl,bc                               ; add on x offset
          ld (block_swap_offset),hl
          ld a,d
          ld (block_swap_value),a                 ; note address and block to switch - dont do until
          ret                                     ; start of next frame

notsurprise

          ret


          
replace_block

          ld a,(block_swap_value)                 ; is there a block to swap waiting?
          or a
          ret z

          ld d,a
          call kjt_page_in_video
          ld hl,(block_swap_offset)
          ld bc,video_base+$400                   ; foreground tilemaps base address
          ld a,(fg_map_buffer)
          xor 2
          add a,b
          ld b,a
          add hl,bc                               ; hl = final plot spot 
          ld (hl),d

          ld a,h                                  ; also replace tile on charmap being drawn
          xor 2
          ld h,a
          ld bc,32
          add hl,bc
          ld (hl),d
          call kjt_page_out_video
          
          xor a
          ld (block_swap_value),a
          ret
          
;---------------------------------------------------------------------------------------------
          
find_tile_under_ball

;set b = x offset from origin required
;    c = y offset ""               ""

;returns: hl = map location of tile, A = tile value (IE: byte at (HL) in bank 1)
;also sets "active_tile_x" and "active_tile_y" registers

          ld h,0
          ld a,(fg_map_pos_y_pixel)
          ld l,a
          ld a,(ball_y)
          add a,c
bmp2nc    add a,l
          jr nc,bmp1nc
          inc h
bmp1nc    ld l,a
          srl h
          rr l
          srl h
          rr l
          srl h
          rr l
          srl h
          rr l
          ld a,l
          ld (active_tile_y),a
          ld de,(fg_map_pos_y_block)
          add hl,de
          ex de,hl
          ld a,map_width                ;multiply map width by ypos block line + slice offset
          call mult_816                 ;on return hl = map line offset
          ld a,(ball_x)
          add a,b
          srl a
          srl a
          srl a
          srl a
          ld (active_tile_x),a
          ld c,a
          ld b,0
          add hl,bc                     
          ld bc,(fg_map_base)
          add hl,bc
          call go_level_data_bank
          ld b,(hl)
          call go_bank_zero
          ld a,b
          ret


;---------------------------------------------------------------------------------------------

get_block_flags

;set A to blcok to get ID bits for.
;returns ID bits in A

          ld de,block_id_table
          add a,e
          jr nc,bidfnc
          inc d
bidfnc    ld e,a
          ld a,(de)
          ret

;-----------------------------------------------------------------------------------------------

go_level_data_bank

          in a,(sys_mem_select)         ;set bank 1
          and %11111000
          or  %00000010
          out (sys_mem_select),a
          ret

go_bank_zero

          in a,(sys_mem_select)         ;set bank 0
          and %11111000
          out (sys_mem_select),a
          ret

;-----------------------------------------------------------------------------------------------

init_reposition_ball


          ld hl,(fg_map_pos_y_block)    ;reposition the ball to a safe spot 
          ld bc,15                      ;scan entire screen from bottom upwards
          add hl,bc
          ex de,hl
          ld a,map_width                ;multiply map width by ypos block line
          call mult_816
          ld de,(trig_base)
          add hl,de                     ;hl = map source address

          call go_level_data_bank
          ld c,15
ifrpy     ld b,map_width
          ld d,0
ifrpx     ld a,(hl)
          cp $fe
          jr nc,foundpos2
          inc hl
          inc d
          djnz ifrpx
          ld de,map_width
          xor a
          sbc hl,de
          sbc hl,de
          dec c
          jr nz,ifrpy
          call go_bank_zero             ;couldnt find a safe place to respawn ball
          xor a
          inc a
          ret
          

reposition_ball

          
          ld hl,(fg_map_pos_y_block)    ;reposition the ball to a safe spot
          ld bc,12                      ;IE: At an $FF/$FE trigger point
          add hl,bc
          ex de,hl
          ld a,map_width                ;multiply map width by ypos block line
          call mult_816
          ld de,(trig_base)
          add hl,de                     ;hl = map source address

          ld a,(ball_x)                 ;if ball was on right side of screen look on
          cp 128                        ;that side first
          jr nc,rs_first
          
ls_first  push hl
          ld e,0
          call scan4rsp
          pop hl
          ret z
          ld de,map_width/2
          add hl,de
          call scan4rsp
          ret

rs_first  push hl
          ld de,map_width/2
          add hl,de
          call scan4rsp
          pop hl
          ret z
          ld e,0
          call scan4rsp
          ret


scan4rsp  call go_level_data_bank
          ld c,8
frpy      ld b,map_width/2
          ld d,e
frpx      ld a,(hl)
          cp $fe
          jr nc,foundpos
          inc hl
          inc d
          djnz frpx
          push de
          ld de,map_width
          xor a
          sbc hl,de
          ld de,map_width/2
          xor a
          sbc hl,de
          pop de
          dec c
          jr nz,frpy
          call go_bank_zero             ;couldnt find a safe place to respawn ball
          xor a
          inc a
          ret

          
foundpos  inc c
          inc c
          inc c
          inc c
foundpos2 ld e,a
          call go_bank_zero
          ld a,d
          sla a
          sla a
          sla a
          sla a
          bit 0,e
          jr nz,nxosrb
          add a,8
nxosrb    ld (ball_x),a

          ld a,(fg_map_pos_y_pixel)
          ld b,a
          ld a,c
          sla a
          sla a
          sla a
          sla a
          sub b
          bit 0,e
          jr nz,nyosrb
          add a,8
nyosrb    ld (ball_y),a
          xor a
          ret
          
;---------------------------------------------------------------------------------------------
          
set_ball_explode_big

          ld a,10
          call new_fx                   ;sound effect

          ld a,4
          ld (ball_status),a            ; set ball explode (big)
          ld a,2
          ld (ball_anim_delay),a
          ld a,$1e
          ld (ball_frame),a
          ld a,$10                      ; set smoke 
          ld (ball_exp_air_frame),a
          ld hl,4
          ld (ball_exp_air_offset),hl
          ld a,0
          ld (ball_exp_air_delay),a
          xor a
          ld (scroll_active),a
          ld (recommence_scroll),a
          ret

;---------------------------------------------------------------------------------------------

init_bonus_object

; set E to bonus type $01-$0F (or $e0-$fd for bonus round tile steps)

          ld a,14             
          call new_fx                             ;sound effect

          ld a,(bonusob_select)                   ;select 1 of 4 available resources to use
          inc a
          and 3
          ld (bonusob_select),a
          sla a
          sla a
          sla a
          ld c,a
          ld b,0
          ld ix,bonusob1
          add ix,bc
          
          ld a,(bonus_round)                      ;if in bonus round, translate trigs $e0-$fd to
          or a                                    ;score bonuses 1 to 4, depending on whether
          jr z,notinbr                            ;the requisite tile has been hit
          ld a,e
          and $1f
          ld d,a
          ld l,a
          ld h,0
          add hl,hl
          ld bc,bonus_round_tile_locations
          add hl,bc
          set 7,(hl)                              ;mark this step "revealed" (set its x coord msb)
          ld a,(bonus_round_step)
          ld b,0
          cp d
          jr nz,wrongstep

fnrbtil   inc a                                   ;correct tile was hit, update to next tile
          ld (bonus_round_step),a
          ld l,a
          ld h,0
          add hl,hl
          ld de,bonus_round_tile_locations
          add hl,de
          bit 7,(hl)                              ;skip this tile step if its already been landed on
          jr nz,fnrbtil

          ld a,(bonus_round_bonus_level)          ;move score bonus up one notch
          ld b,a
          inc a
          cp 4
          jr c,blevok
          ld a,3
blevok    ld (bonus_round_new_bonus_level),a

wrongstep ld hl,bonus_tiles_hit
          inc (hl)
          ld a,(bonus_round_tile_count)
          cp (hl)                                 ;all bonus tiles hit?         
          jr nz,nobrend2
          push bc
          push ix
          call init_jump_bonus
          pop ix
          pop bc
nobrend2  inc b
          ld e,b


notinbr   ld (ix+bobtype),e
          ld (ix+bobtimer),0
          ld (ix+bobanimdelay),0

          ld a,11                                 ;trig $0c and over are reserved for "bad bonuses"
          cp e                          
          jp c,bad_bonus
          
          ld (ix+bobstatus),1
          ld hl,bobinitframelist
          ld d,0
          add hl,de
          ld a,(hl)
          ld (ix+bobframe),a
          ld a,(active_tile_x)                    ;position bonus object
          sla a
          sla a
          sla a
          sla a
          add a,8
          ld (ix+bob_x),a
          ld a,(active_tile_y)
          sla a
          sla a
          sla a
          sla a
          ld (ix+bob_y),a
          
          ld a,4                                  ;01-04 = score bouns
          cp e
          jr c,addlives
          dec e                                   ;add to score depending on obj type
          sla e                         
          sla e
          sla e
          ld d,0
          ld hl,score_addlist
          add hl,de
          ld de,score_addvalue
          ld bc,6
          ldir
          call score_add
          ret
          
addlives  ld a,7
          cp e
          jr c,addjumps
          ld a,e                                  ;add lives depending on obj type
          sub 4                                   ;05,06,07 = +1, +2, +3
          ld e,a
          ld a,(lives)
          add a,e
          cp 10
          jr c,livesok
          ld a,9
livesok   ld (lives),a
          ld a,2              
          call new_fx                             ;sound effect
          ret


addjumps  ld a,10                                 ;add bonus jumps for trigs $08,$09,$0a = +1,+2,+3
          cp e
          jr c,go_shield
          ld a,e
          sub 7
          ld e,a
          ld a,(jumps_lsd)
          add a,e
          cp 10
          jr c,jmsdok1
          sub 10
          ld (jumps_lsd),a
          ld a,(jumps_msd)
          inc a
          ld (jumps_msd),a
          cp 10
          jr c,jmsdok2
          ld a,9
          ld (jumps_msd),a
jmsdok1   ld (jumps_lsd),a
jmsdok2   ret
          


go_shield ld a,200                                ;init some shield time (trig $0b)
          ld (ball_shield),a
          ret                           

          
bad_bonus ret
          

;-----------------------------------------------------------------------------------------------

anim_bonus_objects

          ld ix,bonusob1
          ld b,4
anboblp   push bc
          ld a,(ix+bobstatus)
          or a
          jp z,bobisoff
          ld a,(ix+bobtype)
          cp 12
          jr nc,badboan
          inc (ix+bobtimer)
          ld a,(ix+bobtimer)
          bit 0,a
          jr nz,bobdmu
          dec (ix+bob_y)                ;bonus ob icon rises
bobdmu    cp 50
          jr c,bobson
          ld (ix+bobstatus),0
          jr bobisoff
bobson    ld a,(ix+bobtype)             ;animate extra life objects (heart icon anin)
          cp 5
          jr c,bobisoff
          cp 8
          jr nc,bobisoff
          ld e,a
          ld hl,bobinitframelist
          ld d,0
          add hl,de
          ld e,(hl)
          ld a,(ix+bobtimer)
          rra 
          rra 
          rra 
          and 1
          add a,e
          ld (ix+bobframe),a
          jr bobisoff
          
badboan   nop


bobisoff  ld bc,8
          add ix,bc
          pop bc
          djnz anboblp
          ret
          
;---------------------------------------------------------------------------------------------


score_add ld a,(score+1)
          ld l,a
          push hl
          ld de,score+5
          ld hl,score_addvalue+5
          ld b,6
          ld c,0
scralp    ld a,(de)
          add a,(hl)
          add a,c
          ld c,0
          cp 10
          jr c,sanctd
          sub 10
          ld c,1
sanctd    ld (de),a
          dec hl
          dec de
          djnz scralp
checkxl   pop hl
          bit 0,l
          ret z
          ld a,(score+1)
          bit 0,a
          ret nz
          ld a,2
          call new_fx
          ld a,(lives)                  ;extra life every 20,000
          inc a
          cp 9
          jr c,lifenmax
          ld a,9
lifenmax  ld (lives),a 
          ret
          
          
inc_score 

          ld a,(score+1)
          ld l,a
          push hl
          ld hl,score+5
          ld b,6
incsclp   inc (hl)
          ld a,(hl)
          cp 10
          jr nz,checkxl
          ld (hl),0
          dec hl
          djnz incsclp
          jr checkxl          
          

;--------------------------------------------------------------------------------------------

trigger_enemies

          ld a,(map_moved)
          or a
          ret z
          ld a,(fg_map_pos_y_pixel)
          or a
          ret nz
          
          ld de,(fg_map_pos_y_block)              ;scan 16 blocks for enemy triggers at   
          dec de                                  ;2 lines above top of display
          dec de
          ld a,d                                  ;dont look if thats above (trig) map top 
          cp $ff                                  ;(which shouldn't happen anyway as the bonus round
          ret z                                   ;map data is at the top of the map)
          ld a,map_width
          call mult_816 
          ld de,(trig_base)
          add hl,de 
          push hl
          pop iy
          
          ld ix,enemy_list                        ;start of enemy data structures
          ld e,16                                 ;16 possible enemy resource blocks
          ld hl,winleft_position                  ;initial x position (far left)
          ld (x_enemy_origin),hl
          ld hl,wintop_rasterline-$20
          ld (y_enemy_origin),hl
          call scan_for_trigs
          ret
          


scan_for_trigs

          ld b,map_width                          ;scan 16 blocks for enemy triggers
entrpolp  call go_level_data_bank
          ld d,(iy)                               ;any trig here?
          call go_bank_zero
          ld a,d
          cp $10                                  ;ignore trigs $0-$f and anything > max enemy trig
          jr c,ignore_tr
          cp last_enemy
          jr nc,ignore_tr
          ld a,e                                  ; dont bother looking if all resources taken
          or a
          jr z,ignore_tr
          call trigger_enemy_map

ignore_tr push bc
          ld bc,16                                ;add 16 to init x position
          ld hl,(x_enemy_origin)
          add hl,bc
          ld (x_enemy_origin),hl
          inc iy                                  ;next trig map block
          pop bc
          djnz entrpolp
          ret
          


trigger_enemy_map

;set d = trig number
;set e = number of enemy resources
;    ix = enemy list
;    (x_enemy_origin) = x origin position
;    (y_enemy_origin) = y origin position

          
fferblp   ld a,(ix+enemy_status)                  ;look for a free enemy resource block
          or a
          jr z,ffreeen
          push bc
          ld bc,16                                ;move to next enemy's entry in list
          add ix,bc
          pop bc
          dec e
          jr nz,fferblp                           ;all enemy resources in use?
          ret
          
ffreeen   push bc
          push iy
          ld (ix+enemy_status),1                  ;set up enemy
          ld a,d
          sub 16
          ld (ix+enemy_type),a                    
          ld c,a
          ld b,0
          sla c                                   ;multiply by 8 to get offset index in ob init table
          rl b
          sla c
          rl b
          sla c
          rl b
          ld iy,enemy_inits
          add iy,bc
          ld c,(iy+enemy_init_xoffset)            ;x coord offset
          ld b,0
          bit 7,c
          jr z,nosignex1
          dec b
nosignex1 ld hl,(x_enemy_origin)
          add hl,bc
          ld (ix+enemy_xlsb),l
          ld (ix+enemy_xmsb),h
          ld c,(iy+enemy_init_yoffset)            ;y coord offset
          ld b,0
          bit 7,c
          jr z,nosignex2
          dec b
nosignex2 ld hl,(y_enemy_origin)
          add hl,bc
          ld (ix+enemy_ylsb),l
          ld (ix+enemy_ymsb),h
          ld a,(iy+enemy_init_controlbits)
          ld (ix+enemy_control),a
          ld a,(iy+enemy_init_baseframe)
          ld (ix+enemy_frame),a
          xor a
          ld (ix+enemy_framecounter),a
          ld (ix+enemy_animtimer),a
          ld (ix+enemy_misc_1),a
          ld (ix+enemy_misc_2),a
          ld (ix+enemy_misc_3),a
          ld (ix+enemy_misc_4),a
          ld (ix+enemy_misc_5),a
          ld (ix+enemy_misc_6),a
          pop iy
          pop bc
          ret



trigger_enemy_nonmap

;hl = origin x
;de = origin y
;a = trig number

          push ix
          ld (x_enemy_origin),hl
          ld (y_enemy_origin),de
          ld d,a
          ld e,16
          ld ix,enemy_list
          call trigger_enemy_map
          pop ix
          ret
          
;---------------------------------------------------------------------------------------------

enemy_handler
          
          xor a
          ld (sprite_tile_colis),a
          
          ld ix,enemy_list                        
          ld b,16                                 
enbclp    ld a,(ix+enemy_status)
          or a
          jp z,nxtenboc

          ld h,0
          ld l,(ix+enemy_type)
          add hl,hl
          add hl,hl
          add hl,hl
          ld de,enemy_inits
          add hl,de
          push hl
          pop iy
          bit 0,(ix+enemy_control)                ;simple animation mode?
          jr z,nosimpan
          inc (ix+enemy_animtimer)
          ld a,(ix+enemy_animtimer)
          cp (iy+enemy_init_animspeed)
          jr nz,enfrasa
          ld (ix+enemy_animtimer),0
          inc (ix+enemy_framecounter)
          ld a,(ix+enemy_framecounter)
          cp (iy+enemy_init_framecount)
          jr nz,enfrasa
          ld (ix+enemy_framecounter),0
          bit 6,(ix+enemy_control)                ;ping pong animation?
          jr z,noppanim
          bit 2,(ix+enemy_control)
          jr z,ppansw
          res 2,(ix+enemy_control)
          jr enfrasa
ppansw    set 2,(ix+enemy_control)
          jr enfrasa
          
noppanim  bit 4,(ix+enemy_control)                ;one shot anim, then switch off enemy object?
          jr z,enfrasa
          ld (ix+enemy_status),0
          jr nxtenboc         

enfrasa   bit 2,(ix+enemy_control)                ;forwards or backwards simple anim?
          jr z,fwdanim
          ld a,(iy+enemy_init_framecount)
          sub (ix+enemy_framecounter)
          dec a
          jr enanim
fwdanim   ld a,(ix+enemy_framecounter)
enanim    add a,(iy+enemy_init_baseframe)
          ld (ix+enemy_frame),a
          
nosimpan  bit 1,(ix+enemy_control)
          jr z,noscwisc
          ld a,(map_moved)                        ;shift enemy down with scrolling screen?
          ld e,a
          ld d,0
          ld l,(ix+enemy_ylsb)
          ld h,(ix+enemy_ymsb)
          add hl,de
          ld (ix+enemy_ylsb),l
          ld (ix+enemy_ymsb),h
          
noscwisc  ld de,$138                              ;if enemy has moved out of bottom of screen switch off
          bit 5,(ix+enemy_control)                ;check if enemy type can exist further out of screen
          jr z,swofnorm
          ld de,$1c8
swofnorm  ld l,(ix+enemy_ylsb)                    
          ld h,(ix+enemy_ymsb)
          bit 7,h                                 ;if y pos is negetive, its above screen top
          jr z,outscrb
          ld d,0
          add hl,de
          jr nc,swenoff
          jr enstosc
outscrb   xor a
          sbc hl,de
          jr c,enstosc
swenoff   ld (ix+enemy_status),0

enstosc   ld a,(ix+enemy_type)                    ; make sure nonexistant enemy code is not called
          cp last_enemy
          jr nc,nxtenboc
          ld l,a                                  ; call enemy specific routines
          ld h,0
          add hl,hl
          ld de,enemy_routines
          add hl,de
          ld a,(hl)                               
          inc hl
          ld h,(hl)
          ld l,a
          push bc
          push ix
          call enemy_specific_routines
          pop ix
          pop bc
          
nxtenboc  ld de,16
          add ix,de
          dec b
          jp nz,enbclp
          ret


;---------------------------------------------------------------------------------------------

enemy_specific_routines

          jp (hl)


include "FLOS_based_programs\games\Bounder\inc\enemy_routines.asm"

;---------------------------------------------------------------------------------------------
          
          
get_enemy_xy

          ld l,(ix+enemy_xlsb)                    
          ld h,(ix+enemy_xmsb)
          ld e,(ix+enemy_ylsb)
          ld d,(ix+enemy_ymsb)          
          ret


update_enemy_xy

          ld (ix+enemy_xlsb),l                    
          ld (ix+enemy_xmsb),h          
          ld (ix+enemy_ylsb),e
          ld (ix+enemy_ymsb),d
          ret


;---------------------------------------------------------------------------------------------

directional_move
          
          ld a,(ix+enemy_misc_1)        ;adds xy offset at (ix+enemy_misc_1) to
          sra a                         ;coordinates of object. Switches off
          sra a                         ;object if x coords are out of screen limits
          sra a
          sra a
          ld c,a
          ld b,0
          bit 7,c
          jr z,hrnse
          dec b
hrnse     call get_enemy_xy
          add hl,bc
          call update_enemy_xy
          ld d,h
          ld e,l
          ld bc,$1c0
          xor a
          sbc hl,bc
          jr nc,rockoff
          ex de,hl
          ld bc,$60
          xor a
          sbc hl,bc
          jr nc,norockoff
rockoff   ld (ix+enemy_status),0
norockoff ld a,(ix+enemy_misc_1)
          and $f
          ld b,0
          bit 3,a
          jr z,hrnsey
          or $f0
          dec b
hrnsey    ld c,a
          call get_enemy_xy
          ex de,hl
          add hl,bc
          ex de,hl
          call update_enemy_xy
          ret

;---------------------------------------------------------------------------------------------

test_collision_points

; set c to test point list to use 
; set hl to x coord origin of enemy
; set de to y coord origin of enemy

; returns carry clear if no collision
;         carry set on collision

          ld a,(ball_shield)                      ;no collision check if ball isnt in normal play
          or a                                    ;(OR clears the carry flag)
          ret nz

unconditional_collision_test

          ld a,(ball_status)
          or a                                    ;(OR clears the carry flag)
          ret nz

          push ix
          ld (enemy_col_base_x),hl
          ld (enemy_col_base_y),de
          
          ld a,(ball_frame)
          ld hl,ball_squared_radius_list
          add a,l
          jr nc,nbrlc
          inc h
nbrlc     ld l,a
          push hl
          pop ix
                    
          ld hl,collision_list
          sla c
          ld b,0
          add hl,bc                               ;hl = addr in collision table select list
          ld e,(hl)
          inc hl
          ld d,(hl)                               ;de = addr of collision list to use
          ld a,(de)                     
          ld b,a                                  ;b = number of points in list to check
          inc de                                  
          
test_c_lp push bc
          ld hl,(enemy_col_base_x)      
          ld a,(de)                               ;a = x offset of point
          inc de
          push de
          ld e,a
          ld d,0
          bit 7,e                                 ;sign extend byte to word
          jr z,xofspos
          dec d                                   
xofspos   add hl,de                               ;hl = final computed x coord to check
          ld de,(ball_finalx)
          xor a
          sbc hl,de                               ;subtract ball x coord to get difference
          jr nc,xdelpos
          ld a,h                                  ;if value became negative, make positive 
          cpl
          ld h,a
          ld a,l
          cpl
          ld l,a
          inc hl
xdelpos   ld de,16                                ;is difference > 15?
          xor a
          sbc hl,de
          jr nc,nocolis1                          ;if > 15 there cannot be a collision
          add hl,de                               
          ld c,l                                  ;c = x difference 0 to 15
          pop de

          ld hl,(enemy_col_base_y)                
          ld a,(de)                               ;a = y offset of point
          inc de
          push de
          ld e,a
          ld d,0
          bit 7,e                                 ;sign extend byte to word
          jr z,yofspos
          dec d                                   
yofspos   add hl,de                               ;hl = final computed y coord to check
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr nc,ydelpos
          ld a,h
          cpl
          ld h,a
          ld a,l
          cpl
          ld l,a
          inc hl
ydelpos   ld de,16
          xor a
          sbc hl,de
          jr nc,nocolis2
          add hl,de                               ;l = y difference 0 to 15
          ld b,l
          pop de
          
          ld hl,square_table
          ld a,l
          add a,c
          jr nc,slosok1
          inc h
slosok1   ld l,a
          ld c,(hl)                               ;c = x difference squared
          ld hl,square_table
          ld a,l
          add a,b
          jr nc,slosok2
          inc h
slosok2   ld l,a
          ld a,(hl)                               ;a = y difference squared
          add a,c                                 ;add x difference squared
          rr a                                    ;half it for byte-sized comparison
          cp (ix)                                 
          jr nc,nocolis3                          ;test against allowable ball radius
          pop bc
          pop ix
          scf                                     ;carry flag set = collision
          ret
          
nocolis1  pop de    
          inc de
nocolis3  pop bc
          djnz test_c_lp
          pop ix
          xor a                                   ;carry flag clear = no collision
          ret
          
nocolis2  pop de
          jr nocolis3


;-------------------------------------------------------------------------------------------------

find_trig_at_xy

; set hl = source pos x (word)
; set de = source pos y (word)
;returns a = trigger value
          
          push hl
          ex de,hl
          ld bc,wintop_rasterline
          xor a
          sbc hl,bc
          ld a,(fg_map_pos_y_pixel)
          add a,l
          jr nc,ft1nc
          inc h
ft1nc     ld l,a
          srl h
          rr l
          srl h
          rr l
          srl h
          rr l
          srl h
          rr l
          ld bc,(fg_map_pos_y_block)
          add hl,bc
          ex de,hl
          ld a,map_width                ;multiply map width by ypos block line + slice offset
          call mult_816                 ;on return hl = map line offset
          ex de,hl
          pop hl
          ld bc,winleft_position
          xor a
          sbc hl,bc
          srl h
          rr l
          srl h
          rr l
          srl h
          rr l
          srl h
          rr l
          add hl,de
          ld bc,(trig_base)
          add hl,bc
          call go_level_data_bank
          ld b,(hl)
          call go_bank_zero
          ld a,b
          ret
          
                    
;-------- Scrolling System ----------------------------------------------------------------------------------

scroll_screen

          ld a,(bg_map_buffer)          ;show the opposite video map to that being updated
          xor 2                         ;for background
          rrca
          rrca 
          rrca 
          rrca
          ld b,a
          ld a,(fg_map_buffer)          ;for foreground
          xor 2
          rrca
          rrca
          rrca
          or b
          or %10010001                  ;set other required bits in PF control reg
          ld (vreg_vidctrl),a           
          ld a,(bg_map_pos_y_pixel)
          ld (vreg_yhws_bplcount),a     ;set background y HW scroll pixel-position
          ld a,(fg_map_pos_y_pixel)
          or $80
          ld (vreg_yhws_bplcount),a     ;set foreground y HW scroll pixel-position

          
          ld a,(bg_map_pos_y_pixel)     ;background 
          ld (map_slice),a
          ld a,(bg_map_buffer)
          add a,(video_base/256)
          ld (map_dest_base),a
          ld de,(bg_map_base)
          ld (map_src_base),de
          ld de,(bg_map_pos_y_block)
          dec de                        ;to draw screen 1 line above the currently SHOWN position
          ld (map_pos_y),de
          call draw_map_slice
          
          ld a,(fg_map_pos_y_pixel)     ;foreground
          ld (map_slice),a
          ld a,(fg_map_buffer)
          add a,(video_base/256)+4
          ld (map_dest_base),a
          ld de,(fg_map_base)
          ld (map_src_base),de
          ld de,(fg_map_pos_y_block)
          dec de                        ;to draw screen 1 line above the currently SHOWN position
          ld (map_pos_y),de
          call draw_map_slice
          ret
          
          
draw_map_slice

          push bc
          call kjt_page_in_video        ;copy a slice of map blocks to video block map

          xor a
          ld (vreg_vidpage),a           ;block maps are in vid page 0
          
          ld de,(map_pos_y)
          ld a,(map_slice)              
          add a,e
          jr nc,msr_ncry1
          inc d
msr_ncry1 ld e,a
          ld a,map_width                ;multiply map width by ypos block line + slice offset
          call mult_816
          ld de,(map_src_base)
          add hl,de                     ;hl = map source address
          ld a,(map_dest_base)
          ld d,a
          ld a,(map_slice)
          sla a
          sla a
          sla a
          sla a
          sla a
          jr nc,msr_ncry2
          inc d
msr_ncry2 ld e,a                        ;de = video blockmap destination address
          ld bc,scroll_width
          call go_level_data_bank
          ldir                          ;fill in a line of blocks
          call go_bank_zero
          
          call kjt_page_out_video
          pop bc
          ret

;---------------------------------------------------------------------------------------------

update_map_pos
                    
          xor a
          ld (map_moved),a
          
          ld a,(bonus_round)            ;no scrolling during bonus round
          or a
          ret nz
          
          ld a,(scroll_active)
          or a
          jr z,skpfgs
          ld a,(counter)                ;update background position (move every 4th frame)
          and 3
          jr nz,skpbgs
          call inc_score
          ld a,(bg_map_pos_y_pixel)
          sub 1                         
          jr nc,bgypos
          ld hl,(bg_map_pos_y_block)
          dec hl
          ld (bg_map_pos_y_block),hl
          ld a,(bg_map_buffer)
          xor 2
          ld (bg_map_buffer),a
          ld a,15
bgypos    ld (bg_map_pos_y_pixel),a
          
skpbgs    ld a,(counter)                
          and 1
          jr nz,skpfgs
          ld a,1
          ld (map_moved),a
          ld a,(fg_map_pos_y_pixel)     ;update foreground position (move every 2nd frame)
          sub 1
          jr nc,fgypos
          ld hl,(fg_map_pos_y_block)
          dec hl
          ld (fg_map_pos_y_block),hl
          ld a,h                        ;reached end of map?
          or a
          jr nz,not_eom
          ld a,l
          cp 14
          jr nz,not_eom
          inc hl
          ld (fg_map_pos_y_block),hl
          xor a
          ld (fg_map_pos_y_pixel),a
          xor a
          ld (scroll_active),a
          ld a,1
          ld (end_of_map),a
          xor a
          ld (map_moved),a
          jr skpfgs
not_eom   ld a,(fg_map_buffer)
          xor 2
          ld (fg_map_buffer),a
          ld a,15
fgypos    ld (fg_map_pos_y_pixel),a
skpfgs    ret


;-------------------------------------------------------------------------------------------

draw_starting_playfield
          
          ld a,video_base/256                     ;background - draw on map buffer A
          ld hl,(bg_map_base)
          ld de,(bg_map_pos_y_block)
          call build_map
          ld a,video_base/256                     ;background - draw on map buffer B
          add a,2
          ld hl,(bg_map_base)
          ld de,(bg_map_pos_y_block)
          call build_map
          ld a,video_base/256                     ;foreground - draw on map buffer A
          add a,4
          ld hl,(fg_map_base)
          ld de,(fg_map_pos_y_block)
          call build_map
          ld a,video_base/256                     ;foreground - draw on map buffer B
          add a,6
          ld hl,(fg_map_base)
          ld de,(fg_map_pos_y_block)
          call build_map


          ld de,(fg_map_pos_y_block)              ;now scan initial screen for enemy trigs          
          ld a,map_width                          ;and set 'em up if found
          call mult_816 
          ld de,(trig_base)
          add hl,de 
          push hl
          pop iy
          
          ld ix,enemy_list                        ;start of enemy data structures
          ld e,16                                 ;16 possible enemy resource blocks
          ld hl,wintop_rasterline+1
          ld b,0
          ld a,(fg_map_pos_y_pixel)
          ld c,a
          xor a
          sbc hl,bc
          ld (y_enemy_origin),hl
          
          ld b,15
istscan   ld hl,winleft_position                  ;initial x position (far left)
          ld (x_enemy_origin),hl
          push bc
          call scan_for_trigs
          ld hl,(y_enemy_origin)
          ld bc,16
          add hl,bc
          ld (y_enemy_origin),hl
          pop bc
          djnz istscan
          ret
          
          

build_map ld (map_dest_base),a
          ld (map_src_base),hl
          ld (map_pos_y),de
          ld b,16
dstmloop  ld a,b
          dec a
          ld (map_slice),a
          call draw_map_slice
          djnz dstmloop
          ret


          
;-------- Allocate HW sprite resources to game objects -----------------------------------------

setup_sprites
          
          ld hl,spr_registers
          ld a,(counter)
          cpl                           ;write to the register bank currently "hidden"
          and 1
          add a,h
          ld h,a
          ld (spr_reg_base),hl
          
          ld ix,(spr_reg_base)
          ld bc,45*4                    ;update score sprite definitions
          add ix,bc
          ld de,score
          ld b,6
updslp    ld a,(de)
          add a,$8f
          ld (ix+3),a
          inc ix
          inc ix
          inc ix
          inc ix
          inc hl
          inc de
          djnz updslp
          
          ld ix,(spr_reg_base)
          ld bc,52*4                    ;update jump status sprite defs
          add ix,bc
          ld a,(jumps_msd)
          add a,$8f
          ld (ix+3),a
          ld a,(jumps_lsd)
          add a,$8f
          ld (ix+7),a
                    
          ld ix,(spr_reg_base)
          ld bc,55*4                    ;and lives
          add ix,bc
          ld a,(lives)
          add a,$8f
          ld (ix+3),a


          ld hl,(spr_reg_base)
          ld bc,45*4                    ;protect score sprites by setting maximum                   
          add hl,bc                     ;sprite resources to 45
          ld (sprite_max),hl                      
                    
          xor a
          ld hl,(spr_reg_base)          ;at outset start clear all the sprite control 
          ld b,45                       ;registers (except the score/lives)
clrallspr ld (hl),a
          inc l
          ld (hl),a
          inc l
          ld (hl),a
          inc l
          ld (hl),a
          inc l
          djnz clrallspr
          
          
          ld ix,(spr_reg_base)          ;base of sprite registers
          
          ld a,(ball_status)
          cp 1
          jr z,ball_low
          cp 2
          jr nz,ball_no_fall
ball_low  call allocate_ball            ;if ball is falling (or small explo) it should have low priority

ball_no_fall

          
          ld iy,enemy_list              ;fill in enemy sprites from active object data
          ld b,16                       ;that we want to lower sprite priority than ball
entosplp  push bc
          ld a,(iy+enemy_status)
          or a
          jr z,noentosp
          bit 3,(iy+enemy_control)
          jr nz,noentosp
          ld l,(iy+enemy_xlsb)
          ld h,(iy+enemy_xmsb)
          ld e,(iy+enemy_ylsb)
          ld d,(iy+enemy_ymsb)
          ld c,(iy+enemy_frame)
          call object_to_sprites
noentosp  ld bc,16
          add iy,bc
          pop bc
          djnz entosplp

          
          ld a,(bonus_round_end)
          or a
          jr nz,nobrspr
          ld a,(bonus_round)            ;during bonus round highlight the tile which is
          or a                          ;required to maximize bonus
          jr z,nobrspr
          ld a,(counter)
          and 4                         ;flash "?" sprite
          jr z,nobrspr
          ld a,(bonus_round_step)
          sla a
          ld l,a
          ld h,0
          ld de,bonus_round_tile_locations
          add hl,de
          ld a,(hl)
          inc hl
          ld c,(hl)
          sla c
          sla c
          sla c
          sla c
          ld e,c
          ld d,0
          ld hl,wintop_rasterline+9
          add hl,de
          ex de,hl
          sla a
          sla a
          sla a
          sla a
          ld c,a
          ld b,0
          ld hl,winleft_position+8
          add hl,bc
          ld c,$9c
          call object_to_sprites
          
          
nobrspr   ld a,(game_start_delay)
          or a
          jr nz,no_ball
          ld a,(ball_status)
          or a
          jr nz,show_ball
          ld a,(ball_shield)
          or a
          jr z,show_ball
          ld a,(counter)
          and 1
          jr nz,no_ball

show_ball ld a,(ball_status)
          cp 1                          ;falling?
          jr z,no_ball        
          cp 2                          ;small explosion?
          jr z,no_ball
          call allocate_ball

          
no_ball   ld a,(ball_status)
          cp 4
          jr z,do_smspr
          cp 5
          jr nz,skpsmspr
          ld de,(ball_finaly)           ;ball sinking sprite
          ld hl,(ball_finalx)
          ld a,(sinking_ball_frame)
          ld c,a
          call object_to_sprites
          jr skpsmspr
          

do_smspr  ld hl,(ball_finaly)           ;smoke offsets when ball explodes
          ld bc,(ball_exp_air_offset)
          xor a
          sbc hl,bc
          ex de,hl
          ld hl,(ball_finalx)
          xor a
          sbc hl,bc
          ld a,(ball_exp_air_frame)
          ld c,a
          call object_to_sprites
          ld hl,(ball_finaly)
          ld bc,(ball_exp_air_offset)
          xor a
          sbc hl,bc
          ex de,hl
          ld hl,(ball_finalx)
          add hl,bc
          ld a,(ball_exp_air_frame)
          ld c,a
          call object_to_sprites        
          ld hl,(ball_finaly)
          ld bc,(ball_exp_air_offset)
          add hl,bc
          ex de,hl
          ld hl,(ball_finalx)
          xor a
          sbc hl,bc
          ld a,(ball_exp_air_frame)
          ld c,a
          call object_to_sprites
          ld hl,(ball_finaly)
          ld bc,(ball_exp_air_offset)
          add hl,bc
          ex de,hl
          ld hl,(ball_finalx)
          add hl,bc
          ld a,(ball_exp_air_frame)
          ld c,a
          call object_to_sprites                            


skpsmspr  ld iy,bonusob1                          ;fill in bonus object sprites
          ld b,4
bobtslp   push bc
          ld a,(iy+bobstatus)
          or a
          jr z,nxtbob
          ld b,(iy+bob_x)
          ld c,(iy+bob_y)
          call window_offset_adjust
          ld c,(iy+bobframe)
          call object_to_sprites
nxtbob    ld bc,8
          add iy,bc
          pop bc
          djnz bobtslp
          
          
          ld iy,enemy_list                        ;fill in enemy sprites from active object data
          ld b,16                                 ;to appear above the ball
entosplp2 push bc
          ld a,(iy+enemy_status)
          or a
          jr z,noentosp2
          bit 3,(iy+enemy_control)
          jr z,noentosp2
          ld l,(iy+enemy_xlsb)
          ld h,(iy+enemy_xmsb)
          ld e,(iy+enemy_ylsb)
          ld d,(iy+enemy_ymsb)
          ld c,(iy+enemy_frame)
          call object_to_sprites
noentosp2 ld bc,16
          add iy,bc
          pop bc
          djnz entosplp2
          ret


allocate_ball
          
          ld hl,wintop_rasterline       ;main ball object top window pos
          ld de,(ball_y)                ;y origin
          add hl,de
          ex de,hl                      ;de = y
          ld hl,winleft_position        ;left window pos
          ld bc,(ball_x)                ;x origin           
          add hl,bc                     ;hl = x   
          ld a,(ball_frame)
          ld c,a                        ;object number
          ld (ball_finalx),hl
          ld (ball_finaly),de
          call object_to_sprites
          ret
          
;-------------------------------------------------------------------------------------------------

next_level

          ld a,(level)
          inc a
          ld (level),a
          cp number_of_levels
          jp z,congratulations
          
init_level
          
          call load_level
          call clear_enemies
                    
          xor a
          ld (end_of_level),a
          ld (bonus_round),a
          ld (bonus_round_end),a
          ld (ball_anim_delay),a
          ld (fade_level),a
          ld (ball_status),a
          ld (ball_frame),a
          ld (end_of_map),a
          ld (fg_map_buffer),a
          ld (bg_map_buffer),a
          ld (counter),a
          ld (glow_index),a
          ld (faded_in),a
          ld (faded_out),a
          
          ld a,1
          ld (fade_dir),a
                    
          ld a,(level)                            ;set init scroll positions
          sla a
          sla a
          ld l,a
          ld h,0
          ld bc,level_startblock_positions
          add hl,bc
          ld c,(hl)
          inc hl
          ld b,(hl)
          inc hl
          ld (fg_map_pos_y_block),bc
          ld c,(hl)
          inc hl
          ld b,(hl)
          ld (bg_map_pos_y_block),bc
          ld a,$0f
          ld (fg_map_pos_y_pixel),a
          ld (bg_map_pos_y_pixel),a
          call draw_starting_playfield
          
          ld hl,$1d0                              ;"start" text object
          ld de,$98
          ld a,$32
          call trigger_enemy_nonmap
          
          call init_reposition_ball
          
          ld a,10
          ld (game_start_delay),a
          ld a,100
          ld (recommence_scroll),a
          
          ld hl,palette
          ld b,0
palblk    ld (hl),0
          inc hl
          ld (hl),0
          inc hl
          djnz palblk
          
          ld a,8
          call new_fx                             ;sound effect
          
          ld hl,$c000
          ld (force_sample_base),hl     
          call init_tracker             ;initialize mod with forced sample_base
          ld a,9
          ld (songspeed),a              ;slow speed for ingame tune
          ld a,10
          ld (music_module+950),a       ;force end of song position for tune 2
          ld a,0
          ld (chan_1_enable),a          ;chan 1 silent ingame

          ret
          
;-------------------------------------------------------------------------------------------
                    
          
init_bonus_round

          ld a,(jumps_msd)                        ;if no jumps on init, go direct to
          ld b,a                                  ;nect level instead
          ld a,(jumps_lsd)
          or b
          jp z,next_level

          ld a,1
          ld (bonus_round),a
          ld (fade_dir),a
          xor a
          ld (fade_level),a
          ld (bonus_round_step),a
          ld (bonus_round_bonus_level),a
          ld (bonus_round_tile_count),a
          ld (bonus_round_end),a
          ld (bonus_tiles_hit),a
          ld (fg_map_pos_y_block),a
          ld (fg_map_pos_y_block+1),a
          ld (fg_map_pos_y_pixel),a
          ld (scroll_active),a
          ld (ball_status),a
          ld (ball_frame),a
          ld (end_of_level),a
          ld (faded_in),a
          ld (faded_out),a
          ld hl,0
          ld (ball_finalx),hl
          ld (ball_finaly),hl
                    
          call get_bonus_round_tile_locations
          call clear_enemies
          call draw_starting_playfield
          call init_reposition_ball     

          ld hl,$120                              ;"bonus round" text object
          ld de,$9a
          ld a,$33
          call trigger_enemy_nonmap

          ld a,150
          ld (game_start_delay),a
          
          ld hl,$c000
          ld (force_sample_base),hl     
          call init_tracker             ;initialize mod with forced sample_base
          ld a,9
          ld (songspeed),a              ;slow speed for bonus "tune"
          ld a,10
          ld (songpos),a                ;force start pos for bonus "tune"
          ld a,12
          ld (music_module+950),a       ;force end of song position for tune 2
          ld a,0
          ld (chan_1_enable),a          ;chan 1 silent ingame

          ret


;--------------------------------------------------------------------------------------------


get_bonus_round_tile_locations

          ld ix,bonus_round_tile_count
          ld hl,(trig_base)
          ld b,0
fbrtlp2   ld c,0
fbrtlp    call go_level_data_bank
          ld d,(hl)
          call go_bank_zero
          ld a,d
          cp $f0                                  ;if > $f0 its not a bonus round tile trigger
          jr nc,notbrt
          sub $e0
          jr c,notbrt                             ;if < $e0 its not a bonus round tile trigger
          sla a
          ld e,a
          ld d,0
          push hl
          ld hl,bonus_round_tile_locations
          add hl,de
          ld (hl),c
          inc hl
          ld (hl),b
          pop hl
          inc (ix)
notbrt    inc hl
          inc c
          ld a,c
          cp 16
          jr nz,fbrtlp
          inc b
          ld a,b
          cp 15
          jr nz,fbrtlp2
          ret

;-------------------------------------------------------------------------------------------

init_jump_bonus

          ld a,8
          ld (ball_status),a                      ;in limbo
          xor a
          ld (ball_frame),a
          ld a,1
          ld (bonus_round_end),a
          ld a,255
          ld (game_start_delay),a
          ld hl,$1d2                              ;"jump bonus" text object
          ld de,$90
          ld a,$34
          call trigger_enemy_nonmap
          ld hl,$62                               ;"0000" text object
          ld de,$b0
          ld a,$35
          call trigger_enemy_nonmap

          ld hl,score_addvalue
          ld b,6
clrsav    ld (hl),0
          inc hl
          djnz clrsav
          
          ld a,$a7                                ;modify the score object
          ld ix,spr_objecta1                      ;to reflect number of jumps remaining
          ld a,(jumps_msd)
          ld (score_addvalue+2),a
          add a,$a7
          ld (ix+3),a
          ld a,(jumps_lsd)
          ld (score_addvalue+3),a
          add a,$a7
          ld (ix+7),a         
          
          call score_add
          
          ret

;--------------------------------------------------------------------------------------------

decrement_br_jumps


          ld a,(bonus_round)            ;only dec jumps during bonus round
          or a
          ret z
          
          xor a
          ld (bonus_round_new_bonus_level),a
          
          ld de,jumps_lsd
          ld hl,jumps_msd
          ld a,(de)           
          ld c,(hl)
          ld b,a
          dec b
          ld a,b
          cp $ff
          jr z,brjmdd
          ld (de),a
          ret
brjmdd    ld a,9
          ld (de),a
          dec c
          ld a,c
          cp $ff
          jr z,lastjump
          ld (hl),a
          ret
lastjump  xor a
          ld (de),a
          ld (hl),a
          call init_jump_bonus          
          ret
                    
;--------------------------------------------------------------------------------------------

clear_enemies
          
          ld hl,enemy_list
          ld b,0
clrnmelp  ld (hl),0
          inc hl
          djnz clrnmelp
          ret

;--------------------------------------------------------------------------------------------

timed_events

          ld a,(bonus_round_end)
          or a
          jr z,nobrestuff
          inc a
          jr z,nobrestuff
          cp 150
          jr nz,nbreif
          ld (bonus_round_end),a                  ;start colour fade for bonus round end
          ld a,$ff
          ld (fade_dir),a
          ld a,$1f
          ld (fade_level),a
          jr nobrestuff
nbreif    ld (bonus_round_end),a

nobrestuff

          ld a,(end_of_level)
          or a
          jr z,neoflev
          inc a
          jr z,neoflev
          ld (end_of_level),a
          cp 50
          jr nz,neoflev
          ld a,$1f
          ld (fade_level),a
          ld a,$ff
          ld (fade_dir),a
          
neoflev   ld a,(game_over)
          or a
          jr z,nogamov
          inc a
          jr z,nogamov
          ld (game_over),a
          cp 100
          jr nz,nogamov
          ld a,$ff
          ld (fade_dir),a
          ld a,$1f
          ld (fade_level),a

nogamov   ret

          
;--------------------------------------------------------------------------------------

object_to_sprites

; set IX = first sprite register for this object to use
;     HL = X origin of object
;     DE = Y origin if object
;      C = object number
;     and variable "sprite_max" to sprite register stop location

          ld a,(wiggle_applied)
          add a,l
          jr nc,nowigc
          inc h
nowigc    ld l,a
          ld (origin_x),hl
          ld (origin_y),de

          ld b,0
          sla c
          rl b
          ld hl,object_loc_list 
          add hl,bc
          ld e,(hl)
          inc hl
          ld d,(hl)
          
          ld a,(de)           
          ld b,a              ;b = number of HW sprites used by object          
          inc de

sproblp   push bc             ;see if sprite max is above this sprite we're about to use
          push ix
          pop hl
          ld bc,(sprite_max)
          xor a
          sbc hl,bc
          jr nz,sproktu       ;sprite is OK to use
          ld a,(counter)
          and 1               ;if at sprite max, do a crude multiplex by wrapping 
          jr nz,mplexs        ;around to first sprite resource on odd frames, and ditching 
          pop bc              ;the excess sprites on even frames
          ret
mplexs    ld ix,(spr_reg_base)
sproktu   pop bc

          ld hl,(origin_x)
          ld a,(de)           ; x offset from origin
          bit 7,a
          jr z,spobadx        
          add a,l             ; negetive offset
          jr c,spobno1
          dec h
          jp spobno1
spobadx   add a,l             ; positive offset   
          jr nc,spobno1
          inc h
spobno1   ld (ix),a           ; x coord LSB
          ld a,h
          and 1
          ld c,a              ; c = x coord MSb

          inc de
          ld hl,(origin_y)
          ld a,(de)           ; y offset from origin
          bit 7,a
          jr z,spobady        
          add a,l             ;negetive offset
          jr c,spobno2
          dec h
          jp spobno2
spobady   add a,l             ;positive offset
          jr nc,spobno2
          inc h
spobno2   ld (ix+2),a         ;y coord LSB
          ld a,h
          and 1
          sla a               ; y coord MSb
          or c
          ld c,a
          
          inc de
          ld a,(de)           
          ld (ix+3),a         ;definition number LSB
          
          inc de
          ld a,(de)
          or c
          ld (ix+1),a         ;y height, def MSb, X coord LSb, Y coord LSb
          
          inc de
          ex de,hl
          ld de,4
          add ix,de           ;next hardware register
          ex de,hl
          djnz sproblp
          ret
          
                    
;---------------------------------------------------------------------------------------------------

mult_816

; Input:  A = Multiplier, DE = Multiplicand
; Output: A:HL = Product 

          ld        hl,0
          ld        c,0
          add       a,a                 ; optimised 1st iteration
          jr        nc,$+4
          ld        h,d
          ld        l,e
          add       hl,hl               ; 
          rla                           ;
          jr        nc,$+4              ; 
          add       hl,de               ; 
          adc       a,c                 ; 
          add       hl,hl               ; 
          rla                           ; 
          jr        nc,$+4              ; 
          add       hl,de               ; 
          adc       a,c                 ; 
          add       hl,hl               ; 
          rla                           ; 
          jr        nc,$+4              ; 
          add       hl,de               ; 
          adc       a,c                 ; 
          add       hl,hl               ; 
          rla                           ; 
          jr        nc,$+4              ; 
          add       hl,de               ; 
          adc       a,c                 ; 
          add       hl,hl               ;
          rla                           ; 
          jr        nc,$+4              ; 
          add       hl,de               ; 
          adc       a,c                 ;
          add       hl,hl               ; 
          rla                           ; 
          jr        nc,$+4              ; 
          add       hl,de               ; 
          adc       a,c                 ; 
          add       hl,hl               ; 
          rla                           ; 
          jr        nc,$+4              ; 
          add       hl,de               ; 
          adc       a,c                 ; 
          ret

;---------------------------------------------------------------------------------------------      

game_palette_fade

          ld hl,0                       ;fade entire palette
          ld bc,256
          call palette_fade
          call update_fade
          ret


;---------------------------------------------------------------------------------------------

red_glow  ld a,(counter)
          and 7
          ret nz
          ld a,(fade_dir)
          or a
          ret nz
          ld a,(faded_in)
          or a
          ret z
          ld a,(faded_out)
          or a
          ret nz
                    
          ld hl,red_glow_table
          ld a,(glow_index)
          ld e,a
          ld d,0
          add hl,de
          ld de,palette+(240*2)
          ld bc,26                      ;13 colours involved
          ldir
          add a,26
          cp 208                        ;eight sets of colours 8 * 26 = 160
          jr nz,nogwrap
          xor a
nogwrap   ld (glow_index),a
          ret
          
          
;---------------------------------------------------------------------------------------------      

init_status_line_sprites

          ld ix,spr_registers+(45*4)    ;init score sprites
          add ix,de
          ld a,$a0
          ld b,6
scorsplp  ld (ix),a
          ld (ix+1),$10
          ld (ix+2),$1a
          ld (ix+3),$8f
          inc ix
          inc ix
          inc ix
          inc ix
          add a,8
          djnz scorsplp
          
          ld ix,spr_registers+(51*4)    ;init jumps sprites
          add ix,de
          ld (ix),$62
          ld (ix+1),$11
          ld (ix+2),$1a
          ld (ix+3),$67
          ld ix,spr_registers+(52*4)
          add ix,de
          ld (ix),$70
          ld (ix+1),$11
          ld (ix+2),$1a
          ld (ix+3),$8f
          ld ix,spr_registers+(53*4)
          add ix,de
          ld (ix),$78
          ld (ix+1),$11
          ld (ix+2),$1a
          ld (ix+3),$8f
                    
          ld ix,spr_registers+(54*4)    ;init lives sprites
          add ix,de
          ld (ix),$84
          ld (ix+1),$11
          ld (ix+2),$1a
          ld (ix+3),$b2
          ld ix,spr_registers+(55*4)
          add ix,de
          ld (ix),$94
          ld (ix+1),$11
          ld (ix+2),$1a
          ld (ix+3),$8f                 
          ret


;---------------------------------------------------------------------------------------------

anim_tiles

          ld hl,tile_anim_count1                  ;do flash across "?" tile
          inc (hl)
          ld a,(tile_anim_max1)
          cp (hl)
          jr nz,namtile1
          ld (hl),0
          
          ld a,(tile_anim_tile1)
          add a,$70                     
          ld b,3    
          call copy_tile                          ;a=source tile, b=destination tile
          
          ld a,4                                  ;anim speed
          ld (tile_anim_max1),a
          ld hl,tile_anim_tile1
          inc (hl)
          ld a,(hl)
          cp 5
          jr nz,namtile1
          ld (hl),0
          ld a,100                                ;anim delay between loops
          ld (tile_anim_max1),a


namtile1  ld hl,tile_anim_count2                  ;do mud anim tile
          inc (hl)
          ld a,(tile_anim_max2)
          cp (hl)
          jr nz,namtile2
          ld (hl),0
          
          ld a,(tile_anim_tile2)
          add a,$84                     
          ld b,6    
          call copy_tile                          ;a=source tile, b=destination tile
          
          ld a,3                                  ;anim speed
          ld (tile_anim_max2),a
          ld hl,tile_anim_tile2
          inc (hl)
          ld a,(hl)
          cp 6
          jr nz,namtile2
          ld (hl),0
          ld a,55                                 ;anim delay between loops
          ld (tile_anim_max2),a


namtile2  ld hl,tile_anim_count3                  ;do mud anim tile
          inc (hl)
          ld a,(tile_anim_max3)
          cp (hl)
          jr nz,namtile3
          ld (hl),0
          
          ld a,(tile_anim_tile3)
          add a,$84                     
          ld b,7    
          call copy_tile                          ;a=source tile, b=destination tile
          
          ld a,4                                  ;anim speed
          ld (tile_anim_max3),a
          ld hl,tile_anim_tile3
          inc (hl)
          ld a,(hl)
          cp 6
          jr nz,namtile3
          ld (hl),0
          ld a,98                                 ;anim delay between loops
          ld (tile_anim_max3),a


namtile3  ld hl,tile_anim_count4                  ;do mud anim tile
          inc (hl)
          ld a,(tile_anim_max4)
          cp (hl)
          jr nz,namtile4
          ld (hl),0
          
          ld a,(tile_anim_tile4)
          add a,$84                     
          ld b,8    
          call copy_tile                          ;a=source tile, b=destination tile
          
          ld a,5                                  ;anim speed
          ld (tile_anim_max4),a
          ld hl,tile_anim_tile4
          inc (hl)
          ld a,(hl)
          cp 6
          jr nz,namtile4
          ld (hl),0
          ld a,43                                 ;anim delay between loops
          ld (tile_anim_max4),a

namtile4  ret


copy_tile

                              
          ld h,a                                  ; copy tile definition with blitter
          ld l,0
          ld c,0
          call blit_wait
          ld (blit_src_loc),hl
          ld (blit_dst_loc),bc
          ld a,$00  
          ld (blit_src_mod),a
          ld (blit_dst_mod),a
          ld a,%01110000                          ; ascending, source msb = 1 dest msb = 1
          ld (blit_misc),a
          ld a,15
          ld (blit_height),a
          ld a,15
          ld (blit_width),a                       
          ret


wiggle    ld a,(wiggle_index)
          or a
          ret z
          ld e,a
          inc a
          cp 16
          jr nz,wnoto
          xor a
wnoto     ld (wiggle_index),a
          ld d,0
          ld hl,wiggle_table
          add hl,de
          ld a,(hl)
          ld (wiggle_applied),a
          ret
          

;---------------------------------------------------------------------------------------------      
; TITLE SCREEN                
;---------------------------------------------------------------------------------------------

irq_line0           equ $25             ;colour bars top
irq_line1           equ $6b             ;top scroll split
irq_line2           equ $73             ;stop scroll top split
irq_line3           equ $ad             ;lower scroll split
irq_line4           equ $b6             ;stop scroll lower split
irq_line5           equ $c5             ;colour bars bottom

;---------------------------------------------------------------------------------------------

title_screen
          
          call silence_audio

;--------- Load Title GFX ------------------------------------------------------------------------

          ld hl,titles_tiles_fn         ;filename loc
          ld c,8                        ;destination video bank (tile set 1)
          ld b,4                        ;number of 8KB chunks
          call load_tile_data
          jp nz,load_error
          
          ld hl,titles_sprites_fn       ;load "bounder" sprites 
          ld de,$1            
          call load_sprite_data
          jp nz,load_error


;--------- Init Titles Video + System settings -------------------------------------------------------------

          in a,(sys_mem_select)
          and %00111000
          out (sys_mem_select),a        ; bank zero
          
          ld a,%00001011                
          ld (vreg_vidctrl),a           ; tile mode / playfield A uses tile set B / wideborder
          xor a
          ld (vreg_rasthi),a            ; use y window pos reg
          ld a,$3d                                
          ld (vreg_window),a            ; 240 line display
          ld a,%00000100                
          ld (vreg_rasthi),a            ; Switch to x window pos reg.
          ld a,$9a                      
          ld (vreg_window),a            ; Window Width = 272 pixels incl. wideborder
          xor a
          ld (vreg_yhws_bplcount),a     ; x scroll a = 0
          ld a,$80
          ld (vreg_yhws_bplcount),a     ; x scroll b = 0
                    
          call zero_palette
          ld hl,titles_colours          ; fade routine to use title screen palette
          ld (colour_base),hl

          call wipe_sprites
          
          ld a,%00000001                ; global sprite enable
          ld (vreg_sprctrl),a
          ld a,0
          out (sys_ps2_joy_control),a   ; select joystick 0

;--------- Set up IRQ -------------------------------------------------------------------------
          
          di                            ;disable irqs at CPU level
          
          ld hl,irq_handler0  
          ld (irq_vector),hl
          ld a,irq_line0
          ld (vreg_rastlo),a            ;first split line number req'd
          ld a,%00000010
          ld (vreg_rasthi),a            ;rast pos MSB and video IRQ enable
          ld a,%10000000
          out (sys_irq_enable),a        ;master IRQ enable 
          ld a,%00000111
          out (sys_clear_irq_flags),a   ;clear non-video IRQ flags

;--------- Initialize titles  ------------------------------------------------------------------
          
          xor a
          ld (vreg_vidpage),a           ;select video page 0 to access tile maps
          
          call kjt_page_in_video        ;clear tile maps
          ld hl,video_base
          ld bc,$800
wmaplp    ld (hl),0
          inc hl
          dec bc
          ld a,b
          or c
          jr nz,wmaplp

          ld hl,titles_map              ;copy title screen map to video memory
          ld de,video_base
          ld a,15
cpytmap   ld bc,$11
          ldir
          ex de,hl
          ld bc,$0f
          add hl,bc
          ex de,hl
          dec a
          jr nz,cpytmap

          call kjt_page_out_video
          
          ld a,$1
          ld (fade_dir),a
          xor a
          ld (fade_level),a
          ld (faded_in),a
          ld (faded_out),a
          ld (cheat),a

          ld hl,scroll_text
          ld (scrolltextpointer),hl
          ld a,0
          ld (top_scroll_fine),a

          call write_in_highscore
          
          ld hl,$c000
          ld (force_sample_base),hl     
          call init_tracker             ;initialize mod with forced sample_base
          ld a,6
          ld (songspeed),a              ;speed for title tune
          ld a,1
          ld (songpos),a
          ld a,10
          ld (music_module+950),a       ;force end of song position for tune 1
          ld a,1
          ld (chan_1_enable),a          ;all channels in use
          
          ei                            ;enable interrupts
                    
;-----------------------------------------------------------------------------------------------
; TITLE SCREEN ROUTINES CALLED AT VRT
;-----------------------------------------------------------------------------------------------
          
ts_wvrt   call wait_vrt

          ld hl,counter
          inc (hl)

          call bounce_logo_sprites
          call main_colour_fades
          call colour_cycling
          call scrolling_message
          call scrolling_tile
          call test_cheat
          
          call play_tracker   
          call update_sound_hardware

          in a,(sys_irq_ps2_flags)      ; ESC to exit
          bit 0,a
          jr z,no_quit
          in a,(sys_keyboard_data)
          cp $76                        
          jr z,quit_bounder
          
no_quit   ld a,(faded_out)              
          or a
          jr z,ts_wvrt        
          jp start_new_game
          
quit_bounder

          xor a
          out (sys_audio_enable),a      ; silence channels

          ld hl,hs_filename             ; erase existing hiscore file (if it exists)
          call kjt_erase_file
          ld ix,highscore
          ld b,0
          ld hl,hs_filename
          ld c,0
          ld de,6
          call kjt_save_file
          
          xor a
          ld a,$ff                      ; and quit (restart OS)
          ret
                    
;---------------------------------------------------------------------------------------------

load_error

          ld hl,$f00
          ld (palette),hl
          ld hl,$000
          ld (palette),hl
          jr load_error

;---------------------------------------------------------------------------------------------      

bounce_logo_sprites

          ld a,(cheat)                  ;title sprites dont bounce when cheat mode is on
          cpl
          and 1
          sla a
          sla a
          ld b,a

          ld a,(bounce_index)
          add a,b
          cp 128
          jr c,bi_ok
          sub 128
bi_ok     ld (bounce_index),a
          ld ix,spr_registers
          
          ld b,7                        ;number of chars
          ld c,100                      ;x coord / 2
lspr_lp   push af
          ld e,a
          ld d,0
          ld hl,sine_table+128
          add hl,de
          ld a,(hl)                     ;sine value for y coord
          add a,$40                     ;y coord offset
          call do_hwsprites
          ld a,c
          add a,12                      ;next char x offset/2
          ld c,a
          pop af
          add a,16                      ;sine offset for next char
          cp 128
          jr c,biok2
          sub 128
biok2     djnz lspr_lp
          
          ld a,(bounce_index)
          ld b,7                        ;number of chars
          ld c,100                      ;x coord / 2
lspr_lp2  push af
          ld e,a
          ld d,0
          ld hl,sine_table+128
          add hl,de
          ld a,(hl)                     ;sine value for y coord
          add a,$e0                     ;y coord offset
          call do_hwsprites
          ld a,c
          add a,12                      ;next char x offset/2
          ld c,a
          pop af
          add a,16                      ;sine offset for next char
          cp 128
          jr c,biok3
          sub 128
biok3     djnz lspr_lp2
          ret


do_hwsprites

          ld (ix+2),a                   ;y coord
          ld (ix+6),a                   ;y coord 2
          ld d,$10
          ld a,c
          sla a
          rl d
          ld (ix),a                     ;x coord
          ld (ix+1),d                   ;height / xmb
          add a,16
          jr nc,lsxmsbok
          set 0,d
lsxmsbok  ld (ix+4),a                   ;x coord 2
          ld (ix+5),d                   ;height / xmb 2
          ld a,7
          sub b
          sla a
          add a,$01
          ld (ix+3),a                   ;definition
          add a,14
          ld (ix+7),a                   ;def 2
          ld de,8
          add ix,de
          ret
          
;---------------------------------------------------------------------------------------------      

main_colour_fades

          ld hl,0                       ;fade palette colours 0 to 39
          ld bc,40
          call palette_fade
          call update_fade
          
          ld a,(fade_dir)               ;press fire or press CTRL to start game (init palette fade)
          or a                          ;only check if not fading
          ret nz
          in a,(sys_joy_com_flags)                
          bit 4,a
          jr nz,start_ng                          
          in a,(sys_irq_ps2_flags)
          bit 0,a
          ret z
start_ng  ld a,$ff
          ld (fade_dir),a
          ret
          
;----------------------------------------------------------------------------------------------


colour_cycling


          ld hl,(titles_colours+416)    ;cycle colours 208-240
          push hl
          ld hl,titles_colours+418
          ld de,titles_colours+416
          ld bc,64
          ldir
          pop hl
          ld (titles_colours+416+62),hl
          
          ld a,(fade_dir)               ;fade in these colours
          or a
          jr z,fastpalc       
          ld hl,208 
          ld bc,32
          call palette_fade
          ret

fastpalc  ld a,(faded_out)
          or a
          ret nz
          ld hl,titles_colours+416      ;or copy 'em to h/w palette unscaled    
          ld de,palette+416
          ld bc,64
          ldir
          ret
          

;--------------------------------------------------------------------------------------

irq_handler0

          push af   
          push hl                       ; Maskable IRQ jumps here
          ld a,irq_line1
          ld (vreg_rastlo),a
          ld hl,irq_handler1
          ld (irq_vector),hl
          ld a,%10000000
          ld (vreg_rasthi),a            ; clear irq flag (leaves rest of register intact)
          call colour_bars
          pop hl
          pop af                        
          ei                            ; re-enable interrupts
          reti                          ; return to main code

irq_handler1

          push af   
          push hl                       ; Maskable IRQ jumps here
          ld a,(top_scroll_fine)
          ld (vreg_xhws),a              
          ld a,irq_line2
          ld (vreg_rastlo),a
          ld hl,irq_handler2
          ld (irq_vector),hl
          ld a,%10000000
          ld (vreg_rasthi),a            ; clear irq flag (leaves rest of register intact)
          pop hl
          pop af                        
          ei                            ; re-enable interrupts
          reti                          ; return to main code


irq_handler2

          push af                       ; Maskable IRQ jumps here
          push hl
          xor a
          ld (vreg_xhws),a
          ld a,irq_line3
          ld (vreg_rastlo),a
          ld hl,irq_handler3  
          ld (irq_vector),hl
          ld a,%10000000
          ld (vreg_rasthi),a            ; clear irq flag (leaves rest of register intact)
          pop hl
          pop af                        
          ei                            ; re-enable interrupts
          reti                          ; return to main code


irq_handler3

          push af   
          push hl                       ; Maskable IRQ jumps here
          ld a,(top_scroll_fine)
          xor $0f
          ld (vreg_xhws),a              
          ld a,irq_line4
          ld (vreg_rastlo),a
          ld hl,irq_handler4
          ld (irq_vector),hl
          ld a,%10000000
          ld (vreg_rasthi),a            ; clear irq flag (leaves rest of register intact)
          pop hl
          pop af                        
          ei                            ; re-enable interrupts
          reti                          ; return to main code


irq_handler4

          push af                       ; Maskable IRQ jumps here
          push hl
          xor a
          ld (vreg_xhws),a
          ld a,irq_line5
          ld (vreg_rastlo),a
          ld hl,irq_handler5
          ld (irq_vector),hl
          ld a,%10000000
          ld (vreg_rasthi),a            ; clear irq flag (leaves rest of register intact)
          pop hl
          pop af                        
          ei                            ; re-enable interrupts
          reti                          ; return to main code



irq_handler5

          push af   
          push hl                       ; Maskable IRQ jumps here
          ld a,irq_line0
          ld (vreg_rastlo),a
          ld hl,irq_handler0
          ld (irq_vector),hl
          ld a,%10000000
          ld (vreg_rasthi),a            ; clear irq flag (leaves rest of register intact)
          call colour_bars
          pop hl
          pop af                        
          ei                            ; re-enable interrupts
          reti                          ; return to main code



;----------------------------------------------------------------------------------------------------

colour_bars

          push bc
          push de
          ld a,(fade_level)
          rlca
          rlca
          rlca
          and $f0
          ld c,a
          ld h,scale_table/256
          ld de,colour_bar_palette
          ld b,64
          
cbxwait1  ld a,(vreg_read)
          and 2
          jp z,cbxwait1
cbxwait2  ld a,(vreg_read)
          and 2
          jp nz,cbxwait2
          
          ld a,(de)
          or c
          ld l,a
          ld a,(hl) 
          ld (palette+511),a
          inc de
          ld a,(de)
          rrca
          rrca
          rrca
          rrca
          and $f
          or c
          ld l,a
          ld a,(hl)
          rrca
          rrca
          rrca
          rrca
          ld (fade_temp),a
          ld a,(de)
          and $f
          or c
          ld l,a
          ld a,(fade_temp)
          or (hl)
          ld (palette+510),a

          inc de
          djnz cbxwait1
          pop de
          pop bc
          ret
          
;----------------------------------------------------------------------------------------------------

scrolling_message


          ld a,(top_scroll_fine)        ;update scrolling message pointer
          sub 2
          ld b,a
          jr nc,noismp
          ld b,14
          ld hl,(scrolltextpointer)
          inc hl
          inc hl
          ld a,(hl)
          or a
          jr nz,smpir
          ld hl,scroll_text
smpir     ld (scrolltextpointer),hl
noismp    ld a,b
          ld (top_scroll_fine),a
          cp 14
          ret nz    
          
          push hl                       ;shift existing text two chars left (with blitter)
          ld hl,$3130 
          ld b,16
          ld a,$00            
          ld (blit_src_mod),a
          ld (blit_dst_mod),a
nxtblk    ld a,7
          ld (blit_height),a
          ld (blit_src_loc),hl          
          dec h
          ld (blit_dst_loc),hl
          inc h                         ;next blit copy next block
          inc h
          ld a,%01110000                
          ld (blit_misc),a              ;ascending, source msb = 1 dest msb = 1
          ld a,15
          ld (blit_width),a
          call blit_wait
          djnz nxtblk

          pop hl
          ld a,(hl)                     ;new ascii char 
          sub 32
          jr nc,smnw                    ;if => 32 no funny chars
          xor a                         ;anything else, replace with a space
smnw      ld d,a
          ld e,0
          srl d
          jr nc,lschar
          ld e,8
lschar    ld (blit_src_loc),de
          ld de,$4030
          ld (blit_dst_loc),de
          ld a,$08  
          ld (blit_src_mod),a
          ld a,$08
          ld (blit_dst_mod),a
          ld a,7
          ld (blit_height),a
          ld a,7
          ld (blit_width),a
          call blit_wait
          
          inc hl
          ld a,(hl)                     ;2nd new ascii char 
          sub 32
          jr nc,smnw2                   ;if => 32 no funny chars
          xor a                         ;anything else, replace with a space
smnw2     ld d,a
          ld e,0
          srl d
          jr nc,lschar2
          ld e,8
lschar2   ld (blit_src_loc),de
          ld de,$4038
          ld (blit_dst_loc),de
          ld a,7
          ld (blit_height),a
          ld a,7
          ld (blit_width),a
          call blit_wait
          
          
          push hl                       ;mirrored scroller - shift existing text two chars right (with blitter)
          ld hl,$5060 
          ld b,16
          ld a,$00            
          ld (blit_src_mod),a
          ld (blit_dst_mod),a
nxtblk2   ld a,7
          ld (blit_height),a
          ld (blit_src_loc),hl          
          inc h
          ld (blit_dst_loc),hl
          dec h                         ;next blit copy next block
          dec h
          ld a,15
          ld (blit_width),a
          call blit_wait
          djnz nxtblk2

          pop hl
          ld a,(hl)                     ;new ascii char 
          sub 32
          jr nc,smnw3                   ;if => 32 no funny chars
          xor a                         ;anything else, replace with a space
smnw3     ld d,a
          ld e,$80
          srl d
          jr nc,lschar3
          ld e,$88
lschar3   ld (blit_src_loc),de
          ld de,$4160
          ld (blit_dst_loc),de
          ld a,$08  
          ld (blit_src_mod),a
          ld a,$08
          ld (blit_dst_mod),a
          ld a,7
          ld (blit_height),a
          ld a,7
          ld (blit_width),a
          call blit_wait
          
          dec hl
          ld a,(hl)                     ;2nd new ascii char 
          sub 32
          jr nc,smnw4                   ;if => 32 no funny chars
          xor a                         ;anything else, replace with a space
smnw4     ld d,a
          ld e,$80
          srl d
          jr nc,lschar4
          ld e,$88
lschar4   ld (blit_src_loc),de
          ld de,$4168
          ld (blit_dst_loc),de
          ld a,7
          ld (blit_height),a
          ld a,7
          ld (blit_width),a
          call blit_wait
          ret

blit_wait ld a,(vreg_read)              ;wait for blit to complete
          bit 4,a 
          jr nz,blit_wait
          ret
          

;-----------------------------------------------------------------------------------------------

scrolling_tile

          ld hl,$2100                   ;fetch offset tile image for scrolling effect
          ld b,0                        
          ld a,(tile_scroll)
          and $f
          ld c,a
          add hl,bc
          ld d,0
          ld a,(tile_scroll)
          and $f0
          ld e,a
          sla e
          rl d
          add hl,de
          ld (blit_src_loc),hl
          ld hl,$2000
          ld (blit_dst_loc),hl
          ld a,$10            
          ld (blit_src_mod),a
          ld a,$00
          ld (blit_dst_mod),a
          ld a,%01110000                ;ascending, source msb = 1 dest msb = 1
          ld (blit_misc),a
          ld a,15
          ld (blit_height),a
          ld a,15
          ld (blit_width),a             ;copy to fixed tile with blitter        
          call blit_wait

          ld a,(tile_scroll)
          add a,$11
          jr nc,tsc_ok
          xor a
tsc_ok    ld (tile_scroll),a
          ret
                    
;-----------------------------------------------------------------------------------------------

write_in_highscore
          
          
          ld hl,score                   ;compare score to highscore
          ld de,highscore
          ld b,6
tsthslp   ld a,(de)
          cp (hl)
          jr c,bigger
          jr nz,blit_highscore
          inc hl
          inc de
          djnz tsthslp
          jr blit_highscore

bigger    ld hl,score
          ld de,highscore
          ld bc,6
          ldir
                    
          
blit_highscore
          
          ld a,8              
          ld (blit_src_mod),a           ;set unchanging blit registers
          ld (blit_dst_mod),a
          ld a,%01110000
          ld (blit_misc),a              ;ascending, src+dst msb = 1
                    
          ld ix,highscore               ;put characters in high score block defs
          ld de,$5960                   
          ld b,6                        ;6 chars to do
wihslp    ld l,0
          ld a,(ix)
          srl a
          jr nc,lmfig
          ld l,8
lmfig     add a,$25
          ld h,a
          call blit_fig
          ld a,e
          xor 8
          bit 3,a 
          jr nz,sameblk
          inc d
sameblk   ld e,a
          inc ix
          djnz wihslp
          ret

blit_fig  ld (blit_src_loc),hl          
          ld (blit_dst_loc),de
          ld a,7
          ld (blit_height),a
          ld (blit_width),a
          call blit_wait
          ret


;-----------------------------------------------------------------------------------------------

test_cheat

          ld hl,cheat_count
          in a,(sys_joy_com_flags)
          ld b,a
          bit 5,b
          jr nz,jtestch
          ld (hl),0
          ret
jtestch   bit 0,(hl)
          jr z,tleft
          bit 3,b
          ret z
chcoinc   inc (hl)
          ld a,(hl)
          cp 16
          ret nz
          ld a,1
          ld (cheat),a
          ret

tleft     bit 2,b
          jr nz,chcoinc
          ret       
                    

                    
;======== "LOADING" LOGO ROUTINES ======================================================================

fade_out_loading
          
          di
          ld a,$ff                      ;assumes fade_in_loading has been called 
          ld (fade_dir),a               ;previously (ie: does not set up display etc)
          ld a,$1e
          ld (fade_level),a
          xor a
          ld (faded_in),a
          ld (faded_out),a
          jr ldng_wvrt

;--------------------------------------------------------------------------------------

fade_in_loading
          
          di

;--------- Init System settings for "LOADING" -------------------------------------------

          ld a,%00001101                
          ld (vreg_vidctrl),a           ; tile mode / video inhibited
          xor a
          ld (vreg_rasthi),a            ; use y window pos reg
          ld a,$2e                                
          ld (vreg_window),a            ; 256 line display
          ld a,%00000100                
          ld (vreg_rasthi),a            ; Switch to x window pos reg.
          ld a,$aa                      
          ld (vreg_window),a            ; Window Width = 256 pixels with wideborder
          
          call zero_palette
          ld hl,loading_colours         ; fade routine to use game palette
          ld (colour_base),hl
          ld a,$1
          ld (fade_dir),a
          xor a
          ld (fade_level),a
          ld (faded_in),a
          ld (faded_out),a
          
          call wipe_sprites             ; wipe sprite registers
          ld hl,spr_registers           
          ld (hl),$10                   ; set up "loading" sprite rgisters
          inc hl
          ld (hl),$31
          inc hl
          ld (hl),$80
          inc hl
          ld (hl),$b5
          inc hl
          ld (hl),$20
          inc hl
          ld (hl),$31
          inc hl
          ld (hl),$80
          inc hl
          ld (hl),$b8
          inc hl
          ld (hl),$30
          inc hl
          ld (hl),$31
          inc hl
          ld (hl),$80
          inc hl
          ld (hl),$bb
                    
          ld a,%00000001                ; global sprite enable
          ld (vreg_sprctrl),a


;--------------------------------------------------------------------------------------
          
ldng_wvrt call wait_vrt
          
          ld hl,0
          ld bc,32
          call palette_fade
          call update_fade    
          call update_fade              ;double speed fade
          
          ld a,(faded_out)              
          or a
          ret nz
          ld a,(faded_in)
          or a
          ret nz
          
          jr ldng_wvrt                  
                    
;======== END OF "LOADING" LOGO SECTION ======================================================


;--------------------------------------------------------------------------------------------
; CONGRATULATIONS - GAME COMPLETE CODE
;--------------------------------------------------------------------------------------------

congratulations

;--------- Load Star Sprites ------------------------------------------------------------------------
          
          di
          ld hl,star_sprites_fn         ;filename loc
          ld de,$1                      ;destination sprite block
          call load_sprite_data
          jp nz,load_error


;--------- Load Star Tiles ------------------------------------------------------------------------

          ld hl,congrats_tiles_fn       ;filename loc
          ld c,8                        ;destination video bank (tile set 1)
          ld b,2                        ;number of 8KB chunks
          call load_tile_data
          jp nz,load_error

;--------- Init Game Video + System settings -------------------------------------------------------------


          ld a,%00001001                
          ld (vreg_vidctrl),a           ; tile mode / playfield A uses tile set B / wideborder
          xor a
          ld (vreg_rasthi),a            ; use y window pos reg
          ld a,$2e                                
          ld (vreg_window),a            ; 256 line display
          ld a,%00000100                
          ld (vreg_rasthi),a            ; Switch to x window pos reg.
          ld a,$aa                      
          ld (vreg_window),a            ; Window Width = 256 pixels with wideborder
          
          call zero_palette
          ld hl,star_colours            ; fade routine to use congrats palette
          ld (colour_base),hl
          ld a,$1
          ld (fade_dir),a
          xor a
          ld (fade_level),a
          ld (faded_in),a
          ld (faded_out),a
          
          call wipe_sprites             ; wipe sprite registers
          ld a,%00000011                ; global sprite enable / interleave mode
          ld (vreg_sprctrl),a
          ld a,0
          out (sys_ps2_joy_control),a   ; select joystick A

          ld b,56                       ; initial random star positions z,x,y coords
          ld ix,src_z_coords
nxtrndco  call rand16
          set 4,h
          ld (ix),h
          call rand16
          set 4,h
          set 4,l
          ld (ix+56),h
          ld (ix+112),l
          inc ix
          djnz nxtrndco

          xor a
          ld (vreg_vidpage),a           ;select video page 0 to access tile maps
          
          call kjt_page_in_video        ;clear tile maps
          ld hl,video_base
          ld bc,$800
cwmaplp   ld (hl),0
          inc hl
          dec bc
          ld a,b
          or c
          jr nz,cwmaplp

          ld hl,congrats_map            ;copy title screen map to video memory
          ld de,video_base
          ld a,15
ccpytmap  ld bc,$10
          ldir
          ex de,hl
          ld bc,$10
          add hl,bc
          ex de,hl
          dec a
          jr nz,ccpytmap

          call kjt_page_out_video


          ld hl,$c000
          ld (force_sample_base),hl     
          call init_tracker             ;initialize mod with forced sample_base
          ld a,6
          ld (songspeed),a              ;speed for title tune
          ld a,9
          ld (songpos),a                ;play last section of title tune
          ld a,10
          ld (music_module+950),a       ;force end of song position for title tune
          ld a,1
          ld (chan_1_enable),a          ;all channels in use


;--------------------------------------------------------------------------------------
          

cg_wvrt   call wait_vrt
          
          call coords_to_sprites        ;this is offscreen (double buffer not required)
          call congrats_fade
          call star_routine             ;call routine

          call play_tracker   
          call update_sound_hardware

          ld a,(faded_out)              
          or a
          jr z,cg_wvrt
                    
          jp title_screen               
          
          
;--------------------------------------------------------------------------------------

congrats_fade

          ld hl,0
          ld bc,32
          call palette_fade
          ld hl,128
          ld bc,32
          call palette_fade
          call update_fade
          
          ld a,(fade_dir)               ;press fire start game (init palette fade)
          or a                          ;only check if not fading
          ret nz
          in a,(sys_joy_com_flags)                
          and 16                        
          ret z
          ld a,$ff
          ld (fade_dir),a
          ret
          
;--------------------------------------------------------------------------------------   

star_routine


          ld b,56                       ;number of stars
          ld ix,src_z_coords
          ld iy,dst_xy_coords
star_loop ld a,(ix)                     ;z coord
          add a,4                       ;increase star's z coord      
          jr nc,nonewstar               ;if out of range, reset it and create random star position
          call rand16
          set 4,h
          set 4,l
          ld (ix+56),h                  ;new x ccord
          ld (ix+112),l                 ;new y coord
          ld a,32                       ;initial z coord 
nonewstar ld (ix),a
          ld e,a                        ;z scale factor
          ld h,(ix+56)                  ;x coord
          call multiply                 
          ld (iy),h                     ;scaled x
          ld e,(ix)                     ;z scale factor
          ld h,(ix+112)                 ;y coord
          call multiply
          ld (iy+56),h                  ;scaled y
          inc ix
          inc iy
          djnz star_loop                ;loop
          ret



coords_to_sprites

          ld iy,dst_xy_coords
          ld ix,spr_registers
          ld b,56
nxtcts    ld l,(iy)                     ; star x coord
          ld h,0
          bit 7,l
          jr z,stnotn1
          dec h
stnotn1   ld de,$118                    ;centre of screen x
          add hl,de
          ld (ix),l                     ; spr x coord LSB
          ld a,h                        ; save the MSB
          ld l,(iy+56)                  ; star y coord
          ld h,0
          bit 7,l
          jr z,stnotn2
          dec h
stnotn2   ld de,$78                     ;centre of screen y
          add hl,de           
          ld (ix+2),l                   ; spr y coord LSB
          sla h                         ; shift y coord MSb left
          or h                          ; merge with x MSb
          or $10                        ; merge in spr height
          ld (ix+1),a                   ; spr height / msbs
          ld a,(iy+112)                 ; star z coord
          srl a
          srl a
          srl a
          srl a
          srl a
          add a,$01
          ld (ix+3),a                   ; spr def
          inc iy
          ld de,4
          add ix,de
          djnz nxtcts
          ret
          
          
;----------------------------------------------------------------------------------------------------
          
multiply  bit 7,h
          jr nz,signed
          ld l,0                        ; scale H by E, result in H
          ld d,l
          sla h               
          jr nc,muliter1
          ld l,e
muliter1  add hl,hl           
          jr nc,muliter2      
          add hl,de           
muliter2  add hl,hl           
          jr nc,muliter3      
          add hl,de           
muliter3  add hl,hl           
          jr nc,muliter4      
          add hl,de           
muliter4  add hl,hl           
          jr nc,muliter5      
          add hl,de           
muliter5  add hl,hl           
          jr nc,muliter6      
          add hl,de           
muliter6  add hl,hl           
          jr nc,muliter7      
          add hl,de           
muliter7  add hl,hl           
          jr nc,muliter8      
          add hl,de           
muliter8  ret
          
                    
signed    ld a,h
          neg
          ld h,a
          ld l,0    
          ld d,l
          sla h               
          jr nc,muliter1b
          ld l,e
muliter1b add hl,hl           
          jr nc,muliter2b     
          add hl,de           
muliter2b add hl,hl           
          jr nc,muliter3b     
          add hl,de           
muliter3b add hl,hl           
          jr nc,muliter4b     
          add hl,de           
muliter4b add hl,hl           
          jr nc,muliter5b     
          add hl,de           
muliter5b add hl,hl           
          jr nc,muliter6b     
          add hl,de           
muliter6b add hl,hl           
          jr nc,muliter7b     
          add hl,de           
muliter7b add hl,hl           
          jr nc,muliter8b     
          add hl,de           
muliter8b ld a,h
          neg
          ld h,a
          ret       
                    
;---------------------------------------------------------------------------------------------------


rand16    ld        de,(seed)           
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
          jr        nc,rand
          inc       hl
rand      ld        (seed),hl           
          ret
          
          
;---------------------------------------------------------------------------------------------      
; END OF CONGRATS CODE
;---------------------------------------------------------------------------------------------


load_tile_data

;Set hl= filename loc
;    c = destination video bank
;    b = number of 8KB chunks to load

;ZF set on return if all OK
          
          push bc
          call kjt_find_file
          pop bc
          ret nz

vloadloop ld a,c
          ld (vreg_vidpage),a 
          push bc
          ld ix,$0000
          ld iy,$2000
          call kjt_set_load_length
          ld hl,load_buffer
          ld a,load_buffer_bank
          ld b,a
          call kjt_force_load
          jr z,vdlok
          pop bc
          ret
          
vdlok     call kjt_getbank
          ld (bank_cache),a
          ld a,load_buffer_bank
          call kjt_forcebank  
          call kjt_page_in_video        
          
          ld hl,load_buffer
          ld de,video_base
          ld bc,256*32                  ;copy 32 tiles to vram page (8192 bytes)
          ldir
          
          call kjt_page_out_video
          ld a,(bank_cache)
          call kjt_forcebank  
          
          pop bc
          inc c
          djnz vloadloop
          xor a
          ret

;---------------------------------------------------------------------------------------------      

load_sprite_data

;Set hl = filename loc
;    de = destination sprite block $0-$1FF

;ZF set on return if all OK
          
          ld (sp_dest_block),de
          call kjt_find_file
          ret nz
          ld (sp_filesize_hi),ix
          ld (sp_filesize_lo),iy
          
sloadloop ld hl,(sp_filesize_hi)
          ld de,(sp_filesize_lo)
          ld a,h
          or l
          or d
          or e
          ret z
          ld ix,$0000                   ;default: load 8KB of sprites
          ld iy,$2000
          ld a,h
          or l
          jr nz,spfsok                  ;if (remaining) filesize > 64KB, use 8KB load
          ld a,d
          and $e0
          jr nz,spfsok                  ;if (remaining) filesize > 8KB use 8KB load
          push de                       ;else adjust load size to remaining bytes
          pop iy
spfsok    push iy                       ;MSB of this word = number of sprites to copy from buffer
          call kjt_set_load_length
          ld hl,load_buffer
          ld b,load_buffer_bank
          call kjt_force_load
          jr z,sdlok
          pop iy                        ;if load failed, purge the stack before return
          ret
          
sdlok     ld de,(sp_dest_block)
          ld hl,load_buffer
          call kjt_getbank
          ld (bank_cache),a
          ld a,load_buffer_bank
          call kjt_forcebank  
          pop bc                        ;get word from pushed IY, B = sprites to transfer
          xor a
          or b
          jr z,overspill                ;in case sprite file is not a multiple of 256 bytes
sprcoplp  call copy_sprite
          djnz sprcoplp                 
          
overspill ld a,(bank_cache)
          call kjt_forcebank  
          ld (sp_dest_block),de

          ld hl,(sp_filesize_lo)        ;subtract 8KB from file size
          ld bc,$2000
          xor a
          sbc hl,bc
          ld (sp_filesize_lo),hl
          jp nc,sloadloop
          ld de,(sp_filesize_hi)
          ld a,d
          or e
          jr nz,sp_mbtl                 ;if hi word is already 0, all sprites loaded/copied
          xor a
          ret
sp_mbtl   dec de
          ld (sp_filesize_hi),de
          jp sloadloop


copy_sprite

;hl = source address
;de = dest sprite block ($0-$1ff)
;output: hl=hl+$100, de=de+$1

sprbnklp  push de
          push bc
          in a,(sys_mem_select)
          or %10000000
          out (sys_mem_select),a        ;page in sprite RAM

          ld a,e
          and 15
          add a,sprite_base/256         
          push af
          srl d
          rr e
          srl d
          rr e
          srl d
          rr e
          srl d
          rr e
          ld a,e
          or $80
          ld (vreg_vidpage),a           ;set dest bank 0-1F for sprite
          pop af
          ld e,0
          ld d,a                        ;set dest address $1000 to $1f00
          ld bc,256                     
          ldir                          ;copy a sprite to sprite RAM
          
          in a,(sys_mem_select)
          and %01111111
          out (sys_mem_select),a        ;page out sprite RAM 
          pop bc
          pop de
          inc de
          ret
          
;---------------------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------------------    

load_level
          
          ld a,(level)                  ;get level number, convert hex to ascii for filenames
          ld b,a
          rrca 
          rrca
          rrca
          rrca
          and $f
          add a,$30
          cp $3a
          jr c,hexok1
          add a,7
hexok1    ld (bgmap_fn+6),a
          ld (fgmap_fn+6),a
          ld (trigs_fn+6),a
          ld a,b
          and $f
          add a,$30
          cp $3a
          jr c,hexok2
          add a,7
hexok2    ld (bgmap_fn+7),a
          ld (fgmap_fn+7),a
          ld (trigs_fn+7),a
          
          ld hl,level_data
          ld (bg_map_base),hl
          ld hl,bgmap_fn
          call kjt_find_file
          jr nz,levloaderr
          push iy
          pop bc
          ld hl,(bg_map_base)
          add hl,bc
          jr c,levloaderr
          ld (fg_map_base),hl
          ld hl,(bg_map_base)
          ld b,1
          call kjt_force_load
          jr nz,levloaderr
          
          ld hl,fgmap_fn
          call kjt_find_file
          jr nz,levloaderr
          push iy
          pop bc
          ld hl,(fg_map_base)
          add hl,bc
          jr c,levloaderr
          ld (trig_base),hl
          ld hl,(fg_map_base)
          ld b,1
          call kjt_force_load
          jr nz,levloaderr

          ld hl,trigs_fn
          call kjt_find_file
          jr nz,levloaderr
          push iy
          pop bc
          ld hl,(trig_base)
          add hl,bc
          jr c,levloaderr
          ld hl,(trig_base)
          ld b,1
          call kjt_force_load
          jr nz,levloaderr
          ret


levloaderr

          ld hl,$000f                   ;loading error = screen goes red
          ld (palette),hl
stop_here jr stop_here


;---------------------------------------------------------------------------------------------------------    
; GENERIC ROUTINES USED BY BOTH GAME AND TITLE SCREEN 
;---------------------------------------------------------------------------------------------------------

wipe_sprites

          xor a
          ld hl,spr_registers
          ld b,0
wipsprlp  ld (hl),a
          inc hl
          ld (hl),a
          inc hl
          djnz wipsprlp
          ret
          
;---------------------------------------------------------------------------------------------------------    
          
zero_palette
          
          ld hl,palette                 ; entire palette = $000
          ld b,0
          xor a
clrpallp  ld (hl),a
          inc hl
          ld (hl),a
          inc hl
          djnz clrpallp
          ret

;---------------------------------------------------------------------------------------------------------    

wait_vrt  ld a,(vreg_read)              ;wait for VRT
          and 1
          jr z,wait_vrt
wvrtend   ld a,(vreg_read)
          and 1
          jr nz,wvrtend                 
          ret
          
;---------------------------------------------------------------------------------------------------------    

palette_fade

;set hl = first colour number 0-255
;    bc = number of colours (must be even)


          ld a,(fade_dir)               ;fade = 1, rise.. fade = -1 fall
          or a
          ret z                         ;if fade = 0, no fade
          
          ld (fade_count),bc  
          add hl,hl
          push hl
          ld de,palette
          add hl,de
          ex de,hl
          pop hl
          ld bc,(colour_base)
          add hl,bc
          push hl
          pop bc
          
          ld a,(fade_level)             ;fades in two parts to save raster time
          srl a                         ;half the palette on alternate frames
          jr nc,fadeset1

          ld hl,(fade_count)
          add hl,de
          ex de,hl
          ld hl,(fade_count)
          add hl,bc
          push hl
          pop bc

fadeset1  ld ix,fade_index
          rrca
          rrca
          rrca
          rrca
          and $f0
          ld (ix),a
          ld h,scale_table/256
          
          exx
          ld bc,(fade_count)            ;colours to fade
          srl b
          rr c
          ld b,c
fade_lp   exx

          ld a,(bc)                     ;green
          rrca
          rrca
          rrca
          rrca
          and $f
          or (ix)
          ld l,a
          ld a,(hl)
          rrca
          rrca
          rrca
          rrca
          ld (fade_temp),a
                    
          ld a,(bc)                     ;blue
          and $f
          or (ix)
          ld l,a
          ld a,(fade_temp)
          or (hl)
          ld (de),a
          inc bc
          inc de

          ld a,(bc)                     ;red
          or (ix)
          ld l,a
          ld a,(hl)
          ld (de),a
          inc bc
          inc de

          exx
          djnz fade_lp
          ret
          

update_fade

          ld a,(fade_dir)
          bit 7,a
          jr nz,fade_dwn

          ld a,(fade_level)             ;inc fade level $00=black, $1F = full levels
          cp $1f
          jr z,donefi
          inc a
          ld (fade_level),a
          ret
donefi    xor a
          ld (fade_dir),a
          ld a,1
          ld (faded_in),a     
          ret

fade_dwn  ld a,(fade_level)             ;dec fade level $00=black, $1F = full levels
          or a
          jr z,donefo
          dec a
          ld (fade_level),a
          ret
donefo    ld (fade_dir),a
          ld a,1
          ld (faded_out),a
          ret

;---------------------------------------------------------------------------------------------------------

silence_audio

          ld a,%00000000                 
          out (sys_audio_enable),a      ; Silence audio
          xor a
          ld b,a
          ld d,16
          ld c,audchan0_loc
clrsndlp  out (c),a
          inc c
          dec d
          jr nz,clrsndlp
          ret       


;---------------------------------------------------------------------------------------------------------

include "FLOS_based_programs\games\Bounder\inc\object_list.asm"

;---------------------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------------------    
; Game Variables and data
;---------------------------------------------------------------------------------------------------------    

hs_filename         db "HISCORE.BIN",0  
bg_tiles_fn         db "TILE_BG.BIN",0
fg_tiles_fn         db "TILE_FG.BIN",0
null_sprite_fn      db "SPR_NULL.BIN",0 
global_sprites_fn   db "SPR_GBL.BIN",0
enemy_sprites_fn    db "SPR_NME.BIN",0

bgmap_fn            db "BGMAP_00.BIN",0
fgmap_fn            db "FGMAP_00.BIN",0
trigs_fn            db "TRIGS_00.BIN",0

colour_base         dw 0
seed                dw 0

variables_start

spr_reg_base                  dw 0
bg_map_base                   dw 0
fg_map_base                   dw 0
trig_base                     dw 0

counter                       db 0

scroll_active                 db 0
end_of_map                    db 0 
recommence_scroll             db 0
end_of_level                  db 0
game_over                     db 0

bg_map_pos_y_pixel            db 0
bg_map_pos_y_block            dw 0                
bg_map_buffer                 db 0
fg_map_pos_y_pixel            db 0
fg_map_pos_y_block            dw 0                
fg_map_buffer                 db 0

map_dest_base                 db 0
map_src_base                  dw 0
map_pos_y                     dw 0
map_slice                     db 0

sp_dest_block                 dw 0
sp_filesize_hi                dw 0
sp_filesize_lo                dw 0

sprite_max                    dw 0

origin_x                      dw 0
origin_y                      dw 0

level                         db 0
lives                         db 0
score                         ds 6,0
score_addvalue                ds 6,0
jumps_lsd                     db 0
jumps_msd                     db 0

ball_frame                    db 1
ball_anim_delay               db 0
ball_x                        dw 0
ball_y                        dw 0
ball_status                   db 0
super_bounce                  db 0
old_ball_x                    db 0
old_ball_y                    db 0
map_moved                     db 0
ball_speed                    db 0
ball_bump                     db 0
ball_bump_dir                 db 0
ball_shield                   db 0
rebound_frame                 db 0

ball_land_aggregate           db 0
tile_under_ball               db 0
active_tile_mapaddr           dw 0
active_tile_x                 db 0
active_tile_y                 db 0
trig_high_bounce              db 0
sprite_tile_colis             db 0

prev_change_block_addr1       dw 0
prev_change_block_addr2       dw 0
prev_change_block_addr3       dw 0
prev_change_block_addr4       dw 0

ball_finaly                   dw 0
ball_finalx                   dw 0
ball_exp_air_offset           dw 0
ball_exp_air_frame            db 0
ball_exp_air_delay            db 0
ball_fall_exp_w               dw 0

sinking_ball_frame            db 0
sinking_ball_anim_delay       db 0

x_enemy_origin                dw 0
y_enemy_origin                dw 0

rock_list_index               db 0

bonus_round_tile_locations    ds 64,0
bonus_round                   db 0
bonus_round_step              db 0
bonus_round_bonus_level       db 0
bonus_round_tile_count        db 0
bonus_round_end               db 0
bonus_round_new_bonus_level   db 0
bonus_tiles_hit               db 0
game_start_delay              db 0

bonusob_select                db 0                          ;bonus object stuff
bonusob1                      ds 8,0
bonusob2                      ds 8,0
bonusob3                      ds 8,0
bonusob4                      ds 8,0

tile_anim_count1              db 0                          ;for animated tiles
tile_anim_max1                db 0
tile_anim_tile1               db 0
tile_anim_count2              db 0
tile_anim_max2                db 0
tile_anim_tile2               db 0
tile_anim_count3              db 0
tile_anim_max3                db 0
tile_anim_tile3               db 0
tile_anim_count4              db 0
tile_anim_max4                db 0
tile_anim_tile4               db 0

search_scroll                 db 0
glow_index                    db 0
wiggle_index                  db 0
wiggle_applied                db 0
block_swap_offset             dw 0
block_swap_value              db 0
cheat_count                   db 0

variables_end

cheat                         db 0

;-----------------------------------------------------------------------------------------------

bobtype             equ 0
bobstatus           equ 1
bobframe            equ 2
bobanimdelay        equ 3
bobtimer            equ 4
bob_x               equ 5
bob_y               equ 6
bobmisc             equ 7

bobinitframelist    db $00,$2f,$30,$31,$32,$33,$35,$37,$98,$99,$9a,$9b

score_addlist       db 0,0,0,1,0,0,0,0                      ;last two bytes are padding
                    db 0,0,0,2,0,0,0,0
                    db 0,0,0,5,0,0,0,0
                    db 0,0,1,0,0,0,0,0
                    
;-----------------------------------------------------------------------------------------------

enemy_list          ds 256,0                      ;16 resources * 16 bytes

enemy_status        equ $0
enemy_type          equ $1
enemy_xlsb          equ $2
enemy_xmsb          equ $3
enemy_ylsb          equ $4
enemy_ymsb          equ $5
enemy_frame         equ $6
enemy_animtimer     equ $7
enemy_framecounter  equ $8
enemy_misc_1        equ $9
enemy_misc_2        equ $a
enemy_misc_3        equ $b
enemy_misc_4        equ $c
enemy_misc_5        equ $d
enemy_misc_6        equ $e
enemy_control       equ $f                        ;control bits: bit 0 = use simple animation, 1 = scroll with screen
                                                  ;              bit 2 = backwards animation, bit 3 = priority (1 = above ball)
                                                  ;              bit 4 = one shot animation (then switch obj off)
                                                  ;              bit 5 = exists until 8 blocks out of screen, 6 = ping pong anim

;---------------------------------------------------------------------------------------------------------

enemy_inits
                    
; 0=x offset, 1=y offset, 2=control bits, 3=anim base frame, 4=no.of frames, 5=anim speed

          db $00,$00,$09,$39,$06,$05,$00,$00      ;trig $10 (bird)
          db $02,$ff,$03,$3f,$04,$02,$00,$00      ;trig $11 (right fan)
          db $fc,$ff,$03,$43,$04,$02,$00,$00      ;trig $12 (left fan)
          db $00,$00,$03,$47,$06,$03,$00,$00      ;trig $13 (teleport in)
          db $00,$00,$07,$47,$06,$03,$00,$00      ;trig $14 (teleport out)
          db $00,$00,$02,$4d,$08,$06,$00,$00      ;trig $15 (bumper right)
          db $00,$00,$02,$55,$08,$06,$00,$00      ;trig $16 (bumper left)
          db $ff,$00,$03,$5d,$0c,$02,$00,$00      ;trig $17 (drill)
          
          db $00,$00,$43,$cc,$03,$05,$00,$00      ;trig $18 (bobbing mine - main)
          db $00,$00,$02,$6a,$01,$00,$00,$00      ;trig $19 (small mine NW)
          db $00,$00,$02,$6a,$01,$00,$00,$00      ;trig $1a (small mine NE)
          db $00,$00,$02,$6a,$01,$00,$00,$00      ;trig $1b (small mine SW)
          db $00,$00,$02,$6a,$01,$00,$00,$00      ;trig $1c (small mine SE)
          db $00,$00,$02,$6e,$01,$00,$00,$00      ;trig $1d (horizontal laser turrets)
          db $00,$00,$03,$6f,$03,$03,$00,$00      ;trig $1e (laser blast)
          db $00,$00,$0b,$72,$08,$04,$00,$00      ;trig $1f (active bone-a-rang r)
          
          db $00,$00,$0b,$72,$08,$04,$00,$00      ;trig $20 (active bone-a-rang l)
          db $00,$00,$03,$7a,$03,$03,$00,$00      ;trig $21 (tank right)
          db $00,$00,$03,$a6,$03,$03,$00,$00      ;trig $22 (tank left)
          db $e8,$00,$0b,$b8,$06,$03,$00,$00      ;trig $23 (active dart right)
          db $18,$00,$0b,$d4,$06,$03,$00,$00      ;trig $24 (active dart left)
          db $06,$00,$02,$80,$01,$01,$00,$00      ;trig $25 (cannon right)
          db $08,$00,$02,$81,$01,$01,$00,$00      ;trig $26 (cannon left)
          db $18,$00,$0a,$82,$01,$00,$00,$00      ;trig $27 (cannon ball right)
          
          db $e8,$00,$0a,$82,$01,$00,$00,$00      ;trig $28 (cannon ball left)
          db $00,$00,$13,$11,$06,$03,$00,$00      ;trig $29 (enemy_smoke)
          db $00,$00,$09,$83,$03,$02,$00,$00      ;trig $2a (rocket)
          db $00,$00,$23,$a9,$06,$02,$00,$00      ;trig $2b (patroller right)
          db $00,$00,$23,$a9,$06,$02,$00,$00      ;trig $2c (patroller left)
          db $00,$00,$02,$87,$01,$01,$00,$00      ;trig $2d (moving tile)
          db $00,$00,$02,$00,$01,$01,$00,$00      ;trig $2e (volcano)
          db $00,$00,$0b,$88,$05,$03,$00,$00      ;trig $2f (hot rock)
          
          db $00,$00,$03,$d2,$01,$01,$00,$00      ;trif $30 (orb_turret)
          db $00,$00,$0b,$94,$04,$01,$00,$00      ;trig $31 (glowing orb)
          db $00,$00,$09,$9d,$01,$01,$00,$00      ;trig $32 ("start" text)
          db $00,$00,$09,$9e,$02,$08,$00,$00      ;trig $33 ("bonus round" text)
          db $00,$00,$09,$a0,$01,$01,$00,$00      ;trig $34 ("jump bonus" text)
          db $00,$00,$09,$a1,$01,$01,$00,$00      ;trig $35 ("00000" text)
          db $00,$01,$03,$a2,$02,$0c,$00,$00      ;trig $36 ("GOAL" text)
          db $00,$00,$09,$a4,$01,$01,$00,$00      ;trig $37 ("GAME" text)
          
          db $00,$00,$09,$a5,$01,$01,$00,$00      ;trig $38 ("OVER" text)
          db $00,$00,$03,$af,$06,$02,$00,$00      ;trig $39 (slime right)
          db $00,$00,$07,$af,$06,$02,$00,$00      ;trig $3a (slime left)
          db $00,$00,$02,$b5,$03,$04,$00,$00      ;trig $3b (breakaway tile)
          db $00,$00,$23,$a9,$06,$02,$00,$00      ;trig $3c (patroller up)
          db $00,$00,$23,$a9,$06,$02,$00,$00      ;trig $3d (patroller down)
          db $00,$08,$03,$af,$06,$02,$00,$00      ;trig $3e (slime right - centred)
          db $00,$08,$07,$af,$06,$02,$00,$00      ;trig $3f (slime left - centred)
          
          db $00,$00,$03,$00,$01,$01,$50,$44      ;trig $40 (sea launched missile - delayed start)
          db $00,$00,$03,$c4,$02,$02,$00,$00      ;trig $41 (sea launched missile active)
          db $00,$00,$43,$c6,$06,$02,$00,$00      ;trig $42 (snappy tile)
          db $00,$00,$03,$cf,$03,$02,$00,$00      ;trig $43 (spinny vent fan thing)
          db $00,$00,$03,$be,$08,$03,$00,$00      ;trig $44 (sea launched missile launch phase)
          db $00,$00,$13,$1e,$07,$04,$00,$00      ;trig $45 (generic one shot large explosion)
          db $00,$00,$1b,$da,$04,$03,$00,$00      ;trig $46 (small shot blast)
          db $e0,$00,$03,$00,$01,$01,$30,$1f      ;trig $47 (bone from left - delay start: 30)
          
          db $20,$00,$03,$00,$01,$01,$30,$20      ;trig $48 (bone from right - delay start: 30)
          db $e0,$00,$03,$00,$01,$01,$50,$1f      ;trig $49 (bone from left - delay start: 50)
          db $20,$00,$03,$00,$01,$01,$50,$20      ;trig $4a (bone from right - delay start: 50)
          db $e0,$00,$03,$00,$01,$01,$70,$23      ;trig $4b (dart from left - delay start: 70)
          db $20,$00,$03,$00,$01,$01,$70,$24      ;trig $4c (dart from right - delay start: 70)
          db $e0,$00,$03,$00,$01,$01,$a0,$23      ;trig $4d (dart from left - delay start: a0)
          db $20,$00,$03,$00,$01,$01,$a0,$24      ;trig $4e (dart from right - delay start: a0)
          db $00,$08,$03,$7a,$03,$03,$00,$00      ;trig $4f (tank right - y centred)

          db $00,$08,$03,$a6,$03,$03,$00,$00      ;trig $50 (tank left - y rcentred)
          db $00,$00,$03,$de,$06,$02,$00,$00      ;trig $51 (slime down)
          db $00,$00,$07,$de,$06,$02,$00,$00      ;trig $52 (slime up)
          db $e0,$00,$03,$00,$01,$01,$10,$23      ;trig $53 (dart from left - delay start: ball y trigger)
          db $20,$00,$03,$00,$01,$01,$10,$24      ;trig $54 (dart from right - delay start: ball y trigger)
          db $f8,$00,$07,$47,$06,$03,$00,$00      ;trig $55 (teleport out - uncentred)
          db $08,$00,$03,$de,$06,$02,$00,$00      ;trig $56 (slime down-centered)
          db $08,$00,$07,$de,$06,$02,$00,$00      ;trig $57 (slime up-centered)
          
          db $08,$00,$09,$83,$03,$02,$00,$00      ;trig $58 (rocket - centred)


last_enemy                    equ $59


enemy_init_xoffset            equ 0
enemy_init_yoffset            equ 1
enemy_init_controlbits        equ 2
enemy_init_baseframe          equ 3
enemy_init_framecount         equ 4
enemy_init_animspeed          equ 5
enemy_init_spawn_where        equ 6
enemy_init_spawn_what         equ 7

;------------------------------------------------------------------------------------------------

enemy_routines      dw enemy_bird, enemy_rightfan, enemy_leftfan, teleport_in
                    dw teleport_out,bumper_right,bumper_left, enemy_drill

                    dw enemy_mine_main, small_mine_nw, small_mine_ne, small_mine_sw
                    dw small_mine_se, laser_turrets, laser_blast, enemy_bone_a_rang_r

                    dw enemy_bone_a_rang_l, enemy_tankr, enemy_tankl, dart_right
                    dw dart_left, cannon_right, cannon_left, cannonball_right

                    dw cannonball_left, enemy_smoke, enemy_rocket, enemy_patroller_right
                    dw enemy_patroller_left, moving_tile, enemy_volcano, enemy_hotrock

                    dw enemy_orbturret, enemy_glowball, start_text, bonus_round_text
                    dw start_text, bonus_score_text, goal_text, game_text

                    dw over_text, enemy_slimer, enemy_slimel, breakaway_tile
                    dw enemy_patroller_up, enemy_patroller_down, enemy_slimer, enemy_slimel
                    
                    dw enemy_y_start, enemy_sea_missile, enemy_snappy_tile, enemy_vent_fan
                    dw enemy_sea_missile_launching, no_action, no_action, enemy_y_start

                    dw enemy_y_start, enemy_y_start, enemy_y_start, enemy_y_start
                    dw enemy_y_start, enemy_y_start, enemy_y_start, enemy_tankr
                    
                    dw enemy_tankl, enemy_slimed, enemy_slimeu, enemy_ball_triggered
                    dw enemy_ball_triggered, teleport_out,  enemy_slimed, enemy_slimeu
                    
                    dw enemy_rocket
                    
;------------------------------------------------------------------------------------------------

square_table

                    db 0,1,4,9,16,25,36,49,64,81,100,121,144,169,196,225

ball_squared_radius_list

                    db 0,81,100,121,144,121,100,81,64                 ;per frame number
                    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    db 169,196,225,255,225,196,169 
          
;-------------------------------------------------------------------------------------------------

enemy_col_base_x    dw 0
enemy_col_base_y    dw 0

collision_list      dw birdcolispts, rfancolispts, lfancolispts, burightcolispts
                    dw buleftcolispts, drillcolispts, minecolispts, lasercolispts
                    dw bone1_colispts,bone2_colispts,bone3_colispts,bone4_colispts
                    dw bone5_colispts,bone6_colispts,bone7_colispts,bone8_colispts
                    dw tankcolispts,seamislcolispts, dartcolispts, rocketcolispts
                    dw snappycolispts, slimecolispts, tilecolispts, ventcolispts
                    dw dartlcolispts,vslimecolispts
                    

birdcolispts        db 5, -15,0, 0,-12, 15,0, 0,12, 0,0               ;0 [number of points to check, point offsets x,y]
rfancolispts        db 5, 20,-12, 20,0, 20,12, 4,-8, 4,8              ;1
lfancolispts        db 5, -20,-12, -20,0, -20,12, -4,-8, -4,8         ;2
burightcolispts     db 2, 20,0, 24,0                                  ;3
buleftcolispts      db 2, -24,0, -20,0                                ;4
drillcolispts       db 1, 0,0                                         ;5 
minecolispts        db 5, -8,-8, 8,-8, 8,-8, 8,8, 0,0                 ;6 <- main mine
lasercolispts       db 4, -24,0, -8,0, 8,0, 24,0                      ;7
bone1_colispts      db 2, 0,-14, 0,14                                 ;8
bone2_colispts      db 2, 4,-13,-4,13                                 ;9
bone3_colispts      db 2, 12,-12, -12,12                              ;a
bone4_colispts      db 2, 13,-4, -13,4                                ;b
bone5_colispts      db 2, 14,0, -14,0                                 ;c
bone6_colispts      db 2, 13,4, -13,-4                                ;d
bone7_colispts      db 2, 12,12, -12,-12                              ;e
bone8_colispts      db 2, 4,13, -4,-13                                ;f
tankcolispts        db 4, -10,-6, 10,-6,-10,6,10,6                    ;$10
seamislcolispts     db 4, -6,-10, 6,-10, -6,10,6,10                   ;$11
dartcolispts        db 3, -14,8, 0,8, 18,8                            ;$12
rocketcolispts      db 3, 0,-4, 0,8, 0,24                             ;$13
snappycolispts      db 4, 4,12,10,12,4,20,10,20                       ;$14
slimecolispts       db 2, -10,0, -2,0                                 ;$15
tilecolispts        db 9, -12,-12, 0,-12, 12,-12, -12,0, 0,0, 12,0, -12,12, 0,12, 12,12   ;$16
ventcolispts        db 9, 0,-6, 5,-5, 5,0, 5,5, 0,6, -5,5, -6,0, -5,-5, 0,0               ;$17
dartlcolispts       db 3, -4,8, 16,8, 28,8                                                ;$18
vslimecolispts      db 2, 0,-5, 0,5                                                       ;$19

;--------------------------------------------------------------------------------------------------

wind_data 

          db 1,2,2,1, 0,1,2,1, 2,1,0,1, 1,2,1,1
          db 1,2,2,1, 0,0,1,2, 1,1,2,1, 1,1,1,0
          db 0,1,2,1, 0,1,2,1, 1,1,0,1, 1,1,0,1
          db 0,0,1,0, 0,1,1,1, 1,1,1,1, 0,2,0,1
          db 1,0,1,1, 0,1,0,1, 0,1,0,1, 1,0,1,1
          db 0,1,0,0, 0,0,1,1, 1,0,0,1, 1,0,1,0
          db 0,0,0,1, 0,0,1,1, 0,0,0,1, 0,0,1,0
          db 0,0,1,0, 0,0,1,0, 0,1,0,1, 0,0,1,0
           
bump_data

          db 8,8,8,8, 8,8,8,8, 8,8,8,8, 7,6,5,4, 3,2,1,0    

laserblast_table

          db 1,1,0,0, 1,0,0,1, 1,0,0,0, 1,0,0,1
          db 0,0,1,1, 0,0,1,1, 0,0,1,0, 0,1,0,0
          
bone_sin_table

          incbin "FLOS_based_programs\games\Bounder\data\sin_table.bin"


rock_motion_list

          db $1e,$22,$e1,$02,$2f,$ee,$20,$e2,$0e,$2e,$12,$ef,$21,$e0,$f2,$77    ;xy offset

random_number_list

          db $23,$58,$f1,$8a,$12,$25,$50,$08,$41,$8f,$90,$32,$4d,$50,$2c,$71
          db $4b,$d4,$08,$40,$03,$83,$ee,$16,$f4,$52,$87,$70,$02,$51,$64,$90

direction_offsets

          db $0e,$1e,$2e,$2f, $20,$21,$22,$12, $02,$f2,$e2,$e1, $e0,$ef,$ee,$fe

direction_matrix    

          incbin "FLOS_based_programs\games\Bounder\data\direction_finder.bin"

quadrant_conv_table

          db 00,01,02,03,04,00,00,00
          db 00,15,14,13,12,00,00,00
          db 08,07,06,05,04,00,00,00
          db 08,09,10,11,12,00,00,00
                    
                    
game_colours        incbin "FLOS_based_programs\games\Bounder\data\game_palette.bin"


block_id_table      incbin "FLOS_based_programs\games\Bounder\data\block_id_table.bin"  ; bit 0 = obsticle, bit 1 = explode ball
											; bit 2 = fall through 3 = reserved 
											; bit 4 = water, bit 7 = normal bounce tile

red_glow_table

          dw $200,$300,$400,$500,$600,$700,$810,$a20,$c20,$f10,$f31,$f82,$f75
          dw $100,$200,$300,$400,$500,$600,$700,$900,$b10,$c00,$c10,$c41,$e52
          dw $000,$100,$200,$300,$400,$500,$600,$800,$a00,$b00,$b00,$b20,$d21
          dw $000,$000,$100,$200,$300,$400,$500,$600,$800,$900,$a00,$a10,$c10
          dw $000,$000,$000,$100,$200,$300,$400,$500,$700,$700,$800,$900,$b00
          dw $000,$000,$100,$200,$300,$400,$500,$600,$800,$900,$a00,$a10,$c10
          dw $000,$100,$200,$300,$400,$500,$600,$800,$a00,$b00,$b00,$b20,$d21
          dw $100,$200,$300,$400,$500,$600,$700,$900,$b10,$c00,$c10,$c41,$e52


wiggle_table

          db 0,2,4,2,0,1,2,1,0,0,0,0,0,0,0,0,0,0,0,0
                    
;-----------------------------------------------------------------------------------------------------

level_startblock_positions

          dw $008c,$0070      ; level 00   (foreground pos, background pos)
          dw $00b0,$0071      ; level 01                    
          dw $00d0,$0071      ; level 02
          dw $00e0,$0071      ; level 03
          dw $00f0,$0071      ; level 04
          dw $00f0,$0071      ; level 05
          dw $00f0,$0071      ; level 06
          dw $00f0,$00f0      ; level 07
          dw $00f0,$0072      ; level 08
          dw $00f0,$0071      ; level 09
          
;------------------------------------------------------------------------------------------------------
;   TITLE SCREEN VARIABLES AND DATA 
;------------------------------------------------------------------------------------------------------

                    org (($ + 255) / 256) * 256

scale_table         incbin "FLOS_based_programs\games\Bounder\data\titles_scale_table.bin"

titles_tiles_fn     db "TILE_TTL.BIN",0
titles_sprites_fn   db "SPR_TTL.BIN",0  
sine_table          incbin "FLOS_based_programs\games\Bounder\data\titles_sin_table.bin"
titles_colours      incbin "FLOS_based_programs\games\Bounder\data\titles_palette.bin"
titles_map          incbin "FLOS_based_programs\games\Bounder\data\titles_map.bin"
colour_bar_palette  incbin "FLOS_based_programs\games\Bounder\data\titles_colour_bars_palette.bin"
maths_sin_table     incbin "FLOS_based_programs\games\Bounder\data\maths_sin_table.bin"

fade_dir            db 0
fade_level          db 0
fade_index          db 0
fade_temp           db 0
fade_count          dw 0
faded_in            db 0
faded_out           db 0

bounce_index        db 0
top_scroll_fine     db 0
tile_scroll         db 0

highscore           db 0,0,0,0,0,0

scrolltextpointer   dw 0

scroll_text         incbin "FLOS_based_programs\games\Bounder\data\scroll_text.txt"
                    db 0,0,0,0

;---------------------------------------------------------------------------------------------------
;   "LOADING" LOGO DATA
;---------------------------------------------------------------------------------------------------

loading_colours     incbin "FLOS_based_programs\games\Bounder\data\loading_palette.bin"
load_sprites_fn     db "SPR_LOAD.BIN",0

;---------------------------------------------------------------------------------------------------
;  "CONGRATS" DATA
;---------------------------------------------------------------------------------------------------

dst_xy_coords       ds 56*2,0           ;must remain in this sequence
src_z_coords        ds 56*3,0           ;must remain in this sequence

;---------------------------------------------------------------------------------------------------

star_sprites_fn     db "SPR_STAR.BIN",0
congrats_tiles_fn   db "TILE_TTL.BIN",0
star_colours        incbin "FLOS_based_programs\games\Bounder\data\congrats_palette.bin"
congrats_map        incbin "FLOS_based_programs\games\Bounder\data\congrats_map.bin"

;---------------------------------------------------------------------------------------------------
; SOUND FX
;--------------------------------------------------------------------------------------------------

sfx_data            incbin "FLOS_based_programs\games\Bounder\data\sfx_03.bin"

fx_list             dw sfx_data+0                 ;1  - arc
                    dw sfx_data+$20               ;2  - bonus
                    dw sfx_data+$50               ;3  - bounce 2
                    dw sfx_data+$70               ;4  - crunch
                    dw sfx_data+$90               ;5  - fall
                    dw sfx_data+$c0               ;6  - ball lands
                    dw sfx_data+$e0               ;7  - laser shot
                    dw sfx_data+$100              ;8  - new level
                    dw sfx_data+$120              ;9  - boinggg
                    dw sfx_data+$140              ;10 - pop-bang
                    dw sfx_data+$150              ;11 - rocket
                    dw sfx_data+$170              ;12 - splash
                    dw sfx_data+$180              ;13 - break tile
                    dw sfx_data+$190              ;14 - collect bonus
                    dw sfx_data+$1a0              ;15 - volcano launch
                    dw sfx_data+$1b0              ;16 - shorter boing
                    
include             "FLOS_based_programs\games\Bounder\Inc\sfx_routine.asm"

sfx_filename        db "SFX.SAM",0
sfx_samples_addr    equ $8000
sfx_samples_bank    equ 3

;---------------------------------------------------------------------------------------------------
; MUSIC
;--------------------------------------------------------------------------------------------------

music_samples_addr  equ $8000
music_samples_bank  equ 6
ttmod_samp_filename db "TUNE.SAM",0

include             "FLOS_based_programs\games\Bounder\Inc\z80_protracker_player.asm"
include             "FLOS_based_programs\games\Bounder\Inc\Amiga_audio_to_v5z80p.asm"

                    org (($+2)/2)*2               ;WORD align tracker module in RAM

music_module        incbin "FLOS_based_programs\games\Bounder\data\tune.pat"

;----------------------------------------------------------------------------------------------------
