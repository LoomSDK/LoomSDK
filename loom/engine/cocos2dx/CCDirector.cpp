/****************************************************************************
*  Copyright (c) 2010-2012 cocos2d-x.org
*  Copyright (c) 2008-2010 Ricardo Quesada
*  Copyright (c) 2011      Zynga Inc.
*
*  http://www.cocos2d-x.org
*
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in
*  all copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
*  THE SOFTWARE.
****************************************************************************/
#include "CCDirector.h"
#include "cocoa/CCNS.h"
#include "layers_scenes_transitions_nodes/CCScene.h"
#include "cocoa/CCArray.h"
#include "CCScheduler.h"
#include "ccMacros.h"
#include "touch_dispatcher/CCTouchDispatcher.h"
#include "support/CCPointExtension.h"
#include "support/CCNotificationCenter.h"
#include "cocoa/CCAutoreleasePool.h"
#include "platform/platform.h"
#include "platform/CCFileUtils.h"
#include "CCApplication.h"
#include "CCConfiguration.h"
#include "CCProtocols.h"
#include "keypad_dispatcher/CCKeypadDispatcher.h"
#include "CCAccelerometer.h"
#include "touch_dispatcher/CCTouch.h"
#include "support/CCUserDefault.h"
#include "kazmath/kazmath.h"
#include "kazmath/GL/matrix.h"
#include "support/CCProfiling.h"
#include "CCEGLView.h"
#include <string>

#include "loom/common/platform/platformTime.h"
#include "loom/common/core/performance.h"
#include "loom/engine/cocos2dx/loom/CCLoomCocos2D.h"

#include "scrollwheel_dispatcher/CCScrollWheelDispatcher.h"

#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/engine/loom2d/l2dStage.h"

using namespace std;

unsigned int g_uNumberOfDraws = 0;

NS_CC_BEGIN
// XXX it shoul be a Director ivar. Move it there once support for multiple directors is added

// singleton stuff
static CCDisplayLinkDirector s_SharedDirector;

#define kDefaultFPS    60      // 60 frames per second
extern const char *cocos2dVersion(void);

CCDirector *CCDirector::sharedDirector(void)
{
    static bool s_bFirstUseDirector = true;

    if (s_bFirstUseDirector)
    {
        s_bFirstUseDirector = false;
        s_SharedDirector.init();
    }

    return &s_SharedDirector;
}


CCDirector::CCDirector(void)
{
}


bool CCDirector::init(void)
{
    CCLOG("cocos2d: %s", cocos2dVersion());

    // scenes
    m_pRunningScene = NULL;
    m_pNextScene    = NULL;

    m_pNotificationNode = NULL;

    m_dOldAnimationInterval = m_dAnimationInterval = 1.0 / kDefaultFPS;
    m_pobScenesStack        = new CCArray();
    m_pobScenesStack->init();

    // Set default projection (3D)
    m_eProjection = kCCDirectorProjectionDefault;

    // projection delegate if "Custom" projection is used
    m_pProjectionDelegate = NULL;

    // FPS
    m_fAccumDt      = 0.0f;
    m_fFrameRate    = 0.0f;
    m_bDisplayStats = false;
    m_uTotalFrames  = m_uFrames = 0;
    m_pszFPS        = new char[10];
    m_pLastUpdate   = new struct cc_timeval ();

    // paused ?
    m_bPaused = false;

    // purge ?
    m_bPurgeDirectorInNextLoop = false;

    m_obWinSizeInPixels = m_obWinSizeInPoints = CCSizeZero;

    m_pobOpenGLView = NULL;

    m_fContentScaleFactor      = 1;
    m_bIsContentScaleSupported = false;

    m_pWatcherFun    = NULL;
    m_pWatcherSender = NULL;

    // scheduler
    m_pScheduler = new CCScheduler();
    // touchDispatcher
    m_pTouchDispatcher = new CCTouchDispatcher();
    m_pTouchDispatcher->init();

    // KeypadDispatcher
    m_pKeypadDispatcher = new CCKeypadDispatcher();

    // Accelerometer
    m_pAccelerometer = new CCAccelerometer();

    // ScrollWheel dispatcher
    m_pScrollWheelDispatcher = new CCScrollWheelDispatcher();

    // create autorelease pool
    CCPoolManager::sharedPoolManager()->push();

    return true;
}


