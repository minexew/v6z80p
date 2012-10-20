;---------------------------------------------------------------------------------------
; SHOWSND - A util to browse system memory for sound samples - v0.01 by Phil Ruston 2012
;---------------------------------------------------------------------------------------

;---Standard header for OSCA and FLOS ---------------------------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000

window_width_pixels           equ 320
          
;---------------------------------------------------------------------------------------------
; Init
;---------------------------------------------------------------------------------------------

required_osca       equ $672
include             "flos_based_programs\code_library\program_header\inc\test_osca_version.asm"

;-------- Parse command line arguments ---------------------------------------------------------

          ld a,(hl)                     ; examine argument text, if none, run with default settings
          or a
          jp z,no_args
          
;-------------------------------------------------------------------------------------------------

parse_args

          push hl
          pop ix
          call hex_string_to_numeric              ;ix = source, dehl = value
          ret nz
          ld (wave_addr),hl
          ld a,e
          ld (wave_addr+2),a

          call find_next_arg
          ret nz    
          call hex_string_to_numeric              ;ix = source, dehl = value
          ret nz
          ld (wave_length),hl
          ld a,e
          ld (wave_length+2),a
                              
          call find_next_arg
          ret nz
          call hex_string_to_numeric              ;ix = source, dehl = value
          ret nz
          ld (wave_period),hl
                    

no_args

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
got_mode  ld a,b                                  ;0=PAL, 1=NTSC, 2=VGA

          ld e,a
          ld d,0
          ld hl,vid_mode_split_list
          add hl,de
          ld a,(hl)
          ld (lcop_spl1),a                        ;adjust linecop split depending on video mode
          
;-------------------------------------------------------------------------------------------

          call kjt_get_cursor_position            ; back up some flos display characteristics 
          ld (orig_cursor),bc
          call w_backup_display
          call kjt_clear_screen
                    
          di                                      ; write $fe to first 65 lines * 320 pixels of VRAM
          xor a
          ld (vreg_vidpage),a
          ld a,$20
          out (sys_mem_select),a                  ; all writes to VRAM mode
          ld hl,0
          ld bc,window_width_pixels*65
clrvrlp   ld (hl),$fe
          inc hl
          dec bc
          ld a,b
          or c
          jr nz,clrvrlp
          xor a
          out (sys_mem_select),a
          ei


          ld hl,63*window_width_pixels            ; put y-line offsets in lookup table
          ld de,window_width_pixels               ; for use by linedraw system 
          ld ix,ylookup_table                     ; (64 entries)
          ld b,64
sumtlp1   ld (ix),l
          ld (ix+1),h
          xor a
          sbc hl,de
          inc ix
          inc ix
          djnz sumtlp1
                    
          ld a,14                                 ; copy linecop list to end of linecop accessible memory                         
          call kjt_set_bank
          ld hl,my_linecoplist
          ld de,$ffe0
          ld bc,end_my_linecoplist-my_linecoplist
          ldir                                    
          xor a                                   ; first word of sample RAM is zero (used for silent loops)
          call kjt_set_bank

          ld hl,0
          ld (palette+$1fc),hl
          ld hl,$0f0                              ; set colour for chunky pixel mode (line draw)
          ld (palette+$1fe),hl

          ld hl,linedraw_constants                ; copy the video offset constants to the 
          ld de,linedraw_lut0                     ; line draw hardware lookup table
          ld bc,16
          ldir

          ld hl,0                                 ; 2nd video pointer - used for split screen
          ld (bitplane0b_loc),hl
          ld (bitplane0b_loc+2),hl

          ld de,$ffe1
          ld (vreg_linecop_lo),de                 ; set Linecop address and activate (bit 0 set)

          
          ld a,0                                  ; window number
          ld b,0                                  ; x
          ld c,1                                  ; y
          call draw_window              

          ld a,5                                  ; fill in and show default values for addr/len/per
          call w_set_element_selection
          call w_get_selected_element_data_location         
          ld hl,(wave_period)
          ld de,0
          call req_test_num_limits

          ld a,3
          call w_set_element_selection
          ld a,3
          call w_get_selected_element_data_location
          ld hl,(wave_length)
          ld de,(wave_length+2)
          ld d,0
          call req_test_num_limits
          
          ld a,1
          call w_set_element_selection  
          call w_get_selected_element_data_location
          ld hl,(wave_addr)
          ld de,(wave_addr+2)
          ld d,0
          call req_test_num_limits


          call redraw_wave
          
;---------------------------------------------------------------------------------------------------------

req_loop  call req_show_selection
          call req_show_cursor
          
          ld hl,(wave_addr)
          ld a,(wave_addr+2)
          push af
          push hl
          ld hl,(wave_length)
          ld a,(wave_length+2)
          push af
          push hl
          
          ld hl,(wave_period)
          push hl
          
          ld a,(loop_mode)
          push af
          
          call write_aud_addr
          call write_aud_length
          call write_aud_period
          call write_loop
          call write_onchange
          
          pop bc                                  ;has loop mode changed?
          ld a,(loop_mode)
          cp b
          jr z,lm_noch
          pop hl
          jr lm_ch
          
lm_noch   pop hl                                  ;period changed, play wave (but dont redraw)
          ld de,(wave_period)
          xor a
          sbc hl,de
          jr z,wpsame
lm_ch     pop hl
          pop af
          pop hl
          pop af
          jr plwa
          
wpsame    pop hl                                  ;length changed? need to redraw wave
          ld a,(wave_length+2)
          ld b,a
          pop af
          cp b
          jr nz,rdw1
          ld de,(wave_length)
          xor a
          sbc hl,de
          jr z,wlsame
