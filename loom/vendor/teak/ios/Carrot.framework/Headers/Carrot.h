/* Carrot -- Copyright (C) 2012 GoCarrot Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <Foundation/Foundation.h>

typedef enum CarrotFacebookPermissionType {
   CarrotFacebookPermissionRead           = 0,  /**< Basic read permissions. */
   CarrotFacebookPermissionPublishActions = 1,  /**< 'publish_actions' write permission. */
   CarrotFacebookPermissionReadWrite      = 2   /**< Both read and write permissions.
                                                     (Will force non-iOS6 authentication with app-swaping.) */
} CarrotFacebookPermissionType;

typedef enum CarrotAuthenticationStatus {
   CarrotAuthenticationStatusNotAuthorized   = -1,/**< User has not authorized the application. */
   CarrotAuthenticationStatusUndetermined    = 0, /**< The authentication status for the user has
                                                       not yet been established. */
   CarrotAuthenticationStatusReadOnly        = 1, /**< User has authorized basic read permissions,
                                                       but not the 'publish_actions' permission. */
   CarrotAuthenticationStatusReady           = 2, /**< User has granted the 'publish_actions' permission
                                                       and Carrot can make Open Graph posts. */
} CarrotAuthenticationStatus;

typedef enum CarrotAuthenticationStatusReason {
   CarrotAuthenticationStatusReasonUserRemovedApp = -4,
   CarrotAuthenticationStatusReasonUserDeniedPermissions = -3,
   CarrotAuthenticationStatusReasonSessionExpired = -2,
   CarrotAuthenticationStatusReasonAppDisabledInSettings = -1,
   CarrotAuthenticationStatusReasonUnknown = 0,
   CarrotAuthenticationStatusReasonUnknownShowUser = 1,
   CarrotAuthenticationStatusReasonSessionExists = 2,
   CarrotAuthenticationStatusReasonNewSession = 3
} CarrotAuthenticationStatusReason;

#ifdef __OBJC__

#import <UIKit/UIKit.h>

/**
 * Block type for the completion of Carrot requests.
 *
 * Callback triggered on the completion of the following methods:
 * - getFriendScoresEx:
 * - getUserAchievementsEx:
 */
typedef void (^CarrotRequestResponseEx)(NSHTTPURLResponse* response, NSData* data);

@protocol CarrotDelegate;

/**
 * Allows you to interact with the Carrot service from your iOS/Mac OS application.
 *
 * Once a Carrot instance has been constructed, any calls to the following methods will
 * will be cached on the client and sent to the Carrot service once authentication has
 * occurred.
 *
 * - The postAchievement: method.
 * - The postHighScore: method.
 * - All variations of the postAction method
 * 	* postAction:forObjectInstance:
 * 	* postAction:withProperties:forObjectInstance:
 * 	* postAction:creatingInstanceOf:withProperties:
 * 	* postAction:withProperties:creatingInstanceOf:withProperties:
 * 	* postAction:withProperties:creatingInstanceOf:withProperties:andInstanceId:
 *
 * This means that a user may authenticate with Facebook at a much later date
 * and calls made to Carrot will still be transmitted to the server. Each Carrot
 * request is timestamped, so achievements earned will be granted at the date and time
 * the achievement was earned, instead of a when the request is processed.
 */
@interface Carrot : NSObject

/**
 * Set up Carrot in a single function call.
 *
 * This uses the Objective-C runtime to automatically install Carrot handlers for
 * getting the Facebook access token from the URL which is sent to your UIApplicationDelegate
 * when the -[application:openURL:sourceApplication:annotation:] message is recieved.
 *
 * If you use this function, you do not need to call handleOpenURL: or setAppSecret:.
 *
 * This function *must* be called from no other place than main() in your application's
 * 'main.m' or 'main.mm' file before UIApplicationMain() is called. Ex:
 *
 * 	int main(int argc, char *argv[])
 * 	{
 * 		@autoreleasepool {
 * 			// Add this line here.
 * 			[Carrot plantInApplication:[YourAppDelegate class] withSecret:@"your_app_secret"];
 *
 * 			return UIApplicationMain(argc, argv, nil, NSStringFromClass([YourAppDelegate class]));
 * 		}
 * 	}
 *
 * @param appDelegateClass Class of your application delegate, ex: [YourAppDelegate class].
 * @param appSecret        Your Carrot application secret.
 */
