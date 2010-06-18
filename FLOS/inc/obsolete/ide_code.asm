;-------------------------------------------------------------------------------
;- IDE sector access routines v5.00 - By Phil Ruston ---------------------------
;-------------------------------------------------------------------------------
;
;
; Core routines:
; --------------
; ide_get_id #
; ide_read_sector #*
; ide_write_sector #*
;
; (* Set LBA address bytes before calling)
; (# Set ide_status before calling)
;
; On return, carry flag = 1 if operation sucessful
;            else A = IDE error flags (or if $00, operation timed out)
;
; Variables required:
; -------------------
;
; "sector_buffer" - 512 byte array
;
; "sector_lba0" - LBA of desired sector LSB
; "sector_lba1" 
; "sector_lba2"
; "sector_lba3" - LBA of desired sector MSB
;
; "ide_status" - set bit 0 : User selects master (0) or slave (1) drive
;                    bit 1 : Flag 0 = master not previously accessed 
;                    bit 2 : Flag 0 = slave not previously accessed
;
; "ide_register0" to "ide_register7" and "ide_high_byte" must be defined
;
;------------------------------------------------------------------------

idem_get_id

	call ide_set_master
	jp ide_get_id
	
idem_read_sector

	call ide_set_master
	jp ide_read_sector
	
idem_write_sector

	call ide_set_master
	jp ide_write_sector
		
ides_get_id

	call ide_set_slave
	jp ide_get_id			

ides_read_sector

	call ide_set_slave
	jp ide_read_sector	

ides_write_sector

	call ide_set_slave
	jp ide_write_sector

;-----------------------------------------------------------------------------
			
ide_set_master

	ld a,(ide_status)
	and $fe
	ld (ide_status),a
	ret
	
ide_set_slave

	ld a,(ide_status)
	or 1
	ld (ide_status),a
	ret		

;-----------------------------------------------------------------------------

			
ide_read_sector

	call ide_setup_lba		;tell ide what drive/sector is required
	call ide_wait_busy_ready	;make sure drive is ready to proceed
	ret nc
	ld a,$20
	out (ide_register7),a	;write $20 "read sector" command to reg 7
	call ide_wait_busy_ready	;make sure drive is ready to proceed
	ret nc
	call ide_test_error		;ensure no error was reported
	ret nc
	call ide_wait_buffer	;wait for full buffer signal from drive
	ret nc
	call ide_read_buffer	;grab the 256 words from the buffer
	scf			;carry set on return = operation ok
	ret
		
;-----------------------------------------------------------------------------


ide_write_sector

	call ide_setup_lba		;tell ide what drive/sector is required
	call ide_wait_busy_ready	;make sure drive is ready to proceed
	ret nc
	ld a,$30
	out (ide_register7),a	;write $30 "write sector" command to reg 7		
	call ide_wait_busy_ready
	ret nc
	call ide_test_error		;ensure no error was reported
	ret nc
	call ide_wait_buffer	;wait for buffer ready signal from drive
	ret nc
	call ide_write_buffer	;send 256 words to drive's buffer
	call ide_wait_busy_ready	;make sure drive is ready to proceed
	ret nc
	call ide_test_error		;ensure no error was reported
	ret 			;carry set on return = operation ok

;-----------------------------------------------------------------------------


ide_get_id

	ld a,%10100000
	call master_slave_select	
	out (ide_register6),a	;select device
	call ide_wait_busy_ready
	ret nc
	ld a,$ec			;$ec = ide 'id drive' command 
	out (ide_register7),a
	call ide_wait_busy_ready	;make sure drive is ready to proceed
	ret nc
	call ide_test_error		;ensure no error was reported
	ret nc
	call ide_wait_buffer	;wait for full buffer signal from drive
	ret nc
	call ide_read_buffer	;grab the 256 words from the buffer

	ld hl,sector_buffer+$36	;location of drive name ASCII
	push hl
	ld b,20			;switch the low and high bytes of the drive
swdrname	ld c,(hl)			;name so it is in sequence
	inc hl
	ld a,(hl)
	ld (hl),c
	dec hl
	ld (hl),a
	inc hl
	inc hl
	djnz swdrname
	
	ld de,(sector_buffer+$72)	;return capacity (number of sectors) in BC:DE
	ld bc,(sector_buffer+$74)			
	
	pop hl			;retrieve location of drive name
	scf			;carry set on return = operation ok
	ret
	

;--------------------------------------------------------------------------------
; IDE internal subroutines 
;--------------------------------------------------------------------------------

	
ide_wait_busy_ready

	ld de,2500		;wait about a second max for drive to
ide_wbsy	ld b,0			;become ready before timing out
ide_dlp	djnz ide_dlp
	dec de
	ld a,d
	or e
	jr z,ide_to
	call ide_check_busyready
	jr nz,ide_wbsy
	scf			;carry 1 = ok
	ret
ide_to	xor a			;carry 0 = timed out
	ret


ide_check_busyready

	in a,(ide_register7)	;get ide status in A
	and %11000000		;mask off busy and rdy bits
	xor %01000000		;we want busy(7) to be 0 and rdy(6) to be 1
	ret			;result is zero if ready

	
;----------------------------------------------------------------------------

ide_test_error
	
	scf			;carry set = all OK
	in a,(ide_register7)	;get status in A
	bit 0,a			;test error bit
	ret z			
	bit 5,a
	jr nz,ide_err		;test write error bit
	in a,(ide_register1)	;read error report register
ide_err	or a			;make carry flag zero = error!
	ret			;if a = 0, ide busy timed out

;-----------------------------------------------------------------------------
	
ide_wait_buffer
	
	ld de,0
ide_wdrq	ld b,50			;wait 5 seconds approx
ide_blp	djnz ide_blp
	inc de
	ld a,d
	or e
	jr z,ide_to2
	in a,(ide_register7)
	bit 3,a			;to fill (or ready to fill)
	jr z,ide_wdrq
	scf			;carry 1 = ok
	ret
ide_to2	xor a			;carry 0 = timed out
	ret

;------------------------------------------------------------------------------

ide_read_buffer

	ld hl,sector_buffer
	ld b,0			;read 256 words (512 bytes per sector)
idebufrd	in a,(ide_register0)	;get low byte of ide data word first	
	ld (hl),a
	inc hl
	in a,(ide_high_byte)	;get high byte of ide data word from latch
	ld (hl),a
	inc hl
	djnz idebufrd
	ret
	
;-----------------------------------------------------------------------------

ide_write_buffer
	
	ld hl,sector_buffer		;write 256 words (512 bytes per sector)
	ld b,0			
idebufwt	ld c,(hl)			;store low byte for now			
	inc hl
	ld a,(hl)
	out (ide_high_byte),a	;send high byte to latch
	inc hl
	ld a,c
	out (ide_register0),a	;send low byte to output entire word
	djnz idebufwt
	ret
	
;-----------------------------------------------------------------------------
	

ide_setup_lba
	
	ld a,1
	out (ide_register2),a	;set sector count to 1
	ld hl,sector_lba0
	ld a,(hl)
	out (ide_register3),a	;set lba 0:7
	inc hl
	ld a,(hl)
	out (ide_register4),a	;set lba 8:15
	inc hl
	ld a,(hl)
	out (ide_register5),a	;set lba 16:23
	inc hl
	ld a,(hl)
	and %00001111		;lowest 4 bits used only
	or  %11100000		;to enable lba mode
	call master_slave_select	;set bit 4 accordingly
	out (ide_register6),a	;set lba 24:27 + bits 5:7=111
	ret

;----------------------------------------------------------------------------------------

master_slave_select

	push hl
	ld hl,ide_status
	bit 0,(hl)
	jr z,ide_mast
	or 16
ide_mast:	pop hl
	ret
	
;----------------------------------------------------------------------------------------
; END OF IDE Routines
;----------------------------------------------------------------------------------------
