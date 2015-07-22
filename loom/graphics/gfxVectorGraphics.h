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

#include "loom/graphics/gfxVectorRenderer.h"
#include "loom/engine/loom2d/l2dDisplayObject.h"
#include "loom/engine/loom2d/l2dDisplayObjectContainer.h"
#include "loom/engine/loom2d/l2dMatrix.h"
#include "loom/engine/loom2d/l2dRectangle.h"

namespace GFX
{

class VectorGraphics;

class VectorData {
public:
	virtual ~VectorData() {}
	virtual void render(VectorGraphics* g) = 0;
};

enum VectorPathCommand {
	MOVE_TO,
	LINE_TO,
	CURVE_TO,
	CUBIC_CURVE_TO,
	ARC_TO,
};

class VectorPath : public VectorData {

public:
	utArray<VectorPathCommand> commands;
	utArray<float> data;
	float lastX;
	float lastY;

	void moveTo(float x, float y);
	void lineTo(float x, float y);
	void curveTo(float controlX, float controlY, float anchorX, float anchorY);
	void cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY);
	void arcTo(float controlX, float controlY, float anchorX, float anchorY, float radius);

	virtual void render(VectorGraphics* g);
};

enum VectorShapeType {
	CIRCLE,
	ELLIPSE,
	RECT,
	ROUND_RECT,
	ROUND_RECT_COMPLEX,
	ARC_CW,
	ARC_CCW
};

class VectorShape : public VectorData {
protected:
	VectorShapeType type;
	float x;
	float y;
	float a;
	float b;
	float c;
	float d;
	float e;
	float f;

public:
	VectorShape(VectorShapeType type, float x, float y, float a = 0.0, float b = 0.0, float c = 0.0, float d = 0.0, float e = 0.0, float f = 0.0) : type(type), x(x), y(y), a(a), b(b), c(c), d(d), e(e), f(f) {};

	virtual void render(VectorGraphics* g);
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

	virtual void render(VectorGraphics* g);
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

	virtual void render(VectorGraphics* g);
};

class VectorText : public VectorData {
protected:
	float x;
	float y;
	float width;
	utString* text;

public:
	VectorText(float x, float y, float width, utString* text) : x(x), y(y), width(width), text(text) {};
	~VectorText() { lmDelete(NULL, text); }

	virtual void render(VectorGraphics* g);
};

class VectorTextFormatData : public VectorData {
public:
	GFX::VectorTextFormat* format;
	VectorTextFormatData(GFX::VectorTextFormat* format) : format(format) {};
	~VectorTextFormatData();
	virtual void render(VectorGraphics* g);
};

class VectorSVGData : public VectorData {
public:
	float x;
	float y;
	float scale;
	float lineThickness;
	GFX::VectorSVG* image;
	VectorSVGData(GFX::VectorSVG* image, float x, float y, float scale = 1.0f, float lineThickness = 1.0f) : x(x), y(y), scale(scale), lineThickness(lineThickness), image(image) {};
	virtual void render(VectorGraphics* g);
};





class VectorGraphics {
protected:
	VectorPath* getPath();
	void addShape(VectorShape *shape);
	void restartPath();
	void resetStyle();
	void inflateBounds(const Loom2D::Rectangle& rect);
	void ensureTextFormat();

public:
	utArray<VectorData*> *queue;
	VectorPath *lastPath;
	VectorLineStyle currentLineStyle;
	VectorFill currentFill;
	bool pathDirty;
	bool textFormatDirty;
	GFX::VectorTextFormat currentTextFormat;
	tfloat boundL;
	tfloat boundT;
	tfloat boundR;
	tfloat boundB;
	tfloat scale;
	int clipX, clipY, clipWidth, clipHeight;

	VectorGraphics() {
		queue = new utArray<VectorData*>();
		clipX = clipY = 0;
		clipWidth = clipHeight = -1;
		clear();
	}

	bool isStyleVisible();
	void flushPath();

    void setClipRect(int x, int y, int w, int h);
	void render(Loom2D::RenderState* renderState, Loom2D::Matrix* transform);

	void clear();
	void clearBounds();
	void lineStyle(float thickness, unsigned int color, float alpha, bool pixelHinting, utString scaleMode, utString caps, utString joints, float miterLimit);
	void textFormat(GFX::VectorTextFormat format);
	void beginFill(unsigned int color, float alpha);
	void endFill();

	Loom2D::Rectangle getBounds();

	void moveTo(float x, float y);
	void lineTo(float x, float y);
	void curveTo(float controlX, float controlY, float anchorX, float anchorY);
	void cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY);
	void arcTo(float controlX, float controlY, float anchorX, float anchorY, float radius);

	void drawCircle(float x, float y, float radius);
	void drawEllipse(float x, float y, float width, float height);
	void drawRect(float x, float y, float width, float height);
	void drawRoundRect(float x, float y, float width, float height, float ellipseWidth, float ellipseHeight);
	void drawRoundRectComplex(float x, float y, float width, float height, float topLeftRadius, float topRightRadius, float bottomLeftRadius, float bottomRightRadius);
	void drawArc(float x, float y, float radius, float angleFrom, float angleTo, int direction);

	void drawTextLine(float x, float y, utString text);
	void drawTextBox(float x, float y, float width, utString text);

	Loom2D::Rectangle textLineBounds(GFX::VectorTextFormat format, float x, float y, utString text);
	float textLineAdvance(GFX::VectorTextFormat format, float x, float y, utString text);
	Loom2D::Rectangle textBoxBounds(GFX::VectorTextFormat format, float x, float y, float width, utString text);

	void drawSVG(GFX::VectorSVG* svg, float x, float y, float scale, float lineThickness);
};


}
