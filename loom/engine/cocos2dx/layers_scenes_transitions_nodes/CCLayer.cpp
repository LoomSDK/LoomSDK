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

#include <stdarg.h>
#include "CCLayer.h"
#include "touch_dispatcher/CCTouchDispatcher.h"
#include "keypad_dispatcher/CCKeypadDispatcher.h"
#include "scrollwheel_dispatcher/CCScrollWheelDispatcher.h"
#include "CCAccelerometer.h"
#include "CCDirector.h"
#include "support/CCPointExtension.h"
#include "support/TransformUtils.h"
#include "cocoa/CCGeometry.h"

// extern
#include "kazmath/GL/matrix.h"

cocos2d::CCLayer *pLayer = NULL;

cocos2d::CCLayer *getRootLayer()
{
    return pLayer;
}


NS_CC_BEGIN

// CCLayer
CCLayer::CCLayer()
    : m_bIsTouchEnabled(false)
      , m_bIsAccelerometerEnabled(false)
      , m_bIsKeypadEnabled(false)
      , m_bIsScrollWheelEnabled(false)
      , m_pScriptHandlerEntry(NULL)
{
    setAnchorPoint(ccp(0.5f, 0.5f));
    m_bIgnoreAnchorPointForPosition = true;
}


CCLayer::~CCLayer()
{
    unregisterScriptTouchHandler();
}


bool CCLayer::init()
{
    bool bRet = false;

    do
    {
        CCDirector *pDirector;
        CC_BREAK_IF(!(pDirector = CCDirector::sharedDirector()));
        this->setContentSize(pDirector->getWinSize());
        m_bIsTouchEnabled         = false;
        m_bIsAccelerometerEnabled = false;
        // success
        bRet = true;
    } while (0);
    return bRet;
}


CCLayer *CCLayer::node()
{
    return CCLayer::create();
}


CCLayer *CCLayer::create()
{
    CCLayer *pRet = new CCLayer();

    if (pRet && pRet->init())
    {
        pRet->autorelease();
        return pRet;
    }
    else
    {
        CC_SAFE_DELETE(pRet);
        return NULL;
    }
}


/// Touch and Accelerometer related

void CCLayer::registerWithTouchDispatcher()
{
    CCDirector *pDirector = CCDirector::sharedDirector();

    pDirector->getTouchDispatcher()->addStandardDelegate(this, 0);
}


void CCLayer::registerScriptTouchHandler(int nHandler, bool bIsMultiTouches, int nPriority, bool bSwallowsTouches)
{
}


void CCLayer::unregisterScriptTouchHandler(void)
{
}


int CCLayer::excuteScriptTouchHandler(int nEventType, CCTouch *pTouch)
{
    return 0;
}


int CCLayer::excuteScriptTouchHandler(int nEventType, CCSet *pTouches)
{
    return 0;
}


/// isTouchEnabled getter
bool CCLayer::isTouchEnabled()
{
    return m_bIsTouchEnabled;
}


/// isTouchEnabled setter
void CCLayer::setTouchEnabled(bool enabled)
{
    if (m_bIsTouchEnabled != enabled)
    {
        m_bIsTouchEnabled = enabled;
        if (m_bIsRunning)
        {
            if (enabled)
            {
                this->registerWithTouchDispatcher();
            }
            else
            {
                // have problems?
                CCDirector *pDirector = CCDirector::sharedDirector();
                pDirector->getTouchDispatcher()->removeDelegate(this);
            }
        }
    }
}


/// isAccelerometerEnabled getter
bool CCLayer::isAccelerometerEnabled()
{
    return m_bIsAccelerometerEnabled;
}


/// isAccelerometerEnabled setter
void CCLayer::setAccelerometerEnabled(bool enabled)
{
    if (enabled != m_bIsAccelerometerEnabled)
    {
        m_bIsAccelerometerEnabled = enabled;

        if (m_bIsRunning)
        {
            CCDirector *pDirector = CCDirector::sharedDirector();
            if (enabled)
            {
                pDirector->getAccelerometer()->setDelegate(this);
            }
            else
            {
                pDirector->getAccelerometer()->setDelegate(NULL);
            }
        }
    }
}


