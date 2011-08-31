    include kernal_jump_table.asm
    include OSCA_hardware_equates.asm

macro sthp,dat
    ld   (hl),dat
    inc  hl
endm

macro copwait,line
    dw   line | 0c000h 
endm

macro copsel,reg
    dw   reg | 08000h
endm

macro copsto,dat
    db   dat,0
endm

macro copstp,dat   ; inc selector after store
    db   dat,040h
endm

macro copstw,dat   ; wait for next line after store
    db   dat,020h
endm

macro align,dat
	ds   dat-($ & (dat-1))
endm
