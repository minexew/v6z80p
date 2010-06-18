
; This file contain PQFS specific code, thus it can stream only files from PQFS media.


; struct prototype (to compute members offsets and struct size)
; ("mo__" prefix stands for "member offset")
struct__StreamedFile

mo__ptr_filename                defl    $ - struct__StreamedFile        ; offset of member
                                dw 0
mo__sectors_counter             defl    $ - struct__StreamedFile
                                db 0          
mo__offs_list_of_file_blocks    defl    $ - struct__StreamedFile
                                dw 0
mo__list_of_file_blocks         defl    $ - struct__StreamedFile        
                                dw 0 
mo__membank_of_list             defl    $ - struct__StreamedFile
                                db 0          
structsize__StreamedFile        defl    $ - struct__StreamedFile        ; size of struct



; we use FLOS sector_buffer (512 byte),
; but our own sector_lbaX vars
sector_lba0	db 0
sector_lba1	db 0
sector_lba2	db 0
sector_lba3	db 0


; "StreamedFile__" prefix for all routines, related to streamed file functionality.

; Init instance of StreamedFile
; hl = ptr to filename of streamed file   
; de = ptr to buffer for list of file blocks numbers   
; a  = system bank for list    
StreamedFile__init
        ld (ix + mo__ptr_filename),l
        ld (ix + mo__ptr_filename+1),h

        ld (ix + mo__list_of_file_blocks),e
        ld (ix + mo__list_of_file_blocks+1),d
        
        ld (ix + mo__membank_of_list),a

        ret
; ---------------------------------------------------

; Build in memory list of WORDS.
; This list contain PQFS file block numbers.
; (each file block represent 7E00 bytes of file data)
;
; In:  HL = base address of sound struct
; Out: CF = 1, ok
;      CF = 0, failed     
StreamedFile__build_sectors_list_for_sound_file
                                ; store to tmp var the address of sound struct
        ld iy,tmp1_ptr_to_sound_struct               
        ld (iy),l
        ld (iy+1),h             ; hl = base address of sound struct


        get_value_of_structmember_byptr l, h, hl,   tmp1_ptr_to_sound_struct, mo__ptr_filename
                                       ; hl = ptr to filename
        call kjt_find_file
        jr z,findfileok
	ld hl,str_err_findfile         ; print error
	call kjt_print_string
        or a
        ret
findfileok
        push bc                 ; Bank file was saved from
        push hl                 ; HL    = Address file was saved from
        push ix                 ; IX:IY = Length of file
        push iy                 

        ld ix,tmp1_file_block   ; de = first block of file - store to tmp var
        ld (ix  ),e
        ld (ix+1),d
        xor a                   ; offset in block is 0
        call fs_block_to_lba    ; convert to LBA sector number
        call mmc_read_sector    ; read first sector of first file block

        ;ld hl,sector_buffer
        ;ld de,$8000
        ;ld bc,512
        ;ldir

        pop iy
        pop ix
        pop hl
        pop bc

        ; loop: read 1st sector of each block
        push ix
        push iy
        pop  de
        pop  hl                 
                                ; hl:de - len of file
        ld bc,$7e00
        call div_hl_de_by_bc
                                ; hl:de - number of blocks
                                ; (in fact we will use only low word)
                                ; bc - remainder


        ld a,b                  ; if remainder is not null, inc block count
        or c
        jr z,remiszero
        inc de                  ; recommendation: filesize must be divided by 7E00 without remainder
remiszero

                                ; set sysmem bank for list
        get_value_of_structmember_byptr l, h, hl,   tmp1_ptr_to_sound_struct, mo__membank_of_list
        set_system_bank l       ; l = system bank number
                                ; --- get value of struct member ---
        get_value_of_structmember_byptr l, h, hl,   tmp1_ptr_to_sound_struct, mo__list_of_file_blocks
        push hl
        pop iy                  ; iy = address of list (list of file blocks)


        ; --- read first sector in each file block and store the sector number ---
        ld ix,tmp1_file_block   ; hl, number of first file block
        ld l,(ix  )
        ld h,(ix+1)

read_sector_in_next_file_block
        push de

        ld (iy  ),l
        ld (iy+1),h

        push hl
        pop de                  ; de = file block number
        xor a                   ; offset in block is 0
        call fs_block_to_lba    ; convert to LBA sector number
        call mmc_read_sector    ; read first sector of file block

                                ; get number of next file block
        ld ix,sector_buffer    
        ld l,(ix+8)
        ld h,(ix+9)             ; hl = number of next file block

        inc iy                  ; inc pointer to list
        inc iy
        pop de
        dec de
        ld a,e
        or d
        jr nz,read_sector_in_next_file_block

        ld hl,$ffff             ; put terminator to end of list
        ld (iy  ),l
        ld (iy+1),h

        scf                     ; ret ok
        ret


