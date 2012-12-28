
;---Standard header for OSCA and OS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"


          org $5000

;---------------------------------------------------------------------------------------
; Spira "Quad-sine" line-draw demo with pattern editor.
; By Phil Ruston 08 - www.retroleum.co.uk V1.01
;
; Added video mode check and friendly-flos return Dec 2012
;---------------------------------------------------------------------------------------

req_hw_version      equ $263
half_vbuffer_size   equ $8000           ; IE: 2nd video buffer starts at $10000

window_width        equ 256
window_height       equ 256
number_of_lines     equ 256


;--------------------------------------------------------------------------------------

		call video_mode_prompt		;in case video mode is not PAL 50Hz
		ret nz
		
		call backup_flos_bitmap		;put FLOS display data at $70000


;-------- Initialize --------------------------------------------------------------------

          ld hl,0
          ld (palette),hl
          ld a,%00000100
          ld (vreg_vidctrl),a           ; disable video whilst setting up
          
          ld a,%00000000                ; select y window pos register
          ld (vreg_rasthi),a            ; 
          ld a,$2e                      ; set 256 line display
          ld (vreg_window),a
          ld a,%00000100                ; switch to x window pos register
          ld (vreg_rasthi),a            
          ld a,$bb
          ld (vreg_window),a            ; set 256 pixels wide window

          xor a                         ; clear entire video ram
          call clear_64k_vram
          ld a,1
          call clear_64k_vram
          
          ld a,%00000000                ;draw frame around window
          ld (vreg_vidpage),a
          call make_window_frame
          ld a,%00001000
          ld (vreg_vidpage),a
          call make_window_frame

          ld hl,colours
          ld de,palette+256             ;upload spectrum palette
          ld bc,256
          ldir
          ld hl,0
          ld (palette),hl
          
          call setup_sine_tables
          call setup_line_draw
          call setup_star_sprites
          call setup_logo_sprites
          call setup_panel_sprites
          call panel_off_spr_regs       
          call setup_music
          
          ld a,%00000011
          ld (vreg_sprctrl),a           ; enable sprites + interleaved priority mode
          ld a,%10000000
          ld (vreg_vidctrl),a           ; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)


;--------- Main Loop ---------------------------------------------------------------------------------


wvrtstart ld a,(vreg_read)              ; wait for VRT
          and 1
          jr z,wvrtstart
wvrtend   ld a,(vreg_read)
          and 1
          jr nz,wvrtend
          
          call vrt_routines
          
          ld a,(key_press)
          cp $76
          jr nz,wvrtstart               ;loop if ESC key not pressed


;-------------------------------------------------------------------------------------------------

		xor a
		out (sys_audio_enable),a      ; silence channels
          
		call restore_flos_bitmap
		
		call restore_original_video_mode
		
		call kjt_flos_display
	        
		xor a				; and quit to FLOS
		ret

;-------------------------------------------------------------------------------------------------

vrt_routines

          ld ix,bitplane0a_loc          ; Show video buffer 0 or 1 
          ld hl,0                       ; Buffer 0 address            
          ld a,(buffer)                 
          or a
          jr z,set_vaddr
          xor a
          ld hl,half_vbuffer_size       ; Buffer 1 address
          add hl,hl
          rl a                          ; Put carry in A bit 0 
set_vaddr ld (ix),l                     ;\ 
          ld (ix+1),h                   ;- Video fetch start address for this frame
          ld (ix+2),a                   ;/


;flip buffer flag

          ld a,(buffer)                 ; swap buffer flag
          xor 1
          ld (buffer),a
          
;         ld hl,$f0f
;         ld (palette),hl

          call update_sound_hardware

          call update_star_sprites
          
;         ld hl,$f00
;         ld (palette),hl

          call erase_lines

;         ld hl,$0f0
;         ld (palette),hl

          call make_coords
          call next_frame_updates

;         ld hl,$f0f
;         ld (palette),hl

          call draw_lines

;         ld hl,$ff0
;         ld (palette),hl

          call move_stars
          call change_vars
          call panel_countdown
          call instructions_countdown
          call change_pattern
          call play_tracker

;         ld hl,$0
;         ld (palette),hl               ; raster time marker
          ret
          
;---------------------------------------------------------------------------------------------------------------

make_coords

          di                                      ;using stack pointer so disable IRQs
          ld (orig_sp),sp
          
          ld a,%00000011                          ;source sine tables are at $18000
          out (sys_mem_select),a
                    
          ld sp,2+(number_of_lines*2)+coord_stack1
          ld a,(buffer)
          or a
          jr z,ucs1
          ld sp,2+(number_of_lines*2)+coord_stack2

