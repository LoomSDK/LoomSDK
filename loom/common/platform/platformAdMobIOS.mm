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

#import "platformAdMob.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "GoogleMobileAds/DFPBannerView.h"
#import "GoogleMobileAds/DFPInterstitial.h"
#import "GoogleMobileAds/DFPRequest.h"
//_________________________________________________________________________
// Helpers
//_________________________________________________________________________
static int gloom_adMobCounter = 0;
static NSString* gPublisherId = nil;
static NSMutableDictionary* gBannerAds = nil;
static NSMutableDictionary* bannerAds()
{
    if(gBannerAds == nil)
        gBannerAds = [[NSMutableDictionary dictionary] retain];
    
    return gBannerAds;
}

static NSMutableDictionary* gInterstitialAds = nil;
static NSMutableDictionary* interstitialAds()
{
    if(gInterstitialAds == nil)
        gInterstitialAds = [[NSMutableDictionary dictionary] retain];
    
    return gInterstitialAds;
}

static DFPBannerView* getBannerView(loom_adMobHandle handle)
{
    return [bannerAds() objectForKey:[NSNumber numberWithInt:handle]];
}

static DFPInterstitial* getInterstitialView(loom_adMobHandle handle)
{
    return [interstitialAds() objectForKey:[NSNumber numberWithInt:handle]];
}


static UIViewController* getParentViewController()
{
    return [[[UIApplication sharedApplication] keyWindow] rootViewController];
}

static float getScreenHeight()
{
    UIViewController* controller = getParentViewController();
    
    if(UIInterfaceOrientationIsLandscape(controller.interfaceOrientation))
        return controller.view.frame.size.width;
    else
        return controller.view.frame.size.height;
}

static GADAdSize getSize(loom_adMobHandle size)
{
    switch (size) {
        case ADMOB_BANNER_SIZE_SMART_LANDSCAPE:
            return kGADAdSizeSmartBannerLandscape;
            break;
        case ADMOB_BANNER_SIZE_SMART_PORTRAIT:
            return kGADAdSizeSmartBannerPortrait;
            break;
        case ADMOB_BANNER_SIZE_STANDARD:
            return kGADAdSizeBanner;
            break;
        case ADMOB_BANNER_SIZE_TABLET_MEDIUM:
            return kGADAdSizeMediumRectangle;
            break;
        case ADMOB_BANNER_SIZE_TABLET_FULL:
            return kGADAdSizeFullBanner;
            break;
        case ADMOB_BANNER_SIZE_TABLET_LEADERBOARD:
            return kGADAdSizeLeaderboard;
            break;
        default:
            return kGADAdSizeSmartBannerLandscape;
            break;
    }
}

//_________________________________________________________________________
// Delegate
//_________________________________________________________________________
@interface LMAdDelegate : NSObject <GADInterstitialDelegate>
{
    loom_adMobCallback callback;
    void *payload;
}

-(id)initWithCallback:(loom_adMobCallback)cb andPayload:(void *)pl;

@end

@implementation LMAdDelegate

- (void)interstitialDidReceiveAd:(DFPInterstitial *)interstitial
{
    callback(payload, ADMOB_AD_RECEIVED, NULL);
}

- (void)interstitial:(DFPInterstitial *)interstitial didFailToReceiveAdWithError:(GADRequestError *)error
{
    callback(payload, ADMOB_AD_ERROR, [[error localizedDescription] cStringUsingEncoding:1]);
}

-(id)initWithCallback:(loom_adMobCallback)cb andPayload:(void *)pl
{
    self = [self init];
    
    callback = cb;
    payload = pl;
    
    return self;
}

@end

@interface LMAdBannerDelegate : NSObject <GADBannerViewDelegate>
{
    loom_adMobCallback callback;
    void *payload;
}

-(id)initWithCallback:(loom_adMobCallback)cb andPayload:(void *)pl;

@end

@implementation LMAdBannerDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    callback(payload, ADMOB_AD_RECEIVED, NULL);
}

