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

#include <string.h>
#include "bgfx.h"
#include "nanovg.h"

#include "loom/common/core/log.h"
#include "loom/common/core/allocator.h"
#include "loom/common/core/assert.h"

#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxVectorRenderer.h"

#include "stdio.h"


#include <windows.h>
#include <wchar.h>

#if defined(_MSC_VER) && _MSC_VER > 1310
// Visual C++ 2005 and later require the source files in UTF-8, and all strings 
// to be encoded as wchar_t otherwise the strings will be converted into the 
// local multibyte encoding and cause errors. To use a wchar_t as UTF-8, these 
// strings then need to be convert back to UTF-8. This function is just a rough 
// example of how to do this.
# define utf8(str)  ConvertToUTF8(L##str)
const char * ConvertToUTF8(const wchar_t * pStr) {
	static char szBuf[1024];
	WideCharToMultiByte(CP_UTF8, 0, pStr, -1, szBuf, sizeof(szBuf), NULL, NULL);
	return szBuf;
}
#else
// Visual C++ 2003 and gcc will use the string literals as is, so the files 
// should be saved as UTF-8. gcc requires the files to not have a UTF-8 BOM.
# define utf8(str)  str
#endif




namespace GFX
{
lmDefineLogGroup(gGFXVectorRendererLogGroup, "GFXVectorRenderer", 1, LoomLogInfo);

NVGcontext *nvg = NULL;
static int font;

int VectorRenderer::frameWidth = 0;
int VectorRenderer::frameHeight = 0;

void drawLabel(struct NVGcontext* vg, const char* text, float x, float y, float w, float h)
{
	NVG_NOTUSED(w);

	nvgFontSize(vg, 30.0f);
	nvgFontFace(vg, "sans");
	nvgFillColor(vg, nvgRGBA(255, 255, 255, 128));

	nvgTextAlign(vg, NVG_ALIGN_LEFT | NVG_ALIGN_MIDDLE);
	nvgText(vg, x, y + h*0.5f, text, NULL);
}

void VectorRenderer::setSize(int width, int height) {
	frameWidth = width;
	frameHeight = height;
}

void VectorRenderer::beginFrame()
{
	nvgBeginFrame(nvg, frameWidth, frameHeight, 1, NVG_STRAIGHT_ALPHA);

	nvgSave(nvg);

	nvgLineCap(nvg, NVG_BUTT);
	nvgLineJoin(nvg, NVG_ROUND);

	nvgStrokeWidth(nvg, 10);
	nvgStrokeColor(nvg, nvgRGBA(0, 255, 0, 160));
	nvgBeginPath(nvg);
}

void VectorRenderer::preDraw(float a, float b, float c, float d, float e, float f) {
	nvgSave(nvg);
	nvgTransform(nvg, a, b, c, d, e, f);
}

void VectorRenderer::postDraw() {
	nvgRestore(nvg);
}

void VectorRenderer::endFrame()
{
	nvgStroke(nvg);

	nvgRestore(nvg);

	//drawLabel(nvg, utf8("Hello nanovg! Pokakaj se v hlače. あなたのズボンをうんち。便便在裤子上"), 10, 50, 280, 20);

	nvgEndFrame(nvg);

}



void VectorRenderer::moveTo(float x, float y) {
	nvgMoveTo(nvg, x, y);
}

void VectorRenderer::lineTo(float x, float y) {
	nvgLineTo(nvg, x, y);
}

void VectorRenderer::cubicCurveTo(float c1x, float c1y, float c2x, float c2y, float x, float y) {
	nvgBezierTo(nvg, c1x, c1y, c2x, c2y, x, y);
}

void VectorRenderer::circle(float x, float y, float radius) {
	nvgCircle(nvg, x, y, radius);
}

void VectorRenderer::ellipse(float x, float y, float width, float height) {
	nvgEllipse(nvg, x, y, width, height);
}

void VectorRenderer::rect(float x, float y, float width, float height) {
	nvgRect(nvg, x, y, width, height);
}

void VectorRenderer::roundRect(float x, float y, float width, float height, float radius) {
	nvgRoundedRect(nvg, x, y, width, height, radius);
}



void VectorRenderer::destroyGraphicsResources()
{
	if (nvg != NULL) {
		
	}
}


void VectorRenderer::initializeGraphicsResources()
{
	nvg = nvgCreate(512, 512, 1, 0);
	//font = nvgCreateFont(nvg, "sans", "font/droidsans.ttf");
	//font = nvgCreateFont(nvg, "sans", "font/Pecita.otf");
	font = nvgCreateFont(nvg, "sans", "font/Cyberbit.ttf");

	nvgFontFaceId(nvg, font);
	nvgFontSize(nvg, 30);
}


void VectorRenderer::reset()
{
	destroyGraphicsResources();
	initializeGraphicsResources();
}


void VectorRenderer::initialize()
{
}

}
