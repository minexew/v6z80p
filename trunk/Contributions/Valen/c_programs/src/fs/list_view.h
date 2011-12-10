#ifndef LIST_VIEW_H
#define LIST_VIEW_H

#define PEN_DEFAULT     0x07
#define PEN_SELECTED    0xa9
#define PEN_FILE_EXE    0x05


typedef struct  {
   const char* strArr;          // array of strings
   word        numItems;        // how many items in strArr
   word        selectedIndex;   // index of selected item
   byte        x, y;
   byte        width, height;

// private
   word        firstVisibleIndex;
   const char* firstVisibleStr;
} ListView;


// --- public funcs ------
void ListView_Init(ListView* this);
void ListView_Update(ListView* this);
word ListView_GetNumItems(ListView* this);
word ListView_GetSelectedIndex(ListView* this);
void ListView_SetSelectedIndex(ListView* this, word selectedIndex);

char* ListView_GetItem(ListView* this, word itemIndex);
// helpers
char* ListView_GetSelectedItem(ListView* this);

// --- private funcs ------
void  ListView_check_visible_part(ListView* this);
char* ListView_get_item_by_index(ListView* this, word itemIndex);

void ListView_update_own_textfield(ListView* this);


#endif /* LIST_VIEW_H */