CCDirector::~CCDirector(void)
{
    CCLOG("cocos2d: deallocing %p", this);

    CC_SAFE_RELEASE(m_pRunningScene);
    CC_SAFE_RELEASE(m_pNotificationNode);
    CC_SAFE_RELEASE(m_pobScenesStack);
    CC_SAFE_RELEASE(m_pScheduler);
    CC_SAFE_RELEASE(m_pTouchDispatcher);
    CC_SAFE_RELEASE(m_pKeypadDispatcher);
    CC_SAFE_DELETE(m_pAccelerometer);

    // pop the autorelease pool
    CCPoolManager::sharedPoolManager()->pop();
    CCPoolManager::purgePoolManager();

    // delete m_pLastUpdate
    CC_SAFE_DELETE(m_pLastUpdate);
    // delete fps string
    delete []m_pszFPS;
}


void CCDirector::setGLDefaultValues(void)
{
    // This method SHOULD be called only after openGLView_ was initialized
    CCAssert(m_pobOpenGLView, "opengl view should not be null");

    setAlphaBlending(true);
    setDepthTest(false);
    setProjection(m_eProjection);
}


static GFX::VertexPosColorTex s_quadVertices[4] =
{
    {   0.0f, 128.0f, 0.0f, 0xFFFFFFFF, 0, 0 },
    { 128.0f, 128.0f, 0.0f, 0xFFFFFFFF, 1, 0 },
    {   0.0f,   0.0f, 0.0f, 0xFFFFFFFF, 0, 1 },
    { 128.0f,   0.0f, 0.0f, 0xFFFFFFFF, 1, 1 },
};

// Draw the SCene
void CCDirector::drawScene(void)
{
    // calculate "global" dt
    calculateDeltaTime();

    //tick before glClear: issue #533
    if (!m_bPaused)
    {
        m_pScheduler->update(m_fDeltaTime);
    }

    /* to avoid flickr, nextScene MUST be here: after tick and before draw.
     * XXX: Which bug is this one. It seems that it can't be reproduced with v0.9 */
    if (m_pNextScene)
    {
        setNextScene();
    }

    kmGLPushMatrix();

    // draw the scene
    if (m_pRunningScene)
    {
        float proj[16];
        float view[16];
        m_eProjection = kCCDirectorProjection2D;
        setProjection(m_eProjection);

        kmGLGetMatrix(KM_GL_PROJECTION, (kmMat4 *)proj);
        kmGLGetMatrix(KM_GL_MODELVIEW, (kmMat4 *)view);

        Loom2D::Stage::setViewTransform(view, proj);
        Loom2D::Stage::invokeRenderStage();
    }

    // draw the notifications node
    if (m_pNotificationNode)
    {
        m_pNotificationNode->visit();
    }

    if (m_bDisplayStats)
    {
        //showStats();
    }

    if (m_pWatcherFun && m_pWatcherSender)
    {
        (*m_pWatcherFun)(m_pWatcherSender);
    }

    kmGLPopMatrix();

    m_uTotalFrames++;

    // swap buffers
    if (m_pobOpenGLView)
    {
        m_pobOpenGLView->swapBuffers();
    }

    if (m_bDisplayStats)
    {
        //calculateMPF();
    }
}


void CCDirector::calculateDeltaTime(void)
{
    struct cc_timeval now;

    if (CCTime::gettimeofdayCocos2d(&now, NULL) != 0)
    {
        CCLOG("error in gettimeofday");
        m_fDeltaTime = 0;
        return;
    }

    // new delta time. Re-fixed issue #1277
    if (m_bNextDeltaTimeZero)
    {
        m_fDeltaTime         = 0;
        m_bNextDeltaTimeZero = false;
    }
    else
    {
        m_fDeltaTime = (now.tv_sec - m_pLastUpdate->tv_sec) + (now.tv_usec - m_pLastUpdate->tv_usec) / 1000000.0f;
        m_fDeltaTime = MAX(0, m_fDeltaTime);
    }

#ifdef DEBUG
    // If we are debugging our code, prevent big delta time
    if (m_fDeltaTime > 0.2f)
    {
        m_fDeltaTime = 1 / 60.0f;
    }
#endif

    *m_pLastUpdate = now;
}


