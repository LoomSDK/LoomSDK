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
    void dispatchShowComposition(const char *text, int len, int start, int length);
};

class IMEDelegate
{
public:

    /** Deprecated, not used right now. */
    LOOM_DELEGATE(DidAttachWithIME);
    /** Deprecated, not used right now. */
    LOOM_DELEGATE(DidDetachWithIME);

    /** Invoked when there is new text to be inserted. */
    LOOM_DELEGATE(InsertText);

    /** Invoked when the text should be deleted backwards (backspace). */
    LOOM_DELEGATE(DeleteBackward);

    /** Invoked when there is a new IME composition candidate to be shown */
    LOOM_DELEGATE(ShowComposition);

    /** Deprecated, not used right now. */
    LOOM_DELEGATE(KeyboardWillShow);
    /** Deprecated, not used right now. */
    LOOM_DELEGATE(KeyboardDidShow);
    /** Deprecated, not used right now. */
    LOOM_DELEGATE(KeyboardWillHide);
    /** Deprecated, not used right now. */
    LOOM_DELEGATE(KeyboardDidHide);

    /** Deprecated, not used right now. */
    bool     canAttachWithIME;
    /** Deprecated, not used right now. */
    bool     canDetachWithIME;
    /** Deprecated, not used right now. */
    utString contentText;

    IMEDelegate();
    ~IMEDelegate();

    /** Deprecated, not used right now. */
    virtual void didAttachWithIME();
    /** Deprecated, not used right now. */
    virtual void didDetachWithIME();

    /** Invoke the insert text delegate. */
    virtual void insertText(const char *text, int len);

    /** Invoke the delete backward delegate. */
    virtual void deleteBackward();

    /** Invoke the show composition delegate. */
    virtual void showComposition(const char *text, int len, int start, int length);

    /** Deprecated, not used right now. */
    virtual const char *getContentText();

    /** Deprecated, not used right now. */
    virtual void keyboardWillShow(IMEKeyboardNotificationInfo& info);
    /** Deprecated, not used right now. */
    virtual void keyboardDidShow(IMEKeyboardNotificationInfo& info);
    /** Deprecated, not used right now. */
    virtual void keyboardWillHide(IMEKeyboardNotificationInfo& info);
    /** Deprecated, not used right now. */
    virtual void keyboardDidHide(IMEKeyboardNotificationInfo& info);

    /**
     * Set the IME text input rectangle in device points.
     * This is used for positioning the IME interfaces or
     * moving the rendering to not get covered by the
     * soft keyboard on mobile devices.
     */
    void setTextInputRect(Loom2D::Rectangle rect);

    /**
     * Begin text input and open a soft keyboard if available.
     * This begins the delegate invocation of insertText, showComposition, etc.
     */
    bool attachWithIME(int type = 0);

    /**
     * End text input and close the soft keyboard if available and opened.
     * This ends the delegate invocation of insertText, showComposition, etc.
     */
    bool detachWithIME();
};