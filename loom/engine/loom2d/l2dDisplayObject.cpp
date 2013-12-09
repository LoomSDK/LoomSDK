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

namespace Loom2D
{
Type       *DisplayObject::typeDisplayObject;
lua_Number DisplayObject::_transformationMatrixOrdinal;

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
