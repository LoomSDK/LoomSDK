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

#ifndef __CCLAYER_H__
#define __CCLAYER_H__

#include "base_nodes/CCNode.h"
#include "CCProtocols.h"
#include "touch_dispatcher/CCTouchDelegateProtocol.h"
#include "platform/CCAccelerometerDelegate.h"
#include "keypad_dispatcher/CCKeypadDelegate.h"
#include "cocoa/CCArray.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "scrollwheel_dispatcher/CCScrollWheelDelegate.h"

NS_CC_BEGIN

/**
 * @addtogroup layer
 * @{
 */

class CCTouchScriptHandlerEntry;

//
// CCLayer
//

/** @brief CCLayer is a subclass of CCNode that implements the TouchEventsDelegate protocol.
 *
 * All features from CCNode are valid, plus the following new features:
 * - It can receive iPhone Touches
 * - It can receive Accelerometer input
 */
class CC_DLL CCLayer : public CCNode, public CCTouchDelegate, public CCAccelerometerDelegate, public CCKeypadDelegate, public CCScrollWheelDelegate
{
public:
    CCLayer();
    virtual ~CCLayer();
    bool init();

    // @deprecated: This interface will be deprecated sooner or later.
    CC_DEPRECATED_ATTRIBUTE static CCLayer *node(void);

    /** create one layer */
    static CCLayer *create(void);

    virtual void onEnter();
    virtual void onExit();
    virtual void onEnterTransitionDidFinish();

    // default implements are used to call script callback if exist
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent);

    // LoomScript delegates.
    LOOM_DELEGATE(TouchBegan);
    LOOM_DELEGATE(TouchMoved);
    LOOM_DELEGATE(TouchEnded);
    LOOM_DELEGATE(TouchCancelled);
    LOOM_DELEGATE(KeyBackClicked);
    LOOM_DELEGATE(KeyMenuClicked);
    LOOM_DELEGATE(KeyUp);
    LOOM_DELEGATE(KeyDown);
    LOOM_DELEGATE(ScrollWheelYMoved);
    LOOM_DELEGATE(DidAccelerate);

    // Keypad Delegate implements
    virtual void keyBackClicked();
    virtual void keyMenuClicked();
    virtual void keyUp(int keycode);
    virtual void keyDown(int keycode);

    // ScrollWheel Delegate implements
    virtual void scrollWheelYMoved(float delta);

    // default implements are used to call script callback if exist
    virtual void ccTouchesBegan(CCSet *pTouches, CCEvent *pEvent);
    virtual void ccTouchesMoved(CCSet *pTouches, CCEvent *pEvent);
    virtual void ccTouchesEnded(CCSet *pTouches, CCEvent *pEvent);
    virtual void ccTouchesCancelled(CCSet *pTouches, CCEvent *pEvent);

    virtual void didAccelerate(CCAcceleration *pAccelerationValue);

    /** If isTouchEnabled, this method is called onEnter. Override it to change the
     * way CCLayer receives touch events.
     * ( Default: CCTouchDispatcher::sharedDispatcher()->addStandardDelegate(this,0); )
     * Example:
     * void CCLayer::registerWithTouchDispatcher()
     * {
     * CCTouchDispatcher::sharedDispatcher()->addTargetedDelegate(this,INT_MIN+1,true);
     * }
     * @since v0.8.0
     */
    virtual void registerWithTouchDispatcher(void);

    /** Register script touch events handler */
    void registerScriptTouchHandler(int nHandler, bool bIsMultiTouches = false, int nPriority = INT_MIN, bool bSwallowsTouches = false);

    /** Unregister script touch events handler */
    void unregisterScriptTouchHandler(void);

    /** whether or not it will receive Touch events.
     * You can enable / disable touch events with this property.
     * Only the touches of this node will be affected. This "method" is not propagated to it's children.
     * @since v0.8.1
     */
    bool isTouchEnabled();
    void setTouchEnabled(bool value);

    /** whether or not it will receive Accelerometer events
     * You can enable / disable accelerometer events with this property.
     * @since v0.8.1
     */
    bool isAccelerometerEnabled();
    void setAccelerometerEnabled(bool value);

    /** whether or not it will receive keypad events
     * You can enable / disable accelerometer events with this property.
     * it's new in cocos2d-x
     */
    bool isKeypadEnabled();
    void setKeypadEnabled(bool value);

    /** whether or not it will receive mousewheel events.
     */
    bool isScrollWheelEnabled();
    void setScrollWheelEnabled(bool value);

protected:
    bool m_bIsTouchEnabled;
    bool m_bIsAccelerometerEnabled;
    bool m_bIsKeypadEnabled;
    bool m_bIsScrollWheelEnabled;

private:
    // Script touch events handler
    CCTouchScriptHandlerEntry *m_pScriptHandlerEntry;
    int excuteScriptTouchHandler(int nEventType, CCTouch *pTouch);
    int excuteScriptTouchHandler(int nEventType, CCSet *pTouches);
};

// for the subclass of CCLayer, each has to implement the static "node" method
// @deprecated: This interface will be deprecated sooner or later.
#define LAYER_NODE_FUNC(layer)                    \
    CC_DEPRECATED_ATTRIBUTE static layer * node() \
    {                                             \
        layer *pRet = new layer();                \
        if (pRet && pRet->init())                 \
        {                                         \
            pRet->autorelease();                  \
            return pRet;                          \
        }                                         \
        else                                      \
        {                                         \
            delete pRet;                          \
            pRet = NULL;                          \
            return NULL;                          \
        }                                         \
    }


// for the subclass of CCLayer, each has to implement the static "create" method
#define LAYER_CREATE_FUNC(layer)   \
    static layer * create()        \
    {                              \
        layer *pRet = new layer(); \
        if (pRet && pRet->init())  \
        {                          \
            pRet->autorelease();   \
            return pRet;           \
        }                          \
        else                       \
        {                          \
            delete pRet;           \
            pRet = NULL;           \
            return NULL;           \
        }                          \
    }

// @deprecated: This interface will be deprecated sooner or later.
#define LAYER_NODE_FUNC_PARAM(layer, __PARAMTYPE__, __PARAM__)           \
    CC_DEPRECATED_ATTRIBUTE static layer * node(__PARAMTYPE__ __PARAM__) \
    {                                                                    \
        layer *pRet = new layer();                                       \
        if (pRet && pRet->init(__PARAM__))                               \
        {                                                                \
            pRet->autorelease();                                         \
            return pRet;                                                 \
        }                                                                \
        else                                                             \
        {                                                                \
            delete pRet;                                                 \
            pRet = NULL;                                                 \
            return NULL;                                                 \
        }                                                                \
    }


#define LAYER_CREATE_FUNC_PARAM(layer, __PARAMTYPE__, __PARAM__) \
    static layer * create(__PARAMTYPE__ __PARAM__)               \
    {                                                            \
        layer *pRet = new layer();                               \
        if (pRet && pRet->init(__PARAM__))                       \
        {                                                        \
            pRet->autorelease();                                 \
            return pRet;                                         \
        }                                                        \
        else                                                     \
        {                                                        \
            delete pRet;                                         \
            pRet = NULL;                                         \
            return NULL;                                         \
        }                                                        \
    }

// end of layer group
/// @}

NS_CC_END
#endif // __CCLAYER_H__
