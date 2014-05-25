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

#import <UIKit/UIKit.h>
#import "Parse.h"

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformParse.h"
#include "loom/common/platform/platformParseiOS.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"



static bool _initialized = false;


@implementation ParseAPIiOS


-(void) initialize
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *app_id = [mainBundle objectForInfoDictionaryKey:@"ParseAppIDString"];
    NSString *client_key = [mainBundle objectForInfoDictionaryKey:@"ParseClientKeyString"];
//TEMP: LFL: Remove this log once we are all working 1005
NSLog(@"-----Info.plist Parse Strings: %@ %@", app_id, client_key);

//TODO: don't initialize without valid strings
    [Parse setApplicationId:app_id clientKey:client_key];
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
                                                    UIRemoteNotificationTypeAlert|
                                                    UIRemoteNotificationTypeSound];    
    _initialized = true;
}

-(void) registerForRemoteNotifications:(NSData *)deviceToken
{
    if(_initialized)
    {
        // Store the deviceToken in the current installation and save it to Parse.
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if(currentInstallation != NULL)
        {
            [currentInstallation setDeviceTokenFromData:deviceToken];
            [currentInstallation saveInBackground];    
        }
    }
}

-(void) failedToRegister:(NSError *)error
{
    _initialized = false;
}

-(void) receivedRemoteNotification:(NSDictionary *)userInfo
{
    if(_initialized)
    {
        [PFPush handlePush:userInfo];
    }
}


@end





///initializes the data for the Parse class for iOS
void platform_parseInitialize()
{
}

///check if the Parse API has initialized
bool platform_hasInitialized()
{
    return _initialized;
}

///Returns the parse installation ID
const char* platform_getInstallationID()
{
    if(_initialized)
    {

    }
    return "";
}

///Returns the parse installation object's objectId
const char* platform_getInstallationObjectID()
{
    if(_initialized)
    {

    }
    return "";
}

///Updates the custom userId property on the installation
bool platform_updateInstallationUserID(const char* userId)
{
    if(_initialized)
    {
        // return true;
    }
    return false;
}


#endif
