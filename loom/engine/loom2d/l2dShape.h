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

#pragma once

#include "loom/engine/loom2d/l2dDisplayObject.h"

namespace Loom2D
{

enum VectorPathCommand { MOVE_TO, LINE_TO };


#define MAXCOMMANDS 10
#define MAXDATA 100

class Shape : public DisplayObject
{
public:

    static Type *typeShape;

	VectorPathCommand commands[MAXCOMMANDS];
	int commandIndex = 0;
	float data[MAXDATA];
	int dataIndex = 0;

	Shape()
	{
		type = typeShape;
	}

    void render(lua_State *L);

	void moveTo(float x, float y);
	void lineTo(float x, float y);

    static void initialize(lua_State *L)
    {
		typeShape = LSLuaState::getLuaState(L)->getType("loom2d.display.Shape");
		lmAssert(typeShape, "unable to get loom2d.display.Shape type");

		//NativeInterface::registerManagedNativeType<Shape>(registerNative);
		//LOOM_DECLARE_MANAGEDNATIVETYPE(Shape, registerNative);
	}
	/*
	static int registerNative(lua_State *L)
	{
		beginPackage(L, "loom2d.display")
			.deriveClass<Shape, DisplayObject>("Shape")
			.addConstructor<void(*)(void)>()
			.addMethod("moveTo", &Shape::moveTo)
			.addMethod("lineTo", &Shape::lineTo)
			.endClass()
			.endPackage();
		return 0;
	}
	*/
};
}
