#!/bin/bash

V6Z80P_path="/home/valen/_1/v6z80p_SVN/"
flos_asm_file=$V6Z80P_path"FLOS/FLOS570FAT16.asm"


# ---- Generate FLOS proxy jump table 
regex1="kjt_\(.*\)jp.*;"
# extract only lines with kjt jumps
sed -n  '/'$regex1'/p'               $flos_asm_file              > tmp1
# convert to our format
echo "; Machine generated. Dont edit. Source file:" $flos_asm_file        >  i__kernal_jump_table.asm
echo "; FLOS proxy jump table (must be identical to Kernel jump table)"  >> i__kernal_jump_table.asm
sed 's/'$regex1'/    jp proxy__\1  ;   /' tmp1                                >> i__kernal_jump_table.asm
rm tmp1

