#ifndef FS_WALK_H
#define FS_WALK_H

#ifndef EXTERN_FS_WALK
    #define EXTERN_FS_WALK extern
#endif


#define FILENAME_LEN    8+1+3                // FILENAME + dot + EXT

#define DIRBUF_LEN     1024*2

EXTERN_FS_WALK BYTE* tmp1;


void fill_ListView_by_entries_from_current_dir(void);
void clear_area(byte x, byte y, byte width, byte height);




#endif /* FS_WALK_H */
