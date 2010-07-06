#ifndef MACROS_H
#define MACROS_H


#define IRQ_VECTOR	0x00A01

#define JOY_UP_MASK     1
#define JOY_DOWN_MASK   2
#define JOY_LEFT_MASK   4
#define JOY_RIGHT_MASK  8
#define JOY_FIRE1_MASK  16
#define JOY_FIRE2_MASK  32

// vreg_vidctrl bits
#define BITMAP_MODE             0x00            // bit 0 = 0 (bitmap mode)
#define TILE_MAP_MODE           1
#define WIDE_LEFT_BORDER        2
// in bitmap mode
#define CHUNKY_PIXEL_MODE       0x80            // bit 7 = 1 (chunky pixel mode)
// in extended tilemap mode
#define DUAL_PLAY_FIELD         0x80

// vreg_window bits
#define SWITCH_TO_X_WINDOW_REGISTER   4

// vreg_ext_vidctrl bits
#define EXTENDED_TILE_MAP_MODE  1

// vreg_sprctrl bits
#define SPRITE_ENABLE                           1
#define DOUBLE_BUFFER_SPRITE_REGISTER_MODE      8

// blit_misc bits
#define BLITTER_MISC_ASCENDING_MODE             0x40

#define BLITTER_LINEDRAW_BUSY                   0x10

// sys_irq_enable bits
#define IRQ_ENABLE_MASTER                       0x80
#define IRQ_ENABLE_AUDIO                        8
#define IRQ_ENABLE_TIMER                        4
#define IRQ_ENABLE_MOUSE                        2
#define IRQ_ENABLE_KEYBOARD                     1


#define WRITE_REG(reg, value)  ( *((byte *) (reg)) = (value) )
#define READ_REG(reg, var)     ( var = *(( byte*) (reg)) )

/* define a vars (ports) in I/O space. This is SDCC specific feature.*/
sfr at SYS_MEM_SELECT           io__sys_mem_select;
sfr at SYS_KEYBOARD_DATA        io__sys_keyboard_data;
sfr at SYS_PS2_JOY_CONTROL      io__sys_ps2_joy_control;
sfr at SYS_JOY_COM_FLAGS        io__sys_joy_com_flags;
sfr at SYS_IRQ_ENABLE           io__sys_irq_enable;
sfr at SYS_CLEAR_IRQ_FLAGS      io__sys_clear_irq_flags;

/* define memory mapped I/O devices. This is SDCC specific feature.*/
//------ Graphics registers -------------------------------------------------

//#define PALETTE 		   0x0

//#define VIDEO_REGISTERS	   0x200
static volatile __at VREG_XHWS  unsigned char mm__vreg_xhws;
static volatile __at VREG_VIDCTRL  unsigned char mm__vreg_vidctrl;
static volatile __at VREG_WINDOW  unsigned char mm__vreg_window;
static volatile __at VREG_YHWS_BPLCOUNT  unsigned char mm__vreg_yhws_bplcount;
static volatile __at VREG_RASTHI  unsigned char mm__vreg_rasthi;
//#define VREG_RASTLO	   0x205
static volatile __at VREG_VIDPAGE  unsigned char mm__vreg_vidpage;
static volatile __at VREG_SPRCTRL  unsigned char mm__vreg_sprctrl;
static volatile __at MULT_WRITE  unsigned short mm__mult_write; // signed word
static volatile __at MULT_INDEX  unsigned char mm__mult_index;
//#define LINEDRAW_COLOUR	   0x20b
static volatile __at VREG_EXT_VIDCTRL  unsigned char mm__vreg_ext_vidctrl;
//#define VREG_LINECOP_LO	   0x20d
//#define VREG_LINECOP_HI	   0x20e
//#define VREG_PALETTE_CTRL	   0x20f

// blitter set-up registers
static volatile __at BLIT_SRC_LOC  unsigned short mm__blit_src_loc;
static volatile __at BLIT_DST_LOC  unsigned short mm__blit_dst_loc;
static volatile __at BLIT_SRC_MOD  unsigned char mm__blit_src_mod;
static volatile __at BLIT_DST_MOD  unsigned char mm__blit_dst_mod;
static volatile __at BLIT_HEIGHT  unsigned char mm__blit_height;
static volatile __at BLIT_WIDTH  unsigned char mm__blit_width;
static volatile __at BLIT_MISC  unsigned char mm__blit_misc;
static volatile __at BLIT_SRC_MSB  unsigned char mm__blit_src_msb;
static volatile __at BLIT_DST_MSB  unsigned char mm__blit_dst_msb;

static volatile __at VREG_READ  unsigned char mm__vreg_read;  // video status read register
static volatile __at MULT_READ  unsigned short mm__mult_read;
static volatile __at MULT_TABLE  unsigned short mm__mult_table;

static volatile __at BITPLANE0A_LOC   unsigned char mm__bitplane0a_loc__byte0;
static volatile __at BITPLANE0A_LOC+1 unsigned char mm__bitplane0a_loc__byte1;
static volatile __at BITPLANE0A_LOC+2 unsigned char mm__bitplane0a_loc__byte2;
static volatile __at BITPLANE0A_LOC+3 unsigned char mm__bitplane0a_loc__byte3;

// Set system memory page at address 0x8000-0xFFFF
// (logic system memory pages are 0-14)
#define SET_SYSTEM_PAGE(page)     io__sys_mem_select = (page + 1)          // add 1 to page (convert to hardware page number)

#define SET_SPRITE_PAGE(page)     mm__vreg_vidpage = ((page) | 0x80)       // set bit 7 - Set Sprite Page
#define PAGE_IN_SPRITE_RAM()      (io__sys_mem_select |= 0x80)
#define PAGE_OUT_SPRITE_RAM()     (io__sys_mem_select &= (~0x80))


#define SET_VIDEO_PAGE(page)      mm__vreg_vidpage = (page)                // bit 7 is clear - Set Video Page
#define PAGE_IN_VIDEO_RAM()      (io__sys_mem_select |= 0x40)
#define PAGE_OUT_VIDEO_RAM()     (io__sys_mem_select &= (~0x40))

// misc macros
#define GET_WORD_9TH_BIT(v)     ( ((word)v>>8) & 1 )
// RGB to 12bit V6Z80P palette value
#define RGB2WORD(r,g,b)         (   (word) ((r/16<<8)+(g/16<<4)+(b/16))   )

#endif /* MACROS_H */
