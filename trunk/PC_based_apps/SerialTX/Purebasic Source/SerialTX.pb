;--------------------------------------------------------------------------------------------------------
; SerialSend: A PureBasic app for Windows to send a file to V6Z80P via serial RS232 from command line.
; Use: "SerialTX filename <com> <baud>" (and RX or FILERX in FLOS to receive)
; A quick mod of Serial Link by Phil @ retroleum.co.uk v0.01
; COM spec 8-N-1, no hardware flow control
;--------------------------------------------------------------------------------------------------------
  
OpenConsole()

srcfile$ = ProgramParameter()
com$ = ProgramParameter()
baud$ = ProgramParameter()

If srcfile$=""
 PrintN("SerialSend.exe - Send file via command line FLOS")
 PrintN(" ")
 PrintN("USE: SerialTX filename [com] [baud]")
 PrintN ("    com = 'COM1' To 'COM9', if not supplied first working COM port will be used.")
 PrintN ("    baud = 57600 or 115200, if not supplied baud set at 115200")
 Delay (5000)
 Goto normal_quit
 EndIf

If baud$ = ""
 baud$ = "115200"
EndIf
If baud$ <> "115200" And baud$ <> "57600"
 PrintN("Unsupported baud rate")
 Goto error_quit
EndIf
 
 
;---- Allocate memory for header buffer and file ----------------------------------------

*blockbuffer = AllocateMemory(258)                   ; 256 data + 2 CRC bytes
 If *blockbuffer = 0
  PrintN("Cant allocate memory buffer")
  Goto error_quit
 EndIf
*junkbuffer = AllocateMemory(258)
 If *junkbuffer = 0
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
 
 PrintN("Attempting to send " + srcfile$ + " on " + com$ + " at " + baud$ + " baud...")
 PrintN(" ")
 
  Gosub send_file
  
  If sendbuffer > 0
   FreeMemory(*SendBuffer)
  EndIf
   If error = 0
    PrintN("Completed OK")
    Goto normal_quit
   Else
    Goto error_quit
   EndIf
   
   
  
  ;----Send a file------------------------------------------------------------------------------------

send_file:

time_out_seconds = 3
error = 0  

  If ReadFile(0,srcfile$) 
   filesize.l = Lof(0)                                                    ; get the length of opened file
   *SendBuffer = AllocateMemory(filesize)                                 ; allocate memory for file  
   If *Sendbuffer = 0
    PrintN("Cant allocate memory buffer")
    Goto error_quit
   EndIf
   ReadData(0,*SendBuffer, filesize)                                      ; read all data into the memory block
   CloseFile(0)                                                           ; close the previously opened file
  Else
   PrintN("Load error")
   error = 1
   Return
  EndIf
 
;----- Make file header  ---------------------------------------------------------
  
  For addr = 0 To 255                         ; clear block buffer
   PokeB (*blockbuffer+addr,0)
  Next addr
     
  Filename$ = GetFilePart(srcfile$)           ; copy filename to header
  For n = 1 To 16
  If n <= Len(filename$)
    fnchar$ = Mid(filename$,n,1)
    fnascii = Asc(fnchar$)
   Else 
    fnascii = 0
   EndIf
  PokeB (*blockbuffer+(n-1),fnascii)
  Next n 
  PokeL (*blockbuffer+16,filesize)

  header_id$="Z80P.FHEADER"                  ; copy ID string to header
  For n = 1 To 12
    idchar$ = Mid(header_id$,n,1)
    idascii = Asc(idchar$)
   PokeB(*blockbuffer+20+(n-1),idascii)
  Next n

  Gosub calc_CRC
  PokeW (*blockbuffer+256,calculated_crc)
  
;---- Send File Header ---------------------------------------------------------------
 
Gosub clear_serial_receive_buffer

If IsSerialPort(0)
 result = WriteSerialPortData(0,*blockbuffer,258)
 If result <> 0             
  PrintN("Sending File Header")
 Else
  PrintN("Error Sending Header")
  error=1
  Return
 EndIf
Else
 PrintN("Port not ready")
  error = 1
 Return
EndIf

 Repeat
  NbDataToWrite.l = AvailableSerialPortOutput(0)       ; wait for send buffer to empty
 Until NbDataToWrite = 0
  
 ;PrintN("Waiting for header acknowledge..")          ; wait for acknowledge
 
 Gosub wait_ack
 If error = 1
  Return
 EndIf
 
 If ackstring$ = "WW"
  PrintN("OK, waiting for receiver to accept file..")
  time_out_seconds = 15
  Gosub wait_ack
  time_out_seconds = 3
   If error = 1
    Return
   EndIf
 EndIf
 
 If ackstring$ = "XX"
  PrintN("File refused.")
  error = 1
  Return
 EndIf
 
 If ackstring$ <> "OK"
  PrintN("Unknown acknowledge received:(" + ackstring$ + ")")
  error = 1
  Return
 Else
  PrintN("Ack received..OK.")
 EndIf
  
