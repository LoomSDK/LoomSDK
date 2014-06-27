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
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"

static SensorTripleChangedCallback gTripleChangedCallback = NULL;


static UIViewController* getParentViewController()
{
    return [[[UIApplication sharedApplication] keyWindow] rootViewController];
}

///initializes the data for the Mobile class for iOS
void platform_mobileInitialize(SensorTripleChangedCallback sensorTripleChangedCB)
{
    gTripleChangedCallback = sensorTripleChangedCB;    
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
    NSString *body = (text) ? [NSString stringWithUTF8String : text] : nil;
    NSArray *activityItems = @[body];

    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [getParentViewController() presentViewController:controller animated:YES completion:nil];
    return true;
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
