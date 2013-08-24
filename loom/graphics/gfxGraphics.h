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

#pragma once

#include <stdint.h>
#include "loom/common/core/assert.h"

namespace GFX
{
class Graphics
{
private:

    static bool sInitialized;
    static bool sContextLost;

    static void *sPlatformData[3];

    static int sWidth;
    static int sHeight;
    static int sFillColor;
    static int sView;

    static uint32_t sCurrentFrame;

    static void initializePlatform();

public:

    // this must be the
    static void initialize();

    static bool isInitialized()
    {
        return sInitialized;
    }

    static void reset(int width, int height, uint32_t flags = 0);

    static void shutdown();

    static void beginFrame();

    static void endFrame();

    static void handleContextLoss();

    static inline uint32_t getCurrentFrame() { return sCurrentFrame; }

    static inline int getWidth() { return sWidth; }
    static inline int getHeight() { return sHeight; }

    static void setViewTransform(float *view, float *proj);

    // sets the current view for drawing operations
    static inline void setView(int view)
    {
        sView = view;
    }

    static inline int getView()
    {
        return sView;
    }

    // bgfx uses void* for internal GL context creation, this will likely be
    // factored out to external platform code, but for now a necessary evil
    static void setPlatformData(void *data1, void *data2 = NULL, void *data3 = NULL)
    {
        sPlatformData[0] = data1;
        sPlatformData[1] = data2;
        sPlatformData[2] = data3;
    }

    static void setDebug(int flags);
    static void screenshot(const char *path);
    static void setFillColor(int color);
    static int getFillColor();

    // Set the clip rect and return an ID referencing it that is valid
    // for the current frame. This can be used in the other setClipRect
    // overload to save on setup overhead. Note you must set the cliprect
    // before every bgfx::submit call.
    static int setClipRect(int x, int y, int width, int height);
    static void setClipRect(int cached);

    // Render with no cliprect.
    static void clearClipRect();
};
}
