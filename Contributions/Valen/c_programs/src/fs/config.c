#define CONFIG_FILE_MAX_SIZE            1024
#define CONFIG_FILE_DIR                 "COMMANDS"
#define CONFIG_FILE_MAX_EXT_ACTIONS     64

byte config_file_buffer[CONFIG_FILE_MAX_SIZE];

struct {
    word config_file_buffer_size;
    BOOL is_in_ext_section;

    const char* user_action_based_on_ext[CONFIG_FILE_MAX_EXT_ACTIONS][2];
    byte user_action_based_on_ext_index;

} config;

// prototypes
void add_user_action_based_on_ext(const char *pExt, const char *pAction);

//void parse_config_file(void)
void replace_new_lines_with_zero_bytes(void)
{
    word i;
    for(i=0; i<CONFIG_FILE_MAX_SIZE; i++) {
        if(config_file_buffer[i] == 0) {
            config.config_file_buffer_size = i;
            return;
        }
        if(config_file_buffer[i] == (byte)'\x0D' || config_file_buffer[i] == (byte)'\x0A') {
            config_file_buffer[i] = 0;
        }

    }

}


void iterate_trough_extensions(void)
{

    byte *pEqualChar;
    byte *p = config_file_buffer;
    config.is_in_ext_section = FALSE;

    while(p < p + config.config_file_buffer_size) {
        if(strcmp(p, "[Ext]") == 0) config.is_in_ext_section = TRUE;
        p += strlen(p);
        if(*p == 0) p++;
        if(*p == 0) p++;
        if(*p == 0) return;
        if(config.is_in_ext_section) {
//            FLOS_PrintStringLFCR(p);
            pEqualChar = strstr(p, "=");
            if(pEqualChar) {
                *pEqualChar = 0;        // split string to two, e.g "BMP=SHOWBMP" to "BMP",0,"SHOWBMP"
                add_user_action_based_on_ext(p, p+strlen(p)+1);
                //FLOS_PrintStringLFCR(p);
                //FLOS_PrintStringLFCR(p+strlen(p)+1);
            }
        }
    }

}


void add_user_action_based_on_ext(const char *pExt, const char *pAction)
{

    config.user_action_based_on_ext[config.user_action_based_on_ext_index][0] = pExt;
    config.user_action_based_on_ext[config.user_action_based_on_ext_index][1] = pAction;

    if(config.user_action_based_on_ext_index+1 < CONFIG_FILE_MAX_EXT_ACTIONS)
        config.user_action_based_on_ext_index++;
}


const char* get_user_action_based_on_ext(const char *pExt)
{
    byte i;
    word r;
    for(i=0; i<CONFIG_FILE_MAX_EXT_ACTIONS; i++) {
        r = strcmp(config.user_action_based_on_ext[i][0], pExt);
        if(r==0) return config.user_action_based_on_ext[i][1];

    }
    return NULL;
}   



void init_config_file_parser(void) {
    config.user_action_based_on_ext_index = 0;

    memset(config.user_action_based_on_ext, 0 , sizeof(config.user_action_based_on_ext));
}


// ---------
// public
BOOL load_config_file(void)
{
    init_config_file_parser();

    FLOS_RootDir();
    if(!FLOS_ChangeDir(CONFIG_FILE_DIR))
    {
        FLOS_PrintStringLFCR("Failed to cahange dir to /" CONFIG_FILE_DIR);
        return FALSE;
    }

    memset(config_file_buffer, 0, CONFIG_FILE_MAX_SIZE);
    if(!load_file_to_buffer("FS.CFG", 0, config_file_buffer, CONFIG_FILE_MAX_SIZE, 0))
        return FALSE;


   replace_new_lines_with_zero_bytes();
   iterate_trough_extensions();


    return TRUE;
}

