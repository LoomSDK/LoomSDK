#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/core/log.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#   include <jni.h>
#   include "loom/common/platform/platformAndroidJni.h"
#endif

lmDefineLogGroup(FacebookLogGroup, "Facebook", 1, LoomLogDebug);

using namespace LS;

class Facebook
{
public:
    LOOM_STATICDELEGATE(OnSessionStatus);
//GW TODO - this function is redundant with the death of Gamewoof. To be altered to suit new provider.
    static void noteGamewoofToken(const char *token)
    {
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        loomJniMethodInfo methodInfo;
        LoomJni::getStaticMethodInfo(   methodInfo,
                                        "co/theengine/loomdemo/LoomDemo",
                                        "registerDeviceWithSpotkinStatic",
                                        "(Ljava/lang/String;)V");
        jstring jTokenString = methodInfo.env->NewStringUTF(token);
        methodInfo.env->CallStaticVoidMethod(methodInfo.classID, methodInfo.methodID, jTokenString);
        methodInfo.env->DeleteLocalRef(jTokenString);
#endif
    }

    static bool openSessionWithReadPermissions(const char* permissionsString)
    {
        bool ret = false;
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        loomJniMethodInfo methodInfo;
        LoomJni::getStaticMethodInfo(   methodInfo,
                                        "co/theengine/loomdemo/LoomFacebook",
                                        "openSessionWithReadPermissions",
                                        "(Ljava/lang/String;)Z");
        jstring jPermissionsString = methodInfo.env->NewStringUTF(permissionsString);
        jboolean result = methodInfo.env->CallStaticBooleanMethod(methodInfo.classID, methodInfo.methodID, jPermissionsString);
        methodInfo.env->DeleteLocalRef(jPermissionsString);
        ret = result;
#endif
        return ret;
    }

    static bool requestNewPublishPermissions(const char* permissionsString)
    {
        bool ret = false;
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        loomJniMethodInfo methodInfo;
        LoomJni::getStaticMethodInfo(   methodInfo,
                                        "co/theengine/loomdemo/LoomFacebook",
                                        "requestNewPublishPermissions",
                                        "(Ljava/lang/String;)Z");
        jstring jPermissionsString = methodInfo.env->NewStringUTF(permissionsString);
        jboolean result = methodInfo.env->CallStaticBooleanMethod(methodInfo.classID, methodInfo.methodID, jPermissionsString);
        methodInfo.env->DeleteLocalRef(jPermissionsString);
        ret = result;
#endif
        return ret;
    }

    static const char* getAccessToken()
    {
        static utString accessToken;
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        loomJniMethodInfo methodInfo;
        LoomJni::getStaticMethodInfo(   methodInfo,
                                        "co/theengine/loomdemo/LoomFacebook",
                                        "getAccessToken",
                                        "()Ljava/lang/String;");
        jstring accessTokenString = (jstring)methodInfo.env->CallStaticObjectMethod(methodInfo.classID, methodInfo.methodID);
        accessToken = LoomJni::jstring2string(accessTokenString);
        methodInfo.env->DeleteLocalRef(accessTokenString);
#endif
        return accessToken.c_str();
    }
};

NativeDelegate Facebook::_OnSessionStatusDelegate;

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

extern "C"
{
    void Java_co_theengine_loomdemo_LoomFacebook_nativeStatusCallback(JNIEnv* env, jobject thiz, jstring sessonState, jstring sessionPermissions)
    {
        const char *sessonStateString = env->GetStringUTFChars(sessonState, 0);
        const char *sessionPermissionsString = env->GetStringUTFChars(sessionPermissions, 0);

        Facebook::_OnSessionStatusDelegate.pushArgument(sessonStateString);
        Facebook::_OnSessionStatusDelegate.pushArgument(sessionPermissionsString);
        Facebook::_OnSessionStatusDelegate.invoke();

        env->ReleaseStringUTFChars(sessonState, sessonStateString);
        env->ReleaseStringUTFChars(sessionPermissions, sessionPermissionsString);
    }
}

#endif

static int registerLoomFacebook(lua_State* L)
{
    beginPackage(L, "Loom")

    .beginClass<Facebook>("Facebook")
        .addStaticMethod("noteGamewoofToken", &Facebook::noteGamewoofToken)
        .addStaticMethod("openSessionWithReadPermissions", &Facebook::openSessionWithReadPermissions)
        .addStaticMethod("requestNewPublishPermissions", &Facebook::requestNewPublishPermissions)
        .addStaticMethod("getAccessToken", &Facebook::getAccessToken)
        .addStaticProperty("onSessionStatus", &Facebook::getOnSessionStatusDelegate)
    .endClass()

    .endPackage();

    return 0;
}

void installLoomFacebook()
{
    LOOM_DECLARE_NATIVETYPE(Facebook, registerLoomFacebook);
}
