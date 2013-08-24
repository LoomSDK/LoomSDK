/****************************************************************************
*  Copyright (c) 2012 Spotkin, LLC
****************************************************************************/

#include "CCScrollWheelDelegate.h"
#include "ccMacros.h"

NS_CC_BEGIN

//------------------------------------------------------------------
//
// CCScrollWheelHandler
//
//------------------------------------------------------------------
CCScrollWheelDelegate *CCScrollWheelHandler::getDelegate()
{
    return m_pDelegate;
}


CCScrollWheelHandler::~CCScrollWheelHandler()
{
    if (m_pDelegate)
    {
        dynamic_cast<CCObject *>(m_pDelegate)->release();
    }
}


void CCScrollWheelHandler::setDelegate(CCScrollWheelDelegate *pDelegate)
{
    if (pDelegate)
    {
        dynamic_cast<CCObject *>(pDelegate)->retain();
    }

    if (m_pDelegate)
    {
        dynamic_cast<CCObject *>(m_pDelegate)->release();
    }
    m_pDelegate = pDelegate;
}


bool CCScrollWheelHandler::initWithDelegate(CCScrollWheelDelegate *pDelegate)
{
    CCAssert(pDelegate != NULL, "It's a wrong delegate!");

    m_pDelegate = pDelegate;
    dynamic_cast<CCObject *>(pDelegate)->retain();

    return true;
}


CCScrollWheelHandler *CCScrollWheelHandler::handlerWithDelegate(CCScrollWheelDelegate *pDelegate)
{
    CCScrollWheelHandler *pHandler = new CCScrollWheelHandler;

    if (pHandler)
    {
        if (pHandler->initWithDelegate(pDelegate))
        {
            pHandler->autorelease();
        }
        else
        {
            CC_SAFE_RELEASE_NULL(pHandler);
        }
    }

    return pHandler;
}


NS_CC_END
