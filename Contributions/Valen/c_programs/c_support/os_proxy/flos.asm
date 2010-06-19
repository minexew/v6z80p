; Proxy for calling Asm code (FLOS KERNAL) from C.
; -----------------------


;---Standard header for V6Z80P and OS -------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

include "macro.asm"     ; macros
;--------------------------------------------------------------------------------------


	org $5080       ;
I_DATA equ $            ; area for exchange data (between C and asm code)
        ds  $20
        ; $5080 + $20
        ds $13          ; align data (mimic original FLOS offsets)
include "i__kernal_jump_table.asm"


       i__os_print_string		;start + $13
        PUSH_ALL_REGS
        GET_I_DATA l, h
        call kjt_print_string
        POP_ALL_REGS
        ret


       i__os_clear_screen		;start + $16
        PUSH_ALL_REGS
        call kjt_clear_screen
        POP_ALL_REGS
        ret


       i__os_page_in_video		;start + $19

       i__os_page_out_video	;start + $1c

       i__os_wait_vrt		;start + $1f
        PUSH_ALL_REGS
        call kjt_wait_vrt
        POP_ALL_REGS
        ret

       i__keyboard_irq_code	;start + $22

       i__hexbyte_to_ascii		;start + $25

       i__ascii_to_hexword		;start + $28

       i__os_dont_store_registers	;start + $2b

       i__os_user_input		;start + $2e


       i__os_check_disk_pqfs	;start + $31

       i__os_change_drive		;start + $34

       i__os_check_disk_available	;start + $37
        PUSH_ALL_REGS
        call kjt_check_disk_available
        ld c,0                  ; status = failed
        jr nz,failed9
        ld c,1                  ; status = ok
failed9
        ld ix, I_DATA
                                     ; c = result code, a = file system error code (if call was failed)
        SET_I_DATA c, a
        POP_ALL_REGS
        ret

       i__fs_get_drive		;start + $3a

       i__os_format		;start + $3d

       i__os_make_dir		;start + $40
        PUSH_ALL_REGS
        GET_I_DATA l, h
        call kjt_make_dir
        ld e,0                  ; status = failed
        jr nz,failed10
        ld e,1                  ; status = ok
failed10

        ld ix, I_DATA
                                     ; e = result code, a = file system error code (if call was failed)
                                     ; b = HW err code (if call was failed and a = 0)
        SET_I_DATA e, a, b
        POP_ALL_REGS
        ret


       i__os_change_dir		;start + $43
        PUSH_ALL_REGS
        GET_I_DATA l, h
        call kjt_change_dir
        ld e,0                  ; status = failed
        jr nz,failed12
        ld e,1                  ; status = ok
failed12

        ld ix, I_DATA
                                     ; e = result code, a = file system error code (if call was failed)
                                     ; b = HW err code (if call was failed and a = 0)
        SET_I_DATA e, a, b
        POP_ALL_REGS
        ret


       i__os_parent_dir		;start + $46
        PUSH_ALL_REGS
        call kjt_parent_dir
        ld e,0                  ; status = failed
        jr nz,failed13
        ld e,1                  ; status = ok
failed13

        ld ix, I_DATA
                                     ; e = result code, a = file system error code (if call was failed)
                                     ; b = HW err code (if call was failed and a = 0)
        SET_I_DATA e, a, b
        POP_ALL_REGS
        ret


       i__os_root_dir		;start + $49
        PUSH_ALL_REGS
        call kjt_root_dir
        ld e,0                  ; status = failed
        jr nz,failed14
        ld e,1                  ; status = ok
failed14

        ld ix, I_DATA
                                     ; e = result code, a = file system error code (if call was failed)
                                     ; b = HW err code (if call was failed and a = 0)
        SET_I_DATA e, a, b
        POP_ALL_REGS
        ret


       i__os_delete_dir		;start + $4c
        PUSH_ALL_REGS
        GET_I_DATA l, h
        call kjt_delete_dir
        ld e,0                  ; status = failed
        jr nz,failed11
        ld e,1                  ; status = ok
failed11

        ld ix, I_DATA
                                     ; e = result code, a = file system error code (if call was failed)
                                     ; b = HW err code (if call was failed and a = 0)
        SET_I_DATA e, a, b
        POP_ALL_REGS
        ret





       i__os_find_file		;start + $4f

        PUSH_ALL_REGS
        GET_I_DATA l, h
        call kjt_find_file
        ld e,0                  ; status = failed
        jr nz,failed1
        ld e,1                  ; status = ok
failed1

        push ix
        push iy
        ld ix, I_DATA
                                     ; e = result code, a = file system error code (if call was failed)
                                     ; b = HW err code (if call was failed and a = 0)

        SET_I_DATA e, a, b           ; b = bank (if call was ok)
; HL = address file originally saved from
        SET_I_DATA l, h
; IX:IY = length of file
        pop hl
        pop bc                  ; bc:hl
        SET_I_DATA l, h, c, b


        POP_ALL_REGS
        ret


       i__os_load_file		;start + $52

       i__os_save_file		;start + $55

       i__os_erase_file		;start + $58
        PUSH_ALL_REGS
; HL = address of zero terminated filename.
        GET_I_DATA l, h
        call kjt_erase_file
        ld c,0                  ; status = failed
        jr nz,failed5
        ld c,1                  ; status = ok
failed5
        ld ix, I_DATA
                                     ; c = result code, a = file system error code (if call was failed)
                                     ; b = HW err code (if a = 0)
        SET_I_DATA c, a, b
        POP_ALL_REGS
        ret


       i__fs_get_total_sectors	;start + $5b
        PUSH_ALL_REGS
        call kjt_get_total_sectors
        xor a
        ld ix, I_DATA
        SET_I_DATA e, d, c, a                        ; c:de = total blocks
        POP_ALL_REGS
        ret

       i__os_wait_key_press	;start + $5e
        PUSH_ALL_REGS
        call kjt_wait_key_press

        ld ix, I_DATA
                                     ; a = scan code,  b = ASCII code
        SET_I_DATA a, b
        POP_ALL_REGS
        ret


       i__os_get_key_press		;start + $61
        PUSH_ALL_REGS
        call kjt_get_key

        ld ix, I_DATA
                                     ; a = scan code,  b = ASCII code
        SET_I_DATA a, b
        POP_ALL_REGS
        ret


       i__os_forcebank		;start + $64

       i__os_getbank		;start + $67

       i__os_create_file		;start + $6a
        PUSH_ALL_REGS
; HL = address of zero terminated filename.
; IX = address that file should load to when no overrides are specified (irrelevent on FAT16)
;  B = bank part of reload address (irrelevent on FAT16)
        GET_I_DATA l, h, e, d, b
        push de
        pop ix
        call kjt_create_file
        ld c,0                  ; status = failed
        jr nz,failed4
        ld c,1                  ; status = ok
failed4
        ld ix, I_DATA
                                     ; c = result code, a = file system error code (if call was failed)
                                     ; b = HW err code (if a = 0)
        SET_I_DATA c, a, b
        POP_ALL_REGS
        ret



       i__os_incbank		;start + $6d

       i__os_compare_strings	;start + $70

       i__os_write_bytes_to_file	;start + $73
        PUSH_ALL_REGS

        ld ix, I_DATA
        GET_I_DATA_2 l, h, e, d           ; hl = filename, de = address
        push de                         ; push address
        GET_I_DATA_2 b, e, d, c, a        ; b = bank, c:de = len, a = unknow (not used)        
        pop ix                          ; pop address, ix = address

        call kjt_write_bytes_to_file
        ld c,0                  ; status = failed
        jr nz,failed30
        ld c,1                  ; status = ok
failed30

        ld ix, I_DATA
                                     ; c = result code, a = file system error code (if call was failed)
                                     ; b = HW err code (if a = 0)
        SET_I_DATA c, a, b
        POP_ALL_REGS
        ret


       i__os_bchl_memfill		;start + $76

       i__os_force_load		;start + $79
        PUSH_ALL_REGS
        GET_I_DATA l, h, b
        call kjt_force_load
        ld c,0                  ; status = failed
        jr nz,failed2
        ld c,1                  ; status = ok
failed2

        ld ix, I_DATA
                                     ; c = result code, a = file system error code (if call was failed)
                                     ; b = HW err code (if a = 0)
        SET_I_DATA c, a, b
        POP_ALL_REGS
        ret


       i__os_set_file_pointer	;start + $7c
        PUSH_ALL_REGS
        GET_I_DATA l, h, e, d
        push hl
        push de
; IX:IY = file pointer
        pop ix
        pop iy
        call kjt_set_file_pointer
        POP_ALL_REGS
        ret


       i__os_set_load_length	;start + $7f
        PUSH_ALL_REGS
        GET_I_DATA l, h, e, d
        push hl
        push de
