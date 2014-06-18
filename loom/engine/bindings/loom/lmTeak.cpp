#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platformTeak.h"


using namespace LS;


class Teak
{
private:
    /// Event handler; this is called by the C mobile API when there is a recorded Teak Authorization change
    static void authStatusDelegate(int authStatus)
    {
        ///Convert to delegate calls.
        _OnAuthStatusDelegate.pushArgument(authStatus);
        _OnAuthStatusDelegate.invoke();
    }

public:
    LOOM_STATICDELEGATE(OnAuthStatus);


    static void initialize()
    {
        platform_teakInitialize(authStatusDelegate);
    }
    
    static bool isActive()
    {
        return platform_isActive();
    }    
    static void setAccessToken(const char* fbAccessToken)
    {
        return platform_setAccessToken(fbAccessToken);
    }

    static int getStatus()
    {
        return platform_getStatus();
    }
    
    static bool postAchievement(const char* achievementId)
    {
        return platform_postAchievement(achievementId);
    }

    static bool postHighScore(int score)
    {
        return platform_postHighScore(score);
    }

    static bool postAction(const char* actionId, const char* objectInstanceId)
    {
        return platform_postAction(actionId, objectInstanceId);
    }
};



NativeDelegate Teak::_OnAuthStatusDelegate;


static int registerLoomTeak(lua_State* L)
{
    beginPackage(L, "loom.social")

    .beginClass<Teak>("Teak")
        .addStaticMethod("isActive", &Teak::isActive)
        .addStaticMethod("setAccessToken", &Teak::setAccessToken)
        .addStaticMethod("getStatus", &Teak::getStatus)
        .addStaticMethod("postAchievement", &Teak::postAchievement)
        .addStaticMethod("postHighScore", &Teak::postHighScore)
        .addStaticMethod("postAction", &Teak::postAction)
        .addStaticProperty("onAuthStatus", &Teak::getOnAuthStatusDelegate)
    .endClass()

    .endPackage();

    return 0;
}

void installLoomTeak()
{
    LOOM_DECLARE_NATIVETYPE(Teak, registerLoomTeak);
    Teak::initialize();
}