+ (void)plantInApplication:(Class)appDelegateClass withSecret:(NSString*)appSecret;

/**
 * Set up Carrot in a single function call.
 *
 * This uses the Objective-C runtime to automatically install Carrot handlers for
 * getting the Facebook access token from the URL which is sent to your UIApplicationDelegate
 * when the -[application:openURL:sourceApplication:annotation:] message is recieved.
 *
 * If you use this function, you do not need to call handleOpenURL: or setAppSecret:.
 *
 * This function *must* be called from no other place than main() in your application's
 * 'main.m' or 'main.mm' file before UIApplicationMain() is called. Ex:
 *
 * 	int main(int argc, char *argv[])
 * 	{
 * 		@autoreleasepool {
 * 			// Add this line here.
 * 			[Carrot plantInApplication:[YourAppDelegate class] appID:@"your_fb_app_id" withSecret:@"your_app_secret"];
 *
 * 			UIApplicationMain(argc, argv, nil, NSStringFromClass([YourAppDelegate class]));
 * 		}
 * 	}
 *
 * @param appID            Your Facebook Application ID.
 * @param appDelegateClass Class of your application delegate, ex: [YourAppDelegate class].
 * @param appSecret        Your Carrot application secret.
 */
+ (void)plant:(NSString*)appID inApplication:(Class)appDelegateClass withSecret:(NSString*)appSecret;

/**
 * Set up Carrot in a single function call.
 *
 * This uses the Objective-C runtime to automatically install Carrot handlers for
 * getting the Facebook access token from the URL which is sent to your UIApplicationDelegate
 * when the -[application:openURL:sourceApplication:annotation:] message is recieved.
 *
 * If you use this function, you do not need to call handleOpenURL: or setAppSecret:.
 *
 * This function *must* be called from no other place than main() in your application's
 * 'main.m' or 'main.mm' file before UIApplicationMain() is called. Ex:
 *
 * 	int main(int argc, char *argv[])
 * 	{
 * 		@autoreleasepool {
 * 			// Add this line here.
 * 			[Carrot plantInApplication:[YourAppDelegate class] appID:@"your_fb_app_id" urlSchemeSuffix:@"your_scheme_suffix" withSecret:@"your_app_secret"];
 *
 * 			return UIApplicationMain(argc, argv, nil, NSStringFromClass([YourAppDelegate class]));
 * 		}
 * 	}
 *
 * @param appID            Your Facebook Application ID.
 * @param appDelegateClass Class of your application delegate, ex: [YourAppDelegate class].
 * @param urlSchemeSuffix  URL Scheme Suffix of your Application.
 * @param appSecret        Your Carrot application secret.
 */
+ (void)plant:(NSString*)appID inApplication:(Class)appDelegateClass urlSchemeSuffix:(NSString*)urlSchemeSuffix withSecret:(NSString*)appSecret;

/**
 * The authentication status of the current user.
 */
@property (nonatomic, readonly) CarrotAuthenticationStatus authenticationStatus;

/**
 * The reason for the authentication status of the current user.
 */
@property (nonatomic, readonly) CarrotAuthenticationStatusReason authenticationStatusReason;

/**
 * CarrotDelegate which recieves action notifications.
 */
@property (weak, nonatomic, setter=setDelegate:) NSObject <CarrotDelegate>* delegate;

/**
 * The Facebook info of the current user, or nil.
 */
