#include "include_all.h"

FLOS_VOLUME_INFO* FLOS_GetVolumeInfo(void)
{
    word w;
    BYTE b1, b2;
    static FLOS_VOLUME_INFO volume_info;

    CALL_FLOS_CODE(KJT_GET_VOLUME_INFO);

    w   = *PTRTO_I_DATA(I_DATA,   word);
    b1  = *PTRTO_I_DATA(I_DATA+2, byte);
    b2  = *PTRTO_I_DATA(I_DATA+3, byte);
    
    volume_info.mount_list             = (BYTE*) w;
    volume_info.number_volumes_mounted = b1;
    volume_info.current_volume         = b2;
    
    return &volume_info;
}
