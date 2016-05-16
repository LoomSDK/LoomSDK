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


#include "loom/common/utils/utString.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platform.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include "loom/common/platform/platformFileAndroid.h"
#include "loom/common/platform/platformAndroidJni.h"

#include <jni.h>
#include <cstddef>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fts.h>
#include <limits.h>

extern "C" {
const char *platform_getWritablePath()
{
    static utString path;

    if (path.size())
    {
        return path.c_str();
    }

    path = LoomJni::getWritablePath();

    return path.c_str();
}

const char *platform_getSettingsPath()
{
    static utString path;

    if (path.size())
    {
        return path.c_str();
    }

    path = LoomJni::getSettingsPath();

    return path.c_str();
}


int ftw(const char *path, int (*fn)(const char *, const struct stat *, int), int nfds)
{
    /* LINTED */
    char *const paths[2] = { (char *)__UNCONST(path), NULL };
    FTSENT      *cur;
    FTS         *ftsp;
    int         fnflag, error, sverrno;

    /* XXX - nfds is currently unused */
    if ((nfds < 1) || (nfds > OPEN_MAX))
    {
        errno = EINVAL;
        return(-1);
    }

    ftsp = fts_open(paths, FTS_COMFOLLOW | FTS_NOCHDIR, NULL);
    if (ftsp == NULL)
    {
        return(-1);
    }
    error = 0;
    while ((cur = fts_read(ftsp)) != NULL)
    {
        switch (cur->fts_info)
        {
        case FTS_D:
            fnflag = FTW_D;
            break;

        case FTS_DNR:
            fnflag = FTW_DNR;
            break;

        case FTS_DP:
            /* we only visit in preorder */
            continue;

        case FTS_F:
        case FTS_DEFAULT:
            fnflag = FTW_F;
            break;

        case FTS_NS:
        case FTS_NSOK:
        case FTS_SLNONE:
            fnflag = FTW_NS;
            break;

        case FTS_SL:
            fnflag = FTW_SL;
            break;

        case FTS_DC:
            errno = ELOOP;

        /* FALLTHROUGH */
        default:
            error = -1;
            goto done;
        }
        error = fn(cur->fts_path, cur->fts_statp, fnflag);
        if (error != 0)
        {
            break;
        }
    }
done:
    sverrno = errno;
    if ((fts_close(ftsp) != 0) && (error == 0))
    {
        error = -1;
    }
    else
    {
        errno = sverrno;
    }
    return(error);
}
}
#endif
