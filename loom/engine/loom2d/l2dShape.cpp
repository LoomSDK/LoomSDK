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

#include "loom/common/core/assert.h"
#include "loom/graphics/gfxVectorRenderer.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/engine/loom2d/l2dShape.h"

#include <math.h>

namespace Loom2D
{

Type *Shape::typeShape = NULL;





/****************************
        API FUNCTIONS
****************************/



void VectorPath::moveTo(float x, float y) {
	commands.push_back(MOVE_TO);
	data.push_back(x);
	data.push_back(y);
}
void VectorPath::lineTo(float x, float y) {
	commands.push_back(LINE_TO);
	data.push_back(x);
	data.push_back(y);
}
void VectorPath::curveTo(float controlX, float controlY, float anchorX, float anchorY) {
	commands.push_back(CURVE_TO);
	data.push_back(controlX);
	data.push_back(controlY);
	data.push_back(anchorX);
	data.push_back(anchorY);
}
void VectorPath::cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY) {
	commands.push_back(CUBIC_CURVE_TO);
	data.push_back(controlX1);
	data.push_back(controlY1);
	data.push_back(controlX2);
	data.push_back(controlY2);
	data.push_back(anchorX);
	data.push_back(anchorY);
}
void VectorPath::arcTo(float controlX, float controlY, float anchorX, float anchorY, float radius) {
	commands.push_back(ARC_TO);
	data.push_back(controlX);
	data.push_back(controlY);
	data.push_back(anchorX);
	data.push_back(anchorY);
	data.push_back(radius);
}



void Shape::clear() {
	utArray<VectorData*>::Iterator it = queue->iterator();
	while (it.hasMoreElements()) {
		VectorData* d = it.getNext();
		delete d;
	}
	queue->clear();
	lastPath = NULL;
}

void Shape::lineStyle(float thickness, unsigned int color, float alpha, bool pixelHinting, utString scaleMode, utString caps, utString joints, float miterLimit) {

	const char* t;

	t = scaleMode.c_str();
	GFX::VectorLineScaleMode::Enum scaleModeEnum =
		!strcmp(t, "normal") ? GFX::VectorLineScaleMode::NORMAL :
		!strcmp(t, "none") ? GFX::VectorLineScaleMode::NONE :
		GFX::VectorLineScaleMode::NORMAL;

	t = caps.c_str();
	GFX::VectorLineCaps::Enum capsEnum =
		!strcmp(t, "round") ? GFX::VectorLineCaps::ROUND :
		!strcmp(t, "square") ? GFX::VectorLineCaps::SQUARE :
		!strcmp(t, "none") ? GFX::VectorLineCaps::NONE :
		GFX::VectorLineCaps::ROUND;

	t = joints.c_str();
	GFX::VectorLineJoints::Enum jointsEnum =
		!strcmp(t, "round") ? GFX::VectorLineJoints::ROUND :
		!strcmp(t, "bevel") ? GFX::VectorLineJoints::BEVEL :
		!strcmp(t, "miter") ? GFX::VectorLineJoints::MITER :
		GFX::VectorLineJoints::ROUND;

	queue->push_back(new VectorLineStyle(thickness, color, alpha, scaleModeEnum, capsEnum, jointsEnum, miterLimit));
	restartPath();
}

void Shape::textFormat(GFX::VectorTextFormat format) {
	queue->push_back(new VectorTextFormatData(new GFX::VectorTextFormat(format)));
}

void Shape::beginFill(unsigned int color, float alpha) {
	queue->push_back(new VectorFill(color, alpha));
	restartPath();
}

void Shape::endFill() {
	queue->push_back(new VectorFill());
	restartPath();
}


void Shape::moveTo(float x, float y) {
	getPath()->moveTo(x, y);
}

void Shape::lineTo(float x, float y) {
	getPath()->lineTo(x, y);
}

void Shape::curveTo(float controlX, float controlY, float anchorX, float anchorY) {
	getPath()->curveTo(controlX, controlY, anchorX, anchorY);
}

void Shape::cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY) {
	getPath()->cubicCurveTo(controlX1, controlY1, controlX2, controlY2, anchorX, anchorY);
}

