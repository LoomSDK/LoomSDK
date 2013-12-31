
#include "loom/common/platform/platform.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_OSX || LOOM_PLATFORM == LOOM_PLATFORM_IOS

#include <mach/mach.h>

unsigned int platform_getProcessMemory() 
{
    struct task_basic_info info;    
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
       TASK_BASIC_INFO,
       (task_info_t)&info,
       &size);

    if( kerr == KERN_SUCCESS ) 
        return info.resident_size

    return 0;

}

#else

//TODO: LOOM-1842
unsigned int platform_getProcessMemory() 
{
    return 0;
}

#endif
