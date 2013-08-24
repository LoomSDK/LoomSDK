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

package loom.gameframework
{

    /**
     * Base class for components that need to perform actions every tick. This
     * needs to be subclassed to be useful.
     */
    public class TickedComponent extends LoomComponent implements ITicked
    {
        /**
         * The update priority for this component. Higher numbered priorities have
         * onInterpolateTick and onTick called before lower priorities.
         */
        public var updatePriority:Number = 0.0;
        
        private var _registerForUpdates:Boolean = true;
        private var _isRegisteredForUpdates:Boolean = false;
        
        [Inject]
        public var timeManager:TimeManager;
        
        /**
         * Set to register/unregister for tick updates.
         */
        public function set registerForTicks(value:Boolean):void
        {
            _registerForUpdates = value;
            
            if(_registerForUpdates && !_isRegisteredForUpdates)
            {
                // Need to register.
                _isRegisteredForUpdates = true;
                timeManager.addTickedObject(this, updatePriority);                
            }
            else if(!_registerForUpdates && _isRegisteredForUpdates)
            {
                // Need to unregister.
                _isRegisteredForUpdates = false;
                timeManager.removeTickedObject(this);
            }
        }
        
        /**
         * @private
         */
        public function get registerForTicks():Boolean
        {
            return _registerForUpdates;
        }
        
        /**
         * @inheritDoc
         */
        public function onTick():void
        {
            applyBindings();
        }
        
        override protected function onAdd():Boolean
        {
            if(!super.onAdd())
                return false;
            
            // This causes the component to be registerd if it isn't already.
            registerForTicks = registerForTicks;
            
            return true;
        }
        
        override protected function onRemove():void
        {
            super.onRemove();
            
            // Make sure we are unregistered.
            registerForTicks = false;
        }
    }
}