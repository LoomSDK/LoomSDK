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
 * Copyright (c) 2010 cocos2d-x.org
 * http://www.cocos2d-x.org
 */

#include "loom/common/utils/utString.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platform.h"


#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include "platformAndroidJni.h"

static loom_logGroup_t jniLogGroup = { "jni", 1 };

void loom_set_javavm(void *vm)
{
    LoomJni::setJavaVM((JavaVM *)vm);
}

extern "C"
{
//////////////////////////////////////////////////////////////////////////
// java vm helper function
//////////////////////////////////////////////////////////////////////////

static bool getEnv(JNIEnv **env)
{
    bool bRet = false;

    do
    {
        if (LOOMJAVAVM == NULL)
        {
            __android_log_print(ANDROID_LOG_INFO, "LoomJNI", "Missing LOOMJAVAVM (== NULL)");
            break;
        }

        if (LOOMJAVAVM->GetEnv((void **)env, JNI_VERSION_1_4) != JNI_OK)
        {
            __android_log_print(ANDROID_LOG_INFO, "LoomJNI", "Failed to get the environment using GetEnv()");
            break;
        }

        if (LOOMJAVAVM->AttachCurrentThread(env, 0) < 0)
        {
            __android_log_print(ANDROID_LOG_INFO, "LoomJNI", "Failed to get the environment using AttachCurrentThread()");
            break;
        }

        bRet = true;
    } while (0);

    return bRet;
}

JNIEnv *loomJniMethodInfo_::getEnv()
{
    JNIEnv *env = NULL;
    ::getEnv(&env);
    return env;
}

static jclass getClassID_(const char *className, JNIEnv *env)
{
    JNIEnv *pEnv = env;
    jclass ret   = 0;

    do
    {
        if (!pEnv)
        {
            if (!getEnv(&pEnv))
            {
                break;
            }
        }

        jclass classRef = pEnv->FindClass(className);
        ret = (jclass)env->NewGlobalRef(classRef);
        if (!ret)
        {
            lmLog(jniLogGroup, "Failed to find class of %s", className);

            jthrowable exc;
            exc = pEnv->ExceptionOccurred();
            if (exc)
            {
                pEnv->ExceptionClear();
            }
            break;
        }
    } while (0);

    return ret;
}


static bool getStaticMethodInfo_(loomJniMethodInfo& methodinfo, const char *className, const char *methodName, const char *paramCode)
{
    jmethodID methodID = 0;
    JNIEnv    *pEnv    = 0;
    bool      bRet     = false;

    do
    {
        if (!getEnv(&pEnv))
        {
            break;
        }

        jclass classID = getClassID_(className, pEnv);

        if (!classID)
        {
            return false;
        }

        methodID = pEnv->GetStaticMethodID(classID, methodName, paramCode);
        if (!methodID)
        {
            lmLog(jniLogGroup, "Failed to find static method id of %s on class %s", methodName, className);
            break;
        }

        methodinfo.classID  = classID;
        methodinfo.methodID = methodID;

        bRet = true;
    } while (0);

    return bRet;
}


static bool getMethodInfo_(loomJniMethodInfo& methodinfo, const char *className, const char *methodName, const char *paramCode)
{
    jmethodID methodID = 0;
    JNIEnv    *pEnv    = 0;
    bool      bRet     = false;

    do
    {
        if (!getEnv(&pEnv))
        {
            break;
        }

        jclass classID = getClassID_(className, pEnv);

        if (!classID)
        {
            return false;
        }

        methodID = pEnv->GetMethodID(classID, methodName, paramCode);
        if (!methodID)
        {
            lmLog(jniLogGroup, "Failed to find method id of %s", methodName);
            break;
        }

        methodinfo.classID  = classID;
        methodinfo.methodID = methodID;

        bRet = true;
    } while (0);

    return bRet;
}


static utString jstring2string_(jstring jstr)
{
    if (jstr == NULL)
    {
        return "";
    }

    JNIEnv *env = 0;

    if (!getEnv(&env))
    {
        return 0;
    }

    const char *chars = env->GetStringUTFChars(jstr, NULL);
    utString   ret(chars);
    env->ReleaseStringUTFChars(jstr, chars);
    return ret;
}

}

JavaVM *LoomJni::m_psJavaVM = NULL;

JavaVM *LoomJni::getJavaVM()
{
    return m_psJavaVM;
}


void LoomJni::setJavaVM(JavaVM *javaVM)
{
    m_psJavaVM = javaVM;
}


jclass LoomJni::getClassID(const char *className, JNIEnv *env)
{
    return getClassID_(className, env);
}


bool LoomJni::getStaticMethodInfo(loomJniMethodInfo& methodinfo, const char *className, const char *methodName, const char *paramCode)
{
    return getStaticMethodInfo_(methodinfo, className, methodName, paramCode);
}


bool LoomJni::getMethodInfo(loomJniMethodInfo& methodinfo, const char *className, const char *methodName, const char *paramCode)
{
    return getMethodInfo_(methodinfo, className, methodName, paramCode);
}


utString LoomJni::jstring2string(jstring str)
{
    return jstring2string_(str);
}


const char *LoomJni::getPackageName()
{
    static utString packageName;

    if (packageName.size())
    {
        return packageName.c_str();
    }

    loomJniMethodInfo t;

    if (getStaticMethodInfo(t,
        "co/theengine/loomdemo/LoomDemo",
        "getActivityPackageName",
        "()Ljava/lang/String;"))
    {
        jstring str = (jstring)t.getEnv()->CallStaticObjectMethod(t.classID, t.methodID);
        t.getEnv()->DeleteLocalRef(t.classID);
        packageName = jstring2string(str);
        t.getEnv()->DeleteLocalRef(str);

        lmLog(jniLogGroup, "package name %s", packageName.c_str());

        return packageName.c_str();
    }

    return 0;
}

const char *LoomJni::getWritablePath()
{
    static utString writablePath;

    loomJniMethodInfo t;

    if (getStaticMethodInfo(t,
        "co/theengine/loomdemo/LoomDemo",
        "getActivityWritablePath",
        "()Ljava/lang/String;"))
    {
        jstring str = (jstring)t.getEnv()->CallStaticObjectMethod(t.classID, t.methodID);
        t.getEnv()->DeleteLocalRef(t.classID);
        writablePath = jstring2string(str);
        t.getEnv()->DeleteLocalRef(str);

        lmLog(jniLogGroup, "writable path %s", writablePath.c_str());

        return writablePath.c_str();
    }

    return 0;
}
#endif