// m_pobOpenGLView

void CCDirector::setOpenGLView(CCEGLViewProtocol *pobOpenGLView)
{
    CCAssert(pobOpenGLView, "opengl view should not be null");

    if (m_pobOpenGLView != pobOpenGLView)
    {
        // because EAGLView is not kind of CCObject
        delete m_pobOpenGLView; // [openGLView_ release]
        m_pobOpenGLView = pobOpenGLView;

        // set size
        m_obWinSizeInPoints = m_pobOpenGLView->getSize();
        m_obWinSizeInPixels = CCSizeMake(m_obWinSizeInPoints.width * m_fContentScaleFactor, m_obWinSizeInPoints.height * m_fContentScaleFactor);


        if (m_pobOpenGLView)
        {
            setGLDefaultValues();
        }

        CHECK_GL_ERROR_DEBUG();

        if (m_fContentScaleFactor != 1)
        {
            updateContentScaleFactor();
        }

        m_pobOpenGLView->setTouchDelegate(m_pTouchDispatcher);
        m_pTouchDispatcher->setDispatchEvents(true);
    }
}


void CCDirector::setNextDeltaTimeZero(bool bNextDeltaTimeZero)
{
    m_bNextDeltaTimeZero = bNextDeltaTimeZero;
}


void CCDirector::setProjection(ccDirectorProjection kProjection)
{
    CCSize size      = m_obWinSizeInPixels;
    CCSize sizePoint = m_obWinSizeInPoints;

    switch (kProjection)
    {
    case kCCDirectorProjection2D:
       {
           kmGLMatrixMode(KM_GL_PROJECTION);
           kmGLLoadIdentity();
           // y flip
           kmGLScalef(1.0f, -1.0f, 1.0f);

           kmMat4 orthoMatrix;
           kmMat4OrthographicProjection(&orthoMatrix, 0, size.width / CC_CONTENT_SCALE_FACTOR(), 0, size.height / CC_CONTENT_SCALE_FACTOR(), -1024, 1024);
           kmGLMultMatrix(&orthoMatrix);

           kmGLMatrixMode(KM_GL_MODELVIEW);
           kmGLLoadIdentity();
       }
       break;

    case kCCDirectorProjection3D:
       {
           float zeye = this->getZEye();

           kmMat4 matrixPerspective, matrixLookup;

           kmGLMatrixMode(KM_GL_PROJECTION);
           kmGLLoadIdentity();

           // issue #1334
           kmMat4PerspectiveProjection(&matrixPerspective, 60, (GLfloat)size.width / size.height, 0.1f, zeye * 2);
           // kmMat4PerspectiveProjection( &matrixPerspective, 60, (GLfloat)size.width/size.height, 0.1f, 1500);

           kmGLMultMatrix(&matrixPerspective);

           kmGLMatrixMode(KM_GL_MODELVIEW);
           kmGLLoadIdentity();
           kmVec3 eye, center, up;
           kmVec3Fill(&eye, sizePoint.width / 2, sizePoint.height / 2, zeye);
           kmVec3Fill(&center, sizePoint.width / 2, sizePoint.height / 2, 0.0f);
           kmVec3Fill(&up, 0.0f, 1.0f, 0.0f);
           kmMat4LookAt(&matrixLookup, &eye, &center, &up);
           kmGLMultMatrix(&matrixLookup);
       }
       break;

    case kCCDirectorProjectionCustom:
        if (m_pProjectionDelegate)
        {
            m_pProjectionDelegate->updateProjection();
        }
        break;

    default:
        CCLOG("cocos2d: Director: unrecognized projection");
        break;
    }

    m_eProjection = kProjection;
}


void CCDirector::purgeCachedData(void)
{
    CCFileUtils::sharedFileUtils()->purgeCachedEntries();
}


float CCDirector::getZEye(void)
{
    return(m_obWinSizeInPixels.height / 1.1566f / CC_CONTENT_SCALE_FACTOR());
}


void CCDirector::setAlphaBlending(bool bOn)
{
}


void CCDirector::setDepthTest(bool bOn)
{
}


CCPoint CCDirector::convertToGL(const CCPoint& uiPoint)
{
    CCSize s    = m_obWinSizeInPoints;
    float  newY = s.height - uiPoint.y;

    return ccp(uiPoint.x, newY);
}


