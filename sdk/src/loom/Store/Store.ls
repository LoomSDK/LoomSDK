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
     * Loom Store API.
     *
     * Loom abstracts the native store on your platform (if present) and provides
     * a streamlined interface to query products and initiate purchases.
     *
     * You need to set up products on your platform's store management console - 
     * iTunes Connect for iOS and the Play Store for Android. Then you can query
     * their presence and price by passing their identifiers to listProducts, and
     * initiate a purchase via requestPurchase.
     *
     * Product and transactions are reported via the onProduct and onTransaction
     * delegates. Subscribe to them before calling any Store methods.
     *
     * NOTES: 
     *
     * 1) If you are not using Loom CLI and you wish to use the Store on Android, 
     * you will manually need to add the "com.android.vending.BILLING" permission to 
     * the AndroidManifest.xml file.
     *
     * 2) If you are using Loom CLI and you wish to not include BILLING permissions
     * in your App, you can disable them by specifying "uses_store": "false" in your
     * loom.config file.
     *
     * @see Product
     * @see Transaction
     */
    public class Store 
    {
        private static var _provider:IStoreProvider = null;

        /**
         * Pass this constant to Store.initialize to select the dummy provider.
         *
         * See the Store API reference for details on the role of the dummy provider.
         */
        public static const DUMMY_PROVIDER:String = "dummy";

        /**
         * Called to initialize the Store API. You can optionally specify a 
         * provider; by default it uses the platform's native store. The only
         * supported provider string is "dummy" - this selects the 
         * DummyStoreProvider which is useful for testing.
         *
         * Make sure to add callbacks to onProduct and onTransaction BEFORE
         * calling initialize() as some platforms report information as part of
         * initialization.
         *
         * @see DummyStoreProvider
         */
        public static function initialize(provider:String = null)
        {
            switch(provider)
            {
                case DUMMY_PROVIDER:
                    _provider = new DummyStoreProvider();
                    break;

                default:
                    _provider = new NativeStoreProvider();
                    break;
            }
        }

        /**
         * Return the active store provider. This can be used to filter behavior
         * based on the store.
         */
        public static function get providerName():String
        {
            Debug.assert(_provider, "Store.activeStoreProvider - calling before initialize()");
            return _provider.providerName;
        }

        /**
         * If false, the store is unavailable and you should disable the purchase UI.
         */
        public static function get available():Boolean
        {
            Debug.assert(_provider, "Store.available - calling before initialize()");
            return _provider.available;
        }

        /**
         * Given a list of product identifiers (matching what you set up in the store's
         * management console) return detailed product data via the onProduct delegate.
         * 
         * @param identifiers List of product IDs for which to get information.
         * @param onComplete Called when the full list is reported via the onProduct delegate.
         *
         * @see Product
         */
        public static function listProducts(identifiers:Vector.<String>, onComplete:Function = null):void
        {
            Debug.assert(_provider, "Store.listProducts - calling before initialize()");
            if(!onComplete)
                onComplete = function():void {};
            _provider.listProducts(identifiers, onComplete);
        }
        
        /**
         * Initiate the native payment UI for the specified product (the identifier must
         * match what was specified in the store's management console). When the transaction
         * is completed, it's posted via the onTransaction delegate. You can only request
         * purchases for products that you've previously listed via listProducts.
         *
         * @param identifier Product to request a purchase.
         * @param onComplete Called when the purchase UI has completed; NOT when the
         *                   transaction is available.
         *
         * @see Transaction
         */
        public static function requestPurchase(identifier:String, onComplete:Function = null):void
        {
            Debug.assert(_provider, "Store.requestPurchase - calling before initialize()");
            if(!onComplete)
                onComplete = function():void {};
            _provider.requestPurchase(identifier, onComplete);
        }
        
        /**
         * This delegate is called once with each product's details, after a call
         * to listProducts. If a product isn't found or is otherwise unavailable,
         * this delegate will not be fired for it. It is passed one parameter of type
         * Product.
         *
         * @see Product
         */
        public static var onProduct:ProductDelegate;
        
        /**
         * This delegate is caleld once for each known transaction. Old transactions may be 
         * reported immediately after initialize() is called, and transactions started by 
         * requestPurchase will be reported after an indefinite period (ie, however long it
         * takes the native store to report it back). It is passed one parameter of type
         * Transaction.
         */
        public static var onTransaction:TransactionDelegate;
    }
 
    delegate ProductDelegate(product:Product):void;
    delegate TransactionDelegate(transaction:Transaction):void;
}