; Compute 
; In:  HL = base address of sound struct
StreamedFile__compute_LBA_sector_address

        ld iy,tmp2_ptr_to_sound_struct               
        ld (iy),l
        ld (iy+1),h             ; hl = base address of sound struct
        push hl
        pop iy                  ; iy = hl

        ; --------
redo_offs
                                ; set sysmem bank for list
        ld l,(iy + mo__membank_of_list) 
        set_system_bank l       ; l = system bank number (h = unknown value)

        get_value_of_structmember_byptr l, h, hl,   tmp2_ptr_to_sound_struct, mo__list_of_file_blocks
                                                ; hl = ptr to list of file blocks
        get_value_of_structmember_byptr e, d, de,   tmp2_ptr_to_sound_struct, mo__offs_list_of_file_blocks
                                                ; de = offset in list
        add hl,de                               ; hl = current address in list
        ld e,(hl)                               
        inc hl
        ld d,(hl)                               ; de = current file block number
        ;
        ld hl,$ffff                             ; do we reach end of list ?
        or a
        sbc hl,de
        jr nz, not_end_of_list
                                                ; reset offset to 0
        ld bc,0
        set_value_of_structmember_byptr c, b, bc,   tmp2_ptr_to_sound_struct, mo__offs_list_of_file_blocks
        jr redo_offs
not_end_of_list


        ld a,(iy + mo__sectors_counter) 
        inc a                                   ; we count from first data sector (thus, skip first meta-data sector in file block)
        ; de = current file block number, a = offset
        push iy
        call fs_block_to_lba                    ; convert to LBA sector number
        pop iy

        ; --------
        ld a,(iy + mo__sectors_counter)         ; a = sectors counter [0...3e]
        inc a                                   ; inc sector counter

        cp $3f                         ; $7E00/$200 = $3F    check, if sector counter is within file block
        jr nz,not_last_sector_in_file_block

                                                ; inc offset in list
        get_value_of_structmember_byptr e, d, de,   tmp2_ptr_to_sound_struct, mo__offs_list_of_file_blocks
                                                ; de = offset in list
        inc de                                  ; 
        inc de                                  ; to the next WORD in list
        set_value_of_structmember_byptr e, d, de,   tmp2_ptr_to_sound_struct, mo__offs_list_of_file_blocks
                                                ; store 

        xor a                                   ; reset sector counter to 0 
not_last_sector_in_file_block
        ld (iy + mo__sectors_counter),a         ; store 

        ret




; Divide hl:de by bc.
; Using substractions (slow...)
; In:  HL:DE,  32 bit DWORD
;      BC,     divide by
; Out: HL:DE,  result
;      BC,     remainder
div_hl_de_by_bc
        exx
        ld hl,$ffff         ; hl':de' counter of substractions
        ld de,$ffff
        exx
                

div_loop1
        push bc

        exx             ; advance counter
        ex de,hl
        ld bc,1
        add hl,bc       ; low WORD

        ex de,hl
        ld bc,0
        adc hl,bc       ; hi WORD  
        exx

        ; ---------------
        ex de,hl
                        ; hl = low WORD
        or a
        sbc hl,bc       ; low WORD - const
        push af
	ex af,af'       ; 
        pop af

        ex de,hl        ; hl = hi WORD
        ld bc,0
        sbc hl,bc       ; hi WORD - const
        pop bc
        jr nc, div_loop1                ;no carry was set (in result of hi WORD sub)
	ex af,af'        
        jr nc, div_loop1                ;no carry was set (in result of low WORD sub)
                        ; both carry flags was set

        push de         ; calc remainder
        pop hl
        add hl,bc       ; 
        push hl
        pop bc          ; bc = remainder

        exx             
        push hl
        push de
        exx
        pop de
        pop hl

        ret


str_err_findfile 	db "Cant find the file",11,0

tmp1_file_info		
tmp1_file_block	        db 0,0		;0 - first block address
tmp1_file_length	db 0,0,0,0	;2 - file length in bytes (little endian)
tmp1_z80_address	db 0,0		;6 - z80 load/save address
tmp1_z80_bank	        db 0		;8 - bank load/save offset 0/1/2/3		


tmp1_ptr_to_sound_struct        dw 0
tmp2_ptr_to_sound_struct        dw 0



; ------------ copy'n'paste from FLOS ---------------- not changed --
fs_block_to_lba


	push ix			; upon call: de = block, a = sector offset
	push de
	push bc
	inc de			; skip first 64 sectors of disk (leave PC MBR etc intact)
	and $3f
	ld b,a			; stash the sector offset for now
	xor a			; a = LSB
	srl d			; multiply de by 64
	rr e	
	rra
	srl d
	rr e
	rra
	or b			; or in the sector offset
	ld ix,sector_lba0		
	ld (ix),a			; put values in registers
	ld (ix+1),e
	ld (ix+2),d
	ld (ix+3),0		; PQFS doesnt use addresses this high
	pop bc
	pop de
	pop ix
	ret
