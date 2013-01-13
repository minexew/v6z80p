;--------------------------------------------------------------------------------------

os_fs_vars_loc

; Sets HL to location of following data structure:

; $00 byte     - fs_filepointer_valid
; $01 longword - fs_file_pointer
; $05 longword - fs_file_length
; $09 longword - fs_bytes_to_go
; $0d word     - fs_file_start_cluster
; $0f word     - fs_file_working_cluster
; $11 word     - fs_z80_address
; $13 byte     - fs_z80_bank

		ld hl,fs_filepointer_valid
		ret

;--------------------------------------------------------------------------------------


os_find_file	

; Before calling, set HL to address of zero terminated filename.
; Opens the file and returns info on file via CPU registers


		call fs_hl_to_filename
		call fs_open_file_command			; Returns A = 0, file found OK..
		jr c,os_fferr					; If carry = 1: h/w error.
		ret nz						; If ZF not set: File Error.		
		
		ld ix,(fs_file_length+2)			; IX:IY = length of file
		ld iy,(fs_file_length)
		xor a						; Zero flag set, all OK
		ret	

os_fferr	ld b,a						; hardware error: A = $00, B = error bits
		xor a			
		ld c,a
		inc c						; Zero flag cleared
		ret		

;--------------------------------------------------------------------------------------------------------

set_loadlength24
	
		ld (fs_bytes_to_go),hl				; set load length to A:HL
		ld h,0
		ld l,a
		ld (fs_bytes_to_go+2),hl
		ret
	
;--------------------------------------------------------------------------------------------------------	

os_set_load_length

		ld (fs_bytes_to_go),iy				; set load length to IX:IY (for kernal)
		ld (fs_bytes_to_go+2),ix
		ret

;---------------------------------------------------------------------------------------------------------

os_set_load_address

		ld (fs_z80_address),hl
		ld a,b
		ld (fs_z80_bank),a
		ret
	
;----------------------------------------------------------------------------------------------------------	

os_set_file_pointer

; Moves the "start of file" pointer allowing random access to file contents.
; Note: File pointer is reset by opening a file, and automatically incremented
;       by normal read function.

		ld (fs_file_pointer),iy				; set file pointer to IX:IY  
		ld (fs_file_pointer+2),ix
		push af
		xor a
		ld (fs_filepointer_valid),a			; invalidate filepointer
		pop af
		ret
	
;-----------------------------------------------------------------------------------------------------------

os_load_file

; loads a file in its entirity
; Before calling set:
 
; B = bank to load to
; HL = filename string
; IX = load address
				
		push bc					; cache load bank
		push ix					; cache load address IX	
		call os_find_file
		pop hl						; get the load address back, but in HL for next routine
		pop bc						; restore the load bank
		ret nz
	
	
os_force_load
 
; Loads data from a file opened with "os_find_file" 
; Before calling set:
 
; HL = load address
;  B = bank to load to
  
		call os_set_load_address			

os_continue_load
			 
		call fs_read_data_command
		jr c,os_fferr
		ret
		
;-----------------------------------------------------------------------------------------------------------

os_create_file	

; Before calling, set..

; HL = address of zero terminated filename.
; On return:

; If zero flag NOT set, there was an error.
; If   A = $00, b = hardware error code
; Else A = File system error code

		call fs_hl_to_filename
cf_fnset	call fs_create_file_command		; this routine returns A = 0/carry clear if file created OK..
		jp c,os_fferr				; translate errors to standard FLOS format (Zero Flag,A,B)
		ret

;--------------------------------------------------------------------------------------------------------

os_write_bytes_to_file

; Before calling, set..

; IX   = address to save data from
; B    = bank to save data from
; C:DE = number of bytes to save
; HL   = address of null-terminated ascii name of file the databytes are to be appended to

; On return:

; If zero flag NOT set, there was an error.
; If   A = $00, b = hardware error code
; Else A = File system error code

; NOTE:
; Will return "file not found" if the file has not been created previously.

		call os_save_setup
		jp nc,os_invalid_bank
	
