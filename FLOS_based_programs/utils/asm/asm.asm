;======================================================================================
; Standard header for OSCA and FLOS
;======================================================================================

include "equates\kernal_jump_table.asm"
include "equates\osca_hardware_equates.asm"
include "equates\system_equates.asm"

          org $5000
          
;--------------------------------------------------------------------------------------

default_org         equ 0

src_buffer_size     equ 1024
space               equ 32
tab                 equ 9
max_stack_levels    equ 8
incbin_buffer_size  equ 512

;--------------------------------------------------------------------------------------

          ld a,(hl)                     ; examine argument text for source filename
          or a                          
          jr nz,got_fn
          
bad_fn    ld hl,app_txt
          call kjt_print_string
          ld hl,missing_filename_txt
          call kjt_print_string
          xor a
          ret
          
got_fn    cp "%"
          jr z,bad_fn                   ; cant have includes without filename
          
fn_ok     ld de,working_src_filename    ; copy to working filename string
          ld b,16
fnclp     ld a,(hl)
          or a
          jr z,fncdone_noincl
          cp " "
          jr z,fncdone
          ld (de),a
          inc hl
          inc de
          djnz fnclp
fncdone   xor a
          ld (de),a                     ; null terminate filename

          ld de,dir_include_list        ; search for include dir %assigns
findinc   inc hl
          ld a,(hl)
          or a
          jr z,gotadinc
          cp "%"
          jr nz,findinc
cpydinc   ld a,(hl)
          cp " "
          jr z,gotdinc
          or a
          jr z,gotadinc
          ld (de),a
          inc de
          inc hl
          jr cpydinc
gotdinc   xor a
          ld (de),a
          inc de
          jr findinc

gotadinc  ld a,$ff
          ld (de),a                     ;terminate assigns list with $ff

fncdone_noincl
          
          
          ld hl,app_txt
          call kjt_print_string

          ld hl,working_src_filename    ; does filename exist?
          call kjt_find_file
          jp nz,load_error
          
;-------------------------------------------------------------------------------------------------

          call init_symbol_table
          call init_output_buffer
          
          ld hl,assembling_txt
          call kjt_print_string
          
          ld hl,$ffff                   ; these values should only be set for first pass
          ld (min_addr),hl
          xor a
          ld (mem_overflow),a
          
          ld hl,first_pass_txt
          call kjt_print_string
          xor a
          ld (pass_count),a
          call assemble
          jr nz,asm_failed

          ld hl,second_pass_txt
          call kjt_print_string
          ld a,1
          ld (pass_count),a
          call assemble
          jr nz,asm_failed

;-------------------------------------------------------------------------------------------------
          
          ld hl,from_txt+1
          ld de,(min_addr)
          call hexword_to_ascii_string
          ld hl,to_txt+1
          ld de,(bin_addr)
          dec de
          call hexword_to_ascii_string
          ld hl,assembled_txt
          call kjt_print_string
          
          call save_assembled_binary
          jr nz,save_fail
          
          ld hl,save_ok_txt
          call kjt_print_string
          ld hl,working_src_filename
          call kjt_print_string
          call new_line
          call new_line
          xor a
          ret


load_error

          ld a,$d
          call error_main
          xor a
          ret       

save_fail call error_main               ;show error text only (skip assembly related info)
          xor a
          ret

asm_failed

          call show_error
          xor a
          ret

;-------------------------------------------------------------------------------------------------------------------

missing_filename_txt

          db 11,"Usage: ASM source.asm [%incl_assigned] ",11,0

app_txt   db 11,"ASM v0.01 for FLOS by Phil Ruston",11,0

assembling_txt

          db "Assembling..",11,0

first_pass_txt

          db "Pass 1..",11,0
          
second_pass_txt

          db "Pass 2..",11,0

assembled_txt

          db "Assembled "
from_txt  db "$xxxx-"
to_txt    db "$xxxx OK",11,0

save_ok_txt

          db "Created file: ",0
          

cr_txt    db 11,0

char_txt  db " ",0  

;-------------------------------------------------------------------------------------------------------------------
; These output routines must not be located in paged memory!
;-------------------------------------------------------------------------------------------------------------------

