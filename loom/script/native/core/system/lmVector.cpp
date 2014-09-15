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

#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsRuntime.h"

using namespace LS;

/**
 *  LoomScript Vector's have an internal table to hold their data, this table is 
 *  read bounds protected on access using this metatable function
 */
static int lsr_vectorinternal_index(lua_State *L)
{

    if (lua_isnumber(L, 2))
    {
        int idx = (int) lua_tonumber(L, 2);

        // indexing with a negative number is an error
        if (idx < 0)
        {
            lua_pushstring(L, "Vector indexed with negative number");
            lua_error(L);
            return 0;
        }
        
        lua_rawgeti(L, 1, LSINDEXVECTORLENGTH);

        // only check if our length has been initialized
        // it might not be if we're raw setting up vector data
        if (lua_isnumber(L, -1))
        {
            int length = (int) lua_tonumber(L, -1);

            if (idx >= length)
            {
                lua_pushfstring(L, "Vector read index out of bounds index: %f length: %f", (double) idx, (double) length);
                lua_error(L);
                return 0;
            }
        }

        lua_pop(L, 1);

    
    }

    lua_rawget(L, 1);
    return 1;
}


/**
 *  LoomScript Vector's have an internal table to hold their data, this table is 
 *  write bounds protected on access using this metatable function
 */
static int lsr_vectorinternal_newindex(lua_State *L)
{
    
    if (lua_isnumber(L, 2))
    {
        int idx = (int) lua_tonumber(L, 2);

        // indexing with a negative number is an error
        if (idx < 0)
        {
            lua_pushstring(L, "Vector indexed with negative number");
            lua_error(L);
            return 0;
        }
        
        lua_rawgeti(L, 1, LSINDEXVECTORLENGTH);

        // only check if our length has been initialized
        // it might not be if we're raw setting up vector data
        if (lua_isnumber(L, -1))
        {
            int length = (int) lua_tonumber(L, -1);

            if (idx >= length)
            {
                lua_pushfstring(L, "Vector write index out of bounds index: %f length: %f", (double) idx, (double) length);
                lua_error(L);
                return 0;
            }
        }

        lua_pop(L, 1);

    
    }

    lua_rawset(L, 1);
    return 0;
}

// creates the internal vector used by a Vector.<T> instance
static void lsr_create_internal_vector(lua_State *L)
{
    lua_newtable(L);

    luaL_getmetatable(L, LSVECTORINTERNAL);
    lua_setmetatable(L, -2);
}

class LSVector {
    /*
     * Sort Flags, these must match the const definitions in Vector.ls
     */
    enum SortFlags
    {
        CASEINSENSITIVE    = 1,
        DESCENDING         = 2,
        UNIQUESORT         = 4,
        RETURNINDEXEDARRAY = 8,
        NUMERIC            = 16
    };

public:

    static inline void checkNotFixed(lua_State *L, int idx)
    {
        lua_rawgeti(L, idx, LSINDEXVECTORFIXED);

        if (lua_toboolean(L, -1))
        {
            lua_pushstring(L, "invalid operation on fixed vector!");
            lua_error(L);
        }

        lua_pop(L, 1);
    }

    static int initialize(lua_State *L)
    {
        lsr_create_internal_vector(L);
        lua_rawseti(L, 1, LSINDEXVECTOR);        
        lua_pushboolean(L, 0);
        lua_rawseti(L, 1, LSINDEXVECTORFIXED);

        lsr_vector_set_length(L, 1, (int) lua_tonumber(L, 2));        


        return 0;
    }

    static int setFixed(lua_State *L)
    {
        lua_pushboolean(L, 1);
        lua_rawseti(L, 1, LSINDEXVECTORFIXED);

        return 0;
    }

    static int clear(lua_State *L)
    {
        checkNotFixed(L, 1);

        lsr_create_internal_vector(L);
        lua_rawseti(L, 1, LSINDEXVECTOR);

        lsr_vector_set_length(L, 1, 0);        

        return 0;
    }

    static int _push(lua_State *L)
    {
        checkNotFixed(L, 1);

        int length = lsr_vector_get_length(L, 1);

        lsr_vector_set_length(L, 1, length + 1);

        lua_rawgeti(L, 1, LSINDEXVECTOR);
        lua_pushnumber(L, length);
        lua_pushvalue(L, 2);
        lua_settable(L, -3);

        lua_pushvalue(L, 1);

        return 1;
    }