CCPoint CCDirector::convertToUI(const CCPoint& glPoint)
{
    CCSize winSize   = m_obWinSizeInPoints;
    float  oppositeY = winSize.height - glPoint.y;

    return ccp(glPoint.x, oppositeY);
}


CCSize CCDirector::getWinSize(void)
{
    return m_obWinSizeInPoints;
}


CCSize CCDirector::getWinSizeInPixels()
{
    return m_obWinSizeInPixels;
}


void CCDirector::reshapeProjection(const CCSize& newWindowSize)
{
    CC_UNUSED_PARAM(newWindowSize);
    if (m_pobOpenGLView)
    {
        m_obWinSizeInPoints = m_pobOpenGLView->getSize();
        m_obWinSizeInPixels = CCSizeMake(m_obWinSizeInPoints.width * m_fContentScaleFactor,
                                         m_obWinSizeInPoints.height * m_fContentScaleFactor);

        setProjection(m_eProjection);
    }

    // Update the display size.
    CCLoomCocos2d::setDisplaySize((int)m_obWinSizeInPixels.width, (int)m_obWinSizeInPixels.height);
}


// scene management

void CCDirector::runWithScene(CCScene *pScene)
{
    CCAssert(pScene != NULL, "running scene should not be null");
    CCAssert(m_pRunningScene == NULL, "m_pRunningScene should be null");

    pushScene(pScene);
    startAnimation();
}


void CCDirector::replaceScene(CCScene *pScene)
{
    CCAssert(pScene != NULL, "the scene should not be null");

    unsigned int index = m_pobScenesStack->count();

    m_bSendCleanupToScene = true;
    m_pobScenesStack->replaceObjectAtIndex(index - 1, pScene);

    m_pNextScene = pScene;
}


void CCDirector::pushScene(CCScene *pScene)
{
    CCAssert(pScene, "the scene should not null");

    m_bSendCleanupToScene = false;

    m_pobScenesStack->addObject(pScene);
    m_pNextScene = pScene;
}


void CCDirector::popScene(void)
{
    CCAssert(m_pRunningScene != NULL, "running scene should not null");

    m_pobScenesStack->removeLastObject();
    unsigned int c = m_pobScenesStack->count();

    if (c == 0)
    {
        end();
    }
    else
    {
        m_bSendCleanupToScene = true;
        m_pNextScene          = (CCScene *)m_pobScenesStack->objectAtIndex(c - 1);
    }
}


void CCDirector::popToRootScene(void)
{
    CCAssert(m_pRunningScene != NULL, "A running Scene is needed");
    unsigned int c = m_pobScenesStack->count();

    if (c == 1)
    {
        m_pobScenesStack->removeLastObject();
        this->end();
    }
    else
    {
        while (c > 1)
        {
            CCScene *current = (CCScene *)m_pobScenesStack->lastObject();
            if (current->isRunning())
            {
                current->onExit();
            }
            current->cleanup();

            m_pobScenesStack->removeLastObject();
            c--;
        }
        m_pNextScene          = (CCScene *)m_pobScenesStack->lastObject();
        m_bSendCleanupToScene = false;
    }
}


void CCDirector::end()
{
    m_bPurgeDirectorInNextLoop = true;
}


void CCDirector::purgeDirector()
{
    // don't release the event handlers
    // They are needed in case the director is run again
    m_pTouchDispatcher->removeAllDelegates();

    if (m_pRunningScene)
    {
        m_pRunningScene->onExit();
        m_pRunningScene->cleanup();
        m_pRunningScene->release();
    }

    m_pRunningScene = NULL;
    m_pNextScene    = NULL;

    // remove all objects, but don't release it.
    // runWithScene might be executed after 'end'.
    m_pobScenesStack->removeAllObjects();

    stopAnimation();

    CCObject *pProjectionDelegate = (CCObject *)m_pProjectionDelegate;
    CC_SAFE_RELEASE_NULL(pProjectionDelegate);

    // purge all managed caches
    CCFileUtils::purgeFileUtils();
    CCConfiguration::purgeConfiguration();

    // cocos2d-x specific data structures
    CCUserDefault::purgeSharedUserDefault();
    CCNotificationCenter::purgeNotificationCenter();


    // OpenGL view
    m_pobOpenGLView->end();
    m_pobOpenGLView = NULL;
}