os_wbfgo	ld a,(fs_file_length+2)
		ld c,a
		ld a,0+(((max_bank+2)/2)-1)	
		cp c
		jr c,os_ftbig				;attempting to save > memory size?

		call fs_write_bytes_to_file_command
		jp c,os_fferr
		ret

os_ftbig	ld a,$08				;error - file is too long
		or a
		ret	
	
	
os_save_setup

		ld a,b					
		ld (fs_z80_bank),a	
		cp max_bank+1
		ret nc
		xor a
		ld (fs_file_length+3),a
		ld a,c
		ld (fs_file_length+2),a
		ld (fs_file_length),de
		ld (fs_z80_address),ix	 	
		call fs_hl_to_filename
		scf
		ret

		
;--------------------------------------------------------------------------------------------------------

os_save_file

; This routine both creates and saves data to a new file. It is provided for compatibility with
; the legacy kjt_save_file routine. New programs should instead use the kjt_create_file and
; kjt_write_bytes_to_file routines. It cannot be used to append data to an existing file and
; will return the error "File already exists" if this is attempted.

; Before calling, set..
; HL = address of zero terminated filename.
; IX = address of file data
;  B = bank that file data resides in
; C:DE = number of bytes to save
	
		call os_save_setup
		jp nc,os_invalid_bank	
		call cf_fnset
		ret nz
		jr os_wbfgo


;-----------------------------------------------------------------------------------------------------------


os_check_volume_format

		call fs_check_disk_format
os_rffsc	jp c,os_fferr
		ret




os_format
		push hl					;set HL to label and A to DEV number
		call dev_to_driver_lookup
		pop hl
		jp nc,os_invalid_device				;invalid DEVICE selection

		push af				
		ld de,fs_sought_filename
		call fs_clear_filename
		ld b,11
		call os_copy_ascii_run
		pop af
		
		ld hl,current_driver
		ld b,(hl)
		ld (hl),a
		push bc
		push hl
		call fs_format_device_command
		pop hl
		pop bc
		ld (hl),b
		jr os_rffsc




os_make_dir

		call fs_hl_to_filename
		call fs_make_dir_command
		jr os_rffsc
		




os_change_dir

		call fs_hl_to_filename
		call fs_change_dir_command
		jr os_rffsc
		
	
	
	
os_parent_dir

		call fs_parent_dir_command
		jr os_rffsc
		


	
os_root_dir

		call fs_goto_root_dir_command
		jr os_rffsc
	

os_erase_file	
	
		call fs_hl_to_filename
		call fs_erase_file_command
		jr os_rffsc
		



os_goto_first_dir_entry	

		call fs_goto_first_dir_entry
		jr os_rffsc




os_get_dir_entry		

		call fs_get_dir_entry	
		jr os_rffsc




os_goto_next_dir_entry	
	
		call fs_goto_next_dir_entry	
		jr os_rffsc
	


os_get_current_dir_name

		call fs_get_current_dir_name
		jr os_rffsc
	
	
	
os_calc_free_space

		call fs_calc_free_space
		jr os_rffsc
		


os_rename_file

		push de
		call fs_hl_to_alt_filename		;set hl = file to rename, de = new filename
		pop hl				
		call fs_hl_to_filename	
		call fs_rename_command
		jr os_rffsc
	


os_delete_dir

		push hl
		call os_change_dir			; delete dir, and if any %assigns are pointing to it
		pop hl
		ret nz					; remove them
		push hl
		call kjt_get_dir_cluster		
		ld (scratch_pad),de			; get cluster of dir we're deleting for assign compare
		call os_parent_dir
		pop hl
		ret nz
		
		call fs_hl_to_filename
		call fs_delete_dir_command
		jp c,os_fferr
		ret nz
		
		ld ix,env_var_list
		ld b,max_envars
