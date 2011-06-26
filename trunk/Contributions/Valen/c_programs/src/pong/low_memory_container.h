#ifndef LOW_MEMORY_CONTAINER_H
#define LOW_MEMORY_CONTAINER_H

#include <v6z80p_types.h>

#include <OSCA_hardware_equates.h>
//#include <scan_codes.h>
#include <macros.h>
#include <macros_specific.h>


#include "sound_fx/sound_fx.h"


//EXTERN_LOW_MEMORY_CONTAINER 
void Sound_NewFx(byte fx_number);
void asmproxy__Sound_NewFx(void);
void Sound_PlayFx(void);
void Sound_AddFxDesc(byte fx_number,  SOUND_FX* p);

void Music_InitTracker(void);
void Music_PlayTracker(void);
void Music_UpdateSoundHardware(void);
// base = word address in audio RAM
void Music_SetForceSampleBase(word base);



#endif /* LOW_MEMORY_CONTAINER_H */
