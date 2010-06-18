; Arrange binary data into text for Xilinx Blockram INIT source

;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------

  srcfile$ = OpenFileRequester("Select a binary file to convert","","all files(*.*)|*.*",0)
    
     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                  ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize+512)      ; allocate the needed memory
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)                ; read all data into the memory block
      Else
       MessageRequester("BlockRAM INIT maker","File error" + Chr(13) , 0)
       End
      EndIf
      CloseFile(0)
     EndIf

;-------------------------------------------------------------------------------------------

blockram = 0
text$=""
*addrcounter = *sourcebuffer+31
line$="INST blah INIT_"

;-----------------------------------------------------------------------------------------

Repeat
 name$=InputRequester("Phils BlockRAM init util","What is blockram "+Hex(blockram)+" called?", "ROM_data_a")

  For linecount = 0 To 15
   line$="INST "+Chr($22)+name$+Chr($22)+" INIT_"
   initno$ = RSet(Hex(linecount),2,"0")
   line$=line$+initno$+" = "
   For column=31 To 0 Step -1
    hexval.w=PeekW(*addrcounter)&255
    digit$ = RSet(Hex(hexval),2,"0")
    line$=line$+digit$
    *addrcounter = *addrcounter - 1
   Next column
   text$=text$+line$+";"+Chr(13)+Chr(10)
   *addrcounter=*addrcounter+64
  Next linecount

  text$=text$+Chr(13)+Chr(10)
  blockram=blockram+1

Until *addrcounter > (*sourcebuffer+sourcesize)

 SetClipboardText(text$)

 MessageRequester("BlockRAM INIT maker","Text is in the clipboard" + Chr(13) , 0)
;-----------------------------------------------------------------------------------------

   End

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 6
; Folding = -
; Executable = BlockRAM_INIT.exe