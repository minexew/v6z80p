; ****************************************************************************
; * DISK TOOL (PARTION/FORMATTER) V0.05 by P.Ruston '08 - '11 	       *
; ****************************************************************************

	incdir "../EQUATES"

;---Standard header for OSCA and FLOS ----------------------------------------


	include "kernal.asm"
	include "OSCA.asm"
	include "system.asm"

	org $5000
	
;-----------------------------------------------------------------------------

begin	call kjt_clear_screen
	
	ld hl,app_banner
	call kjt_print_string
	
	ld hl,device_txt
	call kjt_print_string
	
	call kjt_get_device_info
	
	ld (device_info_table),hl
	push hl
	ld de,5
	add hl,de
	call kjt_print_string
	call new_line
	ld hl,total_cap_txt
	call kjt_print_string
	pop ix

	xor a
	ld (mbr_present),a

	ld b,(ix+4)
	ld c,(ix+3)
	ld d,(ix+2)
	ld e,(ix+1)
	ld (total_sectors),de
	ld (total_sectors+2),bc
	
	ld e,d
	ld d,c
	ld c,b
	srl c
	rr d
	rr e
	srl c
	rr d
	rr e
	srl c
	rr d
	rr e
	ex de,hl
	call show_hexword_as_decimal
	ld hl,mb_txt
	call kjt_print_string
	call new_line
	call new_line

	ld hl,partitions_txt		; show current partitions
	call kjt_print_string

	ld a,(device)
	ld bc,0
	ld de,0
	call kjt_read_sector		; get sector zero
	jp nz,disk_error
	ld hl,(sector_buffer+$1fe)		; check FAT signature @ $1FE in sector buffer 
	ld de,$aa55
	xor a
	sbc hl,de
	jp nz,no_mbr
	ld hl,sector_buffer+$36		; carry set if 36-3a = FAT16 (if this is on sector 0 there's no MBR)
	ld de,fat16_txt			
	ld b,5
	call kjt_compare_strings
	jp c,no_mbr
	ld hl,sector_buffer+$36		; carry set if 36-3a = FAT32	(if this is on sector 0 there's no MBR)
	ld de,fat32_txt			
	ld b,5
	call kjt_compare_strings
	jp c,no_mbr

	ld a,1				; assume then that this is an MBR at sector 0
	ld (mbr_present),a
	ld ix,sector_buffer+$1be
fptnlp	push af
	push ix
	add a,$2f
	ld (ptnum_txt),a
	ld a,(ix+4)			; what kind of partition is defined?
	or a				; 0 = no partition in this slot = assumed last partition
	jp z,last_ptn

	ld l,(ix+$8)			; this is a partition of *some* kind, add "sectors in partition" 
	ld h,(ix+$9)			; to "sectors from MBR" to make "first free sector"
	ld e,(ix+$c)
	ld d,(ix+$d)
	add hl,de
	ex de,hl
	ld l,(ix+$a)
	ld h,(ix+$b)
	ld c,(ix+$e)
	ld b,(ix+$f)
	adc hl,bc
	ld (first_free_sector),de
	ld (first_free_sector+2),hl

	ld c,(ix+$f)			; get size of partition
	ld d,(ix+$e)
	ld e,(ix+$d)
	srl c
	rr d
	rr e
	srl c
	rr d
	rr e
	srl c
	rr d
	rr e
	push de
	push af
	ld hl,ptnum_txt		
	call kjt_print_string
	pop af
	ld de,fat_txt
	cp $6
	jr z,fatpart
	cp $b
	jr z,fatpart
	cp $c
	jr z,fatpart
	cp $e
	jr z,fatpart
	ld de,nonfat_txt
fatpart	ex de,hl			
	call kjt_print_string
	pop hl
	call show_hexword_as_decimal		; show size of partition
	ld hl,mb_txt
	call kjt_print_string
	call new_line 

nxtptn	pop ix
	ld de,16
	add ix,de
	pop af
	inc a
	cp 5
	jp nz,fptnlp
	dec a
ptns	ld (partition_count),a
	call new_line
	jr ptnsdone

last_ptn	pop ix
	pop af
	dec a
	jr nz,ptns
	ld (partition_count),a
noptns	ld hl,none_defined_txt
	call kjt_print_string
	ld hl,0
	ld (first_free_sector),hl
	ld (first_free_sector+2),hl
	
ptnsdone	ld hl,free_txt			;show remaining space
	call kjt_print_string
	ld hl,(total_sectors)
	ld de,(first_free_sector)
	xor a
	sbc hl,de
	ex de,hl
	ld hl,(total_sectors+2)
	ld bc,(first_free_sector+2)
	sbc hl,bc
	ld e,d
	ld d,l
	ld l,h
	srl l
	rr d
	rr e
	srl l
	rr d
	rr e
	srl l
	rr d
	rr e
	ex de,hl
	ld (unallocated_mb),hl
	call show_hexword_as_decimal
	ld hl,mb_txt
	call kjt_print_string
	call new_line
	call new_line
	jr menu

no_mbr	ld hl,nombr_txt
	call kjt_print_string

;---------------------------------------------------------------------------------------------

menu	ld hl,menu_txt
	call kjt_print_string
	
waitkey	call kjt_wait_key_press
	cp $76
	jr z,quit

	ld a,b
	or a
	jr z,waitkey
	cp "0"
	jr z,init_mbr
	cp "1"
	jp z,make_part
	cp "2"
	jp z,delete_part
	cp "3"
	jp z,format_part
	cp "4"
	jp z,remount_devs
	
	jr waitkey
	
quit	call new_line
	call new_line
	xor a
	call kjt_mount_volumes
	xor a
	ret
	
;---------------------------------------------------------------------------------------------------

init_mbr	ld hl,mbr_warn_txt
	call kjt_print_string
	call kjt_get_input_string		; wait for confirmation
	or a
	jp z,begin
	ld a,(hl)
	cp "Y"
	jp nz,begin

	ld hl,working_txt
	call kjt_print_string

	ld hl,mbr_data			; copy "blank" MBR to sector buffer
	ld de,sector_buffer
	ld bc,512
	ldir

	ld a,(device)
	ld bc,0
	ld de,0
	call kjt_write_sector		; write sector zero
	jp nz,disk_error
	
	ld hl,sector_buffer			; zero the sector buffer
	ld bc,512
	xor a
	call kjt_bchl_memfill
		
	ld bc,0				; fill sectors 1-255 with zeroes
	ld de,1
mbrilp	push bc
	push de
	ld a,(device)
	call kjt_write_sector
	pop de
	pop bc
	jp nz,disk_error
	inc de
	bit 0,d
	jr z,mbrilp
	
done	ld hl,done_txt
	call kjt_print_string
	call kjt_wait_key_press
	jp begin
	
;---------------------------------------------------------------------------------------------------

make_part

	ld hl,makepart_txt
	call kjt_print_string
	
	ld a,(mbr_present)
	or a
	jr nz,mbrok
	ld hl,mpartnombr_txt
nombrerr	call kjt_print_string
	call kjt_wait_key_press
	jp begin
		
mbrok	ld a,(partition_count)
	cp 4
	jr nz,makeptn
	ld hl,ptntfull_txt
	call kjt_print_string
	call kjt_wait_key_press
	jp begin
		
makeptn	ld hl,sizereq_txt
	call kjt_print_string
	call kjt_get_input_string
	or a
	jp z,begin
	call ascii_decimal_to_hex
	jp nz,badfigs
	push hl				; check requested partition size is > 31MB and < 2049MB
	ld de,32				; and there is enough free space for it. 
	xor a
	sbc hl,de
	pop hl
	jp c,ptoosmall
	push hl
	ld de,$801
	xor a
	sbc hl,de
	pop hl
	jp nc,pmaxsize
	push hl
	dec hl
	ld de,(unallocated_mb)
	xor a
	sbc hl,de
	pop hl
	jp nc,ptoobig
	ld (new_ptn_size_mb),hl
	
	ld a,(device)
	ld bc,0
	ld de,0
	call kjt_read_sector		; read in sector zero (MBR)
	jp nz,disk_error

	ld hl,first_partition_info
	ld a,(partition_count)		; get previous partition entry data (loc and len)
	or a				; special case when no partitions
	jr z,mfirstp
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl	
	ld de,sector_buffer+$1be
	add hl,de
mfirstp	push hl
	pop ix
	ld l,(ix+$8)			; location lo
	ld h,(ix+$9)
	ld e,(ix+$c)			; length lo
	ld d,(ix+$d)
	add hl,de				; new loc lo
	ex de,hl
	ld l,(ix+$a)			; location hi
	ld h,(ix+$b)
	ld c,(ix+$e)			; length hi
	ld b,(ix+$f)
	adc hl,bc
	push hl				; new loc hi
		
	ld a,(partition_count)		; put data in relevent partition entry (in sector buffer)
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl	
	ld bc,sector_buffer+$1be
	add hl,bc
	push hl
	pop ix
	ld (ix+$8),e			; start location (lo word)
	ld (ix+$9),d
	pop de
	ld (ix+$a),e			; start location (hi word)
	ld (ix+$b),d
	
	ld hl,(new_ptn_size_mb)		; convert mb to sectors
	ld e,0
	add hl,hl
	rl e
	add hl,hl
	rl e
	add hl,hl
	rl e
	ld (ix+$c),0			; size of partition in sectors
	ld (ix+$d),l
	ld (ix+$e),h
	ld (ix+$f),e
	
	ld (ix+$4),$e			; partition type: FAT16 LBA

	ld (ix+$0),$0			; non active sector
	
	ld (ix+$1),$0			; C/H/S start tuple (unused)
	ld (ix+$2),$0
	ld (ix+$3),$0
	
	ld (ix+$5),$0			; C/H/S end tuple (unused)
	ld (ix+$6),$0
	ld (ix+$7),$0

	ld e,(ix+$8)			; note where this partition's first sector is located
	ld d,(ix+$9)
	ld c,(ix+$a)
	ld b,(ix+$b)
	ld (partition_base),de
	ld (partition_base+2),bc

	ld a,(device)
	ld bc,0
	ld de,0
	call kjt_write_sector		; rewrite MBR
	jp nz,disk_error

	call clear_sector_buffer		; also wipe partition's first sector
	ld hl,0			
	call get_bcde_lba
	ld a,(device)
	call kjt_write_sector		
	jp nz,disk_error

	jp done
		

ptoosmall

	ld hl,ptoosmall_txt
mp_err	call kjt_print_string
	call kjt_wait_key_press
	jp begin
	
badfigs	ld hl,badfigs_txt
	jr mp_err
	
ptoobig	ld hl,ptoobig_txt
	jr mp_err
	
pmaxsize	ld hl,pmaxsize_txt
	jr mp_err
	
;---------------------------------------------------------------------------------------------------

delete_part
	
	ld hl,delpart_txt
	call kjt_print_string
	
	ld hl,dp_nmbr_txt
	ld a,(mbr_present)
	or a
	jp z,nombrerr

	ld a,(partition_count)		; do any partitions exist?
	or a
	jr nz,ptdel
	ld hl,noparts_txt
	call kjt_print_string
	call kjt_wait_key_press
	jp begin
	
ptdel	push af
	ld hl,delconfirm_txt
	call kjt_print_string
	pop af
	add a,$2f
	ld (delp_number_txt),a
	ld hl,delp_number_txt
	call kjt_print_string
	call new_line
	call new_line
	ld hl,yesno_txt
	call kjt_print_string
		
	call kjt_get_input_string		; wait for confirmation
	or a
	jp z,begin
	ld a,(hl)
	cp "Y"
	jp nz,begin

	ld a,(device)
	ld bc,0
	ld de,0
	call kjt_read_sector		; get sector zero (MBR)
	jp nz,disk_error

	ld a,(partition_count)		; wipe relevant partition entry
	dec a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl	
	ld de,sector_buffer+$1be
	add hl,de
	push hl
	pop ix
	ld e,(ix+$8)			; note where this partition's first sector is located
	ld d,(ix+$9)
	ld c,(ix+$a)
	ld b,(ix+$b)
	ld (partition_base),de
	ld (partition_base+2),bc
	ld bc,16
	xor a
	call kjt_bchl_memfill
	
	ld a,(device)
	ld bc,0
	ld de,0
	call kjt_write_sector		; rewrite MBR
	jp nz,disk_error

	call clear_sector_buffer		; also wipe partition's first sector
	ld hl,0			
	call get_bcde_lba
	ld a,(device)
	call kjt_write_sector		
	jp nz,disk_error
	jp done
	
;---------------------------------------------------------------------------------------------------

format_part

	ld hl,format_txt
	call kjt_print_string
	xor a
	ld (ptn2format),a
	
	ld hl,fp_nmbr_txt
	ld a,(mbr_present)
	or a
	jp z,nombrerr
		
	ld a,(partition_count)		;are there any partitions to format?
	or a
	jr nz,okform1
	ld hl,no_parts_tf_txt
	call kjt_print_string
	call kjt_wait_key_press
	jp begin
	
okform1	cp 1				;if there's only one partition dont ask which..
	jr z,skpwhich
	ld hl,which_part_tf_txt		;which partition to format?
	call kjt_print_string
	call kjt_get_input_string		
	or a
	jp z,begin
	ld a,(partition_count)
	ld b,a
	ld a,(hl)
	sub $30
	jp c,begin
	cp b
	jp nc,begin
	ld (ptn2format),a
	
skpwhich	ld hl,volume_label_txt		;wipe volume label string	
	ld bc,12
	ld a,32
	call kjt_bchl_memfill
	ld hl,prompt_label_txt		;prompt for volume label
	call kjt_print_string
	call kjt_get_input_string
	ld de,volume_label_txt
cpyvlab	ld a,(hl)
	or a
	jr z,labeldun
	ld (de),a
	inc hl
	inc de
	jr cpyvlab

labeldun	ld a,(ptn2format)
	add a,$30
	ld (ptnfchar),a
	ld hl,format_confirm_txt		;confirm format
	call kjt_print_string
	call kjt_get_input_string		
	or a
	jp z,begin
	ld a,(hl)
	cp "Y"
	jp nz,begin

	ld a,(device)
	ld bc,0
	ld de,0
	call kjt_read_sector		; read in MBR
	jp nz,disk_error

	ld a,(ptn2format)			; get partition entry data (loc and len)
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl	
	ld de,sector_buffer+$1be
	add hl,de
	push hl
	pop ix
	ld a,(ix+4)			; check that the partition type = FAT
	cp $6
	jr z,ptntok
	cp $b
	jr z,ptntok
	cp $c
	jr z,ptntok
	cp $e
	jr z,ptntok
	ld hl,nonfatptn_txt
	call kjt_print_string
	call kjt_wait_key_press
	jp begin
	
ptntok	ld l,(ix+$8)
	ld h,(ix+$9)
	ld c,(ix+$a)
	ld b,(ix+$b)
	ld (partition_base),hl
	ld (partition_base+2),bc

	ld e,(ix+$c)			
	ld d,(ix+$d)
	ld c,(ix+$e)
	ld b,(ix+$f)			;bc:de = total sectors in partition according to MBR
	ld a,b
	or a
	jr nz,fs_truncs
	ld a,c
	cp $3f
	jr c,fs_fssok			;if more than $3f0000 sectors, fix at $3f0000
fs_truncs	ld de,$0000
	ld bc,$003f
fs_fssok	ld (partition_size),de
	ld (partition_size+2),bc

	ld a,c
	ld hl,$0080			;find appropriate cluster size (in h)
fs_fcls	add hl,hl
	cp h
	jr nc,fs_fcls
	ld a,h
	ld (cluster_size),a		
	
	ld hl,0				
ffatslp1	srl a	
	jr z,fatsc1			;divide total sectors by sectors per cluster..
	srl c				
	rr d
	rr e
	rr h
	rr l
	jr ffatslp1
fatsc1	ld b,8
ffatslp2	srl c				; ..and 256 to find length of FAT tables
	rr d
	rr e
	rr h
	rr l
	djnz ffatslp2
	ld a,h
	or l
	jr z,gotfatsize			;if remainder, add 1 to number of sectors in FAT
	inc de
	

gotfatsize

	ld (sectors_per_fat),de
	ld (bootsector_stub+$16),de		;update sectors per fat
	
	ld a,(cluster_size)			;update bootsector stub - sectors per cluster
	ld (bootsector_stub+$0d),a

	ld hl,0
	ld (bootsector_stub+$20),hl
	ld (bootsector_stub+$22),hl
	ld (bootsector_stub+$13),hl
	
	ld hl,(partition_size+2)		;partition size hi word
	ld a,h
	or l
	jr nz,bigptnsize
	ld hl,(partition_size)		;ptn size low word
	ld (bootsector_stub+$13),hl		;if ptn size < 65536, fill in this word
	jr ptnsizeset

bigptnsize

	ld (bootsector_stub+$22),hl		;if ptn size > 65535, fill in double word here
	ld hl,(partition_size)		
	ld (bootsector_stub+$20),hl		;low word
	
ptnsizeset
	
	ld hl,volume_label_txt		;update volume name in bootsector (obsolete)
	ld de,bootsector_stub+$2b
	ld bc,11
	ldir
	ld a,(ptn2format)			
	add a,$c4
	ld (bootsector_stub+$27),a		;update serial number
		
;	call show_debug_info
	
	ld hl,working_txt
	call kjt_print_string
	
	call clear_sector_buffer		;prepare partition boot sector
	ld hl,bootsector_stub
	ld de,sector_buffer
	ld bc,$3f
	ldir
	ld hl,$aa55
	ld (sector_buffer+$1fe),hl
	ld hl,0
	call get_bcde_lba			; bcde + 0 = partition base (location of partition boot sector)
	ld a,(device)
	call kjt_write_sector		; write partition boot sector
	jp nz,disk_error
	
	call clear_sector_buffer
	ld hl,(sectors_per_fat)
	add hl,hl
	ld de,32
	add hl,de				; hl = number of blank sectors to write
	push hl
	ld hl,1			
	call get_bcde_lba			; bcde + 1 = first sector address of FAT 1
	pop hl
secwp_lp	push hl				; wipe the next n sectors, where n = (2*sectors_per_fat) + sectors_in_root
	push de
	push bc
	ld a,(device)
	call kjt_write_sector
	pop bc
	pop de
	pop hl
	jp nz,disk_error
	inc de				; inc bc:de
	ld a,d
	or e
	jr nz,wscount
	inc bc
wscount	dec hl
	ld a,h
	or l
	jr nz,secwp_lp

	ld hl,$fff8			;update first sector of FAT tables
	ld (sector_buffer),hl
	ld l,$ff	
	ld (sector_buffer+2),hl
	ld hl,1
	call get_bcde_lba			;bcde = partition base + 1
	ld a,(device)
	call kjt_write_sector		;write first sector of FAT1
	jp nz,disk_error
	ld hl,(sectors_per_fat)		
	inc hl
	call get_bcde_lba			;bcde = partition base + sectors in fat + 1
	ld a,(device)
	call kjt_write_sector		;write first sector of FAT2
	jp nz,disk_error		

	call clear_sector_buffer		;make root dir sector
	ld hl,volume_label_txt
	ld de,sector_buffer
	ld bc,11
	ldir
	ld a,8
	ld (de),a				;bit 3 set = entry is volume label
	ld a,$21
	ld (sector_buffer+$18),a		;set date to 1 JAN 1980
	ld hl,(sectors_per_fat)
	add hl,hl
	inc hl				
	call get_bcde_lba			;bcde = ROOT DIR = partition base + (2 * sectors in fat) + 1
	ld a,(device)	
	call kjt_write_sector		;write first root dir sector
	jp nz,disk_error
	jp done
	
	
clear_sector_buffer

	ld hl,sector_buffer			;prepare partition boot sector
	ld bc,512
	xor a
	call kjt_bchl_memfill
	ret


get_bcde_lba

	ld de,(partition_base)		;input hl, output bc:de = partition_base + hl
	ld bc,(partition_base+2)
	add hl,de
	ex de,hl
	ret nc
	inc bc
	ret

	
show_debug_info

	call new_line
	call new_line
	ld a,(cluster_size)			;debug - show cluster size + sectors per fat
	ld hl,byte_ascii_txt+1
	call kjt_hex_byte_to_ascii
	ld hl,clustersize_txt
	call kjt_print_string
	ld hl,byte_ascii_txt
	call kjt_print_string
	call new_line
	ld a,(sectors_per_fat+1)
	ld hl,word_ascii_txt+1
	call kjt_hex_byte_to_ascii
	ld a,(sectors_per_fat)
	call kjt_hex_byte_to_ascii
	ld hl,sectorsperfat_txt
	call kjt_print_string
	ld hl,word_ascii_txt
	call kjt_print_string
	call new_line
	call new_line
	ret
	
		
ptn2format	db 0
	
partition_base	dw 0,0

partition_size	dw 0,0
	
cluster_size 	db 0

sectors_per_fat 	dw 0

volume_label_txt	ds 12," "

	
bootsector_stub

	db  $eb,$3c,$90,$6d,$6b,$64,$6f,$73,$66,$73,$00,$00,$02,$00,$01,$00 
	db  $02,$00,$02,$00,$00,$F8,$00,$00,$3F,$00,$FF,$00,$00,$00,$00,$00 
	db  $00,$00,$00,$00,$00,$00,$29,$C4,$E6,$36,$98,$20,$20,$20,$20,$20 
	db  $20,$20,$20,$20,$20,$20,$46,$41,$54,$31,$36,$20,$20,$20,$C3    


;---------------------------------------------------------------------------------------------------

remount_devs

	ld a,1
	call kjt_mount_volumes
	jp begin

;---------------------------------------------------------------------------------------------------
	
disk_error

	ld hl,disk_error_txt
	call kjt_print_string	
	jp quit
	
	
;----------------------------------------------------------------------------------

show_hexword_as_decimal



	ld de,decimal_output
	push de
	call hex2dec
	pop hl
	call showdec
	ret
	
	
hex2dec

; INPUT  : HL hex word to convert, DE = location for output string
	
	ld	bc,-10000
	call	Num1
	ld	bc,-1000
	call	Num1
	ld	bc,-100
	call	Num1
	ld	c,-10
	call	Num1
	ld	c,b

Num1	ld	a,'0'-1
Num2	inc	a
	add	hl,bc
	jr	c,Num2
	sbc	hl,bc

	ld	(de),a
	inc	de
	ret



showdec

; INPUT HL = location for most significant digit of decimal string

	ld b,4			;can only skip a max of 4 digits
shdeclp	ld a,(hl)
	cp "0"
	jr nz,dnzd
	inc hl
	djnz shdeclp
dnzd	call kjt_print_string
	ret
	

;------------------------------------------------------------------------------------------

ascii_decimal_to_hex

; INPUT:  HL = MSB ascii digit of decimal figure
; OUTPUT: HL = hex value (if ZF is not set: Error)

	ld b,0			;find lsb, check ascii digits
fdlsb	ld a,(hl)
	or a
	jr z,dnumend
	cp $30
	jr c,dnumbad
	cp $3a
	jr nc,dnumbad
	inc hl
	inc b			;b = number of digits
	ld a,b
	cp 6			;5 digits max
	jr nz,fdlsb
	xor a
	inc a
	ret
	
dnumend	ld a,b
	or a
	jr nz,dnumok
dnumbad	xor a			;zero flag not set = bad ascii figures / no text
	inc a
	ret

dnumok	dec hl
	push hl
	pop iy			;iy = location on LSB ascii digit
	ld hl,declist
	ld ix,0			;tally
d2hlp2	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld a,(iy)
	sub $30
	jr z,nxtdd
d2hlp1	add ix,de
	jr c,dnumbad
	dec a
	jr nz,d2hlp1
nxtdd	dec iy
	djnz d2hlp2
	push ix
	pop hl
	xor a
	ret
	

	ret
	
declist	dw 1,10,100,1000,10000

;----------------------------------------------------------------------------------------


new_line	ld hl,newline_txt
	call kjt_print_string
	ret
	
	
	
;------------------------------------------------------------------------------------------

decimal_output	ds 6,0

mbr_data		incbin "mbr_data.bin"

;-------------------------------------------------------------------------------------------

app_banner

	db "  DISK TOOL V0.05 by Phil Ruston 2011",11
	db "  ===================================",11,11,0
	

device	db 0


device_info_table

	dw 0

total_sectors	

	dw 0,0
	
first_free_sector

	dw 0,0
		
unallocated_mb

	dw 0

partition_count

	db 0

mbr_present

	db 0
		
device_txt

	db "Device  : ",0

total_cap_txt

	db "Capacity: ",0
	
	
mb_txt
	db " MB",0
	

newline_txt

	db 11,0

new_ptn_size_mb

	dw 0
	

first_partition_info

	db 0,0,0,0, 0,0,0,0, $00,$00,$00,$00, $3e,$00,$00,$00

	
partitions_txt

	db "Partition Table:",11
	db "----------------",11,11,0


fat16_txt	db "FAT16"

fat32_txt	db "FAT32"

nombr_txt	db "Device is not partitioned (No MBR)",11,11,0

ptnum_txt	db "x) ",0

fat_txt	 db "FAT ",0
nonfat_txt db "Non-FAT ",0

disk_error_txt	db 11,11,"Disk Error!",11,11,0

none_defined_txt	db "No partitions are defined in the MBR.",11,11,0

free_txt		db "Unallocated Space: ",0



menu_txt		db "Options:",11
		db "--------",11,11
		db "0  : Initialize MBR",11
		db "1  : Make new partition",11
		db "2  : Delete last partition",11
		db "3  : Format a partition",11
		db "4  : Remount devices",11
		db "ESC: Quit",0
		



mbr_warn_txt	db 11,11,"INITIALIZE MBR",11
		db "--------------",11,11
		db "WARNING! This will erase any existing",11
		db "partitions. Are you sure you want to",11
		db "proceed?",11,11,"(y/n) ",0

delp_number_txt	db "x?",0




delpart_txt	db 11,11,"DELETE LAST PARTITION",11
		db "---------------------",11,11,0
		
delconfirm_txt	db "Sure you want to delete partition ",0
yesno_txt		db "(y/n) ",0

noparts_txt	db "There are no partitions to delete!",11,11
		db "Press any key..",0

dp_nmbr_txt	db "Error! No partitions defined (No MBR)",11,11
		db "Press any key..",0




makepart_txt	db 11,11,"MAKE NEW PARTITION",11
		db "------------------",11,11,0

ptntfull_txt	db "ERROR! The partition table is full.",11,11
		db "Press any key..",0

mpartnombr_txt	db "ERROR! Cannot make a partition on a",11
		db "device without a Master Boot Record.",11,11
		db "Please use Option 0 to initialize MBR.",11,11
		db "Press any key..",0

sizereq_txt	db "Enter size of desired partition (in MB)",11,11,":",0

working_txt	db 11,11,"Working..",0
done_txt		db 11,11,"Done! Press a key..",0

ptoosmall_txt	db 11,11,"ERROR! Minimum partition size is 32MB",11,11
		db "Press any key..",0

badfigs_txt	db 11,11, "ERROR! Invalid numeric data entered.",11,11
		db "Press any key..",0
		
ptoobig_txt	db 11,11, "ERROR! Not enough free space for the",11
		db "requested partition size.",11,11
		db "Press any key..",0

pmaxsize_txt	db 11,11, "ERROR! Maximum partition size is 2048MB",11,11
		db "Press any key..",0
		
byte_ascii_txt	db "$xx",0

word_ascii_txt	db "$xxxx",0
	
clustersize_txt	db "Cluster size: ",0

sectorsperfat_txt	db "Sectors per fat: ",0
		
		
nonfatptn_txt	db "ERROR! The partition type is not FAT",11,11
		db "Press any key..",0


	
format_txt
		db 11,11,"FORMAT PARTITION",11
		db "----------------",0

which_part_tf_txt	db 11,11,"Which partition do you want to format?",11,11
		db ":",0
	
no_parts_tf_txt	db 11,11,"There are no partitions to format!",11,11
		db "Press any key..",0
	
format_confirm_txt	db 11,11,"Sure you want to format partition "
ptnfchar		db "x?",11,"(y/n) ",0

prompt_label_txt	db 11,11,"Enter desired volume label: ",0
		
fp_nmbr_txt	db 11,11,"Error! No partitions defined (No MBR)",11,11
		db "Press any key..",0

;--------------------------------------------------------------------------------------------
	