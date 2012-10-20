;-----------------------------------------------------------------------------------------
; Bounder for Z80 project - Enemy Routines V1.01
;-----------------------------------------------------------------------------------------

reverse_trig        equ $f0
go_left_trig        equ $f2
go_right_trig       equ $f4
go_up_trig          equ $f3
go_down_trig        equ $f1 

;-----------------------------------------------------------------------------------------

no_action

          ret

;-----------------------------------------------------------------------------------------
          
          
enemy_bird
          
          call get_enemy_xy                                 
          ld de,(ball_finalx)
          xor a
          sbc hl,de
          jr c,nobdgl
          ld a,(ix+enemy_misc_1)                            ;swing left
          sub 1
          ld (ix+enemy_misc_1),a
          bit 7,a
          jr z,bdirdone
          add a,$10
          jr c,bdirdone
          ld (ix+enemy_misc_1),$f0
          jr bdirdone
          
nobdgl    ld a,(ix+enemy_misc_1)                            ;swing right
          add a,1
          ld (ix+enemy_misc_1),a
          bit 7,a
          jr nz,bdirdone
          cp $10
          jr c,bdirdone
          ld (ix+enemy_misc_1),$10
          
bdirdone  ld a,(ix+enemy_misc_2)
          ld e,a
          ld a,(ix+enemy_misc_2)
          add a,(ix+enemy_misc_1)
          ld (ix+enemy_misc_2),a
          ld b,0
          srl a
          srl a
          srl a
          srl a
          srl e
          srl e
          srl e
          srl e     
          cp e
          jr nz,bdirxch
          ld bc,0
          jr bdirx

bdirxch   ld bc,$0001
          inc e
          res 4,e
          cp e
          jr z,bdirx
          ld bc,$ffff
          
bdirx     call get_enemy_xy
          add hl,bc
          inc de
birdniy   call update_enemy_xy          
          ld c,0
          call test_collision_points
          call c,set_ball_explode_big
          ret

;-----------------------------------------------------------------------------------------------------------

enemy_rightfan
          
          ld a,(ball_status)
          or a
          jp nz,no_rwind
          ld l,(ix+enemy_xlsb)
          ld h,(ix+enemy_xmsb)
          ld de,(ball_finalx)           ;is ball right of fan?
          xor a
          sbc hl,de
          jr nc,fgoright
          ld de,$80                     ;if ball >128 pixels away - no effect
          add hl,de
          jr nc,fgoright
                    
          ld l,(ix+enemy_ylsb)
          ld h,(ix+enemy_ymsb)
          ld de,18
          xor a
          sbc hl,de
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr nc,fgoright
          ld l,(ix+enemy_ylsb)
          ld h,(ix+enemy_ymsb)
          ld de,18
          add hl,de
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr c,fgoright
          
          call get_enemy_xy
          ex de,hl
          ld hl,(ball_finalx)
          xor a
          sbc hl,de
          call scale_wind
          add a,b
          ld (ball_x),a
          cp $f8
          jr c,flrgok
          ld a,$f8
flrgok    ld (ball_x),a
          ld b,$08                      ; check if way is clear for ball to go right
          ld c,$f8                       
          call find_tile_under_ball      
          ld a,(hl)                      
          call get_block_flags
          and 1
          jr nz,fnogorigh
          ld b,$08
          ld c,$08
          call find_tile_under_ball
          call get_block_flags
          and 1
          jr z,fgoright
fnogorigh ld a,(old_ball_x)
          ld (ball_x),a

fgoright  call get_enemy_xy   
          ld c,1
          call test_collision_points
          call c,set_ball_explode_big
no_rwind  ret


scale_wind
          
          ld a,(counter)                ; the further the ball is away, the weaker the wind
          and 15
          ld e,a
          ld a,l
          and $70
          or e
          ld e,a
          ld d,0
          ld hl,wind_data
          add hl,de
          ld a,(ball_x)
          ld (old_ball_x),a
          ld b,(hl)
          ret
          

;-----------------------------------------------------------------------------------------------------------

enemy_leftfan
          
          ld a,(ball_status)
          or a
          jp nz,no_lwind
          ld l,(ix+enemy_xlsb)
          ld h,(ix+enemy_xmsb)
          ld de,(ball_finalx)           ;is ball left of fan?
          xor a
          sbc hl,de
          jr c,fgoleft
          ld de,$80                     ;need to be within 128 pixels                     
          xor a
          sbc hl,de
          jr nc,fgoleft
                    
          ld l,(ix+enemy_ylsb)
          ld h,(ix+enemy_ymsb)
          ld de,18
          xor a
          sbc hl,de
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr nc,fgoleft
          ld l,(ix+enemy_ylsb)
          ld h,(ix+enemy_ymsb)
          ld de,18
          add hl,de
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr c,fgoleft
          
          call get_enemy_xy
          ld de,(ball_finalx)
          xor a
          sbc hl,de
          call scale_wind
          sub b
          ld (ball_x),a
          cp $8
          jr nc,fblfok
          ld a,$8
fblfok    ld (ball_x),a
          ld b,$f8                      ; check if way is clear for ball to go left
          ld c,$f8                       
          call find_tile_under_ball      
          call get_block_flags
          and 1
          jr nz,fnogoleft
          ld b,$f8
          ld c,$08
          call find_tile_under_ball
          ld a,(hl)
          call get_block_flags
          and 1
          jr z,fgoleft
