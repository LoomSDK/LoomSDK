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

//#include <math.h>
//#define HAVE_M_PI

#include <string.h>
#include <stdint.h>

#include "loom/common/core/log.h"
#include "loom/common/core/allocator.h"

#include "loom/common/core/assert.h"
#include "loom/graphics/gfxMath.h"
#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/graphics/gfxStateManager.h"
#include "loom/script/runtime/lsProfiler.h"

#include "stdio.h"

namespace GFX
{
lmDefineLogGroup(gGFXQuadRendererLogGroup, "GFXQuadRenderer", 1, LoomLogInfo);

static GLuint sProgramPosColorTex;
static GLuint sProgramPosTex;

static GLuint sProgram_posAttribLoc;
static GLuint sProgram_posColorLoc;
static GLuint sProgram_posTexCoordLoc;
static GLuint sProgram_texUniform;
static GLuint sProgram_mvp;

static GLuint sSrcBlend = GL_SRC_ALPHA;
static GLuint sDstBlend = GL_ONE_MINUS_SRC_ALPHA;

GLuint QuadRenderer::indexBufferId;
GLuint QuadRenderer::vertexBufferId;
VertexPosColorTex* QuadRenderer::batchedVertices;
size_t QuadRenderer::batchedVertexCount;
TextureID QuadRenderer::currentTexture;

int QuadRenderer::numFrameSubmit;

static loom_allocator_t *gQuadMemoryAllocator = NULL;
static bool sShaderStateValid = false;
static bool sTextureStateValid = false;
static bool sBlendStateValid = false;

void QuadRenderer::submit()
{
    LOOM_PROFILE_SCOPE(quadSubmit);

    if (batchedVertexCount <= 0)
    {
        return;
    }

    numFrameSubmit++;

    TextureInfo &tinfo = *Texture::getTextureInfo(currentTexture);

    if (tinfo.handle != -1)
    {
        if (tinfo.visible) {

            // On iPad 1, the PosColorTex shader, which multiplies texture color with
            // vertex color, is 5x slower than PosTex, which just draws the texture
            // unmodified. So we select the shader to use appropriately.

            //lmLogInfo(gGFXQuadRendererLogGroup, "Handle > %u", tinfo.handle);

            if (!Graphics_IsGLStateValid(GFX_OPENGL_STATE_QUAD))
            {
                sShaderStateValid = false;
                sTextureStateValid = false;
                sBlendStateValid = false;
            }
            
            Graphics::context()->glBindBuffer(GL_ARRAY_BUFFER, vertexBufferId);
            
            if (!sShaderStateValid)
            {
                // Select the shader.
                Graphics::context()->glUseProgram(sProgramPosColorTex);

                Graphics::context()->glEnableVertexAttribArray(sProgram_posAttribLoc);
                Graphics::context()->glEnableVertexAttribArray(sProgram_posColorLoc);
                Graphics::context()->glEnableVertexAttribArray(sProgram_posTexCoordLoc);
            
                Graphics::context()->glVertexAttribPointer(sProgram_posAttribLoc,
                                                           3, GL_FLOAT, false,
                                                           sizeof(VertexPosColorTex), (void*)offsetof(VertexPosColorTex, x));

                Graphics::context()->glVertexAttribPointer(sProgram_posColorLoc,
                                                           4, GL_UNSIGNED_BYTE, true,
                                                           sizeof(VertexPosColorTex), (void*)offsetof(VertexPosColorTex, abgr));

                Graphics::context()->glVertexAttribPointer(sProgram_posTexCoordLoc,
                                                           2, GL_FLOAT, false,
                                                           sizeof(VertexPosColorTex), (void*)offsetof(VertexPosColorTex, u));

                Graphics::context()->glUniform1i(sProgram_texUniform, 0);
                Graphics::context()->glUniformMatrix4fv(sProgram_mvp, 1, GL_FALSE, Graphics::getMVP());

                sShaderStateValid = true;
            }
            
            if (!sTextureStateValid)
            {
                // Set up texture state.
                Graphics::context()->glActiveTexture(GL_TEXTURE0);
                Graphics::context()->glBindTexture(GL_TEXTURE_2D, tinfo.handle);

                if (tinfo.clampOnly) {
                    tinfo.wrapU = TEXTUREINFO_WRAP_CLAMP;
                    tinfo.wrapV = TEXTUREINFO_WRAP_CLAMP;
                }

                switch (tinfo.wrapU)
                {
                    case TEXTUREINFO_WRAP_CLAMP:
                        Graphics::context()->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                        break;
                    case TEXTUREINFO_WRAP_MIRROR:
                        Graphics::context()->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
                        break;
                    case TEXTUREINFO_WRAP_REPEAT:
                        Graphics::context()->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
                        break;
                    default:
                        lmAssert(false, "Unsupported wrapU: %d", tinfo.wrapU);
                }
                switch (tinfo.wrapV)
                {
                    case TEXTUREINFO_WRAP_CLAMP:
                        Graphics::context()->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                        break;
                    case TEXTUREINFO_WRAP_MIRROR:
                        Graphics::context()->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
                        break;
                    case TEXTUREINFO_WRAP_REPEAT:
                        Graphics::context()->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
                        break;
                    default:
                        lmAssert(false, "Unsupported wrapV: %d", tinfo.wrapV);
                }
                //*/

                switch (tinfo.smoothing)
                {
                    case TEXTUREINFO_SMOOTHING_NONE:
                        Graphics::context()->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, tinfo.mipmaps ? GL_NEAREST_MIPMAP_NEAREST : GL_NEAREST);
                        Graphics::context()->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
                        break;
                    case TEXTUREINFO_SMOOTHING_BILINEAR:
                        Graphics::context()->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, tinfo.mipmaps ? GL_LINEAR_MIPMAP_LINEAR : GL_LINEAR);
                        Graphics::context()->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                        break;
                    default:
                        lmAssert(false, "Unsupported smoothing: %d", tinfo.smoothing);
                }
                
                sTextureStateValid = true;
            }

            if (!sBlendStateValid)
            {
                // Blend mode.
                Graphics::context()->glEnable(GL_BLEND);
                Graphics::context()->glBlendFuncSeparate(sSrcBlend, sDstBlend, sSrcBlend, sDstBlend);

                sBlendStateValid = true;
            }
            
            Graphics_SetCurrentGLState(GFX_OPENGL_STATE_QUAD);
            
            // Setting the buffer to null supposedly enables better performance because it enables the driver to do some optimizations.
            Graphics::context()->glBufferData(GL_ARRAY_BUFFER, batchedVertexCount*sizeof(VertexPosColorTex), NULL, GL_STREAM_DRAW);
            Graphics::context()->glBufferData(GL_ARRAY_BUFFER, batchedVertexCount*sizeof(VertexPosColorTex), batchedVertices, GL_STREAM_DRAW);

            // And bind indices and draw.
            Graphics::context()->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferId);
            Graphics::context()->glDrawElements(GL_TRIANGLES,
                                                (GLsizei)(batchedVertexCount / 4 * 6), GL_UNSIGNED_SHORT,
                                                nullptr);
        }
    }
    
    batchedVertexCount = 0;
}


