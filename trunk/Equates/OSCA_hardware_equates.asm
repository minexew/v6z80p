
;----- OSCA Main system hardware control / peripheral ports -----------------

sys_mem_select	equ $00
sys_irq_ps2_flags 	equ $01
sys_irq_enable	equ $01
sys_keyboard_data	equ $02
sys_clear_irq_flags	equ $02
sys_mouse_data	equ $03
sys_ps2_joy_control	equ $03
sys_serial_port	equ $04
sys_joy_com_flags	equ $05
sys_sdcard_ctrl1	equ $05
sys_sdcard_ctrl2	equ $06
sys_timer		equ $07
sys_vreg_read	equ $07
sys_audio_enable	equ $08
sys_audio_flags	equ $08
sys_hw_flags	equ $09
sys_hw_settings	equ $09
sys_spi_port	equ $0a
sys_alt_write_page	equ $0b
sys_baud_rate	equ $0c
sys_pic_comms	equ $0d
sys_eeprom_byte	equ $0d
sys_io_pins	equ $0e
sys_io_dir	equ $0f

sys_low_page	equ $20
sys_vram_location	equ $21
sys_audio_panning	equ $22

;---- Sound system ports ---------------------------------------------------

audchan0_loc	equ $10
audchan0_len	equ $11
audchan0_per	equ $12
audchan0_vol	equ $13

audchan1_loc	equ $14
audchan1_len	equ $15
audchan1_per	equ $16
audchan1_vol	equ $17

audchan2_loc	equ $18
audchan2_len	equ $19
audchan2_per	equ $1a
audchan2_vol	equ $1b

audchan3_loc	equ $1c
audchan3_len	equ $1d
audchan3_per	equ $1e
audchan3_vol	equ $1f

aud_panning	equ $22		;alternative name for "sys_audio_panning"

audchan0_loc_hi	equ $24
audchan1_loc_hi	equ $25
audchan2_loc_hi	equ $26
audchan3_loc_hi	equ $27

;------ Graphics registers -------------------------------------------------

palette 		equ $0		

video_registers	equ $200
vreg_xhws		equ $200		; video control registers
vreg_vidctrl	equ $201
vreg_window	equ $202
vreg_yhws_bplcount	equ $203
vreg_rasthi	equ $204
vreg_rastlo	equ $205
vreg_vidpage	equ $206
vreg_sprctrl	equ $207
mult_write	equ $208		; SIGNED WORD
mult_index	equ $20a		; BYTE
linedraw_colour	equ $20b
vreg_ext_vidctrl	equ $20c
vreg_linecop_lo	equ $20d
vreg_linecop_hi	equ $20e
vreg_palette_ctrl	equ $20f

blit_src_loc	equ $210		; blitter set-up registers
blit_dst_loc	equ $212
blit_src_mod	equ $214
blit_dst_mod	equ $215
blit_height	equ $216
blit_width	equ $217
blit_misc		equ $218
blit_src_msb	equ $219
blit_dst_msb	equ $21a

linedraw_reg0 	equ $220		; line draw set-up registers (WORDS)
linedraw_reg1 	equ $222
linedraw_reg2 	equ $224
linedraw_reg3 	equ $226
linedraw_reg4 	equ $228		
linedraw_reg5 	equ $22a
linedraw_reg6 	equ $22c
linedraw_reg7 	equ $22e
linedraw_lut0 	equ $230		; line draw look-up table (WORDS)
linedraw_lut1 	equ $232
linedraw_lut2 	equ $234
linedraw_lut3 	equ $236
linedraw_lut4 	equ $238		
linedraw_lut5 	equ $23a
linedraw_lut6 	equ $23c
linedraw_lut7 	equ $23e

bitplane0a_loc	equ $240
bitplane1a_loc	equ $244
bitplane2a_loc	equ $248
bitplane3a_loc	equ $24c
bitplane4a_loc	equ $250
bitplane5a_loc	equ $254
bitplane6a_loc	equ $258
bitplane7a_loc	equ $25c
bitplane0b_loc	equ $260
bitplane1b_loc	equ $264
bitplane2b_loc	equ $268
bitplane3b_loc	equ $26c
bitplane4b_loc	equ $270
bitplane5b_loc	equ $274
bitplane6b_loc	equ $278
bitplane7b_loc	equ $27c
bitplane_reset	equ $243
bitplane_modulo	equ $247

priority_registers	equ $280

sprite_registers	equ $400		; sprite coord/def/size registers
spr_registers	equ $400		; alternate name

mult_table	equ $600		; maths table (256 SIGNED WORDS)

vreg_read		equ $700		; video status read register
mult_read		equ $704		; SIGNED WORD


;--------------------------------------------------------------------------

sprite_base	equ $1000		; 4KB when banked in
video_base	equ $2000		; 8KB when banked in

;--------------------------------------------------------------------------
