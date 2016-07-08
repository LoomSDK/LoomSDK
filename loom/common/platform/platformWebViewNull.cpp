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

#include "platformWebView.h"
#include "loom/common/core/log.h"
#include "platform.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32 || LOOM_PLATFORM == LOOM_PLATFORM_LINUX

static loom_logGroup_t platformWebViewLogGroup = { "Loom.WebView", 1 };

loom_webView platform_webViewCreate(loom_webViewCallback callback, void *payload)
{
    lmLogError(platformWebViewLogGroup, "WebView is currently not supported on the current platform. Supported platforms are OSX, Android, and iOS");

    return 0;
}


void platform_webViewDestroy(loom_webView handle)
{
}


void platform_webViewDestroyAll()
{
}


void platform_webViewShow(loom_webView handle)
{
}


void platform_webViewHide(loom_webView handle)
{
}


void platform_webViewRequest(loom_webView handle, const char *url)
{
}


bool platform_webViewGoBack(loom_webView handle)
{
    return false;
}


bool platform_webViewGoForward(loom_webView handle)
{
    return false;
}


bool platform_webViewCanGoBack(loom_webView handle)
{
    return false;
}


bool platform_webViewCanGoForward(loom_webView handle)
{
    return false;
}


void platform_webViewSetDimensions(loom_webView handle, float x, float y, float width, float height)
{
}


float platform_webViewGetX(loom_webView handle)
{
    return 0.0f;
}


void platform_webViewSetX(loom_webView handle, float x)
{
}


float platform_webViewGetY(loom_webView handle)
{
    return 0.0f;
}


void platform_webViewSetY(loom_webView handle, float y)
{
}


float platform_webViewGetWidth(loom_webView handle)
{
    return 0.0f;
}


void platform_webViewSetWidth(loom_webView handle, float width)
{
}


float platform_webViewGetHeight(loom_webView handle)
{
    return 0.0f;
}


void platform_webViewSetHeight(loom_webView handle, float height)
{
}

void platform_webViewPauseAll()
{
}

void platform_webViewResumeAll()
{
}

#endif
