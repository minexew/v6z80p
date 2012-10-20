; **********************************************************************
; * 'Parity' demo (Linecop test) - Phil Ruston. www.retroleum.co.uk 09 *
; **********************************************************************
;
; Note: Code is a bit flaky :)
;
; V1.02 - Quick update to use single file loading system
; V1.01 - 60Hz mode auto detect (uses same values for VGA too)
;
;---Standard header for OSCA and OS --------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;--------------------------------------------------------------------------------------
; Program location / truncation header
;--------------------------------------------------------------------------------------

my_location equ $5000                   ; desired load address        
my_bank     equ $00                     ; desired bank (used if location is $8000 to $FFFF)

          org my_location               ; desired load address

load_loc  db $ed,$00                    ; header ID (Invalid but safe Z80 instruction)
          jr exec_addr                  ; jump over remaining header data 
          dw load_loc                   ; location file should load to 
          db my_bank                    ; upper 32KB bank that file should load into
          db 01                         ; control byte: 1=truncate using next 3 bytes
          dw prog_end-my_location       ; Load length 15:0 (if truncate feature required)
          db 0                          ; Load length 23:16 (""                "")

exec_addr

          
;--------- Test OSCA version ---------------------------------------------------------------------

          
          call kjt_get_version                    ; check running under FLOS v541+ 
          ex de,hl
          ld de,$650
          xor a
          sbc hl,de
          jr nc,osca_ok
          ld hl,old_osca_txt
          call kjt_print_string
          xor a
          ret

old_osca_txt

          db "Program requires OSCA v650+",11,11,0
          
osca_ok   

;--------- Get video mode --------------------------------------------------------------------

          ld b,0                                            
          in a,(sys_hw_flags)                     ;VGA jumper on?
          bit 5,a
          jr z,not_vga
          ld b,2
          jr got_mode 
not_vga   ld a,(vreg_read)                        ;60 Hz?
          bit 5,a
          jr z,got_mode
          ld b,1
got_mode  ld a,b
          ld (video_mode),a                       ;0=PAL, 1=NTSC, 2=VGA

;---------------------------------------------------------------------------------------------


          or a
          jr z,paltv
          ld a,$7a
          ld (scroll_text+2),a                    ;initial y postion of scroll text
paltv     

;--------- Load sprites ----------------------------------------------------------------------


          ld hl,loading_txt
          call kjt_print_string
          
          ld hl,bgnd_spr_fn             ;load background sprites 
          ld de,$8000         
          ld b,$1
          call load_from_bulk_file
          jp nz,load_error
          ld hl,$8000                   ;src addr
          ld a,1                        ;src bank
          ld de,0                       ;dest sprite
          ld bc,345                     ;sprite count
          call upload_sprites           
          call dot
                    
          ld hl,logo_spr_fn             ;load logo sprites 
          ld de,$8000                   
          ld b,$1
          call load_from_bulk_file
          jp nz,load_error
          ld hl,$8000
          ld a,1
          ld de,345
          ld bc,108
          call upload_sprites
          call dot
          
          ld hl,font_spr_fn             ;load font sprites 
          ld de,$8000
          ld b,$1             
          call load_from_bulk_file
          jp nz,load_error
          ld hl,$8000
          ld a,1
          ld de,453
          ld bc,59
          call upload_sprites
          call dot

          
;--------- Load 4096 colour pic data --------------------------------------------

          ld a,%00000010                ;clear bank 1 first
          out (sys_mem_select),a
          ld hl,$8000
          ld bc,$8000
          xor a
          call kjt_bchl_memfill
          xor a
          out (sys_mem_select),a
          
          ld hl,zoompic_fn              ; load zoom pic data 
          ld b,1                        ; bank 1 (IE: $10000)
          ld de,$8000                   ; Z80 address to load to 
          call load_from_bulk_file
          jp nz,load_error
          call dot

;--------- Load samples for tune -------------------------------------------------

          ld hl,samples_fn              ; load sample data
          ld b,3                        ; bank 3 (IE: $20000)
          ld de,$8000                   ; Z80 address to load to 
          call load_from_bulk_file
          jp nz,load_error
          call dot
          
          ld hl,0
          ld (force_sample_base),hl     ; Force sample base location to $0
          call init_tracker             ; Initialize mod with forced sample_base


;--------- Initialize program -----------------------------------------------------

          call kjt_wait_vrt

          di
          
          call set_up_display
          call set_up_scale_pattern
          call set_up_linecop_lists
          call set_up_sprites
          

          call anim                               ;prime all systems
          call build_line_list
          call build_scale_list
          call build_linecop_list

          call kjt_wait_vrt

          ld de,1
          ld (vreg_linecop_lo),de
          

;--------- Main loop ---------------------------------------------------------  


wvrtstart ld a,(vreg_read)              ; wait for VRT
          and 1
          jr z,wvrtstart
wvrtend   ld a,(vreg_read)
          and 1
          jr nz,wvrtend

          call per_frame_routines

          in a,(sys_keyboard_data)
          cp $76
          jr nz,wvrtstart               ; quit if ESC key pressed
          xor a
          ld a,$ff
          ret

;------------------------------------------------------------------------------------------
          
upload_sprites

; Keep this routine in unpaged RAM
;
; set DE to sprite number destination (0-511)
;     HL to source address
;     BC to number of sprites
;      A to source bank  (FLOS bank will increase internally when HL wraps beyond $ffff)
          
          ex af,af'

          call kjt_get_bank
          push af

          ex af,af'
          call kjt_set_bank

          in a,(sys_mem_select)         ;page sprite RAM in at $1000-$1fff
          or $80
          out (sys_mem_select),a
                              
          push de
          srl d
          rr  e
          srl d
          rr  e
          srl d
          rr  e
          srl d
          rr  e
          ld a,e
          or $80
          ld (vreg_vidpage),a           ;sprite bank
          exx
          ld c,a
          exx
          pop de

          ld a,e
          and $0f
          or $10
          ld d,a
          ld e,0
          
