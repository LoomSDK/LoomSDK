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
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

//_________________________________________________________________________
// Helpers
//_________________________________________________________________________
static int gloom_webViewCounter = 0;
static NSMutableDictionary* gWebViews;
NSMutableDictionary* webViews()
{
    if(gWebViews == NULL)
        gWebViews = [[NSMutableDictionary dictionary] retain];
    
    return gWebViews;
}

WebView* getWebView(loom_webView handle)
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

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    if(frame == [sender mainFrame])
    {
        NSURLRequest* request = frame.provisionalDataSource.request;
        NSString *urlString = [[request URL] absoluteString];
        callback(payload, WEBVIEW_REQUEST_SENT, [urlString cStringUsingEncoding:1]);
    }
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if(frame == [sender mainFrame])
    {
        NSInteger code = [error code];
        NSString *codeString = [NSString stringWithFormat:@"WebKit Error code: %ld",(long)code];
        callback(payload, WEBVIEW_REQUEST_ERROR, [codeString cStringUsingEncoding:1]);
    }
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if(frame == [sender mainFrame])
    {
        NSInteger code = [error code];
        NSString *codeString = [NSString stringWithFormat:@"WebKit Error code: %ld",(long)code];
        callback(payload, WEBVIEW_REQUEST_ERROR, [codeString cStringUsingEncoding:1]);
    }
}

@end

//_________________________________________________________________________
// platformWebView implementation
//_________________________________________________________________________
loom_webView platform_webViewCreate(loom_webViewCallback callback, void *payload)
{
    int handle = gloom_webViewCounter++;
    
    // get the main window
    NSWindow* window = [[[NSApplication sharedApplication] windows] objectAtIndex:0];
    
    // create our webview
    WebView* webView = [[[WebView alloc] initWithFrame:[window.contentView bounds]] retain];
    [webView setFrameLoadDelegate:[[LMWebViewDelegate alloc] initWithCallback:callback andPayload:payload]];
    [webView setWantsLayer:YES];
    [webViews() setObject:webView forKey:[NSNumber numberWithInt:handle]];
    
    return handle;
}

void platform_webViewDestroy(loom_webView handle)
{
    WebView* webView = getWebView(handle);
    
    [webView removeFromSuperview];
    [webViews() removeObjectForKey:[NSNumber numberWithInt:handle]];
    [webView release];
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
    WebView* webView = getWebView(handle);
    
    // lookup the main window
    NSWindow* window = [[[NSApplication sharedApplication] windows] objectAtIndex:0];
    [(NSView*)[window contentView] addSubview:webView];
}

void platform_webViewHide( loom_webView handle)
{
    WebView* webView = getWebView(handle);
    
    [webView removeFromSuperview];
}

void platform_webViewRequest( loom_webView handle, const char* url)
{
    WebView* webView = getWebView(handle);
    NSURL* urlObj = [NSURL URLWithString:[NSString stringWithUTF8String:url]];
    NSURLRequest* request = [NSURLRequest requestWithURL:urlObj];
    
    [[webView mainFrame] loadRequest:request];
}

bool platform_webViewGoBack( loom_webView handle)
{
    WebView* webView = getWebView(handle);
    
    return [webView goBack];
}

bool platform_webViewGoForward( loom_webView handle)
{
    WebView* webView = getWebView(handle);
    
    return [webView goForward];
}

bool platform_webViewCanGoBack( loom_webView handle)
{
    WebView* webView = getWebView(handle);
    
    return [webView canGoBack];
}

bool platform_webViewCanGoForward( loom_webView handle)
{
    WebView* webView = getWebView(handle);
    
    return [webView canGoForward];
}

void platform_webViewSetDimensions(loom_webView handle, float x, float y, float width, float height)
{
    WebView* webView = getWebView(handle);
    
    [webView setFrame:NSMakeRect(x, y, width, height)];
}

float platform_webViewGetX(loom_webView handle)
{
    WebView* webView = getWebView(handle);
    
    return webView.frame.origin.x;
}

void platform_webViewSetX(loom_webView handle, float x)
{
    WebView* webView = getWebView(handle);
    
    NSRect frame = webView.frame;
    frame.origin.x = x;
    
    [webView setFrame:frame];
}

float platform_webViewGetY(loom_webView handle)
{
    WebView* webView = getWebView(handle);
    
    return webView.frame.origin.y;
}

void platform_webViewSetY(loom_webView handle, float y)
{
    WebView* webView = getWebView(handle);
    
    NSRect frame = webView.frame;
    frame.origin.y = y;
    
    [webView setFrame:frame];
}

float platform_webViewGetWidth(loom_webView handle)
{
    WebView* webView = getWebView(handle);
    
    return webView.frame.size.width;
}

void platform_webViewSetWidth(loom_webView handle, float width)
{
    WebView* webView = getWebView(handle);
    
    NSRect frame = webView.frame;
    frame.size.width = width;
    
    [webView setFrame:frame];
}

float platform_webViewGetHeight(loom_webView handle)
{
    WebView* webView = getWebView(handle);
    
    return webView.frame.size.height;
}

void platform_webViewSetHeight(loom_webView handle, float height)
{
    WebView* webView = getWebView(handle);
    
    NSRect frame = webView.frame;
    frame.size.height = height;
    
    [webView setFrame:frame];
}