@property (strong, nonatomic, readonly) NSDictionary* facebookUser;

/**
 * The Facebook user access token of the current user, or nil.
 */
@property (strong, nonatomic, readonly) NSString* accessToken;

/**
 * The version string for the Carrot SDK
 */
@property (strong, nonatomic, readonly) NSString* version;

/**
 * An app-specified tag for associating metrics with A/B testing groups or
 * other purposes.
 *
 * @note This should be assigned as soon as possible after app launch.
 */
@property (strong, nonatomic) NSString* appTag;

/**
 * The date of install for this app, on this device.
 */
@property (strong, nonatomic, readonly) NSDate* installDate;

/**
 * Carrot singleton.
 *
 * Carrot will retrieve your Facebook application id in the same way that the Facebook SDK
 * does, by looking at the 'FacebookAppID' key in your Info.plist file. If an AppID is
 * assigned using setSharedAppID: or with  plant:inApplication:withSecret: that will
 * be used instead.
 *
 * @returns The shared instance of Carrot used by your application.
 */
+ (Carrot*)sharedInstance;

/**
 * Assign a Facebook Application ID.
 *
 * @note This must be done *before* the first call to sharedInstance: unless you are using
 *       plant:inApplication:withSecret: to set up Carrot.
 *
 * @param appID         Facebook Application ID.
 */
+ (void)setSharedAppID:(NSString*)appID;

/**
 * Assign a URL Scheme Suffix.
 *
 * If your application uses a URL Scheme Suffix, you should pass that suffix to
 * Carrot using this method.
 *
 * For more information, see:
 * https://developers.facebook.com/docs/howtos/share-appid-across-multiple-apps-ios-sdk/
 *
 * @note This must be done *before* the first call to sharedInstance: unless you are using
 *       plantInApplication:appID:urlSchemeSuffix:withSecret: to set up Carrot.
 *
 * @param schemeSuffix     URL Scheme Suffix to use for Facebook Authentication.
 */
+ (void)setSharedAppSchemeSuffix:(NSString*)schemeSuffix;

/**
 * Assign a debug UDID.
 *
 * @note If a debug UDID is desired it <b>must</b> be assigned before any other
 *       Carrot API call, including plantInApplication:appID:withSecret:
 *
 * @param debugUDID     The UDID to use for all Carrot functionality.
 */
+ (void)setDebugUDID:(NSString*)debugUDID;

/**
 * Perform Facebook Authentication required for Carrot.
 *
 * This will use the FacebookSDK.framework methods to perform the authentication needed for Carrot.
 *
 * @note If you are performing your own Facebook authentication, you do not need to use this
 *       method, however you must request the 'publish_actions' permission in order for Carrot
 *       to properly post Open Graph actions, and you must assign the OAuth access token using
 *       setAccessToken:.
 *
 * @param allowLoginUI  Controls if the Facebook Application/Browser should be allowed to
 *                      pop up the login UI.
 * @param permission    The permission type to request. FB/iOS standards suggest that you should
 *                      first ask only for read permissions, and then ask for write permissions
 *                      at the time when they are needed.
 *
 * @returns NO if there are not any registered Facebook accounts on the device (iOS 6 only); YES otherwise.
 */
+ (BOOL)performFacebookAuthAllowingUI:(BOOL)allowLoginUI
                        forPermission:(CarrotFacebookPermissionType)permission;

/**
 * Perform Facebook Authentication required for Carrot.
 *
 * This will use the FacebookSDK.framework methods to perform the authentication needed for Carrot.
 *
 * @note If you are performing your own Facebook authentication, you do not need to use this
 *       method, however you must request the 'publish_actions' permission in order for Carrot
 *       to properly post Open Graph actions, and you must assign the OAuth access token using
 *       setAccessToken:.
 *
 * @param allowLoginUI    Controls if the Facebook Application/Browser should be allowed to pop up the login UI.
 * @param permissionArray The permission type to request. FB/iOS standards suggest that you should first ask only for read permissions, and then ask for write permissions at the time when they are needed. A list of allowable permissions is available at https://developers.facebook.com/docs/reference/login
 *
 * @returns NO if there are not any registered Facebook accounts on the device (iOS 6 only); YES otherwise.
 */