void Shape::arcTo(float controlX, float controlY, float anchorX, float anchorY, float radius) {
	getPath()->arcTo(controlX, controlY, anchorX, anchorY, radius);
}


void Shape::drawCircle(float x, float y, float radius) {
	addShape(new VectorShape(CIRCLE, x, y, radius));
}

void Shape::drawEllipse(float x, float y, float width, float height) {
	addShape(new VectorShape(ELLIPSE, x, y, width, height));
}

void Shape::drawRect(float x, float y, float width, float height) {
	addShape(new VectorShape(RECT, x, y, width, height));
}

// TODO implement ellipseHeight?
void Shape::drawRoundRect(float x, float y, float width, float height, float ellipseWidth, float ellipseHeight) {
	addShape(new VectorShape(ROUND_RECT, x, y, width, height, ellipseWidth));
}

void Shape::drawArc(float x, float y, float radius, float angleFrom, float angleTo, int direction) {
	addShape(new VectorShape(direction == GFX::VectorWinding::CW ? ARC_CW : ARC_CCW, x, y, radius, angleFrom, angleTo));
}

void Shape::drawTextLabel(float x, float y, utString text) {
	queue->push_back(new VectorText(x, y, NAN, new utString(text)));
}

void Shape::drawTextBox(float x, float y, float width, utString text) {
	queue->push_back(new VectorText(x, y, width, new utString(text)));
}

void Shape::drawSVG(float x, float y, float scale, GFX::VectorSVG* svg) {
	queue->push_back(new VectorSVGData(x, y, scale, svg));
	restartPath();
}


/*************************
        RENDERING
*************************/



void Shape::render(lua_State *L)
{
	updateLocalTransform();

	Matrix transform;
	getTargetTransformationMatrix(NULL, &transform);

	GFX::QuadRenderer::submit();

	GFX::VectorRenderer::beginFrame();
	GFX::VectorRenderer::preDraw(transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty);

	resetStyle();

	flushPath();

	utArray<VectorData*>::Iterator it = queue->iterator();
	while (it.hasMoreElements()) {
		VectorData* d = it.getNext();
		d->render(L, this);
	}
	flushPath();

	GFX::VectorRenderer::postDraw();
	GFX::VectorRenderer::endFrame();

}

void VectorPath::render(lua_State *L, Shape* g) {
	int ci = 0;
	int commandNum = commands.size();
	int di = 0;
	float x, y, c1x, c1y, c2x, c2y, r;

	if (!g->isStyleVisible()) return;

	while (ci < commandNum) {
		switch (commands[ci++]) {
		case MOVE_TO:
			// If we don't store it in vars first, the arguments get swapped?
			x = data[di++];
			y = data[di++];
			GFX::VectorRenderer::moveTo(x, y);
			break;
		case LINE_TO:
			x = data[di++];
			y = data[di++];
			GFX::VectorRenderer::lineTo(x, y);
			break;
		case CURVE_TO:
			c1x = data[di++];
			c1y = data[di++];
			x = data[di++];
			y = data[di++];
			GFX::VectorRenderer::curveTo(c1x, c1y, x, y);
			break;
		case CUBIC_CURVE_TO:
			c1x = data[di++];
			c1y = data[di++];
			c2x = data[di++];
			c2y = data[di++];
			x = data[di++];
			y = data[di++];
			GFX::VectorRenderer::cubicCurveTo(c1x, c1y, c2x, c2y, x, y);
			break;
		case ARC_TO:
			c1x = data[di++];
			c1y = data[di++];
			x = data[di++];
			y = data[di++];
			r = data[di++];
			GFX::VectorRenderer::arcTo(c1x, c1y, x, y, r);
			break;
		}
	}

	g->pathDirty = true;
}

void VectorShape::render(lua_State *L, Shape* g) {
	if (!g->isStyleVisible()) return;
	switch (type) {
		case CIRCLE:     GFX::VectorRenderer::circle(x, y, a); break;
		case ELLIPSE:    GFX::VectorRenderer::ellipse(x, y, a, b); break;
		case RECT:       GFX::VectorRenderer::rect(x, y, a, b); break;
		case ROUND_RECT: GFX::VectorRenderer::roundRect(x, y, a, b, c); break;
		case ARC_CW:     GFX::VectorRenderer::arc(x, y, a, b, c, GFX::VectorWinding::CW); break;
		case ARC_CCW:    GFX::VectorRenderer::arc(x, y, a, b, c, GFX::VectorWinding::CCW); break;
	}
	g->pathDirty = true;
}