fnogoleft ld a,(old_ball_x)
          ld (ball_x),a

fgoleft   call get_enemy_xy   
          ld c,2
          call test_collision_points
          call c,set_ball_explode_big
no_lwind  ret
          
          
;-----------------------------------------------------------------------------------------------------------

          
teleport_in         
          
          ld a,(ball_status)            ;no action if ball is not in normal play
          or a
          jp nz,ntpin
          ld a,(ball_frame)             ;ball at bounce point?
          cp 8
          jr nz,ntpin
          ld l,(ix+enemy_xlsb)          ;goes into teleport if centre of
          ld h,(ix+enemy_xmsb)          ;ball is with 7 pixel radius
          ld de,8
          add hl,de
          ld de,(ball_finalx)
          xor a
          sbc hl,de
          jr nc,tpixpos
          ld a,h
          cpl
          ld h,a
          ld a,l
          cpl
          ld l,a
tpixpos   ld de,16
          xor a
          sbc hl,de
          jr nc,ntpin
          add hl,de
          ld b,l
          ld l,(ix+enemy_ylsb)
          ld h,(ix+enemy_ymsb)
          ld de,8
          add hl,de
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr nc,tpiypos
          ld a,h
          cpl
          ld h,a
          ld a,l
          cpl
          ld l,a
tpiypos   ld de,16
          xor a
          sbc hl,de
          jr nc,ntpin
          add hl,de
          ld h,0
          ld de,square_table
          add hl,de
          ld a,(hl)
          ld h,0
          ld l,b
          add hl,de
          add a,(hl)
          jr c,ntpin
          cp 72                         ;6 squared * 2
          jr nc,ntpin
          
          ld a,6
          ld (ball_status),a            ;init transport
          xor a
          ld (ball_anim_delay),a
          ld (scroll_active),a
          ld a,8
          call new_fx                   ;sound effect
ntpin     
          ret
          

;-----------------------------------------------------------------------------------------------------------


teleport_out

          ret

;-----------------------------------------------------------------------------------------------------------



bumper_right

          ld a,2                                  ;is spring retracting?
          cp (ix+enemy_status)
          jr nz,tspringr
          inc (ix+enemy_animtimer)
          ld a,(ix+enemy_animtimer)
          cp (iy+enemy_init_animspeed)
          jr nz,sprad
          ld (ix+enemy_animtimer),0
          inc (ix+enemy_framecounter)
          ld a,(ix+enemy_framecounter)
          cp (iy+enemy_init_framecount)
          jr nz,sprad
          ld (ix+enemy_framecounter),0
          ld (ix+enemy_status),1
sprad     ld a,(ix+enemy_framecounter)
          add a,(iy+enemy_init_baseframe)
          ld (ix+enemy_frame),a
          ret

tspringr  ld a,(ball_frame)                       ;ball at bounce up point?
          cp 1
          jr nz,nosorbs
          ld c,3
          call get_enemy_xy   
          call unconditional_collision_test
          jr nc,nosorbs
          ld (ix+enemy_status),2                  ;switch to spring fire/retract
          ld a,1
          ld (ball_bump),a
          ld a,16
          call new_fx                             ;sound effect
          xor a
          ld (ball_bump_dir),a
          ld (ix+enemy_animtimer),5
nosorbs   ret
          

;-----------------------------------------------------------------------------------------------------------


bumper_left

          ld a,2                                  ;is spring retracting?
          cp (ix+enemy_status)
          jr nz,tspringl
          inc (ix+enemy_animtimer)
          ld a,(ix+enemy_animtimer)
          cp (iy+enemy_init_animspeed)
          jr nz,splad
          ld (ix+enemy_animtimer),0
          inc (ix+enemy_framecounter)
          ld a,(ix+enemy_framecounter)
          cp (iy+enemy_init_framecount)
          jr nz,splad
          ld (ix+enemy_framecounter),0
          ld (ix+enemy_status),1
splad     ld a,(ix+enemy_framecounter)
          add a,(iy+enemy_init_baseframe)
          ld (ix+enemy_frame),a
          ret

tspringl  ld a,(ball_frame)                       ;ball at up bounce point?
          cp 1
          jr nz,nosolbs
          ld c,4
          call get_enemy_xy   
          call unconditional_collision_test
          jr nc,nosolbs
          ld (ix+enemy_status),2                  ;switch to spring fire/retract
          ld a,1
          ld (ball_bump),a
          ld (ball_bump_dir),a
          ld a,16
          call new_fx                             ;sound effect
          ld (ix+enemy_animtimer),5
nosolbs   ret
          
;-----------------------------------------------------------------------------------------------------------



enemy_drill

          ld a,(ix+enemy_control)                 ;check if in simple animation mode
          cp 2
          jr nz,nddelay
          ld (ix+enemy_frame),$5d
          dec (ix+enemy_animtimer)
          ret nz
          ld (ix+enemy_control),3                 ;enable simple animation - forwards
          ret
          
