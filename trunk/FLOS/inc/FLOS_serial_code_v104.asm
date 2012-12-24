;---------- RS232 File Transfer Routines -----------------------------------------------------
;
;  V1.04 - Reformatted source to Tab 8
;
;  v1.03 - Some optimization
;
;  v1.02 - If bit 7 is set in A, when calling serial_get_header is called
;          the wait will be aborted if ESC is pressed. If bit 6 is set, Enter
;          key will escape (also).
;        - Some optimization.
;
;  v1.01 - The load bank and address is now set by "serial_receive_file"
;          it made no sense for the get header routine to do this.
;          This has necessitated changing the RX command code and any
;          external apps that use the KJT routines.
;
;---------------------------------------------------------------------------------------------
; .---------------------.
; ! Receive file header !
; '---------------------'
;
; Before calling set:-
;
; HL = Filename ("*" if dont care)
;  A = Time out in seconds
;
; ZF set / A =0 if all OK and IX returns = location of serial file header
; Else:
; Error code in A: $08 = memory address out of range, $14 = time out error
;                  $25 = Filename mismatch, $0f = checksum bad, $11 = header reception error
; 
;-----------------------------------------------------------------------------------------
	

serial_get_header

		call serial_gh_main
		ret nc
		push af
		call s_badack
		pop af
		or a		
		ret
		

serial_gh_main

		ld (serial_timeout),a		; set timeout value
		ld (serial_fn_addr),hl

		call s_getblock			; gets a block in buffer / test its checksum
		ret c				; carry set = there was an error (code in A)
		
		ld hl,serial_headertag		; Check to make sure its tagged as a header block
		ld de,sector_buffer+20		; check ASCII chars 
		ld b,12
		call os_compare_strings
hdrbad		ld a,$11
		ccf
		ret c				; return with error $11 if header ID string is bad
		ld hl,sector_buffer+32
		ld b,256-32			; bytes 32-256 should be zero
s_chdr		ld a,(hl)
		inc hl
		or a
		jr nz,hdrbad
		djnz s_chdr

		ld hl,sector_buffer+16		; copy length value to fileheader 
		ld de,serial_fileheader+16
		ld bc,4
		ldir				

		ld hl,sector_buffer
		ld de,serial_fileheader		; copy filename to fileheader
		ld b,15				; 15 ASCII chars max (space/zero terminates early)
		call os_copy_ascii_run
		xor a
		ld (de),a			; null terminate string
		
		ld hl,(serial_fn_addr)		; is this the right filename?
		ld a,(hl)
		cp "*"
		jr z,s_rffns			; if requested filename = wildcard, skip compare
		ld de,serial_fileheader
		ld b,16
		call os_compare_strings
		ld a,$25			; Error $25 - Filename doesn't match
		ccf 
		ret c
		
s_rffns		ld ix,serial_fileheader		; ix = start of serial file header
		xor a
		ret



;-----------------------------------------------------------------------------------------
; .-------------------.
; ! Receive file data !
; '-------------------'
;
; Serial_get_header must be called first!
;
; Set:
;
; HL = Start Address
;  B = Start Bank  
;
; On return ix = start of serial_file_header data	
;-----------------------------------------------------------------------------------------

ext_serial_receive_file

		ld a,b
		ld (serial_bank),a
		ld (serial_address),hl

serial_receive_file

		ld a,1				; Set in-file timeout to 1 second
		ld (serial_timeout),a

		call set_serial_bank			

		call s_goodack			; send "OK" to start the first block

		ld ix,(serial_address)
		ld de,(serial_fileheader+16)
		ld hl,(serial_fileheader+18)	; HL:DE = file length
s_gbloop	call s_getblock
		jr c,s_qgbl

		ld c,0				; copy bytes from serial buffer to actual location
		ld iy,sector_buffer
s_rfloop	ld a,(iy)
		ld (ix),a			; put byte at memory location
		dec de				; length of file countdown
		ld a,e
		and d
		inc a
		jr nz,s_rfmb
		dec l
s_rfmb		ld a,e				
		or d
		or l
		jr z,s_rfabr			; if zero, last byte
		push bc
		ld bc,1
		add ix,bc			; next mem address
		pop bc
		jr nc,s_nbt
		call os_incbank			; overflow from $FFFF, goto next bank
		jr nz,s_qgbl				
		ld ix,$8000			; loop around to $8000			
