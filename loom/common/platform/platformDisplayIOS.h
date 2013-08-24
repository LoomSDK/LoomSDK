/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#ifndef _PLATFORM_PLATFORMDISPLAYIOS_H_
#define _PLATFORM_PLATFORMDISPLAYIOS_H_

#include "loom/common/platform/platform.h"
#if LOOM_PLATFORM == LOOM_PLATFORM_IOS

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "platformDisplay.h"
#import <OpenGLES/ES1/gl.h>
#import <CoreMotion/CMMotionManager.h>

@interface platformDisplayIOS : UIResponder<UIApplicationDelegate, GLKViewDelegate, GLKViewControllerDelegate>
{
    CMMotionManager     *motionManager;
    NSMutableDictionary *touchIDs;
    int                 touchCount;
}
- (int)getTouchIDFor:(UITouch *)touch;
- (void)forgetTouchIDFor:(UITouch *)touch;

@end
#endif
#endif // _PLATFORM_PLATFORMDISPLAYIOS_H_
