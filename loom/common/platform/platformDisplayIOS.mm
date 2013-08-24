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

#import "platformDisplayIOS.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <QuartzCore/QuartzCore.h>

#include "loom/common/core/assert.h"

static UIWindow* window;

#include "loom/engine/cocos2dx/platform/ios/EAGLView.h"
#include "RootViewController.h"
#include "loom/engine/cocos2dx/platform/ios/CCApplication.h"

extern void display_init();

RootViewController *viewController = NULL;

display_profile display_getProfile()
{
   UIUserInterfaceIdiom idiom = [UIDevice currentDevice].userInterfaceIdiom;

   // Check for retina.
   if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0) 
   {
      return PROFILE_MOBILE_SMALL;
   }
   else
   {
      return PROFILE_MOBILE_LARGE;
   }
}

float display_getDPI()
{
   // Check for retina.
   if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
       ([UIScreen mainScreen].scale == 2.0)) 
   {
      return 326;
   }
   else
   {
      return 163;
   }
}

extern "C"
{
  int ios_debugOut(const char * __restrict format, ...)
  { 
      va_list args;
      va_start(args,format);    
      NSLogv([NSString stringWithUTF8String:format], args) ;    
      va_end(args);
      return 1;
  }  
}

#endif