s_nbt		inc iy	
		dec c
		jr nz,s_rfloop
		call s_goodack			; send OK ("ready for next block")
		jr s_gbloop

s_rfabr		call s_goodack			; final block's "OK" ack
		call os_restorebank			
		jr s_rffns			; ix = start of serial file header on exit

s_qgbl		push af
		call s_badack
		call os_restorebank
		pop af
		or a
		ret

;-----------------------------------------------------------------------------------------

s_getblock

		push hl
		push de
		push bc

		ld hl,sector_buffer		; load a block of 256 bytes
		ld b,0
s_lgb		call receive_serial_byte
		jr c,s_gberr			; timed out if carry = 1	
		ld (hl),a
		inc hl
		djnz s_lgb

		call receive_serial_byte	; get 2 more bytes - block checksum in bc
		jr c,s_gberr
		ld c,a
		call receive_serial_byte
		jr c,s_gberr		
		ld b,a

		push bc			; make and compare checksum
		ld de,sector_buffer
		ld c,0
		call crc_checksum
		pop bc
		xor a				
		sbc hl,bc
		jr z,s_gberr

		ld a,$0f			;A=$0f : bad checksum
		scf

s_gberr		pop bc
		pop de
		pop hl
		ret
		
;----------------------------------------------------------------------------------

s_goodack	push bc
		ld bc,$4b4f			;chars for "OK"
ackbytes	ld a,c
		call send_serial_byte
		ld a,b
		call send_serial_byte
		pop bc
		ret

s_badack	push bc
		ld bc,$5858			;chars for "XX"
		jr ackbytes

;=================================================================================

; .-----------.
; ! Send file !
; '-----------'

; Before calling set:-

;   HL   = filename
; C:DE   = length of file
;    B   = Bank number that file starts in
;   IX   = Start address

; ZF set / A = OK if all OK, else:
; Return code in A: $08 = memory address out of range, $11 = comms error
;                   $07 = Save length is zero

serial_send_file

		call ser_send_main
		or a
		ret
		
ser_send_main

		ld a,1				; Set timeout at about 1 second
		ld (serial_timeout),a

		ld a,b
		ld (serial_bank),a
		ld (serial_address),ix
		ld b,0
		ld (serial_fileheader+16),de	; length of file lo word
		ld (serial_fileheader+18),bc	; length of file hi word
		ld a,c
		or d
		or e
		jr nz,s_flok
		ld a,7				; Error! Save request = 0 bytes
		ret

s_flok		push hl			; clear the header	
		ld hl,serial_fileheader
		ld c,16
		call os_chl_memclear_short
		pop hl				; fill in filename
		ld de,serial_fileheader
		ld b,16
		call os_copy_ascii_run

s_fncpyd	ld hl,serial_fileheader		; send file header
		ld de,32
		ld c,0
		call s_makeblock			
		call s_sendblock
		ret c
		call s_waitack			; wait to receive "OK" acknowledge
		ret c				; anything else gives a comms error
		
		call set_serial_bank		; send file data

		ld hl,(serial_address)
		ld de,(serial_fileheader+16)	; length of file lo word
		ld bc,(serial_fileheader+18)	; length of file hi word
s_sbloop	call s_makeblock		; make a file block
		jr nz,s_rerr
		call s_sendblock		; send the file block
		jr c,s_rerr	
		call s_waitack			; wait to receive "OK" acknowledge
		jr c,s_rerr
		ld a,e	
		or d
		or c
		jr nz,s_sbloop			; was last byte of file in this block?
s_rerr		push af
		call os_restorebank
		pop af
		ret

;-------------------------------------------------------------------------------------------

s_makeblock

; set ix = src addr, c:de = byte count, a = 0 / ZF set on return if all ok
	
		push bc
		push hl
		push de
		ld hl,sector_buffer			
		ld bc,256				
		call os_bchl_memclear		 
		pop de
		pop hl
		pop bc
		
		ld b,0				; count bytes in sector
		ld iy,sector_buffer	
s_sloop		ld a,(hl)
		ld (iy),a

		dec de				; dec c:de byte count
		ld a,d
		and e
		inc a
		jr nz,s_nol
		dec c
