handle_t open(const char *name, int flags, ...)
{
    FLOS_FILE theFile;

    flags;
    if(FLOS_FindFile(&theFile, name))
        return 0;
    else 
        return -1;
}


DWORD read(handle_t f, void *data, DWORD size)
{
  BOOL r;

  f;
  FLOS_SetLoadLength(size);
  r = FLOS_ForceLoad( data, 0 );

  if(!r)
      return -1; // was error
  else
      return size;
}
