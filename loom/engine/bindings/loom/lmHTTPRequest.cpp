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

#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/script/runtime/lsProfiler.h"
#include "loom/common/platform/platformHttp.h"
#include "loom/common/utils/utByteArray.h"

using namespace LS;


lmDefineLogGroup(gHTTPRequestLogGroup, "HTTPRequest", 1, LoomLogInfo);

class HTTPRequest {
public:

    utString method;
    utString body;
    utString url;
    utString responseCacheFile;

    utByteArray *bodyBytes;

    bool        followRedirects;

    utHashTable<utHashedString, utString> header;

    int id;

    LOOM_DELEGATE(OnSuccess);
    LOOM_DELEGATE(OnFailure);

    HTTPRequest(const char *urlString, const char *contentType) : method("GET"), body(""), responseCacheFile(""), bodyBytes(NULL)
    {
        url = urlString;
        followRedirects          = true;
        id = -1;

        // set the Content-Type in the header
        const char *ctKey = contentType;
        if((ctKey == NULL) || (ctKey[0] == '\0'))
        {
            // use the default content type if none specified
            ctKey = "application/x-www-form-urlencoded";
        }
        setHeaderField("Content-Type", ctKey);
    }

    ~HTTPRequest()
    {
        header.clear();
        cancel();
    }

    void setHeaderField(const char *key, const char *value)
    {
        header.insert(key, value);
    }

    const char *getHeaderField(const char *key)
    {
        utString *val = header.get(key);

        if (val != NULL)
        {
            return val->c_str();
        }
        else
        {
            return NULL;
        }
    }

    bool send()
    {
        if (id != -1) cancel();
        LOOM_PROFILE_SCOPE(httpSend);
        id = -1;
        if (url == "")
        {
            utByteArray *result = lmNew(NULL) utByteArray();
            result->writeString("Error: Empty URL");
            respond(this, LOOM_HTTP_ERROR, result);
        }
        else
        {
            if (bodyBytes != NULL)
            {
                // Send with body as byte array.
                id = platform_HTTPSend((const char *)url.c_str(), (const char *)method.c_str(), &HTTPRequest::respond, (void *)this,
                                  (const char *)bodyBytes->getInternalArray()->ptr(), bodyBytes->getSize(), header,
                                  (const char *)responseCacheFile.c_str(), followRedirects);
            }
            else
            {
                // Send with body as string.
                id = platform_HTTPSend((const char *)url.c_str(), (const char *)method.c_str(), &HTTPRequest::respond, (void *)this,
                                  (const char *)body.c_str(), body.length(), header,
                                  (const char *)responseCacheFile.c_str(), followRedirects);
            }
        }
        return (id == -1) ? false : true;
    }

    void cancel()
    {
        if (id == -1) return;
        bool cancelled = platform_HTTPCancel(id);
        if (cancelled)
        {
            utByteArray *result = lmNew(NULL) utByteArray();
            result->writeString("Request cancelled by user.");
            respond(this, LOOM_HTTP_ERROR, result);
        }
    }

    //only called internally to notfiy that the HTTPRequest has completed now
    void complete()
    {
        if (id == -1) return;
        platform_HTTPComplete(id);
        id = -1;        
    }    

    static bool isConnected()
    {
        return platform_HTTPIsConnected();
    }

    /**
     * Calls the native delegate, this should be used internally only
     */
    static void respond(void *payload, loom_HTTPCallbackType type, utByteArray *data)
    {
        HTTPRequest *request = (HTTPRequest *)payload;

        lmAssert(data != NULL, "Response ByteArray should not be null");

        switch (type)
        {
        case LOOM_HTTP_SUCCESS:
            request->_OnSuccessDelegate.pushArgument(data);
            request->_OnSuccessDelegate.invoke();
            request->complete();
            break;

        case LOOM_HTTP_ERROR:
            request->_OnFailureDelegate.pushArgument(data);
            request->_OnFailureDelegate.invoke();
            request->complete();
            break;

        default:
            break;
        }
    }
};

static int registerLoomHTTPRequest(lua_State *L)
{
    beginPackage(L, "loom")

       .beginClass<HTTPRequest>("HTTPRequest")
       .addConstructor<void (*)(const char *, const char *)>()
       .addMethod("setHeaderField", &HTTPRequest::setHeaderField)
       .addMethod("getHeaderField", &HTTPRequest::getHeaderField)
       .addMethod("send", &HTTPRequest::send)
       .addMethod("cancel", &HTTPRequest::cancel)
       .addStaticMethod("isConnected", &HTTPRequest::isConnected)
       .addVar("method", &HTTPRequest::method)
       .addVar("body", &HTTPRequest::body)
       .addVar("bodyBytes", &HTTPRequest::bodyBytes)
       .addVar("url", &HTTPRequest::url)
       .addVar("cacheFileName", &HTTPRequest::responseCacheFile)
       .addVar("followRedirects", &HTTPRequest::followRedirects)
       .addVarAccessor("onSuccess", &HTTPRequest::getOnSuccessDelegate)
       .addVarAccessor("onFailure", &HTTPRequest::getOnFailureDelegate)
       .endClass()

       .endPackage();

    return 0;
}


void installLoomHTTPRequest()
{
    LOOM_DECLARE_NATIVETYPE(HTTPRequest, registerLoomHTTPRequest);
}
