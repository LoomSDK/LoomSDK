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

#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/graphics/gfxVectorGraphics.h"

namespace GFX
{





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



void VectorGraphics::clear() {
	utArray<VectorData*>::Iterator it = queue->iterator();
	while (it.hasMoreElements()) {
		VectorData* d = it.getNext();
		delete d;
	}
	queue->clear();
	lastPath = NULL;
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

	queue->push_back(new VectorLineStyle(thickness, color, alpha, scaleModeEnum, capsEnum, jointsEnum, miterLimit));
	restartPath();
}

void VectorGraphics::textFormat(VectorTextFormat format) {
	queue->push_back(new VectorTextFormatData(new VectorTextFormat(format)));
}

void VectorGraphics::beginFill(unsigned int color, float alpha) {
	queue->push_back(new VectorFill(color, alpha));
	restartPath();
}

void VectorGraphics::endFill() {
	queue->push_back(new VectorFill());
	restartPath();
}


void VectorGraphics::moveTo(float x, float y) {
	getPath()->moveTo(x, y);
}

void VectorGraphics::lineTo(float x, float y) {
	getPath()->lineTo(x, y);
}

void VectorGraphics::curveTo(float controlX, float controlY, float anchorX, float anchorY) {
	getPath()->curveTo(controlX, controlY, anchorX, anchorY);
}

void VectorGraphics::cubicCurveTo(float controlX1, float controlY1, float controlX2, float controlY2, float anchorX, float anchorY) {
	getPath()->cubicCurveTo(controlX1, controlY1, controlX2, controlY2, anchorX, anchorY);
}

void VectorGraphics::arcTo(float controlX, float controlY, float anchorX, float anchorY, float radius) {
	getPath()->arcTo(controlX, controlY, anchorX, anchorY, radius);
}


void VectorGraphics::drawCircle(float x, float y, float radius) {
	addShape(new VectorShape(CIRCLE, x, y, radius));
}

void VectorGraphics::drawEllipse(float x, float y, float width, float height) {
	addShape(new VectorShape(ELLIPSE, x, y, width, height));
}

void VectorGraphics::drawRect(float x, float y, float width, float height) {
	addShape(new VectorShape(RECT, x, y, width, height));
}

// TODO implement ellipseHeight?
void VectorGraphics::drawRoundRect(float x, float y, float width, float height, float ellipseWidth, float ellipseHeight) {
	addShape(new VectorShape(ROUND_RECT, x, y, width, height, ellipseWidth));
}

void VectorGraphics::drawArc(float x, float y, float radius, float angleFrom, float angleTo, int direction) {
	addShape(new VectorShape(direction == VectorWinding::CW ? ARC_CW : ARC_CCW, x, y, radius, angleFrom, angleTo));
}

void VectorGraphics::drawTextLabel(float x, float y, utString text) {
	queue->push_back(new VectorText(x, y, NAN, new utString(text)));
}

void VectorGraphics::drawTextBox(float x, float y, float width, utString text) {
	queue->push_back(new VectorText(x, y, width, new utString(text)));
}

void VectorGraphics::drawSVG(float x, float y, float scale, VectorSVG* svg) {
	queue->push_back(new VectorSVGData(x, y, scale, svg));
	restartPath();
}





/*************************
        RENDERING
*************************/



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
		case ROUND_RECT: VectorRenderer::roundRect(x, y, a, b, c); break;
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
	if (!active) g->flushPath();
	g->currentFill.active = active;
	g->currentFill.color = color;
	g->currentFill.alpha = alpha;
}

void VectorText::render(VectorGraphics* g) {
	if (isnan(width)) {
		VectorRenderer::textLabel(x, y, text);
	} else {
		VectorRenderer::textBox(x, y, width, text);
	}
}

void VectorTextFormatData::render(VectorGraphics* g) {
	VectorRenderer::textFormat(format);
}

void VectorSVGData::render(VectorGraphics* g) {
	g->flushPath();
	VectorRenderer::svg(x, y, scale, image);
}



/*******************
        MISC
********************/

void VectorGraphics::render(Loom2D::Matrix* transform) {
	QuadRenderer::submit();

	VectorRenderer::beginFrame();
	VectorRenderer::preDraw(transform->a, transform->b, transform->c, transform->d, transform->tx, transform->ty);

	resetStyle();

	flushPath();

	utArray<VectorData*>::Iterator it = queue->iterator();
	while (it.hasMoreElements()) {
		VectorData* d = it.getNext();
		d->render(this);
	}
	flushPath();

	VectorRenderer::postDraw();
	VectorRenderer::endFrame();
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
			path = new VectorPath();
			path->moveTo(0, 0);
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
		float scale = 1.0f;
		/*
		// TODO: reimplement
		switch (currentLineStyle.scaleMode) {
			case VectorLineScaleMode::NONE: scale = 1/sqrt(scaleX*scaleX+scaleY*scaleY); break;
		}
		*/
		VectorRenderer::strokeWidth(currentLineStyle.thickness*scale);
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

}
