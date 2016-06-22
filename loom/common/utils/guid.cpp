/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#include <loom/common/platform/platform.h>

#include "guid.h"
#include <string.h>

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#include <rpc.h>
#elif LOOM_PLATFORM == LOOM_PLATFORM_ANDROID || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#include <stdio.h>
#else
#include <uuid/uuid.h>
#endif

const char* LOOM_GUID_EMPTY = "00000000-0000-0000-0000-000000000000";

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
            out_guid = const_cast<char*>(LOOM_GUID_EMPTY);
        }
#elif LOOM_PLATFORM == LOOM_PLATFORM_ANDROID || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
        FILE* f = fopen("/proc/sys/kernel/random/uuid", "r");
        size_t num = fread(out_guid, sizeof(char), LOOM_GUID_SIZE - 1, f);
        fclose(f);

        if (num != LOOM_GUID_SIZE - 1)
        {
            out_guid = const_cast<char*>(LOOM_GUID_EMPTY);
        }
#else
        uuid_t uuid;
        uuid_generate(uuid);
        uuid_unparse_lower(uuid, out_guid);
#endif
    }

    int loom_is_guid(const loom_guid_t guid)
    {
        size_t i = 0;
        size_t p = 0;

        if (strlen(guid) != LOOM_GUID_SIZE - 1)
            return 0;

        // Probably not be best way to do this, but should be quick...
        for (i = 0; i < 8; i++, p++)
        {
            if (!((guid[p] >= 'a' && guid[p] <= 'z') ||
                  (guid[p] >= 'A' && guid[p] <= 'Z') ||
                  (guid[p] >= '0' && guid[p] <= '9')))
            {
                return 0;
            }
        }

        if (guid[p] != '-')
            return 0;
        p++;

        for (i = 0; i < 4; i++, p++)
        {
            if (!((guid[p] >= 'a' && guid[p] <= 'z') ||
                  (guid[p] >= 'A' && guid[p] <= 'Z') ||
                  (guid[p] >= '0' && guid[p] <= '9')))
            {
                return 0;
            }
        }

        if (guid[p] != '-')
            return 0;
        p++;

        for (i = 0; i < 4; i++, p++)
        {
            if (!((guid[p] >= 'a' && guid[p] <= 'z') ||
                  (guid[p] >= 'A' && guid[p] <= 'Z') ||
                  (guid[p] >= '0' && guid[p] <= '9')))
            {
                return 0;
            }
        }

        if (guid[p] != '-')
            return 0;
        p++;

        for (i = 0; i < 4; i++, p++)
        {
            if (!((guid[p] >= 'a' && guid[p] <= 'z') ||
                  (guid[p] >= 'A' && guid[p] <= 'Z') ||
                  (guid[p] >= '0' && guid[p] <= '9')))
            {
                return 0;
            }
        }

        if (guid[p] != '-')
            return 0;
        p++;

        for (i = 0; i < 8; i++, p++)
        {
            if (!((guid[p] >= 'a' && guid[p] <= 'z') ||
                  (guid[p] >= 'A' && guid[p] <= 'Z') ||
                  (guid[p] >= '0' && guid[p] <= '9')))
            {
                return 0;
            }
        }

        return 1;
    }
};
