#define MAX_OBJ_POOL_1     1
#define MAX_OBJ_POOL_2     1
#define MAX_OBJ_POOL_3     5
#define MAX_OBJ_POOL_4     5

// For this pool,
// we know exactly maximum of objects (memory chunks), which will be allocated in a program.
// To allocate a memory chunk, the program should call to func pool_allocate().
static unsigned char pool_1[MAX_OBJ_POOL_1][ sizeof(Startup) ];
static unsigned char pool_1_is_used[MAX_OBJ_POOL_1];

static unsigned char pool_2[MAX_OBJ_POOL_2][ sizeof(Engine) ];
static unsigned char pool_2_is_used[MAX_OBJ_POOL_2];

static unsigned char pool_3[MAX_OBJ_POOL_3][ sizeof(GameObj) ];
static unsigned char pool_3_is_used[MAX_OBJ_POOL_3];

static unsigned char pool_4[MAX_OBJ_POOL_4][ sizeof(MovingGameObj) ];
static unsigned char pool_4_is_used[MAX_OBJ_POOL_4];

    
    
    
    
#define DO_POOL(number)                                 \
    if( size == sizeof(pool_##number[0]) ) {           \
        ptr = pool_find_free_mem_chunk( (unsigned char *)pool_##number, size, MAX_OBJ_POOL_##number, pool_##number##_is_used, "pool_" #number);       \
        if(ptr) return ptr;                             \
    }

#define ZERO_POOL(number)                                                   \
    memset(pool_##number,           0, sizeof(pool_##number));             \
    memset(pool_##number##_is_used, 0, sizeof(pool_##number##_is_used));

#define DO_FREE_POOL(number)                         \
    for(i=0; i<MAX_OBJ_POOL_##number; i++) {        \
        if(p == pool_##number[i]) {                 \
            pool_##number##_is_used[i] = 0;         \
            printf("pool_: mem free. Size: %u, ptr: %u \n", 0, (unsigned int) p ) ;     \
        }                                           \
    }
    
static void* pool_find_free_mem_chunk(unsigned char *p, unsigned short itemSize, unsigned short itemCount, unsigned char *pIsUsed,
                                        unsigned char *strBufName)
{
    unsigned short i;
    unsigned char *p_result;
    
    for(i=0; i<itemCount; i++) {        
        if(pIsUsed[i] == 0) {         
            pIsUsed[i] = 1;           
            
            p_result = p + i * itemSize;
            printf("%s: mem allocated. Size: %u, ptr: %u \n", strBufName, itemSize, (unsigned int) p_result ) ;
            return p_result;           
        }                                    
    }
    return NULL;    
}
        


// Allocate memory area from a pool of pre-reserved memory areas.
void* pool_malloc(unsigned int size)
{

            
    static unsigned char isNeedPoolInit = 1;
    
    //unsigned short i;
    void* ptr;
    // init pool area with zero
    if(isNeedPoolInit) {
        isNeedPoolInit = 0;
        ZERO_POOL(1) ;
        ZERO_POOL(2) ;
        ZERO_POOL(3) ;
        ZERO_POOL(4) ;
        
    }

    
    
    //printf("SIZE: %u \n", sizeof(pool_1[0])  /*sizeof(pool_1)*/ ); exit(1);
    //printf("addr: %u \n", (unsigned int)   (pool_1[1] - pool_1[0]) );
    


    DO_POOL(1);
    DO_POOL(2);
    DO_POOL(3);
    DO_POOL(4);
    
    printf("pool: FAILED to alloc size: %u \n", size);
    //exit(1);
    return NULL;
}


void pool_free(void* p)
{
    unsigned short i;

    DO_FREE_POOL(1);
    DO_FREE_POOL(2);
    DO_FREE_POOL(3);
    DO_FREE_POOL(4);
}
