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


#ifndef _MSC_VER
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif

#include "cocos2d.h"
#include "CCDirector.h"
#include "ccTypes.h"
#include "layers_scenes_transitions_nodes/CCLayer.h"
#include "SimpleAudioEngine.h"
#include "loom/script/loomscript.h"
#include "loom/CCLoomCocos2D.h"


#include "cocoa/CCObject.h"
#include "cocoa/CCSet.h"
#include "cocoa/CCArray.h"
#include "cocoa/CCGeometry.h"
#include "cocoa/CCAffineTransform.h"
#include "include/ccTypes.h"
#include "CCCamera.h"
#include "include/CCProtocols.h"
#include "base_nodes/CCNode.h"
#include "support/CCPointExtension.h"
#include "text_input_node/CCIMEDispatcher.h"


extern cocos2d::CCLayer *getRootLayer();

// script binding interface to CCLoomCocos2D
class LoomCocos2d {
public:

    static void setDisplayCaption(const utString& caption)
    {
        CCLoomCocos2d::setDisplayCaption(caption);
    }

    static const utString& getDisplayCaption()
    {
        return CCLoomCocos2d::getDisplayCaption();
    }

    static void setDisplayOrientation(const utString& orientation)
    {
        CCLoomCocos2d::setDisplayOrientation(orientation);
    }

    static const utString& getDisplayOrientation()
    {
        return CCLoomCocos2d::getDisplayOrientation();
    }

    static int getDisplayWidth()
    {
        return (int)cocos2d::CCDirector::sharedDirector()->getWinSizeInPixels().width;
    }

    static int getDisplayHeight()
    {
        return (int)cocos2d::CCDirector::sharedDirector()->getWinSizeInPixels().height;
    }

    static void setDisplayWidth(int width)
    {
        CCLoomCocos2d::setDisplayWidth(width);
    }

    static void setDisplayHeight(int height)
    {
        CCLoomCocos2d::setDisplayHeight(height);
    }

    static void toggleFullscreen()
    {
        cocos2d::CCDirector::sharedDirector()->getOpenGLView()->toggleFullScreen();
    }

    LOOM_STATICDELEGATE(DisplayStatsChanged);

    static void setDisplayStats(bool enabled)
    {
        cocos2d::CCDirector::sharedDirector()->setDisplayStats(enabled);

        _DisplayStatsChangedDelegate.pushArgument(enabled);
        _DisplayStatsChangedDelegate.invoke();
    }

    static bool getDisplayStats()
    {
        return cocos2d::CCDirector::sharedDirector()->isDisplayStats();
    }

    static void cleanup()
    {
        // remove all of the layers and nodes
        cocos2d::CCScene *scene = cocos2d::CCDirector::sharedDirector()->getRunningScene();

        scene->removeAllChildrenWithCleanup(true);
    }

    static void shutdown()
    {
        cocos2d::CCDirector::sharedDirector()->end();
    }

    // TODO: this should be bound to CCScene
    static void addLayer(cocos2d::CCLayer *layer)
    {
        cocos2d::CCScene *scene = getScene();

        scene->addChild(layer);
        cocos2d::CCDirector::sharedDirector()->getTouchDispatcher()->addTargetedDelegate(layer, 0, false);
    }

    // TODO: this should be bound to CCScene
    static void removeLayer(cocos2d::CCLayer *layer, bool cleanup)
    {
        cocos2d::CCScene *scene = getScene();

        scene->removeChild(layer, cleanup);
        cocos2d::CCDirector::sharedDirector()->getTouchDispatcher()->removeDelegate(layer);
    }

    static cocos2d::CCScene *getScene()
    {
        cocos2d::CCScene *scene = cocos2d::CCDirector::sharedDirector()->getRunningScene();

        // there is a case where the scene is not initialized fully
        if (!scene)
        {
            scene = cocos2d::CCDirector::sharedDirector()->getNextScene();
        }

        return scene;
    }
};

NativeDelegate LoomCocos2d::_DisplayStatsChangedDelegate;

