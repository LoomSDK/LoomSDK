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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/NSSet.h>

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformFacebook.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"


static SessionStatusCallback gSessionStatusCallback = NULL;



void platform_facebookInitialize(SessionStatusCallback sessionStatusCB)
{
    gSessionStatusCallback = sessionStatusCB;
}


//TODO: iOS FB support

bool platform_openSessionWithReadPermissions(const char* permissionsString)
{
    return false;
}

bool platform_requestNewPublishPermissions(const char* permissionsString)
{
    return false;
}

void platform_showFrictionlessRequestDialog(const char* recipientsString, const char* titleString, const char* messageString)
{
}

const char* platform_getAccessToken()
{
    return "";
}

const char* platform_getExpirationDate(const char* dateFormat)
{
    return "";
}