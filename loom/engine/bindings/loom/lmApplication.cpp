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

#include <time.h>

#include "lmApplication.h"

using namespace LS;

#include "loom/common/core/log.h"
#include "loom/common/assets/assetsScript.h"
#include "loom/common/platform/platformNetwork.h"
#include "loom/common/platform/platformWebView.h"
#include "loom/common/platform/platformTime.h"

#include "loom/script/common/lsLog.h"
#include "loom/script/common/lsFile.h"

#include "loom/engine/loom2d/l2dStage.h"

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformHttp.h"
#include "loom/common/platform/platformAdMob.h"

#include "loom/common/config/applicationConfig.h"

#include "loom/graphics/gfxGraphics.h"
#include "loom/script/native/core/system/lmProcess.h"

#include "loom/script/serialize/lsBinReader.h"

#include "loom/engine/bindings/sdl/lmSDL.h"
#include "loom/engine/bindings/loom/lmGameController.h"

LSLuaState     *LoomApplication::rootVM = NULL;
utByteArray    *LoomApplication::initBytes = NULL;
bool           LoomApplication::reloadQueued = false;
bool           LoomApplication::suppressAssetTriggeredReload = false;
utString       LoomApplication::bootAssembly = "bin/Main.loom";
NativeDelegate LoomApplication::event;
NativeDelegate LoomApplication::ticks;
NativeDelegate LoomApplication::assetCommandDelegate;
NativeDelegate LoomApplication::applicationActivated;
NativeDelegate LoomApplication::applicationDeactivated;

static bool initialAssetSystemLoaded = false;
static int lastCameraRequestTimestamp = 0;

// Ignore the camera requests for a 100ms after it's been triggered
const int CAMERA_REQUEST_IGNORE_TIME = 100;

lmDefineLogGroup(applicationLogGroup, "app", 1, LoomLogInfo);
lmDefineLogGroup(scriptLogGroup, "script", 1, LoomLogInfo);

extern int gLoomHeadless;

// Define the global Loom C entrypoints.
extern "C" {

extern void loomsound_shutdown();
extern atomic_int_t gLoomTicking;
extern atomic_int_t gLoomPaused;

void loom_appInit(void)
{
    LoomApplication::initMainAssembly();
}


void loom_appSetup(void)
{
    LoomApplication::initializeCoreServices();
    GFX::Graphics::initialize();
}

void loom_appPause(void)
{
    // We need to have a counter here at least for one reason. Apart from
    // background pausing, we also need to pause when the camera view is opened.
    // Without a counter, this would break for the following control flow:
    //
    //      app -> camera -> background -> camera -> app
    //
    // Using a counter ensures that we only resume when our app view is shown,
    // avoiding background OpenGL drawing crashes. 
    int ticking = atomic_decrement(&gLoomTicking);
    if (ticking != 0) return;

    // Wait for the main thread to stop all GL execution
    // if we're on a different thread
    while (platform_getCurrentThreadId() != LS::NativeDelegate::smMainThreadID &&
           atomic_load32(&gLoomPaused) != 1)
    {
        // Don't use up all the CPU
        loom_thread_sleep(0);
    }
    platform_webViewPauseAll();

    GFX::Graphics::pause();
    lmLogInfo(applicationLogGroup, "Paused");
}
    
void loom_appResume(void)
{
    // See loom_appPause for explanation of the counter
    int ticking = atomic_increment(&gLoomTicking);
    // Enforce sanity, cannot resume more times than we paused.
    // This can happen when some devices start off with a resume event and
    // some don't.
    if (ticking > 1) atomic_compareAndExchange(&gLoomTicking, ticking, 1);
    if (ticking != 1) return;
    GFX::Graphics::resume();

    platform_webViewResumeAll();

    lmLogInfo(applicationLogGroup, "Resumed");
}

void loom_appShutdown(void)
{
    GFX::Graphics::shutdown();
    LoomApplication::shutdown();

#ifdef WIN32
    LS::Process::cleanupConsole();
#endif
}

extern void loomsound_reset();

extern void loomsound_init();

// container for external package functions
typedef void (*FunctionRegisterPackage)(void);
static utArray<FunctionRegisterPackage> sExternalPackageFunctions;

/*
 * Register external package before loom_appSetup to install them immediately after core packages are installed
 * and before executing any assemblies.  This allows application specific packages to be registered which
 * depend (derive) from core engine types without binary dependencies on the core engine libraries
 */
void loom_registerExternalPackage(FunctionRegisterPackage function)
{
    if (sExternalPackageFunctions.find(function) == UT_NPOS)
    {
        sExternalPackageFunctions.push_back(function);
    }
}


static void loom_installExternalPackages()
{
    for (UTsize i = 0; i < sExternalPackageFunctions.size(); i++)
    {
        sExternalPackageFunctions[i]();
    }
}


void handleAssert()
{
    // Try to display the VM stack.
    LoomApplication::getRootVM()->triggerRuntimeError("Native Assertion - see above for full error text");
}
}

