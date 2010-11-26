// "wb" mode
#define OPEN_MODE_FLAGS__WRITE_BINARY (O_WRONLY | O_CREAT | O_TRUNC | O_BINARY)
// "rb" mode
#define OPEN_MODE_FLAGS__READ_BINARY  (O_RDONLY | O_BINARY)

FLOS_FILE* open(const char *name, int flags)
{
    static FLOS_FILE theFile;



    if( (flags & OPEN_MODE_FLAGS__WRITE_BINARY) == OPEN_MODE_FLAGS__WRITE_BINARY ) {
        // "wb" open mode
        // Delete file, if it exist.
        FLOS_EraseFile(name);
        // Create new file
        if(FLOS_CreateFile(name)) {
            return (FLOS_FILE*)1;   // return some not NULL value
        }
        else
            return NULL;  // FLOS error
    }


    if( (flags & OPEN_MODE_FLAGS__READ_BINARY) == OPEN_MODE_FLAGS__READ_BINARY ) {
        // "rb" open mode
        if(FLOS_FindFile(&theFile, name)) {
//            sprintf(myTestString, "name:%s", name); FLOS_PrintStringLFCR(myTestString);
            return &theFile;
        }
        else
            return NULL;  // FLOS error
    }


    return NULL;    // error, incorrect open flags
}


DWORD read(handle_t f, void *data, DWORD size, BYTE system_bank)
{
  BOOL r;

  f;
  FLOS_SetLoadLength(size);
  r = FLOS_ForceLoad( data, system_bank );

//  if(!r && FLOS_GetLastError() == FLOS_FILESYSTEM_ERR__BEYOND_EOF)
//      return 0;     // beyond EOF
  if(!r)
      return -1;    // FLOS error

  return size;  // success
}

DWORD write(handle_t f, const void *data, DWORD size, BYTE system_bank, const char *pFilename)
{
  BOOL r;

  f;
  // Appends new data to an existing file
  r = FLOS_WriteBytesToFile(pFilename, data, system_bank, size);
  if(!r) return -1;    // FLOS error

  return size;  // success
}

loff_t lseek(handle_t f, loff_t offset, int origin)
{
    f; origin;
    FLOS_SetFilePointer(offset);
    return 0;  // success

}


