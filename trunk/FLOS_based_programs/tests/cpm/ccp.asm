; ccp test v1


bdos	equ	0005h
		
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

	org	0100h	;cpm program
start	ld	de,opening0
	ld	c,bd_print_string_code
	call	bdos
	ld	de,opening1
	ld	c,bd_print_string_code
	call	bdos
	ret
opening1:	db	"Dit is de eerste tekst onder CP-M primitief",13,10,"$"
opening0:	db	"Rudimentaire CCP",13,10,"$"
	
	end