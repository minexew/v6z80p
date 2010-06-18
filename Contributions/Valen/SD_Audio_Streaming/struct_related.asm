MACRO get_value_of_structmember_byptr, r1, r2, r3, ptr_to_ptr_to_structbase, offs
        ld ix,ptr_to_ptr_to_structbase
        ld r1, (ix)
        ld r2, (ix+1)           ; r2r1 = address of struct

        push r3
        pop ix
        ld r1, (ix + offs)      ; get member value
        ld r2, (ix + offs + 1)
ENDM


MACRO set_value_of_structmember_byptr, r1, r2, r3, ptr_to_ptr_to_structbase, offs
        push r3                 ; save arg
        ld ix,ptr_to_ptr_to_structbase
        ld r1, (ix)
        ld r2, (ix+1)           ; r2r1 = address of struct

        push r3
        pop ix

        pop r3                 ; restore arg
        ld (ix + offs),r1      ; set member value
        ld (ix + offs + 1),r2
ENDM


; byte read/write

;MACRO get_byte_value_of_structmember_byptr, r1,  ptr_to_ptr_to_structbase, offs
;        ld ix,ptr_to_ptr_to_structbase
;        ld r1, (ix)
;        ld r2, (ix+1)           ; r2r1 = address of struct
;
;        push r3
;        pop ix
;        ld r1, (ix + offs)      ; get member value
 ;       ld r2, (ix + offs + 1)
;ENDM


; In: r1 = bank number
MACRO set_system_bank, r1
	in a,(sys_mem_select)   ;
	and $f0                 ; zero bank bits
        or r1
	out (sys_mem_select),a	
ENDM
