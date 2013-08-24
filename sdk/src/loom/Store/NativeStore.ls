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

package loom.store
{
    /**
     * Bindings to the native store API for the current platform.
     *
     * For simplicity, the native store bindings are implemented without a 
     * direct coupling to the loom.store API. This allows it to be more direct,
     * simplifying binding and native code, with an adapter (NativeStoreProvider)
     * presenting a simple-to-use and convenient API to users.
     */
    public native class NativeStore
    {
        /// Called to initialize the store. Calls to onProduct/onTransaction
        /// may occur directly from inside initialize() depending on the store
        /// API.
        public static native function initialize():void;

        /// Is IAP currently available? (ie user has not disable IAP on their
        /// device.)
        public static native var available:Boolean;

        /// A string identifying the native provider.
        public static native var providerName:String;

        /// Initiate a request for product information. JSON is an array
        /// of SKU strings.
        public static native function listProducts(json:String):void;

        /// Initiate a request for product purchase. identifier is a SKU
        /// previously requested via listProducts.
        public static native function requestPurchase(identifier:String):void;

        /// Called when a product is available. Parameters are:
        /// id, title, description, price, all strings.
        public static native var onProduct:NativeDelegate;

        /// Called when a product info request has completed.
        public static native var onProductComplete:NativeDelegate;

        /// Called when the purchase UI has gone away.
        public static native var onPurchaseUIComplete:NativeDelegate;

        /// Called when a transaction is avaialble: Parameters are:
        /// productId, transactionId, transactionDate, success. First
        /// three are strings, last is boolean.
        public static native var onTransaction:NativeDelegate;
    }
}