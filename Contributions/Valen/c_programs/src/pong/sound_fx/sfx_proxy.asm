; Proxy for calling asm code from C.

;---Standard header for V6Z80P and OS ----------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

        ; pattern data
        music_module equ $8000+$2000+$200          ; WORD align song module in RAM (module, not a sample data!)	

	org $8000
;
fx_list	ds 128*2  		; just reserve space. Later C code will add as many as required.

; jump table
        jp new_fx
        jp play_fx

        jp init_tracker
        jp play_tracker
        jp update_sound_hardware
        jp set_force_sample_base

;---------------------------------------------------------------------------------------------

include "sfx_routine.asm"

; Music player
include "50Hz_60Hz_Protracker_code_v513.asm"


;---------------------------------------------------------------------------------------------

; in hl = base
set_force_sample_base
        ld (force_sample_base),hl
        ret

 