rdw1      pop hl
          pop af
          jr rdwg
          
wlsame    ld a,(wave_addr+2)                      ;location changed? need to redraw wave
          ld b,a
          pop hl
          pop af
          cp b
          jr nz,rdwg
          ld de,(wave_addr)
          xor a
          sbc hl,de
          jr z,nordwg
rdwg      call redraw_wave
plwa      ld a,(play_on_change)
          or a
          call nz,play_wave
          
          
nordwg    
          ld hl,vreg_read                         ;wait raster
wait_ras1 bit 2,(hl)
          jr z,wait_ras1
wait_ras2 bit 2,(hl)
          jr nz,wait_ras2

          call req_unshow_selection
          ld hl,0
          call kjt_draw_cursor

          call kjt_get_key
          ld (req_current_scancode),a
          ld c,a
          ld a,b
          ld (req_current_ascii_char),a
          ld a,c
          cp $0d
          jp z,req_tab_pressed
          
          ld a,(req_ascii_input_mode)
          or a
          jp nz,nocurs
          ld a,(req_current_scancode)
          cp $72
          jp z,req_down_pressed
          cp $75
          jp z,req_up_pressed
          cp $74
          jp z,req_right_pressed
          cp $6b
          jp z,req_left_pressed

nocurs    ld a,(req_current_scancode)
          cp $66
          jp z,req_backspace_pressed
          cp $5a
          jp z,req_enter_pressed
          cp $55
          jp z,req_plus_pressed
          cp $4e
          jp z,req_minus_pressed
          cp $29
          jp z,req_space_pressed
          cp $76
          jr z,req_esc_pressed
          
          ld hl,req_incdec_release                ;if +/- not pressed for 0.25 second, set as key released
          inc (hl)
          jr nz,req_idrm
          ld (hl),$ff
req_idrm  ld a,(hl)
          cp 12
          jr c,req_nrsr
          xor a
          ld (req_incdec_repeat),a
          
req_nrsr  ld a,(req_current_ascii_char)
          or a
          jp nz,req_ascii_input
          jp req_loop
          
;---------------------------------------------------------------------------------------------------------

req_esc_pressed
          
          ld a,(req_ascii_input_mode)             ;if pressed ESC whilst entering text
          or a                                    ;restore the original text for the element
          jr z,quit                               ;and continue
          call w_show_associated_text
          xor a
          ld (req_ascii_input_mode),a
          jp req_loop


quit      ld de,0                                 ; disable linecop
          ld (vreg_linecop_lo),de

          call kjt_flos_display
          
          call w_restore_display
          
          in a,(sys_audio_enable)       
          and %11111110
          out (sys_audio_enable),a                ;stop channel 0 playback

          ld bc,(orig_cursor)
          call kjt_set_cursor_position
          xor a
          ret
                    
          
;---------------------------------------------------------------------------------------------------------

req_tab_pressed
req_down_pressed

          ld a,(req_ascii_input_mode)
          or a
          call nz,req_end_ascii_input_mode
                    
          call w_next_selectable_element
          jp req_loop



req_up_pressed

          ld ix,up_element_sel_swaps
          call element_sel_swap
          jp req_loop



req_left_pressed

          ld ix,left_element_sel_swaps
          call element_sel_swap
          jp req_loop
          


req_right_pressed

          ld ix,right_element_sel_swaps
          call element_sel_swap
          jp req_loop
          

                    
element_sel_swap

          ld a,(ix)
          cp $ff
          ret z
          call w_get_element_selection
          cp (ix)
          jr z,gotswap
          inc ix
          inc ix
          jr element_sel_swap
gotswap   ld a,(ix+1)
          call w_set_element_selection
          ret


          

right_element_sel_swaps

          db 1,6, 3,8, 5,10, 6,1, 8,3, 10,5, $ff

left_element_sel_swaps

          db 6,1, 8,3, 10,5, 1,6, 3,8, 5,10, $ff

up_element_sel_swaps

          db 1,10, 3,1, 5,3, 6,5, 8,6, 10,8, $ff


;----------------------------------------------------------------------------------------------------------

req_plus_pressed

          ld a,(req_ascii_input_mode)
          or a
          jp nz,req_ascii_input
          
          call w_get_associated_data_location     ; no action if not a numeric input
          jp z,req_loop
          bit 3,(ix+3)
          jp z,req_loop
          
          call req_incdec_preamble
          jp nz,req_loop
          
          add hl,bc
          jr nc,req_hmsbs
          inc de

req_hmsbs call req_test_num_limits
          jp req_loop

          
;----------------------------------------------------------------------------------------------------------
          
          

req_minus_pressed
          
          ld a,(req_ascii_input_mode)
          or a
          jp nz,req_ascii_input
          
          call w_get_associated_data_location     ; no action if not a numeric input
          jp z,req_loop
          bit 3,(ix+3)
          jp z,req_loop

          call req_incdec_preamble
          jp nz,req_loop
          
          xor a
          sbc hl,bc
          jr nc,req_hmsbs
          dec de
          jr req_hmsbs


;----------------------------------------------------------------------------------------------------------
; Support code for +/- input hex value adjust
;----------------------------------------------------------------------------------------------------------


req_incdec_preamble
          
          xor a
          ld (req_incdec_release),a               ;reset the release timer
          
          call req_signextend_decision            ;get sign extend option
          call req_ascii_to_hex                   ;ASCII string to hex in DE:HL
          ret nz
          
          call w_get_selected_element_data_location

          ld c,(ix+15)                            ;get min increment
          ld b,(ix+16)
          ld a,(req_incdec_repeat)                ;magnify adjust value based on time key held
          inc a
          jr nz,req_idho
          dec a
