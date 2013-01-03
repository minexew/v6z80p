
This programs makes a .v6c (v6z80 FPGA config file, as used by EEPROM.EXE)
from a standard Xilinx .bin file

.v6c files have the following extra data appended to the end:

@ $1fbdd: PCB Type Requirement (1=V6Z80P,2=V6Z80P+v1.0, 3=V6Z80P+v1.1)
@ $1fbde: 16 ASCII Chars Config ID
@ $1fbee: $00




