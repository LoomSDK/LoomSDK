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

static ShaderProgram* sCurrentShader;

static GLuint sSrcBlend = GL_SRC_ALPHA;
static GLuint sDstBlend = GL_ONE_MINUS_SRC_ALPHA;
static bool sBlendEnabled = true;

GLuint QuadRenderer::indexBufferId;
GLuint QuadRenderer::vertexBufferId;
VertexPosColorTex* QuadRenderer::batchedVertices;
size_t QuadRenderer::batchedVertexCount;
TextureID QuadRenderer::currentTexture;

int QuadRenderer::numFrameSubmit;

static loom_allocator_t *gQuadMemoryAllocator = NULL;
static bool sTextureStateValid = false;
static bool sBlendStateValid = false;
static bool sShaderStateValid = false;

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

            GL_Context* ctx = Graphics::context();

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
            
            ctx->glBindBuffer(GL_ARRAY_BUFFER, vertexBufferId);
            
            if (!sShaderStateValid)
            {
                Loom2D::Matrix mvp;
                mvp.copyFromMatrix4(Graphics::getMVP());
                sCurrentShader->setMVP(mvp);
                sCurrentShader->setTextureId(0);
                sCurrentShader->bind();

                sShaderStateValid = true;
            }
            
            if (!sTextureStateValid)
            {
                // Set up texture state.
                ctx->glActiveTexture(GL_TEXTURE0);
                ctx->glBindTexture(GL_TEXTURE_2D, tinfo.handle);

                if (tinfo.clampOnly) {
                    tinfo.wrapU = TEXTUREINFO_WRAP_CLAMP;
                    tinfo.wrapV = TEXTUREINFO_WRAP_CLAMP;
                }

                switch (tinfo.wrapU)
                {
                    case TEXTUREINFO_WRAP_CLAMP:
                        ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                        break;
                    case TEXTUREINFO_WRAP_MIRROR:
                        ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
                        break;
                    case TEXTUREINFO_WRAP_REPEAT:
                        ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
                        break;
                    default:
                        lmAssert(false, "Unsupported wrapU: %d", tinfo.wrapU);
                }
                switch (tinfo.wrapV)
                {
                    case TEXTUREINFO_WRAP_CLAMP:
                        ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                        break;
                    case TEXTUREINFO_WRAP_MIRROR:
                        ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
                        break;
                    case TEXTUREINFO_WRAP_REPEAT:
                        ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
                        break;
                    default:
                        lmAssert(false, "Unsupported wrapV: %d", tinfo.wrapV);
                }
                //*/

                switch (tinfo.smoothing)
                {
                    case TEXTUREINFO_SMOOTHING_NONE:
                        ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, tinfo.mipmaps ? GL_NEAREST_MIPMAP_NEAREST : GL_NEAREST);
                        ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
                        break;
                    case TEXTUREINFO_SMOOTHING_BILINEAR:
                        ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, tinfo.mipmaps ? GL_LINEAR_MIPMAP_LINEAR : GL_LINEAR);
                        ctx->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                        break;
                    default:
                        lmAssert(false, "Unsupported smoothing: %d", tinfo.smoothing);
                }
                
                sTextureStateValid = true;
            }

            if (!sBlendStateValid)
            {
                if (sBlendEnabled)
                {
                    ctx->glEnable(GL_BLEND);
                    ctx->glBlendFuncSeparate(sSrcBlend, sDstBlend, sSrcBlend, sDstBlend);
                }
                else
                {
                    ctx->glDisable(GL_BLEND);
                }

                sBlendStateValid = true;
            }
            
            Graphics_SetCurrentGLState(GFX_OPENGL_STATE_QUAD);
            
            // Setting the buffer to null supposedly enables better performance because it enables the driver to do some optimizations.
            ctx->glBufferData(GL_ARRAY_BUFFER, batchedVertexCount*sizeof(VertexPosColorTex), NULL, GL_STREAM_DRAW);
            ctx->glBufferData(GL_ARRAY_BUFFER, batchedVertexCount*sizeof(VertexPosColorTex), batchedVertices, GL_STREAM_DRAW);

            // And bind indices and draw.
            ctx->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferId);
            ctx->glDrawElements(GL_TRIANGLES,
                                                (GLsizei)(batchedVertexCount / 4 * 6), GL_UNSIGNED_SHORT,
                                                nullptr);
        }
    }
    
    batchedVertexCount = 0;
}


VertexPosColorTex *QuadRenderer::getQuadVertexMemory(uint16_t vertexCount, TextureID texture, bool blendEnabled, uint32_t srcBlend, uint32_t dstBlend, ShaderProgram *shader)
{
    LOOM_PROFILE_SCOPE(quadGetVertices);

    if (!vertexCount || (texture < 0) || (vertexCount > MAXBATCHQUADS * 4) || shader == nullptr)
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

    if (sCurrentShader != NULL && *sCurrentShader != *shader)
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

    if (sCurrentShader != NULL && *sCurrentShader != *shader)
        sShaderStateValid = false;

    if (srcBlend != sSrcBlend ||
        dstBlend != sDstBlend ||
        blendEnabled != sBlendEnabled)
        sBlendStateValid = false;

    sSrcBlend = srcBlend;
    sDstBlend = dstBlend;
    sBlendEnabled = blendEnabled;
    currentTexture = texture;
    sCurrentShader = shader;

    VertexPosColorTex *currentVertices = &batchedVertices[batchedVertexCount];
    batchedVertexCount += vertexCount;
    return currentVertices;
}


void QuadRenderer::batch(VertexPosColorTex *vertices, uint16_t vertexCount, TextureID texture, bool blendEnabled, uint32_t srcBlend, uint32_t dstBlend, ShaderProgram *shader)
{
    LOOM_PROFILE_SCOPE(quadBatch);

    VertexPosColorTex *vertexPtr = getQuadVertexMemory(vertexCount, texture, blendEnabled, srcBlend, dstBlend, shader);

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

    GL_Context* ctx = Graphics::context();

    // create the single initial vertex buffer
    ctx->glGenBuffers(1, &vertexBufferId);
    ctx->glBindBuffer(GL_ARRAY_BUFFER, vertexBufferId);
    ctx->glBufferData(GL_ARRAY_BUFFER, MAXBATCHQUADS * 4 * sizeof(VertexPosColorTex), 0, GL_STREAM_DRAW);
    ctx->glBindBuffer(GL_ARRAY_BUFFER, 0);

    // create the single, reused index buffer
    ctx->glGenBuffers(1, &indexBufferId);
    ctx->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferId);
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

    ctx->glBufferData(GL_ELEMENT_ARRAY_BUFFER, MAXBATCHQUADS * 6 * sizeof(uint16_t), pStart, GL_STREAM_DRAW);
    ctx->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

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
