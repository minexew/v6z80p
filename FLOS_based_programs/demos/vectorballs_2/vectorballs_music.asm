; creates a music player routine at $8000 for vectorballs 2 demo
;
;---Standard header for OSCA and OS ----------------------------------------

include "equates\kernal_jump_table.asm"
include "equates\OSCA_hardware_equates.asm"
include "equates\system_equates.asm"


          org $8000

          jp init_mus
          
          call play_tracker
          call update_sound_hardware
          ret

          
init_mus  ld hl,0+(music_samples-$8000)/2
          ld (force_sample_base),hl     ; Force sample base location to $0
          call init_tracker
          ret

;-----------------------------------------------------------------------------

include             "flos_based_programs\demos\vectorballs_2\inc\50Hz_60Hz_Protracker_Code_v513.asm"

;------------------------------------------------------------------------------

                    org (($+2)/2)*2     ; WORD align 

music_module        incbin "flos_based_programs\demos\vectorballs_2\data\tune.pat"

                    
music_samples       

;------------------------------------------------------------------------------
