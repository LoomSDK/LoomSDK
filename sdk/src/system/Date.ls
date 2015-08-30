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

package system {
    
/**
 * Provides native date utility.
 */
[Native]
native class Date {
    
    /**
     * This function wraps the native strftime function from the ctime C++ library, which is used to get a string representation of the current system time.
     * 
     * @param format The format string to be passed into the native strftime function. See [C++ documentation](http://www.cplusplus.com/reference/ctime/strftime/)
     * for details on formatting options.
     * @return A formatted string representing date information.
     */
    public native static function formatTime(format:String):String;
}   
}