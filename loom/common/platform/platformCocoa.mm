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

#import <Foundation/Foundation.h>
#if LOOM_PLATFORM == LOOM_PLATFORM_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif

extern "C"
{

int platform_openURL(const char *url)
{
    NSURL* nsurl = [NSURL URLWithString:[NSString stringWithUTF8String:url]];
    if (nsurl == nil) return false;
    return [
#if LOOM_PLATFORM == LOOM_PLATFORM_OSX
        [NSWorkspace sharedWorkspace]
#else
        [UIApplication sharedApplication]
#endif
        openURL:nsurl
    ] == YES ? true : false;
}

}
