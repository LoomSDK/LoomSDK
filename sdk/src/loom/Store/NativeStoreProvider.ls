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
     * Wraps the low-level native store implementation and adapts it to suit 
     * the high level store API.
     */
    public class NativeStoreProvider implements IStoreProvider
    {
        protected var _listCompleteCallback:Function;
        protected var _purchaseCompleteCallback:Function;

        public function NativeStoreProvider()
        {
            // Register delegates.
            NativeStore.onProduct += productHandler;
            NativeStore.onProductComplete += productCompleteHandler;
            NativeStore.onPurchaseUIComplete += productPurchaseUICompleteHandler;
            NativeStore.onTransaction += transactionHandler;

            NativeStore.initialize();
        }

        protected function productHandler(id:String, title:String, description:String, price:String):void
        {
            var product:Product = new Product();
            product.identifier = id;
            product.title = title;
            product.description = description;
            product.price = price;

            Store.onProduct(product);
        }

        protected function productCompleteHandler():void
        {
            if(_listCompleteCallback)
                _listCompleteCallback.call();
            _listCompleteCallback = null;
        }

        protected function productPurchaseUICompleteHandler():void
        {
            if(_purchaseCompleteCallback)
                _purchaseCompleteCallback.call();
            _purchaseCompleteCallback = null;
        }

        protected function transactionHandler(productId:String, txnId:String, txnDate:String, success:Boolean):void
        {
            // Create transaction...
            var txn:Transaction = new Transaction();
            txn.productIdentifier = productId;
            txn.transactionIdentifier = txnId;
            txn.transactionDate = txnDate;
            txn.successful = success;

            // ...and fire it off.
            Store.onTransaction(txn);
        }

        public function get available():Boolean
        {
            return NativeStore.available;
        }

        public function get providerName():String
        {
            return NativeStore.providerName;
        }

        public function listProducts(identifiers:Vector.<String>, onComplete:Function):void
        {
            Debug.assert(_listCompleteCallback == null, "Already have a listProducts call in flight.");

            // Construct JSON.
            var json = "[";
            for(var i:int=0; i<identifiers.length-1; i++)
            {
                json += "\"" + identifiers[i] + "\",";
            }
            json += "\"" + identifiers[identifiers.length-1] + "\"]";

            // Note callback.
            _listCompleteCallback = onComplete;

            // Pass to store API, kick off request.
            trace("Calling listProducts with JSON: " + json);
            NativeStore.listProducts(json);
        }

        public function requestPurchase(identifier:String, onComplete:Function):void
        {
            Debug.assert(_purchaseCompleteCallback == null, "Already have a requestPurchase call in flight.");

            // Note callback.
            _purchaseCompleteCallback = onComplete;

            // Pass to store API, kick off request.
            NativeStore.requestPurchase(identifier);
        }
    }
}