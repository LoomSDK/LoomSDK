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

#ifndef _lsphysics_h
#define _lsphysics_h


// This is lifted from the initial loom demo physics.cpp and needs to be improved

void *physics_spawnBody(float x, float y, float radius, float mass);
void *physics_spawnWall(float x1, float x2, float y1, float y2);
void physics_getBodyPos(void *body, float& outX, float& outY, float& rad, float& speed, float& angle);
void physics_setBodyPos(void *body, float x, float y);
void physics_setBodyVel(void *body, float x, float y);
void physics_applyForce(void *body, float fx, float fy);
float physics_getMass(void *body);
void physics_destroyBody(void *body);
void physics_setGravity(float x, float y);

void physics_tick();

void physics_setInterObjectGravityEnabled(int enabled);
#endif
