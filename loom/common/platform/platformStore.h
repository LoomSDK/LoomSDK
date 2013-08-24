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

#ifndef _LOOM_COMMON_PLATFORM_PLATFORMSTORE_H_
#define _LOOM_COMMON_PLATFORM_PLATFORMSTORE_H_

/**
 * Loom Store API
 *
 * For store support, Loom includes a cross-platform native store API. This
 * abstraction handles the details of talking to iTunes, Play, or other stores.
 * It is designed for simplicity of implementation/portability and not convenience
 * of API; the LoomScript Store API adapts the native API to be convenient and
 * easy to use.
 *
 * Native code may find this store API the easiest to use.
 *
 * Futher stores may be added by providing implementations of these functions
 * and adding appropriate #ifdefs. You will see that on Android we bridge to
 * a Java store API wrapper via JNI and on iOS we use StoreKit via Objective C.
 *
 * In the case of e.g. adding support for a further Android store beyond Play,
 * you would want to implement this support in LoomStore.java rather than having
 * two "native store" implementations running in parallel.
 *
 */

/// Types of events that the store API posts.
enum LoomStoreEventTypes
{
    /// Fired when a product's info is available after a call to
    /// platform_storeListProducts - payload is a JSON descriptor
    /// of the product (see NativeStoreProvider.ls for details on
    /// parsing this).
    LoomStoreProduct,

    /// Fired when all pending products have returned information.
    LoomStoreProductsComplete,

    /// Fired when the store-provided purchase UI has gone away.
    LoomStorePurchaseUIComplete,

    /// Fired when a transaction is available; may results from call
    /// to platform_storeInitialize or a call to platform_storeRequestPurchase.
    /// See NativeStoreProvider.ls for details on parsing the JSON in
    /// payload.
    LoomStoreTransaction,
};

/// Callback for store API events.
typedef void (*StoreEventCallback)(const char *type, const char *payload);

/// Initialize the store with a single event handler callback.
void platform_storeInitialize(StoreEventCallback eventCallback);

/// Returns non-zero if the native store is active and can accept payments.
int platform_storeAvailable();

/// A string identifying the provider for the native store (ie, "iTunes Store",
/// "Play Store").
const char *platform_storeProviderName();

/// Given a JSON array of string product identifiers, issues a request to the
/// store API and posts results back via the store event callback.
void platform_storeListProducts(const char *requestJson);

/// Request purchase for a given product identifier. Results are posted back
/// via the store event callback.
void platform_storeRequestPurchase(const char *identifier);
#endif
