BOOL Utils_Check_FLOS_Version(word req_version)
{
    word os_version_word, hw_version_word;

    FLOS_GetVersion(&os_version_word, &hw_version_word);
    if(os_version_word < req_version)
        return FALSE;


    return TRUE;
}