    static int shift(lua_State *L)
    {
        checkNotFixed(L, 1);

        int fidx = lua_gettop(L);

        int length = lsr_vector_get_length(L, fidx);

        if (!length)
        {
            lua_pushnil(L);
            return 1;
        }

        lua_rawgeti(L, fidx, LSINDEXVECTOR);

        int idx = lua_gettop(L);

        lua_pushnumber(L, 0);
        lua_gettable(L, -2);

        lsr_create_internal_vector(L);

        int nidx = lua_gettop(L);

        for (int i = 1; i < length; i++)
        {
            lua_pushnumber(L, i);
            lua_gettable(L, idx);

            lua_pushnumber(L, i - 1);
            lua_pushvalue(L, -2);
            lua_settable(L, nidx);

            // pop value
            lua_pop(L, 1);
        }

        lua_pushvalue(L, nidx);
        lua_rawseti(L, fidx, LSINDEXVECTOR);

        // update length
        lsr_vector_set_length(L, fidx, length - 1);


        lua_pushvalue(L, idx + 1);

        return 1;
    }

    static int length(lua_State *L)
    {
        lua_pushnumber(L, lsr_vector_get_length(L, 1));
        return 1;
    }

    static int setlength(lua_State *L)
    {
        // get the new length
        int nlength = (int)lua_tonumber(L, 2);

        lsr_vector_set_length(L, 1, nlength);

        return 0;
    }

    //FIXME: untested
    static int contains(lua_State *L)
    {
        int length = lsr_vector_get_length(L, 1);

        lua_rawgeti(L, 1, LSINDEXVECTOR);
        int vidx = lua_gettop(L);

        for (int i = 0; i < length; i++)
        {
            lua_pushnumber(L, i);
            lua_gettable(L, vidx);

            if (lua_equal(L, 2, -1))
            {
                lua_pushboolean(L, 1);
                return 1;
            }

            lua_pop(L, 1);
        }

        lua_pushboolean(L, 0);
        return 1;
    }

    static int remove(lua_State *L)
    {
        checkNotFixed(L, 1);

        int length = lsr_vector_get_length(L, 1);

        lua_rawgeti(L, 1, LSINDEXVECTOR);
        int vidx = lua_gettop(L);

        for (int i = 0; i < length; i++)
        {
            lua_pushnumber(L, i);
            lua_rawget(L, vidx);

            if (lua_equal(L, 2, -1))
            {
                // pop current value
                lua_pop(L, 1);

                // shift
                for (int j = i; j < length; j++)
                {
                    lua_pushnumber(L, j);
                    lua_pushnumber(L, j + 1);
                    lua_rawget(L, vidx);
                    lua_rawset(L, vidx);
                }

                lsr_vector_set_length(L, 1, length - 1);

                return 0;
            }

            lua_pop(L, 1);
        }

        return 1;
    }

    static int pop(lua_State *L)
    {
        checkNotFixed(L, 1);

        int fidx = lua_gettop(L);

        int length = lsr_vector_get_length(L, fidx);

        if (!length)
        {
            lua_pushnil(L);
            return 1;
        }

        lua_rawgeti(L, fidx, LSINDEXVECTOR);

        int idx = lua_gettop(L);

        // store for return
        lua_pushnumber(L, length - 1);
        lua_gettable(L, idx);

        lsr_vector_set_length(L, fidx, length - 1);


        return 1;
    }

    static int indexOf(lua_State *L)
    {
        int startIndex = (int)lua_tonumber(L, 3);

        int length = lsr_vector_get_length(L, 1);

        // are we out of range?
        if (startIndex >= length)
        {
            lua_pushnumber(L, -1);
            return 1;
        }

        lua_rawgeti(L, 1, LSINDEXVECTOR);
        int tableIdx = lua_gettop(L);

        for (int i = startIndex; i < length; i++)
        {
            lua_rawgeti(L, tableIdx, i);
            if (lua_equal(L, -1, 2))
            {
                lua_pushnumber(L, i);
                return 1;
            }
            lua_pop(L, 1);
        }

        lua_pushnumber(L, -1);
        return 1;
    }

