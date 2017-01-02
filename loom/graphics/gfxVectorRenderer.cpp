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

#include <string.h>
#include "stdio.h"

#include "loom/common/core/log.h"
#include "loom/common/core/allocator.h"
#include "loom/common/core/assert.h"
#include "loom/common/assets/assets.h"

#include "loom/common/platform/platformIO.h"
#include "loom/common/platform/platformFont.h"

#include "loom/graphics/gfxMath.h"
#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxVectorRenderer.h"

#include "loom/script/runtime/lsProfiler.h"

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


static void* customAlloc(size_t size) { return lmAlloc(NULL, size); }
static void* customRealloc(void* mem, size_t size) { return lmRealloc(NULL, mem, size); }
static void customFree(void* mem) { lmFree(NULL, mem); }

extern SDL_Window *gSDLWindow;

namespace GFX
{
lmDefineLogGroup(gGFXVectorRendererLogGroup, "gfx.vector", 1, LoomLogInfo);

NVGcontext *nvg = NULL;

static VectorTextFormat currentTextFormat;
static lmscalar currentTextFormatAlpha;
static bool currentTextFormatApplied = false;
static int defaultFontId = VectorTextFormat::FONT_UNDEFINED;

VectorTextFormat VectorTextFormat::defaultFormat = VectorTextFormat(0x000000, 14);

utHashTable<utHashedString, utString> VectorTextFormat::loadedFonts;
int VectorRenderer::frameWidth = 0;
int VectorRenderer::frameHeight = 0;
uint8_t VectorRenderer::quality = VectorRenderer::QUALITY_ANTIALIAS | VectorRenderer::QUALITY_STENCIL_STROKES;
uint8_t VectorRenderer::tessellationQuality = 6;
utHashTable<utIntHashKey, int> VectorRenderer::imageLookup;

void VectorRenderer::setSize(int width, int height) {
    frameWidth = width;
    frameHeight = height;
}

void VectorRenderer::beginFrame()
{
    LOOM_PROFILE_SCOPE(vectorBegin);

    nvgTessLevelMax(nvg, tessellationQuality);
    nvgBeginFrame(nvg, frameWidth, frameHeight, 1);

    deleteImages();

    /*
    nvgBeginPath(nvg);
    nvgRect(nvg, 100, 100, 120, 30);
    nvgFillColor(nvg, nvgRGBA(255, 192, 0, 255));
    nvgFill(nvg);

    drawLabel(nvg, "hello fonts", 10.f, 50.f, 200.f, 200.f);
    //*/
}

void VectorRenderer::preDraw(lmscalar a, lmscalar b, lmscalar c, lmscalar d, lmscalar e, lmscalar f) {
    LOOM_PROFILE_SCOPE(vectorPreDraw);

    nvgSave(nvg);
    nvgTransform(nvg, (float) a, (float) b, (float) c, (float) d, (float) e, (float) f);

    nvgLineCap(nvg, NVG_BUTT);
    nvgLineJoin(nvg, NVG_ROUND);

    currentTextFormat = VectorTextFormat::defaultFormat;
    currentTextFormatAlpha = 1;
    currentTextFormatApplied = false;
}

void VectorRenderer::postDraw() {
    LOOM_PROFILE_SCOPE(vectorPostDraw);

    nvgRestore(nvg);
}

void VectorRenderer::endFrame()
{
    LOOM_PROFILE_SCOPE(vectorEnd);

    nvgEndFrame(nvg);
}

void VectorRenderer::setClipRect(int x, int y, int w, int h) {
    nvgScissorScreen(nvg, (float) x, (float) y, (float) w, (float) h);
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
    currentTextFormatApplied = false;
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

void VectorRenderer::fillTexture(TextureID id, Loom2D::Matrix transform, bool repeat, bool smooth, float alpha) {

    TextureInfo *tinfo = Texture::getTextureInfo(id);

    // Setup flags
    int flags = NVG_IMAGE_NODELETE;
    if (tinfo->mipmaps) flags |= NVG_IMAGE_GENERATE_MIPMAPS;
    if (repeat) {
        flags |= NVG_IMAGE_REPEATX;
        flags |= NVG_IMAGE_REPEATY;
    }
    if (smooth) flags |= NVG_IMAGE_BILINEAR;

    // Key based on id and flags
    utIntHashKey key = utIntHashKey(utIntHashKey(id).hash() ^ utIntHashKey(flags).hash());

    int *stored = imageLookup.get(key);
    int nvgImage;
    if (stored == NULL) {
        nvgImage = nvglCreateImageFromHandle(nvg, tinfo->getHandleID(), tinfo->width, tinfo->height, flags);
        imageLookup.insert(key, nvgImage);
    } else {
        nvgImage = *stored;
    }

    // Save transform
    float xform[6];
    nvgCurrentTransform(nvg, xform);

    // Apply fill transform
    nvgTransform(nvg, (float)transform.a, (float)transform.b, (float)transform.c, (float)transform.d, (float)transform.tx, (float)transform.ty);

    // Set paint
    nvgFillPaint(nvg, nvgImagePattern(nvg, 0.f, 0.f, (float) tinfo->width, (float) tinfo->height, 0.f, nvgImage, alpha));

    // Restore transform
    nvgSetTransform(nvg, xform);
}

void VectorRenderer::textFormat(VectorTextFormat* format, lmscalar a) {
    currentTextFormat.merge(format);
    currentTextFormatAlpha = a;
    currentTextFormatApplied = false;
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

static bool readFontFile(const char *path, void** mem, size_t* size)
{
    void* mapped;
    long mappedSize;

    bool success = platform_mapFile(path, &mapped, &mappedSize) != 0;

    if (success) {
        *mem = customAlloc(mappedSize);
        *size = mappedSize;

        memcpy(*mem, mapped, mappedSize);

        platform_unmapFile(mapped);
    }

    return success;
}


static bool readDefaultFontFaceBytes(void** mem, size_t* size)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    // Get Windows dir
    char windir[MAX_PATH];
    GetWindowsDirectoryA((LPSTR)&windir, MAX_PATH);

    // Load font file
    return readFontFile((utString(windir) + "\\Fonts\\arial.ttf").c_str(), mem, size) != 0;

    // Kept for future implementation of grabbing fonts by name
    /*
    SDL_SysWMinfo info;
    SDL_VERSION(&info.version);
    if (SDL_GetWindowWMInfo(gSDLWindow, &info)) {
    HWND windowHandle = info.info.win.window;
    HDC deviceContext = GetDC(windowHandle);
    DWORD size = GetFontData(deviceContext, 0, 0, NULL, 0);
    lmAssert(size != GDI_ERROR, "Font data retrieval failed: %d", GetLastError());
    }
    else {
    lmLogError(gGFXVectorRendererLogGroup, "Error retrieving window information: %s", SDL_GetError());
    }
    */
#elif LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
    return readFontFile("/system/fonts/DroidSans.ttf", mem, size) != 0;
#elif LOOM_PLATFORM == LOOM_PLATFORM_OSX
    return readFontFile("/Library/Fonts/Arial.ttf", mem, size) != 0;
#elif defined(LOOM_BUILD_BBB) || defined(LOOM_BUILD_RPI2)
	return readFontFile("/lib/fonts/NimbusSansL.ttf", mem, size) != 0;
#elif LOOM_PLATFORM == LOOM_PLATFORM_IOS
    return (bool)platform_fontSystemFontFromName("ArialMT", mem, (unsigned int*)size);
#elif LOOM_PLATFORM == LOOM_PLATFORM_LINUX
    FILE* pipe = popen("fc-match -f \"%{file}\"", "r");
    if (!pipe)
    {
        mem = NULL;
        size = 0;
    }
    char buffer[128];
    utString path = "";
    while (!feof(pipe))
    {
        if (fgets(buffer, 128, pipe) != NULL)
            path += buffer;
    }

    pclose(pipe);
    return readFontFile(path.c_str(), mem, size) != 0;
#else
    mem = NULL;
    size = 0;
    return false;
#endif
}

static void loadDefaultFontFace() {
    lmLogWarn(gGFXVectorRendererLogGroup, "TextFormat font face not specified, using predefined default system font");
    void* mem;
    size_t size;
    bool success = readDefaultFontFaceBytes(&mem, &size);
    if (!success) {
        defaultFontId = VectorTextFormat::FONT_DEFAULTMISSING;
        return;
    }
    int handle = nvgCreateFontMem(nvg, "__default", (unsigned char*)mem, size, true);
    if (handle == -1) {
        customFree(mem);
        defaultFontId = VectorTextFormat::FONT_DEFAULTMEMORY;
        return;
    }
    defaultFontId = handle;
}

void VectorTextFormat::ensureFontId() {
    if (fontId == VectorTextFormat::FONT_UNDEFINED) {
        int id = nvgFindFont(nvg, font.c_str());
        fontId = id >= 0 ? id : VectorTextFormat::FONT_NOTFOUND;
    }

    if (fontId == VectorTextFormat::FONT_NOTFOUND) {
        if (defaultFontId == VectorTextFormat::FONT_UNDEFINED) loadDefaultFontFace();
        fontId = defaultFontId;
    }

    if (fontId < 0) {
        if (defaultFontId != VectorTextFormat::FONT_REPORTEDERROR) {
            const char *msg;
            switch (defaultFontId) {
                case VectorTextFormat::FONT_DEFAULTMISSING: msg = "Missing default system font face (load error or unsupported platform)"; break;
                case VectorTextFormat::FONT_DEFAULTMEMORY:  msg = "Unable to create default font face memory"; break;
                default:                                    msg = "Unknown error"; break;
            }
            lmLogError(gGFXVectorRendererLogGroup, "TextFormat font error: %s", msg);
            defaultFontId = VectorTextFormat::FONT_REPORTEDERROR;
        }
        return;
    }
}

static void applyTextFormat(VectorTextFormat *format, lmscalar alpha) {
    format->ensureFontId();

    if (format->fontId >= 0) nvgFontFaceId(nvg, format->fontId);

    if (format->color >= 0) {
        unsigned int rgb = format->color;
        float cr = ((rgb >> 16) & 0xff) / 255.0f;
        float cg = ((rgb >> 8) & 0xff) / 255.0f;
        float cb = ((rgb >> 0) & 0xff) / 255.0f;
        nvgFillColor(nvg, nvgRGBAf(cr, cg, cb, (float)alpha));
    }
    if (!isnan(format->size)) nvgFontSize(nvg, format->size);
    if (format->align != -1) nvgTextAlign(nvg, format->align);
    if (!isnan(format->letterSpacing)) nvgTextLetterSpacing(nvg, format->letterSpacing);
    if (!isnan(format->lineHeight)) nvgTextLineHeight(nvg, format->lineHeight);

    currentTextFormatApplied = false;
}

void VectorRenderer::ensureTextFormat() {
    if (currentTextFormatApplied) return;
    applyTextFormat(&currentTextFormat, currentTextFormatAlpha);
    currentTextFormatApplied = true;
}

void VectorRenderer::textLine(float x, float y, utString* string) {
    ensureTextFormat();
    nvgText(nvg, x, y, string->c_str(), NULL);
}

void VectorRenderer::textBox(float x, float y, float width, utString* string) {
    ensureTextFormat();
    nvgTextBox(nvg, x, y, width, string->c_str(), NULL);
}

Loom2D::Rectangle VectorRenderer::textLineBounds(VectorTextFormat* format, float x, float y, utString* string) {
    float bounds[4];
    nvgSave(nvg);
    nvgReset(nvg);
    applyTextFormat(format, 1);
    nvgTextBounds(nvg, x, y, string->c_str(), NULL, bounds);
    nvgRestore(nvg);
    float xmin = bounds[0];
    float ymin = bounds[1];
    float xmax = bounds[2];
    float ymax = bounds[3];
    return Loom2D::Rectangle(xmin, ymin, xmax-xmin, ymax-ymin);
}

float VectorRenderer::textLineAdvance(VectorTextFormat* format, float x, float y, utString* string) {
    nvgSave(nvg);
    nvgReset(nvg);
    applyTextFormat(format, 1);
    float advance = nvgTextBounds(nvg, x, y, string->c_str(), NULL, NULL);
    nvgRestore(nvg);
    return advance;
}

Loom2D::Rectangle VectorRenderer::textBoxBounds(VectorTextFormat* format, float x, float y, float width, utString* string) {
    float bounds[4];
    nvgSave(nvg);
    nvgReset(nvg);
    applyTextFormat(format, 1);
    nvgTextBoxBounds(nvg, x, y, width, string->c_str(), NULL, bounds);
    nvgRestore(nvg);
    float xmin = bounds[0];
    float ymin = bounds[1];
    float xmax = bounds[2];
    float ymax = bounds[3];
    return Loom2D::Rectangle(xmin, ymin, xmax - xmin, ymax - ymin);
}

void VectorRenderer::svg(VectorSVG* image, float x, float y, float scale, float lineThickness, float alpha) {
    image->render(x, y, scale, lineThickness, alpha);
}

void VectorRenderer::deleteImages()
{
    if (nvg != NULL)
    {
        for (UTsize i = 0; i < imageLookup.size(); i++) {
            nvgDeleteImage(nvg, imageLookup.at(i));
        }
    }
    imageLookup.clear();
}

void VectorRenderer::destroyGraphicsResources()
{
    deleteImages();
    if (nvg != NULL) {

#ifdef LOOM_RENDERER_OPENGLES2
        nvgDeleteGLES2(nvg);
#else
        nvgDeleteGL2(nvg);
#endif

        currentTextFormatApplied = false;
        defaultFontId = -1;

        nvg = NULL;
    }
}


void VectorRenderer::initializeGraphicsResources()
{
    LOOM_PROFILE_SCOPE(vectorInit);
    destroyGraphicsResources();

    int flags = 0;

    if (quality & QUALITY_ANTIALIAS) flags |= NVG_ANTIALIAS;
    if (quality & QUALITY_STENCIL_STROKES)   flags |= NVG_STENCIL_STROKES;

#if GFX_OPENGL_CHECK
    flags |= NVG_DEBUG;
#endif

#ifdef LOOM_RENDERER_OPENGLES2
    nvg = nvgCreateGLES2(flags);
#else
    nvg = nvgCreateGL2(flags);
#endif

    lmAssert(nvg != NULL, "Unable to init nanovg");

    VectorTextFormat::restoreLoaded();

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

void VectorTextFormat::restoreLoaded() {
    utHashTableIterator< utHashTable<utHashedString, utString> > it = loadedFonts.iterator();
    while (it.hasMoreElements()) {
        utHashEntry<utHashedString, utString> s = it.getNext();
        load(s.second, s.first.str());
    }
    defaultFontId = -1;
}

void VectorTextFormat::load(utString fontName, utString filePath) {
    loadedFonts.insert(utHashedString(filePath), utString(fontName));
    void* bytes = loom_asset_lock(filePath.c_str(), LATText, 1);
    nvgCreateFontMem(nvg, fontName.c_str(), static_cast<unsigned char*>(bytes), 0, 0);
    loom_asset_unlock(filePath.c_str());
}

void VectorTextFormat::merge(VectorTextFormat* source) {
    if (source->font.size() > 0) {
        font = source->font;
        fontId = VectorTextFormat::FONT_UNDEFINED;
    }
    if (source->color >= 0) color = source->color;
    if (!isnan(source->size)) size = source->size;
    if (source->align != -1) align = source->align;
    if (!isnan(source->letterSpacing)) letterSpacing = source->letterSpacing;
    if (!isnan(source->lineHeight)) lineHeight = source->lineHeight;
}

VectorSVG::VectorSVG() {
    image = NULL;
}

VectorSVG::~VectorSVG() {
    reset();
}

void VectorSVG::reset() {
    resetInfo();
    resetImage();
}

void VectorSVG::resetInfo() {
    if (path.empty() == false) {
        loom_asset_unsubscribe(path.c_str(), onReload, this);
        path.clear();
    }
}

void VectorSVG::resetImage() {
    if (image != NULL) {
        nsvgDelete(image);
        image = NULL;
    }
}

void VectorSVG::loadFile(utString path, utString units, float dpi) {
    lmLogDebug(gGFXVectorRendererLogGroup, "Loading '%s'", path.c_str());
    reset();
    this->units = units;
    this->dpi = dpi;
    this->path = path;
    loom_asset_subscribe(this->path.c_str(), onReload, this, 1);

    // Ensure we load if it wasn't present already.
    if(!image)
        reload();
}

void VectorSVG::onReload(void *payload, const char *name) {
    VectorSVG* svg = static_cast<VectorSVG*>(payload);
    lmAssert(strncmp(svg->path.c_str(), name, svg->path.size()) == 0, "Expected svg path and reloaded path mismatch: %s %s", svg->path.c_str(), name);
    svg->reload();
}

void VectorSVG::reload() {
    resetImage();
    char* data = static_cast<char*>(loom_asset_lock(path.c_str(), LATText, true));
    parse(data, units.c_str(), dpi);
    loom_asset_unlock(path.c_str());
}

void VectorSVG::loadString(utString svg, utString units, float dpi) {
    reset();
    parse(svg.c_str(), units.c_str(), dpi);
}

void VectorSVG::parse(const char* svg, const char* units, float dpi) {
    // Parse is destructive so make a copy.
    char *svgTemp = (char*)lmAlloc(NULL, strlen(svg) + 1);
    memcpy(svgTemp, svg, strlen(svg) + 1);
    image = nsvgParse((char*) svgTemp, units, dpi);
    lmFree(NULL, svgTemp);
    if (image->shapes == NULL)
    {
        lmLogError(gGFXVectorRendererLogGroup, "Failure loading %s - no shapes.", path.c_str());
        nsvgDelete(image);
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
void VectorSVG::render(float x, float y, float scale, float lineThickness, float alpha) {
    LOOM_PROFILE_SCOPE(vectorRenderSVG);

    if (image == NULL) return;

    nvgSave(nvg);
    nvgTranslate(nvg, x, y);
    nvgScale(nvg, scale, scale);
    for (NSVGshape* shape = image->shapes; shape != NULL; shape = shape->next) {
        NSVGpaint* fill = &shape->fill;
        bool hasFill = false;
        switch (fill->type) {
            case NSVG_PAINT_COLOR:
                VectorRenderer::fillColor32(fill->color, shape->opacity * alpha);
                hasFill = true;
                break;
            case NSVG_PAINT_NONE:
            default: break;
        }
        NSVGpaint* stroke = &shape->stroke;
        bool hasStroke = false;
        switch (stroke->type) {
            case NSVG_PAINT_COLOR:
                VectorRenderer::strokeColor32(stroke->color, shape->opacity * alpha);
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
    LOOM_PROFILE_SCOPE(vectorReset);
    destroyGraphicsResources();
    initializeGraphicsResources();
}


void VectorRenderer::initialize()
{
    nvgSetAllocFunctions(customAlloc, customRealloc, customFree);
    nvgGLSetAllocFunctions(customAlloc, customRealloc, customFree);
    nsvgSetAllocFunctions(customAlloc, customRealloc, customFree);
    initializeGraphicsResources();
}

}
