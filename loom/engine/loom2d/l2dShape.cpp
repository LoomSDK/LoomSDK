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

void VectorPath::render(lua_State *L) {
	int ci = 0;
	int di = 0;
	float x, y, c1x, c1y, c2x, c2y;
	while (ci < commandIndex) {
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
	lmAssert(commandIndex < MAXCOMMANDS, "Too many Shape commands added");
	lmAssert(dataIndex + 1 < MAXDATA, "Too much Shape data added");
	commands[commandIndex++] = MOVE_TO;
	data[dataIndex++] = x;
	data[dataIndex++] = y;
}
void VectorPath::lineTo(float x, float y) {
	lmAssert(commandIndex < MAXCOMMANDS, "Too many Shape commands added");
	lmAssert(dataIndex + 1 < MAXDATA, "Too much Shape data added");
	commands[commandIndex++] = LINE_TO;
	data[dataIndex++] = x;
	data[dataIndex++] = y;
}
void VectorPath::cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY) {
	lmAssert(commandIndex < MAXCOMMANDS, "Too many Shape commands added");
	lmAssert(dataIndex + 1 < MAXDATA, "Too much Shape data added");
	commands[commandIndex++] = CUBIC_CURVE_TO;
	data[dataIndex++] = controlX1;
	data[dataIndex++] = controlY1;
	data[dataIndex++] = controlX2;
	data[dataIndex++] = controlY2;
	data[dataIndex++] = anchorX;
	data[dataIndex++] = anchorY;
}

void VectorShape::render(lua_State *L) {
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
			queue->push_back(path);
		}
		lastPath = path;
	}
	return path;
}

void Shape::clear() {
	utArray<VectorData*>::Iterator it = queue->iterator();
	while (it.hasMoreElements()) {
		VectorData* d = it.getNext();
		delete d;
	}
	queue->clear();
	if (lastPath) lastPath = NULL;
}

void Shape::moveTo(float x, float y) {
	getPath()->moveTo(x, y);
}

void Shape::lineTo(float x, float y) {
	getPath()->lineTo(x, y);
}

void Shape::cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY) {
	getPath()->cubicCurveTo(controlX1, controlX2, controlY1, controlY2, anchorX, anchorY);
}

void Shape::addShape(VectorShape *shape) {
	queue->push_back(shape);
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

void Shape::render(lua_State *L)
{
    updateLocalTransform();

	Matrix transform;
	getTargetTransformationMatrix(NULL, &transform);

	GFX::QuadRenderer::submit();

	GFX::VectorRenderer::beginFrame();
	GFX::VectorRenderer::preDraw(transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty);

	utArray<VectorData*>::Iterator it = queue->iterator();
	while (it.hasMoreElements()) {
		VectorData* d = it.getNext();
		d->render(L);
	}

	GFX::VectorRenderer::postDraw();
	GFX::VectorRenderer::endFrame();
	
}

}
