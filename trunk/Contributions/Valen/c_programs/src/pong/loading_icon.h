#ifndef LOADING_ICON_H
#define LOADING_ICON_H

typedef struct {
    BOOL isLoaded;
    ushort palette[256];
} LoadingIcon;

LoadingIcon loadingIcon;

#endif /* LOADING_ICON_H */
