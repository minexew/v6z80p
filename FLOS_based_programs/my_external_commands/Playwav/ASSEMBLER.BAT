
%v6z80pdir%\pasmo\pasmo.exe -d -I %v6z80pdir%\equates -I %v6z80pdir%\FLOS_based_programs\ext_cmds\playwav\inc -I %v6z80pdir%\FLOS_based_programs\ext_cmds\playwav\data %1 %1.bin

%v6z80pdir%\pasmo\pasmo_rename.exe %1

pause

@rem -d for assembly progress output