static int registerCocos2D(lua_State *L)
{
    beginPackage(L, "loom2d.display")

       .beginClass<LoomCocos2d>("Cocos2D")

       .addStaticProperty("onDisplayStatsChanged", &LoomCocos2d::getDisplayStatsChangedDelegate)
       .addStaticProperty("onOrientationChanged", &CCLoomCocos2d::getOrientationChangedDelegate)
       .addStaticProperty("onDisplaySizeChanged", &CCLoomCocos2d::getDisplaySizeChangedDelegate)

       .addStaticMethod("getOrientation", &CCLoomCocos2d::getOrientation)

       .addStaticMethod("toggleFullscreen", &LoomCocos2d::toggleFullscreen)

       .addStaticMethod("getDisplayCaption", &LoomCocos2d::getDisplayCaption)
       .addStaticMethod("setDisplayCaption", &LoomCocos2d::setDisplayCaption)

       .addStaticMethod("getDisplayOrientation", &LoomCocos2d::getDisplayOrientation)
       .addStaticMethod("setDisplayOrientation", &LoomCocos2d::setDisplayOrientation)

       .addStaticMethod("getDisplayWidth", &LoomCocos2d::getDisplayWidth)
       .addStaticMethod("getDisplayHeight", &LoomCocos2d::getDisplayHeight)
       .addStaticMethod("getDisplayStats", &LoomCocos2d::getDisplayStats)
       .addStaticMethod("setDisplayWidth", &LoomCocos2d::setDisplayWidth)
       .addStaticMethod("setDisplayHeight", &LoomCocos2d::setDisplayHeight)
       .addStaticMethod("setDisplayStats", &LoomCocos2d::setDisplayStats)
       .addStaticMethod("cleanup", &LoomCocos2d::cleanup)
       .addStaticMethod("shutdown", &LoomCocos2d::shutdown)
       .addStaticMethod("addLayer", &LoomCocos2d::addLayer)
       .addStaticMethod("removeLayer", &LoomCocos2d::removeLayer)
       .endClass()

       .endPackage();

    return 0;
}


using namespace cocos2d;

static int registerSimpleAudioEngine(lua_State *L)
{
    beginPackage(L, "loom.sound")

       .beginClass<CocosDenshion::SimpleAudioEngine>("SimpleAudioEngine")

       .addStaticMethod("sharedEngine", &CocosDenshion::SimpleAudioEngine::sharedEngine)
       .addStaticMethod("end", &CocosDenshion::SimpleAudioEngine::end)
       .addMethod("playBackgroundMusic", &CocosDenshion::SimpleAudioEngine::playBackgroundMusic)
       .addMethod("preloadBackgroundMusic", &CocosDenshion::SimpleAudioEngine::preloadBackgroundMusic)
       .addMethod("stopBackgroundMusic", &CocosDenshion::SimpleAudioEngine::stopBackgroundMusic)
       .addMethod("pauseBackgroundMusic", &CocosDenshion::SimpleAudioEngine::pauseBackgroundMusic)
       .addMethod("resumeBackgroundMusic", &CocosDenshion::SimpleAudioEngine::resumeBackgroundMusic)
       .addMethod("rewindBackgroundMusic", &CocosDenshion::SimpleAudioEngine::rewindBackgroundMusic)
       .addMethod("willPlayBackgroundMusic", &CocosDenshion::SimpleAudioEngine::willPlayBackgroundMusic)
       .addMethod("isBackgroundMusicPlaying", &CocosDenshion::SimpleAudioEngine::isBackgroundMusicPlaying)
       .addMethod("getBackgroundMusicVolume", &CocosDenshion::SimpleAudioEngine::getBackgroundMusicVolume)
       .addMethod("setBackgroundMusicVolume", &CocosDenshion::SimpleAudioEngine::setBackgroundMusicVolume)
       .addMethod("getEffectsVolume", &CocosDenshion::SimpleAudioEngine::getEffectsVolume)
       .addMethod("setEffectsVolume", &CocosDenshion::SimpleAudioEngine::setEffectsVolume)
       .addMethod("playEffect", &CocosDenshion::SimpleAudioEngine::playEffect)
       .addMethod("pauseEffect", &CocosDenshion::SimpleAudioEngine::pauseEffect)
       .addMethod("pauseAllEffects", &CocosDenshion::SimpleAudioEngine::pauseAllEffects)
       .addMethod("resumeEffect", &CocosDenshion::SimpleAudioEngine::resumeEffect)
       .addMethod("resumeAllEffects", &CocosDenshion::SimpleAudioEngine::resumeAllEffects)
       .addMethod("stopEffect", &CocosDenshion::SimpleAudioEngine::stopEffect)
       .addMethod("stopAllEffects", &CocosDenshion::SimpleAudioEngine::stopAllEffects)
       .addMethod("preloadEffect", &CocosDenshion::SimpleAudioEngine::preloadEffect)
       .addMethod("unloadEffect", &CocosDenshion::SimpleAudioEngine::unloadEffect)

       .endClass()

       .endPackage();

    return 0;
}