ucs1      ld (new_sp),sp
          ld a,(work_sin_start1a)
          ld b,a
          ld a,(work_sin_start1b)                 
          ld d,a
          ld a,(work_sin_start2a)
          ld c,a
          ld a,(work_sin_start2b)
          ld e,a
          
          ld a,(sinadd1a_disp)
          ld (sinadd1a+1),a
          ld a,(sinadd1b_disp)          
          ld (sinadd1b+1),a
          ld a,(sinadd2a_disp)
          ld (sinadd2a+1),a
          ld a,(sinadd2b_disp)
          ld (sinadd2b+1),a

          ld a,(radius1a)
          add a,$80 
          ld (radsize1a+1),a
          ld a,(radius1b)
          add a,$80 
          ld (radsize1b+1),a
          ld a,(radius2a)
          add a,$80
          ld (radsize2a+1),a
          ld a,(radius2b)
          add a,$80
          ld (radsize2b+1),a

          exx
          ld b,number_of_lines                    ;dot count
          
dotloop   exx
          ld a,b
sinadd1a  add a,1
          ld b,a
          ld a,d
sinadd1b  add a,1
          ld d,a
          ld a,c
sinadd2a  add a,1
          ld c,a
          ld a,e
sinadd2b  add a,1
          ld e,a
          
radsize1a ld h,0
          ld l,b                        
          ld a,(hl)
radsize2a ld h,0
          ld l,c
          add a,(hl)
          add a,$80
          exx
          ld l,a
          exx
radsize1b ld h,0
          ld l,d
          ld a,(hl)
radsize2b ld h,0
          ld l,e
          add a,(hl)
          add a,$80
          exx
          ld h,a
          push hl
          djnz dotloop
          
          ld ix,(new_sp)                ;retrieve first value - for loop connect
          ld e,(ix-2)
          ld d,(ix-1)
          push de                       ;add it at end of stack list

          ld sp,(orig_sp)
          xor a
          out (sys_mem_select),a
          ei
          ret


;---------------------------------------------------------------------------------------------------

next_frame_updates

          ld hl,frame_disps             ;update vars for next frame
          ld de,work_sin_start1a
          ld b,4
frdlp     ld a,(de)
          add a,(hl)
          ld (de),a
          inc hl
          inc de
          djnz frdlp
          ret

;---------------------------------------------------------------------------------------------------

up_key    equ "q"
down_key  equ "a"
inc_key   equ "p"
dec_key   equ "o"
space_key equ " "


change_vars

          call kjt_get_key
          ld (key_press),a
          ld a,b
          
          cp space_key
          jp z,space_pressed
          
          ld b,a                        ;dont change values unless in edit mode
          ld a,(edit_mode)
          or a
          ret z
          ld a,b
          cp up_key
          jp z,upvar
          cp down_key
          jp z,downvar
          cp inc_key
          jp z,incvar
          cp dec_key
          jp z,decvar
          ret


space_pressed

          ld a,(edit_mode)
          xor 1
          ld (edit_mode),a
          jr nz,shwpan
          call panel_off_spr_regs
          xor a
          ret
shwpan    call show_panel
          xor a
          ret
          
          
upvar     call show_panel
          ld a,(var_to_change)
          sub 1
          jr nc,upvok
          xor a
upvok     ld (var_to_change),a
          call move_highlight
          ret
          
          
downvar   call show_panel
          ld a,(var_to_change)
          inc a
          cp 16
          jr nz,downvok
          ld a,15
downvok   ld (var_to_change),a
          call move_highlight
          ret


incvar    call show_panel
          ld hl,sin_start1a
          ld a,(var_to_change)
          ld e,a
          ld d,0
          add hl,de
          ld b,(hl)
          inc (hl)
          cp 4
          call z,rad1
          cp 5
          call z,rad1
          cp 6
          call z,rad2
          cp 7
          call z,rad2
          call update_panel_gfx
          ret
          
          
decvar    call show_panel
          ld hl,sin_start1a
          ld a,(var_to_change)
          ld e,a
          ld d,0
          add hl,de
          ld b,(hl)
          dec (hl)
          cp 4                          ;check radius boundaries
          call z,rad1
          cp 5
          call z,rad1
          cp 6
          call z,rad2
          cp 7
          call z,rad2
          call update_panel_gfx
          ret
          

rad1      push hl
          pop de
          inc de
          inc de
          ld a,(de)
          add a,(hl)
          jr c,restor
          cp $7f
          jr nc,restor
          xor a
          ret
restor    ld (hl),b
          xor a
          ret

rad2      push hl
          pop de
          dec de
          dec de
          ld a,(de)
          add a,(hl)
          jr c,restor
          cp $7f
          jr nc,restor
          xor a
          ret       
          
          
update_panel_gfx

          ld c,(hl)                               ;c = new value
          ld a,(var_to_change)
          sla a
          sla a
          sla a
          ld e,a
          ld d,0
          ld ix,spr_registers+(67*4)
          add ix,de
          ld a,c
          rrca
          rrca
          rrca
          rrca
          and $f
          add a,16
          ld (ix+3),a                             ;High nyb sprite def
          ld a,c
          and $f
          add a,16
          ld (ix+7),a                             ;Low nyb sprite def
          
          ld a,(sin_start1a)
          ld (work_sin_start1a),a
          ld a,(sin_start1b)
          ld (work_sin_start1b),a
          ld a,(sin_start2a)
          ld (work_sin_start2a),a
          ld a,(sin_start2b)
          ld (work_sin_start2b),a
          ret


