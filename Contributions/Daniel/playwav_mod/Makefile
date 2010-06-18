asmname= playwav
v6z80pdir= ~/work/V6z80p/V6pack
all: $(asmname).asm
	pasmo --alocal -d -I $(v6z80pdir)/Equates $(asmname).asm $(asmname).exe > $(asmname).lst 
#	sjasm $(asmname).asm

send: all
	sendv6 $(asmname).exe
	
