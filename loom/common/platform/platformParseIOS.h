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

#ifndef _LOOM_COMMON_PLATFORM_PLATFORMPARSEIOS_H_
#define _LOOM_COMMON_PLATFORM_PLATFORMPARSEIOS_H_


// wrapper functions for internal Parse functionality for iOS
#if LOOM_PLATFORM == LOOM_PLATFORM_IOS

#import <Foundation/Foundation.h>
#import <Foundation/NSSet.h>

@interface ParseAPIiOS : NSObject

+(void)initialize;
+(void)registerForRemoteNotifications:(NSData *)deviceToken;
+(void)failedToRegister:(NSError *)code;
+(void)handleRemoteNotification:(NSDictionary *)info;
+(void)receivedRemoteNotification:(NSDictionary *)userInfo;

@end

#endif


#endif //_LOOM_COMMON_PLATFORM_PLATFORMPARSEIOS_H_