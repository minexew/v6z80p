SHELL = cmd.exe

#
# ZDS II Make File - flexbm project, Debug configuration
#
# Generated by: ZDS II - eZ80Acclaim! 5.1.1 (Build 10061702)
#   IDE component: d:5.1:10042301
#   Install Path: C:\Program Files\ZiLOG\ZDSII_eZ80Acclaim!_5.1.1\
#

RM = del

ZDS = C:\PROGRA~1\ZiLOG\ZDSII_~1.1
BIN = $(ZDS)\bin
# ZDS include base directory
INCLUDE = C:\PROGRA~1\ZiLOG\ZDSII_~1.1\include
# intermediate files directory
WORKDIR = E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\FLEXIB~1\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"..;..\..\includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\flexbm_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\FLEXIB~1\Debug

build: flexbm

buildall: clean flexbm

relink: deltarget flexbm

deltarget: 
	@if exist $(WORKDIR)\flexbm.lod  \
            $(RM) $(WORKDIR)\flexbm.lod
	@if exist $(WORKDIR)\flexbm.hex  \
            $(RM) $(WORKDIR)\flexbm.hex
	@if exist $(WORKDIR)\flexbm.map  \
            $(RM) $(WORKDIR)\flexbm.map

clean: 
	@if exist $(WORKDIR)\flexbm.lod  \
            $(RM) $(WORKDIR)\flexbm.lod
	@if exist $(WORKDIR)\flexbm.hex  \
            $(RM) $(WORKDIR)\flexbm.hex
	@if exist $(WORKDIR)\flexbm.map  \
            $(RM) $(WORKDIR)\flexbm.map
	@if exist $(WORKDIR)\setupbm.obj  \
            $(RM) $(WORKDIR)\setupbm.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\setupbm.obj

flexbm: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\setupbm.obj :  \
            E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\FLEXIB~1\src\setupbm.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\FLEXIB~1\src\setupbm.asm

