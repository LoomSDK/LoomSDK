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

#include "loom/script/loomscript.h"


// script binding interface to CCLoomCocos2D
class LoomCocos2d {
public:

    static void setDisplayCaption(const utString& caption)
    {
//        CCLoomCocos2d::setDisplayCaption(caption);
    }

    static const utString& getDisplayCaption()
    {
//        return CCLoomCocos2d::getDisplayCaption();
    }

    static void setDisplayOrientation(const utString& orientation)
    {
//        CCLoomCocos2d::setDisplayOrientation(orientation);
    }

    static const utString& getDisplayOrientation()
    {
//        return CCLoomCocos2d::getDisplayOrientation();
    }

    static int getDisplayWidth()
    {
//        return (int)cocos2d::CCDirector::sharedDirector()->getWinSizeInPixels().width;
    }

    static int getDisplayHeight()
    {
//        return (int)cocos2d::CCDirector::sharedDirector()->getWinSizeInPixels().height;
    }

    static void setDisplayWidth(int width)
    {
//        CCLoomCocos2d::setDisplayWidth(width);
    }

    static void setDisplayHeight(int height)
    {
//        CCLoomCocos2d::setDisplayHeight(height);
    }

    static void toggleFullscreen()
    {
//        cocos2d::CCDirector::sharedDirector()->getOpenGLView()->toggleFullScreen();
    }

    LOOM_STATICDELEGATE(DisplayStatsChanged);

    static void setDisplayStats(bool enabled)
    {
//        cocos2d::CCDirector::sharedDirector()->setDisplayStats(enabled);

        _DisplayStatsChangedDelegate.pushArgument(enabled);
        _DisplayStatsChangedDelegate.invoke();
    }

    static bool getDisplayStats()
    {
//        return cocos2d::CCDirector::sharedDirector()->isDisplayStats();
        return false;
    }
    
    LOOM_STATICDELEGATE(OrientationChanged);
    LOOM_STATICDELEGATE(DisplaySizeChanged);

    static void cleanup()
    {
        // remove all of the layers and nodes
//        cocos2d::CCScene *scene = cocos2d::CCDirector::sharedDirector()->getRunningScene();
//
//        scene->removeAllChildrenWithCleanup(true);
    }

    static int getOrientation()
    {
        return 0;
    }

    static void shutdown()
    {
//        cocos2d::CCDirector::sharedDirector()->end();
    }
    
    // TODO: this should be bound to CCScene
//    static void addLayer(cocos2d::CCLayer *layer)
//    {
//        cocos2d::CCScene *scene = getScene();
//
//        scene->addChild(layer);
//        cocos2d::CCDirector::sharedDirector()->getTouchDispatcher()->addTargetedDelegate(layer, 0, false);
//    }

    // TODO: this should be bound to CCScene
//    static void removeLayer(cocos2d::CCLayer *layer, bool cleanup)
//    {
//        cocos2d::CCScene *scene = getScene();
//
//        scene->removeChild(layer, cleanup);
//        cocos2d::CCDirector::sharedDirector()->getTouchDispatcher()->removeDelegate(layer);
//    }

//    static cocos2d::CCScene *getScene()
//    {
//        cocos2d::CCScene *scene = cocos2d::CCDirector::sharedDirector()->getRunningScene();
//
//        // there is a case where the scene is not initialized fully
//        if (!scene)
//        {
//            scene = cocos2d::CCDirector::sharedDirector()->getNextScene();
//        }
//
//        return scene;
//    }
};

NativeDelegate LoomCocos2d::_DisplayStatsChangedDelegate;
NativeDelegate LoomCocos2d::_OrientationChangedDelegate;
NativeDelegate LoomCocos2d::_DisplaySizeChangedDelegate;

static int registerCocos2D(lua_State *L)
{
    beginPackage(L, "loom2d.display")

       .beginClass<LoomCocos2d>("Cocos2D")

       .addStaticProperty("onDisplayStatsChanged", &LoomCocos2d::getDisplayStatsChangedDelegate)
       .addStaticProperty("onOrientationChanged", &LoomCocos2d::getOrientationChangedDelegate)
       .addStaticProperty("onDisplaySizeChanged", &LoomCocos2d::getDisplaySizeChangedDelegate)

       .addStaticMethod("getOrientation", &LoomCocos2d::getOrientation)

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
//       .addStaticMethod("addLayer", &LoomCocos2d::addLayer)
//       .addStaticMethod("removeLayer", &LoomCocos2d::removeLayer)
       .endClass()

       .endPackage();

    return 0;
}


//using namespace cocos2d;

void installPackage();

void installPackageCocos2DX()
{
    // Register some bindings for Cocos.
    LOOM_DECLARE_NATIVETYPE(LoomCocos2d, registerCocos2D);

    installPackage();
}

