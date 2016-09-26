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

#include <stdio.h>

#include "telemetryServer.h"

#include "loom/common/platform/platformNetwork.h"
#include "loom/common/platform/platformIO.h"
#include "loom/common/platform/platformFile.h"
#include "loom/common/platform/platformThread.h"
#include "loom/common/platform/platformTime.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/stringTable.h"
#include "loom/common/utils/fourcc.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/common/assets/assetProtocol.h"

#include "loom/common/core/allocator.h"

// For realpath
#if LOOM_PLATFORM_IS_APPLE == 1 || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#include <sys/param.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <signal.h>
#else
#include <direct.h>
#define MAXPATHLEN    4096 // Arbitrary, is this big enough?
#define getcwd        _getcwd
#endif


// These stubs are required for LoomCommon to work without LoomScript for now
void loom_asset_notifyPendingCountChange() {};
namespace LS {
    class NativeDelegate
    {
        public: static int smMainThreadID;
    };
    int NativeDelegate::smMainThreadID = 0xBAADF00D;
}

// Delay in milliseconds between checks of file system.
const int gFileCheckInterval = 100;

static const int socketPingTimeoutMs = 6000;

lmDefineLogGroup(gAssetAgentLogGroup, "agent", 1, LoomLogInfo);

// The asset agent maintains a cache of all the local files and scans from time
// to time for changes. When a change is detected, the file is streamed to any
// connected games. The following structures are used to track and describe this
// state.

// State of a file.
struct FileEntry
{
    utString  path;
    char      hash[40]; // sha1
    long long modifiedTime;
    long long size;
};

// Description of a change related to a file.
struct FileEntryDelta
{
    enum
    {
        Added, Removed, Modified
    }
             action;
    utString path;
};

// Used to let files settle; first we note a modification to a file then once
// its state has been the same for a little while, we issue a FileEntryDelta.
struct FileModificationNote
{
    FileModificationNote()
    {
        onlyForClient = -1;
    }

    StringTableEntry path;
    long long        lastSeenTime;
    int              onlyForClient; // If not -1, then only send to the specified client.
};

// Thread-safe state for connected clients.
static MutexHandle gActiveSocketsMutex = NULL;
static utArray<AssetProtocolHandler *> gActiveHandlers;

// Threads for talking to socket and watching files.
static ThreadHandle gFileWatcherThread    = NULL;
static ThreadHandle gSocketListenerThread = NULL;

// Thread-safe state for modified files we are waiting to settle.
static MutexHandle            gFileScannerLock = NULL;
utArray<FileModificationNote> gPendingModifications;

// Handle to our listen sock.
static loom_socketId_t gListenSocket = 0;

// Callback/binding state.
typedef void (*IdleCallback)();
typedef void (*LogCallback)(const char *entry);
typedef void (*FileChangeCallback)(const char *path);

static int          gQuitFlag           = 0;
static ThreadHandle gCallbackLock       = NULL;
LogCallback         gLogCallback        = NULL;
FileChangeCallback  gFileChangeCallback = NULL;

static utHashTable<utFastStringHash, utString> gOptions;

// Queue for callbacks.
enum CallbackQueueNoteType
{
    QNT_Log,
    QNT_Change
};

struct CallbackQueueNote
{
    CallbackQueueNoteType type;

    // Owned by the note - delete it when you're done!
    utString text;
};

utList<CallbackQueueNote *> gCallbackQueue;

static void enqueueLogCallback(const char *msg)
{
    CallbackQueueNote *cqn = lmNew(NULL) CallbackQueueNote();

    cqn->type = QNT_Log;
    cqn->text = utString(msg);

    loom_mutex_lock(gCallbackLock);
    gCallbackQueue.push_back(cqn);
    loom_mutex_unlock(gCallbackLock);
}


static void enqueueFileChangeCallback(const char *path)
{
    CallbackQueueNote *cqn = lmNew(NULL) CallbackQueueNote();

    cqn->type = QNT_Change;
    cqn->text = utString(path);

    loom_mutex_lock(gCallbackLock);
    gCallbackQueue.push_back(cqn);
    loom_mutex_unlock(gCallbackLock);
}