void CCLayer::didAccelerate(CCAcceleration *pAccelerationValue)
{
    _DidAccelerateDelegate.allowAsync();
    _DidAccelerateDelegate.pushArgument(pAccelerationValue->x);
    _DidAccelerateDelegate.pushArgument(pAccelerationValue->y);
    _DidAccelerateDelegate.pushArgument(pAccelerationValue->z);
    _DidAccelerateDelegate.invoke();
}


/// keypad related logic
void CCLayer::keyBackClicked()
{
    _KeyBackClickedDelegate.invoke();
}


void CCLayer::keyMenuClicked()
{
    _KeyMenuClickedDelegate.invoke();
}


void CCLayer::keyDown(int keycode)
{
    _KeyDownDelegate.pushArgument(keycode);
    _KeyDownDelegate.invoke();
}


void CCLayer::keyUp(int keycode)
{
    _KeyUpDelegate.pushArgument(keycode);
    _KeyUpDelegate.invoke();
}


/// isKeypadEnabled getter
bool CCLayer::isKeypadEnabled()
{
    return m_bIsKeypadEnabled;
}


/// isKeypadEnabled setter
void CCLayer::setKeypadEnabled(bool enabled)
{
    if (enabled != m_bIsKeypadEnabled)
    {
        m_bIsKeypadEnabled = enabled;

        if (m_bIsRunning)
        {
            CCDirector *pDirector = CCDirector::sharedDirector();
            if (enabled)
            {
                pDirector->getKeypadDispatcher()->addDelegate(this);
            }
            else
            {
                pDirector->getKeypadDispatcher()->removeDelegate(this);
            }
        }
    }
}


/// scrollwheel related logic
void CCLayer::scrollWheelYMoved(float delta)
{
    _ScrollWheelYMovedDelegate.pushArgument(delta);
    _ScrollWheelYMovedDelegate.invoke();
}


/// isScrollWheelEnabled getter
bool CCLayer::isScrollWheelEnabled()
{
    return m_bIsScrollWheelEnabled;
}


/// isScrollWheelEnabled setter
void CCLayer::setScrollWheelEnabled(bool enabled)
{
    if (enabled != m_bIsScrollWheelEnabled)
    {
        m_bIsScrollWheelEnabled = enabled;

        if (m_bIsRunning)
        {
            CCDirector *pDirector = CCDirector::sharedDirector();
            if (enabled)
            {
                pDirector->getScrollWheelDispatcher()->addDelegate(this);
            }
            else
            {
                pDirector->getScrollWheelDispatcher()->removeDelegate(this);
            }
        }
    }
}


/// Callbacks
void CCLayer::onEnter()
{
    CCDirector *pDirector = CCDirector::sharedDirector();

    // register 'parent' nodes first
    // since events are propagated in reverse order
    if (m_bIsTouchEnabled)
    {
        this->registerWithTouchDispatcher();
    }

    // then iterate over all the children
    CCNode::onEnter();

    // add this layer to concern the Accelerometer Sensor
    if (m_bIsAccelerometerEnabled)
    {
        pDirector->getAccelerometer()->setDelegate(this);
    }

    // add this layer to concern the kaypad msg
    if (m_bIsKeypadEnabled)
    {
        pDirector->getKeypadDispatcher()->addDelegate(this);
    }

    if (m_bIsScrollWheelEnabled)
    {
        pDirector->getScrollWheelDispatcher()->addDelegate(this);
    }
}


void CCLayer::onExit()
{
    CCDirector *pDirector = CCDirector::sharedDirector();

    if (m_bIsTouchEnabled)
    {
        pDirector->getTouchDispatcher()->removeDelegate(this);
        unregisterScriptTouchHandler();
    }

    // remove this layer from the delegates who concern Accelerometer Sensor
    if (m_bIsAccelerometerEnabled)
    {
        pDirector->getAccelerometer()->setDelegate(NULL);
    }

    // remove this layer from the delegates who concern the kaypad msg
    if (m_bIsKeypadEnabled)
    {
        pDirector->getKeypadDispatcher()->removeDelegate(this);
    }

    CCNode::onExit();
}


void CCLayer::onEnterTransitionDidFinish()
{
    if (m_bIsAccelerometerEnabled)
    {
        CCDirector *pDirector = CCDirector::sharedDirector();
        pDirector->getAccelerometer()->setDelegate(this);
    }

    CCNode::onEnterTransitionDidFinish();
}


