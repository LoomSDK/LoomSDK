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

#ifndef _lscompilerlog_h
#define _lscompilerlog_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

namespace LS {
class LSCompilerLog {
public:

    struct Message
    {
        utString filename;
        int      line;

        utString message;
        utString subType;

        bool operator==(const Message& rhs)
        {
            return filename == rhs.filename && line == rhs.line &&
                   message == rhs.message && subType == rhs.subType;
        }
    };

private:

    static utArray<Message> errors;
    static utArray<Message> warnings;

    static void dump(const Message& msg, bool warning = false);

public:

    static void logWarning(utString filename, int line, utString message, utString subType = "");

    static void logError(utString filename, int line, utString message, utString subType = "");

    static void dump(bool errorsOnly = false);

    static void clear()
    {
        errors.clear();
        warnings.clear();
    }

    static int getNumErrors()
    {
        return errors.size();
    }

    static int getNumWarnings()
    {
        return warnings.size();
    }

    static void getError(unsigned int num, Message& msg)
    {
        if (num < errors.size())
        {
            msg = errors[num];
        }
    }

    static void getWarning(unsigned int num, Message& msg)
    {
        if (num < warnings.size())
        {
            msg = warnings[num];
        }
    }
};
}
#endif