+ (BOOL)performFacebookAuthAllowingUI:(BOOL)allowLoginUI
                   forPermissionArray:(NSArray*)permissionArray;

/**
 * Handle an openURL message from an external application.
 *
 * This method should be called during your UIApplicationDelegate's
 * -[application:openURL:sourceApplication:annotation:] implementation.
 *
 * @note You can allow Carrot to perform this for you by using plantInApplication:withSecret:
 *
 * @param url           URL passed to the message.
 *
 * @returns YES if the URL has been handled by the Carrot instance.
 *
 * @see plantInApplication:withSecret:
 */
- (BOOL)handleOpenURL:(NSURL*)url;

/**
 * Assign a Facebook access token.
 *
 * @note You can allow Carrot to perform this for you by using plantInApplication:withSecret:
 * @note You should call this method if you do not use the handleOpenURL: method.
 *
 * @param accessToken   Access token retrieved from Facebook.
 */
- (void)setAccessToken:(NSString*)accessToken;

/**
 * Assign a Carrot application secret.
 *
 * @note You can allow Carrot to perform this for you by using plantInApplication:withSecret:
 *
 * @param appSecret     Carrot application secret.
 */
- (void)setAppSecret:(NSString*)appSecret;

/**
 * Assign a push notification device token to the current Carrot user.
 *
 * @note You can allow Carrot to perform this for you by using plantInApplication:withSecret:
 *
 * @param deviceToken   Push notification device token.
 */
- (void)setDevicePushToken:(NSData*)deviceToken;

/**
 * Tell Carrot to start tracking session length.
 *
 * @note You can allow Carrot to perform this for you by using plantInApplication:withSecret:
 *
 * @param application    UIApplication for the session which is starting.
 */
- (void)beginApplicationSession:(UIApplication*)application;

/**
 * Tell Carrot to stop tracking session length.
 *
 * @note You can allow Carrot to perform this for you by using plantInApplication:withSecret:
 *
 * @param application    UIApplication for the session which is ending.
 */
- (void)endApplicationSession:(UIApplication*)application;

/**
 * Tell Carrot to send the install date metric if it hasn't already been sent.
 *
 * @note You can allow Carrot to perform this for you by using plantInApplication:withSecret:
 */
- (void)sendInstallMetricIfNeeded;

/**
 * Inform Carrot about a purchase of premium currency for metrics tracking.
 *
 * @param amount     The amount of real money spent.
 * @param currency   The type of real money spent (eg. USD).
 */
- (void)postPremiumCurrencyPurchase:(float)amount inCurrency:(NSString*)currency;

