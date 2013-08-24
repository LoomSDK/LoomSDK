//
//  EBPurchase.m
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


#import "EBPurchase.h"

@implementation EBPurchase

@synthesize delegate;
@synthesize validProduct;


-(bool) requestProducts:(NSSet*)productIds
{
    if(productIds == nil)
    {
        NSLog(@"EBPurchase requestProduct: productIds = NIL");
        return NO;
    }

    NSLog(@"EBPurchase requestProduct: %@", productIds);

    if ([SKPaymentQueue canMakePayments] == NO)
    {
        // Notify user that In-App Purchase is Disabled.
        NSLog(@"EBPurchase requestProduct: IAP Disabled");
        return NO;
    }

    // Initiate a product request of the Product ID.
    SKProductsRequest *prodRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
    prodRequest.delegate = self;
    [prodRequest start];
    
    return YES;
}

-(bool) purchaseProduct:(SKPayment*)paymentRequest
{
    if (paymentRequest == nil)
    {
        NSLog(@"EBPurchase purchaseProduct: SKPayment = NIL");
        return NO;
    }
    
    NSLog(@"EBPurchase purchaseProduct: %@", paymentRequest.productIdentifier);
    
    if ([SKPaymentQueue canMakePayments] == NO)
    {
        // Notify user that In-App Purchase is Disabled.
        NSLog(@"EBPurchase purchaseProduct: IAP Disabled");
        return NO;
    }
    
    // Assign an observer to monitor the transaction status.
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    // Request a purchase of the product.
    [[SKPaymentQueue defaultQueue] addPayment:paymentRequest];

    return YES;
}

-(bool) restorePurchase 
{
    NSLog(@"EBPurchase restorePurchase");
    
    if ([SKPaymentQueue canMakePayments] == NO)
        return NO;

    // Assign an observer to monitor the transaction status.
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    // Request to restore previous purchases.
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
    return YES;
}

#pragma mark -
#pragma mark SKProductsRequestDelegate Methods

// Store Kit returns a response from an SKProductsRequest.
- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
	// Parse the received product info.
    NSLog(@"Received a product request response.");

    // Report any failed logs.
    for (NSString *invalidId in response.invalidProductIdentifiers)
    {
        NSLog(@"Failed to get product info for: %@", invalidId);
    }
    
    for (SKProduct *product in response.products)
    {
        // Yes, product is available, so return values.
        if ([delegate respondsToSelector:@selector(requestedProduct:skProduct:identifier:name:price:description:)])
            [delegate requestedProduct:self
                             skProduct:product
                            identifier:product.productIdentifier
                                  name:product.localizedTitle
                                 price:[product.price stringValue]
                           description:product.localizedDescription];
    }

    // And note we got everything.
    [delegate gotAllProductListings];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"SKRequest failed: %@,  %@", request, error);
    [request release];
}

- (void)requestDidFinish:(SKRequest *)request
{
    NSLog(@"SKRequest finished: %@", request);
    [request release];
}

#pragma mark -
#pragma mark SKPaymentTransactionObserver Methods

// The transaction status of the SKPaymentQueue is sent here.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for(SKPaymentTransaction *transaction in transactions)
    {
		switch (transaction.transactionState)
        {
			case SKPaymentTransactionStatePurchasing:
				// Item is still in the process of being purchased
                NSLog(@"Saw transaction %@ in purchasing state.", transaction);
				break;
				
			case SKPaymentTransactionStatePurchased:
				// Item was successfully purchased!
                NSLog(@"Saw transaction %@ enter purchased state.", transaction);

				// Return transaction data. App should provide user with purchased product.
                if ([delegate respondsToSelector:@selector(successfulPurchase:restored:identifier:transactionIdentifier:transactionDate:receipt:)])
                    [delegate successfulPurchase:self
                                        restored:NO
                                      identifier:transaction.payment.productIdentifier
                           transactionIdentifier:transaction.transactionIdentifier
                                 transactionDate:[transaction.transactionDate description]
                                         receipt:transaction.transactionReceipt];
				
				// After customer has successfully received purchased content,
				// remove the finished transaction from the payment queue.
				[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
				break;
				
			case SKPaymentTransactionStateRestored:
				// Verified that user has already paid for this item.
				// Ideal for restoring item across all devices of this customer.
                NSLog(@"Saw transaction %@ enter restored state.", transaction);
				
				// Return transaction data. App should provide user with purchased product.
                if ([delegate respondsToSelector:@selector(successfulPurchase:restored:identifier:transactionIdentifier:transactionDate:receipt:)])
                    [delegate successfulPurchase:self
                                        restored:YES
                                      identifier:transaction.payment.productIdentifier
                           transactionIdentifier:transaction.transactionIdentifier
                                 transactionDate:[transaction.transactionDate description]
                                         receipt:transaction.transactionReceipt];
                
				// After customer has restored purchased content on this device,
				// remove the finished transaction from the payment queue.
				[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
				break;
				
			case SKPaymentTransactionStateFailed:
				// Purchase was either cancelled by user or an error occurred.
                NSLog(@"Saw transaction %@ enter failed state.", transaction);

				if (transaction.error.code != SKErrorPaymentCancelled)
                {
                    // A transaction error occurred, so notify user.
                    if ([delegate respondsToSelector:@selector(failedPurchase:error:message:)])
                        [delegate failedPurchase:self error:transaction.error.code message:transaction.error.localizedDescription];
				}
                
				// Finished transactions should be removed from the payment queue.
				[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
				break;
		}
	}
}

// Called when one or more transactions have been removed from the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    NSLog(@"EBPurchase removedTransactions");
    
    // Release the transaction observer since transaction is finished/removed.
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

// Called when SKPaymentQueue has finished sending restored transactions.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    
    NSLog(@"EBPurchase paymentQueueRestoreCompletedTransactionsFinished");
    
    if ([queue.transactions count] == 0) {
        // Queue does not include any transactions, so either user has not yet made a purchase
        // or the user's prior purchase is unavailable, so notify app (and user) accordingly.
        
        NSLog(@"EBPurchase restore queue.transactions count == 0");
        
        // Release the transaction observer since no prior transactions were found.
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
        
        if ([delegate respondsToSelector:@selector(incompleteRestore:)])
            [delegate incompleteRestore:self];
        
    }
    else
    {
        // Queue does contain one or more transactions, so return transaction data.
        // App should provide user with purchased product.
        
        NSLog(@"EBPurchase restore queue.transactions available");
        
        for(SKPaymentTransaction *transaction in queue.transactions)
        {
            NSLog(@"EBPurchase restore queue.transactions - transaction data found");
            
            if ([delegate respondsToSelector:@selector(successfulPurchase:restored:identifier:receipt:)])
                [delegate successfulPurchase:self
                                    restored:YES
                                  identifier:transaction.payment.productIdentifier
                       transactionIdentifier:transaction.transactionIdentifier
                             transactionDate:[transaction.transactionDate description]
                                     receipt:transaction.transactionReceipt];
        }
    }
}

// Called if an error occurred while restoring transactions.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    // Restore was cancelled or an error occurred, so notify user.

    NSLog(@"EBPurchase restoreCompletedTransactionsFailedWithError");

    if ([delegate respondsToSelector:@selector(failedRestore:error:message:)])
        [delegate failedRestore:self error:error.code message:error.localizedDescription];
}


#pragma mark - Internal Methods & Events

- (void)dealloc
{
    [validProduct release];
    [super dealloc];
}

@end