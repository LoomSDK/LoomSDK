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
#import <Foundation/NSSet.h>
#import "Carrot.h"
#import "application/ios/AppController.h"

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformTeak.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(giOSTeakLogGroup, "teak", 1, LoomLogDefault);


static AuthStatusCallback gAuthStatusCallback = NULL;
static bool _initialized = false;
static const char *_teakAppSecret = NULL;




@interface TeakDelegate:NSObject<CarrotDelegate>
@end


@implementation TeakDelegate

- (void)applicationLinkRecieved:(NSURL *)targetURL
{
    //Should we support this?
}


- (void)authenticationStatusChanged:(int)status withError:(NSError *)error
{

    if(error)
    {
        NSLog(@"-=-=-=-=-=-=-Teak Authentication Status Error!-=-=-=-=-=-=-=-");
        //Handle NSError?
        return;
    }

    NSLog(@"-=-=-=-=-=-=-Teak Authentication Status Changed To: %i-=-=-=-=-=-=-=-", status);
    if(gAuthStatusCallback != NULL)
    {
        gAuthStatusCallback(status);
    }
}

@end

TeakDelegate *_teakDelegate = nil;




bool checkTeakAppSecret() 
{
    if((_teakAppSecret == NULL) || (_teakAppSecret[0] == '\0')) 
    {
        lmLog(giOSTeakLogGroup, "No Teak App Secret defined. Alter your 'loom.config' file, or 'Info.plist' file to use Loom.Teak functionality.");
        return false;
    }
    return true;
}


void platform_teakInitialize(AuthStatusCallback authStatusCB)
{
    gAuthStatusCallback = authStatusCB;

    //find the Teak ID for later use; if not present, then log and don't do further initialization!
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *app_secret = [mainBundle objectForInfoDictionaryKey:@"TeakAppSecret"];
    NSString *app_id = [mainBundle objectForInfoDictionaryKey:@"FacebookAppID"];
    // NSLog(@"-----Info.plist TeakAppSecret String: %@", app_secret);
    // NSLog(@"-----Info.plist FBID String: %@", app_id);

     //don't initialize without valid strings
    _initialized = false;
    if((app_secret != nil) && ([app_secret isEqualToString:@""] == FALSE) &&
        (app_id != nil) && ([app_id isEqualToString:@""] == FALSE))
    {    
        _teakAppSecret = [app_secret cStringUsingEncoding:NSUTF8StringEncoding];

        //plant teak into our App with the Secret
        // [Carrot plant:app_id inApplication:[AppController class] withSecret:app_secret];
        // [Carrot plantInApplication:[AppController class] withSecret:app_secret];

        //manually set Facebook App ID & Teak Secret: NOTE: setSharedAppID *MUST* be called prior to any sharedInstance usages!
        [Carrot setSharedAppID:app_id];
        [[Carrot sharedInstance] setAppSecret:app_secret];

        //set status notification delegate
        _teakDelegate = [[TeakDelegate alloc] init];
        [[Carrot sharedInstance] setDelegate:_teakDelegate];

        lmLog(giOSTeakLogGroup, "Teak initialized successfully!!!");
        _initialized = true;
    }
}


bool platform_isTeakActive()
{
    return _initialized;
}


void platform_setAccessToken(const char *fbAccessToken)
{
    if(_initialized)
    {
        NSString *accessToken = [NSString stringWithCString:fbAccessToken encoding:NSUTF8StringEncoding];
        [[Carrot sharedInstance] setAccessToken:accessToken];
    }
}


int platform_getStatus()
{
    if(_initialized)
    {
        return [[Carrot sharedInstance] authenticationStatus];
    }
    return -1;
}


bool platform_postAchievement(const char *achievementId)
{
    if(_initialized)
    {
        NSString *achievementString = [NSString stringWithCString:achievementId encoding:NSUTF8StringEncoding];
        return ([[Carrot sharedInstance] postAchievement:achievementString] == YES) ? true : false;
    }
    return false;
}


bool platform_postHighScore(int score)
{
    if(_initialized)
    {
        return ([[Carrot sharedInstance] postHighScore:score] == YES) ? true : false;
    }
    return false;
}


bool platform_postAction(const char *actionId, const char *objectInstanceId)
{
    if(_initialized)
    {
        NSString *actionString = [NSString stringWithCString:actionId encoding:NSUTF8StringEncoding];
        NSString *instanceString = [NSString stringWithCString:objectInstanceId encoding:NSUTF8StringEncoding];
        return ([[Carrot sharedInstance] postAction:actionString
                                            forObjectInstance:instanceString] == YES) ? true : false;
    }
    return false;
}


bool platform_postActionWithProperties(const char *actionId, const char *objectInstanceId, const char *jsonProperties)
{
    if(_initialized)
    {
        NSString *actionString = [NSString stringWithCString:actionId encoding:NSUTF8StringEncoding];
        NSString *instanceString = [NSString stringWithCString:objectInstanceId encoding:NSUTF8StringEncoding];

        //build property dictionary from the incoming JSON properties string
        NSError *e = nil;
        NSString *jsonString = [NSString stringWithCString:jsonProperties encoding:NSUTF8StringEncoding];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *actionProperties = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                options:NSJSONReadingMutableContainers 
                                                                error:&e];
        // NSLog(@"-----Teak Action Properties: %@", [actionProperties description]);
        if(e != nil)
        {
            NSLog(@"[Teak] Error [%@  %d] creating NSDictionary for JSON Property String: %@", [e localizedDescription], e.code, jsonString);
            return false;
        }        

        return ([[Carrot sharedInstance] postAction:actionString
                                            withProperties:actionProperties
                                            forObjectInstance:instanceString] == YES) ? true : false;
    }
    return false;
}
