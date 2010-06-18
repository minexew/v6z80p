asmname= modplay60
v6z80pdir= ~/work/V6z80p
all: $(asmname).asm
	pasmo -d -I $(v6z80pdir)/Equates -I $(v6z80pdir)/FLOS_based_programs/utils/Protracker_Player/inc $(asmname).asm $(asmname).bin > $(asmname).lst 

send: all
	sendv6 $(asmname).bin
	
