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

#include "stdio.h"

namespace GFX
{
lmDefineLogGroup(gGFXQuadRendererLogGroup, "GFXQuadRenderer", 1, LoomLogInfo);

static unsigned int sProgramPosColorTex;
static unsigned int sProgramPosTex;

static unsigned int sProgram_posAttribLoc;
static unsigned int sProgram_posColorLoc;
static unsigned int sProgram_posTexCoordLoc;
static unsigned int sProgram_texUniform;
static unsigned int sProgram_mvp;

static unsigned int sIndexBufferHandle;

static bool sTinted = true;

unsigned int sSrcBlend = GL_SRC_ALPHA;
unsigned int sDstBlend = GL_ONE_MINUS_SRC_ALPHA;

unsigned int QuadRenderer::vertexBuffers[MAXVERTEXBUFFERS];

VertexPosColorTex* QuadRenderer::vertexData[MAXVERTEXBUFFERS];

void* QuadRenderer::vertexDataMemory = NULL;

int QuadRenderer::maxVertexIdx[MAXVERTEXBUFFERS];

int QuadRenderer::numVertexBuffers;

int               QuadRenderer::currentVertexBufferIdx;
VertexPosColorTex *QuadRenderer::currentVertexPtr;
int               QuadRenderer::vertexCount;

int QuadRenderer::currentIndexBufferIdx;

TextureID QuadRenderer::currentTexture;

// Number of quads pending submission
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

	TextureInfo &tinfo = Texture::sTextureInfos[currentTexture & TEXTURE_ID_MASK];

    if (tinfo.handle != -1)
    {
        // On iPad 1, the PosColorTex shader, which multiplies texture color with
        // vertex color, is 5x slower than PosTex, which just draws the texture
        // unmodified. So we select the shader to use appropriately.

        //lmLogInfo(gGFXQuadRendererLogGroup, "Handle > %u", tinfo.handle);

        // Select the shader.
        if(sTinted)
            Graphics::context()->glUseProgram(sProgramPosColorTex);
        else
            Graphics::context()->glUseProgram(sProgramPosTex);

        // Upload vertex data.
        Graphics::context()->glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[currentVertexBufferIdx]);

        // This commented block seems better for performance, but it's actually a lot slower on iOS.
        // Instead we just update the entire buffer, which seems to run fine.
        // A better solution would be having a triple buffered glMapBuffer approach.
        /*
        Graphics::context()->glBufferSubData(GL_ARRAY_BUFFER,
                                             (vertexCount - quadCount * 4) * sizeof(VertexPosColorTex),
                                             quadCount * 4 * sizeof(VertexPosColorTex),
                                             &vertexData[currentVertexBufferIdx][vertexCount - quadCount*4] );
        */
        Graphics::context()->glBufferData(GL_ARRAY_BUFFER, vertexCount*sizeof(VertexPosColorTex), &vertexData[currentVertexBufferIdx][0], GL_STATIC_DRAW);

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
        
        // Set up texture state.
        Graphics::context()->glActiveTexture(GL_TEXTURE0);
        Graphics::context()->glUniform1i(sProgram_texUniform, 0);
        Graphics::context()->glUniformMatrix4fv(sProgram_mvp, 1, GL_FALSE, Graphics::getMVP());

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
        //*/

        // Blend mode.
        Graphics::context()->glEnable(GL_BLEND);
        Graphics::context()->glBlendFuncSeparate(sSrcBlend, sDstBlend, sSrcBlend, sDstBlend);

        // And bind indices and draw.
        Graphics::context()->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, sIndexBufferHandle);
        Graphics::context()->glDrawElements(GL_TRIANGLES,
                                            quadCount * 6, GL_UNSIGNED_SHORT,
                                            (void*)(currentIndexBufferIdx*sizeof(unsigned short)));
		
        // Reset GL state.
        Graphics::context()->glBindTexture(GL_TEXTURE_2D, 0);
        Graphics::context()->glBindBuffer(GL_ARRAY_BUFFER, 0);
        Graphics::context()->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        Graphics::context()->glUseProgram(0);

        Graphics::context()->glDisableVertexAttribArray(sProgram_posAttribLoc);
        Graphics::context()->glDisableVertexAttribArray(sProgram_posColorLoc);
        Graphics::context()->glDisableVertexAttribArray(sProgram_posTexCoordLoc);

        // Update buffer state.
        currentIndexBufferIdx += quadCount * 6;
    }

    quadCount = 0;
}


VertexPosColorTex *QuadRenderer::getQuadVertices(TextureID texture, uint16_t numVertices, bool tinted, uint32_t srcBlend, uint32_t dstBlend)
{
    if (!numVertices || (texture < 0) || (numVertices > MAXBATCHQUADS * 4))
    {
        return NULL;
    }

    lmAssert(!(numVertices % 4), "numVertices % 4 != 0");
	lmAssert(texture == Texture::getTextureInfo(texture)->id, "Texture ID signature mismatch, you might be trying to draw a disposed texture");
	
    if (((currentTexture != TEXTUREINVALID) && (currentTexture != texture))
        || (sTinted != tinted) || (srcBlend != sSrcBlend) || ( dstBlend != sDstBlend))
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
            _initializeNextVertexBuffer();
        }

        currentIndexBufferIdx = 0;

        maxVertexIdx[currentVertexBufferIdx] = 0;
        currentVertexPtr = vertexData[currentVertexBufferIdx];
        vertexCount      = 0;
        quadCount        = 0;
    }

    VertexPosColorTex *returnPtr = currentVertexPtr;

    sTinted = tinted;
    sSrcBlend = srcBlend;
    sDstBlend = dstBlend;

    currentVertexPtr += numVertices;
    vertexCount      += numVertices;

    maxVertexIdx[currentVertexBufferIdx] = vertexCount;

    currentTexture = texture;

    quadCount += numVertices / 4;

    return returnPtr;
}


