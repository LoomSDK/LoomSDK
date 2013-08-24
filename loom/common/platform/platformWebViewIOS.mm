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

#import "platformWebView.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

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

UIWebView* getWebView(loom_webView handle)
{
    return [webViews() objectForKey:[NSNumber numberWithInt:handle]];
}


static UIViewController* getParentViewController()
{
    return [[[UIApplication sharedApplication] keyWindow] rootViewController];
}

//_________________________________________________________________________
// WebView Delegate
//_________________________________________________________________________
@interface LMWebViewDelegate : NSObject <UIWebViewDelegate>
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

@end

//_________________________________________________________________________
// platformWebView implementation
//_________________________________________________________________________
loom_webView platform_webViewCreate(loom_webViewCallback callback, void *payload)
{
    int handle = gloom_webViewCounter++;
    
    // create our webview
    UIWebView* webView = [[[UIWebView alloc] initWithFrame:[getParentViewController().view bounds]] retain];
    [webView setDelegate:[[LMWebViewDelegate alloc] initWithCallback:callback andPayload:payload]];
    [webViews() setObject:webView forKey:[NSNumber numberWithInt:handle]];
    
    return handle;
}

void platform_webViewDestroy(loom_webView handle)
{
    UIWebView* webView = getWebView(handle);
    
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
    UIWebView* webView = getWebView(handle);
    
    [getParentViewController().view addSubview:webView];
}

void platform_webViewHide( loom_webView handle)
{
    UIWebView* webView = getWebView(handle);
    
    [webView removeFromSuperview];
}

void platform_webViewRequest( loom_webView handle, const char* url)
{
    UIWebView* webView = getWebView(handle);
    NSURL* urlObj = [NSURL URLWithString:[NSString stringWithUTF8String:url]];
    NSURLRequest* request = [NSURLRequest requestWithURL:urlObj];
    
    [webView loadRequest:request];
}

bool platform_webViewGoBack( loom_webView handle)
{
    UIWebView* webView = getWebView(handle);
    
    if([webView canGoBack] == false)
        return false;
    
    [webView goBack];
    return true;
}

bool platform_webViewGoForward( loom_webView handle)
{
    UIWebView* webView = getWebView(handle);
    
    if([webView canGoForward] == false)
        return false;
    
    [webView goForward];
    return true;
}

bool platform_webViewCanGoBack( loom_webView handle)
{
    UIWebView* webView = getWebView(handle);
    
    return [webView canGoBack];
}

bool platform_webViewCanGoForward( loom_webView handle)
{
    UIWebView* webView = getWebView(handle);
    
    return [webView canGoForward];
}

void platform_webViewSetDimensions(loom_webView handle, float x, float y, float width, float height)
{
    UIWebView* webView = getWebView(handle);
    
    UIView* parent = getParentViewController().view;
    float xfmy = parent.frame.size.height - height - y;
    
    [webView setFrame:CGRectMake(x, xfmy, width, height)];
}

float platform_webViewGetX(loom_webView handle)
{
    UIWebView* webView = getWebView(handle);
    
    return webView.frame.origin.x;
}

void platform_webViewSetX(loom_webView handle, float x)
{
    UIWebView* webView = getWebView(handle);
    
    CGRect frame = webView.frame;
    frame.origin.x = x;
    
    [webView setFrame:frame];
}

float platform_webViewGetY(loom_webView handle)
{
    UIWebView* webView = getWebView(handle);
    
    return webView.frame.origin.y;
}

void platform_webViewSetY(loom_webView handle, float y)
{
    UIWebView* webView = getWebView(handle);
    
    UIView* parent = getParentViewController().view;
    
    CGRect frame = webView.frame;
    frame.origin.y = parent.frame.size.height - frame.size.height - y;
    
    [webView setFrame:frame];
}

float platform_webViewGetWidth(loom_webView handle)
{
    UIWebView* webView = getWebView(handle);
    
    return webView.frame.size.width;
}

void platform_webViewSetWidth(loom_webView handle, float width)
{
    UIWebView* webView = getWebView(handle);
    
    CGRect frame = webView.frame;
    frame.size.width = width;
    
    [webView setFrame:frame];
}

float platform_webViewGetHeight(loom_webView handle)
{
    UIWebView* webView = getWebView(handle);
    
    return webView.frame.size.height;
}

void platform_webViewSetHeight(loom_webView handle, float height)
{
    UIWebView* webView = getWebView(handle);
    
    UIView* parent = getParentViewController().view;
    
    CGRect frame = webView.frame;
    frame.size.height = height;
    
    [webView setFrame:frame];
}