evloop		ld a,(ix)				; is this envar an %assign?
		cp "%"
		jr nz,notdenv
		ld a,(current_volume)			; if this doesnt refer to the same volume, skip it
		cp (ix+6)
		jr nz,notdenv
		ld e,(ix+4)
		ld d,(ix+5)
		ld hl,(scratch_pad)
		xor a
		sbc hl,de
		jr nz,notdenv				; is the assign refering to the deleted dir?
		call page_out_hw_registers
		ld (ix),0
		call page_in_hw_registers
notdenv		ld de,8
		add ix,de
		djnz evloop
		xor a
		ret
		
		
;----- FAST SECTOR READ FOR EXTERNAL PROGRAMS ----------------------------------------------------------------

; This routine allow direct access to the sector read routine with minimal OS overhead.
; The location of the sector buffer can be specified (no copying is required, speeding up
; the operation) - little error checking is performed! (IE: not LBA range test)

get_sector_read_addr

; set A to device the read routine address is required from.

		call dev_to_driver_lookup		
		call locate_driver_base			; returns loc in DE
		ld hl,8
		add hl,de				; HL = address of read routine
		ld de,sector_lba0			; DE = address of LBA var
		ld bc,sector_buffer_loc			; BC = address of sector buffer location variable
		xor a
		ret
		
	
	
;----- LOW LEVEL SECTOR ACCESS ETC FOR EXTERNAL PROGRAMS ---------------------------------------------------


; These routines allow low-level sector access, using the stardard OS sector buffer


user_read_sector
	
		call user_access_preamble
		ret nz
		ld (current_driver),a
		call fs_read_sector
sect_done	push af
		ld a,(sys_driver_backup)		;restore system driver number
		ld (current_driver),a
		pop af
		jp os_rffsc
	

user_write_sector

		call user_access_preamble
		ret nz
		ld (current_driver),a
		call fs_write_sector
		jr sect_done


user_access_preamble


		push af				;set A = device 
		ld (sector_lba0),de			;set sector required = BC:DE 
		ld (sector_lba2),bc			
		call dev_to_driver_lookup		;on return if ZF set: all OK, else sector out of range
		push hl
		pop ix
		ld l,(ix+3)
		ld h,(ix+4)
		ld de,(sector_lba2)
		xor a
		sbc hl,de
		jr c,range_err
		jr nz,range_ok
		ld l,(ix+1)
		ld h,(ix+2)
		ld de,(sector_lba0)
		xor a
		sbc hl,de
		jr c,range_err
		jr nz,range_ok
range_err	pop af
		ld a,$1e				;"bad range" error
		or a					;clear zero flag
		ret
	
range_ok	ld a,(current_driver)
		ld (sys_driver_backup),a
		pop af					;get requested device back
		call dev_to_driver_lookup
		jp nc,os_invalid_device
os_null		cp a					;set zero flag, retaining contents of A (driver number)
		ret
		




os_get_device_info

		ld hl,host_device_hardware_info
		ld de,driver_table
		ld a,(device_count)
		ld b,a
		ld a,(current_driver)
		ret




os_get_volume_info

		ld hl,volume_mount_list	
		ld a,(volume_count)
		ld b,a
		ld a,(current_volume)
		ret





get_dirvol_from_envar

		call kjt_get_envar			;HL = location of envar name
		jr z,cd_evok
		ld a,$23
		or a
		ret
cd_evok		ld e,(hl)				;DE = Cluster, A = Volume
		inc hl
		ld d,(hl)
		inc hl
		ld a,(hl)
		ret
		
;-----------------------------------------------------------------------------------------------


os_mount_with_ex0

; Set A to 1 for silent mode, 0 for text output

		call os_mount_volumes	
			
		ld hl,commands_txt			; set "%ex0" assign envar
		call os_change_dir
		jr nz,no_cmdsdir
		call fs_get_dir_block			; Set envar (assign) for "VOL0:COMMANDS"
		ld (envar_data),de
		ld a,$30
		ld (ex_path_txt+3),a
		ld hl,ex_path_txt
		ld de,envar_data
		call os_set_envar
		call os_root_dir

no_cmdsdir	xor a
		ret

;--------------------------------------------------------------------------------------------


