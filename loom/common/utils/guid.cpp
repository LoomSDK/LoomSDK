//
//  guid.cpp
//  LoomEngine
//
//  Created by Dave Fishel on 12/23/14.
//
//

#include <loom/common/platform/platform.h>

#include "guid.h"
#include <string.h>

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#include <rpc.h>
#elif LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#include <stdio.h>
#else
#include <uuid/uuid.h>
#endif

extern "C"
{
    void loom_generate_guid(loom_guid_t out_guid)
    {
        memset(out_guid, 0, sizeof(loom_guid_t));
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#pragma comment(lib, "rpcrt4.lib")
        UUID uuid;
        UuidCreate(&uuid);
        
        char* tempStr = NULL;
        if (UuidToStringA(&uuid, (RPC_CSTR*)&tempStr) == RPC_S_OK)
        {
            strncpy(out_guid, tempStr, strlen(tempStr));
            RpcStringFreeA((RPC_CSTR*)&tempStr);
        }
        else
        {
            out_guid = "00000000-0000-0000-0000-000000000000";
        }
#elif LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        FILE* f = fopen("/proc/sys/kernel/random/uuid", "r");
	fread(out_guid, sizeof(char), LOOM_GUID_SIZE, f);
	fclose(f);
#else
        uuid_t uuid;
        uuid_generate(uuid);
        uuid_unparse_lower(uuid, out_guid);
#endif
    }
};