static CallbackQueueNote *dequeueCallback()
{
    CallbackQueueNote *cqn = NULL;

    loom_mutex_lock(gCallbackLock);

    if (gCallbackQueue.begin() == NULL)
    {
        cqn = NULL;
    }
    else
    {
        cqn = gCallbackQueue.front();
        gCallbackQueue.pop_front();
    }

    loom_mutex_unlock(gCallbackLock);

    return cqn;
}


// Convert a path into its canonical form.
static int makeAssetPathCanonical(const char *pathIn, char pathOut[MAXPATHLEN])
{
    // First thing, safe pathOut.
    pathOut[0] = 0;

    char cwd[MAXPATHLEN];
    char* cwdres = getcwd(cwd, MAXPATHLEN);

    char* resolvedPathPtr = NULL;
    // Note, man page suggests that realpath won't work right for
    // non-existant folders/files.
    if (cwdres != NULL)
    {
        resolvedPathPtr = platform_realpath(pathIn, NULL);
    }

    if (resolvedPathPtr == NULL)
    {
        lmLogError(gAssetAgentLogGroup, "Failed to resolve path %s via realpath due to %s", pathIn, strerror(errno));
        return 0;
    }

    // Now slurp off the prefix if possible.
    lmLogDebug(gAssetAgentLogGroup, "Checking for prefix '%s' '%s' '%s'", resolvedPathPtr, cwd, pathIn);

    lmAssert(resolvedPathPtr, "No resolved path!");
    lmAssert(cwd, "Could not get working dir?");

    const char *prefixOffset = strstr(resolvedPathPtr, cwd);
    if (prefixOffset != NULL)
    {
        // Great, it's known to us.
        strncpy(pathOut, prefixOffset + strlen(cwd) + 1, MAXPATHLEN);
        // free(resolvedPathPtr);
        return 1;
    }
    else
    {
        // Nope, unknown.
        // free(resolvedPathPtr);
        return 0;
    }
}


// We don't track every file. This function filters potential files.
static bool checkInWhitelist(utString path)
{
    // Note the platform-specific version of our whitelisted folders.
    static utString assetPath = "./assets"; platform_normalizePath(const_cast<char*>(assetPath.c_str()));
    static utString binPath   = "./bin";    platform_normalizePath(const_cast<char*>(binPath.c_str()));
    static utString srcPath   = "./src";    platform_normalizePath(const_cast<char*>(srcPath.c_str()));

    // Just prefix match against assets for now - ignore things in other folders.
    lmLogDebug(gAssetAgentLogGroup, "Whitelisting path %s prefix %s\n", path.c_str(), path.substr(0, 6).c_str());
    platform_normalizePath(const_cast<char*>(path.c_str()));
    if (path.substr(path.length() - 3, 3) == "tmp")
    {
        return false;
    }
    if (path.substr(0, 8) == assetPath)
    {
        return true;
    }
    if (path.substr(0, 5) == srcPath)
    {
        return true;
    }
    if (path.substr(0, 5) == binPath)
    {
        return true;
    }
    return false;
}


// Callback for file walker.
static void handleFileStateWalkCallback(const char *path, void *payload)
{
    FileEntry fe;

    // Skip if not in whitelist.
    if (!checkInWhitelist(path))
    {
        return;
    }

    // Note the path.
    fe.path = path;

    // Get the modifiedTime and size.
    fe.modifiedTime = platform_getFileModifiedDate(path);

    // Calculate the hash.
    // TODO: LOOM-32

    // Add to the list.
    utArray<FileEntry> *list = (utArray<FileEntry> *)payload;
    list->push_back(fe);
}


// Sort files by path for consistent ordering.
static int compareFileEntry(const FileEntry& a, const FileEntry& b)
{
    return strcmp(a.path.c_str(), b.path.c_str());
}


// Do it by flag for some sort routines.
static bool compareFileEntryBool(const FileEntry& a, const FileEntry& b)
{
    return strcmp(a.path.c_str(), b.path.c_str()) >= 0;
}


