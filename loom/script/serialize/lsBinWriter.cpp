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


#include "zlib.h"

#include "loom/common/core/allocator.h"
#include "loom/common/utils/utBase64.h"
#include "loom/common/utils/utStreams.h"
#include "lsBinWriter.h"

namespace LS {
utHashTable<utHashedString, int>         BinWriter::stringPool;
utHashTable<utHashedString, BinWriter *> BinWriter::binWriters;

loom_allocator_t *gBinWriterAllocator = NULL;

void BinWriter::writeMemberInfo(json_t* jminfo) {

    int iname = poolJString(json_object_get(jminfo, "name"));
    int isource = -1;
    int ilinenumber = -1;

    json_t *jsource = json_object_get(jminfo, "source");

    if (jsource && json_is_string(jsource))
    {
        isource     = poolString(json_string_value(jsource));
        ilinenumber = (int)json_integer_value(json_object_get(jminfo, "line"));
    }

    bytes.writeInt(iname);
    bytes.writeInt((int)json_integer_value(json_object_get(jminfo, "ordinal")));
    bytes.writeInt(isource);
    bytes.writeInt(ilinenumber);

    json_t *meta_object = json_object_get(jminfo, "metainfo");

    size_t meta_object_size = json_object_size(meta_object);

    // write the size of the object
    bytes.writeInt((int)meta_object_size);

    void *iter = json_object_iter(meta_object);

    size_t count = 0;

    while (iter)
    {
        // write the name to the pool table
        bytes.writeInt(poolString(json_object_iter_key(iter)));

        json_t *metaArray = json_object_iter_value(iter);

        // write the length of the meta array
        bytes.writeInt((int)json_array_size(metaArray));

        for (UTsize i = 0; i < json_array_size(metaArray); i++)
        {
            json_t *keyArray = json_array_get(metaArray, i);

            // write the length of the key array
            bytes.writeInt((int)json_array_size(keyArray));

            for (UTsize j = 0; j < json_array_size(keyArray); j++)
            {
                bytes.writeInt(poolString(json_string_value(json_array_get(keyArray, j))));
            }
        }

        iter = json_object_iter_next(meta_object, iter);
        count++;
    }

    lmAssert(meta_object_size == count, "json object size mismatch");
}


void BinWriter::writeTemplateTypes(json_t *jttypes)
{
    if (!json_is_object(jttypes))
    {
        bytes.writeBoolean(false);
        return;
    }

    json_t *types = json_object_get(jttypes, "types");
    json_t *type  = json_object_get(jttypes, "type");

    if (!types)
    {
        bytes.writeBoolean(false);
        return;
    }

    bytes.writeBoolean(true);

    bytes.writeInt(poolString(json_string_value(type)));
    bytes.writeInt((int)json_array_size(types));

    for (UTsize i = 0; i < json_array_size(types); i++)
    {
        json_t *element = json_array_get(types, i);

        if (json_is_string(element))
        {
            bytes.writeBoolean(false);
            bytes.writeInt(poolString(json_string_value(element)));
        }
        else if (json_is_object(element))
        {
            bytes.writeBoolean(true);
            writeTemplateTypes(element);
        }
        else
        {
            assert(0);
        }
    }
}


void BinWriter::writeMethodInfo(json_t *jminfo)
{
    writeMethodBase(jminfo);

    utString returnType = json_string_value(json_object_get(jminfo, "returntype"));

    if (returnType.size() > 0)
    {
        bytes.writeBoolean(true);
        bytes.writeInt(poolString(returnType.c_str()));
    }
    else
    {
        bytes.writeBoolean(false);
    }
}


void BinWriter::writeProperty(json_t *jprop)
{
    writeMemberInfo(jprop);

    // write attributes
    json_t *attr_array = json_object_get(jprop, "propertyattributes");

    bytes.writeInt((int)json_array_size(attr_array));

    for (size_t i = 0; i < json_array_size(attr_array); i++)
    {
        bytes.writeInt(poolJString(json_array_get(attr_array, i)));
    }

    utString stype = json_string_value(json_object_get(jprop, "type"));
    if (stype.size() > 0)
    {
        bytes.writeBoolean(true);
        bytes.writeInt(poolString(stype.c_str()));
    }
    else
    {
        bytes.writeBoolean(false);
    }

    json_t *getter = json_object_get(jprop, "getter");
    json_t *setter = json_object_get(jprop, "setter");

    if (getter)
    {
        bytes.writeBoolean(true);
        writeMethodInfo(getter);
    }
    else
    {
        bytes.writeBoolean(false);
    }

    if (setter)
    {
        bytes.writeBoolean(true);
        writeMethodInfo(setter);
    }
    else
    {
        bytes.writeBoolean(false);
    }
}


void BinWriter::writeField(json_t *jfield)
{
    writeMemberInfo(jfield);

    // handle attr
    json_t *field_attr = json_object_get(jfield, "fieldattributes");

    bytes.writeInt((int)json_array_size(field_attr));

    for (size_t i = 0; i < json_array_size(field_attr); i++)
    {
        bytes.writeInt(poolJString(json_array_get(field_attr, i)));
    }

    utString stype = json_string_value(json_object_get(jfield, "type"));

    if (stype.size() > 0)
    {
        bytes.writeBoolean(true);
        bytes.writeInt(poolString(stype.c_str()));
    }
    else
    {
        bytes.writeBoolean(false);
    }

    // handle template types

    json_t *ttypes = json_object_get(jfield, "templatetypes");
    if (ttypes && json_is_object(ttypes))
    {
        bytes.writeBoolean(true);
        writeTemplateTypes(ttypes);
    }
    else
    {
        bytes.writeBoolean(false);
    }
}


void BinWriter::writeMethodBase(json_t *jmbase)
{
    writeMemberInfo(jmbase);

    // handle modifiers
    json_t *mod_array = json_object_get(jmbase, "methodattributes");

    bytes.writeInt((int)json_array_size(mod_array));

    for (size_t i = 0; i < json_array_size(mod_array); i++)
    {
        bytes.writeInt(poolJString(json_array_get(mod_array, i)));
    }

    // template types on return
    json_t *ttypes = json_object_get(jmbase, "templatetypes");
    if (ttypes && json_is_object(ttypes))
    {
        bytes.writeBoolean(true);
        writeTemplateTypes(ttypes);
    }
    else
    {
        bytes.writeBoolean(false);
    }

    // parameters
    json_t *parameter_array = json_object_get(jmbase, "parameters");

    bytes.writeInt((int)json_array_size(parameter_array));

    for (size_t i = 0; i < json_array_size(parameter_array); i++)
    {
        json_t *p = json_array_get(parameter_array, i);

        bytes.writeInt(poolJString(json_object_get(p, "name")));
        utString stype = json_string_value(json_object_get(p, "type"));
        if (stype.size() > 0)
        {
            bytes.writeBoolean(true);
            bytes.writeInt(poolString(stype.c_str()));
        }
        else
        {
            bytes.writeBoolean(false);
        }

        if (json_is_true(json_object_get(p, "hasdefault")))
        {
            bytes.writeBoolean(true);
        }
        else
        {
            bytes.writeBoolean(false);
        }

        if (json_is_true(json_object_get(p, "isvarargs")))
        {
            bytes.writeBoolean(true);
        }
        else
        {
            bytes.writeBoolean(false);
        }

        // handle template types
        json_t *ttypes = json_object_get(p, "templatetypes");

        bytes.writeInt((int)json_array_size(ttypes));

        for (size_t i = 0; i < json_array_size(ttypes); i++)
        {
            bytes.writeInt(poolJString(json_array_get(ttypes, i)));
        }
    }

    bytes.writeString(json_string_value(json_object_get(jmbase, "bytecode")));
}


void BinWriter::writeConstructor(json_t *jconstructor)
{
    writeMethodBase(jconstructor);

    if (json_is_true(json_object_get(jconstructor, "defaultconstructor")))
    {
        bytes.writeBoolean(true);
    }
    else
    {
        bytes.writeBoolean(false);
    }
}


void BinWriter::writeClass(json_t *jclass)
{
    writeMemberInfo(jclass);

    // handle class modifiers

    json_t *attr_array = json_object_get(jclass, "classattributes");

    bytes.writeInt((int)json_array_size(attr_array));

    for (size_t i = 0; i < json_array_size(attr_array); i++)
    {
        bytes.writeInt((int)poolJString(json_array_get(attr_array, i)));
    }

    // base class
    int ibaseType = -1;

    utString sbaseType = json_string_value(
        json_object_get(jclass, "baseType"));

    if (sbaseType.size() > 0)
    {
        ibaseType = poolString(sbaseType.c_str());
    }

    bytes.writeInt(ibaseType);

    // interfaces
    json_t *jinterfaces = json_object_get(jclass, "interfaces");

    bytes.writeInt((int)json_array_size(jinterfaces));

    for (size_t i = 0; i < json_array_size(jinterfaces); i++)
    {
        json_t *o = json_array_get(jinterfaces, i);
        bytes.writeInt(poolString(json_string_value(o)));
    }

    // delegate types
    json_t *jdelegate_types = json_object_get(jclass, "delegateTypes");

    bytes.writeInt((int)json_array_size(jdelegate_types));

    for (size_t i = 0; i < json_array_size(jdelegate_types); i++)
    {
        json_t *o = json_array_get(jdelegate_types, i);
        bytes.writeInt(poolString(json_string_value(o)));
    }


    // delegate return type
    int idelegatereturntype = -1;

    utString sdelegateReturnType = json_string_value(
        json_object_get(jclass, "delegateReturnType"));

    if (sdelegateReturnType.size() > 0)
    {
        idelegatereturntype = poolString(sdelegateReturnType.c_str());
    }

    bytes.writeInt(idelegatereturntype);

    // write imports

    json_t *import_array = json_object_get(jclass, "imports");

    bytes.writeInt((int)json_array_size(import_array));

    for (size_t i = 0; i < json_array_size(import_array); i++)
    {
        json_t *jimport = json_array_get(import_array, i);
        bytes.writeInt(poolString(json_string_value(jimport)));
    }

    // write constructor
    json_t *jconstructor = json_object_get(jclass, "constructor");

    if (jconstructor)
    {
        bytes.writeBoolean(true);
        writeConstructor(jconstructor);
    }
    else
    {
        bytes.writeBoolean(false);
    }

    // write fields

    json_t *field_array = json_object_get(jclass, "fields");

    bytes.writeInt((int)json_array_size(field_array));

    for (size_t i = 0; i < json_array_size(field_array); i++)
    {
        json_t *fo = json_array_get(field_array, i);
        writeField(fo);
    }

    // write properties
    json_t *prop_array = json_object_get(jclass, "properties");

    bytes.writeInt((int)json_array_size(prop_array));

    for (size_t i = 0; i < json_array_size(prop_array); i++)
    {
        json_t *po = json_array_get(prop_array, i);
        writeProperty(po);
    }


    // write methods
    json_t *method_array = json_object_get(jclass, "methods");

    bytes.writeInt((int)json_array_size(method_array));

    for (size_t i = 0; i < json_array_size(method_array); i++)
    {
        json_t *jmethod = json_array_get(method_array, i);
        writeMethodInfo(jmethod);
    }

    // static initializer byte code
    utString bc = json_string_value(json_object_get(jclass, "bytecode_staticinitializer"));

    bytes.writeString(bc.c_str());

    // instance initializer byte code
    bc = json_string_value(json_object_get(jclass, "bytecode_instanceinitializer"));

    bytes.writeString(bc.c_str());
}


void BinWriter::writeType(json_t *jtype)
{
    TypeIndex *tindex = lmNew(NULL) TypeIndex;

    typeIndexes.push_back(tindex);

    tindex->position = bytes.getPosition();

    utString package = json_string_value(json_object_get(jtype, "package"));
    utString name    = json_string_value(json_object_get(jtype, "name"));

    utString fullname = package;
    fullname += ".";
    fullname += name;

    tindex->iFullName = poolString(fullname.c_str());

    int itype        = poolJString(json_object_get(jtype, "type"));
    int ipackagename = poolString(package.c_str());
    int iname        = poolString(name.c_str());

    json_t *jtypeid = json_object_get(jtype, "typeid");
    assert(jtypeid && json_is_number(jtypeid));

    int itypeid = (int)json_number_value(jtypeid);

    int isource     = -1;
    int ilinenumber = -1;

    json_t *jsource = json_object_get(jtype, "source");

    if (jsource && json_is_string(jsource))
    {
        isource     = poolString(json_string_value(jsource));
        ilinenumber = (int)json_integer_value(json_object_get(jtype, "line"));
    }

    bytes.writeInt(itype);
    bytes.writeInt(ipackagename);
    bytes.writeInt(iname);
    bytes.writeInt(itypeid);
    bytes.writeInt(isource);
    bytes.writeInt(ilinenumber);

    writeClass(jtype);

    tindex->length = bytes.getPosition() - tindex->position;
}


void BinWriter::writeModules(json_t *json)
{
    // modules
    json_t *module_array = json_object_get(json, "modules");

    bytes.writeInt((int)json_array_size(module_array));

    for (UTsize i = 0; i < json_array_size(module_array); i++)
    {
        json_t *jmodule = json_array_get(module_array, i);

        int itype    = poolJString(json_object_get(jmodule, "type"));
        int iname    = poolJString(json_object_get(jmodule, "name"));
        int iversion = poolJString(json_object_get(jmodule, "version"));

        bytes.writeInt(itype);
        bytes.writeInt(iname);
        bytes.writeInt(iversion);

        // types
        json_t *type_array = json_object_get(jmodule, "types");

        bytes.writeInt((int)json_array_size(type_array));

        for (UTsize j = 0; j < json_array_size(type_array); j++)
        {
            json_t *jtype = json_array_get(type_array, j);
            writeType(jtype);
        }
    }
}


void BinWriter::writeAssembly(const char *sjson, int jsonSize)
{
    json_error_t jerror;
    json_t       *json = json_loadb(sjson, jsonSize, 0, &jerror);

    lmAssert(json, "Error loading Assembly json: %s\n %s %i\n", jerror.source, jerror.text, jerror.line);

    writeAssembly(json);
}


void BinWriter::writeAssembly(json_t *json)
{
    // reserve 32 megs
    bytes.reserve(1024 * 1024 * 32);

    int itype = poolJString(json_object_get(json, "type"));

    const char *uid = json_string_value(json_object_get(json, "uid"));

    binWriters.insert(utHashedString(uid), this);

    int iname       = poolJString(json_object_get(json, "name"));
    int iversion    = poolJString(json_object_get(json, "version"));
    int iuid        = poolString(uid);
    int iloomconfig = 0;

    bool executable = false;
    if (json_object_get(json, "executable") && json_is_true(json_object_get(json, "executable")))
    {
        executable = true;
    }

    iloomconfig = poolJString(json_object_get(json, "loomconfig"));

    bool jit = false;
    if (json_object_get(json, "jit") && json_is_true(json_object_get(json, "jit")))
    {
        jit = true;
    }

    bool debugbuild = false;
    if (json_object_get(json, "debugbuild") && json_is_true(json_object_get(json, "debugbuild")))
    {
        debugbuild = true;
    }

    // basic info
    bytes.writeInt(itype);
    bytes.writeInt(iname);
    bytes.writeInt(iversion);
    bytes.writeInt(iuid);
    bytes.writeInt(iloomconfig);

    // write out flags
    bytes.writeBoolean(executable);
    bytes.writeBoolean(jit);
    bytes.writeBoolean(debugbuild);

    // recursively write references

    json_t *ref_array = json_object_get(json, "references");
    lmAssert(ref_array, "Error with executable assembly, missing references section");

    // write number of references
    bytes.writeInt((int)json_array_size(ref_array));

    for (size_t j = 0; j < json_array_size(ref_array); j++)
    {
        json_t     *jref    = json_array_get(ref_array, j);
        json_t     *jbinary = json_object_get(jref, "binary");
        const char *refname = json_string_value(json_object_get(jref, "name"));
        const char *refuid = json_string_value(json_object_get(jref, "uid"));

        bytes.writeInt(poolString(refname));
        bytes.writeInt(poolString(refuid));

        // already referenced
        if (binWriters.get(utHashedString(refuid)))
        {
            continue;
        }

        if (executable)
        {
            lmAssert(jbinary, "Error with linked assembly %s, missing binary section", refname);
            utString  refjson  = (const char *)utBase64::decode64(json_string_value(jbinary)).getData().ptr();
            BinWriter *bwriter = lmNew(NULL) BinWriter(refname);
            lmAssert(refjson.length() > 0, "Refjson should not be empty! %s", json_string_value(jbinary));
            bwriter->writeAssembly(refjson.c_str(), refjson.length());
        }
    }

    writeModules(json);
}


void BinWriter::writeExecutable(const char *path, const char *sjson, int jsonSize)
{
    json_error_t jerror;
    json_t       *json = json_loadb(sjson, jsonSize, 0, &jerror);

    lmAssert(json, "Error loading Assembly json: %s\n %s %i\n", jerror.source, jerror.text, jerror.line);

    writeExecutable(path, json);
}


void BinWriter::writeExecutable(const char *path, json_t *sjson)
{
    stringPool.clear();
    binWriters.clear();

    utByteArray bytes;
    // reserve 32 megs
    bytes.reserve(1024 * 1024 * 32);

    const char *name = json_string_value(json_object_get(sjson, "name"));
    BinWriter *bexec = lmNew(NULL) BinWriter(name);
    bexec->writeAssembly(sjson);

    // write string pool
    bytes.writeInt((int)stringPool.size());

    // calculate entire buffer size of string pool
    int stringBufferSize = 0;
    for (UTsize i = 0; i < stringPool.size(); i++)
    {
        stringBufferSize += sizeof(int);                               // length
        stringBufferSize += strlen(stringPool.keyAt(i).str().c_str()); // characters
    }

    // length of entire string buffer
    bytes.writeInt(stringBufferSize);

    for (UTsize i = 0; i < stringPool.size(); i++)
    {
        bytes.writeString(stringPool.keyAt(i).str().c_str());
    }

    // generate the type table
    utArray<TypeIndex *> types;
    for (UTsize i = 0; i < binWriters.size(); i++)
    {
        BinWriter *bref = binWriters.at(i);

        for (UTsize j = 0; j < bref->typeIndexes.size(); j++)
        {
            TypeIndex *tindex = bref->typeIndexes.at(j);
            tindex->refIdx = (int)i;
            types.push_back(tindex);
        }
    }

    // write the type table

    bytes.writeInt((int)types.size());

    for (UTsize i = 0; i < types.size(); i++)
    {
        TypeIndex *tindex = types.at(i);
        bytes.writeInt(tindex->refIdx);
        bytes.writeInt(tindex->iFullName);
        bytes.writeInt(tindex->position);
        bytes.writeInt(tindex->length);
    }

    // write out the number of references
    bytes.writeInt((int)binWriters.size());

    // write out reference table (which will allow random access if we want/need it)
    int position = bytes.getPosition() + (binWriters.size() * (sizeof(int) * 4));

    for (UTsize i = 0; i < binWriters.size(); i++)
    {
        BinWriter *bref = binWriters.at(i);
        // (interned) name
        utHashedString uid = binWriters.keyAt(i);
        bytes.writeInt(poolString(binWriters.at(i)->name.c_str()));
        // uid
        bytes.writeInt(poolString(binWriters.keyAt(i).str().c_str()));


        // length
        int length = bref->bytes.getPosition();
        bytes.writeInt(length);
        // position (offset from reference table)
        bytes.writeInt(position);
        position += length;
    }

    for (UTsize i = 0; i < binWriters.size(); i++)
    {
        BinWriter *bref = binWriters.at(i);
        bytes.writeBytes(&bref->bytes);
    }

    int dataLength = bytes.getPosition();

    Bytef *compressed = (Bytef *) lmAlloc(gBinWriterAllocator, dataLength);
    uLongf length = (uLongf) dataLength;
    int ok = compress(compressed, &length, (Bytef *) bytes.getDataPtr(), (uLong) dataLength);
    lmAssert(ok == Z_OK, "problem compressing executable assemby");

    bytes.clear();
    bytes.writeUnsignedInt(LOOM_BINARY_ID);
    bytes.writeUnsignedInt(LOOM_BINARY_VERSION_MAJOR);
    bytes.writeUnsignedInt(LOOM_BINARY_VERSION_MINOR);
    bytes.writeUnsignedInt((unsigned int)dataLength);

    utFileStream binStream;
    binStream.open(path, utStream::SM_WRITE);
    // write header
    binStream.write(bytes.getDataPtr(), sizeof(unsigned int) * 4);
    // write compressed data
    binStream.write(compressed, length);

    binStream.close();

    lmFree(gBinWriterAllocator, compressed);
}
}