init_output_buffer

          ld hl,$8000                   ;wipe sysram $10000-$1ffff
          ld a,2
          out (sys_mem_select),a
          xor a
clropb1   ld (hl),a
          inc l
          jp nz,clropb1
          inc h
          jp nz,clropb1
          ld a,3
          out (sys_mem_select),a
          xor a
          ld hl,$8000
clropb2   ld (hl),a
          inc l
          jp nz,clropb2
          inc h
          jp nz,clropb2
          xor a
          out (sys_mem_select),a
          ret
          

output_data_byte

          exx
          ld b,a
          ld a,(pass_count)             ;nothing is put in memory buffer on first pass
          or a
          jp nz,to_mem
          
          ld a,(mem_overflow)
          or a
          jr nz,output_er
                                        ;however range and minimun location are set
          ld hl,(bin_addr)
          inc hl
          ld (bin_addr),hl
          ld a,h
          or l
          jr z,mem_rolo

no_rolo   dec hl
          ld de,(min_addr)
          xor a
          sbc hl,de
          jr c,minadj
          exx 
          xor a
          ret

minadj    add hl,de
          ld (min_addr),hl
          exx
          xor a
          ret

mem_rolo  ld a,1
          ld (mem_overflow),a
          jr no_rolo

output_er ld a,9                        ;ERROR 9 - out of Z80 address space
          or a
          ret
          
          
                    
to_mem    ld hl,(bin_addr)              ;64KB target address space is mapped into sysram $10000-$1ffff
          inc hl
          ld (bin_addr),hl
          dec hl
          xor a
          sla h
          rla
          scf
          rr h
          add a,2
          out (sys_mem_select),a
          ld (hl),b
          xor a
          out (sys_mem_select),a
          exx
          ret
          
          
bin_addr            dw 0
          
min_addr            dw 0

mem_overflow        db 0

;-------------------------------------------------------------------------------------------------------------------
          
assemble  ld hl,0
          ld (working_src_file_pointer),hl
          ld (working_src_file_pointer+2),hl
          ld hl,default_org
          ld (bin_addr),hl
          xor a
          ld (stack_level),a  
          ld hl,1
          ld (working_src_line_count),hl
          ld hl,include_stack
          ld (stack_addr),hl
          call fill_source_buffer
          ret nz                                  
          
asm_loop  ld hl,(working_src_buffer_addr)
          call isolate_line_components
          ld (working_src_buffer_addr),hl
          or a
          jr z,lcomiso
          cp 1
          ret nz
          call interpret_line                     ;error 1 just means end of source, so assemble last line and return
          ret
          
lcomiso   call interpret_line
          or a
          ret nz
          jr asm_loop
          
;--------------------------------------------------------------------------------------------------------------------


new_line  ld hl,cr_txt
          call kjt_print_string
          xor a
          ret
          

print_char

          push hl
          ld hl,char_txt
          ld (hl),a
          call kjt_print_string
          pop hl
          ret



;====================================================================================================

isolate_line_components
          
          xor a
          ld (label_string),a
          ld (opcode_stem_string),a
          ld (opcode_arg1_string),a
          ld (opcode_arg2_string),a
          ld (quote_mode),a
          
f_start   ld a,(hl)                               ;scan for start of a line (char is space or above)
          or a
          jr nz,noteosrc                          ;EOF?
endofsrc  ld a,(stack_level)
          or a                                    ;Yes, but are we in the include stack?
          jr z,no_spops
          call pop_working_file_info              ;retrieve the previous file details
          ret nz
          call fill_source_buffer                 ;and continue processing that file
          ret nz
          ld hl,(working_src_buffer_addr)         
          jr f_start
          
no_spops  ld a,1
          or a
          ret

noteosrc  cp 10
          jr z,lfchar
          cp 11
          jr nz,notlf
lfchar    ld de,(working_src_line_count)
          inc de
          ld (working_src_line_count),de
notlf     cp tab
          jr z,okftxt
          cp space
          jr nc,okftxt
          inc hl
          push hl                                 ;is the source code buffer address within 256 bytes
          ld de,source_buffer                     ;of the end of the buffer?
          xor a
          sbc hl,de
          ld b,h
          ld c,l
          ld de,src_buffer_size-256
          xor a
          sbc hl,de
          pop hl
          jr c,f_start