void VectorLineStyle::render(lua_State *L, Shape* g) {
	g->flushPath();
	copyTo(&g->currentLineStyle);
}

void VectorFill::render(lua_State *L, Shape* g) {
	if (!active) g->flushPath();
	g->currentFill.active = active;
	g->currentFill.color = color;
	g->currentFill.alpha = alpha;
}

void VectorText::render(lua_State *L, Shape* g) {
	if (isnan(width)) {
		GFX::VectorRenderer::textLabel(x, y, text);
	} else {
		GFX::VectorRenderer::textBox(x, y, width, text);
	}
}

void VectorTextFormatData::render(lua_State *L, Shape* g) {
	GFX::VectorRenderer::textFormat(format);
}

void VectorSVGData::render(lua_State *L, Shape* g) {
	g->flushPath();
	GFX::VectorRenderer::svg(x, y, scale, image);
}



/*******************
        MISC
********************/



void VectorLineStyle::reset() {
	thickness = NAN;
	color = 0x000000;
	alpha = 1;
	scaleMode = GFX::VectorLineScaleMode::NORMAL;
	caps = GFX::VectorLineCaps::ROUND;
	joints = GFX::VectorLineJoints::ROUND;
	miterLimit = 0;
}

void VectorLineStyle::copyTo(VectorLineStyle* s) {
	s->thickness = thickness;
	s->color = color;
	s->alpha = alpha;
	s->scaleMode = scaleMode;
	s->caps = caps;
	s->joints = joints;
	s->miterLimit = miterLimit;
}



VectorPath* Shape::getPath() {
	VectorPath* path = lastPath;
	if (path == NULL) {
		path = queue->empty() ? NULL : dynamic_cast<VectorPath*>(queue->back());
		if (path == NULL) {
			path = new VectorPath();
			path->moveTo(0, 0);
			queue->push_back(path);
		}
		lastPath = path;
	}
	return path;
}

void Shape::addShape(VectorShape *shape) {
	queue->push_back(shape);
	restartPath();
}

bool Shape::isStyleVisible() {
	bool stroke = !isnan(currentLineStyle.thickness);
	bool fill = currentFill.active;
	return stroke || fill;
}

void Shape::flushPath() {
	bool stroke = !isnan(currentLineStyle.thickness);
	if (stroke && pathDirty) {
		float scale = 1.0f;
		switch (currentLineStyle.scaleMode) {
			case GFX::VectorLineScaleMode::NONE: scale = 1/sqrt(scaleX*scaleX+scaleY*scaleY); break;
		}
		GFX::VectorRenderer::strokeWidth(currentLineStyle.thickness*scale);
		GFX::VectorRenderer::strokeColor(currentLineStyle.color, currentLineStyle.alpha);
		GFX::VectorRenderer::lineCaps(currentLineStyle.caps);
		GFX::VectorRenderer::lineJoints(currentLineStyle.joints);
		GFX::VectorRenderer::lineMiterLimit(currentLineStyle.miterLimit);
		GFX::VectorRenderer::renderStroke();
	}
	bool fill = currentFill.active;
	if (fill && pathDirty) {
		GFX::VectorRenderer::fillColor(currentFill.color, currentFill.alpha);
		GFX::VectorRenderer::renderFill();
		currentFill.active = false;
	}
	pathDirty = false;
	GFX::VectorRenderer::clearPath();
}

void Shape::restartPath() {
	if (lastPath) {
		int dataNum = lastPath->data.size();
		if (dataNum >= 2) {
			float x = lastPath->data[dataNum - 2];
			float y = lastPath->data[dataNum - 1];
			lastPath = NULL;
			moveTo(x, y);
		} else {
			lastPath = NULL;
		}
	}
}

void Shape::resetStyle() {
	currentLineStyle.reset();
	currentFill.reset();
}

}
