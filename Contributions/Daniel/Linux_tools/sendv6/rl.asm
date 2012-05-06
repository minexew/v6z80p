; rl-receive and run - looped version
; receives file from serial port without timeout
; uses kjt_set_commander to enable rr-loop
; jumps to 05000h after receiving

  include OSCA_hardware_equates.asm
  include kernal_jump_table.asm
  org  05000h
  ld   hl,emptyline
  call kjt_set_commander
  in   a,(sys_keyboard_data)
  cp   76h
  ret  z
  ld   hl,rlline
  call kjt_set_commander
  ld   hl,cmdline
  ld   a,255
  call kjt_serial_receive_header
  ld   b,0
  ld   hl,05000h
  push hl
  jp   kjt_serial_receive_file
cmdline
  db '*'
emptyline
  db #0  
rlline
  db 'rl',#0
