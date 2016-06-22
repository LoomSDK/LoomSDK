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

#import <Foundation/Foundation.h>
#include "loom/engine/bindings/loom/lmUserDefault.h"

static bool keyExists(const char *k)
{
    return [[NSUserDefaults standardUserDefaults]
            objectForKey:[NSString stringWithUTF8String:k]] != nil;
}

bool UserDefault::getBoolForKey(const char *k, bool v)
{
    if (!keyExists(k)) return v;
    return [[NSUserDefaults standardUserDefaults]
            boolForKey:[NSString stringWithUTF8String:k]];
};

int UserDefault::getIntegerForKey(const char *k, int v)
{
    if (!keyExists(k)) return v;
    return (int)[[NSUserDefaults standardUserDefaults]
            integerForKey:[NSString stringWithUTF8String:k]];
};
float UserDefault::getFloatForKey(const char *k, float v)
{
    if (!keyExists(k)) return v;
    return [[NSUserDefaults standardUserDefaults]
            floatForKey:[NSString stringWithUTF8String:k]];
};

utString UserDefault::getStringForKey(const char *k, const char* v)
{
    NSString *saved = [[NSUserDefaults standardUserDefaults]
                       stringForKey:[NSString stringWithUTF8String:k]];
    return utString(saved == nil ? v : [saved UTF8String]);
};

double UserDefault::getDoubleForKey(const char *k, double v)
{
    if (!keyExists(k)) return v;
    return [[NSUserDefaults standardUserDefaults]
            doubleForKey:[NSString stringWithUTF8String:k]];
};

void UserDefault::setBoolForKey(const char *k, bool v)
{
    [[NSUserDefaults standardUserDefaults]
     setBool:v
     forKey:[NSString stringWithUTF8String:k]
     ];
    [[NSUserDefaults standardUserDefaults] synchronize];
};

void UserDefault::setIntegerForKey(const char *k, int v)
{
    [[NSUserDefaults standardUserDefaults]
     setInteger:v
     forKey:[NSString stringWithUTF8String:k]
     ];
    [[NSUserDefaults standardUserDefaults] synchronize];
};

void UserDefault::setFloatForKey(const char *k, float v)
{
    [[NSUserDefaults standardUserDefaults]
     setFloat:v
     forKey:[NSString stringWithUTF8String:k]
     ];
    [[NSUserDefaults standardUserDefaults] synchronize];
};

void UserDefault::setStringForKey(const char *k, const char * v)
{
    [[NSUserDefaults standardUserDefaults]
     setObject:[NSString stringWithUTF8String:v]
     forKey:[NSString stringWithUTF8String:k]
     ];
    [[NSUserDefaults standardUserDefaults] synchronize];
};

void UserDefault::setDoubleForKey(const char *k, double v)
{
    [[NSUserDefaults standardUserDefaults]
     setDouble:v
     forKey:[NSString stringWithUTF8String:k]
     ];
    [[NSUserDefaults standardUserDefaults] synchronize];
};

bool UserDefault::purge()
{
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    return true;
};

