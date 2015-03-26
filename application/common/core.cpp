#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif

#include "loom/engine/bindings/sdl/lmSDL.h"

#include "loom/graphics/gfxGraphics.h"
#include "loom/engine/loom2d/l2dStage.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platform.h"

#include <SDL.h>

extern "C"
{
    void loom_appSetup();
    void loom_appShutdown();
    void loom_tick();
    void supplyEmbeddedAssets();
};

SDL_Window *gSDLWindow = NULL;
Window *gWindow = NULL;
SDL_GLContext gContext;

lmDefineLogGroup(coreLogGroup, "loom.core", 1, LoomLogInfo);

static int done = 0;

void loop()
{
    SDL_Event event;

    // Get the stage as it will receive most events.
    Loom2D::Stage *stage = Loom2D::Stage::smMainStage;
    
    /* Check for events */
    while (SDL_PollEvent(&event))
    {
        if (event.type == SDL_QUIT)
        {
            done = 1;
        }

        // Bail on the rest if no stage!
        if(!stage)
            continue;

        if(event.type == SDL_KEYDOWN)
        {
            SDL_Keysym key = event.key.keysym;
            // Handle a key!
            stage->_KeyDownDelegate.pushArgument(key.scancode);
            stage->_KeyDownDelegate.pushArgument(key.sym);
            stage->_KeyDownDelegate.pushArgument(key.mod);
            stage->_KeyDownDelegate.invoke();
            //lmLog(coreLogGroup, "keydown %d %d", key.sym, SDLK_BACKSPACE);
            if (SDL_IsTextInputActive() && key.mod == KMOD_NONE && key.sym == SDLK_BACKSPACE) IMEDelegateDispatcher::shared()->dispatchDeleteBackward();
            if (key.mod & KMOD_CTRL && key.sym == SDLK_v) {
                char* clipboard = SDL_GetClipboardText();
                IMEDelegateDispatcher::shared()->dispatchInsertText(clipboard, strlen(clipboard));
                SDL_free(clipboard);
            }
        }
        else if(event.type == SDL_KEYUP)
        {
            stage->_KeyUpDelegate.pushArgument(event.key.keysym.scancode);
            stage->_KeyUpDelegate.pushArgument(event.key.keysym.sym);
            stage->_KeyUpDelegate.pushArgument(event.key.keysym.mod);
            stage->_KeyUpDelegate.invoke();
        }
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
        else if(event.type == SDL_FINGERDOWN)
        {
            stage->_TouchBeganDelegate.pushArgument((int)event.tfinger.fingerId);
            stage->_TouchBeganDelegate.pushArgument(event.tfinger.x*stage->stageWidth);
            stage->_TouchBeganDelegate.pushArgument(event.tfinger.y*stage->stageHeight);
            stage->_TouchBeganDelegate.invoke();
        }
        else if(event.type == SDL_FINGERUP)
        {
            stage->_TouchEndedDelegate.pushArgument((int)event.tfinger.fingerId);
            stage->_TouchEndedDelegate.pushArgument(event.tfinger.x*stage->stageWidth);
            stage->_TouchEndedDelegate.pushArgument(event.tfinger.y*stage->stageHeight);
            stage->_TouchEndedDelegate.invoke();
        }
        else if(event.type == SDL_FINGERMOTION)
        {
            stage->_TouchMovedDelegate.pushArgument((int)event.tfinger.fingerId);
            stage->_TouchMovedDelegate.pushArgument(event.tfinger.x*stage->stageWidth);
            stage->_TouchMovedDelegate.pushArgument(event.tfinger.y*stage->stageHeight);
            stage->_TouchMovedDelegate.invoke();
        }
#else
        else if(event.type == SDL_MOUSEBUTTONDOWN)
        {
            //lmLogInfo(coreLogGroup, "began %d %d %d", event.motion.which, event.motion.x, event.motion.y);
            stage->_TouchBeganDelegate.pushArgument((int)event.motion.which);
            stage->_TouchBeganDelegate.pushArgument(event.motion.x);
            stage->_TouchBeganDelegate.pushArgument(event.motion.y);
            stage->_TouchBeganDelegate.invoke();
        }
        else if(event.type == SDL_MOUSEBUTTONUP)
        {
            //lmLogInfo(coreLogGroup, "ended %d %d %d", event.motion.which, event.motion.x, event.motion.y);
            stage->_TouchEndedDelegate.pushArgument((int)event.motion.which);
            stage->_TouchEndedDelegate.pushArgument(event.motion.x);
            stage->_TouchEndedDelegate.pushArgument(event.motion.y);
            stage->_TouchEndedDelegate.invoke();
        }
        else if(event.type == SDL_MOUSEMOTION)
        {
            //lmLogInfo(coreLogGroup, "moved %d %d %d", event.motion.which, event.motion.x, event.motion.y);
            stage->_TouchMovedDelegate.pushArgument((int)event.motion.which);
            stage->_TouchMovedDelegate.pushArgument(event.motion.x);
            stage->_TouchMovedDelegate.pushArgument(event.motion.y);
            stage->_TouchMovedDelegate.invoke();
        }
#endif
        else if(event.type == SDL_MOUSEWHEEL)
        {
            //stage->_ScrollWheelYMovedDelegate.pushArgument(event.wheel.y * (event.wheel.direction == SDL_MOUSEWHEEL_NORMAL ? 1 : -1));
            stage->_ScrollWheelYMovedDelegate.pushArgument(event.wheel.y);
            stage->_ScrollWheelYMovedDelegate.invoke();
        }
        else if (event.type == SDL_WINDOWEVENT && (event.window.event == SDL_WINDOWEVENT_RESIZED || event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED))
        {
            stage->noteNativeSize(event.window.data1, event.window.data2);
            GFX::Graphics::setNativeSize(event.window.data1, event.window.data2);
        }
        else if (event.type == SDL_TEXTINPUT)
        {
            //lmLog(coreLogGroup, "SDL_TEXTINPUT %s", event.text.text);
            IMEDelegateDispatcher::shared()->dispatchInsertText(event.text.text, strlen(event.text.text));
        }
        else if (event.type == SDL_TEXTEDITING)
        {
            //lmLog(coreLogGroup, "SDL_TEXTEDITING %s %d %d", event.edit.text, event.edit.start, event.edit.length);
        }
    }
    
    /* Tick and render Loom. */
    loom_tick();
}

