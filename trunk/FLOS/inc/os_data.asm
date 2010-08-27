;*************
;* FLOS DATA *
;*************

;-------------------------------------------------------------------------------------------
; Non-packed Text Strings
;-------------------------------------------------------------------------------------------

welcome_message	db "FLOS by Phil Ruston 2010",0
storage_txt	db "Drives:",11,0
os_dos_cmds_txt	db "COMMANDS",0
boot_script_fn	db "BOOT_RUN.SCR",0
os_hex_prefix_txt	db "$",0
os_version_txt	db "FLOS V:$",0		
hw_version_txt	db "OSCA V:$",0
fwd_slash_txt	db " / ",0
loading_txt	db "Loading..",11,0
saving_txt	db "Saving..",11,0
exe_extension_txt	db ".exe",32
os_more_txt	db 11,"More?",11,11,0
nmi_freeze_txt	db 11,11,"** BREAK! **"
crlfx2_txt	db 11,11,0
rep_char_txt	db "x",0

;------------------------------------------------------------------------------------------------
; Packed text section
;------------------------------------------------------------------------------------------------

dictionary	db 0,"DEBUG"		;01	
		db 0,"-----"		;02
		db 0,"IO"			;03
		db 0,"--"			;04
		db 0,"MISC"		;05
		db 0,"----"		;06
		db 0,"ad"			;07
		db 0,"bnk"		;08
		db 0,"a b c"		;09
		db 0,"Address"		;0a
		db 0,"Bytes"		;0b
		db 0,"Bank"		;0c
		db 0,"Hunt"		;0d
		db 0,"Fill"		;0e
		db 0,"Goto"		;0f
		
		db 0,"Show"		;10
		db 0,"CPU"		;11
		db 0,"Registers"		;12
		db 0,"As"			;13
		db 0,"ASCII"		;14
		db 0,"Clear"		;15
		db 0,"Screen"		;16
		db 0,"Disassemble"		;17
		db 0,"Switch"		;18
		db 0,"Copy"		;19
		db 0,"Device"		;1a
		db 0,"Change"		;1b
		db 0,"Drive"		;1c
		db 0,"Dir"		;1d
		db 0,"/"			;1e
		db 0,"fn"			;1f
		
		db 0,"Delete"		;20
		db 0,"File"		;21
		db 0,"Info"		;22
		db 0,"VOLx:"		;23
		db 0,"Make"		;24
		db 0,"Remount"		;25
		db 0,"Start"		;26
		db 0,"Warning!"		;27 
		db 0,"All"		;28
		db 0,"Remove"		;29
		db 0,"Rename"		;2a
		db 0,"Or"			;2b
		db 0,"Receive"		;2c
		db 0,"Save"		;2d
		db 0,"Transmit"		;2e
		db 0,"Load"		;2f
		
		db 0,"OS/HW"		;30
		db 0,"Version"		;31
		db 0,"pen [pap brd crs]"	;32				
		db $80,":"		;33
		db $81,">"		;34
		db $82,"B"		;35
		db 0,"Volumes"		;36
		db $83,"C"		;37
		db $84,"CD"		;38
		db $85,"CLS"		;39
		db $86,"COLOUR"		;3a
		db $87,"D"		;3b
		db $88,"DEL"		;3c
		db $89,"DIR"		;3d
		db $8a,"H"		;3e
		db $8b,"F"		;3f
		
		db 0,"On"			;40 
		db $8c,"FORMAT"		;41
		db 0,"G"			;42
		db $8d,"LB"		;43
		db $8e,"M"		;44
		db $8f,"MOUNT"		;45
		db 0,"Be"			;46
		db $90,"R"		;47
		db $91,"RD"		;48
		db $92,"RN"		;49
		db $93,"RX"		;4a
		db $94,"SB"		;4b
		db $95,"T"		;4c
		db $96,"TX"		;4d
		db $97,"VERS"		;4e	
		db 0,"Write"		;4f
		
		db 0,"Mem"		;50
		db 0,$22,"txt",$22		;51
		db 0,"Will"		;52
		db 0,"Rate"		;53
		db 0,"a"			;54
		db 0,"Prep"		;55
		db $98,"MD"		;56
		db 0,"Drives"		;57
		db 0,"oldfn"		;58
		db 0,"newfn"		;59
		db 0,"len"		;5a
		db 0,"Cols"		;5b
		db $99,"?"		;5c
		db 0,"Commands"		;5d
		db 0," "			;5e
		db 0,"-"			;5f
		
		db 0,"Volume"		;60
		db 0,"Full"		;61
		db 0,"Not"		;62
		db 0,"Found"		;63
		db 0,"Length"		;64
		db 0,"Zero"		;65
		db 0,"Out"		;66
		db 0,"Of"			;67
		db 0,"Range"		;68
		db 0,"Already"		;69
		db 0,"Exists"		;6a
		db 0,"At"			;6b
		db 0,"Root"		;6c
		db 0,"Mismatch"		;6d
		db 0,"Request"		;6e
		db 0,"Data"		;6f

		db 0,"EOF"		;70
		db 0,"After"		;71
		db 0,"Unknown"		;72
		db 0,"Command"		;73
		db 0,"Bad"		;74
		db 0,"Hex"		;75
		db 0,"No"			;76
		db 0,"Aborted"		;77
		db 0,"Present"		;78
		db 0,"Checksum"		;79
		db 0,"Loaded"		;7a
		db 0,"Comms"		;7b
		db 0,"Error"		;7c
		db 0,"Arguments"		;7d
		db 0,"Lost"		;7e
		
		db 0
