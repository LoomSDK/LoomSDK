/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

#include "platformWebView.h"
#include "loom/common/platform/platform.h"
#import <Foundation/Foundation.h>

#if LOOM_PLATFORM == LOOM_PLATFORM_OSX

#import <WebKit/WebKit.h>
typedef WebView CocoaWebView;
typedef NSRect CocoaRect;
typedef NSView CocoaView;
#define CocoaMakeRect NSMakeRect

#else

#import <UIKit/UIKit.h>
typedef UIWebView CocoaWebView;
typedef CGRect CocoaRect;
typedef UIView CocoaView;
#define CocoaMakeRect CGRectMake

#endif

//_________________________________________________________________________
// Helpers
//_________________________________________________________________________

#if LOOM_PLATFORM == LOOM_PLATFORM_IOS
static float pixelsToPoints(float pixels)
{
    float scale = [UIScreen mainScreen].scale;
    return pixels / scale;
}
#endif


static CocoaView* getMainView()
{
#if LOOM_PLATFORM == LOOM_PLATFORM_OSX
    return [[[NSApplication sharedApplication] windows] objectAtIndex:0].contentView;
#else
    return [[[UIApplication sharedApplication] keyWindow] rootViewController].view;
#endif
}

@interface WebViewRef : NSObject {
    CocoaRect _rect;
}
@property (retain) CocoaWebView* view;
@property CocoaRect rect;
@end


@implementation WebViewRef

- (CocoaRect)rect
{
    return _rect;
}
- (void)setRect:(CocoaRect)newRect;
{
    _rect = newRect;
    CocoaRect frame;
#if LOOM_PLATFORM == LOOM_PLATFORM_OSX
    frame = newRect;
#else
    frame.size.width = pixelsToPoints(newRect.size.width);
    frame.size.height = pixelsToPoints(newRect.size.height);
    frame.origin.x = pixelsToPoints(newRect.origin.x);
    frame.origin.y = getMainView().frame.size.height - frame.size.height - pixelsToPoints(newRect.origin.y);
#endif
    self.view.frame = frame;
}

@end


static int gloom_webViewCounter = 0;
static NSMutableDictionary* gWebViews;
NSMutableDictionary* webViews()
{
    if(gWebViews == NULL)
        gWebViews = [[NSMutableDictionary dictionary] retain];
    
    return gWebViews;
}

WebViewRef* getWebViewRef(loom_webView handle)
{
    return [webViews() objectForKey:[NSNumber numberWithInt:handle]];
}

//_________________________________________________________________________
// WebView Delegate
//_________________________________________________________________________
@interface LMWebViewDelegate : NSObject
{
    loom_webViewCallback callback;
    void *payload;
}

-(id)initWithCallback:(loom_webViewCallback)cb andPayload:(void *)pl;

@end

@implementation LMWebViewDelegate

-(id)initWithCallback:(loom_webViewCallback)cb andPayload:(void *)pl
{
    self = [self init];
    
    callback = cb;
    payload = pl;
    
    return self;
}


#if LOOM_PLATFORM == LOOM_PLATFORM_OSX

- (void)webView:(CocoaWebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    if(frame == [sender mainFrame])
    {
        NSURLRequest* request = frame.provisionalDataSource.request;
        NSString *urlString = [[request URL] absoluteString];
        callback(payload, WEBVIEW_REQUEST_SENT, [urlString cStringUsingEncoding:1]);
    }
}

- (void)webView:(CocoaWebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if(frame == [sender mainFrame])
    {
        NSInteger code = [error code];
        NSString *codeString = [NSString stringWithFormat:@"WebKit Error code: %ld",(long)code];
        callback(payload, WEBVIEW_REQUEST_ERROR, [codeString cStringUsingEncoding:1]);
    }
}

- (void)webView:(CocoaWebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if(frame == [sender mainFrame])
    {
        NSInteger code = [error code];
        NSString *codeString = [NSString stringWithFormat:@"WebKit Error code: %ld",(long)code];
        callback(payload, WEBVIEW_REQUEST_ERROR, [codeString cStringUsingEncoding:1]);
    }
}

#else

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *urlString = [[request URL] absoluteString];
    callback(payload, WEBVIEW_REQUEST_SENT, [urlString cStringUsingEncoding:1]);
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSInteger code = [error code];
    NSString *codeString = [NSString stringWithFormat:@"WebKit Error code: %ld",(long)code];
    callback(payload, WEBVIEW_REQUEST_ERROR, [codeString cStringUsingEncoding:1]);
}

#endif


@end