refibuf   ld hl,(working_src_file_pointer)        ;yes, so adjust the file pointer and reload with new data
          ld de,(working_src_file_pointer+2)
          add hl,bc
          jr nc,wfphiok
          inc de
wfphiok   ld (working_src_file_pointer),hl
          ld (working_src_file_pointer+2),de
          call fill_source_buffer
          ret nz                                  
          ld hl,(working_src_buffer_addr)
          jr f_start
          
okftxt    ld (current_line_addr),hl               ;store in case error is to be shown
          ld a,(hl)
          cp tab                                  ;is there anything (EG: a label) at column 0?
          jr z,find_instruction
          cp space
          jr z,find_instruction
          cp ";"
          jp z,gotcomment
          
          ld b,255
          ld de,label_string                      ;copy the ascii from column 0 to label buffer
nlabch    cp "A"
          jr c,nocaseadj
          cp "Z"+1
          jr nc,nocaseadj
          add a,$20
nocaseadj ld (de),a
          inc hl
          inc de
          ld a,(hl)
          cp 10
          jp z,eol_term
          cp 13
          jp z,eol_term
          cp 11
          jp z,eol_term
          cp tab                                  ;breaks on tab, space or colon
          jr z,lab_done
          cp space
          jr z,lab_done
          cp ":"
          jr z,lab_done
notcolon  djnz nlabch
          ld a,4
          ret                                     ;bad label name (returns line too long errror)





lab_done  xor a
          ld (de),a                               ;zero-terminate the label string

find_instruction

          inc hl                                  ;scan until instruction or new line
          ld a,(hl)
          or a
          jp z,endofsrc
          cp 10
          jp z,got_eol        
          cp 13
          jp z,got_eol        
          cp 11
          jp z,got_eol
          cp ";"
          jp z,gotcomment     
          cp $21
          jr c,find_instruction

          ld b,255                                ;copy the opcode stem
          ld de,opcode_stem_string
copyocslp ld a,(hl)
          or a
          jp z,endofsrc_term
          cp $21
          jr c,opcode_stem_done
          cp "A"                                  ;lowercasify opcode stem
          jr c,ncaseadjs
          cp "Z"+1
          jr nc,ncaseadjs
          add a,$20
ncaseadjs ld (de),a
          inc hl
          inc de
          djnz copyocslp
          ld a,4
          ret                                     ;opcode stem too long = line too long error

opcode_stem_done
          
          xor a
          ld (de),a                               ;zero-terminate string

          


find_arg1 ld a,(hl)                               ;find the first opcode argument (if one exists)
          or a
          jp z,endofsrc
          cp ";"
          jr z,a1found_comment
          cp space
          jr z,move_on
          cp tab
          jr z,move_on        
          cp 14                                   ;new line? (ascii char 10,13,11 etc)
          jp c,isolated_entire_opcode             
          jr found_opcode_arg1
move_on   inc hl
          jr find_arg1
          

a1found_comment

          ld a,(quote_mode)                       ;if in quote mode, ";" is treated as normal char
          and 1
          jp z,gotcomment
          jr move_on

          
found_opcode_arg1   
          
          ld b,255
          ld de,opcode_arg1_string
copyarg1  ld a,(hl)
          or a
          jp z,endofsrc_term
          cp ";"                                  
          jr nz,a1notcom                          ;a semicolon (as long as not in quote mode) will terminate the
          ld a,(quote_mode)                       ;arg 1 string
          or a
          ld a,";"
          jr nz,ncaseadj1
          jp isolated_opcode_arg1
a1notcom  cp ","                                  ;comma only separates arg1 and arg2 if not in quote mode
          jr nz,arg1ncoma
          ld a,(quote_mode)                       
          or a
          ld a,","
          jr nz,ncaseadj1
          jp isolated_opcode_arg1
arg1ncoma cp tab                                  ;tabs / spaces are skipped    
          jr z,a1sptab
          cp space                                ;unless quote mode is on
          jr nz,arg1nsp
a1sptab   ld c,a
          ld a,(quote_mode)
          or a
          ld a,c
          jr nz,ncaseadj1
          jr arg1sksp
arg1nsp   jr c,isolated_opcode_arg1               ;end of line or tab?
          cp $22
          jr nz,noquo1                            ;make lower case (but not if between quotes)
