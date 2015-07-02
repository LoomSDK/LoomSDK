﻿/*
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

#include "loom/graphics/gfxMath.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/graphics/gfxVectorGraphics.h"

#include "loom/script/runtime/lsProfiler.h"
#include "loom/common/core/log.h"

namespace GFX
{
lmDeclareLogGroup(gGFXLogGroup);




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


#pragma warning(disable: 4056 4756)
void VectorGraphics::clear() {
	utArray<VectorData*>::Iterator it = queue->iterator();
	while (it.hasMoreElements()) {
		VectorData* d = it.getNext();
		lmDelete(NULL, d);
	}
	queue->clear();
	/*
	bounds.x = INFINITY;
	bounds.y = INFINITY;
	bounds.width = 0;
	bounds.height = 0;
	*/
	boundL = INFINITY;
	boundT = INFINITY;
	boundR = -INFINITY;
	boundB = -INFINITY;
	lastPath = NULL;

	pathDirty = false;
	textFormatDirty = false;

#pragma warning(default: 4056 4756)
}

void VectorGraphics::inflateBounds(Loom2D::Rectangle r) {
	lmLogWarn(gGFXLogGroup, "inflateBounds x:%f y:%f w:%f h%f", r.x, r.y, r.width, r.height);
	boundL = fminf(r.x, boundL);
	boundT = fminf(r.y, boundT);
	boundR = fmaxf(r.x + r.width, boundR);
	boundB = fmaxf(r.y + r.height, boundB);
}

void VectorGraphics::lineStyle(float thickness, unsigned int color, float alpha, bool pixelHinting, utString scaleMode, utString caps, utString joints, float miterLimit) {

	const char* t;

	t = scaleMode.c_str();
	VectorLineScaleMode::Enum scaleModeEnum =
		!strcmp(t, "normal") ? VectorLineScaleMode::NORMAL :
		!strcmp(t, "none") ? VectorLineScaleMode::NONE :
		VectorLineScaleMode::NORMAL;

	t = caps.c_str();
	VectorLineCaps::Enum capsEnum =
		!strcmp(t, "round") ? VectorLineCaps::ROUND :
		!strcmp(t, "square") ? VectorLineCaps::SQUARE :
		!strcmp(t, "none") ? VectorLineCaps::NONE :
		VectorLineCaps::ROUND;

	t = joints.c_str();
	VectorLineJoints::Enum jointsEnum =
		!strcmp(t, "round") ? VectorLineJoints::ROUND :
		!strcmp(t, "bevel") ? VectorLineJoints::BEVEL :
		!strcmp(t, "miter") ? VectorLineJoints::MITER :
		VectorLineJoints::ROUND;

	queue->push_back(lmNew(NULL) VectorLineStyle(thickness, color, alpha, scaleModeEnum, capsEnum, jointsEnum, miterLimit));
	restartPath();
}

void VectorGraphics::textFormat(VectorTextFormat format) {
	ensureTextFormat();
	queue->push_back(lmNew(NULL) VectorTextFormatData(lmNew(NULL) VectorTextFormat(format)));
	currentTextFormat = format;
}

void VectorGraphics::beginFill(unsigned int color, float alpha) {
	queue->push_back(lmNew(NULL) VectorFill(color, alpha));
	restartPath();
}

void VectorGraphics::endFill() {
	queue->push_back(lmNew(NULL) VectorFill());
	restartPath();
}


void VectorGraphics::moveTo(float x, float y) {
	getPath()->moveTo(x, y);
	inflateBounds(Loom2D::Rectangle(x, y, 0, 0));
}

void VectorGraphics::lineTo(float x, float y) {
	getPath()->lineTo(x, y);
	inflateBounds(Loom2D::Rectangle(x, y, 0, 0));
}

void VectorGraphics::curveTo(float controlX, float controlY, float anchorX, float anchorY) {
	getPath()->curveTo(controlX, controlY, anchorX, anchorY);
	inflateBounds(Loom2D::Rectangle(controlX, controlY, 0, 0));
	inflateBounds(Loom2D::Rectangle(anchorX, anchorY, 0, 0));
}

