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

//  Based on
//  https://github.com/AndreasLoew/PhysicsEditor-Cocos2d-x-Box2d/blob/master
//  /Demo/generic-box2d-plist/GB2ShapeCache-x.cpp

//  GB2ShapeCache-x.cpp
//  
//  Loads physics sprites created with http://www.PhysicsEditor.de
//  To be used with cocos2d-x
//
//  Generic Shape Cache for box2d
//
//  Created by Thomas Broquist
//
//      http://www.PhysicsEditor.de
//      http://texturepacker.com
//      http://www.code-and-web.de
//  
//  All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#include "loom/common/core/log.h"
#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/vendor/box2d/Box2D.h"
#include "cocoa/CCNS.h"
#include "cocoa/CCObject.h"
#include "cocoa/CCArray.h"
#include "cocoa/CCDictionary.h"
#include "platform/CCFileUtils.h"
#include <map>

using namespace LS;
using namespace cocos2d;

lmDefineLogGroup(gBox2DLogGroup, "Loom.Box2D", 1, 0);

class BodyDef;
class b2Body;

class b2ShapeCache {
public:
    // Static interface
    static b2ShapeCache* sharedB2ShapeCache(void);
        
    bool init();                        
    void addShapesWithFile(const std::string &plist, b2Vec2 vertexScale, float ptm=0);
    void addFixturesToBody(b2Body *body, const std::string &shape);
    b2Vec2& anchorPointForShape(const std::string &shape);
    void reset();
    float getPtmRatio() { return ptmRatio; }
    ~b2ShapeCache() {}
        
private:
    std::map<std::string, BodyDef *> shapeObjects;
    b2ShapeCache(void) {}
    float ptmRatio;
};

/**
 * Internal class to hold the fixtures
 */
class FixtureDef {
public:
    FixtureDef()
    : next(NULL) {}
    
    ~FixtureDef() {
        delete next;
        delete fixture.shape;
    }
    
    FixtureDef *next;
    b2FixtureDef fixture;
    int callbackData;
};

class BodyDef {
public:
    BodyDef()
    : fixtures(NULL) {}
    
    ~BodyDef() {
        if (fixtures)
            delete fixtures;
    }
    
    FixtureDef *fixtures;
    b2Vec2 anchorPoint;
};

static b2ShapeCache *_sharedB2ShapeCache = NULL;

b2ShapeCache* b2ShapeCache::sharedB2ShapeCache(void) {
    if (!_sharedB2ShapeCache) {
        _sharedB2ShapeCache = new b2ShapeCache();
        _sharedB2ShapeCache->init();
    }
    
    return _sharedB2ShapeCache;
}

bool b2ShapeCache::init() {
    return true;
}

void b2ShapeCache::reset() {
    std::map<std::string, BodyDef *>::iterator iter;
    for (iter = shapeObjects.begin() ; iter != shapeObjects.end() ; ++iter) {
        delete iter->second;
    }
    shapeObjects.clear();
}

void b2ShapeCache::addFixturesToBody(b2Body *body, const std::string &shape) {
    std::map<std::string, BodyDef *>::iterator pos = shapeObjects.find(shape);
    assert(pos != shapeObjects.end());
    
    BodyDef *so = (*pos).second;

    FixtureDef *fix = so->fixtures;
    while (fix) {
        body->CreateFixture(&fix->fixture);
        fix = fix->next;
    }
}

b2Vec2& b2ShapeCache::anchorPointForShape(const std::string &shape) {
    std::map<std::string, BodyDef *>::iterator pos = shapeObjects.find(shape);
    assert(pos != shapeObjects.end());
    
    BodyDef *bd = (*pos).second;
    return bd->anchorPoint;
}


