
exe = playcv6.exe playmv6.exe
asm = pasmo -I ../../include --alocal -d

all: $(exe)

%.exe: %.asm 
	$(asm) $< $@ > $(<:%.asm=%.lst) 

