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

#include "loom/common/platform/platform.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include <jni.h>
#include "platformAndroidJni.h"

#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/platform/platformStore.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(gGoogleStoreLogGroup, "googleplay", 1, LoomLogDefault);

static StoreEventCallback gEventCallback = NULL;

// Matching the enum in LoomStore.java
enum NativeCallbackType
{
    DETAILS_FAILURE, DETAILS_SUCCESS, PURCHASE_SUCCESS, PURCHASE_FAILURE, CONSUME_SUCCESS, CONSUME_FAILURE, DETAILS_COMPLETED
};

extern "C"
{
void Java_co_theengine_loomdemo_billing_LoomStore_nativeCallback(JNIEnv *env, jobject thiz, jint callbackType, jstring data)
{
    lmLogError(gGoogleStoreLogGroup, "LoomStore Android Callback fired! %d", callbackType);

    const char *dataString = env->GetStringUTFChars(data, 0);

    if (gEventCallback)
    {
        const char *typeString = NULL;

        switch (callbackType)
        {
        case DETAILS_FAILURE:
            gEventCallback("error", dataString);
            break;

        case DETAILS_SUCCESS:
            lmLogError(gGoogleStoreLogGroup, "Product! %s", dataString);
            gEventCallback("product", dataString);
            break;

        case DETAILS_COMPLETED:
            lmLogError(gGoogleStoreLogGroup, "Product list complete.");
            gEventCallback("productComplete", NULL);
            break;

        case PURCHASE_FAILURE:
            // Note the UI completed regardless.
            gEventCallback("uiComplete", NULL);
            gEventCallback("error", dataString);
            break;

        case PURCHASE_SUCCESS:
            // Note the UI completed regardless.
            gEventCallback("uiComplete", NULL);

            // And pass the transaction back.
            gEventCallback("transaction", dataString);

            break;

        case CONSUME_FAILURE:
            gEventCallback("error", dataString);
            break;

        case CONSUME_SUCCESS:
            typeString = "consume.success";
            break;

        default:
            lmLogError(gGoogleStoreLogGroup, "Got Play Store event of type %d but don't know how to handle it, ignoring...", callbackType);
            break;
        }
    }
    else
    {
        lmLogError(gGoogleStoreLogGroup, "Got Play Store event of type %d but had no event callback, ignoring...", callbackType);
    }

    env->ReleaseStringUTFChars(data, dataString);
}
}

static loomJniMethodInfo gPurchaseProductMethodInfo;
static loomJniMethodInfo gPushProductMethodInfo;
static loomJniMethodInfo gLoadProductsMethodInfo;
static loomJniMethodInfo gIsAvailableMethodInfo;
static loomJniMethodInfo gQueryPurchasesMethodInfo;

void platform_storeInitialize(StoreEventCallback eventCallback)
{
    //lmAssert(gEventCallback == NULL, "Cannot initialize twice!");
    gEventCallback = eventCallback;

    lmLogDebug(gGoogleStoreLogGroup, "Initializing Store for Android");

    // Bind to JNI entry points.
    LoomJni::getStaticMethodInfo(gPurchaseProductMethodInfo,
                                 "co/theengine/loomdemo/billing/LoomStore",
                                 "purchaseProduct",
                                 "(Ljava/lang/String;)V");

    LoomJni::getStaticMethodInfo(gPushProductMethodInfo,
                                 "co/theengine/loomdemo/billing/LoomStore",
                                 "pushProduct",
                                 "(Ljava/lang/String;)V");

    LoomJni::getStaticMethodInfo(gLoadProductsMethodInfo,
                                 "co/theengine/loomdemo/billing/LoomStore",
                                 "loadProducts",
                                 "()V");

    LoomJni::getStaticMethodInfo(gIsAvailableMethodInfo,
                                 "co/theengine/loomdemo/billing/LoomStore",
                                 "isAvailable",
                                 "()Z");

    LoomJni::getStaticMethodInfo(gQueryPurchasesMethodInfo,
                                 "co/theengine/loomdemo/billing/LoomStore",
                                 "queryInventory",
                                 "()V");


    // Kick off query.
    gQueryPurchasesMethodInfo.getEnv()->CallStaticVoidMethod(gQueryPurchasesMethodInfo.classID, gQueryPurchasesMethodInfo.methodID);
}


int platform_storeAvailable()
{
    return gIsAvailableMethodInfo.getEnv()->CallStaticBooleanMethod(gIsAvailableMethodInfo.classID, gIsAvailableMethodInfo.methodID);
}


const char *platform_storeProviderName()
{
    return "Play Store";
}


void platform_storeListProducts(const char *requestJson)
{
    // Parse the request list.
    json_t *requestList = json_loads(requestJson, 0, NULL);

    // Parse out the list.
    lmAssert(json_is_array(requestList), "Got non-array.");

    // Push the requests
    for (int i = 0; i < json_array_size(requestList); i++)
    {
        json_t *item = json_array_get(requestList, i);
        lmAssert(json_is_string(item), "Got non-string.");

        const char *itemStr = json_string_value(item);
        lmAssert(itemStr != NULL, "Got a NULL string somehow!");

        jstring jProductID = gPushProductMethodInfo.getEnv()->NewStringUTF(itemStr);
        gPushProductMethodInfo.getEnv()->CallStaticVoidMethod(gPushProductMethodInfo.classID, gPushProductMethodInfo.methodID, jProductID);
        gPushProductMethodInfo.getEnv()->DeleteLocalRef(jProductID);
    }

    // Kick off the request.
    gLoadProductsMethodInfo.getEnv()->CallStaticVoidMethod(gLoadProductsMethodInfo.classID, gLoadProductsMethodInfo.methodID);
}


void platform_storeRequestPurchase(const char *identifier)
{
    jstring jIdentifier = gPurchaseProductMethodInfo.getEnv()->NewStringUTF(identifier);

    gPurchaseProductMethodInfo.getEnv()->CallStaticVoidMethod(gPurchaseProductMethodInfo.classID, gPurchaseProductMethodInfo.methodID, jIdentifier);
    gPurchaseProductMethodInfo.getEnv()->DeleteLocalRef(jIdentifier);
}
#endif
