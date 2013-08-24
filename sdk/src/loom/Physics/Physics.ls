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

package loom.physics 
{
    [Native(managed)]
    public native class PhysicsWall 
    {
    }

    [Native(managed)]
    public native class PhysicsBall
    {
        public native var x:Number;
        public native var y:Number;
        public native var angle:Number;
    }

    [Native(managed)]
    static native class Physics 
    {
        
        public static native function init():void;
        public static native function tick():void;
        
        public static native function setGravity(x:Number, y:Number);
        public static native function spawnWall(x1:Number, x2:Number, y1:Number, y2:Number):PhysicsWall;
        public static native function spawnBall(x:Number, y:Number, radius:Number, mass:Number):PhysicsBall;
        public static native function setInterObjectGravityEnabled(enabled:Boolean);        
        
    }
}