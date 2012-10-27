; CPM emulator V 0.0; May 15, 2010 
; CPM BDOS to FLOS translator
; This program resides in the upper 4k pages and intercepts all BDOS calls
; and translates them to FLOS calls
; This means that only well behaving CP-M programs will run without risk
; it is planned to make a BIOS jump table and fill in the calls as far as possible
; First task of the program is to switch out bank 0 and set up page 0
; After that every call to BDOS requires switching in FLOS to deal with the call

		

include 	"symbol_list.symbol"
include	"kernal_jump_table.asm"

;	literal constants
true	equ	0ffh		;constant true
false	equ	000h		;constant false
enddir	equ	0ffffh		;end of directory
byte	equ	1		;number of bytes for "byte" type
word	equ	2		;number of bytes for "word" type

;fixed addresses in low memory
jp_bios	equ	0000h		;jump to bios
jp_bdos	equ	0005h		;jump to bdos
tfcb	equ	005ch		;default fcb location
tbuff	equ	0080h		;default buffer location

;equates for non graphic characters
ctlc	equ	03h		;control c
ctle	equ	05h		;physical eol
ctlh	equ	08h		;backspace
ctlp	equ	10h		;prnt toggle
ctlr	equ	12h		;repeat line
ctls	equ	13h		;stop/start screen
ctlu	equ	15h		;line delete
ctlx	equ	18h		;=ctl-u
ctlz	equ	1ah		;end of file
rubout	equ	7fh		;char delete
tab	equ	09h		;tab char
cr	equ	0dh		;carriage return
lf	equ	0ah		;line feed
ctl	equ	5eh		;up arrow

ssize	equ	24		;24 level stack
;
;	low memory locations
reboot	equ	0000h		;reboot system
ioloc	equ	0003h		;i/o byte location
bdosa	equ	0006h		;address field of jmp BDOS
;
;	file control block (fcb) constants
empty	equ	0e5h		;empty directory entry
lstrec	equ	127		;last record# in extent
recsiz	equ	128		;record size
fcblen	equ	32		;file control block size
dirrec	equ	recsiz/fcblen	;directory elts / record
dskshf	equ	2		;log2(dirrec)
dskmsk	equ	dirrec-1
fcbshf	equ	5		;log2(fcblen)
;
extnum	equ	12		;extent number field
maxext	equ	31		;largest extent number
ubytes	equ	13		;unfilled bytes field
modnum	equ	14		;data module number
maxmod	equ	15		;largest module number
fwfmsk	equ	80h		;file write flag is high order modnum
namlen	equ	15		;name length
reccnt	equ	15		;record count field
dskmap	equ	16		;disk map field
lstfcb	equ	fcblen-1
nxtrec	equ	fcblen
ranrec	equ	nxtrec+1	;random record field (2 bytes)
;
;	reserved file indicators
rofile	equ	9		;high order of first type char
invis	equ	10		;invisible file in dir command
;	equ	11	;reserved
;
;BDOS calling codes
wbootf_code				equ	0
bd_conin_code				equ	1
bd_conout_code				equ	2
bd_aux_in_code				equ	3
bd_aux_out_code				equ	4
bd_list_out_code				equ	5
bd_direct_conin_code			equ	6
bd_aux_input_status_code			equ	7
bd_aux_out_status_code 			equ	8
bd_print_string_code			equ	9
bd_read_con_buf_code			equ	10
bd_con_status_code				equ	11
bd_version_number_code			equ	12
bd_reset_disk_system_code			equ	13
bd_select_disk_code				equ	14
bd_open_file_code				equ	15
bd_close_file_code				equ	16
bd_search_first_code			equ	17
bd_search_next_code				equ	18
bd_delete_file_code				equ	19
bd_read_sequential_code			equ	20
bd_write_sequential_code			equ	21
bd_make_file_code				equ	22
bd_rename_file_code				equ	23
bd_return_login_vector_code			equ	24
bd_return_current_disk_code			equ	25
bd_set_dma_address_code			equ	26
bd_get_allocaction_address_code		equ	27
bd_write_protect_disk_code			equ	28
bd_get_read_only_vector_code			equ	29
bd_set_file_attributes_code			equ	30
bd_get_disk_parameter_block_address_code	equ	31
bd_get_set_user_code_code			equ	32
bd_read_random_code				equ	33
bd_write_random_code			equ	34
bd_compute_file_size_code			equ	35
bd_set_random_record_code			equ	36
bd_reset_drive_code				equ	37
bd_access_drive_code			equ	38
bd_free_drive_code				equ	39
bd_write_random_zero_fill_code		equ	40
bd_test_and_write_record_code			equ	41
bd_lock_record_code				equ	42
bd_unlock_record_code			equ	43
bd_set_multi_sector_count_code		equ	44
bd_set_bdos_error_mode_code			equ	45
bd_get_disk_free_space_code			equ	46
bd_chain_to_program_code			equ	47
bd_flus_buffers_code			equ	48
bd_get_set_system_control_block_code		equ	49
bd_direct_bios_call_code			equ	50
bd_load_overlay_code			equ	59
bd_call_rsx_code				equ	60
bd_free_blocks_code				equ	98
bd_truncate_file_code			equ	99
bd_set_directory_label_code			equ	100
bd_return_directory_label_data_code		equ	101
bd_read_file_date_stamps_password_mode_code	equ	102
bd_write_file_xfcb_code			equ	103
bd_set_date_and_time_code			equ	104
bd_get_date_and_time_code			equ	105
bd_set_default_password_code			equ	106
bd_return_serial_number_code			equ	107
bd_get_set_program_return_code_code		equ	108
bd_get_set_console_mode_code			equ	109
bd_get_set_ouput_delimiter_code		equ	110
bd_print_block_code				equ	111
bd_list_block_code				equ	112
bd_parse_filename_code			equ	152

