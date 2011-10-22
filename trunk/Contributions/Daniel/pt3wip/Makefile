#pt3PT
asmname= pt3play
v6z80pdir= ~/work/v6z80p/trunk
all: $(asmname).asm
	pasmo --alocal -d -I $(v6z80pdir)/Equates $(asmname).asm $(asmname).exe > $(asmname).lst 
#	sjasm $(asmname).asm

run: all
	sv6 $(asmname).exe
	
