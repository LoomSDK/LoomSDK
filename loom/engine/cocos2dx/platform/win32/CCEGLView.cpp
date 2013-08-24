/****************************************************************************
*  Copyright (c) 2010 cocos2d-x.org
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
#include "CCEGLView.h"
#include "cocoa/CCSet.h"
#include "ccMacros.h"
#include "CCDirector.h"
#include "touch_dispatcher/CCTouch.h"
#include "touch_dispatcher/CCTouchDispatcher.h"
#include "text_input_node/CCIMEDispatcher.h"
#include "keypad_dispatcher/CCKeypadDispatcher.h"
#include "scrollwheel_dispatcher/CCScrollWheelDispatcher.h"
#include "CCApplication.h"
#include "loom/common/platform/platformKeyCodes.h"
#include "loom/common/core/assert.h"

#include "loom/graphics/gfxGraphics.h"

NS_CC_BEGIN

//////////////////////////////////////////////////////////////////////////
// impliment CCEGLView
//////////////////////////////////////////////////////////////////////////
static CCEGLView   *s_pMainWindow    = NULL;
static const WCHAR *kWindowClassName = L"Cocos2dxWin32";

static LRESULT CALLBACK _WindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    if (s_pMainWindow && (s_pMainWindow->getHWnd() == hWnd))
    {
        return s_pMainWindow->WindowProc(uMsg, wParam, lParam);
    }
    else
    {
        return DefWindowProcW(hWnd, uMsg, wParam, lParam);
    }
}


CCEGLView::CCEGLView()
    : m_bCaptured(false)
      , m_hWnd(NULL)
      , m_hDC(NULL)
      , m_lpfnAccelerometerKeyHook(NULL)
      , inFullScreen(false)
      , lastWindowedHeight(0)
      , lastWindowedWidth(0)
{
}


CCEGLView::~CCEGLView()
{
}


bool CCEGLView::initGL()
{
    m_hDC = GetDC(m_hWnd);

    GFX::Graphics::setPlatformData(m_hWnd, (void *)NULL, (void *)NULL);

    GFX::Graphics::initialize();

    // set the initial viewport size now that we're initialized
    RECT winRect;
    GetClientRect(getHWnd(), &winRect);

    int width  = winRect.right - winRect.left;
    int height = winRect.bottom - winRect.top;

    GFX::Graphics::reset(width, height);

    return true;
}


void CCEGLView::destroyGL()
{
}


bool CCEGLView::Create(LPCTSTR pTitle, int w, int h)
{
    bool bRet = false;

    do
    {
        CC_BREAK_IF(m_hWnd);

        HINSTANCE hInstance = GetModuleHandle(NULL);
        WNDCLASSW wc;        // Windows Class Structure

        // Redraw On Size, And Own DC For Window.
        wc.style         = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
        wc.lpfnWndProc   = _WindowProc;                     // WndProc Handles Messages
        wc.cbClsExtra    = 0;                               // No Extra Window Data
        wc.cbWndExtra    = 0;                               // No Extra Window Data
        wc.hInstance     = hInstance;                       // Set The Instance
        wc.hIcon         = LoadIcon(NULL, IDI_WINLOGO);     // Load The Default Icon
        wc.hCursor       = LoadCursor(NULL, IDC_ARROW);     // Load The Arrow Pointer
        wc.hbrBackground = NULL;                            // No Background Required For GL
        wc.lpszMenuName  = NULL;                            // We Don't Want A Menu
        wc.lpszClassName = kWindowClassName;                // Set The Class Name

        CC_BREAK_IF(!RegisterClassW(&wc) && 1410 != GetLastError());

        // center window position
        RECT rcDesktop;
        GetWindowRect(GetDesktopWindow(), &rcDesktop);

        WCHAR wszBuf[50] = { 0 };
        MultiByteToWideChar(CP_UTF8, 0, m_szViewName, -1, wszBuf, sizeof(wszBuf));

        // create window
        m_hWnd = CreateWindowExW(
            WS_EX_APPWINDOW | WS_EX_WINDOWEDGE,                                 // Extended Style For The Window
            kWindowClassName,                                                   // Class Name
            wszBuf,                                                             // Window Title
            WS_OVERLAPPEDWINDOW | WS_CAPTION | WS_POPUPWINDOW | WS_MINIMIZEBOX, // Defined Window Style
            0, 0,                                                               // Window Position
            0,                                                                  // Window Width
            0,                                                                  // Window Height
            NULL,                                                               // No Parent Window
            NULL,                                                               // No Menu
            hInstance,                                                          // Instance
            NULL);

        CC_BREAK_IF(!m_hWnd);

        resize(w, h);

        bRet = initGL();
        CC_BREAK_IF(!bRet);

        s_pMainWindow = this;
        bRet          = true;
    } while (0);

    return bRet;
}


static unsigned int WIN32_TO_LOOM_KEYCODE[256] =
{
    /* 0 */
    -1,
    /* VK_LBUTTON */ -1,
    /* VK_RBUTTON */ -1,
    /* VK_CANCEL */ -1,
    /* VK_MBUTTON */ -1,
    /* VK_XBUTTON1 */ -1,
    /* VK_XBUTTON2 */ -1,
    /* 7 */ -1,
    /* VK_BACK */ LOOM_KEY_DELETE_OR_BACKSPACE,
    /* VK_TAB */ LOOM_KEY_TAB,
    /* 10 */ -1,
    /* 11 */ -1,
    /* VK_CLEAR */ LOOM_KEY_CLEAR,
    /* VK_RETURN */ LOOM_KEY_RETURN_OR_ENTER,
    /* 14 */ -1,
    /* 15 */ -1,
    /* VK_SHIFT */ LOOM_KEY_LEFT_SHIFT,
    /* VK_CONTROL */ LOOM_KEY_LEFT_CONTROL,
    /* VK_MENU */ LOOM_KEY_LEFT_ALT,
    /* VK_PAUSE */ LOOM_KEY_PAUSE,
    /* VK_CAPITAL */ LOOM_KEY_CAPS_LOCK,
    /* VK_KANA */ -1,                              /* LOOM_KEY_LANGn? */
    /* 22 */ -1,
    /* VK_JUNJA */ -1,                             /* LOOM_KEY_LANGn? */
    /* VK_FINAL */ -1,                             /* LOOM_KEY_LANGn? */
    /* VK_KANJI */ -1,                             /* LOOM_KEY_LANGn? */
    /* 26 */ -1,
    /* VK_ESCAPE */ LOOM_KEY_ESCAPE,
    /* VK_CONVERT */ -1,                           /* LOOM_KEY_LANGn? */
    /* VK_NONCONVERT */ -1,                        /* LOOM_KEY_LANGn? */
    /* VK_ACCEPT */ -1,                            /* LOOM_KEY_LANGn? */
    /* VK_MODECHANGE */ -1,                        /* LOOM_KEY_LANGn? */
    /* VK_SPACE */ LOOM_KEY_SPACEBAR,
    /* VK_PRIOR */ LOOM_KEY_PAGE_UP,
    /* VK_NEXT */ LOOM_KEY_PAGE_DOWN,
    /* VK_END */ LOOM_KEY_END,
    /* VK_HOME */ LOOM_KEY_HOME,
    /* VK_LEFT */ LOOM_KEY_LEFT_ARROW,
    /* VK_UP */ LOOM_KEY_UP_ARROW,
    /* VK_RIGHT */ LOOM_KEY_RIGHT_ARROW,
    /* VK_DOWN */ LOOM_KEY_DOWN_ARROW,
    /* VK_SELECT */ LOOM_KEY_SELECT,
    /* VK_PRINT */ -1,
    /* VK_EXECUTE */ LOOM_KEY_EXECUTE,
    /* VK_SNAPSHOT */ LOOM_KEY_PRINT_SCREEN,
    /* VK_INSERT */ LOOM_KEY_INSERT,
    /* VK_DELETE */ LOOM_KEY_DELETE_FORWARD,
    /* VK_HELP */ LOOM_KEY_HELP,
    /* 48 */ LOOM_KEY_0,
    /* 49 */ LOOM_KEY_1,
    /* 50 */ LOOM_KEY_2,
    /* 51 */ LOOM_KEY_3,
    /* 52 */ LOOM_KEY_4,
    /* 53 */ LOOM_KEY_5,
    /* 54 */ LOOM_KEY_6,
    /* 55 */ LOOM_KEY_7,
    /* 56 */ LOOM_KEY_8,
    /* 57 */ LOOM_KEY_9,
    /* 58 */ -1,
    /* 59 */ -1,
    /* 60 */ -1,
    /* 61 */ -1,
    /* 62 */ -1,
    /* 63 */ -1,
    /* 64 */ -1,
    /* 65 */ LOOM_KEY_A,
    /* 66 */ LOOM_KEY_B,
    /* 67 */ LOOM_KEY_C,
    /* 68 */ LOOM_KEY_D,
    /* 69 */ LOOM_KEY_E,
    /* 70 */ LOOM_KEY_F,
    /* 71 */ LOOM_KEY_G,
    /* 72 */ LOOM_KEY_H,
    /* 73 */ LOOM_KEY_I,
    /* 74 */ LOOM_KEY_J,
    /* 75 */ LOOM_KEY_K,
    /* 76 */ LOOM_KEY_L,
    /* 77 */ LOOM_KEY_M,
    /* 78 */ LOOM_KEY_N,
    /* 79 */ LOOM_KEY_O,
    /* 80 */ LOOM_KEY_P,
    /* 81 */ LOOM_KEY_Q,
    /* 82 */ LOOM_KEY_R,
    /* 83 */ LOOM_KEY_S,
    /* 84 */ LOOM_KEY_T,
    /* 85 */ LOOM_KEY_U,
    /* 86 */ LOOM_KEY_V,
    /* 87 */ LOOM_KEY_W,
    /* 88 */ LOOM_KEY_X,
    /* 89 */ LOOM_KEY_Y,
    /* 90 */ LOOM_KEY_Z,
    /* VK_LWIN */ LOOM_KEY_LEFT_GUI,
    /* VK_RWIN */ LOOM_KEY_RIGHT_GUI,
    /* VK_APPS */ -1,
    /* 94 */ -1,
    /* VK_SLEEP */ -1,
    /* VK_NUMPAD0 */ LOOM_KEY_PAD0,
    /* VK_NUMPAD1 */ LOOM_KEY_PAD1,
    /* VK_NUMPAD2 */ LOOM_KEY_PAD2,
    /* VK_NUMPAD3 */ LOOM_KEY_PAD3,
    /* VK_NUMPAD4 */ LOOM_KEY_PAD4,
    /* VK_NUMPAD5 */ LOOM_KEY_PAD5,
    /* VK_NUMPAD6 */ LOOM_KEY_PAD6,
    /* VK_NUMPAD7 */ LOOM_KEY_PAD7,
    /* VK_NUMPAD8 */ LOOM_KEY_PAD8,
    /* VK_NUMPAD9 */ LOOM_KEY_PAD9,
    /* VK_MULTIPLY */ LOOM_KEY_PADASTERISK,
    /* VK_ADD */ LOOM_KEY_PADPLUS,
    /* VK_SEPARATOR */ -1,                         /* LOOM_KEY_SEPARATOR? */
    /* VK_SUBTRACT */ LOOM_KEY_PADHYPHEN,
    /* VK_DECIMAL */ LOOM_KEY_PADPERIOD,
    /* VK_DIVIDE */ LOOM_KEY_PADSLASH,
    /* VK_F1  */ LOOM_KEY_F1,
    /* VK_F2  */ LOOM_KEY_F2,
    /* VK_F3  */ LOOM_KEY_F3,
    /* VK_F4  */ LOOM_KEY_F4,
    /* VK_F5  */ LOOM_KEY_F5,
    /* VK_F6  */ LOOM_KEY_F6,
    /* VK_F7  */ LOOM_KEY_F7,
    /* VK_F8  */ LOOM_KEY_F8,
    /* VK_F9  */ LOOM_KEY_F9,
    /* VK_F10 */ LOOM_KEY_F10,
    /* VK_F11 */ LOOM_KEY_F11,
    /* VK_F12 */ LOOM_KEY_F12,
    /* VK_F13 */ LOOM_KEY_F13,
    /* VK_F14 */ LOOM_KEY_F14,
    /* VK_F15 */ LOOM_KEY_F15,
    /* VK_F16 */ LOOM_KEY_F16,
    /* VK_F17 */ LOOM_KEY_F17,
    /* VK_F18 */ LOOM_KEY_F18,
    /* VK_F19 */ LOOM_KEY_F19,
    /* VK_F20 */ LOOM_KEY_F20,
    /* VK_F21 */ LOOM_KEY_F21,
    /* VK_F22 */ LOOM_KEY_F22,
    /* VK_F23 */ LOOM_KEY_F23,
    /* VK_F24 */ LOOM_KEY_F24,
    /* 136 */ -1,
    /* 137 */ -1,
    /* 138 */ -1,
    /* 139 */ -1,
    /* 140 */ -1,
    /* 141 */ -1,
    /* 142 */ -1,
    /* 143 */ -1,
    /* VK_NUMLOCK */ LOOM_KEY_PADNUM_LOCK,
    /* VK_SCROLL */ LOOM_KEY_SCROLL_LOCK,
    /* 146 */ -1,
    /* 147 */ -1,
    /* 148 */ -1,
    /* 149 */ -1,
    /* 150 */ -1,
    /* 151 */ -1,
    /* 152 */ -1,
    /* 153 */ -1,
    /* 154 */ -1,
    /* 155 */ -1,
    /* 156 */ -1,
    /* 157 */ -1,
    /* 158 */ -1,
    /* 159 */ -1,
    /* VK_LSHIFT */ LOOM_KEY_LEFT_SHIFT,
    /* VK_RSHIFT */ LOOM_KEY_RIGHT_SHIFT,
    /* VK_LCONTROL */ LOOM_KEY_LEFT_CONTROL,
    /* VK_RCONTROL */ LOOM_KEY_RIGHT_CONTROL,
    /* VK_LMENU */ LOOM_KEY_LEFT_GUI,              /* ? */
    /* VK_RMENU */ LOOM_KEY_RIGHT_GUI,             /* ? */
    /* VK_BROWSER_BACK */ -1,
    /* VK_BROWSER_FORWARD */ -1,
    /* VK_BROWSER_REFRESH */ -1,
    /* VK_BROWSER_STOP */ -1,
    /* VK_BROWSER_SEARCH */ -1,
    /* VK_BROWSER_FAVORITES */ -1,
    /* VK_BROWSER_HOME */ -1,
    /* VK_VOLUME_MUTE */ LOOM_KEY_MUTE,
    /* VK_VOLUME_DOWN */ LOOM_KEY_VOLUME_DOWN,
    /* VK_VOLUME_UP */ LOOM_KEY_VOLUME_UP,
    /* VK_MEDIA_NEXT_TRACK */ -1,
    /* VK_MEDIA_PREV_TRACK */ -1,
    /* VK_MEDIA_STOP */ -1,
    /* VK_MEDIA_PLAY_PAUSE */ -1,
    /* VK_LAUNCH_MAIL */ -1,
    /* VK_LAUNCH_MEDIA_SELECT */ -1,
    /* VK_LAUNCH_APP1 */ -1,
    /* VK_LAUNCH_APP2 */ -1,
    /* 184 */ -1,
    /* 185 */ -1,
    /* VK_OEM_1 */ LOOM_KEY_SEMICOLON,
    /* VK_OEM_PLUS */ LOOM_KEY_EQUAL_SIGN,
    /* VK_OEM_COMMA */ LOOM_KEY_COMMA,
    /* VK_OEM_MINUS */ LOOM_KEY_HYPHEN,
    /* VK_OEM_PERIOD */ LOOM_KEY_PERIOD,
    /* VK_OEM_2 */ LOOM_KEY_SLASH,
    /* VK_OEM_3 */ LOOM_KEY_GRAVE_ACCENT_AND_TILDE,
    /* 193 */ -1,
    /* 194 */ -1,
    /* 195 */ -1,
    /* 196 */ -1,
    /* 197 */ -1,
    /* 198 */ -1,
    /* 199 */ -1,
    /* 200 */ -1,
    /* 201 */ -1,
    /* 202 */ -1,
    /* 203 */ -1,
    /* 204 */ -1,
    /* 205 */ -1,
    /* 206 */ -1,
    /* 207 */ -1,
    /* 208 */ -1,
    /* 209 */ -1,
    /* 210 */ -1,
    /* 211 */ -1,
    /* 212 */ -1,
    /* 213 */ -1,
    /* 214 */ -1,
    /* 215 */ -1,
    /* 216 */ -1,
    /* 217 */ -1,
    /* 218 */ -1,
    /* VK_OEM_4 */ LOOM_KEY_OPEN_BRACKET,
    /* VK_OEM_5 */ LOOM_KEY_BACKSLASH,
    /* VK_OEM_6 */ LOOM_KEY_CLOSE_BRACKET,
    /* VK_OEM_7 */ LOOM_KEY_QUOTE,
    /* VK_OEM_8 */ -1,
    /* 224 */ -1,
    /* 225 */ -1,
    /* VK_OEM_102 */ LOOM_KEY_NON_US_BACKSLASH,    /* ? */
    /* 227 */ -1,
    /* 228 */ -1,
    /* VK_PROCESSKEY */ -1,
    /* 230 */ -1,
    /* VK_PACKET */ -1,                            /* handle specially? */
    /* 232 */ -1,
    /* 233 */ -1,
    /* 234 */ -1,
    /* 235 */ -1,
    /* VK_ATTN */ LOOM_KEY_SYS_REQ_OR_ATTENTION,   /* ? */
    /* VK_CRSEL */ LOOM_KEY_CR_SEL_OR_PROPS,       /* ? */
    /* VK_EXSEL */ LOOM_KEY_EX_SEL,                /* ? */
    /* VK_EREOF */ -1,
    /* VK_PLAY */ -1,
    /* VK_ZOOM */ -1,
    /* VK_NONAME */ -1,
    /* VK_PA1 */ -1,
    /* VK_OEM_CLEAR */ LOOM_KEY_CLEAR,             /* ? */
    /* 255 */ -1,
};