;---- Send File Data ---------------------------------------------------------------
 
 For addr = 0 To 255                         ; clear block buffer
  PokeB (*blockbuffer+addr,0)
 Next addr
 
 PrintN("Sending file data: " + Filename$)
 
 *filepos.l = *sendbuffer
 bytestogo.l = filesize

Repeat
 
    If bytestogo > 255
     bytecount.l = 256
    Else
     bytecount.l = bytestogo
    EndIf
  
    For addr=0 To bytecount-1
     filebyte.l = PeekB(*filepos+addr)&$ff
     PokeB (*blockbuffer+addr,filebyte)  
    Next addr
    Gosub calc_crc
    PokeW (*blockbuffer+256,calculated_crc)
 
   If WriteSerialPortData(0,*blockbuffer,258)             
    *filepos=*filepos+bytecount
    bytestogo=bytestogo-bytecount
   Else
    PrintN("Error Sending File")
    error=1
    Return
   EndIf

   Repeat
    NbDataToWrite.l = AvailableSerialPortOutput(0)   ;wait for send buffer to empty
   Until NbDataToWrite = 0

Gosub wait_ack
 If error = 1
  Return
 EndIf

If ackstring$ = "WW"
  time_out_seconds = 15
  Gosub wait_ack
  time_out_seconds = 3
   If error = 1
    Return
   EndIf
 EndIf
 
 If ackstring$ <> "OK"
  PrintN("Comms error: Unknown Ack: ("+ackstring$+").")
  error = 1
  Return
 EndIf
  
Until bytestogo <= 0

return

;
 ;------ Make a CRC checksum ----------------------------------------------------- 

Calc_CRC:

hlreg.l = 65535                                       ; crc returned in "calculated_crc"
For bytecount = 0 To 255
byteval.w = PeekB(*blockbuffer+bytecount)&$ff
hlreg = (byteval << 8) ! hlreg
For n = 0 To 7
hlreg = hlreg + hlreg
If hlreg > 65535 
 hlreg = hlreg & $FFFF
 hlreg = hlreg ! $1021
EndIf
Next n
Next bytecount
calculated_crc = hlreg&$ffff
Return

;----- Acknowledge signals ------------------------------------------------------------

Bad_ack:

WriteSerialPortString(0, "XX")
  Repeat
    NbDataToWrite.l = AvailableSerialPortOutput(0)   ;wait for send buffer to empty
  Until NbDataToWrite = 0
Return

Good_ack:

MyBuffer1.s = "OK"
WriteSerialPortString(0, "OK")
  Repeat
    NbDataToWrite.l = AvailableSerialPortOutput(0)   ;wait for send buffer to empty
  Until NbDataToWrite = 0
Return

;---------------------------------------------------------------------------------------

clear_serial_receive_buffer:
  
Repeat                                           ; clear serial receive buffer
 NbDataToRead.l = AvailableSerialPortInput(0)
 If NbDataToRead > 0
  ditchbytes.l = NbDataToRead
  If ditchbytes > 258
   ditchbytes = 258
  EndIf
  transfer =  ReadSerialPortData(0, *junkbuffer, ditchbytes)
 EndIf
Until NbDataToRead = 0
Return

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
 
wait_ack:

 start_time.l=Date()                                                      ; wait for ack
 Repeat
 ackbytes.l = AvailableSerialPortInput(0) 
 Until ackbytes=> 2 Or Date() > start_time+time_out_seconds

 If Date() > start_time+time_out_seconds 
   PrintN("Timed out.")
   error=1
   Return
 EndIf
 
 If ackbytes > 2
  PrintN("Comms Error: Too many Ack bytes received (" +Str(ackbytes)+")") 
  error=1
  Return
 EndIf
 
 ReadSerialPortData(0,*blockbuffer,2)                                    ; ack should be "OK", "WW" or "XX"  
 ackstring$ = Chr(PeekB(*blockbuffer)) + Chr(PeekB(*blockbuffer+1))
Return

;------------------------------------------------------------------------------------------ 
 
error_quit:

 PrintN(" ")
 PrintN("FAILED!")
 Delay(10000)
 
normal_quit:

 CloseConsole()
 End

;-------------------------------------------------------------------------------------------

 
  
  
  
  
  
  
  
  
  
  
  
  
  

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 16
; Folding = -
; EnableXP
; Executable = serialsend.exe