#include "AppDelegate.h"
#include "cocos2d.h"
#include "loom/common/core/log.h"
#include "loom/CCLoomCocos2D.h"
#include "loom/engine/bindings/loom/lmApplication.h"
#include "loom/engine/CocosDenshion/include/SimpleAudioEngine.h"

lmDefineLogGroup(gAppDelegateLogGroup, "appDelegate", 1, 0);

USING_NS_CC;

// cocos2d application instance
static AppDelegate s_sharedApplication;

CCScene *pScene = NULL;

void supplyEmbeddedAssets();

AppDelegate::AppDelegate()
{
}

AppDelegate::~AppDelegate()
{
}

bool AppDelegate::applicationDidFinishLaunching()
{
    NativeDelegate::markMainThread();

    supplyEmbeddedAssets();

    // initialize director
    CCDirector *pDirector = CCDirector::sharedDirector();
    pDirector->setOpenGLView(&CCEGLView::sharedOpenGLView());

    // In our hacked version of cocos, setting this to true means we don't 
    // downscale on retina displays. It basically lets us render at full
    // native res on all devices.
    pDirector->enableRetinaDisplay(true);

    // Note the window size.
    CCLoomCocos2d::setDisplaySize(
        (int) CCDirector::sharedDirector()->getWinSizeInPixels().width,
        (int) CCDirector::sharedDirector()->getWinSizeInPixels().height
    );

    // set FPS. the default value is 1.0/60 if you don't call this
    pDirector->setAnimationInterval(1.0 / 60);
   
    pScene = CCScene::create();

    pDirector->runWithScene(pScene);
   
    return true;
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate::applicationDidEnterBackground()
{
    NativeDelegate::markMainThread();
    LoomApplication::applicationDeactivated.invoke();
    CocosDenshion::SimpleAudioEngine::sharedEngine()->pauseBackgroundMusic();
    CocosDenshion::SimpleAudioEngine::sharedEngine()->pauseAllEffects();
    CCDirector::sharedDirector()->stopAnimation();
}

// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground()
{
    NativeDelegate::markMainThread();
    CCDirector::sharedDirector()->startAnimation();
    CocosDenshion::SimpleAudioEngine::sharedEngine()->resumeBackgroundMusic();
    CocosDenshion::SimpleAudioEngine::sharedEngine()->resumeAllEffects();
    LoomApplication::applicationActivated.invoke();
}
