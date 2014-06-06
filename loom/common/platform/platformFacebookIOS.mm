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
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/NSSet.h>
#import "FBSession.h"
#import "FBWebDialogs.h"
#import "FBAccessTokenData.h"
#import "FBFrictionlessRecipientCache.h"
#import "FBError.h"
#import "FBErrorUtility.h"

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformFacebook.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(giOSFacebookLogGroup, "loom.facebook.ios", 1, 0);



static SessionStatusCallback gSessionStatusCallback = NULL;
static bool _initialized = false;
static const char *_facebookAppID = NULL;
static FBFrictionlessRecipientCache* gFriendCache = NULL;



@interface FacebookAPIiOS : NSObject

+(void)StatusCallback:(FBSession *)session status:(FBSessionState)status error:(NSError*)error;
+(NSArray *)parsePermissionString:(const char *)permissionsString;
+(BOOL)isSessionClosed:(FBSession *)session;

@end


@implementation FacebookAPIiOS

+(NSArray *)parsePermissionString:(const char *)permissionsString
{
    NSString *permissions = [NSString stringWithCString:permissionsString encoding:NSUTF8StringEncoding];
    NSArray *permissionArray = [permissions componentsSeparatedByString:@","];
    return permissionArray;
}


+(BOOL)isSessionClosed:(FBSession *)session
{
    return ((session.state == FBSessionStateClosedLoginFailed) || (session.state == FBSessionStateClosed)) ? YES : NO;
}


+(void)StatusCallback:(FBSession *)session status:(FBSessionState)status error:(NSError*)error
{
    if (error)
    {
        int errorCode = 0;
        NSLog(@"-=-=-=-=-=-=-Facebook Status Error!-=-=-=-=-=-=-=-");
        
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES)
        {
            NSLog(@"Something went wrong: %@", [FBErrorUtility userMessageForError:error]);
        }
        else 
        {
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) 
            {
                NSLog(@"User cancelled login");
            } 
            else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession)
            {
                // Handle session closures that happen outside of the app
                NSLog(@"Session Error: Your current session is no longer valid.");
            } 
            else 
            {
                // Here we will handle all other errors with a generic error message.
                // We recommend you check our Handling Errors guide for more information 
                // https://developers.facebook.com/docs/ios/errors/                
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                NSLog(@"Something went wrong: ErrorCode: %@", [errorInformation objectForKey:@"message"]);
            }
        }

        //get error code
        switch([FBErrorUtility errorCategoryForError:error])
        {
            case FBErrorCategoryRetry:
            case FBErrorCategoryAuthenticationReopenSession:
                errorCode = 1;  //RetryLogin
                break;
            case FBErrorCategoryUserCancelled:
                errorCode = 2;  //UserCancelled
                break;
            case FBErrorCategoryServer:
                errorCode = 3;  //ApplicationNotPermitted
                break;
            case FBErrorCategoryInvalid:
            case FBErrorCategoryPermissions:
            case FBErrorCategoryThrottling:
            case FBErrorCategoryFacebookOther:
            case FBErrorCategoryBadRequest:
                errorCode = 4;  //Unknown
                break;
        }

        NSLog(@"----FBStatusCallback errorCode: %d", errorCode);
        gSessionStatusCallback("", "", errorCode);
        return;
    }


    //state
    const char *sessionStateString = NULL;
    switch(session.state)
    {
        case FBSessionStateCreated:
        case FBSessionStateCreatedTokenLoaded:
        case FBSessionStateCreatedOpening:
            sessionStateString = "CREATED";
            break;
        case FBSessionStateOpen:
        case FBSessionStateOpenTokenExtended:
            sessionStateString = "OPENED";
            break;
        case FBSessionStateClosedLoginFailed:
        case FBSessionStateClosed:
            sessionStateString = "CLOSED";
            break;
    }

    //permissions
    static char permissionsStatic[1024];
    strcpy(permissionsStatic, "");
    NSArray *permissions = nil;
    if([session isOpen])
    {
        FBAccessTokenData *tokenData = [session accessTokenData];
        if(tokenData != nil)
        {
            permissions = [tokenData permissions];
            NSString *permissionsString = [permissions componentsJoinedByString:@","];
            const char *cString = [permissionsString cStringUsingEncoding:NSUTF8StringEncoding];
            if(cString != NULL)
            {
                strcpy(permissionsStatic, cString);
            }
        }
    }
    
    //do native callback
    NSLog(@"----FBStatusCallback state: %s   permissions: %s", sessionStateString, permissionsStatic);
    gSessionStatusCallback(sessionStateString, permissionsStatic, 0);
}

