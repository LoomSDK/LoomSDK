#ifndef __CC_APPLICATION_WIN32_H__
#define __CC_APPLICATION_WIN32_H__

#include <Windows.h>
#include "platform/CCCommon.h"
#include "platform/CCApplicationProtocol.h"

NS_CC_BEGIN

class CCRect;

class CC_DLL CCApplication : public CCApplicationProtocol
{
public:
    CCApplication();
    virtual ~CCApplication();

    /**
     * @brief    Run the message loop.
     */
    int run();

    /**
     * @brief    Get current applicaiton instance.
     * @return Current application instance pointer.
     */
    static CCApplication& sharedApplication();

    /**
     * @brief   Set the CLI Ruby process id, this is used to see if we should exit
     */
    inline void setCLIRubyProcessId(long int processId)
    {
        m_cliRubyProcessID = processId;
    }

    inline long int getCLIRubyProcessId()
    {
        return m_cliRubyProcessID;
    }

    /* override functions */
    virtual void setAnimationInterval(double interval);
    virtual ccLanguageType getCurrentLanguage();

protected:
    HINSTANCE     m_hInstance;
    HACCEL        m_hAccelTable;
    LARGE_INTEGER m_nAnimationInterval;
    DWORD         m_cliRubyProcessID;

    static CCApplication *sm_pSharedApplication;
};

NS_CC_END
#endif    // __CC_APPLICATION_WIN32_H__