s_nol		ld a,e
		or d
		or c
		ret z

		inc iy				; next address - check memory limit
		inc hl
		ld a,h
		or l
		jr nz,s_sbok
		ld h,$80
		call os_incbank			
		ret nz
		
s_sbok		djnz s_sloop
		xor a
		ret


;-------------------------------------------------------------------------------------------


s_sendblock

		push hl
		push de			; sends a 256 byte block and its 2 byte checksum
		push bc				
		ld hl,sector_buffer			
		ld b,0
s_sblklp	ld a,(hl)
		call send_serial_byte
		inc hl
		djnz s_sblklp
		ld de,sector_buffer
		ld c,0
		call crc_checksum
		ld a,l
		call send_serial_byte
		ld a,h
		call send_serial_byte
		xor a
s_popall	pop bc
		pop de
		pop hl
		ret
		

s_waitack
		push hl
		push de
		push bc
		call receive_serial_byte	; wait to receive "OK" acknowledge
		jr c,s_popall
		ld b,a
		call receive_serial_byte
		jr c,s_popall
		ld c,a
		ld hl,$4f4b			; "OK" ASCII chars
		xor a
		sbc hl,bc			; zero flag set on return if OK received
		jr z,s_popall

		ld a,$11			; bad ack received  ($11:"comms error")
		scf
		jr s_popall

	
		
;---------------------------------------------------------------------------------------	
; Low level routines
;---------------------------------------------------------------------------------------


ext_receive_serial_byte

		ld (serial_timeout),a


receive_serial_byte
		
		push bc
		ld a,(serial_timeout)		; max time to wait for a byte to arrive
		ld c,a
		sla c
		sla c
		
wait_sto	ld b,64
wait_sb		in a,(sys_joy_com_flags)	; if bit 6 of status flags = 1, byte is in buffer 
		bit 6,a
		jr nz,sbyte_in
		in a,(sys_irq_ps2_flags)
		bit 2,a				; if bit 2 of status flags = 1, timer has overflowed
		jr z,wait_sb
		ld a,%00000100
		out (sys_clear_irq_flags),a	; clear timer overflow flag
		djnz wait_sb		
		
		ld a,(serial_timeout)		; allow quit with ESC / ENTER?
		ld b,a
		push bc
		call os_get_key_press
		pop bc
		bit 7,b
		jr z,s_escnq
		cp $76
		jr z,s_kquit
s_escnq		bit 6,b
		jr z,sb_dchesc
		cp $5a
		jr nz,sb_dchesc
s_kquit		ld a,$2a			; ERROR CODE $2A - "RECEIVE WAIT ABORTED WITH KEYBOARD"
quit_ser	scf
		pop bc
		ret
		
sb_dchesc	ld a,c				; if time out setting was 0, never time out
		or a
		jr z,wait_sto			
		dec c				; decrement 'time out' seconds
		jr nz,wait_sto			; gives up with carry flag set after [x] seconds
ser_tout	ld a,$14			; ERROR CODE $14 - "SERIAL TIME OUT"	
		jr quit_ser

sbyte_in	in a,(sys_serial_port)		; get serial byte in A - this also clears bit 6 of status flags
		or a				; clear carry flag
		pop bc
		ret
		
	
;------------------------------------------------------------------------------------------------

send_serial_byte

; set A to byte to send before calling

		push bc
		ld b,a
waitb		in a,(sys_joy_com_flags)	; ensure no byte is still being transmitted
		bit 7,a
		jr nz,waitb
		ld a,b
		out (sys_serial_port),a
		ld b,32				; limit send speed (gap between bytes)
ssplim		djnz ssplim	
		pop bc
		xor a
		ret
	
;-----------------------------------------------------------------------------------------------

set_serial_bank

		call os_cachebank			
		ld a,(serial_bank)
		call os_forcebank
		ret

;-----------------------------------------------------------------------------------------------

; makes checksum in HL, src addr = DE, length = C bytes

crc_checksum

		ld hl,$ffff		
crcloop		ld a,(de)			
		xor h			
		ld h,a			
		ld b,8
crcbyte		add hl,hl
		jr nc,crcnext
		ld a,h
		xor 10h
		ld h,a
		ld a,l
		xor 21h
		ld l,a
crcnext		djnz crcbyte
		inc de
		dec c
		jr nz,crcloop
		ret

;----------------------------------------------------------------------------------------------
	