class DummyDefaults
{
public:
    bool getBoolForKey(const char *s, bool v) { return v; };
    int getIntegerForKey(const char *s, int v) { return v; };
    float getFloatForKey(const char *s, float v) { return v; };
    const char *getStringForKey(const char *s, const char* v) { return v; };
    double getDoubleForKey(const char *s, double v) { return v; };
    
    void setBoolForKey(const char *k, bool v) {};
    void setIntegerForKey(const char *k, int v) {};
    void setFloatForKey(const char *k, float v) {};
    void setStringForKey(const char *k, const char * v) {};
    void setDoubleForKey(const char *k, double v) {};

    static void purgeSharedUserDefault()
    {
    }
    static DummyDefaults *sharedUserDefault()
    {
        return NULL;
    }
};

static int registerCCUserDefault(lua_State *L)
{
    beginPackage(L, "loom.platform")

       .beginClass<DummyDefaults>("UserDefault")

       .addMethod("getBoolForKey", &DummyDefaults::getBoolForKey)
       .addMethod("getIntegerForKey", &DummyDefaults::getIntegerForKey)
       .addMethod("getFloatForKey", &DummyDefaults::getFloatForKey)
       .addMethod("getStringForKey", &DummyDefaults::getStringForKey)
       .addMethod("getDoubleForKey", &DummyDefaults::getDoubleForKey)

       .addMethod("setBoolForKey", &DummyDefaults::setBoolForKey)
       .addMethod("setIntegerForKey", &DummyDefaults::setIntegerForKey)
       .addMethod("setFloatForKey", &DummyDefaults::setFloatForKey)
       .addMethod("setStringForKey", &DummyDefaults::setStringForKey)
       .addMethod("setDoubleForKey", &DummyDefaults::setIntegerForKey)

       .addStaticMethod("sharedUserDefault", &DummyDefaults::sharedUserDefault)
       .addStaticMethod("purgeSharedUserDefault", &DummyDefaults::purgeSharedUserDefault)
       .endClass()

       .endPackage();

    return 0;
}

class IMEDelegate
{
public:
    
    IMEDelegate()
    {
        _canAttachWithIME = false;
        _canDetachWithIME = false;
        contentText = "[null]";
    }
    
    bool _canAttachWithIME, _canDetachWithIME;
    const char *contentText;
    
    LOOM_DELEGATE(DidAttachWithIME);
    LOOM_DELEGATE(DidDetachWithIME);
    LOOM_DELEGATE(InsertText);
    LOOM_DELEGATE(DeleteBackward);
    LOOM_DELEGATE(KeyboardWillShow);
    LOOM_DELEGATE(KeyboardDidShow);
    LOOM_DELEGATE(KeyboardWillHide);
    LOOM_DELEGATE(KeyboardDidHide);

    bool attachWithIME(int type = 0) { return true; }
    bool detachWithIME() { return false; }
    
};


static int registerCCLoomScriptIMEDelegate(lua_State *L)
{
    beginPackage(L, "loom.platform")
    
    .beginClass<IMEDelegate>("IMEDelegate")
    
    .addConstructor<void (*)(void)>()
    
    .addVar("canAttachWithIME", &IMEDelegate::_canAttachWithIME)
    .addVar("canDetachWithIME", &IMEDelegate::_canDetachWithIME)
    .addVar("contentText", &IMEDelegate::contentText)
    
    .addVarAccessor("onDidAttachWithIME", &IMEDelegate::getDidAttachWithIMEDelegate)
    .addVarAccessor("onDidDetachWithIME", &IMEDelegate::getDidDetachWithIMEDelegate)
    .addVarAccessor("onInsertText", &IMEDelegate::getInsertTextDelegate)
    .addVarAccessor("onDeleteBackward", &IMEDelegate::getDeleteBackwardDelegate)
    .addVarAccessor("onKeyboardWillShow", &IMEDelegate::getKeyboardWillShowDelegate)
    .addVarAccessor("onKeyboardDidShow", &IMEDelegate::getKeyboardDidShowDelegate)
    .addVarAccessor("onKeyboardWillHide", &IMEDelegate::getKeyboardWillHideDelegate)
    .addVarAccessor("onKeyboardDidHide", &IMEDelegate::getKeyboardDidHideDelegate)
    
    .addMethod("attachWithIME", &IMEDelegate::attachWithIME)
    .addMethod("detachWithIME", &IMEDelegate::detachWithIME)
    
    .endClass()
    
    .endPackage();

    return 0;
}


void installPackage()
{
    LOOM_DECLARE_MANAGEDNATIVETYPE(DummyDefaults, registerCCUserDefault);
    LOOM_DECLARE_MANAGEDNATIVETYPE(IMEDelegate, registerCCLoomScriptIMEDelegate);
}
