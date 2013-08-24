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

#ifndef _PLATFORM_PLATFORMWEB_H_
#define _PLATFORM_PLATFORMWEB_H_

#ifdef __cplusplus
extern "C" {
#endif

/**
 *  Handle to a WebView. Loom WebViews are managed in a platform-specific manner.
 *  Denying all fanciness a simple handle is passed back and forth between the
 *  platforms respective `native language
 */
typedef int   loom_webView;

/**
 *  Represents the type of event the occurred in the WebView for a specific callback.
 *  WEBVIEW_REQUEST_SENT is called when a request has been sent. WEBVIEW_REQUEST_ERROR
 *  is called when a request was unsuccessful.
 */
typedef enum
{
    WEBVIEW_REQUEST_SENT  = 0,
    WEBVIEW_REQUEST_ERROR = 1
} loom_webViewCallbackType;

/**
 *  Callback type for when something happens in a WebView. It receives a payload
 *  (usually an object instance that the WebView is associated with), a type of
 *  event that occurred in the WebView, and a data string.
 */
typedef void (*loom_webViewCallback)(void *payload, loom_webViewCallbackType callbackType, const char *data);

/**
 *  Creates a WebView in a platform-specific manner. Accepts a callback function
 *  and pointer to to object to be passed as the first argument to the callback
 *  when an event occurs. Returns a handle to the newly created WebView.
 */
loom_webView platform_webViewCreate(loom_webViewCallback callback, void *payload);

/**
 *  Destroys the WebView associated with the specified handle. Do not continue
 *  to use this handle as any subsequent calls against the specified handle will
 *  result in unexpected behavior.
 */
void platform_webViewDestroy(loom_webView handle);

/**
 *  Hides and destroys all WebViews created with platform_webViewCreate. This function
 *  is used primarily to facilitate LiveReload as the WebViews are not in the GL layer
 *  and therefore are not completely cleaned up as the rest of the display nodes are.
 */
void platform_webViewDestroyAll();

/**
 *  Show the WebView associated with the specified handle.
 */
void platform_webViewShow(loom_webView handle);

/**
 *  Hide the WebView associated with the specified handle.
 */
void platform_webViewHide(loom_webView handle);

/**
 *  Send the url argument as a request to the WebView associated with the specified handle.
 */
void platform_webViewRequest(loom_webView handle, const char *url);

/**
 *  Attempt to go back in the WebView associated with the specified handle. Returns false
 *  if there is nothing to go back to.
 */
bool platform_webViewGoBack(loom_webView handle);

/**
 *  Attempt to go forward in the WebView associated with the specified handle. Returns false
 *  if there is nothing to go forward to.
 */
bool platform_webViewGoForward(loom_webView handle);

/**
 *  Returns false if there is nothing to go back to. True otherwise.
 */
bool platform_webViewCanGoBack(loom_webView handle);

/**
 *  Returns true if there is nothing to go back to. True otherwise.
 */
bool platform_webViewCanGoForward(loom_webView handle);

/**
 *  Sets the dimensions of the WebView associated with the specified handle.
 */
void platform_webViewSetDimensions(loom_webView handle, float x, float y, float width, float height);

/**
 *  Gets the x position of the WebView associated with the specified handle.
 */
float platform_webViewGetX(loom_webView handle);

/**
 *  Sets the x position of the WebView associated with the specified handle.
 */
void platform_webViewSetX(loom_webView handle, float x);

/**
 *  Gets the y position of the WebView associated with the specified handle.
 */
float platform_webViewGetY(loom_webView handle);

/**
 *  Sets the y position of the WebView associated with the specified handle.
 */
void platform_webViewSetY(loom_webView handle, float y);

/**
 *  Gets the width of the WebView associated with the specified handle.
 */
float platform_webViewGetWidth(loom_webView handle);

/**
 *  Sets the width of the WebView associated with the specified handle.
 */
void platform_webViewSetWidth(loom_webView handle, float width);

/**
 *  Gets the height of the WebView associated with the specified handle.
 */
float platform_webViewGetHeight(loom_webView handle);

/**
 *  Sets the height of the WebView associated with the specified handle.
 */
void platform_webViewSetHeight(loom_webView handle, float height);

#ifdef __cplusplus
}
#endif
#endif
