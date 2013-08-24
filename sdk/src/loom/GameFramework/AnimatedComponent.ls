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
     * Base class for components that need to perform actions every frame. This
     * needs to be subclassed to be useful.
     */
    public class AnimatedComponent extends LoomComponent implements IAnimated
    {
        /**
         * The update priority for this component. Higher numbered priorities have
         * OnFrame called before lower priorities.
         */
        [EditorData(ignore="true")]
        public var updatePriority:Number = 0.0;
        
        private var _registerForUpdates:Boolean = true;
        private var _isRegisteredForUpdates:Boolean = false;
        
        [Inject]
        public var timeManager:TimeManager;
        
        /**
         * Set to register/unregister for frame updates.
         */
        [EditorData(ignore="true")]
        public function set registerForUpdates(value:Boolean):void
        {
            _registerForUpdates = value;
            
            if(_registerForUpdates && !_isRegisteredForUpdates)
            {
                // Need to register.
                _isRegisteredForUpdates = true;
                timeManager.addAnimatedObject(this, updatePriority);
            }
            else if(!_registerForUpdates && _isRegisteredForUpdates)
            {
                // Need to unregister.
                _isRegisteredForUpdates = false;
                timeManager.removeAnimatedObject(this);
            }
        }
        
        /**
         * @private
         */
        public function get registerForUpdates():Boolean
        {
            return _registerForUpdates;
        }
        
        /**
         * @inheritDoc
         */
        public function onFrame():void
        {
            applyBindings();
        }
        
        override protected function onAdd():Boolean
        {
            if (!super.onAdd())
                return false;
            
            // This causes the component to be registerd if it isn't already.
            registerForUpdates = registerForUpdates;
            
            return true;
        }
        
        override protected function onRemove():void
        {
            super.onRemove();
            
            // Make sure we are unregistered.
            registerForUpdates = false;
        }
    }   
}