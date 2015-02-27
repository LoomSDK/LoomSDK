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

#include "loom/script/native/core/system/lmJSON.h"

using namespace LS;

JSON::JSON() : _json(NULL), _root(false)
{
}

bool JSON::clear() {
    if (_json)
    {
        if (_root)
        {
            json_decref(_json);
            _root = false;
        }
        _json = NULL;
        return true;
    }
    return false;
}

JSON::~JSON()
{
    clear();
}

bool JSON::initObject() {
    clear();

    _json = json_object();
    if (_json) _root = true;

    return _json == NULL ? false : true;
}

bool JSON::initArray() {
    clear();

    _json = json_array();
    if (_json) _root = true;

    return _json == NULL ? false : true;
}

bool JSON::loadString(const char *json)
{
    clear();

    _json = json_loads(json, JSON_DISABLE_EOF_CHECK, &_error);

    if (!_json)
    {
        char message[1024];
        snprintf(message, 1024,
                 "JSON Error: Line %i Column %i Position %i, %s (Source: %s)",
                 _error.line, _error.column, _error.position, _error.text,
                 _error.source);

        _errorMsg = message;
    }
    else
    {
        _errorMsg = "";
    }

    if (_json) _root = true;

    return _json == NULL ? false : true;
}

const char *JSON::serialize()
{
    if (!_json)
    {
        return NULL;
    }
    return json_dumps(_json, JSON_SORT_KEYS);
}

const char *JSON::getError()
{
    return _errorMsg.c_str();
}

int JSON::getJSONType()
{
    if (!_json)
    {
        return JSON_NULL;
    }
    return json_typeof(_json);
}

int JSON::getObjectJSONType(const char *key)
{
    if (!_json || isArray())
    {
        return JSON_NULL;
    }
    
    json_t *jobject = json_object_get(_json, key);
    
    if (!jobject)
    {
        return JSON_NULL;
    }
    
    return json_typeof(jobject);
}

int JSON::getArrayJSONType(int index)
{
    if (!isArray())
    {
        return JSON_NULL;
    }
    
    json_t *jobject = json_array_get(_json, index);
    
    if (!jobject)
    {
        return JSON_NULL;
    }
    
    return json_typeof(jobject);
}

const char *JSON::getLongLongAsString(const char *key)
{
    if (!_json)
    {
        return "";
    }

    json_t *jllu = json_object_get(_json, key);

    if (!jllu)
    {
        return "";
    }

    //create static char buffer to return to Loomscript (it makes a copy of this, so it will not be overwritten)
    //NOTE: the longest string length of an unsigned long long is 20 characters (0 to 18446744073709551615) + null terminator
    static char buffer[32];
    memset(buffer, 0x00, 32);
    unsigned long long val = (unsigned long long)json_integer_value(jllu);
    sprintf(buffer, "%llu", val);

    return buffer;
}    

int JSON::getInteger(const char *key)
{
    if (!_json)
    {
        return 0;
    }

    json_t *jint = json_object_get(_json, key);

    if (!jint)
    {
        return 0;
    }

    return (int)json_integer_value(jint);
}

void JSON::setInteger(const char *key, int value)
{
    if (!_json)
    {
        return;
    }

    json_object_set(_json, key, json_integer(value));
}

double JSON::getFloat(const char *key)
{
    if (!_json)
    {
        return 0;
    }

    json_t *jreal = json_object_get(_json, key);

    if (!jreal)
    {
        return 0;
    }

    return (double)json_real_value(jreal);
}

void JSON::setFloat(const char *key, float value)
{
    if (!_json)
    {
        return;
    }

    json_object_set(_json, key, json_real(value));
}

double JSON::getNumber(const char *key)
{
    if (!_json)
    {
        return 0;
    }

    json_t *jreal = json_object_get(_json, key);

    if (!jreal)
    {
        return 0;
    }

    return (double)json_number_value(jreal);
}

void JSON::setNumber(const char *key, double value)
{
    if (!_json)
    {
        return;
    }

    json_object_set(_json, key, json_real(value));
}

bool JSON::getBoolean(const char *key)
{
    if (!_json)
    {
        return false;
    }

    json_t *jbool = json_object_get(_json, key);

    if (!jbool || !json_is_boolean(jbool))
    {
        return false;
    }

    return json_is_true(jbool);
}

void JSON::setBoolean(const char *key, bool value)
{
    if (!_json)
    {
        return;
    }

    json_object_set(_json, key, value ? json_true() : json_false());
}

