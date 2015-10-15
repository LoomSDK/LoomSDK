#ifndef stdbool_h
#define stdbool_h

#ifndef __cplusplus

#include <wtypes.h>

/* MSVC doesn't define _Bool or bool in C, but does have BOOL */
/* Note this doesn't pass autoconf's test because (bool) 0.5 != true */
/* VS2013 (_MSC_VER 1800) already defines these */
#if defined(_MSC_VER) && _MSC_VER < 1800
typedef BOOL _Bool;
#define bool _Bool
#endif

typedef int bool;
#define true 1
#define false 0

#define __bool_true_false_are_defined 1

#endif

#endif /* stdbool_h */
