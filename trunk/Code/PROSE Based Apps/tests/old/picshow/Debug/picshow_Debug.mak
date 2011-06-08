SHELL = cmd.exe

#
# ZDS II Make File - picshow project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\picshow\Debug

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

LDFLAGS = @.\picshow_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\picshow\Debug

build: picshow

buildall: clean picshow

relink: deltarget picshow

deltarget: 
	@if exist $(WORKDIR)\picshow.lod  \
            $(RM) $(WORKDIR)\picshow.lod
	@if exist $(WORKDIR)\picshow.hex  \
            $(RM) $(WORKDIR)\picshow.hex
	@if exist $(WORKDIR)\picshow.map  \
            $(RM) $(WORKDIR)\picshow.map

clean: 
	@if exist $(WORKDIR)\picshow.lod  \
            $(RM) $(WORKDIR)\picshow.lod
	@if exist $(WORKDIR)\picshow.hex  \
            $(RM) $(WORKDIR)\picshow.hex
	@if exist $(WORKDIR)\picshow.map  \
            $(RM) $(WORKDIR)\picshow.map
	@if exist $(WORKDIR)\picshow.obj  \
            $(RM) $(WORKDIR)\picshow.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\picshow.obj

picshow: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\picshow.obj :  \
            E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\picshow\src\picshow.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\picshow\src\picshow.asm