void installPackage();

void installPackageCocos2DX()
{
    // Register some bindings for Cocos.
    LOOM_DECLARE_NATIVETYPE(LoomCocos2d, registerCocos2D);
    LOOM_DECLARE_NATIVETYPE(CocosDenshion::SimpleAudioEngine, registerSimpleAudioEngine);

    installPackage();
}


static int registerCCLayer(lua_State *L)
{
    beginPackage(L, "loom2d.display")

       .beginClass<cocos2d::CCLayer>("CCLayer")

       .addMethod("autorelease", &cocos2d::CCObject::autorelease_void)

       .addMethod("init", &cocos2d::CCLayer::init)

       .addVarAccessor("onTouchBegan", &cocos2d::CCLayer::getTouchBeganDelegate)
       .addVarAccessor("onTouchMoved", &cocos2d::CCLayer::getTouchMovedDelegate)
       .addVarAccessor("onTouchEnded", &cocos2d::CCLayer::getTouchEndedDelegate)
       .addVarAccessor("onTouchCancelled", &cocos2d::CCLayer::getTouchCancelledDelegate)

       .addVarAccessor("onKeyBackClicked", &cocos2d::CCLayer::getKeyBackClickedDelegate)
       .addVarAccessor("onKeyMenuClicked", &cocos2d::CCLayer::getKeyMenuClickedDelegate)
       .addVarAccessor("onKeyDown", &cocos2d::CCLayer::getKeyDownDelegate)
       .addVarAccessor("onKeyUp", &cocos2d::CCLayer::getKeyUpDelegate)

       .addVarAccessor("onScrollWheelYMoved", &cocos2d::CCLayer::getScrollWheelYMovedDelegate)
       .addVarAccessor("onAccelerate", &cocos2d::CCLayer::getDidAccelerateDelegate)

       .addStaticMethod("create", &cocos2d::CCLayer::create)
       .addStaticMethod("rootLayer", &getRootLayer)

       .addMethod("onEnter", &cocos2d::CCLayer::onEnter)
       .addMethod("onExit", &cocos2d::CCLayer::onExit)
       .addMethod("onEnterTransitionDidFinish", &cocos2d::CCLayer::onEnterTransitionDidFinish)
       .addMethod("didAccelerate", &cocos2d::CCLayer::didAccelerate)
       .addMethod("registerWithTouchDispatcher", &cocos2d::CCLayer::registerWithTouchDispatcher)
       .addMethod("registerScriptTouchHandler", (void (cocos2d::CCLayer::*)(int, bool, int, bool)) & cocos2d::CCLayer::registerScriptTouchHandler)
       .addMethod("unregisterScriptTouchHandler", &cocos2d::CCLayer::unregisterScriptTouchHandler)
       .addMethod("isTouchEnabled", &cocos2d::CCLayer::isTouchEnabled)
       .addMethod("setTouchEnabled", &cocos2d::CCLayer::setTouchEnabled)
       .addMethod("isAccelerometerEnabled", &cocos2d::CCLayer::isAccelerometerEnabled)
       .addMethod("setAccelerometerEnabled", &cocos2d::CCLayer::setAccelerometerEnabled)
       .addMethod("isKeypadEnabled", &cocos2d::CCLayer::isKeypadEnabled)
       .addMethod("setKeypadEnabled", &cocos2d::CCLayer::setKeypadEnabled)
       .addMethod("isScrollWheelEnabled", &cocos2d::CCLayer::isScrollWheelEnabled)
       .addMethod("setScrollWheelEnabled", &cocos2d::CCLayer::setScrollWheelEnabled)

       .addVarAccessor("touchBeganDelegate", &cocos2d::CCLayer::getTouchBeganDelegate)
       .addVarAccessor("touchMovedDelegate", &cocos2d::CCLayer::getTouchMovedDelegate)
       .addVarAccessor("touchEndedDelegate", &cocos2d::CCLayer::getTouchEndedDelegate)
       .addVarAccessor("touchCancelledDelegate", &cocos2d::CCLayer::getTouchCancelledDelegate)

       .addConstructor<void (*)(void)>()
       .endClass()

       .endPackage();

    return 0;
}


