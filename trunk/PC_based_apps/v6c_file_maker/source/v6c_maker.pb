;---------------------------------------------------------------------
; Add system details to Xilinx .bin file to make .v6c FPGA config file
;
; PCB requirement @ $1fbdd
; LABEL @ $1fbde
; Null termination at $1fbee (0,0)
;
; ---------------------------------------------------------------------

;-------------------------------------------------------------------------------------
; Get the source .bin file
;-------------------------------------------------------------------------------------

    srcfile$ = OpenFileRequester("Select a Xilinx .bin file","",".bin files (.bin)|*.bin|All Files(*.*)|*.*",0)
    
    If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                        ; get the length of opened file
       *SourceBuffer = AllocateMemory(sourcesize+20)             ; allocate the needed memory
      ReadData(0,*SourceBuffer, sourcesize)                      ; read all data into the memory block
      CloseFile(0)
    Else
     MessageRequester("Information","Couldn't open the file!")
     End
    EndIf
 

;-------------------------------------------------------------------------------
; Add the details
;-------------------------------------------------------------------------------

pcb$ = InputRequester("Phils Utils", "PCB type? 1=V6Z80P 2=V6Z80P+V1.0 3=V6Z80P+V1.1", "1")
label$ = InputRequester("Phils Utils", "Enter Label (16 chars max)", "OSCA")

pcb_byte.w = Val(pcb$)
label$=label$+"                "

PokeS (*sourcebuffer+$1fbde,label$,16)
PokeB (*sourcebuffer+$1fbdd,pcb_byte)
PokeW (*sourcebuffer+$1fbee,0)

;-----------------------------------------------------------------------------------------

filename$ = srcfile$
filep$ = GetFilePart(filename$)
pathp$ = GetPathPart(filename$)

 Position = FindString(filep$, ".", 1)     ; trim off file extention
 If position > 0
  filep$=Left (filep$,position-1)
 EndIf
 
 size = Len (filep$)                        ;ensure 8.3 format
 If size > 8
  size = 8
 EndIf
  
destfilename$= RTrim(label$)+".v6c"

;------------------------------------------------------------------------------------------
; Save the file
;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save As..",DestFileName$,"V6Z80P FPGA config (.v6c)|*.v6c|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new file...
   WriteData(0,*Sourcebuffer,sourcesize+20)      ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file  
  Else
   MessageRequester("Phils Utils","Cant create file!" + Chr(13) , 0)
   End
  EndIf

 ;------------------------------------------------------------------------------------------

  MessageRequester("Phil's Utils..","Done!" + Chr(13) , 0)
  
End

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 56
; FirstLine = 9
; Folding = -
; Executable = ..\..\FLOS\apps\insert_crc_into_OS.exe