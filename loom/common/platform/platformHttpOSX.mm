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
    NSURLConnection *connection;
    bool allowRedirect;
    const char *cacheToFile;
    NSMutableData* receivedData;
    bool statusCodeFail;
}

-(id)initWithCallback:(loom_HTTPCallback)cb 
    request:(NSMutableURLRequest*)req 
    payload:(void *)pl 
    allowRedirect:(bool)ar 
    cacheToFile:(const char *)c;
-(void)cancel;
-(void)complete;

@end

@implementation LMURLConnectionDelegate

-(id)initWithCallback:(loom_HTTPCallback)cb
    request:(NSMutableURLRequest*)req 
    payload:(void *)pl 
    allowRedirect:(bool)ar 
    cacheToFile:(const char *)cf
{
    self = [self init];
    
    callback = cb;
    payload = pl;
    allowRedirect = ar;
    cacheToFile = cf;

    receivedData = [NSMutableData alloc];
    [receivedData setLength:0];

    //create the connection with ourselves as the delegate
    connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    
    return self;
}

-(void)cancel
{
    [connection cancel];
}

-(void)complete
{
    [connection release];
    [receivedData release];
    receivedData = nil;
}

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse
{
    return allowRedirect ? request : nil;
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

    utByteArray* bytes = lmNew(NULL) utByteArray();
    bytes->attach(receivedData.mutableBytes, receivedData.length);
    
    if(statusCodeFail)
        callback(payload, LOOM_HTTP_ERROR, bytes);
    else
        callback(payload, LOOM_HTTP_SUCCESS, bytes);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    utByteArray *ba = lmNew(NULL) utByteArray();

    NSString* err = [error localizedDescription];
    ba->allocateAndCopy((void*)[err cStringUsingEncoding:NSUTF8StringEncoding], [err length]);

    callback(payload, LOOM_HTTP_ERROR, ba);
}

@end


//array of HTTP Connections
static LMURLConnectionDelegate *connections[MAX_CONCURRENT_HTTP_REQUESTS];



/**
 * Performs an asychronous http request
 */
int platform_HTTPSend(const char *url, const char* method, loom_HTTPCallback callback, void *payload, 
    const char *body, int bodyLength, utHashTable<utHashedString, utString> &headers, 
    const char *responseCacheFile, bool followRedirects)
{
    int index = 0;
    while ((connections[index] != NULL) && (index < MAX_CONCURRENT_HTTP_REQUESTS)) {index++;}
    if(index == MAX_CONCURRENT_HTTP_REQUESTS)
    {
        return -1;
    }
    
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
    
    connections[index] = [[LMURLConnectionDelegate alloc] initWithCallback:callback
                                                            request:request 
                                                            payload:payload 
                                                            allowRedirect:followRedirects 
                                                            cacheToFile:responseCacheFile];
    return index;
}

bool platform_HTTPIsConnected()
{
    // TODO: implement
    return true;
}

void platform_HTTPInit()
{
    //clear the connections to all start at null
    memset(connections, 0, sizeof(NSURLConnection *) * MAX_CONCURRENT_HTTP_REQUESTS);
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
    if ((index == -1) || connections[index] == NULL)
    {
        return false;
    }

    [connections[index] cancel];
    return true;
}

void platform_HTTPComplete(int index)
{
    if (index != -1)
    {
        [connections[index] complete];
        [connections[index] release];
        connections[index] = NULL;
    }
}