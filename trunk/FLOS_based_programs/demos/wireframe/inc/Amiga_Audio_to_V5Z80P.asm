;----------------------------------------------------------------------------------------
; Amiga hardware values to V5Z80P conversion / hardware register updates
; For Z80 Protracker Player (requires "Z80_protracker_player.asm")
;
; v5.01 - put period conv table inline as .asm (instead of an incbin file)
;----------------------------------------------------------------------------------------


update_sound_hardware


	ld c,audchan0_per			; set the 4 channels' period and volume
	ld iy,channel_data			; registers. These are always updated 
	call update_pervol			; every frame and require no special timing.
	ld c,audchan1_per
	ld iy,channel_data+vars_per_channel
	call update_pervol
	ld c,audchan2_per			
	ld iy,channel_data+(vars_per_channel*2)
	call update_pervol
	ld c,audchan3_per		
	ld iy,channel_data+(vars_per_channel*3)
	call update_pervol
	

	ld hl,vreg_read			; wait for display window part of scan line (sound dma done)
xwait1	bit 1,(hl)
	jr nz,xwait1
xwait2	bit 1,(hl)				
	jr z,xwait2
	
	
	ld e,%00000001			; now set the 4 channels' sample location
	ld c,audchan0_loc			; and length registers, * if triggered *
	ld iy,channel_data	
	bit 0,(iy+control_bits)
	call nz,update_start_loclen
	ld e,%00000010			
	ld c,audchan1_loc			
	ld iy,channel_data+vars_per_channel	
	bit 0,(iy+control_bits)
	call nz,update_start_loclen
	ld e,%00000100			
	ld c,audchan2_loc			
	ld iy,channel_data+(vars_per_channel*2)
	bit 0,(iy+control_bits)
	call nz,update_start_loclen
	ld e,%00001000			 
	ld c,audchan3_loc			 
	ld iy,channel_data+(vars_per_channel*3)
	bit 0,(iy+control_bits)
	call nz,update_start_loclen

	
	ld hl,vreg_read			 ; wait one scan line (sound dma done)
xwait1b	bit 1,(hl)
	jr nz,xwait1b
xwait2b	bit 1,(hl)				
	jr z,xwait2b

	
	ld e,%00000001			; finally set the 4 channels' loop around values
	ld c,audchan0_loc			; for location and length registers, * if triggered *
	ld iy,channel_data	
	call update_loop_loclen
	ld e,%00000010			
	ld c,audchan1_loc			
	ld iy,channel_data+vars_per_channel	
	call update_loop_loclen
	ld e,%00000100			
	ld c,audchan2_loc			
	ld iy,channel_data+(vars_per_channel*2)
	call update_loop_loclen
	ld e,%00001000			 
	ld c,audchan3_loc			 
	ld iy,channel_data+(vars_per_channel*3)
	call update_loop_loclen
	ret



update_start_loclen

	ld a,e
	cpl
	ld b,a
	ld a,(HW_enabled_channels)
	and b
	ld (HW_enabled_channels),a
	out (sys_audio_enable),a		; disable channel during loc/len update
	
	ld a,(iy+samp_loc_lo)		; lsb of WORD location
	ld b,(iy+samp_loc_hi)		; msb of WORD location
	out (c),a				; write WORD location to HW reg
	inc c				; move to length reg port
	ld a,(iy+samp_len_lo)		; lsb of length in words
	ld b,(iy+samp_len_hi)		; msb of length in words
	out (c),a				; write WORD length to HW reg		 
	ret


					
update_loop_loclen

	res 0,(iy+control_bits)		; clear sample trigger bit
	ld a,(HW_enabled_channels)
	or e
	ld (HW_enabled_channels),a
	out (sys_audio_enable),a		; enable channel to begin playing sound sample	
	
	ld a,(iy+samp_loop_loc_lo)		; lsb of loop location (in words)
	ld b,(iy+samp_loop_loc_hi)		; msb of loop location (in words)
	out (c),a				; write loop location (word address) to HW reg
	inc c				; move to length register port
	ld a,(iy+samp_loop_len_lo)		; lsb of loop length in words
	ld b,(iy+samp_loop_len_hi)		; msb of loop length in words
	out (c),a				; write loop WORD length to HW reg
	ret
	
	
	
