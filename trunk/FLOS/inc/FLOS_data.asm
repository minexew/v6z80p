;*************
;* FLOS DATA *
;*************

;-------------------------------------------------------------------------------------------
; Non-packed Text Strings
;-------------------------------------------------------------------------------------------

flos_version_txt	db "FLOS v"
			db $30+((flos_version>>8)&$f)
			db $30+((flos_version>>4)&$f)
			db $30+(flos_version&$f)
			db 0

osca_version_txt	db " / OSCA v",0

author_txt		db "By Phil Ruston 2008-2013"
crlfx2_txt		db 11,11,0
		
storage_txt		db "Drives:",11,0

commands_txt		db "COMMANDS",0

boot_script_fn		db " BOOT_RUN.SCR ",0		 ; note: surrounding spaces are required for path split routine

os_hex_prefix_txt	db "$"
null_txt		db 0

os_more_txt		db 11,"More?",11,11,0

rep_char_txt		db "x",0

err_txt			db "ERR",0

key_txt			db "%KEY",0

ex_path_txt		db "%EX0",0

formatting_txt		db 11,11,"Formatting.. ",0
default_label		db "FLOS_DISK",0

dir_txt			db "[DIR]",0
xb_spare_txt		db "xB Free",11,0

nmi_freeze_txt		db 11,"** NMI **",11,11,0

register_txt		db "AF",0
			db "BC",0
			db "DE",0
			db "HL",0,0
		
			db "IX",0
			db "IY",0
			db "SP",0
			db "IR",0,0
		
			db "PC",0,0
		
			db " BANK=",0
			db " PORT0=",0
		
flag_txt		db 11," ZF=0 CF=0 SF=P PV=E IFF=0",11,11,0
		
sysram_banked_txt	db "Bank "
banknum_txt		db "xx selected ("
sysram1_txt		db "xx000-"
sysram2_txt		db "xxFFF @ 8000)",11,0

fat16_txt		db "FAT16",0

exe_txt			db ".EXE",0
flx_txt			db ".FLX",0

;------------------------------------------------------------------------------------------------
; Packed text section
;------------------------------------------------------------------------------------------------

; The first byte/char of each entry has bit 7 set. If this byte is $80-$9f, it signifies that this entry
; is also an internal command name (in which case, the actual ASCII begins on the next byte).
; $FF is a special case and is translated to 11 (ie: a FLOS CR+LF char)


