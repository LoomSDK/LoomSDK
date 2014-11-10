#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platformFacebook.h"


using namespace LS;



class Facebook
{
private:
    /// Event handler; this is called by the C mobile API when there is a recorded Session Status change
    static void sessionStatusDelegate(int state, const char *permissions, int errorCode)
    {
        ///Convert to delegate calls.
        _OnSessionStatusDelegate.pushArgument(state);
        _OnSessionStatusDelegate.pushArgument(permissions);
        _OnSessionStatusDelegate.pushArgument(errorCode);
        _OnSessionStatusDelegate.invoke();
    }

    /// Event handler; this is called by the C mobile API when a Frictionless Request Dialog cas completed
    static void frictionlessRequestDelegate(bool success)
    {
        ///Convert to delegate calls.
        _OnFrictionlessRequestDelegate.pushArgument(success);
        _OnFrictionlessRequestDelegate.invoke();
    }

public:
    LOOM_STATICDELEGATE(OnSessionStatus);
    LOOM_STATICDELEGATE(OnFrictionlessRequest);


    static void initialize()
    {
        platform_facebookInitialize(sessionStatusDelegate, frictionlessRequestDelegate);
    }

    static bool isActive()
    {
        return platform_isFacebookActive();
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
	
	static bool isPermissionGranted(const char* permission)
    {
        return platform_isPermissionGranted(permission);
    }
};



NativeDelegate Facebook::_OnSessionStatusDelegate;
NativeDelegate Facebook::_OnFrictionlessRequestDelegate;


static int registerLoomFacebook(lua_State* L)
{
    beginPackage(L, "loom.social")

    .beginClass<Facebook>("Facebook")
        .addStaticMethod("isActive", &Facebook::isActive)
        .addStaticMethod("openSessionWithReadPermissions", &Facebook::openSessionWithReadPermissions)
        .addStaticMethod("requestNewPublishPermissions", &Facebook::requestNewPublishPermissions)
        .addStaticMethod("showFrictionlessRequestDialog", &Facebook::showFrictionlessRequestDialog)
        .addStaticMethod("getAccessToken", &Facebook::getAccessToken)
        .addStaticMethod("closeAndClearTokenInformation", &Facebook::closeAndClearTokenInformation)
        .addStaticMethod("getExpirationDate", &Facebook::getExpirationDate)
		.addStaticMethod("isPermissionGranted", &Facebook::isPermissionGranted)
        .addStaticProperty("onSessionStatus", &Facebook::getOnSessionStatusDelegate)
		.addStaticProperty("onFrictionlessRequest", &Facebook::getOnFrictionlessRequestDelegate)
    .endClass()

    .endPackage();

    return 0;
}

void installLoomFacebook()
{
    LOOM_DECLARE_NATIVETYPE(Facebook, registerLoomFacebook);
    Facebook::initialize();
}
