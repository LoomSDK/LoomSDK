#define	JEMALLOC_MB_C_
#include "jemalloc/internal/jemalloc_internal.h"

// Gets rid of liker warning LNK4221
#ifdef _MSC_VER
void mb_dummy() {}
#endif