scloop    push bc
          ld bc,256
          ldir
          
          ld a,h
          or a
          jr nz,scaok
          ld h,$80
          call kjt_inc_bank

scaok     ld a,d
          cp $20
          jr nz,scdok
          ld d,$10
          exx
          ld a,c
          inc a
          ld c,a
          ld (vreg_vidpage),a
          exx
          
scdok     pop bc
          dec bc
          ld a,b
          or c
          jr nz,scloop
          
          in a,(sys_mem_select)
          and $7f
          out (sys_mem_select),a

          pop af
          call kjt_set_bank
          ret
          
;--------------------------------------------------------------------------------

;----------------------------------------------------------------------------   

per_frame_routines

          ld a,(spr_buffer+1)           ;flip sprite reg select
          xor 1
          ld (spr_buffer+1),a
          xor 1
          rlca
          rlca
          or %01011011
          ld (vreg_sprctrl),a

          call build_linecop_list

          call build_line_list
          call build_scale_list
          call update_sprites
          call scroller
          call anim
          
          call update_sound_hardware
          call play_tracker
          ld hl,0
          ld (mult_table),hl
          ret


;----------------------------------------------------------------------------

set_up_display


          ld a,%00000000                ; select y window pos register
          ld (vreg_rasthi),a            ; 

          ld b,$3d                      ; PAL y window start/end pos (240 lines)
          ld a,(video_mode)
          or a
          jr z,palsize
          ld b,$19                      
palsize   ld a,b
          ld (vreg_window),a
          ld a,%00000100                ; switch to x window pos register
          ld (vreg_rasthi),a            
          ld a,$7e
          ld (vreg_window),a            ; set 368 pixels wide window
          
          ld a,%10000010
          ld (vreg_vidctrl),a           ; bitmap chunky display - disable video

          ld hl,0                       ; blank area display window from VRAM $10000
          ld (bitplane0a_loc),hl
          ld (bitplane0b_loc),hl
          xor a
          ld (bitplane0a_loc+2),a
          inc a
          ld (bitplane0b_loc+2),a
          ld a,$ff
          ld (bitplane_modulo),a        ; reset counter at start of each line

          ld a,2
          ld (vreg_palette_ctrl),a      ; write to both palettes as buffer is used
          call setup_palette
          ld a,3
          ld (vreg_palette_ctrl),a
          call setup_palette
          ret
                              


setup_palette

          ld hl,palette                 ; zero the entire palette
          ld b,0
blp1      ld (hl),0
          inc hl
          ld (hl),0
          inc hl
          djnz blp1
          
          ld hl,bgnd_colours            ; setup background palette
          ld de,palette
          ld bc,96*2
          ldir      
          
          ld hl,font_colours            ; setup font palette
          ld de,palette+(96*2)
          ld bc,32*2
          ldir      
          ret
          
;----------------------------------------------------------------------------


set_up_scale_pattern


          ld e,0                        ; fill first 128K of VRAM with a zeroes 
          ld c,0                        ; IRQs must of disabled
cbp2b     ld a,c
          ld (vreg_vidpage),a           
          ld a,%00100000                
          out (sys_mem_select),a        
          ld hl,0
cbp1b     ld (hl),0
          inc hl
          ld (hl),0
          inc hl
          ld a,h
          or l
          jr nz,cbp1b
          ld a,%00000000
          out (sys_mem_select),a
          ld a,c
          add a,8
          ld c,a
          cp 16
          jr nz,cbp2b


          
          ld a,15                       ;build 128 scaled line iterations
          out (sys_mem_select),a        
          ld hl,$8000
          ld bc,$8000
          xor a
          call kjt_bchl_memfill         ;clear pattern buffer
                    
          ld c,2                        
          ld ix,scale_factors
          ld hl,$8180                   ;origin in x centre of display (+$8000 to avoid 0-fff exclusion)
linelp    ld e,(ix)
          ld d,(ix+1)                   ;de = scale step (d = int / e = fractional)
          inc ix
          inc ix
          push hl
          ld a,l
          sub c                         ;adjust start plot point (left side)
          ld l,a
          push hl
          pop iy
          ld b,c                        ;number of pixels on this line / 2
          inc b
          ld hl,$8000                   ;first pixel colour index * 256
collpl    ld a,h
          cp $80
          jr nz,nottran1
          xor a
nottran1  ld (iy),a
          inc iy                        ;next pixel along
          add hl,de                     ;add scale step to tally
          djnz collpl
          
          pop hl
          push hl
          
          push hl
          pop iy
          ld b,c
          ld hl,$c000                   ;middle pixel colour index * 256
collpr    ld a,h
          cp $fe
          jr c,nottran2
          xor a
nottran2  ld (iy),a
          inc iy                        ;next pixel along
          add hl,de                     ;add scale step to tally
          djnz collpr
          
          pop hl                        
          inc h                         ;next line down
          inc c                         
          ld a,c
          cp 128
          jr nz,linelp


          xor a
          ld (vreg_vidpage),a
          ld a,%00101111                
          out (sys_mem_select),a        
          ld de,$80
          ld hl,$8000
          ld a,$80
doublp    ld bc,$100
          ldir                          ;copy pattern to VRAM $0
          inc d
          dec a
          jr nz,doublp        
          xor a
          out (sys_mem_select),a




          ld hl,sin_table               ; upload sine table to math unit
          ld de,mult_table
          ld bc,$200
          ldir      

          ret
          