nddelay   bit 2,(ix+enemy_control)
          jr nz,dgbckwrd
          ld a,(ix+enemy_framecounter)
          cp 11
          jr nz,danimok
          set 2,(ix+enemy_control)                ;set backwards animation
          ld (ix+enemy_framecounter),0
          jr danimok

dgbckwrd  ld a,(ix+enemy_framecounter)
          cp 11
          jr nz,danimok
          ld (ix+enemy_control),2                 ;disable simple animation
          call rand16
          ld a,l
          and $70
          add a,50
          ld (ix+enemy_animtimer),a
          ld (ix+enemy_framecounter),0
          
danimok   call get_enemy_xy   
          ld c,5
          call test_collision_points
          call c,set_ball_explode_big
          ret
          
          
;-----------------------------------------------------------------------------------------------------------
          
enemy_mine_main

          
          ld a,(ix+enemy_misc_1)                  ;prevent mine exploding until
          cp 100                                  ;2 seconds after init
          jr z,mineoktt
          inc (ix+enemy_misc_1)
          call get_enemy_xy                       ;check ball collision against mine
          ld c,6                                  ;during this dormant time
          call test_collision_points
          call c,set_ball_explode_big
          ret
          
mineoktt  ld l,(ix+enemy_ylsb)                    ;mine explodes is ball is within
          ld h,(ix+enemy_ymsb)                    ;48 vertical pixels above or below
          ld de,$30
          add hl,de
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr c,nominexp
          ld l,(ix+enemy_ylsb)                    
          ld h,(ix+enemy_ymsb)                    
          ld de,$30
          xor a
          sbc hl,de
          jr c,nominexp
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr nc,nominexp

sminexp   xor a                                   ;switch off bobbing mine object
          ld (ix+enemy_status),a                  
          
          ld a,$19                                ;set up fragments
          call get_enemy_xy
          call trigger_enemy_nonmap
          ld a,$1a
          call get_enemy_xy
          call trigger_enemy_nonmap
          ld a,$1b
          call get_enemy_xy
          call trigger_enemy_nonmap
          ld a,$1c
          call get_enemy_xy
          call trigger_enemy_nonmap

          call get_enemy_xy                       ;init a large one-shot explosion object
          ld a,$45
          call trigger_enemy_nonmap

          ld a,15
          call new_fx                             ;sound effect

nominexp  ret
          
          
          
small_mine_nw

          call get_enemy_xy
          dec hl
          dec hl
          dec de
          dec de
          call update_enemy_xy
          ld c,5
          call test_collision_points
          call c,set_ball_explode_big
          ret
          
small_mine_ne
          
          call get_enemy_xy
          inc hl
          inc hl
          dec de
          dec de
          call update_enemy_xy
          ld c,5
          call test_collision_points
          call c,set_ball_explode_big
          ret

small_mine_sw

          call get_enemy_xy
          dec hl
          dec hl
          inc de
          inc de
          call update_enemy_xy
          ld c,5
          call test_collision_points
          call c,set_ball_explode_big
          ret

small_mine_se

          call get_enemy_xy
          inc hl
          inc hl
          inc de
          inc de
          call update_enemy_xy
          ld c,5
          call test_collision_points
          call c,set_ball_explode_big
          ret


;-----------------------------------------------------------------------------------------------------------

          
laser_turrets

          call get_enemy_xy
          ex de,hl
          ld de,$10
          xor a
          sbc hl,de
          jr c,nonewlb
          ld de,$e0
          xor a
          sbc hl,de
          jr nc,nonewlb
          
          inc (ix+enemy_animtimer)
          ld a,(ix+enemy_animtimer)
          cp 26
          jr nz,nonewlb
          ld (ix+enemy_animtimer),0
          ld a,(ix+enemy_misc_1)
          inc a
          and 31
          ld (ix+enemy_misc_1),a
          ld l,a
          ld h,0
          ld de,laserblast_table
          add hl,de
          bit 0,(hl)
          jr z,nonewlb
          call get_enemy_xy
          ld bc,$30
          add hl,bc
          ld a,$1e
          call trigger_enemy_nonmap
          ld a,1
          call new_fx                             ;sound effect
nonewlb   ret
          
                    
;-----------------------------------------------------------------------------------------------------------

          
laser_blast

          inc (ix+enemy_misc_1)                   ;laser blast exists for a half a second
          ld a,(ix+enemy_misc_1)
          cp 25
          jr nz,lbexst
          ld (ix+enemy_status),0
lbexst    ld c,7
          call get_enemy_xy
          call test_collision_points
          call c,set_ball_explode_big
          ret


;-----------------------------------------------------------------------------------------------------------


enemy_bone_a_rang_r

          inc (ix+enemy_misc_2)
          call get_bone_pos   
          call get_enemy_xy
          ld hl,winleft_position-16
          add hl,bc
          bit 0,(ix+enemy_misc_2)
          jr z,bnoincy
          inc de
bnoincy   call update_enemy_xy
          
bcoldet   ld a,(ix+enemy_framecounter)
          add a,8
          ld c,a
          call get_enemy_xy
          call test_collision_points
          call c,set_ball_explode_big
          ret       



enemy_bone_a_rang_l
          
          inc (ix+enemy_misc_2)
          call get_bone_pos   
          call get_enemy_xy
          ld hl,winleft_position+256+16
          xor a
          sbc hl,bc
          bit 0,(ix+enemy_misc_2)
          jr z,bnoyinc
          inc de
