{$mode delphi}
 
uses
  Classes, SysUtils, Synaser, Crt, Dos;
    
const
  hdr:array[0..11] of char='Z80P.FHEADER';
{$IFDEF LINUX}
  ttydev:string='USB0';
{$ELSE}
  ttydev:string='COM1';
{$ENDIF}

var
  ser: TBlockSerial;
  sendstat:boolean;
  buffer:array[0..257] of byte;
  fname,
  devstring:string;

function isesc:boolean;
begin
  isesc:=keypressed;
//  if keypressed then isesc:=readkey=#27 else isesc:=false;
end;

function calccrc:word;
var
  hlreg:dword;
  bytecount:byte;
  byteval:word;
  n:byte;

begin
  hlreg := 65535;
  For bytecount := 0 To 255 do
  begin
    byteval := buffer[bytecount];
    hlreg := (byteval shl 8) xor hlreg;
    For n := 0 To 7 do
    begin
      hlreg := hlreg + hlreg;
      If hlreg > 65535 then
      begin
        hlreg := hlreg and $FFFF;
        hlreg := hlreg xor $1021;
      End;
    end;
  end;
  calccrc:=hlreg;
end;

procedure makehdr;
var s:array[0..15] of char;
begin
  fillchar(buffer,258,0);
  fillchar(s,16,0);
  s:=fname;
  move(s,buffer[0],16);
  move(hdr,buffer[$14],12);
end;

function sendbuf:boolean;
var
  chk:word;
  chok:array[0..1] of char;
begin
  chk:=calccrc;chok:='??';
  move(chk,buffer[256],2);
  ser.sendbuffer(@buffer[0],258);
  ser.flush;
  repeat
    chok[0]:=chok[1];
    chok[1]:=char(ser.recvbyte(2000));
    if isesc then exit;
  until ((chok='OK') or (chok='XX'));
  sendbuf:=chok='OK';
end;

begin
  if ((paramcount<1) or (paramcount>2))   then 
  begin
    writeln('Usage: SENDCMD <device> command');
{$IFDEF LINUX}
    writeln('use "SENDCMD command" to send command to /dev/ttyUSB0');
    writeln('use "SENDCMD USB1 command" to send command to /dev/ttyUSB1');
{$ELSE}
    writeln('use "SENDCMD command" to send command to COM1');
    writeln('use "SENDCMD COM3 command" to send command to COM3');
{$ENDIF}
    halt;
  end;
  if paramcount=1 then fname:=paramstr(1) else begin fname:=paramstr(2); ttydev:=paramstr(1);end;
  ser:=TBlockSerial.Create;
{$IFDEF LINUX}
  devstring:='/dev/tty'+ttydev;
{$ELSE}
  devstring:=ttydev;
{$ENDIF}
  try
    clreol;write('opening '+devstring);gotoxy(1,wherey);
    ser.Connect(devstring);
    ser.config(115200, 8, 'N', SB1, False, False);
    makehdr;
    clreol;write('connecting to V6Z80P');gotoxy(1,wherey);
    sendstat:=sendbuf;
  finally
    ser.free;
  end;
  clreol;write('sending to '+devstring+':');if sendstat then writeln('done') else writeln('error');
end.
