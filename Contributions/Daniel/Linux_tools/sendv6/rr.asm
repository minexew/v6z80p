; rr-receive and run
; receives file from serial port without timeout
; jumps to 05000h after receiving

  include kernal_jump_table.asm
  org  05000h
  ld   hl,msg
  call kjt_print_string
  ld   hl,cmdline
  ld   a,255
  call kjt_serial_receive_header
  ld   b,0
  ld   hl,05000h
  push hl
  jp   kjt_serial_receive_file
cmdline
  db '*',#0  
msg
  db 'Awaiting File ..',#0