bnoyinc   call update_enemy_xy
          jr bcoldet
                    


get_bone_pos

          ld hl,240                               ; max amplitude
          ld (mult_write),hl
          
          ld a,(ix+enemy_misc_1)                  ; step
          srl a
          jr nc,ebrni
          ld (mult_index),a                       ; interpolated step
          ld bc,(mult_read)
          inc a
          ld (mult_index),a
          ld hl,(mult_read)
          add hl,bc
          rr h
          rr l
          ld b,h
          ld c,l
          jr bposinc
          
ebrni     ld (mult_index),a                       ;normal uninterpolated step
          ld bc,(mult_read)

bposinc   inc (ix+enemy_misc_1)                   ;switch off bone at end of arc motion
          ret nz
          ld (ix+enemy_status),0
          ret
          
          
;-----------------------------------------------------------------------------------------------------------
          
enemy_tankr

          inc (ix+enemy_misc_1)
          call get_enemy_xy
          bit 0,(ix+enemy_misc_1)
          jr z,nomlizr
          inc hl
          call update_enemy_xy
nomlizr   ld bc,24
          add hl,bc
          call find_trig_at_xy
          cp reverse_trig
          jr nz,norevlr
          ld (ix+enemy_type),$12                  ;switch object to tank going in opposite dir
norevlr   call get_enemy_xy
          ld c,$10
          call test_collision_points
          call c,set_ball_explode_big
          ret
          
          
;-----------------------------------------------------------------------------------------------------------
          
enemy_tankl

          inc (ix+enemy_misc_1)
          call get_enemy_xy
          bit 0,(ix+enemy_misc_1)
          jr z,nomlizl
          dec hl
          call update_enemy_xy
nomlizl   ld bc,24
          xor a
          sbc hl,bc
          call find_trig_at_xy
          cp reverse_trig
          jr nz,norevll
          ld (ix+enemy_type),$11                  ;switch object to tank going in opposite dir
norevll   call get_enemy_xy
          ld c,$10
          call test_collision_points
          call c,set_ball_explode_big
          ret
          

;-----------------------------------------------------------------------------------------------------------
          
          
dart_right

          call get_enemy_xy
          ld bc,2
          add hl,bc
          call update_enemy_xy
          ld bc,$1c0
          xor a
          sbc hl,bc
          jr c,dartrpok
          ld (ix+enemy_status),0
dartrpok  call get_enemy_xy
          ld c,$12
          call test_collision_points
          call c,set_ball_explode_big
          ret


;-----------------------------------------------------------------------------------------------------------


dart_left
          call get_enemy_xy
          ld bc,2
          xor a
          sbc hl,bc
          call update_enemy_xy
          ld bc,$80
          xor a
          sbc hl,bc
          jr nc,dartlpok
          ld (ix+enemy_status),0
dartlpok  call get_enemy_xy
          ld c,$18
          call test_collision_points
          call c,set_ball_explode_big
          ret

;-----------------------------------------------------------------------------------------------------------

cannon_right

          ld a,(ix+enemy_misc_2)
          or a
          jr z,nocrr1
          dec (ix+enemy_misc_2)
          jr nz,nocrr2
          ld (ix+enemy_misc_3),9
nocrr2    call get_enemy_xy
          ld bc,3
          xor a
          sbc hl,bc
          call update_enemy_xy
          jr nocrr3
nocrr1    ld a,(ix+enemy_misc_3)
          or a
          jr z,nocrr3
          dec (ix+enemy_misc_3)
          call get_enemy_xy
          inc hl
          call update_enemy_xy
          
nocrr3    call get_enemy_xy                       ;dont fire if off screen
          ex de,hl
          ld de,$10
          xor a
          sbc hl,de
          jr c,canrnncb
          ld de,$f0
          xor a
          sbc hl,de
          jr nc,canrnncb
          
          inc (ix+enemy_misc_1)
          ld a,(ix+enemy_misc_1)
          cp 75
          jr nz,canrnncb
          ld (ix+enemy_misc_1),0                  ;launch a cannon ball right
          ld (ix+enemy_misc_2),3
          call get_enemy_xy
          ld a,$27
          call trigger_enemy_nonmap
          call get_enemy_xy
          ld bc,$1c
          add hl,bc
          ld a,$29
          call trigger_enemy_nonmap
          ld a,15
          call new_fx                             ;sound effect


canrnncb  
          call get_enemy_xy
          ld c,$6                       
          call test_collision_points              ;check for collision
          call c,set_ball_explode_big
          ret

;-----------------------------------------------------------------------------------------------------------


cannon_left
          
          ld a,(ix+enemy_misc_2)
          or a
          jr z,noclr1
          dec (ix+enemy_misc_2)
          jr nz,noclr2
          ld (ix+enemy_misc_3),9
noclr2    call get_enemy_xy
          ld bc,3
          add hl,bc
          call update_enemy_xy
          jr noclr3
noclr1    ld a,(ix+enemy_misc_3)
          or a
          jr z,noclr3
          dec (ix+enemy_misc_3)
          call get_enemy_xy
          dec hl
          call update_enemy_xy
          
