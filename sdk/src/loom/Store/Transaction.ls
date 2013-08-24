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
     * A transaction is used to track a purchase, indicating whether it has
     * completed successfully or not.
     *
     * @see loom.store.Store
     */
    public class Transaction
    {
        /// The product which was purchased in this transaction.
        public var productIdentifier:String;
        
        /// An opaque identifier for this specific transaction.
        public var transactionIdentifier:String;

        /// Time the transaction was processed.
        public var transactionDate:String; 
        
        /// True if the transaction has completed successfully and the user 
        /// should be able to reap the benefits.
        public var successful:Boolean;

        public override function toString():String
        {
            return "[Transaction productIdentifier="+ productIdentifier 
            + ", successful=" + successful 
            + ", transactionIdentifier=" + transactionIdentifier 
            + ", transactionDate="+ transactionDate + "]";
        }
    }   
}