bool CCLayer::ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent)
{
    if (_TouchBeganDelegate.getVM())
    {
        CCPoint localPoint = convertToNodeSpace(pTouch->getLocation());

        _TouchBeganDelegate.pushArgument(pTouch->getID());
        _TouchBeganDelegate.pushArgument(localPoint.x);
        _TouchBeganDelegate.pushArgument(localPoint.y);
        _TouchBeganDelegate.invoke();
        return true;
    }

    if (m_pScriptHandlerEntry)
    {
        return excuteScriptTouchHandler(CCTOUCHBEGAN, pTouch) == 0 ? false : true;
    }
    CC_UNUSED_PARAM(pTouch);
    CC_UNUSED_PARAM(pEvent);
//    CCAssert(false, "Layer#ccTouchBegan override me");
    return true;
}


void CCLayer::ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent)
{
    // Invoke the delegate with our status.
    CCPoint localPoint = convertToNodeSpace(pTouch->getLocation());

    _TouchMovedDelegate.pushArgument(pTouch->getID());
    _TouchMovedDelegate.pushArgument(localPoint.x);
    _TouchMovedDelegate.pushArgument(localPoint.y);
    _TouchMovedDelegate.invoke();

    if (m_pScriptHandlerEntry)
    {
        excuteScriptTouchHandler(CCTOUCHMOVED, pTouch);
        return;
    }
    CC_UNUSED_PARAM(pTouch);
    CC_UNUSED_PARAM(pEvent);
}


void CCLayer::ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent)
{
    // Invoke the delegate with our status.
    CCPoint localPoint = convertToNodeSpace(pTouch->getLocation());

    _TouchEndedDelegate.pushArgument(pTouch->getID());
    _TouchEndedDelegate.pushArgument(localPoint.x);
    _TouchEndedDelegate.pushArgument(localPoint.y);
    _TouchEndedDelegate.invoke();

    if (m_pScriptHandlerEntry)
    {
        excuteScriptTouchHandler(CCTOUCHENDED, pTouch);
        return;
    }
    CC_UNUSED_PARAM(pTouch);
    CC_UNUSED_PARAM(pEvent);
}


void CCLayer::ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent)
{
    CCPoint localPoint = convertToNodeSpace(pTouch->getLocation());

    _TouchCancelledDelegate.pushArgument(pTouch->getID());
    _TouchCancelledDelegate.pushArgument(localPoint.x);
    _TouchCancelledDelegate.pushArgument(localPoint.y);
    _TouchCancelledDelegate.invoke();

    if (m_pScriptHandlerEntry)
    {
        excuteScriptTouchHandler(CCTOUCHCANCELLED, pTouch);
        return;
    }
    CC_UNUSED_PARAM(pTouch);
    CC_UNUSED_PARAM(pEvent);
}


void CCLayer::ccTouchesBegan(CCSet *pTouches, CCEvent *pEvent)
{
    if (m_pScriptHandlerEntry)
    {
        excuteScriptTouchHandler(CCTOUCHBEGAN, pTouches);
        return;
    }
    CC_UNUSED_PARAM(pTouches);
    CC_UNUSED_PARAM(pEvent);
}


void CCLayer::ccTouchesMoved(CCSet *pTouches, CCEvent *pEvent)
{
    if (m_pScriptHandlerEntry)
    {
        excuteScriptTouchHandler(CCTOUCHMOVED, pTouches);
        return;
    }
    CC_UNUSED_PARAM(pTouches);
    CC_UNUSED_PARAM(pEvent);
}


void CCLayer::ccTouchesEnded(CCSet *pTouches, CCEvent *pEvent)
{
    if (m_pScriptHandlerEntry)
    {
        excuteScriptTouchHandler(CCTOUCHENDED, pTouches);
        return;
    }
    CC_UNUSED_PARAM(pTouches);
    CC_UNUSED_PARAM(pEvent);
}


void CCLayer::ccTouchesCancelled(CCSet *pTouches, CCEvent *pEvent)
{
    if (m_pScriptHandlerEntry)
    {
        excuteScriptTouchHandler(CCTOUCHCANCELLED, pTouches);
        return;
    }
    CC_UNUSED_PARAM(pTouches);
    CC_UNUSED_PARAM(pEvent);
}


NS_CC_END
