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
#import <Parse/Parse.h>

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformParse.h"
#include "loom/common/platform/platformParseiOS.h"
#include "loom/common/platform/platformMobile.h"
#include "loom/common/platform/platformMobileiOS.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"
#include "loom/vendor/sdl2/src/video/uikit/SDL_uikitappdelegate.h"


static bool _initialized = false;
extern NSDictionary *gRemoteNotificationPayloadDictionary;

@implementation ParseAPIiOS


+(void) initialize
{
    if (_initialized) return;

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *app_id = [mainBundle objectForInfoDictionaryKey:@"ParseAppID"];
    NSString *client_key = [mainBundle objectForInfoDictionaryKey:@"ParseClientKey"];
    NSString *server = [mainBundle objectForInfoDictionaryKey:@"ParseServer"];
    // NSLog(@"-----Info.plist Parse Strings: %@ %@", app_id, client_key);

    //don't initialize without valid strings
    _initialized = false;
    
    if(app_id != nil && ([app_id isEqualToString:@""] == FALSE))
    {
        NSLog(@"Parse initialization");

        [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration>  _Nonnull configuration) {
            configuration.applicationId = app_id;

            if(client_key != nil && ([client_key isEqualToString:@""] == FALSE)) {
                configuration.clientKey = client_key;
            }
            
            configuration.server = server;

            // Enable storing and querying data from Local Datastore. Remove this line if you don't want to
            // use Local Datastore features or want to use cachePolicy.
            configuration.localDatastoreEnabled = YES;
        }]];

        //register for remote notifications with the system... different for iOS8+ though!
        //we need to make sure not to compile in any mention of UIUserNotificationSetting if we are on an older Xcode!            
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000        
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
        {
            //iOS 8 and up
            Class userNotifyClass = NSClassFromString(@"UIUserNotificationSettings");
            if(userNotifyClass != nil)
            {
                id notifySettings = [userNotifyClass settingsForTypes:UIUserNotificationTypeAlert |
                                                                        UIUserNotificationTypeBadge |
                                                                        UIUserNotificationTypeSound
                                                                        categories:nil];
                [[UIApplication sharedApplication] registerUserNotificationSettings:notifySettings];
                [[UIApplication sharedApplication] registerForRemoteNotifications];            
            }
        }
        else
#endif
        {
            //pre-iOS 8 code
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
                                                                                    UIRemoteNotificationTypeAlert|
                                                                                    UIRemoteNotificationTypeSound];    
        }
        _initialized = true;
        NSLog(@"Parse initialized");
    }
}

+(void) didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    if(_initialized)
    {
        // Store the deviceToken in the current installation and save it to Parse.
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if(currentInstallation)
        {
            [currentInstallation setDeviceTokenFromData:deviceToken];
            [currentInstallation saveInBackground];    
            NSLog(@"Parse registered for remote notifications");
        }
    }
}

+(void) failedToRegister:(NSError *)error
{
    _initialized = false;
}

+(void) handleRemoteNotification:(NSDictionary *)info
{
    if (!info) return;
    NSObject* aps = [info objectForKey:@"aps"];
    if (aps && [aps isKindOfClass:[NSDictionary class]]){
        // Release previous payload if any
        if (gRemoteNotificationPayloadDictionary) {
            NSString* jsonString = [gRemoteNotificationPayloadDictionary objectForKey:@"data"];
            if (jsonString) {
                [jsonString release];
            }
            [gRemoteNotificationPayloadDictionary release];
        }
        // Create a new one
        gRemoteNotificationPayloadDictionary = [(NSDictionary*)aps mutableCopy];
        NSObject* data = [info objectForKey:@"data"];
        if (data)
        {
            NSError* err;
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&err];
            NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [gRemoteNotificationPayloadDictionary setValue:jsonString forKey:@"data"];
        }
        ios_RemoteNotificationOpen();
    }
}

+(void) receivedRemoteNotification:(NSDictionary *)userInfo
{
    if(_initialized)
    {
        [PFPush handlePush:userInfo];
        [ParseAPIiOS handleRemoteNotification:userInfo];
    }
}

@end


// Delegate subclass to catch events
@interface SDLUIKitDelegateSub : SDLUIKitDelegate
- (bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
@end

@implementation SDLUIKitDelegateSub : SDLUIKitDelegate
- (bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (launchOptions != nil)
    {
        NSDictionary* dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (dictionary) {
            [ParseAPIiOS handleRemoteNotification:dictionary];
        }
    }
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
@end



// Class category to catch some events and setup the subclass
@interface SDLUIKitDelegate (SDLUIKitDelegatePush)
@end
@implementation SDLUIKitDelegate (SDLUIKitDelegatePush)
// Tells SDL to init with our subclass instead of the base class
+ (NSString *)getAppDelegateClassName
{
    return @"SDLUIKitDelegateSub";
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [ParseAPIiOS didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [ParseAPIiOS receivedRemoteNotification:userInfo];
}
@end





///initializes the data for the Parse class for iOS
void platform_parseInitialize()
{
    [ParseAPIiOS initialize];
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