;-------------------------------------------------------------------------------------------

set_up_linecop_lists

image_colours equ $8000                 ;loaded at boot into bank 1

          ld a,%00010010
          out (sys_mem_select),a        ;use alternative write page, source page = 1
          ld a,14
          out (sys_alt_write_page),a

          ld hl,$8000
          ld (hl),$18                   ;wait for line $28 (use data from clear VRAM $10000 
          inc hl                        ;until dynamic data lines start)
          ld (hl),$c0
          inc hl
          ld (hl),$40                   ;reg reg = $0240 bitmap address lo 
          inc hl
          ld (hl),$82                   
          inc hl
          ld (hl),$40                   ;bitmap 7:0 (side scroll offset)
          inc hl
          ld (hl),$40                   ;write and move to next reg
          inc hl
          ld (hl),$01                   ;bitmap 15:8
          inc hl
          ld (hl),$40                   ;write and move to next reg
          inc hl
          ld (hl),$00                   ;bitmap 18:16
          inc hl
          ld (hl),$00                   ;write to reg
          inc hl
          ld (hl),$01                   ;select reg = $0201 video control
          inc hl
          ld (hl),$82                   
          inc hl
          ld (hl),$a0                   ;BPreg set B                  
          inc hl
          ld (hl),$00                   
          inc hl


          ld (hl),$ff                   ;one above first line to wait for (dynamically updated by prog)
          inc hl
          ld (hl),$c0
          inc hl
          ld (hl),$01                   ;reg = 201
          inc hl
          ld (hl),$82                   
          inc hl
          ld (hl),$80                   ;change to reg set A (no effect until next scanline)
          inc hl
          ld (hl),$00                   
          inc hl
          ld (hl),$41                   ;update bitplane pointer ready for first line     
          inc hl
          ld (hl),$82                   ;set reg $241 = bitmap address (15:8)
          inc hl
          ld (hl),$fc                   ;bitmap addr byte (scaled line image select) DYNAMIC
          inc hl
          ld (hl),$00                   ;write instruction
          inc hl


          ld (hl),$ff                   ;first line to wait for (dynamically updated by prog)
          inc hl
          ld (hl),$c0
          inc hl
          ld (hl),$00                   ;not actually required (for testing: set reg 0 = palette)
          inc hl
          ld (hl),$80                   ;not actually required
          inc hl
          ld (hl),$00                   ;not actually required
          inc hl
          ld (hl),$00                   ;not actually required
          inc hl
          ld (hl),$0d                   ;select reg 20d (linecop PC addr lo)
          inc hl
          ld (hl),$82
          inc hl
          ld (hl),$01                   ;write new location lo value (and inc reg)
          inc hl
          ld (hl),$40
          inc hl
          ld (hl),$02                   ;write new location hi value and restart linecop from new PC
          inc hl                        
          ld (hl),$10                   ;write location and restart




          ld hl,$8100                   ;end of line list  - use data from clear VRAM $10000+ again
          ld (hl),$01                   ;select reg = $0201
          inc hl
          ld (hl),$82                   
          inc hl
          ld (hl),$a0                   ;set BPL Reg B, no effect till next scanline      
          inc hl
          ld (hl),$00                   
          inc hl

          ld (hl),$0e                   ;select reg 20e (linecop PC addr hi)
          inc hl
          ld (hl),$82
          inc hl
          ld (hl),$00                   ;write new LCPC hi (back to $000)
          inc hl
          ld (hl),$00
          inc hl
          
          ld (hl),$ff                   ;wait for $1ff - end list
          inc hl                        
          ld (hl),$c1



          ld hl,$8200                   ;first line entry (top line of source image)
          ld ix,image_colours
          ld c,127                      ;number of lines in source image (colour combinations)
                    
lcrowlp   ld (hl),$41                   
          inc hl
          ld (hl),$82                   ;set reg = bitmap address (15:8)
          inc hl
          ld (hl),$fc                   ;bitmap addr byte (scaled line image select) DYNAMIC
          inc hl
          ld (hl),$00                   ;write instruction
          inc hl

          ld (hl),$0f                   ;select reg $20f - palette control
          inc hl
          ld (hl),$82
          inc hl
          ld (hl),$00                   ;Dynamic live palette select bits (no effect till next scanline)
          inc hl
          ld (hl),$00                   ;write instruction
          inc hl
          ld (hl),$02                   ;Dynamic target palette select bits (immediate effect)
          inc hl
          ld (hl),$00                   ;write instruction
          inc hl
          
          ld (hl),$04                   ;set reg = first palette index
          inc hl
          ld (hl),$81
          inc hl
          ld b,123                      ;max number of colours to update
linepal   ld a,(ix)                     ;(ix);write palette colour lo + inc reg
          inc ix
          ld (hl),a
          inc hl
          ld (hl),$40
          inc hl
          ld a,(ix)                     ;(ix);write palette colour hi + inc reg
          inc ix
          ld (hl),a
          inc hl
          ld (hl),$40
          inc hl
          djnz linepal

          ld (hl),$51                   ;next line to wait for (dynamically updated by program)
          inc hl
          ld (hl),$c0                   ;this is changed to $80 (setreg) if its the last line
          inc hl    
          ld (hl),$0d                   ;select reg 20d (linecop addr lo)
          inc hl
          ld (hl),$82
          inc hl
          ld (hl),$01                   ;write new location lo (keep bit 0 set)
          inc hl
          ld (hl),$40
          inc hl
          ld (hl),$00                   ;write new location hi (dynamically updated by program),
          inc hl                        ;and restart linecop from new location
          ld (hl),$10
          inc hl
          
          ld a,h
          or a
          jr nz,samepage
          ld a,15                       ;if filled lower 32KB of linecop memory, switch
          out (sys_alt_write_page),a    ;bank to upper 32KB
          ld h,$80
          
