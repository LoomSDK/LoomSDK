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
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformMobile.h"
#include "loom/common/platform/platformMobileiOS.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(iosLogGroup, "mobile.ios", 1, LoomLogInfo);

//interface for PlatformMobileiOS
@interface PlatformMobileiOS : NSObject <CLLocationManagerDelegate>

//properties
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *latestLocation;
@property (nonatomic, retain) CMMotionManager *motionManager;

//methods
-(void)initialize;
-(void)startTracking:(int)minDist;
-(void)stopTracking;
-(NSString *)getLocation;

@end


//implementation of PlatformMobileiOS
@implementation PlatformMobileiOS

//methods
- (NSString *)initialize {
    self.locationManager = nil;
    self.motionManager = nil;

    //check authorization status
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    if ((authStatus == kCLAuthorizationStatusDenied) || (authStatus == kCLAuthorizationStatusRestricted))
    {
        NSLog(@"WARNING: Location services are blocked by the user and cannot be used.");
        return;
    }

    //create the location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //create the motion manager
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 1.0/60.0;
}

-(void)startTracking:(int)minDist{
    if ([CLLocationManager locationServicesEnabled] == NO)
    {
        NSLog(@"WARNING: Location Tracking cannot be started because Location Services are disabled on this device.");
        return;
    }

    //make sure that the location manager has been created
    if(self.locationManager == nil)
    {
        //don't need to warn again as it would have already warned at initialization time
        return;
    }

    //reqeust authorization?
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined)
    {
        NSLog(@"Requesting Location Services Authorization...");
        //iOS8 specifics to request in use authorization... weeee!!!!!
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) 
        {
            // Sending a message to avoid compile time error
            [[UIApplication sharedApplication] sendAction:@selector(requestWhenInUseAuthorization)
                                                to:self.locationManager
                                                from:self
                                                forEvent:nil];
        }        
    }

    //set the distance filter and request for location updates
    self.locationManager.distanceFilter = minDist;
    [self.locationManager startUpdatingLocation];
}

-(void)stopTracking{    
    [self.locationManager stopUpdatingLocation];
}

- (NSString *)getLocation {
    NSString *locString = nil;
    if(self.latestLocation != nil)
    {
        locString = [NSString stringWithFormat:@"%f %f", self.latestLocation.coordinate.latitude, 
                                                         self.latestLocation.coordinate.longitude];
    }
    return locString;
}

//returns true if accelerometer is supported on device
-(BOOL)isAccelerometerAvailable {
    return self.motionManager.accelerometerAvailable;
}

//returns true if accelerometer is active (it happens when startAccelerometerUpdates is called on motionManager)
-(BOOL)isAccelerometerActive {
    return self.motionManager.accelerometerActive;
}

-(void)enableAccelerometer:(SensorTripleChangedCallback) gTripleChangedCallback {
    if (self.isAccelerometerActive || !self.isAccelerometerAvailable) return;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        if (gTripleChangedCallback != NULL) {
            double axes[3];
            
            [self remapXAxis:accelerometerData.acceleration.x yAxis:accelerometerData.acceleration.y zAxis:accelerometerData.acceleration.z into:axes];
            gTripleChangedCallback(0,axes[0],axes[1],axes[2]);
        }
    }];
}

-(void)disableAccelerometer {
    [self.motionManager stopAccelerometerUpdates];
}

-(CMAccelerometerData *)getAccelerometerData {
    return self.motionManager.accelerometerData;
}

-(void)remapXAxis:(double) x yAxis:(double) y zAxis:(double) z into:(double *) remapped {
    UIInterfaceOrientation curOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (curOrientation == UIInterfaceOrientationLandscapeLeft) {
        remapped[0] = y;
        remapped[1] = -x;
    } else if (curOrientation == UIInterfaceOrientationLandscapeRight) {
        remapped[0] = -y;
        remapped[1] = x;
    } else if (curOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        remapped[0] = -x;
        remapped[1] = -y;
    } else {
        remapped[0] = x;
        remapped[1] = y;
    }
    remapped[2] = z;
}

//CLLocationManagerDelegate interfaces
//iOS5-
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation 
                                                        fromLocation:(CLLocation *)oldLocation{
    self.latestLocation = newLocation;
}

//iOS6+
-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    self.latestLocation = [locations lastObject];
}

-(void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{   
    NSLog(@"ERROR: Failed to update the current Location with error: %@", error.description);
    self.latestLocation = nil;
}

@end


static SensorTripleChangedCallback gTripleChangedCallback = NULL;
static OpenedViaCustomURLCallback gOpenedViaCustomURLCallback = NULL;
static OpenedViaRemoteNotificationCallback gOpenedViaRemoteNotificationCallback = NULL;

BOOL gOpenedWithCustomURL = NO;
BOOL gOpenedWithRemoteNotification = NO;
NSMutableDictionary *gOpenUrlQueryStringDictionary = nil;
NSDictionary *gRemoteNotificationPayloadDictionary = nil;
PlatformMobileiOS *mobileiOS;



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

    //create the PlatformMobileiOS interface
    mobileiOS = [[PlatformMobileiOS alloc] init];
    [mobileiOS initialize];
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

///enables location tracking for this device
void platform_startLocationTracking(int minDist, int minTime)
{
    //NOTE: minTime isn't supported on iOS
    [mobileiOS startTracking:minDist];
}

///disables location tracking for this device
void platform_stopLocationTracking()
{
    [mobileiOS stopTracking];
}

///returns the device's location using GPS and/or NETWORK signals
const char *platform_getLocation()
{
    static char locationStatic[1024];
    const char *cString;
    locationStatic[0] = '\0';

    //get the location as a string    
    NSString *locString = [mobileiOS getLocation];
    if(locString != nil)
    {
        //convert it to char array and store it in the static to return
        cString = [locString cStringUsingEncoding:NSUTF8StringEncoding];    
        strcpy(locationStatic, cString);
    }
    return locationStatic;

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
    BOOL supported = false;
    
    switch (sensor)
    {
        case 0:
            supported = [mobileiOS isAccelerometerAvailable];
            break;
    }
    
    return supported;
}

///checks if a given sensor is currently enabled
bool platform_isSensorEnabled(int sensor)
{
    BOOL enabled = false;
    
    switch (sensor)
    {
        case 0:
            enabled = [mobileiOS isAccelerometerActive];
            break;
    }
    
    return enabled;
}

///checks if a given sensor has received any data yet
bool platform_hasSensorReceivedData(int sensor)
{
    return [mobileiOS getAccelerometerData] != nil;
}

///enables the given sensor
bool platform_enableSensor(int sensor)
{
    BOOL enabled = false;
    
    switch (sensor)
    {
        case 0:
            [mobileiOS enableAccelerometer:gTripleChangedCallback];
            enabled = true;
            break;
    }
    
    return enabled;
}

///disables the given sensor
void platform_disableSensor(int sensor)
{
    switch (sensor)
    {
        case 0:
            [mobileiOS disableAccelerometer];
            break;
    }
}


#endif
