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


#ifndef _lmapplication_h
#define _lmapplication_h

#include "loom/common/core/stringTable.h"
#include "loom/common/platform/platformThread.h"

#include "loom/common/platform/platformThread.h"
#include "loom/common/platform/platformDisplay.h"
#include "loom/common/platform/platformTime.h"
#include "loom/common/platform/platformIO.h"
#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#include <jni.h>
#include "loom/common/platform/platformAndroidJni.h"
#endif

#include "seatest.h"

using namespace LS;

typedef void (*LoomGenericEventCallback)(void *userData, const char *type, const char *payload);

class LoomApplication
{
protected:
    static LSLuaState *rootVM;
    static bool       reloadQueued;
    static utString   bootAssembly;
    static bool       suppressAssetTriggeredReload;


    static void __handleMainAssemblyUpdate(void *payload, const char *asset);

public:

    static loom_precision_timer_t tickTimer;

    static NativeDelegate ticks;
    static NativeDelegate assetCommandDelegate;
    static NativeDelegate applicationDeactivated;
    static NativeDelegate applicationActivated;
    static NativeDelegate event;

    static const NativeDelegate *getAssetCommandDelegate()
    {
        return &assetCommandDelegate;
    }

    static const NativeDelegate *getApplicationActivatedDelegate()
    {
        return &applicationActivated;
    }

    static const NativeDelegate *getApplicationDeactivatedDelegate()
    {
        return &applicationDeactivated;
    }

    static const NativeDelegate *getTicksDelegate()
    {
        return &ticks;
    }

    static const NativeDelegate *getEventDelegate()
    {
        return &event;
    }

    static void fireGenericEvent(const char *type, const char *payload);
    static void listenForGenericEvents(LoomGenericEventCallback cb, void *userData);

    static LSLuaState *getRootVM()
    {
        return rootVM;
    }

    static bool getReloadQueued()
    {
        return reloadQueued;
    }

    static bool compilerEnabled();

    static const utString& getConfigJSON();

    static int initializeTypes();
    static int registerScriptTypes();
    static int initializeCoreServices();
    static int initialize();
    static void shutdown();
    static void execMainAssembly();
    static void reloadMainAssembly();
    static void _reloadMainAssembly();
    static void reloadAssets();

    static void setBootAssembly(const utString& assemblyName)
    {
        bootAssembly = assemblyName;
    }

    static const char *getBootAssembly()
    {
        return bootAssembly.c_str();
    }
};
#endif