// Take a snapshot of the state of all our tracked files. This snapshot can
// then be compared to identify changes.
static utArray<FileEntry> *generateFileState(const char *root)
{
    utArray<FileEntry> *list = lmNew(NULL) utArray<FileEntry>();

    // Walk files in assets and src.
    char buffer[2048];

    sprintf(buffer, "%s%s%s", root, platform_getFolderDelimiter(), "assets");
    platform_walkFiles(buffer, handleFileStateWalkCallback, list);

    sprintf(buffer, "%s%s%s", root, platform_getFolderDelimiter(), "src");
    platform_walkFiles(buffer, handleFileStateWalkCallback, list);

    sprintf(buffer, "%s%s%s", root, platform_getFolderDelimiter(), "bin");
    platform_walkFiles(buffer, handleFileStateWalkCallback, list);

    // Sort the list into canonical order.
    list->sort(compareFileEntryBool);

    // Return the list.
    return list;
}


// Compare two snapshots of file state from the above function and return a
// description of any changes.
static utArray<FileEntryDelta> *compareFileEntries(utArray<FileEntry> *oldList, utArray<FileEntry> *newList)
{
    UTsize oldIndex = 0, newIndex = 0;

    utArray<FileEntryDelta> *deltaList = lmNew(NULL) utArray<FileEntryDelta>();

    // If we have no lists, it's a trivial case.
    if (!oldList && !newList)
    {
        return deltaList;
    }

    // If we only have one list, then it's either all adds or all removes.
    if (oldList && !newList)
    {
        for (UTsize i = 0; i < oldList->size(); i++)
        {
            FileEntryDelta fed;
            fed.action = FileEntryDelta::Removed;
            fed.path   = oldList->at(i).path;
            deltaList->push_back(fed);
        }

        return deltaList;
    }

    if (!oldList && newList)
    {
        for (UTsize i = 0; i < newList->size(); i++)
        {
            FileEntryDelta fed;
            fed.action = FileEntryDelta::Added;
            fed.path   = newList->at(i).path;
            deltaList->push_back(fed);
        }

        return deltaList;
    }


    // Walk the two lists (which are ordered) and generate FED's based on
    // mismatches.
    for ( ; ; )
    {
        // If we run off the end of either list, deal with the tail of the
        // other list after this block.
        if ((oldIndex >= oldList->size()) || (newIndex >= newList->size()))
        {
            break;
        }

        // Do the comparison...
        const FileEntry& oldEntry      = oldList->at(oldIndex);
        const FileEntry& newEntry      = newList->at(newIndex);
        int              compareResult = compareFileEntry(oldEntry, newEntry);

        FileEntryDelta deltaItem;

        if (compareResult < 0)
        {
            deltaItem.action = FileEntryDelta::Removed;
            deltaItem.path   = oldEntry.path;
            deltaList->push_back(deltaItem);

            oldIndex++;
            continue;
        }
        else if (compareResult > 0)
        {
            deltaItem.action = FileEntryDelta::Added;
            deltaItem.path   = newEntry.path;
            deltaList->push_back(deltaItem);

            newIndex++;
            continue;
        }
        else
        {
            // Match on path, check for other kinds of change.
            if (oldEntry.modifiedTime != newEntry.modifiedTime)
            {
                // TODO: check hash.

                // Report a change.
                deltaItem.action = FileEntryDelta::Modified;
                deltaItem.path   = newEntry.path;
                deltaList->push_back(deltaItem);
            }

            // Advance both.
            oldIndex++, newIndex++;
            continue;
        }
    }

    // Make sure we emit deletions for all remaining old items.
    while (oldIndex < oldList->size())
    {
        FileEntryDelta deltaItem;
        deltaItem.action = FileEntryDelta::Removed;
        deltaItem.path   = oldList->at(oldIndex).path;

        deltaList->push_back(deltaItem);

        oldIndex++;
    }

    // And emit additions for all remaining new items.
    while (newIndex < newList->size())
    {
        FileEntryDelta deltaItem;
        deltaItem.action = FileEntryDelta::Added;
        deltaItem.path   = newList->at(newIndex).path;

        deltaList->push_back(deltaItem);

        newIndex++;
    }

    // If the delta list needed to be canonical, we would sort by path here.

    // Return it!
    return deltaList;
}


