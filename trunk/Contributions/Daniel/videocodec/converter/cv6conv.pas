{$mode delphi}
uses sysutils;

const
  thres=4; // search threshold - too low and decompressor uses too much cpu - too high and reading uses too much cpu
  colornum=255;
  screenx=320;
  screeny=200;
  picx=80;
  picy=100;
  audsiz=1024;
  bmsiz=picx*picy;
  picsiz=bmsiz;
  pagesiz=(bmsiz+511) and $fe00;
  pagesz1=pagesiz-512;
  screensize=screenx*screeny;
  screenvx=screenx shr 1;
  screenvy=screeny shr 1;

type
  tid=array[0..3] of char;
  tpic=array[0..picy,0..picx,0..2] of byte;

var
  movfound,isavi:boolean;
  avinam,audnam,mv6nam:string;
  audbuf:array[0..audsiz-1] of byte;
  outbuf:array[0..65535] of byte;
  lastbuf:array[0..(pagesiz-1)] of byte;
  v6buf:array[0..(pagesiz-1)] of byte;
  pic:tpic;
  leftread,movlen:integer;
  favi,fmv6,faud:file;
  readdone:boolean;
  cnt:dword;obp:word;
  movbeg,len:dword;id,sid:tid;
  pal,yuv:array[0..255,0..2] of byte;

{$i wu}
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
		  movbeg:=filepos(favi);
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
  fillchar(pal,sizeof(pal),0);
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

procedure rgb2yuv(r,g,b:byte;var y,cb,cr:byte);inline;
begin
  Y :=trunc( 0.257*R+0.504*G+0.098*B+ 16);
  Cb:=trunc(-0.148*R-0.291*G+0.439*B+128);
  Cr:=trunc( 0.439*R-0.368*G-0.071*B+128);
end;

procedure setpix(y,x,c:word;col,idv:integer);inline;
begin
  col:=pic[y,x,c]+col div idv;
  if col>255 then col:=255;if col<0 then col:=0;
  pic[y,x,c]:=col;
end;

procedure convertscreen;
var 
  x,y,c:word;
  y0,u0,v0:byte; //y=16..235; cb/cr=16..240
  errcol:byte;
  error,
  lowerr:dword;
begin
  for y:=0 to picy-1 do
   for x:=0 to picx-1 do
   begin
     errcol:=0;lowerr:=$fffffff;
     rgb2yuv(pic[y,x,2],pic[y,x,1],pic[y,x,0],y0,u0,v0);
     for c:=0 to colornum do 
     begin
       //error:=0;for t:=0 to 2 do error+=sqr(pic[y,x,t]-pal[c,t])*rgbmod[t];
	   error:=4*(sqr(y0-yuv[c,0]))+sqr(u0-yuv[c,1])+sqr(v0-yuv[c,2]);
       if error<lowerr then begin lowerr:=error;errcol:=c;end;
     end;
     v6buf[y*picx+x]:=errcol;
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
var
  wc,c,d,g,db,de:word;
  state:byte;
  t:dword;
//b7=pix0 .. b0=pix7
begin
  c:=0;obp:=1;state:=0;wc:=0;
  fillchar(outbuf,sizeof(outbuf),0);
  while c<bmsiz do
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
  if state=1 then begin de:=bmsiz;c:=de;ww(db or $e000);ww(de-db);for d:=db to (de-1) do wb(v6buf[d]);end;
  ww(0); 
  if obp>pagesz1 then
  begin
	obp:=1; fillchar(outbuf,sizeof(outbuf),0);
	for d:=0 to bmsiz-1 do wb(v6buf[d]);
  end;	
  t:=(obp+511) and $fe00;
  outbuf[0]:=(t div 512)-1;
  blockwrite(fmv6,outbuf,t);
  move(v6buf,lastbuf,pagesiz);
end;

function getv6(b,g,r:byte):word;
var res:word; // 0RGB
begin
  res:=(b shr 4) or (g and $f0) or ((r and $f0) shl 4);
  getv6:=res;
end;

procedure copypal;
var 
  x,c:byte;
  b:array[0..255] of word;
begin
  fillchar(pal,sizeof(pal),0);
  for x:=0 to colornum-1 do
   for c:=0 to 2 do pal[x+1,c]:=(lut[x,c] shr 4)*$10;
  for x:=0 to 255 do b[x]:=getv6(pal[x,0],pal[x,1],pal[x,2]);
  for x:=0 to 255 do rgb2yuv(pal[x,2],pal[x,1],pal[x,0],yuv[x,0],yuv[x,1],yuv[x,2]);
  b[0]:=781; // sample period
  blockwrite(fmv6,b,sizeof(b));
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
  resethist;
  repeat
    loadbmp;
	hist3d(pic);
  until readdone;
  quantize;
  copypal;
  readdone:=false;leftread:=movlen;seek(favi,movbeg);
  repeat
    copyaudio;
    loadbmp;
//	copylut;
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
