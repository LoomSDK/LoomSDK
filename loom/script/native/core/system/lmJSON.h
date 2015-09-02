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

#ifndef _SYSTEM_JSON_H
#define _SYSTEM_JSON_H


#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/reflection/lsType.h"
#include "loom/script/runtime/lsRuntime.h"
#include "jansson.h"

class JSON {
    // The native _json object
    json_t *_json;

    // JSON error codes
    json_error_t _error;
    utString     _errorMsg;
    bool         _root;

public:

    JSON();
    ~JSON();

    bool clear();
    bool initObject();
    bool initArray();
    bool loadString(const char *json);
    const char *serialize();
    const char *getError();
    int getJSONType();
    int getObjectJSONType(const char *key);
    int getArrayJSONType(int index);

    const char *getLongLongAsString(const char *key);
    int getInteger(const char *key);
    void setInteger(const char *key, int value);
    double getFloat(const char *key);
    void setFloat(const char *key, float value);
    double getNumber(const char *key);
    void setNumber(const char *key, double value);
    bool getBoolean(const char *key);
    void setBoolean(const char *key, bool value);
    const char *getString(const char *key);
    void setString(const char *key, const char *value);

    // Objects
    JSON *getObject(const char *key);
    void setObject(const char *key, JSON *object);
    bool isObject();
    const char *getObjectFirstKey();
    const char *getObjectNextKey(const char *key);

    // Arrays
    JSON *getArray(const char *key);
    void setArray(const char *key, JSON *object);
    bool isArray();
    int getArrayCount();
    bool getArrayBoolean(int index);
    void setArrayBoolean(int index, bool value);
    int getArrayInteger(int index);
    void setArrayInteger(int index, int value);
    double getArrayFloat(int index);
    void setArrayFloat(int index, float value);
    double getArrayNumber(int index);
    void setArrayNumber(int index, double value);
    const char *getArrayString(int index);
    void setArrayString(int index, const char *value);
    JSON *getArrayObject(int index);
    void setArrayObject(int index, JSON *value);
    JSON *getArrayArray(int index);
    void setArrayArray(int index, JSON *value);
    void expandArray(int desiredLength);
};

#endif