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


package system.application
{

	public class BaseApplication
	{

        protected function run()
        {

        }

        /**
         * Sets a warning level in megabytes for the Application's VM
         * If the Application VM exceeds this level a warning will be displayed in 
         * the console.  Please note that this warning level is purely for the scripting
         * VM and not other assets that may be loaded
         * @param   megabytes The amount of ram in megabytes that causes a warning when exceeded
         */
        public function setMemoryWarningLevel(megabytes:int)
        {
            GC.setMemoryWarningLevel(megabytes);
        }



	}

}