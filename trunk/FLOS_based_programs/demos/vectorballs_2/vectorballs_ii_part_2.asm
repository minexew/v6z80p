; creates a music player routine at $8000 for vectorballs 2 demo

;---Standard header for OSCA and OS ----------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"


	org $8000

	jp init_mus
	
	call play_tracker
	call update_sound_hardware
	ret

	
init_mus	ld hl,0+(music_samples-$8000)/2
	ld (force_sample_base),hl	; Force sample base location to $0
	call init_tracker
	ret

;-----------------------------------------------------------------------------

include 		"Protracker_Code_v510.asm"

;------------------------------------------------------------------------------

		org (($+2)/2)*2	; WORD align 

music_module	incbin "tune.pat"

		
music_samples	

;------------------------------------------------------------------------------
