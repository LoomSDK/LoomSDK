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

class Box2D
{

};

static int registerLoomBox2D(lua_State *L)
{
    beginPackage(L, "loom.box2d")

       .beginClass<Box2D>("Box2D")
/*
       .addStaticMethod("initialize", &Box2D::initialize)

       .addStaticProperty("available", &Box2D::available)
       .addStaticProperty("providerName", &Box2D::providerName)

       .addStaticMethod("listProducts", &Box2D::listProducts)
       .addStaticMethod("requestPurchase", &Box2D::requestPurchase)

       .addStaticProperty("onProduct", &Box2D::getOnProductDelegate)
       .addStaticProperty("onProductComplete", &Box2D::getOnProductCompleteDelegate)
       .addStaticProperty("onPurchaseUIComplete", &Box2D::getOnPurchaseUICompleteDelegate)
       .addStaticProperty("onTransaction", &Box2D::getOnTransactionDelegate)
*/
       .endClass()
    
    .endPackage();

    return 0;
}


void installLoomBox2D()
{
    LOOM_DECLARE_NATIVETYPE(Box2D, registerLoomBox2D);
}
