#ifndef USER_ACTIONS_H
#define USER_ACTIONS_H

BOOL enter_pressed(void);
BOOL f4_pressed(void);
BOOL f3_pressed(void);
BOOL f1_pressed(void);
BOOL do_action_based_on_file_extension(const char* filename);

BOOL delete_dir_entry(void);

#endif /* USER_ACTIONS_H */
