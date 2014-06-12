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
// #import "Carrot.h"

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformTeak.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(giOSTeakLogGroup, "loom.teak.ios", 1, 0);



static AuthStatusCallback gAuthStatusCallback = NULL;
static bool _initialized = false;
static const char *_teakAppSecret = NULL;



bool checkTeakAppSecret() 
{
    if((_teakAppSecret == NULL) || (_teakAppSecret[0] == '\0')) 
    {
        lmLog(giOSTeakLogGroup, "No Teak App Secret defined. Alter your 'loom.config' file, or 'Info.plist' file to use Loom.Teak functionality.");
        return false;
    }
    return true;
}


//TODO: Teak for iOS
void platform_teakInitialize(AuthStatusCallback authStatusCB)
{
    gAuthStatusCallback = authStatusCB;

    //find the Teak ID for later use; if not present, then log and don't do further initialization!
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *app_secret = [mainBundle objectForInfoDictionaryKey:@"TeakAppSecret"];
NSLog(@"-----Info.plist TeakAppSecret String: %@", app_secret);

     //don't initialize without valid strings
    _initialized = false;
    if([app_secret isEqualToString:@""] == FALSE)
    {
        _initialized = true;
        _teakAppSecret = [app_secret cStringUsingEncoding:NSUTF8StringEncoding];
    
        //set up the app secret
        // [[Carrot sharedInstance] setAppSecret:@app_secret];
    }
}

//TODO: delegate!!!

void platform_setAccessToken(const char *fbAccessToken)
{
    if(checkTeakAppSecret())
    {
        // NSString *accessToken = [NSString stringWithCString:fbAccessToken encoding:NSUTF8StringEncoding];
        // [[Carrot sharedInstance] setAccessToken:@accessToken];
    }
}
int platform_getStatus()
{
    if(checkTeakAppSecret())
    {
//TODO: are the values here 1:1 with Android?
        // return [[Carrot sharedInstance] authenticationStatus];
    }
    return -1;
}
bool platform_postAchievement(const char *achievementId)
{
    if(checkTeakAppSecret())
    {
        // return ([[Carrot sharedInstance] postAchievement:@"chicken"] == YES) ? true : false;
    }
    return false;
}
bool platform_postHighScore(int score)
{
    if(checkTeakAppSecret())
    {
        // return ([[Carrot sharedInstance] postHighScore:score] == YES) ? true : false;
    }
    return false;
}
bool platform_postAction(const char *actionId, const char *objectInstanceId)
{
    if(checkTeakAppSecret())
    {
        // NSDictionary* objectProperties = @{
        //     @"title": @"Obj-C Test",
        //     @"image":@"http://static.ak.fbcdn.net/rsrc.php/v2/y_/r/9myDd8iyu0B.gif",
        //     @"description":@"Testing the objective-c dynamic object generation",
        //     @"fields": @{@"sha": @"abcdefg"}
        // };
        // return ([[Carrot sharedInstance] postAction:@"push"
        //                             withProperties:nil
        //                             creatingInstanceOf:@"commit"
        //                             withProperties:objectProperties] == YES) ? true : false;
    }
    return false;
}

