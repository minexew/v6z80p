
%v6z80pdir%\pasmo\pasmo.exe -d -I %v6z80pdir%\equates -I %v6z80pdir%\FLOS_based_programs\code_library\window_routines\inc -I %v6z80pdir%\FLOS_based_programs\code_library\requesters\inc -I %v6z80pdir%\FLOS_based_programs\code_library\string\inc -I %v6z80pdir%\FLOS_based_programs\code_library\program_header %1 %1.bin %1.symbol 

%v6z80pdir%\pasmo\pasmo_rename.exe %1

pause

@rem -d for assembly progress output