static int registerCCUserDefault(lua_State *L)
{
    beginPackage(L, "loom.platform")

       .beginClass<cocos2d::CCUserDefault>("UserDefault")

       .addMethod("getBoolForKey", &cocos2d::CCUserDefault::getBoolForKey)
       .addMethod("getIntegerForKey", &cocos2d::CCUserDefault::getIntegerForKey)
       .addMethod("getFloatForKey", &cocos2d::CCUserDefault::getFloatForKey)
       .addMethod("getStringForKey", &cocos2d::CCUserDefault::getStringForKey)
       .addMethod("getDoubleForKey", &cocos2d::CCUserDefault::getIntegerForKey)

       .addMethod("setBoolForKey", &cocos2d::CCUserDefault::setBoolForKey)
       .addMethod("setIntegerForKey", &cocos2d::CCUserDefault::setIntegerForKey)
       .addMethod("setFloatForKey", &cocos2d::CCUserDefault::setFloatForKey)
       .addMethod("setStringForKey", &cocos2d::CCUserDefault::setStringForKey)
       .addMethod("setDoubleForKey", &cocos2d::CCUserDefault::setIntegerForKey)

       .addStaticMethod("sharedUserDefault", &cocos2d::CCUserDefault::sharedUserDefault)
       .addStaticMethod("purgeSharedUserDefault", &cocos2d::CCUserDefault::purgeSharedUserDefault)
       .endClass()

       .endPackage();

    return 0;
}


static int registerCCLoomScriptIMEDelegate(lua_State *L)
{
    beginPackage(L, "loom.platform")

       .beginClass<cocos2d::CCLoomScriptIMEDelegate>("IMEDelegate")

       .addConstructor<void (*)(void)>()

       .addVar("canAttachWithIME", &cocos2d::CCLoomScriptIMEDelegate::_canAttachWithIME)
       .addVar("canDetachWithIME", &cocos2d::CCLoomScriptIMEDelegate::_canDetachWithIME)
       .addVar("contentText", &cocos2d::CCLoomScriptIMEDelegate::contentText)

       .addVarAccessor("onDidAttachWithIME", &cocos2d::CCLoomScriptIMEDelegate::getDidAttachWithIMEDelegate)
       .addVarAccessor("onDidDetachWithIME", &cocos2d::CCLoomScriptIMEDelegate::getDidDetachWithIMEDelegate)
       .addVarAccessor("onInsertText", &cocos2d::CCLoomScriptIMEDelegate::getInsertTextDelegate)
       .addVarAccessor("onDeleteBackward", &cocos2d::CCLoomScriptIMEDelegate::getDeleteBackwardDelegate)
       .addVarAccessor("onKeyboardWillShow", &cocos2d::CCLoomScriptIMEDelegate::getKeyboardWillShowDelegate)
       .addVarAccessor("onKeyboardDidShow", &cocos2d::CCLoomScriptIMEDelegate::getKeyboardDidShowDelegate)
       .addVarAccessor("onKeyboardWillHide", &cocos2d::CCLoomScriptIMEDelegate::getKeyboardWillHideDelegate)
       .addVarAccessor("onKeyboardDidHide", &cocos2d::CCLoomScriptIMEDelegate::getKeyboardDidHideDelegate)

       .addMethod("attachWithIME", &cocos2d::CCLoomScriptIMEDelegate::attachWithIME)
       .addMethod("detachWithIME", &cocos2d::CCLoomScriptIMEDelegate::detachWithIME)

       .endClass()

       .endPackage();

    return 0;
}


void installPackage()
{
    LOOM_DECLARE_MANAGEDNATIVETYPE(CCLayer, registerCCLayer);
    LOOM_DECLARE_MANAGEDNATIVETYPE(CCUserDefault, registerCCUserDefault);
    LOOM_DECLARE_MANAGEDNATIVETYPE(CCLoomScriptIMEDelegate, registerCCLoomScriptIMEDelegate);
}
