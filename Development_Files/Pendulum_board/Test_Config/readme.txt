
The FPGA configs here are modified versions of OSCA
for the V6+1.1(b) in which the serial port logic has
been removed to make room for a 32bit counter which
is clocked by either GCLK1, GCLK2, or GCLK3.

When the FPGA is configured with one of the
modified versions of OSCA, its counter can be
read with the FLOS program GCLKFREQ.FLX 
 

