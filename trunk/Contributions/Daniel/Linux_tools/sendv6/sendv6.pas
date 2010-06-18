 
uses
  Classes, SysUtils, Synaser, Crt;
    
const
  hdr:array[0..11] of char='Z80P.FHEADER';
var
  ser: TBlockSerial;
  quit:boolean=false;
  buffer:array[0..257] of byte;
  fbuffer:array[0..16777215] of byte;
  fbufpos,
  flen:dword;
  f:file;

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
  s:=paramstr(1);
  move(s,buffer[0],16);
  move(flen,buffer[16],4);
  move(hdr,buffer[$14],12);
end;

function sendbuf:boolean;
var
  chk:word;
  chok:array[0..1] of char;
begin
  chk:=calccrc;
  move(chk,buffer[256],2);
  ser.sendbuffer(@buffer[0],258);
  ser.flush;
  chok[0]:=char(ser.recvbyte(2000));
  chok[1]:=char(ser.recvbyte(2000));
  sendbuf:=chok='OK';
end;

begin
  if paramcount<>1 then halt;
  filemode:=0;
  assign(f,paramstr(1));
  reset(f,1);
  flen:=filesize(f);
  blockread(f,fbuffer,flen);
  close(f);
  fbufpos:=0;
  ser:=TBlockSerial.Create;
  try
    ser.Connect('/dev/ttyUSB0');
    ser.config(115200, 8, 'N', SB1, False, False);
    makehdr;
    if sendbuf then
    begin
      while not quit do
      begin
        if fbufpos>flen then quit:=true else
        begin
          move(fbuffer[fbufpos],buffer[0],256);
          inc(fbufpos,256);
          quit:=not sendbuf;
        end;
        if keypressed then if readkey=#27 then quit:=true;
        write('.');
      end;  
    end;
  finally
    ser.free;
  end;
  writeln;
end.
