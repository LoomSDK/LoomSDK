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

    static bool showFrictionlessRequestDialog(const char* recipientsString, const char* titleString, const char* messageString)
    {
        bool ret = false;
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        loomJniMethodInfo methodInfo;
        LoomJni::getStaticMethodInfo(   methodInfo,
                                        "co/theengine/loomdemo/LoomFacebook",
                                        "showFrictionlessRequestDialog",
                                        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
        jstring jRecipientsString   = methodInfo.env->NewStringUTF(recipientsString);
        jstring jTitleString        = methodInfo.env->NewStringUTF(titleString);
        jstring jMessageString      = methodInfo.env->NewStringUTF(messageString);
        jboolean result = methodInfo.env->CallStaticBooleanMethod(methodInfo.classID, methodInfo.methodID, jRecipientsString, jTitleString, jMessageString);
        methodInfo.env->DeleteLocalRef(jRecipientsString);
        methodInfo.env->DeleteLocalRef(jTitleString);
        methodInfo.env->DeleteLocalRef(jMessageString);
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
	
	static const char* getExpirationDate(const char* dateFormat)
    {
        static utString expirationDate;
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        loomJniMethodInfo methodInfo;
        LoomJni::getStaticMethodInfo(   methodInfo,
                                        "co/theengine/loomdemo/LoomFacebook",
                                        "getExpirationDate",
                                        "(Ljava/lang/String;)Ljava/lang/String;");
		jstring jdateFormatString   = methodInfo.env->NewStringUTF(dateFormat);
        jstring expirationDateString = (jstring)methodInfo.env->CallStaticObjectMethod(methodInfo.classID, methodInfo.methodID,jdateFormatString);
        expirationDate = LoomJni::jstring2string(expirationDateString);
        methodInfo.env->DeleteLocalRef(expirationDateString);
#endif
        return expirationDate.c_str();
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
        .addStaticMethod("openSessionWithReadPermissions", &Facebook::openSessionWithReadPermissions)
        .addStaticMethod("requestNewPublishPermissions", &Facebook::requestNewPublishPermissions)
        .addStaticMethod("showFrictionlessRequestDialog", &Facebook::showFrictionlessRequestDialog)
        .addStaticMethod("getAccessToken", &Facebook::getAccessToken)
        .addStaticMethod("getExpirationDate", &Facebook::getExpirationDate)
		.addStaticProperty("onSessionStatus", &Facebook::getOnSessionStatusDelegate)
    .endClass()

    .endPackage();

    return 0;
}

void installLoomFacebook()
{
    LOOM_DECLARE_NATIVETYPE(Facebook, registerLoomFacebook);
}
