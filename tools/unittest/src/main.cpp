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

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformTime.h"
#include "loom/vendor/seatest/seatest.h"

#include <cstdlib>

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#include <windows.h>
#endif

int main(int argc, const char **argv)
{
    #if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    // This prevents error dialogs on a failed test on Windows
    DWORD dwMode = SetErrorMode(SEM_NOGPFAULTERRORBOX);
    SetErrorMode(dwMode | SEM_NOGPFAULTERRORBOX);
    #endif

    platform_timeInitialize();

    extern void __cdecl test_suite_allTests();
    seatest_set_print_callback(printf);
    if (!seatest_testrunner(0, NULL, test_suite_allTests, NULL, NULL))
    {
        printf("*** TESTS FAILED ***\n");
        exit(EXIT_FAILURE);
    }

    return EXIT_SUCCESS;
}
