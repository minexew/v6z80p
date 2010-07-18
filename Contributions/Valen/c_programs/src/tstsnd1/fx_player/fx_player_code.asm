; Proxy for calling asm code from C.

;---Standard header for V6Z80P and OS ----------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"


;	org
include "fx_player/obj/sound_fx_code_address.asm"



; jump table
        jp new_fx
        jp play_fx

;---------------------------------------------------------------------------------------------

; include fx_player code
include "fx_player.asm"

 
; include sounds descriptors (there are 7 descriptors in my_fx1.dat)
fx_data incbin "my_fx1.dat"