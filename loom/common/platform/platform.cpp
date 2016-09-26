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

#include "loom/common/platform/platform.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#include <shlobj.h>
#include <Shellapi.h>

extern "C" {

int platform_openURL(const char *url)
{
// Casting to int here is the right thing to do based on the func docs
#pragma warning ( suppress: 4311, 4302 )
    return (int)ShellExecute(NULL, "open", url, NULL, NULL, SW_SHOWNORMAL) > 32;
}

}

#elif LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include "loom/common/platform/platformAndroidJni.h"
#include "jni.h"

extern "C" {

int platform_openURL(const char *url)
{
    loomJniMethodInfo t;

    if (LoomJni::getStaticMethodInfo(t
        , "co/theengine/loomplayer/LoomPlayer"
        , "openURL"
        , "(Ljava/lang/String;)Z"))
    {
        JNIEnv *env = t.getEnv();
        jstring urlParam = env->NewStringUTF(url);
        lmAssert(urlParam, "Unable to allocate URL parameter");
        jboolean r = (jboolean)env->CallStaticBooleanMethod(t.classID, t.methodID, urlParam);
        env->DeleteLocalRef(urlParam);
        env->DeleteLocalRef(t.classID);
        return r;
    }
    return false;
}

}

#elif LOOM_PLATFORM == LOOM_PLATFORM_LINUX

#include <unistd.h>

extern "C" {

int platform_openURL(const char *url)
{
    int pid = fork();
    if (pid == 0)
    {
        char *args[] = { (char*)("/usr/bin/xdg-open"), (char*)url, NULL };
    	execv(args[0], args);
    }
    else if (pid == -1)
    {
        return false;
    }
    return true;
}

}

#endif