@end



bool checkFacebookAppId() 
{
    if((_facebookAppID == NULL) || (_facebookAppID[0] == '\0')) 
    {
        lmLog(giOSFacebookLogGroup, "No Facebook Application Id defined. Alter your 'loom.config' file, or 'Info.plist' file to use Loom.Facebook functionality.");
        return false;
    }
    return true;
}




void platform_facebookInitialize(SessionStatusCallback sessionStatusCB)
{
    gSessionStatusCallback = sessionStatusCB;

    //find the Facebook ID for later use; if not present, then log and don't do further initialization!
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *app_id = [mainBundle objectForInfoDictionaryKey:@"FacebookAppID"];
    // NSLog(@"-----Info.plist FacebookAppID String: %@", app_id);

     //don't initialize without valid strings
    _initialized = false;
    if([app_id isEqualToString:@""] == FALSE)
    {
        _initialized = true;
        _facebookAppID = [app_id cStringUsingEncoding:NSUTF8StringEncoding];

        //see if session exists first
        FBSession *session = [FBSession activeSession];
        if(!session)
        {
            ///create and set new session
            lmLog(giOSFacebookLogGroup, "FBSession does not exist at application startup: creating a new session.");
            session = [[FBSession alloc] initWithPermissions:@[@"public_profile"]];
            [FBSession setActiveSession: session];
        }

        //Occurs if Loom App has already logged into 
        if(session.state == FBSessionStateCreatedTokenLoaded)
        {
            lmLog(giOSFacebookLogGroup, "FBSession already has TokenLoaded at application startup: automatically opening the session.");
            [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                     completionHandler:^(FBSession *session, FBSessionState status, NSError *error)
                     {
                        [FacebookAPIiOS StatusCallback:session status:status error:error];
                     }];
        }
        lmLog(giOSFacebookLogGroup, "Facebook initialized successfully!!!");
    }
}

bool platform_openSessionWithReadPermissions(const char* permissionsString)
{
    if(checkFacebookAppId()) 
    {
        NSArray *permissions = [FacebookAPIiOS parsePermissionString:permissionsString];
        FBSession *session = [FBSession activeSession];

        //if a session exists and it has only been CREATED, we need to open it 
        if(session && ![session isOpen] && ![FacebookAPIiOS isSessionClosed:session])
        {
            //NOTE: Would really like to use [session requestNewReadPermissions] here insted of 
            //      re-creating a new session, but it HARD CRASHES on device all of the time without any information!
            // [session requestNewReadPermissions:permissions completionHandler:nil];
            //HACK: create brand new session with our desired permissions because 'requestNewReadPermissions' blows up!
            session = [[FBSession alloc] initWithPermissions:permissions];
            [FBSession setActiveSession: session];
            
            //open up new session with login dialog if necessary
            [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                     completionHandler:^(FBSession *session, FBSessionState status, NSError *error)
                     {
                        [FacebookAPIiOS StatusCallback:session status:status error:error];
                     }];
        }
        else
        {
            //session doesn't exist, or, session is already opened or has been closed
            if(!session)
            {
                //create new session if it doesn't exist
                [FBSession setActiveSession: [[FBSession alloc] init]];
            }
            [FBSession openActiveSessionWithReadPermissions:permissions
                        allowLoginUI:YES
                        completionHandler:^(FBSession *session, FBSessionState status, NSError *error)
                        {
                            [FacebookAPIiOS StatusCallback:session status:status error:error];
                        }];
        }
        return true;
    }
    return false;
}

