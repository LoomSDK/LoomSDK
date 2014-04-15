#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/core/log.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#   include <jni.h>
#   include "loom/common/platform/platformAndroidJni.h"
#endif

lmDefineLogGroup(CarrotLogGroup, "Carrot", 1, LoomLogDebug);

using namespace LS;


//SOCIALTODO: LFL: likely move over to new Teak API eventually
//SOCIALTODO: LFL: create native Teak class that will internally call platform specific code
//                  instead of this inline ANDROID only support -> Loom at lmMobile.cpp for how it uses "platormMobile", etc.
class Carrot
{
public:
    LOOM_STATICDELEGATE(OnAuthStatus);

    static bool postAchievement(const char* achievementId)
    {
        bool ret = false;
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        loomJniMethodInfo methodInfo;
        LoomJni::getStaticMethodInfo(   methodInfo,
                                        "co/theengine/loomdemo/LoomCarrot",
                                        "postAchievement",
                                        "(Ljava/lang/String;)Z");
        jstring jAchievementId = methodInfo.env->NewStringUTF(achievementId);
        ret = methodInfo.env->CallStaticBooleanMethod(methodInfo.classID, methodInfo.methodID, jAchievementId);
        methodInfo.env->DeleteLocalRef(jAchievementId);
#endif
        return ret;
    }

    static bool postHighScore(int score)
    {
        bool ret = false;
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        loomJniMethodInfo methodInfo;
        LoomJni::getStaticMethodInfo(   methodInfo,
                                        "co/theengine/loomdemo/LoomCarrot",
                                        "postHighScore",
                                        "(I)Z");
        ret = methodInfo.env->CallStaticBooleanMethod(methodInfo.classID, methodInfo.methodID, score);
#endif
        return ret;
    }

    static bool postAction(const char* actionId, const char* objectInstanceId)
    {
        bool ret = false;
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        loomJniMethodInfo methodInfo;
        LoomJni::getStaticMethodInfo(   methodInfo,
                                        "co/theengine/loomdemo/LoomCarrot",
                                        "postAction",
                                        "(Ljava/lang/String;Ljava/lang/String;)Z");
        jstring jActionId = methodInfo.env->NewStringUTF(actionId);
        jstring jObjectInstanceId = methodInfo.env->NewStringUTF(objectInstanceId);
        ret = methodInfo.env->CallStaticBooleanMethod(methodInfo.classID, methodInfo.methodID, jActionId, jObjectInstanceId);
        methodInfo.env->DeleteLocalRef(jActionId);
        methodInfo.env->DeleteLocalRef(jObjectInstanceId);
#endif
        return ret;
    }

    static const char* getStatus()
    {
        static utString status;
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        loomJniMethodInfo methodInfo;
        LoomJni::getStaticMethodInfo(   methodInfo,
                                        "co/theengine/loomdemo/LoomCarrot",
                                        "getStatus",
                                        "()Ljava/lang/String;");
        jstring statusString = (jstring)methodInfo.env->CallStaticObjectMethod(methodInfo.classID, methodInfo.methodID);
        status = LoomJni::jstring2string(statusString);
        methodInfo.env->DeleteLocalRef(statusString);
#endif
        return status.c_str();
    }
};

NativeDelegate Carrot::_OnAuthStatusDelegate;

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

extern "C"
{
    void Java_co_theengine_loomdemo_LoomCarrot_nativeStatusCallback(JNIEnv* env, jobject thiz, jstring authStatus)
    {
        const char *authStatusString = env->GetStringUTFChars(authStatus, 0);

        Carrot::_OnAuthStatusDelegate.pushArgument(authStatusString);
        Carrot::_OnAuthStatusDelegate.invoke();

        env->ReleaseStringUTFChars(authStatus, authStatusString);
    }
}

#endif

static int registerLoomCarrot(lua_State* L)
{
    beginPackage(L, "Loom")

    .beginClass<Carrot>("Carrot")
        .addStaticMethod("postAchievement", &Carrot::postAchievement)
        .addStaticMethod("postHighScore", &Carrot::postHighScore)
        .addStaticMethod("postAction", &Carrot::postAction)
        .addStaticMethod("getStatus", &Carrot::getStatus)
        .addStaticProperty("onAuthStatus", &Carrot::getOnAuthStatusDelegate)
    .endClass()

    .endPackage();

    return 0;
}

void installLoomCarrot()
{
    LOOM_DECLARE_NATIVETYPE(Carrot, registerLoomCarrot);
}