/**
 * Post an achievement to the Carrot service.
 *
 * @param achievementId The achievement identifier.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
- (BOOL)postAchievement:(NSString*)achievementId;

/**
 * Post a high score to the Carrot service.
 *
 * @param score         The value of the score to post.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
- (BOOL)postHighScore:(NSUInteger)score;

/**
 * Post an Open Graph action with an existing object to the Carrot service.
 *
 * @param actionId         The Carrot action id.
 * @param objectInstanceId The instance id of the Carrot object.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
- (BOOL)postAction:(NSString*)actionId forObjectInstance:(NSString*)objectInstanceId;

/**
 * Post an Open Graph action with an existing object to the Carrot service.
 *
 * @param actionId         The Carrot action id.
 * @param actionProperties The properties to send with the Carrot action.
 * @param objectInstanceId The instance id of the Carrot object.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
- (BOOL)postAction:(NSString*)actionId withProperties:(NSDictionary*)actionProperties forObjectInstance:(NSString*)objectInstanceId;

/**
 * Post an Open Graph action to the Carrot service creating a new object.
 *
 * @param actionId         The Carrot action id.
 * @param objectTypeId     The object id of the Carrot object type to create.
 * @param objectProperties The properties for the new object.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
- (BOOL)postAction:(NSString*)actionId creatingInstanceOf:(NSString*)objectTypeId withProperties:(NSDictionary*)objectProperties;

/**
 * Post an Open Graph action to the Carrot service creating a new object.
 *
 * @param actionId         The Carrot action id.
 * @param actionProperties The properties to send with the Carrot action.
 * @param objectTypeId     The object id of the Carrot object type to create.
 * @param objectProperties The properties for the new object.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
- (BOOL)postAction:(NSString*)actionId withProperties:(NSDictionary*)actionProperties creatingInstanceOf:(NSString*)objectTypeId withProperties:(NSDictionary*)objectProperties;

/**
 * Post an Open Graph action to the Carrot service creating a new object that specifies an instance id.
 *
 * If the instance id specified already exists on the server, it will be re-used
 * instead of creating a new instance.
 *
 * @param actionId         The Carrot action id.
 * @param actionProperties The properties to send with the Carrot action.
 * @param objectTypeId     The object id of the Carrot object type to create.
 * @param objectProperties The properties for the new object.
 * @param objectInstanceId The object instance id to create or re-use.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
- (BOOL)postAction:(NSString*)actionId withProperties:(NSDictionary*)actionProperties creatingInstanceOf:(NSString*)objectTypeId withProperties:(NSDictionary*)objectProperties andInstanceId:(NSString*)objectInstanceId;

/**
 * Post a 'Like' action that likes the Game's Facebook Page.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
-(BOOL)likeGame;

/**
 * Post a 'Like' action that likes the Publisher's Facebook Page.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
-(BOOL)likePublisher;

/**
 * Post a 'Like' action that likes an achievement.
 *
 * @param achievementId The achievement identifier.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
-(BOOL)likeAchievement:(NSString*)achievementId;

/**
 * Post a 'Like' action that likes an Open Graph object.
 *
 * @param objectInstanceId The instance id of the Carrot object.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
-(BOOL)likeObject:(NSString*)objectInstanceId;

@end
/**
 * Allows for notification of Carrot events of interest to your application.
 */
@protocol CarrotDelegate
@optional

/**
 * The status of user authentication has changed.
 *
 * @param status        Authentication status. @see CarrotAuthenticationStatus
 * @param error         Any error recieved, or nil if there was no error.
 */
- (void)authenticationStatusChanged:(int)status withError:(NSError*)error;

/**
 * A deep-link was recieved.
 *
 * @param targetURL     The target_url parameter of the deep-link from Facebook.
 */
- (void)applicationLinkRecieved:(NSURL*)targetURL;
@end

#endif /* __OBJC__ */

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*CarrotAuthStatusPtr)(const void* context, int status, NSError* error);
typedef void (*CarrotAppLinkPtr)(const void* context, const char* targetURL);

/**
 * Assign a Facebook Application ID.
 *
 * @note This must be done *before* the first call to any Carrot_ functions unless you are using
 *       plantInApplication:appID:withSecret: to set up Carrot.
 */
extern void Carrot_setSharedAppID(const char* appID);

/**
 * Check the authentication status of Carrot.
 *
 * @returns The authentication status of the current user. @see CarrotAuthenticationStatus
 */
extern int Carrot_AuthStatus();

/**
 * Assign a Carrot application secret.
 *
 * @param appSecret     Carrot application secret.
 */
extern void Carrot_SetAppSecret(const char* appSecret);

/**
 * Assign a Facebook access token.
 *
 * @param accessToken   Access token retrieved from Facebook.
 */
extern void Carrot_SetAccessToken(const char* accessToken);

