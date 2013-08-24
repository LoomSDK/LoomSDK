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

#include "seatest.h"
#include "loom/common/core/stringTable.h"

SEATEST_FIXTURE(stringTable)
{
    SEATEST_FIXTURE_ENTRY(stringTable_basic);
}

SEATEST_TEST(stringTable_basic)
{
    stringtable_initialize();
    StringTableEntry ste1 = stringtable_insert("Hey!");
    StringTableEntry ste2 = stringtable_insert("Hey!");
    StringTableEntry ste3 = stringtable_insert("Whoa!");

    assert_true(ste1 != NULL);
    assert_true(ste3 != NULL);
    assert_true(ste1 == ste2);
    assert_string_equal((char *)ste1, (char *)ste2);
    assert_string_equal((char *)ste1, "Hey!");
    assert_true(ste2 != ste3);
}