;	bios access constants
bootf	defl	bios+3*0	;cold boot function
wbootf	defl	bios+3*1	;warm boot function
constf	defl	bios+3*2	;console status function
coninf	defl	bios+3*3	;console input function
conoutf	defl	bios+3*4	;console output function
listf	defl	bios+3*5	;list output function
punchf	defl	bios+3*6	;punch output function
readerf	defl	bios+3*7	;reader input function
homef	defl	bios+3*8	;disk home function
seldskf	defl	bios+3*9	;select disk function
settrkf	defl	bios+3*10	;set track function
setsecf	defl	bios+3*11	;set sector function
setdmaf	defl	bios+3*12	;set dma function
readf	defl	bios+3*13	;read disk function
writef	defl	bios+3*14	;write disk function
liststf	defl	bios+3*15	;list status function
sectran	defl	bios+3*16	;sector translate


		

	org	0F000h	;to be load by non_FLOS loader
	jp	init


page_1:	jp	bios	;bios jump vector
	dw	0000h	;reserved
	jp	bdos	;bdos jump vector
	ret		;rst 1
	defb	0,0,0,0,0,0,0
	ret		;rst 2
	defb	0,0,0,0,0,0,0
	ret		;rst 3
	defb	0,0,0,0,0,0,0
	ret		;rst 4
	defb	0,0,0,0,0,0,0
	ret		;rst 5
	defb	0,0,0,0,0,0,0
	ret		;rst 6
	defb	0,0,0,0,0,0,0
	ret		;rst 7
	defb	0,0
	defs	015h	;unused
	defb	01h	;define drive A
	dw	0000h	;password1 field
	db	00h	;password1 length
	dw	0000h	;password2 field
	db	00h	;password2 length
	defs	05h	;unused
	defs	20h	;FCB #1
	defb	00h	;current record position in FCB #1
	db	0,0,0	;optional random record position
	defs	80h	;128 byte record buffer

opening1:	db	"L2-Setting up for CPM3",13,10,0
opening2:	db	"Changing directory", 13,10,0
opening3:	db	"Directory changed to \CPM,press key",13,10,0
opening4:	db	"Looking for CPM\CCP.COM",13,10,0
opening5:	db	"CPM-CCP.COM found",13,10,0
opening6	db	"File loaded",13,10,0
opening6a	db	"Start move",13,10,0
opening6b	db	"File moved",13,10,0
opening7:	db	"Returned from CCP.COM, press key",13,10,0
move_no_good:	db	"  Move no good",13,10,0
move_good	db	"Move OK. Press Key",13,10,0
calling:	db	"Calling 100h",13,10,0
calling2:	db	"Call succeeded",13,10,0
setup_done:
	db	"L2-Setup ready",13,10,0
cpm_dir:	db	"CPM",0
ccp_naam:	db	"CCP.COM",0

;---------------------------------------------------------------------------------------
;Start of setup routine
	
