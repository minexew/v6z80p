/* Footer begin */


#undef malloc
#undef free

void* my_malloc(size_t i)
{
	void *pMem = NULL;
	
	pMem = malloc(i);
	if(!pMem) {
		DEBUG_PRINT("my_malloc() FAILED mem allocation. Size: %u, ptr: %u \n", i, (unsigned int) pMem);
		Host_ExitToOS(1);
	}
		
	DEBUG_PRINT("my_malloc() mem allocated. Size: %u, ptr: %u \n", i, (unsigned int) pMem);
		
	return pMem;
	
}
void my_free(void* memblock)
{
	return free(memblock);
}





//#include "pool.c"



/* Footer end */
