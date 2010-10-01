regex1="\(FLOS_.*\)\.c"

echo "# Machine generated. Dont edit."                                    >  Makefile_lib
echo "# This file should be included in main makefile."                   >> Makefile_lib

ls | grep FLOS_ - | sed 's/'$regex1'/$(myd7)\/obj\/\1.rel : $(myd7)\/\1.c \n\tcd $(myd7_) \&\& sdcc -c -o obj\/ $(INC) --std-sdcc99  -mz80   --opt-code-speed $(use_stdout) \1.c/' - >> Makefile_lib
echo ' ' >> Makefile_lib

# Generate creation of LIB
#ls | grep FLOS_ - | sed 's/'$regex1'/$(myd7)\/obj\/i_flos_lib\.lib : $(myd7)\/obj\/\1.rel \n\tcd $(myd7_) \&\& sdcclib  obj\/i_flos_lib.lib  obj\/\1.rel/' - >> Makefile_lib









# depend section
echo '$(myd7)/obj/i_flos_lib.lib :   \' >> Makefile_lib
ls | grep FLOS_ - | sed 's/'$regex1'/            $(myd7)\/obj\/\1.rel             \\/' - >> Makefile_lib
echo ' ' >> Makefile_lib
# make section
echo 'xxx' | sed 's/xxx/\tcd $(myd7_) \&\& sdcclib -l obj\/i_flos_lib.lib myliblist.txt  /' - >> Makefile_lib
ls | grep FLOS_ - | sed 's/'$regex1'/obj\/\1.rel/   ' -  >> myliblist.txt
echo ' ' >> Makefile_lib




# $(myd7)/obj/i_flos_lib.lib : $(myd7)/obj/FLOS_*.$(O)