req_idho  ld (req_incdec_repeat),a
          rlca
          rlca
          rlca
          and 7
          jr z,req_gpav
req_aisp  sla c
          rl b
          dec a
          jr nz,req_aisp      
req_gpav  xor a
          ret




req_signextend_decision

          bit 0,(ix+17)                           ;if length of input = max length of input box, and
          ret z                                   ;sign extend bit is set, we can check first char to

          push hl                                 ;get sign extension decision
          ld b,0
req_floi  ld a,(hl)
          or a
          jr z,req_gloi
          cp " "
          jr z,req_gloi
          inc b
          inc hl
          jr req_floi
req_gloi  pop hl
          ld a,(ix+1)                             ;input box size
          cp b
          jr z,req_seok1
          xor a
          ret
req_seok1 ld a,(hl)
          call req_uppercasify
          call req_hex_digit
          bit 3,a
          ret
          

req_ascii_to_hex

          push hl                                 ;String at HL, ZF = set: pack empty digits with 0, else F (for sign extend) 
          pop iy                                  ;Result in DE:HL. IF ZF not set on return, not a hex number
          ld de,0
          ld hl,0                                 ;de:hl = initially $00000000 
          jr z,req_athp
          dec hl                                  ;or de:hl=$ffffffff when sign extension required
          dec de

req_athp  ld b,8                                  ;max chars
req_hexlp ld a,(iy)
          or a
          ret z
          cp 32
          ret z
          call req_uppercasify
          call req_hex_digit  
          cp 16
          jr c,req_hxok
          xor a
          inc a
          ret
          
req_hxok  ld c,a
          push bc
          ld b,4
req_shdw  add hl,hl
          rl e
          rl d
          djnz req_shdw
          pop bc
          ld a,l
          or c
          ld l,a
          inc iy
          djnz req_hexlp
          xor a
          ret


          
          
req_hex_digit

          sub $3a                       
          jr c,req_hex09
          add a,$f9
req_hex09 add a,$a
          ret




req_hex_to_ascii

          ld iy,req_hex_string_txt                ;set DE:HL to hex value, returns string address at HL 
          ld c,8
req_msfh  ld a,d
          rrca
          rrca
          rrca
          rrca
          and $f
          add a,$30
          cp $3a
          jr c,req_ghxd
          add a,$41-$3a
req_ghxd  ld (iy),a
          inc iy
          ld b,4
req_hxsh  add hl,hl
          rl e
          rl d
          djnz req_hxsh
          dec c
          jr nz,req_msfh
          ret



req_uppercasify

; INPUT/OUTPUT A = ascii char to make uppercase

          cp $61                        
          ret c
          cp $7b
          ret nc
          sub $20                                 
          ret
                              



req_test_num_limits

          exx                                     ;compare DE:HL with upper limit
          ld l,(ix+7)
          ld h,(ix+8)
          ld e,(ix+9)
          ld d,(ix+10)
          exx
          call req_compare_dehl_dehl
          jr c,req_ulok                            
          ld l,(ix+7)
          ld h,(ix+8)
          ld e,(ix+9)
          ld d,(ix+10)
          jr req_hvok

req_ulok  exx
          ld l,(ix+11)
          ld h,(ix+12)                            ;compare DE:HL with lower limit
          ld e,(ix+13)
          ld d,(ix+14)
          exx
          call req_compare_dehl_dehl
          jr nc,req_hvok                          
          ld l,(ix+11)
          ld h,(ix+12)                            
          ld e,(ix+13)
          ld d,(ix+14)
          
req_hvok  bit 2,(ix+17)                           ;use granularity mask?
          jr z,req_nogm
          ld a,l
          and (ix+18)
          ld l,a
          ld a,h
          and (ix+19)
          ld h,a
          
req_nogm  call req_hex_to_ascii                   ;DE:HL to ASCII version of hex, HL returns pointing to string 
          ld e,(ix+1)
          ld d,0
          ld hl,req_hex_string_txt+8
          xor a
          sbc hl,de
          
          bit 1,(ix+17)                           ;skip leading zeroes?
          jr z,req_shex
          
          ld b,(ix+1)                             ; 
req_sklz  dec b
          jr z,req_shex
          ld a,(hl)
          cp "0"
          jr nz,req_shex
          inc hl
          jr req_sklz
          
req_shex  call w_ascii_to_associated_data
          call w_show_associated_text
          ret
          
          
          

req_compare_dehl_dehl

          push hl                       ;32bit signed compare. Carry set if de:hl' > de:hl
          push de
          
          exx
          ld a,d
          exx
          bit 7,a                       
          jr nz,req_neg1
          bit 7,d                       
          jr nz,req_gtr                 
          call req_sub
                              
req_cd    pop de
          pop hl
          ret
          
          
req_neg1  bit 7,d                       
          jr z,req_sma
          call req_sub                            
          jr req_cd


req_gtr   scf
          jr req_cd
req_sma   xor a
          jr req_cd


req_sub   exx
          push hl
          exx
          pop bc
          xor a                         
          sbc hl,bc
          ex de,hl
          exx
          push de
          exx
          pop bc
          sbc hl,bc
          ret




req_hex_string_txt

          ds 8,32
          db 0

req_incdec_repeat
          
          db 0
          
req_incdec_release

          db 0
          
;-----------------------------------------------------------------------------------------------------------
; End of support code for +/- values
;-----------------------------------------------------------------------------------------------------------

req_space_pressed

          ld a,(req_ascii_input_mode)
          or a
          jr z,playw
          jp req_loop


