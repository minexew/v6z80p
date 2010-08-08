// Setup display window size
void VideoMode_SetupDisplayWindowSize(byte window_x_start,  byte window_x_stop,
			              byte window_y_start,  byte window_y_stop)
{

    // use y window pos reg
    mm__vreg_rasthi = 0;
    mm__vreg_window = (window_y_start<<4)|window_y_stop;
    // Switch to x window pos reg.
    mm__vreg_rasthi = SWITCH_TO_X_WINDOW_REGISTER;
    mm__vreg_window = (window_x_start<<4)|window_x_stop;
}
