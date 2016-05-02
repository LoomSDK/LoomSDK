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
#include "loom/common/core/log.h"
#include "loom/common/core/allocator.h"
#include "loom/common/platform/platformFile.h"
#include "loom/common/platform/platformIO.h"
#include "loom/common/config/applicationConfig.h"
#include "loom/common/utils/json.h"

//#include "loom/engine/bindings/loom/"

lmDefineLogGroup(gUserDefaultGroup, "userdef", 1, LoomLogInfo);

class ScopedJSON
{
    utString dir;
    utString filepath;

public:
    JSON json;

    ScopedJSON();
    ~ScopedJSON();

    void load();
    void save();
    static void purge();

    template<class T>
    T getValue(const char *k, T def, T value);
};

class UserDefault
{
    static UserDefault shared;

public:
    static const char* getSharedDir()
    {
        return platform_getSettingsPath(LoomApplicationConfig::applicationId().c_str());
    }

    static const char* getSharedFileName()
    {
        return "userdefaults.json";
    }

    bool getBoolForKey(const char *k, bool v)
    {
        ScopedJSON s; return s.getValue(k, v, s.json.getBoolean(k));
    };

    int getIntegerForKey(const char *k, int v)
    {
        ScopedJSON s; return s.getValue(k, v, s.json.getInteger(k));
    };
    float getFloatForKey(const char *k, float v)
    {
        ScopedJSON s; return s.getValue(k, v, static_cast<float>(s.json.getFloat(k)));
    };

    utString getStringForKey(const char *k, const char* v)
    {
        ScopedJSON s; return utString(s.getValue(k, v, s.json.getString(k)));
    };

    double getDoubleForKey(const char *k, double v)
    {
        ScopedJSON s; return s.getValue(k, v, s.json.getNumber(k));
    };

    void setBoolForKey(const char *k, bool v)
    {
        ScopedJSON s; s.json.setBoolean(k, v);
    };

    void setIntegerForKey(const char *k, int v)
    {
        ScopedJSON s; s.json.setInteger(k, v);
    };

    void setFloatForKey(const char *k, float v)
    {
        ScopedJSON s; s.json.setFloat(k, v);
    };

    void setStringForKey(const char *k, const char * v)
    {
        ScopedJSON s; s.json.setString(k, v);
    };

    void setDoubleForKey(const char *k, double v)
    {
        ScopedJSON s; s.json.setNumber(k, v);
    };

    bool purge()
    {
        return platform_removeFile((utString(getSharedDir()) + utString(getSharedFileName())).c_str()) == 0;
    };

    static bool purgeSharedUserDefault()
    {
        return shared.purge();
    }

    static UserDefault *sharedUserDefault()
    {
        return &shared;
    }
};

UserDefault UserDefault::shared;

ScopedJSON::ScopedJSON()
{
    dir = UserDefault::getSharedDir();
    filepath = dir + UserDefault::getSharedFileName();
    load();
}

ScopedJSON::~ScopedJSON()
{
    save();
}

void ScopedJSON::load()
{
    void *data;
    long size;
    const char *path = filepath.c_str();

    // Load text
    bool loaded = platform_mapFile(path, &data, &size) == 1;

    if (loaded)
    {
        char *text = (char*)lmAlloc(NULL, size + 1);
        memcpy(text, data, size);
        platform_unmapFile(data);
        text[size] = 0;

        // Load JSON
        json.loadString(text);
        lmFree(NULL, text);

        lmAssert(json.isObject(), "Loaded JSON not an object");
    }
    else
    {
        platform_makeDir(dir.c_str());
        json.initObject();
    }
}

void ScopedJSON::save()
{
    const char *serialized = json.serialize();
    lmAssert(serialized, "Unable to serialize JSON");

    platform_writeFile(filepath.c_str(), (void*)serialized, strlen(serialized));

    lmFree(NULL, (void*)serialized);
}

template<class T>
T ScopedJSON::getValue(const char *k, T def, T value)
{
    return json.getObjectJSONType(k) == JSON_NULL ? def : value;
}

static int registerLoomUserDefault(lua_State *L)
{
    beginPackage(L, "loom.platform")

        .beginClass<UserDefault>("UserDefault")

        .addMethod("getBoolForKey", &UserDefault::getBoolForKey)
        .addMethod("getIntegerForKey", &UserDefault::getIntegerForKey)
        .addMethod("getFloatForKey", &UserDefault::getFloatForKey)
        .addMethod("getStringForKey", &UserDefault::getStringForKey)
        .addMethod("getDoubleForKey", &UserDefault::getDoubleForKey)

        .addMethod("setBoolForKey", &UserDefault::setBoolForKey)
        .addMethod("setIntegerForKey", &UserDefault::setIntegerForKey)
        .addMethod("setFloatForKey", &UserDefault::setFloatForKey)
        .addMethod("setStringForKey", &UserDefault::setStringForKey)
        .addMethod("setDoubleForKey", &UserDefault::setDoubleForKey)

        .addMethod("purge", &UserDefault::purge)

        .addStaticMethod("sharedUserDefault", &UserDefault::sharedUserDefault)
        .addStaticMethod("purgeSharedUserDefault", &UserDefault::purgeSharedUserDefault)
        .endClass()

        .endPackage();

    return 0;
}

void installLoomUserDefault()
{
    LOOM_DECLARE_NATIVETYPE(UserDefault, registerLoomUserDefault);
}
