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
#include "Parse.h"

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
    NSString *app_id = [mainBundle objectForInfoDictionaryKey:@"ParseAppID"];
    NSString *client_key = [mainBundle objectForInfoDictionaryKey:@"ParseClientKey"];
    // NSLog(@"-----Info.plist Parse Strings: %@ %@", app_id, client_key);

    //don't initialize without valid strings
    _initialized = false;
    if(([app_id isEqualToString:@""] == FALSE) && ([client_key isEqualToString:@""] == FALSE))
    {
        [Parse setApplicationId:app_id clientKey:client_key];
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
                                                        UIRemoteNotificationTypeAlert|
                                                        UIRemoteNotificationTypeSound];    
        _initialized = true;
        NSLog(@"-----Parse Initialized Successfully");
    }
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
            NSLog(@"-----Parse Registered for Remote Notifications Successfully");
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
        NSLog(@"-----Parse Received Remote Notifications");
    }
}


@end





///initializes the data for the Parse class for iOS
void platform_parseInitialize()
{
}

///check if the Parse API is active for use
bool platform_isParseActive()
{
    return _initialized;
}

///Returns the parse installation ID
const char* platform_getInstallationID()
{
    static char installationId[1024];
    if(_initialized)
    {
        PFInstallation *installation = [PFInstallation currentInstallation];
        if(installation != NULL)
        {
            NSString *instID = [installation installationId];
            const char *cString = [instID cStringUsingEncoding:NSUTF8StringEncoding];
            if(cString != NULL)
            {
                strcpy(installationId, cString);
                return installationId;
            }
        }
    }
    return "";
}

///Returns the parse installation object's objectId
const char* platform_getInstallationObjectID()
{
    static char objectId[1024];
    if(_initialized)
    {
        PFInstallation *installation = [PFInstallation currentInstallation];
        if(installation != NULL)
        {
            NSString *objID = [installation objectId];
            const char *cString = [objID cStringUsingEncoding:NSUTF8StringEncoding];
            if(cString != NULL)
            {
                strcpy(objectId, cString);
                return objectId;
            }
        }
    }
    return "";
}

///Updates the custom userId property on the installation
bool platform_updateInstallationUserID(const char* userId)
{
    if(_initialized)
    {
        PFInstallation *installation = [PFInstallation currentInstallation];
        if(installation != NULL)
        {
            NSString *user_id = [NSString stringWithUTF8String:userId];
            [installation setObject:user_id forKey:@"userId"];
            [installation saveInBackground];
        }
        return true;
    }
    return false;
}


#endif