    static void concatVector(lua_State *L, int toIdx, int fromIdx)
    {
        int top = lua_gettop(L);

        toIdx   = lua_absindex(L, toIdx);
        fromIdx = lua_absindex(L, fromIdx);

        int toLength = lsr_vector_get_length(L, toIdx);

        int fromLength = lsr_vector_get_length(L, fromIdx);

        lua_rawgeti(L, toIdx, LSINDEXVECTOR);
        int toTableIdx = lua_gettop(L);
        lua_rawgeti(L, fromIdx, LSINDEXVECTOR);
        int fromTableIdx = lua_gettop(L);

        for (int i = 0; i < fromLength; i++)
        {
            lua_pushnumber(L, i + toLength);
            lua_pushnumber(L, i);
            lua_rawget(L, fromTableIdx);
            lua_rawset(L, toTableIdx);
        }

        lsr_vector_set_length(L, toIdx, toLength + fromLength);

        lua_settop(L, top);
    }

    static int splice(lua_State *L)
    {
        int top = lua_gettop(L);

        int srcVectorLength = lsr_vector_get_length(L, 1);

        int startIndex  = (int)lua_tonumber(L, 2);
        int deleteCount = (int)lua_tonumber(L, 3);

        // varargs are in index 4

        // create our return vector
        Type *vectorType = LSLuaState::getLuaState(L)->getType("system.Vector");
        lsr_createinstance(L, vectorType);
        int newVectorIdx = lua_gettop(L);

        if (startIndex < 0)
        {
            startIndex = srcVectorLength + startIndex;
        }

        if (startIndex < 0)
        {
            startIndex = 0;
        }

        if (startIndex >= srcVectorLength)
        {
            startIndex = srcVectorLength;
        }

        if (deleteCount < 0)
        {
            deleteCount = srcVectorLength;
        }

        if (deleteCount > srcVectorLength)
        {
            deleteCount = srcVectorLength;
        }

        // handle deletion
        if (deleteCount > 0)
        {
            // bring in the source Vector's table
            lua_rawgeti(L, 1, LSINDEXVECTOR);
            int srcTableIdx = lua_gettop(L);

            // bring in the new Vector's table
            lua_rawgeti(L, newVectorIdx, LSINDEXVECTOR);
            int newTableIdx = lua_gettop(L);

            // we need to remove some elements, and make a new array o' them
            for (int i = 0; i < deleteCount; i++)
            {
                if (startIndex + i >= srcVectorLength)
                {
                    break;
                }

                // and copy into our new table
                lua_rawgeti(L, srcTableIdx, startIndex + i);
                lua_rawseti(L, newTableIdx, i);

                // increment new vector length
                lsr_vector_set_length(L, newVectorIdx, i + 1);
            }

            // we now need to shift all the rest of the elements down
            for (int i = startIndex; i < srcVectorLength; i++)
            {
                lua_rawgeti(L, srcTableIdx, i + deleteCount);
                lua_rawseti(L, srcTableIdx, i);
            }

            //zero out for GC
            for (int i = 0; i < deleteCount; i++)
            {
                lua_pushnil(L);
                lua_rawseti(L, srcTableIdx, srcVectorLength - i - 1);
            }


            // update the src vector length
            srcVectorLength -= deleteCount;

            lsr_vector_set_length(L, 1, srcVectorLength);            

            // pop vector tables
            lua_pop(L, 2);
        }

        int numVarArgs = lsr_vector_get_length(L, 4);        

        if (numVarArgs)
        {
            // we're doing an insertion

            // get possibly updated source vector length
            int srcVectorLength = lsr_vector_get_length(L, 1);

            // bring in the source Vector's table
            lua_rawgeti(L, 1, LSINDEXVECTOR);
            int srcTableIdx = lua_gettop(L);

            // bring in the var args table
            lua_rawgeti(L, 4, LSINDEXVECTOR);
            int argTableIdx = lua_gettop(L);

            // create a new table for src vector which will hold insertion
            lsr_create_internal_vector(L);
            int newTableIdx = lua_gettop(L);

            // first bring in everything before insertion
            int count = 0;
            for (int i = 0; i < startIndex; i++)
            {
                lua_rawgeti(L, srcTableIdx, i);
                lua_rawseti(L, newTableIdx, i);

                count++;
            }

            // do the insertion
            for (int i = 0; i < numVarArgs; i++)
            {
                lua_rawgeti(L, argTableIdx, i);
                lua_rawseti(L, newTableIdx, count++);
            }

            // ... and the rest
            for (int i = startIndex; i < srcVectorLength; i++)
            {
                lua_rawgeti(L, srcTableIdx, i);
                lua_rawseti(L, newTableIdx, count++);
            }

            // swap out for the new table
            lua_pushvalue(L, newTableIdx);
            lua_rawseti(L, 1, LSINDEXVECTOR);

            // and update the length
            lsr_vector_set_length(L, 1, count);

            // pop our table store
            lua_pop(L, 3);
        }

        // make sure only  the new vector is on the stack
        lmAssert(lua_gettop(L) == top + 1, "lua stack unaligned after Vector splice");

        return 1;
    }