samepage  dec c
          jr nz,lcrowlp
          xor a
          out (sys_mem_select),a        ;back to bank 0
          ret

;--------------------------------------------------------------------------------------------

set_up_sprites
          

          ld ix,sprite_registers        ;need to set up both sprite register sets
          call su_bdspr
          ld ix,sprite_registers+$100
          call su_bdspr
          
          ld ix,spr_registers+(23*4)
          call su_lspr
          ld ix,spr_registers+$100+(23*4)
          call su_lspr
                    
          ld ix,spr_registers+(30*4)
          call su_sspr
          ld ix,spr_registers+$100+(30*4)
          call su_sspr

          ret
          
          
          
su_bdspr  ld a,$00                      ;backdrop sprites
          ld (mod_instr+1),a            ;set up self modifying instruction
          ld hl,$70                     ;x 
          ld de,$10
          ld c,0                        ;def
          ld b,23
susl      ld (ix),l                     ;x
mod_instr ld a,$00
          or h
          ld (ix+1),a                   ;settings
          ld (ix+2),$ff                 ;y 
          ld (ix+3),c                   ;def
          ld a,c
          add a,15
          ld c,a
          jr nc,nomod
          ld a,$04
          ld (mod_instr+1),a
nomod     add hl,de
          inc ix
          inc ix
          inc ix
          inc ix
          djnz susl
          ret


                    
su_lspr   ld a,$76                      ;logo sprites x
          ld c,$59                      ;1st def
          ld b,7
          ld de,4
sulsplp   ld (ix),a                     ;x
          ld (ix+1),$27                 ;height/msbs
          ld (ix+2),$28                 ;y
          ld (ix+3),c                   ;def
          add ix,de
          inc c
          inc c
          add a,16
          djnz sulsplp
          ret
          

          

su_sspr   ld b,24                       ;scroller sprites
          ld de,4
suscsplp  ld (ix),0                     ;x offscreen at init
          ld (ix+1),$14                 ;height/msbs
          ld (ix+2),$78                 ;y
          ld (ix+3),$c5                 ;def (space)
          add ix,de
          djnz suscsplp
          ret

          
          
;--------------------------------------------------------------------------------------------


build_line_list


; this makes a 256 entry raster line list, where the entries are the line of the source image required


          ld hl,0
          ld (mult_table),hl


          ld hl,line_list               ;clear the previous line list
          ld b,64
          xor a
clrll     ld (hl),a
          inc hl
          ld (hl),a
          inc hl
          ld (hl),a
          inc hl
          ld (hl),a
          inc hl
          djnz clrll
          
          
          ld a,(rotation)
          ld (mult_index),a
          ld a,(size)
          ld e,a                        ;de = max y-coord above centre line
          ld d,0
          ld (mult_write),de
          ld hl,(mult_read)             
          bit 7,h
          jr nz,inverted                ;if hl is negetive flip the image
          
          inc hl                        
          ld b,h                        ;bc = lines above origin
          ld c,l
          add hl,hl                     ;hl = 2 to 202 (+2 increments for word list)
          ld e,l
          ld d,0
          ld hl,scale_factors-2
          add hl,de
          ld e,(hl)
          inc hl
          ld d,(hl)                     ;de = y scale constant [int:frac]

                                        
          ld hl,128                     ;centre of line list
          ld a,(video_mode)
          or a
          jr z,palmode
          ld hl,112
palmode   xor a
          sbc hl,bc
          ld a,l
          ld (first_line),a
          ld bc,line_list
          add hl,bc
          push hl
          pop ix                        ;ix = index of first raster line with image data
          ld hl,$100                    ;source image line selection (*256) at this raster line
mllp      ld (ix),h
          add hl,de                     ;add constant to line selection tally
          inc ix                        ;next raster line
          ld a,h
          cp $7c
          jr c,mllp
          ret
                    
          
          
inverted  ex de,hl                      ;change 0 to -100 -> 0 to 100
          ld hl,0
          xor a
          sbc hl,de
          inc hl                        
          ld b,h                        ;bc = lines above origin
          ld c,l
          add hl,hl                     ;hl = 2 to 202 (+2 increments for word list)
          ld e,l
          ld d,0
          ld hl,scale_factors-2
          add hl,de
          ld e,(hl)
          inc hl
          ld d,(hl)                     ;de = y scale constant [int:frac]

                                        
          ld hl,128                     ;centre of line list
          ld a,(video_mode)
          or a
          jr z,palmode2
          ld hl,112
palmode2  xor a
          sbc hl,bc
          ld a,l
          ld (first_line),a
          ld bc,line_list
          add hl,bc
          push hl
          pop ix                        ;ix = index of first raster line with image data
          ld hl,$7f00                   ;source image line selection (*256) at this raster line
mllp2     ld (ix),h
          inc ix                        ;next raster line
          xor a
          sbc hl,de                     ;sub constant from line selection tally
          jr nc,mllp2
          ret
          

;--------------------------------------------------------------------------------------------

build_scale_list

          ld a,(rotation)
          ld (mult_index),a
          ld b,124
          ld hl,coord_list
          ld ix,124                     ;y coord range = +124 to -124
sloop     ld (mult_write),ix  
          ld a,(mult_read)
          add a,124
          ld (hl),a                     ;range = 0 to 248
          inc hl
          dec ix
          dec ix
          djnz sloop
          

          ld a,(size)
          ld c,a
          ld a,(rotation)               ;list of line widths (for perspective effect)
          sub 64
          ld (mult_index),a
          ld b,124
          ld hl,width_list
          ld ix,124                     ;z coord range = +124 to -124