noclr3    call get_enemy_xy                       ;dont fire if off screen
          ex de,hl
          ld de,$10
          xor a
          sbc hl,de
          jr c,canlnncb
          ld de,$f0
          xor a
          sbc hl,de
          jr nc,canlnncb
          
          inc (ix+enemy_misc_1)
          ld a,(ix+enemy_misc_1)
          cp 75
          jr nz,canlnncb
          ld (ix+enemy_misc_1),0                  ;launch a cannon ball left
          ld (ix+enemy_misc_2),3
          call get_enemy_xy
          ld a,$28
          call trigger_enemy_nonmap
          call get_enemy_xy
          ld bc,$1c
          xor a
          sbc hl,bc
          ld a,$29
          call trigger_enemy_nonmap
          ld a,15
          call new_fx                             ;sound effect

canlnncb  
          call get_enemy_xy
          ld c,$6                       
          call test_collision_points              ;check for collision
          call c,set_ball_explode_big
          ret

;-----------------------------------------------------------------------------------------------------------


cannonball_right

          call get_enemy_xy
          ld bc,3
          add hl,bc
          call update_enemy_xy
          ld bc,$1c0
          xor a
          sbc hl,bc
          jr c,cbrpok
          ld (ix+enemy_status),0
cbrpok    call get_enemy_xy
          ld c,$5
          call test_collision_points
          call c,set_ball_explode_big
          ret

;-----------------------------------------------------------------------------------------------------------


cannonball_left

          call get_enemy_xy
          ld bc,3
          xor a
          sbc hl,bc
          call update_enemy_xy
          ld bc,$80
          xor a
          sbc hl,bc
          jr nc,cblpok
          ld (ix+enemy_status),0
cblpok    call get_enemy_xy
          ld c,$5
          call test_collision_points
          call c,set_ball_explode_big
          ret
          
;-----------------------------------------------------------------------------------------------------------

enemy_smoke

          ret


;-----------------------------------------------------------------------------------------------------------


enemy_rocket

          bit 0,(ix+enemy_misc_1)
          jr nz,nolfx
          ld a,11
          call new_fx                             ;sound effect
          set 0,(ix+enemy_misc_1)

nolfx     call get_enemy_xy
          inc de
          inc de
          call update_enemy_xy
          call get_enemy_xy
          ld c,$13
          call test_collision_points
          call c,set_ball_explode_big
          ret
          
          
;-----------------------------------------------------------------------------------------------------------

moving_tile
          
          call get_enemy_xy
          bit 0,(ix+enemy_misc_1)
          jr z,mtgol
          inc hl
          call update_enemy_xy
          ld bc,17
          add hl,bc
          jr mtgor  
mtgol     dec hl
          call update_enemy_xy
          ld bc,17
          xor a
          sbc hl,bc
mtgor     call find_trig_at_xy
          cp reverse_trig
          jr nz,mtnord
          ld a,(ix+enemy_misc_1)                  ;switch to opposite dir
          xor 1
          ld (ix+enemy_misc_1),a
mtnord    call test_tile_collision
          ret


test_tile_collision           

          call get_enemy_xy                       ;has ball hit sprite tile (ignores height)
          ld c,$16
          call unconditional_collision_test
          jr nc,ntcolis
          ld a,1
          ld (sprite_tile_colis),a
          ret
          
ntcolis   xor a
          ret

;-----------------------------------------------------------------------------------------------------------


enemy_volcano

          ld a,(ix+enemy_frame)                   ;animate eruption explosion if applic
          or a
          jr z,novolan
          dec (ix+enemy_animtimer)
          jr nz,novolan
          ld (ix+enemy_animtimer),$4
          inc (ix+enemy_frame)
          ld a,(ix+enemy_frame)
          cp $25
          jr nz,novolan
          ld (ix+enemy_frame),0
          
novolan   call get_enemy_xy                       ;dont init rocks when offscreen
          ex de,hl
          ld b,h
          ld c,l
          ld de,$10
          xor a
          sbc hl,de
          jr c,no_inhr
          ld h,b
          ld l,c
          ld de,$118
          xor a
          sbc hl,de
          jr nc,no_inhr
          
          inc (ix+enemy_misc_1)
          ld a,(ix+enemy_misc_1)
          cp 60                                   ;time between possible eruptions
          jr nz,no_inhr
          ld (ix+enemy_misc_1),0
          inc (ix+enemy_misc_2)
          ld a,(ix+enemy_misc_2)
          and $1f
          ld l,a
          ld h,0
          ld bc,random_number_list                ;erupt at random intervals
          add hl,bc
          bit 0,(hl)
          jr z,no_inhr
          ld (ix+enemy_frame),$1e
          ld (ix+enemy_animtimer),$3
          call get_enemy_xy                       ;init rocks
          ld a,$2f
          call trigger_enemy_nonmap
          call get_enemy_xy             
          ld a,$2f
          call trigger_enemy_nonmap
          call get_enemy_xy             
          ld a,$2f
          call trigger_enemy_nonmap
          ld a,15
          call new_fx                             ;sound effect
no_inhr   ret
          


;-----------------------------------------------------------------------------------------------------------


enemy_hotrock
          
          ld a,(ix+enemy_misc_1)
          or a
          jr nz,hrgotdir
