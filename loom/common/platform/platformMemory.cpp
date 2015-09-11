
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
        return info.resident_size;

    return 0;

}

#elif LOOM_PLATFORM == LOOM_PLATFORM_WIN32

#include "windows.h"
#pragma comment( lib, "psapi.lib" )
#include "psapi.h"

unsigned int platform_getProcessMemory()
{
    PROCESS_MEMORY_COUNTERS_EX pmc;
    GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc));
    SIZE_T virtualMemUsedByMe = pmc.PrivateUsage;
    return (unsigned int)virtualMemUsedByMe;
}

#else

//TODO: LOOM-1842
unsigned int platform_getProcessMemory() 
{
    return 0;
}

#endif