dictionary	db "D"+$80,"EBUG:"		;01	
		db " "+$80			;02 (space)
		db "I"+$80,"O:"			;03
		db $7f+$80,11			;04 (new line * 2) ($FF = Special case, translated to 11 = <CR,LF>)
		db "M"+$80,"ISC:"		;05
		db "V"+$80,"alue"		;06 
		db "F"+$80,"ilename"		;07
		db "M"+$80,"BR"			;08
		db "E"+$80,"nvar"		;09
		db "A"+$80,"ddress"		;0a
		db "D"+$80,"river"		;0b
		db "B"+$80,"ank"		;0c
		db "N"+$80,"one"		;0d
		db "C"+$80,"ontinue"		;0e
		db "T"+$80,"o"			;0f
		
		db "Y"+$80,"ES" 		;10
		db "S"+$80,"cript"		;11
		db "E"+$80,"nter"		;12
		db " "+$80,"Bytes"		;13
		db "."+$80,"."			;14
		db $7f+$80			;15 (new line) ($FF = Special case, translated to 11 = <CR,LF>)
		db "S"+$80,"ending"		;16
		db "R"+$80,"eceiving"		;17
		db "A"+$80,"waiting"		;18
		db "?"+$80			;19
		db "D"+$80,"evice"		;1a
		db "A"+$80,"ppend"		;1b
		db "E"+$80,"nd"			;1c
		db "D"+$80,"ir"			;1d
		db "E"+$80,"mpty"		;1e
		db "I"+$80,"s"			;1f
		
		db "A"+$80			;20
		db "F"+$80,"ile"		;21
		db "P"+$80,"rotected"		;22
		db "V"+$80,"OLx:"		;23
		db "O"+$80,"S"			;24
		db "O"+$80,"K"			;25
		db "S"+$80,"tart"		;26
		db "W"+$80,"arning!"		;27
		db "A"+$80,"ll"			;28
		db "M"+$80,"issing"		;29
		db "I"+$80,"nvalid"		;2a
		db "D"+$80,"estination"		;2b
		db "R"+$80,"eceive"		;2c
		db "S"+$80,"ave"		;2d
		db "L"+$80,"ong"		;2e
		db "L"+$80,"oad"		;2f
		
		db "T"+$80,"oo"			;30
		db "O"+$80,"ut"			;31
		db "T"+$80,"ime"		;32				
		db $80,":"			;33
		db $81,">"			;34
		db $82,"B"			;35
		db "V"+$80,"olumes"		;36
		db $83,"C"			;37
		db $84,"CD"			;38
		db $85,"CLS"			;39
		db $86,"COLOUR"			;3a
		db $87,"D"			;3b
		db $88,"DEL"			;3c
		db $89,"DIR"			;3d
		db $8a,"H"			;3e
		db $8b,"F"			;3f
		
		db "S"+$80,"erial"		;40 
		db $8c,"FORMAT"			;41
		db "G"+$80			;42
		db $8d,"LB"			;43
		db $8e,"M"			;44
		db $8f,"MOUNT"			;45
		db "B"+$80,"e"			;46
		db $90,"R"			;47
		db $91,"RD"			;48
		db $92,"RN"			;49
		db $93,"RX"			;4a
		db $94,"SB"			;4b
		db $95,"T"			;4c
		db $96,"TX"			;4d
		db "L"+$80,"ost"		;4e	
		db "$"+$80
hex_byte_txt	db "xx"				;4f (for hex-to-ascii)
		
		db "M"+$80,"em"			;50
		db "A"+$80,"rguments"		;51
		db "W"+$80,"ill"		;52
		db "E"+$80,"rror"		;53
		db "C"+$80,"omms"		;54
		db "L"+$80,"oaded"		;55
		db $97,"MD"			;56
		db "C"+$80,"hecksum"		;57
		db "P"+$80,"resent"		;58
		db "A"+$80,"borted"		;59
		db "N"+$80,"o"			;5a
		db "H"+$80,"ex"			;5b
		db $98,"?"			;5c
		db "B"+$80,"ad"			;5d
		db "C"+$80,"ommand"		;5e
		db "-"+$80			;5f
			
		db "V"+$80,"olume"		;60
		db "F"+$80,"ull"		;61
		db "N"+$80,"ot"			;62
		db "F"+$80,"ound"		;63
		db "L"+$80,"ength"		;64
		db "Z"+$80,"ero"		;65
		db "O"+$80,"ut"			;66
		db "O"+$80,"f"			;67
		db "R"+$80,"ange"		;68
		db "A"+$80,"lready"		;69
		db "E"+$80,"xists"		;6a
		db "A"+$80,"t"			;6b
		db "R"+$80,"oot"		;6c
		db "M"+$80,"ismatch"		;6d
		db "R"+$80,"equest"		;6e
		db "D"+$80,"ata"		;6f

		db "E"+$80,"OF"			;70
		db "A"+$80,"fter"		;71
		db "U"+$80,"nknown"		;72
		db "F"+$80,"AT16"		;73
		db $99,"EXEC"			;74	
		db $9a,"<"			;75		
		db "O"+$80,"n"			;76
				
		db "*"+$80,0			;END MARKER ($7e is max dictionaty word number)