sloop2    ld (mult_write),ix  
          ld a,(mult_read)
          sra a
          sra a                         ;approx -31 to +31
          sra a
          add a,c                       ;add minsize + midpoint
          sla a
          ld (hl),a                     
          inc hl
          dec ix
          dec ix
          djnz sloop2
          ret
                    
          
;--------------------------------------------------------------------------------------------


build_linecop_list

          ld a,(restore_wait_bank)      ;restore previous last wait instruction
          or a                          ;in linecop list (was changed to a setreg so
          jr z,norestw                  ;as to have no effect)
          out (sys_mem_select),a
          ld ix,(restore_wait_addr)
          ld (ix+1),$c0                 

norestw
          ld a,14
          out (sys_mem_select),a
          ld hl,(x_offset)              
          ld a,l
          ld ($8004),a
          ld a,h
          ld ($8006),a

          ld d,a                        ;x offset bit 8
          ld e,0                        ;default colour buffer
          exx
          ld iy,scale_list

          ld a,(first_line)             ;first raster line with a image line selection
          ld b,a
          ld e,a
          ld d,0
          ld hl,line_list
          add hl,de
          ld a,(hl)
          sla a
          ld ($8022),a                  ;set linecop address for first image line

          ld a,(hl)           
          ld d,a                        ;d = source image line required
          ld c,a                        ;c = ""
          ld a,b                        ;b = raster line
          add a,$11                     ;adjust for y display window
          ld ($8018),a                  ;set first wait line at start of linecop list 
          sla d                         ;convert line selection to linecop address (flat 0-64K)

          dec a
          ld ($800e),a                  ;set the wait line above first line
          ld a,c              
          exx
          ld c,a
          ld b,0
          ld hl,width_list
          add hl,bc
          ld a,(hl)                     
          or d
          exx                 
          ld ($8016),a                  ;set width of first line (bitplane pointer 15:8) 


mlcl_lp   ld a,14                       ;convert linecop flat address to CPU upper bank
          bit 7,d
          jr z,bankok
          inc a
bankok    set 7,d
          out (sys_mem_select),a        ;DE now in range 8000-ffff, bank set appropriately


          ld a,c              
          exx
          ld c,a
          ld b,0
          ld hl,width_list
          add hl,bc
          ld a,(hl)                     
          or d
          exx                 
          ld e,2
          ld (de),a                     ;set width of line 

          exx                 
          inc e
          ld a,e                        ;colour buffer swap
          and 1
          exx
          ld e,6
          ld (de),a
          or 2
          ld e,8
          ld (de),a


          ld e,$f8  
          set 0,d                       ;add $100 to de
          push de
          pop ix                        ;ix = location where waitline of next raster line is held
          
fnxt      inc hl                        ;move to next entry in line list 
          inc b                         
          ld a,(hl)
          or a
          jr z,lc_end                   ;line selection is zero = end of the linecop list
          cp c                          ;if the line selection is the same as that on the previous raster
          jr z,fnxt                     ;line skip ahead until it changes       
          ld d,a                        
          ld c,a                        ;note the new line entry
                    
          ld a,b
          add a,$11                     ;put next line to wait for at end of current line
          ld (ix),a
          sla d                         ;convert line selection to linecop addr
          ld (ix+6),d                   ;put link to next line at end of current line (update linecop PC)
          jr mlcl_lp
          
lc_end    ld (ix+1),$80                 ;swap the wait for a set reg instruction (no op)
          ld (ix+6),$01                 ;reload linecop PC with $0100 = end of list
          in a,(sys_mem_select)
          ld (restore_wait_bank),a
          ld (restore_wait_addr),ix
          xor a
          out (sys_mem_select),a
          ret
          
          
;-------------------------------------------------------------------------------------------

          
update_sprites



          ld a,(bdspr_sin)              ;update bd sprite regs every frame
          ld (mult_index),a
          ld hl,230
          ld (mult_write),hl
          ld bc,(mult_read)
          ld a,$ff
          sub c
          ld c,a
          ld hl,sprite_registers+2
          ld de,(spr_buffer)
          add hl,de
          ld de,4
          ld b,23
mbdslp    ld (hl),c           
          add hl,de
          djnz mbdslp


          ld a,(logospr_sin)            ;update logo sprite regs every frame
          ld (mult_index),a   
          ld hl,(logo_max)
          ld (mult_write),hl
          ld bc,(mult_read)
          ld e,$ec
          ld a,(video_mode)
          or a
          jr z,pal_lsp
          ld e,$cc
pal_lsp   ld a,e
          sub c
          jr nc,spros
          ld a,$ff
spros     ld c,a
          ld l,$25
          ld a,(stage)
          cp $e0
          jr nz,lspaok
          ld c,$20
          ld l,$27
lspaok    ld ix,sprite_registers+(23*4)
          ld de,(spr_buffer)
          add ix,de 
          ld de,4
          ld b,7
mlslp     ld (ix+1),l
          ld (ix+2),c                   
          add ix,de
          djnz mlslp

          ret
          

;--------------------------------------------------------------------------------------------

anim      ld a,(stage)
          cp $e0
          jr nz,nots_e0
          ld a,(bdspr_sin)              ;backdrop sprites arrive
          inc a
          ld (bdspr_sin),a
          cp 64
          jr nz,noteobds
          ld a,$f0
          ld (stage),a
