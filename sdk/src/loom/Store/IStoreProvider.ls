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
     * Interface for a store API provider.
     *
     * There are multiple platform-specific native store providers; we may also 
     * provide implementations in script that are either live or for debugging.
     * This is the interface that the Store static class expects.
     */
    public interface IStoreProvider
    {
        /// True if the store is available; generally false means that the user
        /// has turned off purchases or hasn't authorized their device.
        function get available():Boolean;

        /// An identifier for this provider.
        function get providerName():String;

        /// Take a list of product identifiers as created in the store's 
        /// management console, and post information about them to the 
        /// Store.onProduct delegate. Calls onComplete when the results
        /// have been posted back.
        function listProducts(identifiers:Vector.<String>, onComplete:Function):void;

        /// Take a product identifier and initiate the purchase process.
        /// A Transaction will be posted to Store.onTransaction with the
        /// result. Calls onComplete when the UI for the purchase has gone away.
        function requestPurchase(identifier:String, onComplete:Function):void;

    }   
}