void QuadRenderer::batch(TextureID texture, VertexPosColorTex *vertices, uint16_t numVertices, uint32_t srcBlend, uint32_t dstBlend)
{
    VertexPosColorTex *verticePtr = getQuadVertices(texture, numVertices, true, srcBlend, dstBlend);

    if (!verticePtr)
        return;

    memcpy((void *)verticePtr, (void *)vertices, sizeof(VertexPosColorTex) * numVertices);
}


void QuadRenderer::beginFrame()
{
    currentIndexBufferIdx  = 0;
    currentVertexBufferIdx = 0;
    vertexCount            = 0;
    currentTexture         = TEXTUREINVALID;
    quadCount              = 0;

    currentVertexPtr = vertexData[currentVertexBufferIdx];
    maxVertexIdx[currentIndexBufferIdx] = 0;

    numFrameSubmit = 0;

    // Fudge something to render with.
/*    VertexPosColorTex v[4];
    v[0].x =  0.5; v[0].y =  0.5; v[0].z = 0.5;
    v[1].x =  0.5; v[1].y = -0.5; v[1].z = 0.5;
    v[2].x = -0.5; v[2].y = -0.5; v[2].z = 0.5;
    v[3].x = -0.5; v[3].y =  0.5; v[3].z = 0.5;
    batch(1, &v[0], 4, 0); */
}


void QuadRenderer::endFrame()
{
    submit();
}


void QuadRenderer::destroyGraphicsResources()
{
    // Probably do something someday.
}

void QuadRenderer::_initializeNextVertexBuffer()
{
    Graphics::context()->glGenBuffers(1, &vertexBuffers[numVertexBuffers]);
    Graphics::context()->glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[numVertexBuffers]);
    Graphics::context()->glBufferData(GL_ARRAY_BUFFER, MAXBATCHQUADS * 4 * sizeof(VertexPosColorTex), 0, GL_STATIC_DRAW);
    Graphics::context()->glBindBuffer(GL_ARRAY_BUFFER, 0);
    numVertexBuffers++;
}

void QuadRenderer::initializeGraphicsResources()
{
    lmLogInfo(gGFXQuadRendererLogGroup, "Initializing Graphics Resources");

    //lmLogInfo(gGFXQuadRendererLogGroup, "OpenGL error %d", Graphics::context()->glGetError());

    // Create the quad 1.
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
    
    /*
    char fragShaderSrc[] =
#if LOOM_RENDERER_OPENGLES2      
        "precision mediump float;\n"
#endif
        "uniform sampler2D u_texture;\n"
        "varying vec2 v_texcoord0;\n"
        "void main()\n"
        "{\n"
        "    gl_FragColor = texture2D(u_texture, v_texcoord0);\n"
        "}\n";
    const int fragShaderLen = sizeof(fragShaderSrc);
    GLchar *fragShaderPtr = &fragShaderSrc[0];

    Graphics::context()->glShaderSource(fragShader, 1, &fragShaderPtr, &fragShaderLen);
    Graphics::context()->glCompileShader(fragShader);
    Graphics::context()->glGetShaderInfoLog(fragShader, 4096, &outLen, error);

    lmLogInfo(gGFXQuadRendererLogGroup, "Program info log %s", error);
    
    Graphics::context()->glAttachShader(quadProg, fragShader);
    Graphics::context()->glAttachShader(quadProg, vertShader);
    Graphics::context()->glLinkProgram(quadProg);
    Graphics::context()->glGetProgramInfoLog(quadProg, 4096, &outLen, error);

    lmLogInfo(gGFXQuadRendererLogGroup, "Program info log %s", error);
    */

    // Get attributes and uniforms.
    sProgram_posAttribLoc = Graphics::context()->glGetAttribLocation(quadProgColor, "a_position");
    sProgram_posColorLoc = Graphics::context()->glGetAttribLocation(quadProgColor, "a_color0");
    sProgram_posTexCoordLoc = Graphics::context()->glGetAttribLocation(quadProgColor, "a_texcoord0");
    sProgram_texUniform = Graphics::context()->glGetUniformLocation(quadProgColor, "u_texture");
    sProgram_mvp = Graphics::context()->glGetUniformLocation(quadProgColor, "u_mvp");

    // Save program for later!
    sProgramPosColorTex = sProgramPosTex = quadProgColor;

    // create the single initial vertex buffer
    numVertexBuffers = 0;
    _initializeNextVertexBuffer();

    // create the single, reused index buffer
    Graphics::context()->glGenBuffers(1, &sIndexBufferHandle);
    Graphics::context()->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, sIndexBufferHandle);
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

    Graphics::context()->glBufferData(GL_ELEMENT_ARRAY_BUFFER, MAXBATCHQUADS * 6 * sizeof(uint16_t), pStart, GL_STATIC_DRAW);
    Graphics::context()->glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    lmFree(gQuadMemoryAllocator, pStart);

    // Create the system memory buffer for quads.
    vertexDataMemory = lmAlloc(gQuadMemoryAllocator, MAXVERTEXBUFFERS * MAXBATCHQUADS * 4 * sizeof(VertexPosColorTex));
    for(int i=0; i<MAXVERTEXBUFFERS; i++)
        vertexData[i] = ((VertexPosColorTex*)vertexDataMemory) + (MAXBATCHQUADS * 4) * i;
}


void QuadRenderer::reset()
{
    destroyGraphicsResources();
    initializeGraphicsResources();
}


void QuadRenderer::initialize()
{
    initializeGraphicsResources();
}
}
