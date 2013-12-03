/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#include "loom/common/core/log.h"
#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/vendor/box2d/Box2D.h"

using namespace LS;

lmDefineLogGroup(gBox2DLogGroup, "Loom.Box2D", 1, 0);

static int registerLoomBox2D(lua_State *L)
{
    beginPackage(L, "loom.box2d")

        .beginClass<b2Vec2>("b2Vec2")

            .addConstructor<void (*)(float32, float32)>()

            .addVar("x", &b2Vec2::x)
            .addVar("y", &b2Vec2::y)

            .addMethod("setZero", &b2Vec2::SetZero)
            .addMethod("set", &b2Vec2::Set)
            .addMethod("length", &b2Vec2::Length)
            .addMethod("lengthSquared", &b2Vec2::LengthSquared)
            .addMethod("normalize", &b2Vec2::Normalize)
            .addMethod("isValid", &b2Vec2::IsValid)
            .addMethod("skew", &b2Vec2::Skew)

        .endClass()

        .beginClass<b2MassData>("b2MassData")

            .addVar("mass", &b2MassData::mass)
            .addVar("center", &b2MassData::center)
            .addVar("i", &b2MassData::I)

        .endClass()

        .beginClass<b2BodyDef>("b2BodyDef")

            .addVar("type", (int b2BodyDef::*)&b2BodyDef::type)
            //.addVar("userData", &b2BodyDef::userData)
            .addVar("position", &b2BodyDef::position)
            .addVar("angle", &b2BodyDef::angle)
            .addVar("linearVelocity", &b2BodyDef::linearVelocity)
            .addVar("angularVelocity", &b2BodyDef::angularVelocity)
            .addVar("linearDamping", &b2BodyDef::linearDamping)
            .addVar("angularDamping", &b2BodyDef::angularDamping)
            .addVar("allowSleep", &b2BodyDef::allowSleep)
            .addVar("awake", &b2BodyDef::awake)
            .addVar("fixedRotation", &b2BodyDef::fixedRotation)
            .addVar("bullet", &b2BodyDef::bullet)
            .addVar("active", &b2BodyDef::active)
            .addVar("gravityScale", &b2BodyDef::gravityScale)

        .endClass()

        .beginClass<b2JointDef>("b2JointDef")

            .addVar("type", (int b2JointDef::*)&b2JointDef::type)
            //.addVar("userData", &b2JointDef::userData)
            .addVar("bodyA", &b2JointDef::bodyA)
            .addVar("bodyB", &b2JointDef::bodyB)
            .addVar("collideConnected", &b2JointDef::collideConnected)

        .endClass()

        .beginClass<b2JointEdge>("b2JointEdge")

            .addVar("other", &b2JointEdge::other)
            .addVar("joint", &b2JointEdge::joint)
            .addVar("prev", &b2JointEdge::prev)
            .addVar("next", &b2JointEdge::next)

        .endClass()

        .beginClass<b2FixtureDef>("b2FixtureDef")

            .addVar("shape", &b2FixtureDef::shape)
            //.addVar("userData", &b2FixtureDef::userData)
            .addVar("friction", &b2FixtureDef::friction)
            .addVar("restitution", &b2FixtureDef::restitution)
            .addVar("density", &b2FixtureDef::density)
            .addVar("isSensor", &b2FixtureDef::isSensor)
            .addVar("filter", &b2FixtureDef::filter)

        .endClass()

        .beginClass<b2Shape>("b2Shape")

            .addMethod("clone", &b2Shape::Clone)
            .addMethod("getType", &b2Shape::GetType)
            .addMethod("getChildCount", &b2Shape::GetChildCount)
            .addMethod("testPoint", &b2Shape::TestPoint)
            .addMethod("rayCast", &b2Shape::RayCast)
            .addMethod("computeAABB", &b2Shape::ComputeAABB)
            .addMethod("computeMass", &b2Shape::ComputeMass)

        .endClass()

        .beginClass<b2Fixture>("b2Fixture")

            .addMethod("getType", &b2Fixture::GetType)
            .addMethod("getShape", (b2Shape* (b2Fixture::*)())&b2Fixture::GetShape)
            .addMethod("setSensor", &b2Fixture::SetSensor)
            .addMethod("isSensor", &b2Fixture::IsSensor)
            .addMethod("setFilterData", &b2Fixture::SetFilterData)
            .addMethod("getFilterData", &b2Fixture::GetFilterData)
            .addMethod("refilter", &b2Fixture::Refilter)
            .addMethod("getBody", (b2Body* (b2Fixture::*)())&b2Fixture::GetBody)
            .addMethod("getNext", (b2Fixture* (b2Fixture::*)())&b2Fixture::GetNext)
            //.addMethod("getUserData", &b2Fixture::GetUserData)
            //.addMethod("setUserData", &b2Fixture::SetUserData)
            .addMethod("testPoint", &b2Fixture::TestPoint)
            .addMethod("rayCast", &b2Fixture::RayCast)
            .addMethod("getMassData", &b2Fixture::GetMassData)
            .addMethod("setDensity", &b2Fixture::SetDensity)
            .addMethod("getFriction", &b2Fixture::GetFriction)
            .addMethod("setFriction", &b2Fixture::SetFriction)
            .addMethod("getRestitution", &b2Fixture::GetRestitution)
            .addMethod("setRestitution", &b2Fixture::SetRestitution)
            .addMethod("getAABB", &b2Fixture::GetAABB)
            .addMethod("dump", &b2Fixture::Dump)

        .endClass()

        /*
        .beginClass<b2ContactID>("b2ContactID")

            .addVar("key", &b2ContactID::key)

        .endClass()        

        .beginClass<b2ManifoldPoint>("b2ManifoldPoint")

            .addVar("localPoint", &b2Manifold::localPoint)
            .addVar("normalImpulse", &b2Manifold::normalImpulse)
            .addVar("tangentImpulse", &b2Manifold::tangentImpulse)
            .addVar("id", &b2Manifold::id)

        .endClass()

        .beginClass<b2Manifold>("b2Manifold")

            .addVar("type", (int b2Manifold::*)&b2Manifold::type)
            //.addVar("points", &b2Manifold::points)
            .addVar("localNormal", &b2Manifold::localNormal)
            .addVar("localPoint", &b2Manifold::localPoint)
            .addVar("pointCount", &b2Manifold::pointCount)

        .endClass()
        */

        .beginClass<b2Contact>("b2Contact")

            //.addMethod("getManifold", (b2Manifold* (b2Contact::*)())&b2Contact::GetManifold)
            //.addMethod("getWorldManifold", (b2Manifold* (b2Contact::*)())&b2Contact::GetWorldManifold)
            .addMethod("isTouching", &b2Contact::IsTouching)
            .addMethod("setEnabled", &b2Contact::SetEnabled)
            .addMethod("isEnabled", &b2Contact::IsEnabled)
            .addMethod("getNext", (b2Contact* (b2Contact::*)())&b2Contact::GetNext)
            .addMethod("getFixtureA", (b2Fixture* (b2Contact::*)())&b2Contact::GetFixtureA)
            .addMethod("getChildIndexA", &b2Contact::GetChildIndexA)
            .addMethod("getFixtureB", (b2Fixture* (b2Contact::*)())&b2Contact::GetFixtureB)
            .addMethod("getChildIndexB", &b2Contact::GetChildIndexB)
            .addMethod("setFriction", &b2Contact::SetFriction)
            .addMethod("getFriction", &b2Contact::GetFriction)
            .addMethod("resetFriction", &b2Contact::ResetFriction)
            .addMethod("setRestitution", &b2Contact::SetRestitution)
            .addMethod("getRestitution", &b2Contact::GetRestitution)
            .addMethod("resetRestitution", &b2Contact::ResetRestitution)
            .addMethod("setTangentSpeed", &b2Contact::SetTangentSpeed)
            .addMethod("getTangentSpeed", &b2Contact::GetTangentSpeed)
            .addMethod("evaluate", &b2Contact::Evaluate)

        .endClass()

        .beginClass<b2ContactEdge>("b2ContactEdge")

            .addVar("other", &b2ContactEdge::other)
            .addVar("contact", &b2ContactEdge::contact)
            .addVar("prev", &b2ContactEdge::prev)
            .addVar("next", &b2ContactEdge::next)

        .endClass() 

        .beginClass<b2Body>("b2Body")

            .addMethod("createFixture", (b2Fixture* (b2Body::*)(const b2FixtureDef*))&b2Body::CreateFixture)
            .addMethod("destroyFixture", (void (b2Body::*)(b2Fixture*))&b2Body::DestroyFixture)
            .addMethod("setTransform", &b2Body::SetTransform)
            .addMethod("getTransform", &b2Body::GetTransform)
            .addMethod("getPosition", &b2Body::GetPosition)
            .addMethod("getAngle", &b2Body::GetAngle)
            .addMethod("getWorldCenter", &b2Body::GetWorldCenter)
            .addMethod("getLocalCenter", &b2Body::GetLocalCenter)
            .addMethod("setLinearVelocity", &b2Body::SetLinearVelocity)
            .addMethod("getLinearVelocity", &b2Body::GetLinearVelocity)
            .addMethod("setAngularVelocity", &b2Body::SetAngularVelocity)
            .addMethod("getAngularVelocity", &b2Body::GetAngularVelocity)
            .addMethod("applyForce", &b2Body::ApplyForce)
            .addMethod("applyForceToCenter", &b2Body::ApplyForceToCenter)
            .addMethod("applyTorque", &b2Body::ApplyTorque)
            .addMethod("applyLinearImpulse", &b2Body::ApplyLinearImpulse)
            .addMethod("applyAngularImpulse", &b2Body::ApplyAngularImpulse)
            .addMethod("getMass", &b2Body::GetMass)
            .addMethod("getInertia", &b2Body::GetInertia)
            .addMethod("getMassData", &b2Body::GetMassData)
            .addMethod("setMassData", &b2Body::SetMassData)
            .addMethod("resetMassData", &b2Body::ResetMassData)
            .addMethod("getWorldPoint", &b2Body::GetWorldPoint)
            .addMethod("getWorldVector", &b2Body::GetWorldVector)
            .addMethod("getLocalPoint", &b2Body::GetLocalPoint)
            .addMethod("getLocalVector", &b2Body::GetLocalVector)
            .addMethod("getLinearVelocityFromWorldPoint", &b2Body::GetLinearVelocityFromWorldPoint)
            .addMethod("getLinearVelocityFromLocalPoint", &b2Body::GetLinearVelocityFromLocalPoint)
            .addMethod("getLinearDamping", &b2Body::GetLinearDamping)
            .addMethod("setLinearDamping", &b2Body::SetLinearDamping)
            .addMethod("getAngularDamping", &b2Body::GetAngularDamping)
            .addMethod("setAngularDamping", &b2Body::SetAngularDamping)
            .addMethod("getGravityScale", &b2Body::GetGravityScale)
            .addMethod("setGravityScale", &b2Body::SetGravityScale)
            .addMethod("setType", &b2Body::SetType)
            .addMethod("getType", &b2Body::GetType)
            .addMethod("setBullet", &b2Body::SetBullet)
            .addMethod("isBullet", &b2Body::IsBullet)
            .addMethod("setSleepingAllowed", &b2Body::SetSleepingAllowed)
            .addMethod("isSleepingAllowed", &b2Body::IsSleepingAllowed)
            .addMethod("setAwake", &b2Body::SetAwake)
            .addMethod("isAwake", &b2Body::IsAwake)
            .addMethod("setActive", &b2Body::SetActive)
            .addMethod("isActive", &b2Body::IsActive)
            .addMethod("setFixedRotation", &b2Body::SetFixedRotation)
            .addMethod("isFixedRotation", &b2Body::IsFixedRotation)
            //.addMethod("getFixtureList", &b2Body::GetFixtureList)
            //.addMethod("getJointList", &b2Body::GetJointList)
            //.addMethod("getContactList", &b2Body::GetContactList)
            .addMethod("getNext", (b2Body* (b2Body::*)())&b2Body::GetNext)
            //.addMethod("getUserData", &b2Body::GetUserData)
            //.addMethod("setUserData", &b2Body::SetUserData)
            .addMethod("getWorld", (b2World* (b2Body::*)())&b2Body::GetWorld)
            .addMethod("dump", &b2Body::Dump)

        .endClass()

        .beginClass<b2Joint>("b2Joint")

            .addMethod("getType", &b2Joint::GetType)
            .addMethod("getBodyA", &b2Joint::GetBodyA)
            .addMethod("getBodyB", &b2Joint::GetBodyB)
            .addMethod("getAnchorA", &b2Joint::GetAnchorA)
            .addMethod("getAnchorB", &b2Joint::GetAnchorB)
            .addMethod("getReactionForce", &b2Joint::GetReactionForce)
            .addMethod("getReactionTorque", &b2Joint::GetReactionTorque)
            .addMethod("getNext", (b2Joint* (b2Joint::*)())&b2Joint::GetNext)
            //.addMethod("getUserData", &b2Joint::GetUserData)
            //.addMethod("setUserData", &b2Joint::SetUserData)
            .addMethod("isActive", &b2Joint::IsActive)
            .addMethod("getCollideConnected", &b2Joint::GetCollideConnected)
            .addMethod("dump", &b2Joint::Dump)
            .addMethod("shiftOrigin", &b2Joint::ShiftOrigin)

        .endClass()

        .beginClass<b2World>("b2World")

            .addConstructor<void (*)(b2Vec2&)>()

            .addMethod("createBody", &b2World::CreateBody)
            .addMethod("destroyBody", &b2World::DestroyBody)
            .addMethod("getBodyCount", &b2World::GetBodyCount)
            //.addMethod("getBodyList", &b2World::GetBodyList)

            .addMethod("createJoint", &b2World::CreateJoint)
            .addMethod("destroyJoint", &b2World::DestroyJoint)
            .addMethod("getJointCount", &b2World::GetJointCount)
            //.addMethod("getJointList", &b2World::GetJointList)

            .addMethod("step", &b2World::Step)
            .addMethod("isLocked", &b2World::IsLocked)

            .addMethod("setAllowSleeping", &b2World::SetAllowSleeping)
            .addMethod("getAllowSleeping", &b2World::GetAllowSleeping)
            .addMethod("setGravity", &b2World::SetGravity)
            .addMethod("getGravity", &b2World::GetGravity)

            .addMethod("clearForces", &b2World::ClearForces)
            .addMethod("setAutoClearForces", &b2World::SetAutoClearForces)
            .addMethod("getAutoClearForces", &b2World::GetAutoClearForces)

            .addMethod("shiftOrigin", &b2World::ShiftOrigin)

            .addMethod("dump", &b2World::Dump)

        .endClass()
    
    .endPackage();

    return 0;
}


void installLoomBox2D()
{
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2Vec2, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2MassData, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2BodyDef, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2JointDef, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2JointEdge, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2FixtureDef, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2Shape, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2Fixture, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2Contact, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2ContactEdge, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2Body, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2Joint, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2World, registerLoomBox2D);
}
