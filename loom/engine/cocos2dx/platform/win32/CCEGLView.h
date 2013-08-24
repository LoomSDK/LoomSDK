#pragma once

#include <Windows.h>
#include "platform/CCCommon.h"
#include "cocoa/CCGeometry.h"
#include "platform/CCEGLViewProtocol.h"

NS_CC_BEGIN

class CCEGL;

class CC_DLL CCEGLView : public CCEGLViewProtocol
{
public:
    CCEGLView();
    virtual ~CCEGLView();

    /* override functions */
    virtual bool isOpenGLReady();
    virtual void end();
    virtual void swapBuffers();
    virtual bool canSetContentScaleFactor();
    virtual void setContentScaleFactor(float contentScaleFactor);
    virtual void setFrameSize(float width, float height);
    virtual void setIMEKeyboardState(bool bOpen, int type = 0);

    virtual bool isFullScreen()
    {
        return inFullScreen;
    }

    virtual void toggleFullScreen()
    {
        if (inFullScreen)
        {
            // Toggle style.
            SetWindowLong(getHWnd(), GWL_STYLE, WS_OVERLAPPEDWINDOW);
            ShowWindow(getHWnd(), SW_SHOW);

            // Go back to a normal size.
            SetWindowPos(getHWnd(), 0, 0, 0, lastWindowedWidth, lastWindowedHeight, SWP_NOMOVE | SWP_SHOWWINDOW);

            inFullScreen = false;
        }
        else
        {
            // Go to windowless style.
            SetWindowLong(getHWnd(), GWL_STYLE, WS_POPUP);
            ShowWindow(getHWnd(), SW_SHOW);

            // Set size to desktop size, noting window size.
            RECT winRect;
            GetWindowRect(getHWnd(), &winRect);

            lastWindowedWidth  = winRect.right - winRect.left;
            lastWindowedHeight = winRect.bottom - winRect.top;

            SetWindowPos(getHWnd(), 0, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), SWP_SHOWWINDOW);

            inFullScreen = true;
        }
    }

private:

    bool inFullScreen;
    int  lastWindowedWidth, lastWindowedHeight;

    virtual bool Create(LPCTSTR pTitle, int w, int h);
    bool initGL();
    void destroyGL();

public:
    virtual LRESULT WindowProc(UINT message, WPARAM wParam, LPARAM lParam);

    // win32 platform function
    HWND getHWnd();
    void resize(int width, int height);
    void centerWindow();

    typedef void (*LPFN_ACCELEROMETER_KEYHOOK)(UINT message, WPARAM wParam, LPARAM lParam);
    void setAccelerometerKeyHook(LPFN_ACCELEROMETER_KEYHOOK lpfnAccelerometerKeyHook);

    // static function

    /**
     * @brief    get the shared main open gl window
     */
    static CCEGLView& sharedOpenGLView();

protected:

private:
    bool m_bCaptured;
    HWND m_hWnd;
    HDC  m_hDC;
    LPFN_ACCELEROMETER_KEYHOOK m_lpfnAccelerometerKeyHook;
};

NS_CC_END