move_highlight

          rlca
          rlca
          rlca
          add a,$17
          ld (spr_registers+266),a
          ret
          
show_panel

          ld a,255
          ld (panel_time),a
          call panel_on_spr_regs
          ret
          
          
;-------------------------------------------------------------------------------------------------------

instructions_countdown


          ld a,(instructions_time)      ;fade out instructions page after a while
          or a
          ret z
          dec a
          ld (instructions_time),a
          cp 16
          ret nc
          ld hl,(instructions_colour)
          ld de,$111
          xor a
          sbc hl,de
          ld (instructions_colour),hl
          ld (palette+128),hl
          ld a,(instructions_time)
          or a
          ret nz
          
          ld ix,spr_registers+(106*4)   ;remove instructions page sprites
          ld b,10
risprlp   ld (ix),0
          ld (ix+1),0
          inc ix
          inc ix
          inc ix
          inc ix
          djnz risprlp        
          ret
          
panel_countdown


          ld a,(panel_time)
          or a
          ret z
          dec a
          ld (panel_time),a
          ret nz
          call panel_off_spr_regs
          ret

;-------------------------------------------------------------------------------------------------------

change_pattern

max_pattern equ 21

          ld a,(edit_mode)
          or a
          ret nz

          ld a,(pattern_time)           ;ready for a new pattern?
          inc a
          ld (pattern_time),a
          jr nz,nnewpat
          ld a,(pattern_number)
          inc a
          cp max_pattern
          jr nz,nfinpat
          xor a
nfinpat   ld (pattern_number),a
          ld de,patterns                ;copy new pattern to working registers
          ld l,a
          ld h,0
          add hl,hl
          add hl,hl
          add hl,hl
          add hl,hl
          add hl,de
          ld de,work_sin_start1a
          ld bc,4
          push hl
          ldir
          pop hl
          ld de,sin_start1a
          ld bc,16
          ldir
          
nnewpat   ld a,(pattern_time)
          cp $f0
          jr nc,fadepatternout
          cp $11
          jr c,fadepatternin
          ret
          
          
fadepatternout

          neg
          
fadepatternin
          
          
          rlca
          rlca
          ld h,a
          ld l,0
          ld (mult_table),hl            ;set up mult table to scale
          xor a
          ld (mult_index),a
          ld (mult_write+1),a

          
          ld de,patterns+4              ;scale radius values
          ld a,(pattern_number)
          ld l,a
          ld h,0
          add hl,hl
          add hl,hl
          add hl,hl
          add hl,hl
          add hl,de
          

          ld a,(hl)
          ld (mult_write),a
          ld a,(mult_read)
          ld (radius1a),a
          inc hl
          ld a,(hl)
          ld (mult_write),a
          ld a,(mult_read)
          ld (radius1b),a
          inc hl
          ld a,(hl)
          ld (mult_write),a
          ld a,(mult_read)
          ld (radius2a),a
          inc hl
          ld a,(hl)
          ld (mult_write),a
          ld a,(mult_read)
          ld (radius2b),a

          ld hl,0                       ;restore mult table first entry
          ld (mult_table),hl
          ret
                    

;------------------------------------------------------------------------------------------------------
; Line draw code - simplified 8 bit maths version to work in 256x256 window
;------------------------------------------------------------------------------------------------------

setup_line_draw


          ld hl,linedraw_constants                ; copy the video offset constants to the 
          ld de,linedraw_lut0                     ; line draw hardware lookup table
          ld bc,16
          ldir
          ret

linedraw_constants

          dw window_width+1                       ;  note: y offsets are switched around for 
          dw window_width-1                       ; "line 0 at top of screen" type malarky.
          dw (65536-window_width)+1
          dw (65536-window_width)-1
          dw 1
          dw 65535
          dw window_width
          dw (65536-window_width)
          

delta_y   db 0


;---------------------------------------------------------------------------------------------------

erase_lines

          di
          ld (orig_sp),sp
          ld sp,coord_stack1
          
          ld a,(buffer)
          rrca
          ld (ewbuff1a+1),a
          ld (ewbuff1b+1),a
          or a
          jr z,ucs1a
          ld sp,coord_stack2

ucs1a     xor a
          ld (linedraw_colour),a        ; erase line colour 

          ld b,number_of_lines/2        ; number of lines/2
          exx
          pop hl                        ; first pixel address (h=y,l=x)
          exx
          
enxt_lna  exx
ewbuff1a  ld c,0                        ; reset the octant code / address MSB 
          ld (linedraw_reg2),hl         ; Hardware line draw constant: Start Address
          pop de                        ; second pixel address (d=y,e=x)
          ld a,e                        ; a=x1
          sub l                         ; a=x1-x0
          jr nc,exdeltapo               ; is delta_x positive?
          neg                           ; make it positive if not
          set 4,c                       ; update octant settings bit 4
          
exdeltapo ld b,a                        ; stash delta_x
          ld a,d
          sub h
          jr nc,eydeltapo
          neg
          set 5,c                       ; update octant settings bit 5

