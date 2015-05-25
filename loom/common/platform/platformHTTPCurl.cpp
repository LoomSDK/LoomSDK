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

#include "platformHttp.h"
#include <stdio.h>
#include <string.h>
#include <cassert>
#include "platform.h"

#ifndef LOOMSCRIPT_STANDALONE
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32 || LOOM_PLATFORM == LOOM_PLATFORM_LINUX


#include "curl/curl.h"
#include "loom/common/core/allocator.h"
#include "loom/common/platform/platformFile.h"
#include "loom/common/utils/utBase64.h"


static CURLM *gMultiHandle;
static CURL *curlHandles[MAX_CONCURRENT_HTTP_REQUESTS];
static int   gHandleCount;
static bool  gHTTPInitialized;

/**
 * Represents a chunk in memory reserved for writing bytes from curls write_data callback
 */
typedef struct
{
    char   *memory;
    size_t size;
} loom_HTTPChunk;

/**
 * Represents a user data payload
 */
typedef struct
{
    // the chunk of data returned by the http call
    loom_HTTPChunk    *chunk;

    // the callback to call when a http callback has finished/failed
    loom_HTTPCallback callback;

    // the payload to be passed to the callback
    void              *payload;

    // the headers slist
    curl_slist        *headers;

    utString          cacheFile;
    void              *body;
    int               bodyLength;
    utString          url;
    utString          method;

    bool              base64;
} loom_HTTPUserData;

static void loom_HTTPCleanupUserData(loom_HTTPUserData *data)
{
    if (!data->chunk) return;
    lmSafeFree(NULL, data->chunk->memory);
    curl_slist_free_all(data->headers);
    lmSafeDelete(NULL, data->chunk);
    lmDelete(NULL, data);
}


/**
 * Write data coming from curl operation
 */
static size_t write_data(void *buffer, size_t size, size_t nmemb, void *userp)
{
    size_t            actualSize = size * nmemb;
    loom_HTTPUserData *userData  = (loom_HTTPUserData *)userp;
    loom_HTTPChunk    *chunk     = userData->chunk;

    // reallocate memory for our chunk. +1 for our null terminator.
    chunk->memory = (char *)lmRealloc(NULL, chunk->memory, chunk->size + actualSize + 1);
    if (chunk->memory == NULL) // OOM?
    {
        // TODO: Log OOM error in loom
        // let curl throw the error for us.
        return 0;
    }

    // copy starting from the last null terminator
    memcpy(&(chunk->memory[chunk->size]), buffer, actualSize);
    chunk->size += actualSize;
    chunk->memory[chunk->size] = 0;

    return actualSize;
}

// Memory management overrides for CURL.
static void *malloc_callback(size_t size)
{
   return lmAlloc(NULL, size);
}

static void free_callback(void *ptr)
{
   return lmFree(NULL, ptr);
}

static void *realloc_callback(void *ptr, size_t size)
{
   return lmRealloc(NULL, ptr, size);
}

static char *strdup_callback(const char *str)
{
   if (!str)
      return NULL;

   char *s = (char *)lmAlloc(NULL, strlen(str) + 1);
   strcpy(s, str);
   return s;
}

static void *calloc_callback(size_t nmemb, size_t size)
{
   void *res = lmAlloc(NULL, nmemb * size);
   memset(res, 0, nmemb * size);
   return res;
}

void platform_HTTPInit()
{
    curl_global_init_mem(CURL_GLOBAL_DEFAULT,
       malloc_callback, free_callback, realloc_callback, 
       strdup_callback, calloc_callback);
    gMultiHandle     = curl_multi_init();
    gHandleCount     = 0;
    gHTTPInitialized = true;
    memset(curlHandles, 0, sizeof(CURL *) * MAX_CONCURRENT_HTTP_REQUESTS);
}


void platform_HTTPCleanup()
{
    curl_multi_cleanup(gMultiHandle);
    curl_global_cleanup();
}


void platform_HTTPUpdate()
{
    assert(gHTTPInitialized);

    curl_multi_perform(gMultiHandle, &gHandleCount);

    // loop over all of our infos and cleanup handles that are done
    int     messageCount = 0;
    CURLMsg *message     = curl_multi_info_read(gMultiHandle, &messageCount);
    while (message != NULL)
    {
        if (message->msg == CURLMSG_DONE)
        {
            // copy the handle because message won't survive
            // past multi_remove_handle. Silly CURL. -JMS
            CURL *handle = message->easy_handle;

            // get our userData payload
            loom_HTTPUserData *userData = NULL;
            curl_easy_getinfo(handle, CURLINFO_PRIVATE, &userData);

            // Make sure no error was thrown
            if (message->data.result == CURLE_OK)
            {
                long http_code = 0;
                curl_easy_getinfo (handle, CURLINFO_RESPONSE_CODE, &http_code);

                // Will we cache to a file?
                if (http_code < 400 && userData->cacheFile.length())
                {
                    platform_writeFile(userData->cacheFile.c_str(), userData->chunk->memory, userData->chunk->size);
                }

                // Do we need to base64?
                const char *result = NULL;
                if (userData->base64)
                {
                    utArray<unsigned char> data;
                    data.resize(userData->chunk->size);
                    memcpy(data.ptr(), userData->chunk->memory, userData->chunk->size);

                    utBase64 result64 = utBase64::encode64(data);
                    result = strdup_callback(result64.getBase64().c_str());
                }
                else
                {
                    result = userData->chunk->memory;
                }

                // notify the callback if we are successful
                if (http_code < 400)
                    userData->callback(userData->payload, LOOM_HTTP_SUCCESS, result);
                else
                    userData->callback(userData->payload, LOOM_HTTP_ERROR, result);

                if(userData->base64)
                   lmFree(NULL, (void*)result);
            }
            else
            {
                // send a failure to the callback
                userData->callback(userData->payload, LOOM_HTTP_ERROR, curl_easy_strerror(message->data.result));
            }

            // clean up any userdata.
            loom_HTTPCleanupUserData(userData);
        }

        // go to the next message
        message = curl_multi_info_read(gMultiHandle, &messageCount);
    }
}