VertexPosColorTex *QuadRenderer::getQuadVertexMemory(uint16_t vertexCount, TextureID texture, uint32_t srcBlend, uint32_t dstBlend)
{
    LOOM_PROFILE_SCOPE(quadGetVertices);

    if (!vertexCount || (texture < 0) || (vertexCount > MAXBATCHQUADS * 4))
    {
        return NULL;
    }

#ifdef LOOM_DEBUG
    loom_mutex_lock(Texture::sTexInfoLock);
    lmAssert(!(vertexCount % 4), "numVertices % 4 != 0");
    lmAssert(texture == Texture::getTextureInfo(texture)->id, "Texture ID signature mismatch, you might be trying to draw a disposed texture");
    loom_mutex_unlock(Texture::sTexInfoLock);
    lmAssert(batchedVertices, "batchedVertices should not be null");
#endif

    bool doSubmit = false;

    if (currentTexture != TEXTUREINVALID && currentTexture != texture)
        doSubmit = true;

    if (srcBlend != sSrcBlend ||
        dstBlend != sDstBlend)
        doSubmit = true;

    if ((batchedVertexCount + vertexCount) > MAXBATCHQUADS * 4)
        doSubmit = true;

    if (doSubmit)
        submit();

    if (currentTexture != TEXTUREINVALID && currentTexture != texture)
        sTextureStateValid = false;

    if (srcBlend != sSrcBlend ||
        dstBlend != sDstBlend)
        sBlendStateValid = false;

    sSrcBlend = srcBlend;
    sDstBlend = dstBlend;
    currentTexture = texture;

    VertexPosColorTex *currentVertices = &batchedVertices[batchedVertexCount];
    batchedVertexCount += vertexCount;
    return currentVertices;
}


void QuadRenderer::batch(VertexPosColorTex *vertices, uint16_t vertexCount, TextureID texture, uint32_t srcBlend, uint32_t dstBlend)
{
    LOOM_PROFILE_SCOPE(quadBatch);

    VertexPosColorTex *vertexPtr = getQuadVertexMemory(vertexCount, texture, srcBlend, dstBlend);

    if (!vertexPtr)
        return;

    memcpy((void *)vertexPtr, (void *)vertices, sizeof(VertexPosColorTex) * vertexCount);
}


void QuadRenderer::beginFrame()
{
    LOOM_PROFILE_SCOPE(quadBegin);

    batchedVertexCount     = 0;
    currentTexture         = TEXTUREINVALID;

    sTextureStateValid = false;
    sBlendStateValid = false;
    sShaderStateValid = false;

    numFrameSubmit = 0;
}


void QuadRenderer::endFrame()
{
    LOOM_PROFILE_SCOPE(quadEnd);
    submit();
}


void QuadRenderer::destroyGraphicsResources()
{
    // Probably do something someday.
}

void QuadRenderer::initializeGraphicsResources()
{
    LOOM_PROFILE_SCOPE(quadInit);

    lmLogInfo(gGFXQuadRendererLogGroup, "Initializing Graphics Resources");

    // Create the quad shader.
    GLuint vertShader      = Graphics::context()->glCreateShader(GL_VERTEX_SHADER);

    //GLuint fragShader      = Graphics::context()->glCreateShader(GL_FRAGMENT_SHADER);
    GLuint fragShaderColor = Graphics::context()->glCreateShader(GL_FRAGMENT_SHADER);

    GLuint quadProg        = Graphics::context()->glCreateProgram();

    GLuint quadProgColor   = Graphics::context()->glCreateProgram();

    char vertShaderSrc[] =
    "attribute vec4 a_position;\n"
    "attribute vec4 a_color0;\n"
    "attribute vec2 a_texcoord0;\n"
    "varying vec2 v_texcoord0;\n"
    "varying vec4 v_color0;\n"
    "uniform mat4 u_mvp;\n"
    "void main()\n"
    "{\n"
    "    gl_Position = u_mvp * a_position;\n"
    "    v_color0 = a_color0;\n"
    "    v_texcoord0 = a_texcoord0;\n"
    "}\n";
    const int vertShaderLen = sizeof(vertShaderSrc);
    GLchar *vertShaderPtr = &vertShaderSrc[0];

    /*
    */

    char fragShaderColorSrc[] =
#if LOOM_RENDERER_OPENGLES2      
        "precision mediump float;\n"
#endif
        "uniform sampler2D u_texture;\n"
        "varying vec2 v_texcoord0;\n"
        "varying vec4 v_color0\n;"
        "void main()\n"
        "{\n"
        "    gl_FragColor = v_color0 * texture2D(u_texture, v_texcoord0);\n"
        "}\n";
    const int fragShaderColorLen = sizeof(fragShaderColorSrc);
    GLchar *fragShaderColorPtr = &fragShaderColorSrc[0];

    Graphics::context()->glShaderSource(vertShader, 1, &vertShaderPtr, &vertShaderLen);
    Graphics::context()->glCompileShader(vertShader);
    GFX_SHADER_CHECK(vertShader);

    Graphics::context()->glShaderSource(fragShaderColor, 1, &fragShaderColorPtr, &fragShaderColorLen);
    Graphics::context()->glCompileShader(fragShaderColor);
    GFX_SHADER_CHECK(fragShaderColor);

    Graphics::context()->glAttachShader(quadProgColor, fragShaderColor);
    Graphics::context()->glAttachShader(quadProgColor, vertShader);
    Graphics::context()->glLinkProgram(quadProgColor);
    GFX_PROGRAM_CHECK(quadProgColor);

    // Get attributes and uniforms.
    sProgram_posAttribLoc = Graphics::context()->glGetAttribLocation(quadProgColor, "a_position");
    sProgram_posColorLoc = Graphics::context()->glGetAttribLocation(quadProgColor, "a_color0");
    sProgram_posTexCoordLoc = Graphics::context()->glGetAttribLocation(quadProgColor, "a_texcoord0");
    sProgram_texUniform = Graphics::context()->glGetUniformLocation(quadProgColor, "u_texture");
    sProgram_mvp = Graphics::context()->glGetUniformLocation(quadProgColor, "u_mvp");

    // Save program for later!
    sProgramPosColorTex = sProgramPosTex = quadProgColor;

    // create the single initial vertex buffer
    Graphics::context()->glGenBuffers(1, &vertexBufferId);
    Graphics::context()->glBindBuffer(GL_ARRAY_BUFFER, vertexBufferId);
    Graphics::context()->glBufferData(GL_ARRAY_BUFFER, MAXBATCHQUADS * 4 * sizeof(VertexPosColorTex), 0, GL_STREAM_DRAW);
    Graphics::context()->glBindBuffer(GL_ARRAY_BUFFER, 0);

    // create the single, reused index buffer
    Graphics::context()->glGenBuffers(1, &indexBufferId);
    Graphics::context()->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferId);
    uint16_t *pIndex = (uint16_t*)lmAlloc(gQuadMemoryAllocator, sizeof(unsigned short) * 6 * MAXBATCHQUADS);
    uint16_t *pStart = pIndex;

    int j = 0;
    for (int i = 0; i < 6 * MAXBATCHQUADS; i += 6, j += 4, pIndex += 6)
    {
        pIndex[0] = j;
        pIndex[1] = j + 2;
        pIndex[2] = j + 1;
        pIndex[3] = j + 1;
        pIndex[4] = j + 2;
        pIndex[5] = j + 3;
    }

    Graphics::context()->glBufferData(GL_ELEMENT_ARRAY_BUFFER, MAXBATCHQUADS * 6 * sizeof(uint16_t), pStart, GL_STREAM_DRAW);
    Graphics::context()->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    lmFree(gQuadMemoryAllocator, pStart);

    // Create the system memory buffer for quads.
    batchedVertices = static_cast<VertexPosColorTex*>(lmAlloc(gQuadMemoryAllocator, MAXBATCHQUADS * 4 * sizeof(VertexPosColorTex)));
}


void QuadRenderer::reset()
{
    LOOM_PROFILE_SCOPE(quadReset);
    destroyGraphicsResources();
    initializeGraphicsResources();
    Graphics_InvalidateGLState(GFX_OPENGL_STATE_QUAD);
}


void QuadRenderer::initialize()
{
    initializeGraphicsResources();
}
}
