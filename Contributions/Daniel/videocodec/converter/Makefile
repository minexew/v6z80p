files=cv6conv.pas mv6conv.pas

all: $(files)
	for i in $(files); do fpc $$i -Sd -XXs -O3;done

win: $(files)
	for i in $(files); do fpc $$i -Sd -XXs -O3 -Twin32;done

run: all
	./$(asmname)