save_append_msg		db $07,$69,$6a,$5f,$1b,$6f,$19,$15+$80		;"Filename Already Exists - Append data?"
ser_rec_msg		db $18,$21,$14,$15+$80				;"Awaiting File..",11,0
ser_rec2_msg		db $17,$6f,$14,$15+$80				;"Receiving Data..",11,0
ser_send_msg		db $16,$6f,$14,$15+$80				;"Sending Data..",11,0
hw_err_msg		db $0b,$53,$4f,$15+$80				;"Driver Error:$xx",11,0
disk_err_msg		db $60,$53+$80					;"Disk Error",0
script_aborted_msg	db $11,$59,$15,$15+$80				;"Script Aborted",11.0
script_error_msg	db $11,$53,$15,$15+$80				;"Script Error",11,0
form_dev_warn1		db $27,$28,$36,$76,$15,$15+$80			;"Warning! all volumes on"
form_dev_warn2		db $52,$46,$4e,$14,$12,$10,$0f,$0e,$15+$80	;"will be lost. Enter YES to Continue"




os_cmd_locs	dw os_cmd_colon		;command 0
		dw os_cmd_gtr		;1
		dw os_cmd_b		;2
		dw os_cmd_c		;3
		dw os_cmd_cd		;4
		dw os_clear_screen	;5	
		dw os_cmd_colour	;6
		dw os_cmd_d		;7

		dw os_cmd_del		;8
		dw os_cmd_dir		;9
		dw os_cmd_h		;a
		dw os_cmd_f		;b
		dw os_cmd_format	;c
		dw os_cmd_lb		;d
		dw os_cmd_m		;e
		dw os_cmd_remount	;f	

		dw os_cmd_r		;10
		dw os_cmd_rd		;11
		dw os_cmd_rn		;12
		dw os_cmd_rx		;13	
		dw os_cmd_sb		;14
		dw os_cmd_t		;15
		dw os_cmd_tx		;16	
		dw os_cmd_md		;17

		dw os_cmd_list		;18
		dw os_cmd_exec		;19
		dw os_cmd_ltn		;1a



packed_cmd_list	db $15+$80						;DEBUG
		db $01,$04+$80
		db $02,$33,$34,$75,$35,$37,$3b,$3f,$42,$3e,$44,$47,$4c+$80
		db $04+$80

		db $03,$04+$80						; IO
		db $02,$38,$3c,$3d,$41,$43,$56,$45,$48,$49,$15+$80
		db $02,$4a,$4b,$4d,$23+$80
		db $04+$80
	
		db $05,$04+$80						; MISC
		db $02,$39,$3a,$74,$5c+$80
		db $04+$80
		db 0




packed_msg_list		db $80				;First message marker
		
			db $60,$61+$80			;$01 Volume Full
			db $21,$62,$63+$80		;$02 File Not Found
			db $1d,$61+$80			;$03 Dir Full
			db $62,$20,$1d+$80		;$04 Not A Dir 
			db $1d,$1f,$62,$1e+$80		;$05 Dir Is Not Empty
			db $62,$20,$21+$80		;$06 Not A File
			db $21,$64,$1f,$65+$80		;$07 File Length Is Zero
			
			db $0a,$66,$67,$68+$80		;$08 Address out of Range
			db $07,$69,$6a+$80		;$09 Filename Already Exists
			db $69,$6b,$6c+$80		;$0a Already at root
			db $72,$5e+$80			;$0b Unknown command
			db $2a,$5b+$80			;$0c Invalid Hex
			db $5a,$07+$80			;$0d No filename
			db $2a,$60+$80			;$0e Invalid Volume
			db $57,$5d+$80			;$0f Checksum bad

bytes_loaded_msg	db $13,$55+$80			;$10 [Space] Bytes Loaded
			db $54,$53+$80			;$11 Comms error
			db $5d,$51+$80			;$12 Bad arguments
format_err_msg		db $62,$73+$80			;$13 not FAT16
			db $40,$32,$31+$80		;$14 serial time out
			db $07,$30,$2e+$80		;$15 filename too long 
			db $5a,$26,$0a+$80		;$16 no start address
			db $5a,$21,$64+$80		;$17 no file length

			db $2d,$59+$80			;$18 save aborted
			db $2d,$53,$6b,$2b+$80		;$19 save error at destination
			db $06,$66,$67,$68+$80		;$1a Value Out of Range
			db $6f,$71,$70,$6e+$80		;$1b Data after EOF request
			db $5a,$1c,$0a+$80		;$1c no end address
			db $5a,$2b,$0a+$80		;$1d no destination address
			db $2a,$68+$80			;$1e Invalid range
			db $29,$51+$80			;$1f missing arguments

