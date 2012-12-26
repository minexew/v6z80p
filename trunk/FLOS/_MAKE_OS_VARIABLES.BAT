 
echo Making os_variables.symbol file

erase %v6z80pdir%\FLOS\inc\FLOS_variables.symbol

%v6z80pdir%\pasmo\pasmo.exe -d -I %v6z80pdir%\equates %v6z80pdir%\FLOS\inc\FLOS_variables.asm %v6z80pdir%\FLOS\inc\FLOS_variables.bin %v6z80pdir%\FLOS\inc\FLOS_variables.symbol

erase %v6z80pdir%\FLOS\inc\FLOS_variables.bin

pause

