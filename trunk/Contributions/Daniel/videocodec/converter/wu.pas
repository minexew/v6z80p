const
  MAXCOLOR=256;
  RED=2;
  GREEN=1;
  BLUE=0;
  bp=32;
  bofr=(bp+1)*(bp+1);
  bofg=(bp+1);
  bs=3;

type
  box=record r0, r1, g0,  g1,  b0,  b1, vol:integer; end;

{* Histogram is in elements 1..HISTSIZE along each axis,
 * element 0 is for base or marginal value
 * NB: these must start out 0!
 *}

type
  cubereal=array[0..bp,0..bp,0..bp] of real;
  cubeint=array[0..bp,0..bp,0..bp] of longint;

var
  lut:array[0..MAXCOLOR-1,0..2] of byte;

var
  m2:cubereal; wt,mr,mg,mb:cubeint;
  hm2:cubereal; hwt,hmr,hmg,hmb:cubeint;
  k:integer;
  cube:array[0..MAXCOLOR-1] of box;
  next:integer;
  i,weight:longint;
  vv:array[0..maxcolor-1] of real;
  temp:real;
  table:array[0..255] of integer;

procedure resethist;
begin
  for i:=0 to 255 do table[i]:=i*i;
  fillchar(hmr,sizeof(hmr),0);
  fillchar(hmg,sizeof(hmg),0);
  fillchar(hmb,sizeof(hmb),0);
  fillchar(hm2,sizeof(hm2),0);
  fillchar(hwt,sizeof(hwt),0);
end;

procedure Hist3d(var pic:tpic);
{* build 3-D color histogram of counts, r/g/b, c^2 *}
var
  r, g, b,
  inr, ing, inb:byte;
  i:longint;
  px,py:word;

begin    
  px:=0;py:=0;
  for i:=0 to picsiz-1 do
  begin
    r := pic[py,px,2] and $f0;
    g := pic[py,px,1] and $f0;
    b := pic[py,px,0] and $f0;
    inc(px);if px=picx then begin px:=0;inc(py);end;
    inr:=(r shr bs)+1; 
    ing:=(g shr bs)+1; 
    inb:=(b shr bs)+1; 
    inc(hwt[inr,ing,inb]);
    hmr[inr,ing,inb] += r;
    hmg[inr,ing,inb] += g;
    hmb[inr,ing,inb] += b;
    hm2[inr,ing,inb] += (table[r]+table[g]+table[b]);
  end;
end;

{* At conclusion of the histogram step, we can interpret
 *   wt[r][g][b] = sum over voxel of P(c)
 *   mr[r][g][b] = sum over voxel of r*P(c)  ,  similarly for mg, mb
 *   m2[r][g][b] = sum over voxel of c^2*P(c)
 * Actually each of these should be divided by 'size' to give the usual
 * interpretation of P() as ranging from 0 to 1, but we needn't do that here.
 *}

{* We now convert histogram into moments so that we can rapidly calculate
 * the sums of the above quantities over any desired box.
 *}

procedure M3d; {* compute cumulative moments. *}
var
  i,r,g,b:byte;
  linet, line_r, line_g, line_b:longint;
  area, area_r, area_g, area_b:array[0..bp] of longint;
  line2:real;
  area2:array[0..bp] of real;

begin
  for r:=1 to bp do 
  begin
    for i:=0 to bp do
    begin 
      area2[i]:=0;area[i]:=0;area_r[i]:=0;area_g[i]:=0;area_b[i]:=0;
    end;
    for g:=1 to bp do
    begin
      line2:=0; linet:=0;line_r:=0; line_g:=0; line_b:=0; 
      for b:=1 to bp do
      begin
        linet     += wt[r,g,b];
        line_r    += mr[r,g,b]; 
        line_g    += mg[r,g,b]; 
        line_b    += mb[r,g,b];
        line2     += m2[r,g,b];
        area[b]   += linet;
        area_r[b] += line_r;
        area_g[b] += line_g;
        area_b[b] += line_b;
        area2[b]  += line2;
        wt[r,g,b] := wt[r-1,g,b] + area[b];
        mr[r,g,b] := mr[r-1,g,b] + area_r[b];
        mg[r,g,b] := mg[r-1,g,b] + area_g[b];
        mb[r,g,b] := mb[r-1,g,b] + area_b[b];
        m2[r,g,b] := m2[r-1,g,b] + area2[b];
      end;
    end;
  end;
end;


function Vol(var cube:box;var mmt:cubeint):longint;
{* Compute sum over a box of any given statistic *}
begin
  vol:=(mmt[cube.r1][cube.g1][cube.b1] 
       -mmt[cube.r1][cube.g1][cube.b0]
       -mmt[cube.r1][cube.g0][cube.b1]
       +mmt[cube.r1][cube.g0][cube.b0]
       -mmt[cube.r0][cube.g1][cube.b1]
       +mmt[cube.r0][cube.g1][cube.b0]
       +mmt[cube.r0][cube.g0][cube.b1]
       -mmt[cube.r0][cube.g0][cube.b0] );
