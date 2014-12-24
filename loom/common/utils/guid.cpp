//
//  guid.cpp
//  LoomEngine
//
//  Created by Dave Fishel on 12/23/14.
//
//

#include "guid.h"
#include <string.h>

#ifdef WIN32
#include <rpc.h>
#else
#include <uuid/uuid.h>
#endif

extern "C"
{
    void loom_generate_guid(loom_guid_t out_guid)
    {
        memset(out_guid, 0, sizeof(loom_guid_t));
#ifdef WIN32
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
#else
        uuid_t uuid;
        uuid_generate(uuid);
        uuid_unparse_lower(uuid, out_guid);
#endif
    }
};