bool platform_requestNewPublishPermissions(const char* permissionsString)
{
    if(checkFacebookAppId()) 
    {
        FBSession *session = [FBSession activeSession];
        if((session != nil) && [session isOpen])
        {
            NSArray *permissions = [FacebookAPIiOS parsePermissionString:permissionsString];
            [session requestNewPublishPermissions:permissions
                     defaultAudience:FBSessionDefaultAudienceFriends
                     completionHandler:nil];
            return true;
        }
    }
    return false;
}

void platform_showFrictionlessRequestDialog(const char* recipientsString, const char* titleString, const char* messageString)
{
    NSString *recipients = [NSString stringWithCString:recipientsString encoding:NSUTF8StringEncoding];
    NSString *message = [NSString stringWithCString:messageString encoding:NSUTF8StringEncoding];
    NSString *title = [NSString stringWithCString:titleString encoding:NSUTF8StringEncoding];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys: recipients, @"to", nil];
    if (gFriendCache == NULL) 
    {
        gFriendCache = [[FBFrictionlessRecipientCache alloc] init];
    }
    [gFriendCache prefetchAndCacheForSession:nil];

    //open up Frictionless Dialog
    // NSLog(@"----FB Frictionless Dialog message: %@, title: %@, recipients: %@", message, title, recipients);
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                    message:message
                    title:title
                    parameters:params
                    handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) 
                    {
                        if(error) 
                        {
                            NSLog(@"----FB Frictionless Dialog:  Error sending request.");
                        }
                        else 
                        {
                            if (result == FBWebDialogResultDialogNotCompleted) 
                            {
                                NSLog(@"----FB Frictionless Dialog:  User canceled request.");
                            } 
                            else 
                            {
                                NSLog(@"----FB Frictionless Dialog:  Request Sent.");
                            }
                        }
                    }
                    friendCache:gFriendCache];
}

const char* platform_getAccessToken()
{
    static char accessTokenStatic[1024];

    FBSession *session = [FBSession activeSession];
    if(session != nil)
    {
        FBAccessTokenData *tokenData = [session accessTokenData];
        if(tokenData != nil)
        {
            NSString *accessToken = [tokenData accessToken];
            const char *cString = [accessToken cStringUsingEncoding:NSUTF8StringEncoding];
            if(cString != NULL)
            {
                strcpy(accessTokenStatic, cString);
                return accessTokenStatic;
            }
        }
    }
    return "";
}

void platform_closeAndClearTokenInformation()
{
    FBSession *session = [FBSession activeSession];
    if(session != nil)
    {
        [session closeAndClearTokenInformation];
    }
}

const char* platform_getExpirationDate(const char *dateFormat)
{
    static char expirationStatic[1024];

    FBSession *session = [FBSession activeSession];
    if(session != nil)
    {
        FBAccessTokenData *tokenData = [session accessTokenData];
        if(tokenData != nil)
        {
            NSString *dateString = nil;
            NSDate *expirationDate = [tokenData expirationDate];
            if(expirationDate == nil)
            {
                expirationDate = [NSDate distantFuture];
            }

            ///format?
            if(dateFormat != NULL)
            {
                NSString *formatString = [NSString stringWithCString:dateFormat encoding:NSUTF8StringEncoding];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:formatString];
                dateString = [formatter stringFromDate:expirationDate];
            }
            else
            {
                dateString = [expirationDate description];
            }

            ///convert to const char* and return
            const char *cString = [dateString cStringUsingEncoding:NSUTF8StringEncoding];
            if(cString != NULL)
            {
                strcpy(expirationStatic, cString);
                return expirationStatic;
            }
        }
    }
    return "";
}


