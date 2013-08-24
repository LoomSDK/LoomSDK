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

#ifndef _ccloomcocos2d_h
#define _ccloomcocos2d_h

#include "loom/common/utils/utString.h"
#include "loom/script/native/lsNativeDelegate.h"

/**
 * Responsible for bridging Cocos2D state into LoomScript.
 */
class CCLoomCocos2d
{
    static utString displayCaption;
    static utString displayOrientation;
    static utString orientation;
    static int      displayWidth;
    static int      displayHeight;

public:

    static const utString OrientationLandscape;
    static const utString OrientationPortrait;
    static const utString OrientationAuto;

    LOOM_STATICDELEGATE(OrientationChanged);
    LOOM_STATICDELEGATE(DisplaySizeChanged);

    static void setDisplayCaption(const utString& caption)
    {
        displayCaption = caption;
    }

    static const utString& getDisplayCaption()
    {
        return displayCaption;
    }

    static void setDisplayOrientation(const utString& orientation)
    {
        displayOrientation = orientation;
    }

    static const utString& getDisplayOrientation()
    {
        return displayOrientation;
    }

    static void setOrientation(const utString& o)
    {
        orientation = o;

        _OrientationChangedDelegate.pushArgument(o.c_str());
        _OrientationChangedDelegate.invoke();
    }

    static const utString& getOrientation()
    {
        return orientation;
    }

    static int getDisplayWidth()
    {
        return displayWidth;
    }

    static int getDisplayHeight()
    {
        return displayHeight;
    }

    static void fireDisplaySizeDelegate();

    static void setDisplaySize(int width, int height)
    {
        if ((width == displayWidth) && (height == displayHeight))
        {
            return;
        }

        displayWidth  = width;
        displayHeight = height;

        fireDisplaySizeDelegate();
    }

    static void setDisplayWidth(int width)
    {
        if (width == displayWidth)
        {
            return;
        }

        displayWidth = width;

        fireDisplaySizeDelegate();
    }

    static void setDisplayHeight(int height)
    {
        if (height == displayHeight)
        {
            return;
        }

        displayHeight = height;

        fireDisplaySizeDelegate();
    }
};
#endif