//_________________________________________________________________________
// platformWebView implementation
//_________________________________________________________________________
loom_webView platform_webViewCreate(loom_webViewCallback callback, void *payload)
{
    int handle = gloom_webViewCounter++;
    
    CocoaWebView* webView = [[[CocoaWebView alloc] initWithFrame:[getMainView() bounds]] retain];
    
#if LOOM_PLATFORM == LOOM_PLATFORM_OSX
    [webView setFrameLoadDelegate:[[LMWebViewDelegate alloc] initWithCallback:callback andPayload:payload]];
    [webView setWantsLayer:YES];
#else
    [webView setDelegate:[[LMWebViewDelegate alloc] initWithCallback:callback andPayload:payload]];
#endif
    
    WebViewRef *ref = [WebViewRef alloc];
    ref.view = webView;
    ref.rect = webView.frame;
    
    [webViews() setObject:ref forKey:[NSNumber numberWithInt:handle]];
    
    return handle;
}

void platform_webViewDestroy(loom_webView handle)
{
    WebViewRef* ref = getWebViewRef(handle);
    CocoaWebView* webView = ref.view;
    
    [webView removeFromSuperview];
    [webView release];
    [ref release];
    
    [webViews() removeObjectForKey:[NSNumber numberWithInt:handle]];
}

void platform_webViewDestroyAll()
{
    NSArray* keys = [webViews() allKeys];
    for (int i=0; i<[keys count]; i++)
    {
        NSNumber* num = [keys objectAtIndex:i];
        platform_webViewDestroy([num intValue]);
    }
}

void platform_webViewShow( loom_webView handle)
{
    CocoaWebView* webView = getWebViewRef(handle).view;
    
    [getMainView() addSubview:webView];
}

void platform_webViewHide( loom_webView handle)
{
    CocoaWebView* webView = getWebViewRef(handle).view;
    
    [webView removeFromSuperview];
}

void platform_webViewRequest( loom_webView handle, const char* url)
{
    CocoaWebView* webView = getWebViewRef(handle).view;
    NSURL* urlObj = [NSURL URLWithString:[NSString stringWithUTF8String:url]];
    NSURLRequest* request = [NSURLRequest requestWithURL:urlObj];
    
#if LOOM_PLATFORM == LOOM_PLATFORM_OSX
    [[webView mainFrame] loadRequest:request];
#else
    [webView loadRequest:request];
#endif
}

bool platform_webViewGoBack( loom_webView handle)
{
    CocoaWebView* webView = getWebViewRef(handle).view;
    
    if (![webView canGoBack]) return false;
    
    [webView goBack];
    return true;
}

bool platform_webViewGoForward( loom_webView handle)
{
    CocoaWebView* webView = getWebViewRef(handle).view;
    
    if (![webView canGoForward]) return false;
    
    [webView goForward];
    return true;
}

bool platform_webViewCanGoBack( loom_webView handle)
{
    CocoaWebView* webView = getWebViewRef(handle).view;
    
    return [webView canGoBack];
}

bool platform_webViewCanGoForward( loom_webView handle)
{
    CocoaWebView* webView = getWebViewRef(handle).view;
    
    return [webView canGoForward];
}

void platform_webViewSetDimensions(loom_webView handle, float x, float y, float width, float height)
{
    WebViewRef* ref = getWebViewRef(handle);
    
    CocoaRect frame;
    frame.origin.x = x;
    frame.origin.y = y;
    frame.size.width = width;
    frame.size.height = height;
    
    ref.rect = frame;
}

float platform_webViewGetX(loom_webView handle)
{
    WebViewRef* ref = getWebViewRef(handle);
    
    return ref.rect.origin.x;
}

void platform_webViewSetX(loom_webView handle, float x)
{
    WebViewRef* ref = getWebViewRef(handle);
    
    CocoaRect rect = ref.rect;
    rect.origin.x = x;
    ref.rect = rect;
}

float platform_webViewGetY(loom_webView handle)
{
    WebViewRef* ref = getWebViewRef(handle);
    
    return ref.rect.origin.y;
}

void platform_webViewSetY(loom_webView handle, float y)
{
    WebViewRef* ref = getWebViewRef(handle);
    
    CocoaRect rect = ref.rect;
    rect.origin.y = y;
    ref.rect = rect;
}

float platform_webViewGetWidth(loom_webView handle)
{
    WebViewRef* ref = getWebViewRef(handle);
    
    return ref.rect.size.width;
}

void platform_webViewSetWidth(loom_webView handle, float width)
{
    WebViewRef* ref = getWebViewRef(handle);
    
    CocoaRect rect = ref.rect;
    rect.size.width = width;
    ref.rect = rect;
}

float platform_webViewGetHeight(loom_webView handle)
{
    WebViewRef* ref = getWebViewRef(handle);
    
    return ref.rect.size.height;
}

void platform_webViewSetHeight(loom_webView handle, float height)
{
    WebViewRef* ref = getWebViewRef(handle);
    
    CocoaRect rect = ref.rect;
    rect.size.height = height;
    ref.rect = rect;
}
