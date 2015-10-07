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


#include "loom/engine/loom2d/l2dDisplayObject.h"
#include "loom/engine/loom2d/l2dDisplayObjectContainer.h"
#include "loom/engine/loom2d/l2dImage.h"
#include "loom/engine/loom2d/l2dStage.h"

using namespace GFX;

namespace Loom2D
{
Type       *DisplayObject::typeDisplayObject;
lua_Number DisplayObject::_transformationMatrixOrdinal;
bool       DisplayObject::cacheAsBitmapInProgress = false;

bool DisplayObject::renderCached(lua_State *L)
{
    if (!cacheAsBitmapValid) return false;
    DisplayObject *cached = static_cast<DisplayObject*>(cachedImage);
    lmAssert(cached != NULL, "Cached image is invalid");

    cached->transformMatrix.identity();
    cached->transformMatrix.translate(cacheAsBitmapOffsetX, cacheAsBitmapOffsetY);
    cached->transformMatrix.concat(&transformMatrix);
    cached->parent = parent;

    lualoom_pushnative<DisplayObject>(L, cached);
    cached->render(L);
    lua_pop(L, 1);
    return true;
}

void DisplayObject::render(lua_State *L) {
    // Disable reentrancy for this function (read: don't cache to texture while caching to a texture)
    if (cacheAsBitmapInProgress) return;

    // Clear and free the cached image if the conditions apply
    if ((!cacheAsBitmap || !cacheAsBitmapValid) && cachedImage != NULL) {
        Quad* quad = static_cast<Quad*>(cachedImage);

        lmAssert(quad != NULL, "Cached image is invalid");

        GFX::Texture::dispose(quad->getNativeTextureID());
        quad->setNativeTextureID(-1);

        lmDelete(NULL, quad);
        cachedImage = NULL;
        cacheAsBitmapValid = false;
    }

    // Cache the contents into an image if the conditions apply
    if (cacheAsBitmap && !cacheAsBitmapValid && cachedImage == NULL) {
        cacheAsBitmapInProgress = true;
        
        // Used for displaying the texture
        Quad* quad = lmNew(NULL) Quad();
        
        // Setup for getmember
        lualoom_pushnative<DisplayObject>(L, this);
        
        // Push function and arguments
        lualoom_getmember(L, -1, "getBounds");
        lualoom_pushnative<DisplayObject>(L, this);
        lua_pushnil(L);
        // Call getBounds
        lua_call(L, 2, 1);
        
        // Returned result
        Loom2D::Rectangle *bounds = (Loom2D::Rectangle*) lualoom_getnativepointer(L, -1);
        cacheAsBitmapOffsetX = bounds->x;
        cacheAsBitmapOffsetY = bounds->y;
        lmscalar fracWidth = bounds->width;
        lmscalar fracHeight = bounds->height;
        int texWidth = static_cast<int>(ceil(fracWidth));
        int texHeight = static_cast<int>(ceil(fracHeight));
        
        // pop bounds Rectangle and the DisplayObject at the top
        lua_pop(L, 1+1);

        // Setup texture
        TextureInfo *tinfo = Texture::initEmptyTexture(texWidth, texHeight);
        Texture::clear(tinfo->id, 0x000000, 0);
        tinfo->smoothing = TEXTUREINFO_SMOOTHING_BILINEAR;
        tinfo->wrapU = TEXTUREINFO_WRAP_CLAMP;
        tinfo->wrapV = TEXTUREINFO_WRAP_CLAMP;
        TextureID id = tinfo->id;

        // Setup quad for rendering the texture
        quad->setNativeTextureID(id);
        
        VertexPosColorTex* qv;

        qv = &quad->quadVertices[0];  qv->x =               0;  qv->y =                0;  qv->z = 0; qv->abgr = 0xFFFFFFFF; qv->u = 0; qv->v = 0;
        qv = &quad->quadVertices[1];  qv->x = (float)texWidth;  qv->y =                0;  qv->z = 0; qv->abgr = 0xFFFFFFFF; qv->u = 1; qv->v = 0;
        qv = &quad->quadVertices[2];  qv->x =               0;  qv->y = (float)texHeight;  qv->z = 0; qv->abgr = 0xFFFFFFFF; qv->u = 0; qv->v = 1;
        qv = &quad->quadVertices[3];  qv->x = (float)texWidth;  qv->y = (float)texHeight;  qv->z = 0; qv->abgr = 0xFFFFFFFF; qv->u = 1; qv->v = 1;
        quad->setNativeVertexDataInvalid(false);

        lmAssert(Texture::getRenderTarget() == -1, "Unsupported render target state: %d", Texture::getRenderTarget());

        // Set render target to texture
        Texture::setRenderTarget(id);
        
        // Shift the contents down and to the right so that the elements extending
        // past the left and top edges don't get cut off, ignore other existing transforms
        Matrix trans;
        trans.translate(-cacheAsBitmapOffsetX, -cacheAsBitmapOffsetY);

        // Setup for Graphics::render
        lualoom_pushnative<DisplayObject>(L, this);
        lualoom_pushnative<Matrix>(L, &trans);
        lua_pushnumber(L, 1);

        // Render the contents into the texture
        Graphics::render(L);

        // Pop previous arguments
        lua_pop(L, 3);

        // Restore render target
        Texture::setRenderTarget(-1);

        // Set valid cached state
        cachedImage = quad;
        cacheAsBitmapValid = true;
        cacheAsBitmapInProgress = false;
    }
}

/** Creates a matrix that represents the transformation from the local coordinate system
 *  to another. If you pass a 'resultMatrix', the result will be stored in this matrix
 *  instead of creating a new object. */
void DisplayObject::getTargetTransformationMatrix(DisplayObject *targetSpace, Matrix *resultMatrix)
{
    if (!resultMatrix)
    {
        return;
    }

    resultMatrix->identity();

    if (transformDirty)
    {
        updateLocalTransform();
    }

    if (targetSpace == this)
    {
        return;
    }

    if ((targetSpace == parent) || ((targetSpace == NULL) && (parent == NULL)))
    {
        resultMatrix->copyFrom(&transformMatrix);
        return;
    }

    DisplayObject *base = this;
    while (base->parent)
    {
        base = base->parent;
    }

    DisplayObject *currentObject = NULL;

    if ((targetSpace == NULL) || (targetSpace == base))
    {
        // targetCoordinateSpace 'null' represents the target space of the base object.
        // -> move up from this to base

        currentObject = this;
        while (currentObject != targetSpace)
        {
            if (currentObject->transformDirty) {
                currentObject->updateLocalTransform();
            }
            resultMatrix->concat(&currentObject->transformMatrix);

            currentObject = currentObject->parent;
        }

        return;
    }
    else if (targetSpace->parent == this) // optimization
    {
        targetSpace->getTargetTransformationMatrix(this, resultMatrix);
        resultMatrix->invert();
        return;
    }

    // 1. find a common parent of this and the target space

    DisplayObject *commonParent = NULL;

    currentObject = this;

    while (currentObject)
    {
        DisplayObject *target = targetSpace;
        while (target)
        {
            if (target == currentObject)
            {
                commonParent = target;
                break;
            }

            target = target->parent;
        }

        if (commonParent)
        {
            break;
        }

        currentObject = currentObject->parent;
    }

    lmAssert(commonParent, "Object not connected to target.");
    //else throw new ArgumentError("Object not connected to target");

    // 2. move up from this to common parent

    currentObject = this;
    while (currentObject != commonParent)
    {
        if (currentObject->transformDirty) {
            currentObject->updateLocalTransform();
        }
        resultMatrix->concat(&currentObject->transformMatrix);
        currentObject = currentObject->parent;
    }

    if (commonParent == targetSpace)
    {
        return;
    }

    // 3. now move up from target until we reach the common parent

    Matrix helperMatrix;
    //helperMatrix.identity();
    currentObject = targetSpace;
    while (currentObject != commonParent)
    {
        helperMatrix.concat(&currentObject->transformMatrix);
        currentObject = currentObject->parent;
    }

    // 4. now combine the two matrices

    helperMatrix.invert();
    resultMatrix->concat(&helperMatrix);
}
}
