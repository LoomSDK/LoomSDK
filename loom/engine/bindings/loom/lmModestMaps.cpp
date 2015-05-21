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

#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/common/utils/utString.h"

#include "loom/graphics/gfxMath.h"
#include "loom/engine/loom2d/l2dDisplayObject.h"
#include "loom/engine/loom2d/l2dMatrix.h"


using namespace LS;
using namespace Loom2D;



/// Script bindings to the native ModestMaps API.
///
/// See ModestMaps.ls for documentation on this API.
class ModestMaps
{
public:
    static float lastCoordinateX;
    static float lastCoordinateY;
    static int parentLoadCol;
    static int parentLoadRow;
    static int parentLoadZoom;


    static utString tileKey(int col, int row, int zoom)
    {
        char key[256];
        sprintf(key, "%c:%i:%i", (char)(((int)'a')+zoom), col, row);
        return utString(key);
    }
 
    static utString prepParentLoad(int col, int row, int zoom, int parentZoom)
    {
        //NOTE_TEC: zoomDiff should always be +ve
        int zoomDiff = zoom - parentZoom;
        if(zoomDiff <= 0)
        {
            parentLoadCol = col;
            parentLoadRow = row;
            parentLoadZoom = zoom;
        }
        else
        {
            float invScaleFactor = 1.0f / (float)(1 << zoomDiff);
            parentLoadCol = floor((float)col * invScaleFactor); 
            parentLoadRow = floor((float)row * invScaleFactor);
            parentLoadZoom = parentZoom;
        }
        return tileKey(parentLoadCol, parentLoadRow, parentLoadZoom);
    }

    static void setLastCoordinate(float col,
                                    float row,
                                    float zoom,
                                    float zoomLevel,
                                    float invTileWidth,
                                    Matrix *worldMatrix,
                                    DisplayObject *context,
                                    DisplayObject *object)
    {
        // this is basically the same as coord.zoomTo, but doesn't make a new Coordinate:
        float zoomFactor = pow(2, zoomLevel - zoom) * invTileWidth;
        float zoomedColumn = col * zoomFactor;
        float zoomedRow = row * zoomFactor;
                    
        worldMatrix->transformCoordInternal(zoomedColumn, zoomedRow, &lastCoordinateX, &lastCoordinateY);

        //transform into correct space if necessary
        if ((context != NULL) && (context != object))
        {
            localToGlobal((DisplayObject *)(object->parent), &lastCoordinateX, &lastCoordinateY);
            globalToLocal(context, &lastCoordinateX, &lastCoordinateY);
        }
    } 




private:
    static void localToGlobal(DisplayObject *obj, float *x, float *y)
    {
        //find the base of the object to start
        DisplayObject *base = obj;
        while (base->parent) { base = (DisplayObject *)base->parent; }

        //get the matrix and transform!
        Matrix mtx;
        obj->getTargetTransformationMatrix(base, &mtx);
        mtx.transformCoordInternal(*x, *y, x, y);
    }


    static void globalToLocal(DisplayObject *obj, float *x, float *y)
    {
        //find the base of the object to start
        DisplayObject *base = obj;
        while (base->parent) { base = (DisplayObject *)base->parent; }

        //get the matrix and transform!
        Matrix mtx;
        obj->getTargetTransformationMatrix(base, &mtx);
        mtx.invert();
        mtx.transformCoordInternal(*x, *y, x, y);
    }
};

float ModestMaps::lastCoordinateX = 0.0f;
float ModestMaps::lastCoordinateY = 0.0f;
int ModestMaps::parentLoadCol = 0;
int ModestMaps::parentLoadRow = 0;
int ModestMaps::parentLoadZoom = 0;




static int registerLoomModestMaps(lua_State *L)
{
    ///set up lua bindings
    beginPackage(L, "loom.modestmaps")

        .beginClass<ModestMaps>("ModestMaps")

            .addStaticVar("LastCoordinateX", &ModestMaps::lastCoordinateX)
            .addStaticVar("LastCoordinateY", &ModestMaps::lastCoordinateY)
            .addStaticVar("ParentLoadCol", &ModestMaps::parentLoadCol)
            .addStaticVar("ParentLoadRow", &ModestMaps::parentLoadRow)
            .addStaticVar("ParentLoadZoom", &ModestMaps::parentLoadZoom)

            .addStaticMethod("tileKey", &ModestMaps::tileKey)
            .addStaticMethod("prepParentLoad", &ModestMaps::prepParentLoad)
            .addStaticMethod("setLastCoordinate", &ModestMaps::setLastCoordinate)

        .endClass()

    .endPackage();

    return 0;
}


void installLoomModestMaps()
{
    LOOM_DECLARE_NATIVETYPE(ModestMaps, registerLoomModestMaps);
}
