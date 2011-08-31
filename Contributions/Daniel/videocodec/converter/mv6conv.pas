{$mode delphi}
uses sysutils;

type
  tid=array[0..3] of char;

const
  thres=4; // search threshold - too low and decompressor uses too much cpu - too high and reading uses too much cpu
//  pal2:array[0..1,0..2] of byte=(($00,$00,$00),($F0,$F0,$F0));//BGR!
  pal4:array[0..3,0..2] of byte=(($00,$00,$00),($50,$50,$50),($A0,$A0,$A0),($F0,$F0,$F0));//BGR!
  screenx=320;
  screeny=200;
  picx=320;
  chrx=picx div 8;
  picy=100;
  bmsiz=chrx*picy;
  pagesiz=(bmsiz+511) and $fe00;
  pagesz1=2*pagesiz-512;
  screensize=screenx*screeny;
  screenvx=screenx shr 1;
  screenvy=screeny shr 1;
  audsiz=1024;

var
  movfound,isavi:boolean;
  avinam,audnam,mv6nam:string;
  audbuf:array[0..audsiz-1] of byte;
  outbuf:array[0..65535] of byte;
  lastbuf:array[0..(2*pagesiz-1)] of byte;
  v6buf:array[0..(2*pagesiz-1)] of byte;
  pic:array[0..picy,0..picx,0..2] of byte;
  pic4:array[0..picy,0..picx] of byte;
  leftread,movlen:integer;
  favi,faud,fmv6:file;
  readdone:boolean;
  cnt:dword;obp:word;
  len:dword;id,sid:tid;

function reverse(s:string):string;
var i:integer;
var tmp:char;
begin
  for i:=1 to length(s) div 2 do
  begin
    tmp:=s[i];
    s[i]:=s[length(s)+1-i];
    s[length(s)+1-i]:=tmp;
    reverse:=s;
  end;
end;

function getid:tid;
var t:tid;
begin
  blockread(favi,t,4);getid:=t;
end;

function getlen:dword;
var t:dword;
begin
  blockread(favi,t,4);getlen:=t;
end;

procedure findmovchunk;
begin
  movfound:=false;isavi:=true;
  id:=getid; if id<>'RIFF' then isavi:=false;id:=getid;
  id:=getid; if id<>'AVI ' then isavi:=false;
  if isavi then
  begin
    repeat
      id:=getid;sid:='';
      if id='LIST' then
      begin
        len:=getlen;
        sid:=getid;
        if sid='movi' then 
        begin
          movfound:=true;      
          movlen:=len-4;
        end else seek(favi,filepos(favi)-4+len);
      end else
      if id='JUNK' then 
      begin
        len:=getlen;
        seek(favi,filepos(favi)+len);
      end else
      begin
        writeLn('Unknown Chunk ',id);
        len:=getlen;
        seek(favi,filepos(favi)+len);
      end;
      if eof(favi) then begin movfound:=true;isavi:=false;end;
    until movfound;
  end else writeLn('unsupported file');
  if isavi then leftread:=movlen else leftread:=0;
end;

procedure appinit;
begin
  if paramcount<>3 then 
  begin
    writeLn('usage: ',paramstr(0),' avifile audfile outfile');
    halt;
  end;
  avinam:=paramstr(1);
  audnam:=paramstr(2);
  mv6nam:=paramstr(3);
  fillchar(lastbuf,sizeof(lastbuf),0);
  cnt:=0;
end;

procedure openfiles;
begin
  assign(favi,avinam);reset(favi,1);
  assign(faud,audnam);reset(faud,1);
  assign(fmv6,mv6nam);rewrite(fmv6,1);
  readdone:=false;
  findmovchunk;
end;

procedure appdone;
begin
  close(fmv6);
  close(favi);
  close(faud);
end;

procedure setpix(y,x,c:word;col,idv:integer);inline;
begin
  col:=pic[y,x,c]+col div idv;
  if col>255 then col:=255;if col<0 then col:=0;
  pic[y,x,c]:=col;
end;

procedure convertscreen;
const rgbmod:array[0..2] of byte=(11,59,30);
var 
  x,y,c,t:word;
  errcol:byte;
  qerr,
  error,
  lowerr:integer;
begin
  for y:=0 to picy-1 do
   for x:=0 to picx-1 do
   begin
     errcol:=0;lowerr:=$fffffff;
     for c:=0 to 3 do 
     begin
       error:=0;
       for t:=0 to 2 do error+=sqr(pic[y,x,t]-pal4[c,t])*rgbmod[t];
       if error<lowerr then begin lowerr:=error;errcol:=c;end;
     end;
     pic4[y,x]:=errcol;
     for c:=0 to 2 do
     begin
       qerr:=(pic[y,x,c]-pal4[errcol,c]);
 