goquo1    call found_quotes
          jr ncaseadj1
noquo1    cp $27
          jr z,goquo1
          ld c,a
          ld a,(quote_mode)
          or a
          ld a,c
          jr nz,ncaseadj1
          cp "A"
          jr c,ncaseadj1
          cp "Z"+1
          jr nc,ncaseadj1
          add a,$20
ncaseadj1 ld (de),a
          inc de
arg1sksp  inc hl
          djnz copyarg1
          ld a,4
          ret                                     ;opcode arg1 too long = line too long error
          
isolated_opcode_arg1
          
          xor a
          ld (de),a                               ;zero-terminate string



find_arg2 ld a,(hl)                               ;find the second opcode argument. If one exists
          or a                                    ;there'll be be a comma separator
          jp z,endofsrc
          cp $22
          jr nz,not_qu2
          call found_quotes
          jr argbscan
not_qu2   cp ";"
          jr z,a2found_comment
          cp space
          jr z,argbscan
          cp tab
          jr z,argbscan       
          cp 14                                   ;new line? (ascii char 10,13,11 etc)
          jr c,isolated_entire_opcode             
          cp ","
          jr z,found_comma
argbscan  inc hl
          jr find_arg2

a2found_comment

          ld a,(quote_mode)                       ;if in quote mode, ";" is treated as normal char
          and 1
          jp z,gotcomment
          jr argbscan


found_comma

          inc hl
          ld a,(hl)
          or a
          jp z,unexpected_eof                     ;returns error since a comma was found previously
          cp space
          jr z,found_comma
          cp tab
          jr z,found_comma
          cp 14
          jp c,syntax_error

          ld b,255                                ;copy the second arg to isolated string
          ld de,opcode_arg2_string
copyarg2  ld a,(hl)
          or a
          jp z,endofsrc_term                      ;returns error since a comma was found previously

          cp ";"                                  
          jr nz,a2notcom                          ;a semicolon (as long as not in quote mode) will terminate the
          ld a,(quote_mode)                       ;arg 2 string
          or a
          ld a,";"
          jr nz,ncaseadj2
          jp isolated_opcode_arg2
          
a2notcom  cp tab                                  ;tabs / spaces are skipped    
          jr z,a2sptab
          cp space                                ;unless quote mode is on
          jr nz,arg2nsp
a2sptab   ld c,a
          ld a,(quote_mode)
          or a
          ld a,c
          jr nz,ncaseadj2
          jr arg2sksp
arg2nsp   jr c,isolated_opcode_arg2               ;space, end of line or tab?
          cp $22
          jr nz,noquo2                            ;make lower case (but not if between quotes)
goquo2    call found_quotes
          jr ncaseadj2
noquo2    cp $27
          jr z,goquo2
          ld c,a
          ld a,(quote_mode)
          or a
          ld a,c
          jr nz,ncaseadj2
          cp "A"
          jr c,ncaseadj2
          cp "Z"+1
          jr nc,ncaseadj2
          add a,$20
ncaseadj2 ld (de),a
          inc de
arg2sksp  inc hl
          djnz copyarg2
          ld a,4
          ret                                     ;opcode arg2 too long = line too long error

isolated_opcode_arg2
          
          xor a
          ld (de),a                               ;zero-terminate string



isolated_entire_opcode
          
          ld a,(hl)                               ;look for CR or ";"
          or a
          jp z,endofsrc                           ;eof
          cp space
          jr z,nl_scan
          cp tab
          jr z,nl_scan
          ld a,(hl)                               ;move hl to start of next line
          cp ";"
          jr z,gotcomment                         ;find <CR> or <LF>
          cp 14
          jp c,got_eol
nl_scan   inc hl
          jr isolated_entire_opcode


gotcomment

          ld a,(hl)
          or a
          jp z,endofsrc
          cp tab
          jr z,nl2scan
          cp 14                                   ;scan until CR/LF is found
          jp c,got_eol
nl2scan   inc hl
          jr gotcomment





endofsrc_term

          xor a
          ld (de),a
          jp endofsrc
          
          
          
eol_term  xor a                                   ;zero terminate the label string
          ld (de),a
          ret



got_eol   xor a
          ret
          
          
                    
          
          
