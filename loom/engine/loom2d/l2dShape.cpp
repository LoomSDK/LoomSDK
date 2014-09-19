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

namespace Loom2D
{

Type *Shape::typeShape = NULL;

void VectorPath::render(lua_State *L, Shape* g) {
	int ci = 0;
	int commandNum = commands.size();
	int di = 0;
	float x, y, c1x, c1y, c2x, c2y;

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
		}
	}
}

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

void VectorShape::render(lua_State *L, Shape* g) {
	if (!g->isStyleVisible()) return;
	switch (type) {
		case CIRCLE:     GFX::VectorRenderer::circle(x, y, a); break;
		case ELLIPSE:    GFX::VectorRenderer::ellipse(x, y, a, b); break;
		case RECT:       GFX::VectorRenderer::rect(x, y, a, b); break;
		case ROUND_RECT: GFX::VectorRenderer::roundRect(x, y, a, b, c); break;
	}
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


void VectorLineStyle::render(lua_State *L, Shape* g) {
	/*
	GFX::VectorRenderer::clearPath();
	GFX::VectorRenderer::strokeWidth(thickness);
	float cr = ((color >> 16) & 0xff) / 255.0f;
	float cg = ((color >> 8) & 0xff) / 255.0f;
	float cb = ((color >> 0) & 0xff) / 255.0f;
	GFX::VectorRenderer::strokeColor(cr, cg, cb, alpha);
	//*/
	g->flushPath();
	g->currentLineStyle.thickness = thickness;
	g->currentLineStyle.color = color;
	g->currentLineStyle.alpha = alpha;
	g->currentLineStyle.caps = caps;
	g->currentLineStyle.joints = joints;
	g->currentLineStyle.miterLimit = miterLimit;
}

void VectorFill::render(lua_State *L, Shape* g) {
	/*
	float cr = ((color >> 16) & 0xff) / 255.0f;
	float cg = ((color >> 8) & 0xff) / 255.0f;
	float cb = ((color >> 0) & 0xff) / 255.0f;
	GFX::VectorRenderer::fillColor(cr, cg, cb, alpha);
	*/
	if (!active) g->flushPath();
	g->currentFill.active = active;
	g->currentFill.color = color;
	g->currentFill.alpha = alpha;
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

bool Shape::isStyleVisible() {
	bool stroke = !isnan(currentLineStyle.thickness);
	bool fill = currentFill.active;
	return stroke || fill;
}

void Shape::flushPath() {
	bool stroke = !isnan(currentLineStyle.thickness);
	if (stroke) {
		GFX::VectorRenderer::strokeWidth(currentLineStyle.thickness);
		unsigned int color = currentLineStyle.color;
		float cr = ((color >> 16) & 0xff) / 255.0f;
		float cg = ((color >> 8) & 0xff) / 255.0f;
		float cb = ((color >> 0) & 0xff) / 255.0f;
		GFX::VectorRenderer::strokeColor(cr, cg, cb, currentLineStyle.alpha);
		GFX::VectorRenderer::lineCaps(currentLineStyle.caps);
		GFX::VectorRenderer::lineJoints(currentLineStyle.joints);
		GFX::VectorRenderer::lineMiterLimit(currentLineStyle.miterLimit);
		GFX::VectorRenderer::renderStroke();
	}
	bool fill = currentFill.active;
	if (fill) {
		unsigned int color = currentFill.color;
		float cr = ((color >> 16) & 0xff) / 255.0f;
		float cg = ((color >> 8) & 0xff) / 255.0f;
		float cb = ((color >> 0) & 0xff) / 255.0f;
		GFX::VectorRenderer::fillColor(cr, cg, cb, currentFill.alpha);
		GFX::VectorRenderer::renderFill();
		currentFill.active = false;
	}
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

void Shape::lineStyle(float thickness, unsigned int color, float alpha, bool pixelHinting, utString scaleMode, utString caps, utString joints, float miterLimit) {
	
	const char* c = caps.c_str();
	GFX::VectorLineCaps capsEnum = 
		!strcmp(c, "round")  ? GFX::VectorLineCaps::CAPS_ROUND :
		!strcmp(c, "square") ? GFX::VectorLineCaps::CAPS_SQUARE :
		!strcmp(c, "none") ? GFX::VectorLineCaps::CAPS_NONE :
		GFX::VectorLineCaps::CAPS_ROUND;

	const char* j = joints.c_str();
	GFX::VectorLineJoints jointsEnum =
		!strcmp(j, "round") ? GFX::VectorLineJoints::JOINTS_ROUND :
		!strcmp(j, "bevel") ? GFX::VectorLineJoints::JOINTS_BEVEL :
		!strcmp(j, "miter") ? GFX::VectorLineJoints::JOINTS_MITER :
		GFX::VectorLineJoints::JOINTS_ROUND;

	queue->push_back(new VectorLineStyle(thickness, color, alpha, capsEnum, jointsEnum, miterLimit));
	restartPath();
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

void Shape::addShape(VectorShape *shape) {
	queue->push_back(shape);
	restartPath();
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

void Shape::resetStyle() {
	currentLineStyle.reset();
	currentFill.reset();
}

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

}
