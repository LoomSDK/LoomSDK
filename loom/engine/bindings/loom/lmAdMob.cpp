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

#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/platform/platformAdMob.h"

using namespace LS;

class BannerAd {
protected:
    loom_adMobHandle m_handle;

public:

    BannerAd(const char *publisherID, int size)
    {
        m_handle = platform_adMobCreate(publisherID, (loom_adMobBannerSize)size);
    }

    ~BannerAd()
    {
        platform_adMobDestroy(m_handle);
    }

    void show()
    {
        platform_adMobShow(m_handle);
    }

    void hide()
    {
        platform_adMobHide(m_handle);
    }

    int getX()
    {
        return platform_adMobGetDimensions(m_handle).x;
    }

    int getY()
    {
        return platform_adMobGetDimensions(m_handle).y;
    }

    int getWidth()
    {
        return platform_adMobGetDimensions(m_handle).width;
    }

    int getHeight()
    {
        return platform_adMobGetDimensions(m_handle).height;
    }

    void setX(int x)
    {
        loom_adMobDimensions frame = platform_adMobGetDimensions(m_handle);

        frame.x = x;

        platform_adMobSetDimensions(m_handle, frame);
    }

    void setY(int y)
    {
        loom_adMobDimensions frame = platform_adMobGetDimensions(m_handle);

        frame.y = y;

        platform_adMobSetDimensions(m_handle, frame);
    }

    void setWidth(int width)
    {
        loom_adMobDimensions frame = platform_adMobGetDimensions(m_handle);

        frame.width = width;

        platform_adMobSetDimensions(m_handle, frame);
    }

    void setHeight(int height)
    {
        loom_adMobDimensions frame = platform_adMobGetDimensions(m_handle);

        frame.height = height;

        platform_adMobSetDimensions(m_handle, frame);
    }
};

class InterstitialAd {
protected:
    loom_adMobHandle m_handle;

public:

    LOOM_DELEGATE(OnAdReceived);
    LOOM_DELEGATE(OnAdError);

    InterstitialAd(const char *publisherID)
    {
        m_handle = platform_adMobCreateInterstitial(publisherID, adMobCallback, (void *)this);
    }

    ~InterstitialAd()
    {
        platform_adMobDestroy(m_handle);
    }

    void show()
    {
        platform_adMobShowInterstitial(m_handle);
    }

    static void adMobCallback(void *payload, loom_adMobCallbackType callbackType, const char *data)
    {
        InterstitialAd *ad = (InterstitialAd *)payload;

        // handle callback, call delegates
        if (callbackType == ADMOB_AD_RECEIVED)
        {
            ad->_OnAdReceivedDelegate.invoke();
        }
        else if (callbackType == ADMOB_AD_ERROR)
        {
            ad->_OnAdErrorDelegate.pushArgument(data);
            ad->_OnAdErrorDelegate.invoke();
        }
    }
};

static int registerLoomAdMobAd(lua_State *L)
{
    beginPackage(L, "loom.admob")

       .beginClass<BannerAd>("BannerAd")
       .addConstructor<void (*)(const char *, int)>()
       .addMethod("show", &BannerAd::show)
       .addMethod("hide", &BannerAd::hide)
       .addMethod("__pget_x", &BannerAd::getX)
       .addMethod("__pset_x", &BannerAd::setX)
       .addMethod("__pget_width", &BannerAd::getWidth)
       .addMethod("__pset_width", &BannerAd::setWidth)
       .addMethod("__pget_y", &BannerAd::getY)
       .addMethod("__pset_y", &BannerAd::setY)
       .addMethod("__pget_height", &BannerAd::getHeight)
       .addMethod("__pset_height", &BannerAd::setHeight)
       .endClass()

       .beginClass<InterstitialAd>("InterstitialAd")
       .addConstructor<void (*)(const char *)>()
       .addMethod("show", &InterstitialAd::show)
       .addVarAccessor("onAdReceived", &InterstitialAd::getOnAdReceivedDelegate)
       .addVarAccessor("onAdError", &InterstitialAd::getOnAdErrorDelegate)
       .endClass()

       .endPackage();

    return 0;
}


void installLoomAdMobAd()
{
    LOOM_DECLARE_NATIVETYPE(BannerAd, registerLoomAdMobAd);
    LOOM_DECLARE_NATIVETYPE(InterstitialAd, registerLoomAdMobAd);
}
