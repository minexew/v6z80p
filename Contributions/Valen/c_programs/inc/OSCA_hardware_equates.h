
//----- OSCA v659 Main system hardware control / peripheral ports -------------

#define SYS_MEM_SELECT	   0x00
#define SYS_IRQ_PS2_FLAGS 	   0x01
#define SYS_IRQ_ENABLE	   0x01
#define SYS_KEYBOARD_DATA	   0x02
#define SYS_CLEAR_IRQ_FLAGS	   0x02
#define SYS_MOUSE_DATA	   0x03
#define SYS_PS2_JOY_CONTROL	   0x03
#define SYS_SERIAL_PORT	   0x04
#define SYS_JOY_COM_FLAGS	   0x05
#define SYS_SDCARD_CTRL1	   0x05
#define SYS_SDCARD_CTRL2	   0x06
#define SYS_TIMER		   0x07
#define SYS_VREG_READ	   0x07
#define SYS_AUDIO_ENABLE	   0x08
#define SYS_AUDIO_FLAGS	   0x08
#define SYS_HW_FLAGS	   0x09
#define SYS_HW_SETTINGS	   0x09
#define SYS_SPI_PORT	   0x0a
#define SYS_ALT_WRITE_PAGE	   0x0b
#define SYS_BAUD_RATE	   0x0c
#define SYS_PIC_COMMS	   0x0d
#define SYS_EEPROM_BYTE	   0x0d
#define SYS_IO_PINS	   0x0e
#define SYS_IO_DIR	   0x0f

#define SYS_LOW_PAGE	   0x20
#define SYS_VRAM_LOCATION	   0x21
#define SYS_AUDIO_PANNING	   0x22

//---- Sound system ports ---------------------------------------------------

#define AUDCHAN0_LOC	   0x10
#define AUDCHAN0_LEN	   0x11
#define AUDCHAN0_PER	   0x12
#define AUDCHAN0_VOL	   0x13

#define AUDCHAN1_LOC	   0x14
#define AUDCHAN1_LEN	   0x15
#define AUDCHAN1_PER	   0x16
#define AUDCHAN1_VOL	   0x17

#define AUDCHAN2_LOC	   0x18
#define AUDCHAN2_LEN	   0x19
#define AUDCHAN2_PER	   0x1a
#define AUDCHAN2_VOL	   0x1b

#define AUDCHAN3_LOC	   0x1c
#define AUDCHAN3_LEN	   0x1d
#define AUDCHAN3_PER	   0x1e
#define AUDCHAN3_VOL	   0x1f


//------ Graphics registers -------------------------------------------------

#define PALETTE 		   0x0		

#define VIDEO_REGISTERS	   0x200
#define VREG_XHWS		   0x200		// video control registers
#define VREG_VIDCTRL	   0x201
#define VREG_WINDOW	   0x202
#define VREG_YHWS_BPLCOUNT	   0x203
#define VREG_RASTHI	   0x204
#define VREG_RASTLO	   0x205
#define VREG_VIDPAGE	   0x206
#define VREG_SPRCTRL	   0x207
#define MULT_WRITE	   0x208		// signed word
#define MULT_INDEX	   0x20a		// byte
#define LINEDRAW_COLOUR	   0x20b
#define VREG_EXT_VIDCTRL	   0x20c
#define VREG_LINECOP_LO	   0x20d
#define VREG_LINECOP_HI	   0x20e
#define VREG_PALETTE_CTRL	   0x20f

#define BLIT_SRC_LOC	   0x210		// blitter set-up registers
#define BLIT_DST_LOC	   0x212
#define BLIT_SRC_MOD	   0x214
#define BLIT_DST_MOD	   0x215
#define BLIT_HEIGHT	   0x216
#define BLIT_WIDTH	   0x217
#define BLIT_MISC		   0x218
#define BLIT_SRC_MSB	   0x219
#define BLIT_DST_MSB	   0x21a

#define LINEDRAW_REG0 	   0x220		// line draw set-up registers (words)
#define LINEDRAW_REG1 	   0x222
#define LINEDRAW_REG2 	   0x224
#define LINEDRAW_REG3 	   0x226
#define LINEDRAW_REG4 	   0x228		
#define LINEDRAW_REG5 	   0x22a
#define LINEDRAW_REG6 	   0x22c
#define LINEDRAW_REG7 	   0x22e
#define LINEDRAW_LUT0 	   0x230		// line draw look-up table (words)
#define LINEDRAW_LUT1 	   0x232
#define LINEDRAW_LUT2 	   0x234
#define LINEDRAW_LUT3 	   0x236
#define LINEDRAW_LUT4 	   0x238		
#define LINEDRAW_LUT5 	   0x23a
#define LINEDRAW_LUT6 	   0x23c
#define LINEDRAW_LUT7 	   0x23e

#define BITPLANE0A_LOC	   0x240
#define BITPLANE1A_LOC	   0x244
#define BITPLANE2A_LOC	   0x248
#define BITPLANE3A_LOC	   0x24c
#define BITPLANE4A_LOC	   0x250
#define BITPLANE5A_LOC	   0x254
#define BITPLANE6A_LOC	   0x258
#define BITPLANE7A_LOC	   0x25c
#define BITPLANE0B_LOC	   0x260
#define BITPLANE1B_LOC	   0x264
#define BITPLANE2B_LOC	   0x268
#define BITPLANE3B_LOC	   0x26c
#define BITPLANE4B_LOC	   0x270
#define BITPLANE5B_LOC	   0x274
#define BITPLANE6B_LOC	   0x278
#define BITPLANE7B_LOC	   0x27c
#define BITPLANE_RESET	   0x243
#define BITPLANE_MODULO	   0x247


#define SPRITE_REGISTERS	   0x400		// sprite coord/def/size registers
#define SPR_REGISTERS	   0x400		// alternate name

#define MULT_TABLE	   0x600		// maths table (256 signed words)

#define VREG_READ		   0x700		// video status read register
#define MULT_READ		   0x704		// signed word


//--------------------------------------------------------------------------

#define SPRITE_BASE	   0x1000		// 4kb when banked in
#define VIDEO_BASE	   0x2000		// 8kb when banked in

//--------------------------------------------------------------------------
