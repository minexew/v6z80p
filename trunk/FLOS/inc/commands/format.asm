;-----------------------------------------------------------------------
;"format" - format disk command. V6.06
;
; This internal format routine is limited to formatting entire disks
; No partition data is allowed.
;-----------------------------------------------------------------------


os_cmd_format

		ld a,(hl)				;check args exist
		or a
		jp z,os_no_args_error
		
fgotargs	call kjt_check_volume_format		;if volume is OK (disk not swapped) do not remount (as this will lose ENVARS unnecessarily)
		jr z,no_remnt
		push hl
		ld a,1					;quiet mode on
		call os_mount_volumes			;refresh mount list
		pop hl
		
no_remnt	ld de,fs_sought_filename
		call fs_clear_filename			
		push hl				;use 2nd parameter as label if supplied
		call os_next_arg
		jr nz,fgotlab
		ld hl,default_label
fgotlab		ld b,11
		call os_copy_ascii_run
		pop hl
		
		ld a,(device_count)			;try to find a device with the name given after "FORMAT"
		or a
		jr z,fno_dev
		ld b,a
		ld c,0					;dev number
		ld ix,host_device_hardware_info
fdev_lp		ld a,(ix)				;a = driver number for this dev
		call locate_driver_base			;DE = location of ascii name of driver (EG: SD_CARD)
		push bc
		ld b,7
		call os_compare_strings
		pop bc
		jr c,format_dev
		ld de,32				;try next device name
		add ix,de
		inc c
		djnz fdev_lp

fno_dev		ld a,$22				;device not present
		or a
		ret
		

	
;----- FORMAT A DEVICE (USE ENTIRE CAPACITY (TRUNCATE AT 2GB) NO MBR) -----


format_dev
	
		call os_new_line
		ld hl,form_dev_warn1
		call os_show_packed_text

		ld a,c					;a = device number requiring format
		add a,$30
		ld (dev_txt+3),a
		ld hl,dev_txt	
		call os_print_string			;show "DEVx" 
		
		ld a,c
		call dev_to_driver_lookup		;get driver number
		ld (current_driver),a
		push ix
		call show_dev_driver_name		;show device driver name ("SD card" etc)
		pop hl
		ld de,5
		add hl,de
		call os_print_str_new_line		;show hardware's name originally from get_id 
		call os_new_line
		ld hl,form_dev_warn2
		call show_packed_text_and_cr
		call confirm_yes
		jr nc,ab_form
		
		ld hl,formatting_txt			;say "formatting..."
		call os_print_string
		
		call fs_format_device_command
		jr c,form_err
		or a
		jr nz,form_err

		ld hl,ok_msg				;say "OK"
		call show_packed_text_and_cr
		
f_end		call os_cmd_remount			;remount drives and show list
		ret

form_err
		ld hl,disk_err_msg
		call show_packed_text_and_cr
		jr f_end
	
	
;---------------------------------------------------------------------------------------------
	
	
ab_form		call os_new_line
		ld a,$2d				;ERROR $2d - aborted	
		or a
		ret
	
confirm_yes

		ld a,3
		call os_user_input
		ld b,3
		ld de,yes_txt+1
		call os_compare_strings
		ret


;------------------------------------------------------------------------------------------------

