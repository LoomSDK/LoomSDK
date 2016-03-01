#ifdef MSVC_DEBUG_HEAP
#define _CRTDBG_MAP_ALLOC
#endif

#include <stdlib.h>

#ifdef MSVC_DEBUG_HEAP
#include <crtdbg.h>
#endif

#include <stdio.h>
#include <time.h>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif

#ifdef WIN32
#include <io.h>
#include <fcntl.h>
#endif

#include "loom/engine/loom2d/l2dStage.h"
#include "loom/engine/bindings/loom/lmApplication.h"
#include "loom/common/config/applicationConfig.h"
#include "loom/graphics/gfxGraphics.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platform.h"

#include "loom/engine/bindings/sdl/lmSDL.h"
#include "loom/engine/bindings/loom/lmGameController.h"

#include "loom/script/native/core/system/lmProcess.h"

#include <SDL.h>

extern "C"
{
    void loom_appInit();
    void loom_appSetup();
    void loom_appShutdown();
    void loom_tick();
    void supplyEmbeddedAssets();
};

SDL_Window *gSDLWindow = NULL;
SDL_GLContext gContext;

lmDefineLogGroup(coreLogGroup, "core", 1, LoomLogInfo);
lmDefineLogGroup(sdlLogGroup, "sdl", 1, LoomLogInfo);