const char *JSON::getString(const char *key)
{
    if (!_json)
    {
        return "";
    }

    json_t *jstring = json_object_get(_json, key);

    if (!jstring)
    {
        return "";
    }

    return json_string_value(jstring);
}

void JSON::setString(const char *key, const char *value)
{
    if (!_json)
    {
        return;
    }

    json_object_set(_json, key, json_string(value));
}

// Objects
JSON *JSON::getObject(const char *key)
{
    if (!_json)
    {
        return NULL;
    }

    json_t *jobject = json_object_get(_json, key);

    if (!jobject || !json_is_object(jobject))
    {
        return NULL;
    }

    JSON *jin = new JSON();
    json_incref(jobject);
    jin->_json = jobject;

    return jin;
}

void JSON::setObject(const char *key, JSON *object)
{
    if (!_json || !object || !object->_json || !json_is_object(object->_json))
    {
        return;
    }

    json_object_set(_json, key, object->_json);
}

bool JSON::isObject()
{
    if (!_json)
    {
        return false;
    }

    return json_is_object(_json);
}

const char *JSON::getObjectFirstKey()
{
    if (!_json)
    {
        return "";
    }

    void *iter = json_object_iter(_json);
    if (!iter)
    {
        return "";
    }

    return json_object_iter_key(iter);
}

const char *JSON::getObjectNextKey(const char *key)
{
    if (!_json)
    {
        return "";
    }

    void *iter = json_object_iter_next(_json, json_object_iter_at(_json, key));
    if (!iter)
    {
        return "";
    }

    return json_object_iter_key(iter);
}

// Arrays
JSON *JSON::getArray(const char *key)
{
    if (!_json)
    {
        return NULL;
    }

    json_t *jarray = json_object_get(_json, key);

    if (!jarray || !json_is_array(jarray))
    {
        return NULL;
    }

    JSON *jin = new JSON();
    json_incref(jarray);
    jin->_json = jarray;

    return jin;
}

void JSON::setArray(const char *key, JSON *object)
{
    if (!object || !object->_json || !json_is_array(object->_json))
    {
        return;
    }

    json_object_set(_json, key, object->_json);
}

bool JSON::isArray()
{
    if (!_json)
    {
        return false;
    }

    return json_is_array(_json);
}

int JSON::getArrayCount()
{
    if (!isArray())
    {
        return 0;
    }

    return (int)json_array_size(_json);
}

bool JSON::getArrayBoolean(int index)
{
    if (!isArray())
    {
        return false;
    }

    json_t *jobject = json_array_get(_json, index);

    if (!jobject || !json_is_boolean(jobject))
    {
        return false;
    }

    return json_is_true(jobject);
}

void JSON::setArrayBoolean(int index, bool value)
{
    if (!isArray())
    {
        return;
    }

    expandArray(index + 1);

    json_array_set(_json, index, value ? json_true() : json_false());
}

int JSON::getArrayInteger(int index)
{
    if (!isArray())
    {
        return 0;
    }

    json_t *jobject = json_array_get(_json, index);

    if (!jobject || !json_is_integer(jobject))
    {
        return 0;
    }

    return (int)json_integer_value(jobject);
}

void JSON::setArrayInteger(int index, int value)
{
    if (!isArray())
    {
        return;
    }

    expandArray(index + 1);

    json_array_set(_json, index, json_integer(value));
}

float JSON::getArrayFloat(int index)
{
    if (!isArray())
    {
        return 0.f;
    }

    json_t *jobject = json_array_get(_json, index);

    if (!jobject || !json_is_real(jobject))
    {
        return 0.f;
    }

    return (float)json_real_value(jobject);
}

void JSON::setArrayFloat(int index, float value)
{
    if (!isArray())
    {
        return;
    }

    expandArray(index + 1);

    json_array_set(_json, index, json_real(value));
}

double JSON::getArrayNumber(int index)
{
    if (!isArray())
    {
        return 0.f;
    }

    json_t *jobject = json_array_get(_json, index);

    if (!jobject || !json_is_number(jobject))
    {
        return 0.f;
    }

    return (double)json_number_value(jobject);
}

void JSON::setArrayNumber(int index, double value)
{
    if (!isArray())
    {
        return;
    }

    expandArray(index + 1);

    json_array_set(_json, index, json_real(value));
}

const char *JSON::getArrayString(int index)
{
    if (!isArray())
    {
        return "";
    }

    json_t *jobject = json_array_get(_json, index);

    if (!jobject || !json_is_string(jobject))
    {
        return "";
    }

    return json_string_value(jobject);
}

