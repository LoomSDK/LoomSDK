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
#include "loom/script/runtime/lsProfiler.h"

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
    static lmscalar lastCoordinateX;
    static lmscalar lastCoordinateY;
    static int parentLoadCol;
    static int parentLoadRow;
    static int parentLoadChild;
    static int parentLoadZoom;
    static lmscalar gridZoom;
    static lmscalar gridTLx;
    static lmscalar gridTLy;
    static lmscalar gridBRx;
    static lmscalar gridBRy;
    static lmscalar gridTRx;
    static lmscalar gridTRy;
    static lmscalar gridBLx;
    static lmscalar gridBLy;
    static lmscalar gridCx;
    static lmscalar gridCy;


    static const char *tileKey(int col, int row, int zoom)
    {
        static char key[256];
        sprintf(key, "%c:%i:%i", (char)(((int)'a')+zoom), col, row);
        return (const char *)key;
    }
 
    static const char *prepParentLoad(int col, int row, int zoom, int parentZoom)
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
            int scaleFactor = 1 << zoomDiff;
            lmscalar invScaleFactor = 1.0f / (lmscalar)scaleFactor;
            lmscalar scaledCol = (lmscalar)col * invScaleFactor;
            lmscalar scaledRow = (lmscalar)row * invScaleFactor;
            parentLoadCol = (int) floor(scaledCol); 
            parentLoadRow = (int) floor(scaledRow);
            parentLoadChild = (int)((scaledCol - (lmscalar)parentLoadCol)*scaleFactor) + (int)((scaledRow - (lmscalar)parentLoadRow)*scaleFactor)*2;
            parentLoadZoom = parentZoom;
        }
        return tileKey(parentLoadCol, parentLoadRow, parentLoadZoom);
    }

    static void setLastCoordinate(lmscalar col,
                                    lmscalar row,
                                    lmscalar zoom,
                                    lmscalar zoomLevel,
                                    lmscalar invTileWidth,
                                    Matrix *worldMatrix,
                                    DisplayObject *context,
                                    DisplayObject *object)
    {
        // this is basically the same as coord.zoomTo, but doesn't make a new Coordinate:
        lmscalar zoomFactor = pow(2, zoomLevel - zoom) * invTileWidth;
        lmscalar zoomedColumn = col * zoomFactor;
        lmscalar zoomedRow = row * zoomFactor;
                    
        worldMatrix->transformCoordInternal(zoomedColumn, zoomedRow, &lastCoordinateX, &lastCoordinateY);

        //transform into correct space if necessary
        if ((context != NULL) && (context != object))
        {
            localToGlobal((DisplayObject *)(object->parent), &lastCoordinateX, &lastCoordinateY);
            globalToLocal(context, &lastCoordinateX, &lastCoordinateY);
        }
    } 


    static void setGridCoordinates(Matrix *invMatrix, lmscalar mapWidth, lmscalar mapHeight, lmscalar mapScale)
    {
        const lmscalar LN2 = (lmscalar) 0.6931471805599453;
        gridZoom = log(mapScale) / LN2;
        invMatrix->transformCoordInternal(0.0, 0.0, &gridTLy, &gridTLx);
        invMatrix->transformCoordInternal(mapWidth, mapHeight, &gridBRy, &gridBRx);
        invMatrix->transformCoordInternal(mapWidth, 0.0, &gridTRy, &gridTRx);
        invMatrix->transformCoordInternal(0.0, mapHeight, &gridBLy, &gridBLx);
        invMatrix->transformCoordInternal(mapWidth * (lmscalar) 0.5, mapHeight * (lmscalar) 0.5, &gridCy, &gridCx);
    }


    static void getGridInverseMatrix(Matrix *worldMatrix, lmscalar tileWidth, lmscalar tileHeight, lmscalar mapScale, Matrix *resultMatrix)
    {
        resultMatrix->invertOther(worldMatrix);
        resultMatrix->scale(mapScale / tileWidth, mapScale / tileHeight);
    }

 
    static const char *getMSProviderZoomString(lmscalar col, lmscalar row, int zoom)
    {
        LOOM_PROFILE_SCOPE(mmZoom);
        // we don't wrap rows here because the map/grid should be enforcing outerLimits :)

        lmscalar zoomExp = pow(2.0f, zoom);
        lmscalar wrappedColumn = fmod(col, zoomExp);
        while (wrappedColumn < 0)
        {
            wrappedColumn += zoomExp;
        }
        col = wrappedColumn;
        
        // convert row + col to zoom string
        // padded with zeroes so we end up with zoom digits after slicing:
        convertToBinary((int) row, _rowBinaryString);
        convertToBinary((int) col, _colBinaryString);

        // generate zoom string
        int rowOffset = (int)strlen(_rowBinaryString) - zoom;
        int colOffset = (int)strlen(_colBinaryString) - zoom;
        const int zoomStringLen = 256;
        static char zoomString[zoomStringLen];
        lmAssert(zoom + 1 < zoomStringLen, "zoom should be less than %d - 1", zoomStringLen);
        for(int i = 0; i < zoom; i++) 
        {
            //proces the row and col bits to build up the zoom string; values of 0,1,2,3
            char value = _colBinaryString[i + colOffset];
            if(_rowBinaryString[i + rowOffset] == '1')
            {
                value = (value == '1') ? '3' : '2';
            }
            zoomString[i] = value;
        }
        zoomString[zoom] = '\0';

        return (const char*) zoomString;
    }