unsigned int Win32ToLoomKeyCode(unsigned int keyCode)
{
    unsigned int byte = keyCode & 0xff;

    return WIN32_TO_LOOM_KEYCODE[byte];
}


LRESULT CCEGLView::WindowProc(UINT message, WPARAM wParam, LPARAM lParam)
{
    int windowWidth = 0, windowHeight = 0;

    switch (message)
    {
    case WM_LBUTTONDOWN:
        if (m_pDelegate && (MK_LBUTTON == wParam))
        {
            POINT   point = { (short)LOWORD(lParam), (short)HIWORD(lParam) };
            CCPoint pt(point.x / CC_CONTENT_SCALE_FACTOR(), point.y / CC_CONTENT_SCALE_FACTOR());
            if (m_rcViewPort.containsPoint(pt))
            {
                m_bCaptured = true;
                SetCapture(m_hWnd);
                int id = 0;
                handleTouchesBegin(1, &id, &pt.x, &pt.y);
            }
        }
        break;

    case WM_MOUSEMOVE:
        if ((MK_LBUTTON == wParam) && m_bCaptured)
        {
            POINT   point = { (short)LOWORD(lParam), (short)HIWORD(lParam) };
            CCPoint pt(point.x / CC_CONTENT_SCALE_FACTOR(), point.y / CC_CONTENT_SCALE_FACTOR());
            int     id = 0;
            handleTouchesMove(1, &id, &pt.x, &pt.y);
        }
        break;

    case WM_LBUTTONUP:
        if (m_bCaptured)
        {
            POINT   point = { (short)LOWORD(lParam), (short)HIWORD(lParam) };
            CCPoint pt(point.x / CC_CONTENT_SCALE_FACTOR(), point.y / CC_CONTENT_SCALE_FACTOR());
            int     id = 0;
            handleTouchesEnd(1, &id, &pt.x, &pt.y);

            ReleaseCapture();
            m_bCaptured = false;
        }
        break;

    case WM_SIZE:
        switch (wParam)
        {
        case SIZE_RESTORED:
            CCApplication::sharedApplication().applicationWillEnterForeground();
            break;

        case SIZE_MINIMIZED:
            CCApplication::sharedApplication().applicationDidEnterBackground();
            break;
        }

        // Update the director with the new window size.
        windowWidth  = LOWORD(lParam); // Macro to get the low-order word.
        windowHeight = HIWORD(lParam); // Macro to get the high-order word.

        CCEGLViewProtocol::setFrameSize((float)windowWidth, (float)windowHeight);
        CCDirector::sharedDirector()->reshapeProjection(cocos2d::CCSizeMake(windowWidth, windowHeight));

        // avoid flicker
        CCDirector::sharedDirector()->drawScene();

        break;

    case WM_KEYDOWN:
        if ((wParam == VK_F1) || (wParam == VK_F2))
        {
            CCDirector *pDirector = CCDirector::sharedDirector();
            if ((GetKeyState(VK_LSHIFT) < 0) || (GetKeyState(VK_RSHIFT) < 0) || (GetKeyState(VK_SHIFT) < 0))
            {
                pDirector->getKeypadDispatcher()->dispatchKeypadMSG(wParam == VK_F1 ? kTypeBackClicked : kTypeMenuClicked);
            }
        }

        // Fire keyboard events but not for repeating keys.
        if ((lParam & (1 << 30)) == 0)
        {
            CCDirector::sharedDirector()->getKeypadDispatcher()->dispatchKeypadMSG(kTypeKeyDown, Win32ToLoomKeyCode(wParam));
        }

        if (m_lpfnAccelerometerKeyHook != NULL)
        {
            (*m_lpfnAccelerometerKeyHook)(message, wParam, lParam);
        }
        break;

    case WM_KEYUP:
        CCDirector::sharedDirector()->getKeypadDispatcher()->dispatchKeypadMSG(kTypeKeyUp, Win32ToLoomKeyCode(wParam));

        if (m_lpfnAccelerometerKeyHook != NULL)
        {
            (*m_lpfnAccelerometerKeyHook)(message, wParam, lParam);
        }
        break;

    case WM_CHAR:
        if (wParam < 0x20)
        {
            if (VK_BACK == wParam)
            {
                CCIMEDispatcher::sharedDispatcher()->dispatchDeleteBackward();
            }
            else if (VK_RETURN == wParam)
            {
                CCIMEDispatcher::sharedDispatcher()->dispatchInsertText("\n", 1);
            }
            else if (VK_TAB == wParam)
            {
                // tab input
            }
            else if (VK_ESCAPE == wParam)
            {
                // ESC input
                CCDirector::sharedDirector()->end();
            }
        }
        else if (wParam < 128)
        {
            // ascii char
            CCIMEDispatcher::sharedDispatcher()->dispatchInsertText((const char *)&wParam, 1);
        }
        else
        {
            char szUtf8[8] = { 0 };
            int  nLen      = WideCharToMultiByte(CP_UTF8, 0, (LPCWSTR)&wParam, 1, szUtf8, sizeof(szUtf8), NULL, NULL);
            CCIMEDispatcher::sharedDispatcher()->dispatchInsertText(szUtf8, nLen);
        }
        if (m_lpfnAccelerometerKeyHook != NULL)
        {
            (*m_lpfnAccelerometerKeyHook)(message, wParam, lParam);
        }
        break;

    case WM_PAINT:
        PAINTSTRUCT ps;
        BeginPaint(m_hWnd, &ps);
        EndPaint(m_hWnd, &ps);
        break;

    case WM_CLOSE:
        CCDirector::sharedDirector()->end();
        break;

    case WM_DESTROY:
        destroyGL();
        PostQuitMessage(0);
        break;

    case WM_MOUSEWHEEL:
       {
           // Normalize to just -1,1 since windows and mac are so different
           short dy = GET_WHEEL_DELTA_WPARAM(wParam);
           dy = (dy > 0) ? 1 : -1;
           CCDirector::sharedDirector()->getScrollWheelDispatcher()->dispatchScrollWheelDeltaY(dy);
       }
       break;

    default:
        return DefWindowProcW(m_hWnd, message, wParam, lParam);
    }
    return 0;
}


