#!/bin/bash

V6Z80P_path="/home/valen/_1/v6z80p_SVN/"
# edit this (location of source asm file of FLOS)
flos_asm_file=$V6Z80P_path"FLOS/FLOSv575.asm"


# ---- Generate FLOS proxy jump table -------------
regex1="kjt_\(.*\)jp.*;"
# extract only lines with kjt jumps
sed -n  '/'$regex1'/p'               $flos_asm_file              > tmp1
# convert to our format
echo "; Machine generated. Dont edit. Source file:" $flos_asm_file        >  i__kernal_jump_table.asm
echo "; FLOS proxy jump table (must be identical to Kernel jump table)"  >> i__kernal_jump_table.asm
sed 's/'$regex1'/    jp proxy__\1  ;   /' tmp1                                >> i__kernal_jump_table.asm
rm tmp1

# ---- Generate kernal_jump_table.h -------------
sed 's/\(.*\)equ.*$\(.*\)/#define \U\1\L   \UOS_START\L+0x\2/' $V6Z80P_path"Equates/kernal_jump_table.asm" | sed 's/;/\/\//' | sed 's/.define os_start.*/#define OS_START 0x1000/i' > kernal_jump_table.h 


# ---- Generate OSCA_hardware_equates.h -------------
sed 's/\(.*\)equ.*$\(.*\)/#define \U\1\L   0x\2/'  $V6Z80P_path"Equates/OSCA_hardware_equates.asm" | sed 's/;/\/\//' >  OSCA_hardware_equates.h