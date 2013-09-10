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

#include "loom/common/core/log.h"
#include "loom/common/core/allocator.h"

#include "loom/common/core/assert.h"
#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxShaders.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/graphics/gfxMath.h"

#include "stdio.h"

namespace GFX
{
lmDefineLogGroup(gGFXQuadRendererLogGroup, "GFXQuadRenderer", 1, LoomLogInfo);

// coincides w/ struct VertexPosColorTex in gfxQuadRenderer.h
static bgfx::VertexDecl sVertexPosColorTexDecl;

static bgfx::UniformHandle sUniformTexColor;
static bgfx::UniformHandle sUniformNodeMatrixRemoveMe;
static bgfx::ProgramHandle sProgramPosColorTex;

static bgfx::IndexBufferHandle sIndexBufferHandle;

bgfx::DynamicVertexBufferHandle QuadRenderer::vertexBuffers[MAXVERTEXBUFFERS];

VertexPosColorTex* QuadRenderer::vertexData[MAXVERTEXBUFFERS];

void* QuadRenderer::vertexDataMemory = NULL;

int QuadRenderer::maxVertexIdx[MAXVERTEXBUFFERS];

int QuadRenderer::numVertexBuffers;

int               QuadRenderer::currentVertexBufferIdx;
VertexPosColorTex *QuadRenderer::currentVertexPtr;
int               QuadRenderer::vertexCount;

int QuadRenderer::currentIndexBufferIdx;

TextureID QuadRenderer::currentTexture;
int       QuadRenderer::quadCount;

int QuadRenderer::numFrameSubmit;

static loom_allocator_t *gQuadMemoryAllocator = NULL;

void QuadRenderer::submit()
{
    if (quadCount <= 0)
    {
        return;
    }

    numFrameSubmit++;

    if (Texture::sTextureInfos[currentTexture].handle.idx != MARKEDTEXTURE)
    {
        lmAssert(sIndexBufferHandle.idx != bgfx::invalidHandle, "No index buffer!");
        bgfx::setIndexBuffer(sIndexBufferHandle, currentIndexBufferIdx, (quadCount * 6));
        bgfx::setVertexBuffer(vertexBuffers[currentVertexBufferIdx], MAXBATCHQUADS * 4);

        bgfx::setTexture(0, sUniformTexColor, Texture::sTextureInfos[currentTexture].handle);

        // Set render states.
        bgfx::setState(0
                       | BGFX_STATE_RGB_WRITE
                       | BGFX_STATE_ALPHA_WRITE
                       //|BGFX_STATE_DEPTH_WRITE
                       //|BGFX_STATE_DEPTH_TEST_LESS
                       | BGFX_STATE_BLEND_FUNC(BGFX_STATE_BLEND_SRC_ALPHA, BGFX_STATE_BLEND_INV_SRC_ALPHA)
                       );

        bgfx::submit(Graphics::getView());

        currentIndexBufferIdx += quadCount * 6;
    }

    quadCount = 0;
}


VertexPosColorTex *QuadRenderer::getQuadVertices(TextureID texture, uint16_t numVertices)
{
    if (!numVertices || (texture < 0) || (numVertices > MAXBATCHQUADS * 4))
    {
        return NULL;
    }

    lmAssert(!(numVertices % 4), "numVertices % 4 != 0");

    if ((currentTexture != TEXTUREINVALID) && (currentTexture != texture))
    {
        submit();
    }

    if ((vertexCount + numVertices) > MAXBATCHQUADS * 4)
    {
        submit();

        if (numVertexBuffers == MAXVERTEXBUFFERS)
        {
            return NULL;
        }

        currentVertexBufferIdx++;

        if (currentVertexBufferIdx == numVertexBuffers)
        {
            // we need to allocate a new one
            printf("Allocating new dynamic vertex buffer\n");
            vertexBuffers[numVertexBuffers++] = bgfx::createDynamicVertexBuffer(MAXBATCHQUADS * 4, sVertexPosColorTexDecl);
        }

        currentIndexBufferIdx = 0;

        maxVertexIdx[currentVertexBufferIdx] = 0;
        currentVertexPtr = vertexData[currentVertexBufferIdx];
        vertexCount      = 0;
        quadCount        = 0;
    }

    VertexPosColorTex *returnPtr = currentVertexPtr;

    currentVertexPtr += numVertices;
    vertexCount      += numVertices;

    maxVertexIdx[currentVertexBufferIdx] = vertexCount;

    currentTexture = texture;

    quadCount += numVertices / 4;

    return returnPtr;
}


void QuadRenderer::batch(TextureID texture, VertexPosColorTex *vertices, uint16_t numVertices)
{
    VertexPosColorTex *verticePtr = getQuadVertices(texture, numVertices);

    if (!verticePtr)
    {
        return;
    }

    memcpy((void *)verticePtr, (void *)vertices, sizeof(VertexPosColorTex) * numVertices);
}


void QuadRenderer::beginFrame()
{
    currentIndexBufferIdx  = 0;
    currentVertexBufferIdx = 0;
    vertexCount            = 0;
    currentTexture         = TEXTUREINVALID;
    quadCount = 0;

    currentVertexPtr = vertexData[currentVertexBufferIdx];
    maxVertexIdx[currentIndexBufferIdx] = 0;

    numFrameSubmit = 0;

    // remove me
    float node[16];
    mtxIdentity(node);

    bgfx::setUniform(sUniformNodeMatrixRemoveMe, (const void *)node);
    bgfx::setProgram(sProgramPosColorTex);
}


void QuadRenderer::endFrame()
{
    submit();

    //printf("numFrameSubmit %i\n", numFrameSubmit);

    for (int i = 0; i < currentVertexBufferIdx + 1; i++)
    {
        // may need to alloc or double buffer if we thread bgfx
        const bgfx::Memory *mem = bgfx::makeRef(vertexData[i], sizeof(VertexPosColorTex) * maxVertexIdx[i]);
        bgfx::updateDynamicVertexBuffer(vertexBuffers[i], mem);
    }
}


void QuadRenderer::destroyGraphicsResources()
{
    for (int i = 0; i < MAXVERTEXBUFFERS; i++)
    {
        if (vertexBuffers[i].idx != bgfx::invalidHandle)
        {
            bgfx::destroyDynamicVertexBuffer(vertexBuffers[i]);
            vertexBuffers[i].idx = bgfx::invalidHandle;
        }
    }

    if (sIndexBufferHandle.idx != bgfx::invalidHandle)
    {
        bgfx::destroyIndexBuffer(sIndexBufferHandle);
        sIndexBufferHandle.idx = bgfx::invalidHandle;
    }

    if (sProgramPosColorTex.idx != bgfx::invalidHandle)
    {
        bgfx::destroyProgram(sProgramPosColorTex);
    }

    if (sUniformTexColor.idx != bgfx::invalidHandle)
    {
        bgfx::destroyUniform(sUniformTexColor);
    }

    if (sUniformNodeMatrixRemoveMe.idx != bgfx::invalidHandle)
    {
        bgfx::destroyUniform(sUniformNodeMatrixRemoveMe);
    }

    sUniformTexColor.idx           = bgfx::invalidHandle;
    sUniformNodeMatrixRemoveMe.idx = bgfx::invalidHandle;
    sProgramPosColorTex.idx        = bgfx::invalidHandle;

    if (vertexDataMemory)
    {
        lmFree(gQuadMemoryAllocator, vertexDataMemory);
        vertexDataMemory = NULL;
    }
}


void QuadRenderer::initializeGraphicsResources()
{
    const bgfx::Memory *mem = NULL;

    lmLogInfo(gGFXQuadRendererLogGroup, "Initializing Graphics Resources");

    // Create texture sampler uniforms.
    sUniformTexColor           = bgfx::createUniform("u_texColor", bgfx::UniformType::Uniform1iv);
    sUniformNodeMatrixRemoveMe = bgfx::createUniform("u_nodeMatrix", bgfx::UniformType::Uniform4x4fv);

    int           sz;
    const uint8_t *pshader;

    // Load vertex shader.
    bgfx::VertexShaderHandle vsh;
    pshader = GetVertexShaderPosColorTex(sz);
    mem     = bgfx::makeRef(pshader, sz);
    vsh     = bgfx::createVertexShader(mem);

    // Load fragment shader.
    bgfx::FragmentShaderHandle fsh;
    pshader = GetFragmentShaderPosColorTex(sz);
    mem     = bgfx::makeRef(pshader, sz);
    fsh     = bgfx::createFragmentShader(mem);

    // Create program from shaders.
    sProgramPosColorTex = bgfx::createProgram(vsh, fsh);

    // We can destroy vertex and fragment shader here since
    // their reference is kept inside bgfx after calling createProgram.
    // Vertex and fragment shader will be destroyed once program is
    // destroyed.
    bgfx::destroyVertexShader(vsh);
    bgfx::destroyFragmentShader(fsh);

    // create the vertex stream
    sVertexPosColorTexDecl.begin();
    sVertexPosColorTexDecl.add(bgfx::Attrib::Position, 3, bgfx::AttribType::Float);
    sVertexPosColorTexDecl.add(bgfx::Attrib::Color0, 4, bgfx::AttribType::Uint8, true);
    sVertexPosColorTexDecl.add(bgfx::Attrib::TexCoord0, 2, bgfx::AttribType::Float);
    sVertexPosColorTexDecl.end();

    // create the single, reused quad index buffer
    numVertexBuffers = 0;
    vertexBuffers[numVertexBuffers++] = bgfx::createDynamicVertexBuffer(MAXBATCHQUADS * 4, sVertexPosColorTexDecl);

    mem = bgfx::alloc(sizeof(uint16_t) * 6 * MAXBATCHQUADS);
    uint16_t *pindice = (uint16_t *)mem->data;

    int j = 0;
    for (int i = 0; i < 6 * MAXBATCHQUADS; i += 6, j += 4, pindice += 6)
    {
        pindice[0] = j;
        pindice[1] = j + 2;
        pindice[2] = j + 1;
        pindice[3] = j + 1;
        pindice[4] = j + 2;
        pindice[5] = j + 3;
    }

    sIndexBufferHandle = bgfx::createIndexBuffer(mem);

    size_t bufferSize = MAXVERTEXBUFFERS * sizeof(VertexPosColorTex) * MAXBATCHQUADS * 4;

    vertexDataMemory = lmAlloc(gQuadMemoryAllocator, bufferSize);

    lmAssert(vertexDataMemory, "Unable to allocate buffer for quad vertex data");

    VertexPosColorTex* p = (VertexPosColorTex*) vertexDataMemory; 

    for (int i = 0; i < MAXVERTEXBUFFERS; i++)
    {
        // setup buffer pointer
        vertexData[i] = p;

        p += MAXBATCHQUADS * 4;
        
    }

}


void QuadRenderer::reset()
{
    destroyGraphicsResources();
    bgfx::frame();
    initializeGraphicsResources();
}


void QuadRenderer::initialize()
{
    sUniformNodeMatrixRemoveMe.idx = bgfx::invalidHandle;
    sUniformTexColor.idx           = bgfx::invalidHandle;
    sProgramPosColorTex.idx        = bgfx::invalidHandle;
    sIndexBufferHandle.idx         = bgfx::invalidHandle;

    for (int i = 0; i < MAXVERTEXBUFFERS; i++)
    {
        vertexBuffers[i].idx = bgfx::invalidHandle;
    }
}
}
