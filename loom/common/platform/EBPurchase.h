//
//  EBPurchase.h
//  Simple In-App Purchase for iOS
//
//  Created by Dave Wooldridge, Electric Butterfly, Inc.
//  Copyright (c) 2011 Electric Butterfly, Inc. - http://www.ebutterfly.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  redistribute it and use it in source and binary forms, with or without
//  modification, subject to the following conditions:
//
//  1. This Software may be used for any purpose, including commercial applications.
//
//  2. This Software in source code form may be redistributed freely and must
//  retain the above copyright notice, this list of conditions and the following
//  disclaimer. Altered source versions must be plainly marked as such, and must
//  not be misrepresented as being the original Software.
//
//  3. Neither the name of the author nor the name of the author's company may be
//  used to endorse or promote products derived from this Software without specific
//  prior written permission.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol EBPurchaseDelegate;

@interface EBPurchase : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    id<EBPurchaseDelegate> delegate;
    SKProduct              *validProduct;
}

@property(assign) id<EBPurchaseDelegate> delegate;
@property (nonatomic, retain) SKProduct  *validProduct;

-(bool)requestProducts:(NSSet *)productIds;
-(bool)purchaseProduct:(SKPayment *)paymentRequest;
-(bool)restorePurchase;

@end

@protocol EBPurchaseDelegate<NSObject>
@optional

-(void)gotAllProductListings;

-(void)requestedProduct:(EBPurchase *)ebp
    skProduct:(SKProduct *)skProduct
    identifier:(NSString *)productId
    name:(NSString *)productName
    price:(NSString *)productPrice
    description:(NSString *)productDescription;

-(void)successfulPurchase:(EBPurchase *)ebp
    restored:(bool)isRestore
    identifier:(NSString *)productId
    transactionIdentifier:(NSString *)id
    transactionDate:(NSString *)date
    receipt:(NSData *)transactionReceipt;

-(void)failedPurchase:(EBPurchase *)ebp
    error:(NSInteger)errorCode
    message:(NSString *)errorMessage;

-(void)incompleteRestore:(EBPurchase *)ebp;

-(void)failedRestore:(EBPurchase *)ebp
    error:(NSInteger)errorCode
    message:(NSString *)errorMessage;

@end
