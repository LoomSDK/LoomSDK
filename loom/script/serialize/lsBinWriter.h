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

#ifndef _lsbinwriter_h
#define _lsbinwriter_h

#include "jansson.h"

#include "loom/common/core/assert.h"
#include "loom/common/utils/utString.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utByteArray.h"

namespace LS {
// Loom executables are stamped with the
// LOOM_BINARY_ID, LOOM_BINARY_VERSION_MAJOR, LOOM_BINARY_VERSION_MINOR
// to verify at load time that they are not out of date
#define LOOM_BINARY_ID                            \
    ((unsigned int)(unsigned char)('M')           \
     | ((unsigned int)(unsigned char)('O') << 8)  \
     | ((unsigned int)(unsigned char)('O') << 16) \
     | ((unsigned int)(unsigned char)('L') << 24))

#define LOOM_BINARY_VERSION_MAJOR    1
#define LOOM_BINARY_VERSION_MINOR    1

/*
 * BinWriter recursively writes an executable binary assembly given a JSON source assembly
 * The binary assembly will include all dependencies linked in and uses zlib compression
 */
class BinWriter {
    /*
     * All types to be written are indexed as TypeIndex
     */
    struct TypeIndex
    {
        // which assembly reference this type belongs to
        int refIdx;
        // the index in the string pool holding the fully qualified name of the type
        int iFullName;
        // the position in the binary this type can be found at
        int position;
        // the length of the binary data
        int length;
    };

    // All strings in a binary assembly are pooled for performance and size
    static utHashTable<utHashedString, int> stringPool;

    // Assembly reference name to BinWriter lookup, for recursive writing of assembly data
    static utHashTable<utHashedString, BinWriter *> binWriters;

    // the bytes of the binary assembly
    utByteArray bytes;

    // All Types of the assembly will be indexed here
    utArray<TypeIndex *> typeIndexes;

    // Name of the assembly to write
    utString name;

    // Reflection Serialization

    /*
     * Write template type information (Vector/Dictionary) types
     * for the MemberInfo
     */
    void writeTemplateTypes(json_t *jttypes);

    /*
     * Writes basic MemberInfo data info to the byte array
     */
    void writeMemberInfo(json_t *jminfo);

    /*
     * Writes a PropertyInfo to the byte array
     */
    void writeProperty(json_t *jprop);

    /*
     * Writes a FieldInfo to the byte array
     */
    void writeField(json_t *jfield);

    /*
     * Writes a MethodBase to the byte array
     */
    void writeMethodBase(json_t *jmbase);

    /*
     * Writes a MethodInfo to the byte array
     */
    void writeMethodInfo(json_t *jminfo);

    /*
     * Writes a ConstructorInfo to the byte array
     */
    void writeConstructor(json_t *jconstructor);

    /*
     * Writes a Class to the byte array
     */
    void writeClass(json_t *jclass);

    /*
     * Writes a Type to the byte array
     */
    void writeType(json_t *jtype);

    /*
     * Writes the Assembly's modules to the byte array
     */
    void writeModules(json_t *json);

    /*
     * Recursively writes an assembly and it's references to the byte stream
     */
    void writeAssembly(json_t *json);

    void writeAssembly(const char *sjson, int sjsonSize);

public:

    BinWriter(const utString& _name)
    : name(_name)
    {
    }

    /*
     * Pools a string to the BinWriter's string pool to increase
     * performance and reduce size on binary loads
     */
    static int poolString(const char *string)
    {
        if (!string || !(*string))
        {
            return -1;
        }

        int *v = stringPool.get(string);
        if (v)
        {
            return *v;
        }

        int sz = stringPool.size();
        stringPool.insert(string, sz);

        return sz;
    }

    /*
     * Pools a JSON string
     */
    static int poolJString(json_t *jstring)
    {
        return poolString(json_string_value(jstring));
    }

    /*
     * Given a path, source JSON, and the size of the JSON
     * generates an executable assembly with all dependencies linked
     * in
     */
    static void writeExecutable(const char *path, const char *sjson, int jsonSize);

    /*
     * Given a path, source JSON, and the size of the JSON
     * generates an executable assembly with all dependencies linked
     * in
     */
    static void writeExecutable(const char *path, json_t *sjson);
};
}
#endif
