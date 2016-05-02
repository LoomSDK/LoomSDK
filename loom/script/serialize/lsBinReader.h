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

#ifndef _lsbinreader_h
#define _lsbinreader_h

#include "jansson.h"

#include "loom/common/utils/utByteArray.h"
#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/reflection/lsAssembly.h"
#include "loom/script/serialize/lsBinWriter.h"

namespace LS {
/*
 * Recursively read an executable binary assembly into a VM and prepare
 * it for execution
 */
class BinReader {
    /*
     * An Assembly reference
     */
    struct Reference
    {
        // the name of the Assembly
        const char *name;
        // the uniqie ID of the Assembly
        const char *uid;
        // the position within the binary file
        int        position;
        // the length of the binary data
        int        length;
        // whether or not the assembly has been loaded
        bool       loaded;
        // The loaded assembly.
        Assembly *assembly;
    };

    /*
     * All types are indexed within the binary data
     */
    struct TypeIndex
    {
        // The index of the refernce assembly this Type belongs to
        int        refIdx;
        // The fully qualified name of the Type
        const char *fullName;
        // The position in the binary data
        int        position;
        // The length of the data
        int        length;
        // The system.reflection Type
        Type       *type;
    };

    // Full qualified typename -> TypeIndex
    static utHashTable<utHashedString, TypeIndex *> types;
    // Reference name -> Reference
    static utHashTable<utHashedString, Reference *> references;
    // The VM we are loading the assemblty into
    static LSLuaState *vm;
    // All of the strings in the assembly are stored (and reused) from
    // a single buffer;
    static const char *stringBuffer;
    // The buffer is sliced into an array for quick lookups
    static utArray<const char *> stringPool;
    // The byte array of the entire binary
    static utByteArray *sBytes;
    // initialized the string pool from the binary file
    static void readStringPool();

    /*
     * Reads a string from the string pool
     */
    static const char *readPoolString()
    {
        int i = sBytes->readInt();

        if (i == -1)
        {
            return "";
        }
        return stringPool[i];
    }

    /*
     * Given a fully qualified type name, return the associated Type
     */
    static Type *getType(const char *fullname)
    {
        if (fullname && strlen(fullname))
        {
            if (types.find(fullname) == UT_NPOS)
            {
                return vm->getType(fullname);
            }

            TypeIndex **tindex = types.get(fullname);
            assert(tindex);
            return (*tindex)->type;
        }

        return NULL;
    }

    /*
     * Given a fully qualified type name, seek to the type in the binary data
     */
    static void seekType(const char *fullname)
    {
        TypeIndex *tindex = *(types.get(utHashedString(fullname)));

        sBytes->setPosition(tindex->position);
    }

    /*
     * The bytes of the currently loading assembly, which may be the executable
     * of a reference assembly
     */
    utByteArray *bytes;

    /*
     * The current assembly (which are recursively loaded);
     */
    Assembly *assembly;

    /*
     * Reads the TemplateInfo for a Vector/Dictionary type
     */
    TemplateInfo *readTemplateTypes();

    /*
     * Reads the basic MemberInfo common to all Types and Members
     */
    void readMemberInfo(MemberInfo *memberInfo);

    /*
     * Reads a FieldInfo for the given Type
     */
    FieldInfo *readField(Type *type);

    /*
     * Reads a PropertyInfo for the given Type
     */
    PropertyInfo *readProperty(Type *type);

    /*
     * Reads a MethodBase which are shared by MethodInfos and ConstructorInfos
     */
    void readMethodBase(MethodBase *mbase);

    /*
     * Reads a Constructor
     */
    ConstructorInfo *readConstructor(Type *type);

    /*
     * Reads a MethodInfo for the given Type
     */
    MethodInfo *readMethodInfo(Type *type);

    /*
     * Reads class information for the given Type
     */
    void readClass(Type *type);

    /*
     * Reads a basic type information and returns the Type
     */
    Type *readType();

    /*
     * Reads the current Assembly's modules
     */
    void readModules();

    /*
    * Reads the Assembly and adds it into the loaded VM
    */
    Assembly *readAssembly(utByteArray *_bytes);

    /*
    * Reads an assembly header and returns it as an Assembly
    */
    Assembly *readAssemblyHeader(utByteArray *_bytes);

    /*
    * Reads the Assembly body
    */
    void readAssemblyBody(Assembly *assembly);

public:
    
    /*
     * Reads a binary executable assembly into the given VM from the provided utByteArray
     * and prepares it for execution
     */
    static Assembly *loadExecutable(LSLuaState *_vm, utByteArray *byteArray);

    /*
    * Reads a binary executable assembly header from the provided
    * utByteArray, use loadExecutableBody to load the body next
    */
    static void loadExecutableHeader(LSLuaState *_vm, utByteArray *byteArray);

    static Assembly *loadMainAssemblyHeader();

    /*
    * Reads a binary executable assembly body into the given VM from the provided
    * utByteArray
    */
    static Assembly *loadExecutableBody();
};
}
#endif
