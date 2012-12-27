; ----------------------------
; V6Z80P EEPROM ROUTINES V1.03
; ----------------------------
;
; Changes:
; --------
;
; v1.03 - Optimized/split up source, added "get_pic_fw" etc, disabled IRQs around main
; routines, some routines renamed.
; 
;---------------------------------------------------------------------------------------

		include "flos_based_programs\code_library\eeprom\inc\eeprom_subroutines.asm"

;-----------------------------------------------------------------------------------------

		include "flos_based_programs\code_library\eeprom\inc\eeprom_programming.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_read.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_interogation.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_slot_list.asm"
		include "flos_based_programs\code_library\eeprom\inc\eeprom_config.asm"
		
;-----------------------------------------------------------------------------------------

