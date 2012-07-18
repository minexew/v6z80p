
%v6z80pdir%\pasmo\pasmo.exe -d -I %v6z80pdir%\equates -I %v6z80pdir%\FLOS_based_programs\tools\emu\data -I %v6z80pdir%\FLOS_based_programs\code_library\window_routines\inc -I %v6z80pdir%\FLOS_based_programs\code_library\Requesters\inc -I %v6z80pdir%\FLOS_based_programs\code_library\eeprom_routines -I %v6z80pdir%\FLOS_based_programs\code_library\program_header %1 %1.bin

%v6z80pdir%\pasmo\pasmo_rename.exe %1

pause