noteobds  ret



          
nots_e0   cp $f0
          jr nz,nots_f0
          ld a,(arc_speed)
          ld b,a    
          ld a,(logospr_sin)            ;logo sprites arrive
          add a,b
          ld (logospr_sin),a
          bit 7,a
          ret z
          sub $80
          ld (logospr_sin),a
          ld a,(arc_speed)
          inc a
          ld (arc_speed),a
          ld hl,(logo_max)              ;at bounce point reduce amp
          srl h
          rr l
          ld a,h
          or l
          jr nz,ampok
          ld hl,0
          ld a,$f8
          ld (stage),a
          ld bc,250
          ld (waittime),bc
ampok     ld (logo_max),hl
          ret




nots_f0   cp $f8
          jr nz,nots_f8
          ld hl,(waittime)
          dec hl
          ld (waittime),hl
          ld a,h
          or l
          ret nz
          ld a,0
          ld (stage),a
          ret




nots_f8   cp 0
          jr nz,nots0
          ld a,(arrive_sine)            ;4096 col pic arriving
          inc a
          inc a
          ld (arrive_sine),a
          ld (mult_index),a
          ld hl,(arrive_max)
          ld de,25
          xor a
          sbc hl,de
ndam      ld (arrive_max),hl
          sra h
          rr l
          sra h
          rr l
          sra h
          rr l
          ld a,h
          cp $ff
          jr nz,arrok
          ld hl,0
          ld a,1
          ld (stage),a
          ld de,215
          ld (waittime),de
arrok     ld (mult_write),hl
          ld hl,(mult_read)
          ld de,72
          add hl,de
          ld (x_offset),hl
          ret
          
          
          
nots0     cp 1                          ;waiting
          jr nz,nots1
          ld hl,(waittime)
          dec hl
          ld (waittime),hl
          ld a,h
          or l
          ret nz
          ld a,2
          ld (stage),a
          ret




nots1     cp 2                          ;zooming
          jr nz,nots2
          ld a,(zoom_sine)
          dec a
          dec a
          ld (zoom_sine),a
          ld (mult_index),a
          ld hl,40
          ld (mult_write),hl
          ld hl,(mult_read)
          ld de,61
          add hl,de
          ld a,l
          ld (size),a

          ld hl,(zoomtime)
          dec hl
          ld (zoomtime),hl
          ld a,h
          or l
          ret nz
          ld a,3
          ld (stage),a
          ld hl,100
          ld (waittime),hl
          ret
          
          

nots2     cp 3                          ;waiting
          jr nz,nots3
          ld hl,(waittime)
          dec hl
          ld (waittime),hl
          ld a,h
          or l
          ret nz
          ld a,4
          ld (stage),a
          ret
          
          
          
nots3     cp 4                          ;rotating / zooming
          jr nz,nots4
          ld hl,rotation
          inc (hl)
          inc (hl)
          
          ld a,(zoom_sine)
          inc a
          ld (zoom_sine),a
          ld (mult_index),a
          ld hl,20                      ;range = -25 to +25
          ld (mult_write),hl
          ld hl,(mult_read)
          ld de,65
          add hl,de
          ld a,l
          ld (size),a
          ret


nots4     ret

;-------------------------------------------------------------------------------------------

scroller

          ld a,(scroll_amp)
          ld l,a
          ld h,0
          ld (mult_write),hl
          ld a,(scroll_sin)
          ld b,a
          inc b
          xor a
          or l
          jr nz,incamp                  ;if scroll amplitude = 0, dont swap priority
          ld b,0                        ;keep scroller in foreground
          ld a,1
          ld (spr_pri),a
incamp    ld a,b
          ld (scroll_sin),a
          ld (mult_index),a
          add a,64
          and $7f
          jr nz,noswpri
          ld a,(spr_pri)                ;flip sprite priority at 0 and 128
          xor 1
          ld (spr_pri),a      
noswpri   ld hl,(mult_read)
          ld a,(scroll_ypos)
          ld e,a
          ld d,0
          add hl,de
          ld c,l                        ;final y pos


          ld ix,sprite_registers+(30*4) ;copy sprite coords etc to regs every frame
          ld de,(spr_buffer)  
          add ix,de
          ld b,24
          ld iy,scroll_xcoords
ssprloop  ld l,(iy)
          ld h,(iy+1)
          ld de,$64                     ;convert x to sprite location x
          add hl,de
          ld (ix),l
          ld a,(spr_pri)
          rrca
          or h
          or $14                        ;size in 7:4 and def MSB hi
          ld (ix+1),a
          ld (ix+2),c
          ld a,(iy+48)                  ;def list
          add a,$a5                     ;convert ascii to sprite def (font at spr_def $1c5)
          ld (ix+3),a
          inc iy
          inc iy
          ld de,4
          add ix,de
          djnz ssprloop
          
          

          ld a,(pause_seconds)
          or a
          jr z,nopause
          ld a,(pause_frames)
          dec a
          jr nz,fcnz
          ld a,50
fcnz      ld (pause_frames),a
          ret nz
          ld a,(pause_seconds)
          dec a
          ld (pause_seconds),a
          ret
nopause   ld iy,scroll_xcoords          ;shift all sprites to left
          ld a,(scroll_speed)
          ld c,a
          ld b,24
shfscsp   ld l,(iy)
          ld h,(iy+1)
          ld d,0
          ld e,c
          xor a
          sbc hl,de
          call c,new_char
          ld (iy),l
          ld (iy+1),h
          inc iy
          inc iy
          djnz shfscsp
          ret
          
new_char  ex de,hl
scrloop   ld hl,(scrollmsg_loc)
          ld a,(hl)
          or a
          jr nz,nowrap
          ld hl,wrap_point
          ld (scrollmsg_loc),hl
          jr scrloop

nowrap    cp 1                          ;if encounter a 1, take the next byte
          jr nz,notone                  ;as seconds to wait
          inc hl
          ld a,(hl)
          ld (pause_seconds),a
          ld a,50
          ld (pause_frames),a
