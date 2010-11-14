 FLOS_FILE* open(const char *name, int flags, ...)
{
    static FLOS_FILE theFile;

    flags;
    if(FLOS_FindFile(&theFile, name)) {

        return &theFile;
    }
    else 
        return -1;  // FLOS error
}


DWORD read(handle_t f, void *data, DWORD size)
{
  BOOL r;

  f;
  FLOS_SetLoadLength(size);
  r = FLOS_ForceLoad( data, 0 );

//  if(!r && FLOS_GetLastError() == FLOS_FILESYSTEM_ERR__BEYOND_EOF)
//      return 0;     // beyond EOF
  if(!r)
      return -1;    // FLOS error

  return size;  // success
}
