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

#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/reflection/lsType.h"
#include "loom/script/runtime/lsRuntime.h"
#include "jansson.h"

using namespace LS;

class JSON {
    // The native _json object
    json_t *_json;

    // JSON error codes
    json_error_t _error;
    utString     _errorMsg;
    bool         _root;

public:

    JSON() :
        _json(NULL), _root(false)
    {
    }

    ~JSON()
    {
        if (_json)
        {
            if (_root)
            {
                json_decref(_json);
            }
            _json = NULL;
        }
    }

    bool loadString(const char *json)
    {
        if (_json)
        {
            if (_root)
            {
                json_decref(_json);
            }
            _json = NULL;
        }

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

        if (_json)
        {
            _root = true;
        }

        return _json == NULL ? false : true;
    }

    const char *serialize()
    {
        if (!_json)
        {
            return NULL;
        }
        return json_dumps(_json, JSON_SORT_KEYS);
    }

    const char *getError()
    {
        return _errorMsg.c_str();
    }

    int getJSONType()
    {
        if (!_json)
        {
            return JSON_NULL;
        }
        return json_typeof(_json);
    }

    int getInteger(const char *key)
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

    void setInteger(const char *key, int value)
    {
        if (!_json)
        {
            return;
        }

        json_object_set(_json, key, json_integer(value));
    }

    double getFloat(const char *key)
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

    void setFloat(const char *key, float value)
    {
        if (!_json)
        {
            return;
        }

        json_object_set(_json, key, json_real(value));
    }

    bool getBoolean(const char *key)
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

    void setBoolean(const char *key, bool value)
    {
        if (!_json)
        {
            return;
        }

        json_object_set(_json, key, value ? json_true() : json_false());
    }

    const char *getString(const char *key)
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

    void setString(const char *key, const char *value)
    {
        if (!_json)
        {
            return;
        }

        json_object_set(_json, key, json_string(value));
    }

    // Objects
    JSON *getObject(const char *key)
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

    void setObject(const char *key, JSON *object)
    {
        if (!_json || !object || !object->_json || !json_is_object(object->_json))
        {
            return;
        }

        json_object_set(_json, key, object->_json);
    }

    bool isObject()
    {
        if (!_json)
        {
            return false;
        }

        return json_is_object(_json);
    }

    const char *getObjectFirstKey()
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

    const char *getObjectNextKey(const char *key)
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
    JSON *getArray(const char *key)
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

    void setArray(const char *key, JSON *object)
    {
        if (!object || !object->_json || !json_is_array(object->_json))
        {
            return;
        }

        json_object_set(_json, key, object->_json);
    }

    bool isArray()
    {
        if (!_json)
        {
            return false;
        }

        return json_is_array(_json);
    }

    int getArrayCount()
    {
        if (!isArray())
        {
            return 0;
        }

        return (int)json_array_size(_json);
    }

    bool getArrayBoolean(int index)
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

    void setArrayBoolean(int index, bool value)
    {
        if (!isArray())
        {
            return;
        }

        expandArray(index + 1);

        json_array_set(_json, index, value ? json_true() : json_false());
    }

    int getArrayInteger(int index)
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

    void setArrayInteger(int index, int value)
    {
        if (!isArray())
        {
            return;
        }

        expandArray(index + 1);

        json_array_set(_json, index, json_integer(value));
    }

    float getArrayFloat(int index)
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

    void setArrayFloat(int index, float value)
    {
        if (!isArray())
        {
            return;
        }

        expandArray(index + 1);

        json_array_set(_json, index, json_real(value));
    }

    const char *getArrayString(int index)
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

    void setArrayString(int index, const char *value)
    {
        if (!isArray())
        {
            return;
        }

        expandArray(index + 1);

        json_array_set(_json, index, json_string(value));
    }

    JSON *getArrayObject(int index)
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

    void setArrayObject(int index, JSON *value)
    {
        if (!isArray() || !value || !value->_json || !json_is_object(value->_json))
        {
            return;
        }

        expandArray(index + 1);

        json_array_set(_json, index, value->_json);
    }

    JSON *getArrayArray(int index)
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

    void setArrayArray(int index, JSON *value)
    {
        if (!isArray() || !value || !value->_json || !json_is_array(value->_json))
        {
            return;
        }

        expandArray(index + 1);

        json_array_set(_json, index, value->_json);
    }

    void expandArray(int desiredLength)
    {
        if (!isArray())
        {
            return;
        }

        while ((int)json_array_size(_json) < desiredLength) { json_array_append_new(_json, json_null()); }
    }
};

static int registerSystemJSON(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<JSON> ("JSON")
       .addConstructor<void (*)(void)>()
       .addMethod("loadString", &JSON::loadString)
       .addMethod("serialize", &JSON::serialize)

       .addMethod("getError", &JSON::getError)
       .addMethod("getJSONType", &JSON::getJSONType)

       .addMethod("getInteger", &JSON::getInteger)
       .addMethod("setInteger", &JSON::setInteger)
       .addMethod("getFloat", &JSON::getFloat)
       .addMethod("setFloat", &JSON::setFloat)
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
    NativeInterface::registerNativeType<JSON>(registerSystemJSON);
}