// Take a difference report from compareFileEntries and issue appropriate
// file modification notes, and check whether they have settled. If so,
// transmit updates to clients.
static void processFileEntryDeltas(utArray<FileEntryDelta> *deltas)
{
    int curTime = platform_getMilliseconds();

    loom_mutex_lock(gFileScannerLock);

    // Update the pending list with all the stuff we've seen.
    for (UTsize i = 0; i < deltas->size(); i++)
    {
        // Get the delta.
        const FileEntryDelta& fed = deltas->at(i);

        // If it's removal, we don't currently send a notification.
        if (fed.action == FileEntryDelta::Removed)
        {
            continue;
        }

        // If it's not whitelisted, ignore it.
        if (!checkInWhitelist(fed.path))
        {
            continue;
        }

        // Note it in the pending modification list.
        bool sawInList = false;
        for (UTsize i = 0; i < gPendingModifications.size(); i++)
        {
            FileModificationNote& fmn = gPendingModifications.at(i);
            if (strcmp(fmn.path, fed.path.c_str()))
            {
                continue;
            }

            // Match - update time.
            lmLogDebug(gAssetAgentLogGroup, "FILE CHANGING - '%s'", fed.path.c_str());
            fmn.lastSeenTime = curTime;
            sawInList        = true;
        }

        if (!sawInList)
        {
            FileModificationNote fmn;
            fmn.path         = stringtable_insert(fed.path.c_str());
            fmn.lastSeenTime = curTime;
            gPendingModifications.push_back(fmn);
            lmLogDebug(gAssetAgentLogGroup, "FILE CHANGED  - '%s'", fed.path.c_str());
        }
    }

    // Now, walk the pending list and send everyone who hasn't been touched for the settling period.

    // See how many files we're sending and note that state.
    const int settleTimeMs = 750;

    int transferStartTime     = platform_getMilliseconds();
    int totalPendingTransfers = 0;
    for (UTsize i = 0; i < gPendingModifications.size(); i++)
    {
        // Only consider pending items that have aged out.
        FileModificationNote& fmn = gPendingModifications.at(i);
        if (curTime - fmn.lastSeenTime < settleTimeMs)
        {
            continue;
        }

        totalPendingTransfers++;
    }

    bool didWeNotifyUserAboutPending = false;

    for (UTsize i = 0; i < gPendingModifications.size(); i++)
    {
        // Only consider pending items that have aged out.
        FileModificationNote& fmn = gPendingModifications.at(i);
        if (curTime - fmn.lastSeenTime < settleTimeMs)
        {
            continue;
        }

        // Make the path canonical.
        utString filename = fmn.path;
        char     canonicalFile[MAXPATHLEN];
        makeAssetPathCanonical(filename.c_str(), canonicalFile);

        // Note: we don't deal with deleted files properly (by uploading new state) because realpath
        // only works right when the file exists. So we just skip doing anything about it.
        // Note we are using gActiveHandlers.size() outside of a lock, but this is ok as it's a word.
        if ((strstr(canonicalFile, ".loom") || strstr(canonicalFile, ".ls")) && (gActiveHandlers.size() > 0))
        {
            lmLog(gAssetAgentLogGroup, "Changed '%s'", canonicalFile);
        }

        if (canonicalFile[0] == 0)
        {
            lmLog(gAssetAgentLogGroup, "   o Ignoring file missing from the asset folder!");

            // Remove from the pending list.
            gPendingModifications.erase(i);
            i--;

            continue;
        }

        // Queue the callback.
        enqueueFileChangeCallback(canonicalFile);

        // Map the file.
        void *fileBits      = NULL;
        long fileBitsLength = 0;
        if (!platform_mapFile(canonicalFile, &fileBits, &fileBitsLength))
        {
            lmLog(gAssetAgentLogGroup, "   o Skipping due to file failing to map.");
            continue;
        }

        // Loop over the active sockets.
        loom_mutex_lock(gActiveSocketsMutex);

        // Blast it out to all clients.
        for (UTsize j = 0; j < gActiveHandlers.size(); j++)
        {
            // If it's for a specific client then only send to that client.
            if ((fmn.onlyForClient != -1) && (fmn.onlyForClient != gActiveHandlers[j]->getId()))
            {
                continue;
            }

            gActiveHandlers[j]->sendFile(canonicalFile, fileBits, fileBitsLength, totalPendingTransfers);

            // If it has been more than a second, note that we are still working.
            const int remainingTransferCount = (totalPendingTransfers * gActiveHandlers.size()) - j;
            if (((platform_getMilliseconds() - transferStartTime) > 2000) && (remainingTransferCount > 1))
            {
                transferStartTime = platform_getMilliseconds();
                lmLog(gAssetAgentLogGroup, "Still transferring files. %d to go!", remainingTransferCount - 1);
                didWeNotifyUserAboutPending = true;
            }
        }

        loom_mutex_unlock(gActiveSocketsMutex);

        totalPendingTransfers--;

        // Unmap the file.
        platform_unmapFile(fileBits);

        // Remove from the pending list.
        gPendingModifications.erase(i);
        i--;
    }

    loom_mutex_unlock(gFileScannerLock);

    if (didWeNotifyUserAboutPending)
    {
        lmLog(gAssetAgentLogGroup, "Done transferring files!");
    }
}


// This is the entry point for the file watcher thread. It scans local files
// for changes and processes the diffs with processFileEntryDeltas.
static int fileWatcherThread(void *payload)
{
    // Start with a sane state so we don't stream everything.
    utArray<FileEntry> *oldState = generateFileState(".");

    // Loop forever looking for changes.
    for ( ; ; )
    {
        int startTime = platform_getMilliseconds();

        utArray<FileEntry>      *newState = generateFileState(".");
        utArray<FileEntryDelta> *deltas   = compareFileEntries(oldState, newState);

        int endTime = platform_getMilliseconds();

        if (endTime - startTime > 250)
        {
            lmLogWarn(gAssetAgentLogGroup, "Scanning files took %dms, consider removing unused files", endTime - startTime);
        }

        processFileEntryDeltas(deltas);

        lmDelete(NULL, deltas);

        // Make the new state the old state and clean up the old state.
        lmDelete(NULL, oldState);
        oldState = newState;

        // Wait a bit so we don't saturate disk or CPU.
        loom_thread_sleep(gFileCheckInterval);
    }
}


/**
 * Post all known files to all clients, or if specified, a single client.
 *
 * Useful for fully synching client with the current asset state.
 *
 * TODO: Optimize to use hashes to only transmit modified data, based on
 * client's starting assets.
 */
static void postAllFiles(int clientId = -1)
{
    lmLog(gAssetAgentLogGroup, "Queueing all files for client %d.", clientId);

    loom_mutex_lock(gFileScannerLock);

    // Walk all the files.
    utArray<FileEntry> *list = lmNew(NULL) utArray<FileEntry>();
    platform_walkFiles(".", handleFileStateWalkCallback, list);

    // Queue them all to be sent.
    for (UTsize i = 0; i < list->size(); i++)
    {
        FileModificationNote note;
        note.path          = stringtable_insert((*list)[i].path.c_str());
        note.lastSeenTime  = 0;
        note.onlyForClient = clientId;
        gPendingModifications.push_back(note);
    }

    loom_mutex_unlock(gFileScannerLock);
}


// Dump connected clients to the console; useful for telling who is connected to the console!
static void listClients()
{
    loom_mutex_lock(gActiveSocketsMutex);

    // Blast it out to all clients.
    lmLog(gAssetAgentLogGroup, "Clients");

    for (UTsize i = 0; i < gActiveHandlers.size(); i++)
    {
        lmLog(gAssetAgentLogGroup, "   #%d - %s", gActiveHandlers[i]->getId(), gActiveHandlers[i]->description().c_str());
    }

    loom_mutex_unlock(gActiveSocketsMutex);
}


static void sendIgnoredError()
{
    lmLog(gAssetAgentLogGroup, "No clients connected, command ignored. Type .help for a list of local commands.")
}


// Entry point for the socket thread. Listen for connections and incoming data,
// and route it to the protocol handlers.
static int socketListeningThread(void *payload)
{
    // Listen for incoming connections.
    int listenPort = 12340;

    gListenSocket = (loom_socketId_t)-1;
    for ( ; ; )
    {
        gListenSocket = loom_net_listenTCPSocket(listenPort);

        if (gListenSocket != (loom_socketId_t)-1)
        {
            break;
        }

        lmLogWarn(gAssetAgentLogGroup, "   - Failed to acquire port %d, trying port %d", listenPort, listenPort + 1);
        listenPort++;
    }

    lmLog(gAssetAgentLogGroup, "Listening on port %d", listenPort);

    while (loom_socketId_t acceptedSocket = loom_net_acceptTCPSocket(gListenSocket))
    {
        // Check to see if we got anybody...
        if (!acceptedSocket || ((int)(long)acceptedSocket == -1))
        {
            // Process the connections.
            loom_mutex_lock(gActiveSocketsMutex);
            
            for (UTsize i = 0; i < gActiveHandlers.size(); i++)
            {
                AssetProtocolHandler* aph = gActiveHandlers[i];
                aph->process();

                // Check for ping timeout
                int msSincePing = loom_readTimer(aph->lastActiveTime);
                if (msSincePing > socketPingTimeoutMs)
                {
                    gActiveHandlers.erase(i);
                    i--;
                    lmLog(gAssetAgentLogGroup, "Client timed out (%x)", aph->socket);
                    loom_net_closeTCPSocket(aph->socket);
                    lmDelete(NULL, aph);
                }
            }

            loom_mutex_unlock(gActiveSocketsMutex);

            loom_thread_sleep(10);
            continue;
        }

        lmLog(gAssetAgentLogGroup, "Client connected (%x)", acceptedSocket);

        loom_mutex_lock(gActiveSocketsMutex);
        gActiveHandlers.push_back(lmNew(NULL) AssetProtocolHandler(acceptedSocket));

        AssetProtocolHandler *handler = gActiveHandlers.back();
        handler->registerListener(lmNew(NULL) TelemetryListener());
        if (TelemetryServer::isRunning()) handler->sendCommand("telemetryEnable");

        // Send it all of our files.
        // postAllFiles(gActiveHandlers[gActiveHandlers.size()-1]->getId());

        loom_mutex_unlock(gActiveSocketsMutex);
    }

    return 0;
}


// Helper to fully shut down the listen socket; helps quite a bit on OS X.
static void shutdownListenSocket()
{
    if (gListenSocket)
    {
        lmLogDebug(gAssetAgentLogGroup, "Shutting down listen socket...");
        loom_net_closeTCPSocket(gListenSocket);
        lmLog(gAssetAgentLogGroup, "Done! Goodbye.");
        gListenSocket = 0;
    }
}


// Cause shutdown sockets to close the listen socket.
static void shutdownListenSocketSignalHandler(int s)
{
    shutdownListenSocket();
    exit(0);
}


static void fileWatcherLogListener(void *payload, loom_logGroup_t *group, loom_logLevel_t level, const char *msg)
{
    enqueueLogCallback(msg);
}


