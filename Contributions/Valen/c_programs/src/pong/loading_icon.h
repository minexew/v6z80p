#ifndef LOADING_ICON_H
#define LOADING_ICON_H

typedef struct {
    BOOL isLoaded;
    ushort palette[256];
} LoadingIcon;

LoadingIcon loadingIcon;

BOOL LoadingIcon_LoadSprites(void);
void LoadingIcon_Enable(BOOL isEnable);
BOOL LoadingIcon_Load(void);

#endif /* LOADING_ICON_H */
