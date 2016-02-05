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

#include "loom/engine/loom2d/l2dStage.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/core/log.h"
#include "loom/common/config/applicationConfig.h"
#include <SDL.h>
#include "lmSDL.h"

IMEDelegateDispatcher* IMEDelegateDispatcher::shared() {
    static IMEDelegateDispatcher instance;
    return &instance;
};

void IMEDelegateDispatcher::add(IMEDelegate* d) {
    delegates.push_back(d);
}

void IMEDelegateDispatcher::remove(IMEDelegate* d) {
    delegates.erase(d, true);
}

void IMEDelegateDispatcher::dispatchInsertText(const char *text, int len) {
    utArray<IMEDelegate*>::Iterator it = delegates.iterator();
    while (it.hasMoreElements()) {
        IMEDelegate* d = it.getNext();
        d->insertText(text, len);
    }
}

void IMEDelegateDispatcher::dispatchDeleteBackward() {
    utArray<IMEDelegate*>::Iterator it = delegates.iterator();
    while (it.hasMoreElements()) {
        IMEDelegate* d = it.getNext();
        d->deleteBackward();
    }
}

void IMEDelegateDispatcher::dispatchShowComposition(const char *text, int len, int start, int length) {
    utArray<IMEDelegate*>::Iterator it = delegates.iterator();
    while (it.hasMoreElements()) {
        IMEDelegate* d = it.getNext();
        d->showComposition(text, len, start, length);
    }
}


IMEDelegate::IMEDelegate()
    : canDetachWithIME(true)
    , canAttachWithIME(true)
    , contentText("")
{
    IMEDelegateDispatcher::shared()->add(this);
}

IMEDelegate::~IMEDelegate()
{
    IMEDelegateDispatcher::shared()->remove(this);
}

void IMEDelegate::didAttachWithIME()
{
    _DidAttachWithIMEDelegate.invoke();
}

void IMEDelegate::didDetachWithIME()
{
    _DidDetachWithIMEDelegate.invoke();
}

void IMEDelegate::insertText(const char *text, int len)
{
    _InsertTextDelegate.pushArgument(text);
    _InsertTextDelegate.pushArgument(len);
    _InsertTextDelegate.invoke();
}

void IMEDelegate::deleteBackward()
{
    _DeleteBackwardDelegate.invoke();
}

void IMEDelegate::showComposition(const char *text, int len, int start, int length)
{
    _ShowCompositionDelegate.pushArgument(text);
    _ShowCompositionDelegate.pushArgument(len);
    _ShowCompositionDelegate.pushArgument(start);
    _ShowCompositionDelegate.pushArgument(length);
    _ShowCompositionDelegate.invoke();
}

const char *IMEDelegate::getContentText()
{
    return contentText.c_str();
}

void IMEDelegate::keyboardWillShow(IMEKeyboardNotificationInfo& info)
{
    _KeyboardWillShowDelegate.invoke();
}

void IMEDelegate::keyboardDidShow(IMEKeyboardNotificationInfo& info)
{
    _KeyboardDidShowDelegate.invoke();
}

void IMEDelegate::keyboardWillHide(IMEKeyboardNotificationInfo& info)
{
    _KeyboardWillHideDelegate.invoke();
}

void IMEDelegate::keyboardDidHide(IMEKeyboardNotificationInfo& info)
{
    _KeyboardDidHideDelegate.invoke();
}

void IMEDelegate::setTextInputRect(Loom2D::Rectangle rect) {
    SDL_Rect r;
    r.x = (int) rect.x;
    r.y = (int) rect.y;
    r.w = (int) rect.width;
    r.h = (int) rect.height;
    SDL_SetTextInputRect(&r);
};
bool IMEDelegate::attachWithIME(int type) { 
    SDL_StartTextInput();
    return true;
};
bool IMEDelegate::detachWithIME() {
    SDL_StopTextInput();
    return true;
};


static int registerIMEDelegate(lua_State *L)
{
    beginPackage(L, "loom.platform")

        .beginClass<IMEDelegate>("IMEDelegate")

        .addConstructor<void(*)(void)>()

        .addVar("canAttachWithIME", &IMEDelegate::canAttachWithIME)
        .addVar("canDetachWithIME", &IMEDelegate::canDetachWithIME)
        .addVar("contentText", &IMEDelegate::contentText)

        .addVarAccessor("onDidAttachWithIME", &IMEDelegate::getDidAttachWithIMEDelegate)
        .addVarAccessor("onDidDetachWithIME", &IMEDelegate::getDidDetachWithIMEDelegate)
        .addVarAccessor("onInsertText", &IMEDelegate::getInsertTextDelegate)
        .addVarAccessor("onDeleteBackward", &IMEDelegate::getDeleteBackwardDelegate)
        .addVarAccessor("onShowComposition", &IMEDelegate::getShowCompositionDelegate)
        .addVarAccessor("onKeyboardWillShow", &IMEDelegate::getKeyboardWillShowDelegate)
        .addVarAccessor("onKeyboardDidShow", &IMEDelegate::getKeyboardDidShowDelegate)
        .addVarAccessor("onKeyboardWillHide", &IMEDelegate::getKeyboardWillHideDelegate)
        .addVarAccessor("onKeyboardDidHide", &IMEDelegate::getKeyboardDidHideDelegate)

        .addMethod("setTextInputRect", &IMEDelegate::setTextInputRect)
        .addMethod("attachWithIME", &IMEDelegate::attachWithIME)
        .addMethod("detachWithIME", &IMEDelegate::detachWithIME)

        .endClass()

        .endPackage();

    return 0;
}


void installPackageSDL()
{
    LOOM_DECLARE_MANAGEDNATIVETYPE(IMEDelegate, registerIMEDelegate);
}