    static int concat(lua_State *L)
    {
        int top = lua_gettop(L);

        // create our return vector
        Type *vectorType = LSLuaState::getLuaState(L)->getType("system.Vector");

        lsr_createinstance(L, vectorType);

        int newVectorIdx = lua_gettop(L);

        // first concat this vector to the new vector
        concatVector(L, newVectorIdx, 1);

        // now iterate over the varargs
        int numArgs = lsr_vector_get_length(L, 2);

        // bring in the Vector's table
        lua_rawgeti(L, 2, LSINDEXVECTOR);
        int argTableIdx = lua_gettop(L);

        lua_rawgeti(L, newVectorIdx, LSINDEXVECTOR);
        int newTableIdx = lua_gettop(L);

        for (int i = 0; i < numArgs; i++)
        {
            lua_pushnumber(L, i);
            lua_rawget(L, argTableIdx);

            if (lua_istable(L, -1))
            {
                //are we a Vector?
                lua_rawgeti(L, -1, LSINDEXVECTOR);

                if (!lua_isnil(L, -1))
                {
                    lua_pop(L, 1); // pop __ls_vector
                    concatVector(L, newVectorIdx, -1);
                    lua_pop(L, 1); // pop Vector
                    continue;
                }
                else
                {
                    // instance table and fall thru
                    lua_pop(L, 1); // pop nil
                }
            }

            // get the current length
            int curLength = lsr_vector_get_length(L, newVectorIdx);
            lua_pushnumber(L, curLength);

            lua_insert(L, -2);
            lua_rawset(L, newTableIdx);

            curLength++;
            lsr_vector_set_length(L, newVectorIdx, curLength);
        }

        lua_pop(L, 2); // pop the arg vector and new vector table

        // make sure only  the new vector is on the stack
        lmAssert(lua_gettop(L) == top + 1, "lua stack unaligned after Vector concat");

        return 1;
    }

    static int slice(lua_State *L)
    {
        int top = lua_gettop(L);

        int srcVectorLength = lsr_vector_get_length(L, 1);

        int startIndex = (int)lua_tonumber(L, 2);
        int endIndex   = (int)lua_tonumber(L, 3);

        // create our return vector
        Type *vectorType = LSLuaState::getLuaState(L)->getType("system.Vector");
        lsr_createinstance(L, vectorType);
        int newVectorIdx = lua_gettop(L);

        if (startIndex < 0)
        {
            startIndex = srcVectorLength + startIndex;
        }

        if (startIndex < 0)
        {
            startIndex = 0;
        }

        if (startIndex >= srcVectorLength)
        {
            startIndex = srcVectorLength;
        }

        if (endIndex < 0)
        {
            endIndex = srcVectorLength + endIndex;
        }

        if (endIndex < 0)
        {
            endIndex = 0;
        }

        if (endIndex > srcVectorLength)
        {
            endIndex = srcVectorLength;
        }

        // bring in the source Vector's table
        lua_rawgeti(L, 1, LSINDEXVECTOR);
        int srcTableIdx = lua_gettop(L);

        // get the new Vector's table
        lua_rawgeti(L, newVectorIdx, LSINDEXVECTOR);
        int newTableIdx = lua_gettop(L);

        int count = 0;
        for (int i = startIndex; i < endIndex; i++)
        {
            lua_pushnumber(L, i);
            lua_rawget(L, srcTableIdx);

            lua_pushnumber(L, count++);
            lua_insert(L, -2);
            lua_rawset(L, newTableIdx);
        }

        // store length
        lsr_vector_set_length(L, newVectorIdx, count);

        lua_pop(L, 2); // pop off the vector tables

        // make sure only  the new vector is on the stack
        lmAssert(lua_gettop(L) == top + 1, "lua stack unaligned after Vector slice");

        return 1;
    }

    // static state variables for access in qsort

