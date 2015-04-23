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
#include "stdio.h"

#include "loom/common/core/log.h"
#include "loom/common/core/allocator.h"
#include "loom/common/core/assert.h"
#include "loom/common/assets/assets.h"

#include "loom/graphics/gfxMath.h"
#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxVectorRenderer.h"

#include "nanovg.h"

#ifdef LOOM_RENDERER_OPENGLES2
#define NANOVG_GLES2_IMPLEMENTATION
#else
#define NANOVG_GL2_IMPLEMENTATION
#endif

#include "nanovg_lm_gl.h"
#include "nanovg_lm_gl_utils.h"

#define NANOSVG_IMPLEMENTATION
#include "nanosvg.h"

/*
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
*/

namespace GFX
{
lmDefineLogGroup(gGFXVectorRendererLogGroup, "GFXVectorRenderer", 1, LoomLogInfo);

NVGcontext *nvg = NULL;
static int font;

int VectorRenderer::frameWidth = 0;
int VectorRenderer::frameHeight = 0;

//*
void drawLabel(struct NVGcontext* vg, const char* text, float x, float y, float w, float h)
{
	NVG_NOTUSED(w);

	nvgFontSize(vg, 30.0f);
	nvgFontFace(vg, "sans");
	nvgFillColor(vg, nvgRGBA(0, 25, 25, 128));

	nvgTextAlign(vg, NVG_ALIGN_LEFT | NVG_ALIGN_MIDDLE);
	nvgText(vg, x, y + h*0.5f, text, NULL);
}
//*/

void VectorRenderer::setSize(int width, int height) {
	frameWidth = width;
	frameHeight = height;
}

void VectorRenderer::beginFrame()
{
    nvgBeginFrame(nvg, frameWidth, frameHeight, 1);



    /*
    nvgBeginPath(nvg);
    nvgRect(nvg, 100, 100, 120, 30);
    nvgFillColor(nvg, nvgRGBA(255, 192, 0, 255));
    nvgFill(nvg);

    drawLabel(nvg, "hello fonts", 10.f, 50.f, 200.f, 200.f);
    //*/
}

void VectorRenderer::preDraw(float a, float b, float c, float d, float e, float f) {
	nvgSave(nvg);
	nvgTransform(nvg, a, b, c, d, e, f);
	
	nvgLineCap(nvg, NVG_BUTT);
	nvgLineJoin(nvg, NVG_ROUND);
}

void VectorRenderer::postDraw() {
	/*
	nvgBeginPath(nvg);
	nvgStrokeColor(nvg, nvgRGBAf(0, 1, 0, 1));
	nvgMoveTo(nvg, 150, 150);
	nvgLineTo(nvg, 250, 150);
	nvgStroke(nvg);
	
	nvgBeginPath(nvg);
	nvgStrokeColor(nvg, nvgRGBAf(1, 0, 0, 1));
	nvgMoveTo(nvg, 150, 180);
	nvgLineTo(nvg, 250, 180);
	nvgStroke(nvg);
	*/

	nvgRestore(nvg);
}

void VectorRenderer::endFrame()
{

	/*
	nvgBeginPath(nvg);
	nvgFillColor(nvg, nvgRGBAf(0, 1, 1, 1));
	nvgRect(nvg, 50, 50, 100, 100);
	nvgFill(nvg);
	*/

	//drawLabel(nvg, utf8("Hello nanovg! Pokakaj se v hlače. あなたのズボンをうんち。便便在裤子上"), 10, 50, 280, 20);

	//drawLabel(nvg, "hello!", 10, 50, 280, 20);

	nvgEndFrame(nvg);
}

void VectorRenderer::setClipRect(int x, int y, int w, int h) {
    nvgScissor(nvg, (float) x, (float) y, (float) w, (float) h);
}
void VectorRenderer::resetClipRect() {
    nvgResetScissor(nvg);
}


void VectorRenderer::clearPath() {
	nvgBeginPath(nvg);
}
void VectorRenderer::renderStroke() {
	nvgStroke(nvg);
}
void VectorRenderer::renderFill() {
	nvgFill(nvg);
}


void VectorRenderer::strokeWidth(float size) {
	nvgStrokeWidth(nvg, size);
}

void VectorRenderer::strokeColor(float r, float g, float b, float a) {
	nvgStrokeColor(nvg, nvgRGBAf(r, g, b, a));
}

void VectorRenderer::strokeColor(unsigned int rgb, float a) {
	float cr = ((rgb >> 16) & 0xff) / 255.0f;
	float cg = ((rgb >> 8) & 0xff) / 255.0f;
	float cb = ((rgb >> 0) & 0xff) / 255.0f;
	strokeColor(cr, cg, cb, a);
}

void VectorRenderer::strokeColor32(unsigned int argb, float a) {
	float ca = ((argb >> 24) & 0xff) / 255.0f;
	strokeColor(argb, a*ca);
}

void VectorRenderer::lineCaps(VectorLineCaps::Enum caps) {
	nvgLineCap(nvg, caps);
}

void VectorRenderer::lineJoints(VectorLineJoints::Enum joints) {
	nvgLineJoin(nvg, joints);
}

void VectorRenderer::lineMiterLimit(float limit) {
	nvgMiterLimit(nvg, limit);
}

void VectorRenderer::fillColor(float r, float g, float b, float a) {
	nvgFillColor(nvg, nvgRGBAf(r, g, b, a));
}

void VectorRenderer::fillColor(unsigned int rgb, float a) {
	float cr = ((rgb >> 16) & 0xff) / 255.0f;
	float cg = ((rgb >> 8) & 0xff) / 255.0f;
	float cb = ((rgb >> 0) & 0xff) / 255.0f;
	fillColor(cr, cg, cb, a);
}

void VectorRenderer::fillColor32(unsigned int argb, float a) {
	float ca = ((argb >> 24) & 0xff) / 255.0f;
	fillColor(argb, a*ca);
}

void VectorRenderer::textFormat(VectorTextFormat* format) {
	if (strlen(format->font) > 0) {
		nvgFontFace(nvg, format->font);
	}
	if (format->color >= 0) {
		unsigned int rgb = format->color;
		float cr = ((rgb >> 16) & 0xff) / 255.0f;
		float cg = ((rgb >> 8) & 0xff) / 255.0f;
		float cb = ((rgb >> 0) & 0xff) / 255.0f;
		nvgFillColor(nvg, nvgRGBAf(cr, cg, cb, 1.0));
	}
	if (!isnan(format->size)) nvgFontSize(nvg, format->size);
	if (format->align != -1) nvgTextAlign(nvg, format->align);
	if (!isnan(format->letterSpacing)) nvgTextLetterSpacing(nvg, format->letterSpacing);
	if (!isnan(format->lineHeight)) nvgTextLineHeight(nvg, format->lineHeight);
}


void VectorRenderer::moveTo(float x, float y) {
	nvgMoveTo(nvg, x, y);
}

void VectorRenderer::lineTo(float x, float y) {
	nvgLineTo(nvg, x, y);
}

void VectorRenderer::curveTo(float cx, float cy, float x, float y) {
	nvgQuadTo(nvg, cx, cy, x, y);
}

void VectorRenderer::cubicCurveTo(float c1x, float c1y, float c2x, float c2y, float x, float y) {
	nvgBezierTo(nvg, c1x, c1y, c2x, c2y, x, y);
}

void VectorRenderer::arcTo(float cx, float cy, float x, float y, float radius) {
	nvgArcTo(nvg, cx, cy, x, y, radius);
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

void VectorRenderer::roundRect(float x, float y, float width, float height, float ellipseWidth, float ellipseHeight) {
	nvgRoundedRectEllipse(nvg, x, y, width, height, ellipseWidth, ellipseHeight);
}

void VectorRenderer::roundRectComplex(float x, float y, float width, float height, float topLeftRadius, float topRightRadius, float bottomLeftRadius, float bottomRightRadius) {
	nvgRoundedRectComplex(nvg, x, y, width, height, topLeftRadius, topRightRadius, bottomLeftRadius, bottomRightRadius);
}

void VectorRenderer::arc(float x, float y, float radius, float angleFrom, float angleTo, VectorWinding::Enum direction) {
	nvgArc(nvg, x, y, radius, angleFrom, angleTo, direction);
}


void VectorRenderer::textLine(float x, float y, utString* string) {
    nvgText(nvg, x, y, string->c_str(), NULL);
}

void VectorRenderer::textBox(float x, float y, float width, utString* string) {
    nvgTextBox(nvg, x, y, width, string->c_str(), NULL);
}

Loom2D::Rectangle VectorRenderer::textLineBounds(VectorTextFormat* format, float x, float y, utString* string) {
    float* bounds = new float[4];
    nvgSave(nvg);
    nvgReset(nvg);
    textFormat(format);
    nvgTextBounds(nvg, x, y, string->c_str(), NULL, bounds);
    nvgRestore(nvg);
    float xmin = bounds[0];
    float ymin = bounds[1];
    float xmax = bounds[2];
    float ymax = bounds[3];
    delete bounds;
    return Loom2D::Rectangle(xmin, ymin, xmax-xmin, ymax-ymin);
}

float VectorRenderer::textLineAdvance(VectorTextFormat* format, float x, float y, utString* string) {
    nvgSave(nvg);
    nvgReset(nvg);
    textFormat(format);
    float advance = nvgTextBounds(nvg, x, y, string->c_str(), NULL, NULL);
    nvgRestore(nvg);
    return advance;
}

Loom2D::Rectangle VectorRenderer::textBoxBounds(VectorTextFormat* format, float x, float y, float width, utString* string) {
    float* bounds = new float[4];
    nvgSave(nvg);
    nvgReset(nvg);
    textFormat(format);
    nvgTextBoxBounds(nvg, x, y, width, string->c_str(), NULL, bounds);
    nvgRestore(nvg);
    float xmin = bounds[0];
    float ymin = bounds[1];
    float xmax = bounds[2];
    float ymax = bounds[3];
    delete bounds;
    return Loom2D::Rectangle(xmin, ymin, xmax - xmin, ymax - ymin);
}

void VectorRenderer::svg(VectorSVG* image, float x, float y, float scale, float lineThickness) {
	image->render(x, y, scale, lineThickness);
}


void VectorRenderer::destroyGraphicsResources()
{
	if (nvg != NULL) {
#ifdef LOOM_RENDERER_OPENGLES2
		nvgDeleteGLES2(nvg);
#else
        nvgDeleteGL2(nvg);
#endif
	}
}


void VectorRenderer::initializeGraphicsResources()
{
#ifdef LOOM_RENDERER_OPENGLES2
    nvg = nvgCreateGLES2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
#else
    nvg = nvgCreateGL2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
#endif
    lmAssert(nvg != NULL, "Unable to init nanovg");
    //nvgCreateFont(nvg, "sans", "assets/droidsans.ttf");
    //nvgCreateFont(nvg, "sans", "assets/SourceSansPro-Regular.ttf");
    //nvgCreateFont(nvg, "sans", "assets/unifont-7.0.06.ttf");
    //nvgCreateFont(nvg, "sans", "assets/keifont.ttf");
    //nvgCreateFont(nvg, "sans", "assets/mikachanALL.ttf");
    //nvgCreateFont(nvg, "sans", "assets/Roboto - Regular.ttf");
	//nvgCreateFont(nvg, "sans", "assets/OpenSans-Regular.ttf");

	

	//font = nvgCreateFont(nvg, "sans", "font/Pecita.otf");
	//font = nvgCreateFont(nvg, "sans", "font/Cyberbit.ttf");
}



/*
VectorFont::VectorFont(utString fontName, utString filePath) {
	this->fontName = fontName;
	this->id = nvgCreateFont(nvg, fontName.c_str(), filePath.c_str());
}
*/

VectorTextFormat::VectorTextFormat() {
    font = "";
    color = -1;
    size = NAN;
    align = -1;
    letterSpacing = NAN;
    lineHeight = NAN;
}

void VectorTextFormat::load(utString fontName, utString filePath) {
    void* bytes = loom_asset_lock(filePath.c_str(), LATText, 1);
    nvgCreateFontMem(nvg, fontName.c_str(), static_cast<unsigned char*>(bytes), 0, 0);
}


VectorSVG::VectorSVG() {
    path = NULL;
    image = NULL;
}
VectorSVG::~VectorSVG() {
	reset();
}
void VectorSVG::reset(bool reloaded) {
	if (!reloaded && path != NULL) {
		loom_asset_unsubscribe(path->c_str(), onReload, this);
		delete path;
		path = NULL;
	}
	if (image != NULL) {
		nsvgDelete(image);
		image = NULL;
	}
}
void VectorSVG::loadFile(utString path, utString units, float dpi) {
	reset();
	this->units = utString(path);
	this->dpi = dpi;
	this->path = new utString(path);
	reload();
	loom_asset_subscribe(path.c_str(), onReload, this, false);
}
void VectorSVG::onReload(void *payload, const char *name) {
	VectorSVG* svg = static_cast<VectorSVG*>(payload);
	lmAssert(strncmp(svg->path->c_str(), name, svg->path->size()) == 0, "expected svg path and reloaded path mismatch: %s %s", svg->path->c_str(), name);
	svg->reload();
}
void VectorSVG::reload() {
	reset(true);
	char* data = static_cast<char*>(loom_asset_lock(path->c_str(), LATText, true));
	parse(data, units.c_str(), dpi);
	loom_asset_unlock(path->c_str());
}
void VectorSVG::loadString(utString svg, utString units, float dpi) {
	reset();
	parse(svg.c_str(), units.c_str(), dpi);
}
void VectorSVG::parse(const char* svg, const char* units, float dpi) {
	char* copy = strdup(svg);
	image = nsvgParse(copy, units, dpi);
	delete copy;
	if (image->shapes == NULL) {
		image = NULL;
		return;
	}
}
float VectorSVG::getWidth() const {
	return image == NULL ? 0.0f : image->width;
}
float VectorSVG::getHeight() const {
	return image == NULL ? 0.0f : image->height;
}
void VectorSVG::render(float x, float y, float scale, float lineThickness) {
	if (image == NULL) return;
	nvgSave(nvg);
	nvgTranslate(nvg, x, y);
	nvgScale(nvg, scale, scale);
	for (NSVGshape* shape = image->shapes; shape != NULL; shape = shape->next) {
		NSVGpaint* fill = &shape->fill;
		bool hasFill = false;
		switch (fill->type) {
			case NSVG_PAINT_COLOR:
				VectorRenderer::fillColor32(fill->color, shape->opacity);
				hasFill = true;
				break;
			case NSVG_PAINT_NONE:
			default: break;
		}
		NSVGpaint* stroke = &shape->stroke;
		bool hasStroke = false;
		switch (stroke->type) {
			case NSVG_PAINT_COLOR:
				VectorRenderer::strokeColor32(stroke->color, shape->opacity);
				VectorRenderer::strokeWidth(lineThickness*shape->strokeWidth);
				hasStroke = true;
			default: break;
		}
		if (!hasFill && !hasStroke) continue;
		int pathind = 0;
        for (NSVGpath* path = shape->paths; path != NULL; path = path->next) {
            //if (pathind++ != 3) continue;
			if (path->npts < 1) continue;
			float winding = 0.0f;
			VectorRenderer::moveTo(path->pts[0], path->pts[1]);
			for (int i = 1; i < path->npts - 1; i += 3) {
                float* p = &path->pts[i * 2];
                winding += (p[4] - p[-2]) * (p[5] + p[-1]);
                VectorRenderer::cubicCurveTo(p[0], p[1], p[2], p[3], p[4], p[5]);
			}
            nvgPathWinding(nvg, winding < 0 ? NVG_CW : NVG_CCW);
            pathind++;
		}
		if (hasFill) VectorRenderer::renderFill();
		if (hasStroke) VectorRenderer::renderStroke();
		VectorRenderer::clearPath();
	}
	nvgRestore(nvg);
}


void VectorRenderer::reset()
{
	destroyGraphicsResources();
	initializeGraphicsResources();
}


void VectorRenderer::initialize()
{
    initializeGraphicsResources();
}

}
