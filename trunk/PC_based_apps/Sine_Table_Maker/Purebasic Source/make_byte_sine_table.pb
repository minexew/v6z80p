;--------------------------------------------------------------------------------------
; sin/cos byte table maker Byte list
;--------------------------------------------------------------------------------------
amp = 256
 While amp > 127
 Amplitude$ = InputRequester("Phil's Sine Byte Table Generator", "Enter max positive amplitude:", "127")
 amp = Val(Amplitude$)
 Wend
Steps$ = InputRequester("Sine Table Generator", "Enter number of angle steps:", "360")
Steps = Val(Steps$)
disp.f = 360 / Steps

;--------------------------------------------------------------------------------------
; make sin list
;--------------------------------------------------------------------------------------

*DestBuffer = AllocateMemory(disp*2)  
  If *Destbuffer
   degree.f = 0 
   index = 0
   While degree < 360
    radian.f = ((degree * 3.14159) / 180)
    sinvalue.f = Sin(radian)
    wordval = sinvalue * amp
    PokeB (*DestBuffer+Index,wordval)
    degree = degree + disp
    index = index + 1
   Wend
 
 ;------------------------------------------------------------------------------------------
 ; Save the sine table
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save As..","sine_table_bytes.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                       ; we create a new text file...
   WriteData(0,*DestBuffer,index)                   ; write data from the memory block into the file
   CloseFile(0)                                   ; close the previously opened file and so store the written data 
  Else
   MessageRequester("Sine table maker","Cant create file!" + Chr(13) , 0)
   End
  EndIf
 

 ;------------------------------------------------------------------------------------------
  
 Else
  MessageRequester("Sine table maker","Cant create destination buffer!" + Chr(13) , 0)
  End
 EndIf
 
; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 33
; Folding = -