void b2ShapeCache::addShapesWithFile(const std::string &plist, b2Vec2 vertexScale, float ptm) {
    
    CCDictionary *dict = CCDictionary::createWithContentsOfFile(plist.c_str());
    CCAssert(dict != NULL, "Shape-file not found");
    CCAssert(dict->count() != 0, "plist file empty or not existing");
    
    CCDictionary *metadataDict = (CCDictionary *)dict->objectForKey("metadata");
    int format = metadataDict->valueForKey("format")->intValue();
    ptmRatio = metadataDict->valueForKey("ptm_ratio")->floatValue();
    if (ptm <= 0)
        ptm = ptmRatio;
    CCLOG("ptmRatio = %f",ptmRatio);
    CCAssert(format == 1, "Format not supported");
    
    CCDictionary *bodyDict = (CCDictionary *)dict->objectForKey("bodies");

    b2Vec2 vertices[b2_maxPolygonVertices];
    
    CCDictElement *dictElem;
    std::string bodyName;
    CCDictionary *bodyData;
    //iterate body list
    CCDICT_FOREACH(bodyDict,dictElem )
    {
        bodyData = (CCDictionary*)dictElem->getObject();
        bodyName = dictElem->getStrKey();
        
        
        BodyDef *bodyDef = new BodyDef();
        CCPoint a = CCPointFromString(bodyData->valueForKey("anchorpoint")->getCString());
        float32 ax = (vertexScale.x >= 0) ? (float32)a.x : (float32)(1-a.x);
        float32 ay = (vertexScale.y >= 0) ? (float32)a.y : (float32)(1-a.y);
        bodyDef->anchorPoint = b2Vec2(ax, ay);
        CCArray *fixtureList = (CCArray*)(bodyData->objectForKey("fixtures"));
        FixtureDef **nextFixtureDef = &(bodyDef->fixtures);
        
        //iterate fixture list
        CCObject *arrayElem;
        CCARRAY_FOREACH(fixtureList, arrayElem)
        {
            b2FixtureDef basicData;
            CCDictionary* fixtureData = (CCDictionary*)arrayElem;
            
            basicData.filter.categoryBits = fixtureData->valueForKey("filter_categoryBits")->intValue();
            basicData.filter.maskBits = fixtureData->valueForKey("filter_maskBits")->intValue();
            basicData.filter.groupIndex = fixtureData->valueForKey("filter_groupIndex")->intValue();
            basicData.friction = fixtureData->valueForKey("friction")->floatValue();
            basicData.density = fixtureData->valueForKey("density")->floatValue();
            basicData.restitution = fixtureData->valueForKey("restitution")->floatValue();
            basicData.isSensor = fixtureData->valueForKey("isSensor")->intValue() != 0;
           
            int callbackData = fixtureData->valueForKey("userdataCbValue")->intValue();
            
            const char* fixtureType = fixtureData->valueForKey("fixture_type")->getCString();

            if (strcmp(fixtureType, "POLYGON")==0) {
                CCArray *polygonsArray = (CCArray *)(fixtureData->objectForKey("polygons"));
                
                CCObject *dicArrayElem;
                CCARRAY_FOREACH(polygonsArray, dicArrayElem)
                {
                    FixtureDef *fix = new FixtureDef();
                    fix->fixture = basicData; // copy basic data
                    fix->callbackData = callbackData;
                    
                    b2PolygonShape *polyshape = new b2PolygonShape();
                    int vindex = 0;
                    
                    CCArray *polygonArray = (CCArray*)dicArrayElem;
                    
                    assert(polygonArray->count() <= b2_maxPolygonVertices);
                    
                    CCObject *piter;
                    CCARRAY_FOREACH(polygonArray, piter)
                    {
                        CCString *verStr = (CCString*)piter;
                        CCPoint offset = CCPointFromString(verStr->getCString());
                        vertices[vindex] = b2Vec2((float32)(offset.x / ptmRatio) * vertexScale.x, (float32)(offset.y / ptmRatio) * vertexScale.y);
                        vindex++;
                    }
                    
                    polyshape->Set(vertices, vindex);
                    fix->fixture.shape = polyshape;
                    
                    // create a list
                    *nextFixtureDef = fix;
                    nextFixtureDef = &(fix->next);
                }

            }
            else if (strcmp(fixtureType, "CIRCLE")==0) {
                FixtureDef *fix = new FixtureDef();
                fix->fixture = basicData; // copy basic data
                fix->callbackData = callbackData;

                CCDictionary *circleData = (CCDictionary *)fixtureData->objectForKey("circle");

                b2CircleShape *circleShape = new b2CircleShape();
                
                circleShape->m_radius = (circleData->valueForKey("radius")->floatValue() / ptmRatio);
                CCPoint p = CCPointFromString(circleData->valueForKey("position")->getCString());
                circleShape->m_p = b2Vec2((float32)(p.x / ptmRatio), (float32)(p.y / ptmRatio));
                fix->fixture.shape = circleShape;
                
                // create a list
                *nextFixtureDef = fix;
                nextFixtureDef = &(fix->next);

            }
            else {
                CCAssert(0, "Unknown fixtureType");
            }
        }
        // add the body element to the hash
        shapeObjects[bodyName] = bodyDef;

    }

}