;------------------------------------------------------------------------------------------------------------

          
req_enter_pressed
          
          call w_get_selected_element_data_location         
          bit 4,(ix+3)                            
          jr z,notchkb                            ;is the selected element a checkbox?
          call w_get_associated_data_location
          ld a,(hl)
          xor 1                                   ;flip string "0" / "1"
          ld (hl),a
          call w_show_associated_text             ;and display new data
          jp req_loop
          
notchkb   call w_get_element_selection            ;if play button selected, play the sample
          cp 6
          jr nz,not_pl
playw     call play_wave
          jp req_loop
          
not_pl    ld a,(req_ascii_input_mode)             ;if pressed Enter on text input box init text input here
          or a                                    ;(unless already in input mode)
          jr z,req_ascii_input
          call req_end_ascii_input_mode 
          jp req_loop


;-------------------------------------------------------------------------------------------------------------

req_ascii_input

          call w_get_selected_element_data_location
          bit 2,(ix+3)                            ;does element allow ascii input?
          jp z,req_loop
          
          ld a,(req_ascii_input_mode)             ;already entering text?                 
          or a
          call z,req_set_ascii_input_mode         ;if not set up the input line
          ld a,(req_ti_cursor)                    
          cp (ix+1)                               ;cant enter more text if at end of line
          jr z,req_nai
          call req_ascii_cursor_pos
          ld a,(req_current_ascii_char)           ;might be non-ascii (EG: initiated with Enter)
          or a
          jp z,req_loop
          call req_uppercasify
          call kjt_plot_char
          ld hl,req_ti_cursor                     ;advance cursor
          inc (hl)
req_nai   jp req_loop
          


          
          
req_set_ascii_input_mode

          xor a                                   ;put the cursor at zero and
          ld (req_ti_cursor),a                    ;clear the text input line.
          inc a                                   
          ld (req_ascii_input_mode),a
          call w_get_selected_element_coords
          call w_get_selected_element_data_location
          ld e,(ix+1)                             ;width of line
req_ctilp ld a,32
          call kjt_plot_char                      ;fill input line with spaces  
          inc b
          dec e
          jr nz,req_ctilp
          ret                 




req_ascii_cursor_pos

          call w_get_selected_element_coords
          ld a,(req_ti_cursor)
          add a,b
          ld b,a
          ret
          
          

req_end_ascii_input_mode

          xor a
          ld (req_ascii_input_mode),a
          
          call w_get_selected_element_coords 
          call kjt_get_charmap_addr_xy            ; copy text from box to element's associated data location
          call w_ascii_to_associated_data
          
          call w_get_selected_element_data_location
          
          bit 3,(ix+3)                            ;is it a numeric input box?             
          ret z
          
          ld l,(ix+5)                             ;yes, so test upper/lower limits against inputted figure
          ld h,(ix+6)
          call req_signextend_decision
          call req_ascii_to_hex                   ;get sign extend option
          jp z,req_tnl                            
          ld hl,0                                 ;if bad hex, upper lower bounds check will insert lowest allowable value
          ld de,0
req_tnl   call req_test_num_limits
          ret
          
          
;----------------------------------------------------------------------------------------------

req_backspace_pressed


          ld a,(req_ascii_input_mode)             ;dont do anything if not in ascii input mode
          or a
          jr z,req_nbs
          
          ld a,(req_ti_cursor)                    ;cant move back if cursor at 0
          or a
          jr z,req_nbs
                    
          ld hl,req_ti_cursor                     ;move back and put a space at current location
          dec (hl)
req_dmcb  call req_ascii_cursor_pos
          ld a,32
          call kjt_plot_char
req_nbs   jp req_loop


;----------------------------------------------------------------------------------------------

req_unshow_selection
          
          ld a,(req_ascii_input_mode)
          or a
          ret nz
          call w_unhighlight_selected_element
          ret
          
req_show_selection

          ld a,(req_ascii_input_mode)
          or a
          ret nz
          ld a,$80                                ; highlight pen colour
          call w_highlight_selected_element
          ret
          
;----------------------------------------------------------------------------------------------

req_show_cursor

          ld a,(req_ascii_input_mode)
          or a
          ret z
          
          call req_ascii_cursor_pos
          push bc
          call w_get_selected_element_data_location
          pop bc
          ld a,(req_ti_cursor)          
          cp (ix+1)
          jr nz,req_cnmax
          dec b                                   ; keep the cursor at the end of the 
req_cnmax call kjt_set_cursor_position            ; text box if necessary
          ld hl,$1800
          call kjt_draw_cursor
          ret


;----------------------------------------------------------------------------------------------
          
req_current_ascii_char        db 0
req_current_scancode          db 0
req_ascii_input_mode          db 0
req_ti_cursor                 db 0

;----------------------------------------------------------------------------------------------


write_aud_addr

          ld a,1
          call read_hex_from_element
          ld (wave_addr),hl
          ld a,e
          ld (wave_addr+2),a
          ret       



write_aud_length
          
          ld a,3
          call read_hex_from_element
          ld (wave_length),hl
          ld a,e
          ld (wave_length+2),a
          ret
                    


write_aud_period

          ld a,5
          call read_hex_from_element
          ld (wave_period),hl
          ret
          


write_loop

          ld a,10                       
          call read_hex_from_element
          ld a,l
          ld (loop_mode),a
          ret
          
          
          
write_onchange

          ld a,8                        
          call read_hex_from_element
          ld a,l
          ld (play_on_change),a
          ret
                    

;----------------------------------------------------------------------------------------------
          
          
read_hex_from_element
          
          call w_get_element_a_data_location
          ld l,(ix+5)
          ld h,(ix+6)
          call req_ascii_to_hex
          ret



