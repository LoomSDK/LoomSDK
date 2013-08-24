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

#include "CCLoomCocos2D.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/graphics/gfxGraphics.h"

const utString CCLoomCocos2d::OrientationLandscape = "landscape";
const utString CCLoomCocos2d::OrientationPortrait  = "portrait";
const utString CCLoomCocos2d::OrientationAuto      = "auto";

LS::NativeDelegate CCLoomCocos2d::_OrientationChangedDelegate;
LS::NativeDelegate CCLoomCocos2d::_DisplaySizeChangedDelegate;

int      CCLoomCocos2d::displayWidth       = 800;
int      CCLoomCocos2d::displayHeight      = 600;
utString CCLoomCocos2d::displayCaption     = "LoomApplication";
utString CCLoomCocos2d::displayOrientation = CCLoomCocos2d::OrientationLandscape;
utString CCLoomCocos2d::orientation        = CCLoomCocos2d::OrientationLandscape;

void CCLoomCocos2d::fireDisplaySizeDelegate()
{
    _DisplaySizeChangedDelegate.pushArgument(displayWidth);
    _DisplaySizeChangedDelegate.pushArgument(displayHeight);
    _DisplaySizeChangedDelegate.invoke();

    if (GFX::Graphics::isInitialized())
    {
        GFX::Graphics::reset(displayWidth, displayHeight);
    }
}