test_opcode_args

          push bc                                 ;on return, A bit0 = 1 if arg1 exists, A bit 1 = 1 if arg2 exists 
          ld b,0
          ld a,(opcode_arg1_string)
          or a
          jr z,noarg1
          set 0,b
noarg1    ld a,(opcode_arg2_string)
          or a
          jr z,noarg2
          set 1,b
noarg2    xor a
          or b
          pop bc
          ret
          


          

found_quotes

          push af
          ld a,(quote_mode)
          xor 1
          ld (quote_mode),a
          pop af
          ret



          
unexpected_eof
          
          ld a,2
          ret
          
syntax_error
          
          ld a,3
          ret

invalid_instruction
          
          ld a,6
          ret

number_out_of_range

          ld a,$22
          ret

;---------------------------------------------------------------------------------------------------
; Interpret line based on isolated components
;--------------------------------------------------------------------------------------------------

interpret_line

          ld hl,(bin_addr)
          ld (opcode_first_byte_addr),hl

          ld a,(label_string)           ;is there a label?
          or a
          jp z,no_label_string
          
          ld hl,opcode_stem_string      ;is the label followed by "equ" (as opcode stem)?
          ld a,"e"
          cp (hl)
          jr nz,label_is_addr           ;if not, define label as assembly location address
          inc hl
          ld a,"q"
          cp (hl)
          jr nz,label_is_addr
          inc hl
          ld a,"u"
          cp (hl)
          jr nz,label_is_addr
          inc hl
          ld a,(hl)
          or a
          jr nz,label_is_addr
          
          ld hl,opcode_arg1_string      ;its an equate - get its value from arg1
          ld a,(hl)
          or a                          ;missing equate arg?
          jp z,syntax_error             
          call handle_numeric_expression          
          jr z,oknewsym                           
          cp $11
          ret nz                        ;if any error other than unknown symbol, quit
          ld a,(pass_count)             ;if on 2nd pass and symbol still relies on unknown values, return error
          or a
          ret z                         ;if on 1st pass, ignore error (dont make a symbol)
          ld a,$11
          or a
          ret

oknewsym  ld hl,label_string            ;make new symbol.
          call new_symbol
          ret z                         ;If no error, return -  nothing else to do on this line

          cp $13                        ;already defined?
          ret nz
          
          ld a,(pass_count)             ;if first pass, always show error
          or a
          jr nz,pass2sne
          ld a,$13                      
          or a
          ret
          
pass2sne  ld hl,(symbol_value)          ;if second pass, compare with existing value (as returned by new_symbol routine)
          xor a
          sbc hl,de 
          ret z                         ;if same, no error
          ld a,$13                      
          or a                          ;if different, return "already defined" error
          ret
          
          
          
label_is_addr

          ld a,(pass_count)             ;dont create code address labels after pass 0
          or a
          jr nz,no_label_string         
          ld hl,label_string            ;define label as assembly location address
          ld de,(bin_addr)
          call new_symbol               
          ret nz
          
          
          
no_label_string

          ld ix,opcode_stem_string      ; look up handler code address based on first character of the opcode
          ld a,(ix)                     ; a - z
          or a
          ret z
          sub $61
          jr c,not_opcode
          cp 26
          jr nc,not_opcode
          sla a
          ld l,a
          ld h,0
          ld de,opcode_dictionary
          add hl,de
          ld e,(hl)
          inc hl
          ld d,(hl)
          ex de,hl
          jp (hl)
          
not_opcode
          
          jp invalid_instruction
          
          

opcode_dictionary

          dw a_code
          dw b_code
          dw c_code
          dw d_code
          dw e_code
          dw f_code
          dw g_code
          dw h_code
          dw i_code
          dw j_code
          dw k_code
          dw l_code
          dw m_code
          dw n_code
          dw o_code
          dw p_code
          dw q_code
          dw r_code
          dw s_code
          dw t_code
          dw u_code
          dw v_code
          dw w_code
          dw x_code
          dw y_code
          dw z_code
          

include   "FLOS_based_programs\utils\asm\includes\common_routines.asm"