hrfdir    ld a,(rock_list_index)        ;select direction offset from list
          ld e,a
          ld l,a
          ld h,0
          ld bc,rock_motion_list
          add hl,bc
          inc e
          ld a,e
          ld (rock_list_index),a
          ld a,(hl)
          ld (ix+enemy_misc_1),a
          cp $77
          jr nz,hrgotdir
          xor a
          ld (rock_list_index),a
          jr hrfdir
hrgotdir  call directional_move
          ld c,$5
          call test_collision_points
          call c,set_ball_explode_big
          ret
          


;-----------------------------------------------------------------------------------------------------------


enemy_orbturret


          call get_enemy_xy                       ;dont fire shots when offscreen
          ex de,hl
          ld b,h
          ld c,l
          ld de,$10
          xor a
          sbc hl,de
          jr c,ewtcf
          ld h,b
          ld l,c
          ld de,$f0
          xor a
          sbc hl,de
          jr nc,ewtcf
          
          ld a,(ball_status)                      ;only fire when ball in normal play
          or a
          jr nz,ewtcf
          ld a,(recommence_scroll)
          or a
          jr nz,ewtcf
          ld a,(game_start_delay)
          or a
          jr nz,ewtcf
          
          inc (ix+enemy_misc_2)
          ld a,(ix+enemy_misc_2)                  
          cp 50                                   ;fire every n frames
          jr nz,ewtcf
          ld (ix+enemy_misc_2),0

          call get_enemy_xy                       ;initialize a blast 
          ld a,$46
          call trigger_enemy_nonmap

          call get_enemy_xy                       ;initialize a glowball
          ld a,$31
          call trigger_enemy_nonmap

          ld a,7
          call new_fx                             ;sound effect

ewtcf     ld c,$6                       
          call test_collision_points              ;check for collision
          call c,set_ball_explode_big
          ret

          

;-----------------------------------------------------------------------------------------------------------

          
enemy_glowball

          
          ld a,(ix+enemy_misc_1)                  ;if zero get the angle towards the ball
          or a
          jr nz,gbgotdir
          
          call get_enemy_xy
          ld bc,(ball_finalx)
          xor a
          sbc hl,bc
          sra h
          rr l
          ex de,hl                                ;e = x delta/2
          ld bc,(ball_finaly)
          xor a
          sbc hl,bc
          sra h
          rr l                                    ;l = y delta/2

          ld c,1                                  ;c = quadrant.. Bit 0: Right(0)/Left Bit 1: Upper(0)/Lower                      
          ld a,e
          bit 7,a
          jr z,xplus
          neg
          res 0,c
xplus     ld e,a
          ld a,l
          bit 7,a
          jr z,yplus
          neg
          set 1,c
yplus     ld l,a
          
scalex    ld a,e
          cp 16
          jr c,scaley
          srl e
          srl l
          jr scalex
scaley    ld a,l
          cp 16
          jr c,yscaled
          srl e
          srl l
          jr scaley

yscaled   ld a,e
          and $f
          ld e,a
          ld a,l
          cpl
          rrca
          rrca
          rrca
          rrca
          and $f0
          or e
          ld de,direction_matrix
          ld l,a
          ld h,0
          add hl,de
          ld l,(hl)
          ld h,0
          ld de,quadrant_conv_table
          add hl,de
          sla c
          sla c
          sla c
          ld b,0
          add hl,bc
          ld l,(hl)
          ld h,0
          ld bc,direction_offsets
          add hl,bc
          ld a,(hl)
          ld (ix+enemy_misc_1),a

gbgotdir  call directional_move
          ld c,$5
          call test_collision_points
          call c,set_ball_explode_big
          ret



;-----------------------------------------------------------------------------------------------------------

start_text

          ld a,(ix+enemy_misc_1)
          or a
          jr z,stmove
          dec a
          ld (ix+enemy_misc_1),a
          ret
stmove    call get_enemy_xy
          ld bc,4
          xor a
          sbc hl,bc
          call update_enemy_xy
          inc (ix+enemy_misc_2)
          ld a,(ix+enemy_misc_2)
          cp $2d
          jr nz,nstiwait
          ld (ix+enemy_misc_1),75
          ret
nstiwait  cp $80
          ret nz
          ld (ix+enemy_status),0
          ret
          

          
;-----------------------------------------------------------------------------------------------------------
          
bonus_round_text

          inc (ix+enemy_misc_1)
          ld a,(ix+enemy_misc_1)
          cp 108
          ret nz
          ld (ix+enemy_status),0
          ld hl,$1d0                              ;init "start" text object
          ld de,$98
          ld a,$32
          call trigger_enemy_nonmap
          ld a,75
          ld (game_start_delay),a
          ret

;-----------------------------------------------------------------------------------------------------------


bonus_score_text

          ld a,(ix+enemy_misc_1)                  ;"00000" text
          or a
          jr z,bstmove
          dec a
          ld (ix+enemy_misc_1),a
          ret
bstmove   call get_enemy_xy
          ld bc,4
          add hl,bc
          call update_enemy_xy
          inc (ix+enemy_misc_2)
          ld a,(ix+enemy_misc_2)
          cp $2d
          jr nz,nbstiwait
          ld (ix+enemy_misc_1),75
          ret