void CCEGLView::setAccelerometerKeyHook(LPFN_ACCELEROMETER_KEYHOOK lpfnAccelerometerKeyHook)
{
    m_lpfnAccelerometerKeyHook = lpfnAccelerometerKeyHook;
}


bool CCEGLView::isOpenGLReady()
{
    return(m_hDC != NULL);
}


void CCEGLView::end()
{
    if (m_hWnd)
    {
        DestroyWindow(m_hWnd);
        m_hWnd = NULL;
    }
    s_pMainWindow = NULL;
    UnregisterClassW(kWindowClassName, GetModuleHandle(NULL));
    delete this;
}


void CCEGLView::swapBuffers()
{
    if (m_hDC != NULL)
    {
    }
}


void CCEGLView::setIMEKeyboardState(bool /*bOpen*/, int type)
{
}


HWND CCEGLView::getHWnd()
{
    return m_hWnd;
}


void CCEGLView::resize(int width, int height)
{
    if (!m_hWnd)
    {
        return;
    }

    RECT rcClient;
    GetClientRect(m_hWnd, &rcClient);
    if ((rcClient.right - rcClient.left == width) &&
        (rcClient.bottom - rcClient.top == height))
    {
        return;
    }
    // calculate new window width and height
    rcClient.right  = rcClient.left + width;
    rcClient.bottom = rcClient.top + height;
    AdjustWindowRectEx(&rcClient, GetWindowLong(m_hWnd, GWL_STYLE), false, GetWindowLong(m_hWnd, GWL_EXSTYLE));

    // change width and height
    SetWindowPos(m_hWnd, 0, 0, 0, rcClient.right - rcClient.left,
                 rcClient.bottom - rcClient.top, SWP_NOCOPYBITS | SWP_NOMOVE | SWP_NOOWNERZORDER | SWP_NOZORDER);
}


