; Proxy for calling Asm code (FLOS KERNAL) from C.
; This proxy is portable across C compilers  (proxy don't depend on any specific C compiler)
; Coded in Pasmo.
; -----------------------
; TODO: this file include all proxies and compiled binary is about 3KB. 
; So, need think how to compile only proxies, used in user project. This will save some memory.


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


        proxy__print_string    ;start + $13
        PUSH_ALL_REGS
        GET_I_DATA l, h
        call kjt_print_string
        POP_ALL_REGS
        ret


        proxy__clear_screen    ;start + $16
        PUSH_ALL_REGS
        call kjt_clear_screen
        POP_ALL_REGS
        ret


        proxy__page_in_video    ;start + $19

        proxy__page_out_video    ;start + $1c

        proxy__wait_vrt    ;start + $1f
        PUSH_ALL_REGS
        call kjt_wait_vrt
        POP_ALL_REGS
        ret

        proxy__keyboard_irq_code    ;start + $22

        proxy__hex_byte_to_ascii     ;start + $25

        proxy__ascii_to_hex_word     ;start + $28

        proxy__dont_store_registers    ;start + $2b

        proxy__get_input_string    ;start + $2e


        proxy__check_volume_format    ;start + $31

        proxy__change_volume    ;start + $34
        PUSH_ALL_REGS
; A = volume to select
        GET_I_DATA a
        call kjt_change_volume
        ld e,0                  ; status = failed
        jr nz,failed22
        ld e,1                  ; status = ok
failed22

        ld ix, I_DATA
                                     ; e = result code
        SET_I_DATA e
        POP_ALL_REGS
        ret
        

        proxy__check_disk_available    ;start + $37 ; no longer used
        PUSH_ALL_REGS
        ld ix, I_DATA
                                     
        xor a                        ; a = result code (always fail this call)     
        SET_I_DATA a
        POP_ALL_REGS
        ret


        proxy__get_volume_info      ;start + $3a
        PUSH_ALL_REGS
        call kjt_get_volume_info    ; function don't return result code 
        ld ix, I_DATA
; HL = address of volume mount list
; B = Number of volumes mounted
; A = currently Selected volume
        SET_I_DATA l, h, b, a
        POP_ALL_REGS
        ret
        
        proxy__format_device               ;start + $3d
        proxy__make_dir             ;start + $40
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


        proxy__change_dir    ;start + $43
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


        proxy__parent_dir    ;start + $46
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


        proxy__root_dir    ;start + $49
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


        proxy__delete_dir    ;start + $4c
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





        proxy__open_file    ;start + $4f

        PUSH_ALL_REGS
        GET_I_DATA l, h
        call kjt_open_file
        push de
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
; DE = first cluster that the file uses
        pop de
        SET_I_DATA e, d


        POP_ALL_REGS
        ret


        proxy__load_file    ;start + $52

        proxy__save_file    ;start + $55

        proxy__erase_file    ;start + $58
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


        proxy__get_total_sectors    ;start + $5b
        PUSH_ALL_REGS
        call kjt_get_total_sectors
        xor a
        ld ix, I_DATA
        SET_I_DATA e, d, c, a                        ; c:de = total blocks
        POP_ALL_REGS
        ret

        proxy__wait_key_press    ;start + $5e
        PUSH_ALL_REGS
        call kjt_wait_key_press

        ld ix, I_DATA
                                     ; a = scan code,  b = ASCII code
        SET_I_DATA a, b
        POP_ALL_REGS
        ret


        proxy__get_key    ;start + $61
        PUSH_ALL_REGS
        call kjt_get_key

        ld ix, I_DATA
                                     ; a = scan code,  b = ASCII code
        SET_I_DATA a, b
        POP_ALL_REGS
        ret


        proxy__force_bank    ;start + $64

        proxy__get_bank    ;start + $67

        proxy__create_file    ;start + $6a
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



        proxy__inc_bank    ;start + $6d

        proxy__compare_strings    ;start + $70

        proxy__write_bytes_to_file    ;start + $73
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


        proxy__bchl_memfill    ;start + $76

        proxy__read_file_data    ;start + $79
        PUSH_ALL_REGS
        GET_I_DATA l, h, b
        call kjt_force_load	; read_file_data and force_load are equ
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


        proxy__set_file_pointer    ;start + $7c
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


        proxy__set_read_length    ;start + $7f
        PUSH_ALL_REGS
        GET_I_DATA l, h, e, d
        push hl
        push de
; IX:IY = load len
        pop ix
        pop iy
        call kjt_set_read_length
        POP_ALL_REGS
        ret


        proxy__serial_receive_header    ;start + $82

        proxy__serial_receive_file    ;start + $85

        proxy__serial_send_file    ;start + $88


        proxy__enable_mouse    ;start + $8b

        proxy__get_mouse_position    ;start + $8e
        PUSH_ALL_REGS
        call kjt_get_mouse_position
                                ; Zero Flag: if not set, the mouse driver was not enabled
        ld c,0                  ; status = failed
        jr nz,failed26
        ld c,1                  ; status = ok
failed26


        ld ix, I_DATA
                                     ; HL = x,  DE = y, A = buttons
        SET_I_DATA c, l, h, e, d, a
        POP_ALL_REGS
        ret


        proxy__get_version    ;start + $91
        PUSH_ALL_REGS
        call kjt_get_version

        ld ix, I_DATA
                                     ; HL = OS version word,  DE = Hardware version word
        SET_I_DATA l, h, e, d
        POP_ALL_REGS
        ret

        proxy__set_cursor_position    ;start + $94
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

        proxy__serial_tx_byte    ;start + $97
        PUSH_ALL_REGS
        GET_I_DATA a
        call kjt_serial_tx_byte
        POP_ALL_REGS
        ret

        proxy__serial_rx_byte    ;start + $9a

        proxy__dir_list_first_entry         ;start + $9d
        PUSH_ALL_REGS
        call kjt_dir_list_first_entry
        POP_ALL_REGS
        ret

         proxy__dir_list_get_entry            ;start + $a0
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

        proxy__dir_list_next_entry           ;start + $a3
        PUSH_ALL_REGS
        call kjt_dir_list_next_entry

        ld ix, I_DATA
                                     ; a = Error code (0 = all OK. $24 = Reached end of directory.)
        SET_I_DATA a
        POP_ALL_REGS
        ret


        proxy__get_cursor_position    ;os_start + $a6
        proxy__read_sector    ;os_start + $a9
        proxy__write_sector    ;os_start + $ac
        
        proxy__set_commander    ;os_start + $af
        PUSH_ALL_REGS
        GET_I_DATA l, h
        call kjt_set_commander
        POP_ALL_REGS
        ret

        proxy__plot_char    ;os_start + $b2
        proxy__set_pen    ;os_start + $b5
        PUSH_ALL_REGS
        GET_I_DATA a
        call kjt_set_pen
        POP_ALL_REGS
        ret


        proxy__background_colours    ;os_start + $b8
        proxy__draw_cursor    ;os_start + $bb

        proxy__get_pen       ;os_start+0xbe

        proxy__scroll_up       ;os_start+0xc1
        PUSH_ALL_REGS
        call kjt_scroll_up
        POP_ALL_REGS
        ret

        proxy__flos_display       ;os_start+0xc4
        PUSH_ALL_REGS
        call kjt_flos_display
        POP_ALL_REGS
        ret

        proxy__get_dir_name       ;os_start+0xc7
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

        proxy__get_key_mod_flags    ;equ os_start + $ca

        proxy__get_display_size    ;equ os_start + $cd   ; added in FLOS v559
        proxy__timer_wait    ;equ os_start + $d0	 ; added in FLOS v559
        proxy__get_charmap_addr_xy ;equ os_start + $d3     ; added in FLOS v559

        proxy__store_dir_position  ;equ os_start + $d6    ; added in FLOS v560
        PUSH_ALL_REGS
        call kjt_store_dir_position
        POP_ALL_REGS
        ret

         proxy__restore_dir_position        ;equ os_start + $d9    ; added in FLOS v560
        PUSH_ALL_REGS
        call kjt_restore_dir_position
        POP_ALL_REGS
        ret

        proxy__mount_volumes           ;   start + $dc (added in v562)
        proxy__get_device_info             ;   start + $df (added in v565)

        proxy__read_sysram_flat    ;   start + $e2 (added in v570)
        PUSH_ALL_REGS
        GET_I_DATA l, h, e, a           ; 1 byte of 4 bytes, is dummy/unused
                                        ; e:hl = address
        call kjt_read_sysram_flat    ; function don't return result code 

        ld ix, I_DATA

        SET_I_DATA a              ; a  = byte read from address
        POP_ALL_REGS
        ret

        proxy__write_sysram_flat   ;   start + $e5 (added in v570)
        proxy__get_mouse_disp		  ;   start + $e8 (added in v571)
        
        proxy__get_dir_cluster		  ;   start + $eb (added in v572)      
       PUSH_ALL_REGS
        call kjt_get_dir_cluster    ; function don't return result code 

        ld ix, I_DATA
; DE = cluster pointed at by current directory
        SET_I_DATA e, d
        POP_ALL_REGS
        ret
       
        
        proxy__set_dir_cluster		  ;   start + $ee (added in v572)
        PUSH_ALL_REGS
; DE = desired cluster number to be used as current dir        
        GET_I_DATA e, d
        call kjt_set_dir_cluster      ; function don't return result code 
        POP_ALL_REGS
        ret
        
        proxy__rename_file		  ;   start + $f1 (added in v572)
        proxy__set_envar		  ;   start + $f4 (added in v575)
        proxy__get_envar		  ;   start + $f7 (added in v572)
        proxy__delete_envar		  ;   start + $fa (added in v572)

        proxy__file_sector_list	  ;   start + $fd (added in v575)
        PUSH_ALL_REGS
        GET_I_DATA a, e, d
        call kjt_file_sector_list    ; function don't return result code 

        ld ix, I_DATA

        SET_I_DATA a              ; a  = Sector offset (within current cluster)
; HL = Memory address of LSB of 4 byte sector location
        SET_I_DATA l, h

; DE = Updated cluster
        SET_I_DATA e, d

        POP_ALL_REGS
        ret

        proxy__mouse_irq_code		  ;   start + $100 (added in v579)
        proxy__get_sector_read_addr	;   start + $103 (added in v588)




