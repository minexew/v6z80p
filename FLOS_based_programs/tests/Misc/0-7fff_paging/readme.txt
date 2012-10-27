These programs test the new RAM paging modes in OSCA v658+

Specifically..

1. The ability to set the 32KB page of system RAm that appears at Z80 $0000-$7fff

2. The ability to page sysRAM $00000-$07fff into Z80 $8000-$FFFF

3. Reading of port $20 (sys_low_page) (OSCA 659)
 