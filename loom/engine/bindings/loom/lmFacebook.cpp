#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platformFacebook.h"


using namespace LS;



class Facebook
{
private:
    /// Event handler; this is called by the C mobile API when there is a recorded sensor change
    static void sessionStatusDelegate(const char *state, const char *permissions)
    {
        ///Convert to delegate calls.
        _OnSessionStatusDelegate.pushArgument(state);
        _OnSessionStatusDelegate.pushArgument(permissions);
        _OnSessionStatusDelegate.invoke();
    }

public:
    LOOM_STATICDELEGATE(OnSessionStatus);


    static void initialize()
    {
        platform_facebookInitialize(sessionStatusDelegate);
    }

    static bool openSessionWithReadPermissions(const char* permissionsString)
    {
        return platform_openSessionWithReadPermissions(permissionsString);
    }

    static bool requestNewPublishPermissions(const char* permissionsString)
    {
        return platform_requestNewPublishPermissions(permissionsString);
    }

    static void showFrictionlessRequestDialog(const char* recipientsString, const char* titleString, const char* messageString)
    {
        platform_showFrictionlessRequestDialog(recipientsString, titleString, messageString);
    }

    static const char* getAccessToken()
    {
        return platform_getAccessToken();
    }
    
	static void closeAndClearTokenInformation()
	{
        platform_closeAndClearTokenInformation();
	}
	
	static const char* getExpirationDate(const char* dateFormat)
    {
        return platform_getExpirationDate(dateFormat);
    }
};



NativeDelegate Facebook::_OnSessionStatusDelegate;


static int registerLoomFacebook(lua_State* L)
{
    beginPackage(L, "Loom")

    .beginClass<Facebook>("Facebook")
        .addStaticMethod("openSessionWithReadPermissions", &Facebook::openSessionWithReadPermissions)
        .addStaticMethod("requestNewPublishPermissions", &Facebook::requestNewPublishPermissions)
        .addStaticMethod("showFrictionlessRequestDialog", &Facebook::showFrictionlessRequestDialog)
        .addStaticMethod("getAccessToken", &Facebook::getAccessToken)
        .addStaticMethod("closeAndClearTokenInformation", &Facebook::closeAndClearTokenInformation)
        .addStaticMethod("getExpirationDate", &Facebook::getExpirationDate)
		.addStaticProperty("onSessionStatus", &Facebook::getOnSessionStatusDelegate)
    .endClass()

    .endPackage();

    return 0;
}

void installLoomFacebook()
{
    LOOM_DECLARE_NATIVETYPE(Facebook, registerLoomFacebook);
    Facebook::initialize();
}