os_mount_volumes
	
		ld (os_quiet_mode),a

		call os_remove_assigns
		
		ld hl,storage_txt
		call os_print_string_cond
		call mount_go
		call page_in_hw_registers
		xor a
tvloop		ld (current_volume),a
		call os_change_volume			;after mount, current volume is set to 0
		ret z					;unless its not valid, then try next vol
		ld a,(current_volume)			;until good volume found
		inc a
		cp max_volumes
		jr nz,tvloop
		ld a,(device_count)
		or a
		jr nz,mfsdevs
		ld hl,none_found_msg
		call os_show_packed_text_cond
mfsdevs		xor a
		ret
	
mount_go	call page_out_hw_registers
		ld hl,volume_mount_list			; wipe current mount list
		ld c,max_volumes*16
clrdl_lp	call os_chl_memclear_short
		call page_in_hw_registers
	
		ld hl,volume_dir_clusters		; wipe directory cluster list
		ld c,max_volumes*2			
		call os_chl_memclear_short	

		ld de,host_device_hardware_info
		ld (dhwn_temp_pointer),de
		
		ld iy,volume_mount_list
		xor a
		ld (volume_count),a
		ld (device_count),a
mnt_loop	ld (current_driver),a			; host driver number
		call locate_driver_base
		ld a,e
		or d
		jr z,nxt_drv				; if driver addr, skip it
		ex de,hl
		ld de,$0e			
		add hl,de				; hl = "get_id" subroutine address for host device
		push iy
		call find_dev				; "get_id" routine must return with ZF set if media present
		pop iy					; size in bc:de and h/w device name location at HL
		call z,got_dev		
nxt_drv		ld a,(current_driver)			; try next driver type 	
		inc a
		cp 4
		jr nz,mnt_loop
		ret
	
find_dev	push hl
		ld hl,sector_buffer			; make sure the OS sector buffer location is set
		ld (sector_buffer_loc),hl	
		pop hl
		jp (hl)


got_dev		push hl				; Host device found, hl = name from get_id
		push de
		push bc
		call os_new_line_cond			; bc:de = total device capacity in sectors
		ld a,"["
		call os_print_char_cond	; "["
		ld a,(current_driver)
		call locate_driver_base
		ex de,hl
		call os_print_string_cond		; show driver name "SD_CARD" etc
		ld a,"]"
		call os_print_char_cond	; "]"
		pop bc
		pop de
		xor a
		ld (vols_on_device_temp),a
	
		call page_out_hw_registers
		ld hl,device_count
		inc (hl)				; Increase the device count
		ld a,(current_driver)
		ld hl,(dhwn_temp_pointer)	
		ld (hl),a
		inc hl
		ld (hl),e				; Fill in total capacity of host device (in sectors) BC:DE
		ld (iy+4),e				; Also put total capacity in first volume entry for devices
		inc hl					; where there is no MBR
		ld (hl),d
		ld (iy+5),d
		inc hl
		ld (hl),c			
		ld (iy+6),c
		inc hl
		ld (hl),b				; capacity MSB
		inc hl
		pop de
		ld b,22					; Fill in hardware name of host device - limit to 22 chars
dnloop		ld a,(de)
		ld (hl),a
		inc hl
		inc de
		djnz dnloop	
		ld b,5		
clrrode		ld (hl),0				; pad device entry with zeroes to 32 bytes
		inc hl
		djnz clrrode
		ld (dhwn_temp_pointer),hl		; update device info pointer ready for next device
			
		xor a					; Now scan this device for partitions
fnxtpart	call page_out_hw_registers
		push iy
		call fs_get_partition_info
		pop iy
		jr c,nxt_dev				; if hardware error or bad format, skip device
		cp $13
		jr z,nxt_dev
		push af
		ld (iy),1				; Found a partition - set volume present
		ld a,(current_driver)
		ld (iy+1),a				; Set volume's Host driver number
		ld a,(partition_temp)	
		ld (iy+7),a				; Set its partition-on-host device number	
		pop af
		or a
		jr z,dev_mbr
		xor a
		ld (iy+8),a				; No MBR on device - fill in partition offset as zero
		ld (iy+9),a				; and go immediately to next device
		ld (iy+10),a				; (capacity data has already been filled in)
		ld (iy+11),a
		call show_vol_info
		call test_max_vol
		ret z					; quit if reached max allowable number of volumes

