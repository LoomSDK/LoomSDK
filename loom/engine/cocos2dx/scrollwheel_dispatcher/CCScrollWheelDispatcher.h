/****************************************************************************
*  Copyright (c) 2012 Spotkin, LLC
****************************************************************************/

#ifndef __CCSCROLLWHEEL_DISPATCHER_H__
#define __CCSCROLLWHEEL_DISPATCHER_H__

#include "CCScrollWheelDelegate.h"
#include "cocoa/CCArray.h"

NS_CC_BEGIN

struct _ccCArray;

/**
 * @class CCScrollWheelDispatcher
 * @brief Dispatch the scrollwheel message
 */
class CC_DLL CCScrollWheelDispatcher : public CCObject
{
public:
    CCScrollWheelDispatcher();
    ~CCScrollWheelDispatcher();

    /**
     * @brief add delegate
     * void addDelegate(CCScrollWheelDelegate* pDelegate);
     */
    void addDelegate(CCScrollWheelDelegate *pDelegate);

    /**
     * @brief remove the delegate
     */
    void removeDelegate(CCScrollWheelDelegate *pDelegate);

    /**
     * @brief force add the delegate
     */
    void forceAddDelegate(CCScrollWheelDelegate *pDelegate);

    /**
     * @brief force remove the delegate
     */
    void forceRemoveDelegate(CCScrollWheelDelegate *pDelegate);

    /**
     * @brief dispatch the key pad msg
     */
    bool dispatchScrollWheelDeltaY(float dy);

protected:

    CCArray *m_pDelegates;
    bool    m_bLocked;
    bool    m_bToAdd;
    bool    m_bToRemove;

    struct _ccCArray *m_pDelegatesToAdd;
    struct _ccCArray *m_pDelegatesToRemove;
};

// end of input group
/// @}

NS_CC_END
#endif