int LoomApplication::initializeTypes()
{
    void installPackageSystem();

    installPackageSystem();

#if LOOM_PLATFORM == LOOM_PLATFORM_OSX || LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    void installPackageCompiler();
    installPackageCompiler();
#endif

    void installPackageLoom();
    installPackageLoom();

    // install all externally registered packages
    loom_installExternalPackages();

    return 0;
}

static int mapScriptFile(const char *path, void **outPointer,
    long *outSize);

static void unmapScriptFile(const char *path);
static void dispatchCommand(const char *cmd);

void LoomApplication::initMainAssembly()
{
    lmAssert(!rootVM, "VM already running");
    rootVM = lmNew(NULL) LSLuaState();

    // Ensure we can load binaries through the asset system
    ensureInitialAssetSystem();

    // Open main assembly header and load the application config from it
    initBytes = rootVM->openExecutableAssembly(bootAssembly);
    rootVM->readExecutableAssemblyBinaryHeader(initBytes);
    Assembly *assembly = BinReader::loadMainAssemblyHeader();
    LoomApplication::setConfigJSON(assembly->getLoomConfig());
}

void LoomApplication::execMainAssembly()
{
    rootVM->open();

    // Read the rest of the assembly - the body
    Assembly *mainAssembly = rootVM->readExecutableAssemblyBinaryBody();
    rootVM->closeExecutableAssembly(bootAssembly, initBytes);
    initBytes = NULL;
    
    lmLogDebug(applicationLogGroup, "   o executing %s", bootAssembly.c_str());

    // Wait for asset agent if appropriate.
    if (LoomApplicationConfig::waitForAssetAgent() > 0)
    {
        lmLogDebug(applicationLogGroup, "   o Waiting %dms for asset agent connection...", LoomApplicationConfig::waitForAssetAgent());
        loom_asset_waitForConnection(LoomApplicationConfig::waitForAssetAgent());
        lmLogDebug(applicationLogGroup, "   o Connected to asset agent.");
    }

    // See if the debugger wants to connect; we want to be able to set
    // breakpoints before any code is run!
    if (LoomApplicationConfig::waitForDebugger() > 0)
    {
        lmLog(applicationLogGroup, "   o Waiting %dms for debugger connection...", LoomApplicationConfig::waitForDebugger());
        mainAssembly->connectToDebugger(LoomApplicationConfig::debuggerHost().c_str(), LoomApplicationConfig::debuggerPort());
    }

    // first see if we have a static main
    MethodInfo *smain = mainAssembly->getStaticMethodInfo("main");
    if (smain)
    {
        //GO!
        smain->invoke(NULL, 0);
    }
    else
    {
        const char *applicationTypeName = "loom.Application";
        const char *consoleApplicationTypeName = "system.application.ConsoleApplication";
        Type *applicationType = rootVM->getType(applicationTypeName);
        Type *consoleApplicationType = rootVM->getType(consoleApplicationTypeName);
        lmCheck(applicationType || consoleApplicationType, "No root application type not found in main assembly");
        
        Type *foundApp = NULL;
        Type *foundCon = NULL;

        utArray<Type *> types;
        mainAssembly->getTypes(types);
        for (UTsize i = 0; i < types.size(); i++)
        {
            Type *appType = types.at(i);
            if (applicationType && appType->isDerivedFrom(applicationType)) foundApp = appType;
            if (consoleApplicationType && appType->isDerivedFrom(consoleApplicationType)) foundCon = appType;
        }

        lmCheck(foundApp || foundCon, "Unable to find a class that extends %s or %s", applicationTypeName, consoleApplicationTypeName);

        Type *execType = foundApp ? foundApp : foundCon;

        const char *name = execType->getName();
        size_t nameLen = strlen(name);
        lmLogInfo(applicationLogGroup, "%.*s", nameLen, "---------------------------------------------");
        lmLogInfo(applicationLogGroup, "%s", name);
        lmLogInfo(applicationLogGroup, "%.*s", nameLen, "---------------------------------------------");
        int top = lua_gettop(rootVM->VM());
        lsr_createinstance(rootVM->VM(), execType);
        lualoom_getmember(rootVM->VM(), -1, "initialize");
        lua_call(rootVM->VM(), 0, 0);
        lua_settop(rootVM->VM(), top);
    }
}


