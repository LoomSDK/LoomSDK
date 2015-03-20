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

#import <Foundation/Foundation.h>
#include "platformHTTP.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

/**
 *  Delegate implementation with support for calling the specified C callback
 */
@interface LMURLConnectionDelegate : NSObject
{
    loom_HTTPCallback callback;
    void *payload;
    bool allowRedirect;
    const char *cacheToFile;
    bool base64EncodeResponse;
    NSMutableData* receivedData;
    bool statusCodeFail;
}

-(id)initWithCallback:(loom_HTTPCallback)cb payload:(void *)pl allowRedirect:(bool)ar cacheToFile:(const char *)cf base64EncodeResponse:(bool)b64;

@end

@implementation LMURLConnectionDelegate

-(id)initWithCallback:(loom_HTTPCallback)cb payload:(void *)pl allowRedirect:(bool)ar cacheToFile:(const char *)cf base64EncodeResponse:(bool)b64 
{
    self = [self init];
    
    callback = cb;
    payload = pl;
    allowRedirect = ar;
    cacheToFile = cf;
    base64EncodeResponse = b64;
    
    receivedData = [NSMutableData alloc];
    [receivedData setLength:0];
    
    return self;
}

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse
{
    return allowRedirect ? request : nil;
}

+(NSString*)base64forData:(NSData*)theData {

    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];

  static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

  NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
  uint8_t* output = (uint8_t*)data.mutableBytes;

    NSInteger i;
  for (i=0; i < length; i += 3) {
    NSInteger value = 0;
        NSInteger j;
    for (j = i; j < (i + 3); j++) {
      value <<= 8;

      if (j < length) {
        value |= (0xFF & input[j]);
      }
    }

    NSInteger theIndex = (i / 3) * 4;
    output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
    output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
    output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
    output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
  }

  return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    statusCodeFail = [response statusCode] >= 400;
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Should we cache results to file?
    if(cacheToFile != NULL)
        [receivedData writeToFile:[NSString stringWithUTF8String:cacheToFile] atomically:YES];

    // Should we base64 encode them before returning the data?
    NSString *response = nil;
    if(base64EncodeResponse)
        response = [LMURLConnectionDelegate base64forData:receivedData];
    else
        response = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];

    if(statusCodeFail)
        callback(payload, LOOM_HTTP_ERROR, [response cStringUsingEncoding:NSUTF8StringEncoding]);
    else
        callback(payload, LOOM_HTTP_SUCCESS, [response cStringUsingEncoding:NSUTF8StringEncoding]);

    [receivedData release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [receivedData release];
    callback(payload, LOOM_HTTP_ERROR, [[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end

/**
 * Performs an asychronous http request
 */
int platform_HTTPSend(const char *url, const char* method, void *callback, void *payload, 
    const char *body, int bodyLength, utHashTable<utHashedString, utString> &headers, 
    const char *responseCacheFile, bool base64EncodeResponseData, bool followRedirects)
{
    NSString *urlString = [NSString stringWithUTF8String:url];
    NSURL*urlObject = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObject];
    [request setHTTPMethod:[NSString stringWithUTF8String:method]];
    
    if(body != NULL)
    {
        // TODO. we should probably pass body length to make this binary compatible
        NSString* bodyString = [NSString stringWithUTF8String:body];
        [request setHTTPBody:[NSData dataWithBytes:(void*)body length:bodyLength]];
    }
    
    // iterate over the utHashTable and register our headers
    utHashTableIterator< utHashTable<utHashedString, utString> > headersIterator(headers);
    while(headersIterator.hasMoreElements())
    {
        utHashedString key = headersIterator.peekNextKey();
        utString value = headersIterator.peekNextValue();
        
        [request setValue:[NSString stringWithUTF8String:value.c_str()] forHTTPHeaderField:[NSString stringWithUTF8String:key.str().c_str()]];
        
        headersIterator.next();
    }
    
    LMURLConnectionDelegate *delegate = [[LMURLConnectionDelegate alloc] initWithCallback:callback payload:payload allowRedirect:followRedirects cacheToFile:responseCacheFile base64EncodeResponse:base64EncodeResponseData];
    
    // NSURLConnected maintains a strong ref to the delegate while
    // it is being used, so this is completely legit
    [[NSURLConnection alloc] initWithRequest:request delegate:delegate];

    return 0; //TODO_KEVIN
}

bool platform_HTTPIsConnected()
{
    // TODO: implement
    return true;
}

void platform_HTTPInit()
{
    // stub on OSX/iOS
}

void platform_HTTPCleanup()
{
    // stub on OSX/iOS
}

void platform_HTTPUpdate()
{
    // stub on OSX/iOS
}

bool platform_HTTPCancel(int index)
{
    return false;
    //TODO_KEVIN
}

void platform_HTTPComplete(int i)
{
    //TODO_KEVIN
    //curlHandles[i] = NULL;
}