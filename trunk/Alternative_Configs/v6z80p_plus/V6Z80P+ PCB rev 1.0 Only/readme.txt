
This is an ultra-basic project demonstrates the Z80 running at 3.5MHz with
a modified V1.0 V6Z80P+ PCB. The FPGA uses the 14MHz clock from the pin
header connected to GCLK3, there is a switch to inhibit the main 16MHz
oscillator to the 74HCT08 gate. When this main clock is inhibited (pulled
high) the alternate clock comes from the FPGA (pin 75).

Code:

The Z80 just counts upwards on a port and a bit from the count is
routed to pin B of the V6Z80P+'s expansion pins (in order to flash an
LED when connected)