include   "FLOS_based_programs\utils\asm\includes\a_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\b_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\c_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\d_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\e_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\f_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\g_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\h_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\i_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\j_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\k_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\l_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\m_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\n_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\o_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\p_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\q_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\r_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\s_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\t_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\u_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\v_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\w_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\x_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\y_instructions.asm"
include   "FLOS_based_programs\utils\asm\includes\z_instructions.asm"


;-----------------------------------------------------------------------------------------------------------------

include "FLOS_based_programs\utils\asm\includes\maths_routines.asm"

include "FLOS_based_programs\utils\asm\includes\symbol_table_routines.asm"

include "FLOS_based_programs\utils\asm\includes\file_buffer_routines.asm"
          
;-----------------------------------------------------------------------------------------------------------------

output_displacement_byte
          
          ld a,(ixiy_prefix)            ; no displacment byte outputted if no ixiy prefix is set
          or a
          ret z
          
          ld de,(displacement_word)     ; check it is in range -128 to +127
          bit 7,d
          jr nz,negdisb
          ld a,d
          or a
          jp nz,calc_overflow
          ld a,e
          cp 128
          jp nc,calc_overflow
disb_ok   ld a,e
          call output_data_byte
          xor a
          ret       

negdisb   ld a,d
          cp $ff
          jp nz,calc_overflow
          ld a,e
          cp 128
          jp c,calc_overflow
          jr disb_ok



;-------------------------------------------------------------------------------------------------------------------
          
output_data_word

          ld a,e
          call output_data_byte
          ld a,d
          call output_data_byte
          ret
          
;-------------------------------------------------------------------------------------------------------------------


output_ixiy_prefix

          ld a,(ixiy_prefix)            ;if prefix isnt set, dont add anything
          or a
          ret z
          call output_data_byte
          xor a
          ret
          
;------------------------------------------------------------------------------------------------------------------
          

print_decimal
          
;Number in hl to decimal ASCII, skips leading zereos
;Thanks to z80 Bits
;inputs:  hl = number to ASCII
;example: hl=300 outputs '00300'
;destroys: af, bc, hl, de used

DispHL:   ld d,5
          ld e,0
          ld bc,-10000
          call Num1
          ld bc,-1000
          call Num1
          ld bc,-100
          call Num1
          ld c,-10
          call Num1
          ld c,-1
Num1:     ld a,'0'-1
Num2:     inc a
          add hl,bc
          jr c,Num2
          sbc hl,bc
          dec d
          jr z,notzero
          cp "0"
          jr nz,notzero
          bit 0,e
          ret z
notzero   call print_char
          ld e,1
          ret 
          

;-----------------------------------------------------------------------------------------------------
; Errors
;-----------------------------------------------------------------------------------------------------


show_error

          push af
          ld hl,error_txt
          call kjt_print_string
          ld hl,(working_src_line_count)
          call print_decimal
          ld hl,of_file_txt
          call kjt_print_string
          ld hl,working_src_filename
          call kjt_print_string
          call new_line
          call new_line

          ld hl,(current_line_addr)               ;isolate current line
          ld de,isolated_label
ccline    ld a,(hl)
          cp tab                                  ;change tabs to spaces when displaying the faulty src line
          jr nz,notetab
          ld a,space
notetab   ld (de),a
          or a
          jr z,eoline
          cp 10
          jr z,eoline
          cp 13
          jr z,eoline
          cp 11
          jr z,eoline
          inc hl
          inc de
          jr ccline
eoline    xor a
          ld (de),a
          ld hl,isolated_label
          call kjt_print_string
          call new_line
          call new_line
          pop af
          
error_main

          sla a
          ld e,a
          ld d,0
          ld hl,error_text_table
          add hl,de
          ld e,(hl)
          inc hl
          ld d,(hl)
          ex de,hl
          call kjt_print_string
          call new_line
          call new_line
          ret
          
