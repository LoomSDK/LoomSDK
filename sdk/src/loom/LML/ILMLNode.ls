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

package loom.lml {
    
    /**
     *  The ILMLNode interface is an optional interface for objects that
     *  are instantiated via LML. It provides methods for initialization
     *  and lifecycle for a node of LML.
     */
    public interface ILMLNode {

        /**
         *  Called after the object has been instiated and before the object 
         *  has had any properties/children set in LML. This is useful for
         *  initialization of the LML node before mutating it. Passes the id of the object.
         *
         *  @param id The id of the object in LML
         */
         function preinitializeLMLNode(id:String);

        /**
         *  Called after the object has been instantiated and all of it's
         *  properties/children have been set from LML. Passes the id of the object.
         *
         *  @param id The id of the object in LML.
         */
        function initializeLMLNode(id:String);

    }

}