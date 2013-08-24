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
     * Dummy store provider.
     *
     * This implements a simple dummy store that is useful for testing. It
     * is agreeable but stupid, ie, it will give you back data for products
     * and pretend transactions are going through but the data is always the
     * same or just slightly different.
     */
    public class DummyStoreProvider implements IStoreProvider
    {
        /** @inheritDocs */
        public function get providerName():String
        {
            return "Dummy";
        }

        /** @inheritDocs */
        public function get available():Boolean
        {
            return true;
        }

        /** @inheritDocs */
        public function listProducts(identifiers:Vector.<String>, onComplete:Function):void
        {
            trace("DummyStore - Listing products " + identifiers.toString());

            // TODO: Defer this callback to stress user code. LOOM-1354
            for each(var id in identifiers)
            {
                var p = new Product();
                p.identifier = id;
                p.title = "Item (" + id + ")";
                p.description = "It's really great!";
                p.price = "$100.00";

                Store.onProduct(p);
            }

            onComplete.call();          
        }

        /** @inheritDocs */
        public function requestPurchase(identifier:String, onComplete:Function):void
        {
            trace("DummyStore - requesting purchase: " + identifier);

            // TODO: Defer this callback to stress user code. LOOM-1354
            var txn = new Transaction();
            txn.productIdentifier = identifier;
            txn.transactionIdentifier = Math.random().toFixed(5);
            txn.transactionDate = "Today";
            txn.successful = true;

            Store.onTransaction(txn);

            onComplete.call();          
        }
    }   
}