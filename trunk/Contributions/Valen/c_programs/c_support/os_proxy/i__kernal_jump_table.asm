; Machine generated. Dont edit. Source file: /home/valen/_1/v6z80p_SVN/FLOS/FLOSv579.asm
; FLOS proxy jump table (must be identical to Kernel jump table)
    jp proxy__print_string		  ;   start + $13
    jp proxy__clear_screen		  ;   start + $16
    jp proxy__page_in_video		  ;   start + $19
    jp proxy__page_out_video		  ;   start + $1c
    jp proxy__wait_vrt		  ;   start + $1f
    jp proxy__keyboard_irq_code	  ;   start + $22
    jp proxy__hex_byte_to_ascii	  ;   start + $25
    jp proxy__ascii_to_hex_word	  ;   start + $28
    jp proxy__dont_store_registers	  ;   start + $2b
    jp proxy__get_input_string	  ;   start + $2e
    jp proxy__check_volume_format	  ;   start + $31
    jp proxy__change_volume		  ;   start + $34
    jp proxy__check_disk_available	  ;   obsoleted in v565
    jp proxy__get_volume_info		  ;   start + $3a
    jp proxy__format_device		  ;   start + $3d
    jp proxy__make_dir		  ;   start + $40
    jp proxy__change_dir		  ;   start + $43
    jp proxy__parent_dir		  ;   start + $46
    jp proxy__root_dir		  ;   start + $49
    jp proxy__delete_dir		  ;   start + $4c
    jp proxy__find_file		  ;   start + $4f
    jp proxy__load_file		  ;   start + $52
    jp proxy__save_file		  ;   start + $55
    jp proxy__erase_file		  ;   start + $58
    jp proxy__get_total_sectors	  ;   start + $5b
    jp proxy__wait_key_press		  ;   start + $5e
    jp proxy__get_key		  ;   start + $61
    jp proxy__forcebank		  ;   start + $64
    jp proxy__getbank		  ;   start + $67
    jp proxy__create_file		  ;   start + $6a
    jp proxy__incbank		  ;   start + $6d
    jp proxy__compare_strings		  ;   start + $70
    jp proxy__write_bytes_to_file	  ;   start + $73
    jp proxy__bchl_memfill		  ;   start + $76
    jp proxy__force_load		  ;   start + $79
    jp proxy__set_file_pointer	  ;   start + $7c
    jp proxy__set_load_length		  ;   start + $7f
    jp proxy__serial_receive_header	  ;   start + $82
    jp proxy__serial_receive_file	  ;   start + $85
    jp proxy__serial_send_file	  ;   start + $88
    jp proxy__enable_mouse		  ;   start + $8b
    jp proxy__get_mouse_position	  ;   start + $8e
    jp proxy__get_version		  ;   start + $91
    jp proxy__set_cursor_position	  ;   start + $94
    jp proxy__serial_tx_byte		  ;   start + $97
    jp proxy__serial_rx_byte		  ;   start + $9a
    jp proxy__dir_list_first_entry	  ;   start + $9d (added in v537)
    jp proxy__dir_list_get_entry	  ;   start + $a0 ""
    jp proxy__dir_list_next_entry	  ;   start + $a3 ""
    jp proxy__get_cursor_position	  ;   start + $a6 (added in v538)
    jp proxy__read_sector		  ;   start + $a9 (updated in v565)
    jp proxy__write_sector		  ;   start + $ac ""
    jp proxy__not_used_one		  ;   start + $af obsoleted in V565
    jp proxy__plot_char		  ;   start + $b2 (added in v539)
    jp proxy__set_pen		  ;   start + $b5 ("")
    jp proxy__background_colours	  ;   start + $b8 ("")
    jp proxy__draw_cursor		  ;   start + $bb (added in v541)
    jp proxy__get_pen		  ;   start + $be (added in v544)
    jp proxy__scroll_up		  ;   start + $c1 ("")
    jp proxy__flos_display		  ;   start + $c4 (added in v547)
    jp proxy__get_dir_name		  ;   start + $c7 (added in v555)
    jp proxy__get_key_mod_flags	  ;   start + $ca (added in v555)
    jp proxy__get_display_size	  ;   start + $cd (added in v559)
    jp proxy__timer_wait		  ;   start + $d0 (added in v559)
    jp proxy__get_charmap_addr_xy	  ;   start + $d3 (added in v559)
    jp proxy__store_dir_position	  ;   start + $d6 (added in v560)
    jp proxy__restore_dir_position	  ;   start + $d9 (added in v560)
    jp proxy__mount_volumes		  ;   start + $dc (added in v562)
    jp proxy__get_device_info		  ;   start + $df (added in v565)
    jp proxy__read_sysram_flat	  ;   start + $e2 (added in v570)
    jp proxy__write_sysram_flat	  ;   start + $e5 (added in v570)
    jp proxy__get_mouse_disp		  ;   start + $e8 (added in v571)
    jp proxy__get_dir_cluster		  ;   start + $eb (added in v572)
    jp proxy__set_dir_cluster		  ;   start + $ee (added in v572)
    jp proxy__rename_file		  ;   start + $f1 (added in v572)
    jp proxy__set_envar		  ;   start + $f4 (added in v575)
    jp proxy__get_envar		  ;   start + $f7 (added in v572)
    jp proxy__delete_envar		  ;   start + $fa (added in v572)
    jp proxy__file_sector_list	  ;   start + $fd (added in v575)
    jp proxy__mouse_irq_code		  ;   start + $100 (added in v579)
