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
#include "loom/common/platform/platformWebView.h"

using namespace LS;

class WebView {
protected:
    loom_webView m_handle;

public:

    LOOM_DELEGATE(OnRequestSent);
    LOOM_DELEGATE(OnRequestFailed);

    WebView()
    {
        m_handle = platform_webViewCreate(webViewCallback, (void *)this);
    }

    ~WebView()
    {
        platform_webViewDestroy(m_handle);
    }

    void show()
    {
        platform_webViewShow(m_handle);
    }

    void hide()
    {
        platform_webViewHide(m_handle);
    }

    void request(const char *url)
    {
        platform_webViewRequest(m_handle, url);
    }

    bool goBack()
    {
        return platform_webViewGoBack(m_handle);
    }

    bool goForward()
    {
        return platform_webViewGoForward(m_handle);
    }

    bool canGoBack()
    {
        return platform_webViewCanGoBack(m_handle);
    }

    bool canGoForward()
    {
        return platform_webViewCanGoForward(m_handle);
    }

    void setDimensions(float x, float y, float width, float height)
    {
        platform_webViewSetDimensions(m_handle, x, y, width, height);
    }

    float getX()
    {
        return platform_webViewGetX(m_handle);
    }

    void setX(float x)
    {
        platform_webViewSetX(m_handle, x);
    }

    float getY()
    {
        return platform_webViewGetY(m_handle);
    }

    void setY(float y)
    {
        platform_webViewSetY(m_handle, y);
    }

    float getWidth()
    {
        return platform_webViewGetWidth(m_handle);
    }

    void setWidth(float width)
    {
        platform_webViewSetWidth(m_handle, width);
    }

    float getHeight()
    {
        return platform_webViewGetHeight(m_handle);
    }

    void setHeight(float height)
    {
        platform_webViewSetHeight(m_handle, height);
    }

    static void webViewCallback(void *payload, loom_webViewCallbackType callbackType, const char *data)
    {
        WebView *webView = (WebView *)payload;

        // handle callback, call delegates
        if (callbackType == WEBVIEW_REQUEST_SENT)
        {
            webView->_OnRequestSentDelegate.pushArgument(data);
            webView->_OnRequestSentDelegate.invoke();
        }
        else if (callbackType == WEBVIEW_REQUEST_ERROR)
        {
            webView->_OnRequestFailedDelegate.pushArgument(data);
            webView->_OnRequestFailedDelegate.invoke();
        }
    }
};

static int registerLoomWebView(lua_State *L)
{
    beginPackage(L, "loom")

       .beginClass<WebView>("WebView")
       .addConstructor<void (*)(void)>()
       .addMethod("show", &WebView::show)
       .addMethod("hide", &WebView::hide)
       .addMethod("request", &WebView::request)
       .addMethod("goBack", &WebView::goBack)
       .addMethod("goForward", &WebView::goForward)
       .addMethod("canGoBack", &WebView::canGoBack)
       .addMethod("canGoForward", &WebView::canGoForward)
       .addMethod("setDimensions", &WebView::setDimensions)
       .addMethod("__pget_x", &WebView::getX)
       .addMethod("__pset_x", &WebView::setX)
       .addMethod("__pget_width", &WebView::getWidth)
       .addMethod("__pset_width", &WebView::setWidth)
       .addMethod("__pget_y", &WebView::getY)
       .addMethod("__pset_y", &WebView::setY)
       .addMethod("__pget_height", &WebView::getHeight)
       .addMethod("__pset_height", &WebView::setHeight)
       .addVarAccessor("onRequestSent", &WebView::getOnRequestSentDelegate)
       .addVarAccessor("onRequestFailed", &WebView::getOnRequestFailedDelegate)
       .endClass()

       .endPackage();

    return 0;
}


void installLoomWebView()
{
    LOOM_DECLARE_NATIVETYPE(WebView, registerLoomWebView);
}
