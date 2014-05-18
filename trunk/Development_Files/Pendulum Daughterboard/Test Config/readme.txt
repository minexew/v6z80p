
The FPGA configs here are modified versions of OSCA
for the V6+1.1(b) in which the serial port logic has
been removed to make room for a 32bit counter which
is clocked by either GCLK1, GCLK2, or GCLK3. The
counter can be read with the FLOS program
GCLKTEST.FLX (counts ticks in 10 seconds). 

