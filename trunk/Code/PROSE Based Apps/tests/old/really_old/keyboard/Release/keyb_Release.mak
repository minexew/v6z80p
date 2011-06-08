SHELL = cmd.exe

#
# ZDS II Make File - keyb project, Release configuration
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
WORKDIR = E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\keyboard\Release

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"..;..\..\includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -NOdebug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\keyb_Release.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\keyboard\Release

build: keyb

buildall: clean keyb

relink: deltarget keyb

deltarget: 
	@if exist $(WORKDIR)\helloworld_adl.lod  \
            $(RM) $(WORKDIR)\helloworld_adl.lod
	@if exist $(WORKDIR)\helloworld_adl.hex  \
            $(RM) $(WORKDIR)\helloworld_adl.hex
	@if exist $(WORKDIR)\helloworld_adl.map  \
            $(RM) $(WORKDIR)\helloworld_adl.map

clean: 
	@if exist $(WORKDIR)\helloworld_adl.lod  \
            $(RM) $(WORKDIR)\helloworld_adl.lod
	@if exist $(WORKDIR)\helloworld_adl.hex  \
            $(RM) $(WORKDIR)\helloworld_adl.hex
	@if exist $(WORKDIR)\helloworld_adl.map  \
            $(RM) $(WORKDIR)\helloworld_adl.map
	@if exist $(WORKDIR)\waitkey.obj  \
            $(RM) $(WORKDIR)\waitkey.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\waitkey.obj

keyb: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\waitkey.obj :  \
            E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\keyboard\src\waitkey.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\keyboard\src\waitkey.asm