end;

{* The next two routines allow a slightly more efficient calculation
 * of Vol() for a proposed subbox of a given box.  The sum of Top()
 * and Bottom() is the Vol() of a subbox split in the given direction
 * and with the specified new upper bound.
 *}

function Bottom(var cube:box;dir:byte;var mmt:cubeint):longint;
{* Compute part of Vol(cube, mmt) that doesn't depend on r1, g1, or b1 *}
{* (depending on dir) *}
begin
  case dir of
  RED:   Bottom:=(
        -mmt[cube.r0][cube.g1][cube.b1]
        +mmt[cube.r0][cube.g1][cube.b0]
        +mmt[cube.r0][cube.g0][cube.b1]
        -mmt[cube.r0][cube.g0][cube.b0] );
  GREEN: Bottom:=( 
        -mmt[cube.r1][cube.g0][cube.b1]
        +mmt[cube.r1][cube.g0][cube.b0]
        +mmt[cube.r0][cube.g0][cube.b1]
        -mmt[cube.r0][cube.g0][cube.b0] );
  BLUE:  Bottom:=(
        -mmt[cube.r1][cube.g1][cube.b0]
        +mmt[cube.r1][cube.g0][cube.b0]
        +mmt[cube.r0][cube.g1][cube.b0]
        -mmt[cube.r0][cube.g0][cube.b0] );
  else bottom:=0;
  end;
end;

function Top(var cube:box;dir:byte;ipos:integer;var mmt:cubeint):longint;
{* Compute remainder of Vol(cube, mmt), substituting pos for *}
{* r1, g1, or b1 (depending on dir) *}
begin
  case dir of
  RED:
      Top:=( mmt[ipos][cube.g1][cube.b1] 
       -mmt[ipos][cube.g1][cube.b0]
       -mmt[ipos][cube.g0][cube.b1]
       +mmt[ipos][cube.g0][cube.b0] );
  GREEN:
      Top:=( mmt[cube.r1][ipos][cube.b1] 
       -mmt[cube.r1][ipos][cube.b0]
       -mmt[cube.r0][ipos][cube.b1]
       +mmt[cube.r0][ipos][cube.b0] );
  BLUE:
      Top:=( mmt[cube.r1][cube.g1][ipos]
       -mmt[cube.r1][cube.g0][ipos]
       -mmt[cube.r0][cube.g1][ipos]
       +mmt[cube.r0][cube.g0][ipos] );
  else top:=0;
  end;
end;

function fVar(var cube:box):real;
{* Compute the weighted variance of a box *}
{* NB: as with the raw statistics, this is really the variance * size *}
var dr, dg, db, xx:real;
begin
  dr:= Vol(cube, mr); 
  dg:= Vol(cube, mg); 
  db:= Vol(cube, mb);
  xx:=  m2[cube.r1][cube.g1][cube.b1] 
 -m2[cube.r1][cube.g1][cube.b0]
 -m2[cube.r1][cube.g0][cube.b1]
 +m2[cube.r1][cube.g0][cube.b0]
 -m2[cube.r0][cube.g1][cube.b1]
 +m2[cube.r0][cube.g1][cube.b0]
 +m2[cube.r0][cube.g0][cube.b1]
 -m2[cube.r0][cube.g0][cube.b0];

  fvar:=( xx - (dr*dr+dg*dg+db*db)/Vol(cube,wt) );    
end;

{* We want to minimize the sum of the variances of two subboxes.
 * The sum(c^2) terms can be ignored since their sum over both subboxes
 * is the same (the sum for the whole box) no matter where we split.
 * The remaining terms have a minus sign in the variance formula,
 * so we drop the minus sign and MAXIMIZE the sum of the two terms.
 *}

function Maximize(var cube:box;dir:byte;first,last:integer;var cut:integer;whole_r,whole_g,whole_b,whole_w:longint):real;
var
  half_r, half_g, half_b, half_w,
  base_r, base_g, base_b, base_w:longint;
  i:integer;
  temp,max:real;

begin
  base_r := Bottom(cube, dir, mr);
  base_g := Bottom(cube, dir, mg);
  base_b := Bottom(cube, dir, mb);
  base_w := Bottom(cube, dir, wt);
  max := 0.0;
  cut := -1;
  for i:=first to last-1 do
  begin
    half_r := base_r + Top(cube, dir, i, mr);
    half_g := base_g + Top(cube, dir, i, mg);
    half_b := base_b + Top(cube, dir, i, mb);
    half_w := base_w + Top(cube, dir, i, wt);
    {* now half_x is sum over lower half of box, if split at i *}
    if (half_w = 0) then
    begin      {* subbox could be empty of pixels! *}
      continue;             {* never split into an empty box *}
    end else temp :=(half_r*half_r + half_g*half_g + half_b*half_b)/half_w;
    half_r := whole_r - half_r;
    half_g := whole_g - half_g;
    half_b := whole_b - half_b;
    half_w := whole_w - half_w;
    if (half_w = 0) then
    begin      {* subbox could be empty of pixels! *}
      continue;             {* never split into an empty box *}
    end else temp += (half_r*half_r + half_g*half_g + half_b*half_b)/half_w;
    if (temp > max) then begin max:=temp; cut:=i;end
  end;
  Maximize:=max;
end;

function Cut(var set1:box;var set2:box):boolean;
var
  dir:byte;
  cutr, cutg, cutb:integer;
  maxr, maxg, maxb:real;
  whole_r, whole_g, whole_b, whole_w:longint;
begin
  whole_r := Vol(set1, mr);
  whole_g := Vol(set1, mg);
  whole_b := Vol(set1, mb);
  whole_w := Vol(set1, wt);

  maxr := Maximize(set1, RED, set1.r0+1, set1.r1, cutr, whole_r, whole_g, whole_b, whole_w);
  maxg := Maximize(set1, GREEN, set1.g0+1, set1.g1, cutg, whole_r, whole_g, whole_b, whole_w);
  maxb := Maximize(set1, BLUE, set1.b0+1, set1.b1, cutb, whole_r, whole_g, whole_b, whole_w);

  if ( (maxr>=maxg) and (maxr>=maxb) ) then
  begin
    dir := RED;
    if (cutr < 0) then exit(false); {* can't split the box *}
  end else if ( (maxg>=maxr) and (maxg>=maxb) ) then
    dir := GREEN
  else
    dir := BLUE; 

  set2.r1 := set1.r1;
  set2.g1 := set1.g1;
  set2.b1 := set1.b1;

  case dir of
  RED:
    begin
      set1.r1 := cutr;
      set2.r0 := set1.r1;
      set2.g0 := set1.g0;
      set2.b0 := set1.b0;
    end;
  GREEN:
    begin
      set1.g1 := cutg;
      set2.g0 := set1.g1;
      set2.r0 := set1.r0;
      set2.b0 := set1.b0;
    end;
  BLUE:
    begin
      set1.b1 := cutb;
      set2.b0 := set1.b1;
      set2.r0 := set1.r0;
      set2.g0 := set1.g0;
    end;
  end;
  set1.vol:=(set1.r1-set1.r0)*(set1.g1-set1.g0)*(set1.b1-set1.b0);
  set2.vol:=(set2.r1-set2.r0)*(set2.g1-set2.g0)*(set2.b1-set2.b0);
  cut:=true;
end;

procedure quantize;

begin
  {* input R,G,B components into Ir, Ig, Ib;
     set size to width*height *}
  move(hm2,m2,sizeof(hm2));
  move(hwt,wt,sizeof(hwt));
  move(hmr,mr,sizeof(hmr));
  move(hmg,mg,sizeof(hmg));
  move(hmb,mb,sizeof(hmb));

  M3d;

  cube[0].r0 := 0;cube[0].g0 := 0;cube[0].b0 := 0;
  cube[0].r1 :=bp;cube[0].g1 :=bp;cube[0].b1 :=bp;
  next := 0;
  
  i:=1;
  while i<colornum do
  begin
    if (Cut(cube[next], cube[i])) then
    begin
      {* volume test ensures we won't try to cut one-cell box *}
      if (cube[next].vol>1) then vv[next]:= fVar(cube[next]) else vv[next]:=0.0;
      if (cube[i].vol>1) then vv[i]:=fvar(cube[i]) else vv[i]:=0.0;
    end else 
    begin
      vv[next] := 0.0;   {* don't try to split this box again *}
      dec(i);              {* didn't create box i *}
    end;
    next := 0; temp := vv[0];
    for k:=1 to i do
     if (vv[k] > temp) then
     begin
       temp := vv[k]; next := k;
     end;

    if (temp <= 0.0) then
    begin
      break;
    end;
    inc(i);
  end;

  {* the space for array m2 can be freed now *}
  for k:=0 to (colornum-1) do 
  begin
    weight := Vol(cube[k], wt);
    if (weight)>0 then
    begin
      lut[k,2] := Vol(cube[k], mr) div weight;
      lut[k,1] := Vol(cube[k], mg) div weight;
      lut[k,0] := Vol(cube[k], mb) div weight;
    end
    else
    begin
      lut[k,2]:=0;lut[k,1]:=0;lut[k,0]:=0;   
    end;
  end;
  
  {* output lut_r, lut_g, lut_b as color look-up table contents,
     Qadd as the quantized image (array of table addresses). *}
 
end;

