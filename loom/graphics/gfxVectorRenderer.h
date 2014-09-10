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

#include "loom/graphics/gfxTexture.h"

namespace GFX
{

class VectorRenderer
{
    friend class Graphics;

private:

    // initial initialization
    static void initialize();

    static void initializeGraphicsResources();
    static void destroyGraphicsResources();

    // reset the quad renderer, on loss of context etc
    static void reset();

public:

	static int frameWidth;
	static int frameHeight;

    static void submit();

	static void setSize(int width, int height);

	static void beginFrame();

	static void preDraw(float a, float b, float c, float d, float e, float f);
	static void postDraw();
	
	static void clearPath();
	static void renderStroke();
	static void renderFill();

	static void strokeWidth(float size);
	static void strokeColor(float r, float g, float b, float a);

	static void fillColor(float r, float g, float b, float a);

	static void moveTo(float x, float y);
	static void lineTo(float x, float y);
	static void cubicCurveTo(float c1x, float c1y, float c2x, float c2y, float x, float y);
	static void circle(float x, float y, float radius);
	static void ellipse(float x, float y, float width, float height);
	static void rect(float x, float y, float width, float height);
	static void roundRect(float x, float y, float width, float height, float radius);

    static void endFrame();
};

}
