// Setup display window size
void VideoMode_SetupDisplayWindowSize(byte window_x_start,  byte window_x_stop,
			              byte window_y_start,  byte window_y_stop);
void VideoMode_InitTilemapMode(byte additionalBits_vidctrl, byte additionalBits_ext_vidctrl);
void TileMap_8x8_FillPlayfield(BYTE playfieldNumber, WORD offset, WORD fillSize, WORD tileNumber);