nbstiwait cp $80
          ret nz
          ld (ix+enemy_status),0
          ret

;-----------------------------------------------------------------------------------------------------------


goal_text
          ld a,(ball_status)
          or a
          ret nz
          ld a,(scroll_active)
          or a
          ret nz
          call get_enemy_xy             ;check for ball in goal area
          ld bc,$2c
          xor a
          sbc hl,bc
          ld de,(ball_finalx)
          xor a
          sbc hl,de
          jr nc,missgoal
          call get_enemy_xy
          ld bc,$24
          add hl,bc
          ld de,(ball_finalx)
          xor a
          sbc hl,de
          jr c,missgoal
          call get_enemy_xy
          ex de,hl
          ld bc,$0a
          xor a
          sbc hl,bc
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr nc,missgoal
          call get_enemy_xy
          ex de,hl
          add hl,bc
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr c,missgoal

          ld a,6
          ld (ball_status),a            ;set as if initializing teleport..
          xor a
          ld (ball_anim_delay),a
          ld a,1
          ld (end_of_level),a           ;but end of level is set, so.. there.
          ld a,8
          call new_fx

missgoal  ret




;-----------------------------------------------------------------------------------------------------------


game_text

          ld a,(ix+enemy_misc_1)
          or a
          ret nz
          call get_enemy_xy
          ld bc,4
          xor a
          sbc hl,bc
          call update_enemy_xy
          inc (ix+enemy_misc_2)
          ld a,(ix+enemy_misc_2)
          cp $2d
          ret nz
          ld (ix+enemy_misc_1),1
          ret


;-----------------------------------------------------------------------------------------------------------


over_text

          ld a,(ix+enemy_misc_1)
          or a
          ret nz
          call get_enemy_xy
          ld bc,4
          add hl,bc
          call update_enemy_xy
          inc (ix+enemy_misc_2)
          ld a,(ix+enemy_misc_2)
          cp $2d
          ret nz
          ld (ix+enemy_misc_1),1
          ret



;-----------------------------------------------------------------------------------------------------------
          
enemy_slimer

          call get_enemy_xy                       ;move slime right
          inc hl
          call update_enemy_xy
          ld bc,4                                 ;check collision
          add hl,bc
          call find_trig_at_xy
          cp reverse_trig
          jr nz,norevsr
          ld (ix+enemy_type),$2a                  ;switch object to go in opposite dir ($3a less $10)
norevsr   call get_enemy_xy
          ld c,$15
          call test_collision_points
          call c,set_ball_explode_big
          ret
          
          
          
enemy_slimel

          call get_enemy_xy                       ;move slime left
          dec hl
          call update_enemy_xy
          ld bc,16                                ;check collision
          xor a
          sbc hl,bc
          call find_trig_at_xy
          cp reverse_trig
          jr nz,norevsl
          ld (ix+enemy_type),$29                  ;switch object to go in opposite dir ($39 less $10)
norevsl   call get_enemy_xy
          ld c,$15
          call test_collision_points
          call c,set_ball_explode_big
          ret



enemy_slimed

          call get_enemy_xy                       ;move slime down
          inc de
          call update_enemy_xy
          ex de,hl
          ld bc,8                                 ;check collision
          add hl,bc
          ex de,hl
          call find_trig_at_xy
          cp reverse_trig
          jr nz,norevsd
          ld (ix+enemy_type),$42                  ;switch object to go in opposite dir ($52 less $10)
norevsd   call get_enemy_xy
          ld c,$19
          call test_collision_points
          call c,set_ball_explode_big
          ret
          
          
          
enemy_slimeu

          call get_enemy_xy                       ;move slime up
          dec de
          call update_enemy_xy
          ex de,hl
          ld bc,8                                 ;check collision
          xor a
          sbc hl,bc
          ex de,hl
          call find_trig_at_xy
          cp reverse_trig
          jr nz,norevsu
          ld (ix+enemy_type),$41                  ;switch object to go in opposite dir ($51 less $10)
norevsu   call get_enemy_xy
          ld c,$19
          call test_collision_points
          call c,set_ball_explode_big
          ret


;-----------------------------------------------------------------------------------------------------------
          
breakaway_tile

          call test_tile_collision
          or a
          ret z
          ld a,(rebound_frame)
          or a
          ret z
          ld (ix+enemy_control),$13               ;if ball bounced on tile, set to crumble (one shot animation - then off) 
          ld a,13
          call new_fx                             ;sound effect
          ret

;-----------------------------------------------------------------------------------------------------------

enemy_patroller_right
          
          call enemy_right
          ld bc,16                                ;check collision
          add hl,bc
          call find_trig_at_xy
          cp go_down_trig
          jr nz,nogdtepr
          ld (ix+enemy_type),$2d                  ;switch object (less $10)
          call enemy_left
          jr nogltepr
nogdtepr  cp go_up_trig
          jr nz,nogutepr
          ld (ix+enemy_type),$2c
          call enemy_left
          jr nogltepr
nogutepr  cp go_left_trig
          jr nz,nogltepr
          ld (ix+enemy_type),$1c
          call enemy_left

nogltepr  call get_enemy_xy
          ld c,$06
          call test_collision_points
          call c,set_ball_explode_big
          ret
          