update_pervol

	ld l,(iy+period_lo)			; lsb of Amiga period
	ld h,(iy+period_hi)			; msb of Amiga period
	add hl,hl
	ld de,amiga_period_conv_table-(108*2)
	add hl,de
	ld a,(hl)				; z80 project period value (lo)
	inc hl				;
	ld b,(hl)				; z80 project period value (hi)
	out (c),a				; write converted period to sample rate port
	
	inc c				; move to volume register port
	ld a,(iy+volume)			; get channel's volume value
	ld b,a				; 
	out (c),a				; write volume to HW register
	ret
	

;--------------------------------------------------------------------------------------------

HW_enabled_channels

	db 0

amiga_period_conv_table

          DW $01E2,$01E7,$01EB,$01F0,$01F4,$01F9,$01FD,$0202	; covers values 108 to 907
          DW $0206,$020A,$020F,$0213,$0218,$021C,$0221,$0225
          DW $022A,$022E,$0233,$0237,$023C,$0240,$0245,$0249
          DW $024E,$0252,$0256,$025B,$025F,$0264,$0268,$026D
          DW $0271,$0276,$027A,$027F,$0283,$0288,$028C,$0291
          DW $0295,$029A,$029E,$02A2,$02A7,$02AB,$02B0,$02B4
          DW $02B9,$02BD,$02C2,$02C6,$02CB,$02CF,$02D4,$02D8
          DW $02DD,$02E1,$02E5,$02EA,$02EE,$02F3,$02F7,$02FC
          DW $0300,$0305,$0309,$030E,$0312,$0317,$031B,$0320
          DW $0324,$0329,$032D,$0331,$0336,$033A,$033F,$0343
          DW $0348,$034C,$0351,$0355,$035A,$035E,$0363,$0367
          DW $036C,$0370,$0375,$0379,$037D,$0382,$0386,$038B
          DW $038F,$0394,$0398,$039D,$03A1,$03A6,$03AA,$03AF
          DW $03B3,$03B8,$03BC,$03C1,$03C5,$03C9,$03CE,$03D2
          DW $03D7,$03DB,$03E0,$03E4,$03E9,$03ED,$03F2,$03F6
          DW $03FB,$03FF,$0404,$0408,$040D,$0411,$0415,$041A
          DW $041E,$0423,$0427,$042C,$0430,$0435,$0439,$043E
          DW $0442,$0447,$044B,$0450,$0454,$0458,$045D,$0461
          DW $0466,$046A,$046F,$0473,$0478,$047C,$0481,$0485
          DW $048A,$048E,$0493,$0497,$049C,$04A0,$04A4,$04A9
          DW $04AD,$04B2,$04B6,$04BB,$04BF,$04C4,$04C8,$04CD
          DW $04D1,$04D6,$04DA,$04DF,$04E3,$04E8,$04EC,$04F0
          DW $04F5,$04F9,$04FE,$0502,$0507,$050B,$0510,$0514
          DW $0519,$051D,$0522,$0526,$052B,$052F,$0534,$0538
          DW $053C,$0541,$0545,$054A,$054E,$0553,$0557,$055C
          DW $0560,$0565,$0569,$056E,$0572,$0577,$057B,$0580
          DW $0584,$0588,$058D,$0591,$0596,$059A,$059F,$05A3
          DW $05A8,$05AC,$05B1,$05B5,$05BA,$05BE,$05C3,$05C7
          DW $05CB,$05D0,$05D4,$05D9,$05DD,$05E2,$05E6,$05EB
          DW $05EF,$05F4,$05F8,$05FD,$0601,$0606,$060A,$060F
          DW $0613,$0617,$061C,$0620,$0625,$0629,$062E,$0632
          DW $0637,$063B,$0640,$0644,$0649,$064D,$0652,$0656
          DW $065B,$065F,$0663,$0668,$066C,$0671,$0675,$067A
          DW $067E,$0683,$0687,$068C,$0690,$0695,$0699,$069E
          DW $06A2,$06A7,$06AB,$06AF,$06B4,$06B8,$06BD,$06C1
          DW $06C6,$06CA,$06CF,$06D3,$06D8,$06DC,$06E1,$06E5
          DW $06EA,$06EE,$06F2,$06F7,$06FB,$0700,$0704,$0709
          DW $070D,$0712,$0716,$071B,$071F,$0724,$0728,$072D
          DW $0731,$0736,$073A,$073E,$0743,$0747,$074C,$0750
          DW $0755,$0759,$075E,$0762,$0767,$076B,$0770,$0774
          DW $0779,$077D,$0782,$0786,$078A,$078F,$0793,$0798
          DW $079C,$07A1,$07A5,$07AA,$07AE,$07B3,$07B7,$07BC
          DW $07C0,$07C5,$07C9,$07CE,$07D2,$07D6,$07DB,$07DF
          DW $07E4,$07E8,$07ED,$07F1,$07F6,$07FA,$07FF,$0803
          DW $0808,$080C,$0811,$0815,$081A,$081E,$0822,$0827
          DW $082B,$0830,$0834,$0839,$083D,$0842,$0846,$084B
          DW $084F,$0854,$0858,$085D,$0861,$0865,$086A,$086E
          DW $0873,$0877,$087C,$0880,$0885,$0889,$088E,$0892
          DW $0897,$089B,$08A0,$08A4,$08A9,$08AD,$08B1,$08B6
          DW $08BA,$08BF,$08C3,$08C8,$08CC,$08D1,$08D5,$08DA
          DW $08DE,$08E3,$08E7,$08EC,$08F0,$08F5,$08F9,$08FD
          DW $0902,$0906,$090B,$090F,$0914,$0918,$091D,$0921
          DW $0926,$092A,$092F,$0933,$0938,$093C,$0941,$0945
          DW $0949,$094E,$0952,$0957,$095B,$0960,$0964,$0969
          DW $096D,$0972,$0976,$097B,$097F,$0984,$0988,$098D
          DW $0991,$0995,$099A,$099E,$09A3,$09A7,$09AC,$09B0
          DW $09B5,$09B9,$09BE,$09C2,$09C7,$09CB,$09D0,$09D4
          DW $09D8,$09DD,$09E1,$09E6,$09EA,$09EF,$09F3,$09F8
          DW $09FC,$0A01,$0A05,$0A0A,$0A0E,$0A13,$0A17,$0A1C
          DW $0A20,$0A24,$0A29,$0A2D,$0A32,$0A36,$0A3B,$0A3F
          DW $0A44,$0A48,$0A4D,$0A51,$0A56,$0A5A,$0A5F,$0A63
          DW $0A68,$0A6C,$0A70,$0A75,$0A79,$0A7E,$0A82,$0A87
          DW $0A8B,$0A90,$0A94,$0A99,$0A9D,$0AA2,$0AA6,$0AAB
          DW $0AAF,$0AB4,$0AB8,$0ABC,$0AC1,$0AC5,$0ACA,$0ACE
          DW $0AD3,$0AD7,$0ADC,$0AE0,$0AE5,$0AE9,$0AEE,$0AF2
          DW $0AF7,$0AFB,$0B00,$0B04,$0B08,$0B0D,$0B11,$0B16
          DW $0B1A,$0B1F,$0B23,$0B28,$0B2C,$0B31,$0B35,$0B3A
          DW $0B3E,$0B43,$0B47,$0B4B,$0B50,$0B54,$0B59,$0B5D
          DW $0B62,$0B66,$0B6B,$0B6F,$0B74,$0B78,$0B7D,$0B81
          DW $0B86,$0B8A,$0B8F,$0B93,$0B97,$0B9C,$0BA0,$0BA5
          DW $0BA9,$0BAE,$0BB2,$0BB7,$0BBB,$0BC0,$0BC4,$0BC9
          DW $0BCD,$0BD2,$0BD6,$0BDB,$0BDF,$0BE3,$0BE8,$0BEC
          DW $0BF1,$0BF5,$0BFA,$0BFE,$0C03,$0C07,$0C0C,$0C10
          DW $0C15,$0C19,$0C1E,$0C22,$0C27,$0C2B,$0C2F,$0C34
          DW $0C38,$0C3D,$0C41,$0C46,$0C4A,$0C4F,$0C53,$0C58
          DW $0C5C,$0C61,$0C65,$0C6A,$0C6E,$0C72,$0C77,$0C7B
          DW $0C80,$0C84,$0C89,$0C8D,$0C92,$0C96,$0C9B,$0C9F
          DW $0CA4,$0CA8,$0CAD,$0CB1,$0CB6,$0CBA,$0CBE,$0CC3
          DW $0CC7,$0CCC,$0CD0,$0CD5,$0CD9,$0CDE,$0CE2,$0CE7
          DW $0CEB,$0CF0,$0CF4,$0CF9,$0CFD,$0D02,$0D06,$0D0A
          DW $0D0F,$0D13,$0D18,$0D1C,$0D21,$0D25,$0D2A,$0D2E
          DW $0D33,$0D37,$0D3C,$0D40,$0D45,$0D49,$0D4E,$0D52
          DW $0D56,$0D5B,$0D5F,$0D64,$0D68,$0D6D,$0D71,$0D76
          DW $0D7A,$0D7F,$0D83,$0D88,$0D8C,$0D91,$0D95,$0D9A
          DW $0D9E,$0DA2,$0DA7,$0DAB,$0DB0,$0DB4,$0DB9,$0DBD
          DW $0DC2,$0DC6,$0DCB,$0DCF,$0DD4,$0DD8,$0DDD,$0DE1
          DW $0DE5,$0DEA,$0DEE,$0DF3,$0DF7,$0DFC,$0E00,$0E05
          DW $0E09,$0E0E,$0E12,$0E17,$0E1B,$0E20,$0E24,$0E29
          DW $0E2D,$0E31,$0E36,$0E3A,$0E3F,$0E43,$0E48,$0E4C
          DW $0E51,$0E55,$0E5A,$0E5E,$0E63,$0E67,$0E6C,$0E70
          DW $0E75,$0E79,$0E7D,$0E82,$0E86,$0E8B,$0E8F,$0E94
          DW $0E98,$0E9D,$0EA1,$0EA6,$0EAA,$0EAF,$0EB3,$0EB8
          DW $0EBC,$0EC1,$0EC5,$0EC9,$0ECE,$0ED2,$0ED7,$0EDB
          DW $0EE0,$0EE4,$0EE9,$0EED,$0EF2,$0EF6,$0EFB,$0EFF
          DW $0F04,$0F08,$0F0D,$0F11,$0F15,$0F1A,$0F1E,$0F23
          DW $0F27,$0F2C,$0F30,$0F35,$0F39,$0F3E,$0F42,$0F47
          DW $0F4B,$0F50,$0F54,$0F58,$0F5D,$0F61,$0F66,$0F6A
          DW $0F6F,$0F73,$0F78,$0F7C,$0F81,$0F85,$0F8A,$0F8E
          DW $0F93,$0F97,$0F9C,$0FA0,$0FA4,$0FA9,$0FAD,$0FB2
          DW $0FB6,$0FBB,$0FBF,$0FC4,$0FC8,$0FCD,$0FD1,$0FD6

;========================================================================================
