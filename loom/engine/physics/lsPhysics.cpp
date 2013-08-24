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

#include "loom/script/loomscript.h"

using namespace LS;

#include "chipmunk/chipmunk.h"

void gravitySolverInner(cpBody *elt, void *data);
void gravitySolver(cpBody *elt, void *data);
void clearForces(cpBody *b, void *data);

cpSpace    *gSpace            = 0;
static int interObjectGravity = 0; // A flag to turn inter-object gravity on/off.

void physics_init()
{
    cpInitChipmunk();

    gSpace          = cpSpaceNew();
    gSpace->gravity = cpv(0, 0);
}


void *physics_spawnBody(float x, float y, float radius, float mass)
{
    cpBody *body = cpBodyNew((cpFloat)mass, cpMomentForCircle((cpFloat)mass, 0.f, radius, cpv(0, 0)));

    body->p = cpv(x, y);
    cpSpaceAddBody(gSpace, body);

    cpShape *circle = cpCircleShapeNew(body, radius, cpv(0, 0));
    circle->e = 0.5f;
    circle->u = 0.0f;
    circle->collision_type = 1;
    body->data             = circle;
    cpSpaceAddShape(gSpace, circle);

    return body;
}


void *physics_spawnWall(float x1, float x2, float y1, float y2)
{
    cpBody *body = cpBodyNewStatic();

    body->p = cpv((x1 + x2) * 0.5f, (y1 + y2) * 0.5f);
    //cpSpaceAddBody(gSpace, body); // No need to add static bodies

    float w = x1 < x2 ? x2 - x1 : x1 - x2;
    float h = y1 < y2 ? y2 - y1 : y1 - y2;

    cpShape *rect = cpBoxShapeNew(body, w, h);
    rect->e = 0.5f;
    rect->u = 0.0f;
    rect->collision_type = 1;
    body->data           = rect;

    cpSpaceAddStaticShape(gSpace, rect);
    return body;
}


void physics_getBodyPos(void *body, float& outX, float& outY, float& rad, float& speed, float& angle)
{
    cpBody *b = (cpBody *)body;

    angle = (float)cpBodyGetAngle(b);
    outX  = (float)b->p.x;
    outY  = (float)b->p.y;
    rad   = (float)cpCircleShapeGetRadius(b->shapeList_private);
    speed = (float)cpvlength(b->v);
}


struct GravitySolverState
{
    cpVect  gforce;
    cpVect  ourCenter;
    cpFloat ourMass;
    cpBody  *ourBody;
};

void gravitySolverInner(cpBody *elt, void *data)
{
    GravitySolverState *gss  = (GravitySolverState *)data;
    cpBody             *body = (cpBody *)elt;

    // Don't gravitate ourselves.
    if (body == gss->ourBody)
    {
        return;
    }

    // Figure delta & distance.
    cpVect  sP         = cpBodyGetPos(body);
    cpVect  delta      = cpvsub(sP, gss->ourCenter);
    cpFloat deltaLenSq = cpvlengthsq(delta);

    // Cap distance thus force. Avoid singularity.
    if (deltaLenSq < 1.0f)
    {
        deltaLenSq = 1.0f;
    }

    // Get mass.
    cpFloat otherMass = cpBodyGetMass(body);

    // Solve gravity formula.
    const cpFloat g = 1000.f;
    cpFloat       f = g * ((otherMass * gss->ourMass) / deltaLenSq);

    // Accumulate force.
    cpVect force = cpvnormalize(delta);
    force.x    *= f;
    force.y    *= f;
    gss->gforce = cpvadd(gss->gforce, force);
}


void gravitySolver(cpBody *elt, void *data)
{
    cpBody *body = (cpBody *)elt;

    GravitySolverState gss;

    gss.gforce    = cpv(0, 0);
    gss.ourCenter = cpBodyGetPos(body);
    gss.ourMass   = cpBodyGetMass(body);
    gss.ourBody   = body;

    cpSpaceEachBody(gSpace, gravitySolverInner, &gss);

    cpBodyApplyForce(body, gss.gforce, cpv(0, 0));
}


void clearForces(cpBody *b, void *data)
{
    cpBodyResetForces(b);
}


void physics_tick()
{
    // Apply gravity.
    if (interObjectGravity)
    {
        cpSpaceEachBody(gSpace, gravitySolver, 0);
    }

    // Run sim.
    cpSpaceStep(gSpace, 1.0f / 60.0f);

    // Clear everyone's forces.
    cpSpaceEachBody(gSpace, clearForces, 0);
}