static int gLoomExecutionDone = 0;

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
            // Terminate execution.
            gLoomExecutionDone = 1;
            continue;
        }

        // Bail on the rest if no stage!
        if(!stage)
            continue;

        // Adjust coordinates for mouse events to work properly on high dpi screens.
        if(event.type == SDL_MOUSEMOTION 
            || event.type == SDL_MOUSEBUTTONDOWN 
            || event.type == SDL_MOUSEBUTTONUP)
        {
            if (SDL_GetWindowFlags(gSDLWindow) & SDL_WINDOW_ALLOW_HIGHDPI)
            {
                // We work in drawable space but OS gives us these events in 
                // window coords - so scale. Usually it's an integer scale.
                int winW, winH;
                SDL_GetWindowSize(gSDLWindow, &winW, &winH);
                int drawableW, drawableH;
                SDL_GL_GetDrawableSize(gSDLWindow, &drawableW, &drawableH);

                if(event.type == SDL_MOUSEMOTION)
                {
                    event.motion.x *= drawableW / winW;
                    event.motion.y *= drawableH / winH;
                }
                else
                {
                    event.button.x *= drawableW / winW;
                    event.button.y *= drawableH / winH;
                }
            }            
        }

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
        else if(event.type == SDL_FINGERDOWN)
        {
            if (!stage->fingerEnabled) continue;
            stage->_TouchBeganDelegate.pushArgument((int)event.tfinger.fingerId);
            stage->_TouchBeganDelegate.pushArgument(event.tfinger.x*stage->stageWidth);
            stage->_TouchBeganDelegate.pushArgument(event.tfinger.y*stage->stageHeight);
            stage->_TouchBeganDelegate.invoke();
        }
        else if(event.type == SDL_FINGERUP)
        {
            if (!stage->fingerEnabled) continue;
            stage->_TouchEndedDelegate.pushArgument((int)event.tfinger.fingerId);
            stage->_TouchEndedDelegate.pushArgument(event.tfinger.x*stage->stageWidth);
            stage->_TouchEndedDelegate.pushArgument(event.tfinger.y*stage->stageHeight);
            stage->_TouchEndedDelegate.invoke();
        }
        else if(event.type == SDL_FINGERMOTION)
        {
            if (!stage->fingerEnabled) continue;
            stage->_TouchMovedDelegate.pushArgument((int)event.tfinger.fingerId);
            stage->_TouchMovedDelegate.pushArgument(event.tfinger.x*stage->stageWidth);
            stage->_TouchMovedDelegate.pushArgument(event.tfinger.y*stage->stageHeight);
            stage->_TouchMovedDelegate.pushArgument(SDL_BUTTON_LEFT);
            stage->_TouchMovedDelegate.invoke();
        }
        else if(event.type == SDL_MOUSEBUTTONDOWN)
        {
            if (!stage->mouseEnabled) continue;
            stage->_TouchBeganDelegate.pushArgument((int)event.button.which);
            stage->_TouchBeganDelegate.pushArgument(event.button.x);
            stage->_TouchBeganDelegate.pushArgument(event.button.y);
            stage->_TouchBeganDelegate.invoke();
        }
        else if(event.type == SDL_MOUSEBUTTONUP)
        {
            if (!stage->mouseEnabled) continue;
            stage->_TouchEndedDelegate.pushArgument((int)event.button.which);
            stage->_TouchEndedDelegate.pushArgument(event.button.x);
            stage->_TouchEndedDelegate.pushArgument(event.button.y);
            stage->_TouchEndedDelegate.invoke();
        }
        else if(event.type == SDL_MOUSEMOTION)
        {
            if (!stage->mouseEnabled) continue;
            stage->_TouchMovedDelegate.pushArgument((int)event.motion.which);
            stage->_TouchMovedDelegate.pushArgument(event.motion.x);
            stage->_TouchMovedDelegate.pushArgument(event.motion.y);
            stage->_TouchMovedDelegate.pushArgument((int)event.motion.state);
            stage->_TouchMovedDelegate.invoke();
        }
        else if(event.type == SDL_MOUSEWHEEL)
        {
            stage->_ScrollWheelYMovedDelegate.pushArgument(event.wheel.y);
            stage->_ScrollWheelYMovedDelegate.invoke();
        }
        else if (event.type == SDL_WINDOWEVENT && (event.window.event == SDL_WINDOWEVENT_RESIZED || event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED))
        {
            int winWidth = event.window.data1, winHeight = event.window.data2;
            SDL_GL_GetDrawableSize(gSDLWindow, &winWidth, &winHeight);
            stage->noteNativeSize(winWidth, winHeight);
            GFX::Graphics::setNativeSize(winWidth, winHeight);
        }
        else if (event.type == SDL_TEXTINPUT)
        {
            IMEDelegateDispatcher::shared()->dispatchInsertText(event.text.text, strlen(event.text.text));
        }
        else if (event.type == SDL_TEXTEDITING)
        {
            IMEDelegateDispatcher::shared()->dispatchShowComposition(event.text.text, strlen(event.text.text), event.edit.start, event.edit.length);
        }
        else if (event.type == SDL_CONTROLLERBUTTONDOWN)
        {
            //lmLogInfo(coreLogGroup, "Controller Button Down %d %d %d", event.cbutton.which, event.cbutton.button);
            LoomGameController::getGameController(LoomGameController::getControllerIndex(event.cbutton.which))->buttonDown(event);
        }
        else if (event.type == SDL_CONTROLLERBUTTONUP)
        {
            //lmLogInfo(coreLogGroup, "Controller Button Up %d %d %d", event.cbutton.which, event.cbutton.button);
            LoomGameController::getGameController(LoomGameController::getControllerIndex(event.cbutton.which))->buttonUp(event);
        }
        else if (event.type == SDL_CONTROLLERAXISMOTION)
        {
            //lmLog(coreLogGroup, "Controller [%d] triggered axis event.", LoomGameController::indexOfDevice(event.caxis.which));
            LoomGameController::getGameController(LoomGameController::getControllerIndex(event.cbutton.which))->axisMove(event);
        }
        else if (event.type == SDL_CONTROLLERDEVICEADDED)
        {
            int addedDevice = LoomGameController::addDevice(event.cdevice.which);
            if (addedDevice != -1)
            {
                stage->_GameControllerAddedDelegate.pushArgument(addedDevice);
                stage->_GameControllerAddedDelegate.invoke();
            }
        }
        else if (event.type == SDL_CONTROLLERDEVICEREMOVED)
        {
            int removedDevice = LoomGameController::removeDevice(event.cdevice.which);
            if (removedDevice != -1)
            {
                stage->_GameControllerRemovedDelegate.pushArgument(removedDevice);
                stage->_GameControllerRemovedDelegate.invoke();
            }
        }
        else if (event.type == SDL_WINDOWEVENT)
        {
            if (event.window.event == SDL_WINDOWEVENT_FOCUS_GAINED)
            {
                const NativeDelegate* activated = LoomApplication::getApplicationActivatedDelegate();
                activated->invoke();
            }
            else if (event.window.event == SDL_WINDOWEVENT_FOCUS_LOST)
            {
                const NativeDelegate* deactivated = LoomApplication::getApplicationDeactivatedDelegate();
                deactivated->invoke();
            }
        }
    }

    /* Tick and render Loom. */
    loom_tick();
}

