; FIRMWARE.EXE v1.00
; ------------------
;
; Reads in a file and writes it to EEPROM from given block number (0 if not supplied)
;
; Usage: FIRMWARE.EXE filename.bin [EEPROM block]
;
;
;---Standard header for OSCA and FLOS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000

;------------------------------------------------------------------------------

data_buffer         equ $8000

;------------------------------------------------------------------------------

          ld a,(hl)                     ; examine argument text, if 0: show use
          or a                          
          jp z,show_use

          ld de,filename                ; copy args to working filename string
          ld b,16
fnclp     ld a,(hl)
          or a
          jr z,fncdone
          cp " "
          jr z,fncdone
          ld (de),a
          inc hl
          inc de
          djnz fnclp
fncdone   xor a
          ld (de),a                     ; null terminate filename
          
          xor a
          ld (block_number),a           ; next byte is destination block number (if supplied)

          call kjt_ascii_to_hex_word
          or a
          jr nz,got_blk
          ld a,e
          ld (block_number),a

;-----------------------------------------------------------------------------------------------

got_blk   xor a
          ld (source_bank),a
          
          ld hl,filename                ; does filename exist?
          call kjt_find_file
          jp nz,ld_error

          push ix
          pop de
          push iy
          pop hl
          ld bc,1
          xor a
          sbc hl,bc
          jr nc,lowok
          dec de
lowok     ld a,e
          inc a
          ld (blocks_to_write),a

          sla a                         ;fills n x 2 banks with FF so that there's
          ld b,a                        ;no random data at end (since this app writes
          xor a                         ;to whole 64KB banks without read-modify-write)
          call kjt_force_bank
lp2       ld a,$ff
          ld hl,$8000
lp1       ld (hl),a
          inc l
          jr nz,lp1
          inc h
          jr nz,lp1
          call kjt_inc_bank
          djnz lp2
          xor a
          call kjt_force_bank

          ld hl,loading_txt
          call kjt_print_string

          ld hl,data_buffer
          ld b,0
          call kjt_force_load           
          jp nz,ld_error
          
          ld hl,confirm_txt             
          call kjt_print_string
	  ld a,1
          call kjt_get_input_string
          or a
          jp z,quit
          ld a,(hl)
          cp "Y"
          jp nz,abort

          ld hl,working_txt             
          call kjt_print_string

nxt_page  call erase_block    
          call write_block
          jr nz,epr_error
          call verify_block
          jr nz,epr_error
          
          ld hl,source_bank
          inc (hl)
          inc (hl)
          ld hl,block_number
          inc (hl)
          ld hl,blocks_to_write
          dec (hl)
          jr nz,nxt_page
          
          ld hl,ok_text                 ; show "completed" text
          call kjt_print_string
quit      xor a
          ret


epr_error ld hl,eeprom_error
          call kjt_print_string
          xor a
          ret
          
ld_error  ld hl,load_error
          call kjt_print_string
          xor a
          ret       
          
show_use  ld hl,show_use_txt
          call kjt_print_string
          xor a
          ret                 
          
abort     ld hl,aborted_txt
          call kjt_print_string
          xor a
          ret                 
                    
;------------------------------------------------------------------------------------------

erase_block

          ld hl,erasing_block_txt                 ; show "verifying" text
          call kjt_print_string

          ld a,(block_number)           
          ld hl,block_num_txt 
          call kjt_hex_byte_to_ascii
          ld hl,block_num_txt                     ; show "erasing" text
          call kjt_print_string

          ld a,(block_number)                     ; erase the required 64KB eeprom sector 
          call erase_eeprom_sector
          ret

;------------------------------------------------------------------------------------------

write_block

          ld hl,writing_block_txt                 ; show "verifying" text
          call kjt_print_string

          ld a,(source_bank)
          call kjt_forcebank
          ld hl,data_buffer
          ld b,0                                  ; 256 pages to write
          ld a,(block_number)
          ld d,a
          ld e,0
dwrpagelp call program_eeprom_page
          or a
          jr nz,wr_error
          inc h
          jr nz,samebdb
          ld h,$80
          call kjt_incbank
samebdb   inc de
          djnz dwrpagelp
          xor a
          ret

wr_error  xor a
          inc a
          ret


;------------------------------------------------------------------------------------------

verify_block
          
          ld hl,verifying_block_txt               ; show "verifying" text
          call kjt_print_string
          
          ld a,(source_bank)
          call kjt_forcebank
          ld hl,data_buffer
          ld b,0
          ld a,(block_number)
          ld d,a
          ld e,0
dvrpagelp call read_eeprom_page
          or a
          jr nz,time_out_err
          ld ix,page_buffer
dverlp    ld a,(ix)
          cp (hl)
          jr nz,ver_error
          inc ix
          inc l
          jr nz,dverlp
          inc h
          jr nz,dsamebnkv
          ld h,$80
          call kjt_incbank
dsamebnkv inc de
          djnz dvrpagelp
          xor a
          ret
          
ver_error xor a
          inc a
          ret

time_out_err

          xor a
          inc a
          ret
                              
          
;-----------------------------------------------------------------------------------

include "flos_based_programs\code_library\eeprom\inc\eeprom_routines.asm"

;------------------------------------------------------------------------------------

filename            db 18,0

test_fn             db "default.bin"

show_use_txt        db "Usage:",11,"FIRMWARE.EXE filename.bin [EEPROM block]",11,0

eeprom_error        db "EEPROM error!",11,0

load_error          db "LOAD error! File not found?",11,0

ok_text             db "EEPROM update: OK",11,0

loading_txt         db 11,"Loading firmware file..",11,11,0

confirm_txt         db "Confirm overwrite EEPROM data (y/n) ",0

working_txt         db 11,11,"OK, Updating...",11,11,0

erasing_block_txt   db "Erasing block $",0
block_num_txt       db "xx",11,0

writing_block_txt   db "Writing..",11,0

verifying_block_txt db "Verifying..",11,11,0

aborted_txt         db 11,11,"Aborted",11,11,0

block_number        db 0

blocks_to_write     db 0

source_bank         db 0

page_buffer         ds 256,0

;------------------------------------------------------------------------------------