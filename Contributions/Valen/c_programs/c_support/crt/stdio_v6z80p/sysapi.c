 FLOS_FILE* open(const char *name, int flags)
{
    static FLOS_FILE theFile;

    //sprintf(myTestString, "name:%s", name); FLOS_PrintStringLFCR(myTestString);
    if(flags & O_BINARY) {
        // "rb" open mode
        if(FLOS_FindFile(&theFile, name)) {
            return &theFile;
        }
        else
            return NULL;  // FLOS error
    }

    if(flags & (O_WRONLY | O_CREAT | O_TRUNC | O_BINARY)) {
        // "wb" open mode
        if(FLOS_CreateFile(name)) {
            return (FLOS_FILE*)1;   // return some not NULL value
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