static void sdlLogOutput(void* userdata, int category, SDL_LogPriority priority, const char* message)
{
    loom_logLevel_t level;
    switch (priority)
    {
        case SDL_LOG_PRIORITY_VERBOSE: return;
        case SDL_LOG_PRIORITY_DEBUG:    level = LoomLogDebug; break;
        case SDL_LOG_PRIORITY_INFO:     level = LoomLogInfo; break;
        case SDL_LOG_PRIORITY_WARN:     level = LoomLogWarn; break;
        case SDL_LOG_PRIORITY_ERROR:    level = LoomLogError; break;
        case SDL_LOG_PRIORITY_CRITICAL: level = LoomLogError; break;
        default: level = LoomLogInfo;
    }
    const char *cat;
    switch (category)
    {
        case SDL_LOG_CATEGORY_APPLICATION: cat = "application"; break;
        case SDL_LOG_CATEGORY_ERROR:       cat = "error"; break;
        case SDL_LOG_CATEGORY_SYSTEM:      cat = "system"; break;
        case SDL_LOG_CATEGORY_AUDIO:       cat = "audio"; break;
        case SDL_LOG_CATEGORY_VIDEO:       cat = "video"; break;
        case SDL_LOG_CATEGORY_RENDER:      cat = "render"; break;
        case SDL_LOG_CATEGORY_INPUT:       cat = "input"; break;
        case SDL_LOG_CATEGORY_CUSTOM:      cat = "custom"; break;
        default:                           cat = "unknown";
    }
    loom_log(&sdlLogGroup, level, "%*ssdl.%s  %s", 10 - (strlen(cat) + 4), " ", cat, message);
}