eydeltapo ld (delta_y),a                ; stash delta_y
          sub b                         ; delta y - delta x
          jr c,ehoriz_sg                ; if delta_x > delta_y then the line has horizontal segments
          ld h,0
          jr z,dxdyz3
          neg
          dec h                         ; vertical segment code.. 
dxdyz3    ld l,a
          add hl,hl
          ld (linedraw_reg0),hl         ; Hardware linedraw Constant: 2 x (delta_x - delta_y)       
          ld h,0
          ld l,b
          add hl,hl
          ld (linedraw_reg1),hl         ; Hardware Linedraw Constant: 2 x delta_x         
          set 6,c                       ; update octant settings
          ld a,(delta_y)                
          ld l,a                        ; l = line length (IE: y)
          jp eline_len
          
ehoriz_sg ld h,255
          ld l,a
          add hl,hl
          ld (linedraw_reg0),hl         ; Hardware Linedraw Constant: 2 x (delta_y - delta_x)
          ld a,(delta_y)
          ld l,a
          ld h,0
          add hl,hl
          ld (linedraw_reg1),hl         ; Hardware Linedraw Constant: 2 x delta_y
          ld l,b                        ; l = line length (IE: x)
          
eline_len ld h,c                        ; HL = composite of MSB,octant code and line length
                    
eld_wait1 ld a,(vreg_read)
          and $10                       ; ensure any previous line draw / blit op is complete
          jr nz,eld_wait1               ; before restarting line draw operation
          
          ld (linedraw_reg3),hl         ; line length, octant code, y address MSB & Start line draw.
          
          ex de,hl                      ; second pixel pos becomes first pixel

ewbuff1b  ld c,0                        ; reset the octant code / address MSB 
          ld (linedraw_reg6),hl         ; Hardware line draw constant: Start Address
          pop de                        ; second pixel address (d=y,e=x)
          ld a,e                        ; a = x1
          sub l                         ; a = x1 - x0
          jr nc,exdeltap2               ; is delta_x positive?
          neg                           ; make it positive if not
          set 4,c                       ; update octant settings bit 4
          
exdeltap2 ld b,a                        ; stash delta_x
          ld a,d
          sub h
          jr nc,eydeltap2
          neg
          set 5,c                       ; update octant settings bit 5

eydeltap2 ld (delta_y),a                ; stash delta_y
          sub b                         ; delta y - delta x
          jr c,ehriz_sg2                ; if delta_x > delta_y then the line has horizontal segments
          ld h,0
          jr z,dxdyz4
          neg
          dec h                         ; vertical segment code.. 
dxdyz4    ld l,a
          add hl,hl
          ld (linedraw_reg4),hl         ; Hardware linedraw Constant: 2 x (delta_x - delta_y)       
          ld h,0
          ld l,b
          add hl,hl
          ld (linedraw_reg5),hl         ; Hardware Linedraw Constant: 2 x delta_x         
          set 6,c                       ; update octant settings
          ld a,(delta_y)                
          ld l,a                        ; l = line length (IE: y)
          jp eline_ln2
          
ehriz_sg2 ld h,255
          ld l,a
          add hl,hl
          ld (linedraw_reg4),hl         ; Hardware Linedraw Constant: 2 x (delta_y - delta_x)
          ld a,(delta_y)
          ld l,a
          ld h,0
          add hl,hl
          ld (linedraw_reg5),hl         ; Hardware Linedraw Constant: 2 x delta_y
          ld l,b                        ; l = line length (IE: x)
          
eline_ln2 ld h,c                        ; HL = composite of MSB,octant code and line length
                              
eld_wait2 ld a,(vreg_read)
          and $10                       ; ensure any previous line draw / blit op is complete
          jr nz,eld_wait2               ; before restarting line draw operation
          
          ld (linedraw_reg7),hl         ; line length, octant code, y address MSB & Start line draw.

          ex de,hl                      ; second pixel pos becomes first pixel

          exx
          dec b
          jp nz,enxt_lna
          
          ld sp,(orig_sp)
          ei
          ret
          
;---------------------------------------------------------------------------------------------------
          
draw_lines

          di
          ld (orig_sp),sp
          ld sp,coord_stack1
          
          ld a,(buffer)
          rrca
          ld (wbuff1a+1),a
          ld (wbuff1b+1),a
          or a
          jr z,ucs1b
          ld sp,coord_stack2

ucs1b     ld b,number_of_lines/2        ; number of lines/2
          ld c,128                      ; line colour
          ld hl,vreg_read
          exx
          pop hl                        ; first pixel address (h=y,l=x)
          exx
          
nxt_linea exx
wbuff1a   ld c,0                        ; reset the octant code / address MSB 
          ld (linedraw_reg2),hl         ; Hardware line draw constant: Start Address (h=x0,l=y0)
          pop de                        ; second pixel address (d=y1,e=x1)
          ld a,e                        ; a=x1
          sub l                         ; a=x1-x0
          jr nc,xdeltapos               ; is delta_x positive?
          neg                           ; make it positive if not
          set 4,c                       ; update octant settings bit 4
          
