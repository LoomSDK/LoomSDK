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

#ifndef _UTILS_GUID_H_
#define _UTILS_GUID_H_

#define LOOM_GUID_SIZE 37

typedef char loom_guid_t[LOOM_GUID_SIZE];

extern "C"
{
    /*
     
     Usage is super simple:
     
     loom_guid_t myGuid;
     loom_generate_guid(myGuid);
     printf("my guid: %s\n", myGuid);
     
     */
    void loom_generate_guid(loom_guid_t out_guid);
};

#endif