void CCDirector::setNextScene(void)
{
    if (m_pRunningScene)
    {
        m_pRunningScene->onExit();
    }

    // issue #709. the root node (scene) should receive the cleanup message too
    // otherwise it might be leaked.
    if (m_bSendCleanupToScene && m_pRunningScene)
    {
        m_pRunningScene->cleanup();
    }

    if (m_pRunningScene)
    {
        m_pRunningScene->release();
    }

    m_pRunningScene = m_pNextScene;
    m_pNextScene->retain();
    m_pNextScene = NULL;

    if (m_pRunningScene)
    {
        m_pRunningScene->onEnter();
        m_pRunningScene->onEnterTransitionDidFinish();
    }
}


CCScene *CCDirector::getNextScene()
{
    return m_pNextScene;
}


void CCDirector::pause(void)
{
    if (m_bPaused)
    {
        return;
    }

    m_dOldAnimationInterval = m_dAnimationInterval;

    // when paused, don't consume CPU
    setAnimationInterval(1 / 4.0);
    m_bPaused = true;
}


void CCDirector::resume(void)
{
    if (!m_bPaused)
    {
        return;
    }

    setAnimationInterval(m_dOldAnimationInterval);

    if (CCTime::gettimeofdayCocos2d(m_pLastUpdate, NULL) != 0)
    {
        CCLOG("cocos2d: Director: Error in gettimeofday");
    }

    m_bPaused    = false;
    m_fDeltaTime = 0;
}


// display the FPS using a LabelAtlas
// updates the FPS every frame
void CCDirector::showStats(void)
{
    m_uFrames++;
    m_fAccumDt += m_fDeltaTime;

    g_uNumberOfDraws = 0;
}


void CCDirector::calculateMPF()
{
    struct cc_timeval now;
    CCTime::gettimeofdayCocos2d(&now, NULL);

    m_fSecondsPerFrame = (now.tv_sec - m_pLastUpdate->tv_sec) + (now.tv_usec - m_pLastUpdate->tv_usec) / 1000000.0f;
}


/***************************************************
 * mobile platforms specific functions
 **************************************************/
void CCDirector::updateContentScaleFactor()
{
    // [openGLView responseToSelector:@selector(setContentScaleFactor)]
    if (m_pobOpenGLView->canSetContentScaleFactor())
    {
        m_pobOpenGLView->setContentScaleFactor(m_fContentScaleFactor);
        m_bIsContentScaleSupported = true;
    }
    else
    {
        CCLOG("cocos2d: setContentScaleFactor:'is not supported on this device");
    }
}


bool CCDirector::enableRetinaDisplay(bool enabled)
{
    // Already enabled?
    if (enabled && (m_fContentScaleFactor == 2))
    {
        return true;
    }

    // Already diabled?
    if (!enabled && (m_fContentScaleFactor == 1))
    {
        return false;
    }

    // setContentScaleFactor is not supported
    if (!m_pobOpenGLView->canSetContentScaleFactor())
    {
        return false;
    }

    // SD device
    if (m_pobOpenGLView->getMainScreenScale() == 1.0)
    {
        return false;
    }

    float newScale = (float)(enabled ? 2 : 1);
    setContentScaleFactor(newScale);

    return true;
}


float CCDirector::getContentScaleFactor(void)
{
    return m_fContentScaleFactor;
}


void CCDirector::setContentScaleFactor(float scaleFactor)
{
    if (scaleFactor != m_fContentScaleFactor)
    {
        m_fContentScaleFactor = scaleFactor;
        m_obWinSizeInPixels   = CCSizeMake(m_obWinSizeInPoints.width * scaleFactor, m_obWinSizeInPoints.height * scaleFactor);

        if (m_pobOpenGLView)
        {
            updateContentScaleFactor();
        }

        // update projection
        setProjection(m_eProjection);
    }
}


CCNode *CCDirector::getNotificationNode()
{
    return m_pNotificationNode;
}


void CCDirector::setNotificationNode(CCNode *node)
{
    CC_SAFE_RELEASE(m_pNotificationNode);
    m_pNotificationNode = node;
    CC_SAFE_RETAIN(m_pNotificationNode);
}