ok_msg			db $25+$80			;$20 OK
			db $2a,$0c+$80			;$21 invalid bank
			db $1a,$62,$58+$80		;$22 Device not present
			db $1d,$62,$63+$80		;$23 Dir not found
			db $1c,$67,$1d+$80		;$24 End of Dir
			db $07,$6d+$80			;$25 Filename mismatch
			db $24,$50,$22+$80		;$26 OS RAM protected
			db $5c+$80			;$27 "?" 

no_vols_msg		db $5a,$36+$80			;$28 No Volumes
none_found_msg		db $15,$0d,$63+$80		;$29 None Found
			db $2c,$59+$80			;$2a Receive Aborted - Serial receive abort
			db $09,$62,$63+$80		;$2b Envar not found
			db $09,$21,$61+$80		;$2c Envar file full
			db $59+$80			;$2d Aborted
			db $5a,$08+$80			;$2e No MBR
				
			db $ff				;END MARKER
		

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
		db $5c				;$61-$61	
		
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
		db $7c				;$61-$61		

;---------------------------------------------------------------------------------------------

function_key_list	db $05,$06,$04,$0c,$03,$0b,$83,$0a,$01	;scancodes for F1->F9
		
fkey_filename		db "Fx.CMD",0
	
	
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

serial_timeout		db 0
serial_bank		db 0
serial_address		dw 0
serial_fn_addr		dw 0
serial_filename		ds 18,0			
serial_fn_length	db 0

serial_fileheader  	ds 20,0
serial_headertag	db "Z80P.FHEADER"		;12 chars


;----------------------------------------------------------------------------------
; BOOT INFO
;----------------------------------------------------------------------------------

bootcode_version	dw 0

boot_info		db 0		; Devices present at bootcode time, bit 0 = SD Card
			db 0		; OS boot device: 1 = SD card, 2 = EEPROM, 3 = Serial

;----------------------------------------------------------------------------------
; FILE SYSTEM RELATED VARIABLES
;----------------------------------------------------------------------------------

current_volume		db 0
	
current_driver		db 0		; normally updated by the "change volume" routine

device_count		db 0		; IE: the number of devices that initialized

volume_count		db 0
				
vol_txt			db " VOL0:",0	; space prefix intentional
dev_txt			db "DEV0:",0


sector_buffer_loc	dw sector_buffer

;===================================================================================

; Each storage device type has a pointer to its driver code here.
; There must be at least one driver and there can be a maximum of 4

driver_table	

	dw sd_card_driver	;Device driver #0
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
partition_temp		db 0
vols_on_device_temp	db 0
sys_driver_backup	db 0
os_quiet_mode		db 0

;----------------------------------------------------------------------------------

pre_script_dir		dw 0
pre_script_vol		db 0

;-----------------------------------------------------------------------------------

cmd_filename_addr	dw 0

path_flag		db 0

envar_data		db 0,0,0,0

bank_pre_cmd		db 0
exe_bank		db 0

fs_drive_sel_cache	db 0		; used in format command

filesize_cache_lsw	dw 0		; used by LB command
filesize_cache_msw	dw 0		; "" 

stored_cluster		dw 0		;legacy - only for compatibility with old programs

;----------------------------------------------------------------------------------------

ui_index		db 0
ui_max_chars		db 0

;----------------------------------------------------------------------------------------

cursor_y		db 0		; keep this byte order 
cursor_x		db 0		; (allows read as word with y=LSB) 

;----- INTERRUPT RELATED ----------------------------------------------------------------

default_irq_instructions	jp os_irq_handler
				jp os_no_nmi_freeze			
			
;--------------------------------------------------------------------------------------
	