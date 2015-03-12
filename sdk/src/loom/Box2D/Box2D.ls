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
/*
* Copyright (c) 2006-2011 Erin Catto http://www.box2d.org
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
*/

package loom.box2d 
{
    import loom.LoomTextAsset;
    
    /**
     * Enumeration of body types.
     * Static bodies are able to be positioned, but will not move.
     * Kinematic bodies are able to be moved, but are not affected by other bodies.
     * Dynamic bodies are affected by other bodies and will give way to static or kinematic bodies.
     */
    enum BodyType {
        STATIC = 0,
        KINEMATIC,
        DYNAMIC
    };    
    
    /**
     * Vector in 2-dimensional space.
     */
    [Native(managed)]
    final public native class Vec2
    {        
        public native var x:Number;
        public native var y:Number;
        
        /**
         * Construct a 2D vector with the specified x and y coordinates.
         * @param x X coordinate of the vector.
         * @param y Y coordinate of the vector.
         */
        public native function Vec2(x:Number, y:Number);
        
        /**
         * Set x and y to zero.
         */
        public native function setZero():void;
        
        /**
         * Set the vector to the specified coordinates.
         * @param x X coordinate of the vector.
         * @param y Y coordinate of the vector.
         */
        public native function setValue(x:Number, y:Number):void;
        
        /**
         * The length of the vector. Use lengthSquared in performance-sensitive places if possible to avoid the square root call.
         * @return The length of the vector.
         */
        public native function length():Number;
        
        /**
         * The squared length of the vector. Avoids the use of the square root call, making it more performant.
         * @return The squared length of the vector.
         */
        public native function lengthSquared():Number;
        
        /**
         * Normalizes the vector into a unit vector with the length of 1 and returns the previous length.
         * @return The previous length of the vector.
         */
        public native function normalize():Number;
        
        /**
         * Checks if the coordinates of the vector are finite or not.
         * @return true if all the coordinates are finite, false if any of them are infinite or NaN.
         */
        public native function isValid():Boolean;
        
        /**
         * Returns a skewed vector that is perpendicular to this vector.
         * return.x = -y
         * return.y = x
         * @return The skewed vector.
         */
        public native function skew():Vec2;
    }
    
    /**
     * Body definition holding the data needed to create a body.
     */
    [Native(managed)]
    final public native class BodyDef
    {
        /**
         * The BodyType of the body definition.
         * @see loom.box2d.BodyType
         */
        public static native const type:int;
        
        /**
         * Position vector of the body.
         */
        public native var position:Vec2;
        
        /**
         * Angle of the body in radians.
         */
        public native var angle:Number;
        
        /**
         * Positional velocity vector.
         */
        public native var linearVelocity:Vec2;
        
        /**
         * Angular velocity in radians per second.
         */
        public native var angularVelocity:Number;
        
        /**
         * Linear damping is used to reduce the linear velocity. The damping parameter
         * can be larger than 1.0 but the damping effect becomes sensitive to the
         * time step when the damping parameter is large.
         */
        public native var linearDamping:Number;
        
        /**
         * Angular damping is used to reduce the angular velocity. The damping parameter
         * can be larger than 1.0 but the damping effect becomes sensitive to the
         * time step when the damping parameter is large.
         */
        public native var angularDamping:Number;
        
        /**
         * Set this flag to false if this body should never fall asleep.
         * Note that this increases CPU usage.
         */
        public native var allowSleep:Boolean;
        
        /**
         * true if the body is initially awake, false if it's initally sleeping.
         */
        public native var awake:Boolean;
        
        /**
         * true if the body should have a fixed rotation (good for characters).
         */
        public native var fixedRotation:Boolean;
        
        /**
         * true if the body is a fast moving body that should be prevented from tunneling through other moving bodies.
         * Note that all bodies are prevented from tunneling through kinematic and static bodies. This setting is only considered on dynamic bodies.
         * @warning You should use this flag sparingly since it increases processing time.
         */
        public native var bullet:Boolean;
        
        /**
         * true if the body initially starts out being active.
         */
        public native var active:Boolean;
        
        /**
         * Per-body gravity scaling.
         */
        public native var gravityScale:Number;
    }
    
    /**
     * A polygon shape is a solid convex polygon.
     * A polygon is convex when all line segments connecting two points in the interior do not cross any edge of the polygon.
     * Polygons are solid and never hollow. A polygon must have 3 or more vertices.
     */
    [Native(managed)]
    final public native class PolygonShape extends Shape
    {
        /**
         * Build vertices to represent an axis-aligned box centered on the local origin.
         * @param hx The half-width of the box.
         * @param hy The half-height of the box.
        */
        public native function setAsBox(hx:Number, hy:Number):void;
    }
    
    /**
     * Circle shapes have a position and radius.
     * Circles are solid. You cannot make a hollow circle. However, you can create chains of line segments using polygon shapes.
     */
    [Native(managed)]
    final public native class CircleShape extends Shape
    {        
    }
    
    /**
     * Shapes describe collision geometry and may be used independently of physics simulation.
     */
    [Native(managed)]
    public native class Shape
    {
        /**
         * The radius of the shape (applies to polygons as well as circles).    
         */
        public native var radius:Number;
    }

    /**
     * Fixture definition holding the data needed to create a fixture.
     */
    [Native(managed)]
    final public native class FixtureDef
    {
        /**
         * The shape that the fixture relates to.
         */
        public native var shape:Shape;
        
        /**
         * The friction coefficient, usually in the range [0,1].
         */
        public native var friction:Number;
        
        /**
         * The restitution (elasticity) usually in the range [0,1].
         */
        public native var restitution:Number;
        
        /**
         * The density, usually in kg/m^2.
         */
        public native var density:Number;
        
        /**
         * A sensor shape collects contact information but never generates a collision response.
         */
        public native var isSensor:Boolean;
        //public native var filter:Filter;
    }
    
    /**
     * Fixtures allow Shape instances to be attached to Body instances.
     */
    [Native(managed)]
    final public native class Fixture
    {
        /**
         * Set the density of the fixture.
         */
        public native function setDensity(d:Number):void;
        
        /**
         * Get the density of the fixture.
         */
        public native function getDensity():Number;
        
        /**
         * Set the friction of the fixture.
         */
        public native function setFriction(f:Number):void;
        
        /**
         * Get the friction of the fixture.
         */
        public native function getFriction():Number;
        
        /**
         * Set the restitution of the fixture.
         */
        public native function setRestitution(r:Number):void;
        
        /**
         * Get the restitution of the fixture.
         */
        public native function getRestitution():Number;
        
        /**
         * Dump this fixture to the log file.
         * @param bodyIndex
         */
        public native function dump(bodyIndex:int=0):void;
        
        /**
         * Custom user data set on the fixture.
         */
        public var userData:Object;

        /**
         * Get the user data for the fixture.
         */
        public function getUserData():Object { return userData; };
        
        /**
         * Set the user data for the fixture.
         */
        public function setUserData(data:Object):void { userData = data; };
    }

    /**
     * Bodies are the elemental parts of the physics simulation.
     * A body only defines intangible properties, such as position and velocity.
     * Create fixtures on the body to define its size and shape.
     */
    [Native(managed)]
    final public native class Body
    {
        /**
         * Create a fixture and attach it to the body with the specified fixture definition.
         * If the density is non-zero, this function automatically updates the mass of the body.
         * Contacts are not created until the next time step.
         * @param def The fixture definition to create the fixture from.
         * @return The created fixture.
         */
        public native function createFixture(def:FixtureDef):Fixture;
        
        /**
         * Destroy a fixture. This removes the fixture from the broad-phase and
         * destroys all contacts associated with this fixture. This will
         * automatically adjust the mass of the body if the body is dynamic and the 
         * fixture has positive density.
         * All fixtures attached to a body are implicitly destroyed when the body is destroyed.
         * @param fixture The fixture to be removed.
         */
        public native function destroyFixture(fixture:Fixture):void;
        
        /**
         * Set the position of the body's origin and rotation.
         * This breaks any contacts and wakes the other bodies.
         * Manipulating a body's transform may cause non-physical behavior.
         * @param position The world position of the body's local origin.
         * @param angle The world rotation in radians.
         */
        public native function setTransform(position:Vec2, angle:Number):void;
        //public native function getTransform():Transform;
        
        /**
         * Get the world body origin position.
         * @return The world position of the body's origin.
         */
        public native function getPosition():Vec2;
        
        /**
         * Get the angle in radians.
         * @return The world rotation angle in radians.
         */
        public native function getAngle():Number;
        
        /**
         * Get the world position of the center of mass.
         */
        public native function getWorldCenter():Vec2;
        
        /**
         * Get the local position of the center of mass.
         */
        public native function getLocalCenter():Vec2;
        
        /**
         * Set the linear velocity of the center of mass.
         */
        public native function setLinearVelocity(velocity:Vec2):void;
        
        /**
         * Get the linear velocity of the center of mass.
         */
        public native function getLinearVelocity():Vec2;
        
        /**
         * Set the angular velocity in radians per second.
         */
        public native function setAngularVelocity(omega:Number):void;
        
        /**
         * Get the angular velocity in radians per second.
         */
        public native function getAngularVelocity():Number;

        public native function getContactList():ContactEdge;
        
        /**
         * Apply a force at a world point. If the force is not
         * applied at the center of mass, it will generate a torque and
         * affect the angular velocity. This wakes up the body.
         * @param force The world force vector, usually in Newtons (N).
         * @param point The world position of the point of application.
         * @param wake Wake up the body.
         */
        public native function applyForce(force:Vec2, point:Vec2, wake:Boolean):void;
        
        /**
         * Apply a force to the center of mass. This wakes up the body.
         * @param force the world force vector, usually in Newtons (N).
         * @param wake Wake up the body.
         */
        public native function applyForceToCenter(force:Vec2, wake:Boolean):void;
        
        /**
         * Apply a torque. This affects the angular velocity
         * without affecting the linear velocity of the center of mass.
         * This wakes up the body.
         * @param torque The torque amount to apply about the z-axis (out of the screen), usually in N-m.
         * @param wake Wake up the body.
         */
        public native function applyTorque(torque:Number, wake:Boolean):void;
        
        /**
         * Apply an impulse at a point. This immediately modifies the velocity.
         * It also modifies the angular velocity if the point of application
         * is not at the center of mass. This wakes up the body.
         * @param impulse The world impulse vector, usually in N-seconds or kg-m/s.
         * @param point The world position of the point of application.
         * @param wake Wake up the body.
         */
        public native function applyLinearImpulse(impulse:Vec2, point:Vec2, wake:Boolean):void;
        
        /**
         * Apply an angular impulse.
         * @param impulse The angular impulse in units of kg*m*m/s.
         * @param wake Wake up the body.
         */
        public native function applyAngularImpulse(impulse:Number, wake:Boolean):void;
        
        /**
         * Get the total mass of the body.
         * @return The mass, usually in kilograms (kg).
         */
        public native function getMass():Number;
        
        /**
         * Get the rotational inertia of the body about the local origin.
         * @return The rotational inertia, usually in kg-m^2.
         */
        public native function getInertia():Number;
        
        //public native function getMassData(data:MassData):void;
        //public native function setMassData(data:MassData):void;
        
        public native function resetMassData():void;
        
        /**
         * Get the world coordinates of a point given the local coordinates.
         * @param localPoint A point on the body measured relative the the body's origin.
         * @return The same point expressed in world coordinates.
         */
        public native function getWorldPoint(localPoint:Vec2):Vec2;
        
        /**
         * Get the world coordinates of a vector given the local coordinates.
         * @param localVector A vector fixed in the body.
         * @return The same vector expressed in world coordinates.
         */
        public native function getWorldVector(localVector:Vec2):Vec2;
        
        /**
         * Gets a local point relative to the body's origin given a world point.
         * @param worldPoint A point in world coordinates.
         * @return The corresponding local point relative to the body's origin.
         */
        public native function getLocalPoint(worldPoint:Vec2):Vec2;
        
        /**
         * Gets a local vector given a world vector.
         * @param worldVector A vector in world coordinates.
         * @return The corresponding local vector.
         */
        public native function getLocalVector(worldVector:Vec2):Vec2;
        
        /**
         * Get the world linear velocity of a world point attached to this body.
         * @param worldPoint A point in world coordinates.
         * @return The world velocity of a point.
         */
        public native function getLinearVelocityFromWorldPoint(worldPoint:Vec2):Vec2;
        
        /**
         * Get the world velocity of a local point.
         * @param localPoint A point in local coordinates.
         * @return The world velocity of a point.
         */
        public native function getLinearVelocityFromLocalPoint(localPoint:Vec2):Vec2;
        
        /**
         * Get the linear damping of the body.
         * @see loom.box2d.BodyDef 
         */
        public native function getLinearDamping():Number;
        
        /**
         * Set the linear damping of the body.
         * @see loom.box2d.BodyDef
         */
        public native function setLinearDamping(linearDamping:Number):void;
        
        /**
         * Get the angular damping of the body.
         * @see loom.box2d.BodyDef
         */
        public native function getAngularDamping():Number;
        
        /**
         * Set the angular damping of the body.
         * @see loom.box2d.BodyDef
         */
        public native function setAngularDamping(angularDamping:Number):void;
        
        /**
         * Get the gravity scale of the body.
         */
        public native function getGravityScale():Number;
        
        /**
         * Set the gravity scale of the body.
         */
        public native function setGravityScale(scale:Number):void;
        
        //public native function setType(type:int):void;
        //public native function getType():int;
        
        /**
         * true if this body should be treated like a bullet for continuous collision detection.
         */
        public native function setBullet(flag:Boolean):void;
        
        /**
         * Returns true if this body is treated like a bullet for continuous collision detection.
         */
        public native function isBullet():Boolean;
        
        /**
         * Set the sleeping state of the body. If you disable sleeping, the body will be woken.
         */
        public native function setSleepingAllowed(flag:Boolean):void;
        
        /**
         * Get the sleeping state of the body.
         */
        public native function isSleepingAllowed():Boolean;
        
        /**
         * Set the sleep state of the body. A sleeping body has very low CPU cost.
         * @param flag Set to true to wake the body, false to put it to sleep.
         */
        public native function setAwake(flag:Boolean):void;
        
        /**
         * Get the sleeping state of the body.
         * @return true if the body is sleeping.
         */
        public native function isAwake():Boolean;
        
        /**
         * Set the active state of the body. An inactive body is not
         * simulated and cannot be collided with or woken up.
         * If you pass a flag of true, all fixtures will be added to the
         * broad-phase.
         * If you pass a flag of false, all fixtures will be removed from
         * the broad-phase and all contacts will be destroyed.
         * Fixtures and joints are otherwise unaffected. You may continue
         * to create/destroy fixtures and joints on inactive bodies.
         * Fixtures on an inactive body are implicitly inactive and will
         * not participate in collisions, ray-casts, or queries.
         * Joints connected to an inactive body are implicitly inactive.
         * An inactive body is still owned by a World object and remains
         * in the body list.
         * @param flag true to activate and false to deactivate the body.
         */
        public native function setActive(flag:Boolean):void;
        
        /**
         * Get the active state of the body.
         * @return
         */
        public native function isActive():Boolean;
        
        /**
         * Set the body to have fixed rotation. This causes the mass to be reset.
         */
        public native function setFixedRotation(flag:Boolean):void;
        
        /**
         * Returns true if the body has fixed rotation.
         */
        public native function isFixedRotation():Boolean;
        
        /**
         * Get the next body in the world's body list.
         * @return The next body in the list.
         */
        public native function getNext():Body;
        
        /**
         * Get the parent world of the body.
         */
        public native function getWorld():World;
        
        /**
         * Dump this body to the log file.
         */
        public native function dump():void;
        
        /**
         * Custom user data set on the body.
         */
        public var userData:Object;

        /**
         * Get the user data for the body.
         */
        public function getUserData():Object { return userData; };
        
        /**
         * Set the user data for the body.
         */
        public function setUserData(data:Object):void { userData = data; };
    }
    
    /**
     * World is the main physics class that contains bodies and handles their simulation.
     */
    [Native(managed)]
    final public native class World
    {
        /**
         * Construct a world object.
         * @param gravity The world gravity vector.
         */
        public native function World(gravity:Vec2);
        
        /**
         * Create a rigid body given a definition. No reference to the definition
         * is retained.
         * @param def The definition to create the body from.
         */
        public native function createBody(def:BodyDef):Body;
        
        /**
         * Destroy a rigid body given a definition. No reference to the definition
         * is retained. This function is locked during callbacks.
         * @warning This automatically deletes all associated shapes and joints.
         */
        public native function destroyBody(body:Body):void;
        
        /**
         * Get the number of bodies in the world.
         * @return
         */
        public native function getBodyCount():Number;
        
        /**
         * Get the world body list. With the returned body, use body.getNext to get
         * the next body in the world list. A null body indicates the end of the list.
         * @return The head of the world body list.
         */
        public native function getBodyList():Body;
        
        //public native function createJoint(def:JointDef):Joint;
        //public native function destroyJoint(joint:Joint):void;
        public native function getJointCount():Number;
        
        /**
         * Take a time step. This performs collision detection, integration,
         * and constraint solution.
         * @param timeStep The amount of time to simulate, this should not vary.
         * @param velocityIterations The number of iterations to perform in the velocity constraint solver.
         * @param positionIterations The number of iterations to perform in the position constraint solver.
         */
        public native function step(timeStep:Number, velocityIterations:int, positionIterations:int):void;
        
        /**
         * Returns true if the world is locked (in the middle of a time step).
         */
        public native function isLocked():Boolean;
        
        /**
         * Set if the bodies in the world are allowed to sleep.
         */
        public native function setAllowSleeping(value:Boolean):void;
        
        /**
         * Returns true if sleeping is enabled.
         */
        public native function getAllowSleeping():Boolean;
        
        /**
         * Change the world gravity vector.
         */
        public native function setGravity(gravity:Vec2):void;
        
        /**
         * Get the world gravity vector.
         */
        public native function getGravity():Vec2;
        
        /**
         * Manually clear the force buffer on all bodies. By default, forces are cleared automatically
         * after each call to step. The default behavior is modified by calling setAutoClearForces.
         * The purpose of this function is to support sub-stepping. Sub-stepping is often used to maintain
         * a fixed sized time step under a variable frame-rate.
         * When you perform sub-stepping you will disable auto clearing of forces and instead call
         * clearForces after all sub-steps are complete in one pass of your game loop.
         * @see setAutoClearForces
         */
        public native function clearForces():void;
        
        /**
         * Set flag to control automatic clearing of forces after each time step.
         */
        public native function setAutoClearForces(clear:Boolean):void;
        
        /**
         * Get the flag that controls automatic clearing of forces after each time step.
         */
        public native function getAutoClearForces():Boolean;
        
        /**
         * Shift the world origin. Useful for large worlds.
         * The body shift formula is: position -= newOrigin
         * @param newOrigin The new origin with respect to the old origin.
         */
        public native function shiftOrigin(newOrigin:Vec2):void;
        
        /**
         * Dump the world into the log file.
         * @warning This should be called outside of a time step.
         */
        public native function dump():void;
    }
    
    [Native(managed)]
    final public native class ShapeCache
    {
        public static native function sharedShapeCache():ShapeCache;
        
        public native function reset():void;

        /**
         * Add fixture data to the specified body.
         * @param body The body to add the fixtures to.
         * @param shapeName Name of the shape.
         */
        public native function addFixturesToBody(body:Body, shapeName:String):void;
        
        /**
         * Adds shapes to the shape cache from a plist file.
         * @param plistPath The path of the plist file to load.
         * @param vertexScale The scale vector used for the shapes. Useful to flip the Y axis.
         * @param ptm The pixels-to-meters ratio used for the shapes.
         */
        public native function addShapesWithFile(plistPath:String, vertexScale:Vec2, ptm:Number = 0):void;
        
        /**
         * Returns the anchor point of the given shape.
         * @param shapeName The name of the shape to get the anchor point for.
         * @return The anchor point.
         */
        public native function anchorPointForShape(shapeName:String):Vec2;
    }

    [Native(managed)]
    final public native class ContactEdge
    {
        public native var other:ContactEdge;
        public native var contact:ContactEdge;
        public native var prev:ContactEdge;
        public native var next:ContactEdge;
    }

}