nxt_dev		ld a,(vols_on_device_temp)		; were any volumes found on the previous device?
		or a
		ret nz		
		call test_quiet_mode
		jr nz,skp_cu
		ld a,10
		ld (cursor_x),a
skp_cu		ld hl,no_vols_msg			; if not say "No volumes"
		call os_show_packed_text_cond
		call os_new_line_cond
		ret
	

dev_mbr		ld de,4
		add hl,de
		ld a,(hl)				;A = type of partition
		or a
		ret z					;end if partition type is zero
		add hl,de
	
		push iy
		ld b,4
sfmbrlp		ld a,(hl)				; fill in offset in sectors from MBR to partition
		ld (iy+8),a
		inc hl
		inc iy
		djnz sfmbrlp
		pop iy
		push iy
		ld b,3	
nsivlp		ld a,(hl)
		ld (iy+4),a				; fill in number of sectors in volume (partition)
		inc hl
		inc iy
		djnz nsivlp
		pop iy
		
		call show_vol_info
		call test_max_vol	
		ret z					; quit if reached max allowable number of volumes
		ld a,(partition_temp)
		inc a
		cp 4					; max number of partitions per device
		jp nz,fnxtpart
		jr nxt_dev
	
	
test_max_vol

		ld de,16
		add iy,de			
		ld hl,volume_count
		inc (hl)
		ld a,(hl)
		cp max_volumes
		ret


show_vol_info
	
		call page_in_hw_registers		;ensure hw regs paged in for print / screen scrolling routines etc
		call test_quiet_mode
		jr nz,skp_cm2
		ld a,9			
		ld (cursor_x),a
skp_cm2		ld a,(volume_count)
		push af
		add a,$30		
		ld (vol_txt+4),a	
		ld hl,vol_txt
		call os_print_string_cond		;show "VOLx:"
		ld hl,vols_on_device_temp
		set 0,(hl)				;note that some volumes were found on this device

		pop af
		push iy
		call os_change_volume			;sets up the data structures and variables for the desired volume
		jr z,vform_ok				;so format type / label can be read
svi_fe		ld hl,format_err_msg		
svi_pem		call os_show_packed_text_cond		;volume not formatted to fat16
		jr skpsvl

vform_ok	call show_vol_label			;show volume label
	
skpsvl		call os_new_line_cond
		pop iy
		ret
	

test_quiet_mode

		push hl
		ld hl,os_quiet_mode
		bit 0,(hl)
		pop hl
		ret


show_vol_label
	
		call fs_get_volume_label
		ret c
		ret nz
		ld a," "
		call os_print_char_cond
		ld a,"("
		call os_print_char_cond
		call os_print_string_cond
		ld a,")"
		call os_print_char_cond
		ret
	
;-----------------------------------------------------------------------------------------------


show_dev_driver_name
	
	
		call locate_driver_base			;set driver number in A before calling	
		ex de,hl
		call os_print_string			;show friendly name (IE: "IDE(M)", "SD Card" etc).
		ld a," "
		call os_print_char
		ret


locate_driver_base

		push hl				;returns driver base address in DE
		rlca					;set driver number in A before calling
		ld e,a
		ld d,0
		ld hl,driver_table
		add hl,de
		ld e,(hl)
		inc hl
		ld d,(hl)			
		pop hl
		ret
		
			
;-------------------------------------------------------------------------------------------------------

os_get_dir_vol	call fs_get_dir_block			;returns in cluster in DE
		ld a,(current_volume)			;returns volume in A
		ret




restore_vol_dir	push af				;set A to volume, set DE to cluster
		call os_update_dir_cluster_safe
		pop af
		call os_change_volume
		ret



