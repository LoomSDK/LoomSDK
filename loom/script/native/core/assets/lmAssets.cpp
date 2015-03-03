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

#include "loom/common/assets/assets.h"
#include "loom/common/utils/utString.h"
#include "loom/common/utils/utByteArray.h"
#include "loom/common/core/log.h"
#include "loom/script/loomscript.h"

using namespace LS;

lmDefineLogGroup(gLoomTextAssetGroup, "loom.textAsset", 1, LoomLogInfo);

class LoomTextAsset
{
protected:
    NativeDelegate updateDelegate;

    static void handleAssetNotification(void *payload, const char *path);

    utString contents;
    utString path;

public:
    static LoomTextAsset *create(const char *path);

    void load();

    const char *getContents();
    const NativeDelegate *getUpdateDelegate() const;
};

LoomTextAsset *LoomTextAsset::create(const char *path)
{
    LoomTextAsset *lta = new LoomTextAsset();

    lta->path = path;
    return lta;
}


void LoomTextAsset::load()
{
    // Print a warning if user calls load with no delegates, as this
    // introduces a race condition.
    if (updateDelegate.getCount() == 0)
    {
        lmLog(gLoomTextAssetGroup, "Warning: calling LoomTextAsset::load for asset '%s' without anything added to its delegate! You are likely to miss asset updates/state.", path.c_str());
    }

    // Force it to load.
    loom_asset_lock(path.c_str(), LATText, 1);
    loom_asset_unlock(path.c_str());

    // And subscribe for updates.
    loom_asset_subscribe(path.c_str(), &LoomTextAsset::handleAssetNotification, (void *)this, 1);
}


void LoomTextAsset::handleAssetNotification(void *payload, const char *path)
{
    LoomTextAsset *assetThis = (LoomTextAsset *)payload;

    // Grab the asset so we can use it.
    const char *text = (const char *)loom_asset_lock(path, LATText, 1);

    assetThis->contents = text;
    loom_asset_unlock(path);

    // Trigger the update delegate.
    assetThis->updateDelegate.pushArgument(assetThis->path.c_str());
    assetThis->updateDelegate.pushArgument(assetThis->contents.c_str());
    assetThis->updateDelegate.invoke();
}


const char *LoomTextAsset::getContents()
{
    return contents.c_str();
}


const NativeDelegate *LoomTextAsset::getUpdateDelegate() const
{
    return &updateDelegate;
}

//-----------------------------------------------------------------------------

lmDefineLogGroup(gLoomBinaryAssetGroup, "loom.binaryAsset", 1, LoomLogInfo);

class LoomBinaryAsset
{
protected:
    NativeDelegate updateDelegate;

    static void handleAssetNotification(void *payload, const char *path);

    utByteArray *contents = NULL;
    utString path;

public:
    static LoomBinaryAsset *create(const char *path);

    void load();

    utByteArray* getContents();
    const NativeDelegate *getUpdateDelegate() const;
};

LoomBinaryAsset *LoomBinaryAsset::create(const char *path)
{
    LoomBinaryAsset *lta = new LoomBinaryAsset();

    lta->path = path;
    return lta;
}


void LoomBinaryAsset::load()
{
    // Print a warning if user calls load with no delegates, as this
    // introduces a race condition.
    if (updateDelegate.getCount() == 0)
    {
        lmLog(gLoomBinaryAssetGroup, "Warning: calling LoomBinaryAsset::load for asset '%s' without anything added to its delegate! You are likely to miss asset updates/state.", path.c_str());
    }

    // Force it to load.
    loom_asset_lock(path.c_str(), LATBinary, 1);
    loom_asset_unlock(path.c_str());

    // And subscribe for updates.
    loom_asset_subscribe(path.c_str(), &LoomBinaryAsset::handleAssetNotification, (void *)this, 1);
}


