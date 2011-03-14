void _assert_v6(char *expr, const char *filename, unsigned int linenumber)
{
        BYTE myBuf[32];
        linenumber; filename;


        // page out video and sprite ram 
        // to be sure FLOS address space is paged in
        PAGE_OUT_VIDEO_RAM();
        PAGE_OUT_SPRITE_RAM();

	FLOS_FlosDisplay();
        //FLOS_ClearScreen();
        FLOS_SetPen(0x17);
	FLOS_PrintStringLFCR("ASSERT_V6 failed: ");
	FLOS_PrintString("line: "); _uitoa(linenumber, myBuf, 10); FLOS_PrintString(myBuf);
        FLOS_PrintString("  ");
        FLOS_PrintString("file: "); FLOS_PrintStringLFCR(filename);
	FLOS_PrintStringLFCR(expr);



//	FLOS_PrintStringLFCR("Assert(%s) failed at line %u in file %s.\n",
//		expr, linenumber, filename);
//	while(1);
        FLOS_ExitToFLOS();



}
