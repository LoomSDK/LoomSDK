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


#ifndef _ASSETSYSTEM_ASSETSYSTEM_H_
#define _ASSETSYSTEM_ASSETSYSTEM_H_

#include "loom/common/utils/fourcc.h"
#include "loom/common/platform/platformThread.h"

#ifdef __cplusplus
extern "C" {
#endif

/************************************************************************
* Loom Asset System
*
* A game is nothing without its assets: textures, sprites, sounds, config
* data, scripts, and so forth. Loom's asset system deals with the
* complexity of streaming, decompressing, deserializing, and tracking
* loaded assets so you can focus on writing game code.
*
* WORKING WITH ASSETS
*
* Working with assets is simple. Just lock them to get a pointer to the
* asset's data, and unlock them when you are done with that data:
*
*       loom_asset_image_t *img = loom_asset_lock("foo.jpg", LATImage, 1);
*       // Do something with the asset!
*       loom_asset_unlock("foo.jpg"); // Don't use img after this point!
*
* ASSET SUBSCRIPTION
*
* The above example will block until the asset is loaded, if it isn't
* already. (The third parameter to loom_asset_lock controls this.) If
* you want to avoid hitching, preload assets and subscribe to be notified
* when the asset is loaded or modified:
*
*    loom_asset_subscribe("foo.jpg", myCallback, NULL);
*    loom_asset_preload("foo.jpg");
*
*    void myCallback(const char *name, void *payload)
*    {
*       loom_log("Texture %s changed, instating changes!", name);
*       loom_asset_image_t *img = loom_asset_lock(name, LATImage, 0);
*       // Do something with the asset!
*       loom_asset_unlock(name);
*    }
*
* WAITING ON ASSETS
*
* If you want to wait until all pending assets are loaded, you can ask the
* asset manager to tell you if it has more to load:
*
*    if(loom_asset_queryPendingLoads()) keepShowingLoadingScreen();
*
* UNLOADING ASSETS
*
* Just call loom_asset_flush("foo.jpg") to unload an asset from memory. You
* can also do loom_asset_flushAll() to unload everything.
*
* HOT RELOADING
*
* If you subscribe to assets, and your callback properly kicks old users of an
* asset over to the new version, then you'll automatically see modifications to
* asset source files appear in the game! You can also use
* loom_asset_reload("foo.jpg") or loom_asset_reloadAll() to force assets to be
* reloaded from their source files.
*
* CUSTOM ASSET TYPES
*
* assetImage.c is a good example for adding your own asset types. Simply call
* loom_asset_registerType(), providing the unique asset type fourcc, a
* callback to deserialize the asset, and a function that can tell what fourcc
* corresponds to a given extension, and the asset manager will handle your asset!
*
************************************************************************/

// Assorted built-in asset types, for convenience.
enum LoomAssetType
{
    LATXML          = LOOM_FOURCC('X', 'M', 'L', 1),
    LATText         = LOOM_FOURCC('T', 'X', 'T', 1),
    LATMesh         = LOOM_FOURCC('M', 'S', 'H', 1),
    LATScript       = LOOM_FOURCC('L', 'O', 'O', 'M'),
    LAT_FORCE_DWORD = 0xFFFFFFFF
};

void loom_asset_initialize(const char *rootUri);
void loom_asset_pump();
void loom_asset_waitForConnection(int msToWait);
void loom_asset_shutdown();

typedef void (*LoomAssetCleanupCallback)(void*);
typedef void *(*LoomAssetDeserializeCallback)(void *buffer, size_t bufferLen, LoomAssetCleanupCallback *dtor);
typedef int (*LoomAssetRecognizerCallback)(const char *extension);
void loom_asset_registerType(unsigned int type, LoomAssetDeserializeCallback deserializer, LoomAssetRecognizerCallback recognizer);

// This is called when the asset agent sends us commands.
typedef void (*LoomAssetCommandCallback)(const char *command);
void loom_asset_setCommandCallback(LoomAssetCommandCallback callback);

void loom_asset_preload(const char *name);

void loom_asset_flush(const char *name);
void loom_asset_flushAll();

void loom_asset_reload(const char *name);
void loom_asset_reloadAll();

int loom_asset_isConnected();

int loom_asset_queryPendingTransfers();
int loom_asset_queryPendingLoads();
float loom_asset_checkLoadedPercentage(const char *name);              // Is asset loaded? Returns 1.f if so, or fraction if not.

void *loom_asset_lock(const char *name, unsigned int type, int block); // Acquire lock to data payload of asset.
void loom_asset_unlock(const char *name);                              // Unlock asset.

// Supply an asset's raw bits. Useful for embedding assets in your binary.
void loom_asset_supply(const char *name, void *bits, int length);

typedef void (*LoomAssetChangeCallback)(void *payload, const char *name);
int loom_asset_subscribe(const char *name, LoomAssetChangeCallback cb, void *payload, int doFirstUpdate);
void loom_asset_notifySubscribers(const char *name);
int loom_asset_unsubscribe(const char *name, LoomAssetChangeCallback cb, void *payload);

#ifdef __cplusplus
};
#endif
#endif
