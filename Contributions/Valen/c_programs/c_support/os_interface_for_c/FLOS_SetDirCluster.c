#include "include_all.h"

void FLOS_SetDirCluster(WORD cluster)
{
    word *pWord;

    SET_WORD_IN_DATA_AREA(I_DATA,   cluster);
    CALL_FLOS_CODE(KJT_SET_DIR_CLUSTER);

}
