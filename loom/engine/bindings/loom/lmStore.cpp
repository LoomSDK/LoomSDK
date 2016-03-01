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

#include "loom/common/core/log.h"
#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/platform/platformStore.h"

using namespace LS;

lmDefineLogGroup(gNativeStoreLogGroup, "store", 1, 0);

/// Script bindings to the native Store API.
///
/// See NativeStore.ls for documentation on this API.
///
/// This class takes the low level C Store API and binds it to LoomScript, via
/// JSON and convenience methods.
class NativeStore
{
private:

    /// Event handler; this is called by the C store API when the Store has data
    /// to post back. We convert from JSON store events to calls to script delegates.
    static void eventCallback(const char *type, const char *payload)
    {
        json_error_t jerr;

        // Convert to delegate calls.
        lmLogDebug(gNativeStoreLogGroup, "Event type='%s' payload='%s'", type, payload);

        json_t *payloadJson = payload ? json_loads(payload, 0, NULL) : NULL;

        if (!strcmp(type, "product"))
        {
            // Parse the product data.
            const char *id     = NULL, *title = NULL, *description = NULL, *price = NULL;
            int        jsonRes = json_unpack_ex(payloadJson, &jerr, 0, "{s:s, s:s, s:s, s:s}",
                                                "productId", &id,
                                                "title", &title,
                                                "description", &description,
                                                "price", &price
                                                );

            // Pass to script.
            if (jsonRes == 0)
            {
                lmLogDebug(gNativeStoreLogGroup, "Saw product: %s %s %s %s", id, title, description, price);

                _OnProductDelegate.pushArgument(id);
                _OnProductDelegate.pushArgument(title);
                _OnProductDelegate.pushArgument(description);
                _OnProductDelegate.pushArgument(price);
                _OnProductDelegate.invoke();
            }
            else
            {
                lmLogError(gNativeStoreLogGroup, "Failed to parse product callback payload. JSON error: %s", jerr.text);
            }
        }
        else if (!strcmp(type, "productComplete"))
        {
            _OnProductCompleteDelegate.invoke();
        }
        else if (!strcmp(type, "uiComplete"))
        {
            _OnPurchaseUICompleteDelegate.invoke();
        }
        else if (!strcmp(type, "transaction"))
        {
            // Parse the transaction data.
            const char *productId = NULL, *txnId = NULL, *txnDate = NULL;
            int        success;

            int jsonRes2 = json_unpack_ex(payloadJson, &jerr, 0, "{s:s, s:s, s:s, s:i}",
                                          "productId", &productId,
                                          "transactionId", &txnId,
                                          "transactionDate", &txnDate,
                                          "successful", &success
                                          );

            // Pass to script.
            if (jsonRes2 == 0)
            {
                _OnTransactionDelegate.pushArgument(productId);
                _OnTransactionDelegate.pushArgument(txnId);
                _OnTransactionDelegate.pushArgument(txnDate);
                _OnTransactionDelegate.pushArgument(success == 0 ? false : true);
                _OnTransactionDelegate.invoke();
            }
            else
            {
                lmLogError(gNativeStoreLogGroup, "Failed to parse transaction callback payload. JSON error: %s", jerr.text);
            }
        }
        else
        {
            lmLogWarn(gNativeStoreLogGroup, "Encountered an unknown event type '%s'", type);
        }
    }

public:

    LOOM_STATICDELEGATE(OnProduct);
    LOOM_STATICDELEGATE(OnProductComplete);
    LOOM_STATICDELEGATE(OnPurchaseUIComplete);
    LOOM_STATICDELEGATE(OnTransaction);

    static void initialize()
    {
        lmLog(gNativeStoreLogGroup, "Initializing native store!");
        platform_storeInitialize(eventCallback);
    }

    static bool available()
    {
        return platform_storeAvailable() ? true : false;
    }

    static const char *providerName()
    {
        return platform_storeProviderName();
    }

    static void listProducts(const char *requestJson)
    {
        return platform_storeListProducts(requestJson);
    }

    static void requestPurchase(const char *identifier)
    {
        return platform_storeRequestPurchase(identifier);
    }
};

NativeDelegate NativeStore::_OnProductDelegate;
NativeDelegate NativeStore::_OnProductCompleteDelegate;
NativeDelegate NativeStore::_OnPurchaseUICompleteDelegate;
NativeDelegate NativeStore::_OnTransactionDelegate;

static int registerLoomNativeStore(lua_State *L)
{
    beginPackage(L, "loom.store")

       .beginClass<NativeStore>("NativeStore")
       .addStaticMethod("initialize", &NativeStore::initialize)

       .addStaticProperty("available", &NativeStore::available)
       .addStaticProperty("providerName", &NativeStore::providerName)

       .addStaticMethod("listProducts", &NativeStore::listProducts)
       .addStaticMethod("requestPurchase", &NativeStore::requestPurchase)

       .addStaticProperty("onProduct", &NativeStore::getOnProductDelegate)
       .addStaticProperty("onProductComplete", &NativeStore::getOnProductCompleteDelegate)
       .addStaticProperty("onPurchaseUIComplete", &NativeStore::getOnPurchaseUICompleteDelegate)
       .addStaticProperty("onTransaction", &NativeStore::getOnTransactionDelegate)
       .endClass()

       .endPackage();

    return 0;
}


void installLoomNativeStore()
{
    LOOM_DECLARE_NATIVETYPE(NativeStore, registerLoomNativeStore);
}
