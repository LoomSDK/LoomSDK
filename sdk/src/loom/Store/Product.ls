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
     * A purchaseable product.
     *
     * This is an item as described by the store API we're targeting. The 
     * primary data is the product identifier, which is used to trigger a purchase
     * via Store.requestPurchase(). The other data is included for debug/display
     * purposes.
     *
     * @see loom.store.Store
     */
    public class Product
    {
        /// An opaque identifier for this product. Provided via the store's 
        /// management console.
        public var identifier:String;

        /// A localized displayable title for this product.
        public var title:String;

        /// A localized displayable description for this product.
        public var description:String;

        /// A localized displayable price for this product. It includes currency
        /// as well as cost.
        public var price:String;

        public override function toString():String
        {
            return "[Product identifier='" + identifier 
            + ", title='" + title + "'"
            + ", description='" + description + "'"
            + ", price='" + price + "']";
        }
    }   
}