void VectorGraphics::cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY) {
	getPath()->cubicCurveTo(controlX1, controlY1, controlX2, controlY2, anchorX, anchorY);
	inflateBounds(Loom2D::Rectangle(anchorX, anchorY, 0, 0));
	inflateBounds(Loom2D::Rectangle(controlX1, controlY1, 0, 0));
	inflateBounds(Loom2D::Rectangle(controlX2, controlY2, 0, 0));
}

void VectorGraphics::arcTo(float controlX, float controlY, float anchorX, float anchorY, float radius) {
	getPath()->arcTo(controlX, controlY, anchorX, anchorY, radius);
	inflateBounds(Loom2D::Rectangle(anchorX, anchorY, 0, 0));
	inflateBounds(Loom2D::Rectangle(controlX, controlY, 0, 0));
}


void VectorGraphics::drawCircle(float x, float y, float radius) {
	addShape(lmNew(NULL) VectorShape(CIRCLE, x, y, radius));
	inflateBounds(Loom2D::Rectangle(x - radius, y - radius, 2 * radius, 2 * radius));
}

void VectorGraphics::drawEllipse(float x, float y, float width, float height) {
	addShape(lmNew(NULL) VectorShape(ELLIPSE, x, y, width, height));
	inflateBounds(Loom2D::Rectangle(x - width, y - height, width * 2, height * 2));
}

void VectorGraphics::drawRect(float x, float y, float width, float height) {
	addShape(lmNew(NULL) VectorShape(RECT, x, y, width, height));
	inflateBounds(Loom2D::Rectangle(x, y, width, height));
}

void VectorGraphics::drawRoundRect(float x, float y, float width, float height, float ellipseWidth, float ellipseHeight) {
	addShape(lmNew(NULL) VectorShape(ROUND_RECT, x, y, width, height, ellipseWidth, ellipseHeight));
	inflateBounds(Loom2D::Rectangle(x, y, width, height));
}

void VectorGraphics::drawRoundRectComplex(float x, float y, float width, float height, float topLeftRadius, float topRightRadius, float bottomLeftRadius, float bottomRightRadius) {
	addShape(lmNew(NULL) VectorShape(ROUND_RECT_COMPLEX, x, y, width, height, topLeftRadius, topRightRadius, bottomLeftRadius, bottomRightRadius));
	inflateBounds(Loom2D::Rectangle(x, y, width, height));
}

void VectorGraphics::drawArc(float x, float y, float radius, float angleFrom, float angleTo, int direction) {
	addShape(lmNew(NULL) VectorShape(direction == VectorWinding::CW ? ARC_CW : ARC_CCW, x, y, radius, angleFrom, angleTo));
	// This could be further calculated if needed,
	// right now it inflates like it's an entire circle
	inflateBounds(Loom2D::Rectangle(x - radius, y - radius, 2 * radius, 2 * radius));
}

void VectorGraphics::drawTextLine(float x, float y, utString text) {
	ensureTextFormat();
	queue->push_back(lmNew(NULL) VectorText(x, y, NAN, lmNew(NULL) utString(text)));
	inflateBounds(textLineBounds(currentTextFormat, x, y, text));
}

void VectorGraphics::drawTextBox(float x, float y, float width, utString text) {
	ensureTextFormat();
	queue->push_back(lmNew(NULL) VectorText(x, y, width, lmNew(NULL) utString(text)));
	inflateBounds(textBoxBounds(currentTextFormat, x, y, width, text));
}

Loom2D::Rectangle VectorGraphics::textLineBounds(VectorTextFormat format, float x, float y, utString text) {
	return VectorRenderer::textLineBounds(&format, x, y, &text);
}

float VectorGraphics::textLineAdvance(VectorTextFormat format, float x, float y, utString text) {
	return VectorRenderer::textLineAdvance(&format, x, y, &text);
}

Loom2D::Rectangle VectorGraphics::textBoxBounds(VectorTextFormat format, float x, float y, float width, utString text) {
	return VectorRenderer::textBoxBounds(&format, x, y, width, &text);
}

void VectorGraphics::ensureTextFormat() {
	if (!textFormatDirty) {
		textFormatDirty = true;
		// Default text format
		VectorTextFormat* format = lmNew(NULL) VectorTextFormat();
		format->color = 0x000000;
		format->size = 12;
		format->align = VectorTextFormat::ALIGN_TOP | VectorTextFormat::ALIGN_LEFT;
		queue->push_back(lmNew(NULL) VectorTextFormatData(format));
		currentTextFormat = *format;
	}
}