void LoomApplication::reloadMainAssembly()
{
    if (!rootVM || !rootVM->VM()) return;

    lmLog(applicationLogGroup, "Reloading %s", getBootAssembly());

    // cleanup webviews
    platform_webViewDestroyAll();
    // cleanup ads
    platform_adMobDestroyAll();

    loomsound_reset();

    GFX::Graphics::shutdown();

    const NativeDelegate *onReload = rootVM->getOnReloadDelegate();
    onReload->invoke();

    NativeDelegate::invalidateLuaStateDelegates(rootVM->VM());
    NativeInterface::dumpManagedNatives(rootVM->VM());

    rootVM->close();
    lmDelete(NULL, rootVM);
    rootVM = NULL;

    GFX::Graphics::initialize();

    initMainAssembly();
    execMainAssembly();

    reloadQueued = false;
}


void LoomApplication::_reloadMainAssembly()
{
    reloadQueued = true;
}


static void dispatchCommand(const char *cmd)
{
    NativeDelegate *nd = &LoomApplication::assetCommandDelegate;

    nd->pushArgument(cmd);
    nd->invoke();
}


// The script system needs to use the asset system so we can hot load assemblies.
// These stubs point it to that system.
static int mapScriptFile(const char *path, void **outPointer,
                         long *outSize)
{
    // Skip relative path prefix, TODO: Make this cleaner
    if ((path[0] == '.') && (path[1] == '/'))
    {
        path += 2;
    }

    loom_asset_script_t *scriptAsset = (loom_asset_script_t *)loom_asset_lock(path, LATScript, 1);
    int                 resCode      = 0;

    if (!scriptAsset)
    {
        lmLogWarn(applicationLogGroup, "Failed to map asset for script: '%s'", path);

        *outPointer = NULL;
        if (outSize)
        {
            *outSize = 0;
        }
        resCode = 0;
    }
    else
    {
        lmLogDebug(applicationLogGroup, "Mapped asset for script: '%s'", path);
        *outPointer = scriptAsset->bits;
        *outSize    = (long)scriptAsset->length;
        resCode     = 1;
    }

    return resCode;
}


static void unmapScriptFile(const char *path)
{
    lmLogDebug(applicationLogGroup, "Unmapping asset %s", path);

    // Skip relative path prefix, TODO: Make this cleaner
    if ((path[0] == '.') && (path[1] == '/'))
    {
        path += 2;
    }

    loom_asset_unlock(path);
}

