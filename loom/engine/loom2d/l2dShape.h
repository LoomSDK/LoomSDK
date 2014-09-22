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
#include "loom/graphics/gfxVectorRenderer.h"

namespace Loom2D
{

class Shape;

class VectorData {
	public:
		virtual ~VectorData() {}
		virtual void render(lua_State *L, Shape* g) = 0;
};

#define MAXCOMMANDS 20
#define MAXDATA 200

enum VectorPathCommand {
	MOVE_TO,
	LINE_TO,
	CURVE_TO,
	CUBIC_CURVE_TO
};

class VectorPath : public VectorData {

public:
	utArray<VectorPathCommand> commands;
	utArray<float> data;

	void moveTo(float x, float y);
	void lineTo(float x, float y);
	void curveTo(float controlX, float controlY, float anchorX, float anchorY);
	void cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY);

	virtual void render(lua_State *L, Shape* g);
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

	virtual void render(lua_State *L, Shape* g);
};

class VectorLineStyle : public VectorData {
public:

	float thickness;
	unsigned int color;
	float alpha;
	GFX::VectorLineScaleMode::Enum scaleMode;
	GFX::VectorLineCaps::Enum caps;
	GFX::VectorLineJoints::Enum joints;
	float miterLimit;
	
	VectorLineStyle() {
		reset();
	}
	void reset();
	void copyTo(VectorLineStyle* s);
	VectorLineStyle(float thickness, unsigned int color, float alpha, GFX::VectorLineScaleMode::Enum scaleMode, GFX::VectorLineCaps::Enum caps, GFX::VectorLineJoints::Enum joints, float miterLimit) : thickness(thickness), color(color), alpha(alpha), scaleMode(scaleMode), caps(caps), joints(joints), miterLimit(miterLimit) {};

	virtual void render(lua_State *L, Shape* g);
};

class VectorFill : public VectorData {
public:
	bool active;
	unsigned int color;
	float alpha;

	VectorFill() {
		reset();
	}
	void reset() {
		active = false;
		color = 0x000000;
		alpha = 1;
	}
	VectorFill(unsigned int color, float alpha) : color(color), alpha(alpha) {
		active = true;
	};

	virtual void render(lua_State *L, Shape* g);
};


class Shape : public DisplayObject
{
protected:
	VectorPath* getPath();
	void addShape(VectorShape *shape);
	void restartPath();
	void resetStyle();

public:

    static Type *typeShape;

	utArray<VectorData*> *queue;
	VectorPath *lastPath;
	VectorLineStyle currentLineStyle;
	VectorFill currentFill;
	bool pathDirty = false;
	
	Shape()
	{
		type = typeShape;
		queue = new utArray<VectorData*>();
		lastPath = NULL;
	}

	bool isStyleVisible();
	void flushPath();

    void render(lua_State *L);

	void clear();
	void lineStyle(float thickness, unsigned int color, float alpha, bool pixelHinting, utString scaleMode, utString caps, utString joints, float miterLimit);
	void beginFill(unsigned int color, float alpha);
	void endFill();
	void moveTo(float x, float y);
	void lineTo(float x, float y);
	void curveTo(float controlX, float controlY, float anchorX, float anchorY);
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