os_store_dir	call fs_get_dir_block			;legacy - only for old external prog's kjt calls
		ld (stored_cluster),de
		ret
		

os_restore_dir	

		ld de,(stored_cluster)			;legacy - only for old external progs kjt calls


os_update_dir_cluster_safe

		call fs_update_dir_block
		ld a,d
		or a
		ret z					;if changed to root, dont need to validate dir
		call os_get_current_dir_name		;validate dir cluster by trying to find its name
		ret z
		call fs_goto_root_dir_command		;if this fails, put dir at root
		ld a,$23				;and return error $23, dir not found
		or a
		ret
		



fs_get_dir_cluster_address

		ld hl,volume_dir_clusters		;HL returns location dir cluster pointer
		ld a,(current_volume)	
		rlca
		ld e,a
		ld d,0
		add hl,de
		ret
		
		
	
	
fs_get_total_sectors


		push af
		push hl				;returns total sectors of current volume in C:DE 
		call fs_calc_volume_offset	
		ld hl,volume_mount_list+4
		add hl,de
		ld e,(hl)
		inc hl
		ld d,(hl)
		inc hl
		ld c,(hl)
		pop hl
		pop af
		ret





fs_calc_volume_offset

		ld a,(current_volume)			;selected volume
calc_vol	rlca
		rlca
		rlca
		rlca
		ld e,a
		ld d,0
		ret





dev_to_driver_lookup

		ld hl,device_count			;set A to DEVICE, on return if carry is set: A is driver number
		cp (hl)					;(and hl is device_info base) else: invalid device selected
		ret nc
		rlca			
		rlca
		rlca 
		ld e,a
		ld d,0
		ld hl,host_device_hardware_info
		add hl,de
		ld a,(hl)
		scf
		ret
		




os_change_volume

		ld b,a					; set A to required volume before calling
		cp max_volumes		
		jr nc,fs_ccv2				; report error if above max number of allowable volumes

		ld a,(current_volume)			; note the original volume selection
		push af	
		ld a,b
		ld (current_volume),a			; change to new volume
		call fs_set_driver_for_volume		; set driver appropriately
		
		call fs_check_disk_format		; check that its a valid volume
		jr c,fs_cant_chg_vols
		jr nz,fs_cant_chg_vols
		pop af					; restore stack parity
		xor a					; Exit, All OK
		ret

fs_cant_chg_vols

		pop af		
		ld (current_volume),a			;restore original volume selection
		call fs_set_driver_for_volume		;set driver appropriately
	
fs_ccv2		ld a,$0e				;say "no disk" if required volume selection is not valid	
		or a
		ret
		
	
fs_set_driver_for_volume

		call fs_calc_volume_offset		; update "current_driver" based on volume info table
		ld hl,volume_mount_list+1
		add hl,de
		ld a,(hl)
		ld (current_driver),a
		ret


;--------------------------------------------------------------------------------------------

; Set HL to source. If (HL)="VOL*:" carry is set and A = $00-$09 based on char at *

test_vol_string

		push hl
		pop ix
		ld a,(ix+4)				
		cp ":"					
		jr z,volcolon
		xor a
		ret
		
volcolon	ld de,vol_txt+1				
		ld b,3					
		call os_compare_strings			
		ret nc
		ld a,(ix+3)				
		add a,$d0			;de-asciify the volume mumber (and set carry flag)
		ret
		

;--------------------------------------------------------------------------------------------

os_file_sector_list

;Input DE = cluster, A = sector offset

;Output DE = new cluster, A = new sector number
;       HL = address of LBA0 LSB of sector (internally updates the LBA pointer)

		push af
		ld hl,fs_cluster_size
		cp (hl)
		jr nz,fsl_sc
		ex de,hl
		call get_fat_entry_for_cluster
		ex de,hl
		pop af
		xor a
		push af
fsl_sc		ex de,hl
		call cluster_and_offset_to_lba
		ex de,hl
		pop af
		inc a
fsl_done	ld hl,sector_lba0
		ret
	
	
;--------------------------------------------------------------------------------------------