fat16_txt		db "FAT16"		;7f

		db 0,"Serial"		;80
		db 0,"Time"		;81
		db 0,"Out"		;82
		db 0,"Too"		;83
		db 0,"Long"		;84
		db 0,"Destination"		;85
		db 0,"Selected"		;86
		db 0,"Invalid"		;87
		db 0,"Missing"		;88
		db 0,"OK"			;89
		db 0,"OS"			;8a
		db 0,"Protected"		;8b		
		db 0,"A"			;8c
		db 0,"Is"			;8d
		db 0,"Empty"		;8e
		db 0,"End"		;8f
		
		db 0,"$"
hex_byte_txt	db "xx"			;90 (for hex-to-ascii)
		
		db 0,"Append"		;91
		db 0,"?"			;92
		db 0,"$"			;93 
		db 0,"Awaiting"		;94
		db 0,"Receiving"		;95
		db 0,"Sending"		;96
		db 0,11			;97 (new line)
		db 0,".."			;98
		db 0,"Name"		;99
		db 0," Bytes"		;9a
		db 0,"Press"		;9b
		db 0,"Any"		;9c
		db 0,"Key"		;9d
		db 0,"Enter"		;9e
		db $9a,"EXEC"		;9f

		db 0,"Run"		;a0
		db 0,"Script"		;a1
yes_txt		db 0,"YES" 		;a2
		db 0,"To"			;a3
		db 0,"Set"		;a4
		db 0,"Continue"		;a5
		db 0,"None"		;a6
		db 0,"Driver"		;a7
		db $9b,"<"		;a8
				
		db 0,1			;END MARKER





save_append_msg	db $21,$99,$69,$6a,$5f,$91,$6f,$92,0	;"File Name Already Exists - Append data?"
os_loadaddress_msg 	db $2f,$0a,$93,0			;"Load Addr: $",0
os_bank_msg	db $26,$0c,$93,0			;"Start Bank: $",0
os_filesize_msg	db $21,$64,$93,0			;"File Size: $",0
ser_rec_msg	db $94,$21,$98,$97,0		;"Waiting For File..",11,0
ser_rec2_msg	db $95,$6f,$98,$97,0		;"Receiving Data..",11,0
ser_send_msg	db $96,$6f,$98,$97,0		;"Sending Data..",11,0
hw_err_msg	db $a7,$7c,$90,$97,0		;"Driver Error:$xx",11,0
disk_err_msg	db $60,$7c,0			;"Disk Error",0
script_aborted_msg	db $a1,$77,$97,$97,0		;"Script Aborted",11.0


