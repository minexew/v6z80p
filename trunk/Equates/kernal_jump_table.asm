;-------------------------------
;Kernal jump table for FLOS v588
;-------------------------------

os_start equ $1000

kjt_print_string		equ os_start + $13
kjt_clear_screen		equ os_start + $16
kjt_page_in_video		equ os_start + $19
kjt_page_out_video		equ os_start + $1c
kjt_wait_vrt		equ os_start + $1f
kjt_keyboard_irq_code	equ os_start + $22
kjt_hex_byte_to_ascii	equ os_start + $25
kjt_ascii_to_hex_word	equ os_start + $28
kjt_dont_store_registers	equ os_start + $2b
kjt_get_input_string	equ os_start + $2e
kjt_check_volume_format	equ os_start + $31
kjt_change_volume		equ os_start + $34
kjt_unnecessary		equ os_start + $37	; no longer used (same as kjt_check_volume_format)
kjt_get_volume_info		equ os_start + $3a
kjt_format_device		equ os_start + $3d
kjt_make_dir		equ os_start + $40
kjt_change_dir		equ os_start + $43
kjt_parent_dir		equ os_start + $46
kjt_root_dir		equ os_start + $49
kjt_delete_dir		equ os_start + $4c
kjt_find_file		equ os_start + $4f
kjt_open_file		equ os_start + $4f	; alternative name for above
kjt_load_file		equ os_start + $52
kjt_save_file		equ os_start + $55
kjt_erase_file		equ os_start + $58
kjt_get_total_sectors	equ os_start + $5b
kjt_wait_key_press		equ os_start + $5e
kjt_get_key		equ os_start + $61
kjt_forcebank		equ os_start + $64
kjt_force_bank		equ os_start + $64	; alternative name for above
kjt_getbank		equ os_start + $67
kjt_get_bank		equ os_start + $67	; alternative name for above
kjt_create_file		equ os_start + $6a
kjt_incbank		equ os_start + $6d
kjt_inc_bank		equ os_start + $6d	; alternative name for above
kjt_compare_strings		equ os_start + $70
kjt_write_bytes_to_file	equ os_start + $73
kjt_write_to_file		equ os_start + $73	; alternative name for above
kjt_bchl_memfill		equ os_start + $76
kjt_force_load		equ os_start + $79
kjt_read_from_file		equ os_start + $79	; alternative name for above
kjt_set_file_pointer	equ os_start + $7c
kjt_set_load_length		equ os_start + $7f
kjt_set_read_length		equ os_start + $7f	; alternative name for above
kjt_serial_receive_header	equ os_start + $82
kjt_serial_receive_file	equ os_start + $85
kjt_serial_send_file	equ os_start + $88
kjt_enable_mouse		equ os_start + $8b	; changed from "kjt_enable_pointer" in FLOS v571
kjt_get_mouse_position	equ os_start + $8e
kjt_get_version		equ os_start + $91
kjt_set_cursor_position	equ os_start + $94
kjt_serial_tx_byte		equ os_start + $97
kjt_serial_rx_byte		equ os_start + $9a
kjt_dir_list_first_entry	equ os_start + $9d
kjt_dir_list_get_entry	equ os_start + $a0
kjt_dir_list_next_entry	equ os_start + $a3
kjt_get_cursor_position	equ os_start + $a6
kjt_read_sector		equ os_start + $a9
kjt_write_sector		equ os_start + $ac
kjt_set_commander		equ os_start + $af   ; added in v590
kjt_plot_char		equ os_start + $b2 
kjt_set_pen		equ os_start + $b5 
kjt_background_colours	equ os_start + $b8
kjt_draw_cursor		equ os_start + $bb
kjt_get_pen		equ os_start + $be
kjt_scroll_up		equ os_start + $c1
kjt_flos_display		equ os_start + $c4
kjt_get_dir_name		equ os_start + $c7
kjt_get_key_mod_flags	equ os_start + $ca
kjt_get_display_size	equ os_start + $cd   ; added in v559
kjt_timer_wait		equ os_start + $d0	 ; added in v559
kjt_get_charmap_addr_xy	equ os_start + $d3	 ; added in v559
kjt_store_dir_position	equ os_start + $d6	 ; added in v560
kjt_restore_dir_position	equ os_start + $d9	 ; added in v560
kjt_mount_volumes		equ os_start + $dc	 ; added in v562
kjt_get_device_info		equ os_start + $df   ; added in v565
kjt_read_sysram_flat	equ os_start + $e2 	 ; added in v570
kjt_write_sysram_flat	equ os_start + $e5 	 ; added in v570
kjt_get_mouse_motion	equ os_start + $e8	 ; added in v571
kjt_get_dir_cluster		equ os_start + $eb 	 ; added in v572
kjt_set_dir_cluster		equ os_start + $ee   ; added in v572
kjt_rename_file		equ os_start + $f1   ; added in v572
kjt_set_envar		equ os_start + $f4   ; added in v575
kjt_get_envar		equ os_start + $f7   ; added in v572
kjt_delete_envar		equ os_start + $fa   ; added in v572
kjt_file_sector_list	equ os_start + $fd   ; added in v575
kjt_mouse_irq_code		equ os_start + $100  ; added in v579
kjt_get_sector_read_addr	equ os_start + $103	 ; added in v588