void JSON::setArrayString(int index, const char *value)
{
    if (!isArray())
    {
        return;
    }

    expandArray(index + 1);

    json_array_set(_json, index, json_string(value));
}

JSON *JSON::getArrayObject(int index)
{
    if (!isArray())
    {
        return NULL;
    }

    json_t *object = json_array_get(_json, index);

    if (!object || !json_is_object(object))
    {
        return NULL;
    }

    JSON *jin = new JSON();
    json_incref(object);
    jin->_json = object;
    return jin;
}

void JSON::setArrayObject(int index, JSON *value)
{
    if (!isArray() || !value || !value->_json || !json_is_object(value->_json))
    {
        return;
    }

    expandArray(index + 1);

    json_array_set(_json, index, value->_json);
}

JSON *JSON::getArrayArray(int index)
{
    if (!isArray())
    {
        return NULL;
    }

    json_t *object = json_array_get(_json, index);

    if (!object || !json_is_array(object))
    {
        return NULL;
    }

    JSON *jin = new JSON();
    json_incref(object);
    jin->_json = object;
    return jin;
}

void JSON::setArrayArray(int index, JSON *value)
{
    if (!isArray() || !value || !value->_json || !json_is_array(value->_json))
    {
        return;
    }

    expandArray(index + 1);

    json_array_set(_json, index, value->_json);
}

void JSON::expandArray(int desiredLength)
{
    if (!isArray())
    {
        return;
    }

    while ((int)json_array_size(_json) < desiredLength) { json_array_append_new(_json, json_null()); }
}




static int registerSystemJSON(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<JSON> ("JSON")
       .addConstructor<void (*)(void)>()
       .addMethod("initObject", &JSON::initObject)
       .addMethod("initArray", &JSON::initArray)
       .addMethod("loadString", &JSON::loadString)
       .addMethod("serialize", &JSON::serialize)

       .addMethod("getError", &JSON::getError)
       .addMethod("getJSONType", &JSON::getJSONType)
       .addMethod("getObjectJSONType", &JSON::getObjectJSONType)
       .addMethod("getArrayJSONType", &JSON::getArrayJSONType)

       .addMethod("getLongLongAsString", &JSON::getLongLongAsString)
       .addMethod("getInteger", &JSON::getInteger)
       .addMethod("setInteger", &JSON::setInteger)
       .addMethod("getFloat", &JSON::getFloat)
       .addMethod("setFloat", &JSON::setFloat)
       .addMethod("getNumber", &JSON::getNumber)
       .addMethod("setNumber", &JSON::setNumber)
       .addMethod("getString", &JSON::getString)
       .addMethod("setString", &JSON::setString)
       .addMethod("getBoolean", &JSON::getBoolean)
       .addMethod("setBoolean", &JSON::setBoolean)
       .addMethod("getObject", &JSON::getObject)
       .addMethod("setObject", &JSON::setObject)
       .addMethod("getArray", &JSON::getArray)
       .addMethod("setArray", &JSON::setArray)

       .addMethod("isObject", &JSON::isObject)
       .addMethod("getObjectFirstKey", &JSON::getObjectFirstKey)
       .addMethod("getObjectNextKey", &JSON::getObjectNextKey)

       .addMethod("isArray", &JSON::isArray)
       .addMethod("getArrayCount", &JSON::getArrayCount)

       .addMethod("getArrayBoolean", &JSON::getArrayBoolean)
       .addMethod("setArrayBoolean", &JSON::setArrayBoolean)

       .addMethod("getArrayInteger", &JSON::getArrayInteger)
       .addMethod("setArrayInteger", &JSON::setArrayInteger)

       .addMethod("getArrayFloat", &JSON::getArrayFloat)
       .addMethod("setArrayFloat", &JSON::setArrayFloat)

       .addMethod("getArrayNumber", &JSON::getArrayNumber)
       .addMethod("setArrayNumber", &JSON::setArrayNumber)

       .addMethod("getArrayString", &JSON::getArrayString)
       .addMethod("setArrayString", &JSON::setArrayString)

       .addMethod("getArrayObject", &JSON::getArrayObject)
       .addMethod("setArrayObject", &JSON::setArrayObject)

       .addMethod("getArrayArray", &JSON::getArrayArray)
       .addMethod("setArrayArray", &JSON::setArrayArray)


       .endClass()
       .endPackage();

    return 0;
}


void installSystemJSON()
{
    NativeInterface::registerManagedNativeType<JSON>(registerSystemJSON);
}