packed_help1	db $97,$0
		db $01,$0					;DEBUG
		db $02,$0					;-----
		db $33,$07,$09,$5f,$4f,$50,$0b,$0		; ": ad a b c - Write Mem Bytes"
		db $34,$07,$51,$5f,$4f,$14,$0			; "> ad "txt" - write ASCII"
		db $a8,$07,$09,$5f,$4f,$0b,$1e,$17,$0		; "< ad a b c - write bytes / disassemble" 
		db $35,$08,$5f,$1b,$0c,$0			; "B bnk - change bank"
		db $37,$19,$07,$07,$07,$08,$19,$50,$0		; "C ad ad ad bnk - copy mem"
		db $3b,$07,$07,$5f,$17,$0			; "D ad ad - disassemble"
		db $3f,$07,$07,$54,$5f,$0e,$50,$0		; "F ad ad a" - fill mem"		
		db $42,$07,$5f,$0f,$0a,$0			; "G ad - goto address"
		db $3e,$07,$07,$09,$5f,$0d,$50,$0		; "H ad ad a b c - hunt mem"
		db $44,$07,$5f,$10,$50,$0b,$0			; "M ad - show mem bytes"
		db $47,$5f,$10,$11,$12,$0			; "R - show CPU registers"
		db $4c,$5f,$10,$50,$13,$14,$0			; "T - show mem as ASCII"
		db $97,0
		db $98,0					; ".."
		db $ff
	
		db $97,$0
		db $03,$0					; IO
		db $04,$0					; --
		db $38,$23,$1e,$1d,$5f,$1b,$60,$1e,$1d,$0	; "CD DRVx/dir - change volume / dir"
		db $3c,$1f,$5f,$20,$21,$0			; "DEL fn - delete file"
		db $3d,$5f,$10,$1d,$0			; "DIR - show dir"
		db $41,$1a,$99,$0				; "FORMAT Device Name - prep drive"
		db $43,$1f,$07,$08,$5f,$2f,$21,$0		; "LB fn ad bnk - load file"
		db $56,$1d,$5f,$24,$1d,$0			; "MD fn make dir"
		db $45,$5f,$25,$57,$0			; "MOUNT remount drives"
		db $48,$1d,$5f,$29,$1d,$0			; "RD dir - remove dir"
		db $49,$58,$59,$5f,$2a,$21,$0			; "RN oldfn newfn - rename file"
		db $4a,$1f,$07,$08,$5f,$2c,$21,$0		; "RX fn ad bnk - receive file"
		db $4b,$1f,$07,$08,$5a,$5f,$2d,$21,$0		; "SB fn len bnk - save file"
		db $4d,$1f,$07,$08,$5a,$5f,$2e,$21,$0		; "TX fn len bnk - transmit file"		
		db $23,$5f,$18,$60,0			; "VOLx: - switch volume"
		db $97,$0
		db $98,$0					; ".."
		db $ff

		db $97,0
		db $05,0					; MISC
		db $06,0					; ----
		db $39,$5f,$15,$16,0			; "CLS - clear screen"
		db $3a,$32,$5f,$1b,$5b,0			; "COLOUR pen [paper border cursor] change cols"
		db $9f,$1f,$5f,$a0,$a1,0			; "EXEC fn - run script"
		db $4e,$5f,$10,$30,$31,0			; "VERS - show OS/HW version"
		db $5c,$5f,$10,$5d,0			; "? - Show commands"		
		db $97,0
		db $ff




os_cmd_locs	dw os_cmd_colon	;command 0
		dw os_cmd_gtr	;1
		dw os_cmd_b	;2
		dw os_cmd_c	;3
		dw os_cmd_cd	;4
		dw os_cmd_cls	;5	
		dw os_cmd_colour	;6
		dw os_cmd_d	;7

		dw os_cmd_del	;8
		dw os_cmd_dir	;9
		dw os_cmd_h	;a
		dw os_cmd_f	;b
		dw os_cmd_format	;c
		dw os_cmd_lb	;d
		dw os_cmd_m	;e

		dw os_cmd_remount	;f	
		dw os_cmd_r	;10
		dw os_cmd_rd	;11
		dw os_cmd_rn	;12
		dw os_cmd_rx	;13	
		dw os_cmd_sb	;14
		dw os_cmd_t	;15
		dw os_cmd_tx	;16	

		dw os_cmd_vers	;17											
		dw os_cmd_md	;18
		dw os_cmd_help	;19
		dw os_cmd_exec	;1a
		dw os_cmd_ltn	;1b