int
main(int argc, char *argv[])
{
#ifdef MSVC_DEBUG_HEAP
    // Get current flag
    int tmpFlag = _CrtSetDbgFlag(_CRTDBG_REPORT_FLAG);

    tmpFlag |= _CRTDBG_ALLOC_MEM_DF;
    tmpFlag |= _CRTDBG_LEAK_CHECK_DF;

    // Set flag to the new value.
    _CrtSetDbgFlag(tmpFlag);
#endif

#ifdef WIN32
    // When on windows, do some workarounds so our console window
    // behaves properly.
    
    // put the program name into argv[0]
    char filename[_MAX_PATH];
    GetModuleFileNameA(NULL, filename, _MAX_PATH);
    argv[0] = filename;

    bool fromRuby = false;

    for (int i = 1; i < argc; i++)
    {
        if (!stricmp(argv[i], "ProcessID") && i + 1 < argc)
        {
            fromRuby = true;

            char *pEnd;  

            long int pid = strtol (argv[i + 1], &pEnd, 10);

            LS::Process::rubyProcessId = pid;

            memmove(argv + i, argv + i + 2, (argc - i - 2)*sizeof(char*));
            argc -= 2;
            i--;
            break;
        }
    }

    LS::Process::consoleAttached = false;
    if (!fromRuby && AttachConsole(ATTACH_PARENT_PROCESS))
    {
        HANDLE consoleHandleOut = GetStdHandle(STD_OUTPUT_HANDLE);
        int fdOut = _open_osfhandle((intptr_t)consoleHandleOut, _O_TEXT);
        FILE *fpOut = _fdopen(fdOut, "w");
        *stdout = *fpOut;
        setvbuf(stdout, NULL, _IONBF, 0);

        //redirect unbuffered STDERR to the console
        HANDLE consoleHandleError = GetStdHandle(STD_ERROR_HANDLE);
        int fdError = _open_osfhandle((intptr_t)consoleHandleError, _O_TEXT);
        FILE *fpError = _fdopen(fdError, "w");
        *stderr = *fpError;
        setvbuf(stderr, NULL, _IONBF, 0);

        LS::Process::consoleAttached = true;
    }
#endif

    // Initialize logging.
    loom_log_initialize();

    LSLuaState::initCommandLine(argc, (const char**) argv);

    /* Enable standard application logging */
    SDL_LogSetAllPriority(SDL_LOG_PRIORITY_INFO);
    SDL_LogSetOutputFunction(sdlLogOutput, NULL);
    
    loom_appInit();

    loom_logLevel_t logLevel =
        LoomApplicationConfig::logLevel() == "debug" ? LoomLogDebug :
        LoomApplicationConfig::logLevel() == "verbose" ? LoomLogDebug :
        LoomApplicationConfig::logLevel() == "info" ? LoomLogInfo :
        LoomApplicationConfig::logLevel() == "warn" ? LoomLogWarn :
        LoomApplicationConfig::logLevel() == "warning" ? LoomLogWarn :
        LoomApplicationConfig::logLevel() == "error" ? LoomLogError :
        LoomApplicationConfig::logLevel() == "quiet" ? LoomLogMax :
        LoomApplicationConfig::logLevel() == "none" ? LoomLogMax :
        LoomApplicationConfig::logLevel() == "default" ? (loom_logLevel_t)0 :
        LoomApplicationConfig::logLevel() == "" ? (loom_logLevel_t)0 :
        LoomLogInvalid
    ;

    lmAssert(logLevel != LoomLogInvalid, "Invalid configured log level: %s", LoomApplicationConfig::logLevel().c_str());

    loom_log_setGlobalLevel(logLevel);


    // Log the Loom build timestamp!
    const char *buildTarget;
#ifdef LOOM_DEBUG
    buildTarget = "Debug";
#else
    buildTarget = "Release";
#endif
    lmLogInfo(coreLogGroup, "Loom (%s %s) built on " __DATE__ " at " __TIME__, SDL_GetPlatform(), buildTarget);

    /* Display SDL version */
    SDL_version compiled;
    SDL_version linked;

    SDL_VERSION(&compiled);
    SDL_GetVersion(&linked);

    lmLogDebug(coreLogGroup, "SDL compiled version: %d.%d.%d", compiled.major, compiled.minor, compiled.patch);
    lmLogDebug(coreLogGroup, "SDL linked version : %d.%d.%d", linked.major, linked.minor, linked.patch);


    SDL_Init(
        SDL_INIT_TIMER |
        SDL_INIT_VIDEO | 
        SDL_INIT_JOYSTICK |
        SDL_INIT_HAPTIC |
        SDL_INIT_GAMECONTROLLER |
        SDL_INIT_EVENTS
    );

    int ret;

    
#if LOOM_RENDERER_OPENGLES2
    ret = SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
    lmAssert(ret == 0, "SDL Error: %s", SDL_GetError());
    ret = SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    lmAssert(ret == 0, "SDL Error: %s", SDL_GetError());
#endif
    
    int stencilSize = 1;
    ret = SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, stencilSize);
    lmAssert(ret == 0, "SDL Error: %s", SDL_GetError());
    
    // Set up SDL window.
    if ((gSDLWindow = SDL_CreateWindow(
        "Loom",
        0, 0,
        100,
        100,
        SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIDDEN
#if LOOM_PLATFORM == LOOM_PLATFORM_IOS
        | SDL_WINDOW_BORDERLESS
#endif
        | SDL_WINDOW_OPENGL | SDL_WINDOW_ALLOW_HIGHDPI)) == NULL)
    {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_CreateWindow(): %s\n", SDL_GetError());
        exit(0);
    }

    gContext = SDL_GL_CreateContext(gSDLWindow);
    if (!gContext) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_GL_CreateContext(): %s\n", SDL_GetError());
        exit(2);
    }

    ret = SDL_GL_SetSwapInterval(-1);
    if (ret != 0) {
        lmLog(coreLogGroup, "Late swap tearing not supported, using vsync");
        SDL_GL_SetSwapInterval(1);
    }

    // And show the window with proper settings.
    SDL_SetWindowPosition(gSDLWindow, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);

    SDL_StopTextInput();

    // Initialize Loom!
    loom_appSetup();    
    supplyEmbeddedAssets();

    /* Main render loop */
    gLoomExecutionDone = 0;

    /* Game Controller */
    // Enable controller events
    SDL_GameControllerEventState(SDL_ENABLE);

    //Open all connected game controllers
    LoomGameController::openAll();
    
#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop(loop, 0, 1);
#else
    while (!gLoomExecutionDone) loop();
#endif

    //Close all opened game controllers before closing application
    LoomGameController::closeAll();
    loom_appShutdown();
    
#ifdef WIN32
    LS::Process::cleanupConsole();
#endif

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

    void Java_co_theengine_loomdemo_LoomDemo_nativeSetOrientation(JNIEnv* env, jobject thiz, jstring orientation)
    {
        if (Loom2D::Stage::smMainStage == NULL) return;
        const char *str = env->GetStringUTFChars(orientation, NULL);
        Loom2D::Stage::smMainStage->setOrientation(str);
        env->ReleaseStringUTFChars(orientation, str);
    }

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
