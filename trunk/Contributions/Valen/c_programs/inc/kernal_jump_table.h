//--------------------------
//Kernal jump table for FLOS
//--------------------------

#define OS_START 0x1000

#define KJT_PRINT_STRING		   OS_START+0x13
#define KJT_CLEAR_SCREEN		   OS_START+0x16
#define KJT_PAGE_IN_VIDEO		   OS_START+0x19
#define KJT_PAGE_OUT_VIDEO		   OS_START+0x1c
#define KJT_WAIT_VRT		   OS_START+0x1f
#define KJT_KEYBOARD_IRQ_CODE	   OS_START+0x22
#define KJT_HEX_BYTE_TO_ASCII	   OS_START+0x25
#define KJT_ASCII_TO_HEX_WORD	   OS_START+0x28
#define KJT_DONT_STORE_REGISTERS	   OS_START+0x2b
#define KJT_GET_INPUT_STRING	   OS_START+0x2e

#define KJT_CHECK_DISK_PQFS		   OS_START+0x31
#define KJT_CHANGE_DRIVE		   OS_START+0x34
#define KJT_CHECK_DISK_AVAILABLE	   OS_START+0x37
#define KJT_GET_DRIVE		   OS_START+0x3a
#define KJT_FORMAT		   OS_START+0x3d
#define KJT_MAKE_DIR		   OS_START+0x40
#define KJT_CHANGE_DIR		   OS_START+0x43
#define KJT_PARENT_DIR		   OS_START+0x46
#define KJT_ROOT_DIR		   OS_START+0x49
#define KJT_DELETE_DIR		   OS_START+0x4c
#define KJT_FIND_FILE		   OS_START+0x4f
#define KJT_LOAD_FILE		   OS_START+0x52
#define KJT_SAVE_FILE		   OS_START+0x55
#define KJT_ERASE_FILE		   OS_START+0x58
#define KJT_GET_TOTAL_SECTORS	   OS_START+0x5b

#define KJT_WAIT_KEY_PRESS		   OS_START+0x5e
#define KJT_GET_KEY		   OS_START+0x61

#define KJT_FORCEBANK		   OS_START+0x64
#define KJT_FORCE_BANK		   OS_START+0x64
#define KJT_GETBANK		   OS_START+0x67
#define KJT_GET_BANK		   OS_START+0x67
#define KJT_CREATE_FILE		   OS_START+0x6a
#define KJT_INCBANK		   OS_START+0x6d
#define KJT_INC_BANK		   OS_START+0x6d
#define KJT_COMPARE_STRINGS		   OS_START+0x70
#define KJT_WRITE_BYTES_TO_FILE	   OS_START+0x73
#define KJT_BCHL_MEMFILL		   OS_START+0x76

#define KJT_FORCE_LOAD		   OS_START+0x79
#define KJT_SET_FILE_POINTER	   OS_START+0x7c
#define KJT_SET_LOAD_LENGTH		   OS_START+0x7f
#define KJT_SERIAL_RECEIVE_HEADER	   OS_START+0x82
#define KJT_SERIAL_RECEIVE_FILE	   OS_START+0x85
#define KJT_SERIAL_SEND_FILE	   OS_START+0x88
#define KJT_ENABLE_POINTER		   OS_START+0x8b	// changed from "kjt_init_mouse" in flos v559
#define KJT_GET_MOUSE_POSITION	   OS_START+0x8e
#define KJT_GET_VERSION		   OS_START+0x91
#define KJT_SET_CURSOR_POSITION	   OS_START+0x94
#define KJT_SERIAL_TX_BYTE		   OS_START+0x97
#define KJT_SERIAL_RX_BYTE		   OS_START+0x9a

#define KJT_DIR_LIST_FIRST_ENTRY	   OS_START+0x9d
#define KJT_DIR_LIST_GET_ENTRY	   OS_START+0xa0
#define KJT_DIR_LIST_NEXT_ENTRY	   OS_START+0xa3
#define KJT_GET_CURSOR_POSITION	   OS_START+0xa6
#define KJT_READ_SECTOR		   OS_START+0xa9
#define KJT_WRITE_SECTOR		   OS_START+0xac
#define KJT_SET_SECTOR_LBA		   OS_START+0xaf

#define KJT_PLOT_CHAR		   OS_START+0xb2 
#define KJT_SET_PEN		   OS_START+0xb5 
#define KJT_BACKGROUND_COLOURS	   OS_START+0xb8
#define KJT_DRAW_CURSOR		   OS_START+0xbb
#define KJT_GET_PEN		   OS_START+0xbe
#define KJT_SCROLL_UP		   OS_START+0xc1
#define KJT_FLOS_DISPLAY		   OS_START+0xc4
#define KJT_GET_DIR_NAME		   OS_START+0xc7
#define KJT_GET_KEY_MOD_FLAGS	   OS_START+0xca
#define KJT_GET_DISPLAY_SIZE	   OS_START+0xcd   // added in flos v559
#define KJT_TIMER_WAIT		   OS_START+0xd0	 // added in flos v559
#define KJT_GET_CHARMAP_ADDR_XY	   OS_START+0xd3	 // added in flos v559

#define KJT_STORE_DIR_POSITION	   OS_START+0xd6	// added in flos v560
#define KJT_RESTORE_DIR_POSITION	   OS_START+0xd9	// added in flos v560