packed_msg_list	db 0			;First message marker
		
		db $60,$61,0		;$01 Volume Full (FS error code 01)
		db $21,$62,$63,0		;$02 File Not Found (FS error code 02)
		db $1d,$61,0		;$03 Dir Full (FS error code 03)
		db $62,$8c,$1d,0		;$04 Not A Dir (FS error code 04) 
		db $1d,$8d,$62,$8e,0	;$05 Dir Is Not Empty (FS error code 05)
		db $62,$8c,$21,0		;$06 Not A File (FS error code 06)
		db $21,$64,$8d,$65,0	;$07 File Length Is Zero (FS error code 07)
		db $0a,$66,$67,$68,0	;$08 Address out of range (FS error code 08)
		db $21,$99,$69,$6a,0	;$09 File Name Already Exists (FS error code 09)
		db $69,$6b,$6c,0		;$0a Already at root (FS error code 0a)

		db $72,$73,0		;$0b Unknown command (OS error code 01)
		db $87,$75,0		;$0c Invalid Hex (OS error code 02)
		db $76,$21,$99,0		;$0d No file name (OS error code 03)

		db $87,$60,0		;$0e Invalid Volume (OS error code 04)
		db $79,$74,0		;$0f Checksum bad (OS error code 05)
		db $9a,$7a,0		;$10 [Space] Bytes Loaded (OS error code 06)
		db $7b,$7c,0		;$11 Comms error (OS error code 07)
		db $74,$7d,0		;$12 Bad arguments (OS error code 08)

format_err_msg	db $62,$7f,0		;$13 not FAT16 (OS error code 09)

		db $80,$81,$82,0		;$14 serial time out (OS error code 0a)
		db $21,$99,$83,$84,0	;$15 file name too long (OS error code 0b)
		db $76,$26,$0a,0		;$16 no start address (OS error code 0c)
		db $76,$21,$64,0		;$17 no file length (OS error code 0d)
		db $2d,$77,0		;$18 save aborted (OS error code 0e)
		db $2d,$7c,$6b,$85,0	;$19 save error at destination (OS error code 0f)
		db $0c,$90,$86,0		;$1a bank ** selected (OS error code 10)
		db $87,$0c,0		;$1b invalid bank (OS error code 11)
		db $76,$8f,$0a,0		;$1c no end address (OS error code 12)
		db $76,$85,$0a,0		;$1d no destination address (OS error code 13)

		db $74,$68,0		;$1e bad range (OS error code 14)
		db $88,$7d,0		;$1f missing arguments (OS error code 15)
ok_msg		db $89,0			;$20 ok (OS error code 16)

		db $87,$60,0		;$21 Invalid Volume
		db $1a,$62,$78,0		;$22 Device not present

		db $1d,$62,$63,0		;$23 Dir not found
		db $77,0			;$24 aborted (OS error code 17)

		db $21,$99,$6d,0		;$25 File name mismatch (FS error code 0c)
		db $8a,$50,$8b,0		;$26 OS RAM protected (OS error code 18)
		db $6f,$71,$70,$6e,0	;$27 Data after EOF request (FS error code 0d)
no_vols_msg	db $76,$36,$0		;$28 No Volumes
none_found_msg	db $97,$a6,$63,$0		;$29 None Found
		
		db $2c,$77,0		;$2a "Receive Aborted" - Serial receive abort
				
		db $ff			;END MARKER
		

;--------------------------------------------------------------------------------------------
; Scancode to ASCII keymap
;--------------------------------------------------------------------------------------------

unshifted_keymap						
		db $23,$00			;$0e	;unshifted
		db $00,$00,$00,$00,$00,$71,$31,$00	;$10
		db $00,$00,$7a,$73,$61,$77,$32,$00
		db $00,$63,$78,$64,$65,$34,$33,$00	;$20
		db $00,$20,$76,$66,$74,$72,$35,$00
		db $00,$6e,$62,$68,$67,$79,$36,$00	;$30
		db $00,$00,$6d,$6a,$75,$37,$38,$00
		db $00,$2c,$6b,$69,$6f,$30,$39,$00	;$40
		db $00,$2e,$2f,$6c,$3b,$70,$2d,$00
		db $00,$00,$27,$00,$5b,$3d,$00,$00	;$50
		db $00,$00,$00,$5d,$00,$23,$00,$00
		db $00,$5c			;$60-$61	
		