;---------------------------------------------------------------------------------------------------------

redraw_wave
                    
          call erase_waveform

          ld de,(wave_length)
          ld a,(wave_length+2)
          ld c,a
          ld a,(wave_addr+2)
          ld hl,(wave_addr)
          
draw_waveform
          
;set A:HL to flat address $0-$7ffff
;    C:DE to length in bytes
          
          push hl
          add hl,hl                               ;convert flat to Bank and Offset between $8000-$ffff
          rl a
          pop hl
          ld (sample_bank_base),a
          set 7,h
          ld (sample_base),hl                     ;Z80 source address (paged RAM area $8000-$FFFF)
          
          in a,(sys_alt_write_page)               ;enable any_page mode (allow bank 0 to be paged into $8000-$ffff)
          set 5,a
          out (sys_alt_write_page),a
          
          ld a,c                                  ;if sample len > $7fff bytes use alternative computation
          or a
          jr nz,sl_big
          bit 7,d
          jr nz,sl_big
          
sl_small  ld (mult_table+256),de                  ;DE = total length of sample in bytes (len = 7fff max)
          ld a,128
          ld (mult_index),a
                              
          ld hl,0                                 ;get points from this wave to represent it on screen
          ld bc,window_width_pixels               ;number of points
          ld de,wave_points
dwloop    ld (mult_write),hl                      ;scaling step, 0 to 16384 in steps of (16384/320)           
          ld a,51                                 ;IE:16384/window_width_pixels
          add a,l
          ld l,a
          jr nc,nocarry1
          inc h
          
nocarry1  exx
          ld hl,(sample_base)                     
          ld de,(mult_read)                       ;index in wave
          ld a,(sample_bank_base)
          add hl,de                               
          adc a,0
          set 7,h
          out (sys_mem_select),a
          ld a,(hl)                               ;get sample byte
          sra a
          sra a
          add a,32                                ;convert to 0-64 range (pixel y)
          exx 
          
          ld (de),a
          inc de
          dec bc
          ld a,b
          or c
          jr nz,dwloop
          jr msp_done
          
          
sl_big    srl c                                   ;divide sample length by 4 so it'll work with this routine
          rr d                                    
          rr e
          srl c
          rr d
          rr e
          ld a,d                                  ;if len/4 >= $8000, set to $7fff for display purposes
          cp $80
          jr nz,wlenok
          ld de,$7fff

wlenok    ld (mult_table+256),de                  ;DE = total length of sample in bytes (len = 7fff max)
          ld a,128
          ld (mult_index),a
                              
          ld hl,0                                 ;get points from this wave to represent it on screen
          ld bc,window_width_pixels               ;number of points
          ld de,wave_points
dwloop2   ld (mult_write),hl                      ;scaling step, 0 to 16384 in steps of (16384/320)           
          ld a,51                                 ;IE:16384/window_width_pixels
          add a,l
          ld l,a
          jr nc,nocarry2
          inc h

nocarry2  exx
          ld hl,(sample_base)                     
          ld de,(mult_read)                       ;index in wave
          ld a,(sample_bank_base)
          add hl,de                               
          adc a,0
          set 7,h
          add hl,de
          adc a,0
          set 7,h
          add hl,de
          adc a,0
          set 7,h
          add hl,de
          adc a,0
          set 7,h
          out (sys_mem_select),a
          ld a,(hl)                               ;get sample byte
          sra a
          sra a
          add a,32                                ;convert to 0-64 range (pixel y)
          exx 
          
          ld (de),a
          inc de
          dec bc
          ld a,b
          or c
          jr nz,dwloop2
          
          
          
msp_done  xor a
          out (sys_mem_select),a
          
          in a,(sys_alt_write_page)               ; disable any_page mode
          res 5,a
          out (sys_alt_write_page),a
          
lines     ld bc,319                               ; draw the wave using linedraw system
          ld hl,wave_points
          ld ix,line_coords
          ld de,0                                 ; xcoord 
dlloop    ld (ix+0),e                             ; start x
          ld (ix+1),d
          inc de
          ld (ix+4),e                             ; end x
          ld (ix+5),d                   
          ld a,(hl)                               ; y coord
          ld (ix+2),a                             ; start y
          inc hl
          ld a,(hl)
          ld (ix+6),a                             ; end y
          exx
          ld a,$ff                                ; line colour
          call draw_line
          exx
          dec bc
          ld a,b
          or c
          jr nz,dlloop
          ret

          
;-------------------------------------------------------------------------------------------------------

draw_line

; Note coord system has y=0 at the highest location in VRAM
; set IX to coords (startx,starty,endx,endy)
; set A = linecolour
; Limitation: y = 0 to 63 max (entries in lookup table)


          ld hl,vreg_read
ld_wait1  bit 4,(hl)                    ; ensure any previous line draw / blit op is complete
          jr nz,ld_wait1                ; before restarting line draw setup

          ld (linedraw_colour),a

next_line ld c,0                        ; reset the octant code / address MSBs
          ld l,(ix+2)                   ; y0 LSB
          ld h,c
          add hl,hl
          ld de,ylookup_table
          add hl,de
          ld e,(hl)
          inc hl
          ld d,(hl)
          ex de,hl
          ld e,(ix)                     
          ld d,(ix+1)                   ; de = x0
          add hl,de                     ; hl = video start address
          jr nc,no_sacar
          inc c
