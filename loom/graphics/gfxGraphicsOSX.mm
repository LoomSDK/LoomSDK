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

#include "loom/graphics/gfxGraphics.h"
#include "bgfxplatform.h"


namespace GFX
{
    void Graphics::initializePlatform()
    {
        // make sure we have a NSWindow at index 0, or a NSGLView and GLContext in 1 and 2
        lmAssert(sPlatformData[0] || (sPlatformData[1] && sPlatformData[2]), "Please make sure platform data is initialized");
        //bgfx::osxSetNSWindow(sPlatformData[0]);
        //bgfx::osxSetNSOpenGLView(sPlatformData[1]);
        //bgfx::osxSetNSOpenGLContext(sPlatformData[2]);
    }
}

