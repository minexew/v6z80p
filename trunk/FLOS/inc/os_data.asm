;*************
;* FLOS DATA *
;*************

;-------------------------------------------------------------------------------------------
; Non-packed Text Strings
;-------------------------------------------------------------------------------------------

welcome_message	db "FLOS by Phil Ruston 2012",0

storage_txt	db "Drives:",11,0

commands_txt	db "COMMANDS",0

boot_script_fn	db "BOOT_RUN.SCR",0

os_hex_prefix_txt	db "$",0

flos_version_txt	db "FLOS V:$"
flos_version_hex	db "xxxx / OSCA V:$"
osca_version_hex	db "xxxx"
crlfx2_txt	db 11,11,0

loading_txt	db "Loading..",11,0

saving_txt	db "Saving..",11,0

os_more_txt	db 11,"More?",11,11,0

nmi_freeze_txt	db 11,11,"** BREAK! **"

rep_char_txt	db "x",0

err_txt		db "ERR",0

key_txt		db "%KEY",0

ex_path_txt	db "%EX0",0

formatting_txt	db 11,11,"Formatting.. ",0
default_label	db "FLOS_DISK",0

dir_txt		db "[DIR]",0
xb_spare_txt	db "xB Free",11,0

register_txt	db " A=",0,1
		db " BC=",0,2
		db " DE=",0,2
		db " HL=",0,2
		
		db 11,$27,"A=",0,1
		db $27,"BC=",0,2
		db $27,"DE=",0,2
		db $27,"HL=",0,2
		
		db 11," IX=",0,2
		db " IY=",0,2
		db " SP=",0,2
		db " PC=",0,2,0,0

flag_txt		db " ZF=0 CF=0 SF=P PV=E IFF=0",11,11,0
		

;------------------------------------------------------------------------------------------------
; Packed text section
;------------------------------------------------------------------------------------------------

dictionary	db 0,"DEBUG:"		;01	
		db 0,"------"		;02
		db 0,"IO:"		;03
		db 0,"---"		;04
		db 0,"MISC:"		;05
		db 0,"-----"		;06
		db 0,"Filename"		;07
		db 0,"MBR"		;08
		db 0,""			;09
		db 0,"Address"		;0a
		db 0,""			;0b
		db 0,"Bank"		;0c
		db 0,""			;0d
		db 0,""			;0e
		db 0,""			;0f
		
		db 0,""			;10
		db 0,""			;11
		db 0,""			;12
		db 0,""			;13
		db 0,""			;14
		db 0,""			;15
		db 0,""			;16
		db 0,""			;17
		db 0,""			;18
		db 0,""			;19
		db 0,"Device"		;1a
		db 0,""			;1b
		db 0,""			;1c
		db 0,"Dir"		;1d
		db 0,""			;1e
		db 0,""			;1f
		
		db 0,""			;20
		db 0,"File"		;21
		db 0,""			;22
		db 0,"VOLx:"		;23
		db 0,""			;24
		db 0,""			;25
		db 0,"Start"		;26
		db 0,"Warning!"		;27
		db 0,"All"		;28
		db 0,""			;29
		db 0,""			;2a
		db 0,""			;2b
		db 0,"Receive"		;2c
		db 0,"Save"		;2d
		db 0,""			;2e
		db 0,"Load"		;2f
		
		db 0,""			;30
		db 0,""			;31
		db 0,""	;32				
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
		
		db 0,""			;40 
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
		db 0,""			;4e	
		db 0,""			;4f
		
		db 0,"Mem"		;50
		db 0,""			;51
		db 0,"Will"		;52
		db 0,""			;53
		db 0,""			;54
		db 0,""			;55
		db $97,"MD"		;56
		db 0,""			;57
		db 0,""			;58
		db 0,""			;59
		db 0,""			;5a
		db 0,""			;5b
		db $98,"?"		;5c
		db 0,""			;5d
		db 0," "			;5e ???
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
		db 0,""			;9b
		db 0,""			;9c
		db 0,""			;9d
		db 0,"Enter"		;9e 
		db $99,"EXEC"		;9f

		db 0,""			;a0
		db 0,"Script"		;a1