bool platform_HTTPIsConnected()
{
    // Surely we're online!
    return true;
}


int platform_HTTPSend(const char *url, const char *method, loom_HTTPCallback callback, void *payload,
                       const char *body, int bodyLength, utHashTable<utHashedString, utString>& headers,
                       const char *responseCacheFile, bool base64EncodeResponseData, bool followRedirects)
{
    assert(gHTTPInitialized);

    //get an empty slot for our handle to use
    int index = 0;
    while ((curlHandles[index] != NULL) && (index < MAX_CONCURRENT_HTTP_REQUESTS)) {index++;}
    if(index == MAX_CONCURRENT_HTTP_REQUESTS)
    {
        return -1;
    }

    // initialize our curl handle
    CURL *curlHandle = curl_easy_init();

    curl_slist *headersList = NULL;

    // alloc our struct, this needs to be alloc'd in the heap
    // because it should persist past the initial request
    loom_HTTPUserData *userData = lmNew(NULL) loom_HTTPUserData;

    // do not keep pointers to the strings passed in
    userData->cacheFile  = responseCacheFile ? responseCacheFile : "";
    userData->body       = (void *)body;
    userData->bodyLength = bodyLength;
    userData->url        = url ? url : "";
    userData->method     = method ? method : "";
    userData->callback   = callback;
    userData->payload    = payload;
    userData->base64     = base64EncodeResponseData;

    // iterate over the utHashTable and register our headers
    utHashTableIterator<utHashTable<utHashedString, utString> > headersIterator(headers);
    while (headersIterator.hasMoreElements())
    {
        utHashedString key    = headersIterator.peekNextKey();
        utString       value  = headersIterator.peekNextValue();
        utString       header = key.str() + ":" + value;

        headersList = curl_slist_append(headersList, header.c_str());

        headersIterator.next();
    }

    // initialize our chunk data, it will eventually be resized.
    userData->chunk = lmNew(NULL) loom_HTTPChunk;
    userData->chunk->memory = (char*)lmAlloc(NULL, 1); // Must use malloc as Curl wants to realloc.
    userData->chunk->memory[0] = 0;
    userData->chunk->size      = 0;

    // headers
    userData->headers = headersList;

    // url to call
    curl_easy_setopt(curlHandle, CURLOPT_URL, userData->url.c_str());
    // our writedata callback
    curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, write_data);
    // our writedata callback payload
    curl_easy_setopt(curlHandle, CURLOPT_WRITEDATA, userData);
    // general payload
    curl_easy_setopt(curlHandle, CURLOPT_PRIVATE, userData);
    // custom headers
    curl_easy_setopt(curlHandle, CURLOPT_HTTPHEADER, userData->headers);

    // Configure redirect behavior.
    curl_easy_setopt(curlHandle, CURLOPT_FOLLOWLOCATION, followRedirects ? 1 : 0);

    if (strcmp(method, "GET") == 0)
    {
        // do nothing, GET is the default
    }
    else if (strcmp(method, "POST") == 0)
    {
        curl_easy_setopt(curlHandle, CURLOPT_POST, 1);
        curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDSIZE, userData->bodyLength);
        curl_easy_setopt(curlHandle, CURLOPT_COPYPOSTFIELDS, (const char *)userData->body);
    }
    else // call error
    {
        callback(payload, LOOM_HTTP_ERROR, "Error: Unknown HTTP Method.");
        return -1;
    }

    // add to the multi interface
    curl_multi_add_handle(gMultiHandle, curlHandle);
    curlHandles[index] = curlHandle;

    return index;
}

bool platform_HTTPCancel(int index)
{
    return ((index == -1) || (curlHandles[index] == NULL)) ? false : true;
}

void platform_HTTPComplete(int index)
{
    if(index != -1)
    {
        curl_multi_remove_handle(gMultiHandle, curlHandles[index]);
        curl_easy_cleanup(curlHandles[index]);
        curlHandles[index] = NULL;
    }
}

#endif
#endif //LOOMSCRIPT_STANDALONE

