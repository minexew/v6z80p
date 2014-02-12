#ifndef POOL_H
#define POOL_H

void* pool_malloc(unsigned int size, const char *typeName);
void  pool_free(void* p);


#endif /* POOL_H */