; IX:IY = load len
        pop ix
        pop iy
        call kjt_set_load_length
        POP_ALL_REGS
        ret


       i__os_serial_get_header	;start + $82

       i__os_serial_receive_file	;start + $85

       i__os_serial_send_file	;start + $88


       i__os_init_mouse		;start + $8b

       i__os_get_mouse_position	;start + $8e

       i__os_get_version		;start + $91
        PUSH_ALL_REGS
        call kjt_get_version

        ld ix, I_DATA
                                     ; HL = OS version word,  DE = Hardware version word
        SET_I_DATA l, h, e, d
        POP_ALL_REGS
        ret

       i__os_set_cursor_position	;start + $94
;;ret
        PUSH_ALL_REGS
        GET_I_DATA b, c
; b = X, c = Y
        call kjt_set_cursor_position
        ld c,0                  ; status = failed
        jr nz,failed16
        ld c,1                  ; status = ok
failed16

        ld ix, I_DATA
                                     ; c = result code
        SET_I_DATA c
        POP_ALL_REGS
        ret

       i__os_serial_tx		;start + $97

       i__os_serial_rx		;start + $9a

        i__os_dir_list_first_entry        ;start + $9d
        PUSH_ALL_REGS
        call kjt_dir_list_first_entry
        POP_ALL_REGS
        ret

        i__os_dir_list_get_entry          ;start + $a0
        PUSH_ALL_REGS
        call kjt_dir_list_get_entry
        ld e,0                  ; status = failed (hardware error)
        jr nz,failed15
        ld e,1                  ; status = ok
failed15

        push ix
        push iy
        ld ix, I_DATA
                                     ; e = result code,
                                     ; hl = Location of null terminated filename string
                                     ; b = File flag (1 = directory, 0 = file)
                                     ; a = Error code (0 = all OK. $24 = Reached end of directory.)

        SET_I_DATA e, l, h, b, a
                                     ; IX:IY = Length of file (if applicable)
        pop hl
        pop bc                       ; bc:hl
        SET_I_DATA l, h, c, b

        POP_ALL_REGS
        ret

        i__os_dir_list_next_entry         ;start + $a3
        PUSH_ALL_REGS
        call kjt_dir_list_next_entry

        ld ix, I_DATA
                                     ; a = Error code (0 = all OK. $24 = Reached end of directory.)
        SET_I_DATA a
        POP_ALL_REGS
        ret


       i__os_get_cursor_position	;os_start + $a6
       i__os_read_sector		;os_start + $a9
       i__os_write_sector		;os_start + $ac
       i__os_set_sector_lba		;os_start + $af

       i__os_plot_char		;os_start + $b2
       i__os_set_pen		;os_start + $b5
        PUSH_ALL_REGS
        GET_I_DATA a
        call kjt_set_pen
        POP_ALL_REGS
        ret


       i__os_background_colours	;os_start + $b8
       i__os_draw_cursor	;os_start + $bb

       i__os_kjt_get_pen		   ;os_start+0xbe
       i__os_kjt_scroll_up		   ;os_start+0xc1
       i__os_kjt_flos_display		   ;os_start+0xc4
        PUSH_ALL_REGS
        call kjt_flos_display
        POP_ALL_REGS
        ret

       i__os_kjt_get_dir_name		   ;os_start+0xc7
        PUSH_ALL_REGS
        call kjt_get_dir_name
        ld e,0                  ; status = failed
        jr nz,failed20
        ld e,1                  ; status = ok
failed20

        ld ix, I_DATA
                                     ; e = result code,
                                     ; hl = Address of null terminated dirname string
        SET_I_DATA e, l, h

        POP_ALL_REGS
        ret

        i__os_kjt_get_key_mod_flags	;equ os_start + $ca

        i__os_kjt_get_display_size	;equ os_start + $cd   ; added in FLOS v559
        i__os_kjt_timer_wait		;equ os_start + $d0	 ; added in FLOS v559
        i__os_kjt_get_charmap_addr_xy	;equ os_start + $d3	 ; added in FLOS v559

        i__os_kjt_store_dir_position	;equ os_start + $d6	; added in FLOS v560
        PUSH_ALL_REGS
        call kjt_store_dir_position
        POP_ALL_REGS
        ret

        i__os_kjt_restore_dir_position	;equ os_start + $d9	; added in FLOS v560
        PUSH_ALL_REGS
        call kjt_restore_dir_position
        POP_ALL_REGS
        ret