// sierra lite
       setpix(y+0,x+1,c,qerr,2);
       setpix(y+1,x-1,c,qerr,4);
       setpix(y+1,x+0,c,qerr,4);
{
// floyd-steinberg
       setpix(y+0,x+1,c,qerr*7/16);
       setpix(y+1,x-1,c,qerr*3/16);
       setpix(y+1,x+0,c,qerr*5/16);
       setpix(y+1,x+1,c,qerr*1/16);
}
     end;
   end;
end;

procedure loadbmp;
var y:word;fok:boolean;
begin
  fok:=true;
  id:=getid;
  len:=getlen;

  dec(leftread,len+8); if leftread<1 then readdone:=true;
  if id<>'00dc' then begin fok:=false; writeLn('unknown chunk ',id);end;
  if len<>(picx*picy*3) then begin fok:=false;writeLn('frame difference: ',len,' bytes instead of ',picx*picy*3,' bytes');end;
  if fok then
  begin
    for y:=0 to (picy-1) do 
    begin
      blockread(favi,pic[y],picx*3);
    end;
  end else readdone:=true;
end;

function h(w,d:word):char;inline;
begin
  h:=char($30+((w div d) mod 10));
end;

procedure wb(b:byte);inline;begin outbuf[obp]:=b;inc(obp);end;
procedure ww(w:word);inline;begin wb(w);wb(w shr 8);end;
procedure savev6;
const
  bp:array[0..7] of byte=(128,64,32,16,8,4,2,1);
  dathdr='DATA';
var
  wc,c,cy,cx,d,g,db,de:word;
  state:byte;
  s,b:byte;
  t:dword;
//b7=pix0 .. b0=pix7
begin
  fillchar(v6buf,pagesiz*2,0);
  for c:=0 to 1 do
   for cy:=0 to picy-1 do
    for cx:=0 to chrx-1 do
    begin
      b:=0;
      for s:=0 to 7 do if pic4[cy,cx*8+s] and (c+1)=(c+1) then b:=b or bp[s];
      v6buf[c*pagesiz+cy*chrx+cx]:=b;
    end;
  c:=0;obp:=1;state:=0;wc:=0;
  fillchar(outbuf,sizeof(outbuf),0);
  while c<pagesiz+bmsiz do
  begin
    case state of
      0: // search for difference
         if v6buf[c]=lastbuf[c] then inc(c) else begin db:=c;state:=1;d:=0;end;
      1: // count indifferences
         if v6buf[c]<>lastbuf[c] then begin inc(c);inc(d);end else begin de:=c;state:=2;g:=0;end;
      2: // find X free bytes
         if v6buf[c+g]=lastbuf[c+g] then begin inc(g);if g=thres then state:=3;end else begin inc(c,g);inc(d,g);state:=1;end; 
      3: // save values and restart search
         begin inc(wc);ww(db or $e000);ww(de-db);for d:=db to (de-1) do wb(v6buf[d]);state:=0;end;
    end;
  end;
  if state=1 then begin de:=pagesiz+bmsiz;c:=de;ww(db or $e000);ww(de-db);for d:=db to (de-1) do wb(v6buf[d]);end;
  ww(0); // end of frame marker
  if obp>pagesz1 then
  begin
	obp:=1; fillchar(outbuf,sizeof(outbuf),0);
{	ww($e000);ww(bmsiz);for d:=0 to bmsiz-1 do wb(v6buf[d]);
	ww($f000);ww(bmsiz);for d:=pagesiz to pagesiz+bmsiz-1 do wb(v6buf[d]);}
	for d:=0 to pagesiz+bmsiz-1 do wb(v6buf[d]);
//	ww(0);
  end;	
  t:=(obp+511) and $fe00;
  outbuf[0]:=(t div 512)-1;
  blockwrite(fmv6,outbuf,t);
  move(v6buf,lastbuf,pagesiz*2);
end;

procedure copyaudio;
var fr:integer;
begin
  fillchar(audbuf,audsiz,0);
  blockread(faud,audbuf,audsiz,fr);
  blockwrite(fmv6,audbuf,audsiz);
end;


begin
  appinit;
  openfiles;
  repeat
    copyaudio;
    loadbmp;
    convertscreen;
    savev6;
    inc(cnt);
  until readdone;
  appdone;
end.

{
byte: size of frame in sectors
word: 
$0000: no frame
$e000: start pos for copy
word: len
}

; vim: set ts=4:
