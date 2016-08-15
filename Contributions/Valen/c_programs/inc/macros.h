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
// ---- in bitmap mode
#define CHUNKY_PIXEL_MODE       0x80            // bit 7 = 1 (chunky pixel mode)
// ---- in extended tilemap mode
#define DUAL_PLAY_FIELD         0x80
// (bit 3, of vidctrl)
#define TILE_SIZE_8x8           8
#define TILE_SIZE_16x16         0


// vreg_window bits
#define SWITCH_TO_X_WINDOW_REGISTER   4

// vreg_ext_vidctrl bits
#define EXTENDED_TILE_MAP_MODE  1

// vreg_sprctrl bits
#define SPRITE_ENABLE                           1
#define DOUBLE_BUFFER_SPRITE_REGISTER_MODE      8
#define MATTE_MODE_ENABLE                       0x20

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

#if defined(SDCC) || defined(__SDCC)
#include <mem_and_io_sdcc.h>
#endif

#ifdef __IAR_SYSTEMS_ICC__
#include <mem_and_io_iar.h>
#endif

// Set system memory page at address 0x8000-0xFFFF
// (logic system memory pages are 0-14)
#define SET_SYSTEM_PAGE(page)     io__sys_mem_select = (page + 1)          // add 1 to page (convert to hardware page number)

#define SET_SYSTEM_LOW_PAGE(page) io__sys_low_page = (page)



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

// tilemaps video page (tilemaps start at VRAM 0x70000)
#define TILEMAPS_VIDEO_PAGE                (0x70000/0x2000)

#endif /* MACROS_H */