shifted_keymap	db $7e,$00			;$0e	;shifted	
		db $00,$00,$00,$00,$00,$51,$21,$00	;$10
		db $00,$00,$5a,$53,$41,$57,$22,$00
		db $00,$43,$58,$44,$45,$24,$60,$00	;$20
		db $00,$20,$56,$46,$54,$52,$25,$00
		db $00,$4e,$42,$48,$47,$59,$5e,$00	;$30
		db $00,$00,$4d,$4a,$55,$26,$2a,$00
		db $00,$3c,$4b,$49,$4f,$29,$28,$00	;$40
		db $00,$3e,$3f,$4c,$3a,$50,$5f,$00
		db $00,$00,$40,$00,$7b,$2b,$00,$00	;$50
		db $00,$00,$00,$7d,$00,$7e,$00,$00
		db $00,$7c			;$60-$61		
	
;---------------------------------------------------------------------------------------------


ui_index		db 0			; user input
ui_string		ds OS_window_cols+2,0	; ""      ""


pen_colours	dw $000,$00f,$f00,$f0f,$0f0,$0ff,$ff0,$fff
		dw $555,$999,$ccc,$f71,$07f,$df8,$840

current_pen	dw $7		; current pen selection - WORD padded! (bit 7 = inverse mode)
ui_paper		dw $007		; background colour ($RGB)
ui_border		dw $00b		; border colour
ui_cursor		dw $48f		; cursor colour

;==================================================================================
;  Serial Routine Data
;==================================================================================

serial_timeout	db 0
serial_bank	db 0
serial_address	dw 0
serial_fn_addr	dw 0
serial_filename	ds 18,0			
serial_fn_length	db 0

serial_fileheader   ds 20,0
serial_headertag	db "Z80P.FHEADER"		;12 chars


;----------------------------------------------------------------------------------
; FILE SYSTEM RELATED VARIABLES
;----------------------------------------------------------------------------------

boot_drive	db 0

current_volume	db 0
	
current_driver	db 0	;normally updated by the "change volume" routine

device_count	db 0	;IE: the number of devices that initialized

volume_count	db 0
				
vol_txt		db " VOL0:",0	;space prefix intentional
dev_txt		db "DEV0:",0

;===================================================================================

; Each storage device type has a pointer to its driver code here.
; There must be at least one driver and there can be a maximum of 4

driver_table	

	dw sd_card_driver		;Device driver #0
	dw 0			;Device driver #1 (0 = not used)
	dw 0			;Device driver #2 (0 = not used)
	dw 0			;Device driver #3 (0 = not used)
	

; Each driver's code should have a header in the form:
; ----------------------------------------------------
;
; $0-$7 = ASCII name of device type (null terminated)
; $8    = JP to read sector routine
; $B    = JP to write sector routine
; $E    = Start of initialize device / get ID routine

;=====================================================================================

volume_dir_clusters

	ds max_volumes*2,0
	
	
; The main "volume_mount_list" info table is located under the hardware registers, each
; entry is 16 bytes in the form:

; OFFSETS
; -------
; $00 - Volume is present (0/1)
; $01 - Volume's host driver number (1 byte)	
; $02 - [reserved]
; $03 - [reserved]
; $04 - Volume's capacity in sectors (3 bytes)
; $07 - Partition number on host drive (0/1/2/3)
; $08 - Offset in sectors from MBR to partition (2 words)
; $0c - [reserved]
; $0d - [reserved]	
; $0e - [reserved]
; $0f - [reserved]

;=====================================================================================


; The "host_device_hardware_info" table is located under the video registers
; Each entry is 32 bytes, there can be 4 devices max.
;
; OFFSETS
; -------
; $00 - Device driver number
; $01 - Device's TOTAL capacity in sectors (4 bytes)
; $05 - Zero terminated hardware name (22 ASCII bytes max followed by $00)
; (remaining bytes to $1F currently unused)

;----------------------------------------------------------------------------------

dhwn_temp_pointer	dw 0
partition_temp	db 0
vols_on_device_temp	db 0
sys_driver_backup	db 0
os_quiet_mode	db 0

;----------------------------------------------------------------------------------

temp_string	ds OS_window_cols+2,0		

bank_pre_cmd	db 0
script_fn		ds 13,0

fs_drive_sel_cache	db 0		; used in format command

filesize_cache_lsw	dw 0		; used by LB command
filesize_cache_msw	dw 0		; "" 

dir_pos_cache	dw 0		; for KJT routines store/restore dir position

mouse_disp_x	dw 0		; mouse displacement (not absolute position)
mouse_disp_y	dw 0
old_mouse_disp_x	dw 0
old_mouse_disp_y	dw 0

;--------------------------------------------------------------------------------------

	