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

package compiler {

import system.VM;

class LSCompiler {

    public static native function compile(buildFile:String);
    public static native function setDebugBuild(debugBuild:Boolean);
    public static native function isDebugBuild():Boolean;
    
    public static function main() {
        
        setDebugBuild(true);
        
        for (var i:Number = 1; i < CommandLine.getArgCount(); i++) {
        
            var arg:String = CommandLine.getArg(i);
            
            // check commandline options
            if (arg == "--profile") {
            
                Console.print("Profiling enabled");
                Profiler.enable(true);
                continue;
            }
            
            if (arg == "--release") {
            
                setDebugBuild(false);
                continue;
            }
            
            // skip commandline options
            if (arg == "--bootstrap")
                continue;
                
            // skip --root and folder specification options
            if (arg == "--root") {
                i++;
                continue;
            }
                
        
            isDebugBuild() ? Console.print("Compiling Debug: " + arg) : Console.print("Compiling Release: " + arg);
            
            compile(arg);
            
        }
        
    }
    
    private static native var releaseBuild:Boolean;

}

}