void CCDirector::setScheduler(CCScheduler *pScheduler)
{
    if (m_pScheduler != pScheduler)
    {
        CC_SAFE_RETAIN(pScheduler);
        CC_SAFE_RELEASE(m_pScheduler);
        m_pScheduler = pScheduler;
    }
}


CCScheduler *CCDirector::getScheduler()
{
    return m_pScheduler;
}


void CCDirector::setTouchDispatcher(CCTouchDispatcher *pTouchDispatcher)
{
    if (m_pTouchDispatcher != pTouchDispatcher)
    {
        CC_SAFE_RETAIN(pTouchDispatcher);
        CC_SAFE_RELEASE(m_pTouchDispatcher);
        m_pTouchDispatcher = pTouchDispatcher;
    }
}


CCTouchDispatcher *CCDirector::getTouchDispatcher()
{
    return m_pTouchDispatcher;
}


void CCDirector::setKeypadDispatcher(CCKeypadDispatcher *pKeypadDispatcher)
{
    CC_SAFE_RETAIN(pKeypadDispatcher);
    CC_SAFE_RELEASE(m_pKeypadDispatcher);
    m_pKeypadDispatcher = pKeypadDispatcher;
}


CCKeypadDispatcher *CCDirector::getKeypadDispatcher()
{
    return m_pKeypadDispatcher;
}


void CCDirector::setAccelerometer(CCAccelerometer *pAccelerometer)
{
    if (m_pAccelerometer != pAccelerometer)
    {
        CC_SAFE_DELETE(m_pAccelerometer);
        m_pAccelerometer = pAccelerometer;
    }
}


CCAccelerometer *CCDirector::getAccelerometer()
{
    return m_pAccelerometer;
}


// ScrollWheel

void CCDirector::setScrollWheelDispatcher(CCScrollWheelDispatcher *pScrollWheelDispatcher)
{
    CC_SAFE_RETAIN(pScrollWheelDispatcher);
    CC_SAFE_RELEASE(m_pScrollWheelDispatcher);
    m_pScrollWheelDispatcher = pScrollWheelDispatcher;
}


CCScrollWheelDispatcher *CCDirector::getScrollWheelDispatcher()
{
    return m_pScrollWheelDispatcher;
}


/***************************************************
 * implementation of DisplayLinkDirector
 **************************************************/

// should we afford 4 types of director ??
// I think DisplayLinkDirector is enough
// so we now only support DisplayLinkDirector
void CCDisplayLinkDirector::startAnimation(void)
{
    if (CCTime::gettimeofdayCocos2d(m_pLastUpdate, NULL) != 0)
    {
        CCLOG("cocos2d: DisplayLinkDirector: Error on gettimeofday");
    }

    m_bInvalid = false;
    CCApplication::sharedApplication().setAnimationInterval(m_dAnimationInterval);
}


extern "C" void loom_tick();

void CCDisplayLinkDirector::mainLoop(void)
{
    // Run tasks.
    loom_tick();

    // We need to apply the accelerometer data here and not
    // when we receive it from JNI as this appears
    // to be on another thread and when we apply
    // there may be script delegates listening
#ifdef ANDROID_NDK
    m_pAccelerometer->apply();
#endif

    if (m_bPurgeDirectorInNextLoop)
    {
        m_bPurgeDirectorInNextLoop = false;
        purgeDirector();
    }
    else if (!m_bInvalid)
    {
        profilerBlock_t p = { "drawScene", platform_getMilliseconds(), 16 };
        drawScene();
        finishProfilerBlock(&p);

        // release the objects
        CCPoolManager::sharedPoolManager()->pop();
    }
}


void CCDisplayLinkDirector::stopAnimation(void)
{
    m_bInvalid = true;
}


void CCDisplayLinkDirector::setAnimationInterval(double dValue)
{
    m_dAnimationInterval = dValue;
    if (!m_bInvalid)
    {
        stopAnimation();
        startAnimation();
    }
}


void CCDirector::setWatcherCallbackFun(void *pSender, WatcherCallbackFun fun)
{
    m_pWatcherFun    = fun;
    m_pWatcherSender = pSender;
}


NS_CC_END