yes_txt		db 0,"YES" 		;a2
		db 0,"To"			;a3
		db 0,"Set"		;a4
		db 0,"Continue"		;a5
		db 0,"None"		;a6
		db 0,"Driver"		;a7
		db $9a,"<"		;a8
		db 0,"Envar"		;a9
				
		db 0,1			;END MARKER





save_append_msg	db $07,$69,$6a,$5f,$91,$6f,$92,$97,0		;"Filename Already Exists - Append data?"
ser_rec_msg	db $94,$21,$98,$97,0			;"Awaiting File..",11,0
ser_rec2_msg	db $95,$6f,$98,$97,0			;"Receiving Data..",11,0
ser_send_msg	db $96,$6f,$98,$97,0			;"Sending Data..",11,0
hw_err_msg	db $a7,$7c,$90,$97,0			;"Driver Error:$xx",11,0
disk_err_msg	db $60,$7c,0				;"Disk Error",0
script_aborted_msg	db $a1,$77,$97,$97,0			;"Script Aborted",11.0
script_error_msg	db $a1,$7c,$97,$97,0			;"Script Error",11,0
form_dev_warn1	db $27,$28,$36,$40,$97,$97,0			;"Warning! all volumes on"
form_dev_warn2	db $52,$46,$7e,$98,$9e,$a2,$a3,$a5,$97,0	;"will be lost. Enter YES to Continue"




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

		dw os_cmd_md	;17
		dw os_cmd_list	;18
		dw os_cmd_exec	;19
		dw os_cmd_ltn	;1a



packed_cmd_list	db $97,0
		db $01,$97,0
		db $02,$97,0					; DEBUG
		db $33,$34,$a8,$35,$37,$3b,$3f,$42,$3e,$44,$47,$4c,0
		db $97,$97,0

		db $03,$97,0
		db $04,$97,0					; IO
		db $38,$3c,$3d,$41,$43,$56,$45,$48,$49,$97,0
		db $4a,$4b,$4d,$23,0
		db $97,$97,0

		db $05,$97,0
		db $06,$97,0					; MISC		
		db $39,$3a,$9f,$4e,$5c,0
		db $97,$97,0
		db $ff						;end marker	


packed_msg_list	db 0			;First message marker
		
		db $60,$61,0		;$01 Volume Full
		db $21,$62,$63,0		;$02 File Not Found
		db $1d,$61,0		;$03 Dir Full
		db $62,$8c,$1d,0		;$04 Not A Dir 
		db $1d,$8d,$62,$8e,0	;$05 Dir Is Not Empty
		db $62,$8c,$21,0		;$06 Not A File
		db $21,$64,$8d,$65,0	;$07 File Length Is Zero
		
		db $0a,$66,$67,$68,0	;$08 Address out of Range
		db $07,$69,$6a,0		;$09 Filename Already Exists
		db $69,$6b,$6c,0		;$0a Already at root
		db $72,$73,0		;$0b Unknown command
		db $87,$75,0		;$0c Invalid Hex
		db $76,$07,0		;$0d No filename
		db $87,$60,0		;$0e Invalid Volume
		db $79,$74,0		;$0f Checksum bad

bytes_loaded_msg	db $9a,$7a,0		;$10 [Space] Bytes Loaded
		db $7b,$7c,0		;$11 Comms error
		db $74,$7d,0		;$12 Bad arguments
format_err_msg	db $62,$7f,0		;$13 not FAT16
		db $80,$81,$82,0		;$14 serial time out
		db $07,$83,$84,0		;$15 filename too long 
		db $76,$26,$0a,0		;$16 no start address
		db $76,$21,$64,0		;$17 no file length

		db $2d,$77,0		;$18 save aborted
		db $2d,$7c,$6b,$85,0	;$19 save error at destination
bank_msg		db $0c,$90,$86,0		;$1a bank ** selected
		db $6f,$71,$70,$6e,0	;$1b Data after EOF request
		db $76,$8f,$0a,0		;$1c no end address
		db $76,$85,$0a,0		;$1d no destination address
		db $74,$68,0		;$1e bad range
		db $88,$7d,0		;$1f missing arguments

ok_msg		db $89,0			;$20 OK
		db $87,$0c,0		;$21 invalid bank
		db $1a,$62,$78,0		;$22 Device not present
		db $1d,$62,$63,0		;$23 Dir not found
		db $87,$67,$1d,0		;$24 End of Dir
		db $07,$6d,0		;$25 Filename mismatch
		db $8a,$50,$8b,0		;$26 OS RAM protected)
		db $92,0			;$27 ? (NOT USED)

