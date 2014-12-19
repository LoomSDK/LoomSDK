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

#include <assert.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>

#if LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#include <stdarg.h>
#endif

#include "loom/common/platform/platformDisplay.h"
#include "loom/common/platform/platformThread.h"
#include "loom/common/platform/platformTime.h" // Needed to generate fake accelerometer data
#include "loom/common/platform/platform.h"
#include "loom/common/core/performance.h"
#include "loom/common/core/log.h"


lmDefineLogGroup(gPlatformErrorLogGroup, "error", 1, LoomLogDebug);


#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32

#include <windows.h>

// The accelerometer is disabled by default in order to conserve battery on mobile devices.
static unsigned char accelerometerEnabled = 0;
// If 0, then accelerometer reports being held straight down.
// If 1, then cycles through fake spinning data.
static unsigned char accelerometerDebugMode = 0;

void platform_enableAccelerometer(unsigned char enabled)
{
    accelerometerEnabled = enabled;
}


void platform_setAccelerometerDebugMode(unsigned char enabled)
{
    accelerometerDebugMode = enabled;
}


void accelerometerUpdate()
{
}


int platform_debugOut(const char *out, ...)
{
    int  len;

    /*
    char buff[2048];
    va_list args;
    va_start(args, out);
    vsprintf_s(buff, 2046, out, args);
    va_end(args);
    */

    char* buff;
    lmLogArgs(buff, out);

    // Put a new line in so windows displays this junk right.
    len           = (int)strlen(buff);
    buff[len]     = '\n';
    buff[len + 1] = 0;

    // Make it available for debugger.
    OutputDebugStringA((LPCSTR)buff);

    // Make it show in console, too.
    fputs(buff, stdout);

    free(buff);

    return 0;
}


int platform_error(const char *out, ...)
{
    static int pesafety = 0;

    /*
    va_list    args;
    char       buff[2048];
    va_start(args, out);
    vsprintf_s(buff, 2046, out, args);
    va_end(args);
    */

    char* buff;
    lmLogArgs(buff, out);
    
    OutputDebugStringA(buff);

    // Try to output/log error. Add a guard to avid infinite logging.
    if (pesafety == 0)
    {
        pesafety = 1;
        lmLogError(gPlatformErrorLogGroup, "%s", buff);
        pesafety = 0;
    }

    free(buff);

    return 0;
}


#elif LOOM_PLATFORM_IS_APPLE

// For Mac and iOS, most of these functions are implemented in platformDisplayCocoa.m

#include <stdio.h>
#include <stdarg.h>
#include <string.h>

#if LOOM_PLATFORM == LOOM_PLATFORM_IOS
int ios_debugOut(const char *__restrict format, ...);
#endif

int platform_debugOut(const char *out, ...)
{
    int  len;

    /*
    va_list args;
    char buff[2048];
    va_start(args, out);
    vsnprintf(buff, 2046, out, args);
    va_end(args);
    */

    char* buff;
    lmLogArgs(buff, out);

    // Put a new line in so windows displays this junk right.
    len           = strlen(buff);
    buff[len]     = '\n';
    buff[len + 1] = 0;

    fprintf(stderr, "%s", buff);

#if LOOM_PLATFORM == LOOM_PLATFORM_IOS
    ios_debugOut("%s", buff);
#endif

    free(buff);

    return 0;
}


int platform_error(const char *out, ...)
{
    char* buff;
    lmLogArgs(buff, out);

    // Try to output/log error with re-entrancy guard.
    static int pesafety = 0;
    if (pesafety == 0)
    {
        pesafety = 1;
        lmLogError(gPlatformErrorLogGroup, "%s", buff);
        pesafety = 0;
    }

    free(buff);

    return 0;
}


#elif LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include <GLES2/gl2.h>


#include <android/log.h>
#include <jni.h>

int platform_debugOut(const char *out, ...)
{
    char    *buf; // Perhaps make this a static buffer and use vsnprintf() for performance increase?
    va_list args;

    va_start(args, out);
    vasprintf(&buf, out, args);
    va_end(args);

    __android_log_write(ANDROID_LOG_INFO, "Loom-Debug-Out", buf);

    free(buf); // Needs to use same allocator as vasprintf, NOT lmFree.

    return 0;
}


int platform_error(const char *out, ...)
{
    char    *buff; // Perhaps make this a static buffer and use vsnprintf() for performance increase?
    va_list args;

    va_start(args, out);
    vasprintf(&buff, out, args);
    va_end(args);

    __android_log_write(ANDROID_LOG_ERROR, "Loom-Error", buff);

    // Try to output/log error with re-entrancy guard.
    static int pesafety = 0;
    if (pesafety == 0)
    {
        pesafety = 1;
        lmLogError(gPlatformErrorLogGroup, "%s", buff);
        pesafety = 0;
    }

    free(buff); // Needs to use same allocator as vasprintf, NOT lmFree.

    return 0;
}


static JavaVM  *JVM;
static jobject jActivity = 0; // This needs to be a global (weak) reference
                              //  in order to be valid across JNI calls
static unsigned char accelerometerEnabled   = 0;
static unsigned char accelerometerDebugMode = 0;


JNIEXPORT void JNICALL
Java_co_theengine_loom_android_LoomActivity_loomSensorInit(JNIEnv  *env,
                                                           jobject thiz)
{
    // Store our Java environment and activity object
    //  so that we can make Java calls in the future.
    // TODO: Ensure that this initialization is indeed called again
    //  if the activity is ever recreated (such as on a suspend).

    // Store these as global references, because local references
    //  may not be stored and re-used outside of this JNI call.
    jActivity = (*env)->NewWeakGlobalRef(env, thiz);

    // TODO: Destroy this with a DeleteGlobalWeakRef
}


void platform_enableAccelerometer(unsigned char enabled)
{
    accelerometerEnabled = enabled;

    JNIEnv *env;
    if ((*JVM)->GetEnv(JVM, (void **)&env, JNI_VERSION_1_4) != JNI_OK)
    {
        platform_error("Android failed to get the environment using GetEnv()");
        return;
    }
    jclass    cls = (*env)->GetObjectClass(env, jActivity);
    jmethodID mid = (*env)->GetMethodID(env, cls, "enableAccelerometer", "(I)V");
    assert(mid);

    (*env)->CallVoidMethod(env, jActivity, mid, (int)enabled);
}


void platform_setAccelerometerDebugMode(unsigned char enabled)
{
    accelerometerDebugMode = enabled;
}


#else // Unsupported platforms use stubbed functions

int platform_debugOut(const char *out, ...)
{
    // TODO: Does this need to be smarter, or stripped in release builds?
    va_list args;

    va_start(args, out);
    vprintf(out, args);
    va_end(args);
    printf("\n");

    return 0;
}


int platform_error(const char *out, ...)
{
    // TODO: Does this need to be smarter, or stripped in release builds?
    char    buff[4096];
    va_list args;

    va_start(args, out);
    vsnprintf(buff, 4094, out, args);
    va_end(args);

    // Try to output/log error.
    static int pesafety = 0;
    if (pesafety == 0)
    {
        pesafety = 1;
        lmLogError(gPlatformErrorLogGroup, "%s", buff);
        pesafety = 0;
    }

    return 0;
}
#endif

#if LOOM_PLATFORM == LOOM_PLATFORM_LINUX || LOOM_PLATFORM == LOOM_PLATFORM_WIN32 || LOOM_PLATFORM == LOOM_PLATFORM_OSX

display_profile display_getProfile()
{
    return PROFILE_DESKTOP;
}


float display_getDPI()
{
    return 200;
}
#endif
