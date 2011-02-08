all: memtool.asm
	pasmo -E clearmem=0 memtool.asm memrnd.exe
	pasmo -E clearmem=1 memtool.asm memclr.exe

