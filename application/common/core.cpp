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
#include "loom/common/platform/platformMobile.h"
#include "loom/common/core/telemetry.h"

#include "loom/engine/bindings/sdl/lmSDL.h"
#include "loom/engine/bindings/loom/lmGameController.h"

#include "loom/script/native/core/system/lmProcess.h"

#include <SDL.h>

#include "optionparser/optionparser.h"

extern "C"
{
    void loom_appInit();
    void loom_appSetup();
    void loom_appShutdown();
    void loom_appPause();
    void loom_appResume();
    void loom_tick();
    void supplyEmbeddedAssets();
};

SDL_Window *gSDLWindow = NULL;
SDL_GLContext gContext;
int gLoomHeadless = 0;

#define LOOM_PLAYER_VERSION "1.1.0"

#define SDL_LOG_EVENTS 0
lmDefineLogGroup(coreLogGroup, "core", 1, LoomLogInfo);
lmDefineLogGroup(sdlLogGroup, "sdl", 1, LoomLogInfo);
#define lmLogSDL(level, group, message) lmLogLevel(level, group, "%s", message);
#define lmLogSDLGroup(loggedLevel, loggedCategory, groupCategory, postfix) \
    static lmDefineLogGroup(sdl ## _ ## postfix ## LogGroup, "sdl." #postfix, 1, LoomLogInfo); \
    if (loggedCategory == groupCategory) { logged = true; lmLogSDL(loggedLevel, sdl ## _ ## postfix ## LogGroup, message); } \

static int gLoomExecutionDone = 0;
static int sdlFocusGained = 0;

static const char* getSDLEventName(const SDL_Event* event)
{
    switch (event->type) {
        case SDL_APP_DIDENTERBACKGROUND: return "SDL_APP_DIDENTERBACKGROUND"; break;
        case SDL_APP_WILLENTERBACKGROUND: return "SDL_APP_WILLENTERBACKGROUND"; break;
        case SDL_APP_DIDENTERFOREGROUND: return "SDL_APP_DIDENTERFOREGROUND"; break;
        case SDL_APP_WILLENTERFOREGROUND: return "SDL_APP_WILLENTERFOREGROUND"; break;

        case SDL_WINDOWEVENT: switch (event->window.event) {
            case SDL_WINDOWEVENT_NONE: return "SDL_WINDOWEVENT_NONE"; break;
            case SDL_WINDOWEVENT_SHOWN: return "SDL_WINDOWEVENT_SHOWN"; break;
            case SDL_WINDOWEVENT_HIDDEN: return "SDL_WINDOWEVENT_HIDDEN"; break;
            case SDL_WINDOWEVENT_EXPOSED: return "SDL_WINDOWEVENT_EXPOSED"; break;
            case SDL_WINDOWEVENT_MOVED: return "SDL_WINDOWEVENT_MOVED"; break;
            case SDL_WINDOWEVENT_RESIZED: return "SDL_WINDOWEVENT_RESIZED"; break;
            case SDL_WINDOWEVENT_SIZE_CHANGED: return "SDL_WINDOWEVENT_SIZE_CHANGED"; break;
            case SDL_WINDOWEVENT_MINIMIZED: return "SDL_WINDOWEVENT_MINIMIZED"; break;
            case SDL_WINDOWEVENT_MAXIMIZED: return "SDL_WINDOWEVENT_MAXIMIZED"; break;
            case SDL_WINDOWEVENT_RESTORED: return "SDL_WINDOWEVENT_RESTORED"; break;
            case SDL_WINDOWEVENT_ENTER: return "SDL_WINDOWEVENT_ENTER"; break;
            case SDL_WINDOWEVENT_LEAVE: return "SDL_WINDOWEVENT_LEAVE"; break;
            case SDL_WINDOWEVENT_FOCUS_GAINED: return "SDL_WINDOWEVENT_FOCUS_GAINED"; break;
            case SDL_WINDOWEVENT_FOCUS_LOST: return "SDL_WINDOWEVENT_FOCUS_LOST"; break;
            case SDL_WINDOWEVENT_CLOSE: return "SDL_WINDOWEVENT_CLOSE"; break;
        }; break;
    }
    return "N/A";
}

void loop()
{
    Telemetry::beginTick();

    LOOM_PROFILE_START(loom_events);

    SDL_Event event;

    // Get the stage as it will receive most events.
    Loom2D::Stage *stage = Loom2D::Stage::smMainStage;

    /* Check for events */
    while (stage && SDL_PollEvent(&event))
    {
#if SDL_LOG_EVENTS
        lmLogWarn(coreLogGroup, "SDL event from queue 0x%x, %s", event.type, getSDLEventName(&event));
#endif


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

            //lmLog(coreLogGroup, "keydown %d %d", key.sym, SDLK_AC_BACK);
            if (key.sym == SDLK_AC_BACK)
            {
                stage->_BackKeyDelegate.invoke();
            }
            else
            {
                // Handle a key!
                stage->_KeyDownDelegate.pushArgument(key.scancode);
                stage->_KeyDownDelegate.pushArgument(key.sym);
                stage->_KeyDownDelegate.pushArgument(key.mod);
                stage->_KeyDownDelegate.invoke();
                //lmLog(coreLogGroup, "keydown %d %d", key.sym, SDLK_BACKSPACE);
                if (SDL_IsTextInputActive() && (key.mod & ~KMOD_CAPS & ~KMOD_NUM) == KMOD_NONE && key.sym == SDLK_BACKSPACE)
                {
                    IMEDelegateDispatcher::shared()->dispatchDeleteBackward();
                }
                if (key.mod & KMOD_CTRL && key.sym == SDLK_v) {
                    char* clipboard = SDL_GetClipboardText();
                    IMEDelegateDispatcher::shared()->dispatchInsertText(clipboard, strlen(clipboard));
                    SDL_free(clipboard);
                }
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
            // This is a workaround for the SDL_WINDOWEVENT_FOCUS_GAINED event
            // not firing at startup on some platforms, due
            // to the SDL video/windows not being initialized yet or similar.
            if (event.window.event == SDL_WINDOWEVENT_FOCUS_GAINED || sdlFocusGained == 0 && event.window.event == SDL_WINDOWEVENT_SHOWN)
            {
                sdlFocusGained++;
                if (sdlFocusGained == 1) {
                    const NativeDelegate* activated = LoomApplication::getApplicationActivatedDelegate();
                    activated->invoke();
                }
                else if (sdlFocusGained > 1)
                {
                    sdlFocusGained = 1;
                }
            }
            else if (event.window.event == SDL_WINDOWEVENT_FOCUS_LOST)
            {
                sdlFocusGained--;
                if (sdlFocusGained < -1) sdlFocusGained = -1;
                const NativeDelegate* deactivated = LoomApplication::getApplicationDeactivatedDelegate();
                deactivated->invoke();
            }
        }
    }

    LOOM_PROFILE_END(loom_events);

    /* Tick and render Loom. */
    loom_tick();

    LOOM_PROFILE_ZERO_CHECK()

    Telemetry::endTick();
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

    bool logged = false;

    lmLogSDLGroup(level, category, SDL_LOG_CATEGORY_APPLICATION, app);
    lmLogSDLGroup(level, category, SDL_LOG_CATEGORY_ERROR, error);
    lmLogSDLGroup(level, category, SDL_LOG_CATEGORY_SYSTEM, system);
    lmLogSDLGroup(level, category, SDL_LOG_CATEGORY_AUDIO, audio);
    lmLogSDLGroup(level, category, SDL_LOG_CATEGORY_VIDEO, video);
    lmLogSDLGroup(level, category, SDL_LOG_CATEGORY_RENDER, render);
    lmLogSDLGroup(level, category, SDL_LOG_CATEGORY_INPUT, input);
    lmLogSDLGroup(level, category, SDL_LOG_CATEGORY_CUSTOM, custom);

    if (!logged) lmLogSDL(level, sdlLogGroup, message);
}

// This filter is required for events that are high priority and
// cannot wait in the event queue. Note that this can get called from
// a different thread, so thread safety should be taken into account
static int sdlPriorityEvents(void* userdata, SDL_Event* event)
{
#if SDL_LOG_EVENTS
    lmLogWarn(coreLogGroup, "SDL event 0x%x, %s", event->type, getSDLEventName(event));
#endif

    switch (event->type) {
        // If we don't pause immediately, the app could get killed
        // due to misbehaved processing / OpenGL activity
        case SDL_APP_WILLENTERBACKGROUND:
            loom_appPause();
            return false;

        // SDL_APP_WILLENTERFOREGROUND seems like a closer fit, but it doesn't
        // work with the iOS notification/control center
        case SDL_APP_DIDENTERFOREGROUND:
            loom_appResume();
            return false;

        case SDL_QUIT:
        case SDL_APP_TERMINATING:
            // Terminate execution.
            gLoomExecutionDone = 1;
            return false;
    }
    return true;
}

enum  OptionIndex { UNKNOWN, VERSION, HELP, FROM_RUBY, APP_TYPE, LOOP };
enum  OptionType { DISABLE, ENABLE, OTHER };
const option::Descriptor usage[] =
{
    { UNKNOWN,   OTHER, "" , "",          option::Arg::None,     "USAGE: LoomPlayer [options] [loom-file-or-project-dir] [app-arguments]\n"
                                                                 "\n"
                                                                 "Options:" },
    { VERSION,   OTHER, "v", "version",   option::Arg::None,     "  --version, -v  \tPrint version information and exit." },
    { HELP,      OTHER, "h", "help",      option::Arg::None,     "  --help, -h  \tPrint usage and exit." },
    { FROM_RUBY, OTHER, "",  "from-ruby", option::Arg::None,     "  --from-ruby  \tDefined when running from the Ruby asset agent." },
    { APP_TYPE,  OTHER, "",  "app-type",  option::Arg::Optional, "  --app-type  \tOverride the application type, can be either 'console' or 'gui'." },
    { LOOP,      OTHER, "",  "loop",      option::Arg::Optional, "  --loop  \t" },
    { UNKNOWN,   OTHER, "",  "",          option::Arg::None,     0 },
    { UNKNOWN,   OTHER, "",  "",          option::Arg::None,     "\n"
                                                                 "Examples:\n"
                                                                 "  LoomPlayer  \tLaunches project in the working directory.\n"
                                                                 "  LoomPlayer .  \tSame as above.\n"
                                                                 "  LoomPlayer path/to/project/dir/  \tLaunches project located in path/to/project/dir/.\n"
                                                                 "  LoomPlayer path/to/assembly/Main.loom  \tLaunches the specified .loom assembly.\n"
    },
    { 0,0,0,0,0,0 }
};

static utByteArray usageBuffer;

static void printUsageFlush()
{
    UTsize size = usageBuffer.getSize();
    if (size == 0) return;
    usageBuffer.setPosition(size - 1);
    char last = usageBuffer.readUnsignedByte();
    if (last == '\n')
    {
        usageBuffer.resize(size - 1);
    }
    platform_debugOut("%.*s", usageBuffer.getSize(), usageBuffer.getDataPtr());
    usageBuffer.resize(0);
}

static void printOption(const char *msg, int size)
{
    usageBuffer.writeUTFInternal(msg, size);
    if (msg[size - 1] == '\n') printUsageFlush();
}

static void printUsage()
{
    usageBuffer.reserve(256);
    option::printUsage(printOption, usage);
    printUsageFlush();
}

static int getSDLWindowPosition(int appConfigPos) {
    return
        appConfigPos == LoomApplicationConfig::POSITION_UNDEFINED ||
        appConfigPos == LoomApplicationConfig::POSITION_INVALID ? SDL_WINDOWPOS_UNDEFINED :
        appConfigPos == LoomApplicationConfig::POSITION_CENTERED ? SDL_WINDOWPOS_CENTERED :
        appConfigPos;
}

#define usageError(format, ...) { platform_error("Error: " format "\n\n", ##__VA_ARGS__); printUsage(); return 1; }

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
#endif


    argc -= (argc>0); argv += (argc>0); // skip program name argv[0] if present
    option::Stats  stats(usage, argc, argv);

    option::Option* options = (option::Option*)calloc(stats.options_max, sizeof(option::Option));
    option::Option* buffer = (option::Option*)calloc(stats.buffer_max, sizeof(option::Option));

    option::Parser parse(usage, argc, argv, options, buffer);

    if (parse.error()) usageError("Error parsing arguments");

    if (options[VERSION]) {
        platform_debugOut("%s", LOOM_PLAYER_VERSION);
        return 0;
    }

    if (options[HELP]) {
        printUsage();
        return 0;
    }

    for (option::Option* opt = options[UNKNOWN]; opt; opt = opt->next())
        platform_debugOut("Unknown option: %s", opt->name);

    int coreOptions = 0;

    utString assemblyPath = ".";

    if (parse.nonOptionsCount() > 0) {
        assemblyPath = parse.nonOption(0);
    }
    if (!assemblyPath.endsWith(".loom")) assemblyPath += "/bin/Main.loom";
    if (!platform_mapFileExists(assemblyPath.c_str())) usageError("Invalid path to Loom assembly (.loom): %s", assemblyPath.c_str());
    LoomApplication::setBootAssembly(assemblyPath);
    coreOptions++;

#ifdef WIN32

    LS::Process::consoleAttached = false;

    if (!options[FROM_RUBY] && AttachConsole(ATTACH_PARENT_PROCESS))
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

    LSSetExitHandler(loom_appShutdown);

    // Initialize logging
    loom_log_initialize();
    loom_log_buffer();

    LSLuaState::initCommandLine(parse.nonOptionsCount() - coreOptions, parse.nonOptions() + coreOptions);

    /* Enable standard application logging */
    SDL_LogSetAllPriority(SDL_LOG_PRIORITY_INFO);
    SDL_LogSetOutputFunction(sdlLogOutput, NULL);

    loom_appInit();

    gLoomHeadless = (options[APP_TYPE] ? options[APP_TYPE].arg : LoomApplicationConfig::applicationType()) == "console";
    if (gLoomHeadless) loom_log_setGlobalLevel(LoomLogWarn);

    loom_log_buffer_flush();

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

    if (gLoomHeadless) SDL_setenv("SDL_VIDEODRIVER", "dummy", 1);

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

#if LOOM_PLATFORM == LOOM_PLATFORM_IOS
    // Check for SDL_DROPFILE event - this is to check if the app was opened
    // using a custom URL scheme
    SDL_Event e;
    SDL_PumpEvents();
    if (SDL_PeepEvents(&e, 1, SDL_GETEVENT, SDL_DROPFILE, SDL_DROPFILE))
    {
        if (e.type == SDL_DROPFILE)
        {
            platform_setOpenURLQueryData(e.drop.file);
            SDL_free(e.drop.file);
        }
    }
#endif

    // Set event callback for events that cannot wait
    SDL_SetEventFilter(sdlPriorityEvents, NULL);

    if (!gLoomHeadless) {

        int stencilSize = 1;
        ret = SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, stencilSize);
        lmAssert(ret == 0, "Unable to set OpenGL stencil size to %d: %s", stencilSize, SDL_GetError());

        Uint32 windowFlags = 0;

        windowFlags |= SDL_WINDOW_HIDDEN;
        windowFlags |= SDL_WINDOW_OPENGL | SDL_WINDOW_ALLOW_HIGHDPI;

#if LOOM_PLATFORM == LOOM_PLATFORM_IOS
        windowFlags |= SDL_WINDOW_BORDERLESS;
#endif

        if (LoomApplicationConfig::displayMaximized()) windowFlags |= SDL_WINDOW_MAXIMIZED;
        if (LoomApplicationConfig::displayMinimized()) windowFlags |= SDL_WINDOW_MINIMIZED;
        if (LoomApplicationConfig::displayResizable()) windowFlags |= SDL_WINDOW_RESIZABLE;
        if (LoomApplicationConfig::displayBorderless()) windowFlags |= SDL_WINDOW_BORDERLESS;
        utString displayMode = LoomApplicationConfig::displayMode();

        windowFlags |=
            displayMode == "window" ? 0 :
            displayMode == "fullscreen" ? SDL_WINDOW_FULLSCREEN :
            displayMode == "fullscreenWindow" ? SDL_WINDOW_FULLSCREEN_DESKTOP :
            0;

        // Set up SDL window.
        if ((gSDLWindow = SDL_CreateWindow(
            "Loom",
            getSDLWindowPosition(LoomApplicationConfig::displayX()),
            getSDLWindowPosition(LoomApplicationConfig::displayY()),
            LoomApplicationConfig::displayWidth(),
            LoomApplicationConfig::displayHeight(),
            windowFlags
        )) == NULL)
        {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_CreateWindow(): %s\n", SDL_GetError());
            exit(1);
        }

        gContext = SDL_GL_CreateContext(gSDLWindow);
        if (!gContext) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_GL_CreateContext(): %s\n", SDL_GetError());
            exit(2);
        }

        ret = SDL_GL_SetSwapInterval(-1);
        if (ret != 0) {
            lmLogDebug(coreLogGroup, "Late swap tearing not supported, using vsync");
            SDL_GL_SetSwapInterval(1);
        }
    }

    SDL_StopTextInput();

    // Initialize Loom!
    loom_appSetup();
    supplyEmbeddedAssets();

    /* Main render loop */
    if (gLoomHeadless && !options[LOOP]) gLoomExecutionDone = 1;

#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop(loop, 0, 1);
#else
    while (!gLoomExecutionDone) loop();
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

    void Java_co_theengine_loomplayer_LoomPlayer_nativeSetOrientation(JNIEnv* env, jobject thiz, jstring orientation)
    {
        if (Loom2D::Stage::smMainStage == NULL) return;
        const char *str = env->GetStringUTFChars(orientation, NULL);
        Loom2D::Stage::smMainStage->setOrientation(str);
        env->ReleaseStringUTFChars(orientation, str);
    }

    void Java_co_theengine_loomplayer_LoomPlayer_nativeSetPaths(JNIEnv* env, jobject thiz, jstring apkPath, jobject am)
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
