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

#include "loom/script/compiler/lsCompilerLog.h"

#include <stdio.h>

namespace LS {
utArray<LSCompilerLog::Message> LSCompilerLog::errors;
utArray<LSCompilerLog::Message> LSCompilerLog::warnings;

void LSCompilerLog::logWarning(utString filename, int line, utString message,
                               utString subType)
{
    Message msg;

    msg.filename = filename;
    msg.line     = line;
    msg.message  = message;
    msg.subType  = subType;
    if (warnings.find(msg) == UT_NPOS)
    {
        warnings.push_back(msg);
    }
}


void LSCompilerLog::logError(utString filename, int line, utString message,
                             utString subType)
{
    Message msg;

    msg.filename = filename;
    msg.line     = line;
    msg.message  = message;
    msg.subType  = subType;
    if (errors.find(msg) == UT_NPOS)
    {
        errors.push_back(msg);
    }
}


void LSCompilerLog::dump(const Message& msg, bool warning)
{
    printf("%s(%i) : %s - %s\n", msg.filename.c_str(), msg.line, warning ? "warning" : "error",
           msg.message.c_str());
}


void LSCompilerLog::dump(bool errorsOnly)
{
    if (!errorsOnly)
    {
        for (unsigned int i = 0; i < warnings.size(); i++)
        {
            dump(warnings[i], true);
        }
    }

    for (unsigned int i = 0; i < errors.size(); i++)
    {
        dump(errors[i]);
    }
}
}