void VectorGraphics::drawSVG(VectorSVG* svg, float x, float y, float scale, float lineThickness) {
	queue->push_back(lmNew(NULL) VectorSVGData(svg, x, y, scale, lineThickness));
	restartPath();
	inflateBounds(Loom2D::Rectangle(x, y, svg->getWidth() * scale, svg->getHeight() * scale));
}





/*************************
        RENDERING
*************************/

void VectorGraphics::render(Loom2D::RenderState* renderStatePointer, Loom2D::Matrix* transform) {
    LOOM_PROFILE_SCOPE(vectorRender);

    QuadRenderer::submit();

    Loom2D::RenderState &renderState = *renderStatePointer;

    VectorRenderer::beginFrame();
    VectorRenderer::preDraw(transform->a, transform->b, transform->c, transform->d, transform->tx, transform->ty);

    scale = sqrt(transform->a*transform->a + transform->b*transform->b + transform->c*transform->c + transform->d*transform->d);

    if (clipWidth != -1 && clipHeight != -1)
    {
        Loom2D::Matrix    res;
        Loom2D::Rectangle clipBounds = Loom2D::Rectangle((float)clipX, (float)clipY, (float)clipWidth, (float)clipHeight);
        Loom2D::Rectangle clipResult;
        Loom2D::DisplayObject::transformBounds(transform, &clipBounds, &clipResult);

        if (!renderState.isClipping()) {
            renderState.clipRect = Loom2D::Rectangle(clipResult);
        }
        else
        {
            renderState.clipRect.clip(clipResult.x, clipResult.y, clipResult.width, clipResult.height);
        }
    }

    if (renderState.isClipping()) VectorRenderer::setClipRect((int)renderState.clipRect.x, (int)renderState.clipRect.y, (int)renderState.clipRect.width, (int)renderState.clipRect.height);

    resetStyle();

    flushPath();

    LOOM_PROFILE_START(vectorRenderData);
    utArray<VectorData*>::Iterator it = queue->iterator();
    while (it.hasMoreElements()) {
        VectorData* d = it.getNext();
        d->render(this);
    }
    flushPath();
    LOOM_PROFILE_END(vectorRenderData);

    if (renderState.isClipping()) {
        VectorRenderer::resetClipRect();
    }

    VectorRenderer::postDraw();
    VectorRenderer::endFrame();
}

void VectorPath::render(VectorGraphics* g) {
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
			VectorRenderer::moveTo(x, y);
			break;
		case LINE_TO:
			x = data[di++];
			y = data[di++];
			VectorRenderer::lineTo(x, y);
			break;
		case CURVE_TO:
			c1x = data[di++];
			c1y = data[di++];
			x = data[di++];
			y = data[di++];
			VectorRenderer::curveTo(c1x, c1y, x, y);
			break;
		case CUBIC_CURVE_TO:
			c1x = data[di++];
			c1y = data[di++];
			c2x = data[di++];
			c2y = data[di++];
			x = data[di++];
			y = data[di++];
			VectorRenderer::cubicCurveTo(c1x, c1y, c2x, c2y, x, y);
			break;
		case ARC_TO:
			c1x = data[di++];
			c1y = data[di++];
			x = data[di++];
			y = data[di++];
			r = data[di++];
			VectorRenderer::arcTo(c1x, c1y, x, y, r);
			break;
		}
	}

	g->pathDirty = true;
}

void VectorShape::render(VectorGraphics* g) {
	if (!g->isStyleVisible()) return;
	switch (type) {
		case CIRCLE:     VectorRenderer::circle(x, y, a); break;
		case ELLIPSE:    VectorRenderer::ellipse(x, y, a, b); break;
		case RECT:       VectorRenderer::rect(x, y, a, b); break;
		case ROUND_RECT: VectorRenderer::roundRect(x, y, a, b, c, d); break;
		case ROUND_RECT_COMPLEX: VectorRenderer::roundRectComplex(x, y, a, b, c, d, e, f); break;
		case ARC_CW:     VectorRenderer::arc(x, y, a, b, c, VectorWinding::CW); break;
		case ARC_CCW:    VectorRenderer::arc(x, y, a, b, c, VectorWinding::CCW); break;
	}
	g->pathDirty = true;
}