no_sacar  ld (linedraw_reg2),hl         ; Hardware line draw constant: Start Address [15:0]
          sla c                         ; shift line address MSBs to [11:9] of octant code reg

          ld l,(ix+4)                             
          ld h,(ix+5)                   ; hl = x1
          xor a                         ; clear carry flag
          sbc hl,de                     ; hl = delta_x (x1-x0)
          bit 7,h
          jr z,xdeltapos                ; is delta_x positive?
          ex de,hl                      ; make it positive if not
          xor a
          ld l,a
          ld h,a
          sbc hl,de                     
          set 4,c                       ; update octant settings bit 4
          
xdeltapos ld (delta_x),hl               ; stash delta_x
          ld e,(ix+2)                   
          ld d,(ix+3)                   ; de = y0
          ld l,(ix+6)
          ld h,(ix+7)                   ; hl = y1
          xor a
          sbc hl,de                     ; hl = delta y (y1-y0)
          bit 7,h
          jr z,ydeltapos                ; is delta_y positive?
          ex de,hl                      ; make it positive if not
          xor a
          ld l,a
          ld h,a
          sbc hl,de                     
          set 5,c                       ; update octant settings bit 5

ydeltapos ld (delta_y),hl               ; stash delta_y
          ld de,(delta_x)               ; hl = delta_y, de = delta_x
          xor a
          sbc hl,de                     ; hl = (delta_y - delta_x)
          jr c,horiz_seg                ; if delta_x > delta_y then the line has horizontal segments

          xor a                         ; vertical segment code.. 
          ex de,hl                      ; de = (delta_y - delta_x)
          ld l,a                        
          ld h,a                        ; hl = 0
          sbc hl,de                     ; hl = (delta_x - delta_y)
          add hl,hl
          ld (linedraw_reg0),hl         ; Hardware linedraw Constant: 2 x (delta_x - delta_y)       
          ld hl,(delta_x)
          add hl,hl
          ld (linedraw_reg1),hl         ; Hardware Linedraw Constant: 2 x delta_x         
          set 6,c                       ; update octant settings
          ld de,(delta_y)               ; de = line length
          jp line_len
          
horiz_seg add hl,hl
          ld (linedraw_reg0),hl         ; Hardware Linedraw Constant: 2 x (delta_y - delta_x)
          ld hl,(delta_y)
          add hl,hl
          ld (linedraw_reg1),hl         ; Hardware Linedraw Constant: 2 x delta_y

line_len  ld a,d                        ; de = line length (assumes length < $0200, as it should be)
          or c                          ; OR in the octant / addr MSB bits
          ld d,a                        ; DE = composite of MSB,octant code and line length

          ld (linedraw_reg3),de         ; line length, octant code, y address MSB & Start line draw.
          ret
          
          
;-------------------------------------------------------------------------------------------------------------------

erase_waveform
          
          call wait_blit
          
          ld hl,0+(64*window_width_pixels)
          ld (blit_src_loc),hl          
          ld hl,0
          ld (blit_dst_loc),hl
          xor a
          ld (blit_src_msb),a
          ld (blit_dst_msb),a
          ld (blit_dst_mod),a
          ld a,256-(window_width_pixels/2)        ; source mod is -160
          ld (blit_src_mod),a
          ld a,%01000011
          ld (blit_misc),a                                  
          ld a,127
          ld (blit_height),a
          ld a,window_width_pixels/2
          ld (blit_width),a                       ; 160x * 128y = clear 320*64 pixels 
          ret


;-------------------------------------------------------------------------------------------------------------------

          
wait_blit ld hl,vreg_read
bl_wait   bit 4,(hl)                              ; ensure blit op is complete
          jr nz,bl_wait                 
          ret

;--------------------------------------------------------------------------------------------------------------------

play_wave

          ld hl,wave_addr                         ;copy loc,len,period
          ld de,sample_addr
          ld bc,8
          ldir
          ld a,$40
          ld (sample_volume),a
                    
          ld a,(loop_mode)                        ;if loop mode, use same values at sample loop
          or a
          jr nz,samp_lm
          
          ld hl,silence                           ;else play silence at end of sample
          ld a,0
          ld (sample_loop_addr),hl
          ld (sample_loop_addr+2),a
          ld hl,2
          ld (sample_loop_length),hl
          ld (sample_loop_length+2),a   
          jr sound_go
                    
samp_lm   ld hl,wave_addr
          ld de,sample_loop_addr
          ld bc,6
          ldir

sound_go  call play_sound_sample
          ret



          
;-----------------------------------------------------------------------------------------
;        Simple sample play routine, first channel only                                    
;-----------------------------------------------------------------------------------------

;Set vars : sample_addr        (24 bit, flat byte address)
;           sample_length      (24 bit, in bytes)
;           sample_period      (16 bit)
;           sample_volume      (8 bit)
;           sample_loop_addr   (24 bit, flat byte address)
;           sample_loop_length (24 bit, in bytes)


play_sound_sample

          call dma_wait

          in a,(sys_audio_enable)       
          and %11111110
          out (sys_audio_enable),a      ;stop channel 0 playback

          ld a,(sample_addr+2)
          ld hl,(sample_addr)
          srl a                         ;divide location by 2 for WORD location
          rr h
          rr l
          ld b,h                        
          ld c,audchan0_loc   
          out (c),l                     ;write sample WORD address [15:0] to audio port   
          out (audchan0_loc_hi),a       ;write sample WORD address [16:17] to audio port
          
          ld a,(sample_length+2)
          ld hl,(sample_length)
          srl a
          rr h
          rr l                          ;divide length by 2 for length in WORDS
          ld b,h
          ld c,audchan0_len
          out (c),l                     ;write sample WORD length to port
          
          ld hl,(sample_period)         ;period = clock ticks between sample bytes
          ld b,h
          ld c,audchan0_per
          out (c),l                     ;set sample period to relevant port 
          
          ld a,(sample_volume)
          out (audchan0_vol),a          ;write sample volume to port (64 = full volume)

          call dma_wait

          in a,(sys_audio_enable)       
          or %00000001
          out (sys_audio_enable),a      ;start channel 0 playback
          
          