void LoomApplication::ensureInitialAssetSystem()
{
    if (initialAssetSystemLoaded) return;
    initialAssetSystemLoaded = true;

    // Initialize asset system. This has to be done first thing
    // so the assembly header can be read for logging configuration.
    lmLogDebug(applicationLogGroup, "Initializing asset system...");
    lmLogDebug(applicationLogGroup, "   o assets");
    loom_asset_initialize(".");
    loom_asset_setCommandCallback(dispatchCommand);

    lmLogDebug(applicationLogGroup, "   o stringtable");
    stringtable_initialize();

    LS::LSFileInitialize(mapScriptFile, unmapScriptFile);
}

int LoomApplication::initializeCoreServices()
{
    // Mark the main thread for NativeDelegates.
    NativeDelegate::markMainThread();

    // Initialize services.
    lmLogDebug(applicationLogGroup, "Initializing services...");

    // Set up assert handling callback.
    lmLogDebug(applicationLogGroup, "   o asserts");
    loom_setAssertCallback(handleAssert);

    lmLogDebug(applicationLogGroup, "   o performance");
    performance_initialize();

    lmLogDebug(applicationLogGroup, "   o RNG");
    srand((unsigned int)time(NULL));

    lmLogDebug(applicationLogGroup, "   o time");
    platform_timeInitialize();

    lmLogDebug(applicationLogGroup, "   o types");
    initializeTypes();

    lmLogDebug(applicationLogGroup, "   o network");
    loom_net_initialize();

    lmLogDebug(applicationLogGroup, "   o http");
    platform_HTTPInit();


    lmLogDebug(applicationLogGroup, "   o sound");
    loomsound_init();

    LoomGameController::init();

    // Initialize script hooks.
    LS::LSLogInitialize((LS::FunctionLog)loom_log, (void *)&scriptLogGroup, LoomLogDebug, LoomLogInfo, LoomLogWarn, LoomLogError);
    LS::NativeTypeBase::initialize();

    // Set up listener for changes to the boot assembly.
    suppressAssetTriggeredReload = true;

    loom_asset_subscribe(bootAssembly.c_str(), LoomApplication::__handleMainAssemblyUpdate, NULL, 0);

    // And fire script execution.
    execMainAssembly();
    suppressAssetTriggeredReload = false;

    return 0;
}

void LoomApplication::shutdown()
{
    loomsound_shutdown();

    //Close all opened game controllers before closing application
    LoomGameController::shutdown();

    platform_HTTPCleanup();

    // Shut down application subsystems.
    loom_asset_shutdown();
} 


void LoomApplication::reloadAssets()
{
    loom_asset_reloadAll();
}


bool LoomApplication::compilerEnabled()
{
#if LOOM_PLATFORM == LOOM_PLATFORM_IOS || LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
    return false;

#else
    return true;
#endif
}


const utString& LoomApplication::getConfigJSON()
{
    return LoomApplicationConfig::getApplicationConfigJSON();
}

void LoomApplication::setConfigJSON(const utString &configJSON)
{
    LoomApplicationConfig::parseApplicationConfig(configJSON);
    Loom2D::Stage::sizeDirty = true;
    Loom2D::Stage::visDirty = true;
    Loom2D::Stage::initFromConfig();
}



void LoomApplication::__handleMainAssemblyUpdate(void *payload, const char *name)
{
    // Don't reload unless we've finished initializing the VM at least once.
    if (suppressAssetTriggeredReload)
    {
        return;
    }

    lmLogDebug(applicationLogGroup, "Restarting VM due to modification to '%s'", name);
    _reloadMainAssembly();
}


struct LoomApplicationGenericEventCallbackNote
{
    LoomGenericEventCallback cb;
    void                     *userData;
};

static utArray<LoomApplicationGenericEventCallbackNote> gNativeGenericCallbacks;

void LoomApplication::fireGenericEvent(const char *type, const char *payload)
{
    if (strcmp(type, "cameraRequest") == 0)
    {
        int currentTime = platform_getMilliseconds();
        int prevTime = lastCameraRequestTimestamp;
        lastCameraRequestTimestamp = currentTime;

        if (currentTime > prevTime && currentTime - prevTime < CAMERA_REQUEST_IGNORE_TIME)
            return;
    }

    event.pushArgument(type);
    event.pushArgument(payload);
    event.invoke();

    // Also do C++ callbacks.
    for (unsigned int i = 0; i < gNativeGenericCallbacks.size(); i++)
    {
        LoomApplicationGenericEventCallbackNote &note = gNativeGenericCallbacks[i];
        lmAssert(note.cb, "Callback should not be null");
        note.cb(note.userData, type, payload);
    }

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
    
    loomJniMethodInfo eventCallback;
    LoomJni::getStaticMethodInfo(eventCallback,
        "co/theengine/loomplayer/LoomPlayer",
        "handleGenericEvent",
        "(Ljava/lang/String;Ljava/lang/String;)V");
    JNIEnv *env = eventCallback.getEnv();
    if (env == NULL) {
        __android_log_print(ANDROID_LOG_WARN, "LoomJNI", "fireGenericEvent called before JNI init");
        return;
    }
    jstring jType    = env->NewStringUTF(type);
    jstring jPayload = env->NewStringUTF(payload);
    env->CallStaticVoidMethod(eventCallback.classID, eventCallback.methodID, jType, jPayload);
    env->DeleteLocalRef(jType);
    env->DeleteLocalRef(jPayload);
    env->DeleteLocalRef(eventCallback.classID);
#endif
}


#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
extern "C"
{
void Java_co_theengine_loomplayer_LoomPlayer_internalTriggerGenericEvent(JNIEnv *env, jobject thiz, jstring type, jstring payload)
{
    const char *typeString    = env->GetStringUTFChars(type, 0);
    const char *payloadString = env->GetStringUTFChars(payload, 0);

    LoomApplication::fireGenericEvent(typeString, payloadString);

    env->ReleaseStringUTFChars(type, typeString);
    env->ReleaseStringUTFChars(payload, payloadString);
}
}
#endif

void LoomApplication::listenForGenericEvents(LoomGenericEventCallback cb, void *userData)
{
    LoomApplicationGenericEventCallbackNote lagecn;

    lagecn.cb       = cb;
    lagecn.userData = userData;
    gNativeGenericCallbacks.push_back(lagecn);
}


int registerLoomApplication(lua_State *L)
{
    beginPackage(L, "loom")

       .beginClass<LoomApplication>("Application")

       .addStaticMethod("reloadMainAssembly", &LoomApplication::_reloadMainAssembly)

       .addStaticMethod("compilerEnabled", &LoomApplication::compilerEnabled)

       .addStaticMethod("getBootAssembly", &LoomApplication::getBootAssembly)

       .addStaticProperty("assetCommandDelegate", &LoomApplication::getAssetCommandDelegate)
       .addStaticProperty("applicationActivated", &LoomApplication::getApplicationActivatedDelegate)
       .addStaticProperty("applicationDeactivated", &LoomApplication::getApplicationDeactivatedDelegate)
       .addStaticProperty("ticks", &LoomApplication::getTicksDelegate)

       .addStaticProperty("event", &LoomApplication::getEventDelegate)
       .addStaticMethod("fireGenericEvent", &LoomApplication::fireGenericEvent)

       .addStaticProperty("loomConfigJSON", &LoomApplicationConfig::getApplicationConfigJSON)
       .addStaticMethod("setConfigJSON", &LoomApplication::setConfigJSON)

       .addStaticProperty("version", &LoomApplicationConfig::version)

       .endClass()

       .endPackage();

    return 0;
}


void installLoomApplication()
{
    LOOM_DECLARE_NATIVETYPE(LoomApplication, registerLoomApplication);
}