void CCEGLView::setFrameSize(float width, float height)
{
    Create((LPCTSTR)m_szViewName, (int)width, (int)height);
    CCEGLViewProtocol::setFrameSize(width, height);
}


void CCEGLView::centerWindow()
{
    if (!m_hWnd)
    {
        return;
    }

    RECT rcDesktop, rcWindow;
    GetWindowRect(GetDesktopWindow(), &rcDesktop);

    // substract the task bar
    HWND hTaskBar = FindWindow(TEXT("Shell_TrayWnd"), NULL);
    if (hTaskBar != NULL)
    {
        APPBARDATA abd;

        abd.cbSize = sizeof(APPBARDATA);
        abd.hWnd   = hTaskBar;

        SHAppBarMessage(ABM_GETTASKBARPOS, &abd);
        SubtractRect(&rcDesktop, &rcDesktop, &abd.rc);
    }
    GetWindowRect(m_hWnd, &rcWindow);

    int offsetX = (rcDesktop.right - rcDesktop.left - (rcWindow.right - rcWindow.left)) / 2;
    offsetX = (offsetX > 0) ? offsetX : rcDesktop.left;
    int offsetY = (rcDesktop.bottom - rcDesktop.top - (rcWindow.bottom - rcWindow.top)) / 2;
    offsetY = (offsetY > 0) ? offsetY : rcDesktop.top;

    SetWindowPos(m_hWnd, 0, offsetX, offsetY, 0, 0, SWP_NOCOPYBITS | SWP_NOSIZE | SWP_NOOWNERZORDER | SWP_NOZORDER);
}


bool CCEGLView::canSetContentScaleFactor()
{
    // Always draw at full res.
    return false;
}


void CCEGLView::setContentScaleFactor(float contentScaleFactor)
{
    // Does nothing as we don't have a meaningful "retina" mode on Windows.
}


CCEGLView& CCEGLView::sharedOpenGLView()
{
    static CCEGLView *s_pEglView = NULL;

    if (s_pEglView == NULL)
    {
        s_pEglView = new CCEGLView();
    }
    return *s_pEglView;
}


NS_CC_END
