#include <Intrz80.h>


// sfr mm__vreg_someport      = 0x12;

/* define a vars (ports) in I/O space. This is SDCC specific feature.*/
sfr io__sys_mem_select      = SYS_MEM_SELECT;
sfr io__sys_keyboard_data   = SYS_KEYBOARD_DATA;

// __sfr __at SYS_PS2_JOY_CONTROL      io__sys_ps2_joy_control;
// __sfr __at SYS_JOY_COM_FLAGS        io__sys_joy_com_flags;
sfr io__sys_irq_enable      = SYS_IRQ_ENABLE;


sfr io__sys_clear_irq_flags = SYS_CLEAR_IRQ_FLAGS;
sfr io__sys_irq_ps2_flags   = SYS_IRQ_PS2_FLAGS;


// __sfr __at SYS_MOUSE_DATA           io__sys_mouse_data;

// __sfr __at SYS_TIMER                io__sys_timer;
// __sfr __at SYS_ALT_WRITE_PAGE       io__sys_alt_write_page;
// __sfr __at SYS_LOW_PAGE             io__sys_low_page; 


/* define memory mapped I/O devices. This is SDCC specific feature.*/
//------ Graphics registers -------------------------------------------------

//#define PALETTE          0x0

//#define VIDEO_REGISTERS      0x200

    #define mm__vreg_xhws    ( *((unsigned char*) VREG_XHWS) )
    #define mm__vreg_vidctrl ( *((unsigned char*) VREG_VIDCTRL) )
    #define mm__vreg_window  ( *((unsigned char*) VREG_WINDOW) )
    #define mm__vreg_yhws_bplcount  ( *((unsigned char*) VREG_YHWS_BPLCOUNT) )
    #define mm__vreg_rasthi  ( *((unsigned char*) VREG_RASTHI) )
//#define VREG_RASTLO      0x205
    #define mm__vreg_vidpage ( *((unsigned char*) VREG_VIDPAGE) )
    #define mm__vreg_sprctrl ( *((unsigned char*) VREG_SPRCTRL) )
// static volatile __at MULT_WRITE  unsigned short mm__mult_write; // signed word
// static volatile __at MULT_INDEX  unsigned char mm__mult_index;
//#define LINEDRAW_COLOUR      0x20b
    #define mm__vreg_ext_vidctrl  ( *((unsigned char*) VREG_EXT_VIDCTRL) )
//#define VREG_LINECOP_LO      0x20d
//#define VREG_LINECOP_HI      0x20e
//#define VREG_PALETTE_CTRL    0x20f

// blitter set-up registers
// static volatile __at BLIT_SRC_LOC  unsigned short mm__blit_src_loc;
// static volatile __at BLIT_DST_LOC  unsigned short mm__blit_dst_loc;
// static volatile __at BLIT_SRC_MOD  unsigned char mm__blit_src_mod;
// static volatile __at BLIT_DST_MOD  unsigned char mm__blit_dst_mod;
// static volatile __at BLIT_HEIGHT  unsigned char mm__blit_height;
// static volatile __at BLIT_WIDTH  unsigned char mm__blit_width;
// static volatile __at BLIT_MISC  unsigned char mm__blit_misc;
// static volatile __at BLIT_SRC_MSB  unsigned char mm__blit_src_msb;
// static volatile __at BLIT_DST_MSB  unsigned char mm__blit_dst_msb;

// static volatile __at VREG_READ  unsigned char mm__vreg_read;  // video status read register
// static volatile __at MULT_READ  unsigned short mm__mult_read;
// static volatile __at MULT_TABLE  unsigned short mm__mult_table;

// static volatile __at BITPLANE0A_LOC   unsigned char mm__bitplane0a_loc__byte0;
// static volatile __at BITPLANE0A_LOC+1 unsigned char mm__bitplane0a_loc__byte1;
// static volatile __at BITPLANE0A_LOC+2 unsigned char mm__bitplane0a_loc__byte2;
// static volatile __at BITPLANE0A_LOC+3 unsigned char mm__bitplane0a_loc__byte3;

// 
#define EI()    enable_interrupt();
#define DI()    disable_interrupt();