enemy_patroller_left
          
          call enemy_left                         ;move left
          ld bc,15                                ;check collision
          xor a
          sbc hl,bc
          call find_trig_at_xy
          cp go_up_trig
          jr nz,nogutepl
          ld (ix+enemy_type),$2c                  ;switch object (less $10)
          call enemy_right
          jr nogltepr
nogutepl  cp go_down_trig
          jr nz,nogdtepl
          ld (ix+enemy_type),$2d
          call enemy_right
          jr nogltepr
nogdtepl  cp go_right_trig
          jr nz,nogltepr
          ld (ix+enemy_type),$1b
          call enemy_right
          jr nogltepr
          

enemy_patroller_down

          call enemy_down                         ;move slime right
          ex de,hl
          ld bc,16                                ;check collision
          add hl,bc
          ex de,hl
          call find_trig_at_xy
          cp go_left_trig
          jr nz,nogltepd
          ld (ix+enemy_type),$1c                  ;switch object (less $10)
          call enemy_up
          jr nogltepr
nogltepd  cp go_right_trig
          jr nz,nogrtepd
          ld (ix+enemy_type),$1b
          call enemy_up
          jr nogltepr
nogrtepd  cp go_up_trig
          jr nz,nogltepr
          ld (ix+enemy_type),$2c
          call enemy_up
          jr nogltepr
          


enemy_patroller_up
          
          call enemy_up                           ;move slime left
          ex de,hl
          ld bc,16                                ;check collision
          xor a
          sbc hl,bc
          ex de,hl
          call find_trig_at_xy
          cp go_right_trig
          jr nz,nogrtepu
          ld (ix+enemy_type),$1b                  ;switch object (less $10)
          call enemy_down
          jp nogltepr
nogrtepu  cp go_left_trig
          jr nz,nogltepu
          ld (ix+enemy_type),$1c                  ;switch object (less $10)
          call enemy_down
          jp nogltepr
nogltepu  cp go_down_trig
          jp nz,nogltepr
          ld (ix+enemy_type),$2d
          call enemy_down
          jp nogltepr
          

          

enemy_right
          
          call get_enemy_xy                       
          inc hl
          call update_enemy_xy
          ret

enemy_left
          
          call get_enemy_xy                       
          dec hl
          call update_enemy_xy
          ret
                    
enemy_down
          
          call get_enemy_xy                       
          inc de
          call update_enemy_xy
          ret

enemy_up
          call get_enemy_xy                       
          dec de
          call update_enemy_xy
          ret
          
;-----------------------------------------------------------------------------------------------------------


enemy_sea_missile_launching


          ld a,(ix+enemy_framecounter)
          cp 6
          jr nz,slmnca
          ld (ix+enemy_type),$31                  ;change animation (enemy type) when reaches max frame
          ld (ix+enemy_animtimer),$0
          ld (ix+enemy_framecounter),$0
          ld a,11
          call new_fx
slmnca    ret



enemy_sea_missile


          call get_enemy_xy                       ;move missile down screen
          inc de
          call update_enemy_xy
          ld c,$11                                ;test for collision
          call test_collision_points
          call c,set_ball_explode_big
          ret


;-----------------------------------------------------------------------------------------------------------

enemy_snappy_tile
          
          ld a,(rebound_frame)
          or a
          ret z
          call get_enemy_xy
          ld c,$14                                ;test for collision (only on bounce)
          call test_collision_points
          call c,set_ball_explode_big
          ret

;-----------------------------------------------------------------------------------------------------------

enemy_vent_fan

          ld a,(rebound_frame)
          or a
          ret z
          call get_enemy_xy
          ld c,$17                                ;test for collision (only on bounce)
          call test_collision_points
          call c,set_ball_explode_big
          ret

;-----------------------------------------------------------------------------------------------------------

enemy_y_start

          call get_enemy_xy                       ; compare y coord with comparision value 
          ld a,d                                  ; if same init "real" enemy and switch off this one
          or a
          ret nz
          ld a,e
          cp (iy+enemy_init_spawn_where)
          ret nz
                    
          ld (ix+enemy_status),0                  ;switch off this place holder enemy
          ld a,(iy+enemy_init_spawn_what)         
          call trigger_enemy_nonmap               ;spawn the actual enemy which is required
          ret

;-----------------------------------------------------------------------------------------------------------
          
enemy_ball_triggered

          call get_enemy_xy                       ;trigger enemy when its y coord is within         
          ex de,hl                                ;+/- spawn_where pixels of the ball
          ld de,(ball_finaly)
          xor a
          sbc hl,de
          jr nc,ycomppos
          ld a,h                                  
          inc h
          jr nz,ebtor
          ld a,l
          neg
          jr ycomptst

ycomppos  ld a,h
          or a
          jr nz,ebtor
          ld a,l
          
ycomptst  cp (iy+enemy_init_spawn_where)
          jr nc,ebtor
          ld (ix+enemy_status),0                  ;switch off this place holder enemy
          call get_enemy_xy
          ld a,(iy+enemy_init_spawn_what)         
          call trigger_enemy_nonmap               ;spawn the actual enemy which is required
ebtor     ret

                    
;-----------------------------------------------------------------------------------------------------------
