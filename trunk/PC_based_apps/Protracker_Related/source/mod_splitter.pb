; ------------------------------------------------------------
; Phil's Utils
; ------------------------------------------------------------

; Mod splitter - loads a protracker module and saves as two files:
; "data" and "samples"

MessageRequester("Phils Utils: Mod Splitter","Splits Protracker modules into seperate pattern and sample files"+ Chr(13) , 0)

;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------


  srcfile$ = OpenFileRequester("Select a Protracker file","","All Files(*.*)|*.*",0)
    
     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                  ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize)          ; allocate the needed memory
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)                ; read all data into the memory block
      Else
       MessageRequester("Phils utils","File error" + Chr(13) , 0)
       End
      EndIf
      CloseFile(0)
     Else
      MessageRequester("Phils utils","File error" + Chr(13) , 0)
      End
     EndIf
  

 FileName$ = GetFilePart(srcfile$)                        ; trim off file extention
 Position = FindString(FileName$, ".", 1)
 If position > 0
  FileName$=Left (FileName$,position-1)
 EndIf


 ;-----------------------------------------------------------------------------------------
 ;Process...
 ;-----------------------------------------------------------------------------------------
 
 songlength.l = PeekW(*sourcebuffer+950)&$ff
 highest.l = 0

 For patterncount = 0 To songlength
  pattern.w = PeekW(*sourcebuffer+952+patterncount)&$ff
  If pattern > highest
   highest = pattern
  EndIf
 Next patterncount
 
samples_offset = 1084+((highest+1)*1024)


 ;------------------------------------------------------------------------------------------
 ; Save the data 
 ;------------------------------------------------------------------------------------------
 
  
  dstfile$ = SaveFileRequester("Save pattern data as..",filename$+".pat","All files (*.*)|*.*",0)
  If CreateFile(0,dstfile$)                   
   WriteData(0,*Sourcebuffer,samples_offset)    
   CloseFile(0)                         
  Else
   MessageRequester("Phils utils","Can't create file" + Chr(13) , 0)
  End
  EndIf


  dstfile$ = SaveFileRequester("Save sample data as..",filename$+".sam","All files (*.*)|*.*",0)
  If CreateFile(0,dstfile$)                         
   WriteData(0,*Sourcebuffer+samples_offset,sourcesize-samples_offset)
   CloseFile(0)                                   
  Else
   MessageRequester("Phils utils","Can't create file" + Chr(13) , 0)
  End
  EndIf

;------------------------------------------------------------------------------------------
   

End 

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 73
; FirstLine = 30
; Folding = -
; EnableAsm
; Executable = ..\mod_splitter.exe