private:
    static char _rowBinaryString[33];
    static char _colBinaryString[33];


    static void localToGlobal(DisplayObject *obj, lmscalar *x, lmscalar *y)
    {
        //find the base of the object to start
        DisplayObject *base = obj;
        while (base->parent) { base = (DisplayObject *)base->parent; }

        //get the matrix and transform!
        Matrix mtx;
        obj->getTargetTransformationMatrix(base, &mtx);
        mtx.transformCoordInternal(*x, *y, x, y);
    }


    static void globalToLocal(DisplayObject *obj, lmscalar *x, lmscalar *y)
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

    /** 
     * @return 32 digit binary representation of numberToConvert
     *  
     * NOTE: Due to Loom Script not having unsigned int values, this will 
     * only work correctly for number with values up to up to 2147483647
     */
    static void convertToBinary(int numberToConvert, char *binString) 
    {
        bool negative = false;       
        if(numberToConvert < 0)
        {
            //we want to wrap -ve values around as if we were casting to uint, so 2s comp FTW!
            numberToConvert += (1 << 30);
            negative = true;
        }

        //convert to a binary string
        binString[32] = '\0';
        int numBits = 32;
        int remainder;
        while (numberToConvert > 0)
        {
            remainder = (int)(numberToConvert % 2);
            numberToConvert = (int)(numberToConvert / 2);
            binString[--numBits] = (remainder == 0) ? '0' : '1';
        }

        //add preceeding digits if necessary
        if (numBits > 0) 
        {
            memset(binString, (negative) ? '1' : '0', numBits);
        }
    }    
};

lmscalar ModestMaps::lastCoordinateX = 0.0f;
lmscalar ModestMaps::lastCoordinateY = 0.0f;
int ModestMaps::parentLoadCol = 0;
int ModestMaps::parentLoadRow = 0;
int ModestMaps::parentLoadChild = 0;
int ModestMaps::parentLoadZoom = 0;
lmscalar ModestMaps::gridZoom = 0.0f;
lmscalar ModestMaps::gridTLx = 0.0f;
lmscalar ModestMaps::gridTLy = 0.0f;
lmscalar ModestMaps::gridBRx = 0.0f;
lmscalar ModestMaps::gridBRy = 0.0f;
lmscalar ModestMaps::gridTRx = 0.0f;
lmscalar ModestMaps::gridTRy = 0.0f;
lmscalar ModestMaps::gridBLx = 0.0f;
lmscalar ModestMaps::gridBLy = 0.0f;
lmscalar ModestMaps::gridCx = 0.0f;
lmscalar ModestMaps::gridCy = 0.0f;
char ModestMaps::_rowBinaryString[33];
char ModestMaps::_colBinaryString[33];




static int registerLoomModestMaps(lua_State *L)
{
    ///set up lua bindings
    beginPackage(L, "loom.modestmaps")

        .beginClass<ModestMaps>("ModestMaps")

            .addStaticVar("LastCoordinateX", &ModestMaps::lastCoordinateX)
            .addStaticVar("LastCoordinateY", &ModestMaps::lastCoordinateY)
            .addStaticVar("ParentLoadCol", &ModestMaps::parentLoadCol)
            .addStaticVar("ParentLoadRow", &ModestMaps::parentLoadRow)
            .addStaticVar("ParentLoadChild", &ModestMaps::parentLoadChild)
            .addStaticVar("ParentLoadZoom", &ModestMaps::parentLoadZoom)
            .addStaticVar("GridZoom", &ModestMaps::gridZoom)
            .addStaticVar("GridTLx", &ModestMaps::gridTLx)
            .addStaticVar("GridTLy", &ModestMaps::gridTLy)
            .addStaticVar("GridBRx", &ModestMaps::gridBRx)
            .addStaticVar("GridBRy", &ModestMaps::gridBRy)
            .addStaticVar("GridTRx", &ModestMaps::gridTRx)
            .addStaticVar("GridTRy", &ModestMaps::gridTRy)
            .addStaticVar("GridBLx", &ModestMaps::gridBLx)
            .addStaticVar("GridBLy", &ModestMaps::gridBLy)
            .addStaticVar("GridCx", &ModestMaps::gridCx)
            .addStaticVar("GridCy", &ModestMaps::gridCy)

            .addStaticMethod("tileKey", &ModestMaps::tileKey)
            .addStaticMethod("prepParentLoad", &ModestMaps::prepParentLoad)
            .addStaticMethod("setLastCoordinate", &ModestMaps::setLastCoordinate)
            .addStaticMethod("setGridCoordinates", &ModestMaps::setGridCoordinates)
            .addStaticMethod("getGridInverseMatrix", &ModestMaps::getGridInverseMatrix)
            .addStaticMethod("getMSProviderZoomString", &ModestMaps::getMSProviderZoomString)

        .endClass()

    .endPackage();

    return 0;
}


void installLoomModestMaps()
{
    LOOM_DECLARE_NATIVETYPE(ModestMaps, registerLoomModestMaps);
}
