;--------------------------------------------------------------------------------------------------------
; Shows bytes received by serial port
;--------------------------------------------------------------------------------------------------------
  
OpenConsole()

com$ = ProgramParameter()
baud$ = ProgramParameter()

 PrintN("rx_mon.exe v0.01")
 PrintN(" ")
 PrintN("USE: rx_mon [com] [baud]")
 PrintN(" ")
 PrintN ("    com = 'COM1' To 'COM9', if not supplied first working COM port will be used.")

If baud$ = ""
 baud$ = "57600"
EndIf
 
;---- Allocate memory for header buffer and file ----------------------------------------

*blockbuffer = AllocateMemory(1024)
 If *blockbuffer = 0
  PrintN("Cant allocate memory buffer")
  Goto error_quit
 EndIf

 ;--- Open Com Port  ---------------------------------------------------------------- 

findcom.l = 0 
If com$ = ""
 Repeat
   findcom = findcom + 1
   com$ = "COM"+Str(findcom)
   Gosub open_com_port
 Until comok=1 Or findcom = 9
 Else
  Gosub open_com_port
  If comok = 0
   PrintN("Cant open " + com$)
   Goto error_quit
  EndIf
 EndIf

 If findcom = 9 And comok=0
  PrintN("Cant find a com port (Tried COM1-C0M9)")
  Goto error_quit
 EndIf

;--------------------------------------------------------------------------------------
 
 PrintN("Monitoring port " + com$ + " at " + baud$ + " baud...")
 PrintN(" ")
 
 showbytes:

 Repeat
 ackbytes.l = AvailableSerialPortInput(0) 
 Until ackbytes => 1
 
 Repeat
  
 ReadSerialPortData(0,*blockbuffer,1)                                 
 thebyte = PeekB(*blockbuffer) 
 thestring$ = Str(thebyte)
 PrintN (thestring$) 
 ackbytes = ackbytes - 1
 
 Until ackbytes = 0 
  
 Goto showbytes
 
 ;---------------------------------------------------------------------------------------
 
 open_com_port:
 
 MyCom$ = Com$ + ": baud=" + Baud$ + " parity=N Data=8 stop=1"
 
 If OpenSerialPort(0, com$, Val(baud$), #PB_SerialPort_NoParity, 8, 1, #PB_SerialPort_NoHandshake, 258, 258)
     comok = 1
  Else
     comok = 0
  EndIf
Return
 
;--------------------------------------------------------------------------------------

error_quit:
 
 CloseSerialPort(0)
 
 PrintN(" ")
 PrintN("FAILED!")

 Delay(10000)

 CloseConsole()
 End
 
 ;-------------------------------------------------------------------------------------------

normal_quit:
 
 CloseSerialPort(0)
 CloseConsole()
 End

;-------------------------------------------------------------------------------------------

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 16
; Folding = -
; EnableXP
; Executable = serialsend.exe