    // the lua_State we're sorting in
    static lua_State *_sortState;
    // the vector table we're sorting
    static int _sortVectorIdx;
    // the length of the vector table
    static int _sortVectorLength;
    // current sort flags (for default sort only)
    static int _sortFlags;
    // whether we're aborting sort on UNIQUESORT flag
    static bool _sortUniqueAbort;
    // if we're using a sort Function instead of numeric/string sort
    static bool _sortFunction;

    // internal (qsort) function
    static int internalsort(const void *pidx1, const void *pidx2)
    {
        static char sbuffer1[1024];
        static char sbuffer2[1024];

        int idx1 = *((int *)pidx1);
        int idx2 = *((int *)pidx2);

        lua_State *L = _sortState;

        if (_sortFunction)
        {
            // we're using a sort function, so we need to
            // setup args and call the sort function

            lua_pushvalue(L, 2);
            lua_rawgeti(L, _sortVectorIdx, idx1);
            lua_rawgeti(L, _sortVectorIdx, idx2);
            lua_call(L, 2, 1);

            if (!lua_isnumber(L, -1))
            {
                lua_pushstring(L, "Vector.sort compare function did not return a number");
                lua_error(L);
            }

            int rval = (int)lua_tonumber(L, -1);
            lua_pop(L, 1);
            return rval;
        }

        // convert to string/number generic objects are undefined and should use a script sorting function

        const char *s1 = "";
        const char *s2 = "";

        double d1 = 0;
        double d2 = 0;

        lua_rawgeti(L, _sortVectorIdx, idx1);

        // please note, we MUST check string first as lua automatically converts numbers to strings :/
        if (lua_isnumber(L, -1))
        {
            d1 = lua_tonumber(L, -1);
            if (!(_sortFlags & NUMERIC))
            {
                snprintf(sbuffer1, 1024, "%512.8f", d1); // up to 512 digits before decimal and 8 after
                s1 = sbuffer1;
            }
        }
        else if (lua_isstring(L, -1))
        {
            s1 = lua_tostring(L, -1);
        }

        lua_pop(L, 1);

        lua_rawgeti(L, _sortVectorIdx, idx2);

        if (lua_isnumber(L, -1))
        {
            d2 = lua_tonumber(L, -1);
            if (!(_sortFlags & NUMERIC))
            {
                snprintf(sbuffer2, 1024, "%512.8f", d2); // up to 512 digits before decimal and 8 after
                s2 = sbuffer2;
            }
        }
        else if (lua_isstring(L, -1))
        {
            s2 = lua_tostring(L, -1);
        }

        lua_pop(L, 1);

        bool descending = _sortFlags & DESCENDING ? true : false;

        if (_sortFlags & NUMERIC)
        {
            if (d1 < d2)
            {
                return descending ? 1 : -1;
            }

            if (d1 > d2)
            {
                return descending ? -1 : 1;
            }


            if (_sortFlags & UNIQUESORT)
            {
                _sortUniqueAbort = true;
            }

            return 0;
        }

        int val = 0;

        if (_sortFlags & CASEINSENSITIVE)
        {
            val = descending ? -strcasecmp(s1, s2) : strcasecmp(s1, s2);
        }
        else
        {
            val = descending ? -strcmp(s1, s2) : strcmp(s1, s2);
        }

        if (!val)
        {
            _sortUniqueAbort = true;
        }

        return val;
    }

