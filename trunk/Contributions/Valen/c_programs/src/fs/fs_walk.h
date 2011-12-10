#ifndef FS_WALK_H
#define FS_WALK_H

#define FILENAME_LEN    8+1+3                // FILENAME + dot + EXT


void fill_ListView_by_entries_from_current_dir(void);
void clear_area(byte x, byte y, byte width, byte height);

#endif /* FS_WALK_H */