scrdone   inc hl
          ld a,(hl)
          jr notthree

notone    cp 2                          ;if two, the next byte is the scroll speed
          jr nz,nottwo
          inc hl
          ld a,(hl)
          ld (scroll_speed),a
          jr scrdone

nottwo    cp 3                          ;if three the next byte is the scroll y position 
          jr nz,notthree      
          inc hl
          ld a,(hl)
          ld (scroll_ypos),a
          jr scrdone

notthree  cp 4
          jr nz,notfour
          inc hl
          ld a,(hl)
          ld (scroll_amp),a
          jr scrdone
          
notfour   inc hl
          ld (scrollmsg_loc),hl
          ld (iy+48),a                                      

endscr    ex de,hl
          ld de,368+16                  ;put sprite on right side     
          add hl,de
          ret
          

;---------------------------------------------------------------------------------------------------------

bulkfile_fn         db "parity.exe",0             ;same as main program, adjusted index_start:

index_start_lo      equ prog_end-my_location      ;low word of offset to bulkfile

index_start_hi      equ 0                         ;hi word of offset to bulkfile


          include "bulk_file_loader.asm"

;---------------------------------------------------------------------------------------------------------

dot       ld hl,dot_txt
          call kjt_print_string
          ret
          
          
load_error

          push af
          ld hl,load_err_txt
          call kjt_print_string
          pop af
          ret


dot_txt             db ".",0

loading_txt         db "Loading",0
          
load_err_txt        db " Load error",11,0

bgnd_spr_fn         db "BGNDSPR.BIN",0
logo_spr_fn         db "LOGOSPR.BIN",0
font_spr_fn         db "FONTSPR.BIN",0
samples_fn          db "SAMPLES.BIN",0
zoompic_fn          db "12BITPAL.BIN",0

video_mode          db 0
          
;----------------------------------------------------------------------------------------------------------

spr_buffer          dw 0

scroll_speed        db 4
scroll_ypos         db $80
scroll_amp          db 0
scroll_sin          db 0
spr_pri             db 0

scroll_xcoords      dw $000,$010,$020,$030,$040,$050,$060,$070
                    dw $080,$090,$0a0,$0b0,$0c0,$0d0,$0e0,$0f0
                    dw $100,$110,$120,$130,$140,$150,$160,$170
                    ds 48,$20                     ;for defs
                    
                    
scrollmsg_loc       dw scroll_text

;--------------------------------------------------------------------------------------------------------

scroll_text         db " ",3,$84," ",1,4 ; start delay
                    
                    db " ",2,8
                    
                    db "     IT",$27,"S ANOTHER V6Z80P TEST DEMO THINGY!                               "
                    
                    db 2,4
                    
                    DB "HERE",$27,"S A 4096 COLOUR PIC.....                       "
                    
                    DB 1,1," ",2,6
                    
                    DB "NICE, BUT LET",$27,"S GIVE THE PLUMAGE SOME...                      "
                    
                    DB 2,8
                    DB "ZOOMAGE!       "
                    DB 1,4,"               "
                    
                    DB 2,4
                    db " ",1,3
          
                    db "   AND PERHAPS A SPOT OF ROTATION TOO...                             "
                    
                    DB 1,4
                    
                    DB "AS A 2D PLATFORM, MY V6Z80P ARCHITECTURE ACHIEVES THESE MIND BLOWING "
                    DB "(IN 1990) EFFECTS WITH ITS LINE-SYNC",$27,"D CO-PROCESSOR - THIS DEMO IS REALLY A TEST THEREOF..                         "
                    db 2,8," ",3,$40,"LOOKS LIKE IT ALL WORKS SO WE CAN GET ON WITH THE HIGHLY IMPORTANT PART:                                   "
                    db 2,6," ",3,$c0
                    db "HERE COME THE GREETINGS...                            "
                    db 3,$7a," ",2,4
                    db "HELLO TO: ",2,6
                    
                    DB "JIM B,",2,8," GRAHAM C,",2,$a," VALEN,",2,$c," DANIEL I,",2,$e," MARTIN M,",2,$10," BRANISLAV B, HENK K, "
                    DB "DAVID R, SLAWOMIR B, BLAH BLAH BOILED BEEF AND PARROTS, SURELY NOBODY WILL READ THIS, PETER MCQ, "
                    DB "GREY, HUW W, STEVE G, RICHARD D, ALAN G, DANIEL T, IVAN, BOOTBLOCK, PETER G "
                    DB "AND ANYONE I FORGOT...                      "
                    
                    DB 2,4
                    
                    DB "OOOPS! TOO FAST... "
                    
                    DB 2,8
                    
                    DB "                              LETS REPEAT THAT, BUT A LITTLE SLOWER.. "
                    
                    db 4,$60,"AND WITH EXTRA WAVINESS..  "
                    
                    db 2,5
                    
wrap_point          DB "HELLO TO: "
                    
                    DB "JIM B, GRAHAM C, VALEN, DANIEL I, MARTIN M, BRANISLAV B, HENK K, "
                    DB "DAVID R, SLAWOMIR B, TAN YONG LAK, BRANDER, ERIK L, PETER MCQ, "
                    DB "GREY, HUW W, STEVE G, GEOFF O, RICHARD D, ALAN G, JIM F-A, DANIEL T, IVAN, BOOTBLOCK, PETER G "
                    DB "AND ANYONE I FORGOT...                      "

                    DB "AND SO IT",$27,"S THE END OF ANOTHER SCROLLING MESSAGE. I GUESS THE ONLY THINGS LEFT TO SAY "
                    DB "ARE.. CODE: PHIL RUSTON 2009, GRAPHICS: GOOGLE IMAGE SEARCH (!), "
                    DB "TUNE: ZEROES AND ONES BY NOISE UNIT 1993....                    GOTTA GO, BE SEEING YOU!"
                    DB "                                                  ",2,8,"8 BIT FOREVER :)                                           ",2,5," "
                    DB 0
                    