no_vols_msg	db $76,$36,$0		;$28 No Volumes
none_found_msg	db $97,$a6,$63,$0		;$29 None Found
		db $2c,$77,0		;$2a Receive Aborted - Serial receive abort
		db $a9,$62,$63,0		;$2b Envar not found
		db $a9,$21,$61,0		;$2c Envar file full
		db $77,0			;$2d Aborted
		db $76,$08,0		;$2e No MBR
		
		db $ff			;END MARKER
		

;--------------------------------------------------------------------------------------------
; Scancode to ASCII keymap
;--------------------------------------------------------------------------------------------

unshifted_keymap						
		db                     $23	;$0e-$0e	;unshifted
		db $00,$00,$00,$00,$71,$31	;$11-$16
		db $00,$7a,$73,$61,$77,$32	;$19-$1e
		db $63,$78,$64,$65,$34,$33	;$21-$26
		db $20,$76,$66,$74,$72,$35	;$29-$2e
		db $6e,$62,$68,$67,$79,$36	;$31-$36
		db $00,$6d,$6a,$75,$37,$38	;$39-$3e
		db $2c,$6b,$69,$6f,$30,$39	;$41-$46
		db $2e,$2f,$6c,$3b,$70,$2d	;$49-$4e
		db $00,$27,$00,$5b,$3d,$00	;$51-$56
		db $00,$00,$5d,$00,$23,$00	;$59-$5e
		db $5c			;$61-$61	
		
shifted_keymap	db                     $7e	;$0e-$0e	;shifted	
		db $00,$00,$00,$00,$51,$21	;$11-$16
		db $00,$5a,$53,$41,$57,$22	;$19-$1e
		db $43,$58,$44,$45,$24,$60	;$21-$26
		db $20,$56,$46,$54,$52,$25	;$29-$2e
		db $4e,$42,$48,$47,$59,$5e	;$31-$36
		db $00,$4d,$4a,$55,$26,$2a	;$39-$3e
		db $3c,$4b,$49,$4f,$29,$28	;$41-$46
		db $3e,$3f,$4c,$3a,$50,$5f	;$49-$4e
		db $00,$40,$00,$7b,$2b,$00	;$51-$56
		db $00,$00,$7d,$00,$7e,$00	;$59-$5e
		db $7c			;$61-$61		

;---------------------------------------------------------------------------------------------

function_key_list	db $05,$06,$04,$0c,$03,$0b,$83,$0a,$01	;scancodes for F1->F9
		
fkey_filename	db "Fx.CMD",0
	
	
;----------------------------------------------------------------------------------
; Colours - dont change the order of these labels
;----------------------------------------------------------------------------------

current_pen	dw $7		; current pen selection - WORD padded! (bit 7 = inverse mode)

default_paper	dw $007		; background colour ($RGB)
default_border	dw $00b		; border colour
default_cursor	dw $48f		; cursor colour

pen_colours	dw $000,$00f,$f00,$f0f,$0f0,$0ff,$ff0,$fff
		dw $555,$999,$ccc,$f71,$07f,$df8,$840


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
	
current_driver	db 0		;normally updated by the "change volume" routine

device_count	db 0		;IE: the number of devices that initialized

volume_count	db 0
				
vol_txt		db " VOL0:",0	;space prefix intentional
dev_txt		db "DEV0:",0


sector_buffer_loc	dw sector_buffer

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

os_dir_block_cache  dw 0
os_vol_cache	db 0

envar_data	db 0,0,0,0

bank_pre_cmd	db 0
exe_bank		db 0

fs_drive_sel_cache	db 0		; used in format command

filesize_cache_lsw	dw 0		; used by LB command
filesize_cache_msw	dw 0		; "" 

dir_pos_cache	dw 0		; for KJT routines store/restore dir position

ui_index		db 0
ui_max_chars	db 0


;----- INTERRUPT RELATED ----------------------------------------------------------------

default_irq_instructions	jp os_irq_handler
			jp os_no_nmi_freeze			
			
;--------------------------------------------------------------------------------------
	