int
main(int argc, char *argv[])
{
    SDL_Init(SDL_INIT_EVERYTHING);

    /* Enable standard application logging */
    SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);

    int stencilSize = 1;
    int ret = SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, stencilSize);
    lmAssert(ret == 0, "SDL Error: %s", SDL_GetError());

    // Set up SDL window.
    if ((gSDLWindow = SDL_CreateWindow(
        "Loom",
        0, 0,
        100,
        100,
        SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN | SDL_WINDOW_OPENGL
        | SDL_WINDOW_ALLOW_HIGHDPI)) == NULL)
    {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_CreateWindow(): %s\n", SDL_GetError());
        exit(0);
    }
    gWindow = new Window(gSDLWindow);
    Window::setMain(gWindow);

    gContext = SDL_GL_CreateContext(gSDLWindow);
    if (!gContext) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_GL_CreateContext(): %s\n", SDL_GetError());
        exit(2);
    }

    SDL_GL_SetSwapInterval(-1);

    // And show the window with proper settings.
    SDL_SetWindowPosition(gSDLWindow, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);

    SDL_StopTextInput();

    // Initialize Loom!
    loom_appSetup();    
    supplyEmbeddedAssets();

    /* Main render loop */
    done = 0;
    
#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop(loop, 0, 1);
#else
    while (!done) loop();
#endif
    
    loom_appShutdown();
    
    exit(0);
    return 0; /* to prevent compiler warning */
}


/*
SDL_android_main.c, placed in the public domain by Sam Lantinga  3/13/14
*/
#ifdef __ANDROID__

/* Include the SDL main definition header */
#include "SDL_main.h"

/*******************************************************************************
Functions called by JNI
*******************************************************************************/
#include <jni.h>

#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>

void loom_set_javavm(void *vm);

/* Called before SDL_main() to initialize JNI bindings in SDL library */
extern "C" {

    extern void SDL_Android_Init(JNIEnv* env, jclass cls);
    void loom_setAssetManager(AAssetManager *am);

    void Java_co_theengine_loomdemo_LoomDemo_nativeSetPaths(JNIEnv* env, jobject thiz, jstring apkPath, jobject am)
    {
        const char *str = env->GetStringUTFChars(apkPath, NULL);
        //cocos2d::CCFileUtils::sharedFileUtils()->setResourcePath(str);
        env->ReleaseStringUTFChars(apkPath, str);
        loom_setAssetManager(AAssetManager_fromJava(env, am));
    }

    /* Start up the SDL app */
    int Java_org_libsdl_app_SDLActivity_nativeInit(JNIEnv* env, jclass cls, jobject array)
    {
        int i;
        int argc;
        int status;

        /* This interface could expand with ABI negotiation, callbacks, etc. */
        SDL_Android_Init(env, cls);

        JavaVM *jvm;
        env->GetJavaVM(&jvm);

        loom_set_javavm((void *) jvm);

        SDL_SetMainReady();

        /* Prepare the arguments. */

        int len = env->GetArrayLength(static_cast<jarray>(array));
        char* argv[1 + len + 1];
        argc = 0;
        /* Use the name "app_process" so PHYSFS_platformCalcBaseDir() works.
        https://bitbucket.org/MartinFelis/love-android-sdl2/issue/23/release-build-crash-on-start
        */
        argv[argc++] = SDL_strdup("app_process");
        for (i = 0; i < len; ++i) {
            const char* utf;
            char* arg = NULL;
            jstring string = static_cast<jstring>(env->GetObjectArrayElement(static_cast<jobjectArray>(array), i));
            if (string) {
                utf = env->GetStringUTFChars(string, 0);
                if (utf) {
                    arg = SDL_strdup(utf);
                    env->ReleaseStringUTFChars(string, utf);
                }
                env->DeleteLocalRef(string);
            }
            if (!arg) {
                arg = SDL_strdup("");
            }
            argv[argc++] = arg;
        }
        argv[argc] = NULL;


        /* Run the application. */

        status = SDL_main(argc, argv);

        /* Release the arguments. */

        for (i = 0; i < argc; ++i) {
            SDL_free(argv[i]);
        }

        /* Do not issue an exit or the whole application will terminate instead of just the SDL thread */
        /* exit(status); */

        return status;
    }
}


#endif /* __ANDROID__ */


/* vi: set ts=4 sw=4 expandtab: */