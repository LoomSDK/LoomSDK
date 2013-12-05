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

package loom.box2d 
{
    [Native(managed)]
    final public native class b2Vec2
    {        
        public native var x:Number;
        public native var y:Number;

        public native function b2Vec2(vec_x:Number, vec_y:Number);

        public native function setZero():void;
        public native function setValue(vec_x:Number, vec_y:Number):void;
        public native function length():Number;
        public native function lengthSquared():Number;
        public native function normalize():Number;
        public native function isValid():Boolean;
        public native function skew():b2Vec2;
    }
 
    [Native(managed)]
    final public native class b2BodyDef
    {        
        public native var position:b2Vec2;
        public native var angle:Number;
        public native var linearVelocity:b2Vec2;
        public native var angularVelocity:Number;
        public native var linearDamping:Number;
        public native var angularDamping:Number;
        public native var allowSleep:Boolean;
        public native var awake:Boolean;
        public native var fixedRotation:Boolean;
        public native var bullet:Boolean;
        public native var active:Boolean;
        public native var gravityScale:Number;
    }

    [Native(managed)]
    final public native class b2Body
    {
        //public native function createFixture(def:b2FixtureDef):b2Fixture;
        //public native function destroyFixture(fixture:b2Fixture):void;
        public native function setTransform(position:b2Vec2, angle:Number):void;
        //public native function getTransform():b2Transform;
        public native function getPosition():b2Vec2;
        public native function getAngle():Number;
        public native function getWorldCenter():b2Vec2;
        public native function getLocalCenter():b2Vec2;
        public native function setLinearVelocity(velocity:b2Vec2):void;
        public native function getLinearVelocity():b2Vec2;
        public native function setAngularVelocity(omega:Number):void;
        public native function getAngularVelocity():Number;
        public native function applyForce(force:b2Vec2, point:b2Vec2, wake:Boolean):void;
        public native function applyForceToCenter(force:b2Vec2, wake:Boolean):void;
        public native function applyTorque(torque:Number, wake:Boolean):void;
        public native function applyLinearImpulse(impulse:b2Vec2, point:b2Vec2, wake:Boolean):void;
        public native function applyAngularImpulse(impulse:Number, wake:Boolean):void;
        public native function getMass():Number;
        public native function getInertia():Number;
        //public native function getMassData(data:b2MassData):void;
        //public native function setMassData(data:b2MassData):void;
        public native function resetMassData():void;
        public native function getWorldPoint(localPoint:b2Vec2):b2Vec2;
        public native function getWorldVector(localVector:b2Vec2):b2Vec2;
        public native function getLocalPoint(worldPoint:b2Vec2):b2Vec2;
        public native function getLocalVector(worldVector:b2Vec2):b2Vec2;
        public native function getLinearVelocityFromWorldPoint(worldPoint:b2Vec2):b2Vec2;
        public native function getLinearVelocityFromLocalPoint(localPoint:b2Vec2):b2Vec2;
        public native function getLinearDamping():Number;
        public native function setLinearDamping(linearDampling:Number):void;
        public native function getAngularDamping():Number;
        public native function setAngularDamping(angularDampling:Number):void;
        public native function getGravityScale():Number;
        public native function setGravityScale(scale:Number):void;
        //public native function setType(type:int):void;
        //public native function getType():int;
        public native function setBullet(flag:Boolean):void;
        public native function isBullet():Boolean;
        public native function setSleepingAllowed(flag:Boolean):void;
        public native function isSleepingAllowed():Boolean;
        public native function setAwake(flag:Boolean):void;
        public native function isAwake():Boolean;
        public native function setActive(flag:Boolean):void;
        public native function isActive():Boolean;
        public native function setFixedRotation(flag:Boolean):void;
        public native function isFixedRotation():Boolean;
        public native function getNext():b2Body;
        public native function getWorld():b2World;
        public native function dump():void;
    }
 
    [Native(managed)]
    final public native class b2World
    {        
        public native function b2World(gravity:b2Vec2);

        public native function createBody(def:b2BodyDef):b2Body;
        public native function destroyBody(body:b2Body):void;
        public native function getBodyCount():Number;
        //public native function createJoint(def:b2JointDef):b2Joint;
        //public native function destroyJoint(joint:b2Joint):void;
        public native function getJointCount():Number;
        public native function step(timeStep:Number, velocityIterations:int, positionIterations:int):void;
        public native function isLocked():Boolean;
        public native function setAllowSleeping(value:Boolean):void;
        public native function getAllowSleeping():Boolean;
        public native function setGravity(gravity:b2Vec2):void;
        public native function getGravity():b2Vec2;
        public native function clearForces():void;
        public native function setAutoClearForces(clear:Boolean):void;
        public native function getAutoClearForces():Boolean;
        public native function shiftOrigin(newOrigin:b2Vec2):void;
        public native function dump():void;
    }

}