xdeltapos ld b,a                        ; stash delta_x
          ld a,d                        ; a = y1
          sub h                         ; z = y1-y0
          jr nc,ydeltapos
          neg
          set 5,c                       ; update octant settings bit 5

ydeltapos ld (delta_y),a                ; stash delta_y
          sub b                         ; delta y - delta x
          jr c,horiz_seg                ; if delta_x > delta_y then the line has horizontal segments
          ld h,0
          jr z,dxdyz1
          neg                           ; vertical segment code. a = delta x - delta y
          dec h                         ;
dxdyz1    ld l,a
          add hl,hl
          ld (linedraw_reg0),hl         ; Hardware linedraw Constant: 2 x (delta_x - delta_y)       
          ld h,0
          ld l,b
          add hl,hl
          ld (linedraw_reg1),hl         ; Hardware Linedraw Constant: 2 x delta_x         
          set 6,c                       ; update octant settings
          ld a,(delta_y)                
          ld l,a                        ; l = line length (IE: y)
          jp line_len
          
horiz_seg ld l,a
          ld h,255
          add hl,hl
          ld (linedraw_reg0),hl         ; Hardware Linedraw Constant: 2 x (delta_y - delta_x)
          ld a,(delta_y)
          ld l,a
          ld h,0
          add hl,hl
          ld (linedraw_reg1),hl         ; Hardware Linedraw Constant: 2 x delta_y
          ld l,b                        ; l = line length
          
line_len  ld h,c                        ; HL = composite of MSB,octant code and line length
          exx 
          ld a,c
          
ld_wait1  bit 4,(hl)                    ; ensure any previous line draw / blit op is complete
          jr nz,ld_wait1                ; before restarting line draw operation
          
          ld (linedraw_colour),a
          inc c
          exx
          ld (linedraw_reg3),hl         ; line length, octant code, y address MSB & Start line draw.
          


          ex de,hl                      ; second pixel pos becomes first pixel



wbuff1b   ld c,0                        ; reset the octant code / address MSB 
          ld (linedraw_reg6),hl         ; Hardware line draw constant: Start Address
          pop de                        ; second pixel address (d=y,e=x)
          ld a,e                        ; a = x0
          sub l                         ; a = x0 - x1
          jr nc,xdeltap2                ; is delta_x positive?
          neg                           ; make it positive if not
          set 4,c                       ; update octant settings bit 4
          
xdeltap2  ld b,a                        ; stash delta_x
          ld a,d
          sub h
          jr nc,ydeltap2
          neg
          set 5,c                       ; update octant settings bit 5

ydeltap2  ld (delta_y),a                ; stash delta_y
          sub b                         ; delta y - delta x
          jr c,horiz_sg2                ; if delta_x > delta_y then the line has horizontal segments
          ld h,0
          jr z,dxdyz2
          neg
          dec h                         ; vertical segment code.. 
dxdyz2    ld l,a
          add hl,hl
          ld (linedraw_reg4),hl         ; Hardware linedraw Constant: 2 x (delta_x - delta_y)       
          ld h,0
          ld l,b
          add hl,hl
          ld (linedraw_reg5),hl         ; Hardware Linedraw Constant: 2 x delta_x         
          set 6,c                       ; update octant settings
          ld a,(delta_y)                
          ld l,a                        ; l = line length (IE: y)
          jp line_len2
          
horiz_sg2 ld h,255
          ld l,a
          add hl,hl
          ld (linedraw_reg4),hl         ; Hardware Linedraw Constant: 2 x (delta_y - delta_x)
          ld a,(delta_y)
          ld l,a
          ld h,0
          add hl,hl
          ld (linedraw_reg5),hl         ; Hardware Linedraw Constant: 2 x delta_y
          ld l,b                        ; l = line length (IE: x)
          
line_len2 ld h,c                        ; HL = composite of MSB,octant code and line length
                                        
ld_wait2  ld a,(vreg_read)
          and $10                       ; ensure any previous line draw / blit op is complete
          jr nz,ld_wait2                ; before restarting line draw operation
          
          ld (linedraw_reg7),hl         ; line length, octant code, y address MSB & Start line draw.

          ex de,hl                      ; second pixel pos becomes first pixel

          exx
          dec b
          jp nz,nxt_linea
          
          ld sp,(orig_sp)
          ei
          ret



;--------------------------------------------------------------------------------------------------------------

update_star_sprites


          ld ix,spr_registers
          ld iy,star_pos_list

          ld b,number_of_stars                    ;update sprite reg x coords
starloop  ld h,0
          ld l,(iy)
          ld de,128+48
          add hl,de
          ld (ix),l
          ld a,h
          or $10
          ld (ix+1),a
          inc iy
          ld de,4
          add ix,de
          djnz starloop
          ret       
          
          
move_stars

          ld hl,star_pos_list
          ld b,number_of_stars/8
ms_loop   ld a,(hl)
          sub 1
          ld (hl),a
          inc hl
          ld a,(hl)
          sub 2
          ld (hl),a
          inc hl
          ld a,(hl)
          sub 3
          ld (hl),a
          inc hl
          ld a,(hl)
          sub 4
          ld (hl),a
          inc hl
          ld a,(hl)
          sub 5
          ld (hl),a
          inc hl
          ld a,(hl)
          sub 6
          ld (hl),a
          inc hl
          ld a,(hl)
          sub 7
          ld (hl),a
          inc hl
          ld a,(hl)
          sub 8
          ld (hl),a
          inc hl
          djnz ms_loop
          ret

          
;---------------------------------------------------------------------------------------------------

setup_sine_tables

          ld hl,sine_table              ; upload sine table to maths unit
          ld de,mult_table
          ld bc,512
          ldir

          ld a,%00000011                ; make sine look-up tables at $18000
          out (sys_mem_select),a
          ld hl,$8000                   
          ld b,$80
          ld ix,0
mlutlp2   ld (mult_write),ix
          ld c,0
mlutlp1   ld a,c
          ld (mult_index),a
          ld de,(mult_read)
          ld (hl),e
          inc hl
          inc c
          jr nz,mlutlp1
          inc ix
          djnz mlutlp2
          xor a
          out (sys_mem_select),a
          ret

;---------------------------------------------------------------------------------------------------
          
          
setup_star_sprites

number_of_stars equ 64


          ld de,palette
          ld hl,stars_cols
          ld bc,32
          ldir

          ld a,3
          ld hl,star_gfx
          ld de,sprite_base
          ld bc,end_star_gfx-star_gfx
          call unpack_sprites
          
          ld ix,star_pos_list           ;set random star x positions
          ld hl,0
          ld de,$f147
          ld a,31
          ld b,number_of_stars          ;number of stars
suspllp   ld (ix),h
          add hl,de
          add a,h
          inc a
          rrca 
          xor b
          sub e
          ld h,a
          inc ix
          djnz suspllp
                    
          ld ix,spr_registers           ;set Y and Def sprite registers
          ld b,number_of_stars
          ld de,4
          ld c,32                       ;first y pos
          ld a,$37                      ;first def
istsplp   ld (ix+2),c                   
          inc c
          inc c
          inc c
          inc c
          ld (ix+3),a                   
          dec a
          and $7
          or $30
          add ix,de
          djnz istsplp
          ret
          
          

;----------------------------------------------------------------------------------------------------------

setup_panel_sprites

          xor a                         ;unpack sprites
          ld hl,settings_gfx
          ld de,sprite_base
          ld bc,end_settings_gfx-settings_gfx
          call unpack_sprites

          ld a,1
          ld hl,hexfont_gfx
          ld de,sprite_base
          ld bc,end_hexfont_gfx-hexfont_gfx
          call unpack_sprites
          
          ld a,2
          ld hl,highlight_gfx
          ld de,sprite_base
          ld bc,end_highlight_gfx-highlight_gfx
          call unpack_sprites

          ld a,5
          ld hl,instruction_gfx
          ld de,sprite_base
          ld bc,end_instruction_gfx-instruction_gfx
          call unpack_sprites

          ld ix,spr_registers+(64*4)    ;set up sprite registers
          ld (ix),$b8
          ld (ix+1),$80
          ld (ix+2),$18
          ld (ix+3),$00
          ld (ix+4),$c8
          ld (ix+5),$80
          ld (ix+6),$18
          ld (ix+7),$08
          ld (ix+8),$d8
          ld (ix+9),$10
          ld (ix+10),$17
          ld (ix+11),$20
          ld ix,spr_registers+(67*4)
          ld de,8
          ld a,$18
          ld b,16
susprlp   ld (ix),$d8
          ld (ix+1),$10
          ld (ix+2),a
          ld (ix+3),16
          ld (ix+4),$e0
          ld (ix+5),$10
          ld (ix+6),a
          ld (ix+7),16
          add a,8
          add ix,de
          djnz susprlp
          
          
          ld ix,spr_registers+(106*4)   ;instructions page sprites
          ld e,$50                      
          ld hl,$e0
          ld b,10
suisprlp  ld (ix),l
          ld a,h
          or $70
          ld (ix+1),a
          ld (ix+2),$60
          ld (ix+3),e
          ld a,l
          add a,16
          jr nc,isnoc
          inc h
isnoc     ld l,a
          ld a,e
          add a,7
          ld e,a
          inc ix
          inc ix
          inc ix
          inc ix
          djnz suisprlp       
          
          ld hl,$fff
          ld (palette+128),hl
          ret



panel_on_spr_regs

          ld ix,spr_registers+(64*4)    
          ld (ix),$b8
          ld (ix+4),$c8
          ld (ix+8),$d8
          ld ix,spr_registers+(67*4)
          ld de,8
          ld a,$18
          ld b,16
ponsprlp  ld (ix),$d8
          ld (ix+4),$e0
          add a,8
          add ix,de
          djnz ponsprlp
          
          ld hl,sin_start1a                       ; populate "value" defs
          ld de,8
          ld b,16
          ld ix,spr_registers+(67*4)
nxtent    ld a,(hl)
          rrca
          rrca
          rrca
          rrca
          and $f
          add a,16
          ld (ix+3),a                             ;High nyb sprite def
          ld a,(hl)
          and $f
          add a,16
          ld (ix+7),a                             ;Low nyb sprite def
          add ix,de
          inc hl
          djnz nxtent         
          ret


panel_off_spr_regs

          ld ix,spr_registers+(64*4)
          ld de,4
          xor a
          ld b,32+3
posprlp   ld (ix),a
          add ix,de
          djnz posprlp
          ret

;-------------------------------------------------------------------------------------------------------

setup_logo_sprites

          ld a,4
          ld hl,logo_gfx
          ld de,sprite_base
          ld bc,end_logo_gfx-logo_gfx
          call unpack_sprites
          
          ld ix,spr_registers+(100*4)   ;position logo sprites
          ld a,$4c
          ld c,$40
          ld b,6
          ld de,4
sulsplp   ld (ix),a                     ;x
          ld (ix+1),$21                 ;height/msbs
          ld (ix+2),$f9                 ;y
          ld (ix+3),c                   ;def
          add ix,de
          inc c
          inc c
          add a,16
          djnz sulsplp
          
          ld hl,logo_cols               ;upload colours
          ld de,palette+32
          ld bc,64
          ldir
          ret
          
;-------------------------------------------------------------------------------------------------

make_window_frame
          
          di
          ld a,%00100000
          out (sys_mem_select),a
          ld hl,0
          ld ix,128
          ld de,256
          ld b,0
frlp1     ld (hl),15
          dec h
          ld (hl),15
          inc h
          ld (ix+127),15
          ld (ix-128),15
          inc l
          add ix,de
          djnz frlp1
          ld a,%00000000
          out (sys_mem_select),a
          ei
          ret

;----------------------------------------------------------------------------------------------

setup_music
          
          ld hl,$8000                             ;copy samples to sound sys accessible RAM
          exx
          ld de,end_of_samples
          ld hl,music_samples
suploadlp ld a,%00000000
          out (sys_mem_select),a                  ;source bank
          ld c,(hl)
          inc hl
          ld b,(hl)
          inc hl
          push bc
          ld a,%00000100
          out (sys_mem_select),a                  ;dest bank
          exx
          pop bc
          ld (hl),c
          inc hl
          ld (hl),b
          inc hl
          exx 
          push hl
          xor a
          sbc hl,de
          pop hl
          jr c,suploadlp

          ld a,%00000000
          out (sys_mem_select),a
                    
          ld hl,0
          ld (force_sample_base),hl
          
          call init_tracker

          ret


;---------------------------------------------------------------------------------------
; Unpacks V5Z80P_RLE packed data to sprite RAM - Phil_V5Z80P @ Retroleum.co.uk 2008
; Keeps destination within $1000-$1fff and updates vreg_vidpage as required
;----------------------------------------------------------------------------------------

unpack_sprites

;set  A = initial sprite bank (0-15)
;set HL = source address of packed file
;set DE = destination address for unpacked data (within sprite page $1000-$1fff)
;set BC = length of packed file

          dec bc                        ;less 1 to skip match token
          push hl
          pop ix
          exx
          ld b,a
          exx
          or $80
          ld (vreg_vidpage),a           ; select initial sprite bank

          in a,(sys_mem_select)
          and $1f
          or $80
          out (sys_mem_select),a        ; page in sprite memory
          
          inc hl
unp_gtok  ld a,(ix)                     ; get token byte
unp_next  bit 5,d                       ; test for next sprite page
          jp z,nchsb1
          exx
          inc b
          ld a,b
          or $80
          ld (vreg_vidpage),a
          exx
          ld d,$10
          ld a,(ix)
nchsb1    cp (hl)                       ; is byte at source location same as token?
          jr z,unp_brun                 ; if it is, there's a byte run to expand
          ldi                           ; if not, simply copy this byte to destination
          jp pe,unp_next                ; last byte of source?
          jr packend
          
unp_brun  push bc                       ; stash B register
          inc hl              
          ld a,(hl)                     ; get byte value
          inc hl              
          ld b,(hl)                     ; get run length
          inc hl
          
unp_rllp  ld (de),a                     ; write byte value, byte run length
          inc de              
          bit 5,d                       ; test for next sprite page
          jp z,nchsb2
          ld c,a
          exx
          inc b
          ld a,b
          or $80
          ld (vreg_vidpage),a
          exx
          ld d,$10
          ld a,c
nchsb2    djnz unp_rllp
          
          pop bc    
          dec bc                        ; last byte of source?
          dec bc
          dec bc
          ld a,b
          or c
          jp nz,unp_gtok

packend   in a,(sys_mem_select)         ;page out sprite memory
          and $7f
          out (sys_mem_select),a        
          ret

;--------------------------------------------------------------------------------------------------

clear_64k_vram

; set A to 64K video page to clear

          rlca                          
          rlca
          rlca
          ld (vreg_vidpage),a
          ld (orig_sp),sp

          di
          ld a,%00100000
          out (sys_mem_select),a
          ld hl,0
          ld sp,hl
          ld bc,$8000