;-----------------------------------------------------------------------------------------
;         Now re-set start/len registers for when sample loops                                     
;-----------------------------------------------------------------------------------------
          
          
          call dma_wait                 ;allow time for sample to start playing..

          ld a,(sample_loop_addr+2)
          ld hl,(sample_loop_addr)
          srl a                         ;divide location by 2 for WORD location
          rr h
          rr l
          ld b,h                        
          ld c,audchan0_loc   
          out (c),l                     ;write sample WORD address [15:0] to audio port   
          out (audchan0_loc_hi),a       ;write sample WORD address [16:17] to audio port
          
          ld a,(sample_loop_length+2)
          ld hl,(sample_loop_length)
          srl a
          rr h
          rr l                          ;divide length by 2 for length in WORDS
          ld b,h
          ld c,audchan0_len
          out (c),l                     ;write sample WORD length to port
          ret
          
          
;-----------------------------------------------------------------------------------------

dma_wait  push bc
          in a,(sys_vreg_read)          ;wait for the beginning of a scan line 
          and $40                       ;(ie: after audio DMA) This is so that all the
          ld b,a                        ;audio registers are cleanly initialized
dma_loop  in a,(sys_vreg_read)
          and $40
          cp b
          jr z,dma_loop
          pop bc
          ret
          
;-------------------------------------------------------------------------------------------------------------------

find_next_arg

          ld a,(ix)
          or a
          jr z,missing_args
          cp " "
          jr nz,got_narg
          inc ix
          jr find_next_arg
got_narg  cp a
          ret
                    

          
missing_args

          ld a,$1f
          or a
          ret

;-------------------------------------------------------------------------------------------------------------------

sample_addr         db 0,0,0
sample_length       db 0,0,0
sample_period       dw 0
sample_volume       db 0
sample_loop_addr    db 0,0,0
sample_loop_length  db 0,0,0

;------------------------------------------------------------------------------------------------------------------

          include "flos_based_programs\code_library\window_routines\inc\window_draw_routines.asm"
          include "flos_based_programs\code_library\window_routines\inc\window_support_routines.asm"
          include "flos_based_programs\code_library\string\inc\hex_string_to_numeric.asm"
                    
;-------------------------------------------------------------------------------------------------------------------


linedraw_constants

          dw (65536-window_width_pixels)+1
          dw (65536-window_width_pixels)-1
          dw window_width_pixels+1      
          dw window_width_pixels-1
          dw 1
          dw 65535
          dw (65536-window_width_pixels)
          dw window_width_pixels



delta_x   dw 0
delta_y   dw 0


line_coords

          dw 0,0    ;start x / y
          dw 0,0    ;end x / y


;-------------------------------------------------------------------------------------------------------------------

wave_addr           db $00,$80,$00                ;numeric data extracted from user input window
wave_length         db $00,$10,$00
wave_period         dw $2d5

loop_mode           db 0
play_on_change      db 1

;------------------------------------------------------------------------------------------------------------------

wave_points         ds window_width_pixels,0

sample_base         dw 0
sample_bank_base    db 0

;-------------------------------------------------------------------------------------------------------------------

my_linecoplist      

          dw $c002            ;wait for line
          dw $8201            ;set register to $201 (vreg_vidctrl)
          dw $00a0            ;write $80 to register (switch to chunky pixel mode)
          dw $8243            ;select register $243 (reset video counter)
          dw $0000            ;write $00, reset counter
          
lcop_spl1 dw $c058            ;wait for line
          dw $8201            ;set register $201 (vreg_victrl)
          dw $0000            ;write 0 to register (bitmap bitplane mode)
          dw $8243            ;select register $243 (reset video counter)
          dw $0000            ;write $00, reset counter

          dw $c1ff            ;wait for line $1ff (end of list)

end_my_linecoplist  


vid_mode_split_list

          db $68,$58,$58      ;PAL50, NTSC60, VGA60


;-------------------------------------------------------------------------------------------------------------------

ylookup_table       ds 64*2,0

orig_cursor         dw 0

;-------------------------------------------------------------------------------------------------------------------



;------ My Window Descriptions -----------------------------------------------------

window_list         dw win_inf_inputs                       ;Window 0


;------ Window Info -----------------------------------------------------------

win_inf_inputs      db 0,0                        ;0 - position on screen of frame (x,y) 
                    db 38,9                       ;2 - dimensions of frame (x,y)
                    db 0                          ;4 - current element/gadget selected
                    db 0                          ;5 - unused at present
                    
                    db 4,3                        ;6 - position of first element (x,y)
                    dw win_element0               ;8 - location of first element description
                    db 12,3
                    dw win_element1
                    
                    db 4,5                        
                    dw win_element2               
                    db 12,5
                    dw win_element3
                    
                    db 4,7                        
                    dw win_element4               
                    db 12,7
                    dw win_element5
                    
                    db 22,3                       
                    dw win_element6               
                    
                    db 22,5                       
                    dw win_element7     
                    db 32,5
                    dw win_element8
                    
                    db 22,7                       
                    dw win_element9               
                    db 32,7
                    dw win_element10              
                    
                    db 3,1
                    dw win_element11
                    
                    db 255                        ;255 = end of list of window elements
                    
                    
;---- Window Elements ---------------------------------------------------------------------