void VectorLineStyle::render(VectorGraphics* g) {
	g->flushPath();
	copyTo(&g->currentLineStyle);
}

void VectorFill::render(VectorGraphics* g) {
	g->flushPath();
	g->currentFill.active = active;
	g->currentFill.color = color;
	g->currentFill.alpha = alpha;
}

void VectorText::render(VectorGraphics* g) {
	if (isnan(width)) {
		VectorRenderer::textLine(x, y, text);
	} else {
		VectorRenderer::textBox(x, y, width, text);
	}
}

void VectorTextFormatData::render(VectorGraphics* g) {
	VectorRenderer::textFormat(format);
}
VectorTextFormatData::~VectorTextFormatData() {
	lmDelete(NULL, this->format);
}

void VectorSVGData::render(VectorGraphics* g) {
	g->flushPath();
	VectorRenderer::svg(image, x, y, scale, lineThickness);
}



/*******************
        MISC
********************/


void VectorGraphics::setClipRect(int x, int y, int w, int h) {
    clipX = x;
    clipY = y;
    clipWidth = w;
    clipHeight = h;
}

void VectorLineStyle::reset() {
	thickness = NAN;
	color = 0x000000;
	alpha = 1;
	scaleMode = VectorLineScaleMode::NORMAL;
	caps = VectorLineCaps::ROUND;
	joints = VectorLineJoints::ROUND;
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



VectorPath* VectorGraphics::getPath() {
	VectorPath* path = lastPath;
	if (path == NULL) {
		path = queue->empty() ? NULL : dynamic_cast<VectorPath*>(queue->back());
		if (path == NULL) {
			path = lmNew(NULL) VectorPath();
			path->moveTo(0, 0);
			inflateBounds(Loom2D::Rectangle(0, 0, 0, 0));
			queue->push_back(path);
		}
		lastPath = path;
	}
	return path;
}

void VectorGraphics::addShape(VectorShape *shape) {
	queue->push_back(shape);
	restartPath();
}

bool VectorGraphics::isStyleVisible() {
	bool stroke = !isnan(currentLineStyle.thickness);
	bool fill = currentFill.active;
	return stroke || fill;
}

void VectorGraphics::flushPath() {
	bool stroke = !isnan(currentLineStyle.thickness);
	if (stroke && pathDirty) {
		float thicknessScale = 1.0f;
		switch (currentLineStyle.scaleMode) {
			case VectorLineScaleMode::NONE: thicknessScale = 1/scale; break;
		}
		VectorRenderer::strokeWidth(currentLineStyle.thickness*thicknessScale);
		VectorRenderer::strokeColor(currentLineStyle.color, currentLineStyle.alpha);
		VectorRenderer::lineCaps(currentLineStyle.caps);
		VectorRenderer::lineJoints(currentLineStyle.joints);
		VectorRenderer::lineMiterLimit(currentLineStyle.miterLimit);
		VectorRenderer::renderStroke();
	}
	bool fill = currentFill.active;
	if (fill && pathDirty) {
		VectorRenderer::fillColor(currentFill.color, currentFill.alpha);
		VectorRenderer::renderFill();
		currentFill.active = false;
	}
	pathDirty = false;
	VectorRenderer::clearPath();
}

void VectorGraphics::restartPath() {
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

void VectorGraphics::resetStyle() {
	currentLineStyle.reset();
	currentFill.reset();
}

#pragma warning(disable: 4056 4756)
Loom2D::Rectangle VectorGraphics::getBounds() {
	//float* bounds = VectorRenderer::getBounds();
	//return Loom2D::Rectangle(bounds[0], bounds[1], bounds[2], bounds[3]);
	if (boundL == INFINITY || boundT == INFINITY || boundR == -INFINITY || boundB == -INFINITY) return Loom2D::Rectangle(0.f, 0.f, 0.f, 0.f);
	return Loom2D::Rectangle(boundL, boundT, boundR-boundL, boundB-boundT);
#pragma warning(default: 4056 4756)
}

}
