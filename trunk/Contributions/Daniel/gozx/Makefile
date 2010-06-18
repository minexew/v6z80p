asmname= boot
v6z80pdir= ~/work/V6z80p/V6pack
all: $(asmname)1.asm
	pasmo --alocal -d -I $(v6z80pdir)/Equates $(asmname)1.asm $(asmname)1.exe
	pasmo --alocal -d -I $(v6z80pdir)/Equates $(asmname)2.asm $(asmname)2.exe
	pasmo --alocal -d -I $(v6z80pdir)/Equates $(asmname)3.asm $(asmname)3.exe
	
