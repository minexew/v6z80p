; ----------------------------
; V6Z80P EEPROM ROUTINES V1.03
; ----------------------------
;
; Main routine list:
; -------------------
; program_eeprom_page  (burns new data to eeprom - all 256 bytes of page must be $ff prior to write)
; read_eeprom_page     (reads 256 bytes to address label "page_buffer")
; erase_eeprom_sector  (erases a 64KB sector to all $ff)
; get_eeprom_size      (returns number of slots)
; get_pic_fw           (returns pic fw version byte)
; list_eeprom_contents (shows a list of all slot contents)
;
; ZF is set on return if operation was successful.
;
;  
; Changes:
; --------
;
; v1.03 - Optimized/split up source, added "get_pic_fw" etc, some routines renamed.
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

