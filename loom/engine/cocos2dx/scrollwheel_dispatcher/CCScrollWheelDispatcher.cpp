/****************************************************************************
*  Copyright (c) 2012 Spotkin, LLC
****************************************************************************/

#include "CCScrollWheelDispatcher.h"
#include "support/data_support/ccCArray.h"

NS_CC_BEGIN

//------------------------------------------------------------------
//
// CCScrollWheelDispatcher
//
//------------------------------------------------------------------
CCScrollWheelDispatcher::CCScrollWheelDispatcher()
    : m_bLocked(false)
      , m_bToAdd(false)
      , m_bToRemove(false)
{
    m_pDelegates = CCArray::create();
    m_pDelegates->retain();

    m_pDelegatesToAdd    = ccCArrayNew(8);
    m_pDelegatesToRemove = ccCArrayNew(8);
}


CCScrollWheelDispatcher::~CCScrollWheelDispatcher()
{
    CC_SAFE_RELEASE(m_pDelegates);
    if (m_pDelegatesToAdd)
    {
        ccCArrayFree(m_pDelegatesToAdd);
    }

    if (m_pDelegatesToRemove)
    {
        ccCArrayFree(m_pDelegatesToRemove);
    }
}


void CCScrollWheelDispatcher::removeDelegate(CCScrollWheelDelegate *pDelegate)
{
    if (!pDelegate)
    {
        return;
    }
    if (!m_bLocked)
    {
        forceRemoveDelegate(pDelegate);
    }
    else
    {
        ccCArrayAppendValue(m_pDelegatesToRemove, pDelegate);
        m_bToRemove = true;
    }
}


void CCScrollWheelDispatcher::addDelegate(CCScrollWheelDelegate *pDelegate)
{
    if (!pDelegate)
    {
        return;
    }

    if (!m_bLocked)
    {
        forceAddDelegate(pDelegate);
    }
    else
    {
        ccCArrayAppendValue(m_pDelegatesToAdd, pDelegate);
        m_bToAdd = true;
    }
}


void CCScrollWheelDispatcher::forceAddDelegate(CCScrollWheelDelegate *pDelegate)
{
    CCScrollWheelHandler *pHandler = CCScrollWheelHandler::handlerWithDelegate(pDelegate);

    m_pDelegates->addObject(pHandler);
}


void CCScrollWheelDispatcher::forceRemoveDelegate(CCScrollWheelDelegate *pDelegate)
{
    CCScrollWheelHandler *pHandler = NULL;
    CCObject             *pObj     = NULL;

    CCARRAY_FOREACH(m_pDelegates, pObj)
    {
        pHandler = (CCScrollWheelHandler *)pObj;
        if (pHandler && (pHandler->getDelegate() == pDelegate))
        {
            m_pDelegates->removeObject(pHandler);
            break;
        }
    }
}


bool CCScrollWheelDispatcher::dispatchScrollWheelDeltaY(float dy)
{
    CCScrollWheelHandler  *pHandler  = NULL;
    CCScrollWheelDelegate *pDelegate = NULL;

    m_bLocked = true;

    if (m_pDelegates->count() > 0)
    {
        CCObject *pObj = NULL;
        CCARRAY_FOREACH(m_pDelegates, pObj)
        {
            CC_BREAK_IF(!pObj);

            pHandler  = (CCScrollWheelHandler *)pObj;
            pDelegate = pHandler->getDelegate();

            pDelegate->scrollWheelYMoved(dy);
        }
    }

    m_bLocked = false;
    if (m_bToRemove)
    {
        m_bToRemove = false;
        for (unsigned int i = 0; i < m_pDelegatesToRemove->num; ++i)
        {
            forceRemoveDelegate((CCScrollWheelDelegate *)m_pDelegatesToRemove->arr[i]);
        }
        ccCArrayRemoveAllValues(m_pDelegatesToRemove);
    }

    if (m_bToAdd)
    {
        m_bToAdd = false;
        for (unsigned int i = 0; i < m_pDelegatesToAdd->num; ++i)
        {
            forceAddDelegate((CCScrollWheelDelegate *)m_pDelegatesToAdd->arr[i]);
        }
        ccCArrayRemoveAllValues(m_pDelegatesToAdd);
    }

    return true;
}


NS_CC_END