init:	ld	hl,0
	add	hl,sp
	ld	(entsp),hl	;entsp = stackptr
	ld	sp,lstack	;local stack setup
	ld	hl,opening1
	call	kjt_print_string	;signal on V6Z80P screen
	ld	hl,opening1
	call	FLOS_print_serial_string

;this routine has been enterd with upper bank set to 1
;now set up lower bank for CPM
;first make possible to read RAM under ROM (0000H-01FFH and video (200H-07FFH)

	call	alt_write_enable
	call	CPM_bank_in

;set up page 1

	ld	hl,page_1
	ld	bc,0100h
	ld	de,0000h
	ldir			;that's it
;change to cpm directory
	call	FLOS_bank_in
	ld 	hl,opening2		;"Changing directory", 13,10,0
	call	FLOS_print_serial_string
	call	test_first_page
	jp	nz,err253
	ld	hl,cpm_dir
	call	kjt_change_dir
	jp	nz,exit
	call	test_first_page
	jp	nz,err258
	ld	hl,opening3		;"Directory changed to \CPM,press key",13,10,0
	call	FLOS_print_serial_string
	call	test_first_page
	jp	nz,err262
	ld	hl,opening4		;"Looking for CPM\CCP.COM",13,10,0
	call	FLOS_print_serial_string
	call	test_first_page
	jp	nz,err266
	ld	hl,ccp_naam
	call	kjt_find_file
	jp	nz,exit
	call	test_first_page
	jp	nz,err271
	ld	hl,opening5		;"CPM-CCP.COM found",13,10,0
	call	FLOS_print_serial_string
	call	kjt_set_load_length
	call	test_first_page
	jp	nz,err276
	ld	hl,9000h
	ld	b,0
	call	kjt_force_load
	ld	hl,opening6		;"File loaded",13,10,0
	call	FLOS_print_serial_string
;	call	kjt_wait_key_press
	ld	hl,opening6a		;"Start move",13,10,0
	call	FLOS_print_serial_string
	ld	hl,9000h
	call	makehex
	ld	hl,hexbuf
	call	FLOS_print_serial_string
	call	CPM_bank_in
	ld	hl,9000h
	call	makehex
	call	FLOS_bank_in
	ld	hl,hexbuf
	call	FLOS_print_serial_string
	call	CPM_bank_in
	ld	hl,9000h
	ld	de,0100h
	ld	bc,0200h		;primitive move
	ldir
	call	FLOS_bank_in
	ld	hl,9000h
	call	makehex
	ld	hl,hexbuf
	call	FLOS_print_serial_string
	call	test_2_page
	jp	nz,err305
	ld	hl,opening6b		;"File moved",13,10,0
	call	FLOS_print_serial_string
	call	test_first_page
	jp	nz,err292
	call	test_2_page
	jp	nz,err305
	ld	hl,move_good		;"Move OK. Press Key"
	call	FLOS_print_serial_string
;	call	kjt_wait_key_press		;is dit een verdachte routine?
	call	test_2_page
	jp	nz,err305
	ld	hl,calling		;;"Calling 100h",
	call	FLOS_print_serial_string
	ld	hl,calling		;"Calling 100h",
	call	FLOS_print_serial_string
	call	test_first_page
	jp	nz,err303
	call	test_2_page
	jp	nz,err305
	call	CPM_bank_in
	call	0100h
;	ld	hl,opening7		;"Returned from CCP.COM, press key"
;	jr	call_ret
no_call	ld	hl,calling2		;"Call succeeded"
;	ld	de,9000h
;	ld	bc,300h
;	ldir
;	ld	hl,9000h
;	call	makehex
;	ld	hl,hexbuf
call_ret	call	FLOS_bank_in
	call	FLOS_print_serial_string
;	call	kjt_wait_key_press
exit:	ld	hl,setup_done		;"L2-Setup ready"
	call	FLOS_print_serial_string
	ld	hl,(entsp)
	ld	sp,hl
;do not change upper bank
	ret

test_first_page:
	ld	hl,testing	;enters with Flosbank in
	call	FLOS_print_serial_string
	call	CPM_bank_in
	ld	hl,0
	ld	de,page_1
	ld	bc,100h
t_f_p1:	ld	a,(de)
	cp	(hl)
	jr	nz,comperr
	inc	hl
	inc	de
	djnz	t_f_p1
comperr:	push	af
	call	FLOS_bank_in
	pop	af
	ret
	
err253:	ld	hl,txt253
	jp	print_err
txt253:	db	"Fout bij regel 253",13,10,0
err258	ld	hl,txt258
	jp	print_err
txt258:	db	"Fout bij regel 258",13,10,0
err262:	ld	hl,txt262
	jp	print_err
txt262:	db	"Fout bij regel 262",13,10,0
err266:	ld	hl,txt266
	jp	print_err
txt266:	db	"Fout bij regel 266",13,10,0
err271:	ld	hl,txt271
	jp	print_err
txt271:	db	"Fout bij regel 271",13,10,0
err276:	ld	hl,txt276
	jp	print_err
txt276:	db	"Fout bij regel 276",13,10,0
err292:	ld	hl,txt292
	jp	print_err
txt292:	db	"Fout bij regel 292",13,10,0
err303:	ld	hl,txt303
	jr	print_err
err305:	ld	hl,txt305
	call	FLOS_bank_in
	call	FLOS_print_serial_string
	call	CPM_bank_in
	ld	hl,0100h
	call	makehex
	call	FLOS_bank_in
	ld	hl,hexbuf
	call	FLOS_print_serial_string
	jr	print_ex
print_err:call	FLOS_bank_in
	call	FLOS_print_serial_string
	call	CPM_bank_in
	ld	hl,0000h
	call	makehex
	call	FLOS_bank_in
	ld	hl,hexbuf
	call	FLOS_print_serial_string
	call	CPM_bank_in
	ld	hl,0100h
	call	makehex
	call	FLOS_bank_in
	ld	hl,hexbuf
	call	FLOS_print_serial_string
print_ex	ld	hl,(entsp)
	ld	sp,hl
	ret
txt303:	db	"Fout bij regel 303",13,10,0
txt305:	db	"CCP.COM corrupt",13,10,0
testing	db	"testing page 1",13,10,0
testing2	db	"testing page 2",13,10,0

test_2_page:
	ld	hl,testing2	;enters with Flosbank in
	call	FLOS_print_serial_string
	call	CPM_bank_in
	ld	hl,100h
	ld	de,ccp_bytes
	ld	bc,11h
t_2_p1:	ld	a,(de)
	cp	(hl)
	jr	nz,t_2_p2
	inc	hl
	inc	de
	djnz	t_2_p1
t_2_p2:	push	af
	call	FLOS_bank_in
	pop	af
	ret

ccp_bytes	db	11h,3fh,01h,0eH,09h,0cdH,05h,00h,11h,11h,01h,0eh,09h,0cdh,05h,00h,0c9h,044h
	
makehex:	ld	de,hexbuf
	ld	bc,4000H
st1:	ld	a,(hl)
	push	af
	and	0f0h
	rra
	rra
	rra
	rra
	add	a,30h
	cp	3ah
	jr	c,stow
	add	a,07H
stow:	ld	(de),a
	inc	de
	pop	af
	and	0fh
	add	a,30h
	cp	3ah
	jr	c,stow1
	add	a,07H
stow1:	ld	(de),a
	inc	de
	ld	a,20h
	ld	(de),a
	inc	de
	inc	hl
	djnz	st1
	einde:	ret	

hexbuf	defs	3*40H
	db	13,10,0

	

;-----------------------------------------------------------------
;memory management
alt_write_enable
	push	af
	in	a,(sys_alt_write_page)
	ld	(alt_write_status),a
	or	%11000000
	out	(sys_alt_write_page),a
	pop	af
	ret

alt_write_disable
	push	af
	ld	a,(alt_write_status)
	out	(sys_alt_write_page),a
	pop	af
	ret

;sys_irq_enable	equ	01H

CPM_bank_in	;now switch in bank 1; leave FLOS in bank 0
	di	;no interrupts now
	call	alt_write_enable
	push	af
	in	a,(sys_low_page)
	ld	(low_page_status),a
	and	%11110000
	or	%00000011		; bank 3: 018000-01FFFF
	out	(sys_low_page),a	;FLOS no longer accessible
	pop	af
	ret

FLOS_bank_in	push	af
	ld	a,(low_page_status)
	out	(sys_low_page),a	;FLOS accessible
	pop	af
	call	alt_write_enable
	ei	;enable interrupts again
	ret
;-----------------------------------------------------------------		
FLOS_print_serial_string
	ld	a,(hl)
	or	a
	ret	z
	call	kjt_serial_tx_byte
	inc	hl
	jr	FLOS_print_serial_string
;-----------------------------------------------------------------		


;	data areas
;
		ds	ssize*2		;stack size
lstack:
illegal_function_message
		db	"Illegal BDOS function call",cr,lf,"$"
alt_write_status	db	0		;stores FLOS ststus
low_page_status	db	0		;stores FLOS status
entsp		ds	word		;user stack pointer

;	common values shared between bdosi and bdos
usrcode: 		db	0		;current user number
curdsk:		db	0		;current disk number
info:		ds	word		;information address
aret:		ds	word		;address value to return
lret		equ	aret		;low(aret)

;		data areas
pererr:	dw	persub		;permanent error subroutine
selerr:	dw	selsub		;select error subroutine
roderr:	dw	rodsub		;ro disk error subroutine
roferr:	dw	rofsub		;ro file error subroutine
;


bdos		;entry point for BDOS calls
;	ex	de,hl
;	ld	(info),hl
;	ex	de,hl		;info=DE, DE=info
;	push	hl
;	push	de
;	push	bc
;	push	af
	call	FLOS_bank_in
	ld	hl,bdostext
	call	FLOS_print_serial_string
;	pop	af
;	pop	bc
;	pop	de
	call	CPM_bank_in
	ret
bdostext	db	"BDOS reached",13,10,0
ld	a,e
	ld	(linfo),a	;linfo = low(info) - don't equ
	ld	hl,0
	ld	(aret),hl	;return value defaults to 0000
				;save user's stack pointer, set to local stack
	add	hl,sp
	ld	(entsp),hl	;entsp = stackptr
	ld	sp,lstack	;local stack setup
	xor	a
	ld	(fcbdsk),a
	ld	(resel),a	;fcbdsk,resel=false
	ld	hl,goback	;return here after all functions
	push	hl		;jmp goback equivalent to ret
	ld	a,c
	cp	nfuncs
	ret	nc		;skip if invalid #
	ld	c,e		;possible output character to C
	ld	hl,functab
	ld	e,a
	ld	d,0		;DE=func, HL=.ciotab
	add	hl,de
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;DE=functab(func)
	ld	hl,(info) ;info in DE for later xchg	
	ex	de,hl
	jp	(hl)		;dispatched
;	dispatch table for BDOS functions
functab:
	dw	wbootf				;0
	dw	bd_conin				;1
	dw	bd_conout				;2
	dw	bd_aux_in				;3
	dw	bd_aux_out			;4
	dw	bd_list_out			;5
	dw	bd_direct_conin			;6
	dw	bd_aux_input_status			;7
	dw	bd_aux_out_status 			;8
	dw	bd_print_string			;9
	dw	bd_read_con_buf			;10
	dw	bd_con_status			;11
diskf	equ	($-functab)/2			;disk funcs
	dw	bd_version_number			;12
	dw	bd_reset_disk_system		;13
	dw	bd_select_disk			;14
	dw	bd_open_file			;15
	dw	bd_close_file			;16
	dw	bd_search_first			;17
	dw	bd_search_next			;18
	dw	bd_delete_file			;19
	dw	bd_read_sequential			;20
	dw	bd_write_sequential			;21
	dw	bd_make_file			;22
	dw	bd_rename_file			;23
	dw	bd_return_login_vector		;24
	dw	bd_return_current_disk		;25
	dw	bd_set_dma_address			;26
	dw	bd_get_allocaction_address		;27
	dw	bd_write_protect_disk		;28
	dw	bd_get_read_only_vector		;29
	dw	bd_set_file_attributes		;30
	dw	bd_get_disk_parameter_block_address	;31
	dw	bd_get_set_user_code		;32
	dw	bd_read_random			;33
	dw	bd_write_random			;34
	dw	bd_compute_file_size		;35
	dw	bd_set_random_record		;36
	dw	bd_reset_drive			;37
	dw	bd_access_drive			;38
	dw	bd_free_drive			;39
	dw	bd_write_random_zero_fill		;40
	dw	bd_test_and_write_record		;41
	dw	bd_lock_record			;42
	dw	bd_unlock_record			;43
nfuncs	equ	($-functab)/2			;end of normal functions
	dw	bd_set_multi_sector_count		;44
	dw	bd_set_bdos_error_mode		;45
	dw	bd_get_disk_free_space		;46
	dw	bd_chain_to_program			;47
	dw	bd_flus_buffers			;48
	dw	bd_get_set_system_control_block	;49
	dw	bd_direct_bios_call			;50
	dw	illegal				;51
	dw	illegal				;52
	dw	illegal				;53
	dw	illegal				;54
	dw	illegal				;55
	dw	illegal				;56
	dw	illegal				;57
	dw	illegal				;58
	dw	bd_load_overlay			;59
	dw	bd_call_rsx			;60
	dw	illegal				;61
	dw	illegal				;62
	dw	illegal				;63
	dw	illegal				;64
	dw	illegal				;65
	dw	illegal				;66
	dw	illegal				;67
	dw	illegal				;68
	dw	illegal				;69
	dw	illegal				;70
	dw	illegal				;71
	dw	illegal				;72
	dw	illegal				;73
	dw	illegal				;74
	dw	illegal				;75
	dw	illegal				;76
	dw	illegal				;77
	dw	illegal				;78
	dw	illegal				;79
	dw	illegal				;80
	dw	illegal				;81
	dw	illegal				;82
	dw	illegal				;83
	dw	illegal				;84
	dw	illegal				;85
	dw	illegal				;86
	dw	illegal				;87
	dw	illegal				;88
	dw	illegal				;89
	dw	illegal				;90
	dw	illegal				;91
	dw	illegal				;92
	dw	illegal				;93
	dw	illegal				;94
	dw	illegal				;95
	dw	illegal				;96
	dw	illegal				;97
	dw	bd_free_blocks			;98
	dw	bd_truncate_file			;99
	dw	bd_set_directory_label		;100
	dw	bd_return_directory_label_data	;101
	dw	bd_read_file_date_stamps_password_mode	;102
	dw	bd_write_file_xfcb			;103
	dw	bd_set_date_and_time		;104
	dw	bd_get_date_and_time		;105
	dw	bd_set_default_password		;106
	dw	bd_return_serial_number		;107
	dw	bd_get_set_program_return_code	;108
	dw	bd_get_set_console_mode		;109
	dw	bd_get_set_ouput_delimiter		;110
	dw	bd_print_block			;111
	dw	bd_list_block			;112
	dw	illegal				;113
	dw	illegal				;114
	dw	illegal				;115
	dw	illegal				;116
	dw	illegal				;117
	dw	illegal				;118
	dw	illegal				;119
	dw	illegal				;120
	dw	illegal				;121
	dw	illegal				;122
	dw	illegal				;123
	dw	illegal				;124
	dw	illegal				;125
	dw	illegal				;126
	dw	illegal				;127
	dw	illegal				;128
	dw	illegal				;129
	dw	illegal				;130
	dw	illegal				;131
	dw	illegal				;132
	dw	illegal				;133
	dw	illegal				;134
	dw	illegal				;135
	dw	illegal				;136
	dw	illegal				;137
	dw	illegal				;138
	dw	illegal				;139
	dw	illegal				;140
	dw	illegal				;141
	dw	illegal				;142
	dw	illegal				;143
	dw	illegal				;144
	dw	illegal				;145
	dw	illegal				;146
	dw	illegal				;147
	dw	illegal				;148
	dw	illegal				;149
	dw	illegal				;150
	dw	illegal				;151
	dw	bd_parse_filename			;152

illegal:	ld	de,illegal_function_message
	ld	c,bd_list_out_code
	call	jp_bdos
	ret

persub:				;report permanent error
	ld	hl,permsg
	call	errflg		;to report the error
	cp	ctlc
	jp	z,reboot	;reboot if response is ctlc
	ret			;and ignore the error
;
selsub:				;report select error
	ld	hl,selmsg
	jp	wait$err	;wait console before boot
;
rodsub:				;report write to read/only disk
	ld	hl,rodmsg
	jp	wait$err	;wait console
;
rofsub:				;report read/only file
	ld	hl,rofmsg	;drop through to wait for console
;
wait$err:
				;wait for response before boot
	call	errflg
	jp	reboot

errflg:
				;report error to console, message address in HL
	push	hl
	call	crlf		;stack mssg address, new line
	ld	a,(curdsk)
	add	a,41H
	ld	(dskerr),a	;current disk name
	ld	de,dskmsg
	call	bd_print_string		;the error message
	pop	de
	call	bd_print_string		;error mssage tail
	ret

crlf	ld	e,13
	call	bd_conout
	ld	e,10
	call	bd_conout
	ret


goback:		;arrive here at end of processing to return to user
	ld	a,(resel)
	or	a
	jp	z,retmon
				;reselection may have taken place
	ld	hl,(info)
	ld	(hl),0		;fcb(0)=0
	ld	a,(fcbdsk)
	or	a
	jp	z,retmon
				;restore disk number
	ld	(hl),a		;fcb(0)=fcbdsk
	ld	a,(olddsk)
	ld	(linfo),a
;	call	curselect		;*** leave this out for the moment
;	return from the disk monitor
retmon:
	ld	hl,(entsp)
	ld	sp,hl		;user stack restored
	ld	hl,(aret)
	ld	a,l
	ld	b,h		;BA = HL = aret
	ret
;
;	error messages
dskmsg:	db	'Bdos Err On '
dskerr:	db	' : $'		;filled in by errflg
permsg:	db	'Bad Sector$'
selmsg:	db	'Select$'
rofmsg:	db	'File '
rodmsg:	db	'R/O$'

;
;
;
;Start of Bdos functions

	dw	wbootf				;0
;--------------------------------------------------------------------------------
bd_conin				;1
;only for serial at the moment
	call	FLOS_bank_in
w_key:	ld	a,15	;timeout value
	call	kjt_serial_rx_byte
	jr	c,w_key	;try again
	cp	13
	jr	z,echo_back
	cp	10	
	jr	z,echo_back
	cp	08
	jr	z,echo_back
;valid ascii key; tab expansion not implemented
	call	CPM_bank_in
	ret		;with char in a
echo_back	call	kjt_serial_tx_byte	;call naar conout?
	jr	w_key	
;----------------------------------------------------------------------------------
bd_conout				;2
	call	FLOS_bank_in
	ld	a,e
	;tab expansion should go here
	call	kjt_serial_tx_byte
	call	CPM_bank_in
	xor	a
	ret
bd_aux_in				;3
	xor	a
	ret
bd_aux_out			;4
	xor	a
	ret
bd_list_out			;5
	xor	a
	ret
bd_direct_conin			;6
	xor	a
	ret
bd_aux_input_status			;7
	xor	a
	ret
bd_aux_out_status 			;8
	xor	a
	ret
bd_print_string			;9
		call	FLOS_bank_in
b_p_s_1:		ld	hl,string_delimiter
		ld	a,(de)
		cp	(hl)
		jr	z,end_b_p_s
		cp	tab
		jr	z,expand_tab
		push	af
		push	de
		call	kjt_serial_tx_byte
		pop	de
		pop	af
		inc	de
		jr	b_p_s_1
expand_tab	push	de
		ld	b,8
e_t_1		ld	a," "
		push	bc
		call	kjt_serial_tx_byte
		pop	bc
		djnz	e_t_1
		pop	de
		jr	b_p_s_1
end_b_p_s:	call	CPM_bank_in
		xor	a
		ret
bd_read_con_buf			;10
	xor	a
	ret
bd_con_status			;11
	xor	a
	ret
bd_version_number			;12
	xor	a
	ret
bd_reset_disk_system		;13
	xor	a
	ret
bd_select_disk			;14
	xor	a
	ret
bd_open_file			;15
	xor	a
	ret
bd_close_file			;16
	xor	a
	ret
bd_search_first			;17
	xor	a
	ret
bd_search_next			;18
	xor	a
	ret
bd_delete_file			;19
	xor	a
	ret
bd_read_sequential			;20
	xor	a
	ret
bd_write_sequential			;21
	xor	a
	ret
bd_make_file			;22
	xor	a
	ret
bd_rename_file			;23
	xor	a
	ret
bd_return_login_vector		;24
	xor	a
	ret
bd_return_current_disk		;25
	xor	a
	ret
bd_set_dma_address			;26
	xor	a
	ret
bd_get_allocaction_address		;27
	xor	a
	ret
bd_write_protect_disk		;28
	xor	a
	ret
bd_get_read_only_vector		;29
	xor	a
	ret
bd_set_file_attributes		;30
	xor	a
	ret
bd_get_disk_parameter_block_address	;31
	xor	a
	ret
bd_get_set_user_code		;32
	xor	a
	ret
bd_read_random			;33
	xor	a
	ret
bd_write_random			;34
	xor	a
	ret
bd_compute_file_size		;35
	xor	a
	ret
bd_set_random_record		;36
	xor	a
	ret
bd_reset_drive			;37
	xor	a
	ret
bd_access_drive			;38
	xor	a
	ret
bd_free_drive			;39
	xor	a
	ret
bd_write_random_zero_fill		;40
	xor	a
	ret
bd_test_and_write_record		;41
	xor	a
	ret
bd_lock_record			;42
	xor	a
	ret
bd_unlock_record			;43
	xor	a
	ret
bd_set_multi_sector_count		;44
	xor	a
	ret
bd_set_bdos_error_mode		;45
	xor	a
	ret
bd_get_disk_free_space		;46
	xor	a
	ret
bd_chain_to_program			;47
	xor	a
	ret
bd_flus_buffers			;48
	xor	a
	ret
bd_get_set_system_control_block	;49
	xor	a
	ret
bd_direct_bios_call			;50
	xor	a
	ret
bd_load_overlay			;59
	xor	a
	ret
bd_call_rsx			;60
	xor	a
	ret
bd_free_blocks			;98
	xor	a
	ret
bd_truncate_file			;99
	xor	a
	ret
bd_set_directory_label		;100
	xor	a
	ret
bd_return_directory_label_data	;101
	xor	a
	ret
bd_read_file_date_stamps_password_mode	;102
	xor	a
	ret
bd_write_file_xfcb			;103
	xor	a
	ret
bd_set_date_and_time		;104
	xor	a
	ret
bd_get_date_and_time		;105
	xor	a
	ret
bd_set_default_password		;106
	xor	a
	ret
bd_return_serial_number		;107
	xor	a
	ret
bd_get_set_program_return_code	;108
	xor	a
	ret
bd_get_set_console_mode		;109
	xor	a
	ret
bd_get_set_ouput_delimiter		;110
	ld	hl,0ffffh
	sbc	hl,de
	jr	z,g_s_o_d_1
	ld	a,e
	ld	(string_delimiter),a
	ret
g_s_o_d_1:ld	a,(string_delimiter)
	ret

bd_print_block			;111
	xor	a
	ret
bd_list_block			;112
	xor	a
	ret
bd_parse_filename			;152
	xor	a
	ret
;
bios	xor	a
	ret	;entry point for BIOS calls
		
;	data areas
;
;	initialized data
efcb:		db	empty		;0e5=available dir entry
rodsk:		dw	0		;read only disk vector
dlog:		dw	0		;logged-in disks
dmaad:		dw	tbuff		;initial dma address
string_delimiter:	db	'$'		;cpm-convention
;
;	curtrka - alloca are set upon disk select
;	(data must be adjacent, do not insert variables)
;	(address of translate vector, not used)
cdrmaxa: 	ds	word		;pointer to cur dir max value
curtrka: 	ds	word		;current track address
curreca: 	ds	word		;current record address
buffa:	ds	word		;pointer to directory dma address
dpbaddr: 	ds	word		;current disk parameter block address
checka:	ds	word		;current checksum vector address
alloca:	ds	word		;current allocation vector address
addlist	equ	$-buffa		;address list size
;
;	sectpt - offset obtained from disk parm block at dpbaddr
;	(data must be adjacent, do not insert variables)
sectpt:	ds	word		;sectors per track
blkshf:	ds	byte		;block shift factor
blkmsk:	ds	byte		;block mask
extmsk:	ds	byte		;extent mask
maxall:	ds	word		;maximum allocation number
dirmax:	ds	word		;largest directory number
dirblk:	ds	word		;reserved allocation bits for directory
chksiz:	ds	word		;size of checksum vector
offset:	ds	word		;offset tracks at beginning
dpblist	equ	$-sectpt	;size of area
;
;	local variables
tranv:	ds	word		;address of translate vector
fcb$copied:
	ds	byte		;set true if copy$fcb called
rmf:	ds	byte		;read mode flag for open$reel
dirloc:	ds	byte		;directory flag in rename, etc.
seqio:	ds	byte		;1 if sequential i/o
linfo:	ds	byte		;low(info)
dminx:	ds	byte		;local for diskwrite
searchl: ds	byte		;search length
searcha: ds	word		;search address
tinfo:	ds	word		;temp for info in "make"
single:	ds	byte		;set true if single byte allocation map
resel:	ds	byte		;reselection flag
olddsk:	ds	byte		;disk on entry to bdos
fcbdsk:	ds	byte		;disk named in fcb
rcount:	ds	byte		;record count in current fcb
extval:	ds	byte		;extent number and extmsk
vrecord: ds	word		;current virtual record
arecord: ds	word		;current actual record
arecord1:	ds	word	;current actual block# * blkmsk
;
;	local variables for directory access
dptr:	ds	byte		;directory pointer 0,1,2,3
dcnt:	ds	word		;directory counter 0,1,...,dirmax
drec:	ds	word		;directory record 0,1,...,dirmax/4
		end
