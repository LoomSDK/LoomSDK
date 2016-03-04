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
#import <Foundation/NSSet.h>
#import <StoreKit/StoreKit.h>

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformStore.h"
#include "loom/common/platform/EBPurchase.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"

extern "C"
{
  #include "loom/vendor/jansson/src/jansson_private.h"
}

lmDefineLogGroup(gAppleStoreLogGroup, "applestore", 1, LoomLogDefault);

static StoreEventCallback gEventCallback = NULL;

// We are only ever compiled on iOS so we don't have to
// include a platform guard.

@interface EBPurchaseListener : NSObject <EBPurchaseDelegate>

-(void) requestedProduct:(EBPurchase*)ebp
               skProduct:(SKProduct*)product
              identifier:(NSString*)productId
                    name:(NSString*)productName
                   price:(NSString*)productPrice
             description:(NSString*)productDescription;

-(void) gotAllProductListings;

-(void) successfulPurchase:(EBPurchase*)ebp
                  restored:(bool)isRestore
                identifier:(NSString*)productId
     transactionIdentifier:(NSString*)txnId
           transactionDate:(NSString*)txnDate
                   receipt:(NSData*)transactionReceipt;

-(void) failedPurchase:(EBPurchase*)ebp
                 error:(NSInteger)errorCode
               message:(NSString*)errorMessage;

-(void) incompleteRestore:(EBPurchase*)ebp;

-(void) failedRestore:(EBPurchase*)ebp
                error:(NSInteger)errorCode
              message:(NSString*)errorMessage;

@end

@implementation EBPurchaseListener

-(void) gotAllProductListings
{
    gEventCallback("productComplete", NULL);
}

-(void) requestedProduct:(EBPurchase*)ebp
               skProduct:(SKProduct*)product
              identifier:(NSString*)productId
                    name:(NSString*)productName
                   price:(NSString*)productPrice
             description:(NSString*)productDescription
{
    // Convert into JSON.
    json_t *packaged = json_pack("{s:s, s:s, s:s, s:s}",
        "productId",  [productId cStringUsingEncoding:NSUTF8StringEncoding],
        "title",      [productName cStringUsingEncoding:NSUTF8StringEncoding],
        "price",      [productPrice cStringUsingEncoding:NSUTF8StringEncoding],
        "description",[productDescription cStringUsingEncoding:NSUTF8StringEncoding]
        );
    const char *packagedString = json_dumps(packaged, 0);

    // And submit to the callback.
    gEventCallback("product", packagedString);

    // Clean it up!
    jsonp_free((void*)packagedString);
    json_decref(packaged);
}

-(void) successfulPurchase:(EBPurchase*)ebp
                  restored:(bool)isRestore
                identifier:(NSString*)productId
     transactionIdentifier:(NSString*)txnId
           transactionDate:(NSString*)txnDate
                   receipt:(NSData*)transactionReceipt
{
    // Convert into JSON.
    json_t *transaction = json_pack("{s:s, s:s, s:s, s:i}",
        "productId",     [productId cStringUsingEncoding:NSUTF8StringEncoding],
        "transactionId", [txnId cStringUsingEncoding:NSUTF8StringEncoding],
        "transactionDate",       [txnDate cStringUsingEncoding:NSUTF8StringEncoding],
        // TODO: Include receipt LOOM-1353
        "successful",            1
        );
    const char *transactionString = json_dumps(transaction, 0);

    // And submit back to Loom.
    gEventCallback("uiComplete", NULL);
    gEventCallback("transaction", transactionString);

    // Clean it up!
    jsonp_free((void*)transactionString);
    json_decref(transaction);
}

-(void) failedPurchase:(EBPurchase*)ebp
                 error:(NSInteger)errorCode
               message:(NSString*)errorMessage
{
    
    gEventCallback("uiComplete", NULL);
    lmLog(gAppleStoreLogGroup, "Got a failed purchase %d '%s'.", errorCode, [errorMessage cStringUsingEncoding:NSUTF8StringEncoding]);
}

-(void) incompleteRestore:(EBPurchase*)ebp
{
    lmLog(gAppleStoreLogGroup, "Got an incomplete restore.");
}

-(void) failedRestore:(EBPurchase*)ebp
                error:(NSInteger)errorCode
              message:(NSString*)errorMessage
{
    lmLog(gAppleStoreLogGroup, "Got a failed restore with error %d '%s'.", errorCode, [errorMessage cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end

static EBPurchase *gPurchase = NULL;
static EBPurchaseListener *gPurchaseListener = NULL;

void platform_storeInitialize(StoreEventCallback eventCallback)
{
    lmAssert(gEventCallback == NULL, "Can't initialize store twice.");
    gEventCallback = eventCallback;

    // Initialize the EBPurchase and its listener.
    gPurchase = [[EBPurchase alloc] init];
    gPurchaseListener = [[EBPurchaseListener alloc] init];
    gPurchase.delegate = gPurchaseListener;
}

int platform_storeAvailable()
{
    return [SKPaymentQueue canMakePayments] ? 1 : 0;
}

const char *platform_storeProviderName()
{
    return "iTunes Store";
}

void platform_storeListProducts(const char *requestJson)
{
    // Parse the request list.
    json_t *requestList = json_loads(requestJson, 0, NULL);

    // Parse out the list.
    lmAssert(json_is_array(requestList), "Got non-list.");

    // Make the requests
    NSMutableSet *prodSet = [NSMutableSet setWithCapacity:json_array_size(requestList)];
    for(int i=0; i<json_array_size(requestList); i++)
    {
        json_t *item = json_array_get(requestList, i);
        lmAssert(json_is_string(item), "Got non-string.");
        
        NSString *prodString = [NSString stringWithCString:json_string_value(item)
                                                  encoding:NSStringEncodingConversionAllowLossy];
        
        [prodSet addObject:prodString];
    }

    if(![gPurchase requestProducts:prodSet])
    {
        lmLogError(gAppleStoreLogGroup, "Failed to request product info.");
    }
}

void platform_storeRequestPurchase(const char *identifier)
{
    // Fire off the request.
    NSString *prodString = [NSString stringWithCString:identifier
                                              encoding:NSStringEncodingConversionAllowLossy];
    
    // Create a payment.
    SKMutablePayment *payment = [[SKMutablePayment alloc] init];
    payment.productIdentifier = prodString;
    payment.quantity = 1;
    payment.requestData = nil;
    
    if(![gPurchase purchaseProduct:payment])
    {
        lmLogError(gAppleStoreLogGroup, "Failed to trigger product purchase for '%s'", identifier);
    }
}
