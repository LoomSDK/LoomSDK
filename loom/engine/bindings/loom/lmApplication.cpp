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

LSLuaState     *LoomApplication::rootVM = NULL;
utByteArray    *LoomApplication::initBytes = NULL;
bool           LoomApplication::reloadQueued = false;
bool           LoomApplication::suppressAssetTriggeredReload = false;
utString       LoomApplication::bootAssembly = "Main.loom";
NativeDelegate LoomApplication::event;
NativeDelegate LoomApplication::ticks;
NativeDelegate LoomApplication::assetCommandDelegate;
NativeDelegate LoomApplication::applicationActivated;
NativeDelegate LoomApplication::applicationDeactivated;

static bool initialAssetSystemLoaded = false;


lmDefineLogGroup(applicationLogGroup, "app", 1, LoomLogInfo);
lmDefineLogGroup(scriptLogGroup, "script", 1, LoomLogInfo);

// Define the global Loom C entrypoints.
extern "C" {

extern void loomsound_shutdown();

void loom_appInit(void)
{
    LoomApplication::initMainAssembly();
}


void loom_appSetup(void)
{
    LoomApplication::initializeCoreServices();
    GFX::Graphics::initialize();
}


void loom_appShutdown(void)
{
    GFX::Graphics::shutdown();
    LoomApplication::shutdown();
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
    LoomApplicationConfig::parseApplicationConfig(assembly->getLoomConfig());
}

void LoomApplication::execMainAssembly()
{
    rootVM->open();

    // Read the rest of the assembly - the body
    Assembly *mainAssembly = rootVM->readExecutableAssemblyBinaryBody();
    rootVM->closeExecutableAssembly(bootAssembly, false, initBytes);
    initBytes = NULL;
    
    lmLogDebug(applicationLogGroup, "   o executing %s", bootAssembly.c_str());

    Loom2D::Stage::updateFromConfig();

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
        // look for a class derived from LoomApplication in the main assembly
        Type *loomAppType = rootVM->getType("loom.Application");
        if (loomAppType)
        {
            utArray<Type *> types;
            mainAssembly->getTypes(types);
            for (UTsize i = 0; i < types.size(); i++)
            {
                Type *appType = types.at(i);
                if (appType->isDerivedFrom(loomAppType))
                {
                    const char *name = appType->getName();
                    size_t nameLen = strlen(name);
                    lmLogInfo(applicationLogGroup, "%.*s", nameLen, "---------------------------------------------");
                    lmLogInfo(applicationLogGroup, "%s", name);
                    lmLogInfo(applicationLogGroup, "%.*s", nameLen, "---------------------------------------------");
                    int top = lua_gettop(rootVM->VM());
                    lsr_createinstance(rootVM->VM(), appType);
                    lualoom_getmember(rootVM->VM(), -1, "initialize");
                    lua_call(rootVM->VM(), 0, 0);
                    lua_settop(rootVM->VM(), top);
                }
            }
        }
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

    // Initialize script hooks.
    LS::LSLogInitialize((LS::FunctionLog)loom_log, (void *)&scriptLogGroup, LoomLogDebug, LoomLogInfo, LoomLogWarn, LoomLogError);
    LS::NativeTypeBase::initialize();
    //LS::LSLogSetLevel(LS::LSLogError);

    // Set up listener for changes to the boot assembly.
    suppressAssetTriggeredReload = true;
    loom_asset_subscribe(utString("bin/" + bootAssembly).c_str(), LoomApplication::__handleMainAssemblyUpdate, NULL, 0);

    // And fire script executoin.
    execMainAssembly();
    suppressAssetTriggeredReload = false;

    return 0;
}

void LoomApplication::shutdown()
{
    loomsound_shutdown();

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

       .addStaticProperty("version", &LoomApplicationConfig::version)

       .endClass()

       .endPackage();

    return 0;
}


void installLoomApplication()
{
    LOOM_DECLARE_NATIVETYPE(LoomApplication, registerLoomApplication);
}