wpvrlp    push hl
          djnz wpvrlp
          dec c
          jr nz,wpvrlp
          xor a
          out (sys_mem_select),a
          ld sp,(orig_sp)
          ei
          ret

;-----------------------------------------------------------------------------------------------------
; These variables must be in unpaged RAM space ie <$8000 
;-----------------------------------------------------------------------------------------------------
                    
orig_sp             dw 0
new_sp              dw 0
coord_stack1        ds 2+(number_of_lines*2),0              
coord_stack2        ds 2+(number_of_lines*2),0              

var_to_change       db 0
key_press           db 0
panel_time          db 0
instructions_time   db 255
instructions_colour dw $fff
pattern_number      db 0
pattern_time        db 17
edit_mode           db 0

buffer              db 0

work_sin_start1a    db 0
work_sin_start1b    db 64
work_sin_start2a    db 0
work_sin_start2b    db 0

sin_start1a         db 0
sin_start1b         db 64
sin_start2a         db 0
sin_start2b         db 0

radius1a            db 100
radius1b            db 100
radius2a            db 0
radius2b            db 0

sinadd1a_disp       db 1
sinadd1b_disp       db 1
sinadd2a_disp       db 0
sinadd2b_disp       db 0

frame_disps         db 1
                    db 0
                    db 0
                    db 0

star_pos_list       ds number_of_stars,0

;------------------------------------------------------------------------------------------------------
; Location of following data not critical
;-------------------------------------------------------------------------------------------------------

colours             dw $f0f,$f0f,$e0f,$e0f,$d0f,$c0f,$b0f,$a0f,$90f,$80f,$70f,$60f,$50f,$40f,$30f,$30f,$20f,$20f,$10f,$10f,$00f
                    dw $00f,$00f,$01f,$01f,$02f,$02f,$03f,$04f,$05f,$06f,$07f,$08f,$09f,$0af,$0bf,$0cf,$0df,$0df,$0ef,$0ef,$0ff
                    dw $0ff,$0ff,$0fe,$0fe,$0fd,$0fd,$0fc,$0fb,$0fa,$0f9,$0f8,$0f7,$0f6,$0f5,$0f4,$0f3,$0f2,$0f2,$0f1,$0f1,$0f0
                    dw $0f0,$1f0,$1f0,$2f0,$2f0,$3f0,$4f0,$5f0,$6f0,$7f0,$8f0,$9f0,$af0,$bf0,$cf0,$df0,$df0,$ef0,$ef0,$ff0,$ff0
                    dw $ff0,$fe0,$fe0,$fd0,$fd0,$fc0,$fb0,$fa0,$f90,$f80,$f70,$f60,$f50,$f40,$f30,$f30,$f20,$f20,$f10,$f10,$f00
                    dw $f00,$f00,$f01,$f01,$f02,$f02,$f03,$f04,$f05,$f06,$f07,$f08,$f09,$f0a,$f0b,$f0c,$f0d,$f0d,$f0d,$f0e,$f0e,$f0f,$f0f
                    
stars_cols          incbin "flos_based_programs\demos\spira\data\stars_palette.bin"

logo_cols           incbin "flos_based_programs\demos\spira\data\logo_palette.bin"

sine_table          incbin "flos_based_programs\demos\spira\data\sin_table.bin"

patterns            incbin "flos_based_programs\demos\spira\data\patterns.bin"
          
;---------------------------------------------------------------------------------------------------

hexfont_gfx         incbin "flos_based_programs\demos\spira\data\hexfont_sprites_packed.bin"
end_hexfont_gfx     db 0

settings_gfx        incbin "flos_based_programs\demos\spira\data\settings_sprites_packed.bin"
end_settings_gfx    db 0

highlight_gfx       incbin "flos_based_programs\demos\spira\data\highlight_sprites_packed.bin"
end_highlight_gfx   db 0

star_gfx            incbin "flos_based_programs\demos\spira\data\stars_sprites_packed.bin"
end_star_gfx        db 0

logo_gfx            incbin "flos_based_programs\demos\spira\data\logo_sprites_packed.bin"
end_logo_gfx        db 0

instruction_gfx     incbin "flos_based_programs\demos\spira\data\instructions_sprites_packed.bin"
end_instruction_gfx db 0

;=============================================================================================================

 	include "flos_based_programs\code_library\video\inc\video_mode_prompt.asm"

	include "flos_based_programs\code_library\video\inc\backup_restore_flos_bitmap.asm"
         
;=============================================================================================================


                    include "flos_based_programs\demos\spira\inc\Z80_Protracker_Player_v504.asm"
                    include "flos_based_programs\demos\spira\inc\Amiga_audio_to_V5Z80P_v502.asm"

          
                    org (($+2)/2)*2               ; word align

music_module        incbin "flos_based_programs\demos\spira\data\tune.pat"

music_samples       incbin "flos_based_programs\demos\spira\data\tune.sam"
end_of_samples      db 0

;---------------------------------------------------------------------------------------------------
