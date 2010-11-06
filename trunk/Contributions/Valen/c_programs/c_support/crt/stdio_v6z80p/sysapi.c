handle_t open(const char *name, int flags, ...)
{
    FLOS_FILE theFile;

    flags;
    if(FLOS_FindFile(&theFile, name))
        return 0;
    else 
        return -1;
}