- (void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error
{
    callback(payload, ADMOB_AD_ERROR, [[error localizedDescription] cStringUsingEncoding:1]);
}

-(id)initWithCallback:(loom_adMobCallback)cb andPayload:(void *)pl
{
    self = [self init];

    callback = cb;
    payload = pl;

    return self;
}

@end

//_________________________________________________________________________
// platformAdMob implementation
//_________________________________________________________________________

void platform_adMobInitalize(const char *publisherID)
{
    gPublisherId = [NSString stringWithUTF8String:publisherID];
}

loom_adMobHandle platform_adMobCreateInterstitial(const char *adUnitID, loom_adMobCallback callback, void *payload)
{
    int handle = gloom_adMobCounter++;
    
    // create our ad
    DFPInterstitial* ad = [[[DFPInterstitial alloc] init] retain];
    ad.adUnitID = [NSString stringWithUTF8String:adUnitID];
    [ad setDelegate:[[LMAdDelegate alloc] initWithCallback:callback andPayload:payload]];
    [ad loadRequest:[DFPRequest request]];

    [interstitialAds() setObject:ad forKey:[NSNumber numberWithInt:handle]];
    
    return handle;
}

void platform_adMobLoadInterstitial(loom_adMobHandle handle)
{
    DFPInterstitial* ad = getInterstitialView(handle);
    DFPRequest* request = [DFPRequest request];
    request.publisherProvidedID = gPublisherId;
    [ad loadRequest:request];
}

void platform_adMobShowInterstitial(loom_adMobHandle handle)
{
    DFPInterstitial* ad = getInterstitialView(handle);
    [ad presentFromRootViewController:getParentViewController()];
}

void platform_adMobDestroyInterstitial(loom_adMobHandle handle)
{
    
    DFPInterstitial* ad = getInterstitialView(handle);
    [interstitialAds() removeObjectForKey:[NSNumber numberWithInt:handle]];
    [ad release];
}

loom_adMobHandle platform_adMobCreate(const char *adUnitID, loom_adMobCallback callback, void *payload, loom_adMobBannerSize size)
{
    int handle = gloom_adMobCounter++;
    
    // create our banner ad
    DFPBannerView* banner = [[[DFPBannerView alloc] initWithAdSize:getSize(size)] retain];
    [bannerAds() setObject:banner forKey:[NSNumber numberWithInt:handle]];
    [banner setDelegate:[[LMAdBannerDelegate alloc] initWithCallback:callback andPayload:payload]];
    banner.adUnitID = [NSString stringWithUTF8String:adUnitID];
    banner.rootViewController = getParentViewController();
    
    int parentHeight = getScreenHeight();
    CGRect frame = banner.frame;
    frame.origin.y = parentHeight - frame.size.height;
    [banner setFrame:frame];
    
    return handle;
}

void platform_adMobLoad(loom_adMobHandle handle)
{
    DFPBannerView* banner = getBannerView(handle);
    DFPRequest* request = [DFPRequest request];
    request.publisherProvidedID = gPublisherId;
    [banner loadRequest: request];
}

void platform_adMobShow(loom_adMobHandle handle)
{
    DFPBannerView* banner = getBannerView(handle);
    [getParentViewController().view addSubview:banner];
}

void platform_adMobHide(loom_adMobHandle handle)
{
    
    DFPBannerView* banner = getBannerView(handle);
    [banner removeFromSuperview];
}

void platform_adMobDestroy(loom_adMobHandle handle)
{
    
    DFPBannerView* banner = getBannerView(handle);
    [banner removeFromSuperview];
    [bannerAds() removeObjectForKey:[NSNumber numberWithInt:handle]];
    [banner release];
}

void platform_adMobDestroyAll()
{
    NSArray* keys = [bannerAds() allKeys];
    for (int i=0; i<[keys count]; i++)
    {
        NSNumber* num = [keys objectAtIndex:i];
        platform_adMobDestroy([num intValue]);
    }
    
    NSArray* keys2 = [interstitialAds() allKeys];
    for (int i=0; i<[keys2 count]; i++)
    {
        NSNumber* num = [keys2 objectAtIndex:i];
        platform_adMobDestroyInterstitial([num intValue]);
    }
}

void platform_adMobSetDimensions(loom_adMobHandle handle, loom_adMobDimensions frame)
{
    
    DFPBannerView* banner = getBannerView(handle);
    float parentHeight = getScreenHeight();
    
    // reverse the Y position
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGRect rect = CGRectMake(frame.x / screenScale, frame.y / screenScale, frame.width / screenScale, frame.height / screenScale);
    
    banner.frame = rect;
}

loom_adMobDimensions platform_adMobGetDimensions(loom_adMobHandle handle)
{
    
    DFPBannerView* banner = getBannerView(handle);
    int parentHeight = getScreenHeight();
    
    CGFloat screenScale = [[UIScreen mainScreen] scale];

    CGRect rect = banner.frame;
    loom_adMobDimensions frame;
    frame.x = rect.origin.x * screenScale;
    frame.y = rect.origin.y * screenScale;
    frame.width = rect.size.width * screenScale;
    frame.height = rect.size.height * screenScale;
    
    return frame;
}

