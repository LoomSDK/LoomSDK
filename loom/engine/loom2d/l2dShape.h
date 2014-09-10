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

class VectorData {
	public:
		virtual ~VectorData() {}
		virtual void render(lua_State *L) = 0;
};

#define MAXCOMMANDS 20
#define MAXDATA 200

enum VectorPathCommand {
	MOVE_TO,
	LINE_TO,
	CUBIC_CURVE_TO
};

class VectorPath : public VectorData {

public:
	utArray<VectorPathCommand> commands;
	utArray<float> data;

	void moveTo(float x, float y);
	void lineTo(float x, float y);
	void cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY);

	virtual void render(lua_State *L);
};

enum VectorShapeType {
	CIRCLE,
	ELLIPSE,
	RECT,
	ROUND_RECT
};

class VectorShape : public VectorData {
protected:
	VectorShapeType type;
	float x;
	float y;
	float a;
	float b;
	float c;

public:
	VectorShape(VectorShapeType type, float x, float y, float a = 0.0, float b = 0.0, float c = 0.0) : type(type), x(x), y(y), a(a), b(b), c(c) {};

	virtual void render(lua_State *L);
};

class VectorLineStyle : public VectorData {
protected:
	float thickness;
	unsigned int color;
	float alpha;

public:
	VectorLineStyle(float thickness, unsigned int color, float alpha) : thickness(thickness), color(color), alpha(alpha) {};

	virtual void render(lua_State *L);
};


class Shape : public DisplayObject
{
protected:
	VectorPath* getPath();
	void addShape(VectorShape *shape);

public:

    static Type *typeShape;

	utArray<VectorData*> *queue;

	VectorPath *lastPath;

	Shape()
	{
		type = typeShape;
		queue = new utArray<VectorData*>();
		lastPath = NULL;
	}

    void render(lua_State *L);

	void clear();
	void lineStyle(float thickness, unsigned int color, float alpha);
	void strokeColor(float r, float g, float b, float a);
	void moveTo(float x, float y);
	void lineTo(float x, float y);
	void cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY);
	void drawCircle(float x, float y, float radius);
	void drawEllipse(float x, float y, float width, float height);
	void drawRect(float x, float y, float width, float height);
	void drawRoundRect(float x, float y, float width, float height, float ellipseWidth, float ellipseHeight);

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
			.addMethod("cubicCurveTo", &Shape::cubicCurveTo)
			.addMethod("drawCircle", &Shape::drawCircle)
			.addMethod("drawEllipse", &Shape::drawEllipse)
			.addMethod("drawRect", &Shape::drawRect)
			.addMethod("drawRoundRect", &Shape::drawRoundRect)
			.endClass()
			.endPackage();
		return 0;
	}
	*/
};
}
