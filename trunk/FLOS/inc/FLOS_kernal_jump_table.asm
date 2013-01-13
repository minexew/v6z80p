;-----------------------------------------------------------------------
; Kernal Jump Table - Makes OS routines available to user programs
; via indirect jumps. The table entries always remain in the same
; location and order.
;-----------------------------------------------------------------------

kjt_print_string		jp os_print_string		;start + $13
kjt_clear_screen		jp os_clear_screen		;start + $16
kjt_page_in_video		jp os_page_in_video		;start + $19
kjt_page_out_video		jp os_page_out_video		;start + $1c
kjt_wait_vrt			jp os_wait_vrt			;start + $1f
kjt_keyboard_irq_code		jp keyboard_irq_code		;start + $22
kjt_hex_byte_to_ascii		jp hexbyte_to_ascii		;start + $25
kjt_ascii_to_hex_word		jp ascii_to_hexword		;start + $28
kjt_dont_store_registers	jp os_dont_store_registers	;start + $2b
kjt_get_input_string		jp os_user_input		;start + $2e
kjt_check_volume_format		jp os_check_volume_format	;start + $31
kjt_change_volume		jp os_change_volume		;start + $34
kjt_read_baddr			jp os_read_baddr		;start + $37 (added in v603)
kjt_get_volume_info		jp os_get_volume_info		;start + $3a
kjt_format_device		jp os_format			;start + $3d
kjt_make_dir			jp os_make_dir			;start + $40
kjt_change_dir			jp os_change_dir		;start + $43
kjt_parent_dir			jp os_parent_dir		;start + $46
kjt_root_dir			jp os_root_dir			;start + $49
kjt_delete_dir			jp os_delete_dir		;start + $4c
kjt_open_file			jp os_find_file			;start + $4f
kjt_load_file			jp os_load_file			;start + $52 
kjt_save_file			jp os_save_file			;start + $55
kjt_erase_file			jp os_erase_file		;start + $58
kjt_get_total_sectors		jp fs_get_total_sectors		;start + $5b
kjt_wait_key_press		jp os_wait_key_press		;start + $5e
kjt_get_key			jp os_get_key_press		;start + $61
kjt_force_bank			jp os_forcebank			;start + $64
kjt_get_bank			jp os_getbank			;start + $67
kjt_create_file			jp os_create_file		;start + $6a
kjt_inc_bank			jp os_incbank			;start + $6d
kjt_compare_strings		jp os_compare_strings		;start + $70
kjt_write_bytes_to_file		jp os_write_bytes_to_file	;start + $73
kjt_bchl_memfill		jp os_bchl_memfill		;start + $76
kjt_read_file_data		jp os_force_load		;start + $79
kjt_set_file_pointer		jp os_set_file_pointer		;start + $7c
kjt_set_read_length		jp os_set_load_length		;start + $7f
kjt_serial_receive_header	jp serial_get_header		;start + $82
kjt_serial_receive_file		jp ext_serial_receive_file	;start + $85
kjt_serial_send_file		jp serial_send_file		;start + $88
kjt_enable_mouse		jp os_enable_mouse		;start + $8b
kjt_get_mouse_position		jp os_get_mouse_position	;start + $8e
kjt_get_version			jp os_get_version		;start + $91
kjt_set_cursor_position		jp os_set_cursor_position	;start + $94
kjt_serial_tx_byte		jp send_serial_byte		;start + $97
kjt_serial_rx_byte		jp ext_receive_serial_byte	;start + $9a
kjt_dir_list_first_entry	jp os_goto_first_dir_entry	;start + $9d (added in v537)
kjt_dir_list_get_entry		jp os_get_dir_entry		;start + $a0 ""
kjt_dir_list_next_entry		jp os_goto_next_dir_entry	;start + $a3 ""
kjt_get_cursor_position		jp os_get_cursor_position	;start + $a6 (added in v538)
kjt_read_sector			jp user_read_sector		;start + $a9 (updated in v565)
kjt_write_sector		jp user_write_sector		;start + $ac ""
kjt_set_commander		jp os_set_commander		;start + $af (added in v590)
kjt_plot_char			jp os_plotchar			;start + $b2 (added in v539)
kjt_set_pen			jp os_set_pen			;start + $b5 ("")
kjt_get_flos_bank		jp os_get_flos_bank		;start + $b8 (added in v603)
kjt_draw_cursor			jp draw_cursor			;start + $bb (added in v541)
kjt_get_pen			jp os_get_pen			;start + $be (added in v544)
kjt_scroll_up			jp scroll_up			;start + $c1 ("")
kjt_flos_display		jp os_restore_video_mode	;start + $c4 (added in v547)
kjt_get_dir_name		jp os_get_current_dir_name	;start + $c7 (added in v555)
kjt_get_key_mod_flags		jp os_get_key_mod_flags		;start + $ca (added in v555)
kjt_get_display_size		jp os_get_display_size		;start + $cd (added in v559)
kjt_timer_wait			jp os_timer_wait		;start + $d0 (added in v559)
kjt_get_charmap_addr_xy		jp os_get_charmap_xy		;start + $d3 (added in v559)
kjt_store_dir_position		jp os_store_dir			;start + $d6 (added in v560)
kjt_restore_dir_position	jp os_restore_dir		;start + $d9 (added in v560)
kjt_mount_volumes		jp os_mount_with_ex0		;start + $dc (added in v562)
kjt_get_device_info		jp os_get_device_info		;start + $df (added in v565)
kjt_read_sysram_flat		jp os_readmemflat		;start + $e2 (added in v570)
kjt_write_sysram_flat		jp os_writememflat		;start + $e5 (added in v570)
kjt_get_mouse_disp		jp os_get_mouse_motion		;start + $e8 (added in v571)
kjt_get_dir_cluster		jp fs_get_dir_block		;start + $eb (added in v572)
kjt_set_dir_cluster		jp os_update_dir_cluster_safe	;start + $ee (added in v572)
kjt_rename_file			jp os_rename_file		;start + $f1 (added in v572)
kjt_set_envar			jp os_set_envar			;start + $f4 (added in v575)
kjt_get_envar			jp os_get_envar			;start + $f7 (added in v572)
kjt_delete_envar		jp os_delete_envar		;start + $fa (added in v572)
kjt_file_sector_list		jp os_file_sector_list		;start + $fd (added in v575)
kjt_mouse_irq_code		jp mouse_irq_code		;start + $100 (added in v579)
kjt_get_sector_read_addr	jp get_sector_read_addr		;start + $103 (added in v588)
kjt_get_key_buffer		jp get_kb_buffer_indexes	;start + $106 (added in v591)
kjt_get_colours			jp os_get_ui_colours		;start + $109 (added in v593)
kjt_set_colours			jp os_set_ui_colours		;start + $10c (added in v593)
kjt_patch_font			jp os_patch_font		;start + $10f (added in v595)
kjt_get_fs_vars_location	jp os_fs_vars_loc		;start + $112 (added in v599)
kjt_continue_load		jp os_continue_load		;start + $115 (added in v599)
kjt_set_load_address		jp os_set_load_address		;start + $118 (added in v599)
kjt_write_baddr			jp os_write_baddr		;start + $11b (added in v603)
kjt_parse_path			jp cd_parse_path		;start + $11e (added in v607)
kjt_ascii_to_hex32		jp ascii_to_hex32_scan		;start + $121 (added in v608)

;-----------------------------------------------------------------------------------------
 