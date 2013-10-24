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

#include "loom/common/core/log.h"
#include "loom/script/loomscript.h"
#include "loom/common/platform/platformMobile.h"

using namespace LS;

lmDefineLogGroup(gMobileLogGroup, "Loom.Mobile", 1, 0);

/// Script bindings to the native Mobile API.
///
/// See Mobile.ls for documentation on this API.
class Mobile
{
public:
    static void initialize()
    {
        platform_mobileInitialize();
    }
};


///Dolby Audio access class... Android Only... treated as though a sub-class of Mobile (hence the reason it doesn't have it's own 'init')
class DolbyAudio
{   
public:
    static bool supported()
    {
        return platform_isDolbyAudioSupported();
    }
    static int privateProfileID()
    {
        return platform_getDolbyAudioPrivateProfileID();
    }
    static void setProcessingEnabled(bool enable)
    {
        platform_setDolbyAudioProcessingEnabled(enable);
    }
    static bool isProcessingEnabled()
    {
        return platform_isDolbyAudioProcessingEnabled();
    }

    static void setProcessingProfile(int profileIndex)
    {
        platform_setDolbyAudioProcessingProfile(profileIndex);
    }
    static int getNumProfiles()
    {
        return platform_getNumDolbyAudioProfiles();
    }
    static const char *getProfileName(int profileIndex)
    {
        return platform_getDolbyAudioProfileName(profileIndex);
    }
    static int getSelectedProfile()
    {
        return platform_getSelectedDolbyAudioProfile();
    }
};



static int registerLoomMobile(lua_State *L)
{
    beginPackage(L, "loom.platform")

        .beginClass<Mobile>("Mobile")

///TODO: add to once we're able to get this into master
///     -vibration
///     -screen timeout///TODO: add to once we're able to get this into master
       
        .endClass()

    .endPackage();

    return 0;
}


static int registerLoomDolbyAudio(lua_State *L)
{
    beginPackage(L, "loom.platform")

        .beginClass<DolbyAudio>("DolbyAudio")

            .addStaticProperty("supported", &DolbyAudio::supported)
            .addStaticProperty("privateProfileID", &DolbyAudio::privateProfileID)

            .addStaticMethod("setProcessingEnabled", &DolbyAudio::setProcessingEnabled)
            .addStaticMethod("isProcessingEnabled", &DolbyAudio::isProcessingEnabled)
            .addStaticMethod("setProcessingProfile", &DolbyAudio::setProcessingProfile)
            .addStaticMethod("getNumProfiles", &DolbyAudio::getNumProfiles)
            .addStaticMethod("getProfileName", &DolbyAudio::getProfileName)
            .addStaticMethod("getSelectedProfile", &DolbyAudio::getSelectedProfile)
   
        .endClass()

    .endPackage();
    return 0;
}



void installLoomMobile()
{
    LOOM_DECLARE_NATIVETYPE(Mobile, registerLoomMobile);
    LOOM_DECLARE_NATIVETYPE(DolbyAudio, registerLoomDolbyAudio);
    Mobile::initialize();
}