error_text_table

          dw 0                                    ;0
          dw 0                                    ;1
          dw unexpected_eof_txt                   ;2
          dw syntax_error_txt                     ;3
          dw line_too_long_txt                    ;4
          dw file_error_txt                       ;5
          dw unknown_opcode_txt                   ;6
          dw include_stack_error_txt              ;7
          dw extraneous_args_txt                  ;8
          dw out_of_z80_ram_txt                   ;9
          dw org_bad_txt                          ;a
          dw save_error_txt                       ;b
          dw no_data_to_save_txt                  ;c
          dw load_err_txt                         ;d
          dw 0                                    ;e
          dw 0                                    ;f
                    
          dw 0                                    ;10
          dw cant_find_label_txt                  ;11
          dw bad_label_name_txt                   ;12
          dw symbol_already_defined_txt           ;13
          dw sym_tab_full_txt                     ;14
          dw 0                                    ;15
          dw 0                                    ;16
          dw 0                                    ;17
          dw 0                                    ;18
          dw 0                                    ;19
          dw 0                                    ;1a
          dw 0                                    ;1b
          dw 0                                    ;1c
          dw 0                                    ;1d
          dw 0                                    ;1e
          dw 0                                    ;1f
          
          dw 0                                    ;20
          dw garbage_number_txt                   ;21
          dw number_range_txt                     ;22
          dw evaluation_error_txt                 ;23
          dw malformed_expression_txt             ;24
          dw math_string_too_long_txt             ;25
          dw unknown_operator_txt                 ;26


;---------------------------------------------------------------------------------------------------

of_file_txt

          db " of file:",0

include_stack_error_txt
          
          db "Too many nested INCLUDES",0

file_error_txt

          db "File not found",0
error_txt

          db 11,"Error! Line ",0
          
math_string_too_long_txt

          db "Maths expression too long",0

malformed_expression_txt

          db "Malformed expression",0

garbage_number_txt  

          db "Garbage in number string",0

unexpected_eof_txt

          db "EOF encountered unexpectedly",0

syntax_error_txt

          db "Syntax error",0
          
line_too_long_txt

          db "Line too long",0

unknown_opcode_txt

          db "Unknown instruction",0

number_range_txt

          db "Value out of range",0

evaluation_error_txt

          db "Evaluation error",0

unknown_operator_txt

          db "Unknown maths operator",0

cant_find_label_txt

          db "Unknown label",0

bad_label_name_txt

          db "Illegal symbol/label name",0
          
symbol_already_defined_txt

          db "Label already exists",0   

extraneous_args_txt

          db "Extraneous arguments",0

out_of_z80_ram_txt

          db "Output beyond address $FFFF",0

org_bad_txt

          db "ORG specifies prior address",0
          
save_error_txt

          db "Save error",0
          
no_data_to_save_txt

          db "No data to save",0

load_err_txt

          db 11,"Error! Can't find source file",0

sym_tab_full_txt

          db "Symbol table is full",0
                                                  
;----------------------------------------------------------------------------------------

current_line_addr             dw 0

pass_count                    db 0

quote_mode                    db 0

opcode_stem                   db 0

operand1_reg_sel              db 0

operand2_reg_sel              db 0

ixiy_prefix                   db 0

displacement_word             dw 0

opcode_first_byte_addr        dw 0

;----------------------------------------------------------------------------------------

label_string                  ds 256,0
opcode_stem_string            ds 256,0
opcode_arg1_string            ds 256,0
opcode_arg2_string            ds 256,0

;----------------------------------------------------------------------------------------

working_src_filename          ds 13,0

working_src_file_pointer      dw 0,0

working_src_file_size         dw 0,0

working_src_line_count        dw 0

working_src_buffer_addr       dw 0

;------------------------------------------------------------------------------------------

stack_level         db 0

stack_addr          dw 0

stack_entry_size    equ 12+1+2+4                            ; filename,zero,line_count,filepointer

include_stack       ds stack_entry_size*max_stack_levels,0

source_buffer       ds src_buffer_size+1,0                  ; ensures zero at end when filesize modulo = 0

;-----------------------------------------------------------------------------------------

incbin_file_size    dw 0                                    ; 16bit - max file = 64KB
incbin_file_pointer dw 0                                    ; 16bit - max file = 64KB
incbin_filename     ds 13,0
incbin_buffer       ds incbin_buffer_size,0

;-----------------------------------------------------------------------------------------

dir_include_list    ds 42,0

original_vol        db 0
original_dir        dw 0
inc_list_addr       dw 0
fn_addr             dw 0

;-----------------------------------------------------------------------------------------

sym_buffer          db 0                                    ;extends to $ffff - dont put anything after this

;-----------------------------------------------------------------------------------------