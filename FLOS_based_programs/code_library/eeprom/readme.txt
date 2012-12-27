
For most basic use, inlcude "eeprom_routines.asm" into your source,
this is just an include list for all the component routines below
plus "eeprom_subroutines.asm"

Where only sepcific features are required, include one or more of
the following:

eeprom_config.asm
eeprom_interogation.asm
eeprom_programming.asm
eeprom_read.asm
eeprom_slot_list.asm

All of the above component routines also require:

"eeprom_subroutines.asm"

See individual sources for the operations they offer.
