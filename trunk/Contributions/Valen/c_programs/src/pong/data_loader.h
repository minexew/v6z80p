#ifndef DATA_LOADER_H
#define DATA_LOADER_H

#include "game_state.h"

// struct for generic tile file loading
typedef struct {
        const char* pFilenameTiles;
        word  vramAddrTiles;            // in 100h chunks
} LoadTilesDescription;

// struct for generic file loading
typedef struct {
        const char* pFilename;
        DWORD dw1;                  // generic param

        BYTE  typeOfFile;           // 1 - sprites
} LoadFileDescription;

BOOL DataLoader_LoadData(GameState state, GameState prev_state);

#endif /* DATA_LOADER_H */
