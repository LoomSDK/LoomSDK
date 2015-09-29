#include "loom/common/platform/platform.h"

/* include/jemalloc/jemalloc_defs.h.  Generated from jemalloc_defs.h.in by configure.  */
/* Defined if __attribute__((...)) syntax is supported. */
#ifndef _MSC_VER
    #define JEMALLOC_HAVE_ATTR 
#endif

/* Defined if alloc_size attribute is supported. */
/* #undef JEMALLOC_HAVE_ATTR_ALLOC_SIZE */

/* Defined if format(gnu_printf, ...) attribute is supported. */
/* #undef JEMALLOC_HAVE_ATTR_FORMAT_GNU_PRINTF */

/* Defined if format(printf, ...) attribute is supported. */
/* #undef JEMALLOC_HAVE_ATTR_FORMAT_PRINTF */

/*
 * Define overrides for non-standard allocator-related functions if they are
 * present on the system.
 */
/* #undef JEMALLOC_OVERRIDE_MEMALIGN */
/* #undef JEMALLOC_OVERRIDE_VALLOC */

/*
 * At least Linux omits the "const" in:
 *
 *   size_t malloc_usable_size(const void *ptr);
 *
 * Match the operating system's prototype.
 */
#define JEMALLOC_USABLE_SIZE_CONST const

/*
 * If defined, specify throw() for the public function prototypes when compiling
 * with C++.  The only justification for this is to match the prototypes that
 * glibc defines.
 */
/* #undef JEMALLOC_USE_CXX_THROW */

/* sizeof(void *) == 2^LG_SIZEOF_PTR. */

#if LOOM_PLATFORM_64BIT
#define LG_SIZEOF_PTR 3
#else
#define LG_SIZEOF_PTR 2
#endif