;codes 1 = pause [n seconds]
;      2 = speed [pixels per frame]
;      3 = set y origin
;      4 = set y wave amplitude

;-------------------------------------------------------------------------------------------

pause_seconds       db 0
pause_frames        db 0

restore_wait_bank   db 0
restore_wait_addr   dw 0

stage               db $e0

bdspr_sin           db 0

logospr_sin         db 64
logo_max            dw 236
arc_speed           db 2

arrive_sine         db 64
arrive_max          dw 240 * 8
x_offset            dw 320

zoom_sine           db 128
waittime            dw 0
zoomtime            dw 386

rotation            db 64

first_line          db 0

size                db 62               ;2-128-254 (step 2) 128=1:1

line_list           ds 255,0
                    db 255

scale_list          ds 256,127

width_list          ds 128,0

coord_list          ds 128,0

;-----------------------------------------------------------------------------------------------------

sin_table           incbin "sin_table.bin"

scale_factors       dw 32768 / $02
                    dw 32768 / $04
                    dw 32768 / $06
                    dw 32768 / $08
                    dw 32768 / $0a
                    dw 32768 / $0c
                    dw 32768 / $0e
                    
                    dw 32768 / $10
                    dw 32768 / $12
                    dw 32768 / $14
                    dw 32768 / $16
                    dw 32768 / $18
                    dw 32768 / $1a
                    dw 32768 / $1c
                    dw 32768 / $1e
                    
                    dw 32768 / $20
                    dw 32768 / $22
                    dw 32768 / $24
                    dw 32768 / $26
                    dw 32768 / $28
                    dw 32768 / $2a
                    dw 32768 / $2c
                    dw 32768 / $2e
          
                    dw 32768 / $30
                    dw 32768 / $32
                    dw 32768 / $34
                    dw 32768 / $36
                    dw 32768 / $38
                    dw 32768 / $3a
                    dw 32768 / $3c
                    dw 32768 / $3e
          
                    dw 32768 / $40
                    dw 32768 / $42
                    dw 32768 / $44
                    dw 32768 / $46
                    dw 32768 / $48
                    dw 32768 / $4a
                    dw 32768 / $4c
                    dw 32768 / $4e
                    
                    dw 32768 / $50
                    dw 32768 / $52
                    dw 32768 / $54
                    dw 32768 / $56
                    dw 32768 / $58
                    dw 32768 / $5a
                    dw 32768 / $5c
                    dw 32768 / $5e

                    dw 32768 / $60
                    dw 32768 / $62
                    dw 32768 / $64
                    dw 32768 / $66
                    dw 32768 / $68
                    dw 32768 / $6a
                    dw 32768 / $6c
                    dw 32768 / $6e
          
                    dw 32768 / $70
                    dw 32768 / $72
                    dw 32768 / $74
                    dw 32768 / $76
                    dw 32768 / $78
                    dw 32768 / $7a
                    dw 32768 / $7c
                    dw 32768 / $7e
                                        
                    dw 32768 / $80
                    dw 32768 / $82
                    dw 32768 / $84
                    dw 32768 / $86
                    dw 32768 / $88
                    dw 32768 / $8a
                    dw 32768 / $8c
                    dw 32768 / $8e
                    
                    dw 32768 / $90
                    dw 32768 / $92
                    dw 32768 / $94
                    dw 32768 / $96
                    dw 32768 / $98
                    dw 32768 / $9a
                    dw 32768 / $9c
                    dw 32768 / $9e

                    dw 32768 / $a0
                    dw 32768 / $a2
                    dw 32768 / $a4
                    dw 32768 / $a6
                    dw 32768 / $a8
                    dw 32768 / $aa
                    dw 32768 / $ac
                    dw 32768 / $ae
          
                    dw 32768 / $b0
                    dw 32768 / $b2
                    dw 32768 / $b4
                    dw 32768 / $b6
                    dw 32768 / $b8
                    dw 32768 / $ba
                    dw 32768 / $bc
                    dw 32768 / $be
                                        
                    dw 32768 / $c0
                    dw 32768 / $c2
                    dw 32768 / $c4
                    dw 32768 / $c6
                    dw 32768 / $c8
                    dw 32768 / $ca
                    dw 32768 / $cc
                    dw 32768 / $ce
                    
                    dw 32768 / $d0
                    dw 32768 / $d2
                    dw 32768 / $d4
                    dw 32768 / $d6
                    dw 32768 / $d8
                    dw 32768 / $da
                    dw 32768 / $dc
                    dw 32768 / $de

                    dw 32768 / $e0
                    dw 32768 / $e2
                    dw 32768 / $e4
                    dw 32768 / $e6
                    dw 32768 / $e8
                    dw 32768 / $ea
                    dw 32768 / $ec
                    dw 32768 / $ee
          
                    dw 32768 / $f0
                    dw 32768 / $f2
                    dw 32768 / $f4
                    dw 32768 / $f6
                    dw 32768 / $f8
                    dw 32768 / $fa
                    dw 32768 / $fc
                    dw 32768 / $fe

;------------------------------------------------------------------------------------------

bgnd_colours        incbin "background_palette.bin"

font_colours        incbin "font_palette.bin"

;------------------------------------------------------------------------------------------

include             "50Hz_60Hz_Protracker_code_v513.asm"

                    org (($+2)/2)*2               ;WORD align song module in RAM

music_module        incbin "tune.pat"
                    
;------------------------------------------------------------------------------------------

prog_end