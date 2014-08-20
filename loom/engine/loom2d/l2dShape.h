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
#include "loom/engine/loom2d/l2dDisplayObjectContainer.h"

namespace Loom2D
{
	class Shape : public DisplayObject
	{
	public:

		static Type *typeShape;

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

		}

	};

}