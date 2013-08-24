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

#include "loom/common/core/log.h"
#include "seatest.h"

SEATEST_FIXTURE(logging)
{
    SEATEST_FIXTURE_ENTRY(logging_basic);
}

static int logCount;
static void test_listener(void *payload, loom_logGroup_t *group, loom_logLevel_t level, const char *msg)
{
    logCount++;
}


lmDefineLogGroup(testGroup, "logging_basic", 1, LoomLogInfo);

SEATEST_TEST(logging_basic)
{
    loom_log_addListener(test_listener, NULL);

    logCount = 0;

    // Test that we can log with no params.
    lmLog(testGroup, "Testing that log output is observed. (1)");
    assert_int_equal(logCount, 1);

    // Try a number param.
    lmLog(testGroup, "Testing that log output is observed. (%d)", 2);
    assert_int_equal(logCount, 2);

    // And a string param.
    lmLog(testGroup, "Testing that log output is observed. (%s)", "3");
    assert_int_equal(logCount, 3);

    loom_log_removeListener(test_listener, NULL);
}