extern "C"
{
// On Windows, make sure that we're exporting the symbols properly for the DLL.
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#define DLLEXPORT    __declspec(dllexport)
#else
#define DLLEXPORT
#endif



void DLLEXPORT assetAgent_set(const char *key, const char *value) {
    utFastStringHash hash = utFastStringHash(key);
    gOptions.set(hash, value);
}

static utString* optionGet(const char *key) {
    utFastStringHash hash = utFastStringHash(key);
    return gOptions.get(hash);
}

static bool optionEquals(const char *key, const char *expected) {
    utString *value = optionGet(key);
    if (value == NULL) return false;
    return *value == expected;
}

void DLLEXPORT assetAgent_run(IdleCallback idleCb, LogCallback logCb, FileChangeCallback changeCb)
{
    loom_log_initialize();
    platform_timeInitialize();
    stringtable_initialize();
    loom_net_initialize();

    // Put best effort towards closing our listen socket when we shut down, to
    // avoid bugs on OSX where the OS won't release it for a while.

#if LOOM_PLATFORM == LOOM_PLATFORM_OSX || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
    atexit(shutdownListenSocket);
    signal(SIGINT, shutdownListenSocketSignalHandler);
#endif

    // Set up mutexes.
    gActiveSocketsMutex = loom_mutex_create();
    gFileScannerLock    = loom_mutex_create();
    gCallbackLock       = loom_mutex_create();

    // Note callbacks.
    gLogCallback        = logCb;
    gFileChangeCallback = changeCb;


    utString *sdkPath = optionGet("sdk");
    if (sdkPath != NULL) TelemetryServer::setClientRootFromSDK(sdkPath->c_str());
    const char *ltcPath = getenv("LoomTelemetry");
    if (ltcPath != NULL) TelemetryServer::setClientRoot(ltcPath);

    if (optionEquals("telemetry", "true")) TelemetryServer::start();



    // Set up the log callback.
    loom_log_addListener(fileWatcherLogListener, NULL);

    lmLogDebug(gAssetAgentLogGroup, "Starting file watcher thread...");
    gFileWatcherThread = loom_thread_start((ThreadFunction)fileWatcherThread, NULL);
    lmLogDebug(gAssetAgentLogGroup, "   o OK!");

    lmLogDebug(gAssetAgentLogGroup, "Starting socket listener thread...");
    gSocketListenerThread = loom_thread_start((ThreadFunction)socketListeningThread, NULL);
    lmLogDebug(gAssetAgentLogGroup, "   o OK!");

    // Loop till it's time to quit.
    while (!gQuitFlag)
    {
        // Serve the idle callback.
        if (idleCb)
        {
            idleCb();
        }

        // And anything in the queue.
        while (CallbackQueueNote *cqn = dequeueCallback())
        {
            if (!cqn)
            {
                break;
            }

            // Issue the call.
            if (cqn->type == QNT_Change)
            {
                gFileChangeCallback(cqn->text.c_str());
            }
            else if (cqn->type == QNT_Log)
            {
                gLogCallback(cqn->text.c_str());
            }
            else
            {
                lmAssert(false, "Unknown callback queue note type.");
            }

            // Clean it up.
            //free((void *)cqn->text);
            lmDelete(NULL, cqn);
        }
        // Pump any remaining socket writes
        loom_net_pump();

        // Poll at about 60hz.
        loom_thread_sleep(16);
    }

    // Clean up the socket.
    shutdownListenSocket();
}


void DLLEXPORT assetAgent_command(const char *cmd)
{
    if (strstr(cmd, ".sendall") != 0)
    {
        postAllFiles();
    }
    else if (strstr(cmd, ".clients") != 0)
    {
        listClients();
    }
    else if (strstr(cmd, ".telemetry") != 0)
    {
        TelemetryServer::isRunning() ? TelemetryServer::stop() : TelemetryServer::start();
        assetAgent_command(TelemetryServer::isRunning() ? "telemetryEnable" : "telemetryDisable");
    }
    else if (cmd[0] != 0)
    {
        loom_mutex_lock(gActiveSocketsMutex);

        if (gActiveHandlers.size() == 0)
        {
            if (strcmp(cmd, "terminate") != 0) sendIgnoredError();
        }

        for (UTsize i = 0; i < gActiveHandlers.size(); i++)
        {
            gActiveHandlers[i]->sendCommand(cmd);
        }

        loom_mutex_unlock(gActiveSocketsMutex);
    }
}


void DLLEXPORT assetAgent_quit()
{
    gQuitFlag = true;

    // Clean up the socket.
    shutdownListenSocket();
}
}