static int registerLoomBox2D(lua_State *L)
{
    beginPackage(L, "loom.box2d")

        .beginClass<b2Vec2>("Vec2")

            .addConstructor<void (*)(float32, float32)>()

            .addVar("x", &b2Vec2::x)
            .addVar("y", &b2Vec2::y)

            .addMethod("setZero", &b2Vec2::SetZero)
            .addMethod("setValue", &b2Vec2::Set)
            .addMethod("length", &b2Vec2::Length)
            .addMethod("lengthSquared", &b2Vec2::LengthSquared)
            .addMethod("normalize", &b2Vec2::Normalize)
            .addMethod("isValid", &b2Vec2::IsValid)
            .addMethod("skew", &b2Vec2::Skew)

        .endClass()

        .beginClass<b2MassData>("MassData")

            .addVar("mass", &b2MassData::mass)
            .addVar("center", &b2MassData::center)
            .addVar("i", &b2MassData::I)

        .endClass()

        .beginClass<b2BodyDef>("BodyDef")

            .addConstructor <void (*)(void) >()

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

        .beginClass<b2JointDef>("JointDef")

            .addConstructor <void (*)(void) >()

            .addVar("type", (int b2JointDef::*)&b2JointDef::type)
            //.addVar("userData", &b2JointDef::userData)
            .addVar("bodyA", &b2JointDef::bodyA)
            .addVar("bodyB", &b2JointDef::bodyB)
            .addVar("collideConnected", &b2JointDef::collideConnected)

        .endClass()

        .beginClass<b2JointEdge>("JointEdge")

            .addConstructor <void (*)(void) >()

            .addVar("other", &b2JointEdge::other)
            .addVar("joint", &b2JointEdge::joint)
            .addVar("prev", &b2JointEdge::prev)
            .addVar("next", &b2JointEdge::next)

        .endClass()

        .beginClass<b2FixtureDef>("FixtureDef")

            .addConstructor <void (*)(void) >()

            .addVar("shape", &b2FixtureDef::shape)
            //.addVar("userData", &b2FixtureDef::userData)
            .addVar("friction", &b2FixtureDef::friction)
            .addVar("restitution", &b2FixtureDef::restitution)
            .addVar("density", &b2FixtureDef::density)
            .addVar("isSensor", &b2FixtureDef::isSensor)
            //.addVar("filter", &b2FixtureDef::filter)

        .endClass()

        .beginClass<b2Shape>("Shape")

            .addVar("radius", &b2Shape::m_radius)

            .addMethod("clone", &b2Shape::Clone)
            .addMethod("getType", &b2Shape::GetType)
            .addMethod("getChildCount", &b2Shape::GetChildCount)
            .addMethod("testPoint", &b2Shape::TestPoint)
            .addMethod("rayCast", &b2Shape::RayCast)
            .addMethod("computeAABB", &b2Shape::ComputeAABB)
            .addMethod("computeMass", &b2Shape::ComputeMass)

        .endClass()

        .deriveClass<b2PolygonShape, b2Shape>("PolygonShape")

            .addConstructor <void (*)(void) >()

            .addMethod("setAsBox", (void (b2PolygonShape::*)(float32, float32))&b2PolygonShape::SetAsBox)

        .endClass()        

        .deriveClass<b2CircleShape, b2Shape>("CircleShape")

            .addConstructor <void (*)(void) >()

        .endClass()        

        .beginClass<b2Fixture>("Fixture")

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
            .addMethod("getDensity", &b2Fixture::GetDensity)
            .addMethod("getFriction", &b2Fixture::GetFriction)
            .addMethod("setFriction", &b2Fixture::SetFriction)
            .addMethod("getRestitution", &b2Fixture::GetRestitution)
            .addMethod("setRestitution", &b2Fixture::SetRestitution)
            .addMethod("getAABB", &b2Fixture::GetAABB)
            .addMethod("dump", &b2Fixture::Dump)

        .endClass()

        /*
        .beginClass<b2ContactID>("ContactID")

            .addVar("key", &b2ContactID::key)

        .endClass()        

        .beginClass<b2ManifoldPoint>("ManifoldPoint")

            .addVar("localPoint", &b2Manifold::localPoint)
            .addVar("normalImpulse", &b2Manifold::normalImpulse)
            .addVar("tangentImpulse", &b2Manifold::tangentImpulse)
            .addVar("id", &b2Manifold::id)

        .endClass()

        .beginClass<b2Manifold>("Manifold")

            .addVar("type", (int b2Manifold::*)&b2Manifold::type)
            //.addVar("points", &b2Manifold::points)
            .addVar("localNormal", &b2Manifold::localNormal)
            .addVar("localPoint", &b2Manifold::localPoint)
            .addVar("pointCount", &b2Manifold::pointCount)

        .endClass()
        */


        .beginClass<b2Body>("Body")

            .addMethod("createFixture", (b2Fixture* (b2Body::*)(const b2FixtureDef*))&b2Body::CreateFixture)
            .addMethod("destroyFixture", (void (b2Body::*)(b2Fixture*))&b2Body::DestroyFixture)
            .addMethod("setTransform", &b2Body::SetTransform)
            //.addMethod("getTransform", &b2Body::GetTransform)
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
            .addMethod("getNext", (b2Body* (b2Body::*)())&b2Body::GetNext)
            .addMethod("getWorld", (b2World* (b2Body::*)())&b2Body::GetWorld)
            .addMethod("dump", &b2Body::Dump)
            // NOTE: Loom can't pass b2dContact or b2dContactEdge classes back to loomscript becuase of how they are handled so
            // we're adding direct accessors into the body class
            .addMethod("bodyToContactIndex", &b2Body::BodyToContactIndex)
            .addMethod("contactIndexToBody", &b2Body::ContactIndexToBody)
            .addMethod("isContacting", &b2Body::IsContacting)
            .addMethod("getNumContacts", &b2Body::GetNumContacts)
            .addMethod("setContactEnabled", &b2Body::SetContactEnabled)
            .addMethod("isContactEnabled", &b2Body::IsContactEnabled)
            .addMethod("getContactFixtureA", (b2Fixture* (b2Body::*)(int contactIndex)) &b2Body::GetContactFixtureA)
            .addMethod("getContactChildIndexA", &b2Body::GetContactChildIndexA)
            .addMethod("getContactFixtureB", (b2Fixture* (b2Body::*)(int contactIndex)) &b2Body::GetContactFixtureB)
            .addMethod("getContactChildIndexB", &b2Body::GetContactChildIndexB)
            .addMethod("setContactFriction", &b2Body::SetContactFriction)
            .addMethod("getContactFriction", &b2Body::GetContactFriction)
            .addMethod("resetContactFriction", &b2Body::ResetContactFriction)
            .addMethod("setContactRestitution", &b2Body::SetContactRestitution)
            .addMethod("getContactRestitution", &b2Body::GetContactRestitution)
            .addMethod("resetContactRestitution", &b2Body::ResetContactRestitution)
            .addMethod("setContactTangentSpeed", &b2Body::SetContactTangentSpeed)
            .addMethod("getContactTangentSpeed", &b2Body::GetContactTangentSpeed)
        .endClass()

        .beginClass<b2Joint>("Joint")

            .addMethod("getType", &b2Joint::GetType)
            .addMethod("getBodyA", &b2Joint::GetBodyA)
            .addMethod("getBodyB", &b2Joint::GetBodyB)
            .addMethod("getAnchorA", &b2Joint::GetAnchorA)
            .addMethod("getAnchorB", &b2Joint::GetAnchorB)
            .addMethod("getReactionForce", &b2Joint::GetReactionForce)
            .addMethod("getReactionTorque", &b2Joint::GetReactionTorque)
            .addMethod("getNext", (b2Joint* (b2Joint::*)())&b2Joint::GetNext)
            .addMethod("isActive", &b2Joint::IsActive)
            .addMethod("getCollideConnected", &b2Joint::GetCollideConnected)
            .addMethod("dump", &b2Joint::Dump)
            .addMethod("shiftOrigin", &b2Joint::ShiftOrigin)

        .endClass()

        .beginClass<b2World>("World")

            .addConstructor<void (*)(b2Vec2&)>()

            .addMethod("createBody", &b2World::CreateBody)
            .addMethod("destroyBody", &b2World::DestroyBody)
            .addMethod("getBodyCount", &b2World::GetBodyCount)
            .addMethod("getBodyList", (b2Body* (b2World::*)())&b2World::GetBodyList)
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
    
        .beginClass<b2ShapeCache>("ShapeCache")

            .addStaticMethod("sharedShapeCache", &b2ShapeCache::sharedB2ShapeCache)

            .addMethod("reset", &b2ShapeCache::reset)
            .addMethod("addFixturesToBody", &b2ShapeCache::addFixturesToBody)
            .addMethod("addShapesWithFile", &b2ShapeCache::addShapesWithFile)
            .addMethod("anchorPointForShape", &b2ShapeCache::anchorPointForShape)

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
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2PolygonShape, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2CircleShape, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2Fixture, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2Contact, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2ContactEdge, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2Body, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2Joint, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2World, registerLoomBox2D);
    LOOM_DECLARE_MANAGEDNATIVETYPE(b2ShapeCache, registerLoomBox2D);
}