;---------------------------------------------------------------------------------------------
; ADDR GADGET
;---------------------------------------------------------------------------------------------

                    
win_element0        db 2                          ;0 = Element Type: 0=button, 1=data area, 2=info (text)
                    db 7,1                        ;1/2 = dimensions of element x,y
                    db 0                          ;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input, b4=checkbox)
                    db 0                          ;4 = event flag
                    dw addr_txt                   ;5/6 = location of associated data
;                   dw 0,0                        ;7/8/9/10 = when numeric input (bit3 of control set), upper limit
;                   dw 0,0                        ;11/12/13/14 = when numeric input, bottom limit
;                   dw 0                          ;15/16= when numeric input with +/- this is the min incrememnt
;                   db 0                          ;17 = control for numeric input, bit0 = sign extend input, bit1 = skip leading zeroes
                                                  
win_element1        db 1
                    db 5,1
                    db %1101                      ;b0:selectable + b2:accepts user input + b3:hex
                    db 0
                    dw entry1_txt
                    dw $fffe,$0007                ;upper limit for hex value
                    dw $0000,$0000                ;lower limit for hex value
                    dw 2                          ;min inc/decrement for +/- buttons
                    db %110                       ;sign extend input: off, skip leading zeroes: on. granularity mask = on
                    dw $fffe                      ;granularity mask (low 16 bits)
                    
addr_txt            db "ADDRESS",0
entry1_txt          db "8000 ",0


;---------------------------------------------------------------------------------------------
; LENGTH GADGET
;---------------------------------------------------------------------------------------------

                    
win_element2        db 2                          ;0 = Element Type: 0=button, 1=data area, 2=info (text)
                    db 6,1                        ;1/2 = dimensions of element x,y
                    db 0                          ;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
                    db 0                          ;4 = event flag
                    dw mod_txt                    ;5/6 = location of associated data
                    
win_element3        db 1
                    db 5,1
                    db %1101                      
                    db 0
                    dw entry2_txt
                    dw $0000,$0002
                    dw $0002,$0000
                    dw 2
                    db %110                       ;sign extend input: off, skip leading zeroes: on granularity mask = on
                    dw $fffe                      ;granularity mask (low 16 bits)
                    
mod_txt             db "LENGTH",0
entry2_txt          db "1000 ",0

                    
;---------------------------------------------------------------------------------------------
; PERIOD GADGET
;---------------------------------------------------------------------------------------------
                    

win_element4        db 2                          ;0 = Element Type: 0=button, 1=data area, 2=info (text)
                    db 6,1                        ;1/2 = dimensions of element x,y
                    db 0                          ;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
                    db 0                          ;4 = event flag
                    dw chunky_txt                 ;5/6 = location of associated data
                    
win_element5        db 1
                    db 4,1
                    db %1101                      
                    db 0
                    dw entry3_txt
                    dw $ffff,$0000                ;upper limit for hex value
                    dw $0000,$0000                ;lower limit for hex value
                    dw 1                          ;min inc/decrement for +/- buttons
                    db 2                          ;sign extend input: off, skip leading zeroes: on, gran mask = off
                              
chunky_txt          db "PERIOD",0
entry3_txt          db "2D5 ",0


;---------------------------------------------------------------------------------------------
; PLAY BUTTON
;---------------------------------------------------------------------------------------------
                    

win_element6        db 0                          ;0 = Element Type: 0=button, 1=data area, 2=info (text)
                    db 9,1                        ;1/2 = dimensions of element x,y
                    db %0001                      ;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
                    db 0                          ;4 = event flag
                    dw play_txt                   ;5/6 = location of associated data
                    
play_txt            db "PLAY WAVE",0

;---------------------------------------------------------------------------------------------
; ON CHANGE OPTION
;---------------------------------------------------------------------------------------------
                    

win_element7        db 2                          ;0 = Element Type: 0=button, 1=data area, 2=info (text)
                    db 9,1                        ;1/2 = dimensions of element x,y
                    db 0                          ;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
                    db 0                          ;4 = event flag
                    dw onchg_txt                  ;5/6 = location of associated data
                    
win_element8        db 1
                    db 1,1
                    db %10001                     ;selectable + checkbox                  
                    db 0
                    dw entry4_txt
                                        
onchg_txt           db "ON CHANGE",0
entry4_txt          db "1",0                      ;default is "0" = not ticked
                    

;---------------------------------------------------------------------------------------------
; LOOP OPTION
;---------------------------------------------------------------------------------------------
                    

win_element9        db 2                          ;0 = Element Type: 0=button, 1=data area, 2=info (text)
                    db 7,1                        ;1/2 = dimensions of element x,y
                    db 0                          ;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
                    db 0                          ;4 = event flag
                    dw loop_txt                   ;5/6 = location of associated data
                    
win_element10       db 1
                    db 1,1
                    db %10001                     ;selectable + checkbox        
                    db 0
                    dw entry5_txt

                                                            
loop_txt            db "LOOPING",0
entry5_txt          db "0",0                      ;default is "0" = not ticked

;---------------------------------------------------------------------------------------------

win_element11       db 2                          ;0 = Element Type: 0=button, 1=data area, 2=info (text)
                    db 32,1                       ;1/2 = dimensions of element x,y
                    db 0                          ;3 = control bits (b0=selectable, b1=special line selection, b2=user input, b3=hex input)
                    db 0                          ;4 = event flag
                    dw title_txt                  ;5/6 = location of associated data

title_txt           db "** Audio Memory Browser V0.01 **",0

;---------------------------------------------------------------------------------------------



          org ($+1) & $fffe

silence             db 0,0                        ;samples have to be word aligned

;--------------------------------------------------------------------------------------------
