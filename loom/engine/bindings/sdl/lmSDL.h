/*
* ===========================================================================
* Loom SDK
* Copyright 2011, 2012, 2013
* The Game Engine Company, LLC
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
* ===========================================================================
*/

#include "SDL.h"
#include "loom/engine/loom2d/l2dRectangle.h"

class Window
{
protected:
    static Window* mainWindow;
    SDL_Window* sdlWindow;
    bool initializing;

public:
    Window(SDL_Window* window);
    static void setMain(Window* window);
    static Window* getMain();
    void updateFromConfig();
    void show();
    void hide();
};

typedef struct
{
    Loom2D::Rectangle begin;
    Loom2D::Rectangle end;
    float duration;
} IMEKeyboardNotificationInfo;

class IMEDelegate;

class IMEDelegateDispatcher
{
protected:
    utArray<IMEDelegate*> delegates;

public:
    static IMEDelegateDispatcher* shared();

    IMEDelegateDispatcher() {};
    ~IMEDelegateDispatcher() {};

    void add(IMEDelegate* id);
    void remove(IMEDelegate* id);
    void dispatchInsertText(const char *text, int len);
    void dispatchDeleteBackward();
};

class IMEDelegate
{
public:

    LOOM_DELEGATE(DidAttachWithIME);
    LOOM_DELEGATE(DidDetachWithIME);
    LOOM_DELEGATE(InsertText);
    LOOM_DELEGATE(DeleteBackward);
    LOOM_DELEGATE(KeyboardWillShow);
    LOOM_DELEGATE(KeyboardDidShow);
    LOOM_DELEGATE(KeyboardWillHide);
    LOOM_DELEGATE(KeyboardDidHide);

    bool     canAttachWithIME;
    bool     canDetachWithIME;
    utString contentText;

    IMEDelegate();
    ~IMEDelegate();

    virtual void didAttachWithIME();
    virtual void didDetachWithIME();

    virtual void insertText(const char *text, int len);
    virtual void deleteBackward();

    virtual const char *getContentText();

    virtual void keyboardWillShow(IMEKeyboardNotificationInfo& info);
    virtual void keyboardDidShow(IMEKeyboardNotificationInfo& info);
    virtual void keyboardWillHide(IMEKeyboardNotificationInfo& info);
    virtual void keyboardDidHide(IMEKeyboardNotificationInfo& info);

    bool attachWithIME(int type = 0);
    bool detachWithIME();
};