void physics_applyForce(void *body, float fx, float fy)
{
    cpBody *b = (cpBody *)body;

    cpBodyResetForces(b);
    cpBodyApplyForce(b, cpv(fx, fy), cpv(0, 0));
}


void physics_setGravity(float x, float y)
{
    gSpace->gravity = cpv(x, y);
}


float physics_getMass(void *body)
{
    cpBody *b = (cpBody *)body;

    return (float)b->m;
}


void physics_setBodyPos(void *body, float x, float y)
{
    cpBody *b = (cpBody *)body;

    cpBodySetPos(b, cpv(x, y));
}


void physics_setBodyVel(void *body, float x, float y)
{
    cpBody *b = (cpBody *)body;

    cpBodySetVel(b, cpv(x, y));
}


void physics_destroyBody(void *body)
{
    cpBody *b = (cpBody *)body;

    cpSpaceRemoveShape(gSpace, (cpShape *)b->data);
    cpShapeFree((cpShape *)b->data);
    if (!cpBodyIsRogue(b))
    {
        cpSpaceRemoveBody(gSpace, b);
    }
    cpBodyFree(b);
}


void physics_setInterObjectGravityEnabled(int enabled)
{
    interObjectGravity = enabled;
}


class PhysicsWall {
public:

    void *body;

    PhysicsWall() : body(0)
    {
    }

    ~PhysicsWall()
    {
        if (body)
        {
            physics_destroyBody(body);
        }
    }
};

class PhysicsBall {
public:

    void *body;

    PhysicsBall() : body(0)
    {
    }

    ~PhysicsBall()
    {
        if (body)
        {
            physics_destroyBody(body);
        }
    }

    float getX() const
    {
        float x, y, r, speed, angle;

        physics_getBodyPos(body, x, y, r, speed, angle);
        return x;
    }

    float getY() const
    {
        float x, y, r, speed, angle;

        physics_getBodyPos(body, x, y, r, speed, angle);
        return y;
    }

    float getAngle() const
    {
        float x, y, r, speed, angle;

        physics_getBodyPos(body, x, y, r, speed, angle);
        return angle;
    }
};

class Physics {
public:

    static void init()
    {
        physics_init();
    }

    static void tick()
    {
        physics_tick();
    }

    static void setInterObjectGravityEnabled(bool enabled)
    {
        physics_setInterObjectGravityEnabled(enabled);
    }

    static void setGravity(float x, float y)
    {
        physics_setGravity(x, y);
    }

    static PhysicsWall *spawnWall(float x1, float x2, float y1, float y2)
    {
        PhysicsWall *hwall = new PhysicsWall();

        hwall->body = physics_spawnWall(x1, x2, y1, y2);
        return hwall;
    }

    static PhysicsBall *spawnBall(float x, float y, float radius, float mass)
    {
        PhysicsBall *hball = new PhysicsBall();

        hball->body = physics_spawnBody(x, y, radius, mass);
        return hball;
    }
};

static int registerLoomPhysicsPhysics(lua_State *L)
{
    beginPackage(L, "loom.physics")

       .beginClass<Physics>("Physics")
       .addStaticMethod("init", &Physics::init)
       .addStaticMethod("tick", &Physics::tick)
       .addStaticMethod("spawnWall", &Physics::spawnWall)
       .addStaticMethod("spawnBall", &Physics::spawnBall)
       .addStaticMethod("setGravity", &Physics::setGravity)
       .addStaticMethod("setInterObjectGravityEnabled", &Physics::setInterObjectGravityEnabled)
       .endClass()

       .beginClass<PhysicsWall>("PhysicsWall")
       .endClass()

       .beginClass<PhysicsBall>("PhysicsBall")
       .addVarAccessor("x", &PhysicsBall::getX)
       .addVarAccessor("y", &PhysicsBall::getY)
       .addVarAccessor("angle", &PhysicsBall::getAngle)
       .endClass()
       .endPackage();

    return 0;
}


void installLoomPhysicsPhysics()
{
    LOOM_DECLARE_MANAGEDNATIVETYPE(Physics, registerLoomPhysicsPhysics);
    LOOM_DECLARE_MANAGEDNATIVETYPE(PhysicsWall, registerLoomPhysicsPhysics);
    LOOM_DECLARE_MANAGEDNATIVETYPE(PhysicsBall, registerLoomPhysicsPhysics);
}
