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

/*
 * Based on JNIHelper
 * Copyright (c) 2010-2011 cocos2d-x.org
 * http://www.cocos2d-x.org
 */
#ifndef __ANDROID_JNI_H__
#define __ANDROID_JNI_H__

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platform.h"
#include "loom/common/utils/utString.h"

#include <jni.h>

typedef struct loomJniMethodInfo_
{
    JNIEnv *getEnv();

    jclass    classID;
    jmethodID methodID;
} loomJniMethodInfo;

class LoomJni
{
public:
    static JavaVM *getJavaVM();
    static void setJavaVM(JavaVM *javaVM);
    static jclass getClassID(const char *className, JNIEnv *env = 0);
    static bool getStaticMethodInfo(loomJniMethodInfo& methodinfo, const char *className, const char *methodName, const char *paramCode);
    static bool getMethodInfo(loomJniMethodInfo& methodinfo, const char *className, const char *methodName, const char *paramCode);
    static utString jstring2string(jstring str);
    static const char *getPackageName();
    static const char *getWritablePath();
    static const char *getSettingsPath();

private:
    static JavaVM *m_psJavaVM;
};

#define LOOMJAVAVM    LoomJni::getJavaVM()
#endif // __ANDROID_JNI_H__

#endif