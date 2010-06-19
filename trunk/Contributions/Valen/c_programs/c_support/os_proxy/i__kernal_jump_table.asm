;-----------------------------------------------------------------------
; C --> Kernal 
; Interface  Jump Table - Makes OS routines available to C programs
; via indirect jumps. The table entries always remain in the same
; location and order.
;-----------------------------------------------------------------------


    jp i__os_print_string		;start + $13
   
    jp i__os_clear_screen		;start + $16
   
    jp i__os_page_in_video		;start + $19
   
    jp i__os_page_out_video	;start + $1c
   
    jp i__os_wait_vrt		;start + $1f
   
    jp i__keyboard_irq_code	;start + $22
   
    jp i__hexbyte_to_ascii		;start + $25
   
    jp i__ascii_to_hexword		;start + $28
   
    jp i__os_dont_store_registers	;start + $2b
   
    jp i__os_user_input		;start + $2e
   

    jp i__os_check_disk_pqfs	;start + $31
   
    jp i__os_change_drive		;start + $34
   
    jp i__os_check_disk_available	;start + $37
   
    jp i__fs_get_drive		;start + $3a
   
    jp i__os_format		;start + $3d
   
    jp i__os_make_dir		;start + $40
   
    jp i__os_change_dir		;start + $43
   
    jp i__os_parent_dir		;start + $46
   
    jp i__os_root_dir		;start + $49
   
    jp i__os_delete_dir		;start + $4c
   

    jp i__os_find_file		;start + $4f
   
    jp i__os_load_file		;start + $52
   
    jp i__os_save_file		;start + $55
   
    jp i__os_erase_file		;start + $58
   
    jp i__fs_get_total_sectors	;start + $5b
   
    jp i__os_wait_key_press	;start + $5e
   
    jp i__os_get_key_press		;start + $61
   
    jp i__os_forcebank		;start + $64
   
    jp i__os_getbank		;start + $67
   
    jp i__os_create_file		;start + $6a
   

    jp i__os_incbank		;start + $6d
   
    jp i__os_compare_strings	;start + $70
   
    jp i__os_write_bytes_to_file	;start + $73
   
    jp i__os_bchl_memfill		;start + $76
   
    jp i__os_force_load		;start + $79
   
    jp i__os_set_file_pointer	;start + $7c
   
    jp i__os_set_load_length	;start + $7f
   
    jp i__os_serial_get_header	;start + $82
   
    jp i__os_serial_receive_file	;start + $85
   
    jp i__os_serial_send_file	;start + $88
   

    jp i__os_init_mouse		;start + $8b
   
    jp i__os_get_mouse_position	;start + $8e
   
    jp i__os_get_version		;start + $91
   
    jp i__os_set_cursor_position	;start + $94
   
    jp i__os_serial_tx		;start + $97
   
    jp i__os_serial_rx		;start + $9a

    jp i__os_dir_list_first_entry        ;start + $9d

    jp i__os_dir_list_get_entry          ;start + $a0

    jp i__os_dir_list_next_entry         ;start + $a3

    jp i__os_get_cursor_position	;os_start + $a6
    jp i__os_read_sector		;os_start + $a9
    jp i__os_write_sector		;os_start + $ac
    jp i__os_set_sector_lba		;os_start + $af

    jp i__os_plot_char		;os_start + $b2 
    jp i__os_set_pen		;os_start + $b5 
    jp i__os_background_colours	;os_start + $b8
    jp i__os_draw_cursor	;os_start + $bb

    jp i__os_kjt_get_pen		   ;os_start+0xbe
    jp i__os_kjt_scroll_up		   ;os_start+0xc1
    jp i__os_kjt_flos_display		   ;os_start+0xc4
    jp i__os_kjt_get_dir_name		   ;os_start+0xc7
    jp i__os_kjt_get_key_mod_flags	   ;os_start + $ca


    jp i__os_kjt_get_display_size	;equ os_start + $cd   ; added in FLOS v559
    jp i__os_kjt_timer_wait		;equ os_start + $d0	 ; added in FLOS v559
    jp i__os_kjt_get_charmap_addr_xy	;equ os_start + $d3	 ; added in FLOS v559

    jp i__os_kjt_store_dir_position	;equ os_start + $d6	; added in FLOS v560
    jp i__os_kjt_restore_dir_position	;equ os_start + $d9	; added in FLOS v560
