rem ** make symbol file **

erase %v6z80pdir%\FLOS\inc\symbol_list.symbol
%v6z80pdir%\pasmo\pasmo.exe -d -I %v6z80pdir%\equates %v6z80pdir%\FLOS\inc\os_symbols.asm %v6z80pdir%\FLOS\inc\symbol_list.bin %v6z80pdir%\FLOS\inc\symbol_list.symbol
erase %v6z80pdir%\FLOS\inc\symbol_list.bin

@echo.
@echo Symbol file made - Press any key to continue second part of assembly..

pause

rem ** assemble os source **

%v6z80pdir%\pasmo\pasmo.exe -d -I %v6z80pdir%\equates -I %v6z80pdir%\FLOS\data -I %v6z80pdir%\FLOS\inc %1 %1.bin %1.symbol

%v6z80pdir%\FLOS\apps\Add_os_crc_header.exe

pause

