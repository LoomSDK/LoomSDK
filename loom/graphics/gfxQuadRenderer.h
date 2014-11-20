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

#pragma once

#include <stdint.h>
#include "loom/graphics/gfxTexture.h"

namespace GFX
{

// Define the maximum number of Quads on a single frame
// this defaults to 65k and can be raised by increasing
// MAXVERTEXBUFFERS (quad batches themselves use 16 bit indices)

// TODO: LOOM-1833 allocate this dynamically 
#define MAXBATCHQUADS       8192
#define MAXVERTEXBUFFERS    8  

struct VertexPosColorTex
{
    float    x, y, z;
    uint32_t abgr;
    float    u, v;
};

class QuadRenderer
{
    friend class Graphics;

private:

    static bgfx::DynamicVertexBufferHandle vertexBuffers[MAXVERTEXBUFFERS];

    static VertexPosColorTex* vertexData[MAXVERTEXBUFFERS];
    static void* vertexDataMemory;

    static int               maxVertexIdx[MAXVERTEXBUFFERS];

    static int numVertexBuffers;

    static int               currentVertexBufferIdx;
    static VertexPosColorTex *currentVertexPtr;
    static int               vertexCount;

    static int currentIndexBufferIdx;

    static TextureID currentTexture;
    static int       quadCount;

    static int numFrameSubmit;

    // initial initialization
    static void initialize();

    static void initializeGraphicsResources();
    static void destroyGraphicsResources();

    // reset the quad renderer, on loss of context etc
    static void reset();


public:

    static void submit();

    static void beginFrame();

    static void endFrame();

    static VertexPosColorTex *getQuadVertices(TextureID texture, uint16_t numVertices, bool tinted, uint64_t blendFunc);

    static void batch(TextureID texture, VertexPosColorTex *vertices, uint16_t numVertices, uint64_t blendFunc);
};
}
