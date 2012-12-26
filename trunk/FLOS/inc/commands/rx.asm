;---------------------------------------------------------------------------------------------------
;"RX" - Receive binary file via serial port command. V6.08
;---------------------------------------------------------------------------------------------------
;
;  6.06 - Bugfix: If comms error encountered in file header the error code is now properly returned
;  6.05 - Added "RX !" to download and run.
;
;---------------------------------------------------------------------------------------------------

os_cmd_rx	in a,(sys_serial_port)		;flush serial buffer at outset

		ld a,(hl)			;check args exist
		or a
		jp z,os_no_fn_error

		ld a,(hl)			;If args = "!", RX and run requested.
		cp "!"
		jr nz,not_rx_run
		push hl
		inc hl
		ld a,(hl)
		pop hl
		or a
		jp z,rx_run
		cp " "
		jp z,rx_run

not_rx_run
	
		call rx_copy_filename

		call hexword_or_bust		;the call only returns here if the hex in DE is valid
		jp z,os_no_start_addr		;gets load location in DE
		ld (serial_address),de
		
		call lb_test_os_loc		;make sure it doesnt overwrite the OS
		ret nz
		
		call hexword_or_bust		;the call only returns here if the hex in DE is valid
		jr nz,serl_dfb			;get bank if specified, else use current bank
		call os_getbank
		ld e,a
serl_dfb	ld b,e
		ld a,b				;check bank is in valid range
		ld (serial_bank),a
		cp max_bank+1
		jp nc,os_invalid_bank
				
		ld hl,ser_rec_msg
		call os_show_packed_text
		
		ld hl,serial_filename		; filename location in HL
		ld a,$80			; no time out / escape key active
		call serial_get_header	
		ret nz			
		ld hl,ser_rec2_msg
		call os_show_packed_text
		call serial_receive_file
		ret nz			

		ld de,serial_fileheader+$13
		call print_double_word
		jp show_bl			; show bytes loaded (use end of LB routine)


;----------------------------------------------------------------------------------------------


rx_run		ld hl,ser_rec_msg
		call os_show_packed_text

		ld hl,serial_filename+1
		ld (hl),0
		dec hl
		ld (hl),"*"
		ld a,$80			; no time out, escape key is active
		call serial_get_header
		ret nz			
		
		ld hl,ser_rec2_msg
		call os_show_packed_text
		
		call s_goodack

		ld a,1				; Set in-file timeout to 1 second
		ld (serial_timeout),a

		call s_getblock			; Read first block (256 bytes) of file into sector buffer
		jr nc,rxe_fblok
		push af			; if carry set there was an error (code in A)
		call s_badack			; tell the sender that the header was rejected
		pop af
		or a
		ret

rxe_fblok

		ld hl,(sector_buffer)
		ld de,$00ed			; check for program location header tag
		xor a
		sbc hl,de			; if present pick up load position, else use default
		ld hl,$5000
		ld a,0
		jr nz,rxe_dfa
		ld hl,(sector_buffer+4)		; specified location for file
		ld a,(sector_buffer+6)		; bank for file
rxe_dfa		ld (serial_address),hl
		ld (serial_bank),a
	
		call set_serial_bank		; save and set bank for transfer of first page of file
		ld bc,256
		ld hl,(serial_fileheader+17)	; file length [23:8]
		xor a
		or h
		or l
		jr nz,rxemtones
		ld a,(serial_fileheader+16)	; file length [7:0]
		dec b
		ld c,a
rxemtones	ld hl,sector_buffer
		ld de,(serial_address)
		ldir				; put first 256 bytes (max) of file at desired location 
		push de
		call os_restorebank
		call s_goodack		
		pop ix				; ix = load address (continuation)

		ld de,(serial_fileheader+18)	; length [31:16]
		ld hl,(serial_fileheader+16)	; length [15:0]				
		ld bc,256			; subtract 256 from file length
		xor a
		sbc hl,bc			  
		ex de,hl			; DE = filelength 15:0 - first page
		ld b,0
		sbc hl,bc			; HL: = filelenth 31:16 - first page
		jr c,rxe_done
rsmswlok	ld a,l
		or d
		or e
		jr z,rxe_done			; if L:DE = 0, all bytes already loaded 
	
		call set_serial_bank
		call s_gbloop			; load the rest of the file
		or a
		ret nz

rxe_done	call set_serial_bank		; need to set the bank again as "s_gbloop" call restores it
		call call_rx
		push af
		call os_restorebank
		pop af
		ret
	
call_rx
		ld a,1
		ld (store_registers),a		; switching to external code, so store registers by default
		call os_allow_nmi_freeze
		
		call get_pre_launch_regs	; set default args position in HL, DE = current DIR block, A = current VOL

		ld ix,(serial_address)
		ld (com_start_addr),ix
		jp (ix)
	
;----------------------------------------------------------------------------------------------

rx_copy_filename

		push hl			;clear serial filename area
		ld hl,serial_filename
		ld c,16
		call os_chl_memclear_short
		pop hl
			
		ld b,16				;max chars to copy
		ld de,serial_filename
		call os_copy_ascii_run		;(hl)->(de) until space or zero, or count = 0
		ld a,c
		ld (serial_fn_length),a
		
		call os_scan_for_space
		ret
		
;----------------------------------------------------------------------------------------------