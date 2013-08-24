/****************************************************************************
*  Copyright (c) 2012 Spotkin, LLC
****************************************************************************/

#ifndef __CCSCROLLWHEEL_DELEGATE_H__
#define __CCSCROLLWHEEL_DELEGATE_H__

#include "cocoa/CCObject.h"

NS_CC_BEGIN

class CC_DLL CCScrollWheelDelegate
{
public:
    // Scroll Wheel Y
    virtual void scrollWheelYMoved(float delta) {}
};

/**
 * @brief
 * CCKeypadHandler
 * Wrapper for Delegates so we can store them in CCArrays
 */
class CC_DLL CCScrollWheelHandler : public CCObject
{
public:
    virtual ~CCScrollWheelHandler(void);

    /** delegate */
    CCScrollWheelDelegate *getDelegate();
    void setDelegate(CCScrollWheelDelegate *pDelegate);

    /** initializes a CCKeypadHandler with a delegate */
    virtual bool initWithDelegate(CCScrollWheelDelegate *pDelegate);

public:
    /** allocates a CCKeypadHandler with a delegate */
    static CCScrollWheelHandler *handlerWithDelegate(CCScrollWheelDelegate *pDelegate);

protected:
    CCScrollWheelDelegate *m_pDelegate;
};

NS_CC_END
#endif // __CCKEYPAD_DELEGATE_H__
