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
#include "loom/common/platform/platformMobile.h"
#include "loom/common/platform/platformMobileiOS.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"

static SensorTripleChangedCallback gTripleChangedCallback = NULL;
static OpenedViaCustomURLCallback gOpenedViaCustomURLCallback = NULL;
static OpenedViaRemoteNotificationCallback gOpenedViaRemoteNotificationCallback = NULL;

BOOL gOpenedWithCustomURL = NO;
BOOL gOpenedWithRemoteNotification = NO;
NSMutableDictionary *gOpenUrlQueryStringDictionary = nil;
NSDictionary *gRemoteNotificationPayloadDictionary = nil;


static UIViewController* getParentViewController()
{
    return [[[UIApplication sharedApplication] keyWindow] rootViewController];
}

void ios_CustomURLOpen()
{
    gOpenedWithCustomURL = YES;
    if (gOpenedViaCustomURLCallback)
    {
        gOpenedViaCustomURLCallback();
    }
}

void ios_RemoteNotificationOpen()
{
    gOpenedWithRemoteNotification = NO;
    if((gRemoteNotificationPayloadDictionary != nil) && ([gRemoteNotificationPayloadDictionary count]))
    {
        NSLog(@"----Remote Notification Payload is: %@", gRemoteNotificationPayloadDictionary);      
        gOpenedWithRemoteNotification = YES;
        if (gOpenedViaRemoteNotificationCallback)
        {
            gOpenedViaRemoteNotificationCallback();
        }
    }
}


///initializes the data for the Mobile class for iOS
void platform_mobileInitialize(SensorTripleChangedCallback sensorTripleChangedCB, 
                                OpenedViaCustomURLCallback customURLCB,
                                OpenedViaRemoteNotificationCallback remoteNotificationCB)
{
    gTripleChangedCallback = sensorTripleChangedCB;    
    gOpenedViaCustomURLCallback = customURLCB;    
    gOpenedViaRemoteNotificationCallback = remoteNotificationCB;    
}

///tells the device to do a short vibration, if supported by the hardware
void platform_vibrate()
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

///sets whether or not to use the system screen sleep timeout
void platform_allowScreenSleep(bool sleep)
{
    if(sleep)
    {
        ///idle time act as normal
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
    else
    {
        ///disable the idle timer
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
}

///shares the specfied text via other applications on the device (ie. Twitter, Facebook)
bool platform_shareText(const char *subject, const char *text)
{
    NSString *body = (text && (text[0] != '\0')) ? [NSString stringWithUTF8String : text] : nil;
    NSString *title = (subject && (subject[0] != '\0')) ? [NSString stringWithUTF8String : subject] : nil;
    NSArray *activityItems = @[body];

    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    if(title != nil)
    {
        [controller setValue:title forKey:@"subject"];
    }

    //TODO: options to exclude various activity types, ie: [UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypePostToFlickr, etc.]

    //if the text body is too long, it ends up being completely empty if we use Twitter, so make sure to exclude it!!!
    if((body != nil) && (body.length > 140))
    {
        controller.excludedActivityTypes = @[UIActivityTypePostToTwitter];
    }

    [getParentViewController() presentViewController:controller animated:YES completion:nil];
    return true;
}

///returns if the application was launched via a Custom URL Scheme
bool platform_wasOpenedViaCustomURL()
{
    return gOpenedWithCustomURL;
}

///returns if the application was launched via a Remote Notification interaction
bool platform_wasOpenedViaRemoteNotification()
{
    return gOpenedWithRemoteNotification;
}

///gets the the specified query key data from any custom scheme URL path that the application was launched with, or "" if not found
const char *platform_getOpenURLQueryData(const char *queryKey)
{
    static char queryDataStatic[1024];
    const char *cString;
    queryDataStatic[0] = '\0';
    if(queryKey && gOpenUrlQueryStringDictionary)
    {
        NSString *queryKeyString = (queryKey) ? [NSString stringWithUTF8String : queryKey] : nil;
        if(queryKeyString)
        {
            NSString *queryData = [gOpenUrlQueryStringDictionary objectForKey:queryKeyString];
            if(queryData)
            {
                cString = [queryData cStringUsingEncoding:NSUTF8StringEncoding];    
                strcpy(queryDataStatic, cString);
                return queryDataStatic;
            }
        }
    }
    return queryDataStatic;
}

///gets the the data associated with the specified key from any potential custom payload attached to a 
///Remote Notification that the application was launched with, or "" if not found
const char *platform_getRemoteNotificationData(const char *key)
{
    static char remoteNotificationDataStatic[1024];
    const char *cString;
    remoteNotificationDataStatic[0] = '\0';
    if(key && gRemoteNotificationPayloadDictionary)
    {
        NSString *keyString = (key) ? [NSString stringWithUTF8String : key] : nil;
        if(keyString)
        {
            NSString *keyData = [gRemoteNotificationPayloadDictionary objectForKey:keyString];
            if(keyData)
            {
                cString = [keyData cStringUsingEncoding:NSUTF8StringEncoding];    
                strcpy(remoteNotificationDataStatic, cString);
                return remoteNotificationDataStatic;
            }
        }
    }
    return remoteNotificationDataStatic;
}

///checks if a given sensor is supported on this hardware
bool platform_isSensorSupported(int sensor)
{
    ///TODO: 1844: Support sensors on iOS
    return false;
}

///checks if a given sensor is currently enabled
bool platform_isSensorEnabled(int sensor)
{
    ///TODO: 1844: Support sensors on iOS
    return false;
}

///checks if a given sensor has received any data yet
bool platform_hasSensorReceivedData(int sensor)
{
    ///TODO: 1844: Support sensors on iOS
    return false;
}

///enables the given sensor
bool platform_enableSensor(int sensor)
{
    ///TODO: 1844: Support sensors on iOS
    return false;
}

///disables the given sensor
void platform_disableSensor(int sensor)
{
    ///TODO: 1844: Support sensors on iOS
}


#endif
