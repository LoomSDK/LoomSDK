/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

#include "loom/common/platform/platform.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_IOS

#import <AudioToolbox/AudioServices.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSSet.h>
#import <UIKit/UIKit.h>

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformParse.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"


///initializes the data for the Parse class for iOS
void platform_parseInitialize()
{
}


///starts up the Parse service
bool platform_startUp(const char *appID, const char *clientKey)
{
//TODO: Parse setup for iOS    
    return false;
}

#endif