    static int sort(lua_State *L)
    {
        _sortState = L;

        _sortVectorLength = lsr_vector_get_length(L, 1);

        lua_rawgeti(L, 1, LSINDEXVECTOR);
        _sortVectorIdx = lua_absindex(L, -1);

        _sortFlags    = 0;
        _sortFunction = false;
        if (lua_isnumber(L, 2))
        {
            _sortFlags = (int)lua_tonumber(L, 2);
        }
        else if (lua_isfunction(L, 2) || lua_iscfunction(L, 2))
        {
            _sortFunction = true;
        }
        else
        {
            lmAssert(0, "INTERNAL ERROR: unknown parameter type to Vector.sort");
        }

        _sortUniqueAbort = false;

        int *indices = new int[_sortVectorLength];

        for (int i = 0; i < _sortVectorLength; i++)
        {
            indices[i] = i;
        }

        qsort(indices, _sortVectorLength, sizeof(int), internalsort);

        if (_sortUniqueAbort)
        {
            lua_pushnumber(L, 0);
            delete [] indices;
            return 1;
        }

        // create new table to hold the result
        lsr_create_internal_vector(L);

        if (_sortFlags & RETURNINDEXEDARRAY)
        {
            // populate index vector
            for (int i = 0; i < _sortVectorLength; i++)
            {
                lua_pushnumber(L, indices[i]);
                lua_rawseti(L, -2, i);
            }

            Type *vectorType = LSLuaState::getLuaState(L)->getType("system.Vector");            
            lsr_createinstance(L, vectorType);

            lua_pushvalue(L, -2); // return the new vector table
            lua_rawseti(L, -2, LSINDEXVECTOR);

            lsr_vector_set_length(L, -1, _sortVectorLength);

            delete [] indices;
            return 1;
        }

        // populate replacement vector
        for (int i = 0; i < _sortVectorLength; i++)
        {
            lua_rawgeti(L, _sortVectorIdx, indices[i]);
            lua_rawseti(L, -2, i);
        }

        // replace vector table
        lua_rawseti(L, 1, LSINDEXVECTOR);
        lsr_vector_set_length(L, 1, _sortVectorLength);

        lua_pushvalue(L, 1); // return the existing vector table
        delete [] indices;

        return 1;
    }
};

lua_State *LSVector::_sortState       = NULL;
int       LSVector::_sortVectorIdx    = -1;
int       LSVector::_sortVectorLength = -2;
int       LSVector::_sortFlags        = 0;
bool      LSVector::_sortUniqueAbort  = false;
bool      LSVector::_sortFunction     = false;

namespace LS {

int lsr_vector_get_length(lua_State *L, int index)
{
    index = lua_absindex(L, index);
    lua_rawgeti(L, index, LSINDEXVECTOR);
    lua_rawgeti(L, -1, LSINDEXVECTORLENGTH);
    int length = (int) lua_tonumber(L, -1);
    lua_pop(L, 2);
    return length;
}

void lsr_vector_set_length(lua_State *L, int index, int nlength)
{
        index = lua_absindex(L, index);
        
        LSVector::checkNotFixed(L, index);        

        // get the current length
        int clength = lsr_vector_get_length(L, index);

        // if we're a shorter vector we have to clear
        // old values for GC
        if (nlength < clength)
        {
            lua_rawgeti(L, index, LSINDEXVECTOR);

            for (int i = nlength; i < clength; i++)
            {
                lua_pushnil(L);
                lua_rawseti(L, -2, i);
            }

            lua_pop(L, 1);
        }

        // set the new length
        lua_rawgeti(L, index, LSINDEXVECTOR);
        lua_pushnumber(L, nlength);
        lua_rawseti(L, -2, LSINDEXVECTORLENGTH);
        lua_pop(L, 1);    
}

}


static int registerSystemVector(lua_State *L)
{

    // Specialized metatable for internal vector table accesses
    luaL_newmetatable(L, LSVECTORINTERNAL);

    lua_pushcfunction(L, lsr_vectorinternal_index);
    lua_setfield(L, -2, "__index");

    lua_pushcfunction(L, lsr_vectorinternal_newindex);
    lua_setfield(L, -2, "__newindex");

    beginPackage(L, "system")

       .beginClass<LSVector> ("Vector")

       .addStaticLuaFunction("initialize", &LSVector::initialize)
       .addStaticLuaFunction("pushSingle", &LSVector::_push)
       .addStaticLuaFunction("shift", &LSVector::shift)
       .addStaticLuaFunction("pop", &LSVector::pop)
       .addStaticLuaFunction("__pget_length", &LSVector::length)
       .addStaticLuaFunction("__pset_length", &LSVector::setlength)
       .addStaticLuaFunction("clear", &LSVector::clear)
       .addStaticLuaFunction("contains", &LSVector::contains)
       .addStaticLuaFunction("remove", &LSVector::remove)
       .addStaticLuaFunction("setFixed", &LSVector::setFixed)
       .addStaticLuaFunction("concat", &LSVector::concat)
       .addStaticLuaFunction("splice", &LSVector::splice)
       .addStaticLuaFunction("slice", &LSVector::slice)
       .addStaticLuaFunction("indexOf", &LSVector::indexOf)
       .addStaticLuaFunction("sort", &LSVector::sort)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemVector()
{
    NativeInterface::registerNativeType<LSVector>(registerSystemVector);
}
