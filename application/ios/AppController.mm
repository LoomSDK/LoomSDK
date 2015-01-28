/****************************************************************************
 Copyright (c) 2010 cocos2d-x.org
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/
#import <UIKit/UIKit.h>
#import "AssetsLibrary/AssetsLibrary.h"
#import "AppController.h"
#import "cocos2d.h"
#import "EAGLView.h"
#import "../common/AppDelegate.h"

#import "RootViewController.h"
#import "FBAppCall.h"

#include "loom/engine/bindings/loom/lmApplication.h"
#include "loom/common/platform/platformMobileiOS.h"



static void handleGenericEvent(void *userData, const char *type, const char *payload)
{
    RootViewController *ac = (RootViewController*)userData;
    [ac handleGenericEvent: type withPayload: payload];
}

@implementation AppController

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
    // Listen for generic events.
    LoomApplication::listenForGenericEvents(handleGenericEvent, (void*)self);

    // Add the view controller's view to the window and display.
    window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    EAGLView *glView = [EAGLView viewWithFrame: [window bounds]
                                        pixelFormat: kEAGLColorFormatRGBA8
                                        depthFormat: GL_DEPTH_COMPONENT16
                                 preserveBackbuffer: NO
                                         sharegroup: nil
                                      multiSampling: NO
                                    numberOfSamples: 0];
    
    // Use RootViewController manage EAGLView 
    viewController = [[RootViewController alloc] initWithNibName:nil bundle:nil];
    viewController.wantsFullScreenLayout = YES;
    viewController.view = glView;
   
    // Enable multitouch.
    [glView setMultipleTouchEnabled:YES];

    // Set RootViewController to window
    if ( [[UIDevice currentDevice].systemVersion floatValue] < 6.0)
    {
        // warning: addSubView doesn't work on iOS6
        [window addSubview: viewController.view];
    }
    else
    {
        // use this method on ios6
        [window setRootViewController:viewController];
    }
    
    [window makeKeyAndVisible];

    [[UIApplication sharedApplication] setStatusBarHidden: YES];
    
    // Parse setup for Push Notifications
    parse = nil;
#if LOOM_ALLOW_FACEBOOK
    parse = [[ParseAPIiOS alloc] init];
    [parse initialize];
#endif

    // Store potential Remote Notification Dictionary in iOS6 and lower (iOS7+ will call the notification fetchCompletionHandler on notification launching)
    if([[UIDevice currentDevice].systemVersion floatValue] < 7.0)
    {
        NSDictionary *rnPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        if((rnPayload != nil) && ([rnPayload count]))
        {
            [self application:application didReceiveRemoteNotification:rnPayload];
        }
    }

    cocos2d::CCApplication::sharedApplication().run();
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSBundle *mainBundle = [NSBundle mainBundle];

    //Custom App URL Scheme Launch?
    NSString *customAppScheme = [mainBundle objectForInfoDictionaryKey:@"CustomAppURLScheme"];
    if((customAppScheme != nil) && 
        ([customAppScheme isEqualToString:@""] == FALSE) && 
        ([[url scheme] caseInsensitiveCompare:customAppScheme] == NSOrderedSame))
    {
        //attempt to parse the query
        [self application:application handleOpenURLQuery:[url query]];
        
        //mark as being opened from a custrom URL and call our native callback
        ios_CustomURLOpen();
    }
    else
    {
#if LOOM_ALLOW_FACEBOOK
        //Facebook Scheme Launch?
        NSString *app_id = [mainBundle objectForInfoDictionaryKey:@"FacebookAppID"];
        if((app_id != nil) && ([app_id isEqualToString:@""] == FALSE))
        {
            NSString *fbScheme = [NSString stringWithFormat:@"%@%@", @"fb", app_id];
            if([[url scheme] isEqualToString:fbScheme])
            {
                // handle Facebook sign in re-launching the application
                NSLog(@"---------Facebook openURL: %@", [url absoluteString]);
                return [FBSession.activeSession handleOpenURL:url];
            }
        }
#endif
    }
    return YES;
}


// called when the application is opened via a Custom URL Scheme
- (void)application:(UIApplication *)application handleOpenURLQuery:(NSString *)query
{
    gOpenUrlQueryStringDictionary = nil;
    if(query)
    {
        // build a dictionary and store the Open URL query there in key/data pairs
        NSLog(@"---------Open URL Query String: %@", query);

        gOpenUrlQueryStringDictionary = [[NSMutableDictionary alloc] init];
        NSArray *queryComponents = [query componentsSeparatedByString:@"&"];
        for (NSString *keyValuePair in queryComponents)
        {
            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            if((pairComponents != nil) && ([pairComponents count] == 2))
            {
                NSString *key = [pairComponents objectAtIndex:0];
                NSString *value = [pairComponents objectAtIndex:1];
                [gOpenUrlQueryStringDictionary setObject:value forKey:key];
            }
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    cocos2d::CCDirector::sharedDirector()->pause();
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    cocos2d::CCDirector::sharedDirector()->resume();

#if LOOM_ALLOW_FACEBOOK
    // Handle the user leaving the app while the Facebook login dialog is being shown
    // For example: when the user presses the iOS "home" button while the login dialog is active
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *app_id = [mainBundle objectForInfoDictionaryKey:@"FacebookAppID"];
    if((app_id != nil) && ([app_id isEqualToString:@""] == FALSE))
    {
        NSLog(@"---------Application Did Become Active: Notifying Facebook");
        [FBAppCall handleDidBecomeActive];    
    }
#endif
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    cocos2d::CCApplication::sharedApplication().applicationDidEnterBackground();
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    cocos2d::CCApplication::sharedApplication().applicationWillEnterForeground();
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    /// Parse Push Notifications
    if(parse)
    {
        NSLog(@"---------Registered Parse for Remote Notifications");
        [parse registerForRemoteNotifications: deviceToken];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    /// Parse Push Notifications
    if(parse)
    {
        NSInteger code = [error code];
        NSString *codeString = [NSString stringWithFormat:@"Error code: %ld",(long)code];
        NSLog(@"---------Failed to register Parse for Remote Notifications: %@", codeString);
        [parse failedToRegister: error];        
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    ///just pass this on through to the fetchCompletionHandler as this function happens in iOS6- and the other in iOS7+
    [self application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
    // Store potential Remote Notification Dictionary
    gRemoteNotificationPayloadDictionary = [[NSDictionary alloc] initWithDictionary:userInfo];
    ios_RemoteNotificationOpen();

    /// Parse Push Notifications registration
    if(parse)
    {
        NSLog(@"---------Received Remote Notification: sending through to Parse");
        [parse receivedRemoteNotification: userInfo];        
    }

    //notify the handler that we're done now
    if(handler != nil)
    {
        handler(UIBackgroundFetchResultNoData);
    }
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark Generic app events
-(void)handleGenericEvent:(const char*)type withPayload: (const char*)payload
{
    NSLog(@"Got generic event: %s %s", type, payload);

    if(!strcmp(type, "cameraRequest"))
    {
        // Pop the camera view up.
        UIImagePickerController *imagePickController = [[UIImagePickerController alloc]init];
        imagePickController.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePickController.delegate = self;
        imagePickController.allowsEditing = TRUE;
        [viewController presentModalViewController:imagePickController animated:YES];
        [imagePickController release];   
    }
    else if(!strcmp(type, "showStatusBar"))
    {
        [[UIApplication sharedApplication] setStatusBarHidden: NO];
    }
    else if(!strcmp(type, "hideStatusBar"))
    {
        [[UIApplication sharedApplication] setStatusBarHidden: YES];
    }
    else if(!strcmp(type, "saveToPhotoLibrary"))
    {
        NSString *path = [NSString stringWithUTF8String:payload];
        NSObject *dataObject = [NSData dataWithContentsOfFile:path];

        // If we're not looking in the app bundle already, try looking in there.
        if(dataObject == nil && [path rangeOfString:[[NSBundle mainBundle] resourcePath] options:NSCaseInsensitiveSearch].location == NSNotFound)
        {
            NSString *inBundlePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], path];
            dataObject = [NSData dataWithContentsOfFile:inBundlePath];
        }

        if(dataObject == nil)
        {
            LoomApplication::fireGenericEvent("saveToPhotoLibraryFail", "badPath");
        }
        else
        {
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeImageDataToSavedPhotosAlbum:dataObject metadata:nil completionBlock:^(NSURL *assetURL, NSError *error)
            {
                if (error)
                {
                    NSString *errorType = [error localizedDescription];
                    if ([error code] == ALAssetsLibraryAccessGloballyDeniedError || [error code] == ALAssetsLibraryAccessUserDeniedError)
                    {
                        errorType = @"accessDenied";
                    }

                    LoomApplication::fireGenericEvent("saveToPhotoLibraryFail", [errorType UTF8String]);
                }
                else
                {
                    LoomApplication::fireGenericEvent("saveToPhotoLibrarySuccess", [[assetURL absoluteString] UTF8String]);
                }
            }];

            [library release];
        }
    }

    return 0;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Save image to a file.
    UIImage *editedImage = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    NSData *data = [NSData dataWithData:UIImageJPEGRepresentation(editedImage, 0.8f)];

    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    
    static int snapshotCount = 1000;
    snapshotCount++;
    
    NSString *snapshotString = [NSString stringWithFormat:@"snapshot%d", snapshotCount];
    NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:snapshotString] URLByAppendingPathExtension:@"jpg"];

    [data writeToURL:fileURL atomically:YES];

    // Hide the view.
    [viewController dismissModalViewControllerAnimated:YES];

    // And return path to the app.
    NSString *imageString = [[fileURL filePathURL] path];
    LoomApplication::fireGenericEvent("cameraSuccess", [imageString cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    // Hide the view.
    [viewController dismissModalViewControllerAnimated:YES];

    LoomApplication::fireGenericEvent("cameraFail", "cancel");
}

@end