void LoomBinaryAsset::handleAssetNotification(void *payload, const char *path)
{
    LoomBinaryAsset *assetThis = (LoomBinaryAsset *)payload;

    // Grab the asset so we can use it.
    utByteArray *bytes = (utByteArray*) loom_asset_lock(path, LATBinary, 1);

    assetThis->contents = bytes;
    loom_asset_unlock(path);

    // Trigger the update delegate.
    assetThis->updateDelegate.pushArgument(assetThis->path.c_str());
    assetThis->updateDelegate.pushArgument(assetThis->contents);
    assetThis->updateDelegate.invoke();
}


utByteArray* LoomBinaryAsset::getContents()
{
    return contents;
}


const NativeDelegate *LoomBinaryAsset::getUpdateDelegate() const
{
    return &updateDelegate;
}


//-----------------------------------------------------------------------------

class LoomAssetManager
{
public:

    LOOM_STATICDELEGATE(PendingCountChange);

    static int pendingUpdateCount()
    {
        return loom_asset_queryPendingLoads() + loom_asset_queryPendingTransfers();
    }

    static void preload(const char *assetPath)
    {
        loom_asset_preload(assetPath);
    }

    static void flush(const char *assetPath)
    {
        loom_asset_flush(assetPath);
    }

    static void reload(const char *assetPath)
    {
        loom_asset_reload(assetPath);
    }

    static void flushAll()
    {
        loom_asset_flushAll();
    }

    static bool isConnected()
    {
        return loom_asset_isConnected() != 0;
    }
};

NativeDelegate LoomAssetManager::_PendingCountChangeDelegate;

void loom_asset_notifyPendingCountChange()
{
    // Push change to script.
    LoomAssetManager::_PendingCountChangeDelegate.pushArgument(LoomAssetManager::pendingUpdateCount());
    LoomAssetManager::_PendingCountChangeDelegate.invoke();
}


//-----------------------------------------------------------------------------

static int registerLoomTextAsset(lua_State *L)
{
    beginPackage(L, "loom")

       .beginClass<LoomTextAsset> ("LoomTextAsset")

       .addStaticMethod("create", &LoomTextAsset::create)

       .addMethod("getContents", &LoomTextAsset::getContents)
       .addMethod("load", &LoomTextAsset::load)
       .addVarAccessor("updateDelegate", &LoomTextAsset::getUpdateDelegate)

       .endClass()

       .endPackage();

    return 0;
}


static int registerLoomBinaryAsset(lua_State *L)
{
    beginPackage(L, "loom")

        .beginClass<LoomBinaryAsset>("LoomBinaryAsset")

        .addStaticMethod("create", &LoomBinaryAsset::create)

        .addMethod("getContents", &LoomBinaryAsset::getContents)
        .addMethod("load", &LoomBinaryAsset::load)
        .addVarAccessor("updateDelegate", &LoomBinaryAsset::getUpdateDelegate)

        .endClass()

        .endPackage();

    return 0;
}


static int registerLoomAssetManager(lua_State *L)
{
    beginPackage(L, "loom")

       .beginClass<LoomAssetManager> ("LoomAssetManager")

       .addStaticMethod("preload", &LoomAssetManager::preload)
       .addStaticMethod("flush", &LoomAssetManager::flush)
       .addStaticMethod("flushAll", &LoomAssetManager::flushAll)
       .addStaticMethod("pendingUpdateCount", &LoomAssetManager::pendingUpdateCount)
       .addStaticProperty("pendingCountChange", &LoomAssetManager::getPendingCountChangeDelegate)
       .addStaticMethod("isConnected", &LoomAssetManager::isConnected)

       .endClass()

       .endPackage();

    return 0;
}


void installLoomAssets()
{
    LOOM_DECLARE_NATIVETYPE(LoomTextAsset, registerLoomTextAsset);
    LOOM_DECLARE_NATIVETYPE(LoomBinaryAsset, registerLoomBinaryAsset);
    LOOM_DECLARE_NATIVETYPE(LoomAssetManager, registerLoomAssetManager);
}
