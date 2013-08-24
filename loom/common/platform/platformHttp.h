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


#ifndef platform_platformHTTP_h
#define platform_platformHTTP_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

/**
 * The platform abstraction for Loom's HTTP support.
 *
 * This cross platform C API is backed by different support libraries based
 * on the OS. On mobile we try to use the recommended native APIs to be more
 * cell and battery friendly.
 */

/**
 *  Enum representing the type of event the callback is called for. LOOM_HTTP_SUCCESS
 *  is called in the case that the http send was successful. LOOM_HTTP_ERROR reports an
 *  unsuccessful http operation.
 */
typedef enum
{
    LOOM_HTTP_SUCCESS, LOOM_HTTP_ERROR
} loom_HTTPCallbackType;

/**
 *  Callback type for receiving responses back from the `platform_HTTPSend` call.
 */
typedef void (*loom_HTTPCallback)(void *payload, loom_HTTPCallbackType type, const char *data);

/**
 *  Call an HTTP send in one method. Other params are body and headers as they
 *  are not always needed. The payload pointer will be passed into the callback
 *  function when it is called as a user payload.
 *
 *  @param bodyLength The length in bytes of the body; use strlen if passing a string.
 */
void platform_HTTPSend(const char *url, const char *method, loom_HTTPCallback callback, void *payload,
                       const char *body, int bodyLength, utHashTable<utHashedString, utString>& headers,
                       const char *responseCacheFile, bool base64EncodeResponseData, bool followRedirects);

/**
 *  Returns true if the device is connected to a network.
 */
bool platform_HTTPIsConnected();

/**
 *  Initializes the HTTP subsystem. Called internally by Loom.
 */
void platform_HTTPInit();

/**
 *  Tears down the HTTP subsystem. Called internally by Loom.
 */
void platform_HTTPCleanup();

/**
 *  Should be called in the main program loop. This calls updates on any async operations. Called internally by Loom.
 */
void platform_HTTPUpdate();
#endif
