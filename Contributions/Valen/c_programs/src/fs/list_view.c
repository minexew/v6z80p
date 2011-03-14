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



// Redraw ListView window, with (visible) items and selection marker
void ListView_Update(ListView* this) {
    word i;
    byte k;
    byte x = this->x, y = this->y;
    byte width = this->width, height = this->height;
    const char* p;
    byte strl;

    ListView_check_visible_part(this);
    p = this->firstVisibleStr;

    // loop for visible rows
    i=this->firstVisibleIndex;
    while( i < (this->firstVisibleIndex+height) &&  i < this->numItems ) {
        // erase select chars
        Display_SetCursorPos(x, y);
        Display_PrintString(" ");
        Display_SetCursorPos(x+width-1, y);
        Display_PrintString(" ");

        // if current item is selected, set pen for selected item
        (i == this->selectedIndex) ? Display_SetPen(PEN_SELECTED) : Display_SetPen(PEN_DEFAULT);
         // if .exe file
        if(strstr(p, ".EXE") != NULL && i != this->selectedIndex) Display_SetPen(PEN_FILE_EXE);
            

        // print item
        Display_SetCursorPos(x+1, y);
        Display_PrintStringLFCR(p);

        strl = strlen(p);
        // erase last chars in row
        if(strl < this->width-2) {
            Display_SetCursorPos(x+1+strl, y);
            for(k=0; k<(this->width-2-strl); k++) Display_PrintString(" ");
        }

        // reset color
        Display_SetPen(PEN_DEFAULT);

        p = p + strlen(p) + 1;
/*
        // if current item is selected, print selection marker
        if(i == this->selectedIndex) {
//            FLOS_SetPen(0xa0);
            FLOS_SetCursorPos(x, y);
            FLOS_PrintString(">"); 
            FLOS_SetCursorPos(x+width-1, y);
            FLOS_PrintString("<"); 
//            FLOS_SetPen(0x07);

        }
*/

        y++;
        i++;
    }//while

    ListView_update_own_textfield(this);
}

word ListView_GetNumItems(ListView* this) {
    return this->numItems;
}

word ListView_GetSelectedIndex(ListView* this)
{
    return this->selectedIndex;
}
void ListView_SetSelectedIndex(ListView* this, word selectedIndex)
{
    this->selectedIndex = selectedIndex;
}

void ListView_Init(ListView* this)
{
    this->firstVisibleIndex = 0;
    this->firstVisibleStr = this->strArr;
}

char* ListView_GetItem(ListView* this, word itemIndex)
{
    return ListView_get_item_by_index(this, itemIndex);
}


// helpers
char* ListView_GetSelectedItem(ListView* this)
{

    char *p;
    word selectedIndex;

    selectedIndex = ListView_GetSelectedIndex(this);
    p = ListView_GetItem(this, selectedIndex);
    return p;
}

// --- private funcs ------
void ListView_check_visible_part(ListView* this)
{
//    word i;
    char* p;

    // down scroll check
    if( this->selectedIndex >= (this->firstVisibleIndex+this->height) ) {
        this->firstVisibleIndex = this->selectedIndex - this->height + 1;
    }
    // up scroll check
    if( this->selectedIndex < this->firstVisibleIndex ) 
        this->firstVisibleIndex = this->selectedIndex;


    p = ListView_get_item_by_index(this, this->firstVisibleIndex);
    this->firstVisibleStr = p;    

}

// calc str ptr for new firstVisibleIndex (slow, if many indices in list and visibleIndex is near end of list)
char* ListView_get_item_by_index(ListView* this, word itemIndex)
{
    word i;
    const char* p;

    p = this->strArr;
    for(i=0; i<itemIndex; i++)
        p = p + strlen(p) + 1;

    return p;
}

void ListView_update_own_textfield(ListView* this)
{
    word numitems;

    // pos to one line below listview window
    Display_SetCursorPos(this->x, this->y+this->height);
    Display_PrintString("---> ");

    numitems = ListView_GetNumItems(this); 
    _uitoa(numitems, buffer, 10);
    Display_PrintString(buffer);

    Display_PrintString(" entries");

}