/**
 * Post an achievement to the Carrot service.
 *
 * @param achievementId The achievement identifier.
 *
 * @returns 1 if the request was cached successfully, and will be sent when possible.
 */
extern int Carrot_PostAchievement(const char* achievementId);

/**
 * Post a high score to the Carrot service.
 *
 * @param score The value of the score to post.
 *
 * @returns 1 if the request was cached successfully, and will be sent when possible.
 */
extern int Carrot_PostHighScore(unsigned int score);

/**
 * Post an Open Graph action with an existing object to the Carrot service.
 *
 * @param actionId               The Carrot action id.
 * @param actionPropertiesJson   The properties to send with the Carrot action encoded as a JSON object, or NULL.
 * @param objectInstanceId       The instance id of the Carrot object.
 *
 * @returns 1 if the request was cached successfully, and will be sent when possible.
 */
extern int Carrot_PostInstanceAction(const char* actionId, const char* actionPropertiesJson,
                                     const char* objectInstanceId);

/**
 * Post an Open Graph action to the Carrot service creating a new object.
 *
 * @param actionId               The Carrot action id.
 * @param actionPropertiesJson   The properties to send with the Carrot action encoded as a JSON object, or NULL.
 * @param objectTypeId           The object id of the Carrot object type to create.
 * @param objectPropertiesJson   The properties for the new object encoded as a JSON object.
 * @param objectInstanceId       The object instance id for the newly created (or re-used object), or NULL.
 *
 * @returns 1 if the request was cached successfully, and will be sent when possible.
 */
extern int Carrot_PostCreateAction(const char* actionId, const char* actionPropertiesJson,
                                   const char* objectId, const char* objectPropertiesJson,
                                   const char* objectInstanceId);

/**
 * Perform Facebook Authentication required for Carrot.
 *
 * This will use the FacebookSDK.framework methods to perform the authentication needed for Carrot.
 *
 * @note If you are performing your own Facebook authentication, you do not need to use this
 *       method, however you must request the 'publish_actions' permission in order for Carrot
 *       to properly post Open Graph actions, and you must assign the OAuth access token using
 *       Carrot_SetAccessToken().
 *
 * @param allowLoginUI  This controls if the Facebook  Application/Browser should be allowed to pop up
 *                      the login UI.
 * @param permission    The permission type to request. FB/iOS standards suggest that you should
 *                      first ask only for read permissions, and then ask for write permissions
 *                      at the time when they are needed.
 *
 * @returns 0 if there are not any registered Facebook accounts on the device (iOS 6 only); 1 otherwise.
 */
extern int Carrot_DoFacebookAuth(int allowLoginUI, int permission);
extern int Carrot_DoFacebookAuthWithPermissions(int allowLoginUI, CFArrayRef permissions);

/**
 * Assign a delegate which calls the provided function pointers.
 *
 * @param authStatus    Authentication status has changed.
 * @param appLink       An application deep-link was called.
 */
extern void Carrot_AssignFnPtrDelegate(const void* context,
                                       CarrotAuthStatusPtr authStatus,
                                       CarrotAppLinkPtr appLink);


/**
 * Post a 'Like' action that likes the Game's Facebook Page.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
extern int Carrot_LikeGame();

/**
 * Post a 'Like' action that likes the Publisher's Facebook Page.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
extern int Carrot_LikePublisher();

/**
 * Post a 'Like' action that likes an achievement.
 *
 * @param achievementId The achievement identifier.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
extern int Carrot_LikeAchievement(const char* achievementId);

/**
 * Post a 'Like' action that likes an Open Graph object.
 *
 * @param objectInstanceId The instance id of the Carrot object.
 *
 * @returns YES if the request was cached successfully, and will be sent when possible.
 */
extern int Carrot_LikeObject(const char* objectInstanceId);

#ifdef